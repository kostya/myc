int printf(const char *fmt, ...);

union Bla {
  short x;
  struct {
    char a;
    char b;
  };
};

int main() {
  union Bla bla;

  bla.a = 10;
  bla.b = 20;
  printf("a = %d, b = %d, x = %d\n", bla.a, bla.b, bla.x);
  return 0;
}
