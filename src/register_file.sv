`ifndef PACKAGE_REGISTER_FILE
`define PACKAGE_REGISTER_FILE
`include "types.svh"
`include "utils.svh"

/** Register file with 2 read ports and 1 write port. */
module register_file #(parameter USE_FORWARDING=0) (
        input clk, reset, write_enable,
        input RegAddress addr_write, addr1, addr2, input Word in,
        output Word out1, out2);

    Word registers[1:(1<<$bits(RegAddress))-1]; // start from 1, register 0 is hardwired to 0

    /* verilator lint_off SYNCASYNCNET */
    `TRACE(addr1 or out1, 39, ("🧾%s => %0d", Reg_name(addr1), out1))
    `TRACE(addr2 or out2, 39, ("🧾%s => %0d", Reg_name(addr2), out2))
    `TRACE(registers[addr_write], 39, ("🧾%s <= %0d", Reg_name(addr_write), in))
    /* verilator lint_on SYNCASYNCNET */

    // read ports, with forwarding
    assign out1 = addr1 == 0 ? 0 : (USE_FORWARDING && write_enable && addr_write == addr1) ? in : registers[addr1];
    assign out2 = addr2 == 0 ? 0 : (USE_FORWARDING && write_enable && addr_write == addr2) ? in : registers[addr2];

    always @ (posedge clk) begin
        if (reset) clear();
        else if (write_enable && addr_write != 0) begin
            // write port
            registers[addr_write] <= in;
        end
    end

    task clear();
        foreach (registers[i]) begin
            registers[i] <= 0;
        end
    endtask

    task dump();
        automatic Word val;
        $display("REGS:");
        foreach (registers[i]) begin
            val = registers[i];
            // check for X in iverilog; verilator does not simulate 4 valued logic, uninitialized regs are all ones = -1
            // this may have false positives, because -1 can be a common result of some computation, but it doesn't
            //  matter too much, as this is just a debug method
            if (^val !== 1'bx && val != 0 && val != -1) $display("  %s = %0d", Reg_name(RegAddress'(i)), val);
        end
    endtask
endmodule


`ifdef TEST_register_file
module register_file_tb;
    logic clk = 0, reset = 0, write_enable = 1;
    RegAddress addr_write, addr1, addr2;
    Word in;
    Word out1, out2;

    register_file rf(clk, reset, write_enable, addr_write, addr1, addr2, in, out1, out2);

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);
    end
    initial begin
        RegAddress i;

        addr1 = 10;
        addr2 = 11;

        // initialize all registers with (i*10)+1, then dump the contents
        i = 0; do begin
            addr_write = i;
            in = i * 10 + 1;
            clk = 0;
            #0.5 clk = 1;
            #0.5;
            i++;
        end while (i != 0);

        // check that the output value is not stuck at the original value (before the write)
        $display("r10 = %0d", out1);
        $display("r11 = %0d", out2);

        rf.dump();

        // test that the `reset` pin zeros all registers
        reset = 1;
        clk = 0;
        #0.5;
        clk = 1;
        #0.5;
        reset = 0;
        $display("After zeroing:");
        rf.dump();
    end
endmodule
`endif

`endif