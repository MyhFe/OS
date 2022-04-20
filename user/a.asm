
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
  14:	40c080e7          	jalr	1036(ra) # 41c <fork>
        if (pid == 0) {
  18:	c911                	beqz	a0,2c <check+0x2c>
    for (int i = 0; i < n_forks; i++) {
  1a:	2485                	addiw	s1,s1,1
  1c:	ff249ae3          	bne	s1,s2,10 <check+0x10>
        while(1){
            printf("this is process %d\n", k);
            sleep(15);
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
  30:	92c90913          	addi	s2,s2,-1748 # 958 <malloc+0xe6>
  34:	85a6                	mv	a1,s1
  36:	854a                	mv	a0,s2
  38:	00000097          	auipc	ra,0x0
  3c:	77c080e7          	jalr	1916(ra) # 7b4 <printf>
            sleep(15);
  40:	453d                	li	a0,15
  42:	00000097          	auipc	ra,0x0
  46:	472080e7          	jalr	1138(ra) # 4b4 <sleep>
        while(1){
  4a:	b7ed                	j	34 <check+0x34>

000000000000004c <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  4c:	7139                	addi	sp,sp,-64
  4e:	fc06                	sd	ra,56(sp)
  50:	f822                	sd	s0,48(sp)
  52:	f426                	sd	s1,40(sp)
  54:	f04a                	sd	s2,32(sp)
  56:	ec4e                	sd	s3,24(sp)
  58:	e852                	sd	s4,16(sp)
  5a:	e456                	sd	s5,8(sp)
  5c:	e05a                	sd	s6,0(sp)
  5e:	0080                	addi	s0,sp,64
  60:	8a2a                	mv	s4,a0
  62:	892e                	mv	s2,a1
    int pid = getpid();
  64:	00000097          	auipc	ra,0x0
  68:	440080e7          	jalr	1088(ra) # 4a4 <getpid>
    for (int i = 0; i < loop_size; i++) {
  6c:	05205a63          	blez	s2,c0 <kill_system_dem+0x74>
  70:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  72:	01f9599b          	srliw	s3,s2,0x1f
  76:	012989bb          	addw	s3,s3,s2
  7a:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  7e:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  80:	00001b17          	auipc	s6,0x1
  84:	8f0b0b13          	addi	s6,s6,-1808 # 970 <malloc+0xfe>
  88:	a031                	j	94 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  8a:	02998663          	beq	s3,s1,b6 <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  8e:	2485                	addiw	s1,s1,1
  90:	02990863          	beq	s2,s1,c0 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  94:	0344e7bb          	remw	a5,s1,s4
  98:	fbed                	bnez	a5,8a <kill_system_dem+0x3e>
  9a:	00000097          	auipc	ra,0x0
  9e:	40a080e7          	jalr	1034(ra) # 4a4 <getpid>
  a2:	ff5514e3          	bne	a0,s5,8a <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  a6:	864a                	mv	a2,s2
  a8:	85a6                	mv	a1,s1
  aa:	855a                	mv	a0,s6
  ac:	00000097          	auipc	ra,0x0
  b0:	708080e7          	jalr	1800(ra) # 7b4 <printf>
  b4:	bfd9                	j	8a <kill_system_dem+0x3e>
            kill_sys();
  b6:	00000097          	auipc	ra,0x0
  ba:	40e080e7          	jalr	1038(ra) # 4c4 <kill_sys>
  be:	bfc1                	j	8e <kill_system_dem+0x42>
        }
    }
    printf("\n");
  c0:	00001517          	auipc	a0,0x1
  c4:	8d050513          	addi	a0,a0,-1840 # 990 <malloc+0x11e>
  c8:	00000097          	auipc	ra,0x0
  cc:	6ec080e7          	jalr	1772(ra) # 7b4 <printf>
}
  d0:	70e2                	ld	ra,56(sp)
  d2:	7442                	ld	s0,48(sp)
  d4:	74a2                	ld	s1,40(sp)
  d6:	7902                	ld	s2,32(sp)
  d8:	69e2                	ld	s3,24(sp)
  da:	6a42                	ld	s4,16(sp)
  dc:	6aa2                	ld	s5,8(sp)
  de:	6b02                	ld	s6,0(sp)
  e0:	6121                	addi	sp,sp,64
  e2:	8082                	ret

00000000000000e4 <pause_system_dem>:

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
  e4:	715d                	addi	sp,sp,-80
  e6:	e486                	sd	ra,72(sp)
  e8:	e0a2                	sd	s0,64(sp)
  ea:	fc26                	sd	s1,56(sp)
  ec:	f84a                	sd	s2,48(sp)
  ee:	f44e                	sd	s3,40(sp)
  f0:	f052                	sd	s4,32(sp)
  f2:	ec56                	sd	s5,24(sp)
  f4:	e85a                	sd	s6,16(sp)
  f6:	e45e                	sd	s7,8(sp)
  f8:	0880                	addi	s0,sp,80
  fa:	8a2a                	mv	s4,a0
  fc:	8b2e                	mv	s6,a1
  fe:	8932                	mv	s2,a2
    int pid = getpid();
 100:	00000097          	auipc	ra,0x0
 104:	3a4080e7          	jalr	932(ra) # 4a4 <getpid>
    for (int i = 0; i < loop_size; i++) {
 108:	05205b63          	blez	s2,15e <pause_system_dem+0x7a>
 10c:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
 10e:	01f9599b          	srliw	s3,s2,0x1f
 112:	012989bb          	addw	s3,s3,s2
 116:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
 11a:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
 11c:	00001b97          	auipc	s7,0x1
 120:	87cb8b93          	addi	s7,s7,-1924 # 998 <malloc+0x126>
 124:	a031                	j	130 <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
 126:	02998663          	beq	s3,s1,152 <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
 12a:	2485                	addiw	s1,s1,1
 12c:	02990963          	beq	s2,s1,15e <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
 130:	0344e7bb          	remw	a5,s1,s4
 134:	fbed                	bnez	a5,126 <pause_system_dem+0x42>
 136:	00000097          	auipc	ra,0x0
 13a:	36e080e7          	jalr	878(ra) # 4a4 <getpid>
 13e:	ff5514e3          	bne	a0,s5,126 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
 142:	864a                	mv	a2,s2
 144:	85a6                	mv	a1,s1
 146:	855e                	mv	a0,s7
 148:	00000097          	auipc	ra,0x0
 14c:	66c080e7          	jalr	1644(ra) # 7b4 <printf>
 150:	bfd9                	j	126 <pause_system_dem+0x42>
            pause_sys(pause_seconds);
 152:	855a                	mv	a0,s6
 154:	00000097          	auipc	ra,0x0
 158:	378080e7          	jalr	888(ra) # 4cc <pause_sys>
 15c:	b7f9                	j	12a <pause_system_dem+0x46>
        }
    }
    printf("\n");
 15e:	00001517          	auipc	a0,0x1
 162:	83250513          	addi	a0,a0,-1998 # 990 <malloc+0x11e>
 166:	00000097          	auipc	ra,0x0
 16a:	64e080e7          	jalr	1614(ra) # 7b4 <printf>
}
 16e:	60a6                	ld	ra,72(sp)
 170:	6406                	ld	s0,64(sp)
 172:	74e2                	ld	s1,56(sp)
 174:	7942                	ld	s2,48(sp)
 176:	79a2                	ld	s3,40(sp)
 178:	7a02                	ld	s4,32(sp)
 17a:	6ae2                	ld	s5,24(sp)
 17c:	6b42                	ld	s6,16(sp)
 17e:	6ba2                	ld	s7,8(sp)
 180:	6161                	addi	sp,sp,80
 182:	8082                	ret

0000000000000184 <main>:

int
main(int argc, char *argv[])
{
 184:	1141                	addi	sp,sp,-16
 186:	e406                	sd	ra,8(sp)
 188:	e022                	sd	s0,0(sp)
 18a:	0800                	addi	s0,sp,16
    //check();
    pause_system_dem(10, 4, 100);
 18c:	06400613          	li	a2,100
 190:	4591                	li	a1,4
 192:	4529                	li	a0,10
 194:	00000097          	auipc	ra,0x0
 198:	f50080e7          	jalr	-176(ra) # e4 <pause_system_dem>
    //kill_system_dem(10, 100);
    print_stats();
 19c:	00000097          	auipc	ra,0x0
 1a0:	338080e7          	jalr	824(ra) # 4d4 <print_stats>


    exit(0);
 1a4:	4501                	li	a0,0
 1a6:	00000097          	auipc	ra,0x0
 1aa:	27e080e7          	jalr	638(ra) # 424 <exit>

00000000000001ae <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1ae:	1141                	addi	sp,sp,-16
 1b0:	e422                	sd	s0,8(sp)
 1b2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1b4:	87aa                	mv	a5,a0
 1b6:	0585                	addi	a1,a1,1
 1b8:	0785                	addi	a5,a5,1
 1ba:	fff5c703          	lbu	a4,-1(a1)
 1be:	fee78fa3          	sb	a4,-1(a5)
 1c2:	fb75                	bnez	a4,1b6 <strcpy+0x8>
    ;
  return os;
}
 1c4:	6422                	ld	s0,8(sp)
 1c6:	0141                	addi	sp,sp,16
 1c8:	8082                	ret

00000000000001ca <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1ca:	1141                	addi	sp,sp,-16
 1cc:	e422                	sd	s0,8(sp)
 1ce:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1d0:	00054783          	lbu	a5,0(a0)
 1d4:	cb91                	beqz	a5,1e8 <strcmp+0x1e>
 1d6:	0005c703          	lbu	a4,0(a1)
 1da:	00f71763          	bne	a4,a5,1e8 <strcmp+0x1e>
    p++, q++;
 1de:	0505                	addi	a0,a0,1
 1e0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1e2:	00054783          	lbu	a5,0(a0)
 1e6:	fbe5                	bnez	a5,1d6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1e8:	0005c503          	lbu	a0,0(a1)
}
 1ec:	40a7853b          	subw	a0,a5,a0
 1f0:	6422                	ld	s0,8(sp)
 1f2:	0141                	addi	sp,sp,16
 1f4:	8082                	ret

00000000000001f6 <strlen>:

uint
strlen(const char *s)
{
 1f6:	1141                	addi	sp,sp,-16
 1f8:	e422                	sd	s0,8(sp)
 1fa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1fc:	00054783          	lbu	a5,0(a0)
 200:	cf91                	beqz	a5,21c <strlen+0x26>
 202:	0505                	addi	a0,a0,1
 204:	87aa                	mv	a5,a0
 206:	4685                	li	a3,1
 208:	9e89                	subw	a3,a3,a0
 20a:	00f6853b          	addw	a0,a3,a5
 20e:	0785                	addi	a5,a5,1
 210:	fff7c703          	lbu	a4,-1(a5)
 214:	fb7d                	bnez	a4,20a <strlen+0x14>
    ;
  return n;
}
 216:	6422                	ld	s0,8(sp)
 218:	0141                	addi	sp,sp,16
 21a:	8082                	ret
  for(n = 0; s[n]; n++)
 21c:	4501                	li	a0,0
 21e:	bfe5                	j	216 <strlen+0x20>

0000000000000220 <memset>:

void*
memset(void *dst, int c, uint n)
{
 220:	1141                	addi	sp,sp,-16
 222:	e422                	sd	s0,8(sp)
 224:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 226:	ce09                	beqz	a2,240 <memset+0x20>
 228:	87aa                	mv	a5,a0
 22a:	fff6071b          	addiw	a4,a2,-1
 22e:	1702                	slli	a4,a4,0x20
 230:	9301                	srli	a4,a4,0x20
 232:	0705                	addi	a4,a4,1
 234:	972a                	add	a4,a4,a0
    cdst[i] = c;
 236:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 23a:	0785                	addi	a5,a5,1
 23c:	fee79de3          	bne	a5,a4,236 <memset+0x16>
  }
  return dst;
}
 240:	6422                	ld	s0,8(sp)
 242:	0141                	addi	sp,sp,16
 244:	8082                	ret

0000000000000246 <strchr>:

char*
strchr(const char *s, char c)
{
 246:	1141                	addi	sp,sp,-16
 248:	e422                	sd	s0,8(sp)
 24a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 24c:	00054783          	lbu	a5,0(a0)
 250:	cb99                	beqz	a5,266 <strchr+0x20>
    if(*s == c)
 252:	00f58763          	beq	a1,a5,260 <strchr+0x1a>
  for(; *s; s++)
 256:	0505                	addi	a0,a0,1
 258:	00054783          	lbu	a5,0(a0)
 25c:	fbfd                	bnez	a5,252 <strchr+0xc>
      return (char*)s;
  return 0;
 25e:	4501                	li	a0,0
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret
  return 0;
 266:	4501                	li	a0,0
 268:	bfe5                	j	260 <strchr+0x1a>

000000000000026a <gets>:

char*
gets(char *buf, int max)
{
 26a:	711d                	addi	sp,sp,-96
 26c:	ec86                	sd	ra,88(sp)
 26e:	e8a2                	sd	s0,80(sp)
 270:	e4a6                	sd	s1,72(sp)
 272:	e0ca                	sd	s2,64(sp)
 274:	fc4e                	sd	s3,56(sp)
 276:	f852                	sd	s4,48(sp)
 278:	f456                	sd	s5,40(sp)
 27a:	f05a                	sd	s6,32(sp)
 27c:	ec5e                	sd	s7,24(sp)
 27e:	1080                	addi	s0,sp,96
 280:	8baa                	mv	s7,a0
 282:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 284:	892a                	mv	s2,a0
 286:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 288:	4aa9                	li	s5,10
 28a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 28c:	89a6                	mv	s3,s1
 28e:	2485                	addiw	s1,s1,1
 290:	0344d863          	bge	s1,s4,2c0 <gets+0x56>
    cc = read(0, &c, 1);
 294:	4605                	li	a2,1
 296:	faf40593          	addi	a1,s0,-81
 29a:	4501                	li	a0,0
 29c:	00000097          	auipc	ra,0x0
 2a0:	1a0080e7          	jalr	416(ra) # 43c <read>
    if(cc < 1)
 2a4:	00a05e63          	blez	a0,2c0 <gets+0x56>
    buf[i++] = c;
 2a8:	faf44783          	lbu	a5,-81(s0)
 2ac:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2b0:	01578763          	beq	a5,s5,2be <gets+0x54>
 2b4:	0905                	addi	s2,s2,1
 2b6:	fd679be3          	bne	a5,s6,28c <gets+0x22>
  for(i=0; i+1 < max; ){
 2ba:	89a6                	mv	s3,s1
 2bc:	a011                	j	2c0 <gets+0x56>
 2be:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2c0:	99de                	add	s3,s3,s7
 2c2:	00098023          	sb	zero,0(s3)
  return buf;
}
 2c6:	855e                	mv	a0,s7
 2c8:	60e6                	ld	ra,88(sp)
 2ca:	6446                	ld	s0,80(sp)
 2cc:	64a6                	ld	s1,72(sp)
 2ce:	6906                	ld	s2,64(sp)
 2d0:	79e2                	ld	s3,56(sp)
 2d2:	7a42                	ld	s4,48(sp)
 2d4:	7aa2                	ld	s5,40(sp)
 2d6:	7b02                	ld	s6,32(sp)
 2d8:	6be2                	ld	s7,24(sp)
 2da:	6125                	addi	sp,sp,96
 2dc:	8082                	ret

00000000000002de <stat>:

int
stat(const char *n, struct stat *st)
{
 2de:	1101                	addi	sp,sp,-32
 2e0:	ec06                	sd	ra,24(sp)
 2e2:	e822                	sd	s0,16(sp)
 2e4:	e426                	sd	s1,8(sp)
 2e6:	e04a                	sd	s2,0(sp)
 2e8:	1000                	addi	s0,sp,32
 2ea:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2ec:	4581                	li	a1,0
 2ee:	00000097          	auipc	ra,0x0
 2f2:	176080e7          	jalr	374(ra) # 464 <open>
  if(fd < 0)
 2f6:	02054563          	bltz	a0,320 <stat+0x42>
 2fa:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2fc:	85ca                	mv	a1,s2
 2fe:	00000097          	auipc	ra,0x0
 302:	17e080e7          	jalr	382(ra) # 47c <fstat>
 306:	892a                	mv	s2,a0
  close(fd);
 308:	8526                	mv	a0,s1
 30a:	00000097          	auipc	ra,0x0
 30e:	142080e7          	jalr	322(ra) # 44c <close>
  return r;
}
 312:	854a                	mv	a0,s2
 314:	60e2                	ld	ra,24(sp)
 316:	6442                	ld	s0,16(sp)
 318:	64a2                	ld	s1,8(sp)
 31a:	6902                	ld	s2,0(sp)
 31c:	6105                	addi	sp,sp,32
 31e:	8082                	ret
    return -1;
 320:	597d                	li	s2,-1
 322:	bfc5                	j	312 <stat+0x34>

0000000000000324 <atoi>:

int
atoi(const char *s)
{
 324:	1141                	addi	sp,sp,-16
 326:	e422                	sd	s0,8(sp)
 328:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 32a:	00054603          	lbu	a2,0(a0)
 32e:	fd06079b          	addiw	a5,a2,-48
 332:	0ff7f793          	andi	a5,a5,255
 336:	4725                	li	a4,9
 338:	02f76963          	bltu	a4,a5,36a <atoi+0x46>
 33c:	86aa                	mv	a3,a0
  n = 0;
 33e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 340:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 342:	0685                	addi	a3,a3,1
 344:	0025179b          	slliw	a5,a0,0x2
 348:	9fa9                	addw	a5,a5,a0
 34a:	0017979b          	slliw	a5,a5,0x1
 34e:	9fb1                	addw	a5,a5,a2
 350:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 354:	0006c603          	lbu	a2,0(a3)
 358:	fd06071b          	addiw	a4,a2,-48
 35c:	0ff77713          	andi	a4,a4,255
 360:	fee5f1e3          	bgeu	a1,a4,342 <atoi+0x1e>
  return n;
}
 364:	6422                	ld	s0,8(sp)
 366:	0141                	addi	sp,sp,16
 368:	8082                	ret
  n = 0;
 36a:	4501                	li	a0,0
 36c:	bfe5                	j	364 <atoi+0x40>

000000000000036e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 36e:	1141                	addi	sp,sp,-16
 370:	e422                	sd	s0,8(sp)
 372:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 374:	02b57663          	bgeu	a0,a1,3a0 <memmove+0x32>
    while(n-- > 0)
 378:	02c05163          	blez	a2,39a <memmove+0x2c>
 37c:	fff6079b          	addiw	a5,a2,-1
 380:	1782                	slli	a5,a5,0x20
 382:	9381                	srli	a5,a5,0x20
 384:	0785                	addi	a5,a5,1
 386:	97aa                	add	a5,a5,a0
  dst = vdst;
 388:	872a                	mv	a4,a0
      *dst++ = *src++;
 38a:	0585                	addi	a1,a1,1
 38c:	0705                	addi	a4,a4,1
 38e:	fff5c683          	lbu	a3,-1(a1)
 392:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 396:	fee79ae3          	bne	a5,a4,38a <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 39a:	6422                	ld	s0,8(sp)
 39c:	0141                	addi	sp,sp,16
 39e:	8082                	ret
    dst += n;
 3a0:	00c50733          	add	a4,a0,a2
    src += n;
 3a4:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3a6:	fec05ae3          	blez	a2,39a <memmove+0x2c>
 3aa:	fff6079b          	addiw	a5,a2,-1
 3ae:	1782                	slli	a5,a5,0x20
 3b0:	9381                	srli	a5,a5,0x20
 3b2:	fff7c793          	not	a5,a5
 3b6:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3b8:	15fd                	addi	a1,a1,-1
 3ba:	177d                	addi	a4,a4,-1
 3bc:	0005c683          	lbu	a3,0(a1)
 3c0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3c4:	fee79ae3          	bne	a5,a4,3b8 <memmove+0x4a>
 3c8:	bfc9                	j	39a <memmove+0x2c>

00000000000003ca <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3ca:	1141                	addi	sp,sp,-16
 3cc:	e422                	sd	s0,8(sp)
 3ce:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3d0:	ca05                	beqz	a2,400 <memcmp+0x36>
 3d2:	fff6069b          	addiw	a3,a2,-1
 3d6:	1682                	slli	a3,a3,0x20
 3d8:	9281                	srli	a3,a3,0x20
 3da:	0685                	addi	a3,a3,1
 3dc:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3de:	00054783          	lbu	a5,0(a0)
 3e2:	0005c703          	lbu	a4,0(a1)
 3e6:	00e79863          	bne	a5,a4,3f6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ea:	0505                	addi	a0,a0,1
    p2++;
 3ec:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3ee:	fed518e3          	bne	a0,a3,3de <memcmp+0x14>
  }
  return 0;
 3f2:	4501                	li	a0,0
 3f4:	a019                	j	3fa <memcmp+0x30>
      return *p1 - *p2;
 3f6:	40e7853b          	subw	a0,a5,a4
}
 3fa:	6422                	ld	s0,8(sp)
 3fc:	0141                	addi	sp,sp,16
 3fe:	8082                	ret
  return 0;
 400:	4501                	li	a0,0
 402:	bfe5                	j	3fa <memcmp+0x30>

0000000000000404 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 404:	1141                	addi	sp,sp,-16
 406:	e406                	sd	ra,8(sp)
 408:	e022                	sd	s0,0(sp)
 40a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 40c:	00000097          	auipc	ra,0x0
 410:	f62080e7          	jalr	-158(ra) # 36e <memmove>
}
 414:	60a2                	ld	ra,8(sp)
 416:	6402                	ld	s0,0(sp)
 418:	0141                	addi	sp,sp,16
 41a:	8082                	ret

000000000000041c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 41c:	4885                	li	a7,1
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <exit>:
.global exit
exit:
 li a7, SYS_exit
 424:	4889                	li	a7,2
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <wait>:
.global wait
wait:
 li a7, SYS_wait
 42c:	488d                	li	a7,3
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 434:	4891                	li	a7,4
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <read>:
.global read
read:
 li a7, SYS_read
 43c:	4895                	li	a7,5
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <write>:
.global write
write:
 li a7, SYS_write
 444:	48c1                	li	a7,16
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <close>:
.global close
close:
 li a7, SYS_close
 44c:	48d5                	li	a7,21
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <kill>:
.global kill
kill:
 li a7, SYS_kill
 454:	4899                	li	a7,6
 ecall
 456:	00000073          	ecall
 ret
 45a:	8082                	ret

000000000000045c <exec>:
.global exec
exec:
 li a7, SYS_exec
 45c:	489d                	li	a7,7
 ecall
 45e:	00000073          	ecall
 ret
 462:	8082                	ret

0000000000000464 <open>:
.global open
open:
 li a7, SYS_open
 464:	48bd                	li	a7,15
 ecall
 466:	00000073          	ecall
 ret
 46a:	8082                	ret

000000000000046c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 46c:	48c5                	li	a7,17
 ecall
 46e:	00000073          	ecall
 ret
 472:	8082                	ret

0000000000000474 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 474:	48c9                	li	a7,18
 ecall
 476:	00000073          	ecall
 ret
 47a:	8082                	ret

000000000000047c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 47c:	48a1                	li	a7,8
 ecall
 47e:	00000073          	ecall
 ret
 482:	8082                	ret

0000000000000484 <link>:
.global link
link:
 li a7, SYS_link
 484:	48cd                	li	a7,19
 ecall
 486:	00000073          	ecall
 ret
 48a:	8082                	ret

000000000000048c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 48c:	48d1                	li	a7,20
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 494:	48a5                	li	a7,9
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <dup>:
.global dup
dup:
 li a7, SYS_dup
 49c:	48a9                	li	a7,10
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4a4:	48ad                	li	a7,11
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4ac:	48b1                	li	a7,12
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4b4:	48b5                	li	a7,13
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4bc:	48b9                	li	a7,14
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <kill_sys>:
.global kill_sys
kill_sys:
 li a7, SYS_kill_sys
 4c4:	48d9                	li	a7,22
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <pause_sys>:
.global pause_sys
pause_sys:
 li a7, SYS_pause_sys
 4cc:	48dd                	li	a7,23
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 4d4:	48e1                	li	a7,24
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4dc:	1101                	addi	sp,sp,-32
 4de:	ec06                	sd	ra,24(sp)
 4e0:	e822                	sd	s0,16(sp)
 4e2:	1000                	addi	s0,sp,32
 4e4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4e8:	4605                	li	a2,1
 4ea:	fef40593          	addi	a1,s0,-17
 4ee:	00000097          	auipc	ra,0x0
 4f2:	f56080e7          	jalr	-170(ra) # 444 <write>
}
 4f6:	60e2                	ld	ra,24(sp)
 4f8:	6442                	ld	s0,16(sp)
 4fa:	6105                	addi	sp,sp,32
 4fc:	8082                	ret

00000000000004fe <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4fe:	7139                	addi	sp,sp,-64
 500:	fc06                	sd	ra,56(sp)
 502:	f822                	sd	s0,48(sp)
 504:	f426                	sd	s1,40(sp)
 506:	f04a                	sd	s2,32(sp)
 508:	ec4e                	sd	s3,24(sp)
 50a:	0080                	addi	s0,sp,64
 50c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 50e:	c299                	beqz	a3,514 <printint+0x16>
 510:	0805c863          	bltz	a1,5a0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 514:	2581                	sext.w	a1,a1
  neg = 0;
 516:	4881                	li	a7,0
 518:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 51c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 51e:	2601                	sext.w	a2,a2
 520:	00000517          	auipc	a0,0x0
 524:	4a050513          	addi	a0,a0,1184 # 9c0 <digits>
 528:	883a                	mv	a6,a4
 52a:	2705                	addiw	a4,a4,1
 52c:	02c5f7bb          	remuw	a5,a1,a2
 530:	1782                	slli	a5,a5,0x20
 532:	9381                	srli	a5,a5,0x20
 534:	97aa                	add	a5,a5,a0
 536:	0007c783          	lbu	a5,0(a5)
 53a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 53e:	0005879b          	sext.w	a5,a1
 542:	02c5d5bb          	divuw	a1,a1,a2
 546:	0685                	addi	a3,a3,1
 548:	fec7f0e3          	bgeu	a5,a2,528 <printint+0x2a>
  if(neg)
 54c:	00088b63          	beqz	a7,562 <printint+0x64>
    buf[i++] = '-';
 550:	fd040793          	addi	a5,s0,-48
 554:	973e                	add	a4,a4,a5
 556:	02d00793          	li	a5,45
 55a:	fef70823          	sb	a5,-16(a4)
 55e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 562:	02e05863          	blez	a4,592 <printint+0x94>
 566:	fc040793          	addi	a5,s0,-64
 56a:	00e78933          	add	s2,a5,a4
 56e:	fff78993          	addi	s3,a5,-1
 572:	99ba                	add	s3,s3,a4
 574:	377d                	addiw	a4,a4,-1
 576:	1702                	slli	a4,a4,0x20
 578:	9301                	srli	a4,a4,0x20
 57a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 57e:	fff94583          	lbu	a1,-1(s2)
 582:	8526                	mv	a0,s1
 584:	00000097          	auipc	ra,0x0
 588:	f58080e7          	jalr	-168(ra) # 4dc <putc>
  while(--i >= 0)
 58c:	197d                	addi	s2,s2,-1
 58e:	ff3918e3          	bne	s2,s3,57e <printint+0x80>
}
 592:	70e2                	ld	ra,56(sp)
 594:	7442                	ld	s0,48(sp)
 596:	74a2                	ld	s1,40(sp)
 598:	7902                	ld	s2,32(sp)
 59a:	69e2                	ld	s3,24(sp)
 59c:	6121                	addi	sp,sp,64
 59e:	8082                	ret
    x = -xx;
 5a0:	40b005bb          	negw	a1,a1
    neg = 1;
 5a4:	4885                	li	a7,1
    x = -xx;
 5a6:	bf8d                	j	518 <printint+0x1a>

00000000000005a8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5a8:	7119                	addi	sp,sp,-128
 5aa:	fc86                	sd	ra,120(sp)
 5ac:	f8a2                	sd	s0,112(sp)
 5ae:	f4a6                	sd	s1,104(sp)
 5b0:	f0ca                	sd	s2,96(sp)
 5b2:	ecce                	sd	s3,88(sp)
 5b4:	e8d2                	sd	s4,80(sp)
 5b6:	e4d6                	sd	s5,72(sp)
 5b8:	e0da                	sd	s6,64(sp)
 5ba:	fc5e                	sd	s7,56(sp)
 5bc:	f862                	sd	s8,48(sp)
 5be:	f466                	sd	s9,40(sp)
 5c0:	f06a                	sd	s10,32(sp)
 5c2:	ec6e                	sd	s11,24(sp)
 5c4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5c6:	0005c903          	lbu	s2,0(a1)
 5ca:	18090f63          	beqz	s2,768 <vprintf+0x1c0>
 5ce:	8aaa                	mv	s5,a0
 5d0:	8b32                	mv	s6,a2
 5d2:	00158493          	addi	s1,a1,1
  state = 0;
 5d6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5d8:	02500a13          	li	s4,37
      if(c == 'd'){
 5dc:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5e0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5e4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5e8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ec:	00000b97          	auipc	s7,0x0
 5f0:	3d4b8b93          	addi	s7,s7,980 # 9c0 <digits>
 5f4:	a839                	j	612 <vprintf+0x6a>
        putc(fd, c);
 5f6:	85ca                	mv	a1,s2
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	ee2080e7          	jalr	-286(ra) # 4dc <putc>
 602:	a019                	j	608 <vprintf+0x60>
    } else if(state == '%'){
 604:	01498f63          	beq	s3,s4,622 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 608:	0485                	addi	s1,s1,1
 60a:	fff4c903          	lbu	s2,-1(s1)
 60e:	14090d63          	beqz	s2,768 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 612:	0009079b          	sext.w	a5,s2
    if(state == 0){
 616:	fe0997e3          	bnez	s3,604 <vprintf+0x5c>
      if(c == '%'){
 61a:	fd479ee3          	bne	a5,s4,5f6 <vprintf+0x4e>
        state = '%';
 61e:	89be                	mv	s3,a5
 620:	b7e5                	j	608 <vprintf+0x60>
      if(c == 'd'){
 622:	05878063          	beq	a5,s8,662 <vprintf+0xba>
      } else if(c == 'l') {
 626:	05978c63          	beq	a5,s9,67e <vprintf+0xd6>
      } else if(c == 'x') {
 62a:	07a78863          	beq	a5,s10,69a <vprintf+0xf2>
      } else if(c == 'p') {
 62e:	09b78463          	beq	a5,s11,6b6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 632:	07300713          	li	a4,115
 636:	0ce78663          	beq	a5,a4,702 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 63a:	06300713          	li	a4,99
 63e:	0ee78e63          	beq	a5,a4,73a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 642:	11478863          	beq	a5,s4,752 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 646:	85d2                	mv	a1,s4
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	e92080e7          	jalr	-366(ra) # 4dc <putc>
        putc(fd, c);
 652:	85ca                	mv	a1,s2
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	e86080e7          	jalr	-378(ra) # 4dc <putc>
      }
      state = 0;
 65e:	4981                	li	s3,0
 660:	b765                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 662:	008b0913          	addi	s2,s6,8
 666:	4685                	li	a3,1
 668:	4629                	li	a2,10
 66a:	000b2583          	lw	a1,0(s6)
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	e8e080e7          	jalr	-370(ra) # 4fe <printint>
 678:	8b4a                	mv	s6,s2
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b771                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 67e:	008b0913          	addi	s2,s6,8
 682:	4681                	li	a3,0
 684:	4629                	li	a2,10
 686:	000b2583          	lw	a1,0(s6)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	e72080e7          	jalr	-398(ra) # 4fe <printint>
 694:	8b4a                	mv	s6,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	bf85                	j	608 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 69a:	008b0913          	addi	s2,s6,8
 69e:	4681                	li	a3,0
 6a0:	4641                	li	a2,16
 6a2:	000b2583          	lw	a1,0(s6)
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	e56080e7          	jalr	-426(ra) # 4fe <printint>
 6b0:	8b4a                	mv	s6,s2
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	bf91                	j	608 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6b6:	008b0793          	addi	a5,s6,8
 6ba:	f8f43423          	sd	a5,-120(s0)
 6be:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6c2:	03000593          	li	a1,48
 6c6:	8556                	mv	a0,s5
 6c8:	00000097          	auipc	ra,0x0
 6cc:	e14080e7          	jalr	-492(ra) # 4dc <putc>
  putc(fd, 'x');
 6d0:	85ea                	mv	a1,s10
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e08080e7          	jalr	-504(ra) # 4dc <putc>
 6dc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6de:	03c9d793          	srli	a5,s3,0x3c
 6e2:	97de                	add	a5,a5,s7
 6e4:	0007c583          	lbu	a1,0(a5)
 6e8:	8556                	mv	a0,s5
 6ea:	00000097          	auipc	ra,0x0
 6ee:	df2080e7          	jalr	-526(ra) # 4dc <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6f2:	0992                	slli	s3,s3,0x4
 6f4:	397d                	addiw	s2,s2,-1
 6f6:	fe0914e3          	bnez	s2,6de <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6fa:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6fe:	4981                	li	s3,0
 700:	b721                	j	608 <vprintf+0x60>
        s = va_arg(ap, char*);
 702:	008b0993          	addi	s3,s6,8
 706:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 70a:	02090163          	beqz	s2,72c <vprintf+0x184>
        while(*s != 0){
 70e:	00094583          	lbu	a1,0(s2)
 712:	c9a1                	beqz	a1,762 <vprintf+0x1ba>
          putc(fd, *s);
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	dc6080e7          	jalr	-570(ra) # 4dc <putc>
          s++;
 71e:	0905                	addi	s2,s2,1
        while(*s != 0){
 720:	00094583          	lbu	a1,0(s2)
 724:	f9e5                	bnez	a1,714 <vprintf+0x16c>
        s = va_arg(ap, char*);
 726:	8b4e                	mv	s6,s3
      state = 0;
 728:	4981                	li	s3,0
 72a:	bdf9                	j	608 <vprintf+0x60>
          s = "(null)";
 72c:	00000917          	auipc	s2,0x0
 730:	28c90913          	addi	s2,s2,652 # 9b8 <malloc+0x146>
        while(*s != 0){
 734:	02800593          	li	a1,40
 738:	bff1                	j	714 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 73a:	008b0913          	addi	s2,s6,8
 73e:	000b4583          	lbu	a1,0(s6)
 742:	8556                	mv	a0,s5
 744:	00000097          	auipc	ra,0x0
 748:	d98080e7          	jalr	-616(ra) # 4dc <putc>
 74c:	8b4a                	mv	s6,s2
      state = 0;
 74e:	4981                	li	s3,0
 750:	bd65                	j	608 <vprintf+0x60>
        putc(fd, c);
 752:	85d2                	mv	a1,s4
 754:	8556                	mv	a0,s5
 756:	00000097          	auipc	ra,0x0
 75a:	d86080e7          	jalr	-634(ra) # 4dc <putc>
      state = 0;
 75e:	4981                	li	s3,0
 760:	b565                	j	608 <vprintf+0x60>
        s = va_arg(ap, char*);
 762:	8b4e                	mv	s6,s3
      state = 0;
 764:	4981                	li	s3,0
 766:	b54d                	j	608 <vprintf+0x60>
    }
  }
}
 768:	70e6                	ld	ra,120(sp)
 76a:	7446                	ld	s0,112(sp)
 76c:	74a6                	ld	s1,104(sp)
 76e:	7906                	ld	s2,96(sp)
 770:	69e6                	ld	s3,88(sp)
 772:	6a46                	ld	s4,80(sp)
 774:	6aa6                	ld	s5,72(sp)
 776:	6b06                	ld	s6,64(sp)
 778:	7be2                	ld	s7,56(sp)
 77a:	7c42                	ld	s8,48(sp)
 77c:	7ca2                	ld	s9,40(sp)
 77e:	7d02                	ld	s10,32(sp)
 780:	6de2                	ld	s11,24(sp)
 782:	6109                	addi	sp,sp,128
 784:	8082                	ret

0000000000000786 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 786:	715d                	addi	sp,sp,-80
 788:	ec06                	sd	ra,24(sp)
 78a:	e822                	sd	s0,16(sp)
 78c:	1000                	addi	s0,sp,32
 78e:	e010                	sd	a2,0(s0)
 790:	e414                	sd	a3,8(s0)
 792:	e818                	sd	a4,16(s0)
 794:	ec1c                	sd	a5,24(s0)
 796:	03043023          	sd	a6,32(s0)
 79a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 79e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7a2:	8622                	mv	a2,s0
 7a4:	00000097          	auipc	ra,0x0
 7a8:	e04080e7          	jalr	-508(ra) # 5a8 <vprintf>
}
 7ac:	60e2                	ld	ra,24(sp)
 7ae:	6442                	ld	s0,16(sp)
 7b0:	6161                	addi	sp,sp,80
 7b2:	8082                	ret

00000000000007b4 <printf>:

void
printf(const char *fmt, ...)
{
 7b4:	711d                	addi	sp,sp,-96
 7b6:	ec06                	sd	ra,24(sp)
 7b8:	e822                	sd	s0,16(sp)
 7ba:	1000                	addi	s0,sp,32
 7bc:	e40c                	sd	a1,8(s0)
 7be:	e810                	sd	a2,16(s0)
 7c0:	ec14                	sd	a3,24(s0)
 7c2:	f018                	sd	a4,32(s0)
 7c4:	f41c                	sd	a5,40(s0)
 7c6:	03043823          	sd	a6,48(s0)
 7ca:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7ce:	00840613          	addi	a2,s0,8
 7d2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7d6:	85aa                	mv	a1,a0
 7d8:	4505                	li	a0,1
 7da:	00000097          	auipc	ra,0x0
 7de:	dce080e7          	jalr	-562(ra) # 5a8 <vprintf>
}
 7e2:	60e2                	ld	ra,24(sp)
 7e4:	6442                	ld	s0,16(sp)
 7e6:	6125                	addi	sp,sp,96
 7e8:	8082                	ret

00000000000007ea <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ea:	1141                	addi	sp,sp,-16
 7ec:	e422                	sd	s0,8(sp)
 7ee:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7f0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f4:	00000797          	auipc	a5,0x0
 7f8:	1e47b783          	ld	a5,484(a5) # 9d8 <freep>
 7fc:	a805                	j	82c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7fe:	4618                	lw	a4,8(a2)
 800:	9db9                	addw	a1,a1,a4
 802:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 806:	6398                	ld	a4,0(a5)
 808:	6318                	ld	a4,0(a4)
 80a:	fee53823          	sd	a4,-16(a0)
 80e:	a091                	j	852 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 810:	ff852703          	lw	a4,-8(a0)
 814:	9e39                	addw	a2,a2,a4
 816:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 818:	ff053703          	ld	a4,-16(a0)
 81c:	e398                	sd	a4,0(a5)
 81e:	a099                	j	864 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 820:	6398                	ld	a4,0(a5)
 822:	00e7e463          	bltu	a5,a4,82a <free+0x40>
 826:	00e6ea63          	bltu	a3,a4,83a <free+0x50>
{
 82a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 82c:	fed7fae3          	bgeu	a5,a3,820 <free+0x36>
 830:	6398                	ld	a4,0(a5)
 832:	00e6e463          	bltu	a3,a4,83a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 836:	fee7eae3          	bltu	a5,a4,82a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 83a:	ff852583          	lw	a1,-8(a0)
 83e:	6390                	ld	a2,0(a5)
 840:	02059713          	slli	a4,a1,0x20
 844:	9301                	srli	a4,a4,0x20
 846:	0712                	slli	a4,a4,0x4
 848:	9736                	add	a4,a4,a3
 84a:	fae60ae3          	beq	a2,a4,7fe <free+0x14>
    bp->s.ptr = p->s.ptr;
 84e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 852:	4790                	lw	a2,8(a5)
 854:	02061713          	slli	a4,a2,0x20
 858:	9301                	srli	a4,a4,0x20
 85a:	0712                	slli	a4,a4,0x4
 85c:	973e                	add	a4,a4,a5
 85e:	fae689e3          	beq	a3,a4,810 <free+0x26>
  } else
    p->s.ptr = bp;
 862:	e394                	sd	a3,0(a5)
  freep = p;
 864:	00000717          	auipc	a4,0x0
 868:	16f73a23          	sd	a5,372(a4) # 9d8 <freep>
}
 86c:	6422                	ld	s0,8(sp)
 86e:	0141                	addi	sp,sp,16
 870:	8082                	ret

0000000000000872 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 872:	7139                	addi	sp,sp,-64
 874:	fc06                	sd	ra,56(sp)
 876:	f822                	sd	s0,48(sp)
 878:	f426                	sd	s1,40(sp)
 87a:	f04a                	sd	s2,32(sp)
 87c:	ec4e                	sd	s3,24(sp)
 87e:	e852                	sd	s4,16(sp)
 880:	e456                	sd	s5,8(sp)
 882:	e05a                	sd	s6,0(sp)
 884:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 886:	02051493          	slli	s1,a0,0x20
 88a:	9081                	srli	s1,s1,0x20
 88c:	04bd                	addi	s1,s1,15
 88e:	8091                	srli	s1,s1,0x4
 890:	0014899b          	addiw	s3,s1,1
 894:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 896:	00000517          	auipc	a0,0x0
 89a:	14253503          	ld	a0,322(a0) # 9d8 <freep>
 89e:	c515                	beqz	a0,8ca <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a2:	4798                	lw	a4,8(a5)
 8a4:	02977f63          	bgeu	a4,s1,8e2 <malloc+0x70>
 8a8:	8a4e                	mv	s4,s3
 8aa:	0009871b          	sext.w	a4,s3
 8ae:	6685                	lui	a3,0x1
 8b0:	00d77363          	bgeu	a4,a3,8b6 <malloc+0x44>
 8b4:	6a05                	lui	s4,0x1
 8b6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8ba:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8be:	00000917          	auipc	s2,0x0
 8c2:	11a90913          	addi	s2,s2,282 # 9d8 <freep>
  if(p == (char*)-1)
 8c6:	5afd                	li	s5,-1
 8c8:	a88d                	j	93a <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8ca:	00000797          	auipc	a5,0x0
 8ce:	11678793          	addi	a5,a5,278 # 9e0 <base>
 8d2:	00000717          	auipc	a4,0x0
 8d6:	10f73323          	sd	a5,262(a4) # 9d8 <freep>
 8da:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8dc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8e0:	b7e1                	j	8a8 <malloc+0x36>
      if(p->s.size == nunits)
 8e2:	02e48b63          	beq	s1,a4,918 <malloc+0xa6>
        p->s.size -= nunits;
 8e6:	4137073b          	subw	a4,a4,s3
 8ea:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8ec:	1702                	slli	a4,a4,0x20
 8ee:	9301                	srli	a4,a4,0x20
 8f0:	0712                	slli	a4,a4,0x4
 8f2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8f4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8f8:	00000717          	auipc	a4,0x0
 8fc:	0ea73023          	sd	a0,224(a4) # 9d8 <freep>
      return (void*)(p + 1);
 900:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 904:	70e2                	ld	ra,56(sp)
 906:	7442                	ld	s0,48(sp)
 908:	74a2                	ld	s1,40(sp)
 90a:	7902                	ld	s2,32(sp)
 90c:	69e2                	ld	s3,24(sp)
 90e:	6a42                	ld	s4,16(sp)
 910:	6aa2                	ld	s5,8(sp)
 912:	6b02                	ld	s6,0(sp)
 914:	6121                	addi	sp,sp,64
 916:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 918:	6398                	ld	a4,0(a5)
 91a:	e118                	sd	a4,0(a0)
 91c:	bff1                	j	8f8 <malloc+0x86>
  hp->s.size = nu;
 91e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 922:	0541                	addi	a0,a0,16
 924:	00000097          	auipc	ra,0x0
 928:	ec6080e7          	jalr	-314(ra) # 7ea <free>
  return freep;
 92c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 930:	d971                	beqz	a0,904 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 932:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 934:	4798                	lw	a4,8(a5)
 936:	fa9776e3          	bgeu	a4,s1,8e2 <malloc+0x70>
    if(p == freep)
 93a:	00093703          	ld	a4,0(s2)
 93e:	853e                	mv	a0,a5
 940:	fef719e3          	bne	a4,a5,932 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 944:	8552                	mv	a0,s4
 946:	00000097          	auipc	ra,0x0
 94a:	b66080e7          	jalr	-1178(ra) # 4ac <sbrk>
  if(p == (char*)-1)
 94e:	fd5518e3          	bne	a0,s5,91e <malloc+0xac>
        return 0;
 952:	4501                	li	a0,0
 954:	bf45                	j	904 <malloc+0x92>
