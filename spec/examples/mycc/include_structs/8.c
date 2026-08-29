int printf(const char *fmt, ...);

struct Bla {
  union {
    char x;
    char y;
  };
  short z;
};

int main() {
  struct Bla bla;

  bla.y = 10;
  bla.x = 20;
  bla.z = 30;
  printf("x = %d, y = %d, z = %d\n", bla.x, bla.y, bla.z);
  return 0;
}
