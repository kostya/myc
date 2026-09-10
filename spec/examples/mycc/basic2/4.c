int printf(const char *fmt, ...);
int main() {
  int rows = 3, cols = 4;
  int matrix[rows][cols];

  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      matrix[i][j] = i * cols + j;
    }
  }
  printf("  VLA matrix[2][3]: %d (expect 11)\n", matrix[2][3]);
  printf("  size = %d\n", sizeof(matrix));
  return 0;
}
