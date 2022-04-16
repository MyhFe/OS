
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

0000000000000338 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 338:	1101                	addi	sp,sp,-32
 33a:	ec06                	sd	ra,24(sp)
 33c:	e822                	sd	s0,16(sp)
 33e:	1000                	addi	s0,sp,32
 340:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 344:	4605                	li	a2,1
 346:	fef40593          	addi	a1,s0,-17
 34a:	00000097          	auipc	ra,0x0
 34e:	f5e080e7          	jalr	-162(ra) # 2a8 <write>
}
 352:	60e2                	ld	ra,24(sp)
 354:	6442                	ld	s0,16(sp)
 356:	6105                	addi	sp,sp,32
 358:	8082                	ret

000000000000035a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 35a:	7139                	addi	sp,sp,-64
 35c:	fc06                	sd	ra,56(sp)
 35e:	f822                	sd	s0,48(sp)
 360:	f426                	sd	s1,40(sp)
 362:	f04a                	sd	s2,32(sp)
 364:	ec4e                	sd	s3,24(sp)
 366:	0080                	addi	s0,sp,64
 368:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 36a:	c299                	beqz	a3,370 <printint+0x16>
 36c:	0805c863          	bltz	a1,3fc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 370:	2581                	sext.w	a1,a1
  neg = 0;
 372:	4881                	li	a7,0
 374:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 378:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 37a:	2601                	sext.w	a2,a2
 37c:	00000517          	auipc	a0,0x0
 380:	44450513          	addi	a0,a0,1092 # 7c0 <digits>
 384:	883a                	mv	a6,a4
 386:	2705                	addiw	a4,a4,1
 388:	02c5f7bb          	remuw	a5,a1,a2
 38c:	1782                	slli	a5,a5,0x20
 38e:	9381                	srli	a5,a5,0x20
 390:	97aa                	add	a5,a5,a0
 392:	0007c783          	lbu	a5,0(a5)
 396:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 39a:	0005879b          	sext.w	a5,a1
 39e:	02c5d5bb          	divuw	a1,a1,a2
 3a2:	0685                	addi	a3,a3,1
 3a4:	fec7f0e3          	bgeu	a5,a2,384 <printint+0x2a>
  if(neg)
 3a8:	00088b63          	beqz	a7,3be <printint+0x64>
    buf[i++] = '-';
 3ac:	fd040793          	addi	a5,s0,-48
 3b0:	973e                	add	a4,a4,a5
 3b2:	02d00793          	li	a5,45
 3b6:	fef70823          	sb	a5,-16(a4)
 3ba:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3be:	02e05863          	blez	a4,3ee <printint+0x94>
 3c2:	fc040793          	addi	a5,s0,-64
 3c6:	00e78933          	add	s2,a5,a4
 3ca:	fff78993          	addi	s3,a5,-1
 3ce:	99ba                	add	s3,s3,a4
 3d0:	377d                	addiw	a4,a4,-1
 3d2:	1702                	slli	a4,a4,0x20
 3d4:	9301                	srli	a4,a4,0x20
 3d6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3da:	fff94583          	lbu	a1,-1(s2)
 3de:	8526                	mv	a0,s1
 3e0:	00000097          	auipc	ra,0x0
 3e4:	f58080e7          	jalr	-168(ra) # 338 <putc>
  while(--i >= 0)
 3e8:	197d                	addi	s2,s2,-1
 3ea:	ff3918e3          	bne	s2,s3,3da <printint+0x80>
}
 3ee:	70e2                	ld	ra,56(sp)
 3f0:	7442                	ld	s0,48(sp)
 3f2:	74a2                	ld	s1,40(sp)
 3f4:	7902                	ld	s2,32(sp)
 3f6:	69e2                	ld	s3,24(sp)
 3f8:	6121                	addi	sp,sp,64
 3fa:	8082                	ret
    x = -xx;
 3fc:	40b005bb          	negw	a1,a1
    neg = 1;
 400:	4885                	li	a7,1
    x = -xx;
 402:	bf8d                	j	374 <printint+0x1a>

0000000000000404 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 404:	7119                	addi	sp,sp,-128
 406:	fc86                	sd	ra,120(sp)
 408:	f8a2                	sd	s0,112(sp)
 40a:	f4a6                	sd	s1,104(sp)
 40c:	f0ca                	sd	s2,96(sp)
 40e:	ecce                	sd	s3,88(sp)
 410:	e8d2                	sd	s4,80(sp)
 412:	e4d6                	sd	s5,72(sp)
 414:	e0da                	sd	s6,64(sp)
 416:	fc5e                	sd	s7,56(sp)
 418:	f862                	sd	s8,48(sp)
 41a:	f466                	sd	s9,40(sp)
 41c:	f06a                	sd	s10,32(sp)
 41e:	ec6e                	sd	s11,24(sp)
 420:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 422:	0005c903          	lbu	s2,0(a1)
 426:	18090f63          	beqz	s2,5c4 <vprintf+0x1c0>
 42a:	8aaa                	mv	s5,a0
 42c:	8b32                	mv	s6,a2
 42e:	00158493          	addi	s1,a1,1
  state = 0;
 432:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 434:	02500a13          	li	s4,37
      if(c == 'd'){
 438:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 43c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 440:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 444:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 448:	00000b97          	auipc	s7,0x0
 44c:	378b8b93          	addi	s7,s7,888 # 7c0 <digits>
 450:	a839                	j	46e <vprintf+0x6a>
        putc(fd, c);
 452:	85ca                	mv	a1,s2
 454:	8556                	mv	a0,s5
 456:	00000097          	auipc	ra,0x0
 45a:	ee2080e7          	jalr	-286(ra) # 338 <putc>
 45e:	a019                	j	464 <vprintf+0x60>
    } else if(state == '%'){
 460:	01498f63          	beq	s3,s4,47e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 464:	0485                	addi	s1,s1,1
 466:	fff4c903          	lbu	s2,-1(s1)
 46a:	14090d63          	beqz	s2,5c4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 46e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 472:	fe0997e3          	bnez	s3,460 <vprintf+0x5c>
      if(c == '%'){
 476:	fd479ee3          	bne	a5,s4,452 <vprintf+0x4e>
        state = '%';
 47a:	89be                	mv	s3,a5
 47c:	b7e5                	j	464 <vprintf+0x60>
      if(c == 'd'){
 47e:	05878063          	beq	a5,s8,4be <vprintf+0xba>
      } else if(c == 'l') {
 482:	05978c63          	beq	a5,s9,4da <vprintf+0xd6>
      } else if(c == 'x') {
 486:	07a78863          	beq	a5,s10,4f6 <vprintf+0xf2>
      } else if(c == 'p') {
 48a:	09b78463          	beq	a5,s11,512 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 48e:	07300713          	li	a4,115
 492:	0ce78663          	beq	a5,a4,55e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 496:	06300713          	li	a4,99
 49a:	0ee78e63          	beq	a5,a4,596 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 49e:	11478863          	beq	a5,s4,5ae <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4a2:	85d2                	mv	a1,s4
 4a4:	8556                	mv	a0,s5
 4a6:	00000097          	auipc	ra,0x0
 4aa:	e92080e7          	jalr	-366(ra) # 338 <putc>
        putc(fd, c);
 4ae:	85ca                	mv	a1,s2
 4b0:	8556                	mv	a0,s5
 4b2:	00000097          	auipc	ra,0x0
 4b6:	e86080e7          	jalr	-378(ra) # 338 <putc>
      }
      state = 0;
 4ba:	4981                	li	s3,0
 4bc:	b765                	j	464 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4be:	008b0913          	addi	s2,s6,8
 4c2:	4685                	li	a3,1
 4c4:	4629                	li	a2,10
 4c6:	000b2583          	lw	a1,0(s6)
 4ca:	8556                	mv	a0,s5
 4cc:	00000097          	auipc	ra,0x0
 4d0:	e8e080e7          	jalr	-370(ra) # 35a <printint>
 4d4:	8b4a                	mv	s6,s2
      state = 0;
 4d6:	4981                	li	s3,0
 4d8:	b771                	j	464 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4da:	008b0913          	addi	s2,s6,8
 4de:	4681                	li	a3,0
 4e0:	4629                	li	a2,10
 4e2:	000b2583          	lw	a1,0(s6)
 4e6:	8556                	mv	a0,s5
 4e8:	00000097          	auipc	ra,0x0
 4ec:	e72080e7          	jalr	-398(ra) # 35a <printint>
 4f0:	8b4a                	mv	s6,s2
      state = 0;
 4f2:	4981                	li	s3,0
 4f4:	bf85                	j	464 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4f6:	008b0913          	addi	s2,s6,8
 4fa:	4681                	li	a3,0
 4fc:	4641                	li	a2,16
 4fe:	000b2583          	lw	a1,0(s6)
 502:	8556                	mv	a0,s5
 504:	00000097          	auipc	ra,0x0
 508:	e56080e7          	jalr	-426(ra) # 35a <printint>
 50c:	8b4a                	mv	s6,s2
      state = 0;
 50e:	4981                	li	s3,0
 510:	bf91                	j	464 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 512:	008b0793          	addi	a5,s6,8
 516:	f8f43423          	sd	a5,-120(s0)
 51a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 51e:	03000593          	li	a1,48
 522:	8556                	mv	a0,s5
 524:	00000097          	auipc	ra,0x0
 528:	e14080e7          	jalr	-492(ra) # 338 <putc>
  putc(fd, 'x');
 52c:	85ea                	mv	a1,s10
 52e:	8556                	mv	a0,s5
 530:	00000097          	auipc	ra,0x0
 534:	e08080e7          	jalr	-504(ra) # 338 <putc>
 538:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 53a:	03c9d793          	srli	a5,s3,0x3c
 53e:	97de                	add	a5,a5,s7
 540:	0007c583          	lbu	a1,0(a5)
 544:	8556                	mv	a0,s5
 546:	00000097          	auipc	ra,0x0
 54a:	df2080e7          	jalr	-526(ra) # 338 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 54e:	0992                	slli	s3,s3,0x4
 550:	397d                	addiw	s2,s2,-1
 552:	fe0914e3          	bnez	s2,53a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 556:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 55a:	4981                	li	s3,0
 55c:	b721                	j	464 <vprintf+0x60>
        s = va_arg(ap, char*);
 55e:	008b0993          	addi	s3,s6,8
 562:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 566:	02090163          	beqz	s2,588 <vprintf+0x184>
        while(*s != 0){
 56a:	00094583          	lbu	a1,0(s2)
 56e:	c9a1                	beqz	a1,5be <vprintf+0x1ba>
          putc(fd, *s);
 570:	8556                	mv	a0,s5
 572:	00000097          	auipc	ra,0x0
 576:	dc6080e7          	jalr	-570(ra) # 338 <putc>
          s++;
 57a:	0905                	addi	s2,s2,1
        while(*s != 0){
 57c:	00094583          	lbu	a1,0(s2)
 580:	f9e5                	bnez	a1,570 <vprintf+0x16c>
        s = va_arg(ap, char*);
 582:	8b4e                	mv	s6,s3
      state = 0;
 584:	4981                	li	s3,0
 586:	bdf9                	j	464 <vprintf+0x60>
          s = "(null)";
 588:	00000917          	auipc	s2,0x0
 58c:	23090913          	addi	s2,s2,560 # 7b8 <malloc+0xea>
        while(*s != 0){
 590:	02800593          	li	a1,40
 594:	bff1                	j	570 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 596:	008b0913          	addi	s2,s6,8
 59a:	000b4583          	lbu	a1,0(s6)
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	d98080e7          	jalr	-616(ra) # 338 <putc>
 5a8:	8b4a                	mv	s6,s2
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	bd65                	j	464 <vprintf+0x60>
        putc(fd, c);
 5ae:	85d2                	mv	a1,s4
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	d86080e7          	jalr	-634(ra) # 338 <putc>
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	b565                	j	464 <vprintf+0x60>
        s = va_arg(ap, char*);
 5be:	8b4e                	mv	s6,s3
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	b54d                	j	464 <vprintf+0x60>
    }
  }
}
 5c4:	70e6                	ld	ra,120(sp)
 5c6:	7446                	ld	s0,112(sp)
 5c8:	74a6                	ld	s1,104(sp)
 5ca:	7906                	ld	s2,96(sp)
 5cc:	69e6                	ld	s3,88(sp)
 5ce:	6a46                	ld	s4,80(sp)
 5d0:	6aa6                	ld	s5,72(sp)
 5d2:	6b06                	ld	s6,64(sp)
 5d4:	7be2                	ld	s7,56(sp)
 5d6:	7c42                	ld	s8,48(sp)
 5d8:	7ca2                	ld	s9,40(sp)
 5da:	7d02                	ld	s10,32(sp)
 5dc:	6de2                	ld	s11,24(sp)
 5de:	6109                	addi	sp,sp,128
 5e0:	8082                	ret

00000000000005e2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5e2:	715d                	addi	sp,sp,-80
 5e4:	ec06                	sd	ra,24(sp)
 5e6:	e822                	sd	s0,16(sp)
 5e8:	1000                	addi	s0,sp,32
 5ea:	e010                	sd	a2,0(s0)
 5ec:	e414                	sd	a3,8(s0)
 5ee:	e818                	sd	a4,16(s0)
 5f0:	ec1c                	sd	a5,24(s0)
 5f2:	03043023          	sd	a6,32(s0)
 5f6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 5fa:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 5fe:	8622                	mv	a2,s0
 600:	00000097          	auipc	ra,0x0
 604:	e04080e7          	jalr	-508(ra) # 404 <vprintf>
}
 608:	60e2                	ld	ra,24(sp)
 60a:	6442                	ld	s0,16(sp)
 60c:	6161                	addi	sp,sp,80
 60e:	8082                	ret

0000000000000610 <printf>:

void
printf(const char *fmt, ...)
{
 610:	711d                	addi	sp,sp,-96
 612:	ec06                	sd	ra,24(sp)
 614:	e822                	sd	s0,16(sp)
 616:	1000                	addi	s0,sp,32
 618:	e40c                	sd	a1,8(s0)
 61a:	e810                	sd	a2,16(s0)
 61c:	ec14                	sd	a3,24(s0)
 61e:	f018                	sd	a4,32(s0)
 620:	f41c                	sd	a5,40(s0)
 622:	03043823          	sd	a6,48(s0)
 626:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 62a:	00840613          	addi	a2,s0,8
 62e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 632:	85aa                	mv	a1,a0
 634:	4505                	li	a0,1
 636:	00000097          	auipc	ra,0x0
 63a:	dce080e7          	jalr	-562(ra) # 404 <vprintf>
}
 63e:	60e2                	ld	ra,24(sp)
 640:	6442                	ld	s0,16(sp)
 642:	6125                	addi	sp,sp,96
 644:	8082                	ret

0000000000000646 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 646:	1141                	addi	sp,sp,-16
 648:	e422                	sd	s0,8(sp)
 64a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 64c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 650:	00000797          	auipc	a5,0x0
 654:	1887b783          	ld	a5,392(a5) # 7d8 <freep>
 658:	a805                	j	688 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 65a:	4618                	lw	a4,8(a2)
 65c:	9db9                	addw	a1,a1,a4
 65e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 662:	6398                	ld	a4,0(a5)
 664:	6318                	ld	a4,0(a4)
 666:	fee53823          	sd	a4,-16(a0)
 66a:	a091                	j	6ae <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 66c:	ff852703          	lw	a4,-8(a0)
 670:	9e39                	addw	a2,a2,a4
 672:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 674:	ff053703          	ld	a4,-16(a0)
 678:	e398                	sd	a4,0(a5)
 67a:	a099                	j	6c0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 67c:	6398                	ld	a4,0(a5)
 67e:	00e7e463          	bltu	a5,a4,686 <free+0x40>
 682:	00e6ea63          	bltu	a3,a4,696 <free+0x50>
{
 686:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 688:	fed7fae3          	bgeu	a5,a3,67c <free+0x36>
 68c:	6398                	ld	a4,0(a5)
 68e:	00e6e463          	bltu	a3,a4,696 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 692:	fee7eae3          	bltu	a5,a4,686 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 696:	ff852583          	lw	a1,-8(a0)
 69a:	6390                	ld	a2,0(a5)
 69c:	02059713          	slli	a4,a1,0x20
 6a0:	9301                	srli	a4,a4,0x20
 6a2:	0712                	slli	a4,a4,0x4
 6a4:	9736                	add	a4,a4,a3
 6a6:	fae60ae3          	beq	a2,a4,65a <free+0x14>
    bp->s.ptr = p->s.ptr;
 6aa:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6ae:	4790                	lw	a2,8(a5)
 6b0:	02061713          	slli	a4,a2,0x20
 6b4:	9301                	srli	a4,a4,0x20
 6b6:	0712                	slli	a4,a4,0x4
 6b8:	973e                	add	a4,a4,a5
 6ba:	fae689e3          	beq	a3,a4,66c <free+0x26>
  } else
    p->s.ptr = bp;
 6be:	e394                	sd	a3,0(a5)
  freep = p;
 6c0:	00000717          	auipc	a4,0x0
 6c4:	10f73c23          	sd	a5,280(a4) # 7d8 <freep>
}
 6c8:	6422                	ld	s0,8(sp)
 6ca:	0141                	addi	sp,sp,16
 6cc:	8082                	ret

00000000000006ce <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6ce:	7139                	addi	sp,sp,-64
 6d0:	fc06                	sd	ra,56(sp)
 6d2:	f822                	sd	s0,48(sp)
 6d4:	f426                	sd	s1,40(sp)
 6d6:	f04a                	sd	s2,32(sp)
 6d8:	ec4e                	sd	s3,24(sp)
 6da:	e852                	sd	s4,16(sp)
 6dc:	e456                	sd	s5,8(sp)
 6de:	e05a                	sd	s6,0(sp)
 6e0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6e2:	02051493          	slli	s1,a0,0x20
 6e6:	9081                	srli	s1,s1,0x20
 6e8:	04bd                	addi	s1,s1,15
 6ea:	8091                	srli	s1,s1,0x4
 6ec:	0014899b          	addiw	s3,s1,1
 6f0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6f2:	00000517          	auipc	a0,0x0
 6f6:	0e653503          	ld	a0,230(a0) # 7d8 <freep>
 6fa:	c515                	beqz	a0,726 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6fc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 6fe:	4798                	lw	a4,8(a5)
 700:	02977f63          	bgeu	a4,s1,73e <malloc+0x70>
 704:	8a4e                	mv	s4,s3
 706:	0009871b          	sext.w	a4,s3
 70a:	6685                	lui	a3,0x1
 70c:	00d77363          	bgeu	a4,a3,712 <malloc+0x44>
 710:	6a05                	lui	s4,0x1
 712:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 716:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 71a:	00000917          	auipc	s2,0x0
 71e:	0be90913          	addi	s2,s2,190 # 7d8 <freep>
  if(p == (char*)-1)
 722:	5afd                	li	s5,-1
 724:	a88d                	j	796 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 726:	00000797          	auipc	a5,0x0
 72a:	0ba78793          	addi	a5,a5,186 # 7e0 <base>
 72e:	00000717          	auipc	a4,0x0
 732:	0af73523          	sd	a5,170(a4) # 7d8 <freep>
 736:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 738:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 73c:	b7e1                	j	704 <malloc+0x36>
      if(p->s.size == nunits)
 73e:	02e48b63          	beq	s1,a4,774 <malloc+0xa6>
        p->s.size -= nunits;
 742:	4137073b          	subw	a4,a4,s3
 746:	c798                	sw	a4,8(a5)
        p += p->s.size;
 748:	1702                	slli	a4,a4,0x20
 74a:	9301                	srli	a4,a4,0x20
 74c:	0712                	slli	a4,a4,0x4
 74e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 750:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 754:	00000717          	auipc	a4,0x0
 758:	08a73223          	sd	a0,132(a4) # 7d8 <freep>
      return (void*)(p + 1);
 75c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 760:	70e2                	ld	ra,56(sp)
 762:	7442                	ld	s0,48(sp)
 764:	74a2                	ld	s1,40(sp)
 766:	7902                	ld	s2,32(sp)
 768:	69e2                	ld	s3,24(sp)
 76a:	6a42                	ld	s4,16(sp)
 76c:	6aa2                	ld	s5,8(sp)
 76e:	6b02                	ld	s6,0(sp)
 770:	6121                	addi	sp,sp,64
 772:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 774:	6398                	ld	a4,0(a5)
 776:	e118                	sd	a4,0(a0)
 778:	bff1                	j	754 <malloc+0x86>
  hp->s.size = nu;
 77a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 77e:	0541                	addi	a0,a0,16
 780:	00000097          	auipc	ra,0x0
 784:	ec6080e7          	jalr	-314(ra) # 646 <free>
  return freep;
 788:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 78c:	d971                	beqz	a0,760 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 78e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 790:	4798                	lw	a4,8(a5)
 792:	fa9776e3          	bgeu	a4,s1,73e <malloc+0x70>
    if(p == freep)
 796:	00093703          	ld	a4,0(s2)
 79a:	853e                	mv	a0,a5
 79c:	fef719e3          	bne	a4,a5,78e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7a0:	8552                	mv	a0,s4
 7a2:	00000097          	auipc	ra,0x0
 7a6:	b6e080e7          	jalr	-1170(ra) # 310 <sbrk>
  if(p == (char*)-1)
 7aa:	fd5518e3          	bne	a0,s5,77a <malloc+0xac>
        return 0;
 7ae:	4501                	li	a0,0
 7b0:	bf45                	j	760 <malloc+0x92>
