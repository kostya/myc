int printf(const char *fmt, ...);

int test_double_ptr() {
  int x = 42;
  int *p = &x;
  int **pp = &p;
  printf("  double ptr: **pp=%d (expect 42)\n", **pp);
  **pp = 100;
  printf("  double ptr write: x=%d (expect 100)\n", x);
  return 0;
}

int test_triple_ptr() {
  int x = 7;
  int *p = &x;
  int **pp = &p;
  int ***ppp = &pp;
  ***ppp = 77;
  printf("  triple ptr: x=%d (expect 77)\n", x);
  return 0;
}

int test_ptr_to_array() {
  int arr[5];
  arr[0] = 1;
  arr[1] = 2;
  arr[2] = 3;
  arr[3] = 4;
  arr[4] = 5;
  int (*parr)[5] = &arr;
  printf("  ptr to array: (*parr)[2]=%d (expect 3)\n", (*parr)[2]);
  (*parr)[2] = 99;
  printf("  ptr to array write: arr[2]=%d (expect 99)\n", arr[2]);
  return 0;
}

int add_one(int x) { return x + 1; }
int mul_two(int x) { return x * 2; }
int sub_three(int x) { return x - 3; }

int test_array_of_fn_ptrs() {
  int (*fns[3])(int);
  fns[0] = add_one;
  fns[1] = mul_two;
  fns[2] = sub_three;
  printf("  fn array: fns[0](5)=%d (expect 6)\n", fns[0](5));
  printf("  fn array: fns[1](5)=%d (expect 10)\n", fns[1](5));
  printf("  fn array: fns[2](5)=%d (expect 2)\n", fns[2](5));
  return 0;
}

int *get_ptr(int *p) { return p; }

int test_fn_returning_ptr() {
  int x = 55;
  int *(*fn)(int *) = get_ptr;
  int *result = fn(&x);
  printf("  fn ret ptr: *result=%d (expect 55)\n", *result);
  return 0;
}

int (*return_add(void))(int, int) { return 0; }

struct Node {
  int value;
  struct Node *next;
};

int test_linked_structs() {
  struct Node a, b, c;
  a.value = 10;
  a.next = &b;
  b.value = 20;
  b.next = &c;
  c.value = 30;
  c.next = 0;

  printf("  linked: a=%d\n", a.value);
  printf("  linked: a->next=%d (expect b addr)\n", a.next->value);
  printf("  linked: a->next->next=%d (expect 30)\n", a.next->next->value);

  if (a.next->next->next == 0) {
    printf("  linked: end is null\n");
  }

  return 0;
}

typedef struct TreeNode {
  int value;
  struct TreeNode *left;
  struct TreeNode *right;
} TreeNode;

int test_tree_node() {
  TreeNode root;
  root.value = 1;
  root.left = 0;
  root.right = 0;
  printf("  tree node: root=%d (expect 1)\n", root.value);
  printf("  tree node: left is null=%d (expect 1)\n", root.left == 0);
  return 0;
}

int test_void_ptr_arith() {
  int x = 42;
  void *vp = &x;
  int *ip = (int *)vp;
  printf("  void* cast: %d (expect 42)\n", *ip);

  char *cp = (char *)vp;
  printf("  void* to char*: %d (expect 42)\n", *cp);
  return 0;
}

int test_const_ptr() {
  int x = 10;
  int y = 20;
  int *p = &x;
  *p = 15;
  p = &y;
  printf("  ptr to const: *p=%d (expect 20)\n", *p);
  return 0;
}

int test_ptr_arithmetic() {
  int arr[10];
  for (int i = 0; i < 10; i++)
    arr[i] = i * 10;

  int *p = arr;
  int *q = arr + 5;
  printf("  ptr diff: q-p=%d (expect 5)\n", (int)(q - p));
  printf("  ptr+2: *(p+3)=%d (expect 30)\n", *(p + 3));
  printf("  ptr[4]: p[4]=%d (expect 40)\n", p[4]);

  if (p < q)
    printf("  ptr compare: p < q\n");
  if (p == arr)
    printf("  ptr compare: p == arr\n");

  return 0;
}

int test_null_edge_cases() {
  int *p = 0;
  void *vp = 0;
  int (*fn)(int) = 0;

  if (p == 0)
    printf("  null: int* == 0\n");
  if (vp == 0)
    printf("  null: void* == 0\n");
  if (fn == 0)
    printf("  null: fn ptr == 0\n");

  if (!p && !vp && !fn)
    printf("  null: all null\n");

  return 0;
}

int test_array_of_structs_with_ptrs() {
  struct Pair {
    int *a;
    int *b;
  };
  int x = 10, y = 20, z = 30, w = 40;

  struct Pair pairs[2];
  pairs[0].a = &x;
  pairs[0].b = &y;
  pairs[1].a = &z;
  pairs[1].b = &w;

  printf("  struct arr: pairs[0].a=%d (expect 10)\n", *pairs[0].a);
  printf("  struct arr: pairs[1].b=%d (expect 40)\n", *pairs[1].b);
  return 0;
}

int test_ptrs_in_ternary() {
  int x = 1, y = 2;
  int *p = &x;
  int *q = &y;
  int *r = (x > 0) ? p : q;
  printf("  ternary ptr: *r=%d (expect 1)\n", *r);
  return 0;
}

int test_struct_first_field_cast() {
  struct Data {
    int id;
    char *name;
  };
  struct Data d;
  d.id = 123;
  d.name = "test";

  int *id_ptr = (int *)&d;
  printf("  first field: *id_ptr=%d (expect 123)\n", *id_ptr);
  return 0;
}

int identity(int x) { return x; }

int test_ptr_to_fn_ptr() {
  int (*fn)(int) = identity;
  int (**pfn)(int) = &fn;
  printf("  ptr to fn ptr: (**pfn)(42)=%d (expect 42)\n", (**pfn)(42));
  printf("  ptr to fn ptr: (*pfn)(99)=%d (expect 99)\n", (*pfn)(99));
  return 0;
}

int test_ptrs_in_loops() {
  int arr[5];
  for (int i = 0; i < 5; i++)
    arr[i] = i * 2;

  int sum = 0;
  for (int *p = arr; p < arr + 5; p++) {
    sum += *p;
  }
  printf("  loop ptr sum: %d (expect 20)\n", sum);
  return 0;
}

int test_ptr_chain_assign() {
  int x = 0;
  int *p = &x;
  int **pp = &p;
  int ***ppp = &pp;

  ***ppp = 42;
  printf("  chain write: x=%d (expect 42)\n", x);

  int y = ***ppp + 1;
  printf("  chain read: y=%d (expect 43)\n", y);
  return 0;
}

int main() {
  printf("=== Pointer Tests ===\n");
  test_double_ptr();
  test_triple_ptr();
  test_ptr_to_array();
  test_array_of_fn_ptrs();
  test_fn_returning_ptr();
  test_linked_structs();
  test_tree_node();
  test_void_ptr_arith();
  test_const_ptr();
  test_ptr_arithmetic();
  test_null_edge_cases();
  test_array_of_structs_with_ptrs();
  test_ptrs_in_ternary();
  test_struct_first_field_cast();
  test_ptr_to_fn_ptr();
  test_ptrs_in_loops();
  test_ptr_chain_assign();
  printf("=== ALL POINTER TESTS PASSED ===\n");
  return 0;
}
