#!/usr/bin/env bash
set -Eeuo pipefail

visualize=0
compiler_args=()
simulator_args=()
args=()
# https://stackoverflow.com/a/63421397
while [ $OPTIND -le "$#" ]; do
    if getopts :dnv option; then
        case $option in
            d) simulator_args+=("+DEBUG") ;;
            n) compiler_args+=("-DNO_TRACING") ;;
            v) visualize=1 ;;
            ?) exit 1;;
        esac
    else
        args+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

if [[ "${#args[@]}" == 0 ]]; then echo >&2 "Missing test module name"; exit 2; fi
tested_module="${args[0]}"

if [[ "${#args[@]}" == 2 ]]; then
    simulator_args+=("+ROM_PATH=$(realpath "${args[1]}")")
fi


root_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
tb_enabler="TEST_$(basename "$tested_module")"
target="$root_dir/build/$(dirname "$tested_module")/V$(basename "$tested_module")"
target_output="$root_dir/build/$tested_module.vcd"
target_dir="$(dirname "$target")"
src="$root_dir/src/$tested_module.sv"

mkdir -p "$target_dir"

# run slang (from Windows) in --lint-only mode to get better error messages
# commented out to allow running on non-WSL Linux
#slang.exe --lint-only --quiet \
#    -Wextra -Wpedantic -Wconversion \
#    -D"$tb_enabler" "${compiler_args[@]}" -I"$(wslpath -w "$root_dir/src")" "$(wslpath -w "$src")"

# compile to an executable
verilator \
    --binary --trace --build-jobs 0 \
    -CFLAGS "-fuse-ld=mold" -MAKEFLAGS "-s OPT_FAST=-O0 CXX=/usr/lib/ccache/gcc CXX=/usr/lib/ccache/g++" \
    -Wall -Wpedantic -Wno-EOFNEWLINE -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
    --x-assign 1 --x-initial unique \
    --top-module "$(basename "$tested_module")_tb" -D"$tb_enabler" "${compiler_args[@]}" \
    -I"$root_dir/src" --Mdir "$target_dir" -o "$target" "$src" \
    >/dev/null # hide build prints

cd "$target_dir"
# run the simulation, set a seed for the initial values of uninitialized variables to catch incorrect resets
# https://verilator.org/guide/latest/exe_sim.html
"$target" +verilator+rand+reset+1 "${simulator_args[@]}"

if [[ "$visualize" == "1" ]]; then
    gtkwave.exe "$(wslpath -w "$target_output")" 1>/dev/null 2>/dev/null
fi