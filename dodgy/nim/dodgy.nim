import os
import posix
import strformat
import strutils

proc NimMain() {.cdecl, importc.}

# Use syscall function call from stdlib
proc syscall(number: clong): clong {.importc, varargs, header: "sys/syscall.h".}
var NR_PRCTL {.importc: "__NR_prctl", header: "unistd.h".}: int
var PR_SET_NAME {.importc: "PR_SET_NAME", header: "sys/prctl.h".}: int

proc memset(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "string.h"}

# Compiled with --nomain so we overwrite Nim's default main func
proc main(argc: int, argv: cstringArray, envp: cstringArray): int {.cdecl, exportc.} =
    # Need to call NimMain ourselves first to avoid explosions
    NimMain()

    # Print data
    echo("-------- REAL --------")
    echo(fmt"  PID     {getpid()}")
    echo(fmt"  PPID    {getppid()}")
    echo(fmt"  argc    {argc}")
    for i in 0..(argc-1):
        echo(fmt"  argv[{i}] {argv[i]}")

    # Double-fork to make parent pid look like PID 1
    var child_pid = fork()
    if child_pid != 0:
        # First parent, exit
        return 0
    child_pid = fork()
    if child_pid != 0:
        # Second parent, exit
        return 0

    # Use prctl syscall to change /proc/pid/comm
    var err = syscall(NR_PRCTL, PR_SET_NAME, cstring("faked"))
    if err < 0:
        echo(fmt"Error calling PRCTL {err}")
        return -1

    # Overwrite args, have to use 'memset'
    discard memset(argv[0], ord('F'), csize_t(len(argv[0])))
    if argc > 1:
        discard memset(argv[1], ord('B'), csize_t(len(argv[1])))

    # Sleep for a second for parent to be reaped
    # and PID 1 to adopt us
    sleep(1 * 1000)

    # Print data
    echo("---- FORK & FAKE -----")
    echo(fmt"  PID     {getpid()}")
    echo(fmt"  PPID    {getppid()}")
    echo(fmt"  argc    {argc}")
    for i in 0..(argc-1):
        echo(fmt"  argv[{i}] {argv[i]}")

    echo("----------------------")
    echo("  Sleeping for 60 seconds so you can lookup the PID")
    setControlCHook(proc() {.noconv.} = discard)
    sleep(60 * 1000)

    return 0
