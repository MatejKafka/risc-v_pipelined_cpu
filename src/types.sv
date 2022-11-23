`ifndef PACKAGE_TYPES
`define PACKAGE_TYPES

timeunit 1s;
timeprecision 100ms;

typedef enum logic {
    TRUE = 1,
    FALSE = 0
} Bool;

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
`define TRACE(what, color_n, display_expr) \
    always @ (what) begin \
        ansi(color_n); \
        $display display_expr; \
        ansi_reset(); \
    end
`else
`define DBG(expr) if (0) expr
`define TRACE(what, color_n, display_expr)
`endif

function void ansi(integer color_n);
    $write("%c[1;%0dm", 8'd27, color_n);
endfunction
function void ansi_reset;
    $write("%c[0m", 8'd27);
endfunction

function void panic(string msg);
    $display("%s", msg);
    $finish();
endfunction

// allow the testbench to supress error prints, especially before the initial reset
Bool SUPRESS_ERRORS = FALSE;
// assumes that `error` is an output signal
`define ERROR(display_expr) do begin \
        error = 1; \
        if (!SUPRESS_ERRORS) begin \
            ansi(31); \
            $display display_expr; \
            ansi_reset(); \
        end \
    end while (0)

`endif