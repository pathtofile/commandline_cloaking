.PHONY: all
all: basic_c basic dodgy_c dodgy preload_c preload loader_py loader_go injector

basic_c: clean
	gcc -Wall -o ./bin/basic_c ./basic/c/basic.c

basic: clean
	go build -o ./bin/basic ./basic/go

dodgy_c: clean
	gcc -Wall -o ./bin/dodgy_c ./dodgy/c/dodgy.c

dodgy: clean
	go build -o ./bin/dodgy ./dodgy/go

preload: clean
	go build -buildmode=c-shared -o ./bin/preload.so ./preload/go
	rm -f ./bin/preload.h

preload_c: clean
	gcc -Wall -fPIC -shared -o ./bin/preload_c.so ./preload/c/preload.c -ldl

loader_go: clean
	go build -o ./bin/loader ./loader/go

loader_py: clean
	cp ./loader/python/loader.py ./bin

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
