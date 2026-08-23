int printf(const char *fmt, ...);

void (*signal(int sig, void (*func)(int)))(int);

void handler(int sig) { printf("handler called with %d\n", sig); }

int main() {

  void (*old_handler)(int) = signal(5, handler);

  if (old_handler == 0) {
    printf("no old handler\n");
  }

  handler(10);

  return 0;
}
