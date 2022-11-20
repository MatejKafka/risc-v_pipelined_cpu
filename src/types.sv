`ifndef PACKAGE_TYPES
`define PACKAGE_TYPES

timeunit 1s;
timeprecision 100ms;

`define BYTES(D) ($bits(D) >> 3)

typedef logic [31:0] Word;
// how many bits are needed to index all bytes of Word, useful for memory accesses
`define WORD_ADDRESS_SIZE $clog2(`BYTES(Word))
// convert address to a word index (e.g. with 32bit Word, 0xC is converted to 3)
`define WORD_ADDRESS(ADDRESS) ADDRESS[$bits(ADDRESS)-1 : `WORD_ADDRESS_SIZE]

typedef logic [4:0] RegAddress;
typedef logic [15:0] RamAddress;
typedef logic [15:0] RomAddress;

`ifdef DEBUG
`define DBG(expr) if (1) expr
`else
`define DBG(expr) if (0) expr
`endif


`endif