int printf(const char *fmt, ...);

int test_for_empty() {
  int inf = 0;
  for (;;) {
    inf++;
    if (inf >= 2)
      break;
  }
  printf("  for(;;): inf=%d (expect 2)\n", inf);
  return 0;
}

int test_for_cond_only() {
  int a = 0;
  for (; a < 2;) {
    a++;
  }
  printf("  for(;cond;): a=%d (expect 2)\n", a);
  return 0;
}

int test_for_init_only() {
  int b;
  for (b = 0;;) {
    b++;
    if (b >= 3)
      break;
  }
  printf("  for(init;;): b=%d (expect 3)\n", b);
  return 0;
}

int test_for_step_only() {
  int c = 0;
  for (;; c++) {
    if (c >= 2)
      break;
  }
  printf("  for(;;step): c=%d (expect 2)\n", c);
  return 0;
}

int test_for_init_cond() {
  int d;
  for (d = 0; d < 2;) {
    d++;
  }
  printf("  for(init;cond;): d=%d (expect 2)\n", d);
  return 0;
}

int test_for_init_step() {
  int e;
  for (e = 0;; e++) {
    if (e >= 2)
      break;
  }
  printf("  for(init;;step): e=%d (expect 2)\n", e);
  return 0;
}

int test_for_cond_step() {
  int f = 0;
  for (; f < 2; f++) {
  }
  printf("  for(;cond;step): f=%d (expect 2)\n", f);
  return 0;
}

int test_for_all_parts() {
  int g;
  for (g = 0; g < 2; g++) {
  }
  printf("  for(init;cond;step): g=%d (expect 2)\n", g);
  return 0;
}

int test_for_compound_step() {
  int h;
  for (h = 0; h < 10; h += 3) {
  }
  printf("  for(+=): h=%d (expect 12)\n", h);
  return 0;
}

int test_for_empty_body() {
  int i = 0;
  for (; i < 3; i++)
    ;
  printf("  for empty body: i=%d (expect 3)\n", i);
  return 0;
}

int test_for_nested() {
  int sum = 0;
  for (int x = 0; x < 3; x++) {
    for (int y = 0; y < 2; y++) {
      sum++;
    }
  }
  printf("  nested for: sum=%d (expect 6)\n", sum);
  return 0;
}

int test_for_continue() {
  int sum = 0;
  for (int k = 0; k < 5; k++) {
    if (k == 2)
      continue;
    sum += k;
  }
  printf("  for continue: sum=%d (expect 8)\n", sum);
  return 0;
}

int test_for_break() {
  int sum = 0;
  for (int k = 0; k < 10; k++) {
    if (k == 4)
      break;
    sum += k;
  }
  printf("  for break: sum=%d (expect 6)\n", sum);
  return 0;
}

int main() {
  printf("=== For All Combinations ===\n");
  test_for_empty();
  test_for_cond_only();
  test_for_init_only();
  test_for_step_only();
  test_for_init_cond();
  test_for_init_step();
  test_for_cond_step();
  test_for_all_parts();
  test_for_compound_step();
  test_for_empty_body();
  test_for_nested();
  test_for_continue();
  test_for_break();
  printf("=== DONE ===\n");
  return 0;
}
