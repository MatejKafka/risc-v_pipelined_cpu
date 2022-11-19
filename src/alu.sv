`ifndef PACKAGE_ALU
`define PACKAGE_ALU
`include "types.sv"

typedef enum logic [2:0] {
    ADD = 2,
    SUB = 6,
    AND = 0,
    OR  = 1,
    XOR = 3,
    SLT = 7,
    SHL = 4,
    SHR = 5
} AluOp;

module alu(input AluOp operation, input Reg a, input Reg b, output Reg out);
    always @ (*) case (operation)
        ADD: out = a + b;
        SUB: out = a - b;
        AND: out = a & b;
        OR:  out = a | b;
        XOR: out = a ^ b;
        SLT: out = {31'b0, a < b};
        SHL: out = a << b;
        SHR: out = a >> b;
    endcase
endmodule

`ifdef TEST_alu
module alu_tb;
    Reg a, b;
    AluOp op;
    wire Reg out;

    alu alu(op, a, b, out);

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end
    initial begin
        a = 10;
        b = 7;

        op = ADD; do begin
            $strobe("a=%0d, b=%0d, op=%0d, out=%0d", a, b, op, out);
            #1 op++;
        end while (op != ADD);
    end
endmodule
`endif

`endif