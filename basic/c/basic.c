#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>

int main(int argc, char* argv[]) {
    printf("  PID     %d\n", getpid());
    printf("  PPID    %d\n", getppid());
    printf("  argc    %d\n", argc);
    for (int i = 0; i < argc; i++) {
        printf("  argv[%d] %s\n", i, argv[i]);
    }

    printf("  Sleeping for 60 seconds so you can lookup the PID\n");
    sleep(60);

    return 0;
}
