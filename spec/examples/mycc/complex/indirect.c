int printf(const char *fmt, ...);

enum OpCode { OP_MOVE = 0, OP_LOADI, OP_ADD, OP_RETURN, NUM_OPCODES };

static int program[] = {OP_LOADI, 0,      5, OP_LOADI, 1,
                        3,        OP_ADD, 0, 1,        OP_RETURN};

int main() {
  int regs[16];
  int pc = 0;

  void *disptab[NUM_OPCODES] = {&&L_OP_MOVE, &&L_OP_LOADI, &&L_OP_ADD,
                                &&L_OP_RETURN};

  goto *disptab[program[pc]];

L_OP_MOVE: {
  printf("OP_MOVE\n");
  pc++;
  goto *disptab[program[pc]];
}

L_OP_LOADI: {
  int r = program[pc + 1];
  int val = program[pc + 2];
  printf("OP_LOADI r%d = %d\n", r, val);
  regs[r] = val;
  pc += 3;
  goto *disptab[program[pc]];
}

L_OP_ADD: {
  int r1 = program[pc + 1];
  int r2 = program[pc + 2];
  printf("OP_ADD r%d = r%d + r%d\n", r1, r1, r2);
  regs[r1] = regs[r1] + regs[r2];
  pc += 3;
  goto *disptab[program[pc]];
}

L_OP_RETURN: {
  printf("OP_RETURN\n");
  printf("r0 = %d, r1 = %d\n", regs[0], regs[1]);
  return 0;
}
}
