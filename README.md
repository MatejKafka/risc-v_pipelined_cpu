# RISC-V CPU with a 5-stage pipeline

Implemented as part of the [Advanced Computer Architectures course](https://cw.fel.cvut.cz/wiki/courses/b4m35pap/start) at FEE CTU.

## Dependencies

- GNU Make & Bash
- Verilator 5.2 or later (or another SystemVerilog simulator)

## Building & simulating

The project is built & ran automatically in one step, using Verilator. To run the provided GCD example program in `test_programs/src/gcd.c`, call `make run-scalar` (to run it in scalar mode) or `make run-pipelined` (to run it with the 5-stage pipeline).

The `Makefile` invokes the `run.sh` script, which compiles and executes a selected testbench module. You can also use it directly (run `./run.sh -h` to get usage information). For example, the following command executes the GCD program on the pipelined CPU:

```shell
./run.sh -d main_pipelined ./test_programs/build/gcd.memh
```

## Visualization

GTKWave config files are provided in the `gtkwave_config` directory, with pre-configured views for the `cpu.sv` and `cpu_pipelined.sv` module traces.

## Project structure

Each component of the CPU has a testbench defined in the same file as the module itself. Most of the file names should be self-explanatory.

* `src/main.sv` – main module wrapping the scalar CPU
* `src/main_pipelined.sv` – main module wrapping the pipelined CPU
* `src/cpu.sv` – the scalar CPU
* `src/cpu_pipelined.sv` – the main pipelined CPU module
	* `src/pipeline_stages.svh` – modules for the 5 pipeline stages
	* `src/pipeline_types.svh` – structs representing the interstage registers of the pipeline