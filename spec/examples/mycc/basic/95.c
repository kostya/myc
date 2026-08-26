int printf(const char *fmt, ...);

int main() {
  int inuse = 100;
  int max =
      (inuse > (int)(1000000 < 1152921504606846775ULL
                         ? 1000000
                         : 1152921504606846775ULL) /
                   3)
          ? (int)(1000000 < 1152921504606846775ULL ? 1000000
                                                   : 1152921504606846775ULL)
          : inuse * 3;

  printf("max = %d\n", max);
  return 0;
}
