int printf(const char *fmt, ...);

int test_switch_scopes(int x) {
  switch (x) {
  case 1: {
    int value = 10;
    printf("value = %d\n", value);
    break;
  }
  case 2: {
    int *value = 0;
    printf("value = %d\n", value);
    break;
  }
  case 3: {
    char value = 30;
    printf("value = %d\n", value);
    break;
  }
  default: {
    void *value = 0;
    printf("value = %d\n", value);
    break;
  }
  }
  return 0;
}

void test_if_else_scopes(int x) {
  if (x > 0) {
    int value = 100;
    printf("value = %d\n", value);
  } else {
    int *value = 0;
    printf("value = %d\n", value);
  }
}

int test_nested_scopes(int x) {
  int value = 1;
  {
    int value = 2;
    printf("  inner: value=%d (expect 2)\n", value);
    {
      int value = 3;
      printf("  inner-inner: value=%d (expect 3)\n", value);
    }
    printf("  inner again: value=%d (expect 2)\n", value);
  }
  printf("  outer: value=%d (expect 1)\n", value);
  return value;
}

int main() {
  printf("=== Switch/If Scopes ===\n");
  test_switch_scopes(1);
  test_switch_scopes(2);
  test_switch_scopes(3);
  test_switch_scopes(99);
  test_if_else_scopes(1);
  test_if_else_scopes(-1);
  test_nested_scopes(0);
  printf("=== DONE ===\n");
  return 0;
}
