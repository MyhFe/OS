
user/_a:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <check>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void check(){
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    //     while(1){
    //         printf("this is process %d\n", k);
    //         sleep(100);
    //     }
    // }
    printf("start\n");
   8:	00001517          	auipc	a0,0x1
   c:	a5050513          	addi	a0,a0,-1456 # a58 <malloc+0xe8>
  10:	00001097          	auipc	ra,0x1
  14:	8a2080e7          	jalr	-1886(ra) # 8b2 <printf>
  18:	001e87b7          	lui	a5,0x1e8
  1c:	48078793          	addi	a5,a5,1152 # 1e8480 <__global_pointer$+0x1e7177>
    int a = 0, b = 1;
    for(int i=0;i<2000000;i++){
  20:	37fd                	addiw	a5,a5,-1
  22:	fffd                	bnez	a5,20 <check+0x20>
        int tmp = a;
        a = b;
        b = b+tmp;
    }
    printf("stop\n");
  24:	00001517          	auipc	a0,0x1
  28:	a3c50513          	addi	a0,a0,-1476 # a60 <malloc+0xf0>
  2c:	00001097          	auipc	ra,0x1
  30:	886080e7          	jalr	-1914(ra) # 8b2 <printf>
}
  34:	60a2                	ld	ra,8(sp)
  36:	6402                	ld	s0,0(sp)
  38:	0141                	addi	sp,sp,16
  3a:	8082                	ret

000000000000003c <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  3c:	7139                	addi	sp,sp,-64
  3e:	fc06                	sd	ra,56(sp)
  40:	f822                	sd	s0,48(sp)
  42:	f426                	sd	s1,40(sp)
  44:	f04a                	sd	s2,32(sp)
  46:	ec4e                	sd	s3,24(sp)
  48:	e852                	sd	s4,16(sp)
  4a:	e456                	sd	s5,8(sp)
  4c:	e05a                	sd	s6,0(sp)
  4e:	0080                	addi	s0,sp,64
  50:	8a2a                	mv	s4,a0
  52:	892e                	mv	s2,a1
    int pid = getpid();
  54:	00000097          	auipc	ra,0x0
  58:	54e080e7          	jalr	1358(ra) # 5a2 <getpid>
    for (int i = 0; i < loop_size; i++) {
  5c:	05205a63          	blez	s2,b0 <kill_system_dem+0x74>
  60:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  62:	01f9599b          	srliw	s3,s2,0x1f
  66:	012989bb          	addw	s3,s3,s2
  6a:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  6e:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  70:	00001b17          	auipc	s6,0x1
  74:	9f8b0b13          	addi	s6,s6,-1544 # a68 <malloc+0xf8>
  78:	a031                	j	84 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  7a:	02998663          	beq	s3,s1,a6 <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  7e:	2485                	addiw	s1,s1,1
  80:	02990863          	beq	s2,s1,b0 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  84:	0344e7bb          	remw	a5,s1,s4
  88:	fbed                	bnez	a5,7a <kill_system_dem+0x3e>
  8a:	00000097          	auipc	ra,0x0
  8e:	518080e7          	jalr	1304(ra) # 5a2 <getpid>
  92:	ff5514e3          	bne	a0,s5,7a <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  96:	864a                	mv	a2,s2
  98:	85a6                	mv	a1,s1
  9a:	855a                	mv	a0,s6
  9c:	00001097          	auipc	ra,0x1
  a0:	816080e7          	jalr	-2026(ra) # 8b2 <printf>
  a4:	bfd9                	j	7a <kill_system_dem+0x3e>
            kill_system();
  a6:	00000097          	auipc	ra,0x0
  aa:	51c080e7          	jalr	1308(ra) # 5c2 <kill_system>
  ae:	bfc1                	j	7e <kill_system_dem+0x42>
        }
    }
    printf("\n");
  b0:	00001517          	auipc	a0,0x1
  b4:	9d850513          	addi	a0,a0,-1576 # a88 <malloc+0x118>
  b8:	00000097          	auipc	ra,0x0
  bc:	7fa080e7          	jalr	2042(ra) # 8b2 <printf>
}
  c0:	70e2                	ld	ra,56(sp)
  c2:	7442                	ld	s0,48(sp)
  c4:	74a2                	ld	s1,40(sp)
  c6:	7902                	ld	s2,32(sp)
  c8:	69e2                	ld	s3,24(sp)
  ca:	6a42                	ld	s4,16(sp)
  cc:	6aa2                	ld	s5,8(sp)
  ce:	6b02                	ld	s6,0(sp)
  d0:	6121                	addi	sp,sp,64
  d2:	8082                	ret

00000000000000d4 <pause_system_dem>:

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
  d4:	715d                	addi	sp,sp,-80
  d6:	e486                	sd	ra,72(sp)
  d8:	e0a2                	sd	s0,64(sp)
  da:	fc26                	sd	s1,56(sp)
  dc:	f84a                	sd	s2,48(sp)
  de:	f44e                	sd	s3,40(sp)
  e0:	f052                	sd	s4,32(sp)
  e2:	ec56                	sd	s5,24(sp)
  e4:	e85a                	sd	s6,16(sp)
  e6:	e45e                	sd	s7,8(sp)
  e8:	0880                	addi	s0,sp,80
  ea:	8a2a                	mv	s4,a0
  ec:	8b2e                	mv	s6,a1
  ee:	8932                	mv	s2,a2
    int pid = getpid();
  f0:	00000097          	auipc	ra,0x0
  f4:	4b2080e7          	jalr	1202(ra) # 5a2 <getpid>
    for (int i = 0; i < loop_size; i++) {
  f8:	05205b63          	blez	s2,14e <pause_system_dem+0x7a>
  fc:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  fe:	01f9599b          	srliw	s3,s2,0x1f
 102:	012989bb          	addw	s3,s3,s2
 106:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
 10a:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
 10c:	00001b97          	auipc	s7,0x1
 110:	984b8b93          	addi	s7,s7,-1660 # a90 <malloc+0x120>
 114:	a031                	j	120 <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
 116:	02998663          	beq	s3,s1,142 <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
 11a:	2485                	addiw	s1,s1,1
 11c:	02990963          	beq	s2,s1,14e <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
 120:	0344e7bb          	remw	a5,s1,s4
 124:	fbed                	bnez	a5,116 <pause_system_dem+0x42>
 126:	00000097          	auipc	ra,0x0
 12a:	47c080e7          	jalr	1148(ra) # 5a2 <getpid>
 12e:	ff5514e3          	bne	a0,s5,116 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
 132:	864a                	mv	a2,s2
 134:	85a6                	mv	a1,s1
 136:	855e                	mv	a0,s7
 138:	00000097          	auipc	ra,0x0
 13c:	77a080e7          	jalr	1914(ra) # 8b2 <printf>
 140:	bfd9                	j	116 <pause_system_dem+0x42>
            pause_system(pause_seconds);
 142:	855a                	mv	a0,s6
 144:	00000097          	auipc	ra,0x0
 148:	486080e7          	jalr	1158(ra) # 5ca <pause_system>
 14c:	b7f9                	j	11a <pause_system_dem+0x46>
        }
    }
    printf("\n");
 14e:	00001517          	auipc	a0,0x1
 152:	93a50513          	addi	a0,a0,-1734 # a88 <malloc+0x118>
 156:	00000097          	auipc	ra,0x0
 15a:	75c080e7          	jalr	1884(ra) # 8b2 <printf>
}
 15e:	60a6                	ld	ra,72(sp)
 160:	6406                	ld	s0,64(sp)
 162:	74e2                	ld	s1,56(sp)
 164:	7942                	ld	s2,48(sp)
 166:	79a2                	ld	s3,40(sp)
 168:	7a02                	ld	s4,32(sp)
 16a:	6ae2                	ld	s5,24(sp)
 16c:	6b42                	ld	s6,16(sp)
 16e:	6ba2                	ld	s7,8(sp)
 170:	6161                	addi	sp,sp,80
 172:	8082                	ret

0000000000000174 <env>:

void env(int size, int interval, char* env_name) {
 174:	711d                	addi	sp,sp,-96
 176:	ec86                	sd	ra,88(sp)
 178:	e8a2                	sd	s0,80(sp)
 17a:	e4a6                	sd	s1,72(sp)
 17c:	e0ca                	sd	s2,64(sp)
 17e:	fc4e                	sd	s3,56(sp)
 180:	f852                	sd	s4,48(sp)
 182:	f456                	sd	s5,40(sp)
 184:	f05a                	sd	s6,32(sp)
 186:	ec5e                	sd	s7,24(sp)
 188:	e862                	sd	s8,16(sp)
 18a:	e466                	sd	s9,8(sp)
 18c:	1080                	addi	s0,sp,96
 18e:	8a2e                	mv	s4,a1
 190:	8b32                	mv	s6,a2
    int result = 1;
    int loop_size = (int)(10e6);
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 192:	00000097          	auipc	ra,0x0
 196:	388080e7          	jalr	904(ra) # 51a <fork>
 19a:	00000097          	auipc	ra,0x0
 19e:	380080e7          	jalr	896(ra) # 51a <fork>
 1a2:	8aaa                	mv	s5,a0
    }
    for (int i = 0; i < loop_size; i++) {
 1a4:	4481                	li	s1,0
        if (i % (int)(loop_size / 10e0) == 0) {
 1a6:	000f49b7          	lui	s3,0xf4
 1aa:	2409899b          	addiw	s3,s3,576
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
 1ae:	00001c97          	auipc	s9,0x1
 1b2:	91ac8c93          	addi	s9,s9,-1766 # ac8 <malloc+0x158>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1b6:	00989937          	lui	s2,0x989
 1ba:	68090913          	addi	s2,s2,1664 # 989680 <__global_pointer$+0x988377>
 1be:	00001c17          	auipc	s8,0x1
 1c2:	8f2c0c13          	addi	s8,s8,-1806 # ab0 <malloc+0x140>
 1c6:	06300b93          	li	s7,99
 1ca:	a821                	j	1e2 <env+0x6e>
        		printf(" ");
 1cc:	8566                	mv	a0,s9
 1ce:	00000097          	auipc	ra,0x0
 1d2:	6e4080e7          	jalr	1764(ra) # 8b2 <printf>
        	}
        }
        if (i % interval == 0) {
 1d6:	0344e7bb          	remw	a5,s1,s4
 1da:	c395                	beqz	a5,1fe <env+0x8a>
    for (int i = 0; i < loop_size; i++) {
 1dc:	2485                	addiw	s1,s1,1
 1de:	03248463          	beq	s1,s2,206 <env+0x92>
        if (i % (int)(loop_size / 10e0) == 0) {
 1e2:	0334e7bb          	remw	a5,s1,s3
 1e6:	fbe5                	bnez	a5,1d6 <env+0x62>
        	if (pid == 0) {
 1e8:	fe0a92e3          	bnez	s5,1cc <env+0x58>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1ec:	86ca                	mv	a3,s2
 1ee:	8626                	mv	a2,s1
 1f0:	85da                	mv	a1,s6
 1f2:	8562                	mv	a0,s8
 1f4:	00000097          	auipc	ra,0x0
 1f8:	6be080e7          	jalr	1726(ra) # 8b2 <printf>
 1fc:	bfe9                	j	1d6 <env+0x62>
 1fe:	87de                	mv	a5,s7
            for(int j=1;j<100;j++){
 200:	37fd                	addiw	a5,a5,-1
 202:	fffd                	bnez	a5,200 <env+0x8c>
 204:	bfe1                	j	1dc <env+0x68>
                result = result * size;
            }
        }
    }
    printf("\n");
 206:	00001517          	auipc	a0,0x1
 20a:	88250513          	addi	a0,a0,-1918 # a88 <malloc+0x118>
 20e:	00000097          	auipc	ra,0x0
 212:	6a4080e7          	jalr	1700(ra) # 8b2 <printf>
}
 216:	60e6                	ld	ra,88(sp)
 218:	6446                	ld	s0,80(sp)
 21a:	64a6                	ld	s1,72(sp)
 21c:	6906                	ld	s2,64(sp)
 21e:	79e2                	ld	s3,56(sp)
 220:	7a42                	ld	s4,48(sp)
 222:	7aa2                	ld	s5,40(sp)
 224:	7b02                	ld	s6,32(sp)
 226:	6be2                	ld	s7,24(sp)
 228:	6c42                	ld	s8,16(sp)
 22a:	6ca2                	ld	s9,8(sp)
 22c:	6125                	addi	sp,sp,96
 22e:	8082                	ret

0000000000000230 <env_large>:

void env_large() {
 230:	1141                	addi	sp,sp,-16
 232:	e406                	sd	ra,8(sp)
 234:	e022                	sd	s0,0(sp)
 236:	0800                	addi	s0,sp,16
    env(10e6, 3, "env_large");
 238:	00001617          	auipc	a2,0x1
 23c:	89860613          	addi	a2,a2,-1896 # ad0 <malloc+0x160>
 240:	458d                	li	a1,3
 242:	00989537          	lui	a0,0x989
 246:	68050513          	addi	a0,a0,1664 # 989680 <__global_pointer$+0x988377>
 24a:	00000097          	auipc	ra,0x0
 24e:	f2a080e7          	jalr	-214(ra) # 174 <env>
}
 252:	60a2                	ld	ra,8(sp)
 254:	6402                	ld	s0,0(sp)
 256:	0141                	addi	sp,sp,16
 258:	8082                	ret

000000000000025a <env_freq>:

void env_freq() {
 25a:	1141                	addi	sp,sp,-16
 25c:	e406                	sd	ra,8(sp)
 25e:	e022                	sd	s0,0(sp)
 260:	0800                	addi	s0,sp,16
    env(10e1, 10e1, "env_freq");
 262:	00001617          	auipc	a2,0x1
 266:	87e60613          	addi	a2,a2,-1922 # ae0 <malloc+0x170>
 26a:	06400593          	li	a1,100
 26e:	06400513          	li	a0,100
 272:	00000097          	auipc	ra,0x0
 276:	f02080e7          	jalr	-254(ra) # 174 <env>
}
 27a:	60a2                	ld	ra,8(sp)
 27c:	6402                	ld	s0,0(sp)
 27e:	0141                	addi	sp,sp,16
 280:	8082                	ret

0000000000000282 <main>:

int
main(int argc, char *argv[])
{
 282:	1141                	addi	sp,sp,-16
 284:	e406                	sd	ra,8(sp)
 286:	e022                	sd	s0,0(sp)
 288:	0800                	addi	s0,sp,16
     pause_system_dem(10, 10, 100);
 28a:	06400613          	li	a2,100
 28e:	45a9                	li	a1,10
 290:	4529                	li	a0,10
 292:	00000097          	auipc	ra,0x0
 296:	e42080e7          	jalr	-446(ra) # d4 <pause_system_dem>
    // kill_system_dem(10, 100);
    print_stats();
 29a:	00000097          	auipc	ra,0x0
 29e:	338080e7          	jalr	824(ra) # 5d2 <print_stats>


    exit(0);
 2a2:	4501                	li	a0,0
 2a4:	00000097          	auipc	ra,0x0
 2a8:	27e080e7          	jalr	638(ra) # 522 <exit>

00000000000002ac <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2ac:	1141                	addi	sp,sp,-16
 2ae:	e422                	sd	s0,8(sp)
 2b0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2b2:	87aa                	mv	a5,a0
 2b4:	0585                	addi	a1,a1,1
 2b6:	0785                	addi	a5,a5,1
 2b8:	fff5c703          	lbu	a4,-1(a1)
 2bc:	fee78fa3          	sb	a4,-1(a5)
 2c0:	fb75                	bnez	a4,2b4 <strcpy+0x8>
    ;
  return os;
}
 2c2:	6422                	ld	s0,8(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret

00000000000002c8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c8:	1141                	addi	sp,sp,-16
 2ca:	e422                	sd	s0,8(sp)
 2cc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2ce:	00054783          	lbu	a5,0(a0)
 2d2:	cb91                	beqz	a5,2e6 <strcmp+0x1e>
 2d4:	0005c703          	lbu	a4,0(a1)
 2d8:	00f71763          	bne	a4,a5,2e6 <strcmp+0x1e>
    p++, q++;
 2dc:	0505                	addi	a0,a0,1
 2de:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	fbe5                	bnez	a5,2d4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2e6:	0005c503          	lbu	a0,0(a1)
}
 2ea:	40a7853b          	subw	a0,a5,a0
 2ee:	6422                	ld	s0,8(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret

00000000000002f4 <strlen>:

uint
strlen(const char *s)
{
 2f4:	1141                	addi	sp,sp,-16
 2f6:	e422                	sd	s0,8(sp)
 2f8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2fa:	00054783          	lbu	a5,0(a0)
 2fe:	cf91                	beqz	a5,31a <strlen+0x26>
 300:	0505                	addi	a0,a0,1
 302:	87aa                	mv	a5,a0
 304:	4685                	li	a3,1
 306:	9e89                	subw	a3,a3,a0
 308:	00f6853b          	addw	a0,a3,a5
 30c:	0785                	addi	a5,a5,1
 30e:	fff7c703          	lbu	a4,-1(a5)
 312:	fb7d                	bnez	a4,308 <strlen+0x14>
    ;
  return n;
}
 314:	6422                	ld	s0,8(sp)
 316:	0141                	addi	sp,sp,16
 318:	8082                	ret
  for(n = 0; s[n]; n++)
 31a:	4501                	li	a0,0
 31c:	bfe5                	j	314 <strlen+0x20>

000000000000031e <memset>:

void*
memset(void *dst, int c, uint n)
{
 31e:	1141                	addi	sp,sp,-16
 320:	e422                	sd	s0,8(sp)
 322:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 324:	ce09                	beqz	a2,33e <memset+0x20>
 326:	87aa                	mv	a5,a0
 328:	fff6071b          	addiw	a4,a2,-1
 32c:	1702                	slli	a4,a4,0x20
 32e:	9301                	srli	a4,a4,0x20
 330:	0705                	addi	a4,a4,1
 332:	972a                	add	a4,a4,a0
    cdst[i] = c;
 334:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 338:	0785                	addi	a5,a5,1
 33a:	fee79de3          	bne	a5,a4,334 <memset+0x16>
  }
  return dst;
}
 33e:	6422                	ld	s0,8(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret

0000000000000344 <strchr>:

char*
strchr(const char *s, char c)
{
 344:	1141                	addi	sp,sp,-16
 346:	e422                	sd	s0,8(sp)
 348:	0800                	addi	s0,sp,16
  for(; *s; s++)
 34a:	00054783          	lbu	a5,0(a0)
 34e:	cb99                	beqz	a5,364 <strchr+0x20>
    if(*s == c)
 350:	00f58763          	beq	a1,a5,35e <strchr+0x1a>
  for(; *s; s++)
 354:	0505                	addi	a0,a0,1
 356:	00054783          	lbu	a5,0(a0)
 35a:	fbfd                	bnez	a5,350 <strchr+0xc>
      return (char*)s;
  return 0;
 35c:	4501                	li	a0,0
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret
  return 0;
 364:	4501                	li	a0,0
 366:	bfe5                	j	35e <strchr+0x1a>

0000000000000368 <gets>:

char*
gets(char *buf, int max)
{
 368:	711d                	addi	sp,sp,-96
 36a:	ec86                	sd	ra,88(sp)
 36c:	e8a2                	sd	s0,80(sp)
 36e:	e4a6                	sd	s1,72(sp)
 370:	e0ca                	sd	s2,64(sp)
 372:	fc4e                	sd	s3,56(sp)
 374:	f852                	sd	s4,48(sp)
 376:	f456                	sd	s5,40(sp)
 378:	f05a                	sd	s6,32(sp)
 37a:	ec5e                	sd	s7,24(sp)
 37c:	1080                	addi	s0,sp,96
 37e:	8baa                	mv	s7,a0
 380:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 382:	892a                	mv	s2,a0
 384:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 386:	4aa9                	li	s5,10
 388:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 38a:	89a6                	mv	s3,s1
 38c:	2485                	addiw	s1,s1,1
 38e:	0344d863          	bge	s1,s4,3be <gets+0x56>
    cc = read(0, &c, 1);
 392:	4605                	li	a2,1
 394:	faf40593          	addi	a1,s0,-81
 398:	4501                	li	a0,0
 39a:	00000097          	auipc	ra,0x0
 39e:	1a0080e7          	jalr	416(ra) # 53a <read>
    if(cc < 1)
 3a2:	00a05e63          	blez	a0,3be <gets+0x56>
    buf[i++] = c;
 3a6:	faf44783          	lbu	a5,-81(s0)
 3aa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3ae:	01578763          	beq	a5,s5,3bc <gets+0x54>
 3b2:	0905                	addi	s2,s2,1
 3b4:	fd679be3          	bne	a5,s6,38a <gets+0x22>
  for(i=0; i+1 < max; ){
 3b8:	89a6                	mv	s3,s1
 3ba:	a011                	j	3be <gets+0x56>
 3bc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3be:	99de                	add	s3,s3,s7
 3c0:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2cf7>
  return buf;
}
 3c4:	855e                	mv	a0,s7
 3c6:	60e6                	ld	ra,88(sp)
 3c8:	6446                	ld	s0,80(sp)
 3ca:	64a6                	ld	s1,72(sp)
 3cc:	6906                	ld	s2,64(sp)
 3ce:	79e2                	ld	s3,56(sp)
 3d0:	7a42                	ld	s4,48(sp)
 3d2:	7aa2                	ld	s5,40(sp)
 3d4:	7b02                	ld	s6,32(sp)
 3d6:	6be2                	ld	s7,24(sp)
 3d8:	6125                	addi	sp,sp,96
 3da:	8082                	ret

00000000000003dc <stat>:

int
stat(const char *n, struct stat *st)
{
 3dc:	1101                	addi	sp,sp,-32
 3de:	ec06                	sd	ra,24(sp)
 3e0:	e822                	sd	s0,16(sp)
 3e2:	e426                	sd	s1,8(sp)
 3e4:	e04a                	sd	s2,0(sp)
 3e6:	1000                	addi	s0,sp,32
 3e8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3ea:	4581                	li	a1,0
 3ec:	00000097          	auipc	ra,0x0
 3f0:	176080e7          	jalr	374(ra) # 562 <open>
  if(fd < 0)
 3f4:	02054563          	bltz	a0,41e <stat+0x42>
 3f8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3fa:	85ca                	mv	a1,s2
 3fc:	00000097          	auipc	ra,0x0
 400:	17e080e7          	jalr	382(ra) # 57a <fstat>
 404:	892a                	mv	s2,a0
  close(fd);
 406:	8526                	mv	a0,s1
 408:	00000097          	auipc	ra,0x0
 40c:	142080e7          	jalr	322(ra) # 54a <close>
  return r;
}
 410:	854a                	mv	a0,s2
 412:	60e2                	ld	ra,24(sp)
 414:	6442                	ld	s0,16(sp)
 416:	64a2                	ld	s1,8(sp)
 418:	6902                	ld	s2,0(sp)
 41a:	6105                	addi	sp,sp,32
 41c:	8082                	ret
    return -1;
 41e:	597d                	li	s2,-1
 420:	bfc5                	j	410 <stat+0x34>

0000000000000422 <atoi>:

int
atoi(const char *s)
{
 422:	1141                	addi	sp,sp,-16
 424:	e422                	sd	s0,8(sp)
 426:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 428:	00054603          	lbu	a2,0(a0)
 42c:	fd06079b          	addiw	a5,a2,-48
 430:	0ff7f793          	andi	a5,a5,255
 434:	4725                	li	a4,9
 436:	02f76963          	bltu	a4,a5,468 <atoi+0x46>
 43a:	86aa                	mv	a3,a0
  n = 0;
 43c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 43e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 440:	0685                	addi	a3,a3,1
 442:	0025179b          	slliw	a5,a0,0x2
 446:	9fa9                	addw	a5,a5,a0
 448:	0017979b          	slliw	a5,a5,0x1
 44c:	9fb1                	addw	a5,a5,a2
 44e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 452:	0006c603          	lbu	a2,0(a3)
 456:	fd06071b          	addiw	a4,a2,-48
 45a:	0ff77713          	andi	a4,a4,255
 45e:	fee5f1e3          	bgeu	a1,a4,440 <atoi+0x1e>
  return n;
}
 462:	6422                	ld	s0,8(sp)
 464:	0141                	addi	sp,sp,16
 466:	8082                	ret
  n = 0;
 468:	4501                	li	a0,0
 46a:	bfe5                	j	462 <atoi+0x40>

000000000000046c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 46c:	1141                	addi	sp,sp,-16
 46e:	e422                	sd	s0,8(sp)
 470:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 472:	02b57663          	bgeu	a0,a1,49e <memmove+0x32>
    while(n-- > 0)
 476:	02c05163          	blez	a2,498 <memmove+0x2c>
 47a:	fff6079b          	addiw	a5,a2,-1
 47e:	1782                	slli	a5,a5,0x20
 480:	9381                	srli	a5,a5,0x20
 482:	0785                	addi	a5,a5,1
 484:	97aa                	add	a5,a5,a0
  dst = vdst;
 486:	872a                	mv	a4,a0
      *dst++ = *src++;
 488:	0585                	addi	a1,a1,1
 48a:	0705                	addi	a4,a4,1
 48c:	fff5c683          	lbu	a3,-1(a1)
 490:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 494:	fee79ae3          	bne	a5,a4,488 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 498:	6422                	ld	s0,8(sp)
 49a:	0141                	addi	sp,sp,16
 49c:	8082                	ret
    dst += n;
 49e:	00c50733          	add	a4,a0,a2
    src += n;
 4a2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4a4:	fec05ae3          	blez	a2,498 <memmove+0x2c>
 4a8:	fff6079b          	addiw	a5,a2,-1
 4ac:	1782                	slli	a5,a5,0x20
 4ae:	9381                	srli	a5,a5,0x20
 4b0:	fff7c793          	not	a5,a5
 4b4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4b6:	15fd                	addi	a1,a1,-1
 4b8:	177d                	addi	a4,a4,-1
 4ba:	0005c683          	lbu	a3,0(a1)
 4be:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4c2:	fee79ae3          	bne	a5,a4,4b6 <memmove+0x4a>
 4c6:	bfc9                	j	498 <memmove+0x2c>

00000000000004c8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4c8:	1141                	addi	sp,sp,-16
 4ca:	e422                	sd	s0,8(sp)
 4cc:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4ce:	ca05                	beqz	a2,4fe <memcmp+0x36>
 4d0:	fff6069b          	addiw	a3,a2,-1
 4d4:	1682                	slli	a3,a3,0x20
 4d6:	9281                	srli	a3,a3,0x20
 4d8:	0685                	addi	a3,a3,1
 4da:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4dc:	00054783          	lbu	a5,0(a0)
 4e0:	0005c703          	lbu	a4,0(a1)
 4e4:	00e79863          	bne	a5,a4,4f4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4e8:	0505                	addi	a0,a0,1
    p2++;
 4ea:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4ec:	fed518e3          	bne	a0,a3,4dc <memcmp+0x14>
  }
  return 0;
 4f0:	4501                	li	a0,0
 4f2:	a019                	j	4f8 <memcmp+0x30>
      return *p1 - *p2;
 4f4:	40e7853b          	subw	a0,a5,a4
}
 4f8:	6422                	ld	s0,8(sp)
 4fa:	0141                	addi	sp,sp,16
 4fc:	8082                	ret
  return 0;
 4fe:	4501                	li	a0,0
 500:	bfe5                	j	4f8 <memcmp+0x30>

0000000000000502 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 502:	1141                	addi	sp,sp,-16
 504:	e406                	sd	ra,8(sp)
 506:	e022                	sd	s0,0(sp)
 508:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 50a:	00000097          	auipc	ra,0x0
 50e:	f62080e7          	jalr	-158(ra) # 46c <memmove>
}
 512:	60a2                	ld	ra,8(sp)
 514:	6402                	ld	s0,0(sp)
 516:	0141                	addi	sp,sp,16
 518:	8082                	ret

000000000000051a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 51a:	4885                	li	a7,1
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <exit>:
.global exit
exit:
 li a7, SYS_exit
 522:	4889                	li	a7,2
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <wait>:
.global wait
wait:
 li a7, SYS_wait
 52a:	488d                	li	a7,3
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 532:	4891                	li	a7,4
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <read>:
.global read
read:
 li a7, SYS_read
 53a:	4895                	li	a7,5
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <write>:
.global write
write:
 li a7, SYS_write
 542:	48c1                	li	a7,16
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <close>:
.global close
close:
 li a7, SYS_close
 54a:	48d5                	li	a7,21
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <kill>:
.global kill
kill:
 li a7, SYS_kill
 552:	4899                	li	a7,6
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <exec>:
.global exec
exec:
 li a7, SYS_exec
 55a:	489d                	li	a7,7
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <open>:
.global open
open:
 li a7, SYS_open
 562:	48bd                	li	a7,15
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 56a:	48c5                	li	a7,17
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 572:	48c9                	li	a7,18
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 57a:	48a1                	li	a7,8
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <link>:
.global link
link:
 li a7, SYS_link
 582:	48cd                	li	a7,19
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 58a:	48d1                	li	a7,20
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 592:	48a5                	li	a7,9
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <dup>:
.global dup
dup:
 li a7, SYS_dup
 59a:	48a9                	li	a7,10
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5a2:	48ad                	li	a7,11
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5aa:	48b1                	li	a7,12
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5b2:	48b5                	li	a7,13
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5ba:	48b9                	li	a7,14
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 5c2:	48d9                	li	a7,22
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 5ca:	48dd                	li	a7,23
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5d2:	48e1                	li	a7,24
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5da:	1101                	addi	sp,sp,-32
 5dc:	ec06                	sd	ra,24(sp)
 5de:	e822                	sd	s0,16(sp)
 5e0:	1000                	addi	s0,sp,32
 5e2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5e6:	4605                	li	a2,1
 5e8:	fef40593          	addi	a1,s0,-17
 5ec:	00000097          	auipc	ra,0x0
 5f0:	f56080e7          	jalr	-170(ra) # 542 <write>
}
 5f4:	60e2                	ld	ra,24(sp)
 5f6:	6442                	ld	s0,16(sp)
 5f8:	6105                	addi	sp,sp,32
 5fa:	8082                	ret

00000000000005fc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5fc:	7139                	addi	sp,sp,-64
 5fe:	fc06                	sd	ra,56(sp)
 600:	f822                	sd	s0,48(sp)
 602:	f426                	sd	s1,40(sp)
 604:	f04a                	sd	s2,32(sp)
 606:	ec4e                	sd	s3,24(sp)
 608:	0080                	addi	s0,sp,64
 60a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 60c:	c299                	beqz	a3,612 <printint+0x16>
 60e:	0805c863          	bltz	a1,69e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 612:	2581                	sext.w	a1,a1
  neg = 0;
 614:	4881                	li	a7,0
 616:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 61a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 61c:	2601                	sext.w	a2,a2
 61e:	00000517          	auipc	a0,0x0
 622:	4da50513          	addi	a0,a0,1242 # af8 <digits>
 626:	883a                	mv	a6,a4
 628:	2705                	addiw	a4,a4,1
 62a:	02c5f7bb          	remuw	a5,a1,a2
 62e:	1782                	slli	a5,a5,0x20
 630:	9381                	srli	a5,a5,0x20
 632:	97aa                	add	a5,a5,a0
 634:	0007c783          	lbu	a5,0(a5)
 638:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 63c:	0005879b          	sext.w	a5,a1
 640:	02c5d5bb          	divuw	a1,a1,a2
 644:	0685                	addi	a3,a3,1
 646:	fec7f0e3          	bgeu	a5,a2,626 <printint+0x2a>
  if(neg)
 64a:	00088b63          	beqz	a7,660 <printint+0x64>
    buf[i++] = '-';
 64e:	fd040793          	addi	a5,s0,-48
 652:	973e                	add	a4,a4,a5
 654:	02d00793          	li	a5,45
 658:	fef70823          	sb	a5,-16(a4)
 65c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 660:	02e05863          	blez	a4,690 <printint+0x94>
 664:	fc040793          	addi	a5,s0,-64
 668:	00e78933          	add	s2,a5,a4
 66c:	fff78993          	addi	s3,a5,-1
 670:	99ba                	add	s3,s3,a4
 672:	377d                	addiw	a4,a4,-1
 674:	1702                	slli	a4,a4,0x20
 676:	9301                	srli	a4,a4,0x20
 678:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 67c:	fff94583          	lbu	a1,-1(s2)
 680:	8526                	mv	a0,s1
 682:	00000097          	auipc	ra,0x0
 686:	f58080e7          	jalr	-168(ra) # 5da <putc>
  while(--i >= 0)
 68a:	197d                	addi	s2,s2,-1
 68c:	ff3918e3          	bne	s2,s3,67c <printint+0x80>
}
 690:	70e2                	ld	ra,56(sp)
 692:	7442                	ld	s0,48(sp)
 694:	74a2                	ld	s1,40(sp)
 696:	7902                	ld	s2,32(sp)
 698:	69e2                	ld	s3,24(sp)
 69a:	6121                	addi	sp,sp,64
 69c:	8082                	ret
    x = -xx;
 69e:	40b005bb          	negw	a1,a1
    neg = 1;
 6a2:	4885                	li	a7,1
    x = -xx;
 6a4:	bf8d                	j	616 <printint+0x1a>

00000000000006a6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6a6:	7119                	addi	sp,sp,-128
 6a8:	fc86                	sd	ra,120(sp)
 6aa:	f8a2                	sd	s0,112(sp)
 6ac:	f4a6                	sd	s1,104(sp)
 6ae:	f0ca                	sd	s2,96(sp)
 6b0:	ecce                	sd	s3,88(sp)
 6b2:	e8d2                	sd	s4,80(sp)
 6b4:	e4d6                	sd	s5,72(sp)
 6b6:	e0da                	sd	s6,64(sp)
 6b8:	fc5e                	sd	s7,56(sp)
 6ba:	f862                	sd	s8,48(sp)
 6bc:	f466                	sd	s9,40(sp)
 6be:	f06a                	sd	s10,32(sp)
 6c0:	ec6e                	sd	s11,24(sp)
 6c2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6c4:	0005c903          	lbu	s2,0(a1)
 6c8:	18090f63          	beqz	s2,866 <vprintf+0x1c0>
 6cc:	8aaa                	mv	s5,a0
 6ce:	8b32                	mv	s6,a2
 6d0:	00158493          	addi	s1,a1,1
  state = 0;
 6d4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6d6:	02500a13          	li	s4,37
      if(c == 'd'){
 6da:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6de:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6e2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6e6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ea:	00000b97          	auipc	s7,0x0
 6ee:	40eb8b93          	addi	s7,s7,1038 # af8 <digits>
 6f2:	a839                	j	710 <vprintf+0x6a>
        putc(fd, c);
 6f4:	85ca                	mv	a1,s2
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	ee2080e7          	jalr	-286(ra) # 5da <putc>
 700:	a019                	j	706 <vprintf+0x60>
    } else if(state == '%'){
 702:	01498f63          	beq	s3,s4,720 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 706:	0485                	addi	s1,s1,1
 708:	fff4c903          	lbu	s2,-1(s1)
 70c:	14090d63          	beqz	s2,866 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 710:	0009079b          	sext.w	a5,s2
    if(state == 0){
 714:	fe0997e3          	bnez	s3,702 <vprintf+0x5c>
      if(c == '%'){
 718:	fd479ee3          	bne	a5,s4,6f4 <vprintf+0x4e>
        state = '%';
 71c:	89be                	mv	s3,a5
 71e:	b7e5                	j	706 <vprintf+0x60>
      if(c == 'd'){
 720:	05878063          	beq	a5,s8,760 <vprintf+0xba>
      } else if(c == 'l') {
 724:	05978c63          	beq	a5,s9,77c <vprintf+0xd6>
      } else if(c == 'x') {
 728:	07a78863          	beq	a5,s10,798 <vprintf+0xf2>
      } else if(c == 'p') {
 72c:	09b78463          	beq	a5,s11,7b4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 730:	07300713          	li	a4,115
 734:	0ce78663          	beq	a5,a4,800 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 738:	06300713          	li	a4,99
 73c:	0ee78e63          	beq	a5,a4,838 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 740:	11478863          	beq	a5,s4,850 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 744:	85d2                	mv	a1,s4
 746:	8556                	mv	a0,s5
 748:	00000097          	auipc	ra,0x0
 74c:	e92080e7          	jalr	-366(ra) # 5da <putc>
        putc(fd, c);
 750:	85ca                	mv	a1,s2
 752:	8556                	mv	a0,s5
 754:	00000097          	auipc	ra,0x0
 758:	e86080e7          	jalr	-378(ra) # 5da <putc>
      }
      state = 0;
 75c:	4981                	li	s3,0
 75e:	b765                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 760:	008b0913          	addi	s2,s6,8
 764:	4685                	li	a3,1
 766:	4629                	li	a2,10
 768:	000b2583          	lw	a1,0(s6)
 76c:	8556                	mv	a0,s5
 76e:	00000097          	auipc	ra,0x0
 772:	e8e080e7          	jalr	-370(ra) # 5fc <printint>
 776:	8b4a                	mv	s6,s2
      state = 0;
 778:	4981                	li	s3,0
 77a:	b771                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 77c:	008b0913          	addi	s2,s6,8
 780:	4681                	li	a3,0
 782:	4629                	li	a2,10
 784:	000b2583          	lw	a1,0(s6)
 788:	8556                	mv	a0,s5
 78a:	00000097          	auipc	ra,0x0
 78e:	e72080e7          	jalr	-398(ra) # 5fc <printint>
 792:	8b4a                	mv	s6,s2
      state = 0;
 794:	4981                	li	s3,0
 796:	bf85                	j	706 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 798:	008b0913          	addi	s2,s6,8
 79c:	4681                	li	a3,0
 79e:	4641                	li	a2,16
 7a0:	000b2583          	lw	a1,0(s6)
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	e56080e7          	jalr	-426(ra) # 5fc <printint>
 7ae:	8b4a                	mv	s6,s2
      state = 0;
 7b0:	4981                	li	s3,0
 7b2:	bf91                	j	706 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7b4:	008b0793          	addi	a5,s6,8
 7b8:	f8f43423          	sd	a5,-120(s0)
 7bc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7c0:	03000593          	li	a1,48
 7c4:	8556                	mv	a0,s5
 7c6:	00000097          	auipc	ra,0x0
 7ca:	e14080e7          	jalr	-492(ra) # 5da <putc>
  putc(fd, 'x');
 7ce:	85ea                	mv	a1,s10
 7d0:	8556                	mv	a0,s5
 7d2:	00000097          	auipc	ra,0x0
 7d6:	e08080e7          	jalr	-504(ra) # 5da <putc>
 7da:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7dc:	03c9d793          	srli	a5,s3,0x3c
 7e0:	97de                	add	a5,a5,s7
 7e2:	0007c583          	lbu	a1,0(a5)
 7e6:	8556                	mv	a0,s5
 7e8:	00000097          	auipc	ra,0x0
 7ec:	df2080e7          	jalr	-526(ra) # 5da <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7f0:	0992                	slli	s3,s3,0x4
 7f2:	397d                	addiw	s2,s2,-1
 7f4:	fe0914e3          	bnez	s2,7dc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7f8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7fc:	4981                	li	s3,0
 7fe:	b721                	j	706 <vprintf+0x60>
        s = va_arg(ap, char*);
 800:	008b0993          	addi	s3,s6,8
 804:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 808:	02090163          	beqz	s2,82a <vprintf+0x184>
        while(*s != 0){
 80c:	00094583          	lbu	a1,0(s2)
 810:	c9a1                	beqz	a1,860 <vprintf+0x1ba>
          putc(fd, *s);
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	dc6080e7          	jalr	-570(ra) # 5da <putc>
          s++;
 81c:	0905                	addi	s2,s2,1
        while(*s != 0){
 81e:	00094583          	lbu	a1,0(s2)
 822:	f9e5                	bnez	a1,812 <vprintf+0x16c>
        s = va_arg(ap, char*);
 824:	8b4e                	mv	s6,s3
      state = 0;
 826:	4981                	li	s3,0
 828:	bdf9                	j	706 <vprintf+0x60>
          s = "(null)";
 82a:	00000917          	auipc	s2,0x0
 82e:	2c690913          	addi	s2,s2,710 # af0 <malloc+0x180>
        while(*s != 0){
 832:	02800593          	li	a1,40
 836:	bff1                	j	812 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 838:	008b0913          	addi	s2,s6,8
 83c:	000b4583          	lbu	a1,0(s6)
 840:	8556                	mv	a0,s5
 842:	00000097          	auipc	ra,0x0
 846:	d98080e7          	jalr	-616(ra) # 5da <putc>
 84a:	8b4a                	mv	s6,s2
      state = 0;
 84c:	4981                	li	s3,0
 84e:	bd65                	j	706 <vprintf+0x60>
        putc(fd, c);
 850:	85d2                	mv	a1,s4
 852:	8556                	mv	a0,s5
 854:	00000097          	auipc	ra,0x0
 858:	d86080e7          	jalr	-634(ra) # 5da <putc>
      state = 0;
 85c:	4981                	li	s3,0
 85e:	b565                	j	706 <vprintf+0x60>
        s = va_arg(ap, char*);
 860:	8b4e                	mv	s6,s3
      state = 0;
 862:	4981                	li	s3,0
 864:	b54d                	j	706 <vprintf+0x60>
    }
  }
}
 866:	70e6                	ld	ra,120(sp)
 868:	7446                	ld	s0,112(sp)
 86a:	74a6                	ld	s1,104(sp)
 86c:	7906                	ld	s2,96(sp)
 86e:	69e6                	ld	s3,88(sp)
 870:	6a46                	ld	s4,80(sp)
 872:	6aa6                	ld	s5,72(sp)
 874:	6b06                	ld	s6,64(sp)
 876:	7be2                	ld	s7,56(sp)
 878:	7c42                	ld	s8,48(sp)
 87a:	7ca2                	ld	s9,40(sp)
 87c:	7d02                	ld	s10,32(sp)
 87e:	6de2                	ld	s11,24(sp)
 880:	6109                	addi	sp,sp,128
 882:	8082                	ret

0000000000000884 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 884:	715d                	addi	sp,sp,-80
 886:	ec06                	sd	ra,24(sp)
 888:	e822                	sd	s0,16(sp)
 88a:	1000                	addi	s0,sp,32
 88c:	e010                	sd	a2,0(s0)
 88e:	e414                	sd	a3,8(s0)
 890:	e818                	sd	a4,16(s0)
 892:	ec1c                	sd	a5,24(s0)
 894:	03043023          	sd	a6,32(s0)
 898:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 89c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8a0:	8622                	mv	a2,s0
 8a2:	00000097          	auipc	ra,0x0
 8a6:	e04080e7          	jalr	-508(ra) # 6a6 <vprintf>
}
 8aa:	60e2                	ld	ra,24(sp)
 8ac:	6442                	ld	s0,16(sp)
 8ae:	6161                	addi	sp,sp,80
 8b0:	8082                	ret

00000000000008b2 <printf>:

void
printf(const char *fmt, ...)
{
 8b2:	711d                	addi	sp,sp,-96
 8b4:	ec06                	sd	ra,24(sp)
 8b6:	e822                	sd	s0,16(sp)
 8b8:	1000                	addi	s0,sp,32
 8ba:	e40c                	sd	a1,8(s0)
 8bc:	e810                	sd	a2,16(s0)
 8be:	ec14                	sd	a3,24(s0)
 8c0:	f018                	sd	a4,32(s0)
 8c2:	f41c                	sd	a5,40(s0)
 8c4:	03043823          	sd	a6,48(s0)
 8c8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8cc:	00840613          	addi	a2,s0,8
 8d0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8d4:	85aa                	mv	a1,a0
 8d6:	4505                	li	a0,1
 8d8:	00000097          	auipc	ra,0x0
 8dc:	dce080e7          	jalr	-562(ra) # 6a6 <vprintf>
}
 8e0:	60e2                	ld	ra,24(sp)
 8e2:	6442                	ld	s0,16(sp)
 8e4:	6125                	addi	sp,sp,96
 8e6:	8082                	ret

00000000000008e8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8e8:	1141                	addi	sp,sp,-16
 8ea:	e422                	sd	s0,8(sp)
 8ec:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ee:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8f2:	00000797          	auipc	a5,0x0
 8f6:	21e7b783          	ld	a5,542(a5) # b10 <freep>
 8fa:	a805                	j	92a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8fc:	4618                	lw	a4,8(a2)
 8fe:	9db9                	addw	a1,a1,a4
 900:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 904:	6398                	ld	a4,0(a5)
 906:	6318                	ld	a4,0(a4)
 908:	fee53823          	sd	a4,-16(a0)
 90c:	a091                	j	950 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 90e:	ff852703          	lw	a4,-8(a0)
 912:	9e39                	addw	a2,a2,a4
 914:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 916:	ff053703          	ld	a4,-16(a0)
 91a:	e398                	sd	a4,0(a5)
 91c:	a099                	j	962 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 91e:	6398                	ld	a4,0(a5)
 920:	00e7e463          	bltu	a5,a4,928 <free+0x40>
 924:	00e6ea63          	bltu	a3,a4,938 <free+0x50>
{
 928:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 92a:	fed7fae3          	bgeu	a5,a3,91e <free+0x36>
 92e:	6398                	ld	a4,0(a5)
 930:	00e6e463          	bltu	a3,a4,938 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 934:	fee7eae3          	bltu	a5,a4,928 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 938:	ff852583          	lw	a1,-8(a0)
 93c:	6390                	ld	a2,0(a5)
 93e:	02059713          	slli	a4,a1,0x20
 942:	9301                	srli	a4,a4,0x20
 944:	0712                	slli	a4,a4,0x4
 946:	9736                	add	a4,a4,a3
 948:	fae60ae3          	beq	a2,a4,8fc <free+0x14>
    bp->s.ptr = p->s.ptr;
 94c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 950:	4790                	lw	a2,8(a5)
 952:	02061713          	slli	a4,a2,0x20
 956:	9301                	srli	a4,a4,0x20
 958:	0712                	slli	a4,a4,0x4
 95a:	973e                	add	a4,a4,a5
 95c:	fae689e3          	beq	a3,a4,90e <free+0x26>
  } else
    p->s.ptr = bp;
 960:	e394                	sd	a3,0(a5)
  freep = p;
 962:	00000717          	auipc	a4,0x0
 966:	1af73723          	sd	a5,430(a4) # b10 <freep>
}
 96a:	6422                	ld	s0,8(sp)
 96c:	0141                	addi	sp,sp,16
 96e:	8082                	ret

0000000000000970 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 970:	7139                	addi	sp,sp,-64
 972:	fc06                	sd	ra,56(sp)
 974:	f822                	sd	s0,48(sp)
 976:	f426                	sd	s1,40(sp)
 978:	f04a                	sd	s2,32(sp)
 97a:	ec4e                	sd	s3,24(sp)
 97c:	e852                	sd	s4,16(sp)
 97e:	e456                	sd	s5,8(sp)
 980:	e05a                	sd	s6,0(sp)
 982:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 984:	02051493          	slli	s1,a0,0x20
 988:	9081                	srli	s1,s1,0x20
 98a:	04bd                	addi	s1,s1,15
 98c:	8091                	srli	s1,s1,0x4
 98e:	0014899b          	addiw	s3,s1,1
 992:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 994:	00000517          	auipc	a0,0x0
 998:	17c53503          	ld	a0,380(a0) # b10 <freep>
 99c:	c515                	beqz	a0,9c8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 99e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9a0:	4798                	lw	a4,8(a5)
 9a2:	02977f63          	bgeu	a4,s1,9e0 <malloc+0x70>
 9a6:	8a4e                	mv	s4,s3
 9a8:	0009871b          	sext.w	a4,s3
 9ac:	6685                	lui	a3,0x1
 9ae:	00d77363          	bgeu	a4,a3,9b4 <malloc+0x44>
 9b2:	6a05                	lui	s4,0x1
 9b4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9b8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9bc:	00000917          	auipc	s2,0x0
 9c0:	15490913          	addi	s2,s2,340 # b10 <freep>
  if(p == (char*)-1)
 9c4:	5afd                	li	s5,-1
 9c6:	a88d                	j	a38 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9c8:	00000797          	auipc	a5,0x0
 9cc:	15078793          	addi	a5,a5,336 # b18 <base>
 9d0:	00000717          	auipc	a4,0x0
 9d4:	14f73023          	sd	a5,320(a4) # b10 <freep>
 9d8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9da:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9de:	b7e1                	j	9a6 <malloc+0x36>
      if(p->s.size == nunits)
 9e0:	02e48b63          	beq	s1,a4,a16 <malloc+0xa6>
        p->s.size -= nunits;
 9e4:	4137073b          	subw	a4,a4,s3
 9e8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9ea:	1702                	slli	a4,a4,0x20
 9ec:	9301                	srli	a4,a4,0x20
 9ee:	0712                	slli	a4,a4,0x4
 9f0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9f2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9f6:	00000717          	auipc	a4,0x0
 9fa:	10a73d23          	sd	a0,282(a4) # b10 <freep>
      return (void*)(p + 1);
 9fe:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a02:	70e2                	ld	ra,56(sp)
 a04:	7442                	ld	s0,48(sp)
 a06:	74a2                	ld	s1,40(sp)
 a08:	7902                	ld	s2,32(sp)
 a0a:	69e2                	ld	s3,24(sp)
 a0c:	6a42                	ld	s4,16(sp)
 a0e:	6aa2                	ld	s5,8(sp)
 a10:	6b02                	ld	s6,0(sp)
 a12:	6121                	addi	sp,sp,64
 a14:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a16:	6398                	ld	a4,0(a5)
 a18:	e118                	sd	a4,0(a0)
 a1a:	bff1                	j	9f6 <malloc+0x86>
  hp->s.size = nu;
 a1c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a20:	0541                	addi	a0,a0,16
 a22:	00000097          	auipc	ra,0x0
 a26:	ec6080e7          	jalr	-314(ra) # 8e8 <free>
  return freep;
 a2a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a2e:	d971                	beqz	a0,a02 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a30:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a32:	4798                	lw	a4,8(a5)
 a34:	fa9776e3          	bgeu	a4,s1,9e0 <malloc+0x70>
    if(p == freep)
 a38:	00093703          	ld	a4,0(s2)
 a3c:	853e                	mv	a0,a5
 a3e:	fef719e3          	bne	a4,a5,a30 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a42:	8552                	mv	a0,s4
 a44:	00000097          	auipc	ra,0x0
 a48:	b66080e7          	jalr	-1178(ra) # 5aa <sbrk>
  if(p == (char*)-1)
 a4c:	fd5518e3          	bne	a0,s5,a1c <malloc+0xac>
        return 0;
 a50:	4501                	li	a0,0
 a52:	bf45                	j	a02 <malloc+0x92>
