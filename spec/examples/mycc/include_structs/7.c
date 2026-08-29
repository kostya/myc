int printf(const char *fmt, ...);

struct Bla {
  struct {
    int x;
    struct {
      int q;
      int u;
    };
  };
  int z;
};

int main() {
  struct Bla bla = {0};

  bla.z = 1;
  bla.x = 2;
  bla.q = 3;
  bla.u = 4;
  printf("x = %d, q = %d, u = %d, z = %d\n", bla.x, bla.q, bla.u, bla.z);
  return 0;
}
