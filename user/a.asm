
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
   c:	a2850513          	addi	a0,a0,-1496 # a30 <malloc+0xe4>
  10:	00001097          	auipc	ra,0x1
  14:	87e080e7          	jalr	-1922(ra) # 88e <printf>
  18:	001e87b7          	lui	a5,0x1e8
  1c:	48078793          	addi	a5,a5,1152 # 1e8480 <__global_pointer$+0x1e719f>
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
  28:	a1450513          	addi	a0,a0,-1516 # a38 <malloc+0xec>
  2c:	00001097          	auipc	ra,0x1
  30:	862080e7          	jalr	-1950(ra) # 88e <printf>
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
  58:	52a080e7          	jalr	1322(ra) # 57e <getpid>
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
  74:	9d0b0b13          	addi	s6,s6,-1584 # a40 <malloc+0xf4>
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
  8e:	4f4080e7          	jalr	1268(ra) # 57e <getpid>
  92:	ff5514e3          	bne	a0,s5,7a <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  96:	864a                	mv	a2,s2
  98:	85a6                	mv	a1,s1
  9a:	855a                	mv	a0,s6
  9c:	00000097          	auipc	ra,0x0
  a0:	7f2080e7          	jalr	2034(ra) # 88e <printf>
  a4:	bfd9                	j	7a <kill_system_dem+0x3e>
            kill_sys();
  a6:	00000097          	auipc	ra,0x0
  aa:	4f8080e7          	jalr	1272(ra) # 59e <kill_sys>
  ae:	bfc1                	j	7e <kill_system_dem+0x42>
        }
    }
    printf("\n");
  b0:	00001517          	auipc	a0,0x1
  b4:	9b050513          	addi	a0,a0,-1616 # a60 <malloc+0x114>
  b8:	00000097          	auipc	ra,0x0
  bc:	7d6080e7          	jalr	2006(ra) # 88e <printf>
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
  f4:	48e080e7          	jalr	1166(ra) # 57e <getpid>
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
 110:	95cb8b93          	addi	s7,s7,-1700 # a68 <malloc+0x11c>
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
 12a:	458080e7          	jalr	1112(ra) # 57e <getpid>
 12e:	ff5514e3          	bne	a0,s5,116 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
 132:	864a                	mv	a2,s2
 134:	85a6                	mv	a1,s1
 136:	855e                	mv	a0,s7
 138:	00000097          	auipc	ra,0x0
 13c:	756080e7          	jalr	1878(ra) # 88e <printf>
 140:	bfd9                	j	116 <pause_system_dem+0x42>
            pause_sys(pause_seconds);
 142:	855a                	mv	a0,s6
 144:	00000097          	auipc	ra,0x0
 148:	462080e7          	jalr	1122(ra) # 5a6 <pause_sys>
 14c:	b7f9                	j	11a <pause_system_dem+0x46>
        }
    }
    printf("\n");
 14e:	00001517          	auipc	a0,0x1
 152:	91250513          	addi	a0,a0,-1774 # a60 <malloc+0x114>
 156:	00000097          	auipc	ra,0x0
 15a:	738080e7          	jalr	1848(ra) # 88e <printf>
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
 174:	715d                	addi	sp,sp,-80
 176:	e486                	sd	ra,72(sp)
 178:	e0a2                	sd	s0,64(sp)
 17a:	fc26                	sd	s1,56(sp)
 17c:	f84a                	sd	s2,48(sp)
 17e:	f44e                	sd	s3,40(sp)
 180:	f052                	sd	s4,32(sp)
 182:	ec56                	sd	s5,24(sp)
 184:	e85a                	sd	s6,16(sp)
 186:	e45e                	sd	s7,8(sp)
 188:	0880                	addi	s0,sp,80
 18a:	8ab2                	mv	s5,a2
    int result = 1;
    int loop_size = (int)(10e6);
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 18c:	00000097          	auipc	ra,0x0
 190:	36a080e7          	jalr	874(ra) # 4f6 <fork>
 194:	00000097          	auipc	ra,0x0
 198:	362080e7          	jalr	866(ra) # 4f6 <fork>
 19c:	8a2a                	mv	s4,a0
    }
    for (int i = 0; i < loop_size; i++) {
 19e:	4481                	li	s1,0
        if (i % (int)(loop_size / 10e0) == 0) {
 1a0:	000f49b7          	lui	s3,0xf4
 1a4:	2409899b          	addiw	s3,s3,576
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
 1a8:	00001b97          	auipc	s7,0x1
 1ac:	8f8b8b93          	addi	s7,s7,-1800 # aa0 <malloc+0x154>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1b0:	00989937          	lui	s2,0x989
 1b4:	68090913          	addi	s2,s2,1664 # 989680 <__global_pointer$+0x98839f>
 1b8:	00001b17          	auipc	s6,0x1
 1bc:	8d0b0b13          	addi	s6,s6,-1840 # a88 <malloc+0x13c>
 1c0:	a809                	j	1d2 <env+0x5e>
        		printf(" ");
 1c2:	855e                	mv	a0,s7
 1c4:	00000097          	auipc	ra,0x0
 1c8:	6ca080e7          	jalr	1738(ra) # 88e <printf>
    for (int i = 0; i < loop_size; i++) {
 1cc:	2485                	addiw	s1,s1,1
 1ce:	03248063          	beq	s1,s2,1ee <env+0x7a>
        if (i % (int)(loop_size / 10e0) == 0) {
 1d2:	0334e7bb          	remw	a5,s1,s3
 1d6:	fbfd                	bnez	a5,1cc <env+0x58>
        	if (pid == 0) {
 1d8:	fe0a15e3          	bnez	s4,1c2 <env+0x4e>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1dc:	86ca                	mv	a3,s2
 1de:	8626                	mv	a2,s1
 1e0:	85d6                	mv	a1,s5
 1e2:	855a                	mv	a0,s6
 1e4:	00000097          	auipc	ra,0x0
 1e8:	6aa080e7          	jalr	1706(ra) # 88e <printf>
 1ec:	b7c5                	j	1cc <env+0x58>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 1ee:	00001517          	auipc	a0,0x1
 1f2:	87250513          	addi	a0,a0,-1934 # a60 <malloc+0x114>
 1f6:	00000097          	auipc	ra,0x0
 1fa:	698080e7          	jalr	1688(ra) # 88e <printf>
}
 1fe:	60a6                	ld	ra,72(sp)
 200:	6406                	ld	s0,64(sp)
 202:	74e2                	ld	s1,56(sp)
 204:	7942                	ld	s2,48(sp)
 206:	79a2                	ld	s3,40(sp)
 208:	7a02                	ld	s4,32(sp)
 20a:	6ae2                	ld	s5,24(sp)
 20c:	6b42                	ld	s6,16(sp)
 20e:	6ba2                	ld	s7,8(sp)
 210:	6161                	addi	sp,sp,80
 212:	8082                	ret

0000000000000214 <env_large>:

void env_large() {
 214:	1141                	addi	sp,sp,-16
 216:	e406                	sd	ra,8(sp)
 218:	e022                	sd	s0,0(sp)
 21a:	0800                	addi	s0,sp,16
    env(10e6, 10e6, "env_large");
 21c:	00001617          	auipc	a2,0x1
 220:	88c60613          	addi	a2,a2,-1908 # aa8 <malloc+0x15c>
 224:	009895b7          	lui	a1,0x989
 228:	68058593          	addi	a1,a1,1664 # 989680 <__global_pointer$+0x98839f>
 22c:	852e                	mv	a0,a1
 22e:	00000097          	auipc	ra,0x0
 232:	f46080e7          	jalr	-186(ra) # 174 <env>
}
 236:	60a2                	ld	ra,8(sp)
 238:	6402                	ld	s0,0(sp)
 23a:	0141                	addi	sp,sp,16
 23c:	8082                	ret

000000000000023e <env_freq>:

void env_freq() {
 23e:	1141                	addi	sp,sp,-16
 240:	e406                	sd	ra,8(sp)
 242:	e022                	sd	s0,0(sp)
 244:	0800                	addi	s0,sp,16
    env(10e1, 10e1, "env_freq");
 246:	00001617          	auipc	a2,0x1
 24a:	87260613          	addi	a2,a2,-1934 # ab8 <malloc+0x16c>
 24e:	06400593          	li	a1,100
 252:	06400513          	li	a0,100
 256:	00000097          	auipc	ra,0x0
 25a:	f1e080e7          	jalr	-226(ra) # 174 <env>
}
 25e:	60a2                	ld	ra,8(sp)
 260:	6402                	ld	s0,0(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret

0000000000000266 <main>:

int
main(int argc, char *argv[])
{
 266:	1141                	addi	sp,sp,-16
 268:	e406                	sd	ra,8(sp)
 26a:	e022                	sd	s0,0(sp)
 26c:	0800                	addi	s0,sp,16
    env_large();
 26e:	00000097          	auipc	ra,0x0
 272:	fa6080e7          	jalr	-90(ra) # 214 <env_large>
    print_stats();
 276:	00000097          	auipc	ra,0x0
 27a:	338080e7          	jalr	824(ra) # 5ae <print_stats>


    exit(0);
 27e:	4501                	li	a0,0
 280:	00000097          	auipc	ra,0x0
 284:	27e080e7          	jalr	638(ra) # 4fe <exit>

0000000000000288 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e422                	sd	s0,8(sp)
 28c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 28e:	87aa                	mv	a5,a0
 290:	0585                	addi	a1,a1,1
 292:	0785                	addi	a5,a5,1
 294:	fff5c703          	lbu	a4,-1(a1)
 298:	fee78fa3          	sb	a4,-1(a5)
 29c:	fb75                	bnez	a4,290 <strcpy+0x8>
    ;
  return os;
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret

00000000000002a4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2aa:	00054783          	lbu	a5,0(a0)
 2ae:	cb91                	beqz	a5,2c2 <strcmp+0x1e>
 2b0:	0005c703          	lbu	a4,0(a1)
 2b4:	00f71763          	bne	a4,a5,2c2 <strcmp+0x1e>
    p++, q++;
 2b8:	0505                	addi	a0,a0,1
 2ba:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2bc:	00054783          	lbu	a5,0(a0)
 2c0:	fbe5                	bnez	a5,2b0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2c2:	0005c503          	lbu	a0,0(a1)
}
 2c6:	40a7853b          	subw	a0,a5,a0
 2ca:	6422                	ld	s0,8(sp)
 2cc:	0141                	addi	sp,sp,16
 2ce:	8082                	ret

00000000000002d0 <strlen>:

uint
strlen(const char *s)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2d6:	00054783          	lbu	a5,0(a0)
 2da:	cf91                	beqz	a5,2f6 <strlen+0x26>
 2dc:	0505                	addi	a0,a0,1
 2de:	87aa                	mv	a5,a0
 2e0:	4685                	li	a3,1
 2e2:	9e89                	subw	a3,a3,a0
 2e4:	00f6853b          	addw	a0,a3,a5
 2e8:	0785                	addi	a5,a5,1
 2ea:	fff7c703          	lbu	a4,-1(a5)
 2ee:	fb7d                	bnez	a4,2e4 <strlen+0x14>
    ;
  return n;
}
 2f0:	6422                	ld	s0,8(sp)
 2f2:	0141                	addi	sp,sp,16
 2f4:	8082                	ret
  for(n = 0; s[n]; n++)
 2f6:	4501                	li	a0,0
 2f8:	bfe5                	j	2f0 <strlen+0x20>

00000000000002fa <memset>:

void*
memset(void *dst, int c, uint n)
{
 2fa:	1141                	addi	sp,sp,-16
 2fc:	e422                	sd	s0,8(sp)
 2fe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 300:	ce09                	beqz	a2,31a <memset+0x20>
 302:	87aa                	mv	a5,a0
 304:	fff6071b          	addiw	a4,a2,-1
 308:	1702                	slli	a4,a4,0x20
 30a:	9301                	srli	a4,a4,0x20
 30c:	0705                	addi	a4,a4,1
 30e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 310:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 314:	0785                	addi	a5,a5,1
 316:	fee79de3          	bne	a5,a4,310 <memset+0x16>
  }
  return dst;
}
 31a:	6422                	ld	s0,8(sp)
 31c:	0141                	addi	sp,sp,16
 31e:	8082                	ret

0000000000000320 <strchr>:

char*
strchr(const char *s, char c)
{
 320:	1141                	addi	sp,sp,-16
 322:	e422                	sd	s0,8(sp)
 324:	0800                	addi	s0,sp,16
  for(; *s; s++)
 326:	00054783          	lbu	a5,0(a0)
 32a:	cb99                	beqz	a5,340 <strchr+0x20>
    if(*s == c)
 32c:	00f58763          	beq	a1,a5,33a <strchr+0x1a>
  for(; *s; s++)
 330:	0505                	addi	a0,a0,1
 332:	00054783          	lbu	a5,0(a0)
 336:	fbfd                	bnez	a5,32c <strchr+0xc>
      return (char*)s;
  return 0;
 338:	4501                	li	a0,0
}
 33a:	6422                	ld	s0,8(sp)
 33c:	0141                	addi	sp,sp,16
 33e:	8082                	ret
  return 0;
 340:	4501                	li	a0,0
 342:	bfe5                	j	33a <strchr+0x1a>

0000000000000344 <gets>:

char*
gets(char *buf, int max)
{
 344:	711d                	addi	sp,sp,-96
 346:	ec86                	sd	ra,88(sp)
 348:	e8a2                	sd	s0,80(sp)
 34a:	e4a6                	sd	s1,72(sp)
 34c:	e0ca                	sd	s2,64(sp)
 34e:	fc4e                	sd	s3,56(sp)
 350:	f852                	sd	s4,48(sp)
 352:	f456                	sd	s5,40(sp)
 354:	f05a                	sd	s6,32(sp)
 356:	ec5e                	sd	s7,24(sp)
 358:	1080                	addi	s0,sp,96
 35a:	8baa                	mv	s7,a0
 35c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 35e:	892a                	mv	s2,a0
 360:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 362:	4aa9                	li	s5,10
 364:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 366:	89a6                	mv	s3,s1
 368:	2485                	addiw	s1,s1,1
 36a:	0344d863          	bge	s1,s4,39a <gets+0x56>
    cc = read(0, &c, 1);
 36e:	4605                	li	a2,1
 370:	faf40593          	addi	a1,s0,-81
 374:	4501                	li	a0,0
 376:	00000097          	auipc	ra,0x0
 37a:	1a0080e7          	jalr	416(ra) # 516 <read>
    if(cc < 1)
 37e:	00a05e63          	blez	a0,39a <gets+0x56>
    buf[i++] = c;
 382:	faf44783          	lbu	a5,-81(s0)
 386:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 38a:	01578763          	beq	a5,s5,398 <gets+0x54>
 38e:	0905                	addi	s2,s2,1
 390:	fd679be3          	bne	a5,s6,366 <gets+0x22>
  for(i=0; i+1 < max; ){
 394:	89a6                	mv	s3,s1
 396:	a011                	j	39a <gets+0x56>
 398:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 39a:	99de                	add	s3,s3,s7
 39c:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2d1f>
  return buf;
}
 3a0:	855e                	mv	a0,s7
 3a2:	60e6                	ld	ra,88(sp)
 3a4:	6446                	ld	s0,80(sp)
 3a6:	64a6                	ld	s1,72(sp)
 3a8:	6906                	ld	s2,64(sp)
 3aa:	79e2                	ld	s3,56(sp)
 3ac:	7a42                	ld	s4,48(sp)
 3ae:	7aa2                	ld	s5,40(sp)
 3b0:	7b02                	ld	s6,32(sp)
 3b2:	6be2                	ld	s7,24(sp)
 3b4:	6125                	addi	sp,sp,96
 3b6:	8082                	ret

00000000000003b8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3b8:	1101                	addi	sp,sp,-32
 3ba:	ec06                	sd	ra,24(sp)
 3bc:	e822                	sd	s0,16(sp)
 3be:	e426                	sd	s1,8(sp)
 3c0:	e04a                	sd	s2,0(sp)
 3c2:	1000                	addi	s0,sp,32
 3c4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3c6:	4581                	li	a1,0
 3c8:	00000097          	auipc	ra,0x0
 3cc:	176080e7          	jalr	374(ra) # 53e <open>
  if(fd < 0)
 3d0:	02054563          	bltz	a0,3fa <stat+0x42>
 3d4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3d6:	85ca                	mv	a1,s2
 3d8:	00000097          	auipc	ra,0x0
 3dc:	17e080e7          	jalr	382(ra) # 556 <fstat>
 3e0:	892a                	mv	s2,a0
  close(fd);
 3e2:	8526                	mv	a0,s1
 3e4:	00000097          	auipc	ra,0x0
 3e8:	142080e7          	jalr	322(ra) # 526 <close>
  return r;
}
 3ec:	854a                	mv	a0,s2
 3ee:	60e2                	ld	ra,24(sp)
 3f0:	6442                	ld	s0,16(sp)
 3f2:	64a2                	ld	s1,8(sp)
 3f4:	6902                	ld	s2,0(sp)
 3f6:	6105                	addi	sp,sp,32
 3f8:	8082                	ret
    return -1;
 3fa:	597d                	li	s2,-1
 3fc:	bfc5                	j	3ec <stat+0x34>

00000000000003fe <atoi>:

int
atoi(const char *s)
{
 3fe:	1141                	addi	sp,sp,-16
 400:	e422                	sd	s0,8(sp)
 402:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 404:	00054603          	lbu	a2,0(a0)
 408:	fd06079b          	addiw	a5,a2,-48
 40c:	0ff7f793          	andi	a5,a5,255
 410:	4725                	li	a4,9
 412:	02f76963          	bltu	a4,a5,444 <atoi+0x46>
 416:	86aa                	mv	a3,a0
  n = 0;
 418:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 41a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 41c:	0685                	addi	a3,a3,1
 41e:	0025179b          	slliw	a5,a0,0x2
 422:	9fa9                	addw	a5,a5,a0
 424:	0017979b          	slliw	a5,a5,0x1
 428:	9fb1                	addw	a5,a5,a2
 42a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 42e:	0006c603          	lbu	a2,0(a3)
 432:	fd06071b          	addiw	a4,a2,-48
 436:	0ff77713          	andi	a4,a4,255
 43a:	fee5f1e3          	bgeu	a1,a4,41c <atoi+0x1e>
  return n;
}
 43e:	6422                	ld	s0,8(sp)
 440:	0141                	addi	sp,sp,16
 442:	8082                	ret
  n = 0;
 444:	4501                	li	a0,0
 446:	bfe5                	j	43e <atoi+0x40>

0000000000000448 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 448:	1141                	addi	sp,sp,-16
 44a:	e422                	sd	s0,8(sp)
 44c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 44e:	02b57663          	bgeu	a0,a1,47a <memmove+0x32>
    while(n-- > 0)
 452:	02c05163          	blez	a2,474 <memmove+0x2c>
 456:	fff6079b          	addiw	a5,a2,-1
 45a:	1782                	slli	a5,a5,0x20
 45c:	9381                	srli	a5,a5,0x20
 45e:	0785                	addi	a5,a5,1
 460:	97aa                	add	a5,a5,a0
  dst = vdst;
 462:	872a                	mv	a4,a0
      *dst++ = *src++;
 464:	0585                	addi	a1,a1,1
 466:	0705                	addi	a4,a4,1
 468:	fff5c683          	lbu	a3,-1(a1)
 46c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 470:	fee79ae3          	bne	a5,a4,464 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 474:	6422                	ld	s0,8(sp)
 476:	0141                	addi	sp,sp,16
 478:	8082                	ret
    dst += n;
 47a:	00c50733          	add	a4,a0,a2
    src += n;
 47e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 480:	fec05ae3          	blez	a2,474 <memmove+0x2c>
 484:	fff6079b          	addiw	a5,a2,-1
 488:	1782                	slli	a5,a5,0x20
 48a:	9381                	srli	a5,a5,0x20
 48c:	fff7c793          	not	a5,a5
 490:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 492:	15fd                	addi	a1,a1,-1
 494:	177d                	addi	a4,a4,-1
 496:	0005c683          	lbu	a3,0(a1)
 49a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 49e:	fee79ae3          	bne	a5,a4,492 <memmove+0x4a>
 4a2:	bfc9                	j	474 <memmove+0x2c>

00000000000004a4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4a4:	1141                	addi	sp,sp,-16
 4a6:	e422                	sd	s0,8(sp)
 4a8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4aa:	ca05                	beqz	a2,4da <memcmp+0x36>
 4ac:	fff6069b          	addiw	a3,a2,-1
 4b0:	1682                	slli	a3,a3,0x20
 4b2:	9281                	srli	a3,a3,0x20
 4b4:	0685                	addi	a3,a3,1
 4b6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4b8:	00054783          	lbu	a5,0(a0)
 4bc:	0005c703          	lbu	a4,0(a1)
 4c0:	00e79863          	bne	a5,a4,4d0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4c4:	0505                	addi	a0,a0,1
    p2++;
 4c6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4c8:	fed518e3          	bne	a0,a3,4b8 <memcmp+0x14>
  }
  return 0;
 4cc:	4501                	li	a0,0
 4ce:	a019                	j	4d4 <memcmp+0x30>
      return *p1 - *p2;
 4d0:	40e7853b          	subw	a0,a5,a4
}
 4d4:	6422                	ld	s0,8(sp)
 4d6:	0141                	addi	sp,sp,16
 4d8:	8082                	ret
  return 0;
 4da:	4501                	li	a0,0
 4dc:	bfe5                	j	4d4 <memcmp+0x30>

00000000000004de <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4de:	1141                	addi	sp,sp,-16
 4e0:	e406                	sd	ra,8(sp)
 4e2:	e022                	sd	s0,0(sp)
 4e4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4e6:	00000097          	auipc	ra,0x0
 4ea:	f62080e7          	jalr	-158(ra) # 448 <memmove>
}
 4ee:	60a2                	ld	ra,8(sp)
 4f0:	6402                	ld	s0,0(sp)
 4f2:	0141                	addi	sp,sp,16
 4f4:	8082                	ret

00000000000004f6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4f6:	4885                	li	a7,1
 ecall
 4f8:	00000073          	ecall
 ret
 4fc:	8082                	ret

00000000000004fe <exit>:
.global exit
exit:
 li a7, SYS_exit
 4fe:	4889                	li	a7,2
 ecall
 500:	00000073          	ecall
 ret
 504:	8082                	ret

0000000000000506 <wait>:
.global wait
wait:
 li a7, SYS_wait
 506:	488d                	li	a7,3
 ecall
 508:	00000073          	ecall
 ret
 50c:	8082                	ret

000000000000050e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 50e:	4891                	li	a7,4
 ecall
 510:	00000073          	ecall
 ret
 514:	8082                	ret

0000000000000516 <read>:
.global read
read:
 li a7, SYS_read
 516:	4895                	li	a7,5
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <write>:
.global write
write:
 li a7, SYS_write
 51e:	48c1                	li	a7,16
 ecall
 520:	00000073          	ecall
 ret
 524:	8082                	ret

0000000000000526 <close>:
.global close
close:
 li a7, SYS_close
 526:	48d5                	li	a7,21
 ecall
 528:	00000073          	ecall
 ret
 52c:	8082                	ret

000000000000052e <kill>:
.global kill
kill:
 li a7, SYS_kill
 52e:	4899                	li	a7,6
 ecall
 530:	00000073          	ecall
 ret
 534:	8082                	ret

0000000000000536 <exec>:
.global exec
exec:
 li a7, SYS_exec
 536:	489d                	li	a7,7
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <open>:
.global open
open:
 li a7, SYS_open
 53e:	48bd                	li	a7,15
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 546:	48c5                	li	a7,17
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 54e:	48c9                	li	a7,18
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 556:	48a1                	li	a7,8
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <link>:
.global link
link:
 li a7, SYS_link
 55e:	48cd                	li	a7,19
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 566:	48d1                	li	a7,20
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 56e:	48a5                	li	a7,9
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <dup>:
.global dup
dup:
 li a7, SYS_dup
 576:	48a9                	li	a7,10
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 57e:	48ad                	li	a7,11
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 586:	48b1                	li	a7,12
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 58e:	48b5                	li	a7,13
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 596:	48b9                	li	a7,14
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <kill_sys>:
.global kill_sys
kill_sys:
 li a7, SYS_kill_sys
 59e:	48d9                	li	a7,22
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <pause_sys>:
.global pause_sys
pause_sys:
 li a7, SYS_pause_sys
 5a6:	48dd                	li	a7,23
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5ae:	48e1                	li	a7,24
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5b6:	1101                	addi	sp,sp,-32
 5b8:	ec06                	sd	ra,24(sp)
 5ba:	e822                	sd	s0,16(sp)
 5bc:	1000                	addi	s0,sp,32
 5be:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5c2:	4605                	li	a2,1
 5c4:	fef40593          	addi	a1,s0,-17
 5c8:	00000097          	auipc	ra,0x0
 5cc:	f56080e7          	jalr	-170(ra) # 51e <write>
}
 5d0:	60e2                	ld	ra,24(sp)
 5d2:	6442                	ld	s0,16(sp)
 5d4:	6105                	addi	sp,sp,32
 5d6:	8082                	ret

00000000000005d8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5d8:	7139                	addi	sp,sp,-64
 5da:	fc06                	sd	ra,56(sp)
 5dc:	f822                	sd	s0,48(sp)
 5de:	f426                	sd	s1,40(sp)
 5e0:	f04a                	sd	s2,32(sp)
 5e2:	ec4e                	sd	s3,24(sp)
 5e4:	0080                	addi	s0,sp,64
 5e6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5e8:	c299                	beqz	a3,5ee <printint+0x16>
 5ea:	0805c863          	bltz	a1,67a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5ee:	2581                	sext.w	a1,a1
  neg = 0;
 5f0:	4881                	li	a7,0
 5f2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5f6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5f8:	2601                	sext.w	a2,a2
 5fa:	00000517          	auipc	a0,0x0
 5fe:	4d650513          	addi	a0,a0,1238 # ad0 <digits>
 602:	883a                	mv	a6,a4
 604:	2705                	addiw	a4,a4,1
 606:	02c5f7bb          	remuw	a5,a1,a2
 60a:	1782                	slli	a5,a5,0x20
 60c:	9381                	srli	a5,a5,0x20
 60e:	97aa                	add	a5,a5,a0
 610:	0007c783          	lbu	a5,0(a5)
 614:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 618:	0005879b          	sext.w	a5,a1
 61c:	02c5d5bb          	divuw	a1,a1,a2
 620:	0685                	addi	a3,a3,1
 622:	fec7f0e3          	bgeu	a5,a2,602 <printint+0x2a>
  if(neg)
 626:	00088b63          	beqz	a7,63c <printint+0x64>
    buf[i++] = '-';
 62a:	fd040793          	addi	a5,s0,-48
 62e:	973e                	add	a4,a4,a5
 630:	02d00793          	li	a5,45
 634:	fef70823          	sb	a5,-16(a4)
 638:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 63c:	02e05863          	blez	a4,66c <printint+0x94>
 640:	fc040793          	addi	a5,s0,-64
 644:	00e78933          	add	s2,a5,a4
 648:	fff78993          	addi	s3,a5,-1
 64c:	99ba                	add	s3,s3,a4
 64e:	377d                	addiw	a4,a4,-1
 650:	1702                	slli	a4,a4,0x20
 652:	9301                	srli	a4,a4,0x20
 654:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 658:	fff94583          	lbu	a1,-1(s2)
 65c:	8526                	mv	a0,s1
 65e:	00000097          	auipc	ra,0x0
 662:	f58080e7          	jalr	-168(ra) # 5b6 <putc>
  while(--i >= 0)
 666:	197d                	addi	s2,s2,-1
 668:	ff3918e3          	bne	s2,s3,658 <printint+0x80>
}
 66c:	70e2                	ld	ra,56(sp)
 66e:	7442                	ld	s0,48(sp)
 670:	74a2                	ld	s1,40(sp)
 672:	7902                	ld	s2,32(sp)
 674:	69e2                	ld	s3,24(sp)
 676:	6121                	addi	sp,sp,64
 678:	8082                	ret
    x = -xx;
 67a:	40b005bb          	negw	a1,a1
    neg = 1;
 67e:	4885                	li	a7,1
    x = -xx;
 680:	bf8d                	j	5f2 <printint+0x1a>

0000000000000682 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 682:	7119                	addi	sp,sp,-128
 684:	fc86                	sd	ra,120(sp)
 686:	f8a2                	sd	s0,112(sp)
 688:	f4a6                	sd	s1,104(sp)
 68a:	f0ca                	sd	s2,96(sp)
 68c:	ecce                	sd	s3,88(sp)
 68e:	e8d2                	sd	s4,80(sp)
 690:	e4d6                	sd	s5,72(sp)
 692:	e0da                	sd	s6,64(sp)
 694:	fc5e                	sd	s7,56(sp)
 696:	f862                	sd	s8,48(sp)
 698:	f466                	sd	s9,40(sp)
 69a:	f06a                	sd	s10,32(sp)
 69c:	ec6e                	sd	s11,24(sp)
 69e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6a0:	0005c903          	lbu	s2,0(a1)
 6a4:	18090f63          	beqz	s2,842 <vprintf+0x1c0>
 6a8:	8aaa                	mv	s5,a0
 6aa:	8b32                	mv	s6,a2
 6ac:	00158493          	addi	s1,a1,1
  state = 0;
 6b0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6b2:	02500a13          	li	s4,37
      if(c == 'd'){
 6b6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6ba:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6be:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6c2:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6c6:	00000b97          	auipc	s7,0x0
 6ca:	40ab8b93          	addi	s7,s7,1034 # ad0 <digits>
 6ce:	a839                	j	6ec <vprintf+0x6a>
        putc(fd, c);
 6d0:	85ca                	mv	a1,s2
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	ee2080e7          	jalr	-286(ra) # 5b6 <putc>
 6dc:	a019                	j	6e2 <vprintf+0x60>
    } else if(state == '%'){
 6de:	01498f63          	beq	s3,s4,6fc <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6e2:	0485                	addi	s1,s1,1
 6e4:	fff4c903          	lbu	s2,-1(s1)
 6e8:	14090d63          	beqz	s2,842 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6ec:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6f0:	fe0997e3          	bnez	s3,6de <vprintf+0x5c>
      if(c == '%'){
 6f4:	fd479ee3          	bne	a5,s4,6d0 <vprintf+0x4e>
        state = '%';
 6f8:	89be                	mv	s3,a5
 6fa:	b7e5                	j	6e2 <vprintf+0x60>
      if(c == 'd'){
 6fc:	05878063          	beq	a5,s8,73c <vprintf+0xba>
      } else if(c == 'l') {
 700:	05978c63          	beq	a5,s9,758 <vprintf+0xd6>
      } else if(c == 'x') {
 704:	07a78863          	beq	a5,s10,774 <vprintf+0xf2>
      } else if(c == 'p') {
 708:	09b78463          	beq	a5,s11,790 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 70c:	07300713          	li	a4,115
 710:	0ce78663          	beq	a5,a4,7dc <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 714:	06300713          	li	a4,99
 718:	0ee78e63          	beq	a5,a4,814 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 71c:	11478863          	beq	a5,s4,82c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 720:	85d2                	mv	a1,s4
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	e92080e7          	jalr	-366(ra) # 5b6 <putc>
        putc(fd, c);
 72c:	85ca                	mv	a1,s2
 72e:	8556                	mv	a0,s5
 730:	00000097          	auipc	ra,0x0
 734:	e86080e7          	jalr	-378(ra) # 5b6 <putc>
      }
      state = 0;
 738:	4981                	li	s3,0
 73a:	b765                	j	6e2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 73c:	008b0913          	addi	s2,s6,8
 740:	4685                	li	a3,1
 742:	4629                	li	a2,10
 744:	000b2583          	lw	a1,0(s6)
 748:	8556                	mv	a0,s5
 74a:	00000097          	auipc	ra,0x0
 74e:	e8e080e7          	jalr	-370(ra) # 5d8 <printint>
 752:	8b4a                	mv	s6,s2
      state = 0;
 754:	4981                	li	s3,0
 756:	b771                	j	6e2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 758:	008b0913          	addi	s2,s6,8
 75c:	4681                	li	a3,0
 75e:	4629                	li	a2,10
 760:	000b2583          	lw	a1,0(s6)
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	e72080e7          	jalr	-398(ra) # 5d8 <printint>
 76e:	8b4a                	mv	s6,s2
      state = 0;
 770:	4981                	li	s3,0
 772:	bf85                	j	6e2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 774:	008b0913          	addi	s2,s6,8
 778:	4681                	li	a3,0
 77a:	4641                	li	a2,16
 77c:	000b2583          	lw	a1,0(s6)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	e56080e7          	jalr	-426(ra) # 5d8 <printint>
 78a:	8b4a                	mv	s6,s2
      state = 0;
 78c:	4981                	li	s3,0
 78e:	bf91                	j	6e2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 790:	008b0793          	addi	a5,s6,8
 794:	f8f43423          	sd	a5,-120(s0)
 798:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 79c:	03000593          	li	a1,48
 7a0:	8556                	mv	a0,s5
 7a2:	00000097          	auipc	ra,0x0
 7a6:	e14080e7          	jalr	-492(ra) # 5b6 <putc>
  putc(fd, 'x');
 7aa:	85ea                	mv	a1,s10
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	e08080e7          	jalr	-504(ra) # 5b6 <putc>
 7b6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7b8:	03c9d793          	srli	a5,s3,0x3c
 7bc:	97de                	add	a5,a5,s7
 7be:	0007c583          	lbu	a1,0(a5)
 7c2:	8556                	mv	a0,s5
 7c4:	00000097          	auipc	ra,0x0
 7c8:	df2080e7          	jalr	-526(ra) # 5b6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7cc:	0992                	slli	s3,s3,0x4
 7ce:	397d                	addiw	s2,s2,-1
 7d0:	fe0914e3          	bnez	s2,7b8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7d4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7d8:	4981                	li	s3,0
 7da:	b721                	j	6e2 <vprintf+0x60>
        s = va_arg(ap, char*);
 7dc:	008b0993          	addi	s3,s6,8
 7e0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7e4:	02090163          	beqz	s2,806 <vprintf+0x184>
        while(*s != 0){
 7e8:	00094583          	lbu	a1,0(s2)
 7ec:	c9a1                	beqz	a1,83c <vprintf+0x1ba>
          putc(fd, *s);
 7ee:	8556                	mv	a0,s5
 7f0:	00000097          	auipc	ra,0x0
 7f4:	dc6080e7          	jalr	-570(ra) # 5b6 <putc>
          s++;
 7f8:	0905                	addi	s2,s2,1
        while(*s != 0){
 7fa:	00094583          	lbu	a1,0(s2)
 7fe:	f9e5                	bnez	a1,7ee <vprintf+0x16c>
        s = va_arg(ap, char*);
 800:	8b4e                	mv	s6,s3
      state = 0;
 802:	4981                	li	s3,0
 804:	bdf9                	j	6e2 <vprintf+0x60>
          s = "(null)";
 806:	00000917          	auipc	s2,0x0
 80a:	2c290913          	addi	s2,s2,706 # ac8 <malloc+0x17c>
        while(*s != 0){
 80e:	02800593          	li	a1,40
 812:	bff1                	j	7ee <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 814:	008b0913          	addi	s2,s6,8
 818:	000b4583          	lbu	a1,0(s6)
 81c:	8556                	mv	a0,s5
 81e:	00000097          	auipc	ra,0x0
 822:	d98080e7          	jalr	-616(ra) # 5b6 <putc>
 826:	8b4a                	mv	s6,s2
      state = 0;
 828:	4981                	li	s3,0
 82a:	bd65                	j	6e2 <vprintf+0x60>
        putc(fd, c);
 82c:	85d2                	mv	a1,s4
 82e:	8556                	mv	a0,s5
 830:	00000097          	auipc	ra,0x0
 834:	d86080e7          	jalr	-634(ra) # 5b6 <putc>
      state = 0;
 838:	4981                	li	s3,0
 83a:	b565                	j	6e2 <vprintf+0x60>
        s = va_arg(ap, char*);
 83c:	8b4e                	mv	s6,s3
      state = 0;
 83e:	4981                	li	s3,0
 840:	b54d                	j	6e2 <vprintf+0x60>
    }
  }
}
 842:	70e6                	ld	ra,120(sp)
 844:	7446                	ld	s0,112(sp)
 846:	74a6                	ld	s1,104(sp)
 848:	7906                	ld	s2,96(sp)
 84a:	69e6                	ld	s3,88(sp)
 84c:	6a46                	ld	s4,80(sp)
 84e:	6aa6                	ld	s5,72(sp)
 850:	6b06                	ld	s6,64(sp)
 852:	7be2                	ld	s7,56(sp)
 854:	7c42                	ld	s8,48(sp)
 856:	7ca2                	ld	s9,40(sp)
 858:	7d02                	ld	s10,32(sp)
 85a:	6de2                	ld	s11,24(sp)
 85c:	6109                	addi	sp,sp,128
 85e:	8082                	ret

0000000000000860 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 860:	715d                	addi	sp,sp,-80
 862:	ec06                	sd	ra,24(sp)
 864:	e822                	sd	s0,16(sp)
 866:	1000                	addi	s0,sp,32
 868:	e010                	sd	a2,0(s0)
 86a:	e414                	sd	a3,8(s0)
 86c:	e818                	sd	a4,16(s0)
 86e:	ec1c                	sd	a5,24(s0)
 870:	03043023          	sd	a6,32(s0)
 874:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 878:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 87c:	8622                	mv	a2,s0
 87e:	00000097          	auipc	ra,0x0
 882:	e04080e7          	jalr	-508(ra) # 682 <vprintf>
}
 886:	60e2                	ld	ra,24(sp)
 888:	6442                	ld	s0,16(sp)
 88a:	6161                	addi	sp,sp,80
 88c:	8082                	ret

000000000000088e <printf>:

void
printf(const char *fmt, ...)
{
 88e:	711d                	addi	sp,sp,-96
 890:	ec06                	sd	ra,24(sp)
 892:	e822                	sd	s0,16(sp)
 894:	1000                	addi	s0,sp,32
 896:	e40c                	sd	a1,8(s0)
 898:	e810                	sd	a2,16(s0)
 89a:	ec14                	sd	a3,24(s0)
 89c:	f018                	sd	a4,32(s0)
 89e:	f41c                	sd	a5,40(s0)
 8a0:	03043823          	sd	a6,48(s0)
 8a4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8a8:	00840613          	addi	a2,s0,8
 8ac:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8b0:	85aa                	mv	a1,a0
 8b2:	4505                	li	a0,1
 8b4:	00000097          	auipc	ra,0x0
 8b8:	dce080e7          	jalr	-562(ra) # 682 <vprintf>
}
 8bc:	60e2                	ld	ra,24(sp)
 8be:	6442                	ld	s0,16(sp)
 8c0:	6125                	addi	sp,sp,96
 8c2:	8082                	ret

00000000000008c4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8c4:	1141                	addi	sp,sp,-16
 8c6:	e422                	sd	s0,8(sp)
 8c8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ca:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ce:	00000797          	auipc	a5,0x0
 8d2:	21a7b783          	ld	a5,538(a5) # ae8 <freep>
 8d6:	a805                	j	906 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8d8:	4618                	lw	a4,8(a2)
 8da:	9db9                	addw	a1,a1,a4
 8dc:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8e0:	6398                	ld	a4,0(a5)
 8e2:	6318                	ld	a4,0(a4)
 8e4:	fee53823          	sd	a4,-16(a0)
 8e8:	a091                	j	92c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8ea:	ff852703          	lw	a4,-8(a0)
 8ee:	9e39                	addw	a2,a2,a4
 8f0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8f2:	ff053703          	ld	a4,-16(a0)
 8f6:	e398                	sd	a4,0(a5)
 8f8:	a099                	j	93e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8fa:	6398                	ld	a4,0(a5)
 8fc:	00e7e463          	bltu	a5,a4,904 <free+0x40>
 900:	00e6ea63          	bltu	a3,a4,914 <free+0x50>
{
 904:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 906:	fed7fae3          	bgeu	a5,a3,8fa <free+0x36>
 90a:	6398                	ld	a4,0(a5)
 90c:	00e6e463          	bltu	a3,a4,914 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 910:	fee7eae3          	bltu	a5,a4,904 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 914:	ff852583          	lw	a1,-8(a0)
 918:	6390                	ld	a2,0(a5)
 91a:	02059713          	slli	a4,a1,0x20
 91e:	9301                	srli	a4,a4,0x20
 920:	0712                	slli	a4,a4,0x4
 922:	9736                	add	a4,a4,a3
 924:	fae60ae3          	beq	a2,a4,8d8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 928:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 92c:	4790                	lw	a2,8(a5)
 92e:	02061713          	slli	a4,a2,0x20
 932:	9301                	srli	a4,a4,0x20
 934:	0712                	slli	a4,a4,0x4
 936:	973e                	add	a4,a4,a5
 938:	fae689e3          	beq	a3,a4,8ea <free+0x26>
  } else
    p->s.ptr = bp;
 93c:	e394                	sd	a3,0(a5)
  freep = p;
 93e:	00000717          	auipc	a4,0x0
 942:	1af73523          	sd	a5,426(a4) # ae8 <freep>
}
 946:	6422                	ld	s0,8(sp)
 948:	0141                	addi	sp,sp,16
 94a:	8082                	ret

000000000000094c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 94c:	7139                	addi	sp,sp,-64
 94e:	fc06                	sd	ra,56(sp)
 950:	f822                	sd	s0,48(sp)
 952:	f426                	sd	s1,40(sp)
 954:	f04a                	sd	s2,32(sp)
 956:	ec4e                	sd	s3,24(sp)
 958:	e852                	sd	s4,16(sp)
 95a:	e456                	sd	s5,8(sp)
 95c:	e05a                	sd	s6,0(sp)
 95e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 960:	02051493          	slli	s1,a0,0x20
 964:	9081                	srli	s1,s1,0x20
 966:	04bd                	addi	s1,s1,15
 968:	8091                	srli	s1,s1,0x4
 96a:	0014899b          	addiw	s3,s1,1
 96e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 970:	00000517          	auipc	a0,0x0
 974:	17853503          	ld	a0,376(a0) # ae8 <freep>
 978:	c515                	beqz	a0,9a4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 97a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 97c:	4798                	lw	a4,8(a5)
 97e:	02977f63          	bgeu	a4,s1,9bc <malloc+0x70>
 982:	8a4e                	mv	s4,s3
 984:	0009871b          	sext.w	a4,s3
 988:	6685                	lui	a3,0x1
 98a:	00d77363          	bgeu	a4,a3,990 <malloc+0x44>
 98e:	6a05                	lui	s4,0x1
 990:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 994:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 998:	00000917          	auipc	s2,0x0
 99c:	15090913          	addi	s2,s2,336 # ae8 <freep>
  if(p == (char*)-1)
 9a0:	5afd                	li	s5,-1
 9a2:	a88d                	j	a14 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9a4:	00000797          	auipc	a5,0x0
 9a8:	14c78793          	addi	a5,a5,332 # af0 <base>
 9ac:	00000717          	auipc	a4,0x0
 9b0:	12f73e23          	sd	a5,316(a4) # ae8 <freep>
 9b4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9b6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9ba:	b7e1                	j	982 <malloc+0x36>
      if(p->s.size == nunits)
 9bc:	02e48b63          	beq	s1,a4,9f2 <malloc+0xa6>
        p->s.size -= nunits;
 9c0:	4137073b          	subw	a4,a4,s3
 9c4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9c6:	1702                	slli	a4,a4,0x20
 9c8:	9301                	srli	a4,a4,0x20
 9ca:	0712                	slli	a4,a4,0x4
 9cc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9ce:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9d2:	00000717          	auipc	a4,0x0
 9d6:	10a73b23          	sd	a0,278(a4) # ae8 <freep>
      return (void*)(p + 1);
 9da:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9de:	70e2                	ld	ra,56(sp)
 9e0:	7442                	ld	s0,48(sp)
 9e2:	74a2                	ld	s1,40(sp)
 9e4:	7902                	ld	s2,32(sp)
 9e6:	69e2                	ld	s3,24(sp)
 9e8:	6a42                	ld	s4,16(sp)
 9ea:	6aa2                	ld	s5,8(sp)
 9ec:	6b02                	ld	s6,0(sp)
 9ee:	6121                	addi	sp,sp,64
 9f0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9f2:	6398                	ld	a4,0(a5)
 9f4:	e118                	sd	a4,0(a0)
 9f6:	bff1                	j	9d2 <malloc+0x86>
  hp->s.size = nu;
 9f8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9fc:	0541                	addi	a0,a0,16
 9fe:	00000097          	auipc	ra,0x0
 a02:	ec6080e7          	jalr	-314(ra) # 8c4 <free>
  return freep;
 a06:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a0a:	d971                	beqz	a0,9de <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a0c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a0e:	4798                	lw	a4,8(a5)
 a10:	fa9776e3          	bgeu	a4,s1,9bc <malloc+0x70>
    if(p == freep)
 a14:	00093703          	ld	a4,0(s2)
 a18:	853e                	mv	a0,a5
 a1a:	fef719e3          	bne	a4,a5,a0c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a1e:	8552                	mv	a0,s4
 a20:	00000097          	auipc	ra,0x0
 a24:	b66080e7          	jalr	-1178(ra) # 586 <sbrk>
  if(p == (char*)-1)
 a28:	fd5518e3          	bne	a0,s5,9f8 <malloc+0xac>
        return 0;
 a2c:	4501                	li	a0,0
 a2e:	bf45                	j	9de <malloc+0x92>
