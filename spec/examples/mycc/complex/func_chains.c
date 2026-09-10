#include <stdio.h>

int *get_array() {
  static int arr[5] = {10, 20, 30, 40, 50};
  return arr;
}

typedef struct {
  int data[5];
} ArrayStruct;

ArrayStruct get_struct() {
  ArrayStruct s = {{100, 200, 300, 400, 500}};
  return s;
}

int **get_ptr_to_array() {
  static int arr1[3] = {1, 2, 3};
  static int arr2[3] = {4, 5, 6};
  static int *ptrs[2] = {arr1, arr2};
  return ptrs;
}

typedef struct {
  int *ptr;
  int size;
} ArrayWrapper;

ArrayWrapper get_wrapper() {
  static int arr[4] = {7, 8, 9, 10};
  ArrayWrapper w = {arr, 4};
  return w;
}

typedef int *(*ArrayGetter)(void);

int *get_static_array() {
  static int arr[3] = {11, 22, 33};
  return arr;
}

ArrayGetter get_array_getter() { return get_static_array; }

int *get_inner_array() {
  static int arr[3] = {111, 222, 333};
  return arr;
}

typedef int *(*InnerGetter)(void);

InnerGetter get_inner() { return get_inner_array; }

int main() {
  printf("=== Crazy Function Result Usage Tests ===\n");

  printf("  get_array()[2] = %d\n", get_array()[2]);
  printf("  get_array()[0] + get_array()[4] = %d\n",
         get_array()[0] + get_array()[4]);

  printf("  get_struct().data[3] = %d\n", get_struct().data[3]);
  printf("  get_struct().data[1] * 2 = %d\n", get_struct().data[1] * 2);

  printf("  get_ptr_to_array()[0][1] = %d\n", get_ptr_to_array()[0][1]);
  printf("  get_ptr_to_array()[1][2] = %d\n", get_ptr_to_array()[1][2]);
  printf("  get_ptr_to_array()[0][0] + get_ptr_to_array()[1][1] = %d\n",
         get_ptr_to_array()[0][0] + get_ptr_to_array()[1][1]);

  printf("  get_wrapper().ptr[2] = %d\n", get_wrapper().ptr[2]);
  printf("  get_wrapper().ptr[0] + get_wrapper().ptr[3] = %d\n",
         get_wrapper().ptr[0] + get_wrapper().ptr[3]);

  printf("  get_array_getter()()[1] = %d\n", get_array_getter()()[1]);
  printf("  get_array_getter()()[0] + get_array_getter()()[2] = %d\n",
         get_array_getter()()[0] + get_array_getter()()[2]);

  printf("  get_inner()()[2] = %d\n", get_inner()()[2]);

  printf("  get_array_getter()()[get_array()[1] / 10] = %d\n",
         get_array_getter()()[get_array()[1] / 10]);

  printf("  get_inner()()[get_array()[0] / 10] = %d\n",
         get_inner()()[get_array()[0] / 10]);

  printf("=== DONE ===\n");
  return 0;
}
