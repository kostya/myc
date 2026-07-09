int printf(const char *fmt, ...);

int test_ternary_null_ptr() {
  int *ptr = 0;
  int *result = ptr ? ptr : (int *)0xDEAD;
  printf("  ternary null: result=%p (expect 0xDEAD)\n", result);

  int x = 42;
  int *ptr2 = &x;
  int val = ptr2 ? *ptr2 : -1;
  printf("  ternary non-null: val=%d (expect 42)\n", val);

  int val2 = ptr ? *ptr : -1;
  printf("  ternary null deref: val2=%d (expect -1, no crash)\n", val2);

  return 0;
}

int side_counter = 0;
int side_a() {
  side_counter++;
  return 1;
}
int side_b() {
  side_counter++;
  return 2;
}

int test_ternary_side_effects() {
  side_counter = 0;
  int x = 1 ? side_a() : side_b();
  printf("  ternary side true: x=%d counter=%d (expect 1, 1)\n", x,
         side_counter);

  side_counter = 0;
  int y = 0 ? side_a() : side_b();
  printf("  ternary side false: y=%d counter=%d (expect 2, 1)\n", y,
         side_counter);

  return 0;
}

int test_ternary_assign() {
  int a = 0, b = 0;
  int x = 1 ? (a = 10) : (b = 20);
  printf("  ternary assign true: x=%d a=%d b=%d (expect 10, 10, 0)\n", x, a, b);

  a = 0;
  b = 0;
  int y = 0 ? (a = 10) : (b = 20);
  printf("  ternary assign false: y=%d a=%d b=%d (expect 20, 0, 20)\n", y, a,
         b);

  return 0;
}

typedef struct Node {
  int value;
  struct Node *next;
} Node;

int test_ternary_struct() {
  Node a = {1, 0};
  Node b = {2, 0};
  Node *ptr = &a;
  Node *null_ptr = 0;

  Node *r1 = ptr ? ptr->next : (Node *)0xBAD;
  printf("  ternary struct non-null: r1=%d (expect 0x0)\n", (int)r1);

  Node *r2 = null_ptr ? null_ptr->next : (Node *)0xBAD;
  printf("  ternary struct null: r2=%p (expect 0xBAD, no crash)\n", r2);

  return 0;
}

int main() {
  printf("=== Ternary Short-Circuit Tests ===\n");
  test_ternary_null_ptr();
  test_ternary_side_effects();
  test_ternary_assign();
  test_ternary_struct();
  printf("=== DONE ===\n");
  return 0;
}
