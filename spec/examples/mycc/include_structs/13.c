int printf(const char *fmt, ...);
#include <string.h>

struct Node {
  union {
    struct {
      int type;
      union {
        int int_val;
        float float_val;
        char str_val[16];
      };
    };
    struct {
      long long_id;
      short short_val;
    };
  };
  struct {
    union {
      double double_val;
      struct {
        char name[32];
        int count;
      };
    };
  };
};

int main() {
  struct Node nodes[3];

  nodes[0].type = 1;
  nodes[0].int_val = 42;
  printf("Node 0: type=%d, int=%d\n", nodes[0].type, nodes[0].int_val);

  nodes[1].type = 2;
  nodes[1].float_val = 3.14f;
  printf("Node 1: type=%d, float=%f\n", nodes[1].type, nodes[1].float_val);

  nodes[2].type = 3;
  strcpy(nodes[2].str_val, "hello");
  printf("Node 2: type=%d, str=%s\n", nodes[2].type, nodes[2].str_val);

  nodes[0].long_id = 123456789L;
  nodes[0].short_val = 7;
  printf("Node 0: long=%ld, short=%d\n", nodes[0].long_id, nodes[0].short_val);

  nodes[1].double_val = 2.71828;
  printf("Node 1: double=%f\n", nodes[1].double_val);

  strcpy(nodes[2].name, "test");
  nodes[2].count = 99;
  printf("Node 2: name=%s, count=%d\n", nodes[2].name, nodes[2].count);

  printf("sizeof(struct Node) = %zu\n", sizeof(struct Node));
  printf("sizeof(nodes) = %zu\n", sizeof(nodes));

  return 0;
}
