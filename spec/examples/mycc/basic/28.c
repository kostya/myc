void test1() {
  int i = 0;
  printf("do-while: ");
  do {
    printf("%d ", i);
    i++;
  } while (i < 3);
  printf("\n");
}

void test2() {
  int i = 0;
  printf("while:    ");
  while (i < 3) {
    printf("%d ", i);
    i++;
  }
  printf("\n");
}

void test3() {
  int i = 0;
  printf("do-while(0): ");
  do {
    printf("%d ", i);
    i++;
  } while (0);
  printf("\n");
}

void test4() {
  int i = 0;
  printf("while(0): ");
  while (0) {
    printf("%d ", i);
    i++;
  }
  printf("(none)\n");
}

int main() {
  test1();
  test2();
  test3();
  test4();
  return 0;
}
