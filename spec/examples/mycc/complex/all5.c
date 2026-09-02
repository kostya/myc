int printf(const char *fmt, ...);
void *malloc(int size);
void free(void *ptr);

int add_int(int a, int b) { return a + b; }
float add_float(float a, float b) { return a + b; }
double add_double(double a, double b) { return a + b; }

int test_function_pointer_casts() {
  printf("=== Function Pointer Casts ===\n");

  void *func_ptrs[3];
  func_ptrs[0] = (void *)add_int;
  func_ptrs[1] = (void *)add_float;
  func_ptrs[2] = (void *)add_double;

  int (*int_func)(int, int) = (int (*)(int, int))func_ptrs[0];
  printf("  int func: %d (expect 30)\n", int_func(10, 20));

  return 0;
}

#define SQUARE(x) ((x) * (x))
#define CUBE(x) (SQUARE(x) * (x))
#define QUAD(x) (SQUARE(SQUARE(x)))

int test_macros() {
  printf("=== Macros ===\n");
  printf("  SQUARE(5): %d (expect 25)\n", SQUARE(5));
  printf("  CUBE(3): %d (expect 27)\n", CUBE(3));
  printf("  QUAD(2): %d (expect 16)\n", QUAD(2));
  return 0;
}

typedef int (*Operation)(int);

Operation create_adder(int n) { return 0; }

int test_vla() {
  printf("=== Variable Length Arrays ===\n");

  int n = 10;
  int arr[n];

  for (int i = 0; i < n; i++) {
    arr[i] = i * i;
  }

  printf("  VLA sum: %d (expect 285)\n", arr[9] + arr[8] + arr[7]);

  int rows = 3, cols = 4;
  int matrix[rows][cols];

  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      matrix[i][j] = i * cols + j;
    }
  }

  printf("  VLA matrix[2][3]: %d (expect 11)\n", matrix[2][3]);

  return 0;
}

typedef int (*FuncPtr)(int, int);
typedef FuncPtr (*FuncPtrFactory)(void);
typedef int Array10[10];
typedef Array10 *Array10Ptr;

int add(int a, int b) { return a + b; }

FuncPtr get_add(void) { return add; }

int test_typedefs() {
  printf("=== Complex Typedefs ===\n");

  FuncPtr fp = add;
  printf("  typedef func: %d (expect 30)\n", fp(10, 20));

  Array10 arr;
  for (int i = 0; i < 10; i++) {
    arr[i] = i;
  }

  Array10Ptr arr_ptr = &arr;
  printf("  typedef array: %d (expect 5)\n", (*arr_ptr)[5]);

  return 0;
}

struct Point3D {
  int x;
  int y;
  int z;
};

int test_member_pointers() {
  printf("=== Member Pointers ===\n");

  struct Point3D p = {1, 2, 3};
  struct Point3D *pp = &p;

  int *px = &p.x;
  int *py = &p.y;
  int *pz = &p.z;

  printf("  members: %d %d %d (expect 1 2 3)\n", *px, *py, *pz);

  int *base = (int *)pp;
  printf("  offset access: %d %d %d (expect 1 2 3)\n", base[0], base[1],
         base[2]);

  return 0;
}

struct TreeNode {
  int value;
  int child_count;
  struct TreeNode *children[10];
};

struct TreeNode *create_tree_node(int value, int child_count) {
  struct TreeNode *node = (struct TreeNode *)malloc(sizeof(struct TreeNode));
  node->value = value;
  node->child_count = child_count;
  for (int i = 0; i < 10; i++) {
    node->children[i] = 0;
  }
  return node;
}

int sum_tree_values(struct TreeNode *root) {
  if (!root)
    return 0;
  int sum = root->value;
  for (int i = 0; i < root->child_count; i++) {
    sum += sum_tree_values(root->children[i]);
  }
  return sum;
}

int test_complex_trees() {
  printf("=== Complex Trees ===\n");

  struct TreeNode *root = create_tree_node(10, 3);
  root->children[0] = create_tree_node(20, 2);
  root->children[1] = create_tree_node(30, 1);
  root->children[2] = create_tree_node(40, 0);

  root->children[0]->children[0] = create_tree_node(50, 0);
  root->children[0]->children[1] = create_tree_node(60, 0);
  root->children[1]->children[0] = create_tree_node(70, 0);

  printf("  tree sum: %d (expect 280)\n", sum_tree_values(root));

  return 0;
}

int test_pointer_arithmetic() {
  printf("=== Pointer Arithmetic ===\n");

  int arr[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  int *p1 = arr;
  int *p2 = arr + 5;

  printf("  p2 - p1: %d (expect 5)\n", p2 - p1);
  printf("  p1 < p2: %d (expect 1)\n", p1 < p2);
  printf("  p1 == p2: %d (expect 0)\n", p1 == p2);

  int *ptrs[3];
  ptrs[0] = arr;
  ptrs[1] = arr + 3;
  ptrs[2] = arr + 7;

  printf("  **ptrs: %d (expect 0)\n", **ptrs);
  printf("  *ptrs[1]: %d (expect 3)\n", *ptrs[1]);
  printf("  ptrs[2][2]: %d (expect 9)\n", ptrs[2][2]);

  void *vp = arr;
  int *ip = (int *)vp;
  ip += 3;
  printf("  void ptr arithmetic: %d (expect 3)\n", *ip);

  return 0;
}

int test_conditional_expressions() {
  printf("=== Conditional Expressions ===\n");

  int a = 5, b = 10, c = 15;

  int result = (a > b) ? 1 : (b > c) ? 2 : (c > a) ? 3 : 4;
  printf("  chained ternary: %d (expect 3)\n", result);

  int x;
  if ((x = a + b) > c) {
    printf("  assignment in condition: x=%d\n", x);
  } else {
    printf("  assignment in condition: x=%d\n", x);
  }

  if ((a < b && b < c) || (a > b && b > c)) {
    printf("  complex logical: true\n");
  }

  int *p1 = &a;
  int *p2 = &b;
  int *p3 = (a > b) ? p1 : p2;
  printf("  ternary pointers: %d (expect 10)\n", *p3);

  return 0;
}

int multiply(int a, int b) { return a * b; }
int subtract(int a, int b) { return a - b; }

int test_nested_calls() {
  printf("=== Nested Calls ===\n");

  int result = add(multiply(2, 3), subtract(multiply(4, 5), add(1, 2)));
  printf("  deep nesting: %d (expect 23)\n", result);

  int x = add(add(add(1, 2), add(3, 4)), add(add(5, 6), add(7, 8)));
  printf("  chain calls: %d (expect 36)\n", x);

  int fib = 5;
  printf("  fibonacci(5): %d (expect 5)\n",
         fib <= 1 ? fib : (fib - 1) + (fib - 2));

  return 0;
}

struct Calculator {
  int (*add)(int, int);
  int (*multiply)(int, int);
  int (*subtract)(int, int);
  int value;
};

int test_struct_methods() {
  printf("=== Struct Methods ===\n");

  struct Calculator calc;
  calc.add = add;
  calc.multiply = multiply;
  calc.subtract = subtract;
  calc.value = 100;

  printf("  method add: %d (expect 30)\n", calc.add(10, 20));
  printf("  method multiply: %d (expect 200)\n", calc.multiply(10, 20));
  printf("  method subtract: %d (expect 10)\n", calc.subtract(30, 20));

  int result = calc.add(calc.multiply(2, 3), calc.subtract(10, 5));
  printf("  method chain: %d (expect 11)\n", result);

  return 0;
}

int test_type_conversions() {
  printf("=== Type Conversions ===\n");

  char c = 'A';
  int i = c;
  long l = i;
  float f = l;
  double d = f;

  printf("  char to double: %f (expect 65.0)\n", d);

  double pi = 3.14159;
  int pi_int = (int)pi;
  char pi_char = (char)pi_int;
  float pi_float = (float)pi_int;

  printf("  explicit casts: %d %d %f\n", pi_int, pi_char, pi_float);

  int val = 42;
  int *ip = &val;
  void *vp = (void *)ip;
  int *ip2 = (int *)vp;
  char *cp = (char *)ip;

  printf("  pointer casts: %d %c\n", *ip2, *cp);

  int a = 5, b = 2;
  float result = (float)a / b;
  printf("  float division: %f (expect 2.5)\n", result);

  return 0;
}

int test_array_of_arrays() {
  printf("=== Array of Arrays ===\n");

  int arr1[3] = {1, 2, 3};
  int arr2[3] = {4, 5, 6};
  int arr3[3] = {7, 8, 9};

  int *array_of_arrays[3] = {arr1, arr2, arr3};

  printf("  array_of_arrays[0][1]: %d (expect 2)\n", array_of_arrays[0][1]);
  printf("  array_of_arrays[1][2]: %d (expect 6)\n", array_of_arrays[1][2]);
  printf("  array_of_arrays[2][0]: %d (expect 7)\n", array_of_arrays[2][0]);

  int **ptr_to_first = array_of_arrays;
  printf("  ptr_to_first[1][1]: %d (expect 5)\n", ptr_to_first[1][1]);

  return 0;
}

int test_float_calls() {
  printf("=== Float Calls ===\n");

  float a = 10.0f;
  float b = 20.0f;
  float c = add_float(a, b);
  printf("  add_float: %f (expect 30.0)\n", c);

  double d1 = 10.0;
  double d2 = 20.0;
  double d3 = add_double(d1, d2);
  printf("  add_double: %f (expect 30.0)\n", d3);

  return 0;
}

int main() {
  test_function_pointer_casts();
  printf("\n");

  test_typedefs();
  printf("\n");

  test_member_pointers();
  printf("\n");

  test_complex_trees();
  printf("\n");

  test_pointer_arithmetic();
  printf("\n");

  test_conditional_expressions();
  printf("\n");

  test_nested_calls();
  printf("\n");

  test_struct_methods();
  printf("\n");

  test_type_conversions();
  printf("\n");

  test_array_of_arrays();
  printf("\n");

  test_float_calls();
  printf("\n");

  test_vla();
  printf("\n");

  return 0;
}
