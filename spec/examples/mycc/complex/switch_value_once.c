int printf(const char *fmt, ...);

int counter = 0;

int next_val() {
  counter++;
  return counter;
}

int test_switch_side_effect() {
  switch (next_val()) {
  case 1:
    return 1;
  case 2:
    return 2;
  case 3:
    return 3;
  default:
    return 4;
  }
}

int main() {
  printf("=== Switch Side-Effect Test ===\n");
  printf("%d\n", test_switch_side_effect());
  printf("%d\n", test_switch_side_effect());
  printf("%d\n", test_switch_side_effect());
  printf("%d\n", test_switch_side_effect());
  printf("=== DONE ===\n");
  return 0;
}
