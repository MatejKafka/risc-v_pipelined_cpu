.PHONY: all build run debug dump test-decode clean
.PRECIOUS: %.memh %.dump %.elf

CC := riscv64-unknown-elf-gcc
OBJDUMP := riscv64-unknown-elf-objdump

all: run


%.elf: %.c
	@# -O1 cleans up the program quite significantly
	$(CC) -static -nostdinc -nostdlib -ffreestanding -march=rv32i -mabi=ilp32 $^ -o $@ -O1

%.dump: %.elf
	$(OBJDUMP) -d $^ -M no-aliases >$@

%.memh: %.dump
	@# disassemble the '_start' function and get the hex values of the instructions
	cat $^ | sed -e '1,/<_start>:/ d' | awk '{ print($$2) }' >$@


build: gcd.memh

run: gcd.memh
	../test.sh main

debug: gcd.memh
	../test.sh main -d

dump: gcd.dump
	cat $^ | sed -e '1,/<_start>:/ d'

test-decode:
	../test.sh rom_decode_test

clean:
	rm -f *.elf *.dump *.memh
