# GDB Analysis – level9 (C++ Object Overflow + Virtual Function Hijacking)

This C++ program allocates two heap objects, uses unsafe input handling to overflow the first object, and exploits a corrupted vtable pointer in the second object to hijack virtual function calls.

---

## 1. Function: main

### Stack Setup and Argument Check

```asm
push %ebp
mov %esp, %ebp
push %ebx
and $0xfffffff0, %esp
sub $0x20, %esp
                  ; Save registers and allocate 32 bytes

cmpl $0x1, 0x8(%ebp)
                  ; Compare argc with 1

jg continue       ; If argc > 1, continue

movl $0x1, (%esp)
call _exit        ; Exit program if no argument
```

### First Object Creation

```asm
movl $0x6c, (%esp)
call operator new ; Allocate 108 bytes for object 1
                  ; (0x6c = 108 bytes)

mov %eax, %ebx
                  ; Store pointer in ebx

movl $0x5, 0x4(%esp)
                  ; Prepare constructor argument (5)

mov %ebx, (%esp)
call N::N(int)    ; Construct first object with value 5

mov %ebx, 0x1c(%esp)
                  ; Store obj1 pointer on stack
```

**Equivalent C++ code:**
```cpp
N *obj1 = new N(5);  // 108-byte object
```

### Second Object Creation

```asm
movl $0x6c, (%esp)
call operator new ; Allocate 108 bytes for object 2

mov %eax, %ebx
                  ; Store pointer

movl $0x6, 0x4(%esp)
                  ; Prepare constructor argument (6)

mov %ebx, (%esp)
call N::N(int)    ; Construct second object with value 6

mov %ebx, 0x18(%esp)
                  ; Store obj2 pointer on stack
```

**Equivalent C++ code:**
```cpp
N *obj2 = new N(6);  // 108-byte object
```

### Prepare Object References

```asm
mov 0x1c(%esp), %eax
mov %eax, 0x14(%esp)
                  ; Store obj1 reference

mov 0x18(%esp), %eax
mov %eax, 0x10(%esp)
                  ; Store obj2 reference
```

### Get User Input

```asm
mov 0xc(%ebp), %eax
                  ; Load argv

add $0x4, %eax
                  ; Move to argv[1]

mov (%eax), %eax
                  ; Load user input string

mov %eax, 0x4(%esp)
                  ; Set as argument
```

### Call setAnnotation (Vulnerable)

```asm
mov 0x14(%esp), %eax
                  ; Load obj1

mov %eax, (%esp)
                  ; Set this pointer

call N::setAnnotation(char*)
                  ; Call method with user input
```

> ⚠️ **Critical Vulnerability: Buffer Overflow in setAnnotation()**
>
> ```cpp
> void N::setAnnotation(char *input)
> {
>     strcpy(annotation, input);  // DANGEROUS! No size check
> }
> ```
>
> - Object is 108 bytes
> - Buffer for annotation is likely 40-60 bytes
> - User input (argv[1]) can be unlimited length
> - **Overflow extends into obj2 (adjacent in heap memory)**

---

## 2. C++ Object Structure

### N Object Layout

```
Object 1 (108 bytes):
+------------------+
| vtable pointer   |  ← First 4 bytes
| (vptr)           |
+------------------+
| member variables |
+------------------+
| annotation buffer| ← strcpy writes here
| (40-60 bytes)    |    Can overflow!
+------------------+

Object 2 (108 bytes):
+------------------+
| vtable pointer   |  ← ⚠️ Can be overwritten!
| (vptr)           |    This is YOUR ATTACK TARGET
+------------------+
| member variables |
+------------------+
| ...              |
+------------------+
```

---

## 3. Virtual Function Call (Exploited)

### Call Virtual Function

```asm
mov 0x10(%esp), %eax
                  ; Load obj2

mov (%eax), %eax
                  ; Load vtable pointer from obj2
                  ; ⚠️ This may be corrupted!

mov (%eax), %edx
                  ; Load first function pointer from vtable

mov 0x14(%esp), %eax
                  ; Load obj1

mov %eax, 0x4(%esp)
                  ; Set argument

mov 0x10(%esp), %eax
                  ; Load obj2

mov %eax, (%esp)
                  ; Set this pointer

call *%edx        ; Call virtual function
                  ; ⚠️ Calls attacker-controlled function!
```

> ⚠️ **Vulnerability: Virtual Function Hijacking**
>
> - Program reads vtable pointer from obj2: `vptr = obj2->vtable`
> - Calls first virtual function: `(*vtable[0])(obj2, obj1)`
> - If vtable was corrupted by overflow, points to **attacker code**
> - **Arbitrary code execution achieved!**

### Function End

```asm
mov -0x4(%ebp), %ebx
                  ; Restore ebx

leave
ret               ; Return from main
```

---

## Exploitation Strategy

### Heap Layout Control

```
Heap Memory:
+-----------+
| obj1      |  ← 108 bytes
|           |
| [overflow zone - attacker controls]
|           |
+-----------+
| obj2      |  ← 108 bytes, first 4 bytes = vtable pointer
|[vptr]     |  ← ⚠️ Attacker overwrites this!
|           |
+-----------+
```

### Attack Steps

1. **Craft malicious input**
   - Create input string longer than annotation buffer (~60+ bytes)
   - Contains: padding + new vtable pointer address

2. **Overflow annotation buffer**
   - `setAnnotation()` copies entire input with `strcpy()`
   - Overflow extends past obj1 boundary
   - **Overwrites obj2's vtable pointer** in adjacent heap memory

3. **Set vtable to attacker address**
   - New vtable pointer points to memory under attacker control
   - Contains addresses of malicious functions

4. **Trigger virtual function call**
   - Program loads corrupted vtable pointer
   - Reads function pointer from attacker's vtable
   - **Calls attacker's function**
   - **Arbitrary code execution!**

### Attack Flow

```
Input: "A"*60 + <attacker_vtable_address>
  ↓
setAnnotation(input)
  ↓
strcpy copies without bounds check
  ↓
Overflow beyond obj1 boundary
  ↓
Overwrites obj2's vtable pointer
  ↓
Virtual function call:
  vptr = obj2->vtable (now points to attacker memory)
  function = (*vptr)[0] (reads attacker function)
  ↓
Call attacker's function
  ↓
Arbitrary code execution
  ↓
Shell access or privilege escalation
```

---

## C++ Specifics

### Virtual Function Mechanism

In C++, virtual functions work through a **vtable (virtual method table)**:

```cpp
class N {
public:
    virtual void method1() { ... }
    virtual void method2() { ... }
};

// At runtime:
// obj->method1() is translated to:
// (*obj->vtable[0])(obj)
```

### Vulnerability Exploitation

By overwriting the **vtable pointer**, attacker can:
- Make object point to **any memory address**
- This "vtable" can contain **any function pointers**
- **Arbitrary function calls** become possible
- **Total code execution control**

---

## Summary

**Critical vulnerabilities:**

1. **Buffer Overflow in setAnnotation()**
   - Uses `strcpy()` without size validation
   - Input can be unlimited length
   - Overflows into adjacent heap memory

2. **Adjacent Object Memory Corruption**
   - obj1 and obj2 allocated sequentially on heap
   - Overflow from obj1 corrupts obj2's data
   - **Specifically overwrites vtable pointer**

3. **Virtual Function Hijacking**
   - Program calls virtual function via corrupted vtable
   - Vtable pointer points to attacker-controlled memory
   - Function pointers can redirect to arbitrary code

4. **Arbitrary Code Execution**
   - Attacker creates fake vtable with function pointers
   - Program reads from fake vtable
   - **Calls any function attacker chooses**
   - Privilege escalation if running as root

**Exploitation requires:**
- Understanding C++ object layout and vtables
- Crafting overflow payload with target vtable address
- Creating fake vtable with malicious function pointers
- Setting up ROP gadgets or shellcode