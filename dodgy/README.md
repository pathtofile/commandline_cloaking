# Dodgy
Dodgy is a program that messes with it's arguments at runtime, to 'cloak' what the actual
arguments and parent process is. In order, `dodgy` does:
- Uses [prctl](https://man7.org/linux/man-pages/man2/prctl.2.html) to change
the value in `/proc/<pid>/comm` (used by some tools)
- Overwrites the address of `argv[0]` and `argv[1]` to fake the real values to tools such as `ps`.
- Double-forks to make it's parent appear to be PID 1
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

There are two versions of the Binary - A C version (`c/dodgy.c`) a Go version (`go/dodgy.go`).
Both do the same thing, to concept of passing, using, and altering `argv` from syscall to
program is easier to see in C (and the syscalls are cleaner),
however Go is a language more people may be familiar with.

# Sysmon output
Dodgy only changes it's arguments once it has run, which is
after Sysmon records the event. As such the read image name and arguments
are recorded 3 events are raised for each parent and child in the double-fork:
```
Event SYSMONEVENT_CREATE_PROCESS
    RuleName: -
    UtcTime: 2021-11-28 01:00:40.436
    ProcessGuid: {35dd0383-d4b8-61a2-7dc3-739ff5550000}
    ProcessId: 1048944
    Image: /path/to/bin/dodgy
    FileVersion: -
    Description: -
    Product: -
    Company: -
    OriginalFileName: -
    CommandLine: ./bin/dodgy AAAA
    CurrentDirectory: /path/to/bin
    User: path
    LogonGuid: {35dd0383-8af4-61a1-e803-000000000000}
    LogonId: 1000
    TerminalSessionId: 221
    IntegrityLevel: no level
    Hashes: -
    ParentProcessGuid: {00000000-0000-0000-0000-000000000000}
    ParentProcessId: 512681
    ParentImage: -
    ParentCommandLine: -
    ParentUser: -
```

You will note that the `ProcessId` recorded is the original pre-double-fork PID.
