
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:



int
main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    // pause_system_dem(10, 10, 100);
    exit(0);
   8:	4501                	li	a0,0
   a:	00000097          	auipc	ra,0x0
   e:	27e080e7          	jalr	638(ra) # 288 <exit>

0000000000000012 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  12:	1141                	addi	sp,sp,-16
  14:	e422                	sd	s0,8(sp)
  16:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  18:	87aa                	mv	a5,a0
  1a:	0585                	addi	a1,a1,1
  1c:	0785                	addi	a5,a5,1
  1e:	fff5c703          	lbu	a4,-1(a1)
  22:	fee78fa3          	sb	a4,-1(a5)
  26:	fb75                	bnez	a4,1a <strcpy+0x8>
    ;
  return os;
}
  28:	6422                	ld	s0,8(sp)
  2a:	0141                	addi	sp,sp,16
  2c:	8082                	ret

000000000000002e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  2e:	1141                	addi	sp,sp,-16
  30:	e422                	sd	s0,8(sp)
  32:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  34:	00054783          	lbu	a5,0(a0)
  38:	cb91                	beqz	a5,4c <strcmp+0x1e>
  3a:	0005c703          	lbu	a4,0(a1)
  3e:	00f71763          	bne	a4,a5,4c <strcmp+0x1e>
    p++, q++;
  42:	0505                	addi	a0,a0,1
  44:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  46:	00054783          	lbu	a5,0(a0)
  4a:	fbe5                	bnez	a5,3a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  4c:	0005c503          	lbu	a0,0(a1)
}
  50:	40a7853b          	subw	a0,a5,a0
  54:	6422                	ld	s0,8(sp)
  56:	0141                	addi	sp,sp,16
  58:	8082                	ret

000000000000005a <strlen>:

uint
strlen(const char *s)
{
  5a:	1141                	addi	sp,sp,-16
  5c:	e422                	sd	s0,8(sp)
  5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  60:	00054783          	lbu	a5,0(a0)
  64:	cf91                	beqz	a5,80 <strlen+0x26>
  66:	0505                	addi	a0,a0,1
  68:	87aa                	mv	a5,a0
  6a:	4685                	li	a3,1
  6c:	9e89                	subw	a3,a3,a0
  6e:	00f6853b          	addw	a0,a3,a5
  72:	0785                	addi	a5,a5,1
  74:	fff7c703          	lbu	a4,-1(a5)
  78:	fb7d                	bnez	a4,6e <strlen+0x14>
    ;
  return n;
}
  7a:	6422                	ld	s0,8(sp)
  7c:	0141                	addi	sp,sp,16
  7e:	8082                	ret
  for(n = 0; s[n]; n++)
  80:	4501                	li	a0,0
  82:	bfe5                	j	7a <strlen+0x20>

0000000000000084 <memset>:

void*
memset(void *dst, int c, uint n)
{
  84:	1141                	addi	sp,sp,-16
  86:	e422                	sd	s0,8(sp)
  88:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  8a:	ce09                	beqz	a2,a4 <memset+0x20>
  8c:	87aa                	mv	a5,a0
  8e:	fff6071b          	addiw	a4,a2,-1
  92:	1702                	slli	a4,a4,0x20
  94:	9301                	srli	a4,a4,0x20
  96:	0705                	addi	a4,a4,1
  98:	972a                	add	a4,a4,a0
    cdst[i] = c;
  9a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  9e:	0785                	addi	a5,a5,1
  a0:	fee79de3          	bne	a5,a4,9a <memset+0x16>
  }
  return dst;
}
  a4:	6422                	ld	s0,8(sp)
  a6:	0141                	addi	sp,sp,16
  a8:	8082                	ret

00000000000000aa <strchr>:

char*
strchr(const char *s, char c)
{
  aa:	1141                	addi	sp,sp,-16
  ac:	e422                	sd	s0,8(sp)
  ae:	0800                	addi	s0,sp,16
  for(; *s; s++)
  b0:	00054783          	lbu	a5,0(a0)
  b4:	cb99                	beqz	a5,ca <strchr+0x20>
    if(*s == c)
  b6:	00f58763          	beq	a1,a5,c4 <strchr+0x1a>
  for(; *s; s++)
  ba:	0505                	addi	a0,a0,1
  bc:	00054783          	lbu	a5,0(a0)
  c0:	fbfd                	bnez	a5,b6 <strchr+0xc>
      return (char*)s;
  return 0;
  c2:	4501                	li	a0,0
}
  c4:	6422                	ld	s0,8(sp)
  c6:	0141                	addi	sp,sp,16
  c8:	8082                	ret
  return 0;
  ca:	4501                	li	a0,0
  cc:	bfe5                	j	c4 <strchr+0x1a>

00000000000000ce <gets>:

char*
gets(char *buf, int max)
{
  ce:	711d                	addi	sp,sp,-96
  d0:	ec86                	sd	ra,88(sp)
  d2:	e8a2                	sd	s0,80(sp)
  d4:	e4a6                	sd	s1,72(sp)
  d6:	e0ca                	sd	s2,64(sp)
  d8:	fc4e                	sd	s3,56(sp)
  da:	f852                	sd	s4,48(sp)
  dc:	f456                	sd	s5,40(sp)
  de:	f05a                	sd	s6,32(sp)
  e0:	ec5e                	sd	s7,24(sp)
  e2:	1080                	addi	s0,sp,96
  e4:	8baa                	mv	s7,a0
  e6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
  e8:	892a                	mv	s2,a0
  ea:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
  ec:	4aa9                	li	s5,10
  ee:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
  f0:	89a6                	mv	s3,s1
  f2:	2485                	addiw	s1,s1,1
  f4:	0344d863          	bge	s1,s4,124 <gets+0x56>
    cc = read(0, &c, 1);
  f8:	4605                	li	a2,1
  fa:	faf40593          	addi	a1,s0,-81
  fe:	4501                	li	a0,0
 100:	00000097          	auipc	ra,0x0
 104:	1a0080e7          	jalr	416(ra) # 2a0 <read>
    if(cc < 1)
 108:	00a05e63          	blez	a0,124 <gets+0x56>
    buf[i++] = c;
 10c:	faf44783          	lbu	a5,-81(s0)
 110:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 114:	01578763          	beq	a5,s5,122 <gets+0x54>
 118:	0905                	addi	s2,s2,1
 11a:	fd679be3          	bne	a5,s6,f0 <gets+0x22>
  for(i=0; i+1 < max; ){
 11e:	89a6                	mv	s3,s1
 120:	a011                	j	124 <gets+0x56>
 122:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 124:	99de                	add	s3,s3,s7
 126:	00098023          	sb	zero,0(s3)
  return buf;
}
 12a:	855e                	mv	a0,s7
 12c:	60e6                	ld	ra,88(sp)
 12e:	6446                	ld	s0,80(sp)
 130:	64a6                	ld	s1,72(sp)
 132:	6906                	ld	s2,64(sp)
 134:	79e2                	ld	s3,56(sp)
 136:	7a42                	ld	s4,48(sp)
 138:	7aa2                	ld	s5,40(sp)
 13a:	7b02                	ld	s6,32(sp)
 13c:	6be2                	ld	s7,24(sp)
 13e:	6125                	addi	sp,sp,96
 140:	8082                	ret

0000000000000142 <stat>:

int
stat(const char *n, struct stat *st)
{
 142:	1101                	addi	sp,sp,-32
 144:	ec06                	sd	ra,24(sp)
 146:	e822                	sd	s0,16(sp)
 148:	e426                	sd	s1,8(sp)
 14a:	e04a                	sd	s2,0(sp)
 14c:	1000                	addi	s0,sp,32
 14e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 150:	4581                	li	a1,0
 152:	00000097          	auipc	ra,0x0
 156:	176080e7          	jalr	374(ra) # 2c8 <open>
  if(fd < 0)
 15a:	02054563          	bltz	a0,184 <stat+0x42>
 15e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 160:	85ca                	mv	a1,s2
 162:	00000097          	auipc	ra,0x0
 166:	17e080e7          	jalr	382(ra) # 2e0 <fstat>
 16a:	892a                	mv	s2,a0
  close(fd);
 16c:	8526                	mv	a0,s1
 16e:	00000097          	auipc	ra,0x0
 172:	142080e7          	jalr	322(ra) # 2b0 <close>
  return r;
}
 176:	854a                	mv	a0,s2
 178:	60e2                	ld	ra,24(sp)
 17a:	6442                	ld	s0,16(sp)
 17c:	64a2                	ld	s1,8(sp)
 17e:	6902                	ld	s2,0(sp)
 180:	6105                	addi	sp,sp,32
 182:	8082                	ret
    return -1;
 184:	597d                	li	s2,-1
 186:	bfc5                	j	176 <stat+0x34>

0000000000000188 <atoi>:

int
atoi(const char *s)
{
 188:	1141                	addi	sp,sp,-16
 18a:	e422                	sd	s0,8(sp)
 18c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 18e:	00054603          	lbu	a2,0(a0)
 192:	fd06079b          	addiw	a5,a2,-48
 196:	0ff7f793          	andi	a5,a5,255
 19a:	4725                	li	a4,9
 19c:	02f76963          	bltu	a4,a5,1ce <atoi+0x46>
 1a0:	86aa                	mv	a3,a0
  n = 0;
 1a2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1a4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1a6:	0685                	addi	a3,a3,1
 1a8:	0025179b          	slliw	a5,a0,0x2
 1ac:	9fa9                	addw	a5,a5,a0
 1ae:	0017979b          	slliw	a5,a5,0x1
 1b2:	9fb1                	addw	a5,a5,a2
 1b4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1b8:	0006c603          	lbu	a2,0(a3)
 1bc:	fd06071b          	addiw	a4,a2,-48
 1c0:	0ff77713          	andi	a4,a4,255
 1c4:	fee5f1e3          	bgeu	a1,a4,1a6 <atoi+0x1e>
  return n;
}
 1c8:	6422                	ld	s0,8(sp)
 1ca:	0141                	addi	sp,sp,16
 1cc:	8082                	ret
  n = 0;
 1ce:	4501                	li	a0,0
 1d0:	bfe5                	j	1c8 <atoi+0x40>

00000000000001d2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1d2:	1141                	addi	sp,sp,-16
 1d4:	e422                	sd	s0,8(sp)
 1d6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1d8:	02b57663          	bgeu	a0,a1,204 <memmove+0x32>
    while(n-- > 0)
 1dc:	02c05163          	blez	a2,1fe <memmove+0x2c>
 1e0:	fff6079b          	addiw	a5,a2,-1
 1e4:	1782                	slli	a5,a5,0x20
 1e6:	9381                	srli	a5,a5,0x20
 1e8:	0785                	addi	a5,a5,1
 1ea:	97aa                	add	a5,a5,a0
  dst = vdst;
 1ec:	872a                	mv	a4,a0
      *dst++ = *src++;
 1ee:	0585                	addi	a1,a1,1
 1f0:	0705                	addi	a4,a4,1
 1f2:	fff5c683          	lbu	a3,-1(a1)
 1f6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 1fa:	fee79ae3          	bne	a5,a4,1ee <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 1fe:	6422                	ld	s0,8(sp)
 200:	0141                	addi	sp,sp,16
 202:	8082                	ret
    dst += n;
 204:	00c50733          	add	a4,a0,a2
    src += n;
 208:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 20a:	fec05ae3          	blez	a2,1fe <memmove+0x2c>
 20e:	fff6079b          	addiw	a5,a2,-1
 212:	1782                	slli	a5,a5,0x20
 214:	9381                	srli	a5,a5,0x20
 216:	fff7c793          	not	a5,a5
 21a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 21c:	15fd                	addi	a1,a1,-1
 21e:	177d                	addi	a4,a4,-1
 220:	0005c683          	lbu	a3,0(a1)
 224:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 228:	fee79ae3          	bne	a5,a4,21c <memmove+0x4a>
 22c:	bfc9                	j	1fe <memmove+0x2c>

000000000000022e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 22e:	1141                	addi	sp,sp,-16
 230:	e422                	sd	s0,8(sp)
 232:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 234:	ca05                	beqz	a2,264 <memcmp+0x36>
 236:	fff6069b          	addiw	a3,a2,-1
 23a:	1682                	slli	a3,a3,0x20
 23c:	9281                	srli	a3,a3,0x20
 23e:	0685                	addi	a3,a3,1
 240:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 242:	00054783          	lbu	a5,0(a0)
 246:	0005c703          	lbu	a4,0(a1)
 24a:	00e79863          	bne	a5,a4,25a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 24e:	0505                	addi	a0,a0,1
    p2++;
 250:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 252:	fed518e3          	bne	a0,a3,242 <memcmp+0x14>
  }
  return 0;
 256:	4501                	li	a0,0
 258:	a019                	j	25e <memcmp+0x30>
      return *p1 - *p2;
 25a:	40e7853b          	subw	a0,a5,a4
}
 25e:	6422                	ld	s0,8(sp)
 260:	0141                	addi	sp,sp,16
 262:	8082                	ret
  return 0;
 264:	4501                	li	a0,0
 266:	bfe5                	j	25e <memcmp+0x30>

0000000000000268 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 268:	1141                	addi	sp,sp,-16
 26a:	e406                	sd	ra,8(sp)
 26c:	e022                	sd	s0,0(sp)
 26e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 270:	00000097          	auipc	ra,0x0
 274:	f62080e7          	jalr	-158(ra) # 1d2 <memmove>
}
 278:	60a2                	ld	ra,8(sp)
 27a:	6402                	ld	s0,0(sp)
 27c:	0141                	addi	sp,sp,16
 27e:	8082                	ret

0000000000000280 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 280:	4885                	li	a7,1
 ecall
 282:	00000073          	ecall
 ret
 286:	8082                	ret

0000000000000288 <exit>:
.global exit
exit:
 li a7, SYS_exit
 288:	4889                	li	a7,2
 ecall
 28a:	00000073          	ecall
 ret
 28e:	8082                	ret

0000000000000290 <wait>:
.global wait
wait:
 li a7, SYS_wait
 290:	488d                	li	a7,3
 ecall
 292:	00000073          	ecall
 ret
 296:	8082                	ret

0000000000000298 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 298:	4891                	li	a7,4
 ecall
 29a:	00000073          	ecall
 ret
 29e:	8082                	ret

00000000000002a0 <read>:
.global read
read:
 li a7, SYS_read
 2a0:	4895                	li	a7,5
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <write>:
.global write
write:
 li a7, SYS_write
 2a8:	48c1                	li	a7,16
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <close>:
.global close
close:
 li a7, SYS_close
 2b0:	48d5                	li	a7,21
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2b8:	4899                	li	a7,6
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2c0:	489d                	li	a7,7
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <open>:
.global open
open:
 li a7, SYS_open
 2c8:	48bd                	li	a7,15
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2d0:	48c5                	li	a7,17
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2d8:	48c9                	li	a7,18
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2e0:	48a1                	li	a7,8
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <link>:
.global link
link:
 li a7, SYS_link
 2e8:	48cd                	li	a7,19
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2f0:	48d1                	li	a7,20
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 2f8:	48a5                	li	a7,9
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <dup>:
.global dup
dup:
 li a7, SYS_dup
 300:	48a9                	li	a7,10
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 308:	48ad                	li	a7,11
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 310:	48b1                	li	a7,12
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 318:	48b5                	li	a7,13
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 320:	48b9                	li	a7,14
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <kill_sys>:
.global kill_sys
kill_sys:
 li a7, SYS_kill_sys
 328:	48d9                	li	a7,22
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <pause_sys>:
.global pause_sys
pause_sys:
 li a7, SYS_pause_sys
 330:	48dd                	li	a7,23
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 338:	48e1                	li	a7,24
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 340:	1101                	addi	sp,sp,-32
 342:	ec06                	sd	ra,24(sp)
 344:	e822                	sd	s0,16(sp)
 346:	1000                	addi	s0,sp,32
 348:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 34c:	4605                	li	a2,1
 34e:	fef40593          	addi	a1,s0,-17
 352:	00000097          	auipc	ra,0x0
 356:	f56080e7          	jalr	-170(ra) # 2a8 <write>
}
 35a:	60e2                	ld	ra,24(sp)
 35c:	6442                	ld	s0,16(sp)
 35e:	6105                	addi	sp,sp,32
 360:	8082                	ret

0000000000000362 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 362:	7139                	addi	sp,sp,-64
 364:	fc06                	sd	ra,56(sp)
 366:	f822                	sd	s0,48(sp)
 368:	f426                	sd	s1,40(sp)
 36a:	f04a                	sd	s2,32(sp)
 36c:	ec4e                	sd	s3,24(sp)
 36e:	0080                	addi	s0,sp,64
 370:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 372:	c299                	beqz	a3,378 <printint+0x16>
 374:	0805c863          	bltz	a1,404 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 378:	2581                	sext.w	a1,a1
  neg = 0;
 37a:	4881                	li	a7,0
 37c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 380:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 382:	2601                	sext.w	a2,a2
 384:	00000517          	auipc	a0,0x0
 388:	44450513          	addi	a0,a0,1092 # 7c8 <digits>
 38c:	883a                	mv	a6,a4
 38e:	2705                	addiw	a4,a4,1
 390:	02c5f7bb          	remuw	a5,a1,a2
 394:	1782                	slli	a5,a5,0x20
 396:	9381                	srli	a5,a5,0x20
 398:	97aa                	add	a5,a5,a0
 39a:	0007c783          	lbu	a5,0(a5)
 39e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3a2:	0005879b          	sext.w	a5,a1
 3a6:	02c5d5bb          	divuw	a1,a1,a2
 3aa:	0685                	addi	a3,a3,1
 3ac:	fec7f0e3          	bgeu	a5,a2,38c <printint+0x2a>
  if(neg)
 3b0:	00088b63          	beqz	a7,3c6 <printint+0x64>
    buf[i++] = '-';
 3b4:	fd040793          	addi	a5,s0,-48
 3b8:	973e                	add	a4,a4,a5
 3ba:	02d00793          	li	a5,45
 3be:	fef70823          	sb	a5,-16(a4)
 3c2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3c6:	02e05863          	blez	a4,3f6 <printint+0x94>
 3ca:	fc040793          	addi	a5,s0,-64
 3ce:	00e78933          	add	s2,a5,a4
 3d2:	fff78993          	addi	s3,a5,-1
 3d6:	99ba                	add	s3,s3,a4
 3d8:	377d                	addiw	a4,a4,-1
 3da:	1702                	slli	a4,a4,0x20
 3dc:	9301                	srli	a4,a4,0x20
 3de:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3e2:	fff94583          	lbu	a1,-1(s2)
 3e6:	8526                	mv	a0,s1
 3e8:	00000097          	auipc	ra,0x0
 3ec:	f58080e7          	jalr	-168(ra) # 340 <putc>
  while(--i >= 0)
 3f0:	197d                	addi	s2,s2,-1
 3f2:	ff3918e3          	bne	s2,s3,3e2 <printint+0x80>
}
 3f6:	70e2                	ld	ra,56(sp)
 3f8:	7442                	ld	s0,48(sp)
 3fa:	74a2                	ld	s1,40(sp)
 3fc:	7902                	ld	s2,32(sp)
 3fe:	69e2                	ld	s3,24(sp)
 400:	6121                	addi	sp,sp,64
 402:	8082                	ret
    x = -xx;
 404:	40b005bb          	negw	a1,a1
    neg = 1;
 408:	4885                	li	a7,1
    x = -xx;
 40a:	bf8d                	j	37c <printint+0x1a>

000000000000040c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 40c:	7119                	addi	sp,sp,-128
 40e:	fc86                	sd	ra,120(sp)
 410:	f8a2                	sd	s0,112(sp)
 412:	f4a6                	sd	s1,104(sp)
 414:	f0ca                	sd	s2,96(sp)
 416:	ecce                	sd	s3,88(sp)
 418:	e8d2                	sd	s4,80(sp)
 41a:	e4d6                	sd	s5,72(sp)
 41c:	e0da                	sd	s6,64(sp)
 41e:	fc5e                	sd	s7,56(sp)
 420:	f862                	sd	s8,48(sp)
 422:	f466                	sd	s9,40(sp)
 424:	f06a                	sd	s10,32(sp)
 426:	ec6e                	sd	s11,24(sp)
 428:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 42a:	0005c903          	lbu	s2,0(a1)
 42e:	18090f63          	beqz	s2,5cc <vprintf+0x1c0>
 432:	8aaa                	mv	s5,a0
 434:	8b32                	mv	s6,a2
 436:	00158493          	addi	s1,a1,1
  state = 0;
 43a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 43c:	02500a13          	li	s4,37
      if(c == 'd'){
 440:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 444:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 448:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 44c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 450:	00000b97          	auipc	s7,0x0
 454:	378b8b93          	addi	s7,s7,888 # 7c8 <digits>
 458:	a839                	j	476 <vprintf+0x6a>
        putc(fd, c);
 45a:	85ca                	mv	a1,s2
 45c:	8556                	mv	a0,s5
 45e:	00000097          	auipc	ra,0x0
 462:	ee2080e7          	jalr	-286(ra) # 340 <putc>
 466:	a019                	j	46c <vprintf+0x60>
    } else if(state == '%'){
 468:	01498f63          	beq	s3,s4,486 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 46c:	0485                	addi	s1,s1,1
 46e:	fff4c903          	lbu	s2,-1(s1)
 472:	14090d63          	beqz	s2,5cc <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 476:	0009079b          	sext.w	a5,s2
    if(state == 0){
 47a:	fe0997e3          	bnez	s3,468 <vprintf+0x5c>
      if(c == '%'){
 47e:	fd479ee3          	bne	a5,s4,45a <vprintf+0x4e>
        state = '%';
 482:	89be                	mv	s3,a5
 484:	b7e5                	j	46c <vprintf+0x60>
      if(c == 'd'){
 486:	05878063          	beq	a5,s8,4c6 <vprintf+0xba>
      } else if(c == 'l') {
 48a:	05978c63          	beq	a5,s9,4e2 <vprintf+0xd6>
      } else if(c == 'x') {
 48e:	07a78863          	beq	a5,s10,4fe <vprintf+0xf2>
      } else if(c == 'p') {
 492:	09b78463          	beq	a5,s11,51a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 496:	07300713          	li	a4,115
 49a:	0ce78663          	beq	a5,a4,566 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 49e:	06300713          	li	a4,99
 4a2:	0ee78e63          	beq	a5,a4,59e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4a6:	11478863          	beq	a5,s4,5b6 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4aa:	85d2                	mv	a1,s4
 4ac:	8556                	mv	a0,s5
 4ae:	00000097          	auipc	ra,0x0
 4b2:	e92080e7          	jalr	-366(ra) # 340 <putc>
        putc(fd, c);
 4b6:	85ca                	mv	a1,s2
 4b8:	8556                	mv	a0,s5
 4ba:	00000097          	auipc	ra,0x0
 4be:	e86080e7          	jalr	-378(ra) # 340 <putc>
      }
      state = 0;
 4c2:	4981                	li	s3,0
 4c4:	b765                	j	46c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4c6:	008b0913          	addi	s2,s6,8
 4ca:	4685                	li	a3,1
 4cc:	4629                	li	a2,10
 4ce:	000b2583          	lw	a1,0(s6)
 4d2:	8556                	mv	a0,s5
 4d4:	00000097          	auipc	ra,0x0
 4d8:	e8e080e7          	jalr	-370(ra) # 362 <printint>
 4dc:	8b4a                	mv	s6,s2
      state = 0;
 4de:	4981                	li	s3,0
 4e0:	b771                	j	46c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4e2:	008b0913          	addi	s2,s6,8
 4e6:	4681                	li	a3,0
 4e8:	4629                	li	a2,10
 4ea:	000b2583          	lw	a1,0(s6)
 4ee:	8556                	mv	a0,s5
 4f0:	00000097          	auipc	ra,0x0
 4f4:	e72080e7          	jalr	-398(ra) # 362 <printint>
 4f8:	8b4a                	mv	s6,s2
      state = 0;
 4fa:	4981                	li	s3,0
 4fc:	bf85                	j	46c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4fe:	008b0913          	addi	s2,s6,8
 502:	4681                	li	a3,0
 504:	4641                	li	a2,16
 506:	000b2583          	lw	a1,0(s6)
 50a:	8556                	mv	a0,s5
 50c:	00000097          	auipc	ra,0x0
 510:	e56080e7          	jalr	-426(ra) # 362 <printint>
 514:	8b4a                	mv	s6,s2
      state = 0;
 516:	4981                	li	s3,0
 518:	bf91                	j	46c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 51a:	008b0793          	addi	a5,s6,8
 51e:	f8f43423          	sd	a5,-120(s0)
 522:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 526:	03000593          	li	a1,48
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	e14080e7          	jalr	-492(ra) # 340 <putc>
  putc(fd, 'x');
 534:	85ea                	mv	a1,s10
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e08080e7          	jalr	-504(ra) # 340 <putc>
 540:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 542:	03c9d793          	srli	a5,s3,0x3c
 546:	97de                	add	a5,a5,s7
 548:	0007c583          	lbu	a1,0(a5)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	df2080e7          	jalr	-526(ra) # 340 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 556:	0992                	slli	s3,s3,0x4
 558:	397d                	addiw	s2,s2,-1
 55a:	fe0914e3          	bnez	s2,542 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 55e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 562:	4981                	li	s3,0
 564:	b721                	j	46c <vprintf+0x60>
        s = va_arg(ap, char*);
 566:	008b0993          	addi	s3,s6,8
 56a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 56e:	02090163          	beqz	s2,590 <vprintf+0x184>
        while(*s != 0){
 572:	00094583          	lbu	a1,0(s2)
 576:	c9a1                	beqz	a1,5c6 <vprintf+0x1ba>
          putc(fd, *s);
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	dc6080e7          	jalr	-570(ra) # 340 <putc>
          s++;
 582:	0905                	addi	s2,s2,1
        while(*s != 0){
 584:	00094583          	lbu	a1,0(s2)
 588:	f9e5                	bnez	a1,578 <vprintf+0x16c>
        s = va_arg(ap, char*);
 58a:	8b4e                	mv	s6,s3
      state = 0;
 58c:	4981                	li	s3,0
 58e:	bdf9                	j	46c <vprintf+0x60>
          s = "(null)";
 590:	00000917          	auipc	s2,0x0
 594:	23090913          	addi	s2,s2,560 # 7c0 <malloc+0xea>
        while(*s != 0){
 598:	02800593          	li	a1,40
 59c:	bff1                	j	578 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 59e:	008b0913          	addi	s2,s6,8
 5a2:	000b4583          	lbu	a1,0(s6)
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	d98080e7          	jalr	-616(ra) # 340 <putc>
 5b0:	8b4a                	mv	s6,s2
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	bd65                	j	46c <vprintf+0x60>
        putc(fd, c);
 5b6:	85d2                	mv	a1,s4
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	d86080e7          	jalr	-634(ra) # 340 <putc>
      state = 0;
 5c2:	4981                	li	s3,0
 5c4:	b565                	j	46c <vprintf+0x60>
        s = va_arg(ap, char*);
 5c6:	8b4e                	mv	s6,s3
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b54d                	j	46c <vprintf+0x60>
    }
  }
}
 5cc:	70e6                	ld	ra,120(sp)
 5ce:	7446                	ld	s0,112(sp)
 5d0:	74a6                	ld	s1,104(sp)
 5d2:	7906                	ld	s2,96(sp)
 5d4:	69e6                	ld	s3,88(sp)
 5d6:	6a46                	ld	s4,80(sp)
 5d8:	6aa6                	ld	s5,72(sp)
 5da:	6b06                	ld	s6,64(sp)
 5dc:	7be2                	ld	s7,56(sp)
 5de:	7c42                	ld	s8,48(sp)
 5e0:	7ca2                	ld	s9,40(sp)
 5e2:	7d02                	ld	s10,32(sp)
 5e4:	6de2                	ld	s11,24(sp)
 5e6:	6109                	addi	sp,sp,128
 5e8:	8082                	ret

00000000000005ea <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5ea:	715d                	addi	sp,sp,-80
 5ec:	ec06                	sd	ra,24(sp)
 5ee:	e822                	sd	s0,16(sp)
 5f0:	1000                	addi	s0,sp,32
 5f2:	e010                	sd	a2,0(s0)
 5f4:	e414                	sd	a3,8(s0)
 5f6:	e818                	sd	a4,16(s0)
 5f8:	ec1c                	sd	a5,24(s0)
 5fa:	03043023          	sd	a6,32(s0)
 5fe:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 602:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 606:	8622                	mv	a2,s0
 608:	00000097          	auipc	ra,0x0
 60c:	e04080e7          	jalr	-508(ra) # 40c <vprintf>
}
 610:	60e2                	ld	ra,24(sp)
 612:	6442                	ld	s0,16(sp)
 614:	6161                	addi	sp,sp,80
 616:	8082                	ret

0000000000000618 <printf>:

void
printf(const char *fmt, ...)
{
 618:	711d                	addi	sp,sp,-96
 61a:	ec06                	sd	ra,24(sp)
 61c:	e822                	sd	s0,16(sp)
 61e:	1000                	addi	s0,sp,32
 620:	e40c                	sd	a1,8(s0)
 622:	e810                	sd	a2,16(s0)
 624:	ec14                	sd	a3,24(s0)
 626:	f018                	sd	a4,32(s0)
 628:	f41c                	sd	a5,40(s0)
 62a:	03043823          	sd	a6,48(s0)
 62e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 632:	00840613          	addi	a2,s0,8
 636:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 63a:	85aa                	mv	a1,a0
 63c:	4505                	li	a0,1
 63e:	00000097          	auipc	ra,0x0
 642:	dce080e7          	jalr	-562(ra) # 40c <vprintf>
}
 646:	60e2                	ld	ra,24(sp)
 648:	6442                	ld	s0,16(sp)
 64a:	6125                	addi	sp,sp,96
 64c:	8082                	ret

000000000000064e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 64e:	1141                	addi	sp,sp,-16
 650:	e422                	sd	s0,8(sp)
 652:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 654:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 658:	00000797          	auipc	a5,0x0
 65c:	1887b783          	ld	a5,392(a5) # 7e0 <freep>
 660:	a805                	j	690 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 662:	4618                	lw	a4,8(a2)
 664:	9db9                	addw	a1,a1,a4
 666:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 66a:	6398                	ld	a4,0(a5)
 66c:	6318                	ld	a4,0(a4)
 66e:	fee53823          	sd	a4,-16(a0)
 672:	a091                	j	6b6 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 674:	ff852703          	lw	a4,-8(a0)
 678:	9e39                	addw	a2,a2,a4
 67a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 67c:	ff053703          	ld	a4,-16(a0)
 680:	e398                	sd	a4,0(a5)
 682:	a099                	j	6c8 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 684:	6398                	ld	a4,0(a5)
 686:	00e7e463          	bltu	a5,a4,68e <free+0x40>
 68a:	00e6ea63          	bltu	a3,a4,69e <free+0x50>
{
 68e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 690:	fed7fae3          	bgeu	a5,a3,684 <free+0x36>
 694:	6398                	ld	a4,0(a5)
 696:	00e6e463          	bltu	a3,a4,69e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 69a:	fee7eae3          	bltu	a5,a4,68e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 69e:	ff852583          	lw	a1,-8(a0)
 6a2:	6390                	ld	a2,0(a5)
 6a4:	02059713          	slli	a4,a1,0x20
 6a8:	9301                	srli	a4,a4,0x20
 6aa:	0712                	slli	a4,a4,0x4
 6ac:	9736                	add	a4,a4,a3
 6ae:	fae60ae3          	beq	a2,a4,662 <free+0x14>
    bp->s.ptr = p->s.ptr;
 6b2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6b6:	4790                	lw	a2,8(a5)
 6b8:	02061713          	slli	a4,a2,0x20
 6bc:	9301                	srli	a4,a4,0x20
 6be:	0712                	slli	a4,a4,0x4
 6c0:	973e                	add	a4,a4,a5
 6c2:	fae689e3          	beq	a3,a4,674 <free+0x26>
  } else
    p->s.ptr = bp;
 6c6:	e394                	sd	a3,0(a5)
  freep = p;
 6c8:	00000717          	auipc	a4,0x0
 6cc:	10f73c23          	sd	a5,280(a4) # 7e0 <freep>
}
 6d0:	6422                	ld	s0,8(sp)
 6d2:	0141                	addi	sp,sp,16
 6d4:	8082                	ret

00000000000006d6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6d6:	7139                	addi	sp,sp,-64
 6d8:	fc06                	sd	ra,56(sp)
 6da:	f822                	sd	s0,48(sp)
 6dc:	f426                	sd	s1,40(sp)
 6de:	f04a                	sd	s2,32(sp)
 6e0:	ec4e                	sd	s3,24(sp)
 6e2:	e852                	sd	s4,16(sp)
 6e4:	e456                	sd	s5,8(sp)
 6e6:	e05a                	sd	s6,0(sp)
 6e8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6ea:	02051493          	slli	s1,a0,0x20
 6ee:	9081                	srli	s1,s1,0x20
 6f0:	04bd                	addi	s1,s1,15
 6f2:	8091                	srli	s1,s1,0x4
 6f4:	0014899b          	addiw	s3,s1,1
 6f8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6fa:	00000517          	auipc	a0,0x0
 6fe:	0e653503          	ld	a0,230(a0) # 7e0 <freep>
 702:	c515                	beqz	a0,72e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 704:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 706:	4798                	lw	a4,8(a5)
 708:	02977f63          	bgeu	a4,s1,746 <malloc+0x70>
 70c:	8a4e                	mv	s4,s3
 70e:	0009871b          	sext.w	a4,s3
 712:	6685                	lui	a3,0x1
 714:	00d77363          	bgeu	a4,a3,71a <malloc+0x44>
 718:	6a05                	lui	s4,0x1
 71a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 71e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 722:	00000917          	auipc	s2,0x0
 726:	0be90913          	addi	s2,s2,190 # 7e0 <freep>
  if(p == (char*)-1)
 72a:	5afd                	li	s5,-1
 72c:	a88d                	j	79e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 72e:	00000797          	auipc	a5,0x0
 732:	0ba78793          	addi	a5,a5,186 # 7e8 <base>
 736:	00000717          	auipc	a4,0x0
 73a:	0af73523          	sd	a5,170(a4) # 7e0 <freep>
 73e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 740:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 744:	b7e1                	j	70c <malloc+0x36>
      if(p->s.size == nunits)
 746:	02e48b63          	beq	s1,a4,77c <malloc+0xa6>
        p->s.size -= nunits;
 74a:	4137073b          	subw	a4,a4,s3
 74e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 750:	1702                	slli	a4,a4,0x20
 752:	9301                	srli	a4,a4,0x20
 754:	0712                	slli	a4,a4,0x4
 756:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 758:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 75c:	00000717          	auipc	a4,0x0
 760:	08a73223          	sd	a0,132(a4) # 7e0 <freep>
      return (void*)(p + 1);
 764:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 768:	70e2                	ld	ra,56(sp)
 76a:	7442                	ld	s0,48(sp)
 76c:	74a2                	ld	s1,40(sp)
 76e:	7902                	ld	s2,32(sp)
 770:	69e2                	ld	s3,24(sp)
 772:	6a42                	ld	s4,16(sp)
 774:	6aa2                	ld	s5,8(sp)
 776:	6b02                	ld	s6,0(sp)
 778:	6121                	addi	sp,sp,64
 77a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 77c:	6398                	ld	a4,0(a5)
 77e:	e118                	sd	a4,0(a0)
 780:	bff1                	j	75c <malloc+0x86>
  hp->s.size = nu;
 782:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 786:	0541                	addi	a0,a0,16
 788:	00000097          	auipc	ra,0x0
 78c:	ec6080e7          	jalr	-314(ra) # 64e <free>
  return freep;
 790:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 794:	d971                	beqz	a0,768 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 796:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 798:	4798                	lw	a4,8(a5)
 79a:	fa9776e3          	bgeu	a4,s1,746 <malloc+0x70>
    if(p == freep)
 79e:	00093703          	ld	a4,0(s2)
 7a2:	853e                	mv	a0,a5
 7a4:	fef719e3          	bne	a4,a5,796 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7a8:	8552                	mv	a0,s4
 7aa:	00000097          	auipc	ra,0x0
 7ae:	b66080e7          	jalr	-1178(ra) # 310 <sbrk>
  if(p == (char*)-1)
 7b2:	fd5518e3          	bne	a0,s5,782 <malloc+0xac>
        return 0;
 7b6:	4501                	li	a0,0
 7b8:	bf45                	j	768 <malloc+0x92>
