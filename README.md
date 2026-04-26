# Rainfall (42) - Binary Exploitation Challenge

[![GitHub Repository](https://img.shields.io/badge/GitHub-rainfall--42-blue?style=flat-square&logo=github)](https://github.com/khammadi/rainfall-42)

This repository contains comprehensive solutions and analysis for the **Rainfall** project: an introduction to exploiting ELF-like binaries on **i386** architecture.

## Quick Navigation

### Main Levels
- [level0](level0/Ressources/gdb_analysis.md) | [Source](level0/source/source.c)
- [level1](level1/Ressources/gdb_analysis.md) | [Source](level1/source/source.c)
- [level2](level2/Ressources/gdb_analysis.md) | [Source](level2/source/source.c)
- [level3](level3/Ressources/gdb_analysis.md) | [Source](level3/source/source.c)
- [level4](level4/Ressources/gdb_analysis.md) | [Source](level4/source/source.c)
- [level5](level5/Ressources/gdb_analysis.md) | [Source](level5/source/source.c)
- [level6](level6/Ressources/gdb_analysis.md) | [Source](level6/source/source.c)
- [level7](level7/Ressources/gdb_analysis.md) | [Source](level7/source/source.c)
- [level8](level8/Ressources/gdb_analysis.md) | [Source](level8/source/source.c)
- [level9](level9/Ressources/gdb_analysis.md) | [Source](level9/source/source.cpp)

### Bonus Levels
- [bonus0](bonu0/Ressources/gdb_analysis.md) | [Source](bonu0/source/source.c)
- [bonus1](bonus1/Ressources/gdb_analysis.md) | [Source](bonus1/source/source.c)
- [bonus2](bonus2/Ressources/gdb_analysis.md) | [Source](bonus2/source/source.c)
- [bonus3](bonus3/Ressources/gdb_analysis.md) | [Source](bonus3/source/source.c)

---

## Project Overview

### Goal

Starting from the `level0` account on the provided VM, exploit vulnerabilities in successive binaries to read the next user's password file:

- Target: `/home/levelX/.pass` (for the next level user)
- Progress: `level0` → `level1` → ... → `level9` (+ bonus challenges)
- Objective: Understand real exploitation techniques through practical experience

### Vulnerability Coverage

This project demonstrates **10 major vulnerability classes**:

| Level | Vulnerability | Technique |
|-------|---------------|-----------|
| **Level 0** | Input validation | Command-line argument checking |
| **Level 1** | Stack buffer overflow | `gets()` function exploitation |
| **Level 2** | Protected overflow | Stack canary bypass |
| **Level 3** | Format string | Memory reading via `%x`, `%s` |
| **Level 4** | Format string write | Memory modification via `%n` |
| **Level 5** | GOT overwrite | Function pointer redirection |
| **Level 6** | Heap overflow | Function pointer on heap |
| **Level 7** | Heap corruption | Adjacent buffer overflow |
| **Level 8** | Use-after-free | Freed memory exploitation |
| **Level 9** | C++ VTable hijack | Virtual function corruption |

---

## Environment & Setup

### Prerequisites

- **VM:** 64-bit Linux (provided ISO or compatible)
- **Architecture:** i386 (32-bit binaries)
- **Tools:** GDB, gcc/clang, Python, bash

### Getting Started

#### 1. SSH to VM
```bash
ssh level0@<VM_IP> -p 4242
# Password: level0
```

#### 2. Discover VM IP (if needed)
```bash
ifconfig
# or
ip addr show
```

#### 3. Navigate to Project
```bash
cd /path/to/rainfall-42
```

#### 4. Review Level Structure
```bash
ls -la level0/
# Output:
# flag
# walkthrough
# Ressources/
# source/
```

---

## Repository Structure

### Mandatory Levels (10 required)

```
level0/
level1/
...
level9/
```

### Bonus Levels (4 optional, assessed after mandatory completion)

```
bonu0/      # Stack overflow pattern analysis
bonus1/     # Integer overflow + stack overflow
bonus2/     # Environment variable shellcode injection
bonus3/     # Out-of-bounds read/write vulnerabilities
```

### Per-Level Structure

Each level follows this standardized format:

```text
levelX/
├── flag                          # Password for next level (keep confidential)
├── source/
│   └── source.c (or .cpp)        # Vulnerable source code (reverse-engineered)
├── walkthrough                   # Step-by-step exploitation guide
└── Ressources/
    ├── gdb_analysis.md           # Detailed GDB debugging analysis
    ├── resources.txt             # Additional reference materials
    └── [optional files]          # Exploits, notes, scripts
```

### File Descriptions

| File | Purpose | Content |
|------|---------|---------|
| `flag` | Solution credential | Password/token for next level |
| `source/source.c` | Code reference | Reverse-engineered vulnerable source |
| `walkthrough` | Reproduction guide | Commands and reasoning to exploit |
| `Ressources/gdb_analysis.md` | Technical analysis | Assembly breakdown, exploitation flow |

---

## Detailed Level Guides

### Level 0: Input Validation Challenge
- **Vulnerability:** Insufficient argument validation
- **File:** `level0/source/source.c`
- **Analysis:** `level0/Ressources/gdb_analysis.md`
- **Skills:** Command-line argument parsing, privilege checks

### Level 1: Stack Buffer Overflow (gets)
- **Vulnerability:** `gets()` function reads unbounded input
- **Technique:** Overwrite return address with function pointer
- **Key:** `level1/source/source.c`
- **Analysis:** `level1/Ressources/gdb_analysis.md`

### Level 2: Stack Canary Bypass
- **Vulnerability:** Buffer overflow with stack canary protection
- **Technique:** Redirect to heap/libc (non-stack) function
- **Protection:** `-fstack-protector`
- **Analysis:** `level2/Ressources/gdb_analysis.md`

### Level 3: Format String (Reading)
- **Vulnerability:** `printf()` without format string validation
- **Technique:** Use `%x`, `%s` specifiers to read memory
- **Concept:** Format string exploitation fundamentals
- **Analysis:** `level3/Ressources/gdb_analysis.md`

### Level 4: Format String (Memory Write)
- **Vulnerability:** Format string with controllable input
- **Technique:** Use `%n` to write to memory
- **Target:** Global variable modification
- **Analysis:** `level4/Ressources/gdb_analysis.md`

### Level 5: GOT Table Hijacking
- **Vulnerability:** Format string combined with writable GOT
- **Technique:** Overwrite `exit()` GOT entry
- **Concept:** Global Offset Table manipulation
- **Analysis:** `level5/Ressources/gdb_analysis.md`

### Level 6: Heap Function Pointer Overflow
- **Vulnerability:** `strcpy()` overflow on heap buffer
- **Technique:** Corrupt adjacent function pointer
- **Concept:** Heap layout exploitation
- **Analysis:** `level6/Ressources/gdb_analysis.md`

### Level 7: Heap-Based Overflow
- **Vulnerability:** Multiple `strcpy()` on adjacent heap allocations
- **Technique:** Sequential buffer overflow chain
- **Concept:** Multi-stage heap corruption
- **Analysis:** `level7/Ressources/gdb_analysis.md`

### Level 8: Heap Overflow + Use-After-Free
- **Vulnerability:** Tiny allocation overflow + use-after-free
- **Technique:** Exploit freed memory through dangling pointer
- **Concept:** Advanced heap exploitation
- **Analysis:** `level8/Ressources/gdb_analysis.md`

### Level 9: C++ Virtual Function Hijacking
- **Vulnerability:** Heap overflow corrupts C++ object VTable
- **Technique:** Overwrite virtual function pointer
- **Concept:** C++ object layout and vtable manipulation
- **Analysis:** `level9/Ressources/gdb_analysis.md`

---

## Bonus Challenges

### Bonus 0: Stack Overflow Pattern Finding
- **Difficulty:** Medium
- **Technique:** Cyclic pattern to find exact offset
- **Tool:** GDB for crash pattern analysis
- **File:** `bonu0/Ressources/gdb_analysis.md`

### Bonus 1: Integer Overflow + Stack Overflow
- **Difficulty:** Hard
- **Concept:** Negative number bypass → size calculation
- **Technique:** `memcpy(buf, src, value * 4)` with negative input
- **File:** `bonus1/Ressources/gdb_analysis.md`

### Bonus 2: Environment Shellcode Injection
- **Difficulty:** Hard
- **Technique:** Shellcode in environment variables
- **Concept:** `strncpy()` buffer + environment exploitation
- **File:** `bonus2/Ressources/gdb_analysis.md`

### Bonus 3: Out-of-Bounds Access
- **Difficulty:** Medium
- **Concept:** Unvalidated buffer indexing
- **Technique:** OOB read/write for authentication bypass
- **File:** `bonus3/Ressources/gdb_analysis.md`

---

## Usage & Workflow

### For Each Level

#### 1. Read Source Code
```bash
cat levelX/source/source.c
# Understand the vulnerability
```

#### 2. Review Walkthrough
```bash
cat levelX/walkthrough
# Follow step-by-step instructions
```

#### 3. Study GDB Analysis
```bash
cat levelX/Ressources/gdb_analysis.md
# Deep dive into assembly and exploitation
```

#### 4. Develop Exploit
```bash
# Create custom script in Ressources/
python3 exploit.py
# or bash script
./exploit.sh
```

#### 5. Test Locally (if applicable)
```bash
gcc -o test levelX/source/source.c
./test "payload"
```

#### 6. SSH and Execute
```bash
ssh levelX@<VM_IP> -p 4242
levelX~$ ./levelX "payload"
levelX~$ cat /home/levelX+1/.pass > /tmp/flag
```

---

## Key Tools & Resources

### Debugging
- **GDB** - GNU Debugger with TUI mode
- **gdb-peda** - Python Exploitation Development Assistance
- **radare2** - Reverse engineering framework

### Exploitation Development
- **pwntools** - Python exploitation library
- **Python** - Script automation and payload generation
- **objdump** - Disassembler for binary analysis

### Analysis
- **strace** - System call tracing
- **ltrace** - Library call tracing
- **checksec** - Binary protection analysis

---

## Core Concepts Learned

### 1. Memory Layout
- Stack (LIFO, local variables, return addresses)
- Heap (dynamic allocation, fragmentation)
- Data segment (global variables)
- Code segment (instructions)

### 2. Exploitation Techniques
- **Buffer Overflow:** Write beyond boundary
- **Format Strings:** Misuse of printf-family functions
- **Heap Exploitation:** Control adjacent allocations
- **Function Pointer Hijacking:** Redirect execution
- **Return-Oriented Programming (ROP):** Chain gadgets

### 3. Protection Mechanisms
- **Stack Canary:** Detect stack overflow
- **ASLR:** Address Space Layout Randomization
- **NX Bit:** Non-executable memory
- **PIE:** Position Independent Executable
- **DEP:** Data Execution Prevention

### 4. Reverse Engineering
- **Disassembly:** Reading assembly language
- **GDB:** Setting breakpoints and inspecting state
- **Register analysis:** Understanding CPU state
- **Memory inspection:** Reading stack/heap contents

---

## Project Constraints & Rules

### From Assignment (Strictly Enforced)

✅ **Must Do:**
- Be ready to **explain and prove** your results during evaluation
- Document your solution clearly
- Include source code (reverse-engineered or provided)
- Provide reproducible walkthrough steps

❌ **Must NOT Do:**
- Use **automation tools** (automation = cheating)
- Brute-force SSH "flags"
- Commit **binaries** to repository
- Include VM files in repository (fetch during evaluation)

### Repository Standards

✓ All files must be clearly explainable  
✓ Walkthrough must be reproducible  
✓ Ressources/ scripts documented  
✓ Minimal dependencies, external tools documented  

---

## Learning Objectives

By completing this project, you will understand:

1. **Binary Exploitation Fundamentals**
   - How memory corruption leads to code execution
   - Common vulnerability patterns in C/C++

2. **Reverse Engineering Skills**
   - Reading and understanding assembly language
   - Using debuggers effectively
   - Analyzing binary behavior

3. **Exploitation Development**
   - Crafting payloads programmatically
   - Bypassing security protections
   - Chaining multiple vulnerabilities

4. **System Security**
   - Why memory safety matters
   - Real-world exploitation techniques
   - Defense mechanisms and their limitations

5. **Debugging Techniques**
   - GDB advanced usage
   - Memory inspection and analysis
   - Breakpoints and conditional debugging

---

## Completion Status

| Level | Status | Vulnerability | GDB Analysis |
|-------|--------|-----------------|--------------|
| **level0** | ✅ Complete | Input validation | ✅ Available |
| **level1** | ✅ Complete | Stack overflow | ✅ Available |
| **level2** | ✅ Complete | Protected overflow | ✅ Available |
| **level3** | ✅ Complete | Format string (read) | ✅ Available |
| **level4** | ✅ Complete | Format string (write) | ✅ Available |
| **level5** | ✅ Complete | GOT hijacking | ✅ Available |
| **level6** | ✅ Complete | Heap overflow | ✅ Available |
| **level7** | ✅ Complete | Heap corruption | ✅ Available |
| **level8** | ✅ Complete | Use-after-free | ✅ Available |
| **level9** | ✅ Complete | C++ VTable | ✅ Available |
| **bonus0** | ✅ Complete | Pattern finding | ✅ Available |
| **bonus1** | ✅ Complete | Integer overflow | ✅ Available |
| **bonus2** | ✅ Complete | Env shellcode | ✅ Available |
| **bonus3** | ✅ Complete | OOB access | ✅ Available |

**Overall:** 14/14 Levels Complete ✅

---

## Contributing & Feedback

Have improvements, corrections, or additional analysis?

- Create a detailed writeup
- Update gdb_analysis.md with new insights
- Share alternative exploitation techniques
- Document edge cases and gotchas

---

## License

Educational purposes only. Use responsibly and legally only for:
- Learning and skill development
- Authorized security testing
- 42 School curriculum completion

---

## Additional References

### Recommended Reading
- "The Shellcoder's Handbook" - Anderson, Erickson, Prozinski, Singh
- "Hacking: The Art of Exploitation" - Jon Erickson
- "The IDA Pro Book" - Chris Eagle
- Intel x86 Assembly documentation

### Online Resources
- [pwn.college](https://pwn.college) - Exploit development fundamentals
- [OverTheWire](https://overthewire.org) - Wargames and challenges
- [Exploit-DB](https://www.exploit-db.com) - Real vulnerability research
- [GDB Manual](https://sourceware.org/gdb/current/onlinedocs/gdb/) - Official GDB documentation

---

## Author

**Repository Owner:** khammadi  
**Project:** 42 School - Rainfall Challenge  
**Last Updated:** April 26, 2026  

---




