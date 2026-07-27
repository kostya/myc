#include "9.h"

void change_data(PointWrap* pw) {
  struct Point p = {1, 2};
  pw->p = p;
}
