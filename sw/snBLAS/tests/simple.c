#include <stdio.h>
#include <snblas.h>

int main() {
    double x = snblas_hello();
    printf("Hello from snBLAS: 0x%llx\n", *(unsigned long long *)&x);
    return 0;
}
