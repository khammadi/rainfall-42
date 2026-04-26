# Rainfall (42) - Binary Exploitation

A comprehensive collection of binary exploitation challenges demonstrating real-world vulnerability exploitation techniques.

## Quick Start

| Level | Analysis | Source |
|-------|----------|--------|
| **level0** | [gdb_analysis.md](level0/Ressources/gdb_analysis.md) | [source.c](level0/source/source.c) |
| **level1** | [gdb_analysis.md](level1/Ressources/gdb_analysis.md) | [source.c](level1/source/source.c) |
| **level2** | [gdb_analysis.md](level2/Ressources/gdb_analysis.md) | [source.c](level2/source/source.c) |
| **level3** | [gdb_analysis.md](level3/Ressources/gdb_analysis.md) | [source.c](level3/source/source.c) |
| **level4** | [gdb_analysis.md](level4/Ressources/gdb_analysis.md) | [source.c](level4/source/source.c) |
| **level5** | [gdb_analysis.md](level5/Ressources/gdb_analysis.md) | [source.c](level5/source/source.c) |
| **level6** | [gdb_analysis.md](level6/Ressources/gdb_analysis.md) | [source.c](level6/source/source.c) |
| **level7** | [gdb_analysis.md](level7/Ressources/gdb_analysis.md) | [source.c](level7/source/source.c) |
| **level8** | [gdb_analysis.md](level8/Ressources/gdb_analysis.md) | [source.c](level8/source/source.c) |
| **level9** | [gdb_analysis.md](level9/Ressources/gdb_analysis.md) | [source.cpp](level9/source/source.cpp) |
| **bonus0** | [gdb_analysis.md](bonu0/Ressources/gdb_analysis.md) | [source.c](bonu0/source/source.c) |
| **bonus1** | [gdb_analysis.md](bonus1/Ressources/gdb_analysis.md) | [source.c](bonus1/source/source.c) |
| **bonus2** | [gdb_analysis.md](bonus2/Ressources/gdb_analysis.md) | [source.c](bonus2/source/source.c) |
| **bonus3** | [gdb_analysis.md](bonus3/Ressources/gdb_analysis.md) | [source.c](bonus3/source/source.c) |

## Overview

This project contains 14 levels that progressively introduce different exploitation techniques. Each level focuses on a specific vulnerability class.

### Vulnerability Types

- **level0**: Input validation
- **level1**: Stack buffer overflow (gets)
- **level2**: Stack canary bypass
- **level3**: Format string reading
- **level4**: Format string memory write
- **level5**: GOT table hijacking
- **level6**: Heap function pointer overflow
- **level7**: Heap buffer overflow
- **level8**: Use-after-free
- **level9**: C++ virtual function hijacking
- **bonus0**: Stack overflow pattern finding
- **bonus1**: Integer overflow
- **bonus2**: Environment variable shellcode injection
- **bonus3**: Out-of-bounds read/write

## Getting Started

### Prerequisites

```bash
# Required tools
- GDB (debugger)
- GCC or Clang (compiler)
- Python 3
- Basic understanding of assembly language
```

### Setup

```bash
# Connect to the target VM
ssh level0@<VM_IP> -p 4242
# Password: level0

# Navigate to project directory
cd /home/level0
```

## Repository Structure

Each level follows this structure:

```
levelX/
├── flag                          # Password for next level
├── walkthrough                   # Step-by-step exploitation guide
├── source/
│   └── source.c (or .cpp)        # Vulnerable source code
└── Ressources/
    ├── gdb_analysis.md           # Detailed GDB analysis
    └── [other resources]
```

## Exploitation Workflow

For each level:

1. **Read the source code** - Understand the vulnerability
2. **Study the GDB analysis** - Learn assembly and exploitation details
3. **Review the walkthrough** - Get step-by-step instructions
4. **Develop the exploit** - Create your payload
5. **Test and execute** - Get the next level's password

## Key Concepts

### Vulnerability Classes

**Buffer Overflows**
- Stack-based: Overwrite return address
- Heap-based: Corrupt adjacent data structures
- Protected: Bypass security mechanisms

**Format String Attacks**
- Read memory using format specifiers (%x, %s)
- Write to memory using %n specifier
- Redirect function execution via GOT

**Heap Exploitation**
- Exploit allocator behavior
- Corrupt function pointers
- Trigger use-after-free conditions

**C++ Exploitation**
- Corrupt virtual function tables
- Hijack object methods
- Exploit object layout

### Protection Mechanisms

- Stack canaries (detect stack overflow)
- ASLR (Address Space Layout Randomization)
- NX bit (Non-executable memory)
- DEP (Data Execution Prevention)
- PIE (Position Independent Executable)

## Tools

### Debugging
- **GDB**: GNU Debugger
- **objdump**: Disassembler
- **gdb-peda**: GDB extension for exploitation

### Exploitation
- **Python**: Script automation
- **pwntools**: Exploitation library
- **bash**: Shell scripting

### Analysis
- **strace**: System call tracing
- **ltrace**: Library call tracing
- **checksec**: Binary protection analysis

## Learning Path

### Beginner
1. level0 - Input validation basics
2. level1 - Simple buffer overflow
3. level2 - Protected overflow

### Intermediate
4. level3-4 - Format string fundamentals
5. level5 - Function redirection
6. level6-7 - Heap exploitation basics

### Advanced
7. level8 - Complex heap exploitation
8. level9 - C++ exploitation
9. bonus levels - Advanced techniques

## Rules

- Be prepared to explain your solution
- No automation tools allowed
- Include reversing work (source code)
- Document walkthrough steps
- No binaries in repository

## References

### Books
- "The Shellcoder's Handbook"
- "Hacking: The Art of Exploitation"
- "The IDA Pro Book"

### Online Resources
- [pwn.college](https://pwn.college)
- [OverTheWire](https://overthewire.org)
- [GDB Manual](https://sourceware.org/gdb/)

## Status

All 14 levels completed with detailed analysis and documentation.

---

**Project:** 42 School - Rainfall Challenge  
**Last Updated:** April 2026




