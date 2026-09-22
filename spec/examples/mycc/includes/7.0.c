int f(int n);
int g(int n) {
  if (n == 0)
    return 0;
  return f(n - 1);
}
