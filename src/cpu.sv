`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.svh"
`include "utils.svh"
`include "ram.sv"
`include "alu.sv"
`include "alu_comparator.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

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

    logic decoder_error;
    Instruction instruction;
    InstructionControl control;
    instruction_decoder decoder(decoder_error, rom_data, instruction);

    Word cmp_src1, cmp_src2;
    logic cmp_out;
    alu_comparator cmp(control.cmp_op, cmp_src1, cmp_src2, cmp_out);

    logic alu_error;
    Word alu_src1, alu_src2, alu_out;
    alu alu(alu_error, control.alu_op, alu_src1, alu_src2, alu_out);

    logic reg_write_enable;
    Word reg_in, reg_out1, reg_out2;
    register_file register_file(clk, reset, reg_write_enable,
        instruction.rd, instruction.rs1, instruction.rs2,
        reg_in, reg_out1, reg_out2);

    logic should_branch;
    RomAddress pc, next_pc;
    program_counter program_counter(clk, reset, 0, should_branch, RomAddress'(alu_out), pc, next_pc);


    assign rom_address = pc;

    assign control = instruction.control;

    /* should_branch */ always @ (*) case (control.branch_condition)
        BC_NEVER: should_branch = FALSE;
        BC_ALWAYS: should_branch = TRUE;
        BC_CMP_TRUE: should_branch = cmp_out;
        BC_CMP_FALSE: should_branch = !cmp_out;
    endcase

    // always use rs1/rs2 with comparator ops
    assign cmp_src1 = reg_out1;
    assign cmp_src2 = reg_out2;

    /* reg_in */ always @ (*) case (control.rd_src)
        RD_ALU:     reg_in = alu_out;
        RD_RAM_OUT: reg_in = ram_data;
        RD_NEXT_PC: reg_in = Word'(next_pc);
        RD_NONE:    reg_in = alu_out; // this is handled below
    endcase
    assign reg_write_enable = control.rd_src != RD_NONE;

    /* alu_src1 */ always @ (*) case (control.alu_src1)
        ALU1_RS1:  alu_src1 = reg_out1;
        ALU1_PC:   alu_src1 = Word'(pc);
        ALU1_ZERO: alu_src1 = 0;
        default: $fatal();
    endcase

    /* alu_src2 */ always @ (*) case (control.alu_src2)
        ALU2_RS2: alu_src2 = reg_out2;
        ALU2_IMM: alu_src2 = instruction.immediate;
    endcase

    assign ram_write_enable = control.ram_write;
    assign ram_address = RamAddress'(alu_out);
    assign ram_write_data = reg_out2;

    assign stop = control.is_ebreak;
    assign error = '{decoder_error, alu_error};

    task dump_registers();
        register_file.dump();
    endtask
endmodule


`ifdef TEST_cpu
`include "cpu_test_program.svh"
module cpu_tb;
    reg clk, reset;
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
    assign rom_data = cpu_test_program[rom_address[6:2]];


    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
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
        cpu.dump_registers();
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