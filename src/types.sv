`ifndef PACKAGE_TYPES
`define PACKAGE_TYPES

timeunit 1s;
timeprecision 100ms;

typedef logic [31:0] Reg;
`define REG_ADDRESS_WIDTH 5
typedef logic [`REG_ADDRESS_WIDTH-1:0] RegAddress;

`ifdef DEBUG
`define DBG(expr) if (1) expr
`else
`define DBG(expr) if (0) expr
`endif


`endif