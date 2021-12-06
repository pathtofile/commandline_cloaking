# Commandline Cloaking
This is a collection of projects to demonstrate how different commandline
cloaking techniques appear to [Sysmon for Linux](https://github.com/Sysinternals/SysmonForLinux/).
This code accompanies my blog [Sysmon for Linux and Commandline Cloaking](https://blog.tofile.dev/xxx).


# Prerequisites
- Go
- Make
- NASM
- GCC
- [Sysmon for Linux](https://github.com/Sysinternals/SysmonForLinux/blob/main/INSTALL.md)

# Building
Run `make` to build all projects:
```bash
git clone https://github.com/pathtofile/commandline_cloaking.git
cd commandline_cloaking
make
```
Binaries will be put in the `dst` folder.
See below for descriptions and how to run each project.

# Projects
See the `README` in each folder for a more complete description of each project.

## [Sysmon](sysmon)
A simple Sysmon config and instructions in how to install and get logs from Sysmon for Linux


## [Basic](basic)
Basic is a golang binary that prints out information about the arguments it was run with.
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
Dodgy is a C program that messes with it's arguments at runtime, to 'cloak' what the actual
argv is. It uses [prctl](https://man7.org/linux/man-pages/man2/prctl.2.html) to change
the value in `/proc/<pid>/comm` (used by some tools), and then overwrites the address
of `argv[0]` and `argv[1]` to fake the real values to tools such as `ps`.
Example usage:
```bash
$> ./bin/dodgy AAAA
-------- REAL --------
  PID     1003213
  argc    2
  argv[0] ./bin/dodgy
  argv[1] AAAA
-------- FAKE --------
  argv[0] FFFFFFFFFFF
  argv[1] BBBB
----------------------

# Check ps output for pid
$> ps aux | grep 1003213
path     1003394  0.0  0.0   2304   560 pts/0    S+   11:42   0:00 FFFFFFFFFFF BBBB
$> cat /proc/1003213/comm
faked
$> cat /proc/1003213/cmdline
FFFFFFFFFFFBBBB
```

## [Loader](loader)
Loader is a Python3 script to load an execute an ELF from in-memory [memfd](https://man7.org/linux/man-pages/man2/memfd_create.2.html)
region.
This was written in Python only to demonstrate code in a different language,
and is easy to re-implement in C or Go.

Example usage:
```bash
$> python3 ./loader/loader.py ./bin/basic AAAA
  PID     1008789
  argc    2
  argv[1] AAAA

# Check ps output for pid
$> ps aux | grep 1008789
path     1008789  0.0  0.0 703072  2872 pts/0    Sl+  12:06   0:00 fake AAAA
```


## [Injector](injector)
Injector is a Go program and ASM shellcode that combine a number of techniques to cloak the commandline
of programs that don't cloak themselves:
- Generates a patched version of the ELF with altered `argv` prior to real code running
- Uses `memfd_create` to load and run patched ELF from in-memory

See [Injector README](injector/README.md) for details on patching. Example usage:
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
