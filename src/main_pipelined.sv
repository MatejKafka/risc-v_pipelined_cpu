`ifndef PACKAGE_MAIN_PIPELINED
`define PACKAGE_MAIN_PIPELINED

// reuse the same `computer` module, just switch the CPU implementation
`define USE_PIPELINE
`include "main.sv"

`ifdef TEST_main_pipelined
// very similar to main.sv, 3 lines are different
module main_pipelined_tb;
    logic reset, error_enabled;
    logic clk, cpu_clk, cpu_stop, error;
    CpuError cpu_error;

    clock clock(clk);
    computer computer(cpu_clk, reset, cpu_stop, cpu_error);

    // supress errors while the initial reset is active
    assign error = cpu_error != 0 & !reset;
    // hold the CPU clock on 1 when it wants to stop or encounters an error to prevent executing more instructions
    assign cpu_clk = clk || (!reset && (cpu_stop || error));


    initial begin
        $dumpfile("main_pipelined.vcd");
        $dumpvars(0, main_tb);
    end

    // block error messages; since we propagate error bits through the pipeline and usually discard them,
    //  we'd have random error messages printed after branches and EBREAK
    initial SUPRESS_ERRORS = 1;

    // block errors during the initial reset (there will most likely be some,
    //  given that the CPU is executing instructions from a random memory address,
    //  which the program counter happened to contain on startup)
    initial error_enabled = 0;
    // start a CPU reset
    initial reset = 1;
    // wait for 1 clock cycle; now the CPU should detect the reset and start executing
    //  instructions from the ROM; we use `always`, because we need non-blocking assignment
    //  for this to work correctly (CPU uses non-blocking assignment internally)
    always @ (posedge clk) begin
        reset <= 0;
        error_enabled <= 1;
    end

    // the reset is completed
    initial @ (negedge reset) $display("Pipelined CPU started.");

    // now we wait until the CPU stops (outside of the initial reset)
    initial @ (posedge (cpu_stop & !reset)) begin
        $display("Received a stop signal from the CPU, stopping...");
        // wait until the next tick to see the final state (non-blocking assignment
        //  is used inside the CPU, so the last writes are only visible after this tick)
        @ (posedge clk);
        $display("");
        $display("Final state:");
        computer.cpu.dump_registers();
        computer.ram.dump();
        $display("");
        $finish();
    end

    // if the CPU raises an error, show it to the user and terminate
    initial @ (posedge error) begin
        // let this tick finish before an exit to get all debug prints; the prints are only done
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