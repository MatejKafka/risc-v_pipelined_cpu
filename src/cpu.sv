`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.sv"
`include "alu.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

module cpu(input clk, input AluOp op, input RegAddress dst, src1, src2, input Bool has_immediate, input Immediate imm, output Word out);
    reg reg_write_enable = 1;
    wire Word v1, v2;
    wire Word aluB;

    assign aluB = has_immediate ? 32'(imm) : v2;

    register_file regs(clk, reg_write_enable, dst, src1, src2, out, v1, v2);
    alu alu(op, v1, aluB, out);

    task dump;
        regs.dump();
    endtask
endmodule

`ifdef TEST_cpu
`include "instruction_macros.sv"
module cpu_tb;
    reg clk;
    RegAddress dst, src1, src2;
    Bool has_immediate;
    Immediate imm;
    wire Word _unused_out;
    AluOp op;
    Bool ebreak;

    cpu cpu(clk, op, dst, src1, src2, has_immediate, imm, _unused_out);

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
    end

    // setup our test instructions
    Instruction instructions[8] = '{
        `D_IMM(ADD, 1, 0, 10),
        `D_IMM(ADD, 1, 1, 40),
        `D_IMM(ADD, 2, 1, 10),
        `D_IMM(ADD, 3, 2, 1),
        `D_IMM(ADD, 4, 3, 1),
        `D_REG(SUB, 5, 4, 1),
        `D_REG(AND, 6, 1, 2),
        `D_EBREAK
    };

    // simulate a primitive program counter to run the instructions defined above
    int i = 0;
    assign {op, dst, src1, has_immediate, src2, imm, ebreak} = instructions[i];
    initial clk = 1;
    always #5 clk <= !clk;
    always @ (posedge (clk & !ebreak)) begin
        i <= i + 1;
    end

    always @ (posedge ebreak) begin
        #5; // delay to let the last register write finish
        cpu.dump();
        $finish();
        // expected output:
        //   r1: 50
        //   r2: 60
        //   r3: 61
        //   r4: 62
        //   r5: 12
        //   r6: 48
    end

endmodule
`endif

`endif