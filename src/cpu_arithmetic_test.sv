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
    reg reg_reset = 0;
    Word v1, v2;
    Word aluB;
    logic unused_error, unused_is_out_zero;

    assign aluB = has_immediate ? Word'(imm) : v2;

    register_file regs(clk, reg_reset, dst, src1, src2, out, v1, v2);
    alu alu(unused_error, op, v1, aluB, out, unused_is_out_zero);
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
    AluOp op;
    logic ebreak;
    InstructionFlags flags;

    cpu cpu(clk, op, dst, src1, src2, has_immediate, imm, out);

    initial begin
        $dumpfile("cpu_arithmetic_test.vcd");
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
    assign {flags, op, dst, src1, src2, imm} = instructions[i];
    assign has_immediate = flags.alu_use_imm;
    assign ebreak = flags.is_ebreak;
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