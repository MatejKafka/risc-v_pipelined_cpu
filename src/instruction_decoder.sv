`ifndef PACKAGE_INSTRUCTION_DECODER
`define PACKAGE_INSTRUCTION_DECODER
`include "types.sv"
`include "alu.sv"
`include "instruction_types.sv"

// TODO: assignment: lw, sw, lui, li, la
// TODO: standard: auipc, blt, bge, bltu, bgeu, lb, lh, lbu, lhu, sb, sh
// standard, skipped: jalr (function support), fence (memory fence)

`define NOP_INSTRUCTION '{IF_ALU_USE_IMM, ADD, 0, 0, 0, 0}
// invoke `ERROR and set the resulting instruction to NOP, to prevent
//  the rest of the CPU from doing something dangerous
`define SIGILL(display_expr) do begin `ERROR(display_expr); out = `NOP_INSTRUCTION; return; end while (0)

// Note that the instruction decoder uses fixed type sizes, unlike the rest of the project.
module instruction_decoder(output reg error, input Word in, output Instruction out);
    `TRACE(out, 32, ("🈯%s%s",
            error ? "ERROR" :
                out.flags.is_branch ? "BRANCH" :
                out.flags.is_ebreak ? "EBREAK" :
                out.alu_op.name(),
            !error & out.flags.alu_use_imm ? " imm" : ""))

    // read the opcode, call the corresponding function to handle that type of instructions
    // since not all opcodes have a standard name, some of the names are made up (like IA = "immediate arithmetic")
    always @ (*) decode_instruction(in);

    function void decode_instruction(Word i);
        error = 0;
        case (i[6:0])
            'b1101111: decode_J (i[31:                              12], i[11:7]);
            'b1100011: decode_B (i[31:25], i[24:20], i[19:15], i[14:12], i[11:7]);
            'b0110011: decode_R (i[31:25], i[24:20], i[19:15], i[14:12], i[11:7]);
            'b0010011: decode_IA(i[31:          20], i[19:15], i[14:12], i[11:7]);
            'b1110011: decode_E (i[31:          20], i[19:                    7]);
            default: `SIGILL(("Invalid/unsupported instruction."));
        endcase
    endfunction


    // J-type instruction(s) (JAL)
    function void decode_J(logic [19:0] shuffled_imm, RegAddress rd);
        automatic Immediate imm = {shuffled_imm[19], shuffled_imm[7:0], shuffled_imm[8], shuffled_imm[18:9], 1'b0};
        // we set alu_op to ADD so that IF_ALU_SHOULD_BE_ZERO is fulfilled and the jump is taken
        out = '{IF_IS_BRANCH | IF_NEXT_PC_TO_RD | IF_ALU_SHOULD_BE_ZERO, ADD, rd, 0, 0, imm}; // JAL
    endfunction


    // B-type instructions (branches - BEQ, BNE)
    function void decode_B(logic [6:0] imm7, RegAddress rs2, rs1, logic [2:0] funct3, logic [4:0] imm5);
        automatic Immediate imm = Immediate'($signed({imm7[6], imm5[0], imm7[5:0], imm5[4:1], 1'b0}));
        // validate the instruction, we only support BEQ and BNE
        if (funct3[2:1] != 'b00) `SIGILL(("Invalid/unsupported B instruction, unknown 'funct3' value: %0b", funct3));
        // set `rd` to r0 to ignore the write
        out = '{IF_IS_BRANCH | (funct3[0] ? IF_NONE : IF_ALU_SHOULD_BE_ZERO), SUB, '0, rs1, rs2, imm};
    endfunction


    // R-type instructions (register-to-register)
    function void decode_R(logic [6:0] funct7, RegAddress rs2, rs1, logic [2:0] funct3, RegAddress rd);
        // AluOps are encoded the same way as in the instruction, so we just combine the relevant bits
        automatic AluOp op = AluOp'({funct7[5], funct3});
        // validate the instruction
        if ({funct7[6], funct7[4:0]} != 0) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7' value."));
        if (funct7[5] && funct3 != 3'b000 && funct3 != 3'b101) `SIGILL(("Invalid/unsupported R instruction, unknown 'funct7'/'funct3' value combination."));
        out = '{IF_NONE, op, rd, rs1, rs2, '0};
    endfunction


    // Immediate Arithmetic instructions
    function void decode_IA(logic [11:0] imm, RegAddress rs1, logic [2:0] funct3, RegAddress rd);
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
        out = '{IF_ALU_USE_IMM, op, rd, rs1, '0, imm_resolved};
    endfunction


    /* EBREAK & ECALL */
    function void decode_E(logic [11:0] type_, logic [12:0] zeros);
        if (zeros != 0) `SIGILL(("Invalid/unsupported E instruction."));
        case (type_)
            12'b000000000000: `SIGILL(("ECALL not supported."));
            12'b000000000001: begin out = '0; out.flags = IF_IS_EBREAK; end
            default: `SIGILL(("Invalid/unsupported E instruction."));
        endcase
    endfunction
endmodule


`ifdef TEST_instruction_decoder
`include "instruction_macros.sv"
module instruction_decoder_tb;
    wire error;
    Word in;
    wire Instruction out;

    instruction_decoder decoder(error, in, out);

    initial begin
        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    initial begin
        in = `R_ADDI(1, 0, -10);
        #1 Instruction_display(out);
        in = `R_ADD(1, 11, 10);
        #1 Instruction_display(out);
        in = `R_SUB(1, 11, 10);
        #1 Instruction_display(out);
        in = `R_AND(1, 11, 10);
        #1 Instruction_display(out);

        in = `R_BEQ (2, 1, -32'd4);
        #1 Instruction_display(out);
        in = `R_BNE (2, 1, 13'd8);
        #1 Instruction_display(out);
        in = `R_JAL(2, 'h0ffffe); // = 1048574
        #1 Instruction_display(out);
        in = `R_JAL(3, -32'd10);
        #1 Instruction_display(out);

        in = `R_EBREAK;
        #1 Instruction_display(out);
    end

    task Instruction_display(Instruction i);
        if (error) $display("ERROR");
        else if (i == `D_NOP) $display("NOP");
        else if (i.flags.is_ebreak) $display("EBREAK");
        else if (i.flags.is_branch) begin
            $display("BRANCH imm=%0d", i.immediate);
        end else begin
            $display("%s rd=%0d rs1=%0d %0s=%0d", i.alu_op.name(), i.rd, i.rs1,
                    i.flags.alu_use_imm ? "imm" : "rs2",
                    i.flags.alu_use_imm ? i.immediate : $signed(21'({1'b0, i.rs2})));
        end
    endtask
endmodule
`endif

`endif