
user/_a:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <check>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void check(){
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    int n_forks = 4;
    int pid;
    int k=0;
    for (int i = 0; i < n_forks; i++) {
   c:	4481                	li	s1,0
   e:	4911                	li	s2,4
    	pid = fork();
  10:	00000097          	auipc	ra,0x0
  14:	7d8080e7          	jalr	2008(ra) # 7e8 <fork>
        if (pid == 0) {
  18:	c911                	beqz	a0,2c <check+0x2c>
    for (int i = 0; i < n_forks; i++) {
  1a:	2485                	addiw	s1,s1,1
  1c:	ff249ae3          	bne	s1,s2,10 <check+0x10>
        while(1){
            printf("this is process %d\n", k);
            sleep(100);
        }
    }
}
  20:	60e2                	ld	ra,24(sp)
  22:	6442                	ld	s0,16(sp)
  24:	64a2                	ld	s1,8(sp)
  26:	6902                	ld	s2,0(sp)
  28:	6105                	addi	sp,sp,32
  2a:	8082                	ret
            printf("this is process %d\n", k);
  2c:	00001917          	auipc	s2,0x1
  30:	cfc90913          	addi	s2,s2,-772 # d28 <malloc+0xea>
  34:	85a6                	mv	a1,s1
  36:	854a                	mv	a0,s2
  38:	00001097          	auipc	ra,0x1
  3c:	b48080e7          	jalr	-1208(ra) # b80 <printf>
            sleep(100);
  40:	06400513          	li	a0,100
  44:	00001097          	auipc	ra,0x1
  48:	83c080e7          	jalr	-1988(ra) # 880 <sleep>
        while(1){
  4c:	b7e5                	j	34 <check+0x34>

000000000000004e <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  4e:	7139                	addi	sp,sp,-64
  50:	fc06                	sd	ra,56(sp)
  52:	f822                	sd	s0,48(sp)
  54:	f426                	sd	s1,40(sp)
  56:	f04a                	sd	s2,32(sp)
  58:	ec4e                	sd	s3,24(sp)
  5a:	e852                	sd	s4,16(sp)
  5c:	e456                	sd	s5,8(sp)
  5e:	e05a                	sd	s6,0(sp)
  60:	0080                	addi	s0,sp,64
  62:	8a2a                	mv	s4,a0
  64:	892e                	mv	s2,a1
    int pid = getpid();
  66:	00001097          	auipc	ra,0x1
  6a:	80a080e7          	jalr	-2038(ra) # 870 <getpid>
    for (int i = 0; i < loop_size; i++) {
  6e:	05205a63          	blez	s2,c2 <kill_system_dem+0x74>
  72:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  74:	01f9599b          	srliw	s3,s2,0x1f
  78:	012989bb          	addw	s3,s3,s2
  7c:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  80:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  82:	00001b17          	auipc	s6,0x1
  86:	cbeb0b13          	addi	s6,s6,-834 # d40 <malloc+0x102>
  8a:	a031                	j	96 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  8c:	02998663          	beq	s3,s1,b8 <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  90:	2485                	addiw	s1,s1,1
  92:	02990863          	beq	s2,s1,c2 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  96:	0344e7bb          	remw	a5,s1,s4
  9a:	fbed                	bnez	a5,8c <kill_system_dem+0x3e>
  9c:	00000097          	auipc	ra,0x0
  a0:	7d4080e7          	jalr	2004(ra) # 870 <getpid>
  a4:	ff5514e3          	bne	a0,s5,8c <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  a8:	864a                	mv	a2,s2
  aa:	85a6                	mv	a1,s1
  ac:	855a                	mv	a0,s6
  ae:	00001097          	auipc	ra,0x1
  b2:	ad2080e7          	jalr	-1326(ra) # b80 <printf>
  b6:	bfd9                	j	8c <kill_system_dem+0x3e>
            kill_system();
  b8:	00000097          	auipc	ra,0x0
  bc:	7d8080e7          	jalr	2008(ra) # 890 <kill_system>
  c0:	bfc1                	j	90 <kill_system_dem+0x42>
        }
    }
    printf("\n");
  c2:	00001517          	auipc	a0,0x1
  c6:	c9e50513          	addi	a0,a0,-866 # d60 <malloc+0x122>
  ca:	00001097          	auipc	ra,0x1
  ce:	ab6080e7          	jalr	-1354(ra) # b80 <printf>
}
  d2:	70e2                	ld	ra,56(sp)
  d4:	7442                	ld	s0,48(sp)
  d6:	74a2                	ld	s1,40(sp)
  d8:	7902                	ld	s2,32(sp)
  da:	69e2                	ld	s3,24(sp)
  dc:	6a42                	ld	s4,16(sp)
  de:	6aa2                	ld	s5,8(sp)
  e0:	6b02                	ld	s6,0(sp)
  e2:	6121                	addi	sp,sp,64
  e4:	8082                	ret

00000000000000e6 <pause_system_dem>:

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
  e6:	715d                	addi	sp,sp,-80
  e8:	e486                	sd	ra,72(sp)
  ea:	e0a2                	sd	s0,64(sp)
  ec:	fc26                	sd	s1,56(sp)
  ee:	f84a                	sd	s2,48(sp)
  f0:	f44e                	sd	s3,40(sp)
  f2:	f052                	sd	s4,32(sp)
  f4:	ec56                	sd	s5,24(sp)
  f6:	e85a                	sd	s6,16(sp)
  f8:	e45e                	sd	s7,8(sp)
  fa:	0880                	addi	s0,sp,80
  fc:	8a2a                	mv	s4,a0
  fe:	8b2e                	mv	s6,a1
 100:	8932                	mv	s2,a2
    int pid = getpid();
 102:	00000097          	auipc	ra,0x0
 106:	76e080e7          	jalr	1902(ra) # 870 <getpid>
    for (int i = 0; i < loop_size; i++) {
 10a:	05205b63          	blez	s2,160 <pause_system_dem+0x7a>
 10e:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
 110:	01f9599b          	srliw	s3,s2,0x1f
 114:	012989bb          	addw	s3,s3,s2
 118:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
 11c:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
 11e:	00001b97          	auipc	s7,0x1
 122:	c4ab8b93          	addi	s7,s7,-950 # d68 <malloc+0x12a>
 126:	a031                	j	132 <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
 128:	02998663          	beq	s3,s1,154 <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
 12c:	2485                	addiw	s1,s1,1
 12e:	02990963          	beq	s2,s1,160 <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
 132:	0344e7bb          	remw	a5,s1,s4
 136:	fbed                	bnez	a5,128 <pause_system_dem+0x42>
 138:	00000097          	auipc	ra,0x0
 13c:	738080e7          	jalr	1848(ra) # 870 <getpid>
 140:	ff5514e3          	bne	a0,s5,128 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
 144:	864a                	mv	a2,s2
 146:	85a6                	mv	a1,s1
 148:	855e                	mv	a0,s7
 14a:	00001097          	auipc	ra,0x1
 14e:	a36080e7          	jalr	-1482(ra) # b80 <printf>
 152:	bfd9                	j	128 <pause_system_dem+0x42>
            pause_system(pause_seconds);
 154:	855a                	mv	a0,s6
 156:	00000097          	auipc	ra,0x0
 15a:	742080e7          	jalr	1858(ra) # 898 <pause_system>
 15e:	b7f9                	j	12c <pause_system_dem+0x46>
        }
    }
    printf("\n");
 160:	00001517          	auipc	a0,0x1
 164:	c0050513          	addi	a0,a0,-1024 # d60 <malloc+0x122>
 168:	00001097          	auipc	ra,0x1
 16c:	a18080e7          	jalr	-1512(ra) # b80 <printf>
}
 170:	60a6                	ld	ra,72(sp)
 172:	6406                	ld	s0,64(sp)
 174:	74e2                	ld	s1,56(sp)
 176:	7942                	ld	s2,48(sp)
 178:	79a2                	ld	s3,40(sp)
 17a:	7a02                	ld	s4,32(sp)
 17c:	6ae2                	ld	s5,24(sp)
 17e:	6b42                	ld	s6,16(sp)
 180:	6ba2                	ld	s7,8(sp)
 182:	6161                	addi	sp,sp,80
 184:	8082                	ret

0000000000000186 <env>:

void env(int size, int interval, char* env_name) {
 186:	711d                	addi	sp,sp,-96
 188:	ec86                	sd	ra,88(sp)
 18a:	e8a2                	sd	s0,80(sp)
 18c:	e4a6                	sd	s1,72(sp)
 18e:	e0ca                	sd	s2,64(sp)
 190:	fc4e                	sd	s3,56(sp)
 192:	f852                	sd	s4,48(sp)
 194:	f456                	sd	s5,40(sp)
 196:	f05a                	sd	s6,32(sp)
 198:	ec5e                	sd	s7,24(sp)
 19a:	e862                	sd	s8,16(sp)
 19c:	e466                	sd	s9,8(sp)
 19e:	1080                	addi	s0,sp,96
 1a0:	8a2e                	mv	s4,a1
 1a2:	8b32                	mv	s6,a2
    int result = 1;
    int loop_size = (int)(10e6);
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 1a4:	00000097          	auipc	ra,0x0
 1a8:	644080e7          	jalr	1604(ra) # 7e8 <fork>
 1ac:	00000097          	auipc	ra,0x0
 1b0:	63c080e7          	jalr	1596(ra) # 7e8 <fork>
 1b4:	8aaa                	mv	s5,a0
    }
    for (int i = 0; i < loop_size; i++) {
 1b6:	4481                	li	s1,0
        if (i % (int)(loop_size / 10e0) == 0) {
 1b8:	000f49b7          	lui	s3,0xf4
 1bc:	2409899b          	addiw	s3,s3,576
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
 1c0:	00001c97          	auipc	s9,0x1
 1c4:	be0c8c93          	addi	s9,s9,-1056 # da0 <malloc+0x162>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1c8:	00989937          	lui	s2,0x989
 1cc:	68090913          	addi	s2,s2,1664 # 989680 <__global_pointer$+0x987fa7>
 1d0:	00001c17          	auipc	s8,0x1
 1d4:	bb8c0c13          	addi	s8,s8,-1096 # d88 <malloc+0x14a>
 1d8:	06300b93          	li	s7,99
 1dc:	a821                	j	1f4 <env+0x6e>
        		printf(" ");
 1de:	8566                	mv	a0,s9
 1e0:	00001097          	auipc	ra,0x1
 1e4:	9a0080e7          	jalr	-1632(ra) # b80 <printf>
        	}
        }
        if (i % interval == 0) {
 1e8:	0344e7bb          	remw	a5,s1,s4
 1ec:	c395                	beqz	a5,210 <env+0x8a>
    for (int i = 0; i < loop_size; i++) {
 1ee:	2485                	addiw	s1,s1,1
 1f0:	03248463          	beq	s1,s2,218 <env+0x92>
        if (i % (int)(loop_size / 10e0) == 0) {
 1f4:	0334e7bb          	remw	a5,s1,s3
 1f8:	fbe5                	bnez	a5,1e8 <env+0x62>
        	if (pid == 0) {
 1fa:	fe0a92e3          	bnez	s5,1de <env+0x58>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1fe:	86ca                	mv	a3,s2
 200:	8626                	mv	a2,s1
 202:	85da                	mv	a1,s6
 204:	8562                	mv	a0,s8
 206:	00001097          	auipc	ra,0x1
 20a:	97a080e7          	jalr	-1670(ra) # b80 <printf>
 20e:	bfe9                	j	1e8 <env+0x62>
 210:	87de                	mv	a5,s7
            for(int j=1;j<100;j++){
 212:	37fd                	addiw	a5,a5,-1
 214:	fffd                	bnez	a5,212 <env+0x8c>
 216:	bfe1                	j	1ee <env+0x68>
                result = result * size;
            }
        }
    }
    printf("\n");
 218:	00001517          	auipc	a0,0x1
 21c:	b4850513          	addi	a0,a0,-1208 # d60 <malloc+0x122>
 220:	00001097          	auipc	ra,0x1
 224:	960080e7          	jalr	-1696(ra) # b80 <printf>
}
 228:	60e6                	ld	ra,88(sp)
 22a:	6446                	ld	s0,80(sp)
 22c:	64a6                	ld	s1,72(sp)
 22e:	6906                	ld	s2,64(sp)
 230:	79e2                	ld	s3,56(sp)
 232:	7a42                	ld	s4,48(sp)
 234:	7aa2                	ld	s5,40(sp)
 236:	7b02                	ld	s6,32(sp)
 238:	6be2                	ld	s7,24(sp)
 23a:	6c42                	ld	s8,16(sp)
 23c:	6ca2                	ld	s9,8(sp)
 23e:	6125                	addi	sp,sp,96
 240:	8082                	ret

0000000000000242 <env_large>:

void env_large() {
 242:	1141                	addi	sp,sp,-16
 244:	e406                	sd	ra,8(sp)
 246:	e022                	sd	s0,0(sp)
 248:	0800                	addi	s0,sp,16
    env(10e6, 3, "env_large");
 24a:	00001617          	auipc	a2,0x1
 24e:	b5e60613          	addi	a2,a2,-1186 # da8 <malloc+0x16a>
 252:	458d                	li	a1,3
 254:	00989537          	lui	a0,0x989
 258:	68050513          	addi	a0,a0,1664 # 989680 <__global_pointer$+0x987fa7>
 25c:	00000097          	auipc	ra,0x0
 260:	f2a080e7          	jalr	-214(ra) # 186 <env>
}
 264:	60a2                	ld	ra,8(sp)
 266:	6402                	ld	s0,0(sp)
 268:	0141                	addi	sp,sp,16
 26a:	8082                	ret

000000000000026c <env_freq>:

void env_freq() {
 26c:	1141                	addi	sp,sp,-16
 26e:	e406                	sd	ra,8(sp)
 270:	e022                	sd	s0,0(sp)
 272:	0800                	addi	s0,sp,16
    env(10e1, 10e1, "env_freq");
 274:	00001617          	auipc	a2,0x1
 278:	b4460613          	addi	a2,a2,-1212 # db8 <malloc+0x17a>
 27c:	06400593          	li	a1,100
 280:	06400513          	li	a0,100
 284:	00000097          	auipc	ra,0x0
 288:	f02080e7          	jalr	-254(ra) # 186 <env>
}
 28c:	60a2                	ld	ra,8(sp)
 28e:	6402                	ld	s0,0(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret

0000000000000294 <test>:



void test(int num_of_copies, int num_of_intervals, char* test_name, char* num_of_tmpfile){
 294:	7119                	addi	sp,sp,-128
 296:	fc86                	sd	ra,120(sp)
 298:	f8a2                	sd	s0,112(sp)
 29a:	f4a6                	sd	s1,104(sp)
 29c:	f0ca                	sd	s2,96(sp)
 29e:	ecce                	sd	s3,88(sp)
 2a0:	e8d2                	sd	s4,80(sp)
 2a2:	e4d6                	sd	s5,72(sp)
 2a4:	e0da                	sd	s6,64(sp)
 2a6:	fc5e                	sd	s7,56(sp)
 2a8:	f862                	sd	s8,48(sp)
 2aa:	f466                	sd	s9,40(sp)
 2ac:	f06a                	sd	s10,32(sp)
 2ae:	ec6e                	sd	s11,24(sp)
 2b0:	0100                	addi	s0,sp,128
 2b2:	8d2a                	mv	s10,a0
 2b4:	f8c43423          	sd	a2,-120(s0)
 2b8:	f8d43023          	sd	a3,-128(s0)
    char* str = "Hello, my name is Steve Gonzales\nWelcome to my Test File for XV6 Schedulers\nFeel free to put notes ;)";
    int str_size = 102;

    int buff_size = str_size / num_of_intervals;
 2bc:	06600913          	li	s2,102
 2c0:	02b9493b          	divw	s2,s2,a1
 2c4:	00090b1b          	sext.w	s6,s2
    char buff [buff_size];
 2c8:	00fb0793          	addi	a5,s6,15
 2cc:	9bc1                	andi	a5,a5,-16
 2ce:	40f10133          	sub	sp,sp,a5
    buff[buff_size - 1] = 0;
 2d2:	397d                	addiw	s2,s2,-1
 2d4:	012107b3          	add	a5,sp,s2
 2d8:	00078023          	sb	zero,0(a5)

    int fd = open(num_of_tmpfile, O_CREATE | O_RDWR);
 2dc:	20200593          	li	a1,514
 2e0:	8536                	mv	a0,a3
 2e2:	00000097          	auipc	ra,0x0
 2e6:	54e080e7          	jalr	1358(ra) # 830 <open>
 2ea:	8aaa                	mv	s5,a0

    for (int i = 0; i < num_of_copies; i++){
 2ec:	07a05b63          	blez	s10,362 <test+0xce>
 2f0:	8a0a                	mv	s4,sp
 2f2:	4c81                	li	s9,0
 2f4:	00001c17          	auipc	s8,0x1
 2f8:	ad4c0c13          	addi	s8,s8,-1324 # dc8 <malloc+0x18a>
        int str_cursor = 0;
        while(str_cursor < str_size){
            //set buffer
            for(int k = 0; k < (buff_size - 1); k++){
                if (str_cursor < str_size){
 2fc:	06500993          	li	s3,101
            for(int k = 0; k < (buff_size - 1); k++){
 300:	4b85                	li	s7,1
            }
            // Write to file
            write(fd, buff, buff_size);
            //sleep(100);
        }
        printf("pid=%d - %s completed %d/%d copies.\n", getpid(), test_name, (i+1), num_of_copies);
 302:	00001d97          	auipc	s11,0x1
 306:	b2ed8d93          	addi	s11,s11,-1234 # e30 <malloc+0x1f2>
 30a:	a0c1                	j	3ca <test+0x136>
                    buff[k] = 0 ;
 30c:	00070023          	sb	zero,0(a4)
            for(int k = 0; k < (buff_size - 1); k++){
 310:	0007861b          	sext.w	a2,a5
 314:	09265363          	bge	a2,s2,39a <test+0x106>
 318:	2785                	addiw	a5,a5,1
 31a:	0705                	addi	a4,a4,1
 31c:	0685                	addi	a3,a3,1
                if (str_cursor < str_size){
 31e:	00f5863b          	addw	a2,a1,a5
 322:	fec9c5e3          	blt	s3,a2,30c <test+0x78>
                    buff[k] = str[str_cursor];
 326:	0006c603          	lbu	a2,0(a3)
 32a:	00c70023          	sb	a2,0(a4)
                str_cursor++;
 32e:	00a784bb          	addw	s1,a5,a0
            for(int k = 0; k < (buff_size - 1); k++){
 332:	0007861b          	sext.w	a2,a5
 336:	ff2641e3          	blt	a2,s2,318 <test+0x84>
            write(fd, buff, buff_size);
 33a:	865a                	mv	a2,s6
 33c:	85d2                	mv	a1,s4
 33e:	8556                	mv	a0,s5
 340:	00000097          	auipc	ra,0x0
 344:	4d0080e7          	jalr	1232(ra) # 810 <write>
        while(str_cursor < str_size){
 348:	0699c063          	blt	s3,s1,3a8 <test+0x114>
            for(int k = 0; k < (buff_size - 1); k++){
 34c:	ff2057e3          	blez	s2,33a <test+0xa6>
 350:	8752                	mv	a4,s4
 352:	018486b3          	add	a3,s1,s8
 356:	87de                	mv	a5,s7
 358:	0004851b          	sext.w	a0,s1
                if (str_cursor < str_size){
 35c:	fff4859b          	addiw	a1,s1,-1
 360:	bf7d                	j	31e <test+0x8a>
    }
    close(fd);
 362:	8556                	mv	a0,s5
 364:	00000097          	auipc	ra,0x0
 368:	4b4080e7          	jalr	1204(ra) # 818 <close>
    unlink(num_of_tmpfile);
 36c:	f8043503          	ld	a0,-128(s0)
 370:	00000097          	auipc	ra,0x0
 374:	4d0080e7          	jalr	1232(ra) # 840 <unlink>
}
 378:	f8040113          	addi	sp,s0,-128
 37c:	70e6                	ld	ra,120(sp)
 37e:	7446                	ld	s0,112(sp)
 380:	74a6                	ld	s1,104(sp)
 382:	7906                	ld	s2,96(sp)
 384:	69e6                	ld	s3,88(sp)
 386:	6a46                	ld	s4,80(sp)
 388:	6aa6                	ld	s5,72(sp)
 38a:	6b06                	ld	s6,64(sp)
 38c:	7be2                	ld	s7,56(sp)
 38e:	7c42                	ld	s8,48(sp)
 390:	7ca2                	ld	s9,40(sp)
 392:	7d02                	ld	s10,32(sp)
 394:	6de2                	ld	s11,24(sp)
 396:	6109                	addi	sp,sp,128
 398:	8082                	ret
            write(fd, buff, buff_size);
 39a:	865a                	mv	a2,s6
 39c:	85d2                	mv	a1,s4
 39e:	8556                	mv	a0,s5
 3a0:	00000097          	auipc	ra,0x0
 3a4:	470080e7          	jalr	1136(ra) # 810 <write>
        printf("pid=%d - %s completed %d/%d copies.\n", getpid(), test_name, (i+1), num_of_copies);
 3a8:	00000097          	auipc	ra,0x0
 3ac:	4c8080e7          	jalr	1224(ra) # 870 <getpid>
 3b0:	85aa                	mv	a1,a0
 3b2:	2c85                	addiw	s9,s9,1
 3b4:	876a                	mv	a4,s10
 3b6:	86e6                	mv	a3,s9
 3b8:	f8843603          	ld	a2,-120(s0)
 3bc:	856e                	mv	a0,s11
 3be:	00000097          	auipc	ra,0x0
 3c2:	7c2080e7          	jalr	1986(ra) # b80 <printf>
    for (int i = 0; i < num_of_copies; i++){
 3c6:	f9ac8ee3          	beq	s9,s10,362 <test+0xce>
        int str_cursor = 0;
 3ca:	4481                	li	s1,0
 3cc:	b741                	j	34c <test+0xb8>

00000000000003ce <run_test>:
void run_test(int n_forks) {
 3ce:	711d                	addi	sp,sp,-96
 3d0:	ec86                	sd	ra,88(sp)
 3d2:	e8a2                	sd	s0,80(sp)
 3d4:	e4a6                	sd	s1,72(sp)
 3d6:	e0ca                	sd	s2,64(sp)
 3d8:	fc4e                	sd	s3,56(sp)
 3da:	f852                	sd	s4,48(sp)
 3dc:	f456                	sd	s5,40(sp)
 3de:	1080                	addi	s0,sp,96
    int pid; 
    int child_pid [n_forks];
 3e0:	00251793          	slli	a5,a0,0x2
 3e4:	07bd                	addi	a5,a5,15
 3e6:	9bc1                	andi	a5,a5,-16
 3e8:	40f10133          	sub	sp,sp,a5
    for (int i = 0; i < n_forks; i++){
 3ec:	0ea05863          	blez	a0,4dc <run_test+0x10e>
 3f0:	8aaa                	mv	s5,a0
 3f2:	8a0a                	mv	s4,sp
 3f4:	89d2                	mv	s3,s4
 3f6:	84d2                	mv	s1,s4
 3f8:	4901                	li	s2,0
 3fa:	a011                	j	3fe <run_test+0x30>
 3fc:	893e                	mv	s2,a5
        pid = fork();
 3fe:	00000097          	auipc	ra,0x0
 402:	3ea080e7          	jalr	1002(ra) # 7e8 <fork>
        if (pid != 0){
 406:	cd51                	beqz	a0,4a2 <run_test+0xd4>
            child_pid[i] = pid;
 408:	c088                	sw	a0,0(s1)
    for (int i = 0; i < n_forks; i++){
 40a:	0019079b          	addiw	a5,s2,1
 40e:	0491                	addi	s1,s1,4
 410:	fefa96e3          	bne	s5,a5,3fc <run_test+0x2e>
 414:	4481                	li	s1,0
        }
    }
    // Wait for all child processes before exiting test
    for (int i = 0; i < n_forks; i++){
        int status;
        wait(&status);
 416:	fa840513          	addi	a0,s0,-88
 41a:	00000097          	auipc	ra,0x0
 41e:	3de080e7          	jalr	990(ra) # 7f8 <wait>
    for (int i = 0; i < n_forks; i++){
 422:	87a6                	mv	a5,s1
 424:	2485                	addiw	s1,s1,1
 426:	ff2798e3          	bne	a5,s2,416 <run_test+0x48>
    }
    printf("Father process pid = %d\n", getpid());
 42a:	00000097          	auipc	ra,0x0
 42e:	446080e7          	jalr	1094(ra) # 870 <getpid>
 432:	85aa                	mv	a1,a0
 434:	00001517          	auipc	a0,0x1
 438:	a3450513          	addi	a0,a0,-1484 # e68 <malloc+0x22a>
 43c:	00000097          	auipc	ra,0x0
 440:	744080e7          	jalr	1860(ra) # b80 <printf>
    printf("Children processes pid:");
 444:	00001517          	auipc	a0,0x1
 448:	a4450513          	addi	a0,a0,-1468 # e88 <malloc+0x24a>
 44c:	00000097          	auipc	ra,0x0
 450:	734080e7          	jalr	1844(ra) # b80 <printf>
     for (int i = 0; i < n_forks; i++){
 454:	02091793          	slli	a5,s2,0x20
 458:	9381                	srli	a5,a5,0x20
 45a:	0785                	addi	a5,a5,1
 45c:	078a                	slli	a5,a5,0x2
 45e:	9a3e                	add	s4,s4,a5
        printf("%d ", child_pid[i]);
 460:	00001497          	auipc	s1,0x1
 464:	a0048493          	addi	s1,s1,-1536 # e60 <malloc+0x222>
 468:	0009a583          	lw	a1,0(s3) # f4000 <__global_pointer$+0xf2927>
 46c:	8526                	mv	a0,s1
 46e:	00000097          	auipc	ra,0x0
 472:	712080e7          	jalr	1810(ra) # b80 <printf>
     for (int i = 0; i < n_forks; i++){
 476:	0991                	addi	s3,s3,4
 478:	ff3a18e3          	bne	s4,s3,468 <run_test+0x9a>
    }
    printf("\n");
 47c:	00001517          	auipc	a0,0x1
 480:	8e450513          	addi	a0,a0,-1820 # d60 <malloc+0x122>
 484:	00000097          	auipc	ra,0x0
 488:	6fc080e7          	jalr	1788(ra) # b80 <printf>
}
 48c:	fa040113          	addi	sp,s0,-96
 490:	60e6                	ld	ra,88(sp)
 492:	6446                	ld	s0,80(sp)
 494:	64a6                	ld	s1,72(sp)
 496:	6906                	ld	s2,64(sp)
 498:	79e2                	ld	s3,56(sp)
 49a:	7a42                	ld	s4,48(sp)
 49c:	7aa2                	ld	s5,40(sp)
 49e:	6125                	addi	sp,sp,96
 4a0:	8082                	ret
            num_of_tmpfile[0] = i - '0';
 4a2:	fd09091b          	addiw	s2,s2,-48
 4a6:	fb240023          	sb	s2,-96(s0)
            num_of_tmpfile[1] = 0;
 4aa:	fa0400a3          	sb	zero,-95(s0)
            char* argv[] = {"env", num_of_tmpfile, 0};
 4ae:	00001517          	auipc	a0,0x1
 4b2:	9aa50513          	addi	a0,a0,-1622 # e58 <malloc+0x21a>
 4b6:	faa43423          	sd	a0,-88(s0)
 4ba:	fa040793          	addi	a5,s0,-96
 4be:	faf43823          	sd	a5,-80(s0)
 4c2:	fa043c23          	sd	zero,-72(s0)
            exec(argv[0], argv);
 4c6:	fa840593          	addi	a1,s0,-88
 4ca:	00000097          	auipc	ra,0x0
 4ce:	35e080e7          	jalr	862(ra) # 828 <exec>
            exit(0);
 4d2:	4501                	li	a0,0
 4d4:	00000097          	auipc	ra,0x0
 4d8:	31c080e7          	jalr	796(ra) # 7f0 <exit>
    printf("Father process pid = %d\n", getpid());
 4dc:	00000097          	auipc	ra,0x0
 4e0:	394080e7          	jalr	916(ra) # 870 <getpid>
 4e4:	85aa                	mv	a1,a0
 4e6:	00001517          	auipc	a0,0x1
 4ea:	98250513          	addi	a0,a0,-1662 # e68 <malloc+0x22a>
 4ee:	00000097          	auipc	ra,0x0
 4f2:	692080e7          	jalr	1682(ra) # b80 <printf>
    printf("Children processes pid:");
 4f6:	00001517          	auipc	a0,0x1
 4fa:	99250513          	addi	a0,a0,-1646 # e88 <malloc+0x24a>
 4fe:	00000097          	auipc	ra,0x0
 502:	682080e7          	jalr	1666(ra) # b80 <printf>
     for (int i = 0; i < n_forks; i++){
 506:	bf9d                	j	47c <run_test+0xae>

0000000000000508 <short_test>:

void short_test(char* num_of_tmpfile) {
 508:	1141                	addi	sp,sp,-16
 50a:	e406                	sd	ra,8(sp)
 50c:	e022                	sd	s0,0(sp)
 50e:	0800                	addi	s0,sp,16
 510:	86aa                	mv	a3,a0
    test(10, 10, "short_test", num_of_tmpfile);
 512:	00001617          	auipc	a2,0x1
 516:	98e60613          	addi	a2,a2,-1650 # ea0 <malloc+0x262>
 51a:	45a9                	li	a1,10
 51c:	4529                	li	a0,10
 51e:	00000097          	auipc	ra,0x0
 522:	d76080e7          	jalr	-650(ra) # 294 <test>
}
 526:	60a2                	ld	ra,8(sp)
 528:	6402                	ld	s0,0(sp)
 52a:	0141                	addi	sp,sp,16
 52c:	8082                	ret

000000000000052e <long_test>:

void long_test(char* num_of_tmpfile) {
 52e:	1141                	addi	sp,sp,-16
 530:	e406                	sd	ra,8(sp)
 532:	e022                	sd	s0,0(sp)
 534:	0800                	addi	s0,sp,16
 536:	86aa                	mv	a3,a0
    test(100, 100, "long_test", num_of_tmpfile);
 538:	00001617          	auipc	a2,0x1
 53c:	97860613          	addi	a2,a2,-1672 # eb0 <malloc+0x272>
 540:	06400593          	li	a1,100
 544:	06400513          	li	a0,100
 548:	00000097          	auipc	ra,0x0
 54c:	d4c080e7          	jalr	-692(ra) # 294 <test>
}
 550:	60a2                	ld	ra,8(sp)
 552:	6402                	ld	s0,0(sp)
 554:	0141                	addi	sp,sp,16
 556:	8082                	ret

0000000000000558 <main>:

int main (int argc, char *argv []){
 558:	1141                	addi	sp,sp,-16
 55a:	e406                	sd	ra,8(sp)
 55c:	e022                	sd	s0,0(sp)
 55e:	0800                	addi	s0,sp,16
    //    short_test(argv[1]);
    // }
    // else{
    //     printf("Error - wrong input - no more then 2 arguments are allowed");
    // }
    env_freq();
 560:	00000097          	auipc	ra,0x0
 564:	d0c080e7          	jalr	-756(ra) # 26c <env_freq>
    print_stats();
 568:	00000097          	auipc	ra,0x0
 56c:	338080e7          	jalr	824(ra) # 8a0 <print_stats>
    exit(0);
 570:	4501                	li	a0,0
 572:	00000097          	auipc	ra,0x0
 576:	27e080e7          	jalr	638(ra) # 7f0 <exit>

000000000000057a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 57a:	1141                	addi	sp,sp,-16
 57c:	e422                	sd	s0,8(sp)
 57e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 580:	87aa                	mv	a5,a0
 582:	0585                	addi	a1,a1,1
 584:	0785                	addi	a5,a5,1
 586:	fff5c703          	lbu	a4,-1(a1)
 58a:	fee78fa3          	sb	a4,-1(a5)
 58e:	fb75                	bnez	a4,582 <strcpy+0x8>
    ;
  return os;
}
 590:	6422                	ld	s0,8(sp)
 592:	0141                	addi	sp,sp,16
 594:	8082                	ret

0000000000000596 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 596:	1141                	addi	sp,sp,-16
 598:	e422                	sd	s0,8(sp)
 59a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 59c:	00054783          	lbu	a5,0(a0)
 5a0:	cb91                	beqz	a5,5b4 <strcmp+0x1e>
 5a2:	0005c703          	lbu	a4,0(a1)
 5a6:	00f71763          	bne	a4,a5,5b4 <strcmp+0x1e>
    p++, q++;
 5aa:	0505                	addi	a0,a0,1
 5ac:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 5ae:	00054783          	lbu	a5,0(a0)
 5b2:	fbe5                	bnez	a5,5a2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 5b4:	0005c503          	lbu	a0,0(a1)
}
 5b8:	40a7853b          	subw	a0,a5,a0
 5bc:	6422                	ld	s0,8(sp)
 5be:	0141                	addi	sp,sp,16
 5c0:	8082                	ret

00000000000005c2 <strlen>:

uint
strlen(const char *s)
{
 5c2:	1141                	addi	sp,sp,-16
 5c4:	e422                	sd	s0,8(sp)
 5c6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 5c8:	00054783          	lbu	a5,0(a0)
 5cc:	cf91                	beqz	a5,5e8 <strlen+0x26>
 5ce:	0505                	addi	a0,a0,1
 5d0:	87aa                	mv	a5,a0
 5d2:	4685                	li	a3,1
 5d4:	9e89                	subw	a3,a3,a0
 5d6:	00f6853b          	addw	a0,a3,a5
 5da:	0785                	addi	a5,a5,1
 5dc:	fff7c703          	lbu	a4,-1(a5)
 5e0:	fb7d                	bnez	a4,5d6 <strlen+0x14>
    ;
  return n;
}
 5e2:	6422                	ld	s0,8(sp)
 5e4:	0141                	addi	sp,sp,16
 5e6:	8082                	ret
  for(n = 0; s[n]; n++)
 5e8:	4501                	li	a0,0
 5ea:	bfe5                	j	5e2 <strlen+0x20>

00000000000005ec <memset>:

void*
memset(void *dst, int c, uint n)
{
 5ec:	1141                	addi	sp,sp,-16
 5ee:	e422                	sd	s0,8(sp)
 5f0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 5f2:	ce09                	beqz	a2,60c <memset+0x20>
 5f4:	87aa                	mv	a5,a0
 5f6:	fff6071b          	addiw	a4,a2,-1
 5fa:	1702                	slli	a4,a4,0x20
 5fc:	9301                	srli	a4,a4,0x20
 5fe:	0705                	addi	a4,a4,1
 600:	972a                	add	a4,a4,a0
    cdst[i] = c;
 602:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 606:	0785                	addi	a5,a5,1
 608:	fee79de3          	bne	a5,a4,602 <memset+0x16>
  }
  return dst;
}
 60c:	6422                	ld	s0,8(sp)
 60e:	0141                	addi	sp,sp,16
 610:	8082                	ret

0000000000000612 <strchr>:

char*
strchr(const char *s, char c)
{
 612:	1141                	addi	sp,sp,-16
 614:	e422                	sd	s0,8(sp)
 616:	0800                	addi	s0,sp,16
  for(; *s; s++)
 618:	00054783          	lbu	a5,0(a0)
 61c:	cb99                	beqz	a5,632 <strchr+0x20>
    if(*s == c)
 61e:	00f58763          	beq	a1,a5,62c <strchr+0x1a>
  for(; *s; s++)
 622:	0505                	addi	a0,a0,1
 624:	00054783          	lbu	a5,0(a0)
 628:	fbfd                	bnez	a5,61e <strchr+0xc>
      return (char*)s;
  return 0;
 62a:	4501                	li	a0,0
}
 62c:	6422                	ld	s0,8(sp)
 62e:	0141                	addi	sp,sp,16
 630:	8082                	ret
  return 0;
 632:	4501                	li	a0,0
 634:	bfe5                	j	62c <strchr+0x1a>

0000000000000636 <gets>:

char*
gets(char *buf, int max)
{
 636:	711d                	addi	sp,sp,-96
 638:	ec86                	sd	ra,88(sp)
 63a:	e8a2                	sd	s0,80(sp)
 63c:	e4a6                	sd	s1,72(sp)
 63e:	e0ca                	sd	s2,64(sp)
 640:	fc4e                	sd	s3,56(sp)
 642:	f852                	sd	s4,48(sp)
 644:	f456                	sd	s5,40(sp)
 646:	f05a                	sd	s6,32(sp)
 648:	ec5e                	sd	s7,24(sp)
 64a:	1080                	addi	s0,sp,96
 64c:	8baa                	mv	s7,a0
 64e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 650:	892a                	mv	s2,a0
 652:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 654:	4aa9                	li	s5,10
 656:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 658:	89a6                	mv	s3,s1
 65a:	2485                	addiw	s1,s1,1
 65c:	0344d863          	bge	s1,s4,68c <gets+0x56>
    cc = read(0, &c, 1);
 660:	4605                	li	a2,1
 662:	faf40593          	addi	a1,s0,-81
 666:	4501                	li	a0,0
 668:	00000097          	auipc	ra,0x0
 66c:	1a0080e7          	jalr	416(ra) # 808 <read>
    if(cc < 1)
 670:	00a05e63          	blez	a0,68c <gets+0x56>
    buf[i++] = c;
 674:	faf44783          	lbu	a5,-81(s0)
 678:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 67c:	01578763          	beq	a5,s5,68a <gets+0x54>
 680:	0905                	addi	s2,s2,1
 682:	fd679be3          	bne	a5,s6,658 <gets+0x22>
  for(i=0; i+1 < max; ){
 686:	89a6                	mv	s3,s1
 688:	a011                	j	68c <gets+0x56>
 68a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 68c:	99de                	add	s3,s3,s7
 68e:	00098023          	sb	zero,0(s3)
  return buf;
}
 692:	855e                	mv	a0,s7
 694:	60e6                	ld	ra,88(sp)
 696:	6446                	ld	s0,80(sp)
 698:	64a6                	ld	s1,72(sp)
 69a:	6906                	ld	s2,64(sp)
 69c:	79e2                	ld	s3,56(sp)
 69e:	7a42                	ld	s4,48(sp)
 6a0:	7aa2                	ld	s5,40(sp)
 6a2:	7b02                	ld	s6,32(sp)
 6a4:	6be2                	ld	s7,24(sp)
 6a6:	6125                	addi	sp,sp,96
 6a8:	8082                	ret

00000000000006aa <stat>:

int
stat(const char *n, struct stat *st)
{
 6aa:	1101                	addi	sp,sp,-32
 6ac:	ec06                	sd	ra,24(sp)
 6ae:	e822                	sd	s0,16(sp)
 6b0:	e426                	sd	s1,8(sp)
 6b2:	e04a                	sd	s2,0(sp)
 6b4:	1000                	addi	s0,sp,32
 6b6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 6b8:	4581                	li	a1,0
 6ba:	00000097          	auipc	ra,0x0
 6be:	176080e7          	jalr	374(ra) # 830 <open>
  if(fd < 0)
 6c2:	02054563          	bltz	a0,6ec <stat+0x42>
 6c6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 6c8:	85ca                	mv	a1,s2
 6ca:	00000097          	auipc	ra,0x0
 6ce:	17e080e7          	jalr	382(ra) # 848 <fstat>
 6d2:	892a                	mv	s2,a0
  close(fd);
 6d4:	8526                	mv	a0,s1
 6d6:	00000097          	auipc	ra,0x0
 6da:	142080e7          	jalr	322(ra) # 818 <close>
  return r;
}
 6de:	854a                	mv	a0,s2
 6e0:	60e2                	ld	ra,24(sp)
 6e2:	6442                	ld	s0,16(sp)
 6e4:	64a2                	ld	s1,8(sp)
 6e6:	6902                	ld	s2,0(sp)
 6e8:	6105                	addi	sp,sp,32
 6ea:	8082                	ret
    return -1;
 6ec:	597d                	li	s2,-1
 6ee:	bfc5                	j	6de <stat+0x34>

00000000000006f0 <atoi>:

int
atoi(const char *s)
{
 6f0:	1141                	addi	sp,sp,-16
 6f2:	e422                	sd	s0,8(sp)
 6f4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 6f6:	00054603          	lbu	a2,0(a0)
 6fa:	fd06079b          	addiw	a5,a2,-48
 6fe:	0ff7f793          	andi	a5,a5,255
 702:	4725                	li	a4,9
 704:	02f76963          	bltu	a4,a5,736 <atoi+0x46>
 708:	86aa                	mv	a3,a0
  n = 0;
 70a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 70c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 70e:	0685                	addi	a3,a3,1
 710:	0025179b          	slliw	a5,a0,0x2
 714:	9fa9                	addw	a5,a5,a0
 716:	0017979b          	slliw	a5,a5,0x1
 71a:	9fb1                	addw	a5,a5,a2
 71c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 720:	0006c603          	lbu	a2,0(a3)
 724:	fd06071b          	addiw	a4,a2,-48
 728:	0ff77713          	andi	a4,a4,255
 72c:	fee5f1e3          	bgeu	a1,a4,70e <atoi+0x1e>
  return n;
}
 730:	6422                	ld	s0,8(sp)
 732:	0141                	addi	sp,sp,16
 734:	8082                	ret
  n = 0;
 736:	4501                	li	a0,0
 738:	bfe5                	j	730 <atoi+0x40>

000000000000073a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 73a:	1141                	addi	sp,sp,-16
 73c:	e422                	sd	s0,8(sp)
 73e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 740:	02b57663          	bgeu	a0,a1,76c <memmove+0x32>
    while(n-- > 0)
 744:	02c05163          	blez	a2,766 <memmove+0x2c>
 748:	fff6079b          	addiw	a5,a2,-1
 74c:	1782                	slli	a5,a5,0x20
 74e:	9381                	srli	a5,a5,0x20
 750:	0785                	addi	a5,a5,1
 752:	97aa                	add	a5,a5,a0
  dst = vdst;
 754:	872a                	mv	a4,a0
      *dst++ = *src++;
 756:	0585                	addi	a1,a1,1
 758:	0705                	addi	a4,a4,1
 75a:	fff5c683          	lbu	a3,-1(a1)
 75e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 762:	fee79ae3          	bne	a5,a4,756 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 766:	6422                	ld	s0,8(sp)
 768:	0141                	addi	sp,sp,16
 76a:	8082                	ret
    dst += n;
 76c:	00c50733          	add	a4,a0,a2
    src += n;
 770:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 772:	fec05ae3          	blez	a2,766 <memmove+0x2c>
 776:	fff6079b          	addiw	a5,a2,-1
 77a:	1782                	slli	a5,a5,0x20
 77c:	9381                	srli	a5,a5,0x20
 77e:	fff7c793          	not	a5,a5
 782:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 784:	15fd                	addi	a1,a1,-1
 786:	177d                	addi	a4,a4,-1
 788:	0005c683          	lbu	a3,0(a1)
 78c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 790:	fee79ae3          	bne	a5,a4,784 <memmove+0x4a>
 794:	bfc9                	j	766 <memmove+0x2c>

0000000000000796 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 796:	1141                	addi	sp,sp,-16
 798:	e422                	sd	s0,8(sp)
 79a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 79c:	ca05                	beqz	a2,7cc <memcmp+0x36>
 79e:	fff6069b          	addiw	a3,a2,-1
 7a2:	1682                	slli	a3,a3,0x20
 7a4:	9281                	srli	a3,a3,0x20
 7a6:	0685                	addi	a3,a3,1
 7a8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 7aa:	00054783          	lbu	a5,0(a0)
 7ae:	0005c703          	lbu	a4,0(a1)
 7b2:	00e79863          	bne	a5,a4,7c2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 7b6:	0505                	addi	a0,a0,1
    p2++;
 7b8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 7ba:	fed518e3          	bne	a0,a3,7aa <memcmp+0x14>
  }
  return 0;
 7be:	4501                	li	a0,0
 7c0:	a019                	j	7c6 <memcmp+0x30>
      return *p1 - *p2;
 7c2:	40e7853b          	subw	a0,a5,a4
}
 7c6:	6422                	ld	s0,8(sp)
 7c8:	0141                	addi	sp,sp,16
 7ca:	8082                	ret
  return 0;
 7cc:	4501                	li	a0,0
 7ce:	bfe5                	j	7c6 <memcmp+0x30>

00000000000007d0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 7d0:	1141                	addi	sp,sp,-16
 7d2:	e406                	sd	ra,8(sp)
 7d4:	e022                	sd	s0,0(sp)
 7d6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 7d8:	00000097          	auipc	ra,0x0
 7dc:	f62080e7          	jalr	-158(ra) # 73a <memmove>
}
 7e0:	60a2                	ld	ra,8(sp)
 7e2:	6402                	ld	s0,0(sp)
 7e4:	0141                	addi	sp,sp,16
 7e6:	8082                	ret

00000000000007e8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7e8:	4885                	li	a7,1
 ecall
 7ea:	00000073          	ecall
 ret
 7ee:	8082                	ret

00000000000007f0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 7f0:	4889                	li	a7,2
 ecall
 7f2:	00000073          	ecall
 ret
 7f6:	8082                	ret

00000000000007f8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 7f8:	488d                	li	a7,3
 ecall
 7fa:	00000073          	ecall
 ret
 7fe:	8082                	ret

0000000000000800 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 800:	4891                	li	a7,4
 ecall
 802:	00000073          	ecall
 ret
 806:	8082                	ret

0000000000000808 <read>:
.global read
read:
 li a7, SYS_read
 808:	4895                	li	a7,5
 ecall
 80a:	00000073          	ecall
 ret
 80e:	8082                	ret

0000000000000810 <write>:
.global write
write:
 li a7, SYS_write
 810:	48c1                	li	a7,16
 ecall
 812:	00000073          	ecall
 ret
 816:	8082                	ret

0000000000000818 <close>:
.global close
close:
 li a7, SYS_close
 818:	48d5                	li	a7,21
 ecall
 81a:	00000073          	ecall
 ret
 81e:	8082                	ret

0000000000000820 <kill>:
.global kill
kill:
 li a7, SYS_kill
 820:	4899                	li	a7,6
 ecall
 822:	00000073          	ecall
 ret
 826:	8082                	ret

0000000000000828 <exec>:
.global exec
exec:
 li a7, SYS_exec
 828:	489d                	li	a7,7
 ecall
 82a:	00000073          	ecall
 ret
 82e:	8082                	ret

0000000000000830 <open>:
.global open
open:
 li a7, SYS_open
 830:	48bd                	li	a7,15
 ecall
 832:	00000073          	ecall
 ret
 836:	8082                	ret

0000000000000838 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 838:	48c5                	li	a7,17
 ecall
 83a:	00000073          	ecall
 ret
 83e:	8082                	ret

0000000000000840 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 840:	48c9                	li	a7,18
 ecall
 842:	00000073          	ecall
 ret
 846:	8082                	ret

0000000000000848 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 848:	48a1                	li	a7,8
 ecall
 84a:	00000073          	ecall
 ret
 84e:	8082                	ret

0000000000000850 <link>:
.global link
link:
 li a7, SYS_link
 850:	48cd                	li	a7,19
 ecall
 852:	00000073          	ecall
 ret
 856:	8082                	ret

0000000000000858 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 858:	48d1                	li	a7,20
 ecall
 85a:	00000073          	ecall
 ret
 85e:	8082                	ret

0000000000000860 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 860:	48a5                	li	a7,9
 ecall
 862:	00000073          	ecall
 ret
 866:	8082                	ret

0000000000000868 <dup>:
.global dup
dup:
 li a7, SYS_dup
 868:	48a9                	li	a7,10
 ecall
 86a:	00000073          	ecall
 ret
 86e:	8082                	ret

0000000000000870 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 870:	48ad                	li	a7,11
 ecall
 872:	00000073          	ecall
 ret
 876:	8082                	ret

0000000000000878 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 878:	48b1                	li	a7,12
 ecall
 87a:	00000073          	ecall
 ret
 87e:	8082                	ret

0000000000000880 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 880:	48b5                	li	a7,13
 ecall
 882:	00000073          	ecall
 ret
 886:	8082                	ret

0000000000000888 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 888:	48b9                	li	a7,14
 ecall
 88a:	00000073          	ecall
 ret
 88e:	8082                	ret

0000000000000890 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 890:	48d9                	li	a7,22
 ecall
 892:	00000073          	ecall
 ret
 896:	8082                	ret

0000000000000898 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 898:	48dd                	li	a7,23
 ecall
 89a:	00000073          	ecall
 ret
 89e:	8082                	ret

00000000000008a0 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 8a0:	48e1                	li	a7,24
 ecall
 8a2:	00000073          	ecall
 ret
 8a6:	8082                	ret

00000000000008a8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 8a8:	1101                	addi	sp,sp,-32
 8aa:	ec06                	sd	ra,24(sp)
 8ac:	e822                	sd	s0,16(sp)
 8ae:	1000                	addi	s0,sp,32
 8b0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 8b4:	4605                	li	a2,1
 8b6:	fef40593          	addi	a1,s0,-17
 8ba:	00000097          	auipc	ra,0x0
 8be:	f56080e7          	jalr	-170(ra) # 810 <write>
}
 8c2:	60e2                	ld	ra,24(sp)
 8c4:	6442                	ld	s0,16(sp)
 8c6:	6105                	addi	sp,sp,32
 8c8:	8082                	ret

00000000000008ca <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 8ca:	7139                	addi	sp,sp,-64
 8cc:	fc06                	sd	ra,56(sp)
 8ce:	f822                	sd	s0,48(sp)
 8d0:	f426                	sd	s1,40(sp)
 8d2:	f04a                	sd	s2,32(sp)
 8d4:	ec4e                	sd	s3,24(sp)
 8d6:	0080                	addi	s0,sp,64
 8d8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 8da:	c299                	beqz	a3,8e0 <printint+0x16>
 8dc:	0805c863          	bltz	a1,96c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 8e0:	2581                	sext.w	a1,a1
  neg = 0;
 8e2:	4881                	li	a7,0
 8e4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 8e8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 8ea:	2601                	sext.w	a2,a2
 8ec:	00000517          	auipc	a0,0x0
 8f0:	5dc50513          	addi	a0,a0,1500 # ec8 <digits>
 8f4:	883a                	mv	a6,a4
 8f6:	2705                	addiw	a4,a4,1
 8f8:	02c5f7bb          	remuw	a5,a1,a2
 8fc:	1782                	slli	a5,a5,0x20
 8fe:	9381                	srli	a5,a5,0x20
 900:	97aa                	add	a5,a5,a0
 902:	0007c783          	lbu	a5,0(a5)
 906:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 90a:	0005879b          	sext.w	a5,a1
 90e:	02c5d5bb          	divuw	a1,a1,a2
 912:	0685                	addi	a3,a3,1
 914:	fec7f0e3          	bgeu	a5,a2,8f4 <printint+0x2a>
  if(neg)
 918:	00088b63          	beqz	a7,92e <printint+0x64>
    buf[i++] = '-';
 91c:	fd040793          	addi	a5,s0,-48
 920:	973e                	add	a4,a4,a5
 922:	02d00793          	li	a5,45
 926:	fef70823          	sb	a5,-16(a4)
 92a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 92e:	02e05863          	blez	a4,95e <printint+0x94>
 932:	fc040793          	addi	a5,s0,-64
 936:	00e78933          	add	s2,a5,a4
 93a:	fff78993          	addi	s3,a5,-1
 93e:	99ba                	add	s3,s3,a4
 940:	377d                	addiw	a4,a4,-1
 942:	1702                	slli	a4,a4,0x20
 944:	9301                	srli	a4,a4,0x20
 946:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 94a:	fff94583          	lbu	a1,-1(s2)
 94e:	8526                	mv	a0,s1
 950:	00000097          	auipc	ra,0x0
 954:	f58080e7          	jalr	-168(ra) # 8a8 <putc>
  while(--i >= 0)
 958:	197d                	addi	s2,s2,-1
 95a:	ff3918e3          	bne	s2,s3,94a <printint+0x80>
}
 95e:	70e2                	ld	ra,56(sp)
 960:	7442                	ld	s0,48(sp)
 962:	74a2                	ld	s1,40(sp)
 964:	7902                	ld	s2,32(sp)
 966:	69e2                	ld	s3,24(sp)
 968:	6121                	addi	sp,sp,64
 96a:	8082                	ret
    x = -xx;
 96c:	40b005bb          	negw	a1,a1
    neg = 1;
 970:	4885                	li	a7,1
    x = -xx;
 972:	bf8d                	j	8e4 <printint+0x1a>

0000000000000974 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 974:	7119                	addi	sp,sp,-128
 976:	fc86                	sd	ra,120(sp)
 978:	f8a2                	sd	s0,112(sp)
 97a:	f4a6                	sd	s1,104(sp)
 97c:	f0ca                	sd	s2,96(sp)
 97e:	ecce                	sd	s3,88(sp)
 980:	e8d2                	sd	s4,80(sp)
 982:	e4d6                	sd	s5,72(sp)
 984:	e0da                	sd	s6,64(sp)
 986:	fc5e                	sd	s7,56(sp)
 988:	f862                	sd	s8,48(sp)
 98a:	f466                	sd	s9,40(sp)
 98c:	f06a                	sd	s10,32(sp)
 98e:	ec6e                	sd	s11,24(sp)
 990:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 992:	0005c903          	lbu	s2,0(a1)
 996:	18090f63          	beqz	s2,b34 <vprintf+0x1c0>
 99a:	8aaa                	mv	s5,a0
 99c:	8b32                	mv	s6,a2
 99e:	00158493          	addi	s1,a1,1
  state = 0;
 9a2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 9a4:	02500a13          	li	s4,37
      if(c == 'd'){
 9a8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 9ac:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 9b0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 9b4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9b8:	00000b97          	auipc	s7,0x0
 9bc:	510b8b93          	addi	s7,s7,1296 # ec8 <digits>
 9c0:	a839                	j	9de <vprintf+0x6a>
        putc(fd, c);
 9c2:	85ca                	mv	a1,s2
 9c4:	8556                	mv	a0,s5
 9c6:	00000097          	auipc	ra,0x0
 9ca:	ee2080e7          	jalr	-286(ra) # 8a8 <putc>
 9ce:	a019                	j	9d4 <vprintf+0x60>
    } else if(state == '%'){
 9d0:	01498f63          	beq	s3,s4,9ee <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 9d4:	0485                	addi	s1,s1,1
 9d6:	fff4c903          	lbu	s2,-1(s1)
 9da:	14090d63          	beqz	s2,b34 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 9de:	0009079b          	sext.w	a5,s2
    if(state == 0){
 9e2:	fe0997e3          	bnez	s3,9d0 <vprintf+0x5c>
      if(c == '%'){
 9e6:	fd479ee3          	bne	a5,s4,9c2 <vprintf+0x4e>
        state = '%';
 9ea:	89be                	mv	s3,a5
 9ec:	b7e5                	j	9d4 <vprintf+0x60>
      if(c == 'd'){
 9ee:	05878063          	beq	a5,s8,a2e <vprintf+0xba>
      } else if(c == 'l') {
 9f2:	05978c63          	beq	a5,s9,a4a <vprintf+0xd6>
      } else if(c == 'x') {
 9f6:	07a78863          	beq	a5,s10,a66 <vprintf+0xf2>
      } else if(c == 'p') {
 9fa:	09b78463          	beq	a5,s11,a82 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 9fe:	07300713          	li	a4,115
 a02:	0ce78663          	beq	a5,a4,ace <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 a06:	06300713          	li	a4,99
 a0a:	0ee78e63          	beq	a5,a4,b06 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 a0e:	11478863          	beq	a5,s4,b1e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 a12:	85d2                	mv	a1,s4
 a14:	8556                	mv	a0,s5
 a16:	00000097          	auipc	ra,0x0
 a1a:	e92080e7          	jalr	-366(ra) # 8a8 <putc>
        putc(fd, c);
 a1e:	85ca                	mv	a1,s2
 a20:	8556                	mv	a0,s5
 a22:	00000097          	auipc	ra,0x0
 a26:	e86080e7          	jalr	-378(ra) # 8a8 <putc>
      }
      state = 0;
 a2a:	4981                	li	s3,0
 a2c:	b765                	j	9d4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 a2e:	008b0913          	addi	s2,s6,8
 a32:	4685                	li	a3,1
 a34:	4629                	li	a2,10
 a36:	000b2583          	lw	a1,0(s6)
 a3a:	8556                	mv	a0,s5
 a3c:	00000097          	auipc	ra,0x0
 a40:	e8e080e7          	jalr	-370(ra) # 8ca <printint>
 a44:	8b4a                	mv	s6,s2
      state = 0;
 a46:	4981                	li	s3,0
 a48:	b771                	j	9d4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a4a:	008b0913          	addi	s2,s6,8
 a4e:	4681                	li	a3,0
 a50:	4629                	li	a2,10
 a52:	000b2583          	lw	a1,0(s6)
 a56:	8556                	mv	a0,s5
 a58:	00000097          	auipc	ra,0x0
 a5c:	e72080e7          	jalr	-398(ra) # 8ca <printint>
 a60:	8b4a                	mv	s6,s2
      state = 0;
 a62:	4981                	li	s3,0
 a64:	bf85                	j	9d4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a66:	008b0913          	addi	s2,s6,8
 a6a:	4681                	li	a3,0
 a6c:	4641                	li	a2,16
 a6e:	000b2583          	lw	a1,0(s6)
 a72:	8556                	mv	a0,s5
 a74:	00000097          	auipc	ra,0x0
 a78:	e56080e7          	jalr	-426(ra) # 8ca <printint>
 a7c:	8b4a                	mv	s6,s2
      state = 0;
 a7e:	4981                	li	s3,0
 a80:	bf91                	j	9d4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a82:	008b0793          	addi	a5,s6,8
 a86:	f8f43423          	sd	a5,-120(s0)
 a8a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a8e:	03000593          	li	a1,48
 a92:	8556                	mv	a0,s5
 a94:	00000097          	auipc	ra,0x0
 a98:	e14080e7          	jalr	-492(ra) # 8a8 <putc>
  putc(fd, 'x');
 a9c:	85ea                	mv	a1,s10
 a9e:	8556                	mv	a0,s5
 aa0:	00000097          	auipc	ra,0x0
 aa4:	e08080e7          	jalr	-504(ra) # 8a8 <putc>
 aa8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 aaa:	03c9d793          	srli	a5,s3,0x3c
 aae:	97de                	add	a5,a5,s7
 ab0:	0007c583          	lbu	a1,0(a5)
 ab4:	8556                	mv	a0,s5
 ab6:	00000097          	auipc	ra,0x0
 aba:	df2080e7          	jalr	-526(ra) # 8a8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 abe:	0992                	slli	s3,s3,0x4
 ac0:	397d                	addiw	s2,s2,-1
 ac2:	fe0914e3          	bnez	s2,aaa <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 ac6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 aca:	4981                	li	s3,0
 acc:	b721                	j	9d4 <vprintf+0x60>
        s = va_arg(ap, char*);
 ace:	008b0993          	addi	s3,s6,8
 ad2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 ad6:	02090163          	beqz	s2,af8 <vprintf+0x184>
        while(*s != 0){
 ada:	00094583          	lbu	a1,0(s2)
 ade:	c9a1                	beqz	a1,b2e <vprintf+0x1ba>
          putc(fd, *s);
 ae0:	8556                	mv	a0,s5
 ae2:	00000097          	auipc	ra,0x0
 ae6:	dc6080e7          	jalr	-570(ra) # 8a8 <putc>
          s++;
 aea:	0905                	addi	s2,s2,1
        while(*s != 0){
 aec:	00094583          	lbu	a1,0(s2)
 af0:	f9e5                	bnez	a1,ae0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 af2:	8b4e                	mv	s6,s3
      state = 0;
 af4:	4981                	li	s3,0
 af6:	bdf9                	j	9d4 <vprintf+0x60>
          s = "(null)";
 af8:	00000917          	auipc	s2,0x0
 afc:	3c890913          	addi	s2,s2,968 # ec0 <malloc+0x282>
        while(*s != 0){
 b00:	02800593          	li	a1,40
 b04:	bff1                	j	ae0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 b06:	008b0913          	addi	s2,s6,8
 b0a:	000b4583          	lbu	a1,0(s6)
 b0e:	8556                	mv	a0,s5
 b10:	00000097          	auipc	ra,0x0
 b14:	d98080e7          	jalr	-616(ra) # 8a8 <putc>
 b18:	8b4a                	mv	s6,s2
      state = 0;
 b1a:	4981                	li	s3,0
 b1c:	bd65                	j	9d4 <vprintf+0x60>
        putc(fd, c);
 b1e:	85d2                	mv	a1,s4
 b20:	8556                	mv	a0,s5
 b22:	00000097          	auipc	ra,0x0
 b26:	d86080e7          	jalr	-634(ra) # 8a8 <putc>
      state = 0;
 b2a:	4981                	li	s3,0
 b2c:	b565                	j	9d4 <vprintf+0x60>
        s = va_arg(ap, char*);
 b2e:	8b4e                	mv	s6,s3
      state = 0;
 b30:	4981                	li	s3,0
 b32:	b54d                	j	9d4 <vprintf+0x60>
    }
  }
}
 b34:	70e6                	ld	ra,120(sp)
 b36:	7446                	ld	s0,112(sp)
 b38:	74a6                	ld	s1,104(sp)
 b3a:	7906                	ld	s2,96(sp)
 b3c:	69e6                	ld	s3,88(sp)
 b3e:	6a46                	ld	s4,80(sp)
 b40:	6aa6                	ld	s5,72(sp)
 b42:	6b06                	ld	s6,64(sp)
 b44:	7be2                	ld	s7,56(sp)
 b46:	7c42                	ld	s8,48(sp)
 b48:	7ca2                	ld	s9,40(sp)
 b4a:	7d02                	ld	s10,32(sp)
 b4c:	6de2                	ld	s11,24(sp)
 b4e:	6109                	addi	sp,sp,128
 b50:	8082                	ret

0000000000000b52 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b52:	715d                	addi	sp,sp,-80
 b54:	ec06                	sd	ra,24(sp)
 b56:	e822                	sd	s0,16(sp)
 b58:	1000                	addi	s0,sp,32
 b5a:	e010                	sd	a2,0(s0)
 b5c:	e414                	sd	a3,8(s0)
 b5e:	e818                	sd	a4,16(s0)
 b60:	ec1c                	sd	a5,24(s0)
 b62:	03043023          	sd	a6,32(s0)
 b66:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b6a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b6e:	8622                	mv	a2,s0
 b70:	00000097          	auipc	ra,0x0
 b74:	e04080e7          	jalr	-508(ra) # 974 <vprintf>
}
 b78:	60e2                	ld	ra,24(sp)
 b7a:	6442                	ld	s0,16(sp)
 b7c:	6161                	addi	sp,sp,80
 b7e:	8082                	ret

0000000000000b80 <printf>:

void
printf(const char *fmt, ...)
{
 b80:	711d                	addi	sp,sp,-96
 b82:	ec06                	sd	ra,24(sp)
 b84:	e822                	sd	s0,16(sp)
 b86:	1000                	addi	s0,sp,32
 b88:	e40c                	sd	a1,8(s0)
 b8a:	e810                	sd	a2,16(s0)
 b8c:	ec14                	sd	a3,24(s0)
 b8e:	f018                	sd	a4,32(s0)
 b90:	f41c                	sd	a5,40(s0)
 b92:	03043823          	sd	a6,48(s0)
 b96:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b9a:	00840613          	addi	a2,s0,8
 b9e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 ba2:	85aa                	mv	a1,a0
 ba4:	4505                	li	a0,1
 ba6:	00000097          	auipc	ra,0x0
 baa:	dce080e7          	jalr	-562(ra) # 974 <vprintf>
}
 bae:	60e2                	ld	ra,24(sp)
 bb0:	6442                	ld	s0,16(sp)
 bb2:	6125                	addi	sp,sp,96
 bb4:	8082                	ret

0000000000000bb6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 bb6:	1141                	addi	sp,sp,-16
 bb8:	e422                	sd	s0,8(sp)
 bba:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 bbc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bc0:	00000797          	auipc	a5,0x0
 bc4:	3207b783          	ld	a5,800(a5) # ee0 <freep>
 bc8:	a805                	j	bf8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 bca:	4618                	lw	a4,8(a2)
 bcc:	9db9                	addw	a1,a1,a4
 bce:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 bd2:	6398                	ld	a4,0(a5)
 bd4:	6318                	ld	a4,0(a4)
 bd6:	fee53823          	sd	a4,-16(a0)
 bda:	a091                	j	c1e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 bdc:	ff852703          	lw	a4,-8(a0)
 be0:	9e39                	addw	a2,a2,a4
 be2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 be4:	ff053703          	ld	a4,-16(a0)
 be8:	e398                	sd	a4,0(a5)
 bea:	a099                	j	c30 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bec:	6398                	ld	a4,0(a5)
 bee:	00e7e463          	bltu	a5,a4,bf6 <free+0x40>
 bf2:	00e6ea63          	bltu	a3,a4,c06 <free+0x50>
{
 bf6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bf8:	fed7fae3          	bgeu	a5,a3,bec <free+0x36>
 bfc:	6398                	ld	a4,0(a5)
 bfe:	00e6e463          	bltu	a3,a4,c06 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c02:	fee7eae3          	bltu	a5,a4,bf6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 c06:	ff852583          	lw	a1,-8(a0)
 c0a:	6390                	ld	a2,0(a5)
 c0c:	02059713          	slli	a4,a1,0x20
 c10:	9301                	srli	a4,a4,0x20
 c12:	0712                	slli	a4,a4,0x4
 c14:	9736                	add	a4,a4,a3
 c16:	fae60ae3          	beq	a2,a4,bca <free+0x14>
    bp->s.ptr = p->s.ptr;
 c1a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c1e:	4790                	lw	a2,8(a5)
 c20:	02061713          	slli	a4,a2,0x20
 c24:	9301                	srli	a4,a4,0x20
 c26:	0712                	slli	a4,a4,0x4
 c28:	973e                	add	a4,a4,a5
 c2a:	fae689e3          	beq	a3,a4,bdc <free+0x26>
  } else
    p->s.ptr = bp;
 c2e:	e394                	sd	a3,0(a5)
  freep = p;
 c30:	00000717          	auipc	a4,0x0
 c34:	2af73823          	sd	a5,688(a4) # ee0 <freep>
}
 c38:	6422                	ld	s0,8(sp)
 c3a:	0141                	addi	sp,sp,16
 c3c:	8082                	ret

0000000000000c3e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c3e:	7139                	addi	sp,sp,-64
 c40:	fc06                	sd	ra,56(sp)
 c42:	f822                	sd	s0,48(sp)
 c44:	f426                	sd	s1,40(sp)
 c46:	f04a                	sd	s2,32(sp)
 c48:	ec4e                	sd	s3,24(sp)
 c4a:	e852                	sd	s4,16(sp)
 c4c:	e456                	sd	s5,8(sp)
 c4e:	e05a                	sd	s6,0(sp)
 c50:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c52:	02051493          	slli	s1,a0,0x20
 c56:	9081                	srli	s1,s1,0x20
 c58:	04bd                	addi	s1,s1,15
 c5a:	8091                	srli	s1,s1,0x4
 c5c:	0014899b          	addiw	s3,s1,1
 c60:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c62:	00000517          	auipc	a0,0x0
 c66:	27e53503          	ld	a0,638(a0) # ee0 <freep>
 c6a:	c515                	beqz	a0,c96 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c6c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c6e:	4798                	lw	a4,8(a5)
 c70:	02977f63          	bgeu	a4,s1,cae <malloc+0x70>
 c74:	8a4e                	mv	s4,s3
 c76:	0009871b          	sext.w	a4,s3
 c7a:	6685                	lui	a3,0x1
 c7c:	00d77363          	bgeu	a4,a3,c82 <malloc+0x44>
 c80:	6a05                	lui	s4,0x1
 c82:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c86:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c8a:	00000917          	auipc	s2,0x0
 c8e:	25690913          	addi	s2,s2,598 # ee0 <freep>
  if(p == (char*)-1)
 c92:	5afd                	li	s5,-1
 c94:	a88d                	j	d06 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 c96:	00000797          	auipc	a5,0x0
 c9a:	25278793          	addi	a5,a5,594 # ee8 <base>
 c9e:	00000717          	auipc	a4,0x0
 ca2:	24f73123          	sd	a5,578(a4) # ee0 <freep>
 ca6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 ca8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 cac:	b7e1                	j	c74 <malloc+0x36>
      if(p->s.size == nunits)
 cae:	02e48b63          	beq	s1,a4,ce4 <malloc+0xa6>
        p->s.size -= nunits;
 cb2:	4137073b          	subw	a4,a4,s3
 cb6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 cb8:	1702                	slli	a4,a4,0x20
 cba:	9301                	srli	a4,a4,0x20
 cbc:	0712                	slli	a4,a4,0x4
 cbe:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 cc0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 cc4:	00000717          	auipc	a4,0x0
 cc8:	20a73e23          	sd	a0,540(a4) # ee0 <freep>
      return (void*)(p + 1);
 ccc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 cd0:	70e2                	ld	ra,56(sp)
 cd2:	7442                	ld	s0,48(sp)
 cd4:	74a2                	ld	s1,40(sp)
 cd6:	7902                	ld	s2,32(sp)
 cd8:	69e2                	ld	s3,24(sp)
 cda:	6a42                	ld	s4,16(sp)
 cdc:	6aa2                	ld	s5,8(sp)
 cde:	6b02                	ld	s6,0(sp)
 ce0:	6121                	addi	sp,sp,64
 ce2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ce4:	6398                	ld	a4,0(a5)
 ce6:	e118                	sd	a4,0(a0)
 ce8:	bff1                	j	cc4 <malloc+0x86>
  hp->s.size = nu;
 cea:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 cee:	0541                	addi	a0,a0,16
 cf0:	00000097          	auipc	ra,0x0
 cf4:	ec6080e7          	jalr	-314(ra) # bb6 <free>
  return freep;
 cf8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 cfc:	d971                	beqz	a0,cd0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cfe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 d00:	4798                	lw	a4,8(a5)
 d02:	fa9776e3          	bgeu	a4,s1,cae <malloc+0x70>
    if(p == freep)
 d06:	00093703          	ld	a4,0(s2)
 d0a:	853e                	mv	a0,a5
 d0c:	fef719e3          	bne	a4,a5,cfe <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 d10:	8552                	mv	a0,s4
 d12:	00000097          	auipc	ra,0x0
 d16:	b66080e7          	jalr	-1178(ra) # 878 <sbrk>
  if(p == (char*)-1)
 d1a:	fd5518e3          	bne	a0,s5,cea <malloc+0xac>
        return 0;
 d1e:	4501                	li	a0,0
 d20:	bf45                	j	cd0 <malloc+0x92>
