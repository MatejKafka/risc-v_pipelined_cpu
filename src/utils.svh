`ifndef PACKAGE_UTILS
`define PACKAGE_UTILS

function string ansi(integer color_n);
    return $sformatf("%c[1;%0dm", 8'd27, color_n);
endfunction
function string ansi_reset;
    return $sformatf("%c[0m", 8'd27);
endfunction

// use by passing $display arguments with parenthesis around them, e.g. '`DISPLAY_COLOR(("%d", num));'
`define DISPLAY_COLOR(COLOR_N, DISPLAY_EXPR) $display("%s%s%s", ansi(COLOR_N), $sformatf DISPLAY_EXPR, ansi_reset())

// use macro instead of a function to get the correct error location
`define PANIC(msg) $fatal(0, "%s%s%s", ansi(31), msg, ansi_reset())


// allow the testbench to supress error/status prints, especially before the initial reset
logic SUPRESS_ERRORS = 0;
logic SUPRESS_TRACE = 0;

// optionally defined in the build script
`ifdef DEBUG
    `define DBG(expr) if (1) expr
    // log all changes to the signals in `what`; for some reason, Verilator is weird
    //  about $monitor and only shows it in debug mode, but that does not work together
    //  with initial value randomization (not sure why), so we don't use it here
    `define TRACE(WHAT, COLOR_N, DISPLAY_EXPR) \
        always @ (WHAT) if (!SUPRESS_TRACE) `DISPLAY_COLOR(COLOR_N, DISPLAY_EXPR);
`else
    `define DBG(expr) if (0) expr
    `define TRACE(what, color_n, display_expr)
`endif

// assumes that `error` is an output signal
`define ERROR(DISPLAY_EXPR) do begin \
        error = 1; \
        if (!SUPRESS_ERRORS) `DISPLAY_COLOR(31, DISPLAY_EXPR); \
    end while (0)

`endif