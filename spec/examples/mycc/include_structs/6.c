int printf(const char *fmt, ...);

struct Bla {
  struct {
    int x;
    int y;
  };
  int z;
};

int main() {
  struct Bla bla = {0};

  bla.z = 1;
  bla.x = 2;
  bla.y = 3;
  printf("x = %d, y = %d, z = %d\n", bla.x, bla.y, bla.z);

  struct Bla *ptr = &bla;
  ptr->z = 1;
  ptr->x = 2;
  ptr->y = 3;
  printf("x = %d, y = %d, z = %d\n", ptr->x, ptr->y, ptr->z);

  return 0;
}
