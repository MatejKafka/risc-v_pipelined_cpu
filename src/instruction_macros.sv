//
// This file contains a set of macros to create raw RISC-V instructions for testing the decoder.
//

`ifndef PACKAGE_INSTRUCTION_MACROS
`define PACKAGE_INSTRUCTION_MACROS

`define ADDI(RD, RS1, IMM) {12'(IMM), 5'(RS1), 3'b000, 5'(RD), 7'b0010011}
`define ADD(RD, RS1, RS2) {7'b0, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define SUB(RD, RS1, RS2) {7'b0100000, 5'(RS2), 5'(RS1), 3'b000, 5'(RD), 7'b0110011}
`define AND(RD, RS1, RS2) {7'b0000000, 5'(RS2), 5'(RS1), 3'b111, 5'(RD), 7'b0110011}
`define EBREAK {12'b000000000001, 13'b0, 7'b1110011}

`endif