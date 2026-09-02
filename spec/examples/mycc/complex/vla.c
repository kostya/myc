int printf(const char *fmt, ...);

int test_vla_basic(int n) {
  int arr[n];
  for (int i = 0; i < n; i++) {
    arr[i] = i * 10;
  }
  printf("  basic: arr[0]=%d arr[2]=%d arr[4]=%d\n", arr[0], arr[2], arr[4]);
  return 0;
}

int test_vla_expr(int n, int m) {
  int arr[n + m];
  for (int i = 0; i < n + m; i++) {
    arr[i] = i;
  }
  printf("  expr size: arr[%d]=%d\n", n + m - 1, arr[n + m - 1]);
  return 0;
}

void vla_sum(int *arr, int len) {
  int sum = 0;
  for (int i = 0; i < len; i++)
    sum += arr[i];
  printf("  decay sum: %d\n", sum);
}

int test_vla_decay(int n) {
  int arr[n];
  for (int i = 0; i < n; i++)
    arr[i] = i + 1;
  vla_sum(arr, n);
  return 0;
}

int test_vla_sizeof(int n) {
  int arr[n];
  printf("  sizeof: arr=%d n*4=%d\n", sizeof(arr), n * (int)sizeof(int));
  return 0;
}

int test_vla_2d(int rows, int cols) {
  int matrix[rows][cols];
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      matrix[i][j] = i * cols + j;
    }
  }
  printf("  2d: matrix[0][0]=%d matrix[%d][%d]=%d (sizeof=%d)\n", matrix[0][0],
         rows - 1, cols - 1, matrix[rows - 1][cols - 1], sizeof(matrix));
  return 0;
}

int test_vla_2d_arg_(int rows, int cols, int matrix[rows][cols]) {
  printf("  2d in arg: matrix[0][0]=%d matrix[%d][%d]=%d (sizeof=%d)\n",
         matrix[0][0], rows - 1, cols - 1, matrix[rows - 1][cols - 1],
         sizeof(matrix));
  return 0;
}

int test_vla_2d_arg(int rows, int cols) {
  int matrix[rows][cols];
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      matrix[i][j] = i * cols + j;
    }
  }
  test_vla_2d_arg_(rows, cols, matrix);
  return 0;
}

int test_vla_3d(int d1, int d2, int d3) {
  int cube[d1][d2][d3];

  for (int i = 0; i < d1; i++) {
    for (int j = 0; j < d2; j++) {
      for (int k = 0; k < d3; k++) {
        cube[i][j][k] = i * d2 * d3 + j * d3 + k;
      }
    }
  }

  printf("  3d: cube[0][0][0]=%d cube[%d][%d][%d]=%d (sizeof=%zu)\n",
         cube[0][0][0], d1 - 1, d2 - 1, d3 - 1, cube[d1 - 1][d2 - 1][d3 - 1],
         sizeof(cube));

  return 0;
}

int test_vla_3d_arg_(int d1, int d2, int d3, int cube[d1][d2][d3]) {
  printf("  3d in arg: cube[0][0][0]=%d cube[%d][%d][%d]=%d (sizeof=%zu)\n",
         cube[0][0][0], d1 - 1, d2 - 1, d3 - 1, cube[d1 - 1][d2 - 1][d3 - 1],
         sizeof(cube));

  return 0;
}

int test_vla_3d_arg(int d1, int d2, int d3) {
  int cube[d1][d2][d3];

  for (int i = 0; i < d1; i++) {
    for (int j = 0; j < d2; j++) {
      for (int k = 0; k < d3; k++) {
        cube[i][j][k] = i * d2 * d3 + j * d3 + k;
      }
    }
  }

  test_vla_3d_arg_(d1, d2, d3, cube);
  return 0;
}

int test_vla_in_loop(int n) {
  for (int i = 1; i <= n; i++) {
    int arr[i];
    for (int j = 0; j < i; j++)
      arr[j] = j;
    if (i == n) {
      printf("  in loop: arr[%d]=%d\n", i - 1, arr[i - 1]);
    }
  }
  return 0;
}

int test_vla_ptr(int n) {
  int arr[n];
  for (int i = 0; i < n; i++)
    arr[i] = i * 5;
  int *p = arr;
  int *end = arr + n;
  printf("  ptr: ");
  for (; p < end; p++) {
    if (p == arr)
      printf("%d", *p);
    else if (p == end - 1)
      printf(" %d\n", *p);
  }
  return 0;
}

void take_void_ptr(void *p) {
  int *ip = (int *)p;
  printf("  cast: %d\n", ip[0]);
}

int test_vla_cast(int n) {
  int arr[n];
  arr[0] = 42;
  take_void_ptr((void *)arr);
  return 0;
}

int test_vla_ternary(int n, int use_second) {
  int a[n];
  int b[n * 2];
  for (int i = 0; i < n; i++)
    a[i] = i;
  for (int i = 0; i < n * 2; i++)
    b[i] = i * 10;

  int *p = use_second ? b : a;
  printf("  ternary vla: p[%d]=%d\n", n - 1, p[n - 1]);
  return 0;
}

int test_vla_conditional(int n) {
  if (n <= 0) {
    printf("  conditional: n <= 0\n");
    return -1;
  }

  int arr[n];
  for (int i = 0; i < n; i++)
    arr[i] = i;
  printf("  conditional: arr[0]=%d\n", arr[0]);
  return 0;
}

int test_vla_recursive(int depth, int n) {
  if (depth == 0) {
    printf("  recursive: bottom\n");
    return 0;
  }
  int arr[n];
  for (int i = 0; i < n; i++)
    arr[i] = depth;
  test_vla_recursive(depth - 1, n);
  printf("  recursive: arr[0]=%d depth=%d\n", arr[0], depth);
  return 0;
}

int get_size(void) { return 10; }

int test_vla_fn_ptr(void) {
  int (*fn)(void) = get_size;
  int n = fn();
  int arr[n];
  for (int i = 0; i < n; i++)
    arr[i] = i;
  printf("  fn ptr: arr[%d]=%d\n", n - 1, arr[n - 1]);
  return 0;
}

int test_vla_sc(int n, int flag) {
  int *arr = 0;
  if (n > 0 && (arr = (int *)0) == 0) {

    int temp[n];
    temp[0] = 99;
    printf("  sc vla: temp[0]=%d\n", temp[0]);
  }
  return 0;
}

int main() {
  printf("=== VLA Tests ===\n");
  test_vla_basic(5);
  test_vla_expr(3, 4);
  test_vla_decay(6);
  test_vla_sizeof(10);
  test_vla_2d(3, 4);
  test_vla_2d_arg(3, 4);
  test_vla_3d(2, 3, 4);
  test_vla_3d_arg(2, 3, 4);
  test_vla_in_loop(4);
  test_vla_ptr(5);
  test_vla_cast(8);
  test_vla_ternary(5, 0);
  test_vla_ternary(5, 1);
  test_vla_conditional(3);
  test_vla_conditional(0);
  test_vla_recursive(3, 4);
  test_vla_fn_ptr();
  test_vla_sc(5, 1);
  printf("=== DONE ===\n");
  return 0;
}
