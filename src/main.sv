`ifndef PACKAGE_MAIN
`define PACKAGE_MAIN
`include "ram.sv"
`include "rom.sv"
`include "cpu.sv"

module clock(output reg clk);
    initial clk = 0;
    // one CPU cycle each 10 time units
    always begin
        #5 clk <= 0;
        #5 clk <= 1;
    end
endmodule

/**
 * The main module, connecting the CPU with RAM and ROM.
 *
 * @param clk: Driving clock signal, all clocked updates (register/memory writes, program
 *      counter updates,...) are done at the positive edge of clk.
 * @param reset: When this pin is set on a positive `clk` edge, the CPU resets.
 * @param cpu_stop: When the CPU encounters an EBREAK instruction, this pin is set to 1.
 *      You should stop the `clk` signal after this signal is raised.
 * @param cpu_error: Indicates when a CPU component encounters an error,
 *      typically caused by attempting to execute an invalid instruction.
 */
module computer(input clk, reset, output cpu_stop, output CpuError cpu_error);
    RomAddress rom_address;
    UWord rom_out;
    rom rom(rom_address, rom_out);

    RamAddress ram_address;
    logic ram_write_enable;
    Word ram_out, ram_in;
    ram ram(clk, reset, ram_write_enable, ram_address, ram_in, ram_out);

    cpu cpu(clk, reset, cpu_stop, cpu_error,
            rom_out, rom_address,
            ram_out, ram_address, ram_write_enable, ram_in);
endmodule


`ifdef TEST_main
module main_tb;
    logic reset, error_enabled;
    logic clk, cpu_clk, cpu_stop, error;
    CpuError cpu_error;

    clock clock(clk);
    computer computer(cpu_clk, reset, cpu_stop, cpu_error);

    // supress errors while the initial reset is active
    assign error = cpu_error != 0 & !reset;
    // hold the CPU clock on 1 when it wants to stop or encounters an error to prevent executing more instructions
    assign cpu_clk = clk | cpu_stop | error;


    initial begin
        $dumpfile("main.vcd");
        $dumpvars(0, main_tb);
    end

    // block errors during the initial reset (there will most likely be some,
    //  given that the CPU is executing instructions from a random memory address,
    //  which the program counter happened to contain on startup)
    initial SUPRESS_ERRORS = 1;
    initial error_enabled = 0;
    // start a CPU reset
    initial reset = 1;
    // wait for 1 clock cycle; now the CPU should detect the reset and start executing
    //  instructions from the ROM; we use `always`, because we need non-blocking assignment
    //  for this to work correctly (CPU uses non-blocking assignment internally)
    always @ (posedge clk) begin
        reset <= 0;
        SUPRESS_ERRORS <= 0;
        error_enabled <= 1;
    end

    // now we wait until the CPU stops (outside of the initial reset)
    initial @ (posedge (cpu_stop & !reset)) begin
        $display("Received a `cpu_stop` signal, stopping...");
        // wait until the next tick to see the final state (non-blocking assignment
        //  is used inside the CPU, so the last writes are only visible after this tick)
        @ (posedge clk);
        $display("");
        $display("Final state:");
        computer.cpu.register_file.dump();
        computer.ram.dump();
        $display("");
        $finish();
    end

    // if the CPU raises an error, show it to the user and terminate
    initial @ (posedge error) begin
        // wait a before an exit to get all debug prints; the prints are only done
        //  at the end of a tick, when the non-blocking assignments are applied
        @ (negedge clk);
        if (cpu_error.decoder) `PANIC("Illegal instruction encountered.");
        if (cpu_error.alu) `PANIC("ALU error ocurred.");
        // huh?
        `PANIC("Unknown CPU error ocurred.");
    end
endmodule
`endif

`endif