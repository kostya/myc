struct Bla {
  struct {
    int y;
  };
};

int main() {
  struct Bla bla;
  bla.y = 10;
  printf("%d\n", bla.y);
  return 0;
}
