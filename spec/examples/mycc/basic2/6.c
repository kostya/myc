int printf(const char *fmt, ...);

int *get_array() {
  static int arr[5] = {10, 20, 30, 40, 50};
  return arr;
}

int *get_inner_array() {
  static int arr[3] = {111, 222, 333};
  return arr;
}

int main() {
  printf("%d\n", get_array()[2]);
  printf("%d\n", get_inner_array()[2]);
  return 0;
}
