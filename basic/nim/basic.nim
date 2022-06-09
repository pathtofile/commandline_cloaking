import os
import strformat
import posix

proc main() =
    echo(fmt"  PID     {getpid()}")
    echo(fmt"  PPID    {getppid()}")
    echo(fmt"  argc    {paramCount() + 1}")  # Nim doesn't count argv[0] in paramCount

    for i in 0..paramCount():
        echo(fmt"  argv[{i}] {paramStr(i)}")

    echo("  Sleeping for 60 seconds so you can lookup the PID")
    setControlCHook(proc() {.noconv.} = discard)
    sleep(60 * 1000)

main()
