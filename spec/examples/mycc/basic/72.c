int printf(const char *fmt, ...);

int test_paren(int x) {
  if ((x > 5)) {
    return 1;
  }
  return 0;
}

int test_paren_stmt(int x) {
  (x);
  (x + 1);
  return x;
}

int test_nested_paren(int x) {
  if (((x > 5) && (x < 10))) {
    return 2;
  }
  return 0;
}

int main() {
  int a = 3;
  if ((a)) {
    printf("a is non-zero: %d\n", a);
  }

  (a);
  ((a + 1));

  printf("%d\n", test_paren(7));
  printf("%d\n", test_paren_stmt(a));
  printf("%d\n", test_nested_paren(a));

  return 0;
}
