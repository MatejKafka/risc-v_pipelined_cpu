`ifndef PACKAGE_INSTRUCTION_TYPES
`define PACKAGE_INSTRUCTION_TYPES

typedef logic signed [20:0] Immediate;

typedef struct packed {
    logic is_ebreak;
    logic is_branch;
    logic alu_should_be_zero;
    logic next_pc_to_rd; // used for JAL/JALR
    logic alu_use_imm;
} InstructionFlags;


logic [4:0] IF_NONE = InstructionFlags'{default: 0};
logic [4:0] IF_IS_EBREAK = InstructionFlags'{is_ebreak: 1, default: 0};
logic [4:0] IF_IS_BRANCH = InstructionFlags'{is_branch: 1, default: 0};
logic [4:0] IF_ALU_SHOULD_BE_ZERO = InstructionFlags'{alu_should_be_zero: 1, default: 0};
logic [4:0] IF_NEXT_PC_TO_RD = InstructionFlags'{next_pc_to_rd: 1, default: 0};
logic [4:0] IF_ALU_USE_IMM = InstructionFlags'{alu_use_imm: 1, default: 0};

typedef struct packed {
    InstructionFlags flags;
    AluOp alu_op;
    RegAddress rd;
    RegAddress rs1;
    RegAddress rs2;
    Immediate immediate;
} Instruction;

`endif