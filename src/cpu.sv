`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.sv"
`include "alu.sv"
`include "register_file.sv"

module cpu(input clk, input AluOp op, input RegAddress dst, src1, input Reg val2, output Reg out);
    reg reg_write_enable = 1;
    RegAddress src2 = 0;
    wire Reg v1, v2;

    register_file regs(clk, reg_write_enable, dst, src1, src2, out, v1, v2);
    alu alu(op, v1, val2, out);

    task dump;
        regs.dump();
    endtask
endmodule

`ifdef TEST_cpu
module cpu_tb;
    reg clk = 0;
    RegAddress dst, src1;
    Reg val2;
    wire Reg out;
    AluOp op;

    cpu cpu(clk, op, dst, src1, val2, out);

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
    end
    initial begin
        run(ADD, 1, 0, 10);
        run(SHL, 1, 1, 3);
        run(ADD, 2, 1, 1);
        run(ADD, 3, 2, 1);
        run(ADD, 4, 3, 1);
        run(ADD, 5, 4, 1);

        cpu.dump();
    end

    task run(AluOp op_, RegAddress dst_, src_, Reg imm_);
        $display("r%0d = r%0d %s %0d", dst_, src_, AluOp_symbol(op_), imm_);
        src1 = src_;
        clk = 1;
        op = op_;
        val2 = imm_;
        #0.5;
        clk = 0;
        #0.5;
        dst = dst_;
    endtask
endmodule
`endif

`endif