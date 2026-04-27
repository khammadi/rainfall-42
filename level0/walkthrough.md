# Level 0 — Walkthrough

## Summary

This document explains how to analyze `level0` (a small C binary) to find the correct input and obtain the password for the next level.

## Objective

Find the numeric input the program expects, run the binary to reach `level1`, and read the `.pass` file.

## Key observations (from GDB)

Disassembling `main` shows the program calls `atoi` on `argv[1]` and compares the result to `0x1a7` (decimal 423):

```asm
   call   atoi
   cmp    $0x1a7, %eax   # compare atoi(argv[1]) with 423
```

Conclusion: the program expects `423` as the correct argument.

## Steps performed

1. Inspect the binary with GDB:

```bash
gdb ./level0
# (in gdb) disas main
```

2. Run the program with the discovered input:

```bash
./level0 423
```

3. Change into `level1` and list files to find the `.pass` file, then print it:

```bash
cd /home/user/level1
ls -la
cat .pass
```

## Commands and observed outputs (representative)

```bash
$ cd /home/user/level1
$ ls -la
total 17
dr-xr-x---+ 1 level1 level1   80 Mar  6  2016 .
dr-x--x--x  1 root   root    340 Sep 23  2015 ..
-rw-r--r--  1 level1 level1  220 Apr  3  2012 .bash_logout
-rw-r--r--  1 level1 level1 3530 Sep 23  2015 .bashrc
-rwsr-s---+ 1 level2 users  5138 Mar  6  2016 level1
-rw-r--r--+ 1 level1 level1   65 Sep 23  2015 .pass
-rw-r--r--  1 level1 level1  675 Apr  3  2012 .profile
$ cat .pass
1fe8a524fa4bec01ca4ea2a869af2a02260d4a7d5fe7e7c24d8617e6dca12d3a
```

## Flag

Contents of `level1/.pass` (next-level password):

```
1fe8a524fa4bec01ca4ea2a869af2a02260d4a7d5fe7e7c24d8617e6dca12d3a
```

## Notes / Tips

- The binary does a simple numeric check (`atoi(argv[1]) == 423`). No exploitation is required for this level.
- Tools: `gdb`, `objdump`, and `strings` are useful to locate magic constants in small CTF binaries.

## Next steps

- Use the retrieved password to proceed to `level1`.
