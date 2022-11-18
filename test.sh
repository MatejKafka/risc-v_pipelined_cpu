#!/usr/bin/env bash

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

target="$build_dir/$target_rel.vvp"
target_output="$build_dir/$target_rel.vcd"
target_dir="$(dirname "$target")"
src="$src_dir/$target_rel.sv"
src_tb="$src_dir/${target_rel}_tb.sv"

srcs=("$src")
if [[ -e "$src_tb" ]]; then
    srcs+=("$src_tb")
fi

mkdir -p "$(dirname "$target")"
iverilog -t vvp -o "$target" "${srcs[@]}"
cd "$target_dir"
vvp "$target"

if [[ "$visualize" == "1" ]]; then
    gtkwave.exe "$(realpath --relative-to=. "$target_output")" 1>/dev/null 2>/dev/null
fi