# GDB Analysis – bonus3 (Out-of-Bounds Read + Arbitrary Comparison)

This program reads data from a file, uses an out-of-bounds index to truncate a buffer, and performs string comparison to determine execution flow.

---

## Program Source Code

```c
#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <unistd.h>

int main(int ac, char **av)
{
    char buf1[66];
    char buf2[65];
    FILE *stream;

    stream = fopen("/home/user/end/.pass", "r");
    bzero(buf1, 33);
    if (!stream || ac != 2)
        return (-1);
    fread(buf1, 1, 66, stream);
    buf1[atoi(av[1])] = '\0';      // ⚠️ OUT-OF-BOUNDS WRITE!
    fread(buf2, 1, 65, stream);
    fclose(stream);
    if (strcmp(av[1], buf1) == 0)
        execl("/bin/sh", "sh", 0);
    else
        puts(buf1[66]);             // ⚠️ OUT-OF-BOUNDS READ!
    return (0);
}
```

---

## 1. Function Overview

### File Opening

```c
stream = fopen("/home/user/end/.pass", "r");
```

Opens the file `/home/user/end/.pass` for reading. This file contains sensitive data (the final password).

### Buffer Initialization

```c
bzero(buf1, 33);              // Zero out first 33 bytes of buf1
char buf1[66];                // Total size: 66 bytes
```

**Buffer 1 (buf1):** 66 bytes, partially zeroed (first 33 bytes)
**Buffer 2 (buf2):** 65 bytes

### Argument Check

```c
if (!stream || ac != 2)
    return (-1);              // Exit if file can't open or not exactly 2 arguments
```

Requires exactly **1 argument** (argc == 2: program + 1 argument)

---

## 2. File Reading

### First fread

```c
fread(buf1, 1, 66, stream);   // Read 66 bytes into buf1
```

Reads **66 bytes** from the file into `buf1`.

### Second fread

```c
fread(buf2, 1, 65, stream);   // Read 65 bytes into buf2
```

Reads **65 bytes** from the file into `buf2`.

**Total read:** 131 bytes from file

---

## 3. Critical Vulnerability: Out-of-Bounds Index

```c
buf1[atoi(av[1])] = '\0';     // ⚠️ DANGEROUS!
```

### How It Works

1. **Convert argument to integer:** `atoi(av[1])`
2. **Use as index into buf1:** `buf1[index]`
3. **Write null terminator:** Set byte to `'\0'`

### Problem: No Bounds Checking

```
buf1 is 66 bytes: indices 0-65 are valid
If atoi(av[1]) > 65:
  ✗ Writes outside buffer boundary
  ✗ Corrupts adjacent memory
  ✗ Can corrupt buf2 or stack data
```

> ⚠️ **Out-of-Bounds Write Vulnerability**
>
> - Array size: 66 bytes (indices 0-65)
> - No validation of index
> - Can write to any memory location
> - Corrupts adjacent buffers or stack

### Example Exploitation

```bash
./bonus3 100          # Write null at buf1[100] - FAR OUT OF BOUNDS
./bonus3 65           # Write null at last valid byte
./bonus3 66           # Write null to buf1[66] - FIRST OUT-OF-BOUNDS
./bonus3 67           # Write null to buf1[67]
```

---

## 4. String Comparison

```c
if (strcmp(av[1], buf1) == 0)
    execl("/bin/sh", "sh", 0);    // Execute shell if match
else
    puts(buf1[66]);                // ⚠️ ANOTHER OOB READ!
```

### Comparison Logic

- **Input:** `av[1]` (user-provided argument)
- **Target:** `buf1` (data read from file)
- **Condition:** If they match exactly, spawn shell

### Shell Execution

If the comparison succeeds, `execl()` spawns an interactive shell with full access.

---

## 5. Critical Vulnerability: Out-of-Bounds Read

```c
puts(buf1[66]);       // ⚠️ READING OUTSIDE BUFFER!
```

### The Problem

```
buf1 is 66 bytes: valid indices are 0-65
buf1[66] accesses memory BEYOND the buffer boundary
This reads whatever is adjacent in memory:
  - buf2 data
  - Stack variables
  - Uninitialized memory
```

> ⚠️ **Out-of-Bounds Read Vulnerability**
>
> - Accesses invalid memory location
> - Reads uninitialized or adjacent data
> - Information leak vulnerability
> - Can crash program with invalid memory access

### What gets read?

```
Stack layout:
+---+---+---+---+---+
| buf1 (66 bytes)   |
+---+---+---+---+---+
| buf2 (65 bytes)   |  ← buf1[66] reads start of buf2!
+---+---+---+---+---+
```

---

## 6. Exploitation Strategy

### Attack Vector 1: Null Terminator Injection

```bash
# Write null terminator to a controlled location
./bonus3 0            # buf1[0] = '\0'
# Now buf1 becomes empty string
# strcmp(av[1], "") will match if av[1] is also empty
./bonus3 ""           # Won't work - needs to match file content
```

### Attack Vector 2: Out-of-Bounds Write to Match

```bash
# The file contains: [PASSWORD][more_data]
# Read first 66 bytes into buf1
# We can truncate buf1 at different positions by choosing index

# If we set buf1[i] = '\0' at position i:
# buf1 becomes truncated to i characters
# Then strcmp(av[1], buf1) will match if av[1] is those i characters
```

### Exploitation Flow

```
File contains: "FLAG_CONTENT_HERE_and_more_stuff"
                01234567890123456789...

Read into buf1 (66 bytes)

./bonus3 10           
  ↓
buf1[10] = '\0'
  ↓
buf1 = "FLAG_CONTE\0..."  (truncated at position 10)
  ↓
strcmp("10", "FLAG_CONTE") = fails

./bonus3 "FLAG_CONTE"
  ↓
buf1[atoi("FLAG_CONTE")] = ERROR (non-numeric string)
  ↓
But if we can match the truncated content...
```

### Key Insight

1. **Read file data** into buf1
2. **Use index** to truncate buf1 at specific position
3. **Compare argument** with truncated buf1
4. **If match:** Shell access granted!

---

## 7. Practical Exploitation

### Step 1: Determine File Content

The file `/home/user/end/.pass` contains the password. We need to:
1. Make `strcmp(av[1], buf1) == 0` true
2. This means `av[1]` must exactly match the file content (or truncated version)

### Step 2: Use Index to Truncate

If we don't know the exact file content, we can:
- Use `./bonus3 0` to truncate at position 0 (empty string)
- Then try `./bonus3 ""` to match empty string
- Or use other indices strategically

### Step 3: Trigger Shell

```bash
./bonus3 [MATCHING_STRING]
# If successful, execl spawns shell
# Shell prompt appears
# You now have access
```

---

## 8. Vulnerability Summary

### Vulnerability 1: Out-of-Bounds Write

```c
buf1[atoi(av[1])] = '\0';
```

- **Problem:** No index validation
- **Impact:** Can truncate buf1 at any position
- **Effect:** Corrupts stack, adjacent buffers, or file data

### Vulnerability 2: Out-of-Bounds Read

```c
puts(buf1[66]);
```

- **Problem:** Accesses memory beyond buffer boundary
- **Impact:** Information leak (reads buf2 or stack data)
- **Effect:** Can reveal sensitive data

### Vulnerability 3: Dangerous strcmp Usage

```c
if (strcmp(av[1], buf1) == 0)
    execl("/bin/sh", "sh", 0);
```

- **Problem:** Attacker can influence both strings
- **Impact:** Can control string comparison result
- **Effect:** Bypass authentication check

---

## 9. Attack Requirements

To successfully exploit:

1. **Understand file content structure**
   - File contains predictable or discoverable data
   - Can be revealed through out-of-bounds read

2. **Find matching string**
   - Use index to truncate buf1 appropriately
   - Provide matching argument

3. **Trigger shell spawn**
   - strcmp succeeds
   - execl executes `/bin/sh`
   - Interactive shell access

---

## Summary

**Critical vulnerabilities:**

1. **Out-of-Bounds Write via atoi Index**
   - No validation of `atoi(av[1])` result
   - Can write null terminator anywhere
   - Truncates buffer at arbitrary position

2. **Out-of-Bounds Read**
   - `buf1[66]` reads beyond 66-byte buffer
   - Leaks adjacent memory contents
   - Information disclosure vulnerability

3. **Weak Authentication Logic**
   - `strcmp()` comparison can be manipulated
   - Attacker controls both strings being compared
   - Enables authentication bypass

4. **Arbitrary Shell Execution**
   - If `strcmp` succeeds, `execl()` spawns shell
   - No privilege escalation checks
   - Direct access to system shell

**Exploitation requirements:**
- Understanding file content layout
- Using out-of-bounds index to truncate appropriately
- Providing matching argument string
- Triggering successful comparison
- Gaining shell access via execl()