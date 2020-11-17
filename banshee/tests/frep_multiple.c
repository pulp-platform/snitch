int main() {
    double x = 0;
    volatile register int N asm ("t0") = 4;
    asm volatile (
        ".word (1 << 20)|(5 << 15)|(1 << 7)|(0b0001011 << 0) \n" // frep t0, 2
        "fadd.d %0, %0, %1\n"
        "fmul.d %0, %0, %2\n"
        : "+f"(x) : "f"(1.0), "f"(2.0)
    );
    return x != 30;
}
