package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"golang.org/x/sys/unix"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Usage: loader.py <binary> [arguments]\n")
		os.Exit(1)
	}

	// Create memory reagon to hold ELF
	fd, err := unix.MemfdCreate("", 0)
	if err != nil {
		fmt.Printf("Error calling MemfdCreate %s", err)
		os.Exit(1)
	}
	fp := fmt.Sprintf("/proc/self/fd/%d", fd)
	file := os.NewFile(uintptr(fd), fp)
	if err != nil {
		fmt.Printf("Error calling NewFile %s", err)
		os.Exit(1)
	}
	defer file.Close()

	// Write ELF data into memory. This reads ELF from
	// disk or stdin, but could also be from the internet,
	// an encrypted file, hardcoded etc.
	data := []byte{}
	if os.Args[1] == "-" {
		// Read from stdin
		read_data, err := ioutil.ReadAll(os.Stdin)
		if err != nil {
			fmt.Printf("Error reading from stdin: %s", err)
			os.Exit(1)
		}
		data = append(data, read_data...)
	} else {
		read_data, err := ioutil.ReadFile(os.Args[1])
		if err != nil {
			fmt.Printf("Error reading file %s: %s", os.Args[1], err)
			os.Exit(1)
		}
		data = append(data, read_data...)
	}

	// Write patched ELF into memfd memory
	_, err = file.Write(data)
	if err != nil {
		fmt.Printf("Error writing data to memfd file %s", err)
		os.Exit(1)
	}

	// Execute in-memory binary
	// To pass in commandline args add them from argv
	argv := []string{"from_loader"}
	if len(os.Args) > 2 {
		argv = append(argv, os.Args[3:]...)
	}
	err = unix.Exec(fp, argv, os.Environ())
	if err != nil {
		fmt.Printf("Failed to execute: %s", err)
		os.Exit(1)
	}
}
