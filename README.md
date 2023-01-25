# RISC-V CPU with 5-stage pipeline

Implemented as part of the [Advanced Computer Architectures course](https://cw.fel.cvut.cz/wiki/courses/b4m35pap/start) at FEE CTU.

## Building & simulating

The project is built & ran automatically in one step, using Verilator. To run the provided GCD example program in `test_programs/src/gcd.c`, call `make run-scalar` (to run it in scalar mode) or `make run-pipelined` (to run it with the 5-stage pipeline).

The `Makefile` invokes the `run.sh` script, which compiles and executes a selected testbench module. You can use it directly like so:

```
./run.sh [-d] [-n] [-v] <module_name> [<rom_memh_image_path>]
```

For example, the following command executes the GCD program on the pipelined CPU:

```shell
./run.sh -d main_pipelined ./test_programs/build/gcd.memh
```

## Visualization

GTKWave config files are provided in the `gtkwave_config` directory, with pre-configured views for the `cpu.sv` and `cpu_pipelined.sv` module traces.