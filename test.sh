#!/usr/bin/env bash
set -e

visualize=0
debug=()
target_rel=
for arg in "$@"; do
    if [[ "$arg" == "-v" ]]; then
        visualize=1
    elif [[ "$arg" == "-d" ]]; then
        debug=("-DDEBUG")
    else
        target_rel="$arg"
    fi
done

build_dir="$(realpath $(dirname $BASH_SOURCE)/build)"
src_dir="$(realpath $(dirname $BASH_SOURCE)/src)"

tb_enabler="TEST_$(basename "$target_rel")"
target="$build_dir/$(dirname "$target_rel")/V$(basename "$target_rel")"
target_output="$build_dir/$target_rel.vcd"
target_dir="$(dirname "$target")"
src="$src_dir/$target_rel.sv"

mkdir -p "$target_dir"

# run slang (from Windows) in --lint-only mode to get better error messages
slang.exe --lint-only --quiet \
    -Wextra -Wpedantic -Wconversion \
    -D"$tb_enabler" "${debug[@]}" -I"$(wslpath -w "$src_dir")" "$(wslpath -w "$src")"

# compile to an executable
verilator \
    --binary --trace --build-jobs 0 -MAKEFLAGS "-s OPT_FAST=-O0 CXX=/usr/lib/ccache/gcc CXX=/usr/lib/ccache/g++" -CFLAGS "-fuse-ld=mold" \
    -Wall -Wpedantic -Wno-EOFNEWLINE -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
    --x-assign 1 --x-initial unique \
    --top-module "$(basename "$target_rel")_tb" -D"$tb_enabler" "${debug[@]}" \
    -I"$src_dir" --Mdir "$target_dir" -o "$target" "$src" \
    >/dev/null # hide build prints

cd "$target_dir"
# run the simulation, set a seed for the initial values of uninitialized variables to catch incorrect resets
# https://verilator.org/guide/latest/exe_sim.html
"$target" +verilator+rand+reset+1

if [[ "$visualize" == "1" ]]; then
    gtkwave.exe "$(realpath --relative-to=. "$target_output")" 1>/dev/null 2>/dev/null
fi