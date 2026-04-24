===========================
Assembly Program Analysis
===========================

This program takes a command-line argument, processes it, and conditionally executes a privileged operation.

----------------------------------------
1. Stack Setup
----------------------------------------
push %ebp
mov %esp, %ebp
and $0xfffffff0, %esp
sub $0x20, %esp

The function begins by saving the base pointer, aligning the stack to 16 bytes, and allocating 32 bytes for local variables.

----------------------------------------
2. Reading argv[1]
----------------------------------------
mov 0xc(%ebp), %eax   ; eax = argv
add $0x4, %eax        ; eax = argv + 4
mov (%eax), %eax      ; eax = argv[1]

The program retrieves the first user argument (argv[1]).

----------------------------------------
3. Converting Input to Integer
----------------------------------------
mov %eax, (%esp)
call atoi

The string argument is converted to an integer using atoi().
Result is stored in eax.

----------------------------------------
4. Checking Condition
----------------------------------------
cmp $0x1a7, %eax      ; 0x1a7 = 423
jne FAIL

If the input is NOT equal to 423, execution jumps to the failure block.

----------------------------------------
5. Success Path (Input == 423)
----------------------------------------

--- Duplicate String ---
movl $0x80c5348, (%esp)
call strdup
mov %eax, 0x10(%esp)

Creates a copy of a string in heap memory.

--- Initialize Variable ---
movl $0x0, 0x14(%esp)

Sets a local variable to 0.

--- Get Group ID ---
call getegid
mov %eax, 0x1c(%esp)

Stores effective group ID (gid).

--- Get User ID ---
call geteuid
mov %eax, 0x18(%esp)

Stores effective user ID (uid).

----------------------------------------
6. Set Group Privileges
----------------------------------------
mov 0x1c(%esp), %eax
mov %eax, 0x8(%esp)

mov 0x1c(%esp), %eax
mov %eax, 0x4(%esp)

mov 0x1c(%esp), %eax
mov %eax, (%esp)

call setresgid

Equivalent to:
setresgid(gid, gid, gid);

Sets real, effective, and saved group IDs.

----------------------------------------
7. Set User Privileges
----------------------------------------
mov 0x18(%esp), %eax
mov %eax, 0x8(%esp)

mov 0x18(%esp), %eax
mov %eax, 0x4(%esp)

mov 0x18(%esp), %eax
mov %eax, (%esp)

call setresuid

Equivalent to:
setresuid(uid, uid, uid);

Sets real, effective, and saved user IDs.

----------------------------------------
8. Execute New Program
----------------------------------------
lea 0x10(%esp), %eax
mov %eax, 0x4(%esp)

movl $0x80c5348, (%esp)
call execv

Equivalent to:
execv("path", argv);

This replaces the current process with a new program.
Often used to execute a shell (e.g., /bin/sh).

----------------------------------------
9. Failure Path
----------------------------------------
FAIL:

mov 0x80ee170, %eax
mov %eax, %edx

mov $0x80c5350, %eax

mov %edx, 0xc(%esp)
movl $0x5, 0x8(%esp)
movl $0x1, 0x4(%esp)
mov %eax, (%esp)

call fwrite

Equivalent to:
fwrite("No !", 1, 5, stream);
    print error message;

Prints an error message when input is incorrect.

----------------------------------------
10. Program Exit
----------------------------------------
mov $0x0, %eax
leave
ret

Returns 0 and exits normally.

----------------------------------------
FINAL BEHAVIOR
----------------------------------------

if (atoi(argv[1]) == 423)
{
    duplicate string;
    get gid and uid;
    set process privileges;
    execute another program (likely a shell);
}
else
{
    print error message;
}
