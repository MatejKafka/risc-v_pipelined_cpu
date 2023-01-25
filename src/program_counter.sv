`ifndef PACKAGE_PROGRAM_COUNTER
`define PACKAGE_PROGRAM_COUNTER
`include "types.svh"
`include "instruction_types.svh"

module program_counter(
        input clk, reset, stall,
        input logic should_branch, input RomAddress branch_target,
        output RomAddress current_pc, output RomAddress next_pc);

    // we calculate PC + 4 here, because for JAL/JALR, we need to access next_pc outside,
    //  and if we did not compute it here, we'd have to route it through ALU
    assign next_pc = current_pc + RomAddress'(`BYTES(UWord)); // +4 for 32bit UWord

    always @ (posedge clk) begin
        current_pc <= reset ? 0
            // even if stalling, follow the branch
            : should_branch ? branch_target
            : stall ? current_pc : next_pc;
    end
endmodule

`ifdef TEST_program_counter
module program_counter_tb;
    reg clk = 1, reset = 1;
    reg should_branch;
    RomAddress branch_target;
    RomAddress current_pc, unused_next_pc;

    program_counter pc(clk, reset, 0, should_branch, branch_target, current_pc, unused_next_pc);

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        #10 $finish();
    end

    always #0.5 clk <= !clk;

    // whenever we reach "instruction" 0x10, jump back to 0x8 by setting `pc_delta` to -0x8
    assign should_branch = current_pc == 'h10;
    assign branch_target = 'h8;

    always @ (posedge clk) begin
        // switch off reset at the first cycle
        reset <= 0;
        $strobe("pc=%0d", current_pc);
    end
endmodule
`endif

`endif