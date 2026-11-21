int printf(const char *fmt, ...);

int test(int x) {
  switch (x) {
  case 1:
    return 10;
  case 2:
    return 20;
  default:
    return 30;
  }
}

int main() {
  printf("%d\n", test(1));
  printf("%d\n", test(2));
  printf("%d\n", test(3));
  return 0;
}
