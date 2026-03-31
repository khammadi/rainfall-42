# Rainfall (42)

This repository contains my work for the **Rainfall** project: an introduction to exploiting ELF-like binaries on **i386**.

## Goal

Starting from the `level0` account on the provided VM, each level requires finding a way to read the next user’s password file:

- Target file: `/home/user/levelX/.pass` (for the next level user)
- Then `su levelX` and continue until the last mandatory level

## Environment

The project is meant to be solved on the provided **64-bit VM** (ISO from the subject).

Typical connection flow:

```sh
# From your host
ssh level0@<VM_IP> -p 4242
# password: level0
```

If the VM IP is not displayed on boot, get it from inside the VM:

```sh
ifconfig
```

## Rules / Constraints (from the subject)

- Be ready to **explain and prove** your results during evaluation.
- **Automation tools are forbidden** (using them is considered cheating).
- Do **not** brute-force SSH “flags”; you must justify the solution.
- Do **not** commit binaries in this repository.
- If you need a file that exists on the project ISO/VM, you must fetch it **during evaluation** (do not include it in the repo).
- Anything you include must be clearly explainable.

## Repository structure (required)

The repository is expected to contain one folder per level.

Mandatory levels:

- `level0/` … `level9/`

Bonus levels (only assessed if mandatory is fully completed and working):

- `bonus0/`, `bonus1/`, `bonus2/`, `bonus3/`

Each `levelX/` folder should follow this structure:

```text
levelX/
  flag
  source
  walkthrough
  Ressources/
```

Meaning:

- `flag`: the obtained password/flag for that level (may be empty if you can justify why).
- `source`: a developer-friendly representation of the exploited program/bug (language of your choice).
- `walkthrough`: step-by-step explanation to reproduce the solution.
- `Ressources/`: any additional files needed to prove the solution (scripts, notes, etc.).

## Suggested content guidelines

- Keep `walkthrough` reproducible (commands, expected outputs, and reasoning).
- If you add scripts under `Ressources/`, document how to run them and be prepared to explain them.
- Prefer minimal dependencies; if you require external tooling, document the exact environment (VM/Docker/Vagrant).