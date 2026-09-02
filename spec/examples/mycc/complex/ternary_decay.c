#include <stdio.h>

static char Output[] = "bla";
static char Output2[] = "hello";

int main() {
  int cond = 1;

  const char *chosen1 = cond ? Output : "fallback";
  printf("1. chosen1: %s\n", chosen1);

  const char *chosen2 = cond ? Output : Output2;
  printf("2. chosen2: %s\n", chosen2);

  const char *chosen3 = cond ? "yes" : Output2;
  printf("3. chosen3: %s\n", chosen3);

  const char *chosen4 = cond ? (cond ? Output : "inner") : "outer";
  printf("4. chosen4: %s\n", chosen4);

  cond = 0;
  const char *chosen5 = cond ? Output : "fallback";
  printf("5. chosen5: %s\n", chosen5);

  const char *chosen6 = cond ? Output : Output2;
  printf("6. chosen6: %s\n", chosen6);

  printf("7. Output: %s\n", Output);
  printf("8. Output2: %s\n", Output2);

  return 0;
}
