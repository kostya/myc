int printf(const char *fmt, ...);

int main() {
  void *label;

  for (int i = 0; i < 10; i++) {
    if (i % 2 == 1) {
      label = &&print1;
    } else {
      label = &&print2;
    }
    goto *label;

  print1:
    printf("in print1\n");
    continue;

  print2:
    printf("in print2\n");
  }

  return 0;
}
