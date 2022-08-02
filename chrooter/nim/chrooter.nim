import os
import posix
import strformat

proc execve(pathname: cstring, argv: cstringArray, envp: cstringArray): cint {.importc: "execve", header: "stdlib.h".}
proc symlink(path1: cstring, path2: cstring): cint {.importc, header: "unistd.h".}
proc link(oldpath: cstring, newpath: cstring): cint {.importc, header: "unistd.h".}
proc chroot(path: cstring): cint {.importc, header: "unistd.h".}
proc getuid(): Uid {.importc, header: "unistd.h".}

var errno {.importc: "errno", header: "errno.h".}: cint
proc strerror(errnum: cint): cstring {.importc, header: "string.h".}

const tmp_dir = "fake_root"

proc main() =
    if paramCount() < 1 or not fileExists(getEnv("BIN_PATH")):
        echo("Usage: chrooter_nim [arguments]")
        echo("Path to binary read from the BIN_PATH environment variable")
        quit(1)

    if getuid() != 0:
        echo("Need to run as root (technically just CAP_SYS_CHROOT but I'm lazy)")
        quit(1)

    # Create temp dir
    let bin_path = absolutePath(getEnv("BIN_PATH"))
    let old_cwd = getCurrentDir()
    removeDir(tmp_dir)
    createDir(tmp_dir)
    setCurrentDir(tmp_dir)

    var err = symlink(".", "bin")
    if err < 0 and errno != 17:
        echo(fmt"symlink ./bin {errno} error: {strerror(errno)}")
        setCurrentDir(old_cwd)
        removeDir(tmp_dir)
        quit(1)

    err = link(cstring(bin_path), "bash")
    if err < 0 and errno != 17:
        echo(fmt"symlink ./bin/bash error: {strerror(errno)}")
        setCurrentDir(old_cwd)
        removeDir(tmp_dir)
        quit(1)

    # Fork, so we can cleanup as well as call execve
    var pid = fork()
    if pid == 0:
        # Child, sleep for a second then cleanup
        sleep(1000)
        setCurrentDir(old_cwd)
        removeDir(tmp_dir)
    else:
        # Parent, chroot into dir and exec
        err = chroot(".")
        if err < 0:
            echo(fmt"chroot error: {strerror(errno)}")
            setCurrentDir(old_cwd)
            removeDir(tmp_dir)
            quit(1)

        # Build argv array
        var args: seq[string]
        args.add("from_chrooter")
        for i in 1..paramCount():
            args.add(paramStr(i))
        var argv = alloccstringArray(args)
        err = execve("/bin/bash", argv, nil)
        if err < 0:
            echo(fmt"execve error: {strerror(errno)}")
            setCurrentDir(old_cwd)
            removeDir(tmp_dir)
            quit(1)

main()
