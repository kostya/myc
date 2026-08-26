int printf(const char *fmt, ...);

int main() {
  int x = 0;
  switch (1) {
  case 0:
    break;
  case 3:
  case 4:
    break;
  case 5: {
    break;
  }
  default:
    (x = 1, x = 2);
  }

  printf("x = %d\n", x);
  return 0;
}
