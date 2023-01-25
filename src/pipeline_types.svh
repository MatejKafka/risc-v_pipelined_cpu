`ifndef PACKAGE_PIPELINE_TYPES
`define PACKAGE_PIPELINE_TYPES
`include "types.svh"
`include "instruction_types.svh"

typedef enum logic[1:0] {
    AF_REG = 0, /** Value from register. */
    AF_MEM = 1, /** Value from MEM forwarding. */
    AF_WB = 2 /** Value from RD writeback forwarding. */
} AluForwarding;


typedef struct packed {
    logic is_ebreak;
    logic should_branch;
    RomAddress branch_target;
    RomAddress pc; // not needed, useful for tracing
} MemIfReg;

function MemIfReg MemIfReg_NOP(MemIfReg in);
    return '{0, 0, in.branch_target, in.pc};
endfunction


typedef struct packed {
    UWord rom_data;
    RomAddress pc;
    RomAddress next_pc;
} IfIdReg;

function IfIdReg IfIdReg_NOP(IfIdReg in);
    // replace the data from ROM with a NOP; I don't like this, but I did not find any nicer way
    return '{R_NOP, in.pc, in.next_pc};
endfunction


typedef struct packed {
    // decoder error is routed through the pipeline so that flushed instructions don't trigger externally visible errors
    logic decoder_error;
    InstructionControl control;
    Immediate immediate;
    Word reg_out1;
    Word reg_out2;
    AluForwarding fwd1;
    AluForwarding fwd2;
    RegAddress rd;
    RomAddress pc;
    RomAddress next_pc;
} IdExReg;

function IdExReg IdExReg_NOP(IdExReg in);
    return '{0, NOP_CONTROL, in.immediate, in.reg_out1, in.reg_out2, in.fwd1, in.fwd2, in.rd, in.pc, in.next_pc};
endfunction


typedef struct packed {
    logic decoder_error;
    logic alu_error;
    InstructionControl control;
    Word alu_out;
    logic cmp_out;
    Word ram_write_data;
    RegAddress rd;
    RomAddress pc; // not needed, useful for tracing
    RomAddress next_pc;
} ExMemReg;

function ExMemReg ExMemReg_NOP(ExMemReg in);
    return '{0, 0, NOP_CONTROL, in.alu_out, in.cmp_out, in.ram_write_data, in.rd, in.pc, in.next_pc};
endfunction


typedef struct packed {
    logic write_enable;
    RegAddress write_address;
    Word write_data;
    RomAddress pc; // not needed, useful for tracing
} WbReg;

function WbReg WbReg_NOP(WbReg in);
    return '{0, in.write_address, in.write_data, in.pc};
endfunction

`endif