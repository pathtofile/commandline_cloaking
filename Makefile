.PHONY: all
all: all_go all_c
all_go: basic_go dodgy_go preload_go loader_go injector_go
all_c: basic_c dodgy_c preload_c loader_c
all_nim: basic_nim dodgy_nim loader_nim preload_nim

basic_c:
	gcc -Wall -o ./bin/basic_c ./basic/c/basic.c

basic_go:
	go build -o ./bin/basic ./basic/go

basic_nim:
	nim compile --out:./bin/basic_nim ./basic/nim/basic.nim

dodgy_c:
	gcc -Wall -o ./bin/dodgy_c ./dodgy/c/dodgy.c

dodgy_go:
	go build -o ./bin/dodgy ./dodgy/go

dodgy_nim:
	nim compile --nomain --out:./bin/dodgy_nim ./dodgy/nim/dodgy.nim
	nim compile --nomain --out:./bin/dodgy_nim_small -d:release -d:danger -d:strip --opt:size ./dodgy/nim/dodgy.nim

preload_go:
	go build -buildmode=c-shared -o ./bin/preload.so ./preload/go
	rm -f ./bin/preload.h

preload_c:
	gcc -Wall -fPIC -shared -o ./bin/preload_c.so ./preload/c/preload.c -ldl

preload_nim:
	nim compile --app:lib --out:./bin/preload_nim.so ./preload/nim/preload.nim

loader_go:
	go build -o ./bin/loader ./loader/go

loader_c:
	gcc -Wall -o ./bin/loader_c ./loader/c/loader.c

loader_py:
	cp ./loader/python/loader.py ./bin

loader_nim:
	nim compile --out:./bin/loader_nim ./loader/nim/loader.nim

injector_go:
	$(shell \
		nasm -felf64 -o ./bin/shellcode.o ./injector/asm/shellcode.asm && \
		objcopy -O binary --only-section=.text ./bin/shellcode.o ./bin/shellcode.bin && \
		rm ./bin/shellcode.o && \
		go build -o ./bin/injector ./injector/go \
	)

clean:
	rm -rf ./bin
	mkdir -p ./bin
