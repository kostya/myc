int printf(const char *fmt, ...);

int main() {
  int i = 0;
  int x = 1;

  switch (x) {
  case 1:
    x++;
  bla: { i++; } break;
  }

  printf("i = %d, x = %d\n", i, x);
  return 0;
}
