`ifndef PACKAGE_INSTRUCTION_DECODER
`define PACKAGE_INSTRUCTION_DECODER
`include "types.sv"
`include "alu.sv"

typedef struct packed {
    AluOp op;
    RegAddress rd;
    RegAddress rs1;
    Bool has_immediate;
    RegAddress rs2;
    Word immediate;
    Bool is_ebreak;
} Instruction;

task Instruction_display(Instruction i);
    $display("%s rd=%0d rs1=%0d %0s=%0d",
        AluOp_symbol(i.op), i.rd, i.rs1,
        i.has_immediate ? "imm" : "rs2",
        i.has_immediate ? $signed(i.immediate) : $signed({1'b0, i.rs2}));
endtask

// iverilog does not seem to support the '{} struct initialization syntax, so we'll have to do it manually
`define INSTRUCTION(I, OP, RD, RS1, HAS_IMMEDIATE, RS2, IMM_SIGN, IMM, IS_EBREAK) do begin \
        I.op = OP; \
        I.rd = RD; \
        I.rs1 = RS1; \
        I.has_immediate = HAS_IMMEDIATE; \
        I.rs2 = RS2; \
        I.immediate = {{21{IMM_SIGN}}, IMM}; \
        I.is_ebreak = IS_EBREAK; \
    end while (0)

/** Note that the instruction decoder uses fixed type sizes, unlike the rest of the project. */
module instruction_decoder(input Word in, output Instruction out);
    // read the opcode, call the corresponding function to handle that type of instructions
    // since not all opcodes have a standard name, some of the names are made up (like IA = "immediate arithmetic")
    always @ (*) case (in[6:0])
        'b0110011: decode_R (in[31:25], in[24:20], in[19:15], in[14:12], in[11:7]);
        'b0010011: decode_IA(in[31:           20], in[19:15], in[14:12], in[11:7]);
        'b1110011: decode_E (in[31:           20], in[19:                      7]);
        default: panic("Invalid/unsupported instruction.");
    endcase


    // ADD & co
    function void decode_R(logic [6:0] funct7, RegAddress rs2, rs1, logic [2:0] funct3, RegAddress rd);
        AluOp op;
        case ({funct7, funct3})
            'b0000000_000: op = ADD;
            'b0100000_000: op = SUB;
            // SLL
            // SLT
            // SLU
            'b0000000_100: op = XOR;
            // SRL
            // SRA
            'b0000000_110: op = OR;
            'b0000000_111: op = AND;
            default: panic("Invalid/unsupported R instruction.");
        endcase
        `INSTRUCTION(out, op, rd, rs1, FALSE, rs2, 1'b0, 1'b0, FALSE);
    endfunction


    // ADDI & co
    function void decode_IA(logic [11:0] imm, RegAddress rs1, logic [2:0] funct3, RegAddress rd);
        `INSTRUCTION(out, ADD, rd, rs1, TRUE, 5'b0, imm[11], imm[10:0], FALSE);
    endfunction


    /* EBREAK & ECALL */
    function void decode_E(logic [11:0] type_, logic [12:0] zeros);
        if (zeros != 0) panic("Invalid/unsupported E instruction.");
        case (type_)
            12'b000000000000: panic("ECALL not supported.");
            12'b000000000001: `INSTRUCTION(out, ADD, RegAddress'(0), RegAddress'(0), FALSE, RegAddress'(0), 1'b0, 11'b0, TRUE);
            default: panic("Invalid/unsupported E instruction.");
        endcase
    endfunction
endmodule

`ifdef TEST_instruction_decoder
module instruction_decoder_tb;
    Word in;
    wire Instruction out;

    instruction_decoder decoder(in, out);

    initial begin
        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    `define ADDI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b0010011}
    `define ADD(RD, RS1, RS2) {7'b0, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
    initial begin
        in = `ADDI(1, 0, -10);
        #1 Instruction_display(out);
        in = `ADD(1, 11, 10);
        #1 Instruction_display(out);
    end
endmodule
`endif

`endif