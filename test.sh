#!/usr/bin/env bash
set -e

visualize=0
target_rel=
if [[ "$1" == "-v" ]]; then
    visualize=1
    target_rel=$2
elif [[ "$2" == "-v" ]]; then
    visualize=1
    target_rel=$1
else
    target_rel=$1
fi

build_dir="$(realpath $(dirname $BASH_SOURCE)/build)"
src_dir="$(realpath $(dirname $BASH_SOURCE)/src)"

tb_enabler="TEST_$(basename "$target_rel")"
target="$build_dir/$target_rel.vvp"
target_output="$build_dir/$target_rel.vcd"
target_dir="$(dirname "$target")"
src="$src_dir/$target_rel.sv"

mkdir -p "$(dirname "$target")"
# run verilator in --lint-only mode to get better error messages
#verilator --lint-only --timing -D"$tb_enabler" -I"$src_dir" "$src"
iverilog -g2012 -Wall -t vvp -D"$tb_enabler" -I"$src_dir" -o "$target" "$src"
cd "$target_dir"
vvp "$target"

if [[ "$visualize" == "1" ]]; then
    gtkwave.exe "$(realpath --relative-to=. "$target_output")" 1>/dev/null 2>/dev/null
fi