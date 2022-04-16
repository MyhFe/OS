#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

// void pause_system_dem(int interval, int pause_seconds, int loop_size) {
//     int pid = getpid();
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("pause system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             pause_sys(pause_seconds);
//         }
//     }
//     printf("\n");
// }



int
main(int argc, char *argv[])
{
    // pause_system_dem(10, 10, 100);
    exit(0);
}