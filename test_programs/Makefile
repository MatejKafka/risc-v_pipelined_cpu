.PHONY: all dump clean
.PRECIOUS: %.memh %.bin

ARCH := riscv64-unknown-elf

ifeq ($(C), zig)
CC := zig cc -target riscv32-freestanding-none
else ifeq ($(C), clang)
CC := clang -target riscv32-freestanding-none
else
CC := $(ARCH)-gcc # default = GCC
endif

OBJDUMP := $(ARCH)-objdump
OBJCOPY := $(ARCH)-objcopy


ifneq ($(filter zig zig.exe, $(firstword $(CC))),)
# zig cc
CFLAGS += -march=generic_rv32
else
# gcc/clang
CFLAGS += -march=rv32i -mabi=ilp32 -lgcc
endif

ifeq ($(firstword $(CC)), clang)
# clang wouldn't find libgcc.a without adding this link directory
CFLAGS += -L /lib/gcc/$(ARCH)/*/rv32i/ilp32
endif


CFLAGS += -O2 -fno-delete-null-pointer-checks
# no need for -fpie, we place .text to a static address in linker.ld
CFLAGS += -static -nostdinc -nostdlib -ffreestanding
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
