#!/usr/bin/env fish

# run the gcd program on the CPU with 100 random inputs, print out the results

for i in (seq 0 99)
    set A (random 0 100)
    set B (random 0 1000)
    sed -e 's/{{A}}/'$A'/' -e 's/{{B}}/'$B'/' gcd_template.c >../gcd.c
    make --directory .. 2>/dev/null | sed -nE 's/^\s*0x0. = (\d*)\s*/\1/p' | tr "\n" "," | xargs echo
end >>_results.csv