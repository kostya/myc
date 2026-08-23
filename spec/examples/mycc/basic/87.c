int printf(const char *fmt, ...);

int bla1() {
  printf("bla1\n");
  return 1;
}
int bla2() {
  printf("bla2\n");
  return 2;
}

int main() {
  (1 < 2) ? bla1() : bla2();

  int x = (1 < 2) ? bla1() : bla2();
  printf("x = %d\n", x);
  return 0;
}
