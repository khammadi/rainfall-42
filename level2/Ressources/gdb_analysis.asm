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

Function p

---

Stack Setup

0x080484d4 <+0>: push %ebp
Save old base pointer.

0x080484d5 <+1>: mov %esp,%ebp
Create new stack frame.

0x080484d7 <+3>: sub $0x68,%esp
Allocate 104 bytes for local variables.

---

fflush

0x080484da <+6>: mov 0x8049860,%eax
Load pointer.

0x080484df <+11>: mov %eax,(%esp)
Prepare argument.

0x080484e2 <+14>: call fflush@plt
Flush output buffer.

---

Vulnerability (Buffer Overflow)

0x080484e7 <+19>: lea -0x4c(%ebp),%eax
Load address of buffer (76 bytes).

0x080484ea <+22>: mov %eax,(%esp)
Pass buffer as argument.

0x080484ed <+25>: call gets@plt
Unsafe input (no size check).

---

Save Return Address

0x080484f2 <+30>: mov 0x4(%ebp),%eax
Load return address.

0x080484f5 <+33>: mov %eax,-0xc(%ebp)
Store it locally.

---

Protection Check

0x080484f8 <+36>: mov -0xc(%ebp),%eax
Reload return address.

0x080484fb <+39>: and $0xb0000000,%eax
Mask high bits.

0x08048500 <+44>: cmp $0xb0000000,%eax
Compare with stack region.

0x08048505 <+49>: jne 0x8048527
If not stack → continue.

Meaning:
Stack addresses (0xbxxxxxxx) are blocked.

---

Attack Detected Path

0x08048507 <+51>: mov $0x8048620,%eax
Load message.

0x0804850c <+56>: mov -0xc(%ebp),%edx
Load return address.

0x0804850f <+59>: mov %edx,0x4(%esp)
Second argument.

0x08048513 <+63>: mov %eax,(%esp)
First argument.

0x08048516 <+66>: call printf@plt
Print warning.

0x0804851b <+71>: movl $0x1,(%esp)
Prepare exit code.

0x08048522 <+78>: call _exit@plt
Terminate program.

---

Safe Path

0x08048527 <+83>: lea -0x4c(%ebp),%eax
Load buffer address.

0x0804852a <+86>: mov %eax,(%esp)
Prepare argument.

0x0804852d <+89>: call puts@plt
Print input.

0x08048532 <+94>: lea -0x4c(%ebp),%eax
Load buffer again.

0x08048535 <+97>: mov %eax,(%esp)
Prepare argument.

0x08048538 <+100>: call strdup@plt
Copy input to heap.

---

Function End

0x0804853d <+105>: leave
Restore stack.

0x0804853e <+106>: ret
Jump to return address.

---

Key Points

Vulnerability:
gets() allows unlimited input → buffer overflow.

Offset:
Buffer = 76 bytes
Saved EBP = 4 bytes
Total = 80 bytes to reach return address.

Protection:
Blocks stack addresses (0xbxxxxxxx).

Bypass Idea:
Use heap or libc address (not stack).

Execution Flow:

input → gets
→ overflow
→ overwrite return address
→ check (not stack)
→ strdup copies to heap
→ ret
→ jump to controlled address

---

Final Summary

The program contains a buffer overflow vulnerability.
It prevents execution from the stack but allows redirection
to other memory regions like heap or libc.
Control of the return address allows execution flow hijacking.

---
