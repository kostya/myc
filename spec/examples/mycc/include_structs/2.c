struct Bla {
  struct {
    struct Cuc {
      int z;
    } y;
  } x;
};

int main() {
  struct Bla bla;
  bla.x.y.z = 10;
  printf("%d\n", bla.x.y.z);
  return 0;
}
