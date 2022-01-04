# PRELOAD
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

# Sysmon output
As preload's shennanigans run after the `execve`, Sysmon only see's the original arguments, and
not what the effective arguments to `basic_c` are:
```
Event SYSMONEVENT_CREATE_PROCESS
       RuleName: -
       UtcTime: 2021-12-02 03:29:01.320
       ProcessGuid: {35dd0383-3d7d-61a8-9d12-65fb78550000}
       ProcessId: 1451890
       Image: /path/to/bin/basic_c
       FileVersion: -
       Description: -
       Product: -
       Company: -
       OriginalFileName: -
       CommandLine: ./bin/basic_c AAAA
       CurrentDirectory: /path/to
       User: path
       LogonGuid: {35dd0383-4d8c-61a4-e803-000000000000}
       LogonId: 1000
       TerminalSessionId: 334
       IntegrityLevel: no level
       Hashes: -
       ParentProcessGuid: {35dd0383-4d8c-61a4-fd3b-d4af46560000}
       ParentProcessId: 1052430
       ParentImage: /usr/bin/bash
       ParentCommandLine: -bash
       ParentUser: path
```

This is accurate, *technically* `basic_c` was launched with `AAAA`, and preload runs after the process
has launched.
