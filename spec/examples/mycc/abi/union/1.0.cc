int printf(const char *fmt, ...);
union U {
  double d;
  float f;
};
double get(union U u);
void test() {
  union U u = {6.5};
  printf("%g\n", get(u));
}
