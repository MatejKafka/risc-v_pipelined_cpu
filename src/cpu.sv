`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.sv"
`include "alu.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

typedef struct packed {
    logic decoder;
    logic alu;
} CpuError;

module cpu(
        input clk, reset, output stop, output CpuError error,
        input Word rom_data, output RomAddress rom_address,
        input Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data);

    // TODO: ...
    assign ram_address = 0;
    assign ram_write_enable = 0;
    assign ram_write_data = 0;

    reg should_branch;
    RomAddress next_pc;
    wire Instruction instruction;
    wire InstructionFlags flags;
    wire decoder_error;
    // TODO: check what happens with immediate >= 16bits here, make sure the output is correctly trimmed
    program_counter program_counter(clk, reset, should_branch, RomAddress'(instruction.immediate), rom_address, next_pc);
    instruction_decoder decoder(decoder_error, rom_data, instruction);

    wire Word alu_src1, alu_src2, alu_out;
    wire alu_error, alu_is_out_zero;
    alu alu(alu_error, instruction.alu_op, alu_src1, alu_src2, alu_out, alu_is_out_zero);

    wire Word reg_in, reg_out1, reg_out2;
    register_file register_file(clk, reset,
        instruction.rd, instruction.rs1, instruction.rs2,
        alu_out, reg_out1, reg_out2);

    assign flags = instruction.flags;
    assign should_branch = flags.is_branch & (flags.alu_should_be_zero == alu_is_out_zero);

    assign reg_in = flags.next_pc_to_rd ? Word'(next_pc) : alu_out;
    assign alu_src1 = reg_out1;
    assign alu_src2 = flags.alu_use_imm ? Word'(instruction.immediate) : reg_out2;

    assign stop = flags.is_ebreak;
    assign error = '{decoder_error, alu_error};
endmodule


`ifdef TEST_cpu
`include "instruction_macros.sv"
module cpu_tb;
    reg clk, reset;
    wire stop;
    Bool error_enabled;
    wire CpuError error;
    wire RomAddress rom_address;
    Word rom_data;

    Word unused_ram_data = 0;
    wire RamAddress unused_ram_address;
    wire unused_ram_write_enable;
    wire Word unused_ram_write_data;

    cpu cpu(clk, reset, stop, error,
        rom_data, rom_address,
        unused_ram_data, unused_ram_address, unused_ram_write_enable, unused_ram_write_data);


    Word rom_simulated[16] = '{
        `R_ADDI(1, 0, 10),
        `R_ADDI(1, 1, 50),
        `R_ADDI(2, 1, 5),
        `R_ADDI(2, 2, -1),
        `R_BNE (2, 1, -13'd4),
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
        `R_EBREAK
    };
    assign rom_data = reset ? 0 : rom_simulated[rom_address[5:2]];


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