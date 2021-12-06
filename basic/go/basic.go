package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	pid := os.Getpid()
	ppid := os.Getppid()

	argc := len(os.Args)
	fmt.Printf("  PID     %d\n", pid)
	fmt.Printf("  PPID    %d\n", ppid)
	fmt.Printf("  argc    %d\n", argc)
	for i := 0; i < argc; i++ {
		fmt.Printf("  argv[%d] %s\n", i, os.Args[i])
	}

	fmt.Print("  Sleeping for 60 seconds so you can lookup the PID")
	time.Sleep(60 * time.Second)
}
