`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.svh"
`include "utils.svh"
`include "ram.sv"
`include "alu.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

typedef struct packed {
    logic decoder;
    logic alu;
} CpuError;

/**
 * The main CPU module, connecting together all submodules.
 *
 * It implements all instructions from RV32I Base Instruction Set, except for:
 *  - load/store instructions for byte and short (the CPU only supports Word-aligned memory access with Word-sized values)
 *  - JALR  (useful, but would require reworking my program counter to accept the full PC from outside, instead of just the immediate)
 *  - FENCE (not useful, the CPU only has a single core/thread)
 *  - ECALL (not useful, the CPU doesn't have privilege levels)
 */
module cpu(
        input clk, reset, output stop, output CpuError error,
        input UWord rom_data, output RomAddress rom_address,
        input  Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data);

    reg should_branch;
    RomAddress pc, next_pc;
    Instruction instruction;
    InstructionFlags flags;
    logic decoder_error;
    program_counter program_counter(clk, reset, should_branch, RomAddress'(instruction.immediate), pc, next_pc);
    instruction_decoder decoder(decoder_error, rom_data, instruction);

    Word alu_src1, alu_src2, alu_out;
    logic alu_error, alu_is_out_zero;
    alu alu(alu_error, instruction.alu_op, alu_src1, alu_src2, alu_out, alu_is_out_zero);

    Word reg_in, reg_out1, reg_out2;
    register_file register_file(clk, reset,
        instruction.rd, instruction.rs1, instruction.rs2,
        reg_in, reg_out1, reg_out2);

    assign rom_address = pc;

    assign flags = instruction.flags;
    assign should_branch = flags.is_branch & (flags.alu_should_be_zero == alu_is_out_zero);

    assign reg_in = flags.ram_read_to_rd ? ram_data :
                    flags.next_pc_to_rd ? Word'(next_pc) :
                    alu_out;
    assign alu_src1 = flags.pc_to_alu_src1 ? Word'(pc) : reg_out1;
    assign alu_src2 = flags.alu_use_imm ? Word'(instruction.immediate) : reg_out2;

    assign ram_write_enable = flags.ram_write;
    //                  \/ this ternary is here just to clean up the RAM debug logs, it's not necessary
    assign ram_address = flags.ram_read_to_rd | flags.ram_write ? RamAddress'(alu_out) : 0;
    //                     \/ same here
    assign ram_write_data = flags.ram_write ? reg_out2 : 0;

    assign stop = flags.is_ebreak;
    assign error = '{decoder_error, alu_error};
endmodule


`ifdef TEST_cpu
`include "instruction_macros.svh"
module cpu_tb;
    reg clk, reset;
    logic error_enabled;
    logic stop;
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
    UWord rom_simulated[22] = '{
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
        `R_JAL (8, 21'd8),
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
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
    end

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
            #5 clk <= !stop;
    end

    always @ (posedge stop) begin
        #10; // delay to let the last register write finish
        cpu.register_file.dump();
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