int printf(const char *fmt, ...);

static const char CHAR_LUT[6] = {'.', '-', '+', '*', 'X', 'M'};
static const short SHORT_LUT[4] = {10, 20, 30, 40};
static const int INT_LUT[5] = {100, 200, 300, 400, 500};
static const long long LL_LUT[3] = {1000LL, 2000LL, 3000LL};
static const float FLOAT_LUT[3] = {1.5f, 2.5f, 3.5f};
static const double DOUBLE_LUT[3] = {1.5, 2.5, 3.5};

static const char STRANGE_CHAR[7] = {'A', 'B', 'C', 'D', 'E', 'F', 'G'};
static const short STRANGE_SHORT[3] = {11, 22, 33};
static const int STRANGE_INT[4] = {111, 222, 333, 444};

static const int PARTIAL[6] = {1, 2, 3};

int test_luts() {
  printf("=== CHAR_LUT ===\n");
  for (int i = 0; i < 6; i++) {
    printf("  CHAR_LUT[%d] = '%c'\n", i, CHAR_LUT[i]);
  }

  printf("=== SHORT_LUT ===\n");
  for (int i = 0; i < 4; i++) {
    printf("  SHORT_LUT[%d] = %d\n", i, SHORT_LUT[i]);
  }

  printf("=== INT_LUT ===\n");
  for (int i = 0; i < 5; i++) {
    printf("  INT_LUT[%d] = %d\n", i, INT_LUT[i]);
  }

  printf("=== LL_LUT ===\n");
  for (int i = 0; i < 3; i++) {
    printf("  LL_LUT[%d] = %lld\n", i, LL_LUT[i]);
  }

  printf("=== FLOAT_LUT ===\n");
  for (int i = 0; i < 3; i++) {
    printf("  FLOAT_LUT[%d] = %f\n", i, FLOAT_LUT[i]);
  }

  printf("=== DOUBLE_LUT ===\n");
  for (int i = 0; i < 3; i++) {
    printf("  DOUBLE_LUT[%d] = %f\n", i, DOUBLE_LUT[i]);
  }

  printf("=== STRANGE_CHAR ===\n");
  for (int i = 0; i < 7; i++) {
    printf("  STRANGE_CHAR[%d] = '%c'\n", i, STRANGE_CHAR[i]);
  }

  printf("=== STRANGE_SHORT ===\n");
  for (int i = 0; i < 3; i++) {
    printf("  STRANGE_SHORT[%d] = %d\n", i, STRANGE_SHORT[i]);
  }

  printf("=== STRANGE_INT ===\n");
  for (int i = 0; i < 4; i++) {
    printf("  STRANGE_INT[%d] = %d\n", i, STRANGE_INT[i]);
  }

  printf("=== PARTIAL ===\n");
  for (int i = 0; i < 6; i++) {
    printf("  PARTIAL[%d] = %d (expect %d)\n", i, PARTIAL[i],
           i < 3 ? i + 1 : 0);
  }

  return 0;
}

int main() {
  printf("=== LUT Tests ===\n");
  test_luts();
  printf("=== DONE ===\n");
  return 0;
}
