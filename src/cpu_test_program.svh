`ifndef PACKAGE_CPU_TEST_PROGRAM
`define PACKAGE_CPU_TEST_PROGRAM
`include "types.svh"
`include "instruction_macros.svh"

// this is used in `cpu.sv` and `cpu_pipelined.sv`
UWord cpu_test_program[26] = '{
    /* 00 */ `R_ADDI(1, 0, 10),
    /* 04 */ `R_ADDI(1, 1, 50),
    /* 08 */ `R_ADDI(2, 1, 5),
    /* 0C */ `R_AUIPC(11, 32'h7FFFF000), // r11 should contain 2147479564 (0x7FFFF00C)
    /* 10 */ `R_ADDI(2, 2, -1),
    /* 14 */ `R_BLT (1, 2, -13'd4),
    /* 18 */ `R_BEQ (2, 1, 13'd8),
    /* 1C */ `R_NOP, // this should be skipped
    /* 20 */ `R_ADDI(3, 2, 1),
    /* 24 */ `R_ADDI(4, 3, 0),
    /* 28 */ `R_ADDI(4, 4, 1),
    /* 2C */ `R_SUB (5, 4, 1),
    /* 30 */ `R_JAL (8, 21'h8),
    /* 34 */ `R_JAL (0, 21'h10), // this should be skipped the first time
    /* 38 */ `R_AUIPC(12, 32'h0), // store PC to r12
    /* 3C */ `R_JALR(11, 12, -12'd4), // jump to r12 - 4
    /* 40 */ `R_NOP, // this should be skipped
    /* 44 */ `R_AND (6, 1, 2),
    /* 48 */ `R_ADDI(7, 2, -5),
    /* 4C */ `R_SW  (1, 1, -12'h20),
    /* 50 */ `R_LW  (9, 0, 12'h1c),
    /* 54 */ `R_ADDI(9, 9, 1), // increment the LW result to test pipeline stalling
             // try to store -2 (0xFFFFFFFE) into r10
    /* 58 */ `R_LUI (10, 32'hFFFFF000),
    /* 5C */ `R_XORI(10, 0, 'hFFE),
    /* 60 */ `R_SW  (10, 0, 0),
    /* 64 */ `R_EBREAK
};

`endif