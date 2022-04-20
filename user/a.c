#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void check(){
    int n_forks = 4;
    int pid;
    int k=0;
    for (int i = 0; i < n_forks; i++) {
    	pid = fork();
        if (pid == 0) {
        
            k = i;
            break;
        }
    }
    
    if (pid==0) {
        while(1){
            printf("this is process %d\n", k);
            sleep(15);
        }
    }
}

void kill_system_dem(int interval, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            kill_sys();
        }
    }
    printf("\n");
}

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            pause_sys(pause_seconds);
        }
    }
    printf("\n");
}

int
main(int argc, char *argv[])
{
    //check();
    pause_system_dem(10, 4, 100);
    //kill_system_dem(10, 100);
    print_stats();


    exit(0);
}