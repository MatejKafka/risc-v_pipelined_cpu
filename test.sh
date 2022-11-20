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
target="$build_dir/$target_rel.vvp"
target_output="$build_dir/$target_rel.vcd"
target_dir="$(dirname "$target")"
src="$src_dir/$target_rel.sv"

mkdir -p "$(dirname "$target")"
# run slang in --lint-only mode to get better error messages
slang.exe --lint-only -D"$tb_enabler" "${debug[@]}" -I"$(wslpath -w "$src_dir")" "$(wslpath -w "$src")" --quiet
iverilog -g2012 -Wall -t vvp -D"$tb_enabler" "${debug[@]}" -I"$src_dir" -o "$target" "$src"
cd "$target_dir"
vvp "$target"

if [[ "$visualize" == "1" ]]; then
    gtkwave.exe "$(realpath --relative-to=. "$target_output")" 1>/dev/null 2>/dev/null
fi