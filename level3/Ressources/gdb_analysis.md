# GDB Analysis – level3

## Main Function

```asm
0x0804851a <+0>:  push %ebp
                  ; Save the previous base pointer on the stack

0x0804851b <+1>:  mov %esp, %ebp
                  ; Set the current stack pointer as the new base pointer

0x0804851d <+3>:  and $0xfffffff0, %esp
                  ; Align the stack to 16 bytes for performance

0x08048520 <+6>:  call 0x80484a4 <v>
                  ; Call the function v (main logic)

0x08048525 <+11>: leave
                  ; Restore the previous stack frame

0x08048526 <+12>: ret
                  ; Return to the caller and end the program
```

## Function v

### Stack Setup

```asm
0x080484a4 <+0>:  push %ebp
                  ; Save the previous base pointer

0x080484a5 <+1>:  mov %esp, %ebp
                  ; Create a new stack frame for function v

0x080484a7 <+3>:  sub $0x218, %esp
                  ; Allocate 536 bytes on the stack for local variables
```

### Input Handling

```asm
0x080484ad <+9>:  mov 0x8049860, %eax
                  ; Load pointer from global memory (likely stdin)

0x080484b2 <+14>: mov %eax, 0x8(%esp)
                  ; Prepare 3rd argument for fgets (input stream)

0x080484b6 <+18>: movl $0x200, 0x4(%esp)
                  ; Prepare 2nd argument (max size = 512 bytes)

0x080484be <+26>: lea -0x208(%ebp), %eax
                  ; Load address of buffer (ebp - 0x208)

0x080484c4 <+32>: mov %eax, (%esp)
                  ; Prepare 1st argument (buffer pointer)

0x080484c7 <+35>: call fgets
                  ; Read up to 512 bytes from input into buffer
```

### Printing User Input

```asm
0x080484cc <+40>: lea -0x208(%ebp), %eax
                  ; Load address of buffer

0x080484d2 <+46>: mov %eax, (%esp)
                  ; Pass buffer as argument to printf

0x080484d5 <+49>: call printf
                  ; Print buffer content directly
```

> ⚠️ **Format String Vulnerability!**
>
> `printf()` is called **without a format string**. User input is treated as a format string, allowing **memory reading and writing**.

### Conditional Check

```asm
0x080484da <+54>: mov 0x804988c, %eax
                  ; Load value from global variable at 0x804988c

0x080484df <+59>: cmp $0x40, %eax
                  ; Compare value with 64 (0x40)

0x080484e2 <+62>: jne 0x8048518
                  ; If value ≠ 64, jump to end
```

### If Condition is True (value == 64)

```asm
0x080484e4 <+64>: mov 0x8049880, %eax
                  ; Load another value from memory

0x080484e9 <+69>: mov %eax, %edx
                  ; Copy value into edx

0x080484eb <+71>: mov $0x8048600, %eax
                  ; Load address of data (likely a string)

0x080484f0 <+76>: mov %edx, 0xc(%esp)
                  ; Prepare argument for fwrite

0x080484f4 <+80>: movl $0xc, 0x8(%esp)
                  ; Set size = 12 bytes

0x080484fc <+88>: movl $0x1, 0x4(%esp)
                  ; Set count = 1

0x08048504 <+96>: mov %eax, (%esp)
                  ; Pass pointer to data

0x08048507 <+99>: call fwrite
                  ; Write data to output
```

### System Call

```asm
0x0804850c <+104>: movl $0x804860d, (%esp)
                   ; Prepare argument for system (likely /bin/sh)

0x08048513 <+111>: call system
                   ; Execute system command
```

### Function End

```asm
0x08048518 <+116>: leave
                   ; Restore previous stack frame

0x08048519 <+117>: ret
                   ; Return from function
```

## Vulnerability Analysis

### Format String Vulnerability

The program reads user input into a **536-byte buffer** and prints it using:

```c
printf(user_input);  // DANGEROUS!
```

Instead of:
```c
printf("%s", user_input);  // SAFE
```

**What attackers can do:**
- **Read memory** using `%x`, `%s`, and similar format specifiers
- **Write memory** using `%n` specifier

### Exploitation Chain

1. **Global variable check:** Value at `0x804988c` is compared against `64` (0x40)
2. **If value == 64:** Program executes `system()` call (likely `/bin/sh`)
3. **Attack:** Use format string vulnerability to overwrite the value at `0x804988c` to `64`
4. **Result:** Gain shell access

## Summary

**The program contains a critical format string vulnerability:**

- Reads user input into a buffer
- Prints the input using `printf()` **without format string protection**
- Checks a global variable value against 64
- If value equals 64, executes a system command

**Exploit path:**
- Use format string vulnerability to modify the global variable
- Trigger the condition to execute `system()` command
- **Gain shell access**