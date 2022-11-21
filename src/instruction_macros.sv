//
// This file contains a set of macros to create both RISC-V instructions for testing the decoder,
// and parsed instructions for testing the core of the CPU.
//

`ifndef PACKAGE_INSTRUCTION_MACROS
`define PACKAGE_INSTRUCTION_MACROS

// raw binary RISC-V instructions
`define ADDI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b0010011}
`define ADD(RD, RS1, RS2) {7'b0, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define SUB(RD, RS1, RS2) {7'b0100000, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define AND(RD, RS1, RS2) {7'b0000000, 5'(RS2), 5'(RS1), 3'b111, 5'(RD), 7'b0110011}
`define EBREAK {12'b000000000001, 13'b0, 7'b1110011}

// macros to create parsed instructions directly
`define D_REG(OP, RD, RS1, RS2) '{OP, RD, RS1, FALSE, RS2, 0, FALSE}
`define D_IMM(OP, RD, RS1, IMM_) '{OP, RD, RS1, TRUE, 0, IMM_, FALSE}
`define D_EBREAK '{AluOp'(0), 0, 0, FALSE, 0, 0, TRUE}

`endif