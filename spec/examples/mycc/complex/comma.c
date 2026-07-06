int printf(const char *fmt, ...);

int test_comma_basic() {
  int a;
  a = (1, 2, 3);
  printf("  comma basic: a=%d (expect 3)\n", a);
  return 0;
}

int test_comma_assign() {
  int x, y;
  x = (y = 5, y + 1);
  printf("  comma assign: x=%d y=%d (expect 6, 5)\n", x, y);
  return 0;
}

int test_comma_chain() {
  int a, b;
  a = 1, b = 2, a += b;
  printf("  comma chain: a=%d b=%d (expect 3, 2)\n", a, b);
  return 0;
}

int test_comma_for() {
  int i, j;
  for (i = 0, j = 10; i < 5; i++, j--) {
  }
  printf("  comma for: i=%d j=%d (expect 5, 5)\n", i, j);
  return 0;
}

int test_comma_for_multi() {
  int a, b, c;
  for (a = 0, b = 10, c = 100; a < 3; a++, b--, c += 10) {
  }
  printf("  comma for multi: a=%d b=%d c=%d (expect 3, 7, 130)\n", a, b, c);
  return 0;
}

int test_comma_side_effects() {
  int x = 0;
  int y = (x = 1, x = x + 2, x * 10);
  printf("  comma side: x=%d y=%d (expect 3, 30)\n", x, y);
  return 0;
}

int test_comma_for_init() {
  int i, j, k;
  for (i = 0, j = 10, k = 20; i < 3; i++, j--, k += 5) {
    printf("  comma for: i=%d j=%d k=%d\n", i, j, k);
  }
  return 0;
}

int test_comma_for_ptr() {
  int a = 1, b = 2, c = 3;
  int *p, *q, *r;
  for (p = &a, q = &b, r = &c; *p < 3; (*p)++, (*q)--, (*r) += 10) {
    printf("  comma for ptr: *p=%d *q=%d *r=%d\n", *p, *q, *r);
  }
  return 0;
}

int test_comma_for_init_only() {
  int x, y;
  for (x = 0, y = 100; x < 3; x++, y -= 10) {
  }
  printf("  comma for init only: x=%d y=%d (expect 3, 70)\n", x, y);
  return 0;
}

int get_first(void) { return 100; }
int get_next(int x) { return x + 1; }

int test_comma_for_fn() {
  int idx, max = 5, val;
  for (idx = 0, val = get_first(); idx < max; idx++, val = get_next(val)) {
    printf("  comma for fn: idx=%d val=%d\n", idx, val);
  }
  return 0;
}

int test_comma_stmt() {
  int a = 0, b = 0;
  a = 1, b = 2, a += b;
  printf("  comma stmt: a=%d b=%d (expect 3, 2)\n", a, b);
  return 0;
}

int test_comma_parens() {
  int idx;
  int max;
  int val;
  for ((idx) = 0, (max) = 2, val = idx; (idx) < (max); (idx)++, (val) = (idx)) {
    printf("test_comma_parens %d\n", val);
  }
  return 0;
}

int main() {
  printf("=== Comma Tests ===\n");
  test_comma_basic();
  test_comma_assign();
  test_comma_chain();
  test_comma_for();
  test_comma_for_multi();
  test_comma_side_effects();
  test_comma_for_init();
  test_comma_for_ptr();
  test_comma_for_init_only();
  test_comma_for_fn();
  test_comma_stmt();
  test_comma_parens();
  printf("=== DONE ===\n");
  return 0;
}
