int printf(const char *fmt, ...);

int check(int x) {
  if (x >= 0)
    return 1;
  else
    return 0;
}

int check_prox(int x) { return check(-x); }

void test() {
  int a = check_prox(10);
  int b = check_prox(-1);
  printf("%d, %d\n", a, b);
}

int main() {
  test();
  return 0;
}
