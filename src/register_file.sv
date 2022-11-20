`ifndef PACKAGE_REGISTER_FILE
`define PACKAGE_REGISTER_FILE
`include "types.sv"

/** Register file with 2 read ports and 1 write port. */
module register_file (
        input clk, write_enable,
        input RegAddress addr_write, addr1, addr2, input Word in,
        output Word out1, out2);

    Word registers[1:(1<<$bits(RegAddress))-1]; // start from 1, register 0 is hardwired to 0

    // read ports
    assign out1 = addr1 == 0 ? 0 : registers[addr1];
    assign out2 = addr2 == 0 ? 0 : registers[addr2];

    always @ (posedge clk) begin
        // write port
        if (write_enable & addr_write != 0) begin
            registers[addr_write] <= in;
        end
    end

    task dump;
        RegAddress i;
        Word val;
        $display("REGS:");
        i = 0; do begin
            val = i == 0 ? 0 : registers[i];
            if (^val !== 1'bx) $display("  r%0d: %0d", i, val);
            i++;
        end while (i != 0);
    endtask
endmodule


`ifdef TEST_register_file
module register_file_tb;
    logic clk = 0, write_enable = 1;
    RegAddress addr_write, addr1, addr2;
    Word in;
    wire Word out1, out2;

    register_file rf(clk, write_enable, addr_write, addr1, addr2, in, out1, out2);

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);
    end
    initial begin
        RegAddress i;

        addr1 = 10;

        // initialize all registers with (i*10)+1, then dump the contents
        i = 0; do begin
            addr_write = i;
            in = i * 10 + 1;
            clk = 1;
            #0.5 clk = 0;
            #0.5;
            i++;
        end while (i != 0);

        rf.dump();
    end
endmodule
`endif

`endif