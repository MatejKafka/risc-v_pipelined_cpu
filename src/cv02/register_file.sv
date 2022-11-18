/**
 * Single-ported register file.
 */
module register_file #
        (parameter W = 32, parameter A = 5)
        (input clk, write_enable, input [0:A-1] read_addr_1, input [0:W-1] write_in_1,
         output reg [0:W-1] read_out_1);
    reg [0:W-1] registers[0:(1<<A)-1];

    always @ (posedge clk) begin
        if (read_addr_1 == 0) read_out_1 = 0; // register 0 is hardwired to 0, ignore writes
        else begin
            if (write_enable) registers[read_addr_1] = write_in_1;
            // read/forward the register value
            read_out_1 = registers[read_addr_1];
        end
    end
endmodule

module register_file_tb;
    reg clk, write_enable;
    reg [0:4] addr;
    reg [0:31] in;
    wire [0:31] out;

    register_file rf(clk, write_enable, addr, in, out);

    initial begin
        // initialize all registers with i*10, then try to read them out
        write_enable = 1;
        clk = 0;
        for (integer i = 0; i < 32; i++) begin
            addr = i;
            in = i * 10 + 1;
            clk = 1;
            #1 clk = 0;
        end

        write_enable = 0;
        for (integer i = 0; i < 32; i++) begin
            addr = i;
            clk = 1;
            $strobe("addr=%d, out=%d", addr, out);
            #1 clk = 0;
        end
    end
endmodule