void test_types() {
  char c = 'A';
  int i = 42;
  long l = 123456L;
  float f = 3.14f;
  double d = 2.71828;
  unsigned fv = 0xfeedbeefu;

  printf("types: %c %d %d %f %f %d\n", c, i, (int)l, f, d, fv);
}

int main() {
  test_types();
  return 0;
}
