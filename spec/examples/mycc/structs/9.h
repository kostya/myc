typedef struct Point {
  int x;
  int y;
} Point;

typedef struct PointWrap {
  struct Point p;
} PointWrap;

void change_data(PointWrap* pw);
