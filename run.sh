#!/usr/bin/env bash
set -Eeuo pipefail


HELP="Usage: $0 [-dnh] <MODULE_NAME> [<ROM_PATH>]
Run the testbench for the selected module.

MODULE_NAME: name of a .sv file in the src directory, without the extension (e.g. 'cpu_pipelined')
ROM_PATH: path to a .memh file containing the ROM (compiled executable) that is loaded into ROM;
          the path is only used for modules which utilize the ROM ('main', 'main_pipelined')

  -d  enable debug trace prints during simulation
  -n  compile the code without tracing support (use -d to enable tracing at runtime)
  -h  display this help and exit

Example: $0 main test_programs/build/gcd.memh"


compiler_args=()
simulator_args=()
args=()
# https://stackoverflow.com/a/63421397
while [ $OPTIND -le "$#" ]; do
    if getopts :dnv option; then
        case $option in
            d) simulator_args+=("+DEBUG") ;;
            n) compiler_args+=("-DNO_TRACING") ;;
            h) echo "$HELP"; exit ;;
            ?) echo >&2 "$HELP"; exit 1 ;;
        esac
    else
        args+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

if [[ "${#args[@]}" == 0 ]]; then
    echo >&2 "$0: missing test module name"
    echo >&2 "Try '$0 -h' for more information."
    exit 2
fi

tested_module="${args[0]}"
if [[ "${#args[@]}" -ge 2 ]]; then
    simulator_args+=("+ROM_PATH=$(realpath "${args[1]}")")
fi


root_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
tb_enabler="TEST_$(basename "$tested_module")"
target="$root_dir/build/$(dirname "$tested_module")/V$(basename "$tested_module")"
target_output="$root_dir/build/$tested_module.vcd"
target_dir="$(dirname "$target")"
src="$root_dir/src/$tested_module.sv"

mkdir -p "$target_dir"

# compile to an executable
# to speed up the compilation a bit, I use the following extra arguments:
#  -CFLAGS "-fuse-ld=mold" -MAKEFLAGS "-s OPT_FAST=-O0 CXX=/usr/lib/ccache/gcc CXX=/usr/lib/ccache/g++"
verilator \
    --binary --trace --build-jobs 0 \
    -Wall -Wpedantic -Wno-EOFNEWLINE -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
    --x-assign 1 --x-initial unique \
    --top-module "$(basename "$tested_module")_tb" -D"$tb_enabler" "${compiler_args[@]}" \
    -I"$root_dir/src" --Mdir "$target_dir" -o "$target" "$src" \
    >/dev/null # hide build prints

cd "$target_dir"
# run the simulation, set all registers to '1 initially to catch incorrect resets
# https://verilator.org/guide/latest/exe_sim.html
"$target" +verilator+rand+reset+1 "${simulator_args[@]}"
