#!/usr/bin/env bash
set -Eeuo pipefail

IFS=$'\n'

# run test.sh for all .sv modules

script_dir="$(realpath $(dirname $BASH_SOURCE))"
module_paths=("$(find "${script_dir}/src" -maxdepth 1 -name '*.sv')")
for p in $module_paths; do
	name="$(basename --suffix .sv "$p")"
	echo ""
	echo "=================================================================================================="
	echo "Running '$name':"
	echo "=================================================================================================="
	"$script_dir/test.sh" "$name" "$@"
done