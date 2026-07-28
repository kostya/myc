union Union {
  int x;
  struct Bla {
    int y;
  } z;
};

int main() {
  union Union val;
  val.x = 10;
  printf("%d %d\n", val.x, val.z.y);
  val.z.y = 20;
  printf("%d %d\n", val.x, val.z.y);
  return 0;
}
