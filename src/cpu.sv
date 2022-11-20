`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.sv"
`include "alu.sv"
`include "register_file.sv"

module cpu(input clk, input AluOp op, input RegAddress dst, src1, input Word val2, output Word out);
    reg reg_write_enable = 1;
    RegAddress src2 = 0;
    wire Word v1, v2;

    register_file regs(clk, reg_write_enable, dst, src1, src2, out, v1, v2);
    alu alu(op, v1, val2, out);

    task dump;
        regs.dump();
    endtask
endmodule

`ifdef TEST_cpu
module cpu_tb;
    typedef struct packed {
        AluOp op;
        RegAddress dst;
        RegAddress src;
        Word imm;
    } instruction;

    instruction instructions[6];

    reg clk = 0;
    RegAddress dst, src1;
    Word val2;
    wire Word out;
    AluOp op;
    int i = 0;

    cpu cpu(clk, op, dst, src1, val2, out);

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
    end
    initial begin
        instructions[0] = {ADD, 5'd1, 5'd0, 32'd10};
        instructions[1] = {SHL, 5'd1, 5'd1, 32'd3};
        instructions[2] = {SUB, 5'd2, 5'd1, 32'd20};
        instructions[3] = {ADD, 5'd3, 5'd2, 32'd1};
        instructions[4] = {ADD, 5'd4, 5'd3, 32'd1};
        instructions[5] = {ADD, 5'd5, 5'd4, 32'd1};
        // $monitor("r%0d = r%0d %s %0d", dst, src1, AluOp_symbol(op), val2);
    end

    always begin
        clk <= !clk;
        #0.5;
    end

    always @ (posedge clk) begin
        if (i == $size(instructions)) begin
            {op, dst, src1, val2} <= 0;
            #1; // delay to let the last write finish
            cpu.dump();
            $finish();
        end
        {op, dst, src1, val2} <= instructions[i];
        i <= i + 1;
    end
endmodule
`endif

`endif