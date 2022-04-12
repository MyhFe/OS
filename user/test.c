#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc ,char** argv){
    int pid = fork();
    if (pid!=0){    //papa
        int pidf = getpid();
        printf("%d %d\n", pidf, pid);
        sleep(50);
        kill_sys();
    } else {
        while (1){
            fprintf(2,"A");       //chiko
            sleep(20);
        }
    }


    // for(int i=0;i<5;i++){
    //     printf("A");
    //     kill_sys();
    // }
    exit(0);
}