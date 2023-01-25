`ifndef PACKAGE_ALU
`define PACKAGE_ALU
`include "types.svh"
`include "utils.svh"

module alu(output logic error, input AluOp operation, input Word a, input Word b, output Word out);
    always @ (*) begin
        error = 0;
        case (operation)
            ADD: out = a + b;
            SUB: out = a - b;
            SLL: out = a << b;
            SLT: out = {31'b0, $signed(a) < $signed(b)};
            SLTU:out = {31'b0, $unsigned(a) < $unsigned(b)};
            XOR: out = a ^ b;
            SRL: out = a >> b;
            SRA: out = a >>> b;
            OR:  out = a | b;
            AND: out = a & b;
            default: begin out = 'x; `ERROR(("Invalid ALU instruction")); end
        endcase
    end
endmodule

`ifdef TEST_alu
module alu_tb;
    logic unused_error;
    Word a, b;
    AluOp op;
    Word out;

    alu alu(unused_error, op, a, b, out);

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end
    initial begin
        a = 20;
        b = 3;
        op = AluOp'(0); do begin
            display_op(FALSE);
            op++;
        end while (op != 'b1000);

        a = -2;
        b = 5;
        op = AluOp'(0); do begin
            display_op(TRUE);
            op++;
        end while (op != 'b1000);

        op = SUB;
        a = 20;
        b = 3;
        display_op(TRUE);
        op = SRA;
        display_op(FALSE);
    end

    task display_op(logic is_signed);
        #1;
        if (is_signed) $display("%0d %0s %0d = %0d", a, AluOp_symbol(op), b, out);
        else $display("%0d %0s %0d = %0d", $unsigned(a), AluOp_symbol(op), $unsigned(b), $unsigned(out));
    endtask
endmodule
`endif

`endif