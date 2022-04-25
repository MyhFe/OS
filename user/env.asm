
user/_env:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test>:
#include "kernel/memlayout.h"
#include "kernel/riscv.h"



void test(int num_of_copies, int num_of_intervals, char* test_name, char* num_of_tmpfile){
   0:	7119                	addi	sp,sp,-128
   2:	fc86                	sd	ra,120(sp)
   4:	f8a2                	sd	s0,112(sp)
   6:	f4a6                	sd	s1,104(sp)
   8:	f0ca                	sd	s2,96(sp)
   a:	ecce                	sd	s3,88(sp)
   c:	e8d2                	sd	s4,80(sp)
   e:	e4d6                	sd	s5,72(sp)
  10:	e0da                	sd	s6,64(sp)
  12:	fc5e                	sd	s7,56(sp)
  14:	f862                	sd	s8,48(sp)
  16:	f466                	sd	s9,40(sp)
  18:	f06a                	sd	s10,32(sp)
  1a:	ec6e                	sd	s11,24(sp)
  1c:	0100                	addi	s0,sp,128
  1e:	8d2a                	mv	s10,a0
  20:	f8c43423          	sd	a2,-120(s0)
  24:	f8d43023          	sd	a3,-128(s0)
    char* str = "Hello, my name is Steve Gonzales\nWelcome to my Test File for XV6 Schedulers\nFeel free to put notes ;)";
    int str_size = 102;

    int buff_size = str_size / num_of_intervals;
  28:	06600913          	li	s2,102
  2c:	02b9493b          	divw	s2,s2,a1
  30:	00090b1b          	sext.w	s6,s2
    char buff [buff_size];
  34:	00fb0793          	addi	a5,s6,15
  38:	9bc1                	andi	a5,a5,-16
  3a:	40f10133          	sub	sp,sp,a5
    buff[buff_size - 1] = 0;
  3e:	397d                	addiw	s2,s2,-1
  40:	012107b3          	add	a5,sp,s2
  44:	00078023          	sb	zero,0(a5)

    int fd = open(num_of_tmpfile, O_CREATE | O_RDWR);
  48:	20200593          	li	a1,514
  4c:	8536                	mv	a0,a3
  4e:	00000097          	auipc	ra,0x0
  52:	57a080e7          	jalr	1402(ra) # 5c8 <open>
  56:	8aaa                	mv	s5,a0

    for (int i = 0; i < num_of_copies; i++){
  58:	07a05b63          	blez	s10,ce <test+0xce>
  5c:	8a0a                	mv	s4,sp
  5e:	4c81                	li	s9,0
  60:	00001c17          	auipc	s8,0x1
  64:	a60c0c13          	addi	s8,s8,-1440 # ac0 <malloc+0xea>
        int str_cursor = 0;
        while(str_cursor < str_size){
            //set buffer
            for(int k = 0; k < (buff_size - 1); k++){
                if (str_cursor < str_size){
  68:	06500993          	li	s3,101
            for(int k = 0; k < (buff_size - 1); k++){
  6c:	4b85                	li	s7,1
            }
            // Write to file
            write(fd, buff, buff_size);
            //sleep(100);
        }
        printf("pid=%d - %s completed %d/%d copies.\n", getpid(), test_name, (i+1), num_of_copies);
  6e:	00001d97          	auipc	s11,0x1
  72:	abad8d93          	addi	s11,s11,-1350 # b28 <malloc+0x152>
  76:	a0c1                	j	136 <test+0x136>
                    buff[k] = 0 ;
  78:	00070023          	sb	zero,0(a4)
            for(int k = 0; k < (buff_size - 1); k++){
  7c:	0007861b          	sext.w	a2,a5
  80:	09265363          	bge	a2,s2,106 <test+0x106>
  84:	2785                	addiw	a5,a5,1
  86:	0705                	addi	a4,a4,1
  88:	0685                	addi	a3,a3,1
                if (str_cursor < str_size){
  8a:	00f5863b          	addw	a2,a1,a5
  8e:	fec9c5e3          	blt	s3,a2,78 <test+0x78>
                    buff[k] = str[str_cursor];
  92:	0006c603          	lbu	a2,0(a3)
  96:	00c70023          	sb	a2,0(a4)
                str_cursor++;
  9a:	00a784bb          	addw	s1,a5,a0
            for(int k = 0; k < (buff_size - 1); k++){
  9e:	0007861b          	sext.w	a2,a5
  a2:	ff2641e3          	blt	a2,s2,84 <test+0x84>
            write(fd, buff, buff_size);
  a6:	865a                	mv	a2,s6
  a8:	85d2                	mv	a1,s4
  aa:	8556                	mv	a0,s5
  ac:	00000097          	auipc	ra,0x0
  b0:	4fc080e7          	jalr	1276(ra) # 5a8 <write>
        while(str_cursor < str_size){
  b4:	0699c063          	blt	s3,s1,114 <test+0x114>
            for(int k = 0; k < (buff_size - 1); k++){
  b8:	ff2057e3          	blez	s2,a6 <test+0xa6>
  bc:	8752                	mv	a4,s4
  be:	018486b3          	add	a3,s1,s8
  c2:	87de                	mv	a5,s7
  c4:	0004851b          	sext.w	a0,s1
                if (str_cursor < str_size){
  c8:	fff4859b          	addiw	a1,s1,-1
  cc:	bf7d                	j	8a <test+0x8a>
    }
    close(fd);
  ce:	8556                	mv	a0,s5
  d0:	00000097          	auipc	ra,0x0
  d4:	4e0080e7          	jalr	1248(ra) # 5b0 <close>
    unlink(num_of_tmpfile);
  d8:	f8043503          	ld	a0,-128(s0)
  dc:	00000097          	auipc	ra,0x0
  e0:	4fc080e7          	jalr	1276(ra) # 5d8 <unlink>
}
  e4:	f8040113          	addi	sp,s0,-128
  e8:	70e6                	ld	ra,120(sp)
  ea:	7446                	ld	s0,112(sp)
  ec:	74a6                	ld	s1,104(sp)
  ee:	7906                	ld	s2,96(sp)
  f0:	69e6                	ld	s3,88(sp)
  f2:	6a46                	ld	s4,80(sp)
  f4:	6aa6                	ld	s5,72(sp)
  f6:	6b06                	ld	s6,64(sp)
  f8:	7be2                	ld	s7,56(sp)
  fa:	7c42                	ld	s8,48(sp)
  fc:	7ca2                	ld	s9,40(sp)
  fe:	7d02                	ld	s10,32(sp)
 100:	6de2                	ld	s11,24(sp)
 102:	6109                	addi	sp,sp,128
 104:	8082                	ret
            write(fd, buff, buff_size);
 106:	865a                	mv	a2,s6
 108:	85d2                	mv	a1,s4
 10a:	8556                	mv	a0,s5
 10c:	00000097          	auipc	ra,0x0
 110:	49c080e7          	jalr	1180(ra) # 5a8 <write>
        printf("pid=%d - %s completed %d/%d copies.\n", getpid(), test_name, (i+1), num_of_copies);
 114:	00000097          	auipc	ra,0x0
 118:	4f4080e7          	jalr	1268(ra) # 608 <getpid>
 11c:	85aa                	mv	a1,a0
 11e:	2c85                	addiw	s9,s9,1
 120:	876a                	mv	a4,s10
 122:	86e6                	mv	a3,s9
 124:	f8843603          	ld	a2,-120(s0)
 128:	856e                	mv	a0,s11
 12a:	00000097          	auipc	ra,0x0
 12e:	7ee080e7          	jalr	2030(ra) # 918 <printf>
    for (int i = 0; i < num_of_copies; i++){
 132:	f9ac8ee3          	beq	s9,s10,ce <test+0xce>
        int str_cursor = 0;
 136:	4481                	li	s1,0
 138:	b741                	j	b8 <test+0xb8>

000000000000013a <run_test>:
void run_test(int n_forks) {
 13a:	711d                	addi	sp,sp,-96
 13c:	ec86                	sd	ra,88(sp)
 13e:	e8a2                	sd	s0,80(sp)
 140:	e4a6                	sd	s1,72(sp)
 142:	e0ca                	sd	s2,64(sp)
 144:	fc4e                	sd	s3,56(sp)
 146:	f852                	sd	s4,48(sp)
 148:	f456                	sd	s5,40(sp)
 14a:	1080                	addi	s0,sp,96
    int pid; 
    int child_pid [n_forks];
 14c:	00251793          	slli	a5,a0,0x2
 150:	07bd                	addi	a5,a5,15
 152:	9bc1                	andi	a5,a5,-16
 154:	40f10133          	sub	sp,sp,a5
    for (int i = 0; i < n_forks; i++){
 158:	0ea05863          	blez	a0,248 <run_test+0x10e>
 15c:	8aaa                	mv	s5,a0
 15e:	8a0a                	mv	s4,sp
 160:	89d2                	mv	s3,s4
 162:	84d2                	mv	s1,s4
 164:	4901                	li	s2,0
 166:	a011                	j	16a <run_test+0x30>
 168:	893e                	mv	s2,a5
        pid = fork();
 16a:	00000097          	auipc	ra,0x0
 16e:	416080e7          	jalr	1046(ra) # 580 <fork>
        if (pid != 0){
 172:	cd51                	beqz	a0,20e <run_test+0xd4>
            child_pid[i] = pid;
 174:	c088                	sw	a0,0(s1)
    for (int i = 0; i < n_forks; i++){
 176:	0019079b          	addiw	a5,s2,1
 17a:	0491                	addi	s1,s1,4
 17c:	fefa96e3          	bne	s5,a5,168 <run_test+0x2e>
 180:	4481                	li	s1,0
        }
    }
    // Wait for all child processes before exiting test
    for (int i = 0; i < n_forks; i++){
        int status;
        wait(&status);
 182:	fa840513          	addi	a0,s0,-88
 186:	00000097          	auipc	ra,0x0
 18a:	40a080e7          	jalr	1034(ra) # 590 <wait>
    for (int i = 0; i < n_forks; i++){
 18e:	87a6                	mv	a5,s1
 190:	2485                	addiw	s1,s1,1
 192:	ff2798e3          	bne	a5,s2,182 <run_test+0x48>
    }
    printf("Father process pid = %d\n", getpid());
 196:	00000097          	auipc	ra,0x0
 19a:	472080e7          	jalr	1138(ra) # 608 <getpid>
 19e:	85aa                	mv	a1,a0
 1a0:	00001517          	auipc	a0,0x1
 1a4:	9c850513          	addi	a0,a0,-1592 # b68 <malloc+0x192>
 1a8:	00000097          	auipc	ra,0x0
 1ac:	770080e7          	jalr	1904(ra) # 918 <printf>
    printf("Children processes pid:");
 1b0:	00001517          	auipc	a0,0x1
 1b4:	9d850513          	addi	a0,a0,-1576 # b88 <malloc+0x1b2>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	760080e7          	jalr	1888(ra) # 918 <printf>
     for (int i = 0; i < n_forks; i++){
 1c0:	02091793          	slli	a5,s2,0x20
 1c4:	9381                	srli	a5,a5,0x20
 1c6:	0785                	addi	a5,a5,1
 1c8:	078a                	slli	a5,a5,0x2
 1ca:	9a3e                	add	s4,s4,a5
        printf("%d ", child_pid[i]);
 1cc:	00001497          	auipc	s1,0x1
 1d0:	98c48493          	addi	s1,s1,-1652 # b58 <malloc+0x182>
 1d4:	0009a583          	lw	a1,0(s3)
 1d8:	8526                	mv	a0,s1
 1da:	00000097          	auipc	ra,0x0
 1de:	73e080e7          	jalr	1854(ra) # 918 <printf>
     for (int i = 0; i < n_forks; i++){
 1e2:	0991                	addi	s3,s3,4
 1e4:	ff3a18e3          	bne	s4,s3,1d4 <run_test+0x9a>
    }
    printf("\n");
 1e8:	00001517          	auipc	a0,0x1
 1ec:	97850513          	addi	a0,a0,-1672 # b60 <malloc+0x18a>
 1f0:	00000097          	auipc	ra,0x0
 1f4:	728080e7          	jalr	1832(ra) # 918 <printf>
}
 1f8:	fa040113          	addi	sp,s0,-96
 1fc:	60e6                	ld	ra,88(sp)
 1fe:	6446                	ld	s0,80(sp)
 200:	64a6                	ld	s1,72(sp)
 202:	6906                	ld	s2,64(sp)
 204:	79e2                	ld	s3,56(sp)
 206:	7a42                	ld	s4,48(sp)
 208:	7aa2                	ld	s5,40(sp)
 20a:	6125                	addi	sp,sp,96
 20c:	8082                	ret
            num_of_tmpfile[0] = i - '0';
 20e:	fd09091b          	addiw	s2,s2,-48
 212:	fb240023          	sb	s2,-96(s0)
            num_of_tmpfile[1] = 0;
 216:	fa0400a3          	sb	zero,-95(s0)
            char* argv[] = {"env", num_of_tmpfile, 0};
 21a:	00001517          	auipc	a0,0x1
 21e:	93650513          	addi	a0,a0,-1738 # b50 <malloc+0x17a>
 222:	faa43423          	sd	a0,-88(s0)
 226:	fa040793          	addi	a5,s0,-96
 22a:	faf43823          	sd	a5,-80(s0)
 22e:	fa043c23          	sd	zero,-72(s0)
            exec(argv[0], argv);
 232:	fa840593          	addi	a1,s0,-88
 236:	00000097          	auipc	ra,0x0
 23a:	38a080e7          	jalr	906(ra) # 5c0 <exec>
            exit(0);
 23e:	4501                	li	a0,0
 240:	00000097          	auipc	ra,0x0
 244:	348080e7          	jalr	840(ra) # 588 <exit>
    printf("Father process pid = %d\n", getpid());
 248:	00000097          	auipc	ra,0x0
 24c:	3c0080e7          	jalr	960(ra) # 608 <getpid>
 250:	85aa                	mv	a1,a0
 252:	00001517          	auipc	a0,0x1
 256:	91650513          	addi	a0,a0,-1770 # b68 <malloc+0x192>
 25a:	00000097          	auipc	ra,0x0
 25e:	6be080e7          	jalr	1726(ra) # 918 <printf>
    printf("Children processes pid:");
 262:	00001517          	auipc	a0,0x1
 266:	92650513          	addi	a0,a0,-1754 # b88 <malloc+0x1b2>
 26a:	00000097          	auipc	ra,0x0
 26e:	6ae080e7          	jalr	1710(ra) # 918 <printf>
     for (int i = 0; i < n_forks; i++){
 272:	bf9d                	j	1e8 <run_test+0xae>

0000000000000274 <short_test>:

void short_test(char* num_of_tmpfile) {
 274:	1141                	addi	sp,sp,-16
 276:	e406                	sd	ra,8(sp)
 278:	e022                	sd	s0,0(sp)
 27a:	0800                	addi	s0,sp,16
 27c:	86aa                	mv	a3,a0
    test(10, 10, "short_test", num_of_tmpfile);
 27e:	00001617          	auipc	a2,0x1
 282:	92260613          	addi	a2,a2,-1758 # ba0 <malloc+0x1ca>
 286:	45a9                	li	a1,10
 288:	4529                	li	a0,10
 28a:	00000097          	auipc	ra,0x0
 28e:	d76080e7          	jalr	-650(ra) # 0 <test>
}
 292:	60a2                	ld	ra,8(sp)
 294:	6402                	ld	s0,0(sp)
 296:	0141                	addi	sp,sp,16
 298:	8082                	ret

000000000000029a <long_test>:

void long_test(char* num_of_tmpfile) {
 29a:	1141                	addi	sp,sp,-16
 29c:	e406                	sd	ra,8(sp)
 29e:	e022                	sd	s0,0(sp)
 2a0:	0800                	addi	s0,sp,16
 2a2:	86aa                	mv	a3,a0
    test(100, 100, "long_test", num_of_tmpfile);
 2a4:	00001617          	auipc	a2,0x1
 2a8:	90c60613          	addi	a2,a2,-1780 # bb0 <malloc+0x1da>
 2ac:	06400593          	li	a1,100
 2b0:	06400513          	li	a0,100
 2b4:	00000097          	auipc	ra,0x0
 2b8:	d4c080e7          	jalr	-692(ra) # 0 <test>
}
 2bc:	60a2                	ld	ra,8(sp)
 2be:	6402                	ld	s0,0(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret

00000000000002c4 <main>:

int main (int argc, char *argv []){
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e406                	sd	ra,8(sp)
 2c8:	e022                	sd	s0,0(sp)
 2ca:	0800                	addi	s0,sp,16
    int n_forks = 5;
    if(argc == 1){
 2cc:	4785                	li	a5,1
 2ce:	02f50263          	beq	a0,a5,2f2 <main+0x2e>
        run_test(n_forks);
        print_stats();
    }
    else if(argc == 2){
 2d2:	4789                	li	a5,2
 2d4:	02f50963          	beq	a0,a5,306 <main+0x42>
       short_test(argv[1]);
    }
    else{
        printf("Error - wrong input - no more then 2 arguments are allowed");
 2d8:	00001517          	auipc	a0,0x1
 2dc:	8e850513          	addi	a0,a0,-1816 # bc0 <malloc+0x1ea>
 2e0:	00000097          	auipc	ra,0x0
 2e4:	638080e7          	jalr	1592(ra) # 918 <printf>
    }
    exit(0);
 2e8:	4501                	li	a0,0
 2ea:	00000097          	auipc	ra,0x0
 2ee:	29e080e7          	jalr	670(ra) # 588 <exit>
        run_test(n_forks);
 2f2:	4515                	li	a0,5
 2f4:	00000097          	auipc	ra,0x0
 2f8:	e46080e7          	jalr	-442(ra) # 13a <run_test>
        print_stats();
 2fc:	00000097          	auipc	ra,0x0
 300:	33c080e7          	jalr	828(ra) # 638 <print_stats>
 304:	b7d5                	j	2e8 <main+0x24>
       short_test(argv[1]);
 306:	6588                	ld	a0,8(a1)
 308:	00000097          	auipc	ra,0x0
 30c:	f6c080e7          	jalr	-148(ra) # 274 <short_test>
 310:	bfe1                	j	2e8 <main+0x24>

0000000000000312 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 312:	1141                	addi	sp,sp,-16
 314:	e422                	sd	s0,8(sp)
 316:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 318:	87aa                	mv	a5,a0
 31a:	0585                	addi	a1,a1,1
 31c:	0785                	addi	a5,a5,1
 31e:	fff5c703          	lbu	a4,-1(a1)
 322:	fee78fa3          	sb	a4,-1(a5)
 326:	fb75                	bnez	a4,31a <strcpy+0x8>
    ;
  return os;
}
 328:	6422                	ld	s0,8(sp)
 32a:	0141                	addi	sp,sp,16
 32c:	8082                	ret

000000000000032e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 32e:	1141                	addi	sp,sp,-16
 330:	e422                	sd	s0,8(sp)
 332:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 334:	00054783          	lbu	a5,0(a0)
 338:	cb91                	beqz	a5,34c <strcmp+0x1e>
 33a:	0005c703          	lbu	a4,0(a1)
 33e:	00f71763          	bne	a4,a5,34c <strcmp+0x1e>
    p++, q++;
 342:	0505                	addi	a0,a0,1
 344:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 346:	00054783          	lbu	a5,0(a0)
 34a:	fbe5                	bnez	a5,33a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 34c:	0005c503          	lbu	a0,0(a1)
}
 350:	40a7853b          	subw	a0,a5,a0
 354:	6422                	ld	s0,8(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret

000000000000035a <strlen>:

uint
strlen(const char *s)
{
 35a:	1141                	addi	sp,sp,-16
 35c:	e422                	sd	s0,8(sp)
 35e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 360:	00054783          	lbu	a5,0(a0)
 364:	cf91                	beqz	a5,380 <strlen+0x26>
 366:	0505                	addi	a0,a0,1
 368:	87aa                	mv	a5,a0
 36a:	4685                	li	a3,1
 36c:	9e89                	subw	a3,a3,a0
 36e:	00f6853b          	addw	a0,a3,a5
 372:	0785                	addi	a5,a5,1
 374:	fff7c703          	lbu	a4,-1(a5)
 378:	fb7d                	bnez	a4,36e <strlen+0x14>
    ;
  return n;
}
 37a:	6422                	ld	s0,8(sp)
 37c:	0141                	addi	sp,sp,16
 37e:	8082                	ret
  for(n = 0; s[n]; n++)
 380:	4501                	li	a0,0
 382:	bfe5                	j	37a <strlen+0x20>

0000000000000384 <memset>:

void*
memset(void *dst, int c, uint n)
{
 384:	1141                	addi	sp,sp,-16
 386:	e422                	sd	s0,8(sp)
 388:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 38a:	ce09                	beqz	a2,3a4 <memset+0x20>
 38c:	87aa                	mv	a5,a0
 38e:	fff6071b          	addiw	a4,a2,-1
 392:	1702                	slli	a4,a4,0x20
 394:	9301                	srli	a4,a4,0x20
 396:	0705                	addi	a4,a4,1
 398:	972a                	add	a4,a4,a0
    cdst[i] = c;
 39a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 39e:	0785                	addi	a5,a5,1
 3a0:	fee79de3          	bne	a5,a4,39a <memset+0x16>
  }
  return dst;
}
 3a4:	6422                	ld	s0,8(sp)
 3a6:	0141                	addi	sp,sp,16
 3a8:	8082                	ret

00000000000003aa <strchr>:

char*
strchr(const char *s, char c)
{
 3aa:	1141                	addi	sp,sp,-16
 3ac:	e422                	sd	s0,8(sp)
 3ae:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3b0:	00054783          	lbu	a5,0(a0)
 3b4:	cb99                	beqz	a5,3ca <strchr+0x20>
    if(*s == c)
 3b6:	00f58763          	beq	a1,a5,3c4 <strchr+0x1a>
  for(; *s; s++)
 3ba:	0505                	addi	a0,a0,1
 3bc:	00054783          	lbu	a5,0(a0)
 3c0:	fbfd                	bnez	a5,3b6 <strchr+0xc>
      return (char*)s;
  return 0;
 3c2:	4501                	li	a0,0
}
 3c4:	6422                	ld	s0,8(sp)
 3c6:	0141                	addi	sp,sp,16
 3c8:	8082                	ret
  return 0;
 3ca:	4501                	li	a0,0
 3cc:	bfe5                	j	3c4 <strchr+0x1a>

00000000000003ce <gets>:

char*
gets(char *buf, int max)
{
 3ce:	711d                	addi	sp,sp,-96
 3d0:	ec86                	sd	ra,88(sp)
 3d2:	e8a2                	sd	s0,80(sp)
 3d4:	e4a6                	sd	s1,72(sp)
 3d6:	e0ca                	sd	s2,64(sp)
 3d8:	fc4e                	sd	s3,56(sp)
 3da:	f852                	sd	s4,48(sp)
 3dc:	f456                	sd	s5,40(sp)
 3de:	f05a                	sd	s6,32(sp)
 3e0:	ec5e                	sd	s7,24(sp)
 3e2:	1080                	addi	s0,sp,96
 3e4:	8baa                	mv	s7,a0
 3e6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3e8:	892a                	mv	s2,a0
 3ea:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3ec:	4aa9                	li	s5,10
 3ee:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3f0:	89a6                	mv	s3,s1
 3f2:	2485                	addiw	s1,s1,1
 3f4:	0344d863          	bge	s1,s4,424 <gets+0x56>
    cc = read(0, &c, 1);
 3f8:	4605                	li	a2,1
 3fa:	faf40593          	addi	a1,s0,-81
 3fe:	4501                	li	a0,0
 400:	00000097          	auipc	ra,0x0
 404:	1a0080e7          	jalr	416(ra) # 5a0 <read>
    if(cc < 1)
 408:	00a05e63          	blez	a0,424 <gets+0x56>
    buf[i++] = c;
 40c:	faf44783          	lbu	a5,-81(s0)
 410:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 414:	01578763          	beq	a5,s5,422 <gets+0x54>
 418:	0905                	addi	s2,s2,1
 41a:	fd679be3          	bne	a5,s6,3f0 <gets+0x22>
  for(i=0; i+1 < max; ){
 41e:	89a6                	mv	s3,s1
 420:	a011                	j	424 <gets+0x56>
 422:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 424:	99de                	add	s3,s3,s7
 426:	00098023          	sb	zero,0(s3)
  return buf;
}
 42a:	855e                	mv	a0,s7
 42c:	60e6                	ld	ra,88(sp)
 42e:	6446                	ld	s0,80(sp)
 430:	64a6                	ld	s1,72(sp)
 432:	6906                	ld	s2,64(sp)
 434:	79e2                	ld	s3,56(sp)
 436:	7a42                	ld	s4,48(sp)
 438:	7aa2                	ld	s5,40(sp)
 43a:	7b02                	ld	s6,32(sp)
 43c:	6be2                	ld	s7,24(sp)
 43e:	6125                	addi	sp,sp,96
 440:	8082                	ret

0000000000000442 <stat>:

int
stat(const char *n, struct stat *st)
{
 442:	1101                	addi	sp,sp,-32
 444:	ec06                	sd	ra,24(sp)
 446:	e822                	sd	s0,16(sp)
 448:	e426                	sd	s1,8(sp)
 44a:	e04a                	sd	s2,0(sp)
 44c:	1000                	addi	s0,sp,32
 44e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 450:	4581                	li	a1,0
 452:	00000097          	auipc	ra,0x0
 456:	176080e7          	jalr	374(ra) # 5c8 <open>
  if(fd < 0)
 45a:	02054563          	bltz	a0,484 <stat+0x42>
 45e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 460:	85ca                	mv	a1,s2
 462:	00000097          	auipc	ra,0x0
 466:	17e080e7          	jalr	382(ra) # 5e0 <fstat>
 46a:	892a                	mv	s2,a0
  close(fd);
 46c:	8526                	mv	a0,s1
 46e:	00000097          	auipc	ra,0x0
 472:	142080e7          	jalr	322(ra) # 5b0 <close>
  return r;
}
 476:	854a                	mv	a0,s2
 478:	60e2                	ld	ra,24(sp)
 47a:	6442                	ld	s0,16(sp)
 47c:	64a2                	ld	s1,8(sp)
 47e:	6902                	ld	s2,0(sp)
 480:	6105                	addi	sp,sp,32
 482:	8082                	ret
    return -1;
 484:	597d                	li	s2,-1
 486:	bfc5                	j	476 <stat+0x34>

0000000000000488 <atoi>:

int
atoi(const char *s)
{
 488:	1141                	addi	sp,sp,-16
 48a:	e422                	sd	s0,8(sp)
 48c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 48e:	00054603          	lbu	a2,0(a0)
 492:	fd06079b          	addiw	a5,a2,-48
 496:	0ff7f793          	andi	a5,a5,255
 49a:	4725                	li	a4,9
 49c:	02f76963          	bltu	a4,a5,4ce <atoi+0x46>
 4a0:	86aa                	mv	a3,a0
  n = 0;
 4a2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4a4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4a6:	0685                	addi	a3,a3,1
 4a8:	0025179b          	slliw	a5,a0,0x2
 4ac:	9fa9                	addw	a5,a5,a0
 4ae:	0017979b          	slliw	a5,a5,0x1
 4b2:	9fb1                	addw	a5,a5,a2
 4b4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4b8:	0006c603          	lbu	a2,0(a3)
 4bc:	fd06071b          	addiw	a4,a2,-48
 4c0:	0ff77713          	andi	a4,a4,255
 4c4:	fee5f1e3          	bgeu	a1,a4,4a6 <atoi+0x1e>
  return n;
}
 4c8:	6422                	ld	s0,8(sp)
 4ca:	0141                	addi	sp,sp,16
 4cc:	8082                	ret
  n = 0;
 4ce:	4501                	li	a0,0
 4d0:	bfe5                	j	4c8 <atoi+0x40>

00000000000004d2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4d2:	1141                	addi	sp,sp,-16
 4d4:	e422                	sd	s0,8(sp)
 4d6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4d8:	02b57663          	bgeu	a0,a1,504 <memmove+0x32>
    while(n-- > 0)
 4dc:	02c05163          	blez	a2,4fe <memmove+0x2c>
 4e0:	fff6079b          	addiw	a5,a2,-1
 4e4:	1782                	slli	a5,a5,0x20
 4e6:	9381                	srli	a5,a5,0x20
 4e8:	0785                	addi	a5,a5,1
 4ea:	97aa                	add	a5,a5,a0
  dst = vdst;
 4ec:	872a                	mv	a4,a0
      *dst++ = *src++;
 4ee:	0585                	addi	a1,a1,1
 4f0:	0705                	addi	a4,a4,1
 4f2:	fff5c683          	lbu	a3,-1(a1)
 4f6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4fa:	fee79ae3          	bne	a5,a4,4ee <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4fe:	6422                	ld	s0,8(sp)
 500:	0141                	addi	sp,sp,16
 502:	8082                	ret
    dst += n;
 504:	00c50733          	add	a4,a0,a2
    src += n;
 508:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 50a:	fec05ae3          	blez	a2,4fe <memmove+0x2c>
 50e:	fff6079b          	addiw	a5,a2,-1
 512:	1782                	slli	a5,a5,0x20
 514:	9381                	srli	a5,a5,0x20
 516:	fff7c793          	not	a5,a5
 51a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 51c:	15fd                	addi	a1,a1,-1
 51e:	177d                	addi	a4,a4,-1
 520:	0005c683          	lbu	a3,0(a1)
 524:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 528:	fee79ae3          	bne	a5,a4,51c <memmove+0x4a>
 52c:	bfc9                	j	4fe <memmove+0x2c>

000000000000052e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 52e:	1141                	addi	sp,sp,-16
 530:	e422                	sd	s0,8(sp)
 532:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 534:	ca05                	beqz	a2,564 <memcmp+0x36>
 536:	fff6069b          	addiw	a3,a2,-1
 53a:	1682                	slli	a3,a3,0x20
 53c:	9281                	srli	a3,a3,0x20
 53e:	0685                	addi	a3,a3,1
 540:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 542:	00054783          	lbu	a5,0(a0)
 546:	0005c703          	lbu	a4,0(a1)
 54a:	00e79863          	bne	a5,a4,55a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 54e:	0505                	addi	a0,a0,1
    p2++;
 550:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 552:	fed518e3          	bne	a0,a3,542 <memcmp+0x14>
  }
  return 0;
 556:	4501                	li	a0,0
 558:	a019                	j	55e <memcmp+0x30>
      return *p1 - *p2;
 55a:	40e7853b          	subw	a0,a5,a4
}
 55e:	6422                	ld	s0,8(sp)
 560:	0141                	addi	sp,sp,16
 562:	8082                	ret
  return 0;
 564:	4501                	li	a0,0
 566:	bfe5                	j	55e <memcmp+0x30>

0000000000000568 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 568:	1141                	addi	sp,sp,-16
 56a:	e406                	sd	ra,8(sp)
 56c:	e022                	sd	s0,0(sp)
 56e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 570:	00000097          	auipc	ra,0x0
 574:	f62080e7          	jalr	-158(ra) # 4d2 <memmove>
}
 578:	60a2                	ld	ra,8(sp)
 57a:	6402                	ld	s0,0(sp)
 57c:	0141                	addi	sp,sp,16
 57e:	8082                	ret

0000000000000580 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 580:	4885                	li	a7,1
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <exit>:
.global exit
exit:
 li a7, SYS_exit
 588:	4889                	li	a7,2
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <wait>:
.global wait
wait:
 li a7, SYS_wait
 590:	488d                	li	a7,3
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 598:	4891                	li	a7,4
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <read>:
.global read
read:
 li a7, SYS_read
 5a0:	4895                	li	a7,5
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <write>:
.global write
write:
 li a7, SYS_write
 5a8:	48c1                	li	a7,16
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <close>:
.global close
close:
 li a7, SYS_close
 5b0:	48d5                	li	a7,21
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5b8:	4899                	li	a7,6
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5c0:	489d                	li	a7,7
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <open>:
.global open
open:
 li a7, SYS_open
 5c8:	48bd                	li	a7,15
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5d0:	48c5                	li	a7,17
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5d8:	48c9                	li	a7,18
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5e0:	48a1                	li	a7,8
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <link>:
.global link
link:
 li a7, SYS_link
 5e8:	48cd                	li	a7,19
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5f0:	48d1                	li	a7,20
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5f8:	48a5                	li	a7,9
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <dup>:
.global dup
dup:
 li a7, SYS_dup
 600:	48a9                	li	a7,10
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 608:	48ad                	li	a7,11
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 610:	48b1                	li	a7,12
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 618:	48b5                	li	a7,13
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 620:	48b9                	li	a7,14
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 628:	48d9                	li	a7,22
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 630:	48dd                	li	a7,23
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 638:	48e1                	li	a7,24
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 640:	1101                	addi	sp,sp,-32
 642:	ec06                	sd	ra,24(sp)
 644:	e822                	sd	s0,16(sp)
 646:	1000                	addi	s0,sp,32
 648:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 64c:	4605                	li	a2,1
 64e:	fef40593          	addi	a1,s0,-17
 652:	00000097          	auipc	ra,0x0
 656:	f56080e7          	jalr	-170(ra) # 5a8 <write>
}
 65a:	60e2                	ld	ra,24(sp)
 65c:	6442                	ld	s0,16(sp)
 65e:	6105                	addi	sp,sp,32
 660:	8082                	ret

0000000000000662 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 662:	7139                	addi	sp,sp,-64
 664:	fc06                	sd	ra,56(sp)
 666:	f822                	sd	s0,48(sp)
 668:	f426                	sd	s1,40(sp)
 66a:	f04a                	sd	s2,32(sp)
 66c:	ec4e                	sd	s3,24(sp)
 66e:	0080                	addi	s0,sp,64
 670:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 672:	c299                	beqz	a3,678 <printint+0x16>
 674:	0805c863          	bltz	a1,704 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 678:	2581                	sext.w	a1,a1
  neg = 0;
 67a:	4881                	li	a7,0
 67c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 680:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 682:	2601                	sext.w	a2,a2
 684:	00000517          	auipc	a0,0x0
 688:	58450513          	addi	a0,a0,1412 # c08 <digits>
 68c:	883a                	mv	a6,a4
 68e:	2705                	addiw	a4,a4,1
 690:	02c5f7bb          	remuw	a5,a1,a2
 694:	1782                	slli	a5,a5,0x20
 696:	9381                	srli	a5,a5,0x20
 698:	97aa                	add	a5,a5,a0
 69a:	0007c783          	lbu	a5,0(a5)
 69e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6a2:	0005879b          	sext.w	a5,a1
 6a6:	02c5d5bb          	divuw	a1,a1,a2
 6aa:	0685                	addi	a3,a3,1
 6ac:	fec7f0e3          	bgeu	a5,a2,68c <printint+0x2a>
  if(neg)
 6b0:	00088b63          	beqz	a7,6c6 <printint+0x64>
    buf[i++] = '-';
 6b4:	fd040793          	addi	a5,s0,-48
 6b8:	973e                	add	a4,a4,a5
 6ba:	02d00793          	li	a5,45
 6be:	fef70823          	sb	a5,-16(a4)
 6c2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6c6:	02e05863          	blez	a4,6f6 <printint+0x94>
 6ca:	fc040793          	addi	a5,s0,-64
 6ce:	00e78933          	add	s2,a5,a4
 6d2:	fff78993          	addi	s3,a5,-1
 6d6:	99ba                	add	s3,s3,a4
 6d8:	377d                	addiw	a4,a4,-1
 6da:	1702                	slli	a4,a4,0x20
 6dc:	9301                	srli	a4,a4,0x20
 6de:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6e2:	fff94583          	lbu	a1,-1(s2)
 6e6:	8526                	mv	a0,s1
 6e8:	00000097          	auipc	ra,0x0
 6ec:	f58080e7          	jalr	-168(ra) # 640 <putc>
  while(--i >= 0)
 6f0:	197d                	addi	s2,s2,-1
 6f2:	ff3918e3          	bne	s2,s3,6e2 <printint+0x80>
}
 6f6:	70e2                	ld	ra,56(sp)
 6f8:	7442                	ld	s0,48(sp)
 6fa:	74a2                	ld	s1,40(sp)
 6fc:	7902                	ld	s2,32(sp)
 6fe:	69e2                	ld	s3,24(sp)
 700:	6121                	addi	sp,sp,64
 702:	8082                	ret
    x = -xx;
 704:	40b005bb          	negw	a1,a1
    neg = 1;
 708:	4885                	li	a7,1
    x = -xx;
 70a:	bf8d                	j	67c <printint+0x1a>

000000000000070c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 70c:	7119                	addi	sp,sp,-128
 70e:	fc86                	sd	ra,120(sp)
 710:	f8a2                	sd	s0,112(sp)
 712:	f4a6                	sd	s1,104(sp)
 714:	f0ca                	sd	s2,96(sp)
 716:	ecce                	sd	s3,88(sp)
 718:	e8d2                	sd	s4,80(sp)
 71a:	e4d6                	sd	s5,72(sp)
 71c:	e0da                	sd	s6,64(sp)
 71e:	fc5e                	sd	s7,56(sp)
 720:	f862                	sd	s8,48(sp)
 722:	f466                	sd	s9,40(sp)
 724:	f06a                	sd	s10,32(sp)
 726:	ec6e                	sd	s11,24(sp)
 728:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 72a:	0005c903          	lbu	s2,0(a1)
 72e:	18090f63          	beqz	s2,8cc <vprintf+0x1c0>
 732:	8aaa                	mv	s5,a0
 734:	8b32                	mv	s6,a2
 736:	00158493          	addi	s1,a1,1
  state = 0;
 73a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 73c:	02500a13          	li	s4,37
      if(c == 'd'){
 740:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 744:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 748:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 74c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 750:	00000b97          	auipc	s7,0x0
 754:	4b8b8b93          	addi	s7,s7,1208 # c08 <digits>
 758:	a839                	j	776 <vprintf+0x6a>
        putc(fd, c);
 75a:	85ca                	mv	a1,s2
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	ee2080e7          	jalr	-286(ra) # 640 <putc>
 766:	a019                	j	76c <vprintf+0x60>
    } else if(state == '%'){
 768:	01498f63          	beq	s3,s4,786 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 76c:	0485                	addi	s1,s1,1
 76e:	fff4c903          	lbu	s2,-1(s1)
 772:	14090d63          	beqz	s2,8cc <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 776:	0009079b          	sext.w	a5,s2
    if(state == 0){
 77a:	fe0997e3          	bnez	s3,768 <vprintf+0x5c>
      if(c == '%'){
 77e:	fd479ee3          	bne	a5,s4,75a <vprintf+0x4e>
        state = '%';
 782:	89be                	mv	s3,a5
 784:	b7e5                	j	76c <vprintf+0x60>
      if(c == 'd'){
 786:	05878063          	beq	a5,s8,7c6 <vprintf+0xba>
      } else if(c == 'l') {
 78a:	05978c63          	beq	a5,s9,7e2 <vprintf+0xd6>
      } else if(c == 'x') {
 78e:	07a78863          	beq	a5,s10,7fe <vprintf+0xf2>
      } else if(c == 'p') {
 792:	09b78463          	beq	a5,s11,81a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 796:	07300713          	li	a4,115
 79a:	0ce78663          	beq	a5,a4,866 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 79e:	06300713          	li	a4,99
 7a2:	0ee78e63          	beq	a5,a4,89e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7a6:	11478863          	beq	a5,s4,8b6 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7aa:	85d2                	mv	a1,s4
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	e92080e7          	jalr	-366(ra) # 640 <putc>
        putc(fd, c);
 7b6:	85ca                	mv	a1,s2
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	e86080e7          	jalr	-378(ra) # 640 <putc>
      }
      state = 0;
 7c2:	4981                	li	s3,0
 7c4:	b765                	j	76c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7c6:	008b0913          	addi	s2,s6,8
 7ca:	4685                	li	a3,1
 7cc:	4629                	li	a2,10
 7ce:	000b2583          	lw	a1,0(s6)
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	e8e080e7          	jalr	-370(ra) # 662 <printint>
 7dc:	8b4a                	mv	s6,s2
      state = 0;
 7de:	4981                	li	s3,0
 7e0:	b771                	j	76c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7e2:	008b0913          	addi	s2,s6,8
 7e6:	4681                	li	a3,0
 7e8:	4629                	li	a2,10
 7ea:	000b2583          	lw	a1,0(s6)
 7ee:	8556                	mv	a0,s5
 7f0:	00000097          	auipc	ra,0x0
 7f4:	e72080e7          	jalr	-398(ra) # 662 <printint>
 7f8:	8b4a                	mv	s6,s2
      state = 0;
 7fa:	4981                	li	s3,0
 7fc:	bf85                	j	76c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7fe:	008b0913          	addi	s2,s6,8
 802:	4681                	li	a3,0
 804:	4641                	li	a2,16
 806:	000b2583          	lw	a1,0(s6)
 80a:	8556                	mv	a0,s5
 80c:	00000097          	auipc	ra,0x0
 810:	e56080e7          	jalr	-426(ra) # 662 <printint>
 814:	8b4a                	mv	s6,s2
      state = 0;
 816:	4981                	li	s3,0
 818:	bf91                	j	76c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 81a:	008b0793          	addi	a5,s6,8
 81e:	f8f43423          	sd	a5,-120(s0)
 822:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 826:	03000593          	li	a1,48
 82a:	8556                	mv	a0,s5
 82c:	00000097          	auipc	ra,0x0
 830:	e14080e7          	jalr	-492(ra) # 640 <putc>
  putc(fd, 'x');
 834:	85ea                	mv	a1,s10
 836:	8556                	mv	a0,s5
 838:	00000097          	auipc	ra,0x0
 83c:	e08080e7          	jalr	-504(ra) # 640 <putc>
 840:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 842:	03c9d793          	srli	a5,s3,0x3c
 846:	97de                	add	a5,a5,s7
 848:	0007c583          	lbu	a1,0(a5)
 84c:	8556                	mv	a0,s5
 84e:	00000097          	auipc	ra,0x0
 852:	df2080e7          	jalr	-526(ra) # 640 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 856:	0992                	slli	s3,s3,0x4
 858:	397d                	addiw	s2,s2,-1
 85a:	fe0914e3          	bnez	s2,842 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 85e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 862:	4981                	li	s3,0
 864:	b721                	j	76c <vprintf+0x60>
        s = va_arg(ap, char*);
 866:	008b0993          	addi	s3,s6,8
 86a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 86e:	02090163          	beqz	s2,890 <vprintf+0x184>
        while(*s != 0){
 872:	00094583          	lbu	a1,0(s2)
 876:	c9a1                	beqz	a1,8c6 <vprintf+0x1ba>
          putc(fd, *s);
 878:	8556                	mv	a0,s5
 87a:	00000097          	auipc	ra,0x0
 87e:	dc6080e7          	jalr	-570(ra) # 640 <putc>
          s++;
 882:	0905                	addi	s2,s2,1
        while(*s != 0){
 884:	00094583          	lbu	a1,0(s2)
 888:	f9e5                	bnez	a1,878 <vprintf+0x16c>
        s = va_arg(ap, char*);
 88a:	8b4e                	mv	s6,s3
      state = 0;
 88c:	4981                	li	s3,0
 88e:	bdf9                	j	76c <vprintf+0x60>
          s = "(null)";
 890:	00000917          	auipc	s2,0x0
 894:	37090913          	addi	s2,s2,880 # c00 <malloc+0x22a>
        while(*s != 0){
 898:	02800593          	li	a1,40
 89c:	bff1                	j	878 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 89e:	008b0913          	addi	s2,s6,8
 8a2:	000b4583          	lbu	a1,0(s6)
 8a6:	8556                	mv	a0,s5
 8a8:	00000097          	auipc	ra,0x0
 8ac:	d98080e7          	jalr	-616(ra) # 640 <putc>
 8b0:	8b4a                	mv	s6,s2
      state = 0;
 8b2:	4981                	li	s3,0
 8b4:	bd65                	j	76c <vprintf+0x60>
        putc(fd, c);
 8b6:	85d2                	mv	a1,s4
 8b8:	8556                	mv	a0,s5
 8ba:	00000097          	auipc	ra,0x0
 8be:	d86080e7          	jalr	-634(ra) # 640 <putc>
      state = 0;
 8c2:	4981                	li	s3,0
 8c4:	b565                	j	76c <vprintf+0x60>
        s = va_arg(ap, char*);
 8c6:	8b4e                	mv	s6,s3
      state = 0;
 8c8:	4981                	li	s3,0
 8ca:	b54d                	j	76c <vprintf+0x60>
    }
  }
}
 8cc:	70e6                	ld	ra,120(sp)
 8ce:	7446                	ld	s0,112(sp)
 8d0:	74a6                	ld	s1,104(sp)
 8d2:	7906                	ld	s2,96(sp)
 8d4:	69e6                	ld	s3,88(sp)
 8d6:	6a46                	ld	s4,80(sp)
 8d8:	6aa6                	ld	s5,72(sp)
 8da:	6b06                	ld	s6,64(sp)
 8dc:	7be2                	ld	s7,56(sp)
 8de:	7c42                	ld	s8,48(sp)
 8e0:	7ca2                	ld	s9,40(sp)
 8e2:	7d02                	ld	s10,32(sp)
 8e4:	6de2                	ld	s11,24(sp)
 8e6:	6109                	addi	sp,sp,128
 8e8:	8082                	ret

00000000000008ea <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8ea:	715d                	addi	sp,sp,-80
 8ec:	ec06                	sd	ra,24(sp)
 8ee:	e822                	sd	s0,16(sp)
 8f0:	1000                	addi	s0,sp,32
 8f2:	e010                	sd	a2,0(s0)
 8f4:	e414                	sd	a3,8(s0)
 8f6:	e818                	sd	a4,16(s0)
 8f8:	ec1c                	sd	a5,24(s0)
 8fa:	03043023          	sd	a6,32(s0)
 8fe:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 902:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 906:	8622                	mv	a2,s0
 908:	00000097          	auipc	ra,0x0
 90c:	e04080e7          	jalr	-508(ra) # 70c <vprintf>
}
 910:	60e2                	ld	ra,24(sp)
 912:	6442                	ld	s0,16(sp)
 914:	6161                	addi	sp,sp,80
 916:	8082                	ret

0000000000000918 <printf>:

void
printf(const char *fmt, ...)
{
 918:	711d                	addi	sp,sp,-96
 91a:	ec06                	sd	ra,24(sp)
 91c:	e822                	sd	s0,16(sp)
 91e:	1000                	addi	s0,sp,32
 920:	e40c                	sd	a1,8(s0)
 922:	e810                	sd	a2,16(s0)
 924:	ec14                	sd	a3,24(s0)
 926:	f018                	sd	a4,32(s0)
 928:	f41c                	sd	a5,40(s0)
 92a:	03043823          	sd	a6,48(s0)
 92e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 932:	00840613          	addi	a2,s0,8
 936:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 93a:	85aa                	mv	a1,a0
 93c:	4505                	li	a0,1
 93e:	00000097          	auipc	ra,0x0
 942:	dce080e7          	jalr	-562(ra) # 70c <vprintf>
}
 946:	60e2                	ld	ra,24(sp)
 948:	6442                	ld	s0,16(sp)
 94a:	6125                	addi	sp,sp,96
 94c:	8082                	ret

000000000000094e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 94e:	1141                	addi	sp,sp,-16
 950:	e422                	sd	s0,8(sp)
 952:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 954:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 958:	00000797          	auipc	a5,0x0
 95c:	2c87b783          	ld	a5,712(a5) # c20 <freep>
 960:	a805                	j	990 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 962:	4618                	lw	a4,8(a2)
 964:	9db9                	addw	a1,a1,a4
 966:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 96a:	6398                	ld	a4,0(a5)
 96c:	6318                	ld	a4,0(a4)
 96e:	fee53823          	sd	a4,-16(a0)
 972:	a091                	j	9b6 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 974:	ff852703          	lw	a4,-8(a0)
 978:	9e39                	addw	a2,a2,a4
 97a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 97c:	ff053703          	ld	a4,-16(a0)
 980:	e398                	sd	a4,0(a5)
 982:	a099                	j	9c8 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 984:	6398                	ld	a4,0(a5)
 986:	00e7e463          	bltu	a5,a4,98e <free+0x40>
 98a:	00e6ea63          	bltu	a3,a4,99e <free+0x50>
{
 98e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 990:	fed7fae3          	bgeu	a5,a3,984 <free+0x36>
 994:	6398                	ld	a4,0(a5)
 996:	00e6e463          	bltu	a3,a4,99e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 99a:	fee7eae3          	bltu	a5,a4,98e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 99e:	ff852583          	lw	a1,-8(a0)
 9a2:	6390                	ld	a2,0(a5)
 9a4:	02059713          	slli	a4,a1,0x20
 9a8:	9301                	srli	a4,a4,0x20
 9aa:	0712                	slli	a4,a4,0x4
 9ac:	9736                	add	a4,a4,a3
 9ae:	fae60ae3          	beq	a2,a4,962 <free+0x14>
    bp->s.ptr = p->s.ptr;
 9b2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9b6:	4790                	lw	a2,8(a5)
 9b8:	02061713          	slli	a4,a2,0x20
 9bc:	9301                	srli	a4,a4,0x20
 9be:	0712                	slli	a4,a4,0x4
 9c0:	973e                	add	a4,a4,a5
 9c2:	fae689e3          	beq	a3,a4,974 <free+0x26>
  } else
    p->s.ptr = bp;
 9c6:	e394                	sd	a3,0(a5)
  freep = p;
 9c8:	00000717          	auipc	a4,0x0
 9cc:	24f73c23          	sd	a5,600(a4) # c20 <freep>
}
 9d0:	6422                	ld	s0,8(sp)
 9d2:	0141                	addi	sp,sp,16
 9d4:	8082                	ret

00000000000009d6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9d6:	7139                	addi	sp,sp,-64
 9d8:	fc06                	sd	ra,56(sp)
 9da:	f822                	sd	s0,48(sp)
 9dc:	f426                	sd	s1,40(sp)
 9de:	f04a                	sd	s2,32(sp)
 9e0:	ec4e                	sd	s3,24(sp)
 9e2:	e852                	sd	s4,16(sp)
 9e4:	e456                	sd	s5,8(sp)
 9e6:	e05a                	sd	s6,0(sp)
 9e8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9ea:	02051493          	slli	s1,a0,0x20
 9ee:	9081                	srli	s1,s1,0x20
 9f0:	04bd                	addi	s1,s1,15
 9f2:	8091                	srli	s1,s1,0x4
 9f4:	0014899b          	addiw	s3,s1,1
 9f8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9fa:	00000517          	auipc	a0,0x0
 9fe:	22653503          	ld	a0,550(a0) # c20 <freep>
 a02:	c515                	beqz	a0,a2e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a04:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a06:	4798                	lw	a4,8(a5)
 a08:	02977f63          	bgeu	a4,s1,a46 <malloc+0x70>
 a0c:	8a4e                	mv	s4,s3
 a0e:	0009871b          	sext.w	a4,s3
 a12:	6685                	lui	a3,0x1
 a14:	00d77363          	bgeu	a4,a3,a1a <malloc+0x44>
 a18:	6a05                	lui	s4,0x1
 a1a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a1e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a22:	00000917          	auipc	s2,0x0
 a26:	1fe90913          	addi	s2,s2,510 # c20 <freep>
  if(p == (char*)-1)
 a2a:	5afd                	li	s5,-1
 a2c:	a88d                	j	a9e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a2e:	00000797          	auipc	a5,0x0
 a32:	1fa78793          	addi	a5,a5,506 # c28 <base>
 a36:	00000717          	auipc	a4,0x0
 a3a:	1ef73523          	sd	a5,490(a4) # c20 <freep>
 a3e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a40:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a44:	b7e1                	j	a0c <malloc+0x36>
      if(p->s.size == nunits)
 a46:	02e48b63          	beq	s1,a4,a7c <malloc+0xa6>
        p->s.size -= nunits;
 a4a:	4137073b          	subw	a4,a4,s3
 a4e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a50:	1702                	slli	a4,a4,0x20
 a52:	9301                	srli	a4,a4,0x20
 a54:	0712                	slli	a4,a4,0x4
 a56:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a58:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a5c:	00000717          	auipc	a4,0x0
 a60:	1ca73223          	sd	a0,452(a4) # c20 <freep>
      return (void*)(p + 1);
 a64:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a68:	70e2                	ld	ra,56(sp)
 a6a:	7442                	ld	s0,48(sp)
 a6c:	74a2                	ld	s1,40(sp)
 a6e:	7902                	ld	s2,32(sp)
 a70:	69e2                	ld	s3,24(sp)
 a72:	6a42                	ld	s4,16(sp)
 a74:	6aa2                	ld	s5,8(sp)
 a76:	6b02                	ld	s6,0(sp)
 a78:	6121                	addi	sp,sp,64
 a7a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a7c:	6398                	ld	a4,0(a5)
 a7e:	e118                	sd	a4,0(a0)
 a80:	bff1                	j	a5c <malloc+0x86>
  hp->s.size = nu;
 a82:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a86:	0541                	addi	a0,a0,16
 a88:	00000097          	auipc	ra,0x0
 a8c:	ec6080e7          	jalr	-314(ra) # 94e <free>
  return freep;
 a90:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a94:	d971                	beqz	a0,a68 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a96:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a98:	4798                	lw	a4,8(a5)
 a9a:	fa9776e3          	bgeu	a4,s1,a46 <malloc+0x70>
    if(p == freep)
 a9e:	00093703          	ld	a4,0(s2)
 aa2:	853e                	mv	a0,a5
 aa4:	fef719e3          	bne	a4,a5,a96 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 aa8:	8552                	mv	a0,s4
 aaa:	00000097          	auipc	ra,0x0
 aae:	b66080e7          	jalr	-1178(ra) # 610 <sbrk>
  if(p == (char*)-1)
 ab2:	fd5518e3          	bne	a0,s5,a82 <malloc+0xac>
        return 0;
 ab6:	4501                	li	a0,0
 ab8:	bf45                	j	a68 <malloc+0x92>
