int g(int n);
int f(int n) {
  if (n == 0)
    return 0;
  return g(n - 1);
}
