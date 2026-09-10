int printf(const char *fmt, ...);
void *malloc(int size);
void free(void *ptr);
int strlen(const char *s);

int fibonacci(int n) {
  if (n <= 1)
    return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

int factorial(int n) {
  if (n <= 1)
    return 1;
  return n * factorial(n - 1);
}

int gcd(int a, int b) {
  while (b != 0) {
    int temp = b;
    b = a % b;
    a = temp;
  }
  return a;
}

int is_prime(int n) {
  if (n < 2)
    return 0;
  for (int i = 2; i * i <= n; i++) {
    if (n % i == 0)
      return 0;
  }
  return 1;
}

int *create_array(int size, int init_val) {
  int *arr = (int *)malloc(size * sizeof(int));
  for (int i = 0; i < size; i++) {
    arr[i] = init_val + i;
  }
  return arr;
}

int sum_array(int *arr, int size) {
  int sum = 0;
  int *end = arr + size;
  while (arr < end) {
    sum += *arr;
    arr++;
  }
  return sum;
}

void reverse_array(int *arr, int size) {
  int *left = arr;
  int *right = arr + size - 1;
  while (left < right) {
    int temp = *left;
    *left = *right;
    *right = temp;
    left++;
    right--;
  }
}

void bubble_sort(int *arr, int size) {
  for (int i = 0; i < size - 1; i++) {
    for (int j = 0; j < size - i - 1; j++) {
      if (arr[j] > arr[j + 1]) {
        int temp = arr[j];
        arr[j] = arr[j + 1];
        arr[j + 1] = temp;
      }
    }
  }
}

int binary_search(int *arr, int size, int target) {
  int left = 0;
  int right = size - 1;
  while (left <= right) {
    int mid = left + (right - left) / 2;
    if (arr[mid] == target)
      return mid;
    if (arr[mid] < target)
      left = mid + 1;
    else
      right = mid - 1;
  }
  return -1;
}

struct Node {
  int data;
  struct Node *next;
};

struct LinkedList {
  struct Node *head;
  int size;
};

void list_init(struct LinkedList *list) {
  list->head = 0;
  list->size = 0;
}

void list_add(struct LinkedList *list, int value) {
  struct Node *node = (struct Node *)malloc(sizeof(struct Node));
  node->data = value;
  node->next = list->head;
  list->head = node;
  list->size++;
}

int list_get(struct LinkedList *list, int index) {
  struct Node *current = list->head;
  int i = 0;
  while (current && i < index) {
    current = current->next;
    i++;
  }
  if (current)
    return current->data;
  return -1;
}

void list_remove_first(struct LinkedList *list) {
  if (list->head) {
    struct Node *temp = list->head;
    list->head = list->head->next;
    free(temp);
    list->size--;
  }
}

void list_clear(struct LinkedList *list) {
  while (list->head) {
    list_remove_first(list);
  }
}

int list_sum(struct LinkedList *list) {
  int sum = 0;
  struct Node *current = list->head;
  while (current) {
    sum += current->data;
    current = current->next;
  }
  return sum;
}

struct TreeNode {
  int value;
  struct TreeNode *left;
  struct TreeNode *right;
};

struct TreeNode *create_tree_node(int value) {
  struct TreeNode *node = (struct TreeNode *)malloc(sizeof(struct TreeNode));
  node->value = value;
  node->left = 0;
  node->right = 0;
  return node;
}

void tree_insert(struct TreeNode **root, int value) {
  if (!*root) {
    *root = create_tree_node(value);
    return;
  }
  if (value < (*root)->value)
    tree_insert(&(*root)->left, value);
  else
    tree_insert(&(*root)->right, value);
}

int tree_sum(struct TreeNode *root) {
  if (!root)
    return 0;
  return root->value + tree_sum(root->left) + tree_sum(root->right);
}

int tree_depth(struct TreeNode *root) {
  if (!root)
    return 0;
  int left_depth = tree_depth(root->left);
  int right_depth = tree_depth(root->right);
  return 1 + (left_depth > right_depth ? left_depth : right_depth);
}

void tree_inorder(struct TreeNode *root, int *arr, int *index) {
  if (!root)
    return;
  tree_inorder(root->left, arr, index);
  arr[*index] = root->value;
  (*index)++;
  tree_inorder(root->right, arr, index);
}

void string_copy(char *dest, const char *src) {
  int i = 0;
  while (src[i]) {
    dest[i] = src[i];
    i++;
  }
  dest[i] = '\0';
}

int string_compare(const char *s1, const char *s2) {
  int i = 0;
  while (s1[i] && s2[i] && s1[i] == s2[i]) {
    i++;
  }
  return s1[i] - s2[i];
}

void string_reverse(char *str) {
  int len = 0;
  while (str[len])
    len++;
  for (int i = 0; i < len / 2; i++) {
    char temp = str[i];
    str[i] = str[len - 1 - i];
    str[len - 1 - i] = temp;
  }
}

#define MATRIX_SIZE 3

void matrix_multiply(int a[MATRIX_SIZE][MATRIX_SIZE],
                     int b[MATRIX_SIZE][MATRIX_SIZE],
                     int result[MATRIX_SIZE][MATRIX_SIZE]) {
  for (int i = 0; i < MATRIX_SIZE; i++) {
    for (int j = 0; j < MATRIX_SIZE; j++) {
      result[i][j] = 0;
      for (int k = 0; k < MATRIX_SIZE; k++) {
        result[i][j] += a[i][k] * b[k][j];
      }
    }
  }
}

void matrix_print(int matrix[MATRIX_SIZE][MATRIX_SIZE]) {
  for (int i = 0; i < MATRIX_SIZE; i++) {
    printf("    ");
    for (int j = 0; j < MATRIX_SIZE; j++) {
      printf("%d ", matrix[i][j]);
    }
    printf("\n");
  }
}

int count_bits(unsigned int n) {
  int count = 0;
  while (n) {
    count += n & 1;
    n >>= 1;
  }
  return count;
}

unsigned int reverse_bits(unsigned int n) {
  unsigned int result = 0;
  for (int i = 0; i < 32; i++) {
    result = (result << 1) | (n & 1);
    n >>= 1;
  }
  return result;
}

unsigned int rotate_left(unsigned int n, int shift) {
  return (n << shift) | (n >> (32 - shift));
}

typedef int (*Operation)(int, int);

int apply_operation(Operation op, int a, int b) { return op(a, b); }

int multiply_operation(int a, int b) { return a * b; }

int add_operation(int a, int b) { return a + b; }

int complex_expression(int a, int b, int c) {
  int result = 0;
  result += (a > b ? a : b) * (c < 10 ? c : 10);
  result -= (a & b) | (c ^ 0xFF);
  result += (a << 2) + (b >> 1);
  result *= (a != b) ? (c != 0 ? c : 1) : (a == 0 ? 1 : a);
  result += (a++, b++, c++);
  result += sizeof(a) + sizeof(int) + sizeof(char *);
  return result;
}

int sum_varargs(int count, ...) { return 0; }

struct TreeNode2 {
  int value;
  struct TreeNode2 *children[3];
};

struct TreeNode2 *create_node2(int value) {
  struct TreeNode2 *node = (struct TreeNode2 *)malloc(sizeof(struct TreeNode2));
  node->value = value;
  for (int i = 0; i < 3; i++) {
    node->children[i] = 0;
  }
  return node;
}

int sum_tree2(struct TreeNode2 *root) {
  if (!root)
    return 0;
  int sum = root->value;
  for (int i = 0; i < 3; i++) {
    sum += sum_tree2(root->children[i]);
  }
  return sum;
}

int test_recursion() {
  printf("=== Recursion ===\n");
  printf("  fibonacci(10) = %d (expect 55)\n", fibonacci(10));
  printf("  fibonacci(20) = %d (expect 6765)\n", fibonacci(20));
  printf("  factorial(5) = %d (expect 120)\n", factorial(5));
  printf("  factorial(10) = %d (expect 3628800)\n", factorial(10));
  printf("  gcd(48, 18) = %d (expect 6)\n", gcd(48, 18));
  printf("  gcd(100, 75) = %d (expect 25)\n", gcd(100, 75));
  printf("  is_prime(17) = %d (expect 1)\n", is_prime(17));
  printf("  is_prime(100) = %d (expect 0)\n", is_prime(100));
  return 0;
}

int test_pointers_and_arrays() {
  printf("=== Pointers and Arrays ===\n");

  int *arr = create_array(10, 5);
  printf("  array sum: %d (expect 95)\n", sum_array(arr, 10));

  reverse_array(arr, 10);
  printf("  reversed array: ");
  for (int i = 0; i < 10; i++) {
    printf("%d ", arr[i]);
  }
  printf("(expect 14 13 12 11 10 9 8 7 6 5)\n");

  int arr2[] = {3, 7, 1, 9, 2, 8, 4, 6, 5, 0};
  bubble_sort(arr2, 10);
  printf("  sorted array: ");
  for (int i = 0; i < 10; i++) {
    printf("%d ", arr2[i]);
  }
  printf("(expect 0 1 2 3 4 5 6 7 8 9)\n");

  printf("  binary_search(5) = %d (expect 5)\n", binary_search(arr2, 10, 5));
  printf("  binary_search(100) = %d (expect -1)\n",
         binary_search(arr2, 10, 100));

  free(arr);
  return 0;
}

int test_linked_list() {
  printf("=== Linked List ===\n");

  struct LinkedList list;
  list_init(&list);

  for (int i = 1; i <= 5; i++) {
    list_add(&list, i * 10);
  }

  printf("  list size: %d (expect 5)\n", list.size);
  printf("  list sum: %d (expect 150)\n", list_sum(&list));
  printf("  element 0: %d (expect 50)\n", list_get(&list, 0));
  printf("  element 4: %d (expect 10)\n", list_get(&list, 4));
  printf("  element 100: %d (expect -1)\n", list_get(&list, 100));

  list_remove_first(&list);
  printf("  after remove, size: %d (expect 4)\n", list.size);
  printf("  after remove, element 0: %d (expect 40)\n", list_get(&list, 0));

  list_clear(&list);
  printf("  after clear, size: %d (expect 0)\n", list.size);

  return 0;
}

int test_binary_tree() {
  printf("=== Binary Tree ===\n");

  struct TreeNode *root = 0;
  int values[] = {5, 3, 7, 2, 4, 6, 8, 1, 9};

  for (int i = 0; i < 9; i++) {
    tree_insert(&root, values[i]);
  }

  printf("  tree sum: %d (expect 45)\n", tree_sum(root));
  printf("  tree depth: %d (expect 4)\n", tree_depth(root));

  int inorder[9];
  int index = 0;
  tree_inorder(root, inorder, &index);

  printf("  inorder traversal: ");
  for (int i = 0; i < 9; i++) {
    printf("%d ", inorder[i]);
  }
  printf("(expect 1 2 3 4 5 6 7 8 9)\n");

  return 0;
}

int test_string_operations() {
  printf("=== String Operations ===\n");

  char src[] = "Hello, World!";
  char dest[50];
  string_copy(dest, src);
  printf("  copied string: %s (expect Hello, World!)\n", dest);

  printf("  compare: %d\n", (unsigned char)string_compare("test", "test"));
  printf("  compare: %d\n", (unsigned char)string_compare("abc", "def"));
  printf("  compare: %d\n", (unsigned char)string_compare("xyz", "abc"));

  char str[] = "reverse";
  string_reverse(str);
  printf("  reversed: %s (expect esrever)\n", str);

  return 0;
}

int test_matrix() {
  printf("=== Matrix Operations ===\n");

  int a[MATRIX_SIZE][MATRIX_SIZE] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};

  int b[MATRIX_SIZE][MATRIX_SIZE] = {{9, 8, 7}, {6, 5, 4}, {3, 2, 1}};

  int result[MATRIX_SIZE][MATRIX_SIZE];
  matrix_multiply(a, b, result);

  printf("  Matrix A:\n");
  matrix_print(a);
  printf("  Matrix B:\n");
  matrix_print(b);
  printf("  A * B:\n");
  matrix_print(result);

  return 0;
}

int test_bit_operations() {
  printf("=== Bit Operations ===\n");

  printf("  count_bits(0xFF) = %d (expect 8)\n", count_bits(0xFF));
  printf("  count_bits(0xF0F0) = %d (expect 8)\n", count_bits(0xF0F0));
  printf("  count_bits(0) = %d (expect 0)\n", count_bits(0));

  unsigned int rev = reverse_bits(0x80000000);
  printf("  reverse_bits(0x80000000) = 0x%X (expect 0x1)\n", rev);

  unsigned int rot = rotate_left(0x80000000, 1);
  printf("  rotate_left(0x80000000, 1) = 0x%X (expect 0x1)\n", rot);

  return 0;
}

int test_function_pointers() {
  printf("=== Function Pointers ===\n");

  Operation ops[2];
  ops[0] = add_operation;
  ops[1] = multiply_operation;

  printf("  10 + 20 = %d (expect 30)\n", apply_operation(ops[0], 10, 20));
  printf("  10 * 20 = %d (expect 200)\n", apply_operation(ops[1], 10, 20));

  int (*func_array[2])(int, int) = {add_operation, multiply_operation};
  printf("  array[0]: %d (expect 30)\n", func_array[0](10, 20));
  printf("  array[1]: %d (expect 200)\n", func_array[1](10, 20));

  return 0;
}

int test_complex_expressions() {
  printf("=== Complex Expressions ===\n");

  int a = 5, b = 10, c = 15;
  int result = complex_expression(a, b, c);
  printf("  complex expression result: %d\n", result);

  int x = 10, y = 20, z = 30;
  int max = (x > y) ? ((x > z) ? x : z) : ((y > z) ? y : z);
  printf("  max of three: %d (expect 30)\n", max);

  if ((a < b && b < c) || (a > b && b > c)) {
    printf("  complex condition: true\n");
  } else {
    printf("  complex condition: false\n");
  }

  int p, q, r;
  p = q = r = 42;
  printf("  chain assignment: %d %d %d (expect 42 42 42)\n", p, q, r);

  return 0;
}

int test_edge_cases() {
  printf("=== Edge Cases ===\n");

  int max_int = 2147483647;
  int overflow = max_int + 1;
  printf("  overflow: %d\n", overflow);

  int neg = -42;
  printf("  negative: %d\n", neg);
  printf("  unary minus: %d\n", -neg);

  int m1 = 1, m2 = 2, m3 = 3, m4 = 4;
  printf("  multiple declarations: %d %d %d %d\n", m1, m2, m3, m4);

  printf("  nested calls: %d\n",
         add_operation(multiply_operation(2, 3), add_operation(4, 5)));

  return 0;
}

int test_memory_management() {
  printf("=== Memory Management ===\n");

  int *ptr1 = (int *)malloc(sizeof(int) * 100);
  int *ptr2 = (int *)malloc(sizeof(int) * 100);
  int *ptr3 = (int *)malloc(sizeof(int) * 100);

  for (int i = 0; i < 100; i++) {
    ptr1[i] = i;
    ptr2[i] = i * 2;
    ptr3[i] = i * 3;
  }

  printf("  ptr1 sum: %d (expect 4950)\n", sum_array(ptr1, 100));
  printf("  ptr2 sum: %d (expect 9900)\n", sum_array(ptr2, 100));
  printf("  ptr3 sum: %d (expect 14850)\n", sum_array(ptr3, 100));

  free(ptr1);
  free(ptr2);
  free(ptr3);

  for (int i = 0; i < 10; i++) {
    int *temp = (int *)malloc(sizeof(int) * 10);
    for (int j = 0; j < 10; j++) {
      temp[j] = i * 10 + j;
    }
    printf("  cycle %d: sum=%d\n", i, sum_array(temp, 10));
    free(temp);
  }

  return 0;
}

int test_nested_structs() {
  printf("=== Nested Structs ===\n");

  struct Inner {
    int a;
    int b;
    char name[10];
  };

  struct Outer {
    struct Inner inner1;
    struct Inner inner2;
    int values[5];
  };

  struct Outer outer;
  outer.inner1.a = 10;
  outer.inner1.b = 20;
  string_copy(outer.inner1.name, "first");

  outer.inner2.a = 30;
  outer.inner2.b = 40;
  string_copy(outer.inner2.name, "second");

  for (int i = 0; i < 5; i++) {
    outer.values[i] = i * 100;
  }

  printf("  inner1: a=%d b=%d name=%s\n", outer.inner1.a, outer.inner1.b,
         outer.inner1.name);
  printf("  inner2: a=%d b=%d name=%s\n", outer.inner2.a, outer.inner2.b,
         outer.inner2.name);

  printf("  values: ");
  for (int i = 0; i < 5; i++) {
    printf("%d ", outer.values[i]);
  }
  printf("\n");

  return 0;
}

int test_recursive_structures() {
  printf("=== Recursive Structures ===\n");

  struct TreeNode2 *root = create_node2(10);
  root->children[0] = create_node2(20);
  root->children[1] = create_node2(30);
  root->children[2] = create_node2(40);

  root->children[0]->children[0] = create_node2(50);
  root->children[0]->children[1] = create_node2(60);

  printf("  tree sum: %d (expect 210)\n", sum_tree2(root));

  return 0;
}

int main() {
  printf("========== HEAVY COMPILER TEST ==========\n\n");

  test_recursion();
  printf("\n");

  test_pointers_and_arrays();
  printf("\n");

  test_linked_list();
  printf("\n");

  test_binary_tree();
  printf("\n");

  test_string_operations();
  printf("\n");

  test_matrix();
  printf("\n");

  test_bit_operations();
  printf("\n");

  test_function_pointers();
  printf("\n");

  test_complex_expressions();
  printf("\n");

  test_edge_cases();
  printf("\n");

  test_memory_management();
  printf("\n");

  test_nested_structs();
  printf("\n");

  test_recursive_structures();
  printf("\n");

  printf("========== TEST COMPLETE ==========\n");

  int total = 0;
  for (int i = 0; i < 100; i++) {
    total += fibonacci(i % 10);
    total += factorial(i % 5);
    total += is_prime(i);
  }
  printf("Final stress test result: %d\n", total);

  return 0;
}
