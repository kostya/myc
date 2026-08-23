int printf(const char *fmt, ...);

int global_c = 10;
int *global_p = &global_c;

int global_arr[3] = {1, 2, 3};

int main() {
  printf("%d %d\n", *global_p, global_arr[1]);
  return 0;
}
