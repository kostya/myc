int printf(const char *fmt, ...);

struct Bla {
  int x;
  char y;
};

int main() {
  struct Bla bla = {.y = 2};
  printf("x = %d, y = %d\n", bla.x, bla.y);
  return 0;
}
