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

function string AluOp_symbol(AluOp op);
    case (op)
        ADD: AluOp_symbol = "+";
        SUB: AluOp_symbol = "-";
        AND: AluOp_symbol = "&";
        OR:  AluOp_symbol = "|";
        XOR: AluOp_symbol = "^";
        SLT: AluOp_symbol = "<";
        SHL: AluOp_symbol = "<<";
        SHR: AluOp_symbol = ">>";
    endcase
endfunction

module alu(input AluOp operation, input Reg a, input Reg b, output Reg out);
    always @ (*) begin
        case (operation)
        ADD: out = a + b;
        SUB: out = a - b;
        AND: out = a & b;
        OR:  out = a | b;
        XOR: out = a ^ b;
        SLT: out = {31'b0, a < b};
        SHL: out = a << b;
        SHR: out = a >> b;
    endcase
    `DBG($display("ALU: %0d = %0d %0s %0d", out, a, AluOp_symbol(operation), b));
    end
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
            #1 $display("%0d %0s %0d = %0d", a, AluOp_symbol(op), b, out);
            op++;
        end while (op != ADD);
    end
endmodule
`endif

`endif