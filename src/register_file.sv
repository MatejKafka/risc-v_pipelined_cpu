`ifndef PACKAGE_REGISTER_FILE
`define PACKAGE_REGISTER_FILE
`include "types.sv"

/** Register file with 2 read ports and 1 write port. */
module register_file (
        input clk, write_enable,
        input RegAddress addr_write, addr1, addr2, input Reg in,
        output Reg out1, out2);

    Reg registers[(1<<`REG_ADDRESS_WIDTH)-1:1]; // start from 1, register 0 is hardwired to 0

    function Reg read_reg(RegAddress addr);
        // register 0 is hardwired to 0
        read_reg = addr == 0 ? 0 : registers[addr];
    endfunction
    function void write_reg(RegAddress addr, Reg value);
        if (addr != 0) registers[addr] = value;
    endfunction

    // we have 2 options here:
    // 1) do register writes on negedge, at the "half" of a cycle
    // 2) do the writes on posedge, together with reads, but now we have to be careful
    //    with how we set the operand registers; effectively, we must set the destination
    //    register 1 cycle after the corresponding instruction is executed; however, imo this
    //    is cleaner than having half-cycles
    always @ (posedge clk) begin
        // write port
        if (write_enable) write_reg(addr_write, in);
        // read ports
        out1 = read_reg(addr1);
        out2 = read_reg(addr2);
        $display("read %d: %d", addr1, out1);
    end

    task dump;
        static RegAddress i = 0; do begin
            if (^read_reg(i) !== 1'bx) $display("r%0d: %0d", i, read_reg(i));
            i++;
        end while (i != 0);
    endtask
endmodule


`ifdef TEST_register_file
module register_file_tb;
    logic clk, write_enable;
    RegAddress addr_write, addr1, addr2;
    Reg in;
    wire Reg out1, out2;

    register_file rf(clk, write_enable, addr_write, addr1, addr2, in, out1, out2);

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);
    end

    RegAddress i;
    initial begin
        // initialize all registers with (i*10)+1, then dump the contents
        write_enable = 1;
        clk = 0;
        i = 0;
        do begin
            addr_write = i;
            in = i * 10 + 1;
            clk = 1;
            #1 clk = 0;
            i++;
        end while (i != 0);

        rf.dump();
    end
endmodule
`endif

`endif