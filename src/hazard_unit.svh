`ifndef PACKAGE_HAZARD_UNIT
`define PACKAGE_HAZARD_UNIT
`include "pipeline_types.svh"

typedef struct packed {
    RdSrc rd_src;
    RegAddress rd;
} StageHazardInfo;

module hazard_unit(
        output logic stall, output AluForwarding alu_forward1, alu_forward2,
        input RegAddress rs1, rs2, input StageHazardInfo ex, mem);

    // check if we need to stall (only necessary when an instruction uses a result of LW in the previous cycle)
    assign stall = ex.rd_src == RD_RAM_OUT && (ex.rd == rs1 || ex.rd == rs2);

    // check if we need to forward (keep in mind that the forwarding applies in the EX stage,
    //  so the signals below are shifted by one stage
    assign alu_forward1 = ex.rd_src != RD_NONE &&  ex.rd == rs1 ? AF_MEM
                       : mem.rd_src != RD_NONE && mem.rd == rs1 ? AF_WB
                                                                : AF_REG;
    assign alu_forward2 = ex.rd_src != RD_NONE &&  ex.rd == rs2 ? AF_MEM
                       : mem.rd_src != RD_NONE && mem.rd == rs2 ? AF_WB
                                                                : AF_REG;
endmodule

`endif