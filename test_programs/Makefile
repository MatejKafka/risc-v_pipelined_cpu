.PHONY: all dump clean
.PRECIOUS: %.memh %.bin

TOOLCHAIN := riscv64-unknown-elf
# compilation works correctly with clang, but we need binutils for riscv64 to manipulate the compiled binary
#CC := clang -target riscv32-freestanding-none
CC := $(TOOLCHAIN)-gcc
OBJDUMP := $(TOOLCHAIN)-objdump
OBJCOPY := $(TOOLCHAIN)-objcopy

CPU_RUNNER := ../run.sh

CFLAGS += -O2 -fno-delete-null-pointer-checks
# no need for -fpie, we place .text to a static address in linker.ld
CFLAGS += -static -nostdinc -nostdlib -ffreestanding
CFLAGS += -march=rv32i -mabi=ilp32
# -ffunction-sections = write each function into a separate section to allow us to manipulate their order in linker.ld
CFLAGS += -ffunction-sections -T linker.ld
CFLAGS += $(EXTRA_CFLAGS)


all: build/gcd.memh

dump: build/gcd.elf
	$(OBJDUMP) -d $^ --visualize-jumps=color --no-show-raw-insn

clean:
	rm -rf build


build/%.elf: src/%.c
	@mkdir -p build
	$(CC) $^ -o $@ $(CFLAGS)

%.bin: %.elf
	$(OBJCOPY) -j .text -O binary $^ $@

%.memh: %.bin
	hexdump -v -e '"%08x\n"' <$^ >$@
