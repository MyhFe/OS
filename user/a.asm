
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
   c:	a4850513          	addi	a0,a0,-1464 # a50 <malloc+0xe8>
  10:	00001097          	auipc	ra,0x1
  14:	89a080e7          	jalr	-1894(ra) # 8aa <printf>
  18:	001e87b7          	lui	a5,0x1e8
  1c:	48078793          	addi	a5,a5,1152 # 1e8480 <__global_pointer$+0x1e717f>
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
  28:	a3450513          	addi	a0,a0,-1484 # a58 <malloc+0xf0>
  2c:	00001097          	auipc	ra,0x1
  30:	87e080e7          	jalr	-1922(ra) # 8aa <printf>
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
  58:	546080e7          	jalr	1350(ra) # 59a <getpid>
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
  74:	9f0b0b13          	addi	s6,s6,-1552 # a60 <malloc+0xf8>
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
  8e:	510080e7          	jalr	1296(ra) # 59a <getpid>
  92:	ff5514e3          	bne	a0,s5,7a <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  96:	864a                	mv	a2,s2
  98:	85a6                	mv	a1,s1
  9a:	855a                	mv	a0,s6
  9c:	00001097          	auipc	ra,0x1
  a0:	80e080e7          	jalr	-2034(ra) # 8aa <printf>
  a4:	bfd9                	j	7a <kill_system_dem+0x3e>
            kill_sys();
  a6:	00000097          	auipc	ra,0x0
  aa:	514080e7          	jalr	1300(ra) # 5ba <kill_sys>
  ae:	bfc1                	j	7e <kill_system_dem+0x42>
        }
    }
    printf("\n");
  b0:	00001517          	auipc	a0,0x1
  b4:	9d050513          	addi	a0,a0,-1584 # a80 <malloc+0x118>
  b8:	00000097          	auipc	ra,0x0
  bc:	7f2080e7          	jalr	2034(ra) # 8aa <printf>
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
  f4:	4aa080e7          	jalr	1194(ra) # 59a <getpid>
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
 110:	97cb8b93          	addi	s7,s7,-1668 # a88 <malloc+0x120>
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
 12a:	474080e7          	jalr	1140(ra) # 59a <getpid>
 12e:	ff5514e3          	bne	a0,s5,116 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
 132:	864a                	mv	a2,s2
 134:	85a6                	mv	a1,s1
 136:	855e                	mv	a0,s7
 138:	00000097          	auipc	ra,0x0
 13c:	772080e7          	jalr	1906(ra) # 8aa <printf>
 140:	bfd9                	j	116 <pause_system_dem+0x42>
            pause_sys(pause_seconds);
 142:	855a                	mv	a0,s6
 144:	00000097          	auipc	ra,0x0
 148:	47e080e7          	jalr	1150(ra) # 5c2 <pause_sys>
 14c:	b7f9                	j	11a <pause_system_dem+0x46>
        }
    }
    printf("\n");
 14e:	00001517          	auipc	a0,0x1
 152:	93250513          	addi	a0,a0,-1742 # a80 <malloc+0x118>
 156:	00000097          	auipc	ra,0x0
 15a:	754080e7          	jalr	1876(ra) # 8aa <printf>
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
 196:	380080e7          	jalr	896(ra) # 512 <fork>
 19a:	00000097          	auipc	ra,0x0
 19e:	378080e7          	jalr	888(ra) # 512 <fork>
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
 1b2:	912c8c93          	addi	s9,s9,-1774 # ac0 <malloc+0x158>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1b6:	00989937          	lui	s2,0x989
 1ba:	68090913          	addi	s2,s2,1664 # 989680 <__global_pointer$+0x98837f>
 1be:	00001c17          	auipc	s8,0x1
 1c2:	8eac0c13          	addi	s8,s8,-1814 # aa8 <malloc+0x140>
 1c6:	06300b93          	li	s7,99
 1ca:	a821                	j	1e2 <env+0x6e>
        		printf(" ");
 1cc:	8566                	mv	a0,s9
 1ce:	00000097          	auipc	ra,0x0
 1d2:	6dc080e7          	jalr	1756(ra) # 8aa <printf>
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
 1f8:	6b6080e7          	jalr	1718(ra) # 8aa <printf>
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
 20a:	87a50513          	addi	a0,a0,-1926 # a80 <malloc+0x118>
 20e:	00000097          	auipc	ra,0x0
 212:	69c080e7          	jalr	1692(ra) # 8aa <printf>
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
 23c:	89060613          	addi	a2,a2,-1904 # ac8 <malloc+0x160>
 240:	458d                	li	a1,3
 242:	00989537          	lui	a0,0x989
 246:	68050513          	addi	a0,a0,1664 # 989680 <__global_pointer$+0x98837f>
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
 266:	87660613          	addi	a2,a2,-1930 # ad8 <malloc+0x170>
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
    env_large();
 28a:	00000097          	auipc	ra,0x0
 28e:	fa6080e7          	jalr	-90(ra) # 230 <env_large>
    print_stats();
 292:	00000097          	auipc	ra,0x0
 296:	338080e7          	jalr	824(ra) # 5ca <print_stats>


    exit(0);
 29a:	4501                	li	a0,0
 29c:	00000097          	auipc	ra,0x0
 2a0:	27e080e7          	jalr	638(ra) # 51a <exit>

00000000000002a4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2aa:	87aa                	mv	a5,a0
 2ac:	0585                	addi	a1,a1,1
 2ae:	0785                	addi	a5,a5,1
 2b0:	fff5c703          	lbu	a4,-1(a1)
 2b4:	fee78fa3          	sb	a4,-1(a5)
 2b8:	fb75                	bnez	a4,2ac <strcpy+0x8>
    ;
  return os;
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret

00000000000002c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e422                	sd	s0,8(sp)
 2c4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2c6:	00054783          	lbu	a5,0(a0)
 2ca:	cb91                	beqz	a5,2de <strcmp+0x1e>
 2cc:	0005c703          	lbu	a4,0(a1)
 2d0:	00f71763          	bne	a4,a5,2de <strcmp+0x1e>
    p++, q++;
 2d4:	0505                	addi	a0,a0,1
 2d6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2d8:	00054783          	lbu	a5,0(a0)
 2dc:	fbe5                	bnez	a5,2cc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2de:	0005c503          	lbu	a0,0(a1)
}
 2e2:	40a7853b          	subw	a0,a5,a0
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret

00000000000002ec <strlen>:

uint
strlen(const char *s)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	cf91                	beqz	a5,312 <strlen+0x26>
 2f8:	0505                	addi	a0,a0,1
 2fa:	87aa                	mv	a5,a0
 2fc:	4685                	li	a3,1
 2fe:	9e89                	subw	a3,a3,a0
 300:	00f6853b          	addw	a0,a3,a5
 304:	0785                	addi	a5,a5,1
 306:	fff7c703          	lbu	a4,-1(a5)
 30a:	fb7d                	bnez	a4,300 <strlen+0x14>
    ;
  return n;
}
 30c:	6422                	ld	s0,8(sp)
 30e:	0141                	addi	sp,sp,16
 310:	8082                	ret
  for(n = 0; s[n]; n++)
 312:	4501                	li	a0,0
 314:	bfe5                	j	30c <strlen+0x20>

0000000000000316 <memset>:

void*
memset(void *dst, int c, uint n)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 31c:	ce09                	beqz	a2,336 <memset+0x20>
 31e:	87aa                	mv	a5,a0
 320:	fff6071b          	addiw	a4,a2,-1
 324:	1702                	slli	a4,a4,0x20
 326:	9301                	srli	a4,a4,0x20
 328:	0705                	addi	a4,a4,1
 32a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 32c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 330:	0785                	addi	a5,a5,1
 332:	fee79de3          	bne	a5,a4,32c <memset+0x16>
  }
  return dst;
}
 336:	6422                	ld	s0,8(sp)
 338:	0141                	addi	sp,sp,16
 33a:	8082                	ret

000000000000033c <strchr>:

char*
strchr(const char *s, char c)
{
 33c:	1141                	addi	sp,sp,-16
 33e:	e422                	sd	s0,8(sp)
 340:	0800                	addi	s0,sp,16
  for(; *s; s++)
 342:	00054783          	lbu	a5,0(a0)
 346:	cb99                	beqz	a5,35c <strchr+0x20>
    if(*s == c)
 348:	00f58763          	beq	a1,a5,356 <strchr+0x1a>
  for(; *s; s++)
 34c:	0505                	addi	a0,a0,1
 34e:	00054783          	lbu	a5,0(a0)
 352:	fbfd                	bnez	a5,348 <strchr+0xc>
      return (char*)s;
  return 0;
 354:	4501                	li	a0,0
}
 356:	6422                	ld	s0,8(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret
  return 0;
 35c:	4501                	li	a0,0
 35e:	bfe5                	j	356 <strchr+0x1a>

0000000000000360 <gets>:

char*
gets(char *buf, int max)
{
 360:	711d                	addi	sp,sp,-96
 362:	ec86                	sd	ra,88(sp)
 364:	e8a2                	sd	s0,80(sp)
 366:	e4a6                	sd	s1,72(sp)
 368:	e0ca                	sd	s2,64(sp)
 36a:	fc4e                	sd	s3,56(sp)
 36c:	f852                	sd	s4,48(sp)
 36e:	f456                	sd	s5,40(sp)
 370:	f05a                	sd	s6,32(sp)
 372:	ec5e                	sd	s7,24(sp)
 374:	1080                	addi	s0,sp,96
 376:	8baa                	mv	s7,a0
 378:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 37a:	892a                	mv	s2,a0
 37c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 37e:	4aa9                	li	s5,10
 380:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 382:	89a6                	mv	s3,s1
 384:	2485                	addiw	s1,s1,1
 386:	0344d863          	bge	s1,s4,3b6 <gets+0x56>
    cc = read(0, &c, 1);
 38a:	4605                	li	a2,1
 38c:	faf40593          	addi	a1,s0,-81
 390:	4501                	li	a0,0
 392:	00000097          	auipc	ra,0x0
 396:	1a0080e7          	jalr	416(ra) # 532 <read>
    if(cc < 1)
 39a:	00a05e63          	blez	a0,3b6 <gets+0x56>
    buf[i++] = c;
 39e:	faf44783          	lbu	a5,-81(s0)
 3a2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3a6:	01578763          	beq	a5,s5,3b4 <gets+0x54>
 3aa:	0905                	addi	s2,s2,1
 3ac:	fd679be3          	bne	a5,s6,382 <gets+0x22>
  for(i=0; i+1 < max; ){
 3b0:	89a6                	mv	s3,s1
 3b2:	a011                	j	3b6 <gets+0x56>
 3b4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3b6:	99de                	add	s3,s3,s7
 3b8:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2cff>
  return buf;
}
 3bc:	855e                	mv	a0,s7
 3be:	60e6                	ld	ra,88(sp)
 3c0:	6446                	ld	s0,80(sp)
 3c2:	64a6                	ld	s1,72(sp)
 3c4:	6906                	ld	s2,64(sp)
 3c6:	79e2                	ld	s3,56(sp)
 3c8:	7a42                	ld	s4,48(sp)
 3ca:	7aa2                	ld	s5,40(sp)
 3cc:	7b02                	ld	s6,32(sp)
 3ce:	6be2                	ld	s7,24(sp)
 3d0:	6125                	addi	sp,sp,96
 3d2:	8082                	ret

00000000000003d4 <stat>:

int
stat(const char *n, struct stat *st)
{
 3d4:	1101                	addi	sp,sp,-32
 3d6:	ec06                	sd	ra,24(sp)
 3d8:	e822                	sd	s0,16(sp)
 3da:	e426                	sd	s1,8(sp)
 3dc:	e04a                	sd	s2,0(sp)
 3de:	1000                	addi	s0,sp,32
 3e0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3e2:	4581                	li	a1,0
 3e4:	00000097          	auipc	ra,0x0
 3e8:	176080e7          	jalr	374(ra) # 55a <open>
  if(fd < 0)
 3ec:	02054563          	bltz	a0,416 <stat+0x42>
 3f0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3f2:	85ca                	mv	a1,s2
 3f4:	00000097          	auipc	ra,0x0
 3f8:	17e080e7          	jalr	382(ra) # 572 <fstat>
 3fc:	892a                	mv	s2,a0
  close(fd);
 3fe:	8526                	mv	a0,s1
 400:	00000097          	auipc	ra,0x0
 404:	142080e7          	jalr	322(ra) # 542 <close>
  return r;
}
 408:	854a                	mv	a0,s2
 40a:	60e2                	ld	ra,24(sp)
 40c:	6442                	ld	s0,16(sp)
 40e:	64a2                	ld	s1,8(sp)
 410:	6902                	ld	s2,0(sp)
 412:	6105                	addi	sp,sp,32
 414:	8082                	ret
    return -1;
 416:	597d                	li	s2,-1
 418:	bfc5                	j	408 <stat+0x34>

000000000000041a <atoi>:

int
atoi(const char *s)
{
 41a:	1141                	addi	sp,sp,-16
 41c:	e422                	sd	s0,8(sp)
 41e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 420:	00054603          	lbu	a2,0(a0)
 424:	fd06079b          	addiw	a5,a2,-48
 428:	0ff7f793          	andi	a5,a5,255
 42c:	4725                	li	a4,9
 42e:	02f76963          	bltu	a4,a5,460 <atoi+0x46>
 432:	86aa                	mv	a3,a0
  n = 0;
 434:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 436:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 438:	0685                	addi	a3,a3,1
 43a:	0025179b          	slliw	a5,a0,0x2
 43e:	9fa9                	addw	a5,a5,a0
 440:	0017979b          	slliw	a5,a5,0x1
 444:	9fb1                	addw	a5,a5,a2
 446:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 44a:	0006c603          	lbu	a2,0(a3)
 44e:	fd06071b          	addiw	a4,a2,-48
 452:	0ff77713          	andi	a4,a4,255
 456:	fee5f1e3          	bgeu	a1,a4,438 <atoi+0x1e>
  return n;
}
 45a:	6422                	ld	s0,8(sp)
 45c:	0141                	addi	sp,sp,16
 45e:	8082                	ret
  n = 0;
 460:	4501                	li	a0,0
 462:	bfe5                	j	45a <atoi+0x40>

0000000000000464 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 464:	1141                	addi	sp,sp,-16
 466:	e422                	sd	s0,8(sp)
 468:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 46a:	02b57663          	bgeu	a0,a1,496 <memmove+0x32>
    while(n-- > 0)
 46e:	02c05163          	blez	a2,490 <memmove+0x2c>
 472:	fff6079b          	addiw	a5,a2,-1
 476:	1782                	slli	a5,a5,0x20
 478:	9381                	srli	a5,a5,0x20
 47a:	0785                	addi	a5,a5,1
 47c:	97aa                	add	a5,a5,a0
  dst = vdst;
 47e:	872a                	mv	a4,a0
      *dst++ = *src++;
 480:	0585                	addi	a1,a1,1
 482:	0705                	addi	a4,a4,1
 484:	fff5c683          	lbu	a3,-1(a1)
 488:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 48c:	fee79ae3          	bne	a5,a4,480 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 490:	6422                	ld	s0,8(sp)
 492:	0141                	addi	sp,sp,16
 494:	8082                	ret
    dst += n;
 496:	00c50733          	add	a4,a0,a2
    src += n;
 49a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 49c:	fec05ae3          	blez	a2,490 <memmove+0x2c>
 4a0:	fff6079b          	addiw	a5,a2,-1
 4a4:	1782                	slli	a5,a5,0x20
 4a6:	9381                	srli	a5,a5,0x20
 4a8:	fff7c793          	not	a5,a5
 4ac:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4ae:	15fd                	addi	a1,a1,-1
 4b0:	177d                	addi	a4,a4,-1
 4b2:	0005c683          	lbu	a3,0(a1)
 4b6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4ba:	fee79ae3          	bne	a5,a4,4ae <memmove+0x4a>
 4be:	bfc9                	j	490 <memmove+0x2c>

00000000000004c0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4c0:	1141                	addi	sp,sp,-16
 4c2:	e422                	sd	s0,8(sp)
 4c4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4c6:	ca05                	beqz	a2,4f6 <memcmp+0x36>
 4c8:	fff6069b          	addiw	a3,a2,-1
 4cc:	1682                	slli	a3,a3,0x20
 4ce:	9281                	srli	a3,a3,0x20
 4d0:	0685                	addi	a3,a3,1
 4d2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4d4:	00054783          	lbu	a5,0(a0)
 4d8:	0005c703          	lbu	a4,0(a1)
 4dc:	00e79863          	bne	a5,a4,4ec <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4e0:	0505                	addi	a0,a0,1
    p2++;
 4e2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4e4:	fed518e3          	bne	a0,a3,4d4 <memcmp+0x14>
  }
  return 0;
 4e8:	4501                	li	a0,0
 4ea:	a019                	j	4f0 <memcmp+0x30>
      return *p1 - *p2;
 4ec:	40e7853b          	subw	a0,a5,a4
}
 4f0:	6422                	ld	s0,8(sp)
 4f2:	0141                	addi	sp,sp,16
 4f4:	8082                	ret
  return 0;
 4f6:	4501                	li	a0,0
 4f8:	bfe5                	j	4f0 <memcmp+0x30>

00000000000004fa <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4fa:	1141                	addi	sp,sp,-16
 4fc:	e406                	sd	ra,8(sp)
 4fe:	e022                	sd	s0,0(sp)
 500:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 502:	00000097          	auipc	ra,0x0
 506:	f62080e7          	jalr	-158(ra) # 464 <memmove>
}
 50a:	60a2                	ld	ra,8(sp)
 50c:	6402                	ld	s0,0(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret

0000000000000512 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 512:	4885                	li	a7,1
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <exit>:
.global exit
exit:
 li a7, SYS_exit
 51a:	4889                	li	a7,2
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <wait>:
.global wait
wait:
 li a7, SYS_wait
 522:	488d                	li	a7,3
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 52a:	4891                	li	a7,4
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <read>:
.global read
read:
 li a7, SYS_read
 532:	4895                	li	a7,5
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <write>:
.global write
write:
 li a7, SYS_write
 53a:	48c1                	li	a7,16
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <close>:
.global close
close:
 li a7, SYS_close
 542:	48d5                	li	a7,21
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <kill>:
.global kill
kill:
 li a7, SYS_kill
 54a:	4899                	li	a7,6
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <exec>:
.global exec
exec:
 li a7, SYS_exec
 552:	489d                	li	a7,7
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <open>:
.global open
open:
 li a7, SYS_open
 55a:	48bd                	li	a7,15
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 562:	48c5                	li	a7,17
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 56a:	48c9                	li	a7,18
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 572:	48a1                	li	a7,8
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <link>:
.global link
link:
 li a7, SYS_link
 57a:	48cd                	li	a7,19
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 582:	48d1                	li	a7,20
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 58a:	48a5                	li	a7,9
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <dup>:
.global dup
dup:
 li a7, SYS_dup
 592:	48a9                	li	a7,10
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 59a:	48ad                	li	a7,11
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5a2:	48b1                	li	a7,12
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5aa:	48b5                	li	a7,13
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5b2:	48b9                	li	a7,14
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <kill_sys>:
.global kill_sys
kill_sys:
 li a7, SYS_kill_sys
 5ba:	48d9                	li	a7,22
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <pause_sys>:
.global pause_sys
pause_sys:
 li a7, SYS_pause_sys
 5c2:	48dd                	li	a7,23
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5ca:	48e1                	li	a7,24
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5d2:	1101                	addi	sp,sp,-32
 5d4:	ec06                	sd	ra,24(sp)
 5d6:	e822                	sd	s0,16(sp)
 5d8:	1000                	addi	s0,sp,32
 5da:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5de:	4605                	li	a2,1
 5e0:	fef40593          	addi	a1,s0,-17
 5e4:	00000097          	auipc	ra,0x0
 5e8:	f56080e7          	jalr	-170(ra) # 53a <write>
}
 5ec:	60e2                	ld	ra,24(sp)
 5ee:	6442                	ld	s0,16(sp)
 5f0:	6105                	addi	sp,sp,32
 5f2:	8082                	ret

00000000000005f4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5f4:	7139                	addi	sp,sp,-64
 5f6:	fc06                	sd	ra,56(sp)
 5f8:	f822                	sd	s0,48(sp)
 5fa:	f426                	sd	s1,40(sp)
 5fc:	f04a                	sd	s2,32(sp)
 5fe:	ec4e                	sd	s3,24(sp)
 600:	0080                	addi	s0,sp,64
 602:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 604:	c299                	beqz	a3,60a <printint+0x16>
 606:	0805c863          	bltz	a1,696 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 60a:	2581                	sext.w	a1,a1
  neg = 0;
 60c:	4881                	li	a7,0
 60e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 612:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 614:	2601                	sext.w	a2,a2
 616:	00000517          	auipc	a0,0x0
 61a:	4da50513          	addi	a0,a0,1242 # af0 <digits>
 61e:	883a                	mv	a6,a4
 620:	2705                	addiw	a4,a4,1
 622:	02c5f7bb          	remuw	a5,a1,a2
 626:	1782                	slli	a5,a5,0x20
 628:	9381                	srli	a5,a5,0x20
 62a:	97aa                	add	a5,a5,a0
 62c:	0007c783          	lbu	a5,0(a5)
 630:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 634:	0005879b          	sext.w	a5,a1
 638:	02c5d5bb          	divuw	a1,a1,a2
 63c:	0685                	addi	a3,a3,1
 63e:	fec7f0e3          	bgeu	a5,a2,61e <printint+0x2a>
  if(neg)
 642:	00088b63          	beqz	a7,658 <printint+0x64>
    buf[i++] = '-';
 646:	fd040793          	addi	a5,s0,-48
 64a:	973e                	add	a4,a4,a5
 64c:	02d00793          	li	a5,45
 650:	fef70823          	sb	a5,-16(a4)
 654:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 658:	02e05863          	blez	a4,688 <printint+0x94>
 65c:	fc040793          	addi	a5,s0,-64
 660:	00e78933          	add	s2,a5,a4
 664:	fff78993          	addi	s3,a5,-1
 668:	99ba                	add	s3,s3,a4
 66a:	377d                	addiw	a4,a4,-1
 66c:	1702                	slli	a4,a4,0x20
 66e:	9301                	srli	a4,a4,0x20
 670:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 674:	fff94583          	lbu	a1,-1(s2)
 678:	8526                	mv	a0,s1
 67a:	00000097          	auipc	ra,0x0
 67e:	f58080e7          	jalr	-168(ra) # 5d2 <putc>
  while(--i >= 0)
 682:	197d                	addi	s2,s2,-1
 684:	ff3918e3          	bne	s2,s3,674 <printint+0x80>
}
 688:	70e2                	ld	ra,56(sp)
 68a:	7442                	ld	s0,48(sp)
 68c:	74a2                	ld	s1,40(sp)
 68e:	7902                	ld	s2,32(sp)
 690:	69e2                	ld	s3,24(sp)
 692:	6121                	addi	sp,sp,64
 694:	8082                	ret
    x = -xx;
 696:	40b005bb          	negw	a1,a1
    neg = 1;
 69a:	4885                	li	a7,1
    x = -xx;
 69c:	bf8d                	j	60e <printint+0x1a>

000000000000069e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 69e:	7119                	addi	sp,sp,-128
 6a0:	fc86                	sd	ra,120(sp)
 6a2:	f8a2                	sd	s0,112(sp)
 6a4:	f4a6                	sd	s1,104(sp)
 6a6:	f0ca                	sd	s2,96(sp)
 6a8:	ecce                	sd	s3,88(sp)
 6aa:	e8d2                	sd	s4,80(sp)
 6ac:	e4d6                	sd	s5,72(sp)
 6ae:	e0da                	sd	s6,64(sp)
 6b0:	fc5e                	sd	s7,56(sp)
 6b2:	f862                	sd	s8,48(sp)
 6b4:	f466                	sd	s9,40(sp)
 6b6:	f06a                	sd	s10,32(sp)
 6b8:	ec6e                	sd	s11,24(sp)
 6ba:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6bc:	0005c903          	lbu	s2,0(a1)
 6c0:	18090f63          	beqz	s2,85e <vprintf+0x1c0>
 6c4:	8aaa                	mv	s5,a0
 6c6:	8b32                	mv	s6,a2
 6c8:	00158493          	addi	s1,a1,1
  state = 0;
 6cc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6ce:	02500a13          	li	s4,37
      if(c == 'd'){
 6d2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6d6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6da:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6de:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6e2:	00000b97          	auipc	s7,0x0
 6e6:	40eb8b93          	addi	s7,s7,1038 # af0 <digits>
 6ea:	a839                	j	708 <vprintf+0x6a>
        putc(fd, c);
 6ec:	85ca                	mv	a1,s2
 6ee:	8556                	mv	a0,s5
 6f0:	00000097          	auipc	ra,0x0
 6f4:	ee2080e7          	jalr	-286(ra) # 5d2 <putc>
 6f8:	a019                	j	6fe <vprintf+0x60>
    } else if(state == '%'){
 6fa:	01498f63          	beq	s3,s4,718 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6fe:	0485                	addi	s1,s1,1
 700:	fff4c903          	lbu	s2,-1(s1)
 704:	14090d63          	beqz	s2,85e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 708:	0009079b          	sext.w	a5,s2
    if(state == 0){
 70c:	fe0997e3          	bnez	s3,6fa <vprintf+0x5c>
      if(c == '%'){
 710:	fd479ee3          	bne	a5,s4,6ec <vprintf+0x4e>
        state = '%';
 714:	89be                	mv	s3,a5
 716:	b7e5                	j	6fe <vprintf+0x60>
      if(c == 'd'){
 718:	05878063          	beq	a5,s8,758 <vprintf+0xba>
      } else if(c == 'l') {
 71c:	05978c63          	beq	a5,s9,774 <vprintf+0xd6>
      } else if(c == 'x') {
 720:	07a78863          	beq	a5,s10,790 <vprintf+0xf2>
      } else if(c == 'p') {
 724:	09b78463          	beq	a5,s11,7ac <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 728:	07300713          	li	a4,115
 72c:	0ce78663          	beq	a5,a4,7f8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 730:	06300713          	li	a4,99
 734:	0ee78e63          	beq	a5,a4,830 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 738:	11478863          	beq	a5,s4,848 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 73c:	85d2                	mv	a1,s4
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	e92080e7          	jalr	-366(ra) # 5d2 <putc>
        putc(fd, c);
 748:	85ca                	mv	a1,s2
 74a:	8556                	mv	a0,s5
 74c:	00000097          	auipc	ra,0x0
 750:	e86080e7          	jalr	-378(ra) # 5d2 <putc>
      }
      state = 0;
 754:	4981                	li	s3,0
 756:	b765                	j	6fe <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 758:	008b0913          	addi	s2,s6,8
 75c:	4685                	li	a3,1
 75e:	4629                	li	a2,10
 760:	000b2583          	lw	a1,0(s6)
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	e8e080e7          	jalr	-370(ra) # 5f4 <printint>
 76e:	8b4a                	mv	s6,s2
      state = 0;
 770:	4981                	li	s3,0
 772:	b771                	j	6fe <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 774:	008b0913          	addi	s2,s6,8
 778:	4681                	li	a3,0
 77a:	4629                	li	a2,10
 77c:	000b2583          	lw	a1,0(s6)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	e72080e7          	jalr	-398(ra) # 5f4 <printint>
 78a:	8b4a                	mv	s6,s2
      state = 0;
 78c:	4981                	li	s3,0
 78e:	bf85                	j	6fe <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 790:	008b0913          	addi	s2,s6,8
 794:	4681                	li	a3,0
 796:	4641                	li	a2,16
 798:	000b2583          	lw	a1,0(s6)
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	e56080e7          	jalr	-426(ra) # 5f4 <printint>
 7a6:	8b4a                	mv	s6,s2
      state = 0;
 7a8:	4981                	li	s3,0
 7aa:	bf91                	j	6fe <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7ac:	008b0793          	addi	a5,s6,8
 7b0:	f8f43423          	sd	a5,-120(s0)
 7b4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7b8:	03000593          	li	a1,48
 7bc:	8556                	mv	a0,s5
 7be:	00000097          	auipc	ra,0x0
 7c2:	e14080e7          	jalr	-492(ra) # 5d2 <putc>
  putc(fd, 'x');
 7c6:	85ea                	mv	a1,s10
 7c8:	8556                	mv	a0,s5
 7ca:	00000097          	auipc	ra,0x0
 7ce:	e08080e7          	jalr	-504(ra) # 5d2 <putc>
 7d2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7d4:	03c9d793          	srli	a5,s3,0x3c
 7d8:	97de                	add	a5,a5,s7
 7da:	0007c583          	lbu	a1,0(a5)
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	df2080e7          	jalr	-526(ra) # 5d2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7e8:	0992                	slli	s3,s3,0x4
 7ea:	397d                	addiw	s2,s2,-1
 7ec:	fe0914e3          	bnez	s2,7d4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7f0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7f4:	4981                	li	s3,0
 7f6:	b721                	j	6fe <vprintf+0x60>
        s = va_arg(ap, char*);
 7f8:	008b0993          	addi	s3,s6,8
 7fc:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 800:	02090163          	beqz	s2,822 <vprintf+0x184>
        while(*s != 0){
 804:	00094583          	lbu	a1,0(s2)
 808:	c9a1                	beqz	a1,858 <vprintf+0x1ba>
          putc(fd, *s);
 80a:	8556                	mv	a0,s5
 80c:	00000097          	auipc	ra,0x0
 810:	dc6080e7          	jalr	-570(ra) # 5d2 <putc>
          s++;
 814:	0905                	addi	s2,s2,1
        while(*s != 0){
 816:	00094583          	lbu	a1,0(s2)
 81a:	f9e5                	bnez	a1,80a <vprintf+0x16c>
        s = va_arg(ap, char*);
 81c:	8b4e                	mv	s6,s3
      state = 0;
 81e:	4981                	li	s3,0
 820:	bdf9                	j	6fe <vprintf+0x60>
          s = "(null)";
 822:	00000917          	auipc	s2,0x0
 826:	2c690913          	addi	s2,s2,710 # ae8 <malloc+0x180>
        while(*s != 0){
 82a:	02800593          	li	a1,40
 82e:	bff1                	j	80a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 830:	008b0913          	addi	s2,s6,8
 834:	000b4583          	lbu	a1,0(s6)
 838:	8556                	mv	a0,s5
 83a:	00000097          	auipc	ra,0x0
 83e:	d98080e7          	jalr	-616(ra) # 5d2 <putc>
 842:	8b4a                	mv	s6,s2
      state = 0;
 844:	4981                	li	s3,0
 846:	bd65                	j	6fe <vprintf+0x60>
        putc(fd, c);
 848:	85d2                	mv	a1,s4
 84a:	8556                	mv	a0,s5
 84c:	00000097          	auipc	ra,0x0
 850:	d86080e7          	jalr	-634(ra) # 5d2 <putc>
      state = 0;
 854:	4981                	li	s3,0
 856:	b565                	j	6fe <vprintf+0x60>
        s = va_arg(ap, char*);
 858:	8b4e                	mv	s6,s3
      state = 0;
 85a:	4981                	li	s3,0
 85c:	b54d                	j	6fe <vprintf+0x60>
    }
  }
}
 85e:	70e6                	ld	ra,120(sp)
 860:	7446                	ld	s0,112(sp)
 862:	74a6                	ld	s1,104(sp)
 864:	7906                	ld	s2,96(sp)
 866:	69e6                	ld	s3,88(sp)
 868:	6a46                	ld	s4,80(sp)
 86a:	6aa6                	ld	s5,72(sp)
 86c:	6b06                	ld	s6,64(sp)
 86e:	7be2                	ld	s7,56(sp)
 870:	7c42                	ld	s8,48(sp)
 872:	7ca2                	ld	s9,40(sp)
 874:	7d02                	ld	s10,32(sp)
 876:	6de2                	ld	s11,24(sp)
 878:	6109                	addi	sp,sp,128
 87a:	8082                	ret

000000000000087c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 87c:	715d                	addi	sp,sp,-80
 87e:	ec06                	sd	ra,24(sp)
 880:	e822                	sd	s0,16(sp)
 882:	1000                	addi	s0,sp,32
 884:	e010                	sd	a2,0(s0)
 886:	e414                	sd	a3,8(s0)
 888:	e818                	sd	a4,16(s0)
 88a:	ec1c                	sd	a5,24(s0)
 88c:	03043023          	sd	a6,32(s0)
 890:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 894:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 898:	8622                	mv	a2,s0
 89a:	00000097          	auipc	ra,0x0
 89e:	e04080e7          	jalr	-508(ra) # 69e <vprintf>
}
 8a2:	60e2                	ld	ra,24(sp)
 8a4:	6442                	ld	s0,16(sp)
 8a6:	6161                	addi	sp,sp,80
 8a8:	8082                	ret

00000000000008aa <printf>:

void
printf(const char *fmt, ...)
{
 8aa:	711d                	addi	sp,sp,-96
 8ac:	ec06                	sd	ra,24(sp)
 8ae:	e822                	sd	s0,16(sp)
 8b0:	1000                	addi	s0,sp,32
 8b2:	e40c                	sd	a1,8(s0)
 8b4:	e810                	sd	a2,16(s0)
 8b6:	ec14                	sd	a3,24(s0)
 8b8:	f018                	sd	a4,32(s0)
 8ba:	f41c                	sd	a5,40(s0)
 8bc:	03043823          	sd	a6,48(s0)
 8c0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8c4:	00840613          	addi	a2,s0,8
 8c8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8cc:	85aa                	mv	a1,a0
 8ce:	4505                	li	a0,1
 8d0:	00000097          	auipc	ra,0x0
 8d4:	dce080e7          	jalr	-562(ra) # 69e <vprintf>
}
 8d8:	60e2                	ld	ra,24(sp)
 8da:	6442                	ld	s0,16(sp)
 8dc:	6125                	addi	sp,sp,96
 8de:	8082                	ret

00000000000008e0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8e0:	1141                	addi	sp,sp,-16
 8e2:	e422                	sd	s0,8(sp)
 8e4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8e6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ea:	00000797          	auipc	a5,0x0
 8ee:	21e7b783          	ld	a5,542(a5) # b08 <freep>
 8f2:	a805                	j	922 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8f4:	4618                	lw	a4,8(a2)
 8f6:	9db9                	addw	a1,a1,a4
 8f8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8fc:	6398                	ld	a4,0(a5)
 8fe:	6318                	ld	a4,0(a4)
 900:	fee53823          	sd	a4,-16(a0)
 904:	a091                	j	948 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 906:	ff852703          	lw	a4,-8(a0)
 90a:	9e39                	addw	a2,a2,a4
 90c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 90e:	ff053703          	ld	a4,-16(a0)
 912:	e398                	sd	a4,0(a5)
 914:	a099                	j	95a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 916:	6398                	ld	a4,0(a5)
 918:	00e7e463          	bltu	a5,a4,920 <free+0x40>
 91c:	00e6ea63          	bltu	a3,a4,930 <free+0x50>
{
 920:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 922:	fed7fae3          	bgeu	a5,a3,916 <free+0x36>
 926:	6398                	ld	a4,0(a5)
 928:	00e6e463          	bltu	a3,a4,930 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 92c:	fee7eae3          	bltu	a5,a4,920 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 930:	ff852583          	lw	a1,-8(a0)
 934:	6390                	ld	a2,0(a5)
 936:	02059713          	slli	a4,a1,0x20
 93a:	9301                	srli	a4,a4,0x20
 93c:	0712                	slli	a4,a4,0x4
 93e:	9736                	add	a4,a4,a3
 940:	fae60ae3          	beq	a2,a4,8f4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 944:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 948:	4790                	lw	a2,8(a5)
 94a:	02061713          	slli	a4,a2,0x20
 94e:	9301                	srli	a4,a4,0x20
 950:	0712                	slli	a4,a4,0x4
 952:	973e                	add	a4,a4,a5
 954:	fae689e3          	beq	a3,a4,906 <free+0x26>
  } else
    p->s.ptr = bp;
 958:	e394                	sd	a3,0(a5)
  freep = p;
 95a:	00000717          	auipc	a4,0x0
 95e:	1af73723          	sd	a5,430(a4) # b08 <freep>
}
 962:	6422                	ld	s0,8(sp)
 964:	0141                	addi	sp,sp,16
 966:	8082                	ret

0000000000000968 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 968:	7139                	addi	sp,sp,-64
 96a:	fc06                	sd	ra,56(sp)
 96c:	f822                	sd	s0,48(sp)
 96e:	f426                	sd	s1,40(sp)
 970:	f04a                	sd	s2,32(sp)
 972:	ec4e                	sd	s3,24(sp)
 974:	e852                	sd	s4,16(sp)
 976:	e456                	sd	s5,8(sp)
 978:	e05a                	sd	s6,0(sp)
 97a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 97c:	02051493          	slli	s1,a0,0x20
 980:	9081                	srli	s1,s1,0x20
 982:	04bd                	addi	s1,s1,15
 984:	8091                	srli	s1,s1,0x4
 986:	0014899b          	addiw	s3,s1,1
 98a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 98c:	00000517          	auipc	a0,0x0
 990:	17c53503          	ld	a0,380(a0) # b08 <freep>
 994:	c515                	beqz	a0,9c0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 996:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 998:	4798                	lw	a4,8(a5)
 99a:	02977f63          	bgeu	a4,s1,9d8 <malloc+0x70>
 99e:	8a4e                	mv	s4,s3
 9a0:	0009871b          	sext.w	a4,s3
 9a4:	6685                	lui	a3,0x1
 9a6:	00d77363          	bgeu	a4,a3,9ac <malloc+0x44>
 9aa:	6a05                	lui	s4,0x1
 9ac:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9b0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9b4:	00000917          	auipc	s2,0x0
 9b8:	15490913          	addi	s2,s2,340 # b08 <freep>
  if(p == (char*)-1)
 9bc:	5afd                	li	s5,-1
 9be:	a88d                	j	a30 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9c0:	00000797          	auipc	a5,0x0
 9c4:	15078793          	addi	a5,a5,336 # b10 <base>
 9c8:	00000717          	auipc	a4,0x0
 9cc:	14f73023          	sd	a5,320(a4) # b08 <freep>
 9d0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9d2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9d6:	b7e1                	j	99e <malloc+0x36>
      if(p->s.size == nunits)
 9d8:	02e48b63          	beq	s1,a4,a0e <malloc+0xa6>
        p->s.size -= nunits;
 9dc:	4137073b          	subw	a4,a4,s3
 9e0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9e2:	1702                	slli	a4,a4,0x20
 9e4:	9301                	srli	a4,a4,0x20
 9e6:	0712                	slli	a4,a4,0x4
 9e8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9ea:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9ee:	00000717          	auipc	a4,0x0
 9f2:	10a73d23          	sd	a0,282(a4) # b08 <freep>
      return (void*)(p + 1);
 9f6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9fa:	70e2                	ld	ra,56(sp)
 9fc:	7442                	ld	s0,48(sp)
 9fe:	74a2                	ld	s1,40(sp)
 a00:	7902                	ld	s2,32(sp)
 a02:	69e2                	ld	s3,24(sp)
 a04:	6a42                	ld	s4,16(sp)
 a06:	6aa2                	ld	s5,8(sp)
 a08:	6b02                	ld	s6,0(sp)
 a0a:	6121                	addi	sp,sp,64
 a0c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a0e:	6398                	ld	a4,0(a5)
 a10:	e118                	sd	a4,0(a0)
 a12:	bff1                	j	9ee <malloc+0x86>
  hp->s.size = nu;
 a14:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a18:	0541                	addi	a0,a0,16
 a1a:	00000097          	auipc	ra,0x0
 a1e:	ec6080e7          	jalr	-314(ra) # 8e0 <free>
  return freep;
 a22:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a26:	d971                	beqz	a0,9fa <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a28:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a2a:	4798                	lw	a4,8(a5)
 a2c:	fa9776e3          	bgeu	a4,s1,9d8 <malloc+0x70>
    if(p == freep)
 a30:	00093703          	ld	a4,0(s2)
 a34:	853e                	mv	a0,a5
 a36:	fef719e3          	bne	a4,a5,a28 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a3a:	8552                	mv	a0,s4
 a3c:	00000097          	auipc	ra,0x0
 a40:	b66080e7          	jalr	-1178(ra) # 5a2 <sbrk>
  if(p == (char*)-1)
 a44:	fd5518e3          	bne	a0,s5,a14 <malloc+0xac>
        return 0;
 a48:	4501                	li	a0,0
 a4a:	bf45                	j	9fa <malloc+0x92>
