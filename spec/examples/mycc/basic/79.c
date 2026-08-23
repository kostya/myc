int printf(const char *fmt, ...);

void test(int a, int b) {}
int sub(int a, int b) { return a - b; }

#define bla(a, b) (test(a, b), sub(a, b))

int main() {
  int c = bla(1, 2);
  printf("c = %d\n", c);
  return 0;
}
