# GDB Analysis – level4 (Format String Vulnerability)

This program contains three functions: `main`, `n`, and `p`. It demonstrates a format string vulnerability that allows arbitrary memory read/write operations.

## 1. Function: main

```asm
0x080484a7 <+0>:  push %ebp
                  ; Save the old base pointer

0x080484a8 <+1>:  mov %esp, %ebp
                  ; Create a new stack frame

0x080484aa <+3>:  and $0xfffffff0, %esp
                  ; Align the stack to 16 bytes

0x080484ad <+6>:  call 0x8048457 <n>
                  ; Call function n

0x080484b2 <+11>: leave
                  ; Restore stack frame

0x080484b3 <+12>: ret
                  ; Return to caller
```

**Summary:** `main` simply calls function `n`.

## 2. Function: n

### Stack Setup

```asm
0x08048457 <+0>:  push %ebp
                  ; Save old base pointer

0x08048458 <+1>:  mov %esp, %ebp
                  ; Create new stack frame

0x0804845a <+3>:  sub $0x218, %esp
                  ; Allocate 0x218 (536 bytes) for local variables
```

### Preparing fgets

```asm
0x08048460 <+9>:  mov 0x8049804, %eax
                  ; Load pointer (likely stdin) into eax

0x08048465 <+14>: mov %eax, 0x8(%esp)
                  ; Store as 3rd argument of fgets

0x08048469 <+18>: movl $0x200, 0x4(%esp)
                  ; Set size = 0x200 (512 bytes)

0x08048471 <+26>: lea -0x208(%ebp), %eax
                  ; Get address of buffer (ebp - 0x208)

0x08048477 <+32>: mov %eax, (%esp)
                  ; Pass as 1st argument (buffer pointer)

0x0804847a <+35>: call fgets
                  ; Read up to 512 bytes from stdin
```

**Equivalent C code:**
```c
char buffer[520];
fgets(buffer, 512, stdin);
```

### Call to p

```asm
0x0804847f <+40>: lea -0x208(%ebp), %eax
                  ; Load buffer address

0x08048485 <+46>: mov %eax, (%esp)
                  ; Pass as argument

0x08048488 <+49>: call p
                  ; Call function p
```

**Equivalent:**
```c
p(buffer);
```

### Condition Check

```asm
0x0804848d <+54>: mov 0x8049810, %eax
                  ; Load value from address 0x8049810

0x08048492 <+59>: cmp $0x1025544, %eax
                  ; Compare with 0x1025544

0x08048497 <+64>: jne 0x80484a5
                  ; If not equal, skip execution
```

### Dangerous Execution (If condition is true)

```asm
0x08048499 <+66>: movl $0x8048590, (%esp)
                  ; Prepare argument for system

0x080484a0 <+73>: call system
                  ; Execute system command
```

### Function End

```asm
0x080484a4 <+76>: leave
                  ; Restore stack

0x080484a5 <+77>: ret
                  ; Return from function
```

**Summary of function n:**
1. Reads user input into a buffer (512 bytes)
2. Passes input to function `p`
3. Checks if global variable at `0x8049810` equals `0x1025544`
4. If true, executes `system()` command

## 3. Function: p

### Stack Setup

```asm
0x08048444 <+0>:  push %ebp
                  ; Save old base pointer

0x08048445 <+1>:  mov %esp, %ebp
                  ; Create new stack frame

0x08048447 <+3>:  sub $0x18, %esp
                  ; Allocate 0x18 (24 bytes) for local variables
```

### Get Argument

```asm
0x0804844a <+6>:  mov 0x8(%ebp), %eax
                  ; Load first argument (buffer pointer)
```

### Pass to printf

```asm
0x0804844d <+9>:  mov %eax, (%esp)
                  ; Pass buffer as argument

0x08048450 <+12>: call printf
                  ; Call printf
```

**Equivalent C code:**
```c
printf(buffer);  // DANGEROUS!
```

### Vulnerability: Format String

**Unsafe usage:**
```c
printf(buffer);
```

**Safe usage:**
```c
printf("%s", buffer);
```

> ⚠️ **Why this is dangerous:**
>
> - User input is treated as a **format string**
> - Allows **reading memory** using `%x`, `%s`, etc.
> - Allows **writing memory** using `%n` specifier

---

## Exploitation Strategy

### Goal

Modify memory at address `0x8049810` so that it becomes `0x1025544`

### Idea

1. Inject the target address into the input
2. Use format string specifiers to write controlled values to memory
3. Satisfy the condition check in function `n`

### Execution Flow

```
main()
  ↓
n() reads input
  ↓
n() calls p(buffer)
  ↓
p() executes printf(buffer)  ← Format string vulnerability here
  ↓
Memory can be modified
  ↓
Back in n(), condition check now passes
  ↓
system() is executed
```

---

## Summary

**The program contains a critical format string vulnerability:**

- **Function p** uses `printf(buffer)` without format string protection
- Allows **arbitrary memory read and write** operations
- Can modify the global variable at `0x8049810`
- Enables **execution flow control** through `system()` call

**Exploitation path:**
1. Use format string vulnerability to modify memory at `0x8049810`
2. Make it equal to `0x1025544`
3. Trigger `system()` execution
4. **Gain shell access**
