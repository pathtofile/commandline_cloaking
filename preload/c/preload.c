// Base of code from: https://gist.github.com/apsun/1e144bf7639b22ff0097171fa0f8c6b1
#define _GNU_SOURCE
#include <stdio.h>
#include <dlfcn.h>
#include <string.h>


// Store the pointer to the real main
static int (*orig_main)(int, char **, char **) = NULL;

// Our hooked version of main
int main_hook(int argc, char **argv, char **envp)
{
    // Overwrite args like in 'dodgy'
    memset(argv[0], 'F', strlen(argv[0]));
    if (argc > 1) {
        memset(argv[1], 'B', strlen(argv[1]));
    }

    // Call real main now
    return orig_main(argc, argv, envp);
}

int __libc_start_main(
    int (*main)(int, char **, char **),
    int argc,
    char **argv,
    int (*init)(int, char **, char **),
    void (*fini)(void),
    void (*rtld_fini)(void),
    void *stack_end)
{
    // Store the pointer to the real main so we can call it later
    orig_main = main;

    // Lookup the real libc function
    typeof(&__libc_start_main) orig_start_main = dlsym(RTLD_NEXT, "__libc_start_main");

    // Let it continue setting things up, then it will call out hooked
    // function once everything is ready to go
    return orig_start_main(main_hook, argc, argv, init, fini, rtld_fini, stack_end);
}
