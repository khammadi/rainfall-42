# GDB Analysis – level7 (Heap-based String Overflow)

This program uses heap-based linked structures and copies user input using unsafe `strcpy()` calls. The heap buffers can be overflowed to corrupt adjacent structures.

---

## 1. Function: main

### Stack Setup

```asm
0x08048521 <+0>:  push %ebp
                  ; Save previous base pointer

0x08048522 <+1>:  mov %esp, %ebp
                  ; Initialize stack frame

0x08048524 <+3>:  and $0xfffffff0, %esp
                  ; Align stack to 16 bytes

0x08048527 <+6>:  sub $0x20, %esp
                  ; Allocate 32 bytes local stack space
```

### Heap Allocation Structure

The program creates a linked structure:

```asm
0x0804852a <+9>:  movl $0x8, (%esp)
                  ; Prepare size 8 bytes for malloc

0x08048531 <+16>: call malloc
                  ; Allocate first heap block (node)

0x08048536 <+21>: mov %eax, 0x1c(%esp)
                  ; Store pointer to first structure
```

**Structure 1:**
```c
struct node {
    int id;           // 4 bytes
    void *next;       // 4 bytes (pointer to buffer)
};
```

```asm
0x0804853e <+30>: movl $0x1, (%eax)
                  ; Set first field to value 1 (id = 1)

0x08048544 <+36>: movl $0x8, (%esp)
                  ; Prepare second malloc allocation

0x0804854b <+43>: call malloc
                  ; Allocate buffer linked to first structure

0x08048556 <+54>: mov %edx, 0x4(%eax)
                  ; Store buffer pointer in first structure's "next" field
```

**Structure 2 (linked to first):**
```asm
0x08048559 <+57>: movl $0x8, (%esp)
                  ; Prepare third malloc allocation

0x08048560 <+64>: call malloc
                  ; Allocate second node structure

0x0804856d <+77>: movl $0x2, (%eax)
                  ; Set id to 2

0x08048573 <+83>: movl $0x8, (%esp)
                  ; Prepare fourth malloc allocation

0x0804857a <+90>: call malloc
                  ; Allocate buffer for second structure

0x08048585 <+101>: mov %edx, 0x4(%eax)
                   ; Store buffer pointer in second structure
```

> ℹ️ **Heap Layout:**
> ```
> Structure 1: [id=1][ptr→buffer1]
>              [user input via argv[1]]
> 
> Structure 2: [id=2][ptr→buffer2]
>              [user input via argv[2]]
> ```

### Argument Processing (First strcpy - Vulnerable)

```asm
0x08048588 <+0>:  mov 0xc(%ebp), %eax
                  ; Load argv pointer

0x0804858b <+3>:  add $0x4, %eax
                  ; Access argv[1]

0x0804858e <+6>:  mov (%eax), %eax
                  ; Load first user argument

0x08048592 <+10>: mov 0x1c(%esp), %eax
                  ; Load first structure pointer

0x08048596 <+14>: mov 0x4(%eax), %eax
                  ; Get destination buffer pointer

0x0804859d <+21>: call strcpy
                  ; Copy argv[1] into heap buffer
```

> ⚠️ **Vulnerability #1: strcpy without bounds check!**
>
> ```c
> strcpy(buffer1, argv[1]);  // DANGEROUS!
> ```
> Input larger than buffer size overflows into adjacent heap memory!

### Second Argument Copy (Second strcpy - Vulnerable)

```asm
0x080485a5 <+0>:  mov 0xc(%ebp), %eax
                  ; Load argv pointer

0x080485a8 <+3>:  add $0x8, %eax
                  ; Access argv[2]

0x080485ad <+8>:  mov %eax, %edx
                  ; Load second user argument

0x080485af <+10>: mov 0x18(%esp), %eax
                  ; Load second structure pointer

0x080485b3 <+14>: mov 0x4(%eax), %eax
                  ; Get destination buffer pointer

0x080485ba <+21>: call strcpy
                  ; Copy argv[2] into heap buffer
```

> ⚠️ **Vulnerability #2: Second strcpy also unsafe!**
>
> ```c
> strcpy(buffer2, argv[2]);  // DANGEROUS!
> ```

### File Handling Section

```asm
0x080485c2 <+0>:  mov $0x80486e9, %edx
                  ; Load filename string

0x080485c7 <+5>:  mov $0x80486eb, %eax
                  ; Load mode string for fopen

0x080485d3 <+17>: call fopen
                  ; Open file and return file pointer

0x080485d8 <+22>: mov %eax, 0x8(%esp)
                  ; Pass file pointer as argument

0x080485dc <+26>: movl $0x44, 0x4(%esp)
                  ; Set buffer size = 68 bytes

0x080485e4 <+34>: movl $0x8049960, (%esp)
                  ; Load global buffer address

0x080485eb <+41>: call fgets
                  ; Read file content into global buffer
```

### Output Section

```asm
0x080485f0 <+46>: movl $0x8048703, (%esp)
                  ; Load string argument for puts

0x080485f7 <+53>: call puts
                  ; Print fixed message

0x080485fc <+58>: mov $0x0, %eax
                  ; Set return value to 0

0x08048601 <+63>: leave
                  ; Restore stack frame

0x08048602 <+64>: ret
                  ; Return from main
```

---

## 2. Function: m (Time/Printf Function)

```asm
0x080484f4 <+0>:  push %ebp
                  ; Save previous base pointer

0x080484f5 <+1>:  mov %esp, %ebp
                  ; Create stack frame

0x080484f7 <+3>:  sub $0x18, %esp
                  ; Allocate local space

0x080484fa <+6>:  movl $0x0, (%esp)
                  ; Prepare argument for time function

0x08048501 <+13>: call time
                  ; Get current timestamp

0x08048506 <+18>: mov $0x80486e0, %edx
                  ; Load format string

0x0804850b <+23>: mov %eax, 0x8(%esp)
                  ; Pass timestamp as argument

0x08048517 <+35>: mov %edx, (%esp)
                  ; Pass format string

0x0804851a <+38>: call printf
                  ; Print formatted output

0x0804851f <+43>: leave
                  ; Restore stack frame

0x08048520 <+44>: ret
                  ; Return from function
```

**What it does:** Prints time-based information using `printf()`

---

## Vulnerability Analysis

### Heap Buffer Overflow

The program allocates heap structures and copies user input without size validation:

```
Heap Memory Layout:
+--------------------+
| Structure 1 (8B)   |
| [id=1][ptr]        |
+--------------------+
| Buffer 1 (8B)      |  ← strcpy(buffer1, argv[1])
| [user input]       |     Can overflow here!
+--------------------+
| Structure 2 (8B)   |  ← Can be corrupted!
| [id=2][ptr]        |
+--------------------+
| Buffer 2 (8B)      |  ← strcpy(buffer2, argv[2])
| [user input]       |     Can overflow here!
+--------------------+
```

### Exploitation Chain

```
Large argv[1] (>8 bytes)
  ↓
strcpy() overflows buffer1
  ↓
Excess bytes corrupt Structure 2
  ↓
id field or pointer field modified
  ↓
Adjacent memory corrupted
  ↓
Heap corruption exploited for code execution
```

### Attack Vectors

1. **Overflow buffer1** with argv[1] to corrupt Structure 2
2. **Modify pointer fields** in Structure 2
3. **Achieve arbitrary memory write** via corrupted pointers
4. **Redirect execution** to malicious code

---

## Summary

**Critical vulnerabilities:**

1. **Unsafe strcpy() #1** in argument processing
   - Copies argv[1] without size check
   - Can overflow into adjacent heap memory

2. **Unsafe strcpy() #2** in second argument processing
   - Copies argv[2] without size check
   - Allows heap corruption

3. **Heap-based Overflow**
   - Structures and buffers are adjacent on heap
   - Overflow can corrupt linked structure pointers
   - Can lead to arbitrary memory write/execute

**Exploitation requires:**
- Crafting argv[1] and argv[2] payloads
- Overflowing buffers to corrupt adjacent structures
- Modifying pointers for code execution

