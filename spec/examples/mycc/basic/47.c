int bla(int x) { return x + 1; }

int main() {
  typedef int (*func_t)(int);
  unsigned long long tmp = (unsigned long long)&bla;
  func_t f = (func_t)tmp;
  printf("tmp = %d\n", f(25));
  return 0;
}
