#include "9.h"

int main() {
  struct PointWrap pw = {0};
  change_data(&pw);
  printf("Point: %d, %d\n", pw.p.x, pw.p.y);
  return 0;
}
