#!/usr/bin/env fish

# run the gcd program on the CPU with 100 random inputs, print out the results

mkdir -p ../build
for i in (seq 0 99)
    set base (random 1 20)
    set base2 (random 1 20)
    set add (random 0 10 20)
    set A (math $add + $base '*' $base2 '*' (random 1 20))
    set B (math $add + $base '*' $base2 '*' (random 1 1000))
    make clean --directory .. --quiet 2>/dev/null
    make run --directory ../.. --quiet EXTRA_CFLAGS="-DGCD_A=$A -DGCD_B=$B" 2>/dev/null \
        | sed -nE 's/^\s*0x0. = (\d*)\s*/\1/p' | tr "\n" "," | xargs echo
end | ./validate.py
