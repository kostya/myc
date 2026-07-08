struct Bla {
  int data[256];
};

int main() {
  struct Bla bla = {0};
  bla.data[100] = 1;
  printf("%d %d\n", bla.data[100], bla.data[101]);
  return 0;
}
