`ifndef PACKAGE_PROGRAM_COUNTER
`define PACKAGE_PROGRAM_COUNTER
`include "types.sv"

module program_counter(
        input clk, reset,
        input should_branch, input RomAddress pc_delta,
        output RomAddress current_pc, output RomAddress next_pc);
    // we calculate PC + 4 here, instead of reusing the adder in the ternary below, because
    //  for JAL, we need to access next_pc outside, and if we did not compute it here, we'd
    //  have to route it through ALU
    // also, in a real CPU, we'd probably want to compute this ASAP, so that when we
    //  figure out if we should take the branch (e.g. for BEQ), we have both values ready
    RomAddress branch_target;
    assign next_pc = current_pc + RomAddress'(`BYTES(Word)); // +4 for 32bit Word
    assign branch_target = current_pc + pc_delta;

    always @ (posedge clk) begin
        if (reset) current_pc <= 0;
        else current_pc <= should_branch ? branch_target : next_pc;
    end
endmodule

`ifdef TEST_program_counter
module program_counter_tb;
    reg clk = 1, reset = 1;
    reg should_branch;
    RomAddress pc_delta;
    wire RomAddress current_pc, unused_next_pc;

    program_counter pc(clk, reset, should_branch, pc_delta, current_pc, unused_next_pc);

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        #10 $finish();
    end

    always #0.5 clk <= !clk;

    // whenever we reach "instruction" 0x10, jump back to 0x8 by setting `pc_delta` to -0x8
    assign should_branch = current_pc == 'h10;
    assign pc_delta = should_branch ? -8 : 0;

    always @ (posedge clk) begin
        // switch off reset at the first cycle
        reset <= 0;
        $strobe("pc=%0d", current_pc);
    end
endmodule
`endif

`endif