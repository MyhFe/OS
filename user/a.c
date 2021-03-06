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
            sleep(100);
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



void test(int num_of_copies, int num_of_intervals, char* test_name, char* num_of_tmpfile){
    char* str = "Hello, my name is Steve Gonzales\nWelcome to my Test File for XV6 Schedulers\nFeel free to put notes ;)";
    int str_size = 102;

    int buff_size = str_size / num_of_intervals;
    char buff [buff_size];
    buff[buff_size - 1] = 0;

    int fd = open(num_of_tmpfile, O_CREATE | O_RDWR);

    for (int i = 0; i < num_of_copies; i++){
        int str_cursor = 0;
        while(str_cursor < str_size){
            //set buffer
            for(int k = 0; k < (buff_size - 1); k++){
                if (str_cursor < str_size){
                    buff[k] = str[str_cursor];
                }
                else{
                    buff[k] = 0 ;
                }
                str_cursor++;
            }
            // Write to file
            write(fd, buff, buff_size);
            //sleep(100);
        }
        printf("pid=%d - %s completed %d/%d copies.\n", getpid(), test_name, (i+1), num_of_copies);
    }
    close(fd);
    unlink(num_of_tmpfile);
}
void run_test(int n_forks) {
    int pid; 
    int child_pid [n_forks];
    for (int i = 0; i < n_forks; i++){
        pid = fork();
        if (pid != 0){
            child_pid[i] = pid;
        }
        else{
            char num_of_tmpfile [2];
            num_of_tmpfile[0] = i - '0';
            num_of_tmpfile[1] = 0;
            char* argv[] = {"env", num_of_tmpfile, 0};
            exec(argv[0], argv);
            exit(0);
        }
    }
    // Wait for all child processes before exiting test
    for (int i = 0; i < n_forks; i++){
        int status;
        wait(&status);
    }
    printf("Father process pid = %d\n", getpid());
    printf("Children processes pid:");
     for (int i = 0; i < n_forks; i++){
        printf("%d ", child_pid[i]);
    }
    printf("\n");
}

void short_test(char* num_of_tmpfile) {
    test(10, 10, "short_test", num_of_tmpfile);
}

void long_test(char* num_of_tmpfile) {
    test(100, 100, "long_test", num_of_tmpfile);
}

int main (int argc, char *argv []){
    // int n_forks = 5;
    // if(argc == 1){
    //     run_test(n_forks);
    //     print_stats();
    // }
    // else if(argc == 2){
    //    short_test(argv[1]);
    // }
    // else{
    //     printf("Error - wrong input - no more then 2 arguments are allowed");
    // }
    env_freq();
    print_stats();
    exit(0);
}
