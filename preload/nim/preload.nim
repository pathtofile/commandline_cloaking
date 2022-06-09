import dynlib

proc memset(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "string.h"}
type
  LibCMain = proc (
    main: pointer,
    argc: cint,
    argv: cstringArray,
    init: pointer,
    fini: pointer,
    rtld_fini: pointer): int {.cdecl}


# Set this to true to overwrite argv in-place
# instead of giving main our own argv array.
# When overwrite_argv = false the output of 'ps'
# will match the original argv from the commandline,
# when it is true the output of 'ps' will be updated
# to reflect the overwritten values
const overwrite_argv = false

# This hooks __libc_start_main
proc hookedLibcMain(
    main: pointer,
    argc: cint,
    argv: cstringArray,
    init: pointer,
    fini: pointer,
    rtld_fini: pointer
): int {.cdecl, exportc:"__libc_start_main", dynlib} =
    # Find original function
    let lib = loadLib("libc.so.6")
    assert lib != nil, "Error loading library"
    let origFunc = cast[LibCMain](lib.symAddr("__libc_start_main"))
    assert origFunc != nil, "Error loading function from library"

    if overwrite_argv:
        # Overwrite args, have to use 'memset'
        discard memset(argv[0], ord('F'), csize_t(len(argv[0])))
        if argc > 1:
            discard memset(argv[1], ord('B'), csize_t(len(argv[1])))

        return origFunc(main, argc, argv, init, fini, rtld_fini)
    else:
        # Create a new argv array to use
        let newArgc = cint(2)
        var newArgv = alloccstringArray(["from_preload", "BBBB"])
        return origFunc(main, newArgc, newArgv, init, fini, rtld_fini)
