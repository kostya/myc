#include <stddef.h>
#include <stdio.h>

typedef struct UserData {
  int id;
  double value;
  char name[32];
} UserData;

typedef struct UserData0 {
  unsigned char bindata[16];
} UserData0;

int main() {
  size_t offset1 = offsetof(UserData, value);
  size_t offset2 = offsetof(UserData0, bindata);
  size_t offset3 = offsetof(UserData, name);

  printf("%zu %zu %zu\n", offset1, offset2, offset3);

  printf("%zu %zu %zu\n", sizeof(UserData), offsetof(UserData, value),
         offsetof(UserData, name));

  int nuv = 2;
  size_t offset4 = (nuv == 0 ? offsetof(UserData0, bindata)
                             : offsetof(UserData, name) + sizeof(UserData));

  printf("%zu\n", offset4);

  return 0;
}
