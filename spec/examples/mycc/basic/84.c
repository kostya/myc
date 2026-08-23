int printf(const char *fmt, ...);

typedef union Bla {
  int x;
  char y;
} Bla;

int main() {
  Bla bla;
  bla.x = 10;
  Bla *ptr = &bla;
  printf("%d\n", ptr->y);
  return 0;
}
