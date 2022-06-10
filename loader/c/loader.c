#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

int main(int argc, char* argv[], char* envp[]) {
    int fd, ret;
    unsigned char buff[1024];
    size_t bread = 0;
    char fname[100];

    if (argc < 2 ) {
        printf("Usage: loader.py <binary> [arguments]\n");
        return 1;
    }

    // Create in-memory file
    fd = memfd_create("", 0);
    if (fd < 0) {
        printf("Error creating in-memory file: %s\n", strerror(errno));
        return 1;
    }
    sprintf(fname, "/proc/self/fd/%d", fd);

    if (strcmp(argv[1], "-") == 0) {
        // Read stdin into in-mem
        while((bread = read(0, buff, sizeof(buff))) > 0) {
            write(fd, buff, bread);
        }
    } else {
        // Read file into in-mem
        FILE *finput = fopen(argv[1], "rb");
        if (finput == NULL) {
            printf("Error opeining file %s: %s\n", argv[1], strerror(errno));
            return 1;
        }
        while ((bread = fread(buff, 1, sizeof(buff), finput)) > 0)
        {
            write(fd, buff, bread);
        }
        fclose(finput);
    }

    // Edit and re-use our argv
    argv[0] = "from_loader";
    for (int i = 1; i < argc; i++) {
        argv[i] = argv[i+1];
    }

    // Execute file
    ret = execve(fname, argv, envp);
    if (ret == -1) {
        printf("Error calling execve: %s\n", strerror(errno));
    }
}
