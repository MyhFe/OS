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
    // int n_forks = 4;
    // int pid;
    // int k=0;
    // for (int i = 0; i < n_forks; i++) {
    // 	pid = fork();
    //     if (pid == 0) {
        
    //         k = i;
    //         break;
    //     }
    // }
    
    // if (pid==0) {
    //     while(1){
    //         printf("this is process %d\n", k);
    //         sleep(100);
    //     }
    // }
    printf("start\n");
    int a = 0, b = 1;
    for(int i=0;i<2000000;i++){
        int tmp = a;
        a = b;
        b = b+tmp;
    }
    printf("stop\n");
}

void kill_system_dem(int interval, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            kill_system();
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
            pause_system(pause_seconds);
        }
    }
    printf("\n");
}

void env(int size, int interval, char* env_name) {
    int result = 1;
    int loop_size = (int)(10e6);
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % (int)(loop_size / 10e0) == 0) {
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
        	}
        }
        if (i % interval == 0) {
            for(int j=1;j<100;j++){
                result = result * size;
            }
        }
    }
    printf("\n");
}

void env_large() {
    env(10e6, 3, "env_large");
}

void env_freq() {
    env(10e1, 10e1, "env_freq");
}

int
main(int argc, char *argv[])
{
     pause_system_dem(10, 10, 100);
    // kill_system_dem(10, 100);
    print_stats();


    exit(0);
}