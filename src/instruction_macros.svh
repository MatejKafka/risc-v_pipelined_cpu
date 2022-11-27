//
// This file contains a set of macros to create both RISC-V instructions for testing the decoder,
// and parsed instructions for testing the core of the CPU.
//

`ifndef PACKAGE_INSTRUCTION_MACROS
`define PACKAGE_INSTRUCTION_MACROS
`include "instruction_types.svh"


// raw binary RISC-V instructions
`define R_LUI(RD, IMM) {{32'(IMM)}[31:12], 5'(RD), 7'b0110111}
`define R_AUIPC(RD, IMM) {{32'(IMM)}[31:12], 5'(RD), 7'b0010111}
`define R_XORI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b100, 5'(RD), 7'b0010011}
`define R_ADDI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b0010011}
`define R_ADD(RD, RS1, RS2) {7'b0, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define R_SUB(RD, RS1, RS2) {7'b0100000, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define R_AND(RD, RS1, RS2) {7'b0000000, 5'(RS2), 5'(RS1), 3'b111, 5'(RD), 7'b0110011}

`define R_JAL(RD, IMM) {{21'(IMM)}[20], {21'(IMM)}[10:1], {21'(IMM)}[11], {21'(IMM)}[19:12], 5'(RD), 7'b1101111}
`define R_JALR(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b1100111}
`define R_BRANCH(FUNCT3, RS1, RS2, IMM) { \
        {13'(IMM)}[12], {13'(IMM)}[10:5], 5'(RS2), 5'(RS1), 3'(FUNCT3), \
        {13'(IMM)}[4:1], {13'(IMM)}[11], 7'b1100011}
`define R_BEQ(RS1, RS2, IMM) `R_BRANCH(3'b000, RS1, RS2, IMM)
`define R_BNE(RS1, RS2, IMM) `R_BRANCH(3'b001, RS1, RS2, IMM)
`define R_BLT(RS1, RS2, IMM) `R_BRANCH(3'b100, RS1, RS2, IMM)
`define R_BGE(RS1, RS2, IMM) `R_BRANCH(3'b101, RS1, RS2, IMM)

`define R_LW(RD, BASE, IMM) {12'(IMM), 5'(BASE), 3'b010, 5'(RD), 7'b0000011}
`define R_SW(SRC, BASE, IMM) {{12'(IMM)}[11:5], 5'(SRC), 5'(BASE), 3'b010, {12'(IMM)}[4:0], 7'b0100011}

`define R_NOP `R_ADDI(0, 0, 0)
`define R_EBREAK {12'b000000000001, 13'b0, 7'b1110011}


// macros to create parsed instructions directly
`define I_REG(OP, RD, RS1, RS2) Instruction'{'{0, 0, BC_NEVER, RD_ALU, ALU1_RS1, ALU2_RS2}, OP, C_NONE, 0, RD, RS1, RS2}
`define I_IMM(OP, RD, RS1, IMM) Instruction'{'{0, 0, BC_NEVER, RD_ALU, ALU1_RS1, ALU2_IMM}, OP, C_NONE, IMM, RD, RS1, 0}
`define I_NOP I_NOP
`define I_EBREAK                Instruction'{'{1, 0, BC_NEVER, RD_NONE, ALU1_RS1, ALU2_IMM}, ADD, C_NONE, 0, 0, 0, 0}


`endif