//
// This file contains a set of macros to create both RISC-V instructions for testing the decoder,
// and parsed instructions for testing the core of the CPU.
//

`ifndef PACKAGE_INSTRUCTION_MACROS
`define PACKAGE_INSTRUCTION_MACROS
`include "instruction_types.sv"

// raw binary RISC-V instructions
`define R_ADDI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b0010011}
`define R_ADD(RD, RS1, RS2) {7'b0, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define R_SUB(RD, RS1, RS2) {7'b0100000, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define R_AND(RD, RS1, RS2) {7'b0000000, 5'(RS2), 5'(RS1), 3'b111, 5'(RD), 7'b0110011}
`define R_JAL(RD, IMM) {{21'(IMM)}[20], {21'(IMM)}[10:1], {21'(IMM)}[11], {21'(IMM)}[19:12], 5'(RD), 7'b1101111}
`define R_BEQ(RS1, RS2, IMM) { \
        {13'(IMM)}[12], {13'(IMM)}[10:5], 5'(RS2), 5'(RS1), 3'b000, \
        {13'(IMM)}[4:1], {13'(IMM)}[11], 7'b1100011}
`define R_BNE(RS1, RS2, IMM) { \
        {13'(IMM)}[12], {13'(IMM)}[10:5], 5'(RS2), 5'(RS1), 3'b001, \
        {13'(IMM)}[4:1], {13'(IMM)}[11], 7'b1100011}
`define R_NOP `R_ADDI(0, 0, 0)
`define R_EBREAK {12'b000000000001, 13'b0, 7'b1110011}

// macros to create parsed instructions directly
`define D_REG(OP, RD, RS1, RS2) Instruction'{IF_NONE,        OP, RD, RS1, RS2, 0}
`define D_IMM(OP, RD, RS1, IMM) Instruction'{IF_ALU_USE_IMM, OP, RD, RS1, 0, IMM}
`define D_NOP `D_IMM(ADD, 0, 0, 0)
`define D_EBREAK                Instruction'{IF_IS_EBREAK, AluOp'(0), 0, 0, 0, 0}

`endif