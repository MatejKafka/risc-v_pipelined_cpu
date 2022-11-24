`ifndef PACKAGE_INSTRUCTION_TYPES
`define PACKAGE_INSTRUCTION_TYPES

typedef logic signed [31:0] Immediate;

typedef enum logic [1:0] {
    RD_ALU_OUT = 0,
    RD_NEXT_PC = 1,
    RD_RAM_DATA = 2
} RdSrc;

typedef struct packed {
    logic is_ebreak;
    logic is_branch;
    logic alu_should_be_zero;
    logic next_pc_to_rd; // used for JAL/JALR
    logic alu_use_imm;
    logic ram_write;
    logic ram_read_to_rd;
    logic pc_to_alu_src1;
} InstructionFlags;

// enum-like setters for InstructionsFlags, to simplify the decoder code
`define IF_ENUM_VALUE(NAME, FIELD) logic [$bits(InstructionFlags)-1:0] NAME = InstructionFlags'{FIELD: 1, default: 0}
logic [$bits(InstructionFlags)-1:0] IF_NONE = InstructionFlags'{default: 0};
`IF_ENUM_VALUE(IF_IS_EBREAK, is_ebreak);
`IF_ENUM_VALUE(IF_IS_BRANCH, is_branch);
`IF_ENUM_VALUE(IF_ALU_SHOULD_BE_ZERO, alu_should_be_zero);
`IF_ENUM_VALUE(IF_NEXT_PC_TO_RD, next_pc_to_rd);
`IF_ENUM_VALUE(IF_ALU_USE_IMM, alu_use_imm);
`IF_ENUM_VALUE(IF_RAM_WRITE, ram_write);
`IF_ENUM_VALUE(IF_RAM_READ_TO_RD, ram_read_to_rd);
`IF_ENUM_VALUE(IF_PC_TO_ALU_SRC1, pc_to_alu_src1);

typedef struct packed {
    InstructionFlags flags;
    AluOp alu_op;
    RegAddress rd;
    RegAddress rs1;
    RegAddress rs2;
    Immediate immediate;
} Instruction;


// this is just a rough dump of (some) relevant values
function string Instruction_to_string(Instruction i);
    automatic InstructionFlags f = i.flags;
    if (i == Instruction'{IF_ALU_USE_IMM, ADD, 0, 0, 0, 0}) return "NOP"; // NOP = ADDI 0, 0, 0
    else if (f.is_ebreak) return "EBREAK";
    else if (f.is_branch) return $sformatf("BRANCH alu_zero=%0d rs1=%0d rs2=%0d jump=%0d", f.alu_should_be_zero, i.rs1, i.rs2, i.immediate);
    else begin
        return $sformatf("%s rd=%s rs1=%s %0s=%s", f.ram_write ? "SW" : f.ram_read_to_rd ? "LW" : i.alu_op.name(),
                Reg_name(i.rd), Reg_name(i.rs1),
                f.alu_use_imm ? "imm" : "rs2",
                f.alu_use_imm ? $sformatf("%0d", i.immediate) : Reg_name(i.rs2));
    end
endfunction

`endif