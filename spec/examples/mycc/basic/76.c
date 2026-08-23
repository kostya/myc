int printf(const char *fmt, ...);

typedef struct TValue {
  int type;
} TValue;

typedef struct TString {
  int len;
} TString;

#define setsvalue2s(io, x)                                                     \
  {                                                                            \
    TValue *io_ = (io);                                                        \
    TString *x_ = (x);                                                         \
    io_->type = x_->len;                                                       \
  }

int main() {
  TValue val;
  TString ts;
  ts.len = 42;

  int err = 1;
  switch (err) {
  case 1: {
    TValue *v = &val;
    TString *s = &ts;
    v->type = s->len;
  }
    printf("case 1: %d\n", val.type);
    break;
  default: {
    setsvalue2s(&val, &ts);
    printf("default: %d\n", val.type);
    break;
  }
  }

  return 0;
}
