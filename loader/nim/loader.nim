import os
import strformat

proc memfd_create(name: cstring, flags: cuint): cint {.importc, header: "sys/mman.h".}
proc execve(pathname: cstring, argv: cstringArray, envp: cstringArray): cint {.importc: "execve", header: "stdlib.h".}

proc main() =
    if paramCount() < 1:
        echo("Usage: loader.py <binary> [arguments]")
        quit(1)

    # Create in-memory file
    let fd = memfd_create("", 0)
    if fd == -1:
        echo("Error creating memfd")
        quit(1)
    let fp = fmt"/proc/self/fd/{fd}"

    # Read ELF from either disk or stdin
    var data: string
    if paramStr(1) == "-":
        data = readAll(stdin)
    else:
        var fread = open(paramStr(1), fmRead)
        data = readAll(fread)
        fread.close()

    # Write data to in-memory file
    var fwrite = open(fp, fmWrite)
    fwrite.write(data)
    fwrite.close()

    # Build argv array
    var args: seq[string]
    args.add("from_loader")
    for i in 2..paramCount():
        args.add(paramStr(i))

    # Exec process
    var argv = alloccstringArray(args)
    discard execve(cstring(fp), argv, nil)

main()
