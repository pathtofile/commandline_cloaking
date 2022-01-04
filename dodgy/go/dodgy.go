package main

import (
	"fmt"
	"os"
	"reflect"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

func main() {
	pid := os.Getpid()
	ppid := os.Getppid()
	argc := len(os.Args)

	fmt.Printf("-------- REAL --------\n")
	fmt.Printf("  PID     %d\n", pid)
	fmt.Printf("  PPID    %d\n", ppid)
	fmt.Printf("  argc    %d\n", argc)
	for i := 0; i < argc; i++ {
		fmt.Printf("  argv[%d] %s\n", i, os.Args[i])
	}

	// Double-fork to make parent pid look like PID 1
	// Can't use syscall.ForkExec as it waits for child to exit,
	// which is the opposite of what we want
	child_pid, _, _ := syscall.Syscall(syscall.SYS_FORK, 0, 0, 0)
	if child_pid != 0 {
		// First partent
		os.Exit(0)
	}
	child_pid, _, _ = syscall.Syscall(syscall.SYS_FORK, 0, 0, 0)
	if child_pid != 0 {
		// First partent
		os.Exit(0)
	}

	// Use prctl to change /proc/pid/comm
	// This is cleaner in C than in Go
	bytes := append([]byte("faked"), 0)
	ptr := unsafe.Pointer(&bytes[0])
	syserr, _, _ := syscall.Syscall(syscall.SYS_PRCTL, syscall.PR_SET_NAME, uintptr(ptr), 0)
	if int(syserr) < 0 {
		fmt.Printf("Erorr Calling PR_SET_NAME")
		os.Exit(1)
	}

	// Overwrite address of argv to fool 'ps'
	// This is much cleaner in C than in Go
	new_arg := strings.Repeat("F", len(os.Args[0]))
	argv_cstr := (*reflect.StringHeader)(unsafe.Pointer(&os.Args[0]))
	argv_ptr := (*[1 << 30]byte)(unsafe.Pointer(argv_cstr.Data))[:argv_cstr.Len]
	copy(argv_ptr, new_arg)
	if argc > 1 {
		new_arg = strings.Repeat("B", len(os.Args[1]))
		argv_cstr = (*reflect.StringHeader)(unsafe.Pointer(&os.Args[1]))
		argv_ptr = (*[1 << 30]byte)(unsafe.Pointer(argv_cstr.Data))[:argv_cstr.Len]
		copy(argv_ptr, new_arg)
	}

	// Sleep for a second for parent to be reaped
	// and PID 1 to adopt us
	time.Sleep(1 * time.Second)

	// Print data
	pid = os.Getpid()
	ppid = os.Getppid()
	argc = len(os.Args)
	fmt.Printf("---- FORK & FAKE -----\n")
	fmt.Printf("  PID     %d\n", pid)
	fmt.Printf("  PPID    %d\n", ppid)
	fmt.Printf("  argc    %d\n", argc)
	for i := 0; i < argc; i++ {
		fmt.Printf("  argv[%d] %s\n", i, os.Args[i])
	}

	fmt.Print("  Sleeping for 60 seconds so you can lookup the PID")
	time.Sleep(60 * time.Second)
}
