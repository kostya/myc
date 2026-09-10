int printf(const char *fmt, ...);
void *malloc(int size);
void free(void *ptr);

int test_pointer_hell() {
  printf("=== Pointer Hell ===\n");

  int val = 42;
  int *p1 = &val;
  int **p2 = &p1;
  int ***p3 = &p2;
  int ****p4 = &p3;
  int *****p5 = &p4;

  printf("  quintuple pointer: %d (expect 42)\n", *****p5);

  int arr1[3] = {1, 2, 3};
  int arr2[3] = {4, 5, 6};
  int arr3[3] = {7, 8, 9};

  int *ptr_array[3] = {arr1, arr2, arr3};
  int **ptr_to_ptr_array = ptr_array;

  printf("  ptr_array[1][2]: %d (expect 6)\n", ptr_to_ptr_array[1][2]);
  printf("  *(*(ptr_array + 2) + 1): %d (expect 8)\n", *(*(ptr_array + 2) + 1));

  return 0;
}

int test_bit_twiddling() {
  printf("=== Bit Twiddling ===\n");

  int a = 10, b = 20;
  a ^= b;
  b ^= a;
  a ^= b;
  printf("  XOR swap: a=%d b=%d (expect 20 10)\n", a, b);

  unsigned int n = 100;
  n--;
  n |= n >> 1;
  n |= n >> 2;
  n |= n >> 4;
  n |= n >> 8;
  n |= n >> 16;
  n++;
  printf("  round up to power of 2: %u (expect 128)\n", n);

  unsigned int tz = 0x80000000;
  int count = 0;
  if (tz)
    while (!(tz & 1)) {
      count++;
      tz >>= 1;
    }
  else
    count = 32;
  printf("  trailing zeros: %d (expect 31)\n", count);

  return 0;
}

int test_insane_expressions() {
  printf("=== Insane Expressions ===\n");

  int a = 1, b = 2, c = 3, d = 4, e = 5;

  int result = (a = b) ? (c = d) ? (e = 10) : 20 : 30;
  printf("  nested ternary: result=%d a=%d c=%d e=%d\n", result, a, c, e);

  int x = (a++, b++, c++, a + b + c);
  printf("  comma operator: x=%d\n", x);

  int arr[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  int *p = arr;
  printf("  3[p]: %d (expect 3)\n", 3 [p]);
  printf("  *(3 + p): %d (expect 3)\n", *(3 + p));
  printf("  p[3]: %d (expect 3)\n", p[3]);

  return 0;
}

struct CrazyStruct {
  union {
    int int_val;
    float float_val;
    char str[8];
    struct {
      short a;
      short b;
    } shorts;
  } data;

  struct CrazyStruct *self;
  struct CrazyStruct *next;
  struct CrazyStruct *prev;
};

int test_crazy_structs() {
  printf("=== Crazy Structs ===\n");

  struct CrazyStruct cs;
  cs.self = &cs;
  cs.next = &cs;
  cs.prev = &cs;

  cs.data.int_val = 0x12345678;
  printf("  union as int: 0x%X\n", cs.data.int_val);
  printf("  union shorts: a=0x%X b=0x%X\n", cs.data.shorts.a, cs.data.shorts.b);

  cs.data.float_val = 3.14f;
  printf("  union as float: %f\n", cs.data.float_val);

  cs.data.str[0] = 'H';
  cs.data.str[1] = 'i';
  cs.data.str[2] = '\0';
  printf("  union as string: %s\n", cs.data.str);

  printf("  self-reference: %d (expect 1)\n", cs.self == &cs);

  return 0;
}

int ackermann(int m, int n) {
  if (m == 0)
    return n + 1;
  if (n == 0)
    return ackermann(m - 1, 1);
  return ackermann(m - 1, ackermann(m, n - 1));
}

int test_deep_recursion() {
  printf("=== Deep Recursion ===\n");

  printf("  ackermann(2, 3): %d (expect 9)\n", ackermann(2, 3));
  printf("  ackermann(3, 2): %d (expect 29)\n", ackermann(3, 2));
  printf("  ackermann(3, 3): %d (expect 61)\n", ackermann(3, 3));

  return 0;
}

struct Base1 {
  int a;
  int b;
};

struct Base2 {
  int c;
  int d;
};

struct Derived {
  struct Base1 base1;
  struct Base2 base2;
  int e;
};

int test_multiple_inheritance() {
  printf("=== Multiple Inheritance ===\n");

  struct Derived d;
  d.base1.a = 1;
  d.base1.b = 2;
  d.base2.c = 3;
  d.base2.d = 4;
  d.e = 5;

  struct Base1 *b1 = (struct Base1 *)&d;
  struct Base2 *b2 = (struct Base2 *)((char *)&d + sizeof(struct Base1));

  printf("  base1: a=%d b=%d (expect 1 2)\n", b1->a, b1->b);
  printf("  base2: c=%d d=%d (expect 3 4)\n", b2->c, b2->d);

  return 0;
}

typedef int (*UnaryOp)(int);
typedef int (*BinaryOp)(int, int);

int double_it(int x) { return x * 2; }
int square_it(int x) { return x * x; }
int add(int a, int b) { return a + b; }
int multiply(int a, int b) { return a * b; }

UnaryOp get_unary_op(int choice) {
  if (choice == 0)
    return double_it;
  else
    return square_it;
}

int test_function_pointer_abuse() {
  printf("=== Function Pointer Abuse ===\n");

  UnaryOp unary_ops[2] = {double_it, square_it};
  BinaryOp binary_ops[2] = {add, multiply};

  printf("  unary ops: %d %d (expect 10 25)\n", unary_ops[0](5),
         unary_ops[1](5));
  printf("  binary ops: %d %d (expect 12 35)\n", binary_ops[0](5, 7),
         binary_ops[1](5, 7));

  printf("  get_unary_op(0)(10): %d (expect 20)\n", get_unary_op(0)(10));
  printf("  get_unary_op(1)(10): %d (expect 100)\n", get_unary_op(1)(10));

  int (*func_matrix[2][2])(int, int) = {{add, multiply}, {add, multiply}};

  printf("  func_matrix[1][0](10, 20): %d (expect 30)\n",
         func_matrix[1][0](10, 20));

  return 0;
}

int side_effect_counter = 0;

int side_effect() {
  side_effect_counter++;
  return side_effect_counter;
}

int test_side_effects() {
  printf("=== Side Effects ===\n");

  int x = 0;
  x = side_effect() + side_effect() + side_effect();
  printf("  sum of side effects: %d (expect 6)\n", x);
  printf("  counter: %d (expect 3)\n", side_effect_counter);

  printf("  nested calls: %d\n",
         add(multiply(double_it(5), square_it(3)), add(10, multiply(2, 3))));

  return 0;
}

int test_overflow_hell() {
  printf("=== Overflow Hell ===\n");

  int max = 2147483647;
  int min = -2147483648;

  printf("  max + 1: %d (expect -2147483648)\n", max + 1);
  printf("  min - 1: %d (expect 2147483647)\n", min - 1);
  printf("  -min: %d (expect -2147483648)\n", -min);
  printf("  max * 2: %d (expect -2)\n", max * 2);

  unsigned int umax = 4294967295u;
  printf("  umax + 1: %u (expect 0)\n", umax + 1);
  printf("  0 - 1: %u (expect 4294967295)\n", 0u - 1);

  return 0;
}

struct Tree {
  int value;
  struct Tree *left;
  struct Tree *right;
};

struct Tree *create_tree(int depth) {
  if (depth <= 0)
    return 0;

  struct Tree *node = (struct Tree *)malloc(sizeof(struct Tree));
  node->value = depth;
  node->left = create_tree(depth - 1);
  node->right = create_tree(depth - 1);
  return node;
}

int tree_size(struct Tree *root) {
  if (!root)
    return 0;
  return 1 + tree_size(root->left) + tree_size(root->right);
}

int test_complex_recursion() {
  printf("=== Complex Recursion ===\n");

  struct Tree *tree = create_tree(5);
  printf("  tree size: %d (expect 31)\n", tree_size(tree));

  return 0;
}

int test_string_abuse() {
  printf("=== String Abuse ===\n");

  char result[50] = {0};
  char *p = result;
  char *src = "Hello ";
  while (*src) {
    *p++ = *src++;
  }
  src = "World!";
  while (*src) {
    *p++ = *src++;
  }
  *p = '\0';
  printf("  concatenated: %s (expect Hello World!)\n", result);

  return 0;
}

int test_type_puzzles() {
  printf("=== Type Puzzles ===\n");

  int *arr[10];

  int matrix[3][4] = {{1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}};
  int (*ptr_to_arr)[4] = matrix;

  printf("  (*ptr_to_arr)[2]: %d (expect 3)\n", (*ptr_to_arr)[2]);
  printf("  ptr_to_arr[1][2]: %d (expect 7)\n", ptr_to_arr[1][2]);

  int (*func_ptr_arr[5])(int, int);
  func_ptr_arr[0] = add;
  func_ptr_arr[1] = multiply;

  printf("  func_ptr_arr[0](10, 20): %d (expect 30)\n",
         func_ptr_arr[0](10, 20));
  printf("  func_ptr_arr[1](10, 20): %d (expect 200)\n",
         func_ptr_arr[1](10, 20));

  return 0;
}

int test_struct_pointer_offsets() {
  printf("=== Struct Pointer Offsets ===\n");

  struct Test {
    char c;
    int i;
    double d;
  };

  struct Test t;
  t.c = 'A';
  t.i = 42;
  t.d = 3.14;

  char *c_ptr = (char *)&t;
  int *i_ptr = (int *)(c_ptr + 4);
  double *d_ptr = (double *)(c_ptr + 8);

  printf("  c via offset: %c (expect A)\n", *c_ptr);
  printf("  i via offset: %d (expect 42)\n", *i_ptr);
  printf("  d via offset: %f (expect 3.14)\n", *d_ptr);

  printf("  sizeof(struct Test): %d\n", sizeof(struct Test));
  printf("  offset of i: %d\n", (int)((char *)&t.i - (char *)&t));
  printf("  offset of d: %d\n", (int)((char *)&t.d - (char *)&t));

  return 0;
}

int main() {
  test_pointer_hell();
  printf("\n");

  test_bit_twiddling();
  printf("\n");

  test_insane_expressions();
  printf("\n");

  test_crazy_structs();
  printf("\n");

  test_deep_recursion();
  printf("\n");

  test_multiple_inheritance();
  printf("\n");

  test_function_pointer_abuse();
  printf("\n");

  test_side_effects();
  printf("\n");

  test_overflow_hell();
  printf("\n");

  test_complex_recursion();
  printf("\n");

  test_string_abuse();
  printf("\n");

  test_type_puzzles();
  printf("\n");

  test_struct_pointer_offsets();
  printf("\n");
  return 0;
}
