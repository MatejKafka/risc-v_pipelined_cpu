`ifndef PACKAGE_INSTRUCTION_TYPES
`define PACKAGE_INSTRUCTION_TYPES

typedef logic signed [31:0] Immediate;

typedef enum logic [1:0] {
    RD_ALU = 0, // rd <= alu_out
    RD_NEXT_PC = 1, // rd <= pc + 4; used for JAL/JALR
    RD_RAM_OUT = 2, // rd <= ram_data
    RD_NONE = 3 // do not write to `rd`
} RdSrc;

typedef enum logic[1:0] {
    ALU1_RS1 = 0, // alu_src1 <= reg[rs1]
    ALU1_PC = 1, // alu_src1 <= pc
    ALU1_ZERO = 2 // alu_src1 <= 0
} AluSrc1;

typedef enum logic {
    ALU2_RS2 = 0, // alu_src2 <= reg[rs2]
    ALU2_IMM = 1 // alu_src2 <= immediate
} AluSrc2;

typedef enum logic[1:0] {
    BC_NEVER = 0, // not a branch instruction
    BC_ALWAYS = 1, // jump
    BC_CMP_TRUE = 2, // branch if the comparison by `cmp_op` in `Instruction` is true
    BC_CMP_FALSE = 3 // opposite of BC_CMP_TRUE
} BranchCondition;

typedef struct packed {
    logic is_ebreak;
    logic ram_write;
    BranchCondition branch_condition;
    RdSrc rd_src;
    AluSrc1 alu_src1;
    AluSrc2 alu_src2;
} InstructionFlags;

typedef struct packed {
    InstructionFlags flags;
    AluOp alu_op;
    ComparatorOp cmp_op;
    Immediate immediate;
    RegAddress rd;
    RegAddress rs1;
    RegAddress rs2;
} Instruction;

// NOP = ADDI 0, 0, 0
const Instruction I_NOP = '{'{0, 0, BC_NEVER, RD_ALU, ALU1_RS1, ALU2_IMM}, ADD, C_NONE, 0, 0, 0, 0};

// this is just a rough dump of (some) relevant values
function string Instruction_to_string(Instruction i);
    automatic InstructionFlags f = i.flags;
    if (i == I_NOP) begin
        return "NOP";
    end else if (f.is_ebreak) begin
        return "EBREAK";
    end else if (f.branch_condition != BC_NEVER) begin
        if (f.branch_condition == BC_ALWAYS) return $sformatf("JUMP imm=%0d", i.immediate);
        else return $sformatf("BRANCH %s(%0s %0s %0s) imm=%0d", f.branch_condition == BC_CMP_TRUE ? "" : "!",
                Reg_name(i.rs1), ComparatorOp_name(i.cmp_op), Reg_name(i.rs2), i.immediate);
    end else begin
        return $sformatf("%s rd=%s rs1=%s %0s=%s", f.ram_write ? "SW" : f.rd_src == RD_RAM_OUT ? "LW" : i.alu_op.name(),
                Reg_name(i.rd), Reg_name(i.rs1),
                f.alu_src2 == ALU2_IMM ? "imm" : "rs2",
                f.alu_src2 == ALU2_IMM ? $sformatf("%0d", $signed(i.immediate)) : Reg_name(i.rs2));
    end
endfunction

`endif