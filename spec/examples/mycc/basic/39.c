int main() {
  char buf[100];
  int w = 800, h = 600;

  int len = snprintf(buf, 100, "%d %d\n", w, h);
  printf("len = %d\n", len);
  printf("buf = %s", buf);

  return 0;
}
