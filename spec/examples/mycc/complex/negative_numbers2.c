int printf(const char *fmt, ...);

double global_neg_float = -2.23307578892655734e-01;
double global_small = 1.5e-300;
double global_big = 1.5e+300;
float global_float = -3.14f;
int global_neg_int = -42;
int global_min_int = -2147483648;
int global_max_int = 2147483647;
unsigned int global_uint = 4294967295U;
long long global_ll = 9223372036854775807LL;
long long global_neg_ll = -9223372036854775807LL;
unsigned long long global_ull = 18446744073709551615ULL;
char global_char = 'A';
signed char global_neg_char = -128;
unsigned char global_uchar = 255;

int global_int_arr[] = {-1, -2, -3, 0, 5, 100};
double global_float_arr[] = {-1.5, -0.5, 0.0, 0.5, 1.5, 3.14};
char global_str[] = "hello";

struct Point {
  int x;
  double y;
};

struct Point global_point = {-10, -3.14};

int main() {

  double neg_float = -2.23307578892655734e-01;
  int neg_int = -42;

  printf("%.7f %d\n", neg_float, neg_int);

  printf("%.7f\n", global_neg_float);
  printf("%g %g %.2f\n", global_small, global_big, global_float);
  printf("%d %d %d %u\n", global_neg_int, global_min_int, global_max_int,
         global_uint);
  printf("%lld %lld %llu\n", global_ll, global_neg_ll, global_ull);
  printf("%c %d %u\n", global_char, global_neg_char, global_uchar);

  printf("%d %d %d %d %d %d\n", global_int_arr[0], global_int_arr[1],
         global_int_arr[2], global_int_arr[3], global_int_arr[4],
         global_int_arr[5]);

  printf("%.1f %.1f %.1f %.1f %.1f %.2f\n", global_float_arr[0],
         global_float_arr[1], global_float_arr[2], global_float_arr[3],
         global_float_arr[4], global_float_arr[5]);

  printf("%s\n", global_str);

  printf("%d %.2f\n", global_point.x, global_point.y);

  return 0;
}
