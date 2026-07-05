int printf(const char *fmt, ...);

int test_and_basic() {
  if (1 && 1)
    printf("  and(1,1): true\n");
  if (!(1 && 0))
    printf("  and(1,0): false\n");
  if (!(0 && 1))
    printf("  and(0,1): false\n");
  if (!(0 && 0))
    printf("  and(0,0): false\n");
  return 0;
}

int test_or_basic() {
  if (1 || 1)
    printf("  or(1,1): true\n");
  if (1 || 0)
    printf("  or(1,0): true\n");
  if (0 || 1)
    printf("  or(0,1): true\n");
  if (!(0 || 0))
    printf("  or(0,0): false\n");
  return 0;
}

int test_and_short_circuit() {
  int x = 0;
  if (0 && (x = 1)) {
    printf("  and short-circuit: BUG\n");
  }
  printf("  and sc &&: x=%d (expect 0)\n", x);

  int y = 0;
  if (0 && (y = 2) && (y = 3)) {
    printf("  and chain: BUG\n");
  }
  printf("  and sc chain: y=%d (expect 0)\n", y);

  return 0;
}

int test_or_short_circuit() {
  int x = 0;
  if (1 || (x = 1)) {
    printf("  or short-circuit: ok\n");
  }
  printf("  or sc ||: x=%d (expect 0)\n", x);

  int y = 0;
  if (1 || (y = 2) || (y = 3)) {
    printf("  or chain: ok\n");
  }
  printf("  or sc chain: y=%d (expect 0)\n", y);

  return 0;
}

int test_sc_with_side_effects() {
  int a = 0;
  int b = 0;

  if ((a = 1) && (b = 2)) {
    printf("  side-effect: a=%d b=%d (expect a=1 b=2)\n", a, b);
  }

  int c = 0;
  int d = 0;
  if ((c = 0) && (d = 5)) {
    printf("  side-effect 2: BUG\n");
  }
  printf("  side-effect 2: c=%d d=%d (expect c=0 d=0)\n", c, d);

  int e = 0;
  int f = 0;
  if ((e = 1) || (f = 5)) {
    printf("  side-effect 3: ok\n");
  }
  printf("  side-effect 3: e=%d f=%d (expect e=1 f=0)\n", e, f);

  return 0;
}

int test_sc_with_pointers() {
  int val = 42;
  int *ptr = &val;
  int *null_ptr = 0;

  if (ptr && *ptr == 42) {
    printf("  sc ptr: ok\n");
  }

  if (!null_ptr || *null_ptr == 0) {
    printf("  sc null: ok (no crash)\n");
  }

  if (ptr && *ptr > 0 && *ptr < 100) {
    printf("  sc ptr range: ok\n");
  }

  return 0;
}

int test_nested_sc() {
  int x = 0;

  if ((1 && 0) || (x = 5)) {
    printf("  nested sc: x=%d (expect 5)\n", x);
  }

  int y = 0;
  if (1 && (0 || (y = 10))) {
    printf("  nested sc 2: y=%d (expect 10)\n", y);
  }

  int z = 0;
  if (0 && (1 || (z = 99))) {
    printf("  nested sc 3: BUG\n");
  }
  printf("  nested sc 3: z=%d (expect 0)\n", z);

  return 0;
}

int test_precedence() {
  int a, b = 0, c = 0;

  a = 1 || (b = 2);
  printf("  precedence 1: a=%d b=%d (expect a=1 b=0)\n", a, b);

  (c = 0) && (c = 3);
  printf("  precedence 2: c=%d (expect 0)\n", c);

  return 0;
}

int test_loop_short_circuit() {
  int i = 0;
  int count = 0;

  while (i < 5 && count < 3) {
    count++;
    i++;
  }
  printf("  loop sc: i=%d count=%d (expect i=3 count=3)\n", i, count);

  return 0;
}

int test_ternary_sc() {
  int x = 0;
  int result = (0 && (x = 5)) ? x : 42;
  printf("  ternary sc: result=%d x=%d (expect result=42 x=0)\n", result, x);
  return 0;
}

int main() {
  printf("=== Short-Circuit Tests ===\n");
  test_and_basic();
  test_or_basic();
  test_and_short_circuit();
  test_or_short_circuit();
  test_sc_with_side_effects();
  test_sc_with_pointers();
  test_nested_sc();
  test_precedence();
  test_loop_short_circuit();
  test_ternary_sc();
  printf("=== DONE ===\n");
  return 0;
}
