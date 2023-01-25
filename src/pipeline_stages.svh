`ifndef PACKAGE_PIPELINE_STAGES
`define PACKAGE_PIPELINE_STAGES
`include "types.svh"
`include "instruction_types.svh"
`include "pipeline_types.svh"
`include "hazard_unit.svh"


module stage_instruction_fetch(
        input clk, reset, stall, output reg cpu_stop,
        input MemIfReg if_in, output IfIdReg out,
        input UWord rom_data, output RomAddress rom_address);

    RomAddress pc, next_pc;
    program_counter program_counter(clk, reset, stall, if_in.should_branch, if_in.branch_target, pc, next_pc);

    // we only output cpu_stop when the EBREAK instruction reaches IF
    // this way, all previous register and memory writes finish, before the signal is raised
    always @ (posedge clk) begin
        cpu_stop <= reset ? 0 : if_in.is_ebreak;
    end

    assign rom_address = pc;
    assign out = '{rom_data: rom_data, pc: pc, next_pc: next_pc};
endmodule


module stage_instruction_decode(
        input clk, reset, output stall,
        input WbReg wb, input IfIdReg if_, output IdExReg out,
        input StageHazardInfo ex_hazard, mem_hazard);

    logic decoder_error;
    Instruction instruction;
    instruction_decoder decoder(decoder_error, if_.rom_data, instruction);

    AluForwarding alu_forward1, alu_forward2;
    hazard_unit hazard_unit(stall, alu_forward1, alu_forward2,
        instruction.rs1, instruction.rs2, ex_hazard, mem_hazard);

    Word reg_out1, reg_out2;
    register_file #(.USE_FORWARDING(1)) register_file(clk, reset, wb.write_enable,
        wb.write_address, instruction.rs1, instruction.rs2,
        wb.write_data, reg_out1, reg_out2);

    assign out = '{
        decoder_error: decoder_error,
        pc: if_.pc, next_pc: if_.next_pc,
        reg_out1: reg_out1, reg_out2: reg_out2,
        fwd1: alu_forward1, fwd2: alu_forward2,
        control: instruction.control, immediate: instruction.immediate, rd: instruction.rd};
endmodule


module stage_execute(
        input Word mem_rd_val, wb_rd_val,
        input IdExReg id, output ExMemReg out);

    // either register output or a forwarded value
    Word fwd_in1, fwd_in2;

    logic cmp_out;
    Word cmp_src1, cmp_src2;
    // always use rs1/rs2 with comparator ops
    alu_comparator cmp(id.control.cmp_op, fwd_in1, fwd_in2, cmp_out);

    logic alu_error;
    Word alu_src1, alu_src2, alu_out;
    alu alu(alu_error, id.control.alu_op, alu_src1, alu_src2, alu_out);

    always @ (*) case (id.fwd1)
        AF_REG:  fwd_in1 = id.reg_out1;
        AF_MEM:  fwd_in1 = mem_rd_val;
        AF_WB:   fwd_in1 = wb_rd_val;
        default: fwd_in1 = id.reg_out1;
    endcase
    always @ (*) case (id.fwd2)
        AF_REG:  fwd_in2 = id.reg_out2;
        AF_MEM:  fwd_in2 = mem_rd_val;
        AF_WB:   fwd_in2 = wb_rd_val;
        default: fwd_in2 = id.reg_out2;
    endcase

    always @ (*) case (id.control.alu_src1)
        ALU1_RS1:  alu_src1 = fwd_in1;
        ALU1_PC:   alu_src1 = Word'(id.pc);
        ALU1_ZERO: alu_src1 = 0;
        default:   alu_src1 = 0;
    endcase

    always @ (*) case (id.control.alu_src2)
        ALU2_RS2: alu_src2 = fwd_in2;
        ALU2_IMM: alu_src2 = id.immediate;
    endcase

    assign out = '{
        decoder_error: id.decoder_error, alu_error: alu_error,
        alu_out: alu_out, cmp_out: cmp_out,
        control: id.control, ram_write_data: fwd_in2, rd: id.rd, pc: id.pc, next_pc: id.next_pc};
endmodule


module stage_memory(
        input reset, output decoder_error, alu_error,
        input Word ram_data, output RamAddress ram_address, output ram_write_enable, output Word ram_write_data,
        input ExMemReg ex, output WbReg out_wb, output MemIfReg out_if);

    assign decoder_error = ex.decoder_error;
    assign alu_error = ex.alu_error;

    assign ram_write_data = ex.ram_write_data;
    assign ram_write_enable = ex.control.ram_write;
    assign ram_address = RamAddress'(ex.alu_out);

    Word reg_write_data;
    always @ (*) case (ex.control.rd_src)
        RD_ALU:     reg_write_data = ex.alu_out;
        RD_RAM_OUT: reg_write_data = ram_data;
        RD_NEXT_PC: reg_write_data = Word'(ex.next_pc);
        RD_NONE:    reg_write_data = ex.alu_out; // this is handled below by disabling write-enable
    endcase

    logic should_branch;
    always @ (*) case (ex.control.branch_condition)
        BC_NEVER: should_branch = FALSE;
        BC_ALWAYS: should_branch = TRUE;
        BC_CMP_TRUE: should_branch = ex.cmp_out;
        BC_CMP_FALSE: should_branch = !ex.cmp_out;
    endcase

    assign out_if = '{
        is_ebreak: ex.control.is_ebreak,
        should_branch: should_branch,
        branch_target: RomAddress'(ex.alu_out),
        pc: ex.pc};

    assign out_wb = '{
        write_enable: ex.control.rd_src != RD_NONE,
        write_address: ex.rd,
        write_data: reg_write_data,
        pc: ex.pc};
endmodule

`endif