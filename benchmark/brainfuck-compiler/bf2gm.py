#!/usr/bin/env python3
"""
Brainfuck to LowIR (GM / cppgm-extended) translator.
Usage: python3 bf2gm.py input.bf [output.lowir]

python3 bf2gm.py mandel.bf mandel.lowir
time ../../plugins/cppgm-extended/dev/cppgm++ -O3 -c mandel.lowir -o mandel.o
time cc mandel.o -o bin_bf_gm
"""

import sys


def compile_bf_to_gm(bf_code: str) -> str:
    decls = []
    globals_ = []
    body = []
    loop_id = 0
    loop_stack = []
    temp_id = 0

    def new_temp():
        nonlocal temp_id
        temp_id += 1
        return f"%t{temp_id}"

    globals_.append("global @array = { zero 30000 }")

    body.append("  block ^alloca:")
    t_base = new_temp()
    body.append(f"    {t_base} = addr @array")
    body.append(f"    store ptr {t_base}, $ptr")
    body.append("    jump ^body")
    body.append("  block ^body:")

    def emit_ptr_move(offset):
        t_cur = new_temp()
        body.append(f"    {t_cur} = load typed ptr $ptr")
        t_new = new_temp()
        if offset > 0:
            body.append(f"    {t_new} = index u8 {t_cur}, {offset}")
        elif offset < 0:
            body.append(f"    {t_new} = index u8 {t_cur}, -{-offset}")
        else:
            return
        body.append(f"    store ptr {t_new}, $ptr")

    def emit_add(delta):
        t_p = new_temp()
        body.append(f"    {t_p} = load typed ptr $ptr")
        t_v = new_temp()
        body.append(f"    {t_v} = load u8 {t_p}")
        t_v2 = new_temp()
        if delta > 0:
            body.append(f"    {t_v2} = binary add u8 {t_v}, {delta}")
        elif delta < 0:
            body.append(f"    {t_v2} = binary sub u8 {t_v}, {-delta}")
        else:
            return
        body.append(f"    store u8 {t_v2}, {t_p}")

    def emit_putchar():
        t_p = new_temp()
        body.append(f"    {t_p} = load typed ptr $ptr")
        t_c = new_temp()
        body.append(f"    {t_c} = load u8 {t_p}")
        t_ci = new_temp()
        body.append(f"    {t_ci} = convert zext i32 u8 {t_c}")
        body.append(f"    {new_temp()} = call i32 @putchar({t_ci})")

    def emit_getchar():
        t_ci = new_temp()
        body.append(f"    {t_ci} = call i32 @getchar()")
        t_c = new_temp()
        body.append(f"    {t_c} = convert trunc u8 i32 {t_ci}")
        t_p = new_temp()
        body.append(f"    {t_p} = load typed ptr $ptr")
        body.append(f"    store u8 {t_c}, {t_p}")

    def emit_loop_start():
        nonlocal loop_id
        loop_id += 1
        lid = loop_id
        loop_stack.append(lid)
        body.append(f"    jump ^cond_{lid}")
        body.append(f"  block ^cond_{lid}:")
        t_p = new_temp()
        body.append(f"    {t_p} = load typed ptr $ptr")
        t_v = new_temp()
        body.append(f"    {t_v} = load u8 {t_p}")
        t_nz = new_temp()
        body.append(f"    {t_nz} = cmp ne u8 {t_v}, 0")
        t_bool = new_temp()
        body.append(f"    {t_bool} = convert trunc i1 i64 {t_nz}")
        body.append(f"    branch {t_bool}, ^body_{lid}, ^end_{lid}")
        body.append(f"  block ^body_{lid}:")

    def emit_loop_end():
        lid = loop_stack.pop()
        body.append(f"    jump ^cond_{lid}")
        body.append(f"  block ^end_{lid}:")

    for cmd in bf_code:
        if cmd == '>':
            emit_ptr_move(1)
        elif cmd == '<':
            emit_ptr_move(-1)
        elif cmd == '+':
            emit_add(1)
        elif cmd == '-':
            emit_add(-1)
        elif cmd == '.':
            emit_putchar()
        elif cmd == ',':
            emit_getchar()
        elif cmd == '[':
            emit_loop_start()
        elif cmd == ']':
            emit_loop_end()

    body.append("    return void")
    body.append("}")

    decls.append("declare function @putchar(%c : i32) -> i32 [linkage=c, binding=strong]")
    decls.append("declare function @getchar() -> i32 [linkage=c, binding=strong]")

    function = []
    function.append("function @main() -> void [role=entry, binding=strong] {")
    function.append("  slot $ptr : ptr")
    function.extend(body)

    return "\n".join(decls + globals_ + function)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 bf2gm.py input.bf [output.lowir]")
        sys.exit(1)
    with open(sys.argv[1]) as f:
        bf_code = f.read()
    lowir_code = compile_bf_to_gm(bf_code)
    if len(sys.argv) >= 3:
        with open(sys.argv[2], 'w') as f:
            f.write(lowir_code)
        print(f"Compiled {sys.argv[1]} -> {sys.argv[2]}")
    else:
        print(lowir_code)


if __name__ == '__main__':
    main()