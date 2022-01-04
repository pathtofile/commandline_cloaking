# Injector
Injector is a Go program and ASM shellcode that combine a number of techniques to cloak the commandline
of programs that don't cloak themselves:
- Generates a patched version of the ELF with altered `argv` prior to real code running
- Uses `memfd_create` to load and run patched ELF from in-memory

# How patching works:
This code makes use of the awesome [Binjection](https://github.com/Binject/binjection) project to
read in the ELF bytes patch them in-memory.

The project project uses a patching technique covered by Silvio Cesare in his 1998 paper
[Unix ELF parasites and viruses](https://vxug.fakedoma.in/archive/VxHeaven/lib/vsc01.html).
As summarised by the Binjection team, this tequniques involves:
1. Increase p_shoff by PAGE_SIZE in the ELF header
2. Patch the insertion code (parasite) to jump to the entry point (original)
3. Locate the text segment program header
    -Modify the entry point of the ELF header to point to the new code (p_vaddr + p_filesz)
    -Increase p_filesz to account for the new code (parasite)
    -Increase p_memsz to account for the new code (parasite)
4. For each phdr which is after the insertion (text segment)
    -increase p_offset by PAGE_SIZE
5. For the last shdr in the text segment
    -increase sh_len by the parasite length
6. For each shdr which is after the insertion
    -Increase sh_offset by PAGE_SIZE
7. Physically insert the new code (parasite) and pad to PAGE_SIZE,
    into the file - text segment p_offset + p_filesz (original)

`Injector` uses Silvio's method to inject [shellcode](shellcode.asm) at
the entrypoint to look for `argv[1]` in the stack,
which is put there by the kernel prior to the ELF running.
The shellcode then overwrites the argument to `BBBB\0`, which will then
be passed into the actual ELF code, as if this was the actual original arg.

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
path     1032969  0.0  0.0 703072  1076 pts/1    Sl+  13:06   0:00 from_injector BBBB
```


# Sysmon output
Sysmon will log the loader fully, but again will have some trouble with the loaded binary.

When this command is run:
```bash
$> ./bin/injector ./bin/shellcode.bin /bin/echo AAAA
BBBB
```

It generates these Sysmon events:
```
Event SYSMONEVENT_CREATE_PROCESS
    RuleName: -
    UtcTime: 2021-11-28 07:54:47.203
    ProcessGuid: {35dd0383-35c7-61a3-401b-4b0000000000}
    ProcessId: 1036649
    Image: /path/to/bin/injector
    FileVersion: -
    Description: -
    Product: -
    Company: -
    OriginalFileName: -
    CommandLine: ./bin/injector ./bin/shellcode.bin /bin/echo AAAA
    CurrentDirectory: /path/to
    User: path
    LogonGuid: {35dd0383-8cdb-61a1-e803-000001000000}
    LogonId: 1000
    TerminalSessionId: 224
    IntegrityLevel: no level
    Hashes: -
    ParentProcessGuid: {00000000-0000-0000-0000-000000000000}
    ParentProcessId: 515316
    ParentImage: -
    ParentCommandLine: -
    ParentUser: -
Event SYSMONEVENT_CREATE_PROCESS
    RuleName: -
    UtcTime: 2021-11-28 07:54:47.203
    ProcessGuid: {35dd0383-35c7-61a3-e37f-08f2a2550000}
    ProcessId: 1036649
    Image: /memfd:
    FileVersion: -
    Description: -
    Product: -
    Company: -
    OriginalFileName: -
    CommandLine: from_injector AAAA
    CurrentDirectory: /path/to
    User: path
    LogonGuid: {35dd0383-8cdb-61a1-e803-000001000000}
    LogonId: 1000
    TerminalSessionId: 224
    IntegrityLevel: no level
    Hashes: -
    ParentProcessGuid: {00000000-0000-0000-0000-000000000000}
    ParentProcessId: 515316
    ParentImage: -
    ParentCommandLine: -
    ParentUser: -
```

Note that there is no indication echo was the program run, and that Sysmon
records the argument being run is `AAAA`, although echo executes as if it was actually run with `BBBB`.

Depending on the machine, user, or parent process, it may be
highly suspicious to see an ELF being run from memory, so this fact alone
may be enough to write a detect for.
