module ex01_tb;
    reg a, b, c, d;
    wire x;
    ex01 dut(.a(a), .b(b), .c(c), .d(d), .x(x));

    initial begin
        $dumpfile("ex03.vcd");
        $dumpvars;
        a = 0;
        b = 0;
        c = 0;
        d = 0;
        #320 $finish;
    end

    always #20 a = ~a;
    always #40 b = ~b;
    always #80 c = ~c;
    always #160 d = ~d;

    always @(x) $display(
        "The value of x was changed. Time=%d, x=%b. Inputs: a=%b, b=%b, c=%b.",
        $time, x, a, b, c);
endmodule