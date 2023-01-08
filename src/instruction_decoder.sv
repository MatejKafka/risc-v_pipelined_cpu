`ifndef PACKAGE_INSTRUCTION_DECODER
`define PACKAGE_INSTRUCTION_DECODER
`include "types.svh"
`include "utils.svh"
`include "instruction_types.svh"

// Note that the instruction decoder uses fixed type sizes, unlike the rest of the project.
module instruction_decoder(output reg error, input UWord in, output Instruction out);
    `TRACE(in or out, 32, ("🈯%s", error ? $sformatf("Invalid instruction (0x%h)", in) : Instruction_to_string(out)))

    // continuously decode instructions
    assign out = decode_instruction(in);


    // HELPER FUNCTIONS ==================================================================================================
    /** Partial decoded instruction without the register numbers, which are extracted the same way for all instructions. */
    typedef struct packed {
        logic invalid_instruction;
        Immediate immediate;
        InstructionControl control;
    } PInstruction;

    function PInstruction parsed(AluOp op, Immediate imm, RdSrc rd, AluSrc1 alu1, AluSrc2 alu2,
            logic is_ebreak = 0, ram_write = 0, BranchCondition branch_cond = BC_NEVER,
            ComparatorOp cmp_op = C_NONE, logic invalid=0);
        return '{invalid, imm, '{op, cmp_op, is_ebreak, ram_write, branch_cond, rd, alu1, alu2}};
    endfunction


    // invoke `ERROR and set the resulting instruction to NOP, to prevent
    //  the rest of the CPU from doing something dangerous
    `define SIGILL(display_expr) do begin \
            `ERROR(display_expr); \
            return parsed(ADD, 0, RdSrc'(0), AluSrc1'(0), AluSrc2'(0), .invalid(TRUE)); \
        end while (0)
    // END HELPER FUNCTIONS ==============================================================================================


    // read the opcode, call the corresponding function to handle that type of instructions
    // since not all opcodes have a standard name, some of the names are made up (like IA = "immediate arithmetic")
    function Instruction decode_instruction(UWord i);
        automatic PInstruction pi;
        error = 0;
        case (i[6:0])
            'b0110111: pi = decode_LUI(i[31:12]);
            'b0010111: pi = decode_AUIPC(i[31:12]);
            'b1101111: pi = decode_JAL(i[31:12]);
            'b1100111: pi = decode_JALR(i[31:        20], i[14:12]);

            'b1100011: pi = decode_B (i[31:25],           i[14:12], i[11:7]);
            'b0100011: pi = decode_S (i[31:25],           i[14:12], i[11:7]);
            'b0000011: pi = decode_IL(i[31:          20], i[14:12]);
            'b0010011: pi = decode_IA(i[31:          20], i[14:12]);
            'b0110011: pi = decode_R (i[31:25],           i[14:12]);
            'b1110011: pi = decode_E (i[31:          20], i[19:          7]);

            'b0001111: begin `ERROR(("FENCE is not supported.")); return I_NOP; end
            default: begin `ERROR(("Invalid/unsupported instruction.")); return I_NOP; end
        endcase

        if (pi.invalid_instruction) return I_NOP;
        // registers are wired directly, and we use flags to define whether to use them or not
        return '{control: pi.control, immediate: pi.immediate, rs2: i[24:20], rs1: i[19:15], rd: i[11:7]};
    endfunction


    // LUI = load upper immediate (effectively, an `ADDI rd, 0, imm`, with large, shifted immediate)
    function PInstruction decode_LUI(logic [19:0] imm);
        // no Immediate' cast here, we need to match the size exactly
        return parsed(XOR, {imm, 12'b0}, RD_ALU, ALU1_ZERO, ALU2_IMM);
    endfunction


    // AUIPC
    function PInstruction decode_AUIPC(logic [19:0] imm);
        // no Immediate' cast here, we need to match the Immediate size exactly because of the shift
        return parsed(ADD, {imm, 12'b0}, RD_ALU, ALU1_PC, ALU2_IMM);
    endfunction


    // JAL
    function PInstruction decode_JAL(logic [19:0] shuffled_imm);
        automatic Immediate imm = Immediate'($signed({shuffled_imm[19], shuffled_imm[7:0], shuffled_imm[8], shuffled_imm[18:9], 1'b0}));
        return parsed(ADD, imm, RD_NEXT_PC, ALU1_PC, ALU2_IMM, .branch_cond(BC_ALWAYS));
    endfunction


    // JALR
    function PInstruction decode_JALR(logic [11:0] imm, logic [2:0] funct3);
        if (funct3 != 'b000) `SIGILL(("Invalid/unsupported J instruction, unknown 'funct3' value: 0b%b", funct3));
        return parsed(ADD, Immediate'($signed(imm)), RD_NEXT_PC, ALU1_RS1, ALU2_IMM, .branch_cond(BC_ALWAYS));
    endfunction


    // B-type instructions (branches - BEQ, BNE,...)
    function PInstruction decode_B(logic [6:0] imm7, logic [2:0] funct3, logic [4:0] imm5);
        automatic Immediate imm = Immediate'($signed({imm7[6], imm5[0], imm7[5:0], imm5[4:1], 1'b0}));
        if (funct3[2:1] == 'b01) `SIGILL(("Invalid/unsupported B instruction, unknown 'funct3' value: 0b%b", funct3));
        // ComparatorOps are encoded the same way as in the instruction, so we just pass the relevant bits
        return parsed(ADD, imm, RD_NONE, ALU1_PC, ALU2_IMM, .branch_cond(funct3[0] ? BC_CMP_FALSE : BC_CMP_TRUE),
                .cmp_op(ComparatorOp'(funct3[2:1])));
    endfunction


    // S-type instructions - memory writes (SW)
    function PInstruction decode_S(logic [6:0] imm7, logic [2:0] funct3, logic [4:0] imm5);
        if (funct3 != 'b010) `SIGILL(("Invalid/unsupported S instruction, unknown 'funct3' value: 0b%b", funct3));
        return parsed(ADD, Immediate'($signed({imm7, imm5})), RD_NONE, ALU1_RS1, ALU2_IMM, .ram_write(TRUE));
    endfunction


    // Immediate Load instructions - memory read (LW)
    function PInstruction decode_IL(logic [11:0] imm, logic [2:0] funct3);
        if (funct3 != 'b010) `SIGILL(("Invalid/unsupported IL instruction, unknown 'funct3' value: 0b%b", funct3));
        return parsed(ADD, Immediate'($signed(imm)), RD_RAM_OUT, ALU1_RS1, ALU2_IMM);
    endfunction


    // R-type instructions (register-to-register)
    function PInstruction decode_R(logic [6:0] funct7, logic [2:0] funct3);
        if ({funct7[6], funct7[4:0]} != 0) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7' value."));
        if (funct7[5] && funct3 != 3'b000 && funct3 != 3'b101) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7'/'funct3' value combination."));
        // AluOps are encoded the same way as in the instruction, so we just combine the relevant bits
        return parsed(AluOp'({funct7[5], funct3}), '0, RD_ALU, ALU1_RS1, ALU2_RS2);
    endfunction


    // Immediate Arithmetic instructions
    function PInstruction decode_IA(logic [11:0] imm, logic [2:0] funct3);
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

        return parsed(op, imm_resolved, RD_ALU, ALU1_RS1, ALU2_IMM);
    endfunction


    /* EBREAK & ECALL */
    function PInstruction decode_E(logic [11:0] type_, logic [12:0] zeros);
        if (zeros != 0) `SIGILL(("Invalid/unsupported E instruction."));
        case (type_)
            12'b000000000000: `SIGILL(("ECALL is not supported."));
            12'b000000000001: return parsed(ADD, 0, RD_NONE, ALU1_RS1, ALU2_IMM, .is_ebreak(TRUE));
            default: `SIGILL(("Invalid/unsupported E instruction."));
        endcase
    endfunction
endmodule


`ifdef TEST_instruction_decoder
`include "instruction_macros.svh"
module instruction_decoder_tb;
    logic error;
    UWord in;
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