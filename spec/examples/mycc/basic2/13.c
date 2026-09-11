int printf(const char *fmt, ...);

int main() {
  void *label = &&target;

  goto *label;
  printf("not in target\n");

target:
  printf("in target\n");
  return 0;
}
