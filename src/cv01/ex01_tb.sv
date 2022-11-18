module ex01_tb;
    reg a, b, c;
    wire d, e;
    ex01 dut(.a(a), .b(b), .c(c), .d(d), .e(e));

    initial begin
        $dumpfile("ex01.vcd");
        $dumpvars;
        a = 0;
        b = 0;
        c = 0;
        #160 $finish;
    end

    always #20 a = ~a;
    always #40 b = ~b;
    always #80 c = ~c;

    always @(d) $display(
        "The value of d was changed. Time=%d, x=%b. Inputs: a=%b, b=%b, c=%b.",
        $time, d, a, b, c);

    always @(e) $display(
        "The value of e was changed. Time=%d, y=%b. Inputs: a=%b, b=%b, c=%b.",
        $time, e, a, b, c);
endmodule