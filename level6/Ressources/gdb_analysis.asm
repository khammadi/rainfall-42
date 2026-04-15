---------------

Function main:

push ebp
Save the old base pointer

mov esp, ebp
Create a new stack frame

and esp, 0xfffffff0
Align the stack to 16 bytes

sub esp, 0x20
Allocate 32 bytes on the stack

movl 0x40, (esp)
Prepare argument 64 for malloc

call malloc
Allocate 64 bytes (buffer)

mov eax, 0x1c(esp)
Store buffer pointer

movl 0x4, (esp)
Prepare argument 4 for malloc

call malloc
Allocate 4 bytes (function pointer)

mov eax, 0x18(esp)
Store pointer address

mov 0x8048468, edx
Load address of function m

mov 0x18(esp), eax
Load pointer location

mov edx, (eax)
Store address of m into allocated pointer

mov 0xc(ebp), eax
Load argv

add eax, 0x4
Move to argv[1]

mov (eax), eax
Get user input (argv[1])

mov eax, edx
Copy input pointer

mov 0x1c(esp), eax
Load buffer address

mov edx, 0x4(esp)
Set source (user input) for strcpy

mov eax, (esp)
Set destination (buffer) for strcpy

call strcpy
Copy user input into buffer (no size check, vulnerable)

mov 0x18(esp), eax
Load pointer location

mov (eax), eax
Load function address from pointer

call *eax
Call the function through pointer (can be hijacked)

leave
Restore stack frame

ret
Return from main

---------------

Function m:

push ebp
Save the old base pointer

mov esp, ebp
Create a new stack frame

sub esp, 0x18
Allocate 24 bytes for local variables

movl 0x80485d1, (esp)
Put the address of a string into the stack (argument for puts)

call puts
Call puts to print the string

leave
Restore the previous stack frame

ret
Return to the caller

---------------