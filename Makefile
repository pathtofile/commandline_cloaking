.PHONY: all
all: basic_c basic_go dodgy_c dodgy_go preload_go preload_c loader_go injector

basic_c: clean
	gcc -Wall -o ./bin/basic_c ./basic/c/basic.c

basic_go: clean
	go build -o ./bin/basic ./basic/go

dodgy_c: clean
	gcc -Wall -o ./bin/dodgy_c ./dodgy/c/dodgy.c

dodgy_go: clean
	go build -o ./bin/dodgy ./dodgy/go

preload_go: clean
	go build -buildmode=c-shared -o ./bin/preload.so ./preload/go

preload_c: clean
	gcc -Wall -fPIC -shared -o ./bin/preload_c.so ./preload/c/preload.c -ldl

loader_go: clean
	go build -o ./bin/loader ./loader/go

injector: clean
	$(shell \
		nasm -felf64 -o ./bin/shellcode.o ./injector/asm/shellcode.asm && \
		objcopy -O binary --only-section=.text ./bin/shellcode.o ./bin/shellcode.bin && \
		rm ./bin/shellcode.o && \
		go build -o ./bin/injector ./injector/go \
	)

clean:
	rm -rf ./bin
	mkdir -p ./bin
