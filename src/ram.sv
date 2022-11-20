`ifndef PACKAGE_RAM
`define PACKAGE_RAM
`include "types.sv"

module ram(input clk, write_enable, input RamAddress address, input Word in, output Word out);
    // addresses are in bytes, but our slots are Word-sized
    Word memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    `TRACE(write_enable or address or in or out, 33, ("📁d we=%0d address=0x%00h in=%0d out=%0d", write_enable, address, in, out))

    // read port
    assign out = memory[`WORD_ADDRESS(address)];

    always @ (posedge clk) begin
        // write port
        if (write_enable) memory[`WORD_ADDRESS(address)] <= in;
    end

    task dump;
        RamAddress i, word_size;
        Word w;
        word_size = $bits(word_size)'`BYTES(Word);
        $display("RAM:");
        i = 0; do begin
            w = memory[`WORD_ADDRESS(i)];
            if (^w !== 1'bx) $display("  0x%00h = %0d", i, w);
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
        write(0, 0);
        write(4, 4);
        write(16, 16);
        ram.dump();
    end

    task write(RamAddress address_, Word value_);
        address = address_;
        in = value_;
        clk = 1;
        #0.5;
        clk = 0;
        #0.5;
    endtask
endmodule
`endif

`endif