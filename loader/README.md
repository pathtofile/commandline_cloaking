# Loader
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

# Sysmon output
Sysmon will log the Python loader fully, but will have trouble with the loaded binary.

Sysmon can only record the image was "memfd", and while is can see the real argv,
as `argv[0]` can be set to anything, sysmon doesn't have the real binary read from disk.
```
Event SYSMONEVENT_CREATE_PROCESS
	RuleName: -
	UtcTime: 2021-11-28 07:52:23.860
	ProcessGuid: {35dd0383-3537-61a3-ed63-6a0000000000}
	ProcessId: 1036590
	Image: /usr/bin/python3.9
	FileVersion: -
	Description: -
	Product: -
	Company: -
	OriginalFileName: -
	CommandLine: python3 ./loader/loader.py ./bin/basic AAAA
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
	UtcTime: 2021-11-28 07:52:23.860
	ProcessGuid: {35dd0383-3537-61a3-1814-480000000000}
	ProcessId: 1036590
	Image: /memfd:
	FileVersion: -
	Description: -
	Product: -
	Company: -
	OriginalFileName: -
	CommandLine: from_loader AAAA
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

Depending on the machine, user, or parent process, it may be
highly suspicious to see an ELF being run from memory, so this fact alone
may be enough to write a detect for.
