int printf(const char *fmt, ...);

void take_int_ptr(int *p) { printf("  take_int_ptr: %d\n", *p); }

void take_char_ptr(char *p) { printf("  take_char_ptr: %s\n", p); }

void take_void_ptr(void *p) {
  int *ip = (int *)p;
  printf("  take_void_ptr: %d\n", *ip);
}

int test_decay_arg() {
  int arr[3];
  arr[0] = 10;
  arr[1] = 20;
  arr[2] = 30;
  take_int_ptr(arr);
  printf("  decay arg: ok\n");

  char str[10];
  str[0] = 'O';
  str[1] = 'K';
  str[2] = '\0';
  take_char_ptr(str);
  printf("  decay char arg: ok\n");

  return 0;
}

int test_decay_cast() {
  char buf[20];
  buf[0] = 'c';
  buf[1] = 'a';
  buf[2] = 's';
  buf[3] = 't';
  buf[4] = '\0';

  take_void_ptr((void *)buf);
  printf("  decay cast void*: ok\n");

  take_char_ptr((char *)buf);
  printf("  decay cast char*: ok\n");

  take_int_ptr((int *)buf);
  printf("  decay cast int*: ok\n");

  return 0;
}

int test_decay_assign() {
  int arr[5];
  arr[0] = 1;
  arr[1] = 2;

  int *p = arr;
  printf("  decay assign: *p=%d *(p+1)=%d\n", *p, *(p + 1));

  int *q;
  q = arr;
  printf("  decay assign 2: *q=%d\n", *q);

  return 0;
}

int *return_array_ptr(int *p) { return p; }

int *test_decay_return() {
  int arr[3];
  arr[0] = 99;
  arr[1] = 100;
  arr[2] = 101;

  int *p = arr;
  int *ret = return_array_ptr(p);
  printf("  decay return: *ret=%d\n", *ret);
  return ret;
}

int test_decay_arithmetic() {
  int arr[5];
  arr[0] = 5;
  arr[1] = 10;
  arr[2] = 15;

  int *p = arr + 1;
  printf("  decay arith: *p=%d\n", *p);

  int *q = &arr[0] + 2;
  printf("  decay arith 2: *q=%d\n", *q);

  return 0;
}

int test_decay_condition() {
  int arr[5];
  arr[0] = 42;

  if (arr) {
    printf("  decay condition: arr is non-null\n");
  }

  int *null_ptr = 0;
  if (!null_ptr) {
    printf("  decay condition: null is false\n");
  }

  return 0;
}

int test_decay_subscript() {
  int arr[5];
  arr[0] = 7;
  arr[1] = 14;
  arr[2] = 21;

  printf("  decay subscript: arr[1]=%d\n", arr[1]);

  int *p = arr;
  printf("  decay subscript ptr: p[2]=%d\n", p[2]);

  return 0;
}

int test_decay_unary() {
  int arr[3];
  arr[0] = 100;
  arr[1] = 200;

  int *p = arr;
  p++;
  printf("  decay unary: *p=%d\n", *p);

  int x = *arr;
  printf("  decay deref: *arr=%d\n", x);

  return 0;
}

int test_decay_sizeof() {
  int arr[10];
  printf("  decay sizeof: sizeof(arr)=%d (expect 40)\n", sizeof(arr));

  char str[5];
  printf("  decay sizeof char: sizeof(str)=%d (expect 5)\n", sizeof(str));

  return 0;
}

int main() {
  printf("=== Decay Tests ===\n");
  test_decay_arg();
  test_decay_cast();
  test_decay_assign();
  test_decay_return();
  test_decay_arithmetic();
  test_decay_condition();
  test_decay_subscript();
  test_decay_unary();
  test_decay_sizeof();
  printf("=== DONE ===\n");
  return 0;
}
