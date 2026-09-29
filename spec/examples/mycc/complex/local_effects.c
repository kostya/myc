int printf(const char *fmt, ...);

int side(int x) {
  printf("side(%d) ", x);
  return x;
}

int main() {
  printf("=== short-circuit && ===\n");
  int a = 0;
  int r1 = side(0) && side(1);
  printf("r1=%d\n", r1);

  int r2 = side(1) && side(2);
  printf("r2=%d\n", r2);

  printf("=== short-circuit || ===\n");
  int r3 = side(1) || side(3);
  printf("r3=%d\n", r3);

  int r4 = side(0) || side(4);
  printf("r4=%d\n", r4);

  printf("=== ++ в || ===\n");
  const char *mode = "r+b";
  int v1 = *mode != '\0' && mode != 0;
  int v2 = (*mode != '+' || ((void)(++mode), 1));

  printf("v1=%d v2=%d mode=%s\n", v1, v2, mode);

  printf("=== assign in if ===\n");
  int x = 0;
  if ((x = side(5))) {
    printf("x=%d\n", x);
  }

  printf("=== i++ ===\n");
  int i = 0;
  int arr[5] = {10, 20, 30, 40, 50};
  int v3 = arr[i++];
  printf("v3=%d i=%d\n", v3, i);

  i = 0;
  arr[i++] = 100;
  printf("arr[0]=%d arr[1]=%d i=%d\n", arr[0], arr[1], i);

  printf("=== side effect init ===\n");
  i = 0;
  int v4 = (i = 42, i + 1);
  printf("v4=%d i=%d\n", v4, i);

  printf("=== inner ===\n");
  i = 0;
  int v5 = side(i++) + side(i++);
  printf("v5=%d i=%d\n", v5, i);

  return 0;
}
