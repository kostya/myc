#include <stdio.h>

typedef struct Bla {
  int frequency;
  char byte_val;
  char is_leaf;
  struct Bla *left;
  struct Bla *right;
} Bla;

int main() {
  printf("%d %d %d\n", sizeof(Bla), sizeof(Bla *), sizeof(Bla *));
  printf("%d %d %d\n", sizeof(struct Bla), sizeof(struct Bla *),
         sizeof(struct Bla *));
  printf("%d %d %d\n", sizeof(int), sizeof(int *), sizeof(int *));

  char x = 'a';
  char *ptr = &x;
  printf("%d\n", sizeof(*ptr));
  return 0;
}
