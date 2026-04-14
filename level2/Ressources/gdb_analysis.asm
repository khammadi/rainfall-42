GDB Analysis – level2 (function p)

---

Main Function

0x0804853f <+0>: push %ebp
Save old base pointer.

0x08048540 <+1>: mov %esp,%ebp
Create new stack frame.

0x08048542 <+3>: and $0xfffffff0,%esp
Align stack for performance.

0x08048545 <+6>: call 0x80484d4 <p>
Call function p.

0x0804854a <+11>: leave
Restore stack.

0x0804854b <+12>: ret
Return to caller.

---
