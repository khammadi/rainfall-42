# GDB Analysis – level6 (Function Pointer Overflow)

This program allocates memory on the heap, stores a function pointer, and uses an unsafe `strcpy()` call. The buffer overflow can overwrite the function pointer to redirect execution.

---

## 1. Function: main

### Memory Allocation and Setup

```asm
push %ebp
mov %esp, %ebp
and $0xfffffff0, %esp
sub $0x20, %esp
                  ; Setup stack frame and allocate 32 bytes

movl $0x40, (%esp)
call malloc       ; Allocate 64 bytes (buffer)
mov %eax, 0x1c(%esp)
                  ; Store buffer pointer at esp+0x1c

movl $0x4, (%esp)
call malloc       ; Allocate 4 bytes (function pointer storage)
mov %eax, 0x18(%esp)
                  ; Store pointer address at esp+0x18
```

**Equivalent C code:**
```c
char *buffer = malloc(64);      // 64-byte buffer
void **fn_ptr = malloc(4);      // Pointer storage
```

### Initialize Function Pointer

```asm
mov $0x8048468, %edx
                  ; Load address of function m

mov 0x18(%esp), %eax
                  ; Load pointer location

mov %edx, (%eax)
                  ; Store address of m into allocated pointer
```

**Equivalent:**
```c
*fn_ptr = &m;  // Initialize with address of function m
```

### Copy User Input (Vulnerable strcpy)

```asm
mov 0xc(%ebp), %eax
                  ; Load argv

add $0x4, %eax
                  ; Move to argv[1]

mov (%eax), %eax
                  ; Get user input (argv[1])

mov %eax, %edx
mov 0x1c(%esp), %eax
                  ; Load buffer address

mov %edx, 0x4(%esp)
                  ; Set source for strcpy

mov %eax, (%esp)
                  ; Set destination for strcpy

call strcpy       ; Copy user input into buffer
```

> ⚠️ **Buffer Overflow Vulnerability!**
>
> `strcpy()` copies **without size checking**:
> ```c
> strcpy(buffer, argv[1]);  // DANGEROUS!
> ```
>
> Input larger than 64 bytes will **overwrite adjacent memory**, including the function pointer!

### Call Function Through Pointer

```asm
mov 0x18(%esp), %eax
                  ; Load pointer location

mov (%eax), %eax
                  ; Load function address from pointer

call *%eax        ; Call the function through pointer
```

**Equivalent:**
```c
(*fn_ptr)();  // Call function via pointer
```

> ⚠️ **If the pointer was overwritten, execution jumps to attacker-controlled address!**

### Function End

```asm
leave
ret               ; Return from main
```

---

## 2. Function: m (Default Function)

```asm
push %ebp
mov %esp, %ebp
sub $0x18, %esp
                  ; Stack setup

movl $0x80485d1, (%esp)
                  ; Load string address (argument for puts)

call puts
                  ; Print the string

leave
ret               ; Return to caller
```

**What it does:** Prints a message (default behavior)

---

## 3. Function: n (Hidden Payload Function)

```asm
push %ebp
mov %esp, %ebp
sub $0x18, %esp
                  ; Stack setup

movl $0x80485b0, (%esp)
                  ; Load command string (argument for system)

call system
                  ; Execute the command using system

leave
ret               ; Return to caller
```

**What it does:** 
- Executes a system command (typically opens a shell)
- Provides shell access

---

## Vulnerability Analysis

### Buffer Overflow Attack

The program allocates memory on the heap:

```
0x....... [64-byte buffer]
0x....... [4-byte function pointer]
```

When `strcpy()` copies user input larger than 64 bytes, it overwrites the function pointer!

### Exploitation Chain

```
User Input (>64 bytes)
  ↓
strcpy() copies into buffer
  ↓
Excess bytes overwrite function pointer
  ↓
Function pointer now points to function n
  ↓
Program calls *fn_ptr
  ↓
Execution jumps to function n
  ↓
Function n calls system()
  ↓
Shell access granted
```

### Attack Steps

1. **Craft payload:**
   - 64 bytes of data to fill the buffer
   - 4 bytes containing address of function `n`

2. **Execute:** Run program with crafted payload as argv[1]

3. **Result:**
   - `strcpy()` overflow overwrites function pointer
   - Function pointer redirected from `m` to `n`
   - `system()` call opens shell
   - **Privilege escalation achieved**
Back in n(), condition check now passes
  ↓
system() is executed

---

## Heap Memory Layout

```
Before overflow:
+---------------+
| buffer (64B)  |  ← esp+0x1c
+---------------+
| *fn_ptr (4B)  |  ← esp+0x18 (points to address of m)
+---------------+

After overflow with large input:
+===============+
| buffer (64B)  |
+===============+
| addr of n (4B)|  ← Function pointer hijacked!
+===============+
```

---

## Summary

**Critical vulnerabilities:**

1. **Buffer Overflow via strcpy()**
   - No size validation
   - Input > 64 bytes overflow into adjacent memory

2. **Heap-based Function Pointer Overwrite**
   - Function pointer can be hijacked
   - Redirects execution to attacker-controlled functioBack in n(), condition check now passes
  ↓
system() is executed
n

3. **Indirect Function Call**
   - Program calls `*fn_ptr` which can be modified
   - Enables control flow hijacking

**Exploitation requires:**
- Calculating offset to function pointer (typically 64 bytes)
- Providing address of function `n` to overwrite the pointer
- Triggering the function call to execute `system()`