# GDB Analysis – level5 (Format String + GOT Overwrite)

This program contains a format string vulnerability that can be exploited to overwrite the GOT (Global Offset Table) entry for the `exit()` function, redirecting execution to a function that executes system commands.

---

## 1. Function: main

```asm
0x08048504 <+0>:  push %ebp
                  ; Save previous base pointer

0x08048505 <+1>:  mov %esp, %ebp
                  ; Initialize stack frame for main

0x08048507 <+3>:  and $0xfffffff0, %esp
                  ; Align stack to 16 bytes

0x0804850a <+6>:  call 0x80484c2 <n>
                  ; Call function n (main logic)

0x0804850f <+11>: leave
                  ; Restore previous stack frame

0x08048510 <+12>: ret
                  ; Return from main
```

**Summary:** `main` simply calls function `n`.

---

## 2. Function: n (Main Vulnerable Function)

### Stack Setup

```asm
0x080484c2 <+0>:  push %ebp
                  ; Save previous base pointer

0x080484c3 <+1>:  mov %esp, %ebp
                  ; Create new stack frame

0x080484c5 <+3>:  sub $0x218, %esp
                  ; Allocate 536 bytes for buffer and local variables
```

### Input Section (fgets)

```asm
0x080484cb <+9>:  mov 0x8049848, %eax
                  ; Load global pointer (stdin)

0x080484d0 <+14>: mov %eax, 0x8(%esp)
                  ; Set 3rd argument (input stream)

0x080484d4 <+18>: movl $0x200, 0x4(%esp)
                  ; Set max input size = 512 bytes

0x080484dc <+26>: lea -0x208(%ebp), %eax
                  ; Load address of local buffer

0x080484e2 <+32>: mov %eax, (%esp)
                  ; Set 1st argument (buffer)

0x080484e5 <+35>: call fgets
                  ; Read user input safely with size limit
```

**Equivalent C code:**
```c
char buffer[536];
fgets(buffer, 512, stdin);
```

### Vulnerable Print Section

```asm
0x080484ea <+40>: lea -0x208(%ebp), %eax
                  ; Load buffer address

0x080484f0 <+46>: mov %eax, (%esp)
                  ; Pass buffer to printf

0x080484f3 <+49>: call printf
                  ; Print user input directly
```

> ⚠️ **Format String Vulnerability!**
>
> User input is used **directly as a format string**:
> ```c
> printf(buffer);  // DANGEROUS!
> ```
> Should be:
> ```c
> printf("%s", buffer);  // SAFE
> ```

### Exit Section

```asm
0x080484f8 <+54>: movl $0x1, (%esp)
                  ; Prepare exit code 1

0x080484ff <+61>: call exit
                  ; Terminate program execution
```

---

## 3. Exit Function via PLT/GOT

```asm
0x080483d0:       jmp *0x8049838
                  ; Indirect jump using GOT entry for exit

0x080483d6:       push $0x28
                  ; Push relocation index for dynamic linker

0x080483db:       jmp <dynamic_linker>
                  ; Resolve real address of exit function
```

### GOT Entry for exit

| Address | Content | Purpose |
|---------|---------|---------|
| 0x8049838 | Runtime address of `exit()` | Can be modified to redirect execution |

> ℹ️ **How GOT works:**
>
> The GOT entry contains a **pointer to the exit function**. If we can write to this address using the format string vulnerability, we can redirect execution to any function.

---

## 4. Function: o (Hidden Payload Function)

```asm
0x080484a4 <+0>:  push %ebp
                  ; Save previous base pointer

0x080484a5 <+1>:  mov %esp, %ebp
                  ; Create stack frame

0x080484a7 <+3>:  sub $0x18, %esp
                  ; Allocate stack space

0x080484aa <+6>:  movl $0x80485f0, (%esp)
                  ; Load string argument (command)

0x080484b1 <+13>: call system
                  ; Execute system command (shell)

0x080484b6 <+18>: movl $0x1, (%esp)
                  ; Prepare exit code

0x080484bd <+25>: call _exit
                  ; Terminate program
```

**What this function does:**
- Executes a system command (typically `/bin/sh`)
- Provides shell access

---

## Vulnerability Analysis

### Format String Attack

The format string vulnerability in function `n` allows attackers to:

1. **Read memory** using format specifiers like `%x`, `%s`
2. **Write memory** using `%n` specifier

### Exploitation Strategy

**Goal:** Redirect `exit()` to function `o`

**Attack steps:**
1. Use format string to **read** the address of function `o`
2. Use `%n` to **write** this address to the GOT entry of `exit` at `0x8049838`
3. When `exit()` is called, execution jumps to function `o`
4. Function `o` executes `system()` → **Shell access**

### Execution Flow

```
main()
  ↓
n() reads input (user provides exploit payload)
  ↓
n() calls printf(buffer)  ← Format string vulnerability triggered
  ↓
Exploit modifies GOT entry for exit
  ↓
n() calls exit()
  ↓
exit() jumps to function o() (via modified GOT)
  ↓
o() executes system()
  ↓
Shell access granted
```

---

## Summary

**Critical vulnerabilities:**

1. **Format String Vulnerability** in function `n`
   - Allows arbitrary memory read/write

2. **GOT Overwrite Opportunity**
   - `exit()` function address can be modified
   - Redirects execution to function `o`

3. **Command Execution**
   - Function `o` calls `system()` which opens a shell
   - Enables privilege escalation if running with elevated privileges

**Exploitation requires:**
- Crafting a format string payload
- Writing function `o`'s address to `exit`'s GOT entry
- Triggering the modified `exit()` call
