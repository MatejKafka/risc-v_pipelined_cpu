`ifndef PACKAGE_ALU_COMPARATOR
`define PACKAGE_ALU_COMPARATOR
`include "types.svh"
`include "utils.svh"

/**
 * A comparator module, used for branch instructions. Typically, branch results are computed
 * on the ALU, but using a separate comparator module frees up the ALU for branch target calculation,
 * avoiding the need for another adder and more control signals just for the program counter.
 */
module alu_comparator(input ComparatorOp operation, input Word a, input Word b, output logic out);
    always @ (*) case (operation)
        C_EQ:  out = a == b;
        C_LT:  out = $signed(a) < $signed(b);
        C_LTU: out = $unsigned(a) < $unsigned(b);
        C_NONE: out = 'x;
    endcase
endmodule

`ifdef TEST_alu_comparator
module alu_comparator_tb;
    Word a, b;
    ComparatorOp op;
    logic out;

    alu_comparator comparator(op, a, b, out);

    initial begin
        $dumpfile("alu_comparator.vcd");
        $dumpvars(0, alu_comparator_tb);
    end
    initial begin
        op = C_EQ; a = 10; b = 10;
        display_op(TRUE);
        op = C_EQ; a = 10; b = 9;
        display_op(TRUE);
        op = C_LT; a = 10; b = -3;
        display_op(TRUE);
        op = C_LT; a = -7; b = -3;
        display_op(TRUE);
        op = C_LTU; a = -1; b = 0;
        display_op(TRUE);
        op = C_LTU; a = 4; b = 7;
        display_op(TRUE);
    end

    task display_op(logic is_signed);
        #1;
        if (is_signed) $display("%0d %0s %0d = %0s", a, ComparatorOp_name(op), b, out ? "TRUE" : "FALSE");
        else $display("%0d %0s %0d = %0s", $unsigned(a), ComparatorOp_name(op), $unsigned(b), out ? "TRUE" : "FALSE");
    endtask
endmodule
`endif

`endif