.PHONY: all run clean

all: build/main.vvp build/cv01/ex01.vvp

run: build/main.vvp
	vvp $^

build/%.vvp: src/%.sv src/%_tb.sv
	@mkdir -p $(dir $@)
	iverilog -t vvp -o $@ src/$*.sv src/$*_tb.sv

clean:
	rm -r build
