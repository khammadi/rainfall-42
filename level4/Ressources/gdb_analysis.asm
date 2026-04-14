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
