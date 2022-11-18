module ex01_tb;
    reg a, b, c;
    wire x, y, z;
    ex05 dut(a, b, c, x, y, z);

    initial begin
        $dumpfile("ex05.vcd");
        $dumpvars;
        $timeformat(0, 0, "", 6);
    end

    initial begin
        a = 0;
        b = 0;
        c = 0;
        #140 $finish;
    end

    always #80 a = ~a;
    always #40 b = ~b;
    always #20 c = ~c;

    always begin
        $strobe("Time=%t, x=%b, y=%b, z=%b. Inputs: a=%b, b=%b, c=%b",
            $time, x, y, z, a, b, c);
        #20;
    end
endmodule