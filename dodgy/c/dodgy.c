#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>

int main(int argc, char* argv[]) {
    int err = -1;
    printf("-------- REAL --------\n");
    printf("  PID     %d\n", getpid());
    printf("  PPID    %d\n", getppid());
    printf("  argc    %d\n", argc);
    for (int i = 0; i < argc; i++) {
        printf("  argv[%d] %s\n", i, argv[i]);
    }

    // Double-fork to make parent pid look like PID 1
    pid_t child_pid = fork();
    if (child_pid != 0)
    {
        // First parent, exit
        return 0;
    }
    child_pid = fork();
    if (child_pid != 0)
    {
        // Second parent, exit
        return 0;
    }

    // Use prctl to change /proc/pid/comm
    err = prctl(PR_SET_NAME,"faked\x00",NULL,NULL,NULL);
    if (err < 0) {
        printf("Erorr calling PR_SET_NAME: %s\n", strerror(errno));
        return 1;
    }
    
    // Overwrite address of argv to fool 'ps'
    // This is much easier in C than in Go
    memset(argv[0], 'F', strlen(argv[0]));
    if (argc > 1) {
        memset(argv[1], 'B', strlen(argv[1]));
    }

    // Sleep for a second for parent to be reaped
	// and PID 1 to adopt us
    sleep(1);

    // Print data
    printf("---- FORK & FAKE -----\n");
    printf("  PID     %d\n", getpid());
    printf("  PPID    %d\n", getppid());
    for (int i = 0; i < argc; i++) {
        printf("  argv[%d] %s\n", i, argv[i]);
    }
    printf("----------------------\n");
    printf("Sleeping for 60 seconds so you can lookup the PID\n");
    sleep(60);

    return 0;
}
