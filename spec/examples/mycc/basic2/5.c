int printf(const char *fmt, ...);

typedef int (*UnaryOp)(int);
int double_it(int x) { return x * 2; }

UnaryOp get_unary_op() { return double_it; }

int main() {
  printf("fn ptr call = %d\n", get_unary_op()(10));
  return 0;
}
