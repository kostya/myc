int printf(const char *fmt, ...);

int y = 10 + 5;
int y2 = 10 - 5;
int y3 = 10 * 5;
int y4 = 10 / 5;
int y5 = 10 % 3;
int y6 = (10 + 5) * 2;

int neg1 = -5;
int neg2 = -(-5);
double neg3 = -2.23307578892655734e-01;
float neg4 = -1.5f;
double neg5 = -0.0;

int b1 = 1 << 4;
int b2 = 255 >> 2;
int b3 = 0xF0 | 0x0F;
int b4 = 0xFF & 0x0F;
int b5 = 0xFF ^ 0x0F;
int b6 = ~0;

int u1 = !0;
int u2 = !5;
int u3 = !1;

int s1 = sizeof(int);
int s2 = sizeof(char);
int s3 = sizeof(long);
int s4 = sizeof(int[10]);

int c1 = (int)5;
long c2 = (long)5;
int c3 = (int)5.9;
double c4 = (double)5;

int *p1 = 0;
int *p2 = (int *)0;
char *p3 = "hello";
const char *p4 = "world";

int cond1 = 1 ? 10 : 20;
int cond2 = 0 ? 10 : 20;

int comb1 = (1 + 2) * (3 + 4);
int comb2 = sizeof(int) + 1;
int comb3 = -sizeof(int);

int arr1[3] = {1, 2, 3};
int arr2[5] = {1, 2};
int arr3[] = {10, 20, 30};
char str1[] = "hello";
char str2[10] = "hi";
int arr4[((9 + 1) + 2)];

int zero1[5];
int zero2[3] = {0};
int zero3[4] = {0, 0};

int one1[1] = {42};
int one2[] = {42};
int one3[5] = {42};

int expr1[3] = {1 + 2, 3 * 4, 5 - 6};
int expr2[4] = {sizeof(int), sizeof(char), 10 + 5, -3};
int expr3[3] = {(int)1.9, (int)2.9, (int)3.9};
int expr4[3] = {1 ? 10 : 20, 0 ? 10 : 20, 1 ? 30 : 40};

int des1[5] = {[0] = 1, [2] = 3, [4] = 5};
int des2[5] = {[4] = 50, [0] = 10};
int des3[10] = {[9] = 99};
int des4[] = {[0] = 1, [1] = 2, [2] = 3};

const char *strs1[3] = {"a", "b", "c"};
const char *strs2[5] = {"one", "two"};
const char *strs3[] = {"first", "second", "third"};
int *ptrs1[3] = {0, 0, 0};
int *ptrs2[3] = {&y, &y2, 0};

struct Point {
  int x, y;
};

struct Point pts1[3] = {{1, 2}, {3, 4}, {5, 6}};
struct Point pts2[3] = {{1, 2}};
struct Point pts3[3] = {0};
struct Point pts4[] = {{1, 2}, {3, 4}};
struct Point pts5[3] = {[1] = {7, 8}};
struct Point pts6[3] = {[0].x = 1, [1].y = 5};

float f1[3] = {1.5f, 2.5f, 3.5f};
double d1[3] = {1.5, 2.5, 3.5};
double d2[5] = {1.0};
float f2[3] = {1.0f, 2, 3};

char chars1[3] = {'a', 'b', 'c'};
char chars2[5] = {'h', 'i'};
char chars3[] = {'x', 'y', 'z', 0};
char chars4[3] = {'a'};

int size1[sizeof(int)] = {0};
int size2[1 + 2 + 3] = {0};
int size3[2 * 3] = {0};
int size4[(4)] = {0};

int main() {
  printf("y: %d %d %d %d %d %d\n", y, y2, y3, y4, y5, y6);
  printf("neg: %d %d %f %f\n", neg1, neg2, neg3, neg4);
  printf("bits: %d %d %d %d %d %d\n", b1, b2, b3, b4, b5, b6);
  printf("unary: %d %d %d\n", u1, u2, u3);
  printf("sizeof: %d %d %d %d\n", s1, s2, s3, s4);
  printf("cast: %d %ld %d %f\n", c1, c2, c3, c4);
  printf("ptr: %d %d %s %s\n", p1 == 0, p2 == 0, p3, p4);
  printf("cond: %d %d\n", cond1, cond2);
  printf("comb: %d %d %d\n", comb1, comb2, comb3);

  printf("--- simple arrays ---\n");
  printf("arr1: %d %d %d\n", arr1[0], arr1[1], arr1[2]);
  printf("arr2: %d %d %d %d %d\n", arr2[0], arr2[1], arr2[2], arr2[3], arr2[4]);
  printf("arr3: %d %d %d\n", arr3[0], arr3[1], arr3[2]);
  printf("str1: %s size=%lu\n", str1, sizeof(str1));
  printf("str2: %s size=%lu\n", str2, sizeof(str2));
  printf("arr4: %d %d\n", arr4[0], arr4[11]);

  printf("--- zero arrays ---\n");
  printf("zero1: %d %d %d %d %d\n", zero1[0], zero1[1], zero1[2], zero1[3],
         zero1[4]);
  printf("zero2: %d %d %d\n", zero2[0], zero2[1], zero2[2]);
  printf("zero3: %d %d %d %d\n", zero3[0], zero3[1], zero3[2], zero3[3]);

  printf("--- one arrays ---\n");
  printf("one1: %d\n", one1[0]);
  printf("one2: %d\n", one2[0]);
  printf("one3: %d %d %d %d %d\n", one3[0], one3[1], one3[2], one3[3], one3[4]);

  printf("--- expr arrays ---\n");
  printf("expr1: %d %d %d\n", expr1[0], expr1[1], expr1[2]);
  printf("expr2: %d %d %d %d\n", expr2[0], expr2[1], expr2[2], expr2[3]);
  printf("expr3: %d %d %d\n", expr3[0], expr3[1], expr3[2]);
  printf("expr4: %d %d %d\n", expr4[0], expr4[1], expr4[2]);

  printf("--- designated arrays ---\n");
  printf("des1: %d %d %d %d %d\n", des1[0], des1[1], des1[2], des1[3], des1[4]);
  printf("des2: %d %d %d %d %d\n", des2[0], des2[1], des2[2], des2[3], des2[4]);
  printf("des3: %d %d %d\n", des3[0], des3[8], des3[9]);
  printf("des4: %d %d %d\n", des4[0], des4[1], des4[2]);

  printf("--- pointer arrays ---\n");
  printf("strs1: %s %s %s\n", strs1[0], strs1[1], strs1[2]);
  printf("strs2: %s %s %d\n", strs2[0], strs2[1], strs2[2] == 0);
  printf("strs3: %s %s %s\n", strs3[0], strs3[1], strs3[2]);
  printf("ptrs1: %d %d %d\n", ptrs1[0] == 0, ptrs1[1] == 0, ptrs1[2] == 0);
  printf("ptrs2: %d %d %d\n", *ptrs2[0], *ptrs2[1], ptrs2[2] == 0);

  printf("--- struct arrays ---\n");
  printf("pts1: (%d,%d) (%d,%d) (%d,%d)\n", pts1[0].x, pts1[0].y, pts1[1].x,
         pts1[1].y, pts1[2].x, pts1[2].y);
  printf("pts2: (%d,%d) (%d,%d) (%d,%d)\n", pts2[0].x, pts2[0].y, pts2[1].x,
         pts2[1].y, pts2[2].x, pts2[2].y);
  printf("pts3: (%d,%d) (%d,%d)\n", pts3[0].x, pts3[0].y, pts3[1].x, pts3[1].y);
  printf("pts4: (%d,%d) (%d,%d)\n", pts4[0].x, pts4[0].y, pts4[1].x, pts4[1].y);
  printf("pts5: (%d,%d) (%d,%d) (%d,%d)\n", pts5[0].x, pts5[0].y, pts5[1].x,
         pts5[1].y, pts5[2].x, pts5[2].y);
  printf("pts6: (%d,%d) (%d,%d) (%d,%d)\n", pts6[0].x, pts6[0].y, pts6[1].x,
         pts6[1].y, pts6[2].x, pts6[2].y);

  printf("--- float arrays ---\n");
  printf("f1: %f %f %f\n", f1[0], f1[1], f1[2]);
  printf("d1: %f %f %f\n", d1[0], d1[1], d1[2]);
  printf("d2: %f %f %f\n", d2[0], d2[1], d2[2]);
  printf("f2: %f %f %f\n", f2[0], f2[1], f2[2]);

  printf("--- char arrays ---\n");
  printf("chars1: %c %c %c\n", chars1[0], chars1[1], chars1[2]);
  printf("chars2: %c %c %d\n", chars2[0], chars2[1], chars2[2]);
  printf("chars3: %s\n", chars3);
  printf("chars4: %c %d %d\n", chars4[0], chars4[1], chars4[2]);

  printf("--- size arrays ---\n");
  printf("size1: %d %d\n", size1[0], size1[3]);
  printf("size2: %d %d\n", size2[0], size2[5]);
  printf("size3: %d %d\n", size3[0], size3[5]);
  printf("size4: %d %d\n", size4[0], size4[3]);

  printf("--- local arrays ---\n");
  int l1[5];
  int l2[5] = {1, 2, 3};
  int l3[] = {10, 20, 30};
  int l5[5] = {[1] = 10, [3] = 30};

  for (int i = 0; i < 5; i++)
    l1[i] = i * 10;

  printf("l1: %d %d %d %d %d\n", l1[0], l1[1], l1[2], l1[3], l1[4]);
  printf("l2: %d %d %d %d %d\n", l2[0], l2[1], l2[2], l2[3], l2[4]);
  printf("l3: %d %d %d\n", l3[0], l3[1], l3[2]);
  printf("l5: %d %d %d %d %d\n", l5[0], l5[1], l5[2], l5[3], l5[4]);

  printf("--- static local arrays ---\n");
  static int sl1[5];
  static int sl2[5] = {1, 2, 3};
  static int sl3[] = {10, 20, 30};
  static int sl4[5] = {[1] = 10, [3] = 30};

  printf("sl1: %d %d %d %d %d\n", sl1[0], sl1[1], sl1[2], sl1[3], sl1[4]);
  printf("sl2: %d %d %d %d %d\n", sl2[0], sl2[1], sl2[2], sl2[3], sl2[4]);
  printf("sl3: %d %d %d\n", sl3[0], sl3[1], sl3[2]);
  printf("sl4: %d %d %d %d %d\n", sl4[0], sl4[1], sl4[2], sl4[3], sl4[4]);

  return 0;
}
