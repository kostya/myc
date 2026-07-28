#include "union_include.h"

void bla() {
  AST_Node node;
  node.type = 1;
  node.data.a = 5;
  printf("node %d %d", node.type, node.data.a);
}
