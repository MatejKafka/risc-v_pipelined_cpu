`ifndef PACKAGE_ROM
`define PACKAGE_ROM
`include "types.svh"
`include "utils.svh"

module rom(input RomAddress address, output UWord out);
    // addresses are in bytes, but our slots are UWord-sized
    UWord memory[0:(1 << ($bits(address) - `WORD_ADDRESS_SIZE)) - 1];

    // read port
    assign out = memory[`WORD_ADDRESS(address)];

    // load up the program passed in the `+ROM_PATH=<path>` simulator argument to the ROM
    initial begin
        string rom_path;
        int fd;
        if ($value$plusargs("ROM_PATH=%s", rom_path)) begin
            $readmemh(rom_path, memory);
        end else begin
            `PANIC("Missing 'ROM_PATH' argument, a path to the ROM content in .memh format must be provided.");
        end
    end

    // initial begin
    //    fd = $fopen(rom_path, "rb");
    //    if (fd == 0) `PANIC($sformatf("ROM: Could not load the program from '%s'. Does the file exist?", rom_path));
    //    else if ($fread(memory, fd) == 0) `PANIC("ROM: The loaded program file seems empty.");
    //    else $fclose(fd);
    // end

    task dump();
        $display("ROM:");
        foreach (memory[i]) begin
            // skip (probably) unused slots
            if (memory[i] != -1) $display("  0x%h = 0x%h", RomAddress'(i), memory[i]);
        end
    endtask
endmodule

`ifdef TEST_rom
module rom_tb;
    RomAddress address;
    UWord out;

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