#include <stdbool.h>
#include <stdint.h>

int main() {
  int width = 6;
  int height = 6;

  bool **visited = malloc(height * sizeof(bool *));

  for (int y = 0; y < height; y++) {
    visited[y] = calloc(width, sizeof(bool));
  }

  visited[1][1] = true;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      printf("(%d %d %d)\n", y, x, visited[y][x]);
    }
  }
  printf("\n");
  return 0;
}
