int printf(const char *fmt, ...);

int test_comma_with_parens() {
  int a = 0, b = 0, c = 0;

  (a = 1), (b = 2), (c = 3);
  printf("  parens comma: a=%d b=%d c=%d (expect 1, 2, 3)\n", a, b, c);

  ((a = 10), (b = 20)), (c = 30);
  printf("  nested parens: a=%d b=%d c=%d (expect 10, 20, 30)\n", a, b, c);

  a = 100, (b = 200, c = 300);
  printf("  mixed comma: a=%d b=%d c=%d (expect 100, 200, 300)\n", a, b, c);

  return 0;
}

int main() {
  printf("=== Comma Parens Tests ===\n");
  test_comma_with_parens();
  printf("=== DONE ===\n");
  return 0;
}
