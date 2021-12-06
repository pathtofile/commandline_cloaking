# Basic
Basic is a simple binary that prints out information about the arguments it was run with.
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
There are two versions of the Binary - A C version (`c/basic.c`) a Go version (`go/basic.go`).
Both do the same thing, to concept of passing and using `argv` from syscall to program is easier
to see in C, however Go is a language more people may be familiar with.


# Sysmon output
Sysmon correctly records the process execute
```
Event SYSMONEVENT_CREATE_PROCESS
    RuleName: -
    UtcTime: 2021-11-30 23:51:08.592
    ProcessGuid: {35dd0383-b8ec-61a6-b8d0-480000000000}
    ProcessId: 1066830
    Image: /path/to/basic
    FileVersion: -
    Description: -
    Product: -
    Company: -
    OriginalFileName: -
    CommandLine: ./bin/basic AAAA
    CurrentDirectory: /path/to
    User: path
    LogonGuid: {35dd0383-9d97-61a4-e803-000002000000}
    LogonId: 1000
    TerminalSessionId: 347
    IntegrityLevel: no level
    Hashes: -
    ParentProcessGuid: {35dd0383-9a98-61a4-fddb-e43082550000}
    ParentProcessId: 1054354
    ParentImage: /usr/bin/bash
    ParentCommandLine: -bash
    ParentUser: path
```
