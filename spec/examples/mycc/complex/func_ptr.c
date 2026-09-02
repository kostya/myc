#include <stdio.h>

typedef int (*UnaryOp)(int);

int double_it(int x) { return x * 2; }
int triple_it(int x) { return x * 3; }
int square_it(int x) { return x * x; }

UnaryOp get_unary_op(int choice) {
  if (choice == 1)
    return double_it;
  if (choice == 2)
    return triple_it;
  return square_it;
}

int main() {
  printf("=== Triple Function Pointer Tests ===\n");

  printf("  double(10) = %d\n", get_unary_op(1)(10));
  printf("  triple(10) = %d\n", get_unary_op(2)(10));
  printf("  square(10) = %d\n", get_unary_op(3)(10));

  printf("\n=== Nested Triple Call ===\n");
  printf("  double(triple(square(2))) = %d\n",
         get_unary_op(1)(get_unary_op(2)(get_unary_op(3)(2))));

  printf("\n=== With temp variables ===\n");
  UnaryOp f1 = get_unary_op(1);
  UnaryOp f2 = get_unary_op(2);
  UnaryOp f3 = get_unary_op(3);

  printf("  f1(f2(f3(3))) = %d\n", f1(f2(f3(3))));

  printf("\n=== Triple chain with 5 ===\n");
  int result = get_unary_op(1)(get_unary_op(2)(get_unary_op(3)(5)));
  printf("  double(triple(square(5))) = %d\n", result);

  printf("\n=== Individual calls ===\n");
  printf("  double(7) = %d\n", double_it(7));
  printf("  triple(7) = %d\n", triple_it(7));
  printf("  square(7) = %d\n", square_it(7));

  printf("=== DONE ===\n");
  return 0;
}
