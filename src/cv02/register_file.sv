/**
 * Single-ported register file.
 */
module register_file #
        (parameter W = 32, parameter A = 5)
        (input clk, write_enable, input [A-1:0] read_addr_1, input [W-1:0] write_in_1,
         output reg [W-1:0] read_out_1);
    reg [W-1:0] registers[(1<<A)-1:0];

    always @ (posedge clk) begin
        if (read_addr_1 == 0) read_out_1 = 0; // register 0 is hardwired to 0, ignore writes
        else begin
            if (write_enable) registers[read_addr_1] = write_in_1;
            // read/forward the register value
            read_out_1 = registers[read_addr_1];
        end
    end
endmodule

`define W 32
`define A 5

module register_file_tb;
    reg clk, write_enable;
    reg [`A-1:0] addr;
    reg [`W-1:0] in;
    wire [`W-1:0] out;

    register_file rf(clk, write_enable, addr, in, out);

    bit [4:0] i;
    initial begin
        // initialize all registers with i*10, then try to read them out
        write_enable = 1;
        clk = 0;
        i = 0;
        do begin
            addr = i;
            in = i * 10 + 1;
            clk = 1;
            #1 clk = 0;
            i++;
        end while (i != 0);

        write_enable = 0;
        i = 0;
        do begin
            addr = i;
            clk = 1;
            $strobe("addr=%d, out=%d", addr, out);
            #1 clk = 0;
            i++;
        end while (i != 0);
    end
endmodule