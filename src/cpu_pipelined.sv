`ifndef PACKAGE_CPU_PIPELINED
`define PACKAGE_CPU_PIPELINED
`include "types.svh"
`include "utils.svh"
`include "ram.sv"
`include "alu.sv"
`include "alu_comparator.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

typedef struct packed {
    logic decoder;
    logic alu;
} CpuError;


typedef struct packed {
    logic should_branch;
    RomAddress branch_target;
} MemIfReg;

typedef struct packed {
    UWord rom_data;
    RomAddress pc;
    RomAddress next_pc;
} IfIdReg;

typedef struct packed {
    InstructionControl control;
    Immediate immediate;
    Word reg_out1;
    Word reg_out2;
    RegAddress rd;
    RomAddress pc;
    RomAddress next_pc;
} IdExReg;

typedef struct packed {
    // TODO: only forward the required control signals
    InstructionControl control;
    Word alu_out;
    logic cmp_out;
    Word ram_write_data;
    RegAddress rd;
    RomAddress next_pc;
} ExMemReg;

typedef struct packed {
    logic is_ebreak;
    logic write_enable;
    RegAddress write_address;
    Word write_data;
} MemIdReg;

module stage_instruction_fetch(
        input clk, reset,
        input MemIfReg if_in, output IfIdReg out,
        input UWord rom_data, output RomAddress rom_address);

    RomAddress pc, next_pc;
    program_counter program_counter(clk, reset, if_in.should_branch, if_in.branch_target, pc, next_pc);

    assign rom_address = pc;
    assign out = '{rom_data: rom_data, pc: pc, next_pc: next_pc};
endmodule

module stage_instruction_decode(
        input clk, reset, output decoder_error, output cpu_stop,
        input MemIdReg wb, input IfIdReg if_, output IdExReg out);

    Instruction instruction;
    instruction_decoder decoder(decoder_error, if_.rom_data, instruction);

    Word reg_out1, reg_out2;
    register_file #(.USE_FORWARDING(0)) register_file(clk, reset, wb.write_enable,
        wb.write_address, instruction.rs1, instruction.rs2,
        wb.write_data, reg_out1, reg_out2);

    // we only output cpu_stop when the EBREAK instruction reaches the write-back stage
    // this way, all previous register and memory writes finish, before the signal is raised
    assign cpu_stop = wb.is_ebreak;

    assign out = '{
        pc: if_.pc, next_pc: if_.next_pc,
        reg_out1: reg_out1, reg_out2: reg_out2,
        control: instruction.control, immediate: instruction.immediate, rd: instruction.rd};
endmodule

module stage_execute(
        output alu_error,
        input IdExReg id, output ExMemReg out);

    logic cmp_out;
    Word cmp_src1, cmp_src2;
    // always use rs1/rs2 with comparator ops
    alu_comparator cmp(id.control.cmp_op, id.reg_out1, id.reg_out2, cmp_out);

    Word alu_src1, alu_src2, alu_out;
    alu alu(alu_error, id.control.alu_op, alu_src1, alu_src2, alu_out);

    always @ (*) case (id.control.alu_src1)
        ALU1_RS1:  alu_src1 = id.reg_out1;
        ALU1_PC:   alu_src1 = Word'(id.pc);
        ALU1_ZERO: alu_src1 = 0;
        default: alu_src1 = 0; //$fatal();
    endcase

    always @ (*) case (id.control.alu_src2)
        ALU2_RS2: alu_src2 = id.reg_out2;
        ALU2_IMM: alu_src2 = id.immediate;
    endcase

    assign out = '{
        alu_out: alu_out, cmp_out: cmp_out,
        control: id.control, ram_write_data: id.reg_out2, rd: id.rd, next_pc: id.next_pc};
endmodule

module stage_memory(
        input reset,
        input Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data,
        input ExMemReg ex, output MemIdReg out_wb, output MemIfReg out_if);

    assign ram_write_data = ex.ram_write_data;
    assign ram_write_enable = ex.control.ram_write;
    assign ram_address = RamAddress'(ex.alu_out);

    Word reg_write_data;
    always @ (*) case (ex.control.rd_src)
        RD_ALU:     reg_write_data = ex.alu_out;
        RD_RAM_OUT: reg_write_data = ex.ram_write_data;
        RD_NEXT_PC: reg_write_data = Word'(ex.next_pc);
        RD_NONE:    reg_write_data = ex.alu_out; // this is handled below
    endcase

    logic should_branch;
    always @ (*) case (ex.control.branch_condition)
        BC_NEVER: should_branch = FALSE;
        BC_ALWAYS: should_branch = TRUE;
        BC_CMP_TRUE: should_branch = ex.cmp_out;
        BC_CMP_FALSE: should_branch = !ex.cmp_out;
    endcase

    assign out_if = '{
        should_branch: should_branch,
        branch_target: RomAddress'(ex.alu_out)};

    assign out_wb = '{
        is_ebreak: ex.control.is_ebreak,
        write_enable: ex.control.rd_src != RD_NONE,
        write_address: ex.rd,
        write_data: reg_write_data};
endmodule

/**
 * The main CPU module, connecting together all submodules.
 *
 * It implements all instructions from RV32I Base Instruction Set, except for:
 *  - load/store instructions for byte and short (the CPU only supports Word-aligned memory access with Word-sized values)
 *  - FENCE (not useful, the CPU only has a single core/thread)
 *  - ECALL (not useful, the CPU doesn't have privilege levels)
 */
module cpu(
        input clk, reset, output stop, output CpuError error,
        input UWord rom_data, output RomAddress rom_address,
        input  Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data);

    MemIfReg if_in;
    IfIdReg if_out;
    stage_instruction_fetch stage_if(clk, reset, if_in, if_out, rom_data, rom_address);

    IfIdReg id_in_if;
    MemIdReg id_in_wb;
    IdExReg id_out;
    stage_instruction_decode stage_id(clk, reset, error.decoder, stop, id_in_wb, id_in_if, id_out);

    IdExReg ex_in;
    ExMemReg ex_out;
    stage_execute stage_ex(error.alu, ex_in, ex_out);

    ExMemReg mem_in;
    MemIdReg mem_out_wb;
    MemIfReg mem_out_if;
    stage_memory stage_mem(reset, ram_data, ram_address, ram_write_enable, ram_write_data, mem_in, mem_out_wb, mem_out_if);

    assign if_in = mem_out_if;
    assign id_in_if = if_out;
    assign id_in_wb = mem_out_wb;
    assign ex_in = id_out;
    assign mem_in = ex_out;
    // always @ (posedge clk) begin
    //     if_in <= mem_out_if;
    //     id_in_if <= if_out;
    //     id_in_wb <= mem_out_wb;
    //     ex_in <= id_out;
    //     mem_in <= ex_out;
    // end
endmodule


`ifdef TEST_cpu_pipelined
`include "instruction_macros.svh"
module cpu_pipelined_tb;
    logic clk, reset;
    logic error_enabled;
    logic stop, masked_stop;
    CpuError error;

    RomAddress rom_address;
    UWord rom_data;

    Word ram_data;
    RamAddress ram_address;
    logic ram_write_enable;
    Word ram_write_data;

    ram ram(clk, reset, ram_write_enable, ram_address, ram_write_data, ram_data);
    cpu cpu(clk, reset, stop, error,
        rom_data, rom_address,
        ram_data, ram_address, ram_write_enable, ram_write_data);


    // for unit testing, we want to avoid using ROM, so we'll use a hardcoded list of instructions
    UWord rom_simulated[25] = '{
        `R_ADDI(1, 0, 10),
        `R_ADDI(1, 1, 50),
        `R_ADDI(2, 1, 5),
        `R_AUIPC(11, 32'h7FFFF000), // r11 should contain 2147479564 (0x7FFFF00C)
        `R_ADDI(2, 2, -1),
        `R_BLT (1, 2, -13'd4),
        `R_BEQ (2, 1, 13'd8),
        `R_NOP, // this should be skipped
        `R_ADDI(3, 2, 1),
        `R_ADDI(4, 3, 0),
        `R_ADDI(4, 4, 1),
        `R_SUB (5, 4, 1),
        `R_JAL (8, 21'h8),
        `R_JAL (0, 21'h10), // this should be skipped the first time
        `R_AUIPC(12, 32'h0), // store PC to r12
        `R_JALR(11, 12, -12'd4), // jump to r12 - 4
        `R_NOP, // this should be skipped
        `R_AND (6, 1, 2),
        `R_ADDI(7, 2, -5),
        `R_SW  (1, 1, -12'h20),
        `R_LW  (9, 0, 12'h1c),
        // try to store -2 (0xFFFFFFFE) into r10
        `R_LUI (10, 32'hFFFFF000),
        `R_XORI(10, 0, 'hFFE),
        `R_SW  (10, 0, 0),
        `R_EBREAK
    };

    assign rom_data = rom_simulated[rom_address[6:2]];


    initial begin
        $dumpfile("cpu_pipelined.vcd");
        $dumpvars(0, cpu_pipelined_tb);
    end

    assign masked_stop = stop & !reset;

    initial clk = 0;
    initial reset = 1;
    initial error_enabled = FALSE;
    // block error messages during the initial reset
    initial SUPRESS_ERRORS = TRUE;
    always @ (posedge clk) begin
        reset <= 0;
        SUPRESS_ERRORS <= FALSE;
        error_enabled <= TRUE;
    end
    always begin
        #5 clk <= 0;
        // prevent clock pulse when the CPU signals a stop
        #5 clk <= !masked_stop;
    end

    always @ (posedge masked_stop) begin
        #10; // delay to let the last register write finish
        cpu.stage_id.register_file.dump();
        ram.dump();
        $finish();
    end

    always @ (posedge (|error & error_enabled)) begin
        // supress errors while the initial reset is active
        if (!(|error) || !reset) begin
            $display("error: %0d", error);
            $finish();
        end
    end
endmodule
`endif

`endif