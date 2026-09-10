int printf(const char *fmt, ...);

int blah = 10;

int main() {
  printf("blah");
  printf("\n");
  printf("global = %d\n", blah);
  return 0;
}
