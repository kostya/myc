int printf(const char *fmt, ...);

union Bla {
  short x;
  union {
    struct {
      char a;
      char b;
      short c;
      int d;
    };
    int q;
  };
};

int main() {
  union Bla bla = {0};

  bla.q = 1000000;
  printf("a = %d, b = %d, x = %d\n", bla.a, bla.b, bla.x);
  return 0;
}
