int printf(const char *fmt, ...);

int test_arrays() {
  int arr[5];
  arr[0] = 1;
  arr[1] = 2;
  arr[2] = 3;
  arr[3] = 4;
  arr[4] = 5;
  printf("  array basic: %d %d %d %d %d\n", arr[0], arr[1], arr[2], arr[3],
         arr[4]);
  return 0;
}

int test_array_to_ptr(int *p, int len) {
  int sum = 0;
  for (int i = 0; i < len; i++) {
    sum += p[i];
  }
  return sum;
}

int test_array_decay() {
  int arr[5];
  arr[0] = 10;
  arr[1] = 20;
  arr[2] = 30;
  arr[3] = 40;
  arr[4] = 50;
  int sum = test_array_to_ptr(arr, 5);
  printf("  array decay sum: %d\n", sum);

  int *p = arr;
  p[2] = 99;
  printf("  array modified via ptr: arr[2]=%d\n", arr[2]);
  return 0;
}

int test_flat_subscript() {
  int flat[3];
  flat[0] = 100;
  flat[1] = 200;
  flat[2] = 300;
  printf("  flat subscript: %d %d %d\n", flat[0], flat[1], flat[2]);
  return 0;
}

int test_implicit_casts() {
  float f = 3.14;
  int i = f;
  printf("  float->int: %d\n", i);

  double d = 2.718;
  int j = d;
  printf("  double->int: %d\n", j);

  int val = 42;
  void *vp = &val;
  int *ip = vp;
  printf("  void*->int*: %d\n", *ip);

  void *null_p = 0;
  if (!null_p)
    printf("  null ptr: false\n");
  if (ip)
    printf("  non-null ptr: true\n");

  if (5)
    printf("  int 5: true\n");
  if (!0)
    printf("  int 0: false\n");
  if (-1)
    printf("  int -1: true\n");

  return 0;
}

int test_literals() {
  int dec = 42;
  int hex = 0xFF;
  int oct = 077;
  printf("  dec=%d hex=%d oct=%d\n", dec, hex, oct);

  float f = 3.14f;
  double d = 2.718;
  printf("  float=%f double=%f\n", f, d);

  char c = 'A';
  printf("  char='%c' int=%d\n", c, c);

  return 0;
}

int test_increments() {
  int pre = 10;
  int post = 10;
  int pre_res = ++pre;
  int post_res = post++;
  printf("  prefix: pre=%d res=%d\n", pre, pre_res);
  printf("  postfix: post=%d res=%d\n", post, post_res);

  int arr[3];
  arr[0] = 10;
  arr[1] = 20;
  arr[2] = 30;
  int *p = arr;
  p++;
  printf("  ptr++: *p=%d\n", *p);
  (*p)++;
  printf("  (*p)++: arr[1]=%d\n", arr[1]);

  return 0;
}

int test_compound_assign() {
  int x = 10;
  x += 5;
  x -= 3;
  x *= 2;
  x /= 4;
  x %= 5;
  printf("  compound: %d\n", x);

  int arr[3];
  arr[0] = 1;
  int *p = arr;
  p += 2;
  *p = 99;
  printf("  ptr+=2: arr[2]=%d\n", arr[2]);

  return 0;
}

int test_sizeof() {
  printf("  sizeof(char)=%d\n", sizeof(char));
  printf("  sizeof(int)=%d\n", sizeof(int));
  printf("  sizeof(long)=%d\n", sizeof(long));
  printf("  sizeof(float)=%d\n", sizeof(float));
  printf("  sizeof(double)=%d\n", sizeof(double));
  printf("  sizeof(int*)=%d\n", sizeof(int *));
  printf("  sizeof(void*)=%d\n", sizeof(void *));
  return 0;
}

int test_ternary() {
  int a = 1, b = 2;
  int max = (a > b) ? a : b;
  printf("  max(1,2)=%d\n", max);

  int min = (a < b) ? a : b;
  printf("  min(1,2)=%d\n", min);

  int x = 10, y = 20, z = 30;
  int mid = (x > y) ? ((x > z) ? x : z) : ((y > z) ? y : z);
  printf("  max of three=%d\n", mid);

  return 0;
}

int test_goto() {
  int x = 0;
  x += 1;
  goto label1;
  x += 100;
label1:
  x += 2;
  printf("  goto: x=%d (expect 3)\n", x);

  int count = 0;
  int sum = 0;
loop_start:
  sum += count;
  count++;
  if (count < 5)
    goto loop_start;
  printf("  goto loop: sum=%d (expect 10)\n", sum);

  return 0;
}

int test_static_counter() {
  static int count;
  count++;
  return count;
}

int test_static() {
  printf("  static call1: %d\n", test_static_counter());
  printf("  static call2: %d\n", test_static_counter());
  printf("  static call3: %d\n", test_static_counter());
  return 0;
}

int test_strings() {
  char *hello = "Hello, World!";
  printf("  string: %s\n", hello);

  char buf[6];
  buf[0] = 'H';
  buf[1] = 'e';
  buf[2] = 'l';
  buf[3] = 'l';
  buf[4] = 'o';
  buf[5] = '\0';
  printf("  char array: %s\n", buf);

  return 0;
}

struct Point {
  int x;
  int y;
};

int test_structs() {
  struct Point p;
  p.x = 10;
  p.y = 20;
  printf("  struct: x=%d y=%d\n", p.x, p.y);

  struct Point *pp = &p;
  pp->x = 30;
  pp->y = 40;
  printf("  struct via ptr: x=%d y=%d\n", p.x, p.y);

  struct Rect {
    struct Point top_left;
    struct Point bottom_right;
  };
  struct Rect r;
  r.top_left.x = 0;
  r.top_left.y = 0;
  r.bottom_right.x = 100;
  r.bottom_right.y = 200;
  printf("  nested struct: (%d,%d)-(%d,%d)\n", r.top_left.x, r.top_left.y,
         r.bottom_right.x, r.bottom_right.y);

  return 0;
}

union Data {
  int i;
  float f;
  char c;
};

int test_unions() {
  union Data d;
  d.i = 42;
  printf("  union int: %d\n", d.i);

  d.c = 'Z';
  printf("  union char: %c\n", d.c);

  d.f = 3.14f;
  printf("  union float: %f\n", d.f);

  return 0;
}

int test_enum() {
  enum Color { RED = 1, GREEN = 2, BLUE = 4 };
  enum Color c = GREEN;
  printf("  enum value: %d\n", c);

  switch (c) {
  case RED:
    printf("  enum switch: RED\n");
    break;
  case GREEN:
    printf("  enum switch: GREEN\n");
    break;
  case BLUE:
    printf("  enum switch: BLUE\n");
    break;
  default:
    printf("  enum switch: ???\n");
    break;
  }
  return 0;
}

int test_enum1() {
  typedef enum Color { RED = 1, GREEN = 2, BLUE = 4 };
  enum Color c = GREEN;
  printf("  enum1 value: %d\n", c);
  return 0;
}

int test_do_while() {
  int i = 3;
  do {
    printf("  do-while: %d\n", i);
    i--;
  } while (i > 0);

  int j = 0;
  do {
    j++;
    if (j > 3)
      break;
    printf("  do-while break: %d\n", j);
  } while (1);

  return 0;
}

int test_unary() {
  int x = 42;
  printf("  neg: %d\n", -x);

  int y = 0;
  printf("  !0: %d\n", !y);
  printf("  !42: %d\n", !x);

  unsigned int z = 0;
  printf("  ~0: %u\n", ~z);

  return 0;
}

int test_casts() {
  double pi = 3.14159;
  int pi_int = (int)pi;
  printf("  cast double->int: %d\n", pi_int);

  int val = 42;
  void *vp = &val;
  int *ip = (int *)vp;
  printf("  cast void*->int*: %d\n", *ip);

  return 0;
}

int test_for_loops() {
  int sum = 0;
  for (int i = 0; i < 5; i++) {
    sum += i;
  }
  printf("  for sum: %d\n", sum);

  int j = 0;
  for (; j < 3; j++) {
    printf("  for no init: %d\n", j);
  }

  for (int k = 0; k < 10; k++) {
    if (k == 3)
      break;
    printf("  for break: %d\n", k);
  }

  int m = 0;
  for (;;) {
    m++;
    if (m > 3)
      break;
    printf("  for infinite: %d\n", m);
  }

  return 0;
}

int test_continue() {
  int sum = 0;
  for (int i = 0; i < 5; i++) {
    if (i == 2)
      continue;
    sum += i;
  }
  printf("  continue for: %d (expect 8)\n", sum);

  int j = 0;
  int wsum = 0;
  while (j < 5) {
    j++;
    if (j == 3)
      continue;
    wsum += j;
  }
  printf("  continue while: %d (expect 12)\n", wsum);

  return 0;
}

int test_scopes() {
  int x = 1;
  {
    int x = 2;
    printf("  inner scope: x=%d\n", x);
    {
      int x = 3;
      printf("  inner-inner: x=%d\n", x);
    }
    printf("  inner again: x=%d\n", x);
  }
  printf("  outer: x=%d\n", x);
  return 0;
}

int test_assign_expr() {
  int a, b, c;
  a = b = c = 42;
  printf("  chain assign: a=%d b=%d c=%d\n", a, b, c);

  int d;
  if ((d = 1)) {
    printf("  assign in if: d=%d\n", d);
  }

  return 0;
}

int test_logical() {
  if (1 && 1)
    printf("  && true: ok\n");
  if (!(0 && 1))
    printf("  && false: ok\n");
  if (1 || 0)
    printf("  || true: ok\n");
  if (!(0 || 0))
    printf("  || false: ok\n");

  int x = 0;
  if (1 || (x = 1)) {
    printf("  short-circuit ||: x=%d (expect 0)\n", x);
  }
  if (0 && (x = 2)) {
    printf("  short-circuit &&: BUG\n");
  }
  printf("  short-circuit &&: x=%d (expect 0)\n", x);

  return 0;
}

int test_switch() {
  int x = 2;
  switch (x) {
  case 1:
    printf("  switch int: 1\n");
    break;
  case 2:
    printf("  switch int: 2\n");
    break;
  default:
    printf("  switch int: default\n");
    break;
  }

  char c = 'B';
  switch (c) {
  case 'A':
    printf("  switch char: A\n");
    break;
  case 'B':
    printf("  switch char: B\n");
    break;
  default:
    printf("  switch char: other\n");
    break;
  }

  int y = 1;
  switch (y) {
  case 1:
    y += 10;
  case 2:
    y += 20;
  default:
    y += 30;
  }
  printf("  switch fall-through: y=%d (expect 61)\n", y);

  return 0;
}

int add(int a, int b) { return a + b; }

int test_invoke() {
  int (*fn)(int, int) = add;
  int result = fn(10, 20);
  printf("  invoke: %d (expect 30)\n", result);
  return 0;
}

int test_null_fn() {
  int (*fn_ptr)(int, int) = 0;

  fn_ptr = &add;
  printf("null_fn = %d\n", fn_ptr(1, 2));
  return 0;
}

int main() {
  printf("=== Arrays ===\n");
  test_arrays();
  test_array_decay();
  test_flat_subscript();

  printf("=== Implicit Casts ===\n");
  test_implicit_casts();

  printf("=== Literals ===\n");
  test_literals();

  printf("=== Increments ===\n");
  test_increments();

  printf("=== Compound Assign ===\n");
  test_compound_assign();

  printf("=== Sizeof ===\n");
  test_sizeof();

  printf("=== Ternary ===\n");
  test_ternary();

  printf("=== Goto ===\n");
  test_goto();

  printf("=== Strings ===\n");
  test_strings();

  printf("=== Structs ===\n");
  test_structs();

  printf("=== Unions ===\n");
  test_unions();

  printf("=== Do-While ===\n");
  test_do_while();

  printf("=== Unary ===\n");
  test_unary();

  printf("=== Casts ===\n");
  test_casts();

  printf("=== Continue ===\n");
  test_continue();

  printf("=== Scopes ===\n");
  test_scopes();

  printf("=== Assign Expr ===\n");
  test_assign_expr();

  printf("=== Logical ===\n");
  test_logical();

  printf("=== Switch ===\n");
  test_switch();

  printf("=== Invoke ===\n");
  test_invoke();

  printf("=== Static ===\n");
  test_static();

  printf("=== Enum ===\n");
  test_enum();
  test_enum1();

  printf("=== For Loops ===\n");
  test_for_loops();

  printf("=== null fn ptr ===\n");
  test_null_fn();

  return 0;
}
