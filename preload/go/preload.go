package main

// #cgo CFLAGS: -D_GNU_SOURCE
// #cgo LDFLAGS: -ldl
// #include <dlfcn.h>
import "C"

import (
	"fmt"
	"unsafe"

	"github.com/awgh/cppgo/asmcall/cdecl"
)

func main() {}

//export __libc_start_main
func __libc_start_main(
	main *C.void,
	argc C.int,
	argv **C.char,
	init *C.void,
	fini *C.void,
	rtld_fini *C.void,
) C.int {
	fp := C.dlopen(C.CString("libc.so.6"), C.RTLD_LAZY)
	orig_func := C.dlsym(fp, C.CString("__libc_start_main"))
	if orig_func == nil {
		fmt.Printf("[ ] orig_func nil \n")
		return 0
	}

	// Alter argv
	// Unlike the version in C, this one alters argv *before*
	// Running the rest of __libc_start_main.
	// This was just simpler in Go to me, but might have concequences
	offset := unsafe.Sizeof(uintptr(0))
	argv_copy := argv

	new_argv_0 := C.CString("from_preload")
	*argv_copy = new_argv_0
	if argc > 1 {
		new_argv_1 := C.CString("BBBB")
		argv_copy = (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(argv_copy)) + offset))
		*argv_copy = new_argv_1
	}

	// If you wanted to print argv:
	// offset := unsafe.Sizeof(uintptr(0))
	// argv_copy := argv
	// var out []string
	// for *argv_copy != nil {
	// 	test := C.GoString(*argv_copy)
	// 	fmt.Printf("[ ] %s\n", test)
	// 	out = append(out, test)
	// 	argv_copy = (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(argv_copy)) + offset))
	// }

	// Call into real main
	main_argv := unsafe.Pointer(argv)
	main_unsafe := unsafe.Pointer(main)
	main_init := unsafe.Pointer(init)
	main_fini := unsafe.Pointer(fini)
	main_rtld_fini := unsafe.Pointer(rtld_fini)
	val, err := cdecl.Call(
		uintptr(orig_func),
		uintptr(main_unsafe),
		uintptr(argc),
		uintptr(main_argv),
		uintptr(main_init),
		uintptr(main_fini),
		uintptr(main_rtld_fini),
	)

	if err == nil {
		fmt.Printf("[ ] Error! %s \n", err)
		return 0
	} else {
		return (C.int)(val)
	}
}
