int printf(const char *fmt, ...);

int test_switch_hell() {
  printf("=== Switch Hell ===\n");

  int count = 10;
  int src[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  int dst[10] = {0};
  int i = 0;

  switch (count % 4) {
  case 0:
    do {
      dst[i] = src[i];
      i++;
    case 3:
      dst[i] = src[i];
      i++;
    case 2:
      dst[i] = src[i];
      i++;
    case 1:
      dst[i] = src[i];
      i++;
    } while (i < count);
  }

  printf("  Duff's device: ");
  for (int j = 0; j < 10; j++) {
    printf("%d ", dst[j]);
  }
  printf("(expect 1 2 3 4 5 6 7 8 9 10)\n");

  return 0;
}

int main() {
  test_switch_hell();
  printf("\n");
  return 0;
}
