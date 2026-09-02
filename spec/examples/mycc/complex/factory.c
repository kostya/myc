#include <stdio.h>

typedef int (*UnaryOp)(int);

int double_it(int x) { return x * 2; }
int triple_it(int x) { return x * 3; }
int square_it(int x) { return x * x; }

UnaryOp get_op(int choice) {
  if (choice == 1)
    return double_it;
  if (choice == 2)
    return triple_it;
  return square_it;
}

typedef UnaryOp (*OpFactory)(int);
OpFactory get_factory() { return get_op; }

int main() {
  printf("=== Triple Call Chain ()()() ===\n");

  int result = get_factory()(1)(10);
  printf("  get_factory()(1)(10) = %d\n", result);

  printf("  get_factory()(2)(10) = %d\n", get_factory()(2)(10));
  printf("  get_factory()(3)(10) = %d\n", get_factory()(3)(10));

  printf("  get_factory()(1)(get_factory()(2)(10)) = %d\n",
         get_factory()(1)(get_factory()(2)(10)));

  printf("=== DONE ===\n");
  return 0;
}
