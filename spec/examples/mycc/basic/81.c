int printf(const char *fmt, ...);

int main() {
  int i = 0;
  int x = 1;
  int in_bla = 0;
  int in_jo = 0;
  switch (x) {
  case 1:
  bla: {
    in_bla++;
    if (i < 3) {
      i++;
      goto jo;
    }
  }
  default:
  jo: {
    in_jo++;
    if (i < 3) {
      i++;
      goto bla;
    }
  }
  }

  printf("i = %d, bla = %d, jo = %d\n", i, in_bla, in_jo);
  return 0;
}
