int printf(const char *fmt, ...);

struct Config {
  union {
    struct {
      int width;
      int height;
    };
    struct {
      int x;
      int y;
    };
  };
  struct {
    union {
      long long flags;
      struct {
        char enabled;
        char visible;
        char focus;
      };
    };
  };
};

int main() {

  struct Config cfg = {0};
  cfg.width = 800;
  cfg.flags = 0x5;

  printf("width=%d, height=%d\n", cfg.width, cfg.height);
  printf("x=%d, y=%d\n", cfg.x, cfg.y);
  printf("flags=0x%x\n", cfg.flags);
  printf("enabled=%d, visible=%d, focus=%d\n", cfg.enabled, cfg.visible,
         cfg.focus);

  cfg.x = 100;
  cfg.y = 200;
  printf("After change: width=%d, height=%d\n", cfg.width, cfg.height);
  printf("x=%d, y=%d\n", cfg.x, cfg.y);

  cfg.flags = 0;
  cfg.enabled = 1;
  cfg.visible = 0;
  cfg.focus = 1;
  printf("flags=0x%x\n", cfg.flags);
  printf("enabled=%d, visible=%d, focus=%d\n", cfg.enabled, cfg.visible,
         cfg.focus);

  return 0;
}
