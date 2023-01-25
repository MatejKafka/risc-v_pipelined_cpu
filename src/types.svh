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
    ADD  = 'b0_000, // addition
    SUB  = 'b1_000, // subtraction
    SLL  = 'b0_001, // shift left logical
    SLT  = 'b0_010, // set less-than
    SLTU = 'b0_011, // set less-than unsigned
    XOR  = 'b0_100,
    SRL  = 'b0_101, // shift right logical
    SRA  = 'b1_101, // shift right arithmetic
    OR   = 'b0_110,
    AND  = 'b0_111
} AluOp;

// these op numbers also correspond to B-format funct3 values
typedef enum logic [1:0] {
    C_EQ   = 'b00,
    C_LT   = 'b10,
    C_LTU  = 'b11,
    C_NONE = 'b01 // any op is ok, the result is not relevant
} ComparatorOp;

typedef struct packed {
    logic decoder;
    logic alu;
} CpuError;


function string AluOp_symbol(AluOp op);
    case (op)
        ADD:  return "+";
        SUB:  return "-";
        SLL:  return "<<";
        SLT:  return "<s";
        SLTU: return "<u";
        XOR:  return "^";
        SRL:  return ">>";
        SRA:  return ">>>";
        OR:   return "|";
        AND:  return "&";
        default: return "INVALID ALU OPERATION";
    endcase
endfunction

function string ComparatorOp_name(ComparatorOp op);
    case (op)
        C_EQ:  return "==";
        C_LT:  return "<s";
        C_LTU: return "<u";
        C_NONE: return "COMPARATOR IDLE";
    endcase
endfunction

function string Reg_name(RegAddress r);
    case (r)
        0:  return "x0/zero";
        1:  return "x1/ra";
        2:  return "x2/sp";
        3:  return "x3/gp";
        4:  return "x4/tp";
        5:  return "x5/t0";
        6:  return "x6/t1";
        7:  return "x7/t2";
        8:  return "x8/s0";
        9:  return "x9/s1";
        10: return "x10/a0";
        11: return "x11/a1";
        12: return "x12/a2";
        13: return "x13/a3";
        14: return "x14/a4";
        15: return "x15/a5";
        16: return "x16/a6";
        17: return "x17/a7";
        18: return "x18/s2";
        19: return "x19/s3";
        20: return "x20/s4";
        21: return "x21/s5";
        22: return "x22/s6";
        23: return "x23/s7";
        24: return "x24/s8";
        25: return "x25/s9";
        26: return "x26/s10";
        27: return "x27/s11";
        28: return "x28/t3";
        29: return "x29/t4";
        30: return "x30/t5";
        31: return "x31/t6";
    endcase
endfunction

`endif