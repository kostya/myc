typedef struct AST_Node AST_Node;

struct AST_Node {
  int type;
  union {
    int a;
    char b;
  } data;
};

void bla();

#include <stdio.h>