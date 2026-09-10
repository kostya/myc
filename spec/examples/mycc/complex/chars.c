typedef unsigned long size_t;
int printf(const char *fmt, ...);

#define BLA "bla"
#define STR(x) #x
#define CONCAT(a, b) a##b

static char Output[] = {BLA};
static const char *output = Output;
static char *const const_output = Output;

void func1(char arr[]) {
  printf("func1: %s\n", arr);
  printf("func1 sizeof(arr)=%zu\n", sizeof(arr));
}

void func2(const char *ptr) { printf("func2: %s\n", ptr); }

void func3(char **pp) {
  static char extra[] = "extra";
  *pp = extra;
}

int main() {

  printf("1. Output: %s\n", Output);
  printf("2. output: %s\n", output);

  printf("3. sizeof(Output)=%zu\n", sizeof(Output));
  printf("4. sizeof(output)=%zu\n", sizeof(output));
  printf("5. sizeof(const_output)=%zu\n", sizeof(const_output));

  printf("6. Output == output: %d\n", Output == output);
  printf("7. &Output == &output: %d\n", &Output == &output);
  printf("8. &Output[0] == output: %d\n", &Output[0] == output);
  printf("9. Output == &Output: %d\n", Output == (char *)&Output);

  printf("10. *output = %c\n", *output);
  printf("11. output[1] = %c\n", output[1]);
  printf("12. *Output = %c\n", *Output);
  printf("13. Output[1] = %c\n", Output[1]);

  printf("14. output+1 = %s\n", output + 1);
  printf("15. Output+1 = %s\n", Output + 1);
  printf("16. (char*)&Output+1 = %s\n", (char *)&Output + 1);

  printf("17. output - (char*)Output = %td\n", output - (char *)Output);

  printf("18. (char*)(&Output+1) - Output = %td\n",
         (char *)(&Output + 1) - Output);

  char (*arr_ptr)[4] = &Output;
  printf("19. *arr_ptr = %s\n", *arr_ptr);
  printf("20. sizeof(*arr_ptr) = %zu\n", sizeof(*arr_ptr));

  func1(Output);
  func1(output);
  func2(Output);
  func2(output);

  printf("21. output before: %s\n", output);
  func3((char **)&output);
  printf("22. output after: %s\n", output);
  printf("23. Output unchanged: %s\n", Output);

  int cond = 1;
  const char *chosen = cond ? Output : "fallback";
  printf("24. chosen: %s\n", chosen);

  char **pp = &output;
  printf("25. **pp = %c\n", **pp);
  printf("26. *pp = %s\n", *pp);

  printf("27. 2[Output] = %c\n", 2 [Output]);
  printf("28. 1[output] = %c\n", 1 [output]);

  printf("29. STR(Output) = %s\n", STR(Output));
  printf("30. CONCAT(out, put) = %s\n", CONCAT(out, put));

  printf("31. Individual chars: ");
  for (int i = 0; Output[i]; i++) {
    printf("%c", Output[i]);
  }
  printf("\n");

  int sizes[4] = {sizeof(Output), sizeof(output), sizeof(&Output),
                  sizeof(&output)};
  printf("32. sizes: %zu %zu %zu %zu\n", (size_t)sizes[0], (size_t)sizes[1],
         (size_t)sizes[2], (size_t)sizes[3]);

  const char *p1 = Output;
  const char *p2 = output;
  const char *p3 = p2;
  printf("33. %d %d\n", p1 == p2, p2 == p3);

  char *mutable_ptr = Output;
  mutable_ptr[0] = 'X';
  printf("34. After modification: %s\n", Output);
  mutable_ptr[0] = 'b';

  const char *readonly = Output;
  printf("35. readonly[0]=%c\n", readonly[0]);

  return 0;
}
