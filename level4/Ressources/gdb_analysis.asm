# Binary Analysis: main, n, and p (Format String Vulnerability)

This document provides a clear and structured analysis of three functions (main, n, and p) extracted using GDB. The goal is to understand program flow, stack usage, and identify vulnerabilities.

---

# 1. Function: main

```asm
0x080484a7 <+0>:  push   %ebp
0x080484a8 <+1>:  mov    %esp,%ebp
0x080484aa <+3>:  and    $0xfffffff0,%esp
0x080484ad <+6>:  call   0x8048457 <n>
0x080484b2 <+11>: leave
0x080484b3 <+12>: ret
```

Explanation

* push %ebp
  Save the old base pointer.

* mov %esp, %ebp
  Create a new stack frame.

* and $0xfffffff0, %esp
  Align the stack to 16 bytes.

* call n
  Call function n.

* leave
  Restore stack frame.

* ret
  Return to caller.

Summary

main only calls function n.

---

# 2. Function: n

```asm
0x08048457 <+0>:  push   %ebp
0x08048458 <+1>:  mov    %esp,%ebp
0x0804845a <+3>:  sub    $0x218,%esp
```

Stack Setup

* Allocates 0x218 (536 bytes) for local variables.

Preparing fgets

```asm
0x08048460 <+9>:  mov    0x8049804,%eax
0x08048465 <+14>: mov    %eax,0x8(%esp)
```

* Loads a pointer (likely stdin) into eax.
* Stores it as the third argument of fgets.

```asm
0x08048469 <+18>: movl   $0x200,0x4(%esp)
```

* 0x200 = 512 bytes to read.

```asm
0x08048471 <+26>: lea    -0x208(%ebp),%eax
0x08048477 <+32>: mov    %eax,(%esp)
```

* Gets the address of the buffer at (ebp - 0x208).
* Passes it as the first argument.

```asm
0x0804847a <+35>: call   fgets
```

Equivalent C code:

```c
char buffer[520];
fgets(buffer, 512, stdin);
```

Call to p

```asm
0x0804847f <+40>: lea    -0x208(%ebp),%eax
0x08048485 <+46>: mov    %eax,(%esp)
0x08048488 <+49>: call   p
```

Equivalent:

```c
p(buffer);
```

Condition Check

```asm
0x0804848d <+54>: mov    0x8049810,%eax
0x08048492 <+59>: cmp    $0x1025544,%eax
0x08048497 <+64>: jne    0x80484a5
```

* Reads value from address 0x8049810.
* Compares it with 0x1025544.
* If not equal, skip execution.

Dangerous Execution

```asm
0x08048499 <+66>: movl   $0x8048590,(%esp)
0x080484a0 <+73>: call   system
```

* Calls system() with a fixed string.

End of function

```asm
leave
ret
```

Summary of n

1. Reads user input into a buffer.
2. Passes input to function p.
3. Checks a global variable.
4. If the value matches, executes system().

---

# 2. Function: n

```asm
0x08048457 <+0>:  push   %ebp
0x08048458 <+1>:  mov    %esp,%ebp
0x0804845a <+3>:  sub    $0x218,%esp
```

Stack Setup

* Allocates 0x218 (536 bytes) for local variables.

Preparing fgets

```asm
0x08048460 <+9>:  mov    0x8049804,%eax
0x08048465 <+14>: mov    %eax,0x8(%esp)
```

* Loads a pointer (likely stdin) into eax.
* Stores it as the third argument of fgets.

```asm
0x08048469 <+18>: movl   $0x200,0x4(%esp)
```

* 0x200 = 512 bytes to read.

```asm
0x08048471 <+26>: lea    -0x208(%ebp),%eax
0x08048477 <+32>: mov    %eax,(%esp)
```

* Gets the address of the buffer at (ebp - 0x208).
* Passes it as the first argument.

```asm
0x0804847a <+35>: call   fgets
```

Equivalent C code:

```c
char buffer[520];
fgets(buffer, 512, stdin);
```

Call to p

```asm
0x0804847f <+40>: lea    -0x208(%ebp),%eax
0x08048485 <+46>: mov    %eax,(%esp)
0x08048488 <+49>: call   p
```

Equivalent:

```c
p(buffer);
```

Condition Check

```asm
0x0804848d <+54>: mov    0x8049810,%eax
0x08048492 <+59>: cmp    $0x1025544,%eax
0x08048497 <+64>: jne    0x80484a5
```

* Reads value from address 0x8049810.
* Compares it with 0x1025544.
* If not equal, skip execution.

Dangerous Execution

```asm
0x08048499 <+66>: movl   $0x8048590,(%esp)
0x080484a0 <+73>: call   system
```

* Calls system() with a fixed string.

End of function

```asm
leave
ret
```

Summary of n

1. Reads user input into a buffer.
2. Passes input to function p.
3. Checks a global variable.
4. If the value matches, executes system().

---

# 3. Function: p

```asm
0x08048444 <+0>:  push   %ebp
0x08048445 <+1>:  mov    %esp,%ebp
0x08048447 <+3>:  sub    $0x18,%esp
```

Setup

* Standard stack frame setup.

Get Argument

```asm
0x0804844a <+6>:  mov    0x8(%ebp),%eax
```

* Loads first argument (buffer).

Pass to printf

```asm
0x0804844d <+9>:  mov    %eax,(%esp)
0x08048450 <+12>: call   printf
```

Equivalent C code:

```c
printf(buffer);
```

Vulnerability: Format String

Unsafe usage:

```c
printf(buffer);
```

Safe usage:

```c
printf("%s", buffer);
```

Why this is dangerous

* User input is treated as a format string.
* It allows reading memory using %x.
* It allows writing memory using %n.

---

# Exploitation Strategy

Goal

Modify memory at address:

0x8049810

So that it becomes:

0x1025544

Idea

* Inject the target address into the input.
* Use %d to write controlled values.

Execution Flow

1. main calls n.
2. n reads input.
3. n calls p(buffer).
4. p executes printf(buffer).
5. Memory can be modified.
6. Back in n, condition becomes true.
7. system() is executed.

---

# Final Conclusion

* The program contains a format string vulnerability in function p.
* This allows arbitrary memory read and write.
* An attacker can control program execution.
* The final goal is to trigger system().

---
