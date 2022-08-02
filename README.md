# Commandline Cloaking
This is a collection of projects to demonstrate how different commandline
cloaking techniques in various languages.

This code accompanies my blog [Sysmon for Linux and Commandline Cloaking](https://blog.tofile.dev/2022/01/04/sysmonlinux.html).

# Prerequisites
- Make
- Go
- GCC
- NASM
- [Nim](https://nim-lang.org/) (optional)
- [Sysmon for Linux](https://github.com/Sysinternals/SysmonForLinux/blob/main/INSTALL.md) (optional)

# Building
Run `make` to build all projects:
```bash
git clone https://github.com/pathtofile/commandline_cloaking.git
cd commandline_cloaking

# To build all examples except Nim:
make
# To build just the C examples:
make all_c
# To build just the Go examples:
make all_go
# To build just the Nim examples:
make all_nim
```

Binaries will be put in the `bin` folder.
See below for descriptions and how to run each project.

# Projects
See the `README` in each folder for a more complete description of each project.

## [Sysmon](sysmon)
A simple Sysmon config and instructions in how to install and get logs from Sysmon for Linux


## [Basic](basic)
Basic is a simple binary that prints out information about the arguments it was run with.

There are two versions of the Binary - A C version (`c/basic.c`) a Go version (`go/basic.go`).
Both do the same thing, to concept of passing and using `argv` from syscall to program is easier
to see in C, however Go is a language more people may be familiar with.

Example usage:
```bash
$> ./bin/basic
  PID     984050
  argc    1
  argv[0] ./bin/basic
$> ./bin/basic AAAA
  PID     984173
  argc    2
  argv[0] ./bin/basic
  argv[1] AAAA
```


## [Dodgy](dodgy)
Dodgy is a program that messes with it's arguments at runtime, to 'cloak' what the actual
arguments and parent process is. In order, `dodgy` does:
- Uses [prctl](https://man7.org/linux/man-pages/man2/prctl.2.html) to change
the value in `/proc/<pid>/comm` (used by some tools)
- Overwrites the address of `argv[0]` and `argv[1]` to fake the real values to tools such as `ps`.
- Double-forks to make it's parent appear to be PID 1

There are two versions of the Binary - A C version (`c/dodgy.c`) a Go version (`go/dodgy.go`).
Both do the same thing, to concept of passing, using, and altering `argv` from syscall to
program is easier to see in C (and the syscalls are cleaner),
however Go is a language more people may be familiar with.

Example usage:
```bash
$> ./bin/dodgy AAAA
-------- REAL --------
  PID     1048944
  PPID    515316
  argc    2
  argv[0] ./bin/dodgy
  argv[1] AAAA
---- FORK & FAKE -----
  PID     1048946
  PPID    1
  argv[0] FFFFFFFFFFF
  argv[1] BBBB
----------------------

# Check ps output for pid
$> ps aux | grep 1048946
path     1048946  0.0  0.0   2304    76 pts/1    S    10:03   0:00 FFFFFFFFFFF BBBB
$> cat /proc/1003213/comm
faked
$> cat /proc/1003213/cmdline
FFFFFFFFFFFBBBB

# Check parents
pstree --show-pids --show-parents 1048946
systemd(1)───faked(1048946)
```


## [Loader](loader)
Loader a tool to load an execute an ELF from in-memory [memfd](https://man7.org/linux/man-pages/man2/memfd_create.2.html)
region.

There are two versions that do the same thing, a Python script `python/loader.py` and a Go binary `go/loader.go`.

Example usage:
```bash
$> python3 ./loader/loader.py ./bin/basic AAAA
  PID     1008789
  argc    2
  argv[1] AAAA

# Check ps output for pid
$> ps aux | grep 1008789
path     1008789  0.0  0.0 703072  2872 pts/0    Sl+  12:06   0:00 from_loader AAAA

# Can also pipe from stdin
$> cat ./bin/basic | python3 ./loader/loader.py - AAAA
  PID     1008789
  argc    2
  argv[1] AAAA
```


## [Injector](injector)
Injector is a Go program and ASM shellcode that combine a number of techniques to cloak the commandline
of programs that don't cloak themselves:
- Generates a patched version of the ELF with altered `argv` prior to real code running
- Uses `memfd_create` to load and run patched ELF from in-memory

See [Injector README](injector/README.md) for details on how patching works.

Example usage:
```bash
$> ./bin/injector ./bin/shellcode.bin /bin/echo AAAA
BBBB

$> ./bin/injector ./bin/shellcode.bin ./bin/basic AAAA
  PID     1032969
  argc    2
  argv[1] BBBB
# Check ps
$> ps aux | grep 1032969
path     1032969  0.0  0.0 703072  1076 pts/1    Sl+  13:06   0:00 A BBBB
```

## [Preload](preload)
Preload in an `LD_PRELOAD` binary that hooks programs written with LibC (i.e. most default binaries on Linux).
Once the library has hooked LibC's main entrypoint `__libc_start_main`, it will alter the `argv` arguemnts,
before continuing on to the program's real `main` function. 

Effectivly, the `preload` sits in between the `execve` syscall and the program's `main` function, altering
the arguments after the syscall but before the program uses them.

There are two versions of the Binary - A C version (`c/preload.c`) a Go version (`go/preload.go`).
They both behave similarly, but the C code is clearer to read.

Example usage:
```bash
# Set the LD_PRELOAD variable to path to preload
# NOTE: this won't work on Go programs, so use the C version of Basic
LD_PRELOAD=./bin/preload.so ./bin/basic_c AAAA
  PID     1451700
  PPID    1052430
  argc    2
  argv[0] from_preload
  argv[1] BBBB

# Check ps output for pid, notice original args
$> ps aux | grep 1451700
path     1451722  0.0  0.1 1147824 9648 pts/0    Sl+  14:56   0:00 ./bin/basic_c AAAA
```

## [Chrooter](chrooter)
This code uses [chroot](https://linux.die.net/man/2/chroot) to mask a binaries real path.

Chroot is a key element of Linux containers that changes the root directory of the calling process.
From that process's perspective the root `/` folder changes, which affects where it looks
to load files, run programs, etc.

For more technical details on `chroot` and how it powers Linux containers, read chapter 4 of
[Liz Rice's awesome Container Security Book](https://www.oreilly.com/library/view/container-security/9781492056690/)
(and then read the rest of it because it's an excelent book).

This program uses symlinks and `chroot` to run an arbitrary binary that the process's perspective is at `/bin/bash`.

Process monitors (including eBPF-based monitors Sysmon for Linux and Tetragon) typically record the binary path from the
processes PoV as this is both easier and more useful when observing activity within a container.

To make it's output in security systems cleaerer, this program reads the binary to symlink and run from the `BIN_PATH`
environment variable.

**NOTE** Using chroot requires the capability `CAP_SYS_ADMIN`, ie. running as root or under a root-like account/program.

**NOTE** This program only works on statically linked binaries. Otherwise you need to also
copy all required libraries into the `chroot` subfolders.

Example usage:
```bash
root@machine$> BIN_PATH=./basic_nim_static ./chrooter_nim AAAA
  PID     21836
  PPID    21783
  argc    2
  argv[0] from_chrooter
  argv[1] AAAA
  Sleeping for 60 seconds so you can lookup the PID
```
