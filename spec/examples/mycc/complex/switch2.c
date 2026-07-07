int printf(const char *fmt, ...);

int test_switch_case_with_block() {
  int x = 0;
  int result = 0;

  switch (x) {
  case 0: {
    int y = 42;
    result = y;
    break;
  }
  case 1:
    result = 100;
    break;
  default:
    result = -1;
    break;
  }

  printf("  switch case block: result=%d (expect 42)\n", result);
  return 0;
}

int test_switch_case_fallthrough() {
  int x = 0;
  int result = 0;

  switch (x) {
  case 0:
    result += 10;

  case 1: {
    int tmp = result + 20;
    result = tmp;
    break;
  }
  default:
    result = -1;
    break;
  }

  printf("  switch fallthrough block: result=%d (expect 30)\n", result);
  return 0;
}

int main() {
  printf("=== Switch Case Block Tests ===\n");
  test_switch_case_with_block();
  test_switch_case_fallthrough();
  printf("=== DONE ===\n");
  return 0;
}
