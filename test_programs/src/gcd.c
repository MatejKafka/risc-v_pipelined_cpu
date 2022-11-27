// optionally set during compilation, since we cannot read input at runtime
#ifndef GCD_A
#define GCD_A 99
#endif
#ifndef GCD_B
#define GCD_B 22
#endif


// found and adapted from here:
// https://codereview.stackexchange.com/questions/190542/find-gcd-of-two-numbers-without-using-multiplication-division-or-modulus-operat
unsigned int gcd(unsigned int a, unsigned int b){
    unsigned int shift = 0;
    while (1) {
        if(a == 0) return b << shift;
        if(b == 0) return a << shift;

        char a_even = !(a & 1);
        char b_even = !(b & 1);

        if (a_even && b_even) {
            a >>= 1;
            b >>= 1;
            shift++;
        } else if (a_even && !b_even) {
            a >>= 1;
        } else if (!a_even && b_even) {
            b >>= 1;
        } else if (a <= b) {
            b = b - a;
        } else {
            unsigned int tmp = b;
            b = a - b;
            a = tmp;
        }
    }
}

unsigned int gcd_recursive(unsigned int a, unsigned int b) {
    if (a == 0) return b;
    if (b == 0) return a;
    char a_even = (a & 1) == 0;
    char b_even = (b & 1) == 0;
    if (a_even && b_even) {
        return gcd_recursive(a >> 1, b >> 1) << 1;
    } else if (a_even && !b_even) {
        return gcd_recursive(a >> 1, b);
    } else if (!a_even && b_even) {
        return gcd_recursive(a, b >> 1);
    } else if (a <= b) {
        return gcd_recursive(a, b - a);
    } else {
        return gcd_recursive(b, a - b);
    }
}

int main() {
    volatile unsigned int *result_ptr = (void *)0x0;
    volatile unsigned int *a_ptr = (void *)0x4;
    volatile unsigned int *b_ptr = (void *)0x8;

    *a_ptr = GCD_A;
    *b_ptr = GCD_B;

    *result_ptr = gcd_recursive(*a_ptr, *b_ptr);
    return 0;
}

__attribute__((noreturn)) void _start() {
    main();
    asm volatile ("EBREAK" ::: "memory");
    __builtin_unreachable();
}
