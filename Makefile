.PHONY: all dump run test decode trace clean

PROGRAM_MEMH = test_programs/build/gcd.memh

all: run

dump:
	@$(MAKE) dump --directory test_programs --no-print-directory

run: $(PROGRAM_MEMH)
	./run.sh main $<

test: $(PROGRAM_MEMH)
	./run_all.sh $<

debug: $(PROGRAM_MEMH)
	./run_all.sh $< -d

decode: $(PROGRAM_MEMH)
	./run.sh rom_decode_test $<

# prints all instructions as they're decoded, followed by a memory (RAM) dump
trace: $(PROGRAM_MEMH)
	./run.sh main $< -d 2>&1 1>build/TMP.dbg_output.txt \
		| grep -E "🈯|📁i" \
		| sed -nE 'N; s/📁i address=(0x[0-9a-f]+) out=0x[0-9a-f]+....\n(.......)🈯/\1: \2/p; D'
	@cat build/TMP.dbg_output.txt \
		| sed -nE '/^RAM:$$/,/^$$/ p' \
		| head -n -1
	@rm build/TMP.dbg_output.txt

test_programs/%:
	$(MAKE) $* --directory test_programs

clean:
	$(MAKE) clean --directory test_programs
	rm -rf build