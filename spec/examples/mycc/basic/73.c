int printf(const char *fmt, ...);

#define VAL 10

int main() {
  int x = 25;

  switch (x) {
  case VAL * 2 + 5:
    printf("computed: %d\n", x);
    break;
  case VAL:
    printf("val: %d\n", x);
    break;
  default:
    printf("default\n");
  }

  return 0;
}
