int printf(const char *fmt, ...);

int main() {
  int a;
  int b;
  int c = ({
    a = 1;
    b = 2;
    a + b;
  });
  printf("a = %d, b = %d, c = %d\n", a, b, c);
  return 0;
}
