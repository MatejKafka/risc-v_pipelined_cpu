#!/usr/bin/env python3

import math

while True:
    try:
        l = input()
    except EOFError:
        break
    parsed = [int(s) for s in l.strip().split(",") if s != ""]
    # if one of the operands is 0, it is not printed from the simulation
    if len(parsed) != 3:
        continue
    r, a, b = parsed
    if math.gcd(a, b) == r:
        print(f"OK: gcd({a}, {b}) = {r}")
    else:
        print(f"WRONG: gcd({a}, {b}) != {r}")
        break
