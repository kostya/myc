#include <stdio.h>

int main() {
  int arr[5] = {10, 20, 30, 40, 50};

  printf("arr[2] = %d\n", arr[2]);

  printf("2[arr] = %d\n", 2 [arr]);

  printf("*(arr + 2) = %d\n", *(arr + 2));

  printf("*(2 + arr) = %d\n", *(2 + arr));

  printf("arr[2] == *(arr + 2): %d\n", arr[2] == *(arr + 2));
  printf("2[arr] == *(2 + arr): %d\n", 2 [arr] == *(2 + arr));
  printf("*(arr + 2) == *(2 + arr): %d\n", *(arr + 2) == *(2 + arr));

  int *ptr = arr;
  printf("ptr[3] = %d\n", ptr[3]);
  printf("*(ptr + 3) = %d\n", *(ptr + 3));
  printf("*(3 + ptr) = %d\n", *(3 + ptr));
  printf("3[ptr] = %d\n", 3 [ptr]);

  for (int i = 0; i < 5; i++) {
    if (arr[i] != *(arr + i)) {
      printf("MISMATCH at %d: arr[%d]=%d != *(arr+%d)=%d\n", i, i, arr[i], i,
             *(arr + i));
      return 1;
    }
    if (arr[i] != *(i + arr)) {
      printf("MISMATCH at %d: arr[%d]=%d != *(%d+arr)=%d\n", i, i, arr[i], i,
             *(i + arr));
      return 1;
    }
    if (arr[i] != i[arr]) {
      printf("MISMATCH at %d: arr[%d]=%d != %d[arr]=%d\n", i, i, arr[i], i,
             i[arr]);
      return 1;
    }
  }

  printf("All commutative accesses match!\n");
  return 0;
}
