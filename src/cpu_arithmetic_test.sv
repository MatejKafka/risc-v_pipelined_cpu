//
// A test file with a basic CPU, which only has a register file and an ALU.
//
`ifndef PACKAGE_CPU_ARITHMETIC_TEST
`define PACKAGE_CPU_ARITHMETIC_TEST
`include "types.svh"
`include "instruction_types.svh"
`include "alu.sv"
`include "register_file.sv"

module cpu(input clk, input AluOp op, input RegAddress dst, src1, src2, input has_immediate, input Immediate imm, output Word out);
    reg reg_reset = 0, reg_write_enable = 1;
    Word v1, v2;
    Word aluB;
    logic unused_error;

    assign aluB = has_immediate ? Word'(imm) : v2;

    register_file regs(clk, reg_reset, reg_write_enable, dst, src1, src2, out, v1, v2);
    alu alu(unused_error, op, v1, aluB, out);
endmodule

`ifdef TEST_cpu_arithmetic_test
`include "instruction_macros.svh"
module cpu_arithmetic_test_tb;
    reg clk = 1;
    logic error;
    RegAddress dst, src1, src2;
    logic has_immediate;
    Immediate imm;
    Word out;
    logic ebreak;
    InstructionControl control;

    cpu cpu(clk, control.alu_op, dst, src1, src2, has_immediate, imm, out);

    initial begin
        $dumpfile("cpu_arithmetic_test.vcd");
        $dumpvars(0, cpu_tb);
    end

    // setup our test instructions
    Instruction instructions[8] = '{
        `I_IMM(ADD, 1, 0, 10),
        `I_IMM(ADD, 1, 1, 40),
        `I_IMM(ADD, 2, 1, 10),
        `I_IMM(ADD, 3, 2, 1),
        `I_IMM(ADD, 4, 3, 1),
        `I_REG(SUB, 5, 4, 1),
        `I_REG(AND, 6, 1, 2),
        `I_EBREAK
    };

    // simulate a primitive program counter to run the instructions defined above
    int i = 0;
    assign {control, imm, dst, src1, src2} = instructions[i];
    assign has_immediate = control.alu_src2 == ALU2_IMM;
    assign ebreak = control.is_ebreak;
    initial clk = 0;
    always begin
        #5 clk <= 0;
        #5 clk <= 1;
    end
    always @ (posedge (clk & !ebreak)) begin
        i <= i + 1;
    end

    always @ (posedge ebreak) begin
        #5; // delay to let the last register write finish
        cpu.regs.dump();
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