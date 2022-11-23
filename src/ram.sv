`ifndef PACKAGE_RAM
`define PACKAGE_RAM
`include "types.sv"

module ram(input clk, write_enable, input RamAddress address, input Word in, output Word out);
    // addresses are in bytes, but our slots are Word-sized
    Word memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    /* verilator lint_off SYNCASYNCNET */
    `TRACE(write_enable or address or in or out, 33, ("📁d we=%0d address=0x%00h in=%0d out=%0d", write_enable, address, in, out))
    /* verilator lint_on SYNCASYNCNET */

    // read port
    assign out = memory[`WORD_ADDRESS(address)];

    always @ (posedge clk) begin
        // write port
        if (write_enable) memory[`WORD_ADDRESS(address)] <= in;
    end

    task dump();
        RamAddress i, word_size;
        Word w;
        word_size = $bits(word_size)'`BYTES(Word);
        $display("RAM:");
        i = 0; do begin
            w = memory[`WORD_ADDRESS(i)];
            // check for X in iverilog; verilator does not simulate 4 valued logic, uninitialized regs are all ones = -1
            // this may have false positives, because -1 can be a common result of some computation, but it doesn't
            //  matter too much, as this is just a debug method
            if (^w !== 1'bx && w != 0 && w != -1) $display("  0x%00h = %0d", i, w);
            i += word_size;
        end while (i != 0);
    endtask

endmodule

`ifdef TEST_ram
module ram_tb;
    reg clk = 0, write_enable = 1;
    RamAddress address;
    Word in;
    wire Word out;

    ram ram(clk, write_enable, address, in, out);

    initial begin
        $dumpfile("ram.vcd");
        $dumpvars(0, ram_tb);
    end
    initial begin
        write(0, 1);
        write(4, 2);
        write(16, 3);
        ram.dump();
    end

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