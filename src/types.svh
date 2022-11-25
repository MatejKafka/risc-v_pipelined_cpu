`ifndef PACKAGE_TYPES
`define PACKAGE_TYPES

timeunit 1s;
timeprecision 100ms;

const logic TRUE = 1;
const logic FALSE = 0;

`define BYTES(D) ($bits(D) >> 3)


typedef logic signed [31:0] Word;
typedef logic unsigned [31:0] UWord;
// how many bits are needed to index all bytes of Word, useful for memory accesses
`define WORD_ADDRESS_SIZE $clog2(`BYTES(Word))
// convert address to a word index (e.g. with 32bit Word, 0xC is converted to 3)
`define WORD_ADDRESS(ADDRESS) ADDRESS[$bits(ADDRESS)-1 : `WORD_ADDRESS_SIZE]

typedef logic [4:0] RegAddress;
typedef logic [7:0] RamAddress;
typedef logic [15:0] RomAddress;


// the ALU op numbers correspond to their RV encoding {funct7[5], funct3} to simplify decoding
// if this is changed, the RV decoder must be changed accordingly
typedef enum logic [3:0] {
    ADD  = 4'b0_000, // addition
    SUB  = 4'b1_000, // subtraction
    SLL  = 4'b0_001, // shift left logical
    SLT  = 4'b0_010, // set less-than
    SLTU = 4'b0_011, // set less-than unsigned
    XOR  = 4'b0_100,
    SRL  = 4'b0_101, // shift right logical
    SRA  = 4'b1_101, // shift right arithmetic
    OR   = 4'b0_110,
    AND  = 4'b0_111
} AluOp;

function string AluOp_symbol(AluOp op);
    case (op)
        ADD: AluOp_symbol = "+";
        SUB: AluOp_symbol = "-";
        SLL: AluOp_symbol = "<<";
        SLT: AluOp_symbol = "<s";
        SLTU:AluOp_symbol = "<u";
        XOR: AluOp_symbol = "^";
        SRL: AluOp_symbol = ">>";
        SRA: AluOp_symbol = ">>>";
        OR:  AluOp_symbol = "|";
        AND: AluOp_symbol = "&";
        default: AluOp_symbol = "INVALID ALU OPERATION";
    endcase
endfunction

function string Reg_name(RegAddress r);
    case (r)
        0:  return "zero";
        1:  return "ra";
        2:  return "sp";
        3:  return "gp";
        4:  return "tp";
        5:  return "t0";
        6:  return "t1";
        7:  return "t2";
        8:  return "s0";
        9:  return "s1";
        10: return "a0";
        11: return "a1";
        12: return "a2";
        13: return "a3";
        14: return "a4";
        15: return "a5";
        16: return "a6";
        17: return "a7";
        18: return "s2";
        19: return "s3";
        20: return "s4";
        21: return "s5";
        22: return "s6";
        23: return "s7";
        24: return "s8";
        25: return "s9";
        26: return "s10";
        27: return "s11";
        28: return "t3";
        29: return "t4";
        30: return "t5";
        31: return "t6";
    endcase
endfunction

`endif