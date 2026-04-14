GDB Analysis of gdb_analysis.asm

MAIN FUNCTION

Address 0x0804851a
Instruction push %ebp
Explanation
Save the previous base pointer on the stack to create a new stack frame

Address 0x0804851b
Instruction mov %esp, %ebp
Explanation
Set the current stack pointer as the new base pointer for this function

Address 0x0804851d
Instruction and $0xfffffff0, %esp
Explanation
Align the stack to 16 bytes for performance and calling conventions

Address 0x08048520
Instruction call 0x80484a4 <v>
Explanation
Call the function v where the main logic of the program is located

Address 0x08048525
Instruction leave
Explanation
Restore the previous stack frame by moving ebp back to esp and popping old ebp

Address 0x08048526
Instruction ret
Explanation
Return execution to the caller and end the program

FUNCTION V

Address 0x080484a4
Instruction push %ebp
Explanation
Save the previous base pointer

Address 0x080484a5
Instruction mov %esp, %ebp
Explanation
Create a new stack frame for function v

Address 0x080484a7
Instruction sub $0x218, %esp
Explanation
Allocate 536 bytes on the stack for local variables including a buffer

INPUT HANDLING

Address 0x080484ad
Instruction mov 0x8049860, %eax
Explanation
Load a pointer from global memory this is likely stdin

Address 0x080484b2
Instruction mov %eax, 0x8(%esp)
Explanation
Prepare the third argument for fgets which is the input stream

Address 0x080484b6
Instruction movl $0x200, 0x4(%esp)
Explanation
Prepare the second argument for fgets which is the maximum size 512 bytes

Address 0x080484be
Instruction lea -0x208(%ebp), %eax
Explanation
Load the address of the buffer located at ebp minus 0x208

Address 0x080484c4
Instruction mov %eax, (%esp)
Explanation
Prepare the first argument for fgets which is the buffer

Address 0x080484c7
Instruction call fgets
Explanation
Read up to 512 bytes from input into the buffer

PRINTING USER INPUT

Address 0x080484cc
Instruction lea -0x208(%ebp), %eax
Explanation
Load the address of the buffer again

Address 0x080484d2
Instruction mov %eax, (%esp)
Explanation
Pass the buffer as argument to printf

Address 0x080484d5
Instruction call printf
Explanation
Print the buffer content directly

Important note
This is a vulnerability because printf is used without a format string
User input is treated as a format string which allows memory reading and writing

CONDITIONAL CHECK

Address 0x080484da
Instruction mov 0x804988c, %eax
Explanation
Load a value from a global variable at address 0x804988c

Address 0x080484df
Instruction cmp $0x40, %eax
Explanation
Compare the value with 64

Address 0x080484e2
Instruction jne 0x8048518
Explanation
If the value is not equal to 64 jump to the end of the function

IF CONDITION IS TRUE

Address 0x080484e4
Instruction mov 0x8049880, %eax
Explanation
Load another value from memory possibly a file pointer or data

Address 0x080484e9
Instruction mov %eax, %edx
Explanation
Copy the value into edx

Address 0x080484eb
Instruction mov $0x8048600, %eax
Explanation
Load the address of some data likely a string

Address 0x080484f0
Instruction mov %edx, 0xc(%esp)
Explanation
Prepare argument for fwrite

Address 0x080484f4
Instruction movl $0xc, 0x8(%esp)
Explanation
Set size argument to 12 bytes

Address 0x080484fc
Instruction movl $0x1, 0x4(%esp)
Explanation
Set count argument to 1

Address 0x08048504
Instruction mov %eax, (%esp)
Explanation
Pass pointer to data for fwrite

Address 0x08048507
Instruction call fwrite
Explanation
Write data to output

SYSTEM CALL

Address 0x0804850c
Instruction movl $0x804860d, (%esp)
Explanation
Prepare argument for system call likely a command string

Address 0x08048513
Instruction call system
Explanation
Execute a system command usually this is /bin/sh

FUNCTION END

Address 0x08048518
Instruction leave
Explanation
Restore previous stack frame

Address 0x08048519
Instruction ret
Explanation
Return from function

FINAL SUMMARY

The program reads user input into a buffer
It prints the input using printf without a format string
This creates a format string vulnerability
A global variable at address 0x804988c is checked against value 64
If the value equals 64 the program executes a system command
An attacker can use the vulnerability to modify this value and gain code execution