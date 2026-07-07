int printf(const char *fmt, ...);

int jo() {
  printf("jo called\n");
  return 1;
}

void bla(int x) {
  (void)x;
  (char)jo();
  (void)jo();
  printf("bla\n");
}

int main() {
  bla(10);
  return 0;
}
