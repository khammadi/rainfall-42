---------------

Function main:

push ebp
Save old base pointer

mov esp, ebp
Create new stack frame

push ebx
Save ebx register

and esp, 0xfffffff0
Align stack to 16 bytes

sub esp, 0x20
Allocate 32 bytes on stack

---------------

Argument check:

cmpl $0x1, 0x8(ebp)
Compare argc with 1

jg continue
If argc > 1, continue

movl $0x1, (esp)
Prepare exit(1)

call _exit
Exit program if no argument

---------------

First object creation:

movl $0x6c, (esp)
Prepare allocation size (108 bytes)

call operator new
Allocate memory for object 1

mov eax, ebx
Store pointer in ebx

movl $0x5, 0x4(esp)
Prepare constructor argument (5)

mov ebx, (esp)
Set object pointer

call N::N(int)
Construct first object with value 5

mov ebx, 0x1c(esp)
Store obj1 on stack

---------------

Second object creation:

movl $0x6c, (esp)
Prepare allocation size (108 bytes)

call operator new
Allocate memory for object 2

mov eax, ebx
Store pointer

movl $0x6, 0x4(esp)
Prepare constructor argument (6)

mov ebx, (esp)
Set object pointer

call N::N(int)
Construct second object with value 6

mov ebx, 0x18(esp)
Store obj2 on stack

---------------

Prepare objects:

mov 0x1c(esp), eax
Load obj1

mov eax, 0x14(esp)
Store obj1

mov 0x18(esp), eax
Load obj2

mov eax, 0x10(esp)
Store obj2

---------------

Get user input:

mov 0xc(ebp), eax
Load argv

add eax, 0x4
Move to argv[1]

mov (eax), eax
Load user input string

mov eax, 0x4(esp)
Set argument for function

---------------

Call setAnnotation:

mov 0x14(esp), eax
Load obj1

mov eax, (esp)
Set this pointer

call N::setAnnotation(char*)
Call method with user input

---------------

Virtual function call:

mov 0x10(esp), eax
Load obj2

mov (eax), eax
Load vtable pointer

mov (eax), edx
Load first function pointer from vtable

mov 0x14(esp), eax
Load obj1

mov eax, 0x4(esp)
Set argument

mov 0x10(esp), eax
Load obj2

mov eax, (esp)
Set this pointer

call *edx
Call virtual function

---------------

Function end:

mov -0x4(ebp), ebx
Restore ebx

leave
Restore stack frame

ret
Return

---------------

Summary:

Two objects are allocated on the heap (108 bytes each).
The first object receives user input via setAnnotation.
This function likely copies data without bounds checking.

Because of this, a buffer overflow can occur in the first object.
The overflow can reach the second object in memory.

The second object contains a vtable pointer at its beginning.
By overflowing, the attacker can overwrite this vtable pointer.

Later, the program calls a virtual function using this pointer.
If overwritten, the attacker controls which function is executed.

---------------