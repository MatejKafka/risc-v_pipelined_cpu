#!/usr/bin/env bash
set -Eeuo pipefail

# run test.sh for all .sv modules
script_dir="$(realpath $(dirname $BASH_SOURCE))"
find "${script_dir}/src" -maxdepth 1 -name '*.sv' | xargs -L1 basename --suffix .sv | xargs -L1 ./test.sh "$@"