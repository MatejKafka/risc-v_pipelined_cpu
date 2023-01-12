`ifndef PACKAGE_RAM
`define PACKAGE_RAM
`include "types.svh"
`include "utils.svh"

module ram #(parameter USE_FORWARDING=0) (
        input clk, reset, write_enable, input RamAddress address, input Word in, output Word out);
    // addresses are in bytes, but our slots are Word-sized
    Word memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    /* verilator lint_off SYNCASYNCNET */
    `TRACE(write_enable or address or in or out, 33, ("📁d we=%0d address=0x%h in=%0d out=%0d", write_enable, address, in, out))
    /* verilator lint_on SYNCASYNCNET */

    // read port, with forwarding
    assign out = USE_FORWARDING && write_enable ? in : memory[`WORD_ADDRESS(address)];

    always @ (posedge clk) begin
        if (reset) clear();
        // write port
        else if (write_enable) memory[`WORD_ADDRESS(address)] <= in;
    end

    task clear();
        // we cannot use <=, verilator will complain that it cannot do non-blocking assignment in loops longer than 256;
        //  I hope using blocking assignment here shouldn't cause too much trouble with timing
        /* verilator lint_off BLKSEQ */
        foreach (memory[i]) begin
            memory[i] = 0;
        end
        /* verilator lint_on BLKSEQ */
    endtask

    task dump();
        $display("RAM:");
        foreach (memory[i]) begin
            // skip (probably) unused slots
            if (memory[i] != 0) $display("  0x%h = %0d", RamAddress'(i * 4), memory[i]);
        end
    endtask
endmodule

`ifdef TEST_ram
module ram_tb;
    reg clk = 0, reset, write_enable = 1;
    RamAddress address;
    Word in;
    Word out;

    ram ram(clk, reset, write_enable, address, in, out);

    initial begin
        $dumpfile("ram.vcd");
        $dumpvars(0, ram_tb);
    end
    initial begin
        reset_ram();
        write(0, 1);
        write(4, 2);
        write(16, 3);
        ram.dump();
    end

    task reset_ram();
        reset = 1;
        clk = 0;
        #0.5 clk = 1;
        #0.5 reset = 0;
    endtask

    task write(RamAddress address_, Word value_);
        address = address_;
        in = value_;
        clk = 0;
        #0.5 clk = 1;
        #0.5;
    endtask
endmodule
`endif

`endif