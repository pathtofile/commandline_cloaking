"""
Python in-memory elf loader
Example of a simple script to load
an ELF into memory and launch it.
"""
import sys
import os
from ctypes import CDLL

def main():
    if len(sys.argv) < 2:
        print("Usage: loader.py <binary> [arguments]")
        sys.exit(1)
    binary = sys.argv[1]

    # Setup libc and syscall numbers
    libc = CDLL("libc.so.6")
    syscall_memfd_create = 319

    # Create memory reagon to hold ELF
    fd = libc.syscall(syscall_memfd_create, "", 0)

    # Write ELF data into memory. This reads ELF from
    # disk or stdin, but could also be from the internet,
    # an encrypted file, hardcoded etc.
    if binary == "-":
        # read from stdin
        data = sys.stdin.buffer.read()
    else:
        with open(binary, "rb") as f:
            data = f.read()
    os.write(fd, data)

    # Use execv to launch. To pass in
    # commandline args add them from argv
    fd_path = f"/proc/self/fd/{fd}"
    argv = ["from_loader", ]
    if len(sys.argv) > 1:
        argv += sys.argv[2:]
    os.execv(fd_path, argv)

if __name__ == "__main__":
    main()
