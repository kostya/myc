int printf(const char *fmt, ...);

struct A {
  int q;
};

struct Bla {
  int x;
  struct A a;
};

int main() {
  struct Bla bla = {.x = 10, .a = {.q = 15}};
  printf("x = %d, q = %d\n", bla.x, bla.a.q);

  struct Bla bla2 = {.a = {.q = 15}};
  printf("x = %d, q = %d\n", bla2.x, bla2.a.q);
  return 0;
}
