`ifndef PACKAGE_INSTRUCTION_DECODER
`define PACKAGE_INSTRUCTION_DECODER
`include "types.sv"
`include "alu.sv"

typedef logic signed [11:00] Immediate;
typedef struct packed {
    AluOp op;
    RegAddress rd;
    RegAddress rs1;
    Bool has_immediate;
    RegAddress rs2;
    Immediate immediate;
    Bool is_ebreak;
} Instruction;

task Instruction_display(Instruction i);
    if (i.is_ebreak) begin
        $display("EBREAK");
    end else begin
        $display("%s rd=%0d rs1=%0d %0s=%0d", AluOp_symbol(i.op), i.rd, i.rs1,
                i.has_immediate ? "imm" : "rs2",
                i.has_immediate ? i.immediate : $signed(12'({1'b0, i.rs2})));
    end
endtask


// Note that the instruction decoder uses fixed type sizes, unlike the rest of the project.
module instruction_decoder(input Word in, output Instruction out);
    // read the opcode, call the corresponding function to handle that type of instructions
    // since not all opcodes have a standard name, some of the names are made up (like IA = "immediate arithmetic")
    always @ (*) case (in[6:0])
        'b0110011: decode_R (in[31:25], in[24:20], in[19:15], in[14:12], in[11:7]);
        'b0010011: decode_IA(in[31:           20], in[19:15], in[14:12], in[11:7]);
        'b1110011: decode_E (in[31:           20], in[19:                      7]);
        default: panic("Invalid/unsupported instruction.");
    endcase


    // R-type instructions (register-to-register)
    function void decode_R(logic [6:0] funct7, RegAddress rs2, rs1, logic [2:0] funct3, RegAddress rd);
        // AluOps are encoded the same way as in the instruction, so we just combine the relevant bits
        automatic AluOp op = AluOp'({funct7[5], funct3});
        // validate the instruction
        if ({funct7[6], funct7[4:0]} != 0) panic("Invalid/unsupported R instruction, unknown 'funct7' value.");
        if (funct7[5] && funct3 != 3'b000 && funct3 != 3'b101) panic("Invalid/unsupported R instruction, unknown 'funct7'/'funct3' value combination.");
        out = '{op, rd, rs1, FALSE, rs2, '0, FALSE};
    endfunction


    // Immediate Arithmetic instructions
    function void decode_IA(Immediate imm, RegAddress rs1, logic [2:0] funct3, RegAddress rd);
        automatic AluOp op;
        automatic Immediate imm_resolved;

        if (funct3 == 3'b?01) begin
            // shifts have 'funct7' and a shorter immediate
            if (funct3 == 3'b001) begin
                if (imm[11:5] != 0) panic("Invalid/unsupported IA shift instruction, unknown 'funct7' value.");
            end else begin
                if ({imm[11], imm[9:5]} != 0) panic("Invalid/unsupported IA shift instruction, unknown 'funct7' value.");
            end
            op = AluOp'({imm[10], 3'b101});
            imm_resolved = Immediate'($unsigned(imm[4:0]));
        end else begin
            op = AluOp'({1'b0, funct3});
            imm_resolved = imm;
        end
        out = '{op, rd, rs1, TRUE, '0, imm_resolved, FALSE};
    endfunction


    /* EBREAK & ECALL */
    function void decode_E(logic [11:0] type_, logic [12:0] zeros);
        if (zeros != 0) panic("Invalid/unsupported E instruction.");
        case (type_)
            12'b000000000000: panic("ECALL not supported.");
            12'b000000000001: begin out = '0; out.is_ebreak = TRUE; end
            default: panic("Invalid/unsupported E instruction.");
        endcase
    endfunction
endmodule


`ifdef TEST_instruction_decoder
`include "instruction_macros.sv"
module instruction_decoder_tb;
    Word in;
    wire Instruction out;

    instruction_decoder decoder(in, out);

    initial begin
        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    initial begin
        in = `ADDI(1, 0, -10);
        #1 Instruction_display(out);
        in = `ADD(1, 11, 10);
        #1 Instruction_display(out);
        in = `SUB(1, 11, 10);
        #1 Instruction_display(out);
        in = `AND(1, 11, 10);
        #1 Instruction_display(out);
    end
endmodule
`endif

`endif