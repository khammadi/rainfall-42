# Assembly Program Analysis

This program contains two functions:
- `main()` → vulnerable input handler
- `run()` → prints a message and executes a command

## 1. Function: main

```asm
push %ebp
mov %esp,%ebp
and $0xfffffff0,%esp
sub $0x50,%esp
```

- Setup stack frame
- Align stack (16 bytes)
- Allocate 80 bytes buffer

### Buffer Preparation

```asm
lea 0x10(%esp), %eax
mov %eax,(%esp)
```

**Equivalent:**
```c
buffer = esp + 16;
```

### User Input

```asm
call gets
```

**Equivalent:**
```c
gets(buffer);
```

> ⚠️ `gets()` reads user input **WITHOUT size checking**

### Function End

```asm
leave
ret
```

**Equivalent:**
```c
return;
```

### Stack Layout (main)

```
HIGH ADDRESS
-------------------------
saved EBP
return address   ← target 
-------------------------
buffer (80 bytes)
-------------------------
LOW ADDRESS
```

## Vulnerability: Buffer Overflow

`gets()` allows **unlimited input**.

If input > 80 bytes:
- overwrite saved EBP
- overwrite return address

**Result:** Control program execution

## 2. Function: run

```asm
push %ebp
mov %esp,%ebp
sub $0x18,%esp
```

Allocate 24 bytes

### Prepare fwrite

```asm
mov 0x80497c0,%eax
mov %eax,%edx

mov $0x8048570,%eax

mov %edx,0xc(%esp)   ; stream
movl $0x13,0x8(%esp) ; size = 19
movl $0x1,0x4(%esp)  ; count = 1
mov %eax,(%esp)      ; string

call fwrite
```

**Equivalent:**
```c
fwrite("message", 1, 19, stream);
```

Prints a message

### Call system

```asm
movl $0x8048584,(%esp)
call system
```

**Equivalent:**
```c
system("command");
```

Executes a shell command

### Function End

```asm
leave
ret
```

## High-Level Code

```c
void run()
{
    fwrite("message", 1, 19, stream);
    system("command");
}

int main()
{
    char buffer[80];

    gets(buffer);   // vulnerable

    return 0;
}
```

## Exploitation Idea

The program **never calls `run()` directly**.

BUT because `main()` is vulnerable to buffer overflow:

```
payload =
[ 80 bytes buffer ]
[ 4 bytes saved EBP ]
[ address of run() ] 
```

When `main()` returns:
→ Execution jumps to `run()`

## What Happens After Exploit

`run()` will:
1. Print a message
2. Execute `system()`

**Result:** Possible shell access

## Security Issues

- `gets()` → buffer overflow
- `system()` → command execution
- **Combination = dangerous**

## Summary

**main():**
- Reads unsafe input
- Vulnerable to overflow

**run():**
- Prints message
- Executes system()
