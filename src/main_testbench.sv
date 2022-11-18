module and_tb;
    reg A,B;
    wire C;
    and_gate dut(.a(A), .b(B), .c(C));

    initial begin
        #5 A=1; B=1;
        #5 A=0; B=1;
        #5 A=1; B=0;
        #5 A=1; B=1;
    end

    initial begin
        $dumpfile("build/wave.vcd"); // create a VCD waveform dump called "wave.vcd"
        $dumpvars(0, dut); // dump variable changes in the testbench
                           // and all modules under it
        $monitor("simtime = %g, A = %b, B = %b, C = %b", $time, A, B, C);
    end
endmodule