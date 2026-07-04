unsigned int helper(unsigned int max);

unsigned int helper(unsigned int max) {
    return max + 1;
}

int main() {
    char result = 'a' + helper(10);
    printf("result = %c (%d)\n", result, result);
    return 0;
}