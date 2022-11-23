`ifndef PACKAGE_ALU
`define PACKAGE_ALU
`include "types.sv"

// the ALU op numbers correspond to their RV encoding {funct7[5], funct3} to simplify decoding
// if this is changed, the RV decoder must be changed accordingly
typedef enum logic [3:0] {
    ADD  = 4'b0_000,
    SUB  = 4'b1_000,
    SLL  = 4'b0_001,
    SLT  = 4'b0_010,
    SLTU = 4'b0_011,
    XOR  = 4'b0_100,
    SRL  = 4'b0_101,
    SRA  = 4'b1_101,
    OR   = 4'b0_110,
    AND  = 4'b0_111
} AluOp;

function string AluOp_symbol(AluOp op);
    case (op)
        ADD: AluOp_symbol = "+";
        SUB: AluOp_symbol = "-";
        SLL: AluOp_symbol = "<<";
        SLT: AluOp_symbol = "<s";
        SLTU:AluOp_symbol = "<u";
        XOR: AluOp_symbol = "^";
        SRL: AluOp_symbol = ">>";
        SRA: AluOp_symbol = ">>>";
        OR:  AluOp_symbol = "|";
        AND: AluOp_symbol = "&";
        default: AluOp_symbol = "--ALU-ERROR--";
    endcase
endfunction

module alu(output reg error, input AluOp operation, input Word a, input Word b, output Word out, output Bool is_out_zero);
    /* verilator lint_off SYNCASYNCNET */
    `TRACE(out, 36, ("🔢%0d = %0d %0s %0d", out, $signed(a), AluOp_symbol(operation), $signed(b)))
    /* verilator lint_on SYNCASYNCNET */

    always @ (*) begin
        error = 0;
        case (operation)
            ADD: out = a + b;
            SUB: out = a - b;
            SLL: out = a << b;
            SLT: out = {31'b0, $signed(a) < $signed(b)};
            SLTU:out = {31'b0, a < b};
            XOR: out = a ^ b;
            SRL: out = a >> b;
            SRA: out = a >>> b;
            OR:  out = a | b;
            AND: out = a & b;
            default: begin out = 'x; `ERROR(("Invalid ALU instruction")); end
        endcase
        is_out_zero = Bool'(out == 0);
    end
endmodule

`ifdef TEST_alu
module alu_tb;
    wire unused_error;
    Word a, b;
    AluOp op;
    wire Word out;
    wire Bool is_out_zero;

    alu alu(unused_error, op, a, b, out, is_out_zero);

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end
    initial begin
        automatic logic [2:0] op_main;

        a = 10;
        b = 7;
        op_main = 0; do begin
            $cast(op, {1'b0, op_main});
            display_op(FALSE);
            op_main++;
        end while (op_main != 0);

        a = -2;
        b = 5;
        op_main = 0; do begin
            $cast(op, {1'b0, op_main});
            display_op(TRUE);
            op_main++;
        end while (op_main != 0);

        op = SUB;
        a = 20;
        b = 3;
        display_op(TRUE);
        op = SRA;
        display_op(FALSE);
    end

    task display_op(Bool signed_);
        #1;
        if (signed_) $display("%0d %0s %0d = %0d%s", $signed(a), AluOp_symbol(op),
                $signed(b), $signed(out), is_out_zero ? " (=0)" : "");
        else $display("%0d %0s %0d = %0d%s", a, AluOp_symbol(op), b, out, is_out_zero ? " (=0)" : "");
    endtask
endmodule
`endif

`endif