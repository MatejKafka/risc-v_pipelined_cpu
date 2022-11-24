`ifndef PACKAGE_ROM
`define PACKAGE_ROM
`include "types.svh"
`include "utils.svh"

module rom(input RomAddress address, output Word out);
    `TRACE(address or out, 33, ("📁i address=0x%00h out=0x%h", address, out))

    // addresses are in bytes, but our slots are Word-sized
    Word memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    // read port
    assign out = memory[`WORD_ADDRESS(address)];

    // load up `gcd.memh` to the ROM
    initial $readmemh("../risc-v_programs/gcd.memh", memory);

    // // load up `gcd.bin` to the ROM
    // initial begin
    //     automatic int fd;
    //     fd = $fopen("../risc-v_programs/gcd.bin", "rb");
    //     if (fd == 0) `PANIC("ROM: Could not load the program from '../risc-v_programs/gcd.bin'. Does the file exist?");
    //     else if ($fread(memory, fd) == 0) `PANIC("ROM: The loaded program file seems empty.");
    //     else $fclose(fd);
    // end
endmodule

`ifdef TEST_rom
module rom_tb;
    RomAddress address;
    Word out;

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
    end

    task show(RomAddress address_);
        address = address_;
        #1;
        $display("0x%00h = %0d", address, out);
    endtask
endmodule
`endif

`endif