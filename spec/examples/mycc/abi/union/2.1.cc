union U {
  double d;
  float f;
};
double get(union U u) { return u.d; }
