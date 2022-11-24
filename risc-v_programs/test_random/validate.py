#!/usr/bin/env python3

import math

with open("_results.csv", "r") as fd:
    results_txt = fd.readlines()

parsed = [[int(s) for s in l.strip().split(",") if s != ""] for l in results_txt]
# if one of the operands is 0, it is not printed from the simulation
parsed3 = [a for a in parsed if len(a) == 3]
for r, a, b in parsed3:
    if math.gcd(a, b) != r:
        print("wrong")
