# GDB Analysis – level8 (Heap Overflow + Use-After-Free)

This program manages authentication and service commands with multiple heap vulnerabilities: buffer overflow, use-after-free, and out-of-bounds memory access.

---

## 1. Function: main

### Stack Setup

```asm
push %ebp
mov %esp, %ebp
push %edi
push %esi
and $0xfffffff0, %esp
sub $0xa0, %esp
                  ; Save registers and allocate 160 bytes buffer space
```

### Main Loop Start

```asm
mov 0x8049ab0, %ecx
                  ; Load pointer (service)

mov 0x8049aac, %edx
                  ; Load pointer (auth)

mov $0x8048810, %eax
                  ; Load format string

mov %ecx, 0x8(%esp)
                  ; Set argument 3 for printf

mov %edx, 0x4(%esp)
                  ; Set argument 2 for printf

mov %eax, (%esp)
                  ; Set argument 1 for printf

call printf
                  ; Print current state
```

### Input Handling (fgets)

```asm
mov 0x8049a80, %eax
                  ; Load stdin

mov %eax, 0x8(%esp)
                  ; Set stream for fgets

movl $0x80, 0x4(%esp)
                  ; Max size = 128 bytes

lea 0x20(%esp), %eax
                  ; Get buffer address

mov %eax, (%esp)
                  ; Set buffer for fgets

call fgets
                  ; Read user input

test %eax, %eax
jne continue       ; Continue if input exists
```

---

## 2. AUTH Command Handler

### Check "auth " Command

```asm
lea 0x20(%esp), %eax
                  ; Load input buffer

mov %eax, %edx
mov $0x8048819, %eax
                  ; Load string "auth "

mov $0x5, %ecx
                  ; Compare 5 bytes

repz cmpsb
                  ; Compare strings

test %eax, %eax
jne skip_auth     ; If not equal, skip
```

### AUTH Processing (Vulnerable strcpy)

```asm
movl $0x4, (%esp)
call malloc       ; Allocate 4 bytes only!
                  ; ⚠️ CRITICAL: Only 4 bytes allocated

mov %eax, 0x8049aac
                  ; Store pointer globally

movl $0x0, (%eax)
                  ; Initialize memory to 0

lea 0x20(%esp), %eax
add $0x5, %eax    ; Skip "auth " prefix

cmp $0x1e, ...    ; Check length <= 30 bytes
ja skip_auth      ; If too long, skip

lea 0x20(%esp), %eax
add $0x5, %eax    ; Point to user data

mov 0x8049aac, %edx
                  ; Load allocated pointer (only 4 bytes!)

call strcpy       ; Copy input into heap
                  ; ⚠️ VULNERABLE: No size check!
```

> ⚠️ **Critical Vulnerability: Heap Buffer Overflow**
>
> - **Only 4 bytes allocated** for auth data
> - `strcpy()` copies **without bounds checking**
> - Input up to 30 bytes can be provided
> - **26+ bytes overflow into adjacent heap memory!**

---

## 3. RESET Command Handler

### Reset Processing

```asm
Compare input with "reset"

if equal:
  mov 0x8049aac, %eax
                  ; Load pointer
  
  call free
                  ; Free memory
```

> ⚠️ **Vulnerability: Use-After-Free**
>
> - Pointer is freed **but not set to NULL**
> - Subsequent accesses to `0x8049aac` still reference freed memory
> - Can lead to arbitrary code execution

---

## 4. SERVICE Command Handler

### Service Processing

```asm
Compare input with "service"

if equal:
  lea 0x20(%esp), %eax
                  ; Load input

  add $0x7, %eax
                  ; Skip "service" prefix

  call strdup
                  ; Duplicate string

  mov %eax, 0x8049ab0
                  ; Store pointer globally
```

---

## 5. LOGIN Command Handler

### Login Processing (Critical)

```asm
Compare input with "login"

if equal:
  mov 0x8049aac, %eax
                  ; Load auth pointer

  mov 0x20(%eax), %eax
                  ; ⚠️ Read value at offset 0x20 (32 bytes)
                  ;    This is OUT-OF-BOUNDS for 4-byte allocation!

  test %eax, %eax
  je fail         ; If zero, fail

  mov $0x8048833, (%esp)
                  ; Prepare command string

  call system
                  ; Execute system command
                  ; ← This grants shell access!
```

> ⚠️ **Vulnerability: Out-of-Bounds Read + Arbitrary Code Execution**
>
> - Program reads from `auth_ptr + 0x20` (offset 32)
> - But auth_ptr only points to 4-byte allocation!
> - If attacker controls heap layout to place non-zero value at offset 32
> - Condition passes and `system()` is executed
> - **Shell access granted!**

### Fail Case

```asm
Print error using fwrite
```

---

## Vulnerability Chain

### Heap Layout Control

```
Initial state:
+------------------+
| auth (4 bytes)   |  ← malloc(4) - TINY allocation
+------------------+
| Adjacent memory  |  ← Controlled by attacker
+------------------+
| ...              |
+--[offset 0x20]---+  ← Program reads HERE
```

### Exploitation Steps

1. **Overflow auth buffer** with strcpy
   - Provide 30-byte input for "auth" command
   - Overwrite adjacent heap memory (26 bytes overflow!)

2. **Control heap layout**
   - Place non-zero value at offset 32 from auth pointer
   - This happens in adjacent heap blocks

3. **Trigger login**
   - Read from `auth_ptr + 0x20` (out-of-bounds)
   - Reads the attacker-controlled value

4. **Execute system()**
   - If read value is non-zero, condition passes
   - `system()` is called
   - **Shell access achieved!**

### Attack Flow

```
User input: "auth " + 30-byte payload
  ↓
strcpy() overflows 4-byte buffer
  ↓
Adjacent heap memory corrupted
  ↓
Attacker controls content at offset 32
  ↓
User input: "login"
  ↓
Program reads from auth_ptr + 0x20 (out-of-bounds)
  ↓
Reads attacker-controlled non-zero value
  ↓
system() is called
  ↓
Shell access granted
```

---

## Additional Vulnerabilities

### Use-After-Free

```asm
reset command:
  call free
                  ; Frees auth pointer
                  ; BUT pointer NOT set to NULL
  
login command:
  mov 0x8049aac, %eax
  mov 0x20(%eax), %eax
                  ; ⚠️ Still reads from freed memory!
```

**Impact:** Can cause crashes or information leaks if exploited

---

## Summary

**Critical vulnerabilities:**

1. **Heap Buffer Overflow via strcpy()**
   - Only 4 bytes allocated for auth data
   - Up to 30 bytes input allowed
   - 26+ byte overflow into adjacent memory

2. **Out-of-Bounds Memory Access**
   - Program reads from `auth_ptr + 0x20` 
   - Pointer only points to 4-byte allocation
   - Offset 32 is far beyond allocated region
   - Accesses attacker-controlled heap memory

3. **Use-After-Free**
   - Memory freed but pointer not cleared
   - Can be exploited for information leaks

4. **Arbitrary Code Execution**
   - Condition check can be bypassed via heap overflow
   - `system()` call grants shell access
   - Privilege escalation possible if running as root

**Exploitation requires:**
- Crafting 30-byte auth payload for heap overflow
- Controlling heap layout to place value at offset 32
- Triggering login to execute system()