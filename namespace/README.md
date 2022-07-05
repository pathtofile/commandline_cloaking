# Namespace
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
root@machine$> BIN_PATH=./basic_nim_static ./namespace_nim AAAA
  PID     21836
  PPID    21783
  argc    2
  argv[0] from_namespace
  argv[1] AAAA
  Sleeping for 60 seconds so you can lookup the PID
```

## Tetragon output
```json
{
  "process_exec": {
    "process": {
      "exec_id": "OjI5Mzc2MTgxOTk3NTcxMzoyMTgzNg==",
      "pid": 21836,
      "uid": 0,
      "cwd": "/path/to/namespace_tmp/",
      "binary": "/bin/bash",
      "arguments": "AAAA",
      "flags": "execve",
      "start_time": "2022-07-05T03:13:04.511Z",
      "auid": 1000,
      "parent_exec_id": "OjI5Mzc2MTgxOTI1MDIwNzoyMTgzNg==",
      "refcnt": 1
    },
    "parent": {
      "exec_id": "OjI5Mzc2MTgxOTI1MDIwNzoyMTgzNg==",
      "pid": 21836,
      "uid": 0,
      "cwd": "/path/to/",
      "binary": "/path/to/namespace_nim",
      "arguments": "AAAA",
      "flags": "execve clone",
      "start_time": "2022-07-05T03:13:04.510Z",
      "auid": 1000,
      "parent_exec_id": "OjI5MzczOTUxNDI1NTM0MjoyMTc4Mw==",
      "refcnt": 1
    }
  },
  "time": "2022-07-05T03:13:04.511Z"
}
```

Without any namespace information, it does appear that `/bin/bash` was the program run,
which is technically correct, just not the fact the program has changed it's root mid-execution.
