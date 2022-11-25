`ifndef PACKAGE_ROM_DECODE_TEST
`define PACKAGE_ROM_DECODE_TEST

`include "rom.sv"
`include "instruction_decoder.sv"

`ifdef TEST_rom_decode_test
`include "instruction_macros.svh"
module rom_decode_test_tb;
    RomAddress rom_address = 0;
    UWord rom_out;
    rom rom(rom_address, rom_out);

    logic error;
    // fake input so we don't get decoder errors
    UWord decoder_in = `R_NOP;
    Instruction instruction;
    instruction_decoder decoder(error, decoder_in, instruction);

    initial begin
        #1;
        foreach (rom.memory[i]) begin
            if (rom.memory[i] == -1) continue;
            $display("0x%h: %s", RomAddress'(i * 4), Instruction_to_string(decoder.decode_instruction(rom.memory[i])));
        end
        $finish();
    end
endmodule
`endif

`endif