`ifndef PACKAGE_CPU_PIPELINED
`define PACKAGE_CPU_PIPELINED
`include "types.svh"
`include "utils.svh"
`include "ram.sv"
`include "alu.sv"
`include "alu_comparator.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"
`include "pipeline_stages.svh"

/**
 * The main CPU module, connecting together all submodules. The external interface is exactly the same
 * as for the scalar cpu in `cpu.sv`.
 *
 * It implements all instructions from RV32I Base Instruction Set, except for:
 *  - load/store instructions for byte and short (the CPU only supports Word-aligned memory access with Word-sized values)
 *  - FENCE (not useful, the CPU only has a single core/thread)
 *  - ECALL (not useful, the CPU doesn't have privilege levels)
 *
 *
 * Implementation notes:
 * =====================
 *
 * Stages of the pipeline are implemented in `pipeline_stages.svh`, interstage registers and related types
 * are defined in `pipeline_types.svh`.
 *
 * ERROR SIGNALLING
 * Decoder and ALU error signals are sent through the pipeline and emitted from MEM. When the pipeline is flushed,
 * error signals are zeroed together with the other control signals. This allows the initial stages of the pipeline
 * to contain invalid instructions (e.g. after a branch) without singalling an error, as long as they're flushed
 * before any effects become visible.
 *
 * BRANCHES / EBREAK
 * `should_branch` and `is_ebreak` signals are routed from MEM to IF. When an instruction with one of these bits set
 * is sent back to IF, the pipeline is flushed by zeroing out control signals for instructions in the IF/ID, ID/EX and
 * EX/MEM interstage registers. When EBREAK reaches IF after passing through the pipeline, all side-effects
 * of previous instructions are already applied, and thanks to the flush, no side-effects are applied for the follow-up
 * instructions (typically invalid)
 *
 * INITIAL CPU RESET
 * When `reset` is set at positive clock edge, all memories (registers, RAM, program counter) are zeroed, and all
 * interstage registers are flushed by zeroing control bits. The reset is finished in 1 cycle, same as the scalar CPU.
 *
 * FORWARDING
 * Forwards are computed in ID in the hazard unit, together with stalls, and forwarding control signals are passed
 * to EX through the ID/EX interstage register.
 *
 * STALLS
 * Only necessary when using LW result in the next instruction. Stall is implemented by blocking program counter
 * from updating on the next cycle, holding the IF/ID interstage register value, and zeroing control signals
 * on the instruction passed through the ID/EX register, turning it into a NOP-like instruction.
 */
module cpu_pipelined(
        input clk, reset, output stop, output CpuError error,
        input UWord rom_data, output RomAddress rom_address,
        input  Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data);

    logic stall;

    // IF
    MemIfReg if_in;
    IfIdReg if_out;
    stage_instruction_fetch stage_if(clk, reset, stall, stop, if_in, if_out, rom_data, rom_address);

    // ID
    IfIdReg id_in_if;
    WbReg id_in_wb;
    IdExReg id_out;
    // info buses from later pipeline stages, connected to the hazard unit
    StageHazardInfo ex_hazard, mem_hazard;
    stage_instruction_decode stage_id(
        clk, reset, stall,
        id_in_wb, id_in_if, id_out,
        ex_hazard, mem_hazard);

    // EX
    IdExReg ex_in;
    ExMemReg ex_out;
    Word mem_fwd, wb_fwd;
    stage_execute stage_ex(mem_fwd, wb_fwd, ex_in, ex_out);

    // MEM
    ExMemReg mem_in;
    WbReg mem_out_wb;
    MemIfReg mem_out_if;
    stage_memory stage_mem(reset, error.decoder, error.alu,
        ram_data, ram_address, ram_write_enable, ram_write_data,
        mem_in, mem_out_wb, mem_out_if);


    // forwarded register writes
    // this does not match the way it's done it QtRVSim, where the forwarding is done after a JAL/JALR mux with PC+4,
    //  but since we always flush the pipeline after a jump, it shouldn't matter that we use ALU output directly
    assign mem_fwd = mem_in.alu_out;
    assign wb_fwd = id_in_wb.write_data;

    // send hazard-relevant signals from EX and MEM stages to the hazard unit
    assign ex_hazard = '{ex_in.control.rd_src, ex_in.rd};
    assign mem_hazard = '{mem_in.control.rd_src, mem_in.rd};

    logic flush_pipeline;
    assign flush_pipeline = if_in.should_branch || if_in.is_ebreak || reset;


    // PC already has an internal register, do not delay branch signals
    assign if_in = mem_out_if;
    // advance the pipeline on each clock
    always @ (posedge clk) begin
        // prioritize flushing pipeline over stalling; if stalling, hold value from the previous cycle
        /*  IF/ID */ id_in_if <= flush_pipeline ? IfIdReg_NOP(if_out) : stall ? id_in_if : if_out;
        /*  ID/EX */ ex_in    <= flush_pipeline || stall ? IdExReg_NOP(id_out) : id_out;
        /* EX/MEM */ mem_in   <= flush_pipeline ? ExMemReg_NOP(ex_out) : ex_out;
        // only flush MEM/WB on reset, not for branches/EBREAK, we want them to propagate to WB (e.g. for JAL/JALR)
        /* MEM/WB */ id_in_wb <=          reset ? WbReg_NOP(mem_out_wb) : mem_out_wb;
    end


    // pull out the PC wires for debugging; otherwise unused
    RomAddress pc_if, pc_id, pc_ex, pc_mem, pc_wb;
    assign pc_if = if_out.pc;
    assign pc_id = id_out.pc;
    assign pc_ex = ex_out.pc;
    assign pc_mem = mem_out_wb.pc;
    assign pc_wb = id_in_wb.pc;

    task dump_registers();
        stage_id.register_file.dump();
    endtask
endmodule


`ifdef TEST_cpu_pipelined
`include "cpu_test_program.svh"
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
    cpu_pipelined cpu(clk, reset, stop, error,
        rom_data, rom_address,
        ram_data, ram_address, ram_write_enable, ram_write_data);


    // for unit testing, we want to avoid using ROM, so we'll use a hardcoded list of instructions
    assign rom_data = cpu_test_program[rom_address[6:2]];


    initial begin
        $dumpfile("cpu_pipelined.vcd");
        $dumpvars(0, cpu_pipelined_tb);
    end

    assign masked_stop = stop & !reset;

    // block error messages; since we propagate error bits through the pipeline and usually discard them,
    //  we'd have random error messages printed after branches and EBREAK
    initial SUPRESS_ERRORS = TRUE;

    initial clk = 0;
    initial reset = 1;
    initial error_enabled = FALSE;
    always @ (posedge clk) begin
        reset <= 0;
        error_enabled <= TRUE;
    end
    always begin
        #5 clk <= 0;
        // prevent clock pulse when the CPU signals a stop
        #5 clk <= !masked_stop;
    end

    always @ (posedge masked_stop) begin
        #10; // delay to let the last register write finish
        cpu.dump_registers();
        ram.dump();
        $finish();
    end

    always @ (posedge (|error & error_enabled)) begin
        // supress errors while the initial reset is active
        if (!(|error) || !reset) begin
            $display("error: %0d, time: %0t", error, $time);
            $finish();
        end
    end
endmodule
`endif

`endif