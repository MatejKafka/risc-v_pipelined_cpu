`ifndef PACKAGE_ROM
`define PACKAGE_ROM
`include "types.sv"

module rom(input RomAddress address, output Word out);
    `TRACE(address or out, 33, ("📁i address=0x%00h out=%0d", address, out))

    // addresses are in bytes, but our slots are Word-sized
    Word memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    // load up "rom.mem" to the ROM
    initial $readmemh("rom.mem", memory);

    // read port
    assign out = memory[`WORD_ADDRESS(address)];
endmodule

`ifdef TEST_rom
module rom_tb;
    RamAddress address;
    wire Word out;

    rom rom(address, out);

    initial begin
        $dumpfile("rom.vcd");
        $dumpvars(0, rom_tb);
    end
    initial begin
        // try to read the first few words
        show(0);
        show(4);
        show(8);
        show('hffff);
    end

    task show(RomAddress address_);
        address = address_;
        #1;
        $display("0x%00h = %0d", address, out);
    endtask
endmodule
`endif

`endif