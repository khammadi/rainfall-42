===========================
Assembly Program Analysis
===========================

This program contains two functions:
- main() → vulnerable input handler
- run()  → prints a message and executes a command

----------------------------------------
1. FUNCTION: main
----------------------------------------

push %ebp
mov %esp,%ebp
and $0xfffffff0,%esp
sub $0x50,%esp

// Setup stack frame
// Align stack (16 bytes)
// Allocate 80 bytes buffer

----------------------------------------
BUFFER PREPARATION
----------------------------------------

lea 0x10(%esp), %eax
mov %eax,(%esp)

Equivalent:
buffer = esp + 16;

----------------------------------------
USER INPUT
----------------------------------------

call gets

Equivalent:
gets(buffer);

 gets() reads user input WITHOUT size checking

----------------------------------------
FUNCTION END
----------------------------------------

leave
ret

Equivalent:
return;

----------------------------------------
STACK LAYOUT (main)
----------------------------------------

HIGH ADDRESS
-------------------------
saved EBP
return address   ← target 
-------------------------
buffer (80 bytes)
-------------------------
LOW ADDRESS

----------------------------------------
VULNERABILITY
----------------------------------------

gets() allows unlimited input.

If input > 80 bytes:
- overwrite saved EBP
- overwrite return address

→ control program execution

----------------------------------------
2. FUNCTION: run
----------------------------------------

push %ebp
mov %esp,%ebp
sub $0x18,%esp

// allocate 24 bytes

----------------------------------------
PREPARE fwrite
----------------------------------------

mov 0x80497c0,%eax
mov %eax,%edx

mov $0x8048570,%eax

mov %edx,0xc(%esp)   ; stream
movl $0x13,0x8(%esp) ; size = 19
movl $0x1,0x4(%esp)  ; count = 1
mov %eax,(%esp)      ; string

call fwrite

Equivalent:
fwrite("message", 1, 19, stream);

→ prints a message

----------------------------------------
CALL system
----------------------------------------

movl $0x8048584,(%esp)
call system

Equivalent:
system("command");

→ executes a shell command

----------------------------------------
FUNCTION END
----------------------------------------

leave
ret

----------------------------------------
HIGH-LEVEL CODE
----------------------------------------

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

----------------------------------------
EXPLOITATION IDEA
----------------------------------------

The program never calls run() directly.

BUT because main() is vulnerable:

payload =
[ 80 bytes buffer ]
[ 4 bytes saved EBP ]
[ address of run() ] 
When main returns:
→ execution jumps to run()

----------------------------------------
WHAT HAPPENS AFTER EXPLOIT
----------------------------------------

run() will:
1. print a message
2. execute system()

→ possible shell access

----------------------------------------
SECURITY ISSUE
----------------------------------------

- gets() → buffer overflow
- system() → command execution
- combination = dangerous

----------------------------------------
SUMMARY
----------------------------------------

main():
- reads unsafe input
- vulnerable to overflow

run():
- prints message
- executes system()