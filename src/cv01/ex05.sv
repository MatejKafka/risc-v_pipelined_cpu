module ex01(input a, b, c, output x, y);
    assign x = ~(a | b) | (b & c);
    assign y = (b & c) ^ c;
endmodule

module ex05(input a, b, c, output x, y, z);
    wire aa, bb, cc;
    ex01 A(a, b, c, aa, bb);
    ex01 B(a, b, c, cc, z);
    ex01 C(aa, bb, cc, x, y);
endmodule