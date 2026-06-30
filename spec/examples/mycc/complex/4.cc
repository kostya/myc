int main() {

  char x = 2;
  x++;
  printf("char++: %d\n", x);

  char y = 5;
  y--;
  printf("char--: %d\n", y);

  unsigned char uc = 250;
  uc++;
  printf("uchar++: %d\n", uc);

  unsigned char uc2 = 0;
  uc2--;
  printf("uchar--: %d\n", uc2);

  short s = 1000;
  s++;
  printf("short++: %d\n", s);

  short s2 = -1000;
  s2--;
  printf("short--: %d\n", s2);

  unsigned short us = 65534;
  us++;
  printf("ushort++: %d\n", us);

  unsigned short us2 = 0;
  us2--;
  printf("ushort--: %d\n", us2);

  char a = 10;
  printf("prefix++: %d\n", ++a);
  printf("after prefix++: %d\n", a);

  char b = 10;
  printf("prefix--: %d\n", --b);
  printf("after prefix--: %d\n", b);

  char c = 10;
  printf("postfix++ expr: %d\n", c++);
  printf("after postfix++ expr: %d\n", c);

  char d = 10;
  printf("postfix-- expr: %d\n", d--);
  printf("after postfix-- expr: %d\n", d);

  int i = 42;
  i++;
  printf("int++: %d\n", i);

  int j = 42;
  j--;
  printf("int--: %d\n", j);

  long long ll = 1000000000;
  ll++;
  printf("longlong++: %lld\n", ll);

  int arr[5] = {10, 20, 30, 40, 50};
  int *p = arr;
  p++;
  printf("ptr++: %d\n", *p);

  p--;
  printf("ptr--: %d\n", *p);

  printf("*++p: %d\n", *++p);

  printf("*p++: %d\n", *p++);
  printf("after *p++: %d\n", *p);

  signed char ov = 127;
  ov++;
  printf("char overflow 127++: %d\n", ov);

  unsigned char uov = 255;
  uov++;
  printf("uchar overflow 255++: %d\n", uov);

  int sum = 0;
  for (char k = 0; k < 10; k++) {
    sum += k;
  }
  printf("sum 0..9: %d\n", sum);

  return 0;
}
