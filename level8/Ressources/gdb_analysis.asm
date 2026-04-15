---------------

Function main:

push ebp
Save the old base pointer

mov esp, ebp
Create a new stack frame

push edi
Save edi register

push esi
Save esi register

and esp, 0xfffffff0
Align stack to 16 bytes

sub esp, 0xa0
Allocate 160 bytes on stack (buffer space)

jmp 0x8048575
Jump to main loop start

nop
No operation

---------------

Main loop start:

mov 0x8049ab0, ecx
Load pointer (service)

mov 0x8049aac, edx
Load pointer (auth)

mov 0x8048810, eax
Load format string

mov ecx, 0x8(esp)
Set argument 3 for printf

mov edx, 0x4(esp)
Set argument 2 for printf

mov eax, (esp)
Set argument 1 for printf

call printf
Print current state

---------------

Input handling:

mov 0x8049a80, eax
Load stdin

mov eax, 0x8(esp)
Set stream for fgets

movl 0x80, 0x4(esp)
Max size = 128 bytes

lea 0x20(esp), eax
Get buffer address

mov eax, (esp)
Set buffer for fgets

call fgets
Read user input

test eax, eax
Check if fgets failed

je end
Exit if no input

---------------

Check "auth " command:

lea 0x20(esp), eax
Load input buffer

mov eax, edx
Copy pointer

mov 0x8048819, eax
Load string "auth "

mov 0x5, ecx
Compare 5 bytes

mov edx, esi
Input

mov eax, edi
Target string

repz cmpsb
Compare strings

test eax, eax
Check result

jne skip_auth
If not equal, skip

---------------

AUTH handling:

movl 0x4, (esp)
Prepare malloc(4)

call malloc
Allocate 4 bytes

mov eax, 0x8049aac
Store pointer globally

mov 0x8049aac, eax
Load pointer

movl 0x0, (eax)
Initialize memory

lea 0x20(esp), eax
Load input

add eax, 0x5
Skip "auth "

Calculate length of input

cmp 0x1e
Check length <= 30

ja skip_auth
If too long, skip

lea 0x20(esp), eax
Load buffer

add eax, 0x5
Point to user data

mov 0x8049aac, eax
Load allocated pointer

mov edx, 0x4(esp)
Set source

mov eax, (esp)
Set destination

call strcpy
Copy input into heap (VULNERABLE)

---------------

Check "reset":

Compare input with "reset"

if equal:

mov 0x8049aac, eax
Load pointer

mov eax, (esp)
Set argument

call free
Free memory (pointer not cleared)

---------------

Check "service":

Compare input with "service"

if equal:

lea 0x20(esp), eax
Load input

add eax, 0x7
Skip "service"

mov eax, (esp)
Set argument

call strdup
Duplicate string

mov eax, 0x8049ab0
Store pointer globally

---------------

Check "login":

Compare input with "login"

if equal:

mov 0x8049aac, eax
Load auth pointer

mov 0x20(eax), eax
Read value at offset 32

test eax, eax
Check if not zero

je fail
If zero, fail

mov 0x8048833, (esp)
Prepare command

call system
Execute system command

---------------

Fail case:

Print error using fwrite

---------------

End:

restore registers
return 0

---------------

Summary of vulnerabilities:

1. malloc(4) allocates very small memory
2. strcpy copies user input without bounds check → heap overflow
3. free is called but pointer is not set to NULL → use-after-free
4. program reads from pointer + 0x20 → out-of-bounds read
5. attacker can control heap layout and memory content
6. if *(ptr + 0x20) != 0 → system() is executed

---------------