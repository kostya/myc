int printf(const char *fmt, ...);

union Bla {
  short x;
  union {
    short a;
    int b;
  };
};

int main() {
  union Bla bla;

  bla.b = 1000000;
  printf("a = %d, b = %d, x = %d\n", bla.a, bla.b, bla.x);
  return 0;
}
