int printf(const char *fmt, ...);

void bla(int x[3]) { printf("%d\n", x[1]); }

void (*addr)(int *) = bla;

int main(void) {
  int x[3] = {1, 2, 3};
  addr(x);
  return 0;
}
