`ifndef PACKAGE_UTILS
`define PACKAGE_UTILS

function string ansi(integer color_n);
    return $sformatf("%c[1;%0dm", 8'd27, color_n);
endfunction
function string ansi_reset;
    return $sformatf("%c[0m", 8'd27);
endfunction

// 32'h8000_0002 = stderr
// use by passing $display arguments with parenthesis around them, e.g. '`LOG_COLOR(("%d", num));'
`define LOG_COLOR(COLOR_N, DISPLAY_EXPR) $fdisplay(32'h8000_0002, "%s%s%s", ansi(COLOR_N), $sformatf DISPLAY_EXPR, ansi_reset())

// use macro instead of a function to get the correct error location
`define PANIC(msg) $fatal(0, "%s%s%s", ansi(31), msg, ansi_reset())


// allow the testbench to supress error/status prints, especially before the initial reset
logic SUPRESS_ERRORS = 0;
logic SUPRESS_TRACE = 0;

logic DEBUG_MODE = logic'($test$plusargs("DEBUG"));

`ifndef NO_TRACING
// log all changes to the signals in `what`; for some reason, Verilator is weird
//  about $monitor and only shows it in debug mode, but that does not work together
//  with initial value randomization (not sure why), so we don't use it here
`define TRACE(WHAT, COLOR_N, DISPLAY_EXPR) \
    always @ (WHAT) if (DEBUG_MODE && !SUPRESS_TRACE) `LOG_COLOR(COLOR_N, DISPLAY_EXPR);
`else
    `define TRACE(what, color_n, display_expr)
`endif

// assumes that `error` is an output signal
`define ERROR(DISPLAY_EXPR) do begin \
        error = 1; \
        if (!SUPRESS_ERRORS) `LOG_COLOR(31, DISPLAY_EXPR); \
    end while (0)

`endif