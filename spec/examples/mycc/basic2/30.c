int printf(const char *fmt, ...);

int g1[10];

int g2[10] = {1, 2, 3};

int g3[] = {1, 2, 3};

int g4[5] = {0};

char g5[] = "hello";

char g6[10] = "hi";

const char *g7[3] = {"a", "b"};

int g8[((9 + 1) + 2)];

void test_static_locals() {
  static int s1[5];
  static int s2[5] = {1, 2, 3};
  static int s3[] = {10, 20, 30};

  printf("s1: %d %d %d %d %d\n", s1[0], s1[1], s1[2], s1[3], s1[4]);
  printf("s2: %d %d %d %d %d\n", s2[0], s2[1], s2[2], s2[3], s2[4]);
  printf("s3: %d %d %d\n", s3[0], s3[1], s3[2]);

  s1[0]++;
  s2[0]++;
  s3[0]++;
}

int main() {
  printf("=== globals ===\n");

  printf("g1: %d %d %d\n", g1[0], g1[1], g1[2]);

  printf("g2: %d %d %d %d %d\n", g2[0], g2[1], g2[2], g2[3], g2[4]);

  printf("g3: %d %d %d\n", g3[0], g3[1], g3[2]);

  printf("g4: %d %d %d\n", g4[0], g4[1], g4[2]);

  printf("g5: %s (size=%lu)\n", g5, sizeof(g5));

  printf("g6: %s (size=%lu)\n", g6, sizeof(g6));

  printf("g7: %s %s %d\n", g7[0], g7[1], g7[2] == 0);

  printf("g8: %d %d\n", g8[0], g8[11]);

  printf("=== static locals ===\n");
  test_static_locals();
  test_static_locals();

  printf("=== local arrays ===\n");
  int l1[5];
  int l2[5] = {1, 2, 3};
  int l3[] = {10, 20, 30};

  for (int i = 0; i < 5; i++)
    l1[i] = i;

  printf("l1: %d %d %d %d %d\n", l1[0], l1[1], l1[2], l1[3], l1[4]);
  printf("l2: %d %d %d %d %d\n", l2[0], l2[1], l2[2], l2[3], l2[4]);
  printf("l3: %d %d %d\n", l3[0], l3[1], l3[2]);

  return 0;
}
