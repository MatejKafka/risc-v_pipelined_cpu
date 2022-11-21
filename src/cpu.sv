`ifndef PACKAGE_CPU
`define PACKAGE_CPU
`include "types.sv"
`include "alu.sv"
`include "register_file.sv"
`include "instruction_decoder.sv"

module cpu(input clk, input AluOp op, input RegAddress dst, src1, src2, input Bool has_immediate, input Word imm, output Word out);
    reg reg_write_enable = 1;
    wire Word v1, v2;
    wire Word aluB;

    assign aluB = has_immediate ? imm : v2;

    register_file regs(clk, reg_write_enable, dst, src1, src2, out, v1, v2);
    alu alu(op, v1, aluB, out);

    task dump;
        regs.dump();
    endtask
endmodule

`ifdef TEST_cpu
`include "instruction_macros.sv"
module cpu_tb;
    reg clk = 0;
    int i = 0;
    RegAddress dst, src1, src2;
    Bool has_immediate;
    Word imm;
    Word raw_instruction;
    wire Instruction instruction;
    wire Word out;
    AluOp op;
    wire Bool ebreak;
    Bool done = FALSE;

    instruction_decoder decoder(raw_instruction, instruction);
    cpu cpu(clk, op, dst, src1, src2, has_immediate, imm, out);

    // forward the parsed instruction to the CPU
    assign {op, dst, src1, has_immediate, src2, imm, ebreak} = instruction;

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);
    end

    // setup our test instructions
    Word instructions[8];
    initial begin
        int j; j = 0;
        instructions[j++] = `ADDI(1, 0, 10);
        instructions[j++] = `ADDI(1, 1, 40);
        instructions[j++] = `ADDI(2, 1, 10);
        instructions[j++] = `ADDI(3, 2, 1);
        instructions[j++] = `ADDI(4, 3, 1);
        instructions[j++] = `SUB(5, 4, 1);
        instructions[j++] = `AND(6, 1, 2);
        instructions[j++] = `EBREAK;
    end

    // simulate a primitive program counter
    assign raw_instruction = instructions[i];
    always begin
        if (!done) begin
            if (!clk) i <= i + 1;
            clk <= !clk;
        end
        #0.5;
    end

    always @ (posedge ebreak) begin
        $display("Executed EBREAK, finishing...");
        done = TRUE;
        #0.5; // delay to let the last register write finish
        cpu.dump();
        $finish();
    end

endmodule
`endif

`endif