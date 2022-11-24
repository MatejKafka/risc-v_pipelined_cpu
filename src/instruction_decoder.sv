`ifndef PACKAGE_INSTRUCTION_DECODER
`define PACKAGE_INSTRUCTION_DECODER
`include "types.svh"
`include "utils.svh"
`include "instruction_types.svh"

`define NOP_INSTRUCTION '{IF_ALU_USE_IMM, ADD, 0, 0, 0, 0}
// invoke `ERROR and set the resulting instruction to NOP, to prevent
//  the rest of the CPU from doing something dangerous
`define SIGILL(display_expr) do begin `ERROR(display_expr); return `NOP_INSTRUCTION; end while (0)

// Note that the instruction decoder uses fixed type sizes, unlike the rest of the project.
module instruction_decoder(output reg error, input Word in, output Instruction out);
    `TRACE(in or out, 32, ("🈯%s", Instruction_to_string(out)))

    // continuously decode instructions
    assign out = decode_instruction(in);

    // read the opcode, call the corresponding function to handle that type of instructions
    // since not all opcodes have a standard name, some of the names are made up (like IA = "immediate arithmetic")
    function Instruction decode_instruction(Word i);
        error = 0;
        case (i[6:0])
            'b0110111: return decode_LUI(i[31:                             12], i[11:7]);
            'b0010111: return decode_AUIPC(i[31:                           12], i[11:7]);
            'b1101111: return decode_J (i[31:                              12], i[11:7]);
            'b1100011: return decode_B (i[31:25], i[24:20], i[19:15], i[14:12], i[11:7]);
            'b0100011: return decode_S (i[31:25], i[24:20], i[19:15], i[14:12], i[11:7]);
            'b0000011: return decode_IL(i[31:          20], i[19:15], i[14:12], i[11:7]);
            'b0010011: return decode_IA(i[31:          20], i[19:15], i[14:12], i[11:7]);
            'b0110011: return decode_R (i[31:25], i[24:20], i[19:15], i[14:12], i[11:7]);
            'b1110011: return decode_E (i[31:          20], i[19:                    7]);
            default: `SIGILL(("Invalid/unsupported instruction."));
        endcase
    endfunction


    // LUI = load upper immediate (effectively, an `ADDI rd, 0, imm`, with large, shifted immediate)
    function Instruction decode_LUI(logic [19:0] imm, RegAddress rd);
        // no Immediate' cast here, we need to match the size exactly
        return '{IF_ALU_USE_IMM, XOR, rd, 0, 0, {imm, 12'b0}};
    endfunction


    // AUIPC
    function Instruction decode_AUIPC(logic [19:0] imm, RegAddress rd);
        // no Immediate' cast here, we need to match the Immediate size exactly because of the shift
        return '{IF_ALU_USE_IMM | IF_PC_TO_ALU_SRC1, ADD, rd, 0, 0, {imm, 12'b0}};
    endfunction


    // J-type instruction(s) (JAL)
    function Instruction decode_J(logic [19:0] shuffled_imm, RegAddress rd);
        automatic Immediate imm = Immediate'($signed({shuffled_imm[19], shuffled_imm[7:0], shuffled_imm[8], shuffled_imm[18:9], 1'b0}));
        // we set alu_op to ADD so that IF_ALU_SHOULD_BE_ZERO is fulfilled and the jump is taken
        return '{IF_IS_BRANCH | IF_NEXT_PC_TO_RD | IF_ALU_SHOULD_BE_ZERO, ADD, rd, 0, 0, imm}; // JAL
    endfunction


    // B-type instructions (branches - BEQ, BNE,...)
    function Instruction decode_B(logic [6:0] imm7, RegAddress rs2, rs1, logic [2:0] funct3, logic [4:0] imm5);
        automatic Immediate imm = Immediate'($signed({imm7[6], imm5[0], imm7[5:0], imm5[4:1], 1'b0}));
        automatic AluOp op;
        automatic logic expected_alu_zero = 0;
        casez (funct3)
            'b00?: begin op = SUB;  expected_alu_zero = !funct3[0]; end // BEQ/BNE
            'b10?: begin op = SLT;  expected_alu_zero =  funct3[0]; end // BLT/BGE
            'b11?: begin op = SLTU; expected_alu_zero =  funct3[0]; end // BLTU/BGEU
            'b01?: `SIGILL(("Invalid/unsupported B instruction, unknown 'funct3' value: %0b", funct3));
        endcase
        // set `rd` to r0 to ignore the write
        return '{IF_IS_BRANCH | (expected_alu_zero ? IF_ALU_SHOULD_BE_ZERO : IF_NONE), op, '0, rs1, rs2, imm};
    endfunction

    // S-type instructions - memory writes (SW)
    function Instruction decode_S(logic [6:0] imm7, RegAddress rs2, rs1, logic [2:0] funct3, logic [4:0] imm5);
        automatic Immediate imm = Immediate'($signed({imm7, imm5}));
        if (funct3 != 'b010) `SIGILL(("Invalid/unsupported S instruction, unknown 'funct3' value: %0b", funct3));
        return '{IF_ALU_USE_IMM | IF_RAM_WRITE, ADD, 0, rs1, rs2, imm};
    endfunction


    // Immediate Load instructions - memory read (LW)
    function Instruction decode_IL(logic [11:0] imm, RegAddress rs1, logic [2:0] funct3, RegAddress rd);
        if (funct3 != 'b010) `SIGILL(("Invalid/unsupported IL instruction, unknown 'funct3' value: %0b", funct3));
        return '{IF_ALU_USE_IMM | IF_RAM_READ_TO_RD, ADD, rd, rs1, 0, Immediate'($signed(imm))};
    endfunction


    // R-type instructions (register-to-register)
    function Instruction decode_R(logic [6:0] funct7, RegAddress rs2, rs1, logic [2:0] funct3, RegAddress rd);
        // AluOps are encoded the same way as in the instruction, so we just combine the relevant bits
        automatic AluOp op = AluOp'({funct7[5], funct3});
        // validate the instruction
        if ({funct7[6], funct7[4:0]} != 0) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7' value."));
        if (funct7[5] && funct3 != 3'b000 && funct3 != 3'b101) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7'/'funct3' value combination."));
        return '{IF_NONE, op, rd, rs1, rs2, '0};
    endfunction


    // Immediate Arithmetic instructions
    function Instruction decode_IA(logic [11:0] imm, RegAddress rs1, logic [2:0] funct3, RegAddress rd);
        automatic AluOp op;
        automatic Immediate imm_resolved;

        // shifts have 'funct7' and a shorter immediate
        if (funct3 == 3'b?01) begin
            // validate the instruction
            if (funct3 == 3'b001) begin
                if (imm[11:5] != 0) `SIGILL(("Invalid/unsupported IA shift instruction, unknown 'funct7' value."));
            end else begin
                if ({imm[11], imm[9:5]} != 0) `SIGILL(("Invalid/unsupported IA shift instruction, unknown 'funct7' value."));
            end
            op = AluOp'({imm[10], 3'b101});
            imm_resolved = Immediate'($unsigned(imm[4:0]));
        end else begin
            op = AluOp'({1'b0, funct3});
            imm_resolved = Immediate'($signed(imm));
        end
        return '{IF_ALU_USE_IMM, op, rd, rs1, '0, imm_resolved};
    endfunction


    /* EBREAK & ECALL */
    function Instruction decode_E(logic [11:0] type_, logic [12:0] zeros);
        if (zeros != 0) `SIGILL(("Invalid/unsupported E instruction."));
        case (type_)
            12'b000000000000: `SIGILL(("ECALL not supported."));
            12'b000000000001: return '{flags: IF_IS_EBREAK, alu_op: AluOp'(0), default: '0};
            default: `SIGILL(("Invalid/unsupported E instruction."));
        endcase
    endfunction
endmodule


`ifdef TEST_instruction_decoder
`include "instruction_macros.svh"
module instruction_decoder_tb;
    logic error;
    Word in;
    Instruction out;

    instruction_decoder decoder(error, in, out);

    initial begin
        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    initial begin
        test_instruction(`R_LUI(1, 32'h7FEED000)); // = 2146357248
        test_instruction(`R_AUIPC(1, 32'h7FEED000)); // = 2146357248

        test_instruction(`R_ADDI(1, 0, -10));
        test_instruction(`R_ADD(1, 11, 10));
        test_instruction(`R_SUB(1, 11, 10));
        test_instruction(`R_AND(1, 11, 10));

        test_instruction(`R_BEQ (2, 1, -32'd4));
        test_instruction(`R_BNE (2, 1, 13'd8));
        test_instruction(`R_JAL(2, 'h0ffffe)); // = 1048574
        test_instruction(`R_JAL(3, -32'd10));

        test_instruction(`R_SW(10, 1, 'h100));
        test_instruction(`R_LW(10, 1, 'h100));

        test_instruction(`R_EBREAK);
    end

    task test_instruction(Word i);
        in = i;
        #1 $display("%s", Instruction_to_string(out));
    endtask
endmodule
`endif

`endif