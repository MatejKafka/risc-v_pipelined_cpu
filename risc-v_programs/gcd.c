// found and adapted from here:
// https://codereview.stackexchange.com/questions/190542/find-gcd-of-two-numbers-without-using-multiplication-division-or-modulus-operat
__attribute__((always_inline))
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

__attribute__((noreturn))
void _start() {
    volatile int* result_ptr = (void*)0x0;
    volatile int* a_ptr = (void*)0x4;
    volatile int* b_ptr = (void*)0x8;

    *a_ptr = 99;
    *b_ptr = 22;

    *result_ptr = gcd(*a_ptr, *b_ptr);

    asm volatile ("EBREAK" ::: "memory");
    __builtin_unreachable();
}