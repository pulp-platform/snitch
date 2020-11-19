__thread int a = 42;
__thread int b = 0;
__thread int c = 99;

int main() {
    return (a != 42) + (b != 0) + (c != 99);
}
