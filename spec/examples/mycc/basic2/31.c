int printf(const char *fmt, ...);

int check(const char *name, const char *const lst[]) {
  int i;
  for (i = 0; lst[i]; i++) {
    printf("  i=%d lst[i]='%s' name='%s'\n", i, lst[i], name);
    if (lst[i][0] == name[0] && lst[i][1] == name[1] && lst[i][2] == name[2])
      return i;
  }
  return -1;
}

static int f_seek(void) {
  static const int mode[] = {0, 1, 2};
  static const char *const modenames[] = {"set", "cur", "end", (char *)0};
  (void)mode;
  return check("cur", modenames);
}

static int f_setvbuf(void) {
  static const int mode[] = {0, 1, 2};
  static const char *const modenames[] = {"no", "full", "line", (char *)0};
  (void)mode;
  return check("full", modenames);
}

int main() {
  int op1 = f_seek();
  int op2 = f_setvbuf();
  printf("f_seek: op=%d (expect 1)\n", op1);
  printf("f_setvbuf: op=%d (expect 1)\n", op2);
  return 0;
}
