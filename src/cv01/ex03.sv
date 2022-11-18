module ex01(input a, b, c, d, output x);
    assign x = a ? b & c : (b ^ d) | c;
endmodule