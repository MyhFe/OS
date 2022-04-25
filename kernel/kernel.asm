
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e6c78793          	addi	a5,a5,-404 # 80005ed0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	6e0080e7          	jalr	1760(ra) # 8000280c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	ab0080e7          	jalr	-1360(ra) # 80001c74 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	166080e7          	jalr	358(ra) # 8000233a <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5a6080e7          	jalr	1446(ra) # 800027b6 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	570080e7          	jalr	1392(ra) # 80002862 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	0c6080e7          	jalr	198(ra) # 8000250c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	4c078793          	addi	a5,a5,1216 # 80021938 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	c9c50513          	addi	a0,a0,-868 # 80008208 <digits+0x1c8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	c6c080e7          	jalr	-916(ra) # 8000250c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a0e080e7          	jalr	-1522(ra) # 8000233a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	0da080e7          	jalr	218(ra) # 80001c58 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	0a8080e7          	jalr	168(ra) # 80001c58 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	09c080e7          	jalr	156(ra) # 80001c58 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	084080e7          	jalr	132(ra) # 80001c58 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	044080e7          	jalr	68(ra) # 80001c58 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	018080e7          	jalr	24(ra) # 80001c58 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	db2080e7          	jalr	-590(ra) # 80001c48 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	d96080e7          	jalr	-618(ra) # 80001c48 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	ace080e7          	jalr	-1330(ra) # 800029a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	034080e7          	jalr	52(ra) # 80005f10 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	b88080e7          	jalr	-1144(ra) # 80001a6c <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	30c50513          	addi	a0,a0,780 # 80008208 <digits+0x1c8>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	2ec50513          	addi	a0,a0,748 # 80008208 <digits+0x1c8>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	c44080e7          	jalr	-956(ra) # 80001b88 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	a2e080e7          	jalr	-1490(ra) # 8000297a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a4e080e7          	jalr	-1458(ra) # 800029a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f9e080e7          	jalr	-98(ra) # 80005efa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fac080e7          	jalr	-84(ra) # 80005f10 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	192080e7          	jalr	402(ra) # 800030fe <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	822080e7          	jalr	-2014(ra) # 80003796 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	7cc080e7          	jalr	1996(ra) # 80004748 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	0ae080e7          	jalr	174(ra) # 80006032 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	fd8080e7          	jalr	-40(ra) # 80001f64 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e9c48493          	addi	s1,s1,-356 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	e82a0a13          	addi	s4,s4,-382 # 800176f0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	859d                	srai	a1,a1,0x7
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	18048493          	addi	s1,s1,384
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800018d4:	7179                	addi	sp,sp,-48
    800018d6:	f406                	sd	ra,40(sp)
    800018d8:	f022                	sd	s0,32(sp)
    800018da:	ec26                	sd	s1,24(sp)
    800018dc:	e84a                	sd	s2,16(sp)
    800018de:	e44e                	sd	s3,8(sp)
    800018e0:	1800                	addi	s0,sp,48
    800018e2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800018e4:	00010497          	auipc	s1,0x10
    800018e8:	e0c48493          	addi	s1,s1,-500 # 800116f0 <proc>
    800018ec:	00016997          	auipc	s3,0x16
    800018f0:	e0498993          	addi	s3,s3,-508 # 800176f0 <tickslock>
    acquire(&p->lock);
    800018f4:	8526                	mv	a0,s1
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	2ee080e7          	jalr	750(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800018fe:	589c                	lw	a5,48(s1)
    80001900:	01278d63          	beq	a5,s2,8000191a <kill+0x46>

      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001904:	8526                	mv	a0,s1
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	392080e7          	jalr	914(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000190e:	18048493          	addi	s1,s1,384
    80001912:	ff3491e3          	bne	s1,s3,800018f4 <kill+0x20>
  }
  return -1;
    80001916:	557d                	li	a0,-1
    80001918:	a829                	j	80001932 <kill+0x5e>
      p->killed = 1;
    8000191a:	4785                	li	a5,1
    8000191c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4789                	li	a5,2
    80001922:	00f70f63          	beq	a4,a5,80001940 <kill+0x6c>
      release(&p->lock);
    80001926:	8526                	mv	a0,s1
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	370080e7          	jalr	880(ra) # 80000c98 <release>
      return 0;
    80001930:	4501                	li	a0,0
}
    80001932:	70a2                	ld	ra,40(sp)
    80001934:	7402                	ld	s0,32(sp)
    80001936:	64e2                	ld	s1,24(sp)
    80001938:	6942                	ld	s2,16(sp)
    8000193a:	69a2                	ld	s3,8(sp)
    8000193c:	6145                	addi	sp,sp,48
    8000193e:	8082                	ret
        p->state = RUNNABLE;
    80001940:	478d                	li	a5,3
    80001942:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    80001944:	00007797          	auipc	a5,0x7
    80001948:	70c7a783          	lw	a5,1804(a5) # 80009050 <ticks>
    8000194c:	dcdc                	sw	a5,60(s1)
    8000194e:	bfe1                	j	80001926 <kill+0x52>

0000000080001950 <kill_system>:


int
kill_system(void)
{
    80001950:	715d                	addi	sp,sp,-80
    80001952:	e486                	sd	ra,72(sp)
    80001954:	e0a2                	sd	s0,64(sp)
    80001956:	fc26                	sd	s1,56(sp)
    80001958:	f84a                	sd	s2,48(sp)
    8000195a:	f44e                	sd	s3,40(sp)
    8000195c:	f052                	sd	s4,32(sp)
    8000195e:	ec56                	sd	s5,24(sp)
    80001960:	e85a                	sd	s6,16(sp)
    80001962:	e45e                	sd	s7,8(sp)
    80001964:	0880                	addi	s0,sp,80
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001966:	00010497          	auipc	s1,0x10
    8000196a:	d8a48493          	addi	s1,s1,-630 # 800116f0 <proc>
    acquire(&p->lock);
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    8000196e:	8926                	mv	s2,s1
      p->killed = 1;
    80001970:	4a85                	li	s5,1
      if(p->state == SLEEPING){
    80001972:	4a09                	li	s4,2
        // Wake process from sleep().
        p->state = RUNNABLE;
    80001974:	4b8d                	li	s7,3
        p->last_runnable_time = ticks;
    80001976:	00007b17          	auipc	s6,0x7
    8000197a:	6dab0b13          	addi	s6,s6,1754 # 80009050 <ticks>
  for(p = proc; p < &proc[NPROC]; p++){
    8000197e:	00016997          	auipc	s3,0x16
    80001982:	d7298993          	addi	s3,s3,-654 # 800176f0 <tickslock>
    80001986:	a811                	j	8000199a <kill_system+0x4a>
      }
      //release(&p->lock);
    }
    release(&p->lock);
    80001988:	8526                	mv	a0,s1
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	30e080e7          	jalr	782(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001992:	18048493          	addi	s1,s1,384
    80001996:	03348b63          	beq	s1,s3,800019cc <kill_system+0x7c>
    acquire(&p->lock);
    8000199a:	8526                	mv	a0,s1
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	248080e7          	jalr	584(ra) # 80000be4 <acquire>
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    800019a4:	589c                	lw	a5,48(s1)
    800019a6:	03092703          	lw	a4,48(s2) # 4000030 <_entry-0x7bffffd0>
    800019aa:	fcf70fe3          	beq	a4,a5,80001988 <kill_system+0x38>
    800019ae:	1b092703          	lw	a4,432(s2)
    800019b2:	fcf70be3          	beq	a4,a5,80001988 <kill_system+0x38>
      p->killed = 1;
    800019b6:	0354a423          	sw	s5,40(s1)
      if(p->state == SLEEPING){
    800019ba:	4c9c                	lw	a5,24(s1)
    800019bc:	fd4796e3          	bne	a5,s4,80001988 <kill_system+0x38>
        p->state = RUNNABLE;
    800019c0:	0174ac23          	sw	s7,24(s1)
        p->last_runnable_time = ticks;
    800019c4:	000b2783          	lw	a5,0(s6)
    800019c8:	dcdc                	sw	a5,60(s1)
    800019ca:	bf7d                	j	80001988 <kill_system+0x38>
  }
  return 0;
}
    800019cc:	4501                	li	a0,0
    800019ce:	60a6                	ld	ra,72(sp)
    800019d0:	6406                	ld	s0,64(sp)
    800019d2:	74e2                	ld	s1,56(sp)
    800019d4:	7942                	ld	s2,48(sp)
    800019d6:	79a2                	ld	s3,40(sp)
    800019d8:	7a02                	ld	s4,32(sp)
    800019da:	6ae2                	ld	s5,24(sp)
    800019dc:	6b42                	ld	s6,16(sp)
    800019de:	6ba2                	ld	s7,8(sp)
    800019e0:	6161                	addi	sp,sp,80
    800019e2:	8082                	ret

00000000800019e4 <print_stats>:
  yield();
  return 0;
}

void
print_stats(void){
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  printf("cpu_utilization: %d \% \n", cpu_utilization);
    800019ec:	00007597          	auipc	a1,0x7
    800019f0:	63c5a583          	lw	a1,1596(a1) # 80009028 <cpu_utilization>
    800019f4:	00006517          	auipc	a0,0x6
    800019f8:	7ec50513          	addi	a0,a0,2028 # 800081e0 <digits+0x1a0>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	b8c080e7          	jalr	-1140(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80001a04:	00007597          	auipc	a1,0x7
    80001a08:	6285a583          	lw	a1,1576(a1) # 8000902c <program_time>
    80001a0c:	00006517          	auipc	a0,0x6
    80001a10:	7ec50513          	addi	a0,a0,2028 # 800081f8 <digits+0x1b8>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	b74080e7          	jalr	-1164(ra) # 80000588 <printf>
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    80001a1c:	00007597          	auipc	a1,0x7
    80001a20:	6245a583          	lw	a1,1572(a1) # 80009040 <sleeping_processes_mean>
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	7ec50513          	addi	a0,a0,2028 # 80008210 <digits+0x1d0>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b5c080e7          	jalr	-1188(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    80001a34:	00007597          	auipc	a1,0x7
    80001a38:	6085a583          	lw	a1,1544(a1) # 8000903c <running_processes_mean>
    80001a3c:	00006517          	auipc	a0,0x6
    80001a40:	7f450513          	addi	a0,a0,2036 # 80008230 <digits+0x1f0>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	b44080e7          	jalr	-1212(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    80001a4c:	00007597          	auipc	a1,0x7
    80001a50:	5ec5a583          	lw	a1,1516(a1) # 80009038 <runnable_processes_mean>
    80001a54:	00006517          	auipc	a0,0x6
    80001a58:	7fc50513          	addi	a0,a0,2044 # 80008250 <digits+0x210>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	b2c080e7          	jalr	-1236(ra) # 80000588 <printf>
}
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret

0000000080001a6c <scheduler>:
}
#endif
#ifdef FCFS
void
scheduler(void)
{
    80001a6c:	715d                	addi	sp,sp,-80
    80001a6e:	e486                	sd	ra,72(sp)
    80001a70:	e0a2                	sd	s0,64(sp)
    80001a72:	fc26                	sd	s1,56(sp)
    80001a74:	f84a                	sd	s2,48(sp)
    80001a76:	f44e                	sd	s3,40(sp)
    80001a78:	f052                	sd	s4,32(sp)
    80001a7a:	ec56                	sd	s5,24(sp)
    80001a7c:	e85a                	sd	s6,16(sp)
    80001a7e:	e45e                	sd	s7,8(sp)
    80001a80:	e062                	sd	s8,0(sp)
    80001a82:	0880                	addi	s0,sp,80
  printf("FCFS\n");
    80001a84:	00006517          	auipc	a0,0x6
    80001a88:	7ec50513          	addi	a0,a0,2028 # 80008270 <digits+0x230>
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	afc080e7          	jalr	-1284(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a94:	8792                	mv	a5,tp
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
    80001a96:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001a98:	00010b97          	auipc	s7,0x10
    80001a9c:	828b8b93          	addi	s7,s7,-2008 # 800112c0 <cpus>
    80001aa0:	00779713          	slli	a4,a5,0x7
    80001aa4:	00eb86b3          	add	a3,s7,a4
    80001aa8:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
        swtch(&c->context, &p->context);
    80001aac:	0721                	addi	a4,a4,8
    80001aae:	9bba                	add	s7,s7,a4
    struct proc *tmp = &proc[0];
    80001ab0:	00010a17          	auipc	s4,0x10
    80001ab4:	c40a0a13          	addi	s4,s4,-960 # 800116f0 <proc>
    int min = __INT_MAX__;
    80001ab8:	80000ab7          	lui	s5,0x80000
    80001abc:	fffaca93          	not	s5,s5
        if (p->state == RUNNABLE){
    80001ac0:	490d                	li	s2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ac2:	00016497          	auipc	s1,0x16
    80001ac6:	c2e48493          	addi	s1,s1,-978 # 800176f0 <tickslock>
        c->proc = p;
    80001aca:	8b36                	mv	s6,a3
    80001acc:	a08d                	j	80001b2e <scheduler+0xc2>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ace:	18078793          	addi	a5,a5,384
    80001ad2:	00978b63          	beq	a5,s1,80001ae8 <scheduler+0x7c>
      if (p->last_runnable_time < min) {
    80001ad6:	5fd8                	lw	a4,60(a5)
    80001ad8:	fed75be3          	bge	a4,a3,80001ace <scheduler+0x62>
        if (p->state == RUNNABLE){
    80001adc:	4f90                	lw	a2,24(a5)
    80001ade:	ff2618e3          	bne	a2,s2,80001ace <scheduler+0x62>
    80001ae2:	89be                	mv	s3,a5
          min = tmp->last_runnable_time;
    80001ae4:	86ba                	mv	a3,a4
    80001ae6:	b7e5                	j	80001ace <scheduler+0x62>
    acquire(&p->lock);
    80001ae8:	8c4e                	mv	s8,s3
    80001aea:	854e                	mv	a0,s3
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	0f8080e7          	jalr	248(ra) # 80000be4 <acquire>
    if ((finish < ticks) || (p->pid==proc[0].pid) || (p->pid==proc[1].pid)){
    80001af4:	00007797          	auipc	a5,0x7
    80001af8:	55c7a783          	lw	a5,1372(a5) # 80009050 <ticks>
    80001afc:	00007717          	auipc	a4,0x7
    80001b00:	54872703          	lw	a4,1352(a4) # 80009044 <finish>
    80001b04:	00f76c63          	bltu	a4,a5,80001b1c <scheduler+0xb0>
    80001b08:	0309a703          	lw	a4,48(s3)
    80001b0c:	030a2683          	lw	a3,48(s4)
    80001b10:	00e68663          	beq	a3,a4,80001b1c <scheduler+0xb0>
    80001b14:	1b0a2683          	lw	a3,432(s4)
    80001b18:	00e69663          	bne	a3,a4,80001b24 <scheduler+0xb8>
      if(p->state == RUNNABLE) {
    80001b1c:	0189a703          	lw	a4,24(s3)
    80001b20:	03270163          	beq	a4,s2,80001b42 <scheduler+0xd6>
  release(&p->lock);
    80001b24:	8562                	mv	a0,s8
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001b32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001b36:	10079073          	csrw	sstatus,a5
    struct proc *tmp = &proc[0];
    80001b3a:	89d2                	mv	s3,s4
    int min = __INT_MAX__;
    80001b3c:	86d6                	mv	a3,s5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001b3e:	87d2                	mv	a5,s4
    80001b40:	bf59                	j	80001ad6 <scheduler+0x6a>
        p->state = RUNNING;
    80001b42:	4711                	li	a4,4
    80001b44:	00e9ac23          	sw	a4,24(s3)
        p->before_switch = ticks;
    80001b48:	04f9a623          	sw	a5,76(s3)
        c->proc = p;
    80001b4c:	013b3023          	sd	s3,0(s6)
        if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b50:	0309a703          	lw	a4,48(s3)
    80001b54:	030a2683          	lw	a3,48(s4)
    80001b58:	00e68e63          	beq	a3,a4,80001b74 <scheduler+0x108>
    80001b5c:	1b0a2683          	lw	a3,432(s4)
    80001b60:	00e68a63          	beq	a3,a4,80001b74 <scheduler+0x108>
          p->runnable_time = p->runnable_time + ticks - p->last_runnable_time;
    80001b64:	0449a703          	lw	a4,68(s3)
    80001b68:	9fb9                	addw	a5,a5,a4
    80001b6a:	03c9a703          	lw	a4,60(s3)
    80001b6e:	9f99                	subw	a5,a5,a4
    80001b70:	04f9a223          	sw	a5,68(s3)
        swtch(&c->context, &p->context);
    80001b74:	07898593          	addi	a1,s3,120
    80001b78:	855e                	mv	a0,s7
    80001b7a:	00001097          	auipc	ra,0x1
    80001b7e:	d96080e7          	jalr	-618(ra) # 80002910 <swtch>
        c->proc = 0;
    80001b82:	000b3023          	sd	zero,0(s6)
    80001b86:	bf79                	j	80001b24 <scheduler+0xb8>

0000000080001b88 <procinit>:
{
    80001b88:	7139                	addi	sp,sp,-64
    80001b8a:	fc06                	sd	ra,56(sp)
    80001b8c:	f822                	sd	s0,48(sp)
    80001b8e:	f426                	sd	s1,40(sp)
    80001b90:	f04a                	sd	s2,32(sp)
    80001b92:	ec4e                	sd	s3,24(sp)
    80001b94:	e852                	sd	s4,16(sp)
    80001b96:	e456                	sd	s5,8(sp)
    80001b98:	e05a                	sd	s6,0(sp)
    80001b9a:	0080                	addi	s0,sp,64
  start_time = ticks;
    80001b9c:	00007797          	auipc	a5,0x7
    80001ba0:	4b47a783          	lw	a5,1204(a5) # 80009050 <ticks>
    80001ba4:	00007717          	auipc	a4,0x7
    80001ba8:	48f72623          	sw	a5,1164(a4) # 80009030 <start_time>
  initlock(&pid_lock, "nextpid");
    80001bac:	00006597          	auipc	a1,0x6
    80001bb0:	6cc58593          	addi	a1,a1,1740 # 80008278 <digits+0x238>
    80001bb4:	00010517          	auipc	a0,0x10
    80001bb8:	b0c50513          	addi	a0,a0,-1268 # 800116c0 <pid_lock>
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	f98080e7          	jalr	-104(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bc4:	00006597          	auipc	a1,0x6
    80001bc8:	6bc58593          	addi	a1,a1,1724 # 80008280 <digits+0x240>
    80001bcc:	00010517          	auipc	a0,0x10
    80001bd0:	b0c50513          	addi	a0,a0,-1268 # 800116d8 <wait_lock>
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	f80080e7          	jalr	-128(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	00010497          	auipc	s1,0x10
    80001be0:	b1448493          	addi	s1,s1,-1260 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001be4:	00006b17          	auipc	s6,0x6
    80001be8:	6acb0b13          	addi	s6,s6,1708 # 80008290 <digits+0x250>
      p->kstack = KSTACK((int) (p - proc));
    80001bec:	8aa6                	mv	s5,s1
    80001bee:	00006a17          	auipc	s4,0x6
    80001bf2:	412a0a13          	addi	s4,s4,1042 # 80008000 <etext>
    80001bf6:	04000937          	lui	s2,0x4000
    80001bfa:	197d                	addi	s2,s2,-1
    80001bfc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	00016997          	auipc	s3,0x16
    80001c02:	af298993          	addi	s3,s3,-1294 # 800176f0 <tickslock>
      initlock(&p->lock, "proc");
    80001c06:	85da                	mv	a1,s6
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	f4a080e7          	jalr	-182(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c12:	415487b3          	sub	a5,s1,s5
    80001c16:	879d                	srai	a5,a5,0x7
    80001c18:	000a3703          	ld	a4,0(s4)
    80001c1c:	02e787b3          	mul	a5,a5,a4
    80001c20:	2785                	addiw	a5,a5,1
    80001c22:	00d7979b          	slliw	a5,a5,0xd
    80001c26:	40f907b3          	sub	a5,s2,a5
    80001c2a:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2c:	18048493          	addi	s1,s1,384
    80001c30:	fd349be3          	bne	s1,s3,80001c06 <procinit+0x7e>
}
    80001c34:	70e2                	ld	ra,56(sp)
    80001c36:	7442                	ld	s0,48(sp)
    80001c38:	74a2                	ld	s1,40(sp)
    80001c3a:	7902                	ld	s2,32(sp)
    80001c3c:	69e2                	ld	s3,24(sp)
    80001c3e:	6a42                	ld	s4,16(sp)
    80001c40:	6aa2                	ld	s5,8(sp)
    80001c42:	6b02                	ld	s6,0(sp)
    80001c44:	6121                	addi	sp,sp,64
    80001c46:	8082                	ret

0000000080001c48 <cpuid>:
{
    80001c48:	1141                	addi	sp,sp,-16
    80001c4a:	e422                	sd	s0,8(sp)
    80001c4c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c4e:	8512                	mv	a0,tp
  return id;
}
    80001c50:	2501                	sext.w	a0,a0
    80001c52:	6422                	ld	s0,8(sp)
    80001c54:	0141                	addi	sp,sp,16
    80001c56:	8082                	ret

0000000080001c58 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c58:	1141                	addi	sp,sp,-16
    80001c5a:	e422                	sd	s0,8(sp)
    80001c5c:	0800                	addi	s0,sp,16
    80001c5e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c60:	2781                	sext.w	a5,a5
    80001c62:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c64:	0000f517          	auipc	a0,0xf
    80001c68:	65c50513          	addi	a0,a0,1628 # 800112c0 <cpus>
    80001c6c:	953e                	add	a0,a0,a5
    80001c6e:	6422                	ld	s0,8(sp)
    80001c70:	0141                	addi	sp,sp,16
    80001c72:	8082                	ret

0000000080001c74 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	1000                	addi	s0,sp,32
  push_off();
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	f1a080e7          	jalr	-230(ra) # 80000b98 <push_off>
    80001c86:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c88:	2781                	sext.w	a5,a5
    80001c8a:	079e                	slli	a5,a5,0x7
    80001c8c:	0000f717          	auipc	a4,0xf
    80001c90:	63470713          	addi	a4,a4,1588 # 800112c0 <cpus>
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	6384                	ld	s1,0(a5)
  pop_off();
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fa0080e7          	jalr	-96(ra) # 80000c38 <pop_off>
  return p;
}
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret

0000000080001cac <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001cac:	1141                	addi	sp,sp,-16
    80001cae:	e406                	sd	ra,8(sp)
    80001cb0:	e022                	sd	s0,0(sp)
    80001cb2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	fc0080e7          	jalr	-64(ra) # 80001c74 <myproc>
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	fdc080e7          	jalr	-36(ra) # 80000c98 <release>

  if (first) {
    80001cc4:	00007797          	auipc	a5,0x7
    80001cc8:	bfc7a783          	lw	a5,-1028(a5) # 800088c0 <first.1716>
    80001ccc:	eb89                	bnez	a5,80001cde <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cce:	00001097          	auipc	ra,0x1
    80001cd2:	cec080e7          	jalr	-788(ra) # 800029ba <usertrapret>
}
    80001cd6:	60a2                	ld	ra,8(sp)
    80001cd8:	6402                	ld	s0,0(sp)
    80001cda:	0141                	addi	sp,sp,16
    80001cdc:	8082                	ret
    first = 0;
    80001cde:	00007797          	auipc	a5,0x7
    80001ce2:	be07a123          	sw	zero,-1054(a5) # 800088c0 <first.1716>
    fsinit(ROOTDEV);
    80001ce6:	4505                	li	a0,1
    80001ce8:	00002097          	auipc	ra,0x2
    80001cec:	a2e080e7          	jalr	-1490(ra) # 80003716 <fsinit>
    80001cf0:	bff9                	j	80001cce <forkret+0x22>

0000000080001cf2 <allocpid>:
allocpid() {
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	e04a                	sd	s2,0(sp)
    80001cfc:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cfe:	00010917          	auipc	s2,0x10
    80001d02:	9c290913          	addi	s2,s2,-1598 # 800116c0 <pid_lock>
    80001d06:	854a                	mv	a0,s2
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	edc080e7          	jalr	-292(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001d10:	00007797          	auipc	a5,0x7
    80001d14:	bb478793          	addi	a5,a5,-1100 # 800088c4 <nextpid>
    80001d18:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d1a:	0014871b          	addiw	a4,s1,1
    80001d1e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d20:	854a                	mv	a0,s2
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
}
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <proc_pagetable>:
{
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	e04a                	sd	s2,0(sp)
    80001d42:	1000                	addi	s0,sp,32
    80001d44:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	5f4080e7          	jalr	1524(ra) # 8000133a <uvmcreate>
    80001d4e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d50:	c121                	beqz	a0,80001d90 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d52:	4729                	li	a4,10
    80001d54:	00005697          	auipc	a3,0x5
    80001d58:	2ac68693          	addi	a3,a3,684 # 80007000 <_trampoline>
    80001d5c:	6605                	lui	a2,0x1
    80001d5e:	040005b7          	lui	a1,0x4000
    80001d62:	15fd                	addi	a1,a1,-1
    80001d64:	05b2                	slli	a1,a1,0xc
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	34a080e7          	jalr	842(ra) # 800010b0 <mappages>
    80001d6e:	02054863          	bltz	a0,80001d9e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d72:	4719                	li	a4,6
    80001d74:	07093683          	ld	a3,112(s2)
    80001d78:	6605                	lui	a2,0x1
    80001d7a:	020005b7          	lui	a1,0x2000
    80001d7e:	15fd                	addi	a1,a1,-1
    80001d80:	05b6                	slli	a1,a1,0xd
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	32c080e7          	jalr	812(ra) # 800010b0 <mappages>
    80001d8c:	02054163          	bltz	a0,80001dae <proc_pagetable+0x76>
}
    80001d90:	8526                	mv	a0,s1
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6902                	ld	s2,0(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret
    uvmfree(pagetable, 0);
    80001d9e:	4581                	li	a1,0
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	794080e7          	jalr	1940(ra) # 80001536 <uvmfree>
    return 0;
    80001daa:	4481                	li	s1,0
    80001dac:	b7d5                	j	80001d90 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dae:	4681                	li	a3,0
    80001db0:	4605                	li	a2,1
    80001db2:	040005b7          	lui	a1,0x4000
    80001db6:	15fd                	addi	a1,a1,-1
    80001db8:	05b2                	slli	a1,a1,0xc
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	4ba080e7          	jalr	1210(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dc4:	4581                	li	a1,0
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	76e080e7          	jalr	1902(ra) # 80001536 <uvmfree>
    return 0;
    80001dd0:	4481                	li	s1,0
    80001dd2:	bf7d                	j	80001d90 <proc_pagetable+0x58>

0000000080001dd4 <proc_freepagetable>:
{
    80001dd4:	1101                	addi	sp,sp,-32
    80001dd6:	ec06                	sd	ra,24(sp)
    80001dd8:	e822                	sd	s0,16(sp)
    80001dda:	e426                	sd	s1,8(sp)
    80001ddc:	e04a                	sd	s2,0(sp)
    80001dde:	1000                	addi	s0,sp,32
    80001de0:	84aa                	mv	s1,a0
    80001de2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001de4:	4681                	li	a3,0
    80001de6:	4605                	li	a2,1
    80001de8:	040005b7          	lui	a1,0x4000
    80001dec:	15fd                	addi	a1,a1,-1
    80001dee:	05b2                	slli	a1,a1,0xc
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	486080e7          	jalr	1158(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001df8:	4681                	li	a3,0
    80001dfa:	4605                	li	a2,1
    80001dfc:	020005b7          	lui	a1,0x2000
    80001e00:	15fd                	addi	a1,a1,-1
    80001e02:	05b6                	slli	a1,a1,0xd
    80001e04:	8526                	mv	a0,s1
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	470080e7          	jalr	1136(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e0e:	85ca                	mv	a1,s2
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	724080e7          	jalr	1828(ra) # 80001536 <uvmfree>
}
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6902                	ld	s2,0(sp)
    80001e22:	6105                	addi	sp,sp,32
    80001e24:	8082                	ret

0000000080001e26 <freeproc>:
{
    80001e26:	1101                	addi	sp,sp,-32
    80001e28:	ec06                	sd	ra,24(sp)
    80001e2a:	e822                	sd	s0,16(sp)
    80001e2c:	e426                	sd	s1,8(sp)
    80001e2e:	1000                	addi	s0,sp,32
    80001e30:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e32:	7928                	ld	a0,112(a0)
    80001e34:	c509                	beqz	a0,80001e3e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	bc2080e7          	jalr	-1086(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e3e:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001e42:	74a8                	ld	a0,104(s1)
    80001e44:	c511                	beqz	a0,80001e50 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e46:	70ac                	ld	a1,96(s1)
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	f8c080e7          	jalr	-116(ra) # 80001dd4 <proc_freepagetable>
  p->pagetable = 0;
    80001e50:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001e54:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001e58:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e5c:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001e60:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001e64:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e68:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e6c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e70:	0004ac23          	sw	zero,24(s1)
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6105                	addi	sp,sp,32
    80001e7c:	8082                	ret

0000000080001e7e <allocproc>:
{
    80001e7e:	1101                	addi	sp,sp,-32
    80001e80:	ec06                	sd	ra,24(sp)
    80001e82:	e822                	sd	s0,16(sp)
    80001e84:	e426                	sd	s1,8(sp)
    80001e86:	e04a                	sd	s2,0(sp)
    80001e88:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8a:	00010497          	auipc	s1,0x10
    80001e8e:	86648493          	addi	s1,s1,-1946 # 800116f0 <proc>
    80001e92:	00016917          	auipc	s2,0x16
    80001e96:	85e90913          	addi	s2,s2,-1954 # 800176f0 <tickslock>
    acquire(&p->lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001ea4:	4c9c                	lw	a5,24(s1)
    80001ea6:	cf81                	beqz	a5,80001ebe <allocproc+0x40>
      release(&p->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb2:	18048493          	addi	s1,s1,384
    80001eb6:	ff2492e3          	bne	s1,s2,80001e9a <allocproc+0x1c>
  return 0;
    80001eba:	4481                	li	s1,0
    80001ebc:	a0ad                	j	80001f26 <allocproc+0xa8>
  p->pid = allocpid();
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	e34080e7          	jalr	-460(ra) # 80001cf2 <allocpid>
    80001ec6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ec8:	4785                	li	a5,1
    80001eca:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001ecc:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001ed0:	0204ac23          	sw	zero,56(s1)
  p->sleeping_time = 0;
    80001ed4:	0404a023          	sw	zero,64(s1)
  p->runnable_time = 0;
    80001ed8:	0404a223          	sw	zero,68(s1)
  p->running_time = 0;
    80001edc:	0404a423          	sw	zero,72(s1)
  p->before_switch = 0;
    80001ee0:	0404a623          	sw	zero,76(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	c10080e7          	jalr	-1008(ra) # 80000af4 <kalloc>
    80001eec:	892a                	mv	s2,a0
    80001eee:	f8a8                	sd	a0,112(s1)
    80001ef0:	c131                	beqz	a0,80001f34 <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	00000097          	auipc	ra,0x0
    80001ef8:	e44080e7          	jalr	-444(ra) # 80001d38 <proc_pagetable>
    80001efc:	892a                	mv	s2,a0
    80001efe:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001f00:	c531                	beqz	a0,80001f4c <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    80001f02:	07000613          	li	a2,112
    80001f06:	4581                	li	a1,0
    80001f08:	07848513          	addi	a0,s1,120
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	dd4080e7          	jalr	-556(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f14:	00000797          	auipc	a5,0x0
    80001f18:	d9878793          	addi	a5,a5,-616 # 80001cac <forkret>
    80001f1c:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f1e:	6cbc                	ld	a5,88(s1)
    80001f20:	6705                	lui	a4,0x1
    80001f22:	97ba                	add	a5,a5,a4
    80001f24:	e0dc                	sd	a5,128(s1)
}
    80001f26:	8526                	mv	a0,s1
    80001f28:	60e2                	ld	ra,24(sp)
    80001f2a:	6442                	ld	s0,16(sp)
    80001f2c:	64a2                	ld	s1,8(sp)
    80001f2e:	6902                	ld	s2,0(sp)
    80001f30:	6105                	addi	sp,sp,32
    80001f32:	8082                	ret
    freeproc(p);
    80001f34:	8526                	mv	a0,s1
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	ef0080e7          	jalr	-272(ra) # 80001e26 <freeproc>
    release(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
    return 0;
    80001f48:	84ca                	mv	s1,s2
    80001f4a:	bff1                	j	80001f26 <allocproc+0xa8>
    freeproc(p);
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	ed8080e7          	jalr	-296(ra) # 80001e26 <freeproc>
    release(&p->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	d40080e7          	jalr	-704(ra) # 80000c98 <release>
    return 0;
    80001f60:	84ca                	mv	s1,s2
    80001f62:	b7d1                	j	80001f26 <allocproc+0xa8>

0000000080001f64 <userinit>:
{
    80001f64:	1101                	addi	sp,sp,-32
    80001f66:	ec06                	sd	ra,24(sp)
    80001f68:	e822                	sd	s0,16(sp)
    80001f6a:	e426                	sd	s1,8(sp)
    80001f6c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	f10080e7          	jalr	-240(ra) # 80001e7e <allocproc>
    80001f76:	84aa                	mv	s1,a0
  initproc = p;
    80001f78:	00007797          	auipc	a5,0x7
    80001f7c:	0ca7b823          	sd	a0,208(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f80:	03400613          	li	a2,52
    80001f84:	00007597          	auipc	a1,0x7
    80001f88:	94c58593          	addi	a1,a1,-1716 # 800088d0 <initcode>
    80001f8c:	7528                	ld	a0,104(a0)
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	3da080e7          	jalr	986(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001f96:	6785                	lui	a5,0x1
    80001f98:	f0bc                	sd	a5,96(s1)
  sleeping_processes_mean = 0;
    80001f9a:	00007717          	auipc	a4,0x7
    80001f9e:	0a072323          	sw	zero,166(a4) # 80009040 <sleeping_processes_mean>
  running_processes_mean = 0;
    80001fa2:	00007717          	auipc	a4,0x7
    80001fa6:	08072d23          	sw	zero,154(a4) # 8000903c <running_processes_mean>
  runnable_processes_mean = 0;
    80001faa:	00007717          	auipc	a4,0x7
    80001fae:	08072723          	sw	zero,142(a4) # 80009038 <runnable_processes_mean>
  p->trapframe->epc = 0;      // user program counter
    80001fb2:	78b8                	ld	a4,112(s1)
    80001fb4:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fb8:	78b8                	ld	a4,112(s1)
    80001fba:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fbc:	4641                	li	a2,16
    80001fbe:	00006597          	auipc	a1,0x6
    80001fc2:	2da58593          	addi	a1,a1,730 # 80008298 <digits+0x258>
    80001fc6:	17048513          	addi	a0,s1,368
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	e68080e7          	jalr	-408(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	2d650513          	addi	a0,a0,726 # 800082a8 <digits+0x268>
    80001fda:	00002097          	auipc	ra,0x2
    80001fde:	16a080e7          	jalr	362(ra) # 80004144 <namei>
    80001fe2:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001fe6:	478d                	li	a5,3
    80001fe8:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001fea:	00007797          	auipc	a5,0x7
    80001fee:	0667a783          	lw	a5,102(a5) # 80009050 <ticks>
    80001ff2:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	ca2080e7          	jalr	-862(ra) # 80000c98 <release>
}
    80001ffe:	60e2                	ld	ra,24(sp)
    80002000:	6442                	ld	s0,16(sp)
    80002002:	64a2                	ld	s1,8(sp)
    80002004:	6105                	addi	sp,sp,32
    80002006:	8082                	ret

0000000080002008 <growproc>:
{
    80002008:	1101                	addi	sp,sp,-32
    8000200a:	ec06                	sd	ra,24(sp)
    8000200c:	e822                	sd	s0,16(sp)
    8000200e:	e426                	sd	s1,8(sp)
    80002010:	e04a                	sd	s2,0(sp)
    80002012:	1000                	addi	s0,sp,32
    80002014:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	c5e080e7          	jalr	-930(ra) # 80001c74 <myproc>
    8000201e:	892a                	mv	s2,a0
  sz = p->sz;
    80002020:	712c                	ld	a1,96(a0)
    80002022:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002026:	00904f63          	bgtz	s1,80002044 <growproc+0x3c>
  } else if(n < 0){
    8000202a:	0204cc63          	bltz	s1,80002062 <growproc+0x5a>
  p->sz = sz;
    8000202e:	1602                	slli	a2,a2,0x20
    80002030:	9201                	srli	a2,a2,0x20
    80002032:	06c93023          	sd	a2,96(s2)
  return 0;
    80002036:	4501                	li	a0,0
}
    80002038:	60e2                	ld	ra,24(sp)
    8000203a:	6442                	ld	s0,16(sp)
    8000203c:	64a2                	ld	s1,8(sp)
    8000203e:	6902                	ld	s2,0(sp)
    80002040:	6105                	addi	sp,sp,32
    80002042:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002044:	9e25                	addw	a2,a2,s1
    80002046:	1602                	slli	a2,a2,0x20
    80002048:	9201                	srli	a2,a2,0x20
    8000204a:	1582                	slli	a1,a1,0x20
    8000204c:	9181                	srli	a1,a1,0x20
    8000204e:	7528                	ld	a0,104(a0)
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	3d2080e7          	jalr	978(ra) # 80001422 <uvmalloc>
    80002058:	0005061b          	sext.w	a2,a0
    8000205c:	fa69                	bnez	a2,8000202e <growproc+0x26>
      return -1;
    8000205e:	557d                	li	a0,-1
    80002060:	bfe1                	j	80002038 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002062:	9e25                	addw	a2,a2,s1
    80002064:	1602                	slli	a2,a2,0x20
    80002066:	9201                	srli	a2,a2,0x20
    80002068:	1582                	slli	a1,a1,0x20
    8000206a:	9181                	srli	a1,a1,0x20
    8000206c:	7528                	ld	a0,104(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	36c080e7          	jalr	876(ra) # 800013da <uvmdealloc>
    80002076:	0005061b          	sext.w	a2,a0
    8000207a:	bf55                	j	8000202e <growproc+0x26>

000000008000207c <fork>:
{
    8000207c:	7179                	addi	sp,sp,-48
    8000207e:	f406                	sd	ra,40(sp)
    80002080:	f022                	sd	s0,32(sp)
    80002082:	ec26                	sd	s1,24(sp)
    80002084:	e84a                	sd	s2,16(sp)
    80002086:	e44e                	sd	s3,8(sp)
    80002088:	e052                	sd	s4,0(sp)
    8000208a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	be8080e7          	jalr	-1048(ra) # 80001c74 <myproc>
    80002094:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	de8080e7          	jalr	-536(ra) # 80001e7e <allocproc>
    8000209e:	12050163          	beqz	a0,800021c0 <fork+0x144>
    800020a2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020a4:	06093603          	ld	a2,96(s2)
    800020a8:	752c                	ld	a1,104(a0)
    800020aa:	06893503          	ld	a0,104(s2)
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	4c0080e7          	jalr	1216(ra) # 8000156e <uvmcopy>
    800020b6:	04054663          	bltz	a0,80002102 <fork+0x86>
  np->sz = p->sz;
    800020ba:	06093783          	ld	a5,96(s2)
    800020be:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    800020c2:	07093683          	ld	a3,112(s2)
    800020c6:	87b6                	mv	a5,a3
    800020c8:	0709b703          	ld	a4,112(s3)
    800020cc:	12068693          	addi	a3,a3,288
    800020d0:	0007b803          	ld	a6,0(a5)
    800020d4:	6788                	ld	a0,8(a5)
    800020d6:	6b8c                	ld	a1,16(a5)
    800020d8:	6f90                	ld	a2,24(a5)
    800020da:	01073023          	sd	a6,0(a4)
    800020de:	e708                	sd	a0,8(a4)
    800020e0:	eb0c                	sd	a1,16(a4)
    800020e2:	ef10                	sd	a2,24(a4)
    800020e4:	02078793          	addi	a5,a5,32
    800020e8:	02070713          	addi	a4,a4,32
    800020ec:	fed792e3          	bne	a5,a3,800020d0 <fork+0x54>
  np->trapframe->a0 = 0;
    800020f0:	0709b783          	ld	a5,112(s3)
    800020f4:	0607b823          	sd	zero,112(a5)
    800020f8:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    800020fc:	16800a13          	li	s4,360
    80002100:	a03d                	j	8000212e <fork+0xb2>
    freeproc(np);
    80002102:	854e                	mv	a0,s3
    80002104:	00000097          	auipc	ra,0x0
    80002108:	d22080e7          	jalr	-734(ra) # 80001e26 <freeproc>
    release(&np->lock);
    8000210c:	854e                	mv	a0,s3
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
    return -1;
    80002116:	5a7d                	li	s4,-1
    80002118:	a859                	j	800021ae <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    8000211a:	00002097          	auipc	ra,0x2
    8000211e:	6c0080e7          	jalr	1728(ra) # 800047da <filedup>
    80002122:	009987b3          	add	a5,s3,s1
    80002126:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002128:	04a1                	addi	s1,s1,8
    8000212a:	01448763          	beq	s1,s4,80002138 <fork+0xbc>
    if(p->ofile[i])
    8000212e:	009907b3          	add	a5,s2,s1
    80002132:	6388                	ld	a0,0(a5)
    80002134:	f17d                	bnez	a0,8000211a <fork+0x9e>
    80002136:	bfcd                	j	80002128 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002138:	16893503          	ld	a0,360(s2)
    8000213c:	00002097          	auipc	ra,0x2
    80002140:	814080e7          	jalr	-2028(ra) # 80003950 <idup>
    80002144:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002148:	4641                	li	a2,16
    8000214a:	17090593          	addi	a1,s2,368
    8000214e:	17098513          	addi	a0,s3,368
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	ce0080e7          	jalr	-800(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000215a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    8000215e:	854e                	mv	a0,s3
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002168:	0000f497          	auipc	s1,0xf
    8000216c:	57048493          	addi	s1,s1,1392 # 800116d8 <wait_lock>
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a72080e7          	jalr	-1422(ra) # 80000be4 <acquire>
  np->parent = p;
    8000217a:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b18080e7          	jalr	-1256(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002188:	854e                	mv	a0,s3
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	a5a080e7          	jalr	-1446(ra) # 80000be4 <acquire>
  np->last_runnable_time = ticks;
    80002192:	00007797          	auipc	a5,0x7
    80002196:	ebe7a783          	lw	a5,-322(a5) # 80009050 <ticks>
    8000219a:	02f9ae23          	sw	a5,60(s3)
  np->state = RUNNABLE;
    8000219e:	478d                	li	a5,3
    800021a0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021a4:	854e                	mv	a0,s3
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	af2080e7          	jalr	-1294(ra) # 80000c98 <release>
}
    800021ae:	8552                	mv	a0,s4
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	64e2                	ld	s1,24(sp)
    800021b6:	6942                	ld	s2,16(sp)
    800021b8:	69a2                	ld	s3,8(sp)
    800021ba:	6a02                	ld	s4,0(sp)
    800021bc:	6145                	addi	sp,sp,48
    800021be:	8082                	ret
    return -1;
    800021c0:	5a7d                	li	s4,-1
    800021c2:	b7f5                	j	800021ae <fork+0x132>

00000000800021c4 <sched>:
{
    800021c4:	7179                	addi	sp,sp,-48
    800021c6:	f406                	sd	ra,40(sp)
    800021c8:	f022                	sd	s0,32(sp)
    800021ca:	ec26                	sd	s1,24(sp)
    800021cc:	e84a                	sd	s2,16(sp)
    800021ce:	e44e                	sd	s3,8(sp)
    800021d0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	aa2080e7          	jalr	-1374(ra) # 80001c74 <myproc>
    800021da:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	98e080e7          	jalr	-1650(ra) # 80000b6a <holding>
    800021e4:	c53d                	beqz	a0,80002252 <sched+0x8e>
    800021e6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021e8:	2781                	sext.w	a5,a5
    800021ea:	079e                	slli	a5,a5,0x7
    800021ec:	0000f717          	auipc	a4,0xf
    800021f0:	0d470713          	addi	a4,a4,212 # 800112c0 <cpus>
    800021f4:	97ba                	add	a5,a5,a4
    800021f6:	5fb8                	lw	a4,120(a5)
    800021f8:	4785                	li	a5,1
    800021fa:	06f71463          	bne	a4,a5,80002262 <sched+0x9e>
  if(p->state == RUNNING)
    800021fe:	4c98                	lw	a4,24(s1)
    80002200:	4791                	li	a5,4
    80002202:	06f70863          	beq	a4,a5,80002272 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002206:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000220a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000220c:	ebbd                	bnez	a5,80002282 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000220e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002210:	0000f917          	auipc	s2,0xf
    80002214:	0b090913          	addi	s2,s2,176 # 800112c0 <cpus>
    80002218:	2781                	sext.w	a5,a5
    8000221a:	079e                	slli	a5,a5,0x7
    8000221c:	97ca                	add	a5,a5,s2
    8000221e:	07c7a983          	lw	s3,124(a5)
    80002222:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002224:	2581                	sext.w	a1,a1
    80002226:	059e                	slli	a1,a1,0x7
    80002228:	05a1                	addi	a1,a1,8
    8000222a:	95ca                	add	a1,a1,s2
    8000222c:	07848513          	addi	a0,s1,120
    80002230:	00000097          	auipc	ra,0x0
    80002234:	6e0080e7          	jalr	1760(ra) # 80002910 <swtch>
    80002238:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000223a:	2781                	sext.w	a5,a5
    8000223c:	079e                	slli	a5,a5,0x7
    8000223e:	993e                	add	s2,s2,a5
    80002240:	07392e23          	sw	s3,124(s2)
}
    80002244:	70a2                	ld	ra,40(sp)
    80002246:	7402                	ld	s0,32(sp)
    80002248:	64e2                	ld	s1,24(sp)
    8000224a:	6942                	ld	s2,16(sp)
    8000224c:	69a2                	ld	s3,8(sp)
    8000224e:	6145                	addi	sp,sp,48
    80002250:	8082                	ret
    panic("sched p->lock");
    80002252:	00006517          	auipc	a0,0x6
    80002256:	05e50513          	addi	a0,a0,94 # 800082b0 <digits+0x270>
    8000225a:	ffffe097          	auipc	ra,0xffffe
    8000225e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>
    panic("sched locks");
    80002262:	00006517          	auipc	a0,0x6
    80002266:	05e50513          	addi	a0,a0,94 # 800082c0 <digits+0x280>
    8000226a:	ffffe097          	auipc	ra,0xffffe
    8000226e:	2d4080e7          	jalr	724(ra) # 8000053e <panic>
    panic("sched running");
    80002272:	00006517          	auipc	a0,0x6
    80002276:	05e50513          	addi	a0,a0,94 # 800082d0 <digits+0x290>
    8000227a:	ffffe097          	auipc	ra,0xffffe
    8000227e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	05e50513          	addi	a0,a0,94 # 800082e0 <digits+0x2a0>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>

0000000080002292 <yield>:
{
    80002292:	1101                	addi	sp,sp,-32
    80002294:	ec06                	sd	ra,24(sp)
    80002296:	e822                	sd	s0,16(sp)
    80002298:	e426                	sd	s1,8(sp)
    8000229a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	9d8080e7          	jalr	-1576(ra) # 80001c74 <myproc>
    800022a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022ae:	478d                	li	a5,3
    800022b0:	cc9c                	sw	a5,24(s1)
  if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    800022b2:	589c                	lw	a5,48(s1)
    800022b4:	0000f717          	auipc	a4,0xf
    800022b8:	46c72703          	lw	a4,1132(a4) # 80011720 <proc+0x30>
    800022bc:	02f70163          	beq	a4,a5,800022de <yield+0x4c>
    800022c0:	0000f717          	auipc	a4,0xf
    800022c4:	5e072703          	lw	a4,1504(a4) # 800118a0 <proc+0x1b0>
    800022c8:	00f70b63          	beq	a4,a5,800022de <yield+0x4c>
    p->running_time = p->running_time + ticks - p->before_switch;
    800022cc:	44bc                	lw	a5,72(s1)
    800022ce:	00007717          	auipc	a4,0x7
    800022d2:	d8272703          	lw	a4,-638(a4) # 80009050 <ticks>
    800022d6:	9fb9                	addw	a5,a5,a4
    800022d8:	44f8                	lw	a4,76(s1)
    800022da:	9f99                	subw	a5,a5,a4
    800022dc:	c4bc                	sw	a5,72(s1)
  p->last_runnable_time = ticks;
    800022de:	00007797          	auipc	a5,0x7
    800022e2:	d727a783          	lw	a5,-654(a5) # 80009050 <ticks>
    800022e6:	dcdc                	sw	a5,60(s1)
  sched();
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	edc080e7          	jalr	-292(ra) # 800021c4 <sched>
  release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9a6080e7          	jalr	-1626(ra) # 80000c98 <release>
}
    800022fa:	60e2                	ld	ra,24(sp)
    800022fc:	6442                	ld	s0,16(sp)
    800022fe:	64a2                	ld	s1,8(sp)
    80002300:	6105                	addi	sp,sp,32
    80002302:	8082                	ret

0000000080002304 <pause_system>:
{
    80002304:	1141                	addi	sp,sp,-16
    80002306:	e406                	sd	ra,8(sp)
    80002308:	e022                	sd	s0,0(sp)
    8000230a:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    8000230c:	0025179b          	slliw	a5,a0,0x2
    80002310:	9fa9                	addw	a5,a5,a0
    80002312:	0017979b          	slliw	a5,a5,0x1
    80002316:	00007517          	auipc	a0,0x7
    8000231a:	d3a52503          	lw	a0,-710(a0) # 80009050 <ticks>
    8000231e:	9fa9                	addw	a5,a5,a0
    80002320:	00007717          	auipc	a4,0x7
    80002324:	d2f72223          	sw	a5,-732(a4) # 80009044 <finish>
  yield();
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	f6a080e7          	jalr	-150(ra) # 80002292 <yield>
}
    80002330:	4501                	li	a0,0
    80002332:	60a2                	ld	ra,8(sp)
    80002334:	6402                	ld	s0,0(sp)
    80002336:	0141                	addi	sp,sp,16
    80002338:	8082                	ret

000000008000233a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000233a:	7179                	addi	sp,sp,-48
    8000233c:	f406                	sd	ra,40(sp)
    8000233e:	f022                	sd	s0,32(sp)
    80002340:	ec26                	sd	s1,24(sp)
    80002342:	e84a                	sd	s2,16(sp)
    80002344:	e44e                	sd	s3,8(sp)
    80002346:	e052                	sd	s4,0(sp)
    80002348:	1800                	addi	s0,sp,48
    8000234a:	89aa                	mv	s3,a0
    8000234c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	926080e7          	jalr	-1754(ra) # 80001c74 <myproc>
    80002356:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	88c080e7          	jalr	-1908(ra) # 80000be4 <acquire>
  release(lk);
    80002360:	854a                	mv	a0,s2
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000236a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000236e:	4789                	li	a5,2
    80002370:	cc9c                	sw	a5,24(s1)
  if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80002372:	589c                	lw	a5,48(s1)
    80002374:	0000f717          	auipc	a4,0xf
    80002378:	3ac72703          	lw	a4,940(a4) # 80011720 <proc+0x30>
    8000237c:	02f70163          	beq	a4,a5,8000239e <sleep+0x64>
    80002380:	0000f717          	auipc	a4,0xf
    80002384:	52072703          	lw	a4,1312(a4) # 800118a0 <proc+0x1b0>
    80002388:	00f70b63          	beq	a4,a5,8000239e <sleep+0x64>
    p->running_time = p->running_time + ticks - p->before_switch;
    8000238c:	44bc                	lw	a5,72(s1)
    8000238e:	00007717          	auipc	a4,0x7
    80002392:	cc272703          	lw	a4,-830(a4) # 80009050 <ticks>
    80002396:	9fb9                	addw	a5,a5,a4
    80002398:	44f8                	lw	a4,76(s1)
    8000239a:	9f99                	subw	a5,a5,a4
    8000239c:	c4bc                	sw	a5,72(s1)
  }
  int sleep_start = ticks;
    8000239e:	00007997          	auipc	s3,0x7
    800023a2:	cb298993          	addi	s3,s3,-846 # 80009050 <ticks>
    800023a6:	0009aa03          	lw	s4,0(s3)
  sched();
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	e1a080e7          	jalr	-486(ra) # 800021c4 <sched>
  p->sleeping_time = ticks - sleep_start;
    800023b2:	0009a783          	lw	a5,0(s3)
    800023b6:	414787bb          	subw	a5,a5,s4
    800023ba:	c0bc                	sw	a5,64(s1)
  // Tidy up.
  p->chan = 0;
    800023bc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
  acquire(lk);
    800023ca:	854a                	mv	a0,s2
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	818080e7          	jalr	-2024(ra) # 80000be4 <acquire>
}
    800023d4:	70a2                	ld	ra,40(sp)
    800023d6:	7402                	ld	s0,32(sp)
    800023d8:	64e2                	ld	s1,24(sp)
    800023da:	6942                	ld	s2,16(sp)
    800023dc:	69a2                	ld	s3,8(sp)
    800023de:	6a02                	ld	s4,0(sp)
    800023e0:	6145                	addi	sp,sp,48
    800023e2:	8082                	ret

00000000800023e4 <wait>:
{
    800023e4:	715d                	addi	sp,sp,-80
    800023e6:	e486                	sd	ra,72(sp)
    800023e8:	e0a2                	sd	s0,64(sp)
    800023ea:	fc26                	sd	s1,56(sp)
    800023ec:	f84a                	sd	s2,48(sp)
    800023ee:	f44e                	sd	s3,40(sp)
    800023f0:	f052                	sd	s4,32(sp)
    800023f2:	ec56                	sd	s5,24(sp)
    800023f4:	e85a                	sd	s6,16(sp)
    800023f6:	e45e                	sd	s7,8(sp)
    800023f8:	e062                	sd	s8,0(sp)
    800023fa:	0880                	addi	s0,sp,80
    800023fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023fe:	00000097          	auipc	ra,0x0
    80002402:	876080e7          	jalr	-1930(ra) # 80001c74 <myproc>
    80002406:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002408:	0000f517          	auipc	a0,0xf
    8000240c:	2d050513          	addi	a0,a0,720 # 800116d8 <wait_lock>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
    havekids = 0;
    80002418:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000241a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	2d498993          	addi	s3,s3,724 # 800176f0 <tickslock>
        havekids = 1;
    80002424:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002426:	0000fc17          	auipc	s8,0xf
    8000242a:	2b2c0c13          	addi	s8,s8,690 # 800116d8 <wait_lock>
    havekids = 0;
    8000242e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	2c048493          	addi	s1,s1,704 # 800116f0 <proc>
    80002438:	a0bd                	j	800024a6 <wait+0xc2>
          pid = np->pid;
    8000243a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000243e:	000b0e63          	beqz	s6,8000245a <wait+0x76>
    80002442:	4691                	li	a3,4
    80002444:	02c48613          	addi	a2,s1,44
    80002448:	85da                	mv	a1,s6
    8000244a:	06893503          	ld	a0,104(s2)
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	224080e7          	jalr	548(ra) # 80001672 <copyout>
    80002456:	02054563          	bltz	a0,80002480 <wait+0x9c>
          freeproc(np);
    8000245a:	8526                	mv	a0,s1
    8000245c:	00000097          	auipc	ra,0x0
    80002460:	9ca080e7          	jalr	-1590(ra) # 80001e26 <freeproc>
          release(&np->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	832080e7          	jalr	-1998(ra) # 80000c98 <release>
          release(&wait_lock);
    8000246e:	0000f517          	auipc	a0,0xf
    80002472:	26a50513          	addi	a0,a0,618 # 800116d8 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
          return pid;
    8000247e:	a09d                	j	800024e4 <wait+0x100>
            release(&np->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
            release(&wait_lock);
    8000248a:	0000f517          	auipc	a0,0xf
    8000248e:	24e50513          	addi	a0,a0,590 # 800116d8 <wait_lock>
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
            return -1;
    8000249a:	59fd                	li	s3,-1
    8000249c:	a0a1                	j	800024e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000249e:	18048493          	addi	s1,s1,384
    800024a2:	03348463          	beq	s1,s3,800024ca <wait+0xe6>
      if(np->parent == p){
    800024a6:	68bc                	ld	a5,80(s1)
    800024a8:	ff279be3          	bne	a5,s2,8000249e <wait+0xba>
        acquire(&np->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024b6:	4c9c                	lw	a5,24(s1)
    800024b8:	f94781e3          	beq	a5,s4,8000243a <wait+0x56>
        release(&np->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7da080e7          	jalr	2010(ra) # 80000c98 <release>
        havekids = 1;
    800024c6:	8756                	mv	a4,s5
    800024c8:	bfd9                	j	8000249e <wait+0xba>
    if(!havekids || p->killed){
    800024ca:	c701                	beqz	a4,800024d2 <wait+0xee>
    800024cc:	02892783          	lw	a5,40(s2)
    800024d0:	c79d                	beqz	a5,800024fe <wait+0x11a>
      release(&wait_lock);
    800024d2:	0000f517          	auipc	a0,0xf
    800024d6:	20650513          	addi	a0,a0,518 # 800116d8 <wait_lock>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7be080e7          	jalr	1982(ra) # 80000c98 <release>
      return -1;
    800024e2:	59fd                	li	s3,-1
}
    800024e4:	854e                	mv	a0,s3
    800024e6:	60a6                	ld	ra,72(sp)
    800024e8:	6406                	ld	s0,64(sp)
    800024ea:	74e2                	ld	s1,56(sp)
    800024ec:	7942                	ld	s2,48(sp)
    800024ee:	79a2                	ld	s3,40(sp)
    800024f0:	7a02                	ld	s4,32(sp)
    800024f2:	6ae2                	ld	s5,24(sp)
    800024f4:	6b42                	ld	s6,16(sp)
    800024f6:	6ba2                	ld	s7,8(sp)
    800024f8:	6c02                	ld	s8,0(sp)
    800024fa:	6161                	addi	sp,sp,80
    800024fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024fe:	85e2                	mv	a1,s8
    80002500:	854a                	mv	a0,s2
    80002502:	00000097          	auipc	ra,0x0
    80002506:	e38080e7          	jalr	-456(ra) # 8000233a <sleep>
    havekids = 0;
    8000250a:	b715                	j	8000242e <wait+0x4a>

000000008000250c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000250c:	7139                	addi	sp,sp,-64
    8000250e:	fc06                	sd	ra,56(sp)
    80002510:	f822                	sd	s0,48(sp)
    80002512:	f426                	sd	s1,40(sp)
    80002514:	f04a                	sd	s2,32(sp)
    80002516:	ec4e                	sd	s3,24(sp)
    80002518:	e852                	sd	s4,16(sp)
    8000251a:	e456                	sd	s5,8(sp)
    8000251c:	e05a                	sd	s6,0(sp)
    8000251e:	0080                	addi	s0,sp,64
    80002520:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002522:	0000f497          	auipc	s1,0xf
    80002526:	1ce48493          	addi	s1,s1,462 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000252a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000252c:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    8000252e:	00007a97          	auipc	s5,0x7
    80002532:	b22a8a93          	addi	s5,s5,-1246 # 80009050 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002536:	00015917          	auipc	s2,0x15
    8000253a:	1ba90913          	addi	s2,s2,442 # 800176f0 <tickslock>
    8000253e:	a839                	j	8000255c <wakeup+0x50>
        p->state = RUNNABLE;
    80002540:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002544:	000aa783          	lw	a5,0(s5)
    80002548:	dcdc                	sw	a5,60(s1)

      }
      release(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	74c080e7          	jalr	1868(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002554:	18048493          	addi	s1,s1,384
    80002558:	03248463          	beq	s1,s2,80002580 <wakeup+0x74>
    if(p != myproc()){
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	718080e7          	jalr	1816(ra) # 80001c74 <myproc>
    80002564:	fea488e3          	beq	s1,a0,80002554 <wakeup+0x48>
      acquire(&p->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	67a080e7          	jalr	1658(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002572:	4c9c                	lw	a5,24(s1)
    80002574:	fd379be3          	bne	a5,s3,8000254a <wakeup+0x3e>
    80002578:	709c                	ld	a5,32(s1)
    8000257a:	fd4798e3          	bne	a5,s4,8000254a <wakeup+0x3e>
    8000257e:	b7c9                	j	80002540 <wakeup+0x34>
    }
  }
}
    80002580:	70e2                	ld	ra,56(sp)
    80002582:	7442                	ld	s0,48(sp)
    80002584:	74a2                	ld	s1,40(sp)
    80002586:	7902                	ld	s2,32(sp)
    80002588:	69e2                	ld	s3,24(sp)
    8000258a:	6a42                	ld	s4,16(sp)
    8000258c:	6aa2                	ld	s5,8(sp)
    8000258e:	6b02                	ld	s6,0(sp)
    80002590:	6121                	addi	sp,sp,64
    80002592:	8082                	ret

0000000080002594 <reparent>:
{
    80002594:	7179                	addi	sp,sp,-48
    80002596:	f406                	sd	ra,40(sp)
    80002598:	f022                	sd	s0,32(sp)
    8000259a:	ec26                	sd	s1,24(sp)
    8000259c:	e84a                	sd	s2,16(sp)
    8000259e:	e44e                	sd	s3,8(sp)
    800025a0:	e052                	sd	s4,0(sp)
    800025a2:	1800                	addi	s0,sp,48
    800025a4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	14a48493          	addi	s1,s1,330 # 800116f0 <proc>
      pp->parent = initproc;
    800025ae:	00007a17          	auipc	s4,0x7
    800025b2:	a9aa0a13          	addi	s4,s4,-1382 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025b6:	00015997          	auipc	s3,0x15
    800025ba:	13a98993          	addi	s3,s3,314 # 800176f0 <tickslock>
    800025be:	a029                	j	800025c8 <reparent+0x34>
    800025c0:	18048493          	addi	s1,s1,384
    800025c4:	01348d63          	beq	s1,s3,800025de <reparent+0x4a>
    if(pp->parent == p){
    800025c8:	68bc                	ld	a5,80(s1)
    800025ca:	ff279be3          	bne	a5,s2,800025c0 <reparent+0x2c>
      pp->parent = initproc;
    800025ce:	000a3503          	ld	a0,0(s4)
    800025d2:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	f38080e7          	jalr	-200(ra) # 8000250c <wakeup>
    800025dc:	b7d5                	j	800025c0 <reparent+0x2c>
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6a02                	ld	s4,0(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret

00000000800025ee <exit>:
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	e052                	sd	s4,0(sp)
    800025fc:	1800                	addi	s0,sp,48
    800025fe:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	674080e7          	jalr	1652(ra) # 80001c74 <myproc>
    80002608:	892a                	mv	s2,a0
  if(p == initproc)
    8000260a:	00007797          	auipc	a5,0x7
    8000260e:	a3e7b783          	ld	a5,-1474(a5) # 80009048 <initproc>
    80002612:	0e850493          	addi	s1,a0,232
    80002616:	16850993          	addi	s3,a0,360
    8000261a:	02a79363          	bne	a5,a0,80002640 <exit+0x52>
    panic("init exiting");
    8000261e:	00006517          	auipc	a0,0x6
    80002622:	cda50513          	addi	a0,a0,-806 # 800082f8 <digits+0x2b8>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	f18080e7          	jalr	-232(ra) # 8000053e <panic>
      fileclose(f);
    8000262e:	00002097          	auipc	ra,0x2
    80002632:	1fe080e7          	jalr	510(ra) # 8000482c <fileclose>
      p->ofile[fd] = 0;
    80002636:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000263a:	04a1                	addi	s1,s1,8
    8000263c:	01348563          	beq	s1,s3,80002646 <exit+0x58>
    if(p->ofile[fd]){
    80002640:	6088                	ld	a0,0(s1)
    80002642:	f575                	bnez	a0,8000262e <exit+0x40>
    80002644:	bfdd                	j	8000263a <exit+0x4c>
  begin_op();
    80002646:	00002097          	auipc	ra,0x2
    8000264a:	d1a080e7          	jalr	-742(ra) # 80004360 <begin_op>
  iput(p->cwd);
    8000264e:	16893503          	ld	a0,360(s2)
    80002652:	00001097          	auipc	ra,0x1
    80002656:	4f6080e7          	jalr	1270(ra) # 80003b48 <iput>
  end_op();
    8000265a:	00002097          	auipc	ra,0x2
    8000265e:	d86080e7          	jalr	-634(ra) # 800043e0 <end_op>
  p->cwd = 0;
    80002662:	16093423          	sd	zero,360(s2)
  acquire(&wait_lock);
    80002666:	0000f517          	auipc	a0,0xf
    8000266a:	07250513          	addi	a0,a0,114 # 800116d8 <wait_lock>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	576080e7          	jalr	1398(ra) # 80000be4 <acquire>
  if((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)){
    80002676:	03092783          	lw	a5,48(s2)
    8000267a:	0000f717          	auipc	a4,0xf
    8000267e:	0a672703          	lw	a4,166(a4) # 80011720 <proc+0x30>
    80002682:	0af70063          	beq	a4,a5,80002722 <exit+0x134>
    80002686:	0000f717          	auipc	a4,0xf
    8000268a:	21a72703          	lw	a4,538(a4) # 800118a0 <proc+0x1b0>
    8000268e:	08f70a63          	beq	a4,a5,80002722 <exit+0x134>
    program_time = program_time + p->running_time;
    80002692:	04892503          	lw	a0,72(s2)
    80002696:	00007717          	auipc	a4,0x7
    8000269a:	99670713          	addi	a4,a4,-1642 # 8000902c <program_time>
    8000269e:	431c                	lw	a5,0(a4)
    800026a0:	00a786bb          	addw	a3,a5,a0
    800026a4:	c314                	sw	a3,0(a4)
    cpu_utilization = (100*program_time)/(ticks-start_time);
    800026a6:	06400793          	li	a5,100
    800026aa:	02d787bb          	mulw	a5,a5,a3
    800026ae:	00007697          	auipc	a3,0x7
    800026b2:	9a26a683          	lw	a3,-1630(a3) # 80009050 <ticks>
    800026b6:	00007717          	auipc	a4,0x7
    800026ba:	97a72703          	lw	a4,-1670(a4) # 80009030 <start_time>
    800026be:	9e99                	subw	a3,a3,a4
    800026c0:	02d7d7bb          	divuw	a5,a5,a3
    800026c4:	00007717          	auipc	a4,0x7
    800026c8:	96f72223          	sw	a5,-1692(a4) # 80009028 <cpu_utilization>
    sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/(exited+1);
    800026cc:	00007617          	auipc	a2,0x7
    800026d0:	96862603          	lw	a2,-1688(a2) # 80009034 <exited>
    800026d4:	0016059b          	addiw	a1,a2,1
    800026d8:	00007797          	auipc	a5,0x7
    800026dc:	96878793          	addi	a5,a5,-1688 # 80009040 <sleeping_processes_mean>
    800026e0:	4394                	lw	a3,0(a5)
    800026e2:	02c686bb          	mulw	a3,a3,a2
    800026e6:	04092703          	lw	a4,64(s2)
    800026ea:	9eb9                	addw	a3,a3,a4
    800026ec:	02b6c6bb          	divw	a3,a3,a1
    800026f0:	c394                	sw	a3,0(a5)
    running_processes_mean = ((running_processes_mean*exited) + p->running_time)/(exited+1);
    800026f2:	00007797          	auipc	a5,0x7
    800026f6:	94a78793          	addi	a5,a5,-1718 # 8000903c <running_processes_mean>
    800026fa:	4398                	lw	a4,0(a5)
    800026fc:	02c7073b          	mulw	a4,a4,a2
    80002700:	9f29                	addw	a4,a4,a0
    80002702:	02b7473b          	divw	a4,a4,a1
    80002706:	c398                	sw	a4,0(a5)
    runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/(exited+1);
    80002708:	00007717          	auipc	a4,0x7
    8000270c:	93070713          	addi	a4,a4,-1744 # 80009038 <runnable_processes_mean>
    80002710:	431c                	lw	a5,0(a4)
    80002712:	02c787bb          	mulw	a5,a5,a2
    80002716:	04492683          	lw	a3,68(s2)
    8000271a:	9fb5                	addw	a5,a5,a3
    8000271c:	02b7c7bb          	divw	a5,a5,a1
    80002720:	c31c                	sw	a5,0(a4)
  exited = exited + 1;
    80002722:	00007717          	auipc	a4,0x7
    80002726:	91270713          	addi	a4,a4,-1774 # 80009034 <exited>
    8000272a:	431c                	lw	a5,0(a4)
    8000272c:	2785                	addiw	a5,a5,1
    8000272e:	c31c                	sw	a5,0(a4)
  reparent(p);
    80002730:	854a                	mv	a0,s2
    80002732:	00000097          	auipc	ra,0x0
    80002736:	e62080e7          	jalr	-414(ra) # 80002594 <reparent>
  wakeup(p->parent);
    8000273a:	05093503          	ld	a0,80(s2)
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	dce080e7          	jalr	-562(ra) # 8000250c <wakeup>
  acquire(&p->lock);
    80002746:	854a                	mv	a0,s2
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002750:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    80002754:	4795                	li	a5,5
    80002756:	00f92c23          	sw	a5,24(s2)
  if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    8000275a:	03092783          	lw	a5,48(s2)
    8000275e:	0000f717          	auipc	a4,0xf
    80002762:	fc272703          	lw	a4,-62(a4) # 80011720 <proc+0x30>
    80002766:	02f70463          	beq	a4,a5,8000278e <exit+0x1a0>
    8000276a:	0000f717          	auipc	a4,0xf
    8000276e:	13672703          	lw	a4,310(a4) # 800118a0 <proc+0x1b0>
    80002772:	00f70e63          	beq	a4,a5,8000278e <exit+0x1a0>
    p->running_time = p->running_time + ticks - p->before_switch;
    80002776:	04892783          	lw	a5,72(s2)
    8000277a:	00007717          	auipc	a4,0x7
    8000277e:	8d672703          	lw	a4,-1834(a4) # 80009050 <ticks>
    80002782:	9fb9                	addw	a5,a5,a4
    80002784:	04c92703          	lw	a4,76(s2)
    80002788:	9f99                	subw	a5,a5,a4
    8000278a:	04f92423          	sw	a5,72(s2)
  release(&wait_lock);
    8000278e:	0000f517          	auipc	a0,0xf
    80002792:	f4a50513          	addi	a0,a0,-182 # 800116d8 <wait_lock>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	502080e7          	jalr	1282(ra) # 80000c98 <release>
  sched();
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	a26080e7          	jalr	-1498(ra) # 800021c4 <sched>
  panic("zombie exit");
    800027a6:	00006517          	auipc	a0,0x6
    800027aa:	b6250513          	addi	a0,a0,-1182 # 80008308 <digits+0x2c8>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800027b6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027b6:	7179                	addi	sp,sp,-48
    800027b8:	f406                	sd	ra,40(sp)
    800027ba:	f022                	sd	s0,32(sp)
    800027bc:	ec26                	sd	s1,24(sp)
    800027be:	e84a                	sd	s2,16(sp)
    800027c0:	e44e                	sd	s3,8(sp)
    800027c2:	e052                	sd	s4,0(sp)
    800027c4:	1800                	addi	s0,sp,48
    800027c6:	84aa                	mv	s1,a0
    800027c8:	892e                	mv	s2,a1
    800027ca:	89b2                	mv	s3,a2
    800027cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	4a6080e7          	jalr	1190(ra) # 80001c74 <myproc>
  if(user_dst){
    800027d6:	c08d                	beqz	s1,800027f8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027d8:	86d2                	mv	a3,s4
    800027da:	864e                	mv	a2,s3
    800027dc:	85ca                	mv	a1,s2
    800027de:	7528                	ld	a0,104(a0)
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	e92080e7          	jalr	-366(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027e8:	70a2                	ld	ra,40(sp)
    800027ea:	7402                	ld	s0,32(sp)
    800027ec:	64e2                	ld	s1,24(sp)
    800027ee:	6942                	ld	s2,16(sp)
    800027f0:	69a2                	ld	s3,8(sp)
    800027f2:	6a02                	ld	s4,0(sp)
    800027f4:	6145                	addi	sp,sp,48
    800027f6:	8082                	ret
    memmove((char *)dst, src, len);
    800027f8:	000a061b          	sext.w	a2,s4
    800027fc:	85ce                	mv	a1,s3
    800027fe:	854a                	mv	a0,s2
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	540080e7          	jalr	1344(ra) # 80000d40 <memmove>
    return 0;
    80002808:	8526                	mv	a0,s1
    8000280a:	bff9                	j	800027e8 <either_copyout+0x32>

000000008000280c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000280c:	7179                	addi	sp,sp,-48
    8000280e:	f406                	sd	ra,40(sp)
    80002810:	f022                	sd	s0,32(sp)
    80002812:	ec26                	sd	s1,24(sp)
    80002814:	e84a                	sd	s2,16(sp)
    80002816:	e44e                	sd	s3,8(sp)
    80002818:	e052                	sd	s4,0(sp)
    8000281a:	1800                	addi	s0,sp,48
    8000281c:	892a                	mv	s2,a0
    8000281e:	84ae                	mv	s1,a1
    80002820:	89b2                	mv	s3,a2
    80002822:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	450080e7          	jalr	1104(ra) # 80001c74 <myproc>
  if(user_src){
    8000282c:	c08d                	beqz	s1,8000284e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000282e:	86d2                	mv	a3,s4
    80002830:	864e                	mv	a2,s3
    80002832:	85ca                	mv	a1,s2
    80002834:	7528                	ld	a0,104(a0)
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	ec8080e7          	jalr	-312(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000283e:	70a2                	ld	ra,40(sp)
    80002840:	7402                	ld	s0,32(sp)
    80002842:	64e2                	ld	s1,24(sp)
    80002844:	6942                	ld	s2,16(sp)
    80002846:	69a2                	ld	s3,8(sp)
    80002848:	6a02                	ld	s4,0(sp)
    8000284a:	6145                	addi	sp,sp,48
    8000284c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000284e:	000a061b          	sext.w	a2,s4
    80002852:	85ce                	mv	a1,s3
    80002854:	854a                	mv	a0,s2
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	4ea080e7          	jalr	1258(ra) # 80000d40 <memmove>
    return 0;
    8000285e:	8526                	mv	a0,s1
    80002860:	bff9                	j	8000283e <either_copyin+0x32>

0000000080002862 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002862:	715d                	addi	sp,sp,-80
    80002864:	e486                	sd	ra,72(sp)
    80002866:	e0a2                	sd	s0,64(sp)
    80002868:	fc26                	sd	s1,56(sp)
    8000286a:	f84a                	sd	s2,48(sp)
    8000286c:	f44e                	sd	s3,40(sp)
    8000286e:	f052                	sd	s4,32(sp)
    80002870:	ec56                	sd	s5,24(sp)
    80002872:	e85a                	sd	s6,16(sp)
    80002874:	e45e                	sd	s7,8(sp)
    80002876:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002878:	00006517          	auipc	a0,0x6
    8000287c:	99050513          	addi	a0,a0,-1648 # 80008208 <digits+0x1c8>
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	d08080e7          	jalr	-760(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002888:	0000f497          	auipc	s1,0xf
    8000288c:	fd848493          	addi	s1,s1,-40 # 80011860 <proc+0x170>
    80002890:	00015917          	auipc	s2,0x15
    80002894:	fd090913          	addi	s2,s2,-48 # 80017860 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002898:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000289a:	00006997          	auipc	s3,0x6
    8000289e:	a7e98993          	addi	s3,s3,-1410 # 80008318 <digits+0x2d8>
    printf("%d %s %s", p->pid, state, p->name);
    800028a2:	00006a97          	auipc	s5,0x6
    800028a6:	a7ea8a93          	addi	s5,s5,-1410 # 80008320 <digits+0x2e0>
    printf("\n");
    800028aa:	00006a17          	auipc	s4,0x6
    800028ae:	95ea0a13          	addi	s4,s4,-1698 # 80008208 <digits+0x1c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b2:	00006b97          	auipc	s7,0x6
    800028b6:	aa6b8b93          	addi	s7,s7,-1370 # 80008358 <states.1747>
    800028ba:	a00d                	j	800028dc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028bc:	ec06a583          	lw	a1,-320(a3)
    800028c0:	8556                	mv	a0,s5
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
    printf("\n");
    800028ca:	8552                	mv	a0,s4
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	cbc080e7          	jalr	-836(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d4:	18048493          	addi	s1,s1,384
    800028d8:	03248163          	beq	s1,s2,800028fa <procdump+0x98>
    if(p->state == UNUSED)
    800028dc:	86a6                	mv	a3,s1
    800028de:	ea84a783          	lw	a5,-344(s1)
    800028e2:	dbed                	beqz	a5,800028d4 <procdump+0x72>
      state = "???";
    800028e4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e6:	fcfb6be3          	bltu	s6,a5,800028bc <procdump+0x5a>
    800028ea:	1782                	slli	a5,a5,0x20
    800028ec:	9381                	srli	a5,a5,0x20
    800028ee:	078e                	slli	a5,a5,0x3
    800028f0:	97de                	add	a5,a5,s7
    800028f2:	6390                	ld	a2,0(a5)
    800028f4:	f661                	bnez	a2,800028bc <procdump+0x5a>
      state = "???";
    800028f6:	864e                	mv	a2,s3
    800028f8:	b7d1                	j	800028bc <procdump+0x5a>
  }
}
    800028fa:	60a6                	ld	ra,72(sp)
    800028fc:	6406                	ld	s0,64(sp)
    800028fe:	74e2                	ld	s1,56(sp)
    80002900:	7942                	ld	s2,48(sp)
    80002902:	79a2                	ld	s3,40(sp)
    80002904:	7a02                	ld	s4,32(sp)
    80002906:	6ae2                	ld	s5,24(sp)
    80002908:	6b42                	ld	s6,16(sp)
    8000290a:	6ba2                	ld	s7,8(sp)
    8000290c:	6161                	addi	sp,sp,80
    8000290e:	8082                	ret

0000000080002910 <swtch>:
    80002910:	00153023          	sd	ra,0(a0)
    80002914:	00253423          	sd	sp,8(a0)
    80002918:	e900                	sd	s0,16(a0)
    8000291a:	ed04                	sd	s1,24(a0)
    8000291c:	03253023          	sd	s2,32(a0)
    80002920:	03353423          	sd	s3,40(a0)
    80002924:	03453823          	sd	s4,48(a0)
    80002928:	03553c23          	sd	s5,56(a0)
    8000292c:	05653023          	sd	s6,64(a0)
    80002930:	05753423          	sd	s7,72(a0)
    80002934:	05853823          	sd	s8,80(a0)
    80002938:	05953c23          	sd	s9,88(a0)
    8000293c:	07a53023          	sd	s10,96(a0)
    80002940:	07b53423          	sd	s11,104(a0)
    80002944:	0005b083          	ld	ra,0(a1)
    80002948:	0085b103          	ld	sp,8(a1)
    8000294c:	6980                	ld	s0,16(a1)
    8000294e:	6d84                	ld	s1,24(a1)
    80002950:	0205b903          	ld	s2,32(a1)
    80002954:	0285b983          	ld	s3,40(a1)
    80002958:	0305ba03          	ld	s4,48(a1)
    8000295c:	0385ba83          	ld	s5,56(a1)
    80002960:	0405bb03          	ld	s6,64(a1)
    80002964:	0485bb83          	ld	s7,72(a1)
    80002968:	0505bc03          	ld	s8,80(a1)
    8000296c:	0585bc83          	ld	s9,88(a1)
    80002970:	0605bd03          	ld	s10,96(a1)
    80002974:	0685bd83          	ld	s11,104(a1)
    80002978:	8082                	ret

000000008000297a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000297a:	1141                	addi	sp,sp,-16
    8000297c:	e406                	sd	ra,8(sp)
    8000297e:	e022                	sd	s0,0(sp)
    80002980:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002982:	00006597          	auipc	a1,0x6
    80002986:	a0658593          	addi	a1,a1,-1530 # 80008388 <states.1747+0x30>
    8000298a:	00015517          	auipc	a0,0x15
    8000298e:	d6650513          	addi	a0,a0,-666 # 800176f0 <tickslock>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	1c2080e7          	jalr	450(ra) # 80000b54 <initlock>
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e422                	sd	s0,8(sp)
    800029a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a8:	00003797          	auipc	a5,0x3
    800029ac:	49878793          	addi	a5,a5,1176 # 80005e40 <kernelvec>
    800029b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b4:	6422                	ld	s0,8(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e406                	sd	ra,8(sp)
    800029be:	e022                	sd	s0,0(sp)
    800029c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	2b2080e7          	jalr	690(ra) # 80001c74 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029d4:	00004617          	auipc	a2,0x4
    800029d8:	62c60613          	addi	a2,a2,1580 # 80007000 <_trampoline>
    800029dc:	00004697          	auipc	a3,0x4
    800029e0:	62468693          	addi	a3,a3,1572 # 80007000 <_trampoline>
    800029e4:	8e91                	sub	a3,a3,a2
    800029e6:	040007b7          	lui	a5,0x4000
    800029ea:	17fd                	addi	a5,a5,-1
    800029ec:	07b2                	slli	a5,a5,0xc
    800029ee:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f4:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f6:	180026f3          	csrr	a3,satp
    800029fa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029fc:	7938                	ld	a4,112(a0)
    800029fe:	6d34                	ld	a3,88(a0)
    80002a00:	6585                	lui	a1,0x1
    80002a02:	96ae                	add	a3,a3,a1
    80002a04:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a06:	7938                	ld	a4,112(a0)
    80002a08:	00000697          	auipc	a3,0x0
    80002a0c:	13868693          	addi	a3,a3,312 # 80002b40 <usertrap>
    80002a10:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a12:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a14:	8692                	mv	a3,tp
    80002a16:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a1c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a20:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a28:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2a:	6f18                	ld	a4,24(a4)
    80002a2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a30:	752c                	ld	a1,104(a0)
    80002a32:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a34:	00004717          	auipc	a4,0x4
    80002a38:	65c70713          	addi	a4,a4,1628 # 80007090 <userret>
    80002a3c:	8f11                	sub	a4,a4,a2
    80002a3e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a40:	577d                	li	a4,-1
    80002a42:	177e                	slli	a4,a4,0x3f
    80002a44:	8dd9                	or	a1,a1,a4
    80002a46:	02000537          	lui	a0,0x2000
    80002a4a:	157d                	addi	a0,a0,-1
    80002a4c:	0536                	slli	a0,a0,0xd
    80002a4e:	9782                	jalr	a5
}
    80002a50:	60a2                	ld	ra,8(sp)
    80002a52:	6402                	ld	s0,0(sp)
    80002a54:	0141                	addi	sp,sp,16
    80002a56:	8082                	ret

0000000080002a58 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a58:	1101                	addi	sp,sp,-32
    80002a5a:	ec06                	sd	ra,24(sp)
    80002a5c:	e822                	sd	s0,16(sp)
    80002a5e:	e426                	sd	s1,8(sp)
    80002a60:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a62:	00015497          	auipc	s1,0x15
    80002a66:	c8e48493          	addi	s1,s1,-882 # 800176f0 <tickslock>
    80002a6a:	8526                	mv	a0,s1
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	178080e7          	jalr	376(ra) # 80000be4 <acquire>
  ticks++;
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	5dc50513          	addi	a0,a0,1500 # 80009050 <ticks>
    80002a7c:	411c                	lw	a5,0(a0)
    80002a7e:	2785                	addiw	a5,a5,1
    80002a80:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	a8a080e7          	jalr	-1398(ra) # 8000250c <wakeup>
  release(&tickslock);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	20c080e7          	jalr	524(ra) # 80000c98 <release>
}
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret

0000000080002a9e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aac:	00074d63          	bltz	a4,80002ac6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ab0:	57fd                	li	a5,-1
    80002ab2:	17fe                	slli	a5,a5,0x3f
    80002ab4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ab6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ab8:	06f70363          	beq	a4,a5,80002b1e <devintr+0x80>
  }
}
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	64a2                	ld	s1,8(sp)
    80002ac2:	6105                	addi	sp,sp,32
    80002ac4:	8082                	ret
     (scause & 0xff) == 9){
    80002ac6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002aca:	46a5                	li	a3,9
    80002acc:	fed792e3          	bne	a5,a3,80002ab0 <devintr+0x12>
    int irq = plic_claim();
    80002ad0:	00003097          	auipc	ra,0x3
    80002ad4:	478080e7          	jalr	1144(ra) # 80005f48 <plic_claim>
    80002ad8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ada:	47a9                	li	a5,10
    80002adc:	02f50763          	beq	a0,a5,80002b0a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ae0:	4785                	li	a5,1
    80002ae2:	02f50963          	beq	a0,a5,80002b14 <devintr+0x76>
    return 1;
    80002ae6:	4505                	li	a0,1
    } else if(irq){
    80002ae8:	d8f1                	beqz	s1,80002abc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002aea:	85a6                	mv	a1,s1
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	8a450513          	addi	a0,a0,-1884 # 80008390 <states.1747+0x38>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a94080e7          	jalr	-1388(ra) # 80000588 <printf>
      plic_complete(irq);
    80002afc:	8526                	mv	a0,s1
    80002afe:	00003097          	auipc	ra,0x3
    80002b02:	46e080e7          	jalr	1134(ra) # 80005f6c <plic_complete>
    return 1;
    80002b06:	4505                	li	a0,1
    80002b08:	bf55                	j	80002abc <devintr+0x1e>
      uartintr();
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	e9e080e7          	jalr	-354(ra) # 800009a8 <uartintr>
    80002b12:	b7ed                	j	80002afc <devintr+0x5e>
      virtio_disk_intr();
    80002b14:	00004097          	auipc	ra,0x4
    80002b18:	938080e7          	jalr	-1736(ra) # 8000644c <virtio_disk_intr>
    80002b1c:	b7c5                	j	80002afc <devintr+0x5e>
    if(cpuid() == 0){
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	12a080e7          	jalr	298(ra) # 80001c48 <cpuid>
    80002b26:	c901                	beqz	a0,80002b36 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b28:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b2c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b2e:	14479073          	csrw	sip,a5
    return 2;
    80002b32:	4509                	li	a0,2
    80002b34:	b761                	j	80002abc <devintr+0x1e>
      clockintr();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	f22080e7          	jalr	-222(ra) # 80002a58 <clockintr>
    80002b3e:	b7ed                	j	80002b28 <devintr+0x8a>

0000000080002b40 <usertrap>:
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b4e:	1007f793          	andi	a5,a5,256
    80002b52:	e3a5                	bnez	a5,80002bb2 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b54:	00003797          	auipc	a5,0x3
    80002b58:	2ec78793          	addi	a5,a5,748 # 80005e40 <kernelvec>
    80002b5c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	114080e7          	jalr	276(ra) # 80001c74 <myproc>
    80002b68:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b6a:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6c:	14102773          	csrr	a4,sepc
    80002b70:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b72:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b76:	47a1                	li	a5,8
    80002b78:	04f71b63          	bne	a4,a5,80002bce <usertrap+0x8e>
    if(p->killed)
    80002b7c:	551c                	lw	a5,40(a0)
    80002b7e:	e3b1                	bnez	a5,80002bc2 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002b80:	78b8                	ld	a4,112(s1)
    80002b82:	6f1c                	ld	a5,24(a4)
    80002b84:	0791                	addi	a5,a5,4
    80002b86:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b90:	10079073          	csrw	sstatus,a5
    syscall();
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	29a080e7          	jalr	666(ra) # 80002e2e <syscall>
  if(p->killed)
    80002b9c:	549c                	lw	a5,40(s1)
    80002b9e:	e7b5                	bnez	a5,80002c0a <usertrap+0xca>
  usertrapret();
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	e1a080e7          	jalr	-486(ra) # 800029ba <usertrapret>
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret
    panic("usertrap: not from user mode");
    80002bb2:	00005517          	auipc	a0,0x5
    80002bb6:	7fe50513          	addi	a0,a0,2046 # 800083b0 <states.1747+0x58>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>
      exit(-1);
    80002bc2:	557d                	li	a0,-1
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	a2a080e7          	jalr	-1494(ra) # 800025ee <exit>
    80002bcc:	bf55                	j	80002b80 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	ed0080e7          	jalr	-304(ra) # 80002a9e <devintr>
    80002bd6:	f179                	bnez	a0,80002b9c <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bdc:	5890                	lw	a2,48(s1)
    80002bde:	00005517          	auipc	a0,0x5
    80002be2:	7f250513          	addi	a0,a0,2034 # 800083d0 <states.1747+0x78>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	9a2080e7          	jalr	-1630(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf6:	00006517          	auipc	a0,0x6
    80002bfa:	80a50513          	addi	a0,a0,-2038 # 80008400 <states.1747+0xa8>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	98a080e7          	jalr	-1654(ra) # 80000588 <printf>
    p->killed = 1;
    80002c06:	4785                	li	a5,1
    80002c08:	d49c                	sw	a5,40(s1)
    exit(-1); 
    80002c0a:	557d                	li	a0,-1
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	9e2080e7          	jalr	-1566(ra) # 800025ee <exit>
    80002c14:	b771                	j	80002ba0 <usertrap+0x60>

0000000080002c16 <kerneltrap>:
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c2c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c30:	1004f793          	andi	a5,s1,256
    80002c34:	c78d                	beqz	a5,80002c5e <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c3a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c3c:	eb8d                	bnez	a5,80002c6e <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	e60080e7          	jalr	-416(ra) # 80002a9e <devintr>
    80002c46:	cd05                	beqz	a0,80002c7e <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c48:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c4c:	10049073          	csrw	sstatus,s1
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	7c250513          	addi	a0,a0,1986 # 80008420 <states.1747+0xc8>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	7da50513          	addi	a0,a0,2010 # 80008448 <states.1747+0xf0>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c7e:	85ce                	mv	a1,s3
    80002c80:	00005517          	auipc	a0,0x5
    80002c84:	7e850513          	addi	a0,a0,2024 # 80008468 <states.1747+0x110>
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	900080e7          	jalr	-1792(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	7e050513          	addi	a0,a0,2016 # 80008478 <states.1747+0x120>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	8e8080e7          	jalr	-1816(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	7e850513          	addi	a0,a0,2024 # 80008490 <states.1747+0x138>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>

0000000080002cb8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	fb0080e7          	jalr	-80(ra) # 80001c74 <myproc>
  switch (n) {
    80002ccc:	4795                	li	a5,5
    80002cce:	0497e163          	bltu	a5,s1,80002d10 <argraw+0x58>
    80002cd2:	048a                	slli	s1,s1,0x2
    80002cd4:	00005717          	auipc	a4,0x5
    80002cd8:	7f470713          	addi	a4,a4,2036 # 800084c8 <states.1747+0x170>
    80002cdc:	94ba                	add	s1,s1,a4
    80002cde:	409c                	lw	a5,0(s1)
    80002ce0:	97ba                	add	a5,a5,a4
    80002ce2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ce4:	793c                	ld	a5,112(a0)
    80002ce6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	64a2                	ld	s1,8(sp)
    80002cee:	6105                	addi	sp,sp,32
    80002cf0:	8082                	ret
    return p->trapframe->a1;
    80002cf2:	793c                	ld	a5,112(a0)
    80002cf4:	7fa8                	ld	a0,120(a5)
    80002cf6:	bfcd                	j	80002ce8 <argraw+0x30>
    return p->trapframe->a2;
    80002cf8:	793c                	ld	a5,112(a0)
    80002cfa:	63c8                	ld	a0,128(a5)
    80002cfc:	b7f5                	j	80002ce8 <argraw+0x30>
    return p->trapframe->a3;
    80002cfe:	793c                	ld	a5,112(a0)
    80002d00:	67c8                	ld	a0,136(a5)
    80002d02:	b7dd                	j	80002ce8 <argraw+0x30>
    return p->trapframe->a4;
    80002d04:	793c                	ld	a5,112(a0)
    80002d06:	6bc8                	ld	a0,144(a5)
    80002d08:	b7c5                	j	80002ce8 <argraw+0x30>
    return p->trapframe->a5;
    80002d0a:	793c                	ld	a5,112(a0)
    80002d0c:	6fc8                	ld	a0,152(a5)
    80002d0e:	bfe9                	j	80002ce8 <argraw+0x30>
  panic("argraw");
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	79050513          	addi	a0,a0,1936 # 800084a0 <states.1747+0x148>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>

0000000080002d20 <fetchaddr>:
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	e04a                	sd	s2,0(sp)
    80002d2a:	1000                	addi	s0,sp,32
    80002d2c:	84aa                	mv	s1,a0
    80002d2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	f44080e7          	jalr	-188(ra) # 80001c74 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d38:	713c                	ld	a5,96(a0)
    80002d3a:	02f4f863          	bgeu	s1,a5,80002d6a <fetchaddr+0x4a>
    80002d3e:	00848713          	addi	a4,s1,8
    80002d42:	02e7e663          	bltu	a5,a4,80002d6e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d46:	46a1                	li	a3,8
    80002d48:	8626                	mv	a2,s1
    80002d4a:	85ca                	mv	a1,s2
    80002d4c:	7528                	ld	a0,104(a0)
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	9b0080e7          	jalr	-1616(ra) # 800016fe <copyin>
    80002d56:	00a03533          	snez	a0,a0
    80002d5a:	40a00533          	neg	a0,a0
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	64a2                	ld	s1,8(sp)
    80002d64:	6902                	ld	s2,0(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret
    return -1;
    80002d6a:	557d                	li	a0,-1
    80002d6c:	bfcd                	j	80002d5e <fetchaddr+0x3e>
    80002d6e:	557d                	li	a0,-1
    80002d70:	b7fd                	j	80002d5e <fetchaddr+0x3e>

0000000080002d72 <fetchstr>:
{
    80002d72:	7179                	addi	sp,sp,-48
    80002d74:	f406                	sd	ra,40(sp)
    80002d76:	f022                	sd	s0,32(sp)
    80002d78:	ec26                	sd	s1,24(sp)
    80002d7a:	e84a                	sd	s2,16(sp)
    80002d7c:	e44e                	sd	s3,8(sp)
    80002d7e:	1800                	addi	s0,sp,48
    80002d80:	892a                	mv	s2,a0
    80002d82:	84ae                	mv	s1,a1
    80002d84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	eee080e7          	jalr	-274(ra) # 80001c74 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d8e:	86ce                	mv	a3,s3
    80002d90:	864a                	mv	a2,s2
    80002d92:	85a6                	mv	a1,s1
    80002d94:	7528                	ld	a0,104(a0)
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	9f4080e7          	jalr	-1548(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d9e:	00054763          	bltz	a0,80002dac <fetchstr+0x3a>
  return strlen(buf);
    80002da2:	8526                	mv	a0,s1
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	0c0080e7          	jalr	192(ra) # 80000e64 <strlen>
}
    80002dac:	70a2                	ld	ra,40(sp)
    80002dae:	7402                	ld	s0,32(sp)
    80002db0:	64e2                	ld	s1,24(sp)
    80002db2:	6942                	ld	s2,16(sp)
    80002db4:	69a2                	ld	s3,8(sp)
    80002db6:	6145                	addi	sp,sp,48
    80002db8:	8082                	ret

0000000080002dba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	1000                	addi	s0,sp,32
    80002dc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	ef2080e7          	jalr	-270(ra) # 80002cb8 <argraw>
    80002dce:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dd0:	4501                	li	a0,0
    80002dd2:	60e2                	ld	ra,24(sp)
    80002dd4:	6442                	ld	s0,16(sp)
    80002dd6:	64a2                	ld	s1,8(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	e426                	sd	s1,8(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	ed0080e7          	jalr	-304(ra) # 80002cb8 <argraw>
    80002df0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002df2:	4501                	li	a0,0
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	64a2                	ld	s1,8(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	e04a                	sd	s2,0(sp)
    80002e08:	1000                	addi	s0,sp,32
    80002e0a:	84ae                	mv	s1,a1
    80002e0c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	eaa080e7          	jalr	-342(ra) # 80002cb8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e16:	864a                	mv	a2,s2
    80002e18:	85a6                	mv	a1,s1
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	f58080e7          	jalr	-168(ra) # 80002d72 <fetchstr>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	64a2                	ld	s1,8(sp)
    80002e28:	6902                	ld	s2,0(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	e04a                	sd	s2,0(sp)
    80002e38:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	e3a080e7          	jalr	-454(ra) # 80001c74 <myproc>
    80002e42:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e44:	07053903          	ld	s2,112(a0)
    80002e48:	0a893783          	ld	a5,168(s2)
    80002e4c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e50:	37fd                	addiw	a5,a5,-1
    80002e52:	475d                	li	a4,23
    80002e54:	00f76f63          	bltu	a4,a5,80002e72 <syscall+0x44>
    80002e58:	00369713          	slli	a4,a3,0x3
    80002e5c:	00005797          	auipc	a5,0x5
    80002e60:	68478793          	addi	a5,a5,1668 # 800084e0 <syscalls>
    80002e64:	97ba                	add	a5,a5,a4
    80002e66:	639c                	ld	a5,0(a5)
    80002e68:	c789                	beqz	a5,80002e72 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e6a:	9782                	jalr	a5
    80002e6c:	06a93823          	sd	a0,112(s2)
    80002e70:	a839                	j	80002e8e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e72:	17048613          	addi	a2,s1,368
    80002e76:	588c                	lw	a1,48(s1)
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	63050513          	addi	a0,a0,1584 # 800084a8 <states.1747+0x150>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	708080e7          	jalr	1800(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e88:	78bc                	ld	a5,112(s1)
    80002e8a:	577d                	li	a4,-1
    80002e8c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	64a2                	ld	s1,8(sp)
    80002e94:	6902                	ld	s2,0(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ea2:	fec40593          	addi	a1,s0,-20
    80002ea6:	4501                	li	a0,0
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	f12080e7          	jalr	-238(ra) # 80002dba <argint>
    return -1;
    80002eb0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eb2:	00054963          	bltz	a0,80002ec4 <sys_exit+0x2a>
  exit(n);
    80002eb6:	fec42503          	lw	a0,-20(s0)
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	734080e7          	jalr	1844(ra) # 800025ee <exit>
  return 0;  // not reached
    80002ec2:	4781                	li	a5,0
}
    80002ec4:	853e                	mv	a0,a5
    80002ec6:	60e2                	ld	ra,24(sp)
    80002ec8:	6442                	ld	s0,16(sp)
    80002eca:	6105                	addi	sp,sp,32
    80002ecc:	8082                	ret

0000000080002ece <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ece:	1141                	addi	sp,sp,-16
    80002ed0:	e406                	sd	ra,8(sp)
    80002ed2:	e022                	sd	s0,0(sp)
    80002ed4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	d9e080e7          	jalr	-610(ra) # 80001c74 <myproc>
}
    80002ede:	5908                	lw	a0,48(a0)
    80002ee0:	60a2                	ld	ra,8(sp)
    80002ee2:	6402                	ld	s0,0(sp)
    80002ee4:	0141                	addi	sp,sp,16
    80002ee6:	8082                	ret

0000000080002ee8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ee8:	1141                	addi	sp,sp,-16
    80002eea:	e406                	sd	ra,8(sp)
    80002eec:	e022                	sd	s0,0(sp)
    80002eee:	0800                	addi	s0,sp,16
  return fork();
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	18c080e7          	jalr	396(ra) # 8000207c <fork>
}
    80002ef8:	60a2                	ld	ra,8(sp)
    80002efa:	6402                	ld	s0,0(sp)
    80002efc:	0141                	addi	sp,sp,16
    80002efe:	8082                	ret

0000000080002f00 <sys_wait>:

uint64
sys_wait(void)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f08:	fe840593          	addi	a1,s0,-24
    80002f0c:	4501                	li	a0,0
    80002f0e:	00000097          	auipc	ra,0x0
    80002f12:	ece080e7          	jalr	-306(ra) # 80002ddc <argaddr>
    80002f16:	87aa                	mv	a5,a0
    return -1;
    80002f18:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f1a:	0007c863          	bltz	a5,80002f2a <sys_wait+0x2a>
  return wait(p);
    80002f1e:	fe843503          	ld	a0,-24(s0)
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	4c2080e7          	jalr	1218(ra) # 800023e4 <wait>
}
    80002f2a:	60e2                	ld	ra,24(sp)
    80002f2c:	6442                	ld	s0,16(sp)
    80002f2e:	6105                	addi	sp,sp,32
    80002f30:	8082                	ret

0000000080002f32 <sys_print_stats>:

void
sys_print_stats(void)
{
    80002f32:	1141                	addi	sp,sp,-16
    80002f34:	e406                	sd	ra,8(sp)
    80002f36:	e022                	sd	s0,0(sp)
    80002f38:	0800                	addi	s0,sp,16
  return print_stats();
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	aaa080e7          	jalr	-1366(ra) # 800019e4 <print_stats>
}
    80002f42:	60a2                	ld	ra,8(sp)
    80002f44:	6402                	ld	s0,0(sp)
    80002f46:	0141                	addi	sp,sp,16
    80002f48:	8082                	ret

0000000080002f4a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f4a:	7179                	addi	sp,sp,-48
    80002f4c:	f406                	sd	ra,40(sp)
    80002f4e:	f022                	sd	s0,32(sp)
    80002f50:	ec26                	sd	s1,24(sp)
    80002f52:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f54:	fdc40593          	addi	a1,s0,-36
    80002f58:	4501                	li	a0,0
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	e60080e7          	jalr	-416(ra) # 80002dba <argint>
    80002f62:	87aa                	mv	a5,a0
    return -1;
    80002f64:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f66:	0207c063          	bltz	a5,80002f86 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	d0a080e7          	jalr	-758(ra) # 80001c74 <myproc>
    80002f72:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80002f74:	fdc42503          	lw	a0,-36(s0)
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	090080e7          	jalr	144(ra) # 80002008 <growproc>
    80002f80:	00054863          	bltz	a0,80002f90 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f84:	8526                	mv	a0,s1
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6145                	addi	sp,sp,48
    80002f8e:	8082                	ret
    return -1;
    80002f90:	557d                	li	a0,-1
    80002f92:	bfd5                	j	80002f86 <sys_sbrk+0x3c>

0000000080002f94 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f94:	7139                	addi	sp,sp,-64
    80002f96:	fc06                	sd	ra,56(sp)
    80002f98:	f822                	sd	s0,48(sp)
    80002f9a:	f426                	sd	s1,40(sp)
    80002f9c:	f04a                	sd	s2,32(sp)
    80002f9e:	ec4e                	sd	s3,24(sp)
    80002fa0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fa2:	fcc40593          	addi	a1,s0,-52
    80002fa6:	4501                	li	a0,0
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	e12080e7          	jalr	-494(ra) # 80002dba <argint>
    return -1;
    80002fb0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fb2:	06054563          	bltz	a0,8000301c <sys_sleep+0x88>
  acquire(&tickslock);
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	73a50513          	addi	a0,a0,1850 # 800176f0 <tickslock>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	c26080e7          	jalr	-986(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002fc6:	00006917          	auipc	s2,0x6
    80002fca:	08a92903          	lw	s2,138(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002fce:	fcc42783          	lw	a5,-52(s0)
    80002fd2:	cf85                	beqz	a5,8000300a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fd4:	00014997          	auipc	s3,0x14
    80002fd8:	71c98993          	addi	s3,s3,1820 # 800176f0 <tickslock>
    80002fdc:	00006497          	auipc	s1,0x6
    80002fe0:	07448493          	addi	s1,s1,116 # 80009050 <ticks>
    if(myproc()->killed){
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	c90080e7          	jalr	-880(ra) # 80001c74 <myproc>
    80002fec:	551c                	lw	a5,40(a0)
    80002fee:	ef9d                	bnez	a5,8000302c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ff0:	85ce                	mv	a1,s3
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	346080e7          	jalr	838(ra) # 8000233a <sleep>
  while(ticks - ticks0 < n){
    80002ffc:	409c                	lw	a5,0(s1)
    80002ffe:	412787bb          	subw	a5,a5,s2
    80003002:	fcc42703          	lw	a4,-52(s0)
    80003006:	fce7efe3          	bltu	a5,a4,80002fe4 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000300a:	00014517          	auipc	a0,0x14
    8000300e:	6e650513          	addi	a0,a0,1766 # 800176f0 <tickslock>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
  return 0;
    8000301a:	4781                	li	a5,0
}
    8000301c:	853e                	mv	a0,a5
    8000301e:	70e2                	ld	ra,56(sp)
    80003020:	7442                	ld	s0,48(sp)
    80003022:	74a2                	ld	s1,40(sp)
    80003024:	7902                	ld	s2,32(sp)
    80003026:	69e2                	ld	s3,24(sp)
    80003028:	6121                	addi	sp,sp,64
    8000302a:	8082                	ret
      release(&tickslock);
    8000302c:	00014517          	auipc	a0,0x14
    80003030:	6c450513          	addi	a0,a0,1732 # 800176f0 <tickslock>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
      return -1;
    8000303c:	57fd                	li	a5,-1
    8000303e:	bff9                	j	8000301c <sys_sleep+0x88>

0000000080003040 <sys_kill>:

uint64
sys_kill(void)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003048:	fec40593          	addi	a1,s0,-20
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	d6c080e7          	jalr	-660(ra) # 80002dba <argint>
    80003056:	87aa                	mv	a5,a0
    return -1;
    80003058:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000305a:	0007c863          	bltz	a5,8000306a <sys_kill+0x2a>
  return kill(pid);
    8000305e:	fec42503          	lw	a0,-20(s0)
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	872080e7          	jalr	-1934(ra) # 800018d4 <kill>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003072:	1141                	addi	sp,sp,-16
    80003074:	e406                	sd	ra,8(sp)
    80003076:	e022                	sd	s0,0(sp)
    80003078:	0800                	addi	s0,sp,16
  return kill_system();
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	8d6080e7          	jalr	-1834(ra) # 80001950 <kill_system>
}
    80003082:	60a2                	ld	ra,8(sp)
    80003084:	6402                	ld	s0,0(sp)
    80003086:	0141                	addi	sp,sp,16
    80003088:	8082                	ret

000000008000308a <sys_pause_system>:


uint64
sys_pause_system(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80003092:	fec40593          	addi	a1,s0,-20
    80003096:	4501                	li	a0,0
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	d22080e7          	jalr	-734(ra) # 80002dba <argint>
    800030a0:	87aa                	mv	a5,a0
    return -1;
    800030a2:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    800030a4:	0007c863          	bltz	a5,800030b4 <sys_pause_system+0x2a>
  return pause_system(time);
    800030a8:	fec42503          	lw	a0,-20(s0)
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	258080e7          	jalr	600(ra) # 80002304 <pause_system>
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	62a50513          	addi	a0,a0,1578 # 800176f0 <tickslock>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	b16080e7          	jalr	-1258(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030d6:	00006497          	auipc	s1,0x6
    800030da:	f7a4a483          	lw	s1,-134(s1) # 80009050 <ticks>
  release(&tickslock);
    800030de:	00014517          	auipc	a0,0x14
    800030e2:	61250513          	addi	a0,a0,1554 # 800176f0 <tickslock>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	bb2080e7          	jalr	-1102(ra) # 80000c98 <release>
  return xticks;
}
    800030ee:	02049513          	slli	a0,s1,0x20
    800030f2:	9101                	srli	a0,a0,0x20
    800030f4:	60e2                	ld	ra,24(sp)
    800030f6:	6442                	ld	s0,16(sp)
    800030f8:	64a2                	ld	s1,8(sp)
    800030fa:	6105                	addi	sp,sp,32
    800030fc:	8082                	ret

00000000800030fe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030fe:	7179                	addi	sp,sp,-48
    80003100:	f406                	sd	ra,40(sp)
    80003102:	f022                	sd	s0,32(sp)
    80003104:	ec26                	sd	s1,24(sp)
    80003106:	e84a                	sd	s2,16(sp)
    80003108:	e44e                	sd	s3,8(sp)
    8000310a:	e052                	sd	s4,0(sp)
    8000310c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000310e:	00005597          	auipc	a1,0x5
    80003112:	49a58593          	addi	a1,a1,1178 # 800085a8 <syscalls+0xc8>
    80003116:	00014517          	auipc	a0,0x14
    8000311a:	5f250513          	addi	a0,a0,1522 # 80017708 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	a36080e7          	jalr	-1482(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003126:	0001c797          	auipc	a5,0x1c
    8000312a:	5e278793          	addi	a5,a5,1506 # 8001f708 <bcache+0x8000>
    8000312e:	0001d717          	auipc	a4,0x1d
    80003132:	84270713          	addi	a4,a4,-1982 # 8001f970 <bcache+0x8268>
    80003136:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000313a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000313e:	00014497          	auipc	s1,0x14
    80003142:	5e248493          	addi	s1,s1,1506 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    80003146:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003148:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000314a:	00005a17          	auipc	s4,0x5
    8000314e:	466a0a13          	addi	s4,s4,1126 # 800085b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003152:	2b893783          	ld	a5,696(s2)
    80003156:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003158:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000315c:	85d2                	mv	a1,s4
    8000315e:	01048513          	addi	a0,s1,16
    80003162:	00001097          	auipc	ra,0x1
    80003166:	4bc080e7          	jalr	1212(ra) # 8000461e <initsleeplock>
    bcache.head.next->prev = b;
    8000316a:	2b893783          	ld	a5,696(s2)
    8000316e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003170:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003174:	45848493          	addi	s1,s1,1112
    80003178:	fd349de3          	bne	s1,s3,80003152 <binit+0x54>
  }
}
    8000317c:	70a2                	ld	ra,40(sp)
    8000317e:	7402                	ld	s0,32(sp)
    80003180:	64e2                	ld	s1,24(sp)
    80003182:	6942                	ld	s2,16(sp)
    80003184:	69a2                	ld	s3,8(sp)
    80003186:	6a02                	ld	s4,0(sp)
    80003188:	6145                	addi	sp,sp,48
    8000318a:	8082                	ret

000000008000318c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000318c:	7179                	addi	sp,sp,-48
    8000318e:	f406                	sd	ra,40(sp)
    80003190:	f022                	sd	s0,32(sp)
    80003192:	ec26                	sd	s1,24(sp)
    80003194:	e84a                	sd	s2,16(sp)
    80003196:	e44e                	sd	s3,8(sp)
    80003198:	1800                	addi	s0,sp,48
    8000319a:	89aa                	mv	s3,a0
    8000319c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000319e:	00014517          	auipc	a0,0x14
    800031a2:	56a50513          	addi	a0,a0,1386 # 80017708 <bcache>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	a3e080e7          	jalr	-1474(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ae:	0001d497          	auipc	s1,0x1d
    800031b2:	8124b483          	ld	s1,-2030(s1) # 8001f9c0 <bcache+0x82b8>
    800031b6:	0001c797          	auipc	a5,0x1c
    800031ba:	7ba78793          	addi	a5,a5,1978 # 8001f970 <bcache+0x8268>
    800031be:	02f48f63          	beq	s1,a5,800031fc <bread+0x70>
    800031c2:	873e                	mv	a4,a5
    800031c4:	a021                	j	800031cc <bread+0x40>
    800031c6:	68a4                	ld	s1,80(s1)
    800031c8:	02e48a63          	beq	s1,a4,800031fc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031cc:	449c                	lw	a5,8(s1)
    800031ce:	ff379ce3          	bne	a5,s3,800031c6 <bread+0x3a>
    800031d2:	44dc                	lw	a5,12(s1)
    800031d4:	ff2799e3          	bne	a5,s2,800031c6 <bread+0x3a>
      b->refcnt++;
    800031d8:	40bc                	lw	a5,64(s1)
    800031da:	2785                	addiw	a5,a5,1
    800031dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	52a50513          	addi	a0,a0,1322 # 80017708 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	ab2080e7          	jalr	-1358(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031ee:	01048513          	addi	a0,s1,16
    800031f2:	00001097          	auipc	ra,0x1
    800031f6:	466080e7          	jalr	1126(ra) # 80004658 <acquiresleep>
      return b;
    800031fa:	a8b9                	j	80003258 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031fc:	0001c497          	auipc	s1,0x1c
    80003200:	7bc4b483          	ld	s1,1980(s1) # 8001f9b8 <bcache+0x82b0>
    80003204:	0001c797          	auipc	a5,0x1c
    80003208:	76c78793          	addi	a5,a5,1900 # 8001f970 <bcache+0x8268>
    8000320c:	00f48863          	beq	s1,a5,8000321c <bread+0x90>
    80003210:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003212:	40bc                	lw	a5,64(s1)
    80003214:	cf81                	beqz	a5,8000322c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003216:	64a4                	ld	s1,72(s1)
    80003218:	fee49de3          	bne	s1,a4,80003212 <bread+0x86>
  panic("bget: no buffers");
    8000321c:	00005517          	auipc	a0,0x5
    80003220:	39c50513          	addi	a0,a0,924 # 800085b8 <syscalls+0xd8>
    80003224:	ffffd097          	auipc	ra,0xffffd
    80003228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
      b->dev = dev;
    8000322c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003230:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003234:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003238:	4785                	li	a5,1
    8000323a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000323c:	00014517          	auipc	a0,0x14
    80003240:	4cc50513          	addi	a0,a0,1228 # 80017708 <bcache>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	a54080e7          	jalr	-1452(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000324c:	01048513          	addi	a0,s1,16
    80003250:	00001097          	auipc	ra,0x1
    80003254:	408080e7          	jalr	1032(ra) # 80004658 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003258:	409c                	lw	a5,0(s1)
    8000325a:	cb89                	beqz	a5,8000326c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000325c:	8526                	mv	a0,s1
    8000325e:	70a2                	ld	ra,40(sp)
    80003260:	7402                	ld	s0,32(sp)
    80003262:	64e2                	ld	s1,24(sp)
    80003264:	6942                	ld	s2,16(sp)
    80003266:	69a2                	ld	s3,8(sp)
    80003268:	6145                	addi	sp,sp,48
    8000326a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000326c:	4581                	li	a1,0
    8000326e:	8526                	mv	a0,s1
    80003270:	00003097          	auipc	ra,0x3
    80003274:	f06080e7          	jalr	-250(ra) # 80006176 <virtio_disk_rw>
    b->valid = 1;
    80003278:	4785                	li	a5,1
    8000327a:	c09c                	sw	a5,0(s1)
  return b;
    8000327c:	b7c5                	j	8000325c <bread+0xd0>

000000008000327e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000327e:	1101                	addi	sp,sp,-32
    80003280:	ec06                	sd	ra,24(sp)
    80003282:	e822                	sd	s0,16(sp)
    80003284:	e426                	sd	s1,8(sp)
    80003286:	1000                	addi	s0,sp,32
    80003288:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000328a:	0541                	addi	a0,a0,16
    8000328c:	00001097          	auipc	ra,0x1
    80003290:	466080e7          	jalr	1126(ra) # 800046f2 <holdingsleep>
    80003294:	cd01                	beqz	a0,800032ac <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003296:	4585                	li	a1,1
    80003298:	8526                	mv	a0,s1
    8000329a:	00003097          	auipc	ra,0x3
    8000329e:	edc080e7          	jalr	-292(ra) # 80006176 <virtio_disk_rw>
}
    800032a2:	60e2                	ld	ra,24(sp)
    800032a4:	6442                	ld	s0,16(sp)
    800032a6:	64a2                	ld	s1,8(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret
    panic("bwrite");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	32450513          	addi	a0,a0,804 # 800085d0 <syscalls+0xf0>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	28a080e7          	jalr	650(ra) # 8000053e <panic>

00000000800032bc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	e04a                	sd	s2,0(sp)
    800032c6:	1000                	addi	s0,sp,32
    800032c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ca:	01050913          	addi	s2,a0,16
    800032ce:	854a                	mv	a0,s2
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	422080e7          	jalr	1058(ra) # 800046f2 <holdingsleep>
    800032d8:	c92d                	beqz	a0,8000334a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032da:	854a                	mv	a0,s2
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	3d2080e7          	jalr	978(ra) # 800046ae <releasesleep>

  acquire(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	42450513          	addi	a0,a0,1060 # 80017708 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	37fd                	addiw	a5,a5,-1
    800032f8:	0007871b          	sext.w	a4,a5
    800032fc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032fe:	eb05                	bnez	a4,8000332e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003300:	68bc                	ld	a5,80(s1)
    80003302:	64b8                	ld	a4,72(s1)
    80003304:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003306:	64bc                	ld	a5,72(s1)
    80003308:	68b8                	ld	a4,80(s1)
    8000330a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000330c:	0001c797          	auipc	a5,0x1c
    80003310:	3fc78793          	addi	a5,a5,1020 # 8001f708 <bcache+0x8000>
    80003314:	2b87b703          	ld	a4,696(a5)
    80003318:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000331a:	0001c717          	auipc	a4,0x1c
    8000331e:	65670713          	addi	a4,a4,1622 # 8001f970 <bcache+0x8268>
    80003322:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003324:	2b87b703          	ld	a4,696(a5)
    80003328:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000332a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000332e:	00014517          	auipc	a0,0x14
    80003332:	3da50513          	addi	a0,a0,986 # 80017708 <bcache>
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6902                	ld	s2,0(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret
    panic("brelse");
    8000334a:	00005517          	auipc	a0,0x5
    8000334e:	28e50513          	addi	a0,a0,654 # 800085d8 <syscalls+0xf8>
    80003352:	ffffd097          	auipc	ra,0xffffd
    80003356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>

000000008000335a <bpin>:

void
bpin(struct buf *b) {
    8000335a:	1101                	addi	sp,sp,-32
    8000335c:	ec06                	sd	ra,24(sp)
    8000335e:	e822                	sd	s0,16(sp)
    80003360:	e426                	sd	s1,8(sp)
    80003362:	1000                	addi	s0,sp,32
    80003364:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003366:	00014517          	auipc	a0,0x14
    8000336a:	3a250513          	addi	a0,a0,930 # 80017708 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003376:	40bc                	lw	a5,64(s1)
    80003378:	2785                	addiw	a5,a5,1
    8000337a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337c:	00014517          	auipc	a0,0x14
    80003380:	38c50513          	addi	a0,a0,908 # 80017708 <bcache>
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	914080e7          	jalr	-1772(ra) # 80000c98 <release>
}
    8000338c:	60e2                	ld	ra,24(sp)
    8000338e:	6442                	ld	s0,16(sp)
    80003390:	64a2                	ld	s1,8(sp)
    80003392:	6105                	addi	sp,sp,32
    80003394:	8082                	ret

0000000080003396 <bunpin>:

void
bunpin(struct buf *b) {
    80003396:	1101                	addi	sp,sp,-32
    80003398:	ec06                	sd	ra,24(sp)
    8000339a:	e822                	sd	s0,16(sp)
    8000339c:	e426                	sd	s1,8(sp)
    8000339e:	1000                	addi	s0,sp,32
    800033a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033a2:	00014517          	auipc	a0,0x14
    800033a6:	36650513          	addi	a0,a0,870 # 80017708 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033b2:	40bc                	lw	a5,64(s1)
    800033b4:	37fd                	addiw	a5,a5,-1
    800033b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b8:	00014517          	auipc	a0,0x14
    800033bc:	35050513          	addi	a0,a0,848 # 80017708 <bcache>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
}
    800033c8:	60e2                	ld	ra,24(sp)
    800033ca:	6442                	ld	s0,16(sp)
    800033cc:	64a2                	ld	s1,8(sp)
    800033ce:	6105                	addi	sp,sp,32
    800033d0:	8082                	ret

00000000800033d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	e04a                	sd	s2,0(sp)
    800033dc:	1000                	addi	s0,sp,32
    800033de:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033e0:	00d5d59b          	srliw	a1,a1,0xd
    800033e4:	0001d797          	auipc	a5,0x1d
    800033e8:	a007a783          	lw	a5,-1536(a5) # 8001fde4 <sb+0x1c>
    800033ec:	9dbd                	addw	a1,a1,a5
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	d9e080e7          	jalr	-610(ra) # 8000318c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033f6:	0074f713          	andi	a4,s1,7
    800033fa:	4785                	li	a5,1
    800033fc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003400:	14ce                	slli	s1,s1,0x33
    80003402:	90d9                	srli	s1,s1,0x36
    80003404:	00950733          	add	a4,a0,s1
    80003408:	05874703          	lbu	a4,88(a4)
    8000340c:	00e7f6b3          	and	a3,a5,a4
    80003410:	c69d                	beqz	a3,8000343e <bfree+0x6c>
    80003412:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003414:	94aa                	add	s1,s1,a0
    80003416:	fff7c793          	not	a5,a5
    8000341a:	8ff9                	and	a5,a5,a4
    8000341c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003420:	00001097          	auipc	ra,0x1
    80003424:	118080e7          	jalr	280(ra) # 80004538 <log_write>
  brelse(bp);
    80003428:	854a                	mv	a0,s2
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	e92080e7          	jalr	-366(ra) # 800032bc <brelse>
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	64a2                	ld	s1,8(sp)
    80003438:	6902                	ld	s2,0(sp)
    8000343a:	6105                	addi	sp,sp,32
    8000343c:	8082                	ret
    panic("freeing free block");
    8000343e:	00005517          	auipc	a0,0x5
    80003442:	1a250513          	addi	a0,a0,418 # 800085e0 <syscalls+0x100>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	0f8080e7          	jalr	248(ra) # 8000053e <panic>

000000008000344e <balloc>:
{
    8000344e:	711d                	addi	sp,sp,-96
    80003450:	ec86                	sd	ra,88(sp)
    80003452:	e8a2                	sd	s0,80(sp)
    80003454:	e4a6                	sd	s1,72(sp)
    80003456:	e0ca                	sd	s2,64(sp)
    80003458:	fc4e                	sd	s3,56(sp)
    8000345a:	f852                	sd	s4,48(sp)
    8000345c:	f456                	sd	s5,40(sp)
    8000345e:	f05a                	sd	s6,32(sp)
    80003460:	ec5e                	sd	s7,24(sp)
    80003462:	e862                	sd	s8,16(sp)
    80003464:	e466                	sd	s9,8(sp)
    80003466:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003468:	0001d797          	auipc	a5,0x1d
    8000346c:	9647a783          	lw	a5,-1692(a5) # 8001fdcc <sb+0x4>
    80003470:	cbd1                	beqz	a5,80003504 <balloc+0xb6>
    80003472:	8baa                	mv	s7,a0
    80003474:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003476:	0001db17          	auipc	s6,0x1d
    8000347a:	952b0b13          	addi	s6,s6,-1710 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003480:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003482:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003484:	6c89                	lui	s9,0x2
    80003486:	a831                	j	800034a2 <balloc+0x54>
    brelse(bp);
    80003488:	854a                	mv	a0,s2
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	e32080e7          	jalr	-462(ra) # 800032bc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003492:	015c87bb          	addw	a5,s9,s5
    80003496:	00078a9b          	sext.w	s5,a5
    8000349a:	004b2703          	lw	a4,4(s6)
    8000349e:	06eaf363          	bgeu	s5,a4,80003504 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034a2:	41fad79b          	sraiw	a5,s5,0x1f
    800034a6:	0137d79b          	srliw	a5,a5,0x13
    800034aa:	015787bb          	addw	a5,a5,s5
    800034ae:	40d7d79b          	sraiw	a5,a5,0xd
    800034b2:	01cb2583          	lw	a1,28(s6)
    800034b6:	9dbd                	addw	a1,a1,a5
    800034b8:	855e                	mv	a0,s7
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	cd2080e7          	jalr	-814(ra) # 8000318c <bread>
    800034c2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c4:	004b2503          	lw	a0,4(s6)
    800034c8:	000a849b          	sext.w	s1,s5
    800034cc:	8662                	mv	a2,s8
    800034ce:	faa4fde3          	bgeu	s1,a0,80003488 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034d2:	41f6579b          	sraiw	a5,a2,0x1f
    800034d6:	01d7d69b          	srliw	a3,a5,0x1d
    800034da:	00c6873b          	addw	a4,a3,a2
    800034de:	00777793          	andi	a5,a4,7
    800034e2:	9f95                	subw	a5,a5,a3
    800034e4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034e8:	4037571b          	sraiw	a4,a4,0x3
    800034ec:	00e906b3          	add	a3,s2,a4
    800034f0:	0586c683          	lbu	a3,88(a3)
    800034f4:	00d7f5b3          	and	a1,a5,a3
    800034f8:	cd91                	beqz	a1,80003514 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fa:	2605                	addiw	a2,a2,1
    800034fc:	2485                	addiw	s1,s1,1
    800034fe:	fd4618e3          	bne	a2,s4,800034ce <balloc+0x80>
    80003502:	b759                	j	80003488 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	0f450513          	addi	a0,a0,244 # 800085f8 <syscalls+0x118>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	032080e7          	jalr	50(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003514:	974a                	add	a4,a4,s2
    80003516:	8fd5                	or	a5,a5,a3
    80003518:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000351c:	854a                	mv	a0,s2
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	01a080e7          	jalr	26(ra) # 80004538 <log_write>
        brelse(bp);
    80003526:	854a                	mv	a0,s2
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	d94080e7          	jalr	-620(ra) # 800032bc <brelse>
  bp = bread(dev, bno);
    80003530:	85a6                	mv	a1,s1
    80003532:	855e                	mv	a0,s7
    80003534:	00000097          	auipc	ra,0x0
    80003538:	c58080e7          	jalr	-936(ra) # 8000318c <bread>
    8000353c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000353e:	40000613          	li	a2,1024
    80003542:	4581                	li	a1,0
    80003544:	05850513          	addi	a0,a0,88
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	798080e7          	jalr	1944(ra) # 80000ce0 <memset>
  log_write(bp);
    80003550:	854a                	mv	a0,s2
    80003552:	00001097          	auipc	ra,0x1
    80003556:	fe6080e7          	jalr	-26(ra) # 80004538 <log_write>
  brelse(bp);
    8000355a:	854a                	mv	a0,s2
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	d60080e7          	jalr	-672(ra) # 800032bc <brelse>
}
    80003564:	8526                	mv	a0,s1
    80003566:	60e6                	ld	ra,88(sp)
    80003568:	6446                	ld	s0,80(sp)
    8000356a:	64a6                	ld	s1,72(sp)
    8000356c:	6906                	ld	s2,64(sp)
    8000356e:	79e2                	ld	s3,56(sp)
    80003570:	7a42                	ld	s4,48(sp)
    80003572:	7aa2                	ld	s5,40(sp)
    80003574:	7b02                	ld	s6,32(sp)
    80003576:	6be2                	ld	s7,24(sp)
    80003578:	6c42                	ld	s8,16(sp)
    8000357a:	6ca2                	ld	s9,8(sp)
    8000357c:	6125                	addi	sp,sp,96
    8000357e:	8082                	ret

0000000080003580 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003580:	7179                	addi	sp,sp,-48
    80003582:	f406                	sd	ra,40(sp)
    80003584:	f022                	sd	s0,32(sp)
    80003586:	ec26                	sd	s1,24(sp)
    80003588:	e84a                	sd	s2,16(sp)
    8000358a:	e44e                	sd	s3,8(sp)
    8000358c:	e052                	sd	s4,0(sp)
    8000358e:	1800                	addi	s0,sp,48
    80003590:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003592:	47ad                	li	a5,11
    80003594:	04b7fe63          	bgeu	a5,a1,800035f0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003598:	ff45849b          	addiw	s1,a1,-12
    8000359c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035a0:	0ff00793          	li	a5,255
    800035a4:	0ae7e363          	bltu	a5,a4,8000364a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a8:	08052583          	lw	a1,128(a0)
    800035ac:	c5ad                	beqz	a1,80003616 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035ae:	00092503          	lw	a0,0(s2)
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	bda080e7          	jalr	-1062(ra) # 8000318c <bread>
    800035ba:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035bc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035c0:	02049593          	slli	a1,s1,0x20
    800035c4:	9181                	srli	a1,a1,0x20
    800035c6:	058a                	slli	a1,a1,0x2
    800035c8:	00b784b3          	add	s1,a5,a1
    800035cc:	0004a983          	lw	s3,0(s1)
    800035d0:	04098d63          	beqz	s3,8000362a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035d4:	8552                	mv	a0,s4
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	ce6080e7          	jalr	-794(ra) # 800032bc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035de:	854e                	mv	a0,s3
    800035e0:	70a2                	ld	ra,40(sp)
    800035e2:	7402                	ld	s0,32(sp)
    800035e4:	64e2                	ld	s1,24(sp)
    800035e6:	6942                	ld	s2,16(sp)
    800035e8:	69a2                	ld	s3,8(sp)
    800035ea:	6a02                	ld	s4,0(sp)
    800035ec:	6145                	addi	sp,sp,48
    800035ee:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035f0:	02059493          	slli	s1,a1,0x20
    800035f4:	9081                	srli	s1,s1,0x20
    800035f6:	048a                	slli	s1,s1,0x2
    800035f8:	94aa                	add	s1,s1,a0
    800035fa:	0504a983          	lw	s3,80(s1)
    800035fe:	fe0990e3          	bnez	s3,800035de <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003602:	4108                	lw	a0,0(a0)
    80003604:	00000097          	auipc	ra,0x0
    80003608:	e4a080e7          	jalr	-438(ra) # 8000344e <balloc>
    8000360c:	0005099b          	sext.w	s3,a0
    80003610:	0534a823          	sw	s3,80(s1)
    80003614:	b7e9                	j	800035de <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003616:	4108                	lw	a0,0(a0)
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	e36080e7          	jalr	-458(ra) # 8000344e <balloc>
    80003620:	0005059b          	sext.w	a1,a0
    80003624:	08b92023          	sw	a1,128(s2)
    80003628:	b759                	j	800035ae <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000362a:	00092503          	lw	a0,0(s2)
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	e20080e7          	jalr	-480(ra) # 8000344e <balloc>
    80003636:	0005099b          	sext.w	s3,a0
    8000363a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000363e:	8552                	mv	a0,s4
    80003640:	00001097          	auipc	ra,0x1
    80003644:	ef8080e7          	jalr	-264(ra) # 80004538 <log_write>
    80003648:	b771                	j	800035d4 <bmap+0x54>
  panic("bmap: out of range");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	fc650513          	addi	a0,a0,-58 # 80008610 <syscalls+0x130>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	eec080e7          	jalr	-276(ra) # 8000053e <panic>

000000008000365a <iget>:
{
    8000365a:	7179                	addi	sp,sp,-48
    8000365c:	f406                	sd	ra,40(sp)
    8000365e:	f022                	sd	s0,32(sp)
    80003660:	ec26                	sd	s1,24(sp)
    80003662:	e84a                	sd	s2,16(sp)
    80003664:	e44e                	sd	s3,8(sp)
    80003666:	e052                	sd	s4,0(sp)
    80003668:	1800                	addi	s0,sp,48
    8000366a:	89aa                	mv	s3,a0
    8000366c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000366e:	0001c517          	auipc	a0,0x1c
    80003672:	77a50513          	addi	a0,a0,1914 # 8001fde8 <itable>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	56e080e7          	jalr	1390(ra) # 80000be4 <acquire>
  empty = 0;
    8000367e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003680:	0001c497          	auipc	s1,0x1c
    80003684:	78048493          	addi	s1,s1,1920 # 8001fe00 <itable+0x18>
    80003688:	0001e697          	auipc	a3,0x1e
    8000368c:	20868693          	addi	a3,a3,520 # 80021890 <log>
    80003690:	a039                	j	8000369e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003692:	02090b63          	beqz	s2,800036c8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003696:	08848493          	addi	s1,s1,136
    8000369a:	02d48a63          	beq	s1,a3,800036ce <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000369e:	449c                	lw	a5,8(s1)
    800036a0:	fef059e3          	blez	a5,80003692 <iget+0x38>
    800036a4:	4098                	lw	a4,0(s1)
    800036a6:	ff3716e3          	bne	a4,s3,80003692 <iget+0x38>
    800036aa:	40d8                	lw	a4,4(s1)
    800036ac:	ff4713e3          	bne	a4,s4,80003692 <iget+0x38>
      ip->ref++;
    800036b0:	2785                	addiw	a5,a5,1
    800036b2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036b4:	0001c517          	auipc	a0,0x1c
    800036b8:	73450513          	addi	a0,a0,1844 # 8001fde8 <itable>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	5dc080e7          	jalr	1500(ra) # 80000c98 <release>
      return ip;
    800036c4:	8926                	mv	s2,s1
    800036c6:	a03d                	j	800036f4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c8:	f7f9                	bnez	a5,80003696 <iget+0x3c>
    800036ca:	8926                	mv	s2,s1
    800036cc:	b7e9                	j	80003696 <iget+0x3c>
  if(empty == 0)
    800036ce:	02090c63          	beqz	s2,80003706 <iget+0xac>
  ip->dev = dev;
    800036d2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036da:	4785                	li	a5,1
    800036dc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036e0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036e4:	0001c517          	auipc	a0,0x1c
    800036e8:	70450513          	addi	a0,a0,1796 # 8001fde8 <itable>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
}
    800036f4:	854a                	mv	a0,s2
    800036f6:	70a2                	ld	ra,40(sp)
    800036f8:	7402                	ld	s0,32(sp)
    800036fa:	64e2                	ld	s1,24(sp)
    800036fc:	6942                	ld	s2,16(sp)
    800036fe:	69a2                	ld	s3,8(sp)
    80003700:	6a02                	ld	s4,0(sp)
    80003702:	6145                	addi	sp,sp,48
    80003704:	8082                	ret
    panic("iget: no inodes");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	f2250513          	addi	a0,a0,-222 # 80008628 <syscalls+0x148>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>

0000000080003716 <fsinit>:
fsinit(int dev) {
    80003716:	7179                	addi	sp,sp,-48
    80003718:	f406                	sd	ra,40(sp)
    8000371a:	f022                	sd	s0,32(sp)
    8000371c:	ec26                	sd	s1,24(sp)
    8000371e:	e84a                	sd	s2,16(sp)
    80003720:	e44e                	sd	s3,8(sp)
    80003722:	1800                	addi	s0,sp,48
    80003724:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003726:	4585                	li	a1,1
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	a64080e7          	jalr	-1436(ra) # 8000318c <bread>
    80003730:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003732:	0001c997          	auipc	s3,0x1c
    80003736:	69698993          	addi	s3,s3,1686 # 8001fdc8 <sb>
    8000373a:	02000613          	li	a2,32
    8000373e:	05850593          	addi	a1,a0,88
    80003742:	854e                	mv	a0,s3
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	5fc080e7          	jalr	1532(ra) # 80000d40 <memmove>
  brelse(bp);
    8000374c:	8526                	mv	a0,s1
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	b6e080e7          	jalr	-1170(ra) # 800032bc <brelse>
  if(sb.magic != FSMAGIC)
    80003756:	0009a703          	lw	a4,0(s3)
    8000375a:	102037b7          	lui	a5,0x10203
    8000375e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003762:	02f71263          	bne	a4,a5,80003786 <fsinit+0x70>
  initlog(dev, &sb);
    80003766:	0001c597          	auipc	a1,0x1c
    8000376a:	66258593          	addi	a1,a1,1634 # 8001fdc8 <sb>
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	b4c080e7          	jalr	-1204(ra) # 800042bc <initlog>
}
    80003778:	70a2                	ld	ra,40(sp)
    8000377a:	7402                	ld	s0,32(sp)
    8000377c:	64e2                	ld	s1,24(sp)
    8000377e:	6942                	ld	s2,16(sp)
    80003780:	69a2                	ld	s3,8(sp)
    80003782:	6145                	addi	sp,sp,48
    80003784:	8082                	ret
    panic("invalid file system");
    80003786:	00005517          	auipc	a0,0x5
    8000378a:	eb250513          	addi	a0,a0,-334 # 80008638 <syscalls+0x158>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>

0000000080003796 <iinit>:
{
    80003796:	7179                	addi	sp,sp,-48
    80003798:	f406                	sd	ra,40(sp)
    8000379a:	f022                	sd	s0,32(sp)
    8000379c:	ec26                	sd	s1,24(sp)
    8000379e:	e84a                	sd	s2,16(sp)
    800037a0:	e44e                	sd	s3,8(sp)
    800037a2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037a4:	00005597          	auipc	a1,0x5
    800037a8:	eac58593          	addi	a1,a1,-340 # 80008650 <syscalls+0x170>
    800037ac:	0001c517          	auipc	a0,0x1c
    800037b0:	63c50513          	addi	a0,a0,1596 # 8001fde8 <itable>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	3a0080e7          	jalr	928(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037bc:	0001c497          	auipc	s1,0x1c
    800037c0:	65448493          	addi	s1,s1,1620 # 8001fe10 <itable+0x28>
    800037c4:	0001e997          	auipc	s3,0x1e
    800037c8:	0dc98993          	addi	s3,s3,220 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037cc:	00005917          	auipc	s2,0x5
    800037d0:	e8c90913          	addi	s2,s2,-372 # 80008658 <syscalls+0x178>
    800037d4:	85ca                	mv	a1,s2
    800037d6:	8526                	mv	a0,s1
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	e46080e7          	jalr	-442(ra) # 8000461e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037e0:	08848493          	addi	s1,s1,136
    800037e4:	ff3498e3          	bne	s1,s3,800037d4 <iinit+0x3e>
}
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6145                	addi	sp,sp,48
    800037f4:	8082                	ret

00000000800037f6 <ialloc>:
{
    800037f6:	715d                	addi	sp,sp,-80
    800037f8:	e486                	sd	ra,72(sp)
    800037fa:	e0a2                	sd	s0,64(sp)
    800037fc:	fc26                	sd	s1,56(sp)
    800037fe:	f84a                	sd	s2,48(sp)
    80003800:	f44e                	sd	s3,40(sp)
    80003802:	f052                	sd	s4,32(sp)
    80003804:	ec56                	sd	s5,24(sp)
    80003806:	e85a                	sd	s6,16(sp)
    80003808:	e45e                	sd	s7,8(sp)
    8000380a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000380c:	0001c717          	auipc	a4,0x1c
    80003810:	5c872703          	lw	a4,1480(a4) # 8001fdd4 <sb+0xc>
    80003814:	4785                	li	a5,1
    80003816:	04e7fa63          	bgeu	a5,a4,8000386a <ialloc+0x74>
    8000381a:	8aaa                	mv	s5,a0
    8000381c:	8bae                	mv	s7,a1
    8000381e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003820:	0001ca17          	auipc	s4,0x1c
    80003824:	5a8a0a13          	addi	s4,s4,1448 # 8001fdc8 <sb>
    80003828:	00048b1b          	sext.w	s6,s1
    8000382c:	0044d593          	srli	a1,s1,0x4
    80003830:	018a2783          	lw	a5,24(s4)
    80003834:	9dbd                	addw	a1,a1,a5
    80003836:	8556                	mv	a0,s5
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	954080e7          	jalr	-1708(ra) # 8000318c <bread>
    80003840:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003842:	05850993          	addi	s3,a0,88
    80003846:	00f4f793          	andi	a5,s1,15
    8000384a:	079a                	slli	a5,a5,0x6
    8000384c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000384e:	00099783          	lh	a5,0(s3)
    80003852:	c785                	beqz	a5,8000387a <ialloc+0x84>
    brelse(bp);
    80003854:	00000097          	auipc	ra,0x0
    80003858:	a68080e7          	jalr	-1432(ra) # 800032bc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000385c:	0485                	addi	s1,s1,1
    8000385e:	00ca2703          	lw	a4,12(s4)
    80003862:	0004879b          	sext.w	a5,s1
    80003866:	fce7e1e3          	bltu	a5,a4,80003828 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000386a:	00005517          	auipc	a0,0x5
    8000386e:	df650513          	addi	a0,a0,-522 # 80008660 <syscalls+0x180>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	ccc080e7          	jalr	-820(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000387a:	04000613          	li	a2,64
    8000387e:	4581                	li	a1,0
    80003880:	854e                	mv	a0,s3
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	45e080e7          	jalr	1118(ra) # 80000ce0 <memset>
      dip->type = type;
    8000388a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	ca8080e7          	jalr	-856(ra) # 80004538 <log_write>
      brelse(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	a22080e7          	jalr	-1502(ra) # 800032bc <brelse>
      return iget(dev, inum);
    800038a2:	85da                	mv	a1,s6
    800038a4:	8556                	mv	a0,s5
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	db4080e7          	jalr	-588(ra) # 8000365a <iget>
}
    800038ae:	60a6                	ld	ra,72(sp)
    800038b0:	6406                	ld	s0,64(sp)
    800038b2:	74e2                	ld	s1,56(sp)
    800038b4:	7942                	ld	s2,48(sp)
    800038b6:	79a2                	ld	s3,40(sp)
    800038b8:	7a02                	ld	s4,32(sp)
    800038ba:	6ae2                	ld	s5,24(sp)
    800038bc:	6b42                	ld	s6,16(sp)
    800038be:	6ba2                	ld	s7,8(sp)
    800038c0:	6161                	addi	sp,sp,80
    800038c2:	8082                	ret

00000000800038c4 <iupdate>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d2:	415c                	lw	a5,4(a0)
    800038d4:	0047d79b          	srliw	a5,a5,0x4
    800038d8:	0001c597          	auipc	a1,0x1c
    800038dc:	5085a583          	lw	a1,1288(a1) # 8001fde0 <sb+0x18>
    800038e0:	9dbd                	addw	a1,a1,a5
    800038e2:	4108                	lw	a0,0(a0)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	8a8080e7          	jalr	-1880(ra) # 8000318c <bread>
    800038ec:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ee:	05850793          	addi	a5,a0,88
    800038f2:	40c8                	lw	a0,4(s1)
    800038f4:	893d                	andi	a0,a0,15
    800038f6:	051a                	slli	a0,a0,0x6
    800038f8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038fa:	04449703          	lh	a4,68(s1)
    800038fe:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003902:	04649703          	lh	a4,70(s1)
    80003906:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000390a:	04849703          	lh	a4,72(s1)
    8000390e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003912:	04a49703          	lh	a4,74(s1)
    80003916:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000391a:	44f8                	lw	a4,76(s1)
    8000391c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000391e:	03400613          	li	a2,52
    80003922:	05048593          	addi	a1,s1,80
    80003926:	0531                	addi	a0,a0,12
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	418080e7          	jalr	1048(ra) # 80000d40 <memmove>
  log_write(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	00001097          	auipc	ra,0x1
    80003936:	c06080e7          	jalr	-1018(ra) # 80004538 <log_write>
  brelse(bp);
    8000393a:	854a                	mv	a0,s2
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	980080e7          	jalr	-1664(ra) # 800032bc <brelse>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6902                	ld	s2,0(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret

0000000080003950 <idup>:
{
    80003950:	1101                	addi	sp,sp,-32
    80003952:	ec06                	sd	ra,24(sp)
    80003954:	e822                	sd	s0,16(sp)
    80003956:	e426                	sd	s1,8(sp)
    80003958:	1000                	addi	s0,sp,32
    8000395a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395c:	0001c517          	auipc	a0,0x1c
    80003960:	48c50513          	addi	a0,a0,1164 # 8001fde8 <itable>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
  ip->ref++;
    8000396c:	449c                	lw	a5,8(s1)
    8000396e:	2785                	addiw	a5,a5,1
    80003970:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003972:	0001c517          	auipc	a0,0x1c
    80003976:	47650513          	addi	a0,a0,1142 # 8001fde8 <itable>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
}
    80003982:	8526                	mv	a0,s1
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6105                	addi	sp,sp,32
    8000398c:	8082                	ret

000000008000398e <ilock>:
{
    8000398e:	1101                	addi	sp,sp,-32
    80003990:	ec06                	sd	ra,24(sp)
    80003992:	e822                	sd	s0,16(sp)
    80003994:	e426                	sd	s1,8(sp)
    80003996:	e04a                	sd	s2,0(sp)
    80003998:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000399a:	c115                	beqz	a0,800039be <ilock+0x30>
    8000399c:	84aa                	mv	s1,a0
    8000399e:	451c                	lw	a5,8(a0)
    800039a0:	00f05f63          	blez	a5,800039be <ilock+0x30>
  acquiresleep(&ip->lock);
    800039a4:	0541                	addi	a0,a0,16
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	cb2080e7          	jalr	-846(ra) # 80004658 <acquiresleep>
  if(ip->valid == 0){
    800039ae:	40bc                	lw	a5,64(s1)
    800039b0:	cf99                	beqz	a5,800039ce <ilock+0x40>
}
    800039b2:	60e2                	ld	ra,24(sp)
    800039b4:	6442                	ld	s0,16(sp)
    800039b6:	64a2                	ld	s1,8(sp)
    800039b8:	6902                	ld	s2,0(sp)
    800039ba:	6105                	addi	sp,sp,32
    800039bc:	8082                	ret
    panic("ilock");
    800039be:	00005517          	auipc	a0,0x5
    800039c2:	cba50513          	addi	a0,a0,-838 # 80008678 <syscalls+0x198>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	b78080e7          	jalr	-1160(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ce:	40dc                	lw	a5,4(s1)
    800039d0:	0047d79b          	srliw	a5,a5,0x4
    800039d4:	0001c597          	auipc	a1,0x1c
    800039d8:	40c5a583          	lw	a1,1036(a1) # 8001fde0 <sb+0x18>
    800039dc:	9dbd                	addw	a1,a1,a5
    800039de:	4088                	lw	a0,0(s1)
    800039e0:	fffff097          	auipc	ra,0xfffff
    800039e4:	7ac080e7          	jalr	1964(ra) # 8000318c <bread>
    800039e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ea:	05850593          	addi	a1,a0,88
    800039ee:	40dc                	lw	a5,4(s1)
    800039f0:	8bbd                	andi	a5,a5,15
    800039f2:	079a                	slli	a5,a5,0x6
    800039f4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f6:	00059783          	lh	a5,0(a1)
    800039fa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039fe:	00259783          	lh	a5,2(a1)
    80003a02:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a06:	00459783          	lh	a5,4(a1)
    80003a0a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a0e:	00659783          	lh	a5,6(a1)
    80003a12:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a16:	459c                	lw	a5,8(a1)
    80003a18:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a1a:	03400613          	li	a2,52
    80003a1e:	05b1                	addi	a1,a1,12
    80003a20:	05048513          	addi	a0,s1,80
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	31c080e7          	jalr	796(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a2c:	854a                	mv	a0,s2
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	88e080e7          	jalr	-1906(ra) # 800032bc <brelse>
    ip->valid = 1;
    80003a36:	4785                	li	a5,1
    80003a38:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a3a:	04449783          	lh	a5,68(s1)
    80003a3e:	fbb5                	bnez	a5,800039b2 <ilock+0x24>
      panic("ilock: no type");
    80003a40:	00005517          	auipc	a0,0x5
    80003a44:	c4050513          	addi	a0,a0,-960 # 80008680 <syscalls+0x1a0>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	af6080e7          	jalr	-1290(ra) # 8000053e <panic>

0000000080003a50 <iunlock>:
{
    80003a50:	1101                	addi	sp,sp,-32
    80003a52:	ec06                	sd	ra,24(sp)
    80003a54:	e822                	sd	s0,16(sp)
    80003a56:	e426                	sd	s1,8(sp)
    80003a58:	e04a                	sd	s2,0(sp)
    80003a5a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a5c:	c905                	beqz	a0,80003a8c <iunlock+0x3c>
    80003a5e:	84aa                	mv	s1,a0
    80003a60:	01050913          	addi	s2,a0,16
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	c8c080e7          	jalr	-884(ra) # 800046f2 <holdingsleep>
    80003a6e:	cd19                	beqz	a0,80003a8c <iunlock+0x3c>
    80003a70:	449c                	lw	a5,8(s1)
    80003a72:	00f05d63          	blez	a5,80003a8c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	c36080e7          	jalr	-970(ra) # 800046ae <releasesleep>
}
    80003a80:	60e2                	ld	ra,24(sp)
    80003a82:	6442                	ld	s0,16(sp)
    80003a84:	64a2                	ld	s1,8(sp)
    80003a86:	6902                	ld	s2,0(sp)
    80003a88:	6105                	addi	sp,sp,32
    80003a8a:	8082                	ret
    panic("iunlock");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	c0450513          	addi	a0,a0,-1020 # 80008690 <syscalls+0x1b0>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>

0000000080003a9c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a9c:	7179                	addi	sp,sp,-48
    80003a9e:	f406                	sd	ra,40(sp)
    80003aa0:	f022                	sd	s0,32(sp)
    80003aa2:	ec26                	sd	s1,24(sp)
    80003aa4:	e84a                	sd	s2,16(sp)
    80003aa6:	e44e                	sd	s3,8(sp)
    80003aa8:	e052                	sd	s4,0(sp)
    80003aaa:	1800                	addi	s0,sp,48
    80003aac:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aae:	05050493          	addi	s1,a0,80
    80003ab2:	08050913          	addi	s2,a0,128
    80003ab6:	a021                	j	80003abe <itrunc+0x22>
    80003ab8:	0491                	addi	s1,s1,4
    80003aba:	01248d63          	beq	s1,s2,80003ad4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003abe:	408c                	lw	a1,0(s1)
    80003ac0:	dde5                	beqz	a1,80003ab8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ac2:	0009a503          	lw	a0,0(s3)
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	90c080e7          	jalr	-1780(ra) # 800033d2 <bfree>
      ip->addrs[i] = 0;
    80003ace:	0004a023          	sw	zero,0(s1)
    80003ad2:	b7dd                	j	80003ab8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ad4:	0809a583          	lw	a1,128(s3)
    80003ad8:	e185                	bnez	a1,80003af8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ada:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ade:	854e                	mv	a0,s3
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	de4080e7          	jalr	-540(ra) # 800038c4 <iupdate>
}
    80003ae8:	70a2                	ld	ra,40(sp)
    80003aea:	7402                	ld	s0,32(sp)
    80003aec:	64e2                	ld	s1,24(sp)
    80003aee:	6942                	ld	s2,16(sp)
    80003af0:	69a2                	ld	s3,8(sp)
    80003af2:	6a02                	ld	s4,0(sp)
    80003af4:	6145                	addi	sp,sp,48
    80003af6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af8:	0009a503          	lw	a0,0(s3)
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	690080e7          	jalr	1680(ra) # 8000318c <bread>
    80003b04:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b06:	05850493          	addi	s1,a0,88
    80003b0a:	45850913          	addi	s2,a0,1112
    80003b0e:	a811                	j	80003b22 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	8be080e7          	jalr	-1858(ra) # 800033d2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b1c:	0491                	addi	s1,s1,4
    80003b1e:	01248563          	beq	s1,s2,80003b28 <itrunc+0x8c>
      if(a[j])
    80003b22:	408c                	lw	a1,0(s1)
    80003b24:	dde5                	beqz	a1,80003b1c <itrunc+0x80>
    80003b26:	b7ed                	j	80003b10 <itrunc+0x74>
    brelse(bp);
    80003b28:	8552                	mv	a0,s4
    80003b2a:	fffff097          	auipc	ra,0xfffff
    80003b2e:	792080e7          	jalr	1938(ra) # 800032bc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b32:	0809a583          	lw	a1,128(s3)
    80003b36:	0009a503          	lw	a0,0(s3)
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	898080e7          	jalr	-1896(ra) # 800033d2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b42:	0809a023          	sw	zero,128(s3)
    80003b46:	bf51                	j	80003ada <itrunc+0x3e>

0000000080003b48 <iput>:
{
    80003b48:	1101                	addi	sp,sp,-32
    80003b4a:	ec06                	sd	ra,24(sp)
    80003b4c:	e822                	sd	s0,16(sp)
    80003b4e:	e426                	sd	s1,8(sp)
    80003b50:	e04a                	sd	s2,0(sp)
    80003b52:	1000                	addi	s0,sp,32
    80003b54:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b56:	0001c517          	auipc	a0,0x1c
    80003b5a:	29250513          	addi	a0,a0,658 # 8001fde8 <itable>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	086080e7          	jalr	134(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b66:	4498                	lw	a4,8(s1)
    80003b68:	4785                	li	a5,1
    80003b6a:	02f70363          	beq	a4,a5,80003b90 <iput+0x48>
  ip->ref--;
    80003b6e:	449c                	lw	a5,8(s1)
    80003b70:	37fd                	addiw	a5,a5,-1
    80003b72:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b74:	0001c517          	auipc	a0,0x1c
    80003b78:	27450513          	addi	a0,a0,628 # 8001fde8 <itable>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	11c080e7          	jalr	284(ra) # 80000c98 <release>
}
    80003b84:	60e2                	ld	ra,24(sp)
    80003b86:	6442                	ld	s0,16(sp)
    80003b88:	64a2                	ld	s1,8(sp)
    80003b8a:	6902                	ld	s2,0(sp)
    80003b8c:	6105                	addi	sp,sp,32
    80003b8e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b90:	40bc                	lw	a5,64(s1)
    80003b92:	dff1                	beqz	a5,80003b6e <iput+0x26>
    80003b94:	04a49783          	lh	a5,74(s1)
    80003b98:	fbf9                	bnez	a5,80003b6e <iput+0x26>
    acquiresleep(&ip->lock);
    80003b9a:	01048913          	addi	s2,s1,16
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	ab8080e7          	jalr	-1352(ra) # 80004658 <acquiresleep>
    release(&itable.lock);
    80003ba8:	0001c517          	auipc	a0,0x1c
    80003bac:	24050513          	addi	a0,a0,576 # 8001fde8 <itable>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	0e8080e7          	jalr	232(ra) # 80000c98 <release>
    itrunc(ip);
    80003bb8:	8526                	mv	a0,s1
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	ee2080e7          	jalr	-286(ra) # 80003a9c <itrunc>
    ip->type = 0;
    80003bc2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	cfc080e7          	jalr	-772(ra) # 800038c4 <iupdate>
    ip->valid = 0;
    80003bd0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	ad8080e7          	jalr	-1320(ra) # 800046ae <releasesleep>
    acquire(&itable.lock);
    80003bde:	0001c517          	auipc	a0,0x1c
    80003be2:	20a50513          	addi	a0,a0,522 # 8001fde8 <itable>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	ffe080e7          	jalr	-2(ra) # 80000be4 <acquire>
    80003bee:	b741                	j	80003b6e <iput+0x26>

0000000080003bf0 <iunlockput>:
{
    80003bf0:	1101                	addi	sp,sp,-32
    80003bf2:	ec06                	sd	ra,24(sp)
    80003bf4:	e822                	sd	s0,16(sp)
    80003bf6:	e426                	sd	s1,8(sp)
    80003bf8:	1000                	addi	s0,sp,32
    80003bfa:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	e54080e7          	jalr	-428(ra) # 80003a50 <iunlock>
  iput(ip);
    80003c04:	8526                	mv	a0,s1
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	f42080e7          	jalr	-190(ra) # 80003b48 <iput>
}
    80003c0e:	60e2                	ld	ra,24(sp)
    80003c10:	6442                	ld	s0,16(sp)
    80003c12:	64a2                	ld	s1,8(sp)
    80003c14:	6105                	addi	sp,sp,32
    80003c16:	8082                	ret

0000000080003c18 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c18:	1141                	addi	sp,sp,-16
    80003c1a:	e422                	sd	s0,8(sp)
    80003c1c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c1e:	411c                	lw	a5,0(a0)
    80003c20:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c22:	415c                	lw	a5,4(a0)
    80003c24:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c26:	04451783          	lh	a5,68(a0)
    80003c2a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c2e:	04a51783          	lh	a5,74(a0)
    80003c32:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c36:	04c56783          	lwu	a5,76(a0)
    80003c3a:	e99c                	sd	a5,16(a1)
}
    80003c3c:	6422                	ld	s0,8(sp)
    80003c3e:	0141                	addi	sp,sp,16
    80003c40:	8082                	ret

0000000080003c42 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c42:	457c                	lw	a5,76(a0)
    80003c44:	0ed7e963          	bltu	a5,a3,80003d36 <readi+0xf4>
{
    80003c48:	7159                	addi	sp,sp,-112
    80003c4a:	f486                	sd	ra,104(sp)
    80003c4c:	f0a2                	sd	s0,96(sp)
    80003c4e:	eca6                	sd	s1,88(sp)
    80003c50:	e8ca                	sd	s2,80(sp)
    80003c52:	e4ce                	sd	s3,72(sp)
    80003c54:	e0d2                	sd	s4,64(sp)
    80003c56:	fc56                	sd	s5,56(sp)
    80003c58:	f85a                	sd	s6,48(sp)
    80003c5a:	f45e                	sd	s7,40(sp)
    80003c5c:	f062                	sd	s8,32(sp)
    80003c5e:	ec66                	sd	s9,24(sp)
    80003c60:	e86a                	sd	s10,16(sp)
    80003c62:	e46e                	sd	s11,8(sp)
    80003c64:	1880                	addi	s0,sp,112
    80003c66:	8baa                	mv	s7,a0
    80003c68:	8c2e                	mv	s8,a1
    80003c6a:	8ab2                	mv	s5,a2
    80003c6c:	84b6                	mv	s1,a3
    80003c6e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c70:	9f35                	addw	a4,a4,a3
    return 0;
    80003c72:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c74:	0ad76063          	bltu	a4,a3,80003d14 <readi+0xd2>
  if(off + n > ip->size)
    80003c78:	00e7f463          	bgeu	a5,a4,80003c80 <readi+0x3e>
    n = ip->size - off;
    80003c7c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c80:	0a0b0963          	beqz	s6,80003d32 <readi+0xf0>
    80003c84:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c86:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c8a:	5cfd                	li	s9,-1
    80003c8c:	a82d                	j	80003cc6 <readi+0x84>
    80003c8e:	020a1d93          	slli	s11,s4,0x20
    80003c92:	020ddd93          	srli	s11,s11,0x20
    80003c96:	05890613          	addi	a2,s2,88
    80003c9a:	86ee                	mv	a3,s11
    80003c9c:	963a                	add	a2,a2,a4
    80003c9e:	85d6                	mv	a1,s5
    80003ca0:	8562                	mv	a0,s8
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	b14080e7          	jalr	-1260(ra) # 800027b6 <either_copyout>
    80003caa:	05950d63          	beq	a0,s9,80003d04 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	60c080e7          	jalr	1548(ra) # 800032bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb8:	013a09bb          	addw	s3,s4,s3
    80003cbc:	009a04bb          	addw	s1,s4,s1
    80003cc0:	9aee                	add	s5,s5,s11
    80003cc2:	0569f763          	bgeu	s3,s6,80003d10 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc6:	000ba903          	lw	s2,0(s7)
    80003cca:	00a4d59b          	srliw	a1,s1,0xa
    80003cce:	855e                	mv	a0,s7
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	8b0080e7          	jalr	-1872(ra) # 80003580 <bmap>
    80003cd8:	0005059b          	sext.w	a1,a0
    80003cdc:	854a                	mv	a0,s2
    80003cde:	fffff097          	auipc	ra,0xfffff
    80003ce2:	4ae080e7          	jalr	1198(ra) # 8000318c <bread>
    80003ce6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce8:	3ff4f713          	andi	a4,s1,1023
    80003cec:	40ed07bb          	subw	a5,s10,a4
    80003cf0:	413b06bb          	subw	a3,s6,s3
    80003cf4:	8a3e                	mv	s4,a5
    80003cf6:	2781                	sext.w	a5,a5
    80003cf8:	0006861b          	sext.w	a2,a3
    80003cfc:	f8f679e3          	bgeu	a2,a5,80003c8e <readi+0x4c>
    80003d00:	8a36                	mv	s4,a3
    80003d02:	b771                	j	80003c8e <readi+0x4c>
      brelse(bp);
    80003d04:	854a                	mv	a0,s2
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	5b6080e7          	jalr	1462(ra) # 800032bc <brelse>
      tot = -1;
    80003d0e:	59fd                	li	s3,-1
  }
  return tot;
    80003d10:	0009851b          	sext.w	a0,s3
}
    80003d14:	70a6                	ld	ra,104(sp)
    80003d16:	7406                	ld	s0,96(sp)
    80003d18:	64e6                	ld	s1,88(sp)
    80003d1a:	6946                	ld	s2,80(sp)
    80003d1c:	69a6                	ld	s3,72(sp)
    80003d1e:	6a06                	ld	s4,64(sp)
    80003d20:	7ae2                	ld	s5,56(sp)
    80003d22:	7b42                	ld	s6,48(sp)
    80003d24:	7ba2                	ld	s7,40(sp)
    80003d26:	7c02                	ld	s8,32(sp)
    80003d28:	6ce2                	ld	s9,24(sp)
    80003d2a:	6d42                	ld	s10,16(sp)
    80003d2c:	6da2                	ld	s11,8(sp)
    80003d2e:	6165                	addi	sp,sp,112
    80003d30:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d32:	89da                	mv	s3,s6
    80003d34:	bff1                	j	80003d10 <readi+0xce>
    return 0;
    80003d36:	4501                	li	a0,0
}
    80003d38:	8082                	ret

0000000080003d3a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d3a:	457c                	lw	a5,76(a0)
    80003d3c:	10d7e863          	bltu	a5,a3,80003e4c <writei+0x112>
{
    80003d40:	7159                	addi	sp,sp,-112
    80003d42:	f486                	sd	ra,104(sp)
    80003d44:	f0a2                	sd	s0,96(sp)
    80003d46:	eca6                	sd	s1,88(sp)
    80003d48:	e8ca                	sd	s2,80(sp)
    80003d4a:	e4ce                	sd	s3,72(sp)
    80003d4c:	e0d2                	sd	s4,64(sp)
    80003d4e:	fc56                	sd	s5,56(sp)
    80003d50:	f85a                	sd	s6,48(sp)
    80003d52:	f45e                	sd	s7,40(sp)
    80003d54:	f062                	sd	s8,32(sp)
    80003d56:	ec66                	sd	s9,24(sp)
    80003d58:	e86a                	sd	s10,16(sp)
    80003d5a:	e46e                	sd	s11,8(sp)
    80003d5c:	1880                	addi	s0,sp,112
    80003d5e:	8b2a                	mv	s6,a0
    80003d60:	8c2e                	mv	s8,a1
    80003d62:	8ab2                	mv	s5,a2
    80003d64:	8936                	mv	s2,a3
    80003d66:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d68:	00e687bb          	addw	a5,a3,a4
    80003d6c:	0ed7e263          	bltu	a5,a3,80003e50 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d70:	00043737          	lui	a4,0x43
    80003d74:	0ef76063          	bltu	a4,a5,80003e54 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d78:	0c0b8863          	beqz	s7,80003e48 <writei+0x10e>
    80003d7c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d7e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d82:	5cfd                	li	s9,-1
    80003d84:	a091                	j	80003dc8 <writei+0x8e>
    80003d86:	02099d93          	slli	s11,s3,0x20
    80003d8a:	020ddd93          	srli	s11,s11,0x20
    80003d8e:	05848513          	addi	a0,s1,88
    80003d92:	86ee                	mv	a3,s11
    80003d94:	8656                	mv	a2,s5
    80003d96:	85e2                	mv	a1,s8
    80003d98:	953a                	add	a0,a0,a4
    80003d9a:	fffff097          	auipc	ra,0xfffff
    80003d9e:	a72080e7          	jalr	-1422(ra) # 8000280c <either_copyin>
    80003da2:	07950263          	beq	a0,s9,80003e06 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003da6:	8526                	mv	a0,s1
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	790080e7          	jalr	1936(ra) # 80004538 <log_write>
    brelse(bp);
    80003db0:	8526                	mv	a0,s1
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	50a080e7          	jalr	1290(ra) # 800032bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dba:	01498a3b          	addw	s4,s3,s4
    80003dbe:	0129893b          	addw	s2,s3,s2
    80003dc2:	9aee                	add	s5,s5,s11
    80003dc4:	057a7663          	bgeu	s4,s7,80003e10 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dc8:	000b2483          	lw	s1,0(s6)
    80003dcc:	00a9559b          	srliw	a1,s2,0xa
    80003dd0:	855a                	mv	a0,s6
    80003dd2:	fffff097          	auipc	ra,0xfffff
    80003dd6:	7ae080e7          	jalr	1966(ra) # 80003580 <bmap>
    80003dda:	0005059b          	sext.w	a1,a0
    80003dde:	8526                	mv	a0,s1
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	3ac080e7          	jalr	940(ra) # 8000318c <bread>
    80003de8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dea:	3ff97713          	andi	a4,s2,1023
    80003dee:	40ed07bb          	subw	a5,s10,a4
    80003df2:	414b86bb          	subw	a3,s7,s4
    80003df6:	89be                	mv	s3,a5
    80003df8:	2781                	sext.w	a5,a5
    80003dfa:	0006861b          	sext.w	a2,a3
    80003dfe:	f8f674e3          	bgeu	a2,a5,80003d86 <writei+0x4c>
    80003e02:	89b6                	mv	s3,a3
    80003e04:	b749                	j	80003d86 <writei+0x4c>
      brelse(bp);
    80003e06:	8526                	mv	a0,s1
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	4b4080e7          	jalr	1204(ra) # 800032bc <brelse>
  }

  if(off > ip->size)
    80003e10:	04cb2783          	lw	a5,76(s6)
    80003e14:	0127f463          	bgeu	a5,s2,80003e1c <writei+0xe2>
    ip->size = off;
    80003e18:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e1c:	855a                	mv	a0,s6
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	aa6080e7          	jalr	-1370(ra) # 800038c4 <iupdate>

  return tot;
    80003e26:	000a051b          	sext.w	a0,s4
}
    80003e2a:	70a6                	ld	ra,104(sp)
    80003e2c:	7406                	ld	s0,96(sp)
    80003e2e:	64e6                	ld	s1,88(sp)
    80003e30:	6946                	ld	s2,80(sp)
    80003e32:	69a6                	ld	s3,72(sp)
    80003e34:	6a06                	ld	s4,64(sp)
    80003e36:	7ae2                	ld	s5,56(sp)
    80003e38:	7b42                	ld	s6,48(sp)
    80003e3a:	7ba2                	ld	s7,40(sp)
    80003e3c:	7c02                	ld	s8,32(sp)
    80003e3e:	6ce2                	ld	s9,24(sp)
    80003e40:	6d42                	ld	s10,16(sp)
    80003e42:	6da2                	ld	s11,8(sp)
    80003e44:	6165                	addi	sp,sp,112
    80003e46:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e48:	8a5e                	mv	s4,s7
    80003e4a:	bfc9                	j	80003e1c <writei+0xe2>
    return -1;
    80003e4c:	557d                	li	a0,-1
}
    80003e4e:	8082                	ret
    return -1;
    80003e50:	557d                	li	a0,-1
    80003e52:	bfe1                	j	80003e2a <writei+0xf0>
    return -1;
    80003e54:	557d                	li	a0,-1
    80003e56:	bfd1                	j	80003e2a <writei+0xf0>

0000000080003e58 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e58:	1141                	addi	sp,sp,-16
    80003e5a:	e406                	sd	ra,8(sp)
    80003e5c:	e022                	sd	s0,0(sp)
    80003e5e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e60:	4639                	li	a2,14
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	f56080e7          	jalr	-170(ra) # 80000db8 <strncmp>
}
    80003e6a:	60a2                	ld	ra,8(sp)
    80003e6c:	6402                	ld	s0,0(sp)
    80003e6e:	0141                	addi	sp,sp,16
    80003e70:	8082                	ret

0000000080003e72 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e72:	7139                	addi	sp,sp,-64
    80003e74:	fc06                	sd	ra,56(sp)
    80003e76:	f822                	sd	s0,48(sp)
    80003e78:	f426                	sd	s1,40(sp)
    80003e7a:	f04a                	sd	s2,32(sp)
    80003e7c:	ec4e                	sd	s3,24(sp)
    80003e7e:	e852                	sd	s4,16(sp)
    80003e80:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e82:	04451703          	lh	a4,68(a0)
    80003e86:	4785                	li	a5,1
    80003e88:	00f71a63          	bne	a4,a5,80003e9c <dirlookup+0x2a>
    80003e8c:	892a                	mv	s2,a0
    80003e8e:	89ae                	mv	s3,a1
    80003e90:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e92:	457c                	lw	a5,76(a0)
    80003e94:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e96:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e98:	e79d                	bnez	a5,80003ec6 <dirlookup+0x54>
    80003e9a:	a8a5                	j	80003f12 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e9c:	00004517          	auipc	a0,0x4
    80003ea0:	7fc50513          	addi	a0,a0,2044 # 80008698 <syscalls+0x1b8>
    80003ea4:	ffffc097          	auipc	ra,0xffffc
    80003ea8:	69a080e7          	jalr	1690(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003eac:	00005517          	auipc	a0,0x5
    80003eb0:	80450513          	addi	a0,a0,-2044 # 800086b0 <syscalls+0x1d0>
    80003eb4:	ffffc097          	auipc	ra,0xffffc
    80003eb8:	68a080e7          	jalr	1674(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebc:	24c1                	addiw	s1,s1,16
    80003ebe:	04c92783          	lw	a5,76(s2)
    80003ec2:	04f4f763          	bgeu	s1,a5,80003f10 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec6:	4741                	li	a4,16
    80003ec8:	86a6                	mv	a3,s1
    80003eca:	fc040613          	addi	a2,s0,-64
    80003ece:	4581                	li	a1,0
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	d70080e7          	jalr	-656(ra) # 80003c42 <readi>
    80003eda:	47c1                	li	a5,16
    80003edc:	fcf518e3          	bne	a0,a5,80003eac <dirlookup+0x3a>
    if(de.inum == 0)
    80003ee0:	fc045783          	lhu	a5,-64(s0)
    80003ee4:	dfe1                	beqz	a5,80003ebc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ee6:	fc240593          	addi	a1,s0,-62
    80003eea:	854e                	mv	a0,s3
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	f6c080e7          	jalr	-148(ra) # 80003e58 <namecmp>
    80003ef4:	f561                	bnez	a0,80003ebc <dirlookup+0x4a>
      if(poff)
    80003ef6:	000a0463          	beqz	s4,80003efe <dirlookup+0x8c>
        *poff = off;
    80003efa:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003efe:	fc045583          	lhu	a1,-64(s0)
    80003f02:	00092503          	lw	a0,0(s2)
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	754080e7          	jalr	1876(ra) # 8000365a <iget>
    80003f0e:	a011                	j	80003f12 <dirlookup+0xa0>
  return 0;
    80003f10:	4501                	li	a0,0
}
    80003f12:	70e2                	ld	ra,56(sp)
    80003f14:	7442                	ld	s0,48(sp)
    80003f16:	74a2                	ld	s1,40(sp)
    80003f18:	7902                	ld	s2,32(sp)
    80003f1a:	69e2                	ld	s3,24(sp)
    80003f1c:	6a42                	ld	s4,16(sp)
    80003f1e:	6121                	addi	sp,sp,64
    80003f20:	8082                	ret

0000000080003f22 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f22:	711d                	addi	sp,sp,-96
    80003f24:	ec86                	sd	ra,88(sp)
    80003f26:	e8a2                	sd	s0,80(sp)
    80003f28:	e4a6                	sd	s1,72(sp)
    80003f2a:	e0ca                	sd	s2,64(sp)
    80003f2c:	fc4e                	sd	s3,56(sp)
    80003f2e:	f852                	sd	s4,48(sp)
    80003f30:	f456                	sd	s5,40(sp)
    80003f32:	f05a                	sd	s6,32(sp)
    80003f34:	ec5e                	sd	s7,24(sp)
    80003f36:	e862                	sd	s8,16(sp)
    80003f38:	e466                	sd	s9,8(sp)
    80003f3a:	1080                	addi	s0,sp,96
    80003f3c:	84aa                	mv	s1,a0
    80003f3e:	8b2e                	mv	s6,a1
    80003f40:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f42:	00054703          	lbu	a4,0(a0)
    80003f46:	02f00793          	li	a5,47
    80003f4a:	02f70363          	beq	a4,a5,80003f70 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f4e:	ffffe097          	auipc	ra,0xffffe
    80003f52:	d26080e7          	jalr	-730(ra) # 80001c74 <myproc>
    80003f56:	16853503          	ld	a0,360(a0)
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	9f6080e7          	jalr	-1546(ra) # 80003950 <idup>
    80003f62:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f64:	02f00913          	li	s2,47
  len = path - s;
    80003f68:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f6a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f6c:	4c05                	li	s8,1
    80003f6e:	a865                	j	80004026 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f70:	4585                	li	a1,1
    80003f72:	4505                	li	a0,1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	6e6080e7          	jalr	1766(ra) # 8000365a <iget>
    80003f7c:	89aa                	mv	s3,a0
    80003f7e:	b7dd                	j	80003f64 <namex+0x42>
      iunlockput(ip);
    80003f80:	854e                	mv	a0,s3
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	c6e080e7          	jalr	-914(ra) # 80003bf0 <iunlockput>
      return 0;
    80003f8a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	60e6                	ld	ra,88(sp)
    80003f90:	6446                	ld	s0,80(sp)
    80003f92:	64a6                	ld	s1,72(sp)
    80003f94:	6906                	ld	s2,64(sp)
    80003f96:	79e2                	ld	s3,56(sp)
    80003f98:	7a42                	ld	s4,48(sp)
    80003f9a:	7aa2                	ld	s5,40(sp)
    80003f9c:	7b02                	ld	s6,32(sp)
    80003f9e:	6be2                	ld	s7,24(sp)
    80003fa0:	6c42                	ld	s8,16(sp)
    80003fa2:	6ca2                	ld	s9,8(sp)
    80003fa4:	6125                	addi	sp,sp,96
    80003fa6:	8082                	ret
      iunlock(ip);
    80003fa8:	854e                	mv	a0,s3
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	aa6080e7          	jalr	-1370(ra) # 80003a50 <iunlock>
      return ip;
    80003fb2:	bfe9                	j	80003f8c <namex+0x6a>
      iunlockput(ip);
    80003fb4:	854e                	mv	a0,s3
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	c3a080e7          	jalr	-966(ra) # 80003bf0 <iunlockput>
      return 0;
    80003fbe:	89d2                	mv	s3,s4
    80003fc0:	b7f1                	j	80003f8c <namex+0x6a>
  len = path - s;
    80003fc2:	40b48633          	sub	a2,s1,a1
    80003fc6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fca:	094cd463          	bge	s9,s4,80004052 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fce:	4639                	li	a2,14
    80003fd0:	8556                	mv	a0,s5
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	d6e080e7          	jalr	-658(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fda:	0004c783          	lbu	a5,0(s1)
    80003fde:	01279763          	bne	a5,s2,80003fec <namex+0xca>
    path++;
    80003fe2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fe4:	0004c783          	lbu	a5,0(s1)
    80003fe8:	ff278de3          	beq	a5,s2,80003fe2 <namex+0xc0>
    ilock(ip);
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	9a0080e7          	jalr	-1632(ra) # 8000398e <ilock>
    if(ip->type != T_DIR){
    80003ff6:	04499783          	lh	a5,68(s3)
    80003ffa:	f98793e3          	bne	a5,s8,80003f80 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ffe:	000b0563          	beqz	s6,80004008 <namex+0xe6>
    80004002:	0004c783          	lbu	a5,0(s1)
    80004006:	d3cd                	beqz	a5,80003fa8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004008:	865e                	mv	a2,s7
    8000400a:	85d6                	mv	a1,s5
    8000400c:	854e                	mv	a0,s3
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	e64080e7          	jalr	-412(ra) # 80003e72 <dirlookup>
    80004016:	8a2a                	mv	s4,a0
    80004018:	dd51                	beqz	a0,80003fb4 <namex+0x92>
    iunlockput(ip);
    8000401a:	854e                	mv	a0,s3
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	bd4080e7          	jalr	-1068(ra) # 80003bf0 <iunlockput>
    ip = next;
    80004024:	89d2                	mv	s3,s4
  while(*path == '/')
    80004026:	0004c783          	lbu	a5,0(s1)
    8000402a:	05279763          	bne	a5,s2,80004078 <namex+0x156>
    path++;
    8000402e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004030:	0004c783          	lbu	a5,0(s1)
    80004034:	ff278de3          	beq	a5,s2,8000402e <namex+0x10c>
  if(*path == 0)
    80004038:	c79d                	beqz	a5,80004066 <namex+0x144>
    path++;
    8000403a:	85a6                	mv	a1,s1
  len = path - s;
    8000403c:	8a5e                	mv	s4,s7
    8000403e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004040:	01278963          	beq	a5,s2,80004052 <namex+0x130>
    80004044:	dfbd                	beqz	a5,80003fc2 <namex+0xa0>
    path++;
    80004046:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004048:	0004c783          	lbu	a5,0(s1)
    8000404c:	ff279ce3          	bne	a5,s2,80004044 <namex+0x122>
    80004050:	bf8d                	j	80003fc2 <namex+0xa0>
    memmove(name, s, len);
    80004052:	2601                	sext.w	a2,a2
    80004054:	8556                	mv	a0,s5
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	cea080e7          	jalr	-790(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000405e:	9a56                	add	s4,s4,s5
    80004060:	000a0023          	sb	zero,0(s4)
    80004064:	bf9d                	j	80003fda <namex+0xb8>
  if(nameiparent){
    80004066:	f20b03e3          	beqz	s6,80003f8c <namex+0x6a>
    iput(ip);
    8000406a:	854e                	mv	a0,s3
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	adc080e7          	jalr	-1316(ra) # 80003b48 <iput>
    return 0;
    80004074:	4981                	li	s3,0
    80004076:	bf19                	j	80003f8c <namex+0x6a>
  if(*path == 0)
    80004078:	d7fd                	beqz	a5,80004066 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000407a:	0004c783          	lbu	a5,0(s1)
    8000407e:	85a6                	mv	a1,s1
    80004080:	b7d1                	j	80004044 <namex+0x122>

0000000080004082 <dirlink>:
{
    80004082:	7139                	addi	sp,sp,-64
    80004084:	fc06                	sd	ra,56(sp)
    80004086:	f822                	sd	s0,48(sp)
    80004088:	f426                	sd	s1,40(sp)
    8000408a:	f04a                	sd	s2,32(sp)
    8000408c:	ec4e                	sd	s3,24(sp)
    8000408e:	e852                	sd	s4,16(sp)
    80004090:	0080                	addi	s0,sp,64
    80004092:	892a                	mv	s2,a0
    80004094:	8a2e                	mv	s4,a1
    80004096:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004098:	4601                	li	a2,0
    8000409a:	00000097          	auipc	ra,0x0
    8000409e:	dd8080e7          	jalr	-552(ra) # 80003e72 <dirlookup>
    800040a2:	e93d                	bnez	a0,80004118 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a4:	04c92483          	lw	s1,76(s2)
    800040a8:	c49d                	beqz	s1,800040d6 <dirlink+0x54>
    800040aa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ac:	4741                	li	a4,16
    800040ae:	86a6                	mv	a3,s1
    800040b0:	fc040613          	addi	a2,s0,-64
    800040b4:	4581                	li	a1,0
    800040b6:	854a                	mv	a0,s2
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	b8a080e7          	jalr	-1142(ra) # 80003c42 <readi>
    800040c0:	47c1                	li	a5,16
    800040c2:	06f51163          	bne	a0,a5,80004124 <dirlink+0xa2>
    if(de.inum == 0)
    800040c6:	fc045783          	lhu	a5,-64(s0)
    800040ca:	c791                	beqz	a5,800040d6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040cc:	24c1                	addiw	s1,s1,16
    800040ce:	04c92783          	lw	a5,76(s2)
    800040d2:	fcf4ede3          	bltu	s1,a5,800040ac <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040d6:	4639                	li	a2,14
    800040d8:	85d2                	mv	a1,s4
    800040da:	fc240513          	addi	a0,s0,-62
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	d16080e7          	jalr	-746(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040e6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ea:	4741                	li	a4,16
    800040ec:	86a6                	mv	a3,s1
    800040ee:	fc040613          	addi	a2,s0,-64
    800040f2:	4581                	li	a1,0
    800040f4:	854a                	mv	a0,s2
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	c44080e7          	jalr	-956(ra) # 80003d3a <writei>
    800040fe:	872a                	mv	a4,a0
    80004100:	47c1                	li	a5,16
  return 0;
    80004102:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004104:	02f71863          	bne	a4,a5,80004134 <dirlink+0xb2>
}
    80004108:	70e2                	ld	ra,56(sp)
    8000410a:	7442                	ld	s0,48(sp)
    8000410c:	74a2                	ld	s1,40(sp)
    8000410e:	7902                	ld	s2,32(sp)
    80004110:	69e2                	ld	s3,24(sp)
    80004112:	6a42                	ld	s4,16(sp)
    80004114:	6121                	addi	sp,sp,64
    80004116:	8082                	ret
    iput(ip);
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	a30080e7          	jalr	-1488(ra) # 80003b48 <iput>
    return -1;
    80004120:	557d                	li	a0,-1
    80004122:	b7dd                	j	80004108 <dirlink+0x86>
      panic("dirlink read");
    80004124:	00004517          	auipc	a0,0x4
    80004128:	59c50513          	addi	a0,a0,1436 # 800086c0 <syscalls+0x1e0>
    8000412c:	ffffc097          	auipc	ra,0xffffc
    80004130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("dirlink");
    80004134:	00004517          	auipc	a0,0x4
    80004138:	69c50513          	addi	a0,a0,1692 # 800087d0 <syscalls+0x2f0>
    8000413c:	ffffc097          	auipc	ra,0xffffc
    80004140:	402080e7          	jalr	1026(ra) # 8000053e <panic>

0000000080004144 <namei>:

struct inode*
namei(char *path)
{
    80004144:	1101                	addi	sp,sp,-32
    80004146:	ec06                	sd	ra,24(sp)
    80004148:	e822                	sd	s0,16(sp)
    8000414a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000414c:	fe040613          	addi	a2,s0,-32
    80004150:	4581                	li	a1,0
    80004152:	00000097          	auipc	ra,0x0
    80004156:	dd0080e7          	jalr	-560(ra) # 80003f22 <namex>
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	6105                	addi	sp,sp,32
    80004160:	8082                	ret

0000000080004162 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004162:	1141                	addi	sp,sp,-16
    80004164:	e406                	sd	ra,8(sp)
    80004166:	e022                	sd	s0,0(sp)
    80004168:	0800                	addi	s0,sp,16
    8000416a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000416c:	4585                	li	a1,1
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	db4080e7          	jalr	-588(ra) # 80003f22 <namex>
}
    80004176:	60a2                	ld	ra,8(sp)
    80004178:	6402                	ld	s0,0(sp)
    8000417a:	0141                	addi	sp,sp,16
    8000417c:	8082                	ret

000000008000417e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	e426                	sd	s1,8(sp)
    80004186:	e04a                	sd	s2,0(sp)
    80004188:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000418a:	0001d917          	auipc	s2,0x1d
    8000418e:	70690913          	addi	s2,s2,1798 # 80021890 <log>
    80004192:	01892583          	lw	a1,24(s2)
    80004196:	02892503          	lw	a0,40(s2)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	ff2080e7          	jalr	-14(ra) # 8000318c <bread>
    800041a2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041a4:	02c92683          	lw	a3,44(s2)
    800041a8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041aa:	02d05763          	blez	a3,800041d8 <write_head+0x5a>
    800041ae:	0001d797          	auipc	a5,0x1d
    800041b2:	71278793          	addi	a5,a5,1810 # 800218c0 <log+0x30>
    800041b6:	05c50713          	addi	a4,a0,92
    800041ba:	36fd                	addiw	a3,a3,-1
    800041bc:	1682                	slli	a3,a3,0x20
    800041be:	9281                	srli	a3,a3,0x20
    800041c0:	068a                	slli	a3,a3,0x2
    800041c2:	0001d617          	auipc	a2,0x1d
    800041c6:	70260613          	addi	a2,a2,1794 # 800218c4 <log+0x34>
    800041ca:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041cc:	4390                	lw	a2,0(a5)
    800041ce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d0:	0791                	addi	a5,a5,4
    800041d2:	0711                	addi	a4,a4,4
    800041d4:	fed79ce3          	bne	a5,a3,800041cc <write_head+0x4e>
  }
  bwrite(buf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	0a4080e7          	jalr	164(ra) # 8000327e <bwrite>
  brelse(buf);
    800041e2:	8526                	mv	a0,s1
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	0d8080e7          	jalr	216(ra) # 800032bc <brelse>
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f8:	0001d797          	auipc	a5,0x1d
    800041fc:	6c47a783          	lw	a5,1732(a5) # 800218bc <log+0x2c>
    80004200:	0af05d63          	blez	a5,800042ba <install_trans+0xc2>
{
    80004204:	7139                	addi	sp,sp,-64
    80004206:	fc06                	sd	ra,56(sp)
    80004208:	f822                	sd	s0,48(sp)
    8000420a:	f426                	sd	s1,40(sp)
    8000420c:	f04a                	sd	s2,32(sp)
    8000420e:	ec4e                	sd	s3,24(sp)
    80004210:	e852                	sd	s4,16(sp)
    80004212:	e456                	sd	s5,8(sp)
    80004214:	e05a                	sd	s6,0(sp)
    80004216:	0080                	addi	s0,sp,64
    80004218:	8b2a                	mv	s6,a0
    8000421a:	0001da97          	auipc	s5,0x1d
    8000421e:	6a6a8a93          	addi	s5,s5,1702 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004224:	0001d997          	auipc	s3,0x1d
    80004228:	66c98993          	addi	s3,s3,1644 # 80021890 <log>
    8000422c:	a035                	j	80004258 <install_trans+0x60>
      bunpin(dbuf);
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	166080e7          	jalr	358(ra) # 80003396 <bunpin>
    brelse(lbuf);
    80004238:	854a                	mv	a0,s2
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	082080e7          	jalr	130(ra) # 800032bc <brelse>
    brelse(dbuf);
    80004242:	8526                	mv	a0,s1
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	078080e7          	jalr	120(ra) # 800032bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424c:	2a05                	addiw	s4,s4,1
    8000424e:	0a91                	addi	s5,s5,4
    80004250:	02c9a783          	lw	a5,44(s3)
    80004254:	04fa5963          	bge	s4,a5,800042a6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004258:	0189a583          	lw	a1,24(s3)
    8000425c:	014585bb          	addw	a1,a1,s4
    80004260:	2585                	addiw	a1,a1,1
    80004262:	0289a503          	lw	a0,40(s3)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	f26080e7          	jalr	-218(ra) # 8000318c <bread>
    8000426e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004270:	000aa583          	lw	a1,0(s5)
    80004274:	0289a503          	lw	a0,40(s3)
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	f14080e7          	jalr	-236(ra) # 8000318c <bread>
    80004280:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004282:	40000613          	li	a2,1024
    80004286:	05890593          	addi	a1,s2,88
    8000428a:	05850513          	addi	a0,a0,88
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ab2080e7          	jalr	-1358(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	fe6080e7          	jalr	-26(ra) # 8000327e <bwrite>
    if(recovering == 0)
    800042a0:	f80b1ce3          	bnez	s6,80004238 <install_trans+0x40>
    800042a4:	b769                	j	8000422e <install_trans+0x36>
}
    800042a6:	70e2                	ld	ra,56(sp)
    800042a8:	7442                	ld	s0,48(sp)
    800042aa:	74a2                	ld	s1,40(sp)
    800042ac:	7902                	ld	s2,32(sp)
    800042ae:	69e2                	ld	s3,24(sp)
    800042b0:	6a42                	ld	s4,16(sp)
    800042b2:	6aa2                	ld	s5,8(sp)
    800042b4:	6b02                	ld	s6,0(sp)
    800042b6:	6121                	addi	sp,sp,64
    800042b8:	8082                	ret
    800042ba:	8082                	ret

00000000800042bc <initlog>:
{
    800042bc:	7179                	addi	sp,sp,-48
    800042be:	f406                	sd	ra,40(sp)
    800042c0:	f022                	sd	s0,32(sp)
    800042c2:	ec26                	sd	s1,24(sp)
    800042c4:	e84a                	sd	s2,16(sp)
    800042c6:	e44e                	sd	s3,8(sp)
    800042c8:	1800                	addi	s0,sp,48
    800042ca:	892a                	mv	s2,a0
    800042cc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ce:	0001d497          	auipc	s1,0x1d
    800042d2:	5c248493          	addi	s1,s1,1474 # 80021890 <log>
    800042d6:	00004597          	auipc	a1,0x4
    800042da:	3fa58593          	addi	a1,a1,1018 # 800086d0 <syscalls+0x1f0>
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	874080e7          	jalr	-1932(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042e8:	0149a583          	lw	a1,20(s3)
    800042ec:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042ee:	0109a783          	lw	a5,16(s3)
    800042f2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042f4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042f8:	854a                	mv	a0,s2
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	e92080e7          	jalr	-366(ra) # 8000318c <bread>
  log.lh.n = lh->n;
    80004302:	4d3c                	lw	a5,88(a0)
    80004304:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004306:	02f05563          	blez	a5,80004330 <initlog+0x74>
    8000430a:	05c50713          	addi	a4,a0,92
    8000430e:	0001d697          	auipc	a3,0x1d
    80004312:	5b268693          	addi	a3,a3,1458 # 800218c0 <log+0x30>
    80004316:	37fd                	addiw	a5,a5,-1
    80004318:	1782                	slli	a5,a5,0x20
    8000431a:	9381                	srli	a5,a5,0x20
    8000431c:	078a                	slli	a5,a5,0x2
    8000431e:	06050613          	addi	a2,a0,96
    80004322:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004324:	4310                	lw	a2,0(a4)
    80004326:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004328:	0711                	addi	a4,a4,4
    8000432a:	0691                	addi	a3,a3,4
    8000432c:	fef71ce3          	bne	a4,a5,80004324 <initlog+0x68>
  brelse(buf);
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	f8c080e7          	jalr	-116(ra) # 800032bc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004338:	4505                	li	a0,1
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	ebe080e7          	jalr	-322(ra) # 800041f8 <install_trans>
  log.lh.n = 0;
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	5607ad23          	sw	zero,1402(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	e34080e7          	jalr	-460(ra) # 8000417e <write_head>
}
    80004352:	70a2                	ld	ra,40(sp)
    80004354:	7402                	ld	s0,32(sp)
    80004356:	64e2                	ld	s1,24(sp)
    80004358:	6942                	ld	s2,16(sp)
    8000435a:	69a2                	ld	s3,8(sp)
    8000435c:	6145                	addi	sp,sp,48
    8000435e:	8082                	ret

0000000080004360 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000436c:	0001d517          	auipc	a0,0x1d
    80004370:	52450513          	addi	a0,a0,1316 # 80021890 <log>
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	870080e7          	jalr	-1936(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000437c:	0001d497          	auipc	s1,0x1d
    80004380:	51448493          	addi	s1,s1,1300 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004384:	4979                	li	s2,30
    80004386:	a039                	j	80004394 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004388:	85a6                	mv	a1,s1
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	fae080e7          	jalr	-82(ra) # 8000233a <sleep>
    if(log.committing){
    80004394:	50dc                	lw	a5,36(s1)
    80004396:	fbed                	bnez	a5,80004388 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004398:	509c                	lw	a5,32(s1)
    8000439a:	0017871b          	addiw	a4,a5,1
    8000439e:	0007069b          	sext.w	a3,a4
    800043a2:	0027179b          	slliw	a5,a4,0x2
    800043a6:	9fb9                	addw	a5,a5,a4
    800043a8:	0017979b          	slliw	a5,a5,0x1
    800043ac:	54d8                	lw	a4,44(s1)
    800043ae:	9fb9                	addw	a5,a5,a4
    800043b0:	00f95963          	bge	s2,a5,800043c2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043b4:	85a6                	mv	a1,s1
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffe097          	auipc	ra,0xffffe
    800043bc:	f82080e7          	jalr	-126(ra) # 8000233a <sleep>
    800043c0:	bfd1                	j	80004394 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043c2:	0001d517          	auipc	a0,0x1d
    800043c6:	4ce50513          	addi	a0,a0,1230 # 80021890 <log>
    800043ca:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043d4:	60e2                	ld	ra,24(sp)
    800043d6:	6442                	ld	s0,16(sp)
    800043d8:	64a2                	ld	s1,8(sp)
    800043da:	6902                	ld	s2,0(sp)
    800043dc:	6105                	addi	sp,sp,32
    800043de:	8082                	ret

00000000800043e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043e0:	7139                	addi	sp,sp,-64
    800043e2:	fc06                	sd	ra,56(sp)
    800043e4:	f822                	sd	s0,48(sp)
    800043e6:	f426                	sd	s1,40(sp)
    800043e8:	f04a                	sd	s2,32(sp)
    800043ea:	ec4e                	sd	s3,24(sp)
    800043ec:	e852                	sd	s4,16(sp)
    800043ee:	e456                	sd	s5,8(sp)
    800043f0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043f2:	0001d497          	auipc	s1,0x1d
    800043f6:	49e48493          	addi	s1,s1,1182 # 80021890 <log>
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	7e8080e7          	jalr	2024(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004404:	509c                	lw	a5,32(s1)
    80004406:	37fd                	addiw	a5,a5,-1
    80004408:	0007891b          	sext.w	s2,a5
    8000440c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000440e:	50dc                	lw	a5,36(s1)
    80004410:	efb9                	bnez	a5,8000446e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004412:	06091663          	bnez	s2,8000447e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004416:	0001d497          	auipc	s1,0x1d
    8000441a:	47a48493          	addi	s1,s1,1146 # 80021890 <log>
    8000441e:	4785                	li	a5,1
    80004420:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004422:	8526                	mv	a0,s1
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000442c:	54dc                	lw	a5,44(s1)
    8000442e:	06f04763          	bgtz	a5,8000449c <end_op+0xbc>
    acquire(&log.lock);
    80004432:	0001d497          	auipc	s1,0x1d
    80004436:	45e48493          	addi	s1,s1,1118 # 80021890 <log>
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004444:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffe097          	auipc	ra,0xffffe
    8000444e:	0c2080e7          	jalr	194(ra) # 8000250c <wakeup>
    release(&log.lock);
    80004452:	8526                	mv	a0,s1
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
}
    8000445c:	70e2                	ld	ra,56(sp)
    8000445e:	7442                	ld	s0,48(sp)
    80004460:	74a2                	ld	s1,40(sp)
    80004462:	7902                	ld	s2,32(sp)
    80004464:	69e2                	ld	s3,24(sp)
    80004466:	6a42                	ld	s4,16(sp)
    80004468:	6aa2                	ld	s5,8(sp)
    8000446a:	6121                	addi	sp,sp,64
    8000446c:	8082                	ret
    panic("log.committing");
    8000446e:	00004517          	auipc	a0,0x4
    80004472:	26a50513          	addi	a0,a0,618 # 800086d8 <syscalls+0x1f8>
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>
    wakeup(&log);
    8000447e:	0001d497          	auipc	s1,0x1d
    80004482:	41248493          	addi	s1,s1,1042 # 80021890 <log>
    80004486:	8526                	mv	a0,s1
    80004488:	ffffe097          	auipc	ra,0xffffe
    8000448c:	084080e7          	jalr	132(ra) # 8000250c <wakeup>
  release(&log.lock);
    80004490:	8526                	mv	a0,s1
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
  if(do_commit){
    8000449a:	b7c9                	j	8000445c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000449c:	0001da97          	auipc	s5,0x1d
    800044a0:	424a8a93          	addi	s5,s5,1060 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044a4:	0001da17          	auipc	s4,0x1d
    800044a8:	3eca0a13          	addi	s4,s4,1004 # 80021890 <log>
    800044ac:	018a2583          	lw	a1,24(s4)
    800044b0:	012585bb          	addw	a1,a1,s2
    800044b4:	2585                	addiw	a1,a1,1
    800044b6:	028a2503          	lw	a0,40(s4)
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	cd2080e7          	jalr	-814(ra) # 8000318c <bread>
    800044c2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044c4:	000aa583          	lw	a1,0(s5)
    800044c8:	028a2503          	lw	a0,40(s4)
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	cc0080e7          	jalr	-832(ra) # 8000318c <bread>
    800044d4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044d6:	40000613          	li	a2,1024
    800044da:	05850593          	addi	a1,a0,88
    800044de:	05848513          	addi	a0,s1,88
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	85e080e7          	jalr	-1954(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044ea:	8526                	mv	a0,s1
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	d92080e7          	jalr	-622(ra) # 8000327e <bwrite>
    brelse(from);
    800044f4:	854e                	mv	a0,s3
    800044f6:	fffff097          	auipc	ra,0xfffff
    800044fa:	dc6080e7          	jalr	-570(ra) # 800032bc <brelse>
    brelse(to);
    800044fe:	8526                	mv	a0,s1
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	dbc080e7          	jalr	-580(ra) # 800032bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004508:	2905                	addiw	s2,s2,1
    8000450a:	0a91                	addi	s5,s5,4
    8000450c:	02ca2783          	lw	a5,44(s4)
    80004510:	f8f94ee3          	blt	s2,a5,800044ac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004514:	00000097          	auipc	ra,0x0
    80004518:	c6a080e7          	jalr	-918(ra) # 8000417e <write_head>
    install_trans(0); // Now install writes to home locations
    8000451c:	4501                	li	a0,0
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	cda080e7          	jalr	-806(ra) # 800041f8 <install_trans>
    log.lh.n = 0;
    80004526:	0001d797          	auipc	a5,0x1d
    8000452a:	3807ab23          	sw	zero,918(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	c50080e7          	jalr	-944(ra) # 8000417e <write_head>
    80004536:	bdf5                	j	80004432 <end_op+0x52>

0000000080004538 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	e426                	sd	s1,8(sp)
    80004540:	e04a                	sd	s2,0(sp)
    80004542:	1000                	addi	s0,sp,32
    80004544:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004546:	0001d917          	auipc	s2,0x1d
    8000454a:	34a90913          	addi	s2,s2,842 # 80021890 <log>
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004558:	02c92603          	lw	a2,44(s2)
    8000455c:	47f5                	li	a5,29
    8000455e:	06c7c563          	blt	a5,a2,800045c8 <log_write+0x90>
    80004562:	0001d797          	auipc	a5,0x1d
    80004566:	34a7a783          	lw	a5,842(a5) # 800218ac <log+0x1c>
    8000456a:	37fd                	addiw	a5,a5,-1
    8000456c:	04f65e63          	bge	a2,a5,800045c8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004570:	0001d797          	auipc	a5,0x1d
    80004574:	3407a783          	lw	a5,832(a5) # 800218b0 <log+0x20>
    80004578:	06f05063          	blez	a5,800045d8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000457c:	4781                	li	a5,0
    8000457e:	06c05563          	blez	a2,800045e8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004582:	44cc                	lw	a1,12(s1)
    80004584:	0001d717          	auipc	a4,0x1d
    80004588:	33c70713          	addi	a4,a4,828 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000458c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000458e:	4314                	lw	a3,0(a4)
    80004590:	04b68c63          	beq	a3,a1,800045e8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004594:	2785                	addiw	a5,a5,1
    80004596:	0711                	addi	a4,a4,4
    80004598:	fef61be3          	bne	a2,a5,8000458e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000459c:	0621                	addi	a2,a2,8
    8000459e:	060a                	slli	a2,a2,0x2
    800045a0:	0001d797          	auipc	a5,0x1d
    800045a4:	2f078793          	addi	a5,a5,752 # 80021890 <log>
    800045a8:	963e                	add	a2,a2,a5
    800045aa:	44dc                	lw	a5,12(s1)
    800045ac:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045ae:	8526                	mv	a0,s1
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	daa080e7          	jalr	-598(ra) # 8000335a <bpin>
    log.lh.n++;
    800045b8:	0001d717          	auipc	a4,0x1d
    800045bc:	2d870713          	addi	a4,a4,728 # 80021890 <log>
    800045c0:	575c                	lw	a5,44(a4)
    800045c2:	2785                	addiw	a5,a5,1
    800045c4:	d75c                	sw	a5,44(a4)
    800045c6:	a835                	j	80004602 <log_write+0xca>
    panic("too big a transaction");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	12050513          	addi	a0,a0,288 # 800086e8 <syscalls+0x208>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045d8:	00004517          	auipc	a0,0x4
    800045dc:	12850513          	addi	a0,a0,296 # 80008700 <syscalls+0x220>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	f5e080e7          	jalr	-162(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045e8:	00878713          	addi	a4,a5,8
    800045ec:	00271693          	slli	a3,a4,0x2
    800045f0:	0001d717          	auipc	a4,0x1d
    800045f4:	2a070713          	addi	a4,a4,672 # 80021890 <log>
    800045f8:	9736                	add	a4,a4,a3
    800045fa:	44d4                	lw	a3,12(s1)
    800045fc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045fe:	faf608e3          	beq	a2,a5,800045ae <log_write+0x76>
  }
  release(&log.lock);
    80004602:	0001d517          	auipc	a0,0x1d
    80004606:	28e50513          	addi	a0,a0,654 # 80021890 <log>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	68e080e7          	jalr	1678(ra) # 80000c98 <release>
}
    80004612:	60e2                	ld	ra,24(sp)
    80004614:	6442                	ld	s0,16(sp)
    80004616:	64a2                	ld	s1,8(sp)
    80004618:	6902                	ld	s2,0(sp)
    8000461a:	6105                	addi	sp,sp,32
    8000461c:	8082                	ret

000000008000461e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000461e:	1101                	addi	sp,sp,-32
    80004620:	ec06                	sd	ra,24(sp)
    80004622:	e822                	sd	s0,16(sp)
    80004624:	e426                	sd	s1,8(sp)
    80004626:	e04a                	sd	s2,0(sp)
    80004628:	1000                	addi	s0,sp,32
    8000462a:	84aa                	mv	s1,a0
    8000462c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000462e:	00004597          	auipc	a1,0x4
    80004632:	0f258593          	addi	a1,a1,242 # 80008720 <syscalls+0x240>
    80004636:	0521                	addi	a0,a0,8
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	51c080e7          	jalr	1308(ra) # 80000b54 <initlock>
  lk->name = name;
    80004640:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004644:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004648:	0204a423          	sw	zero,40(s1)
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	e04a                	sd	s2,0(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004666:	00850913          	addi	s2,a0,8
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004674:	409c                	lw	a5,0(s1)
    80004676:	cb89                	beqz	a5,80004688 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004678:	85ca                	mv	a1,s2
    8000467a:	8526                	mv	a0,s1
    8000467c:	ffffe097          	auipc	ra,0xffffe
    80004680:	cbe080e7          	jalr	-834(ra) # 8000233a <sleep>
  while (lk->locked) {
    80004684:	409c                	lw	a5,0(s1)
    80004686:	fbed                	bnez	a5,80004678 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004688:	4785                	li	a5,1
    8000468a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000468c:	ffffd097          	auipc	ra,0xffffd
    80004690:	5e8080e7          	jalr	1512(ra) # 80001c74 <myproc>
    80004694:	591c                	lw	a5,48(a0)
    80004696:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004698:	854a                	mv	a0,s2
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	5fe080e7          	jalr	1534(ra) # 80000c98 <release>
}
    800046a2:	60e2                	ld	ra,24(sp)
    800046a4:	6442                	ld	s0,16(sp)
    800046a6:	64a2                	ld	s1,8(sp)
    800046a8:	6902                	ld	s2,0(sp)
    800046aa:	6105                	addi	sp,sp,32
    800046ac:	8082                	ret

00000000800046ae <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046ae:	1101                	addi	sp,sp,-32
    800046b0:	ec06                	sd	ra,24(sp)
    800046b2:	e822                	sd	s0,16(sp)
    800046b4:	e426                	sd	s1,8(sp)
    800046b6:	e04a                	sd	s2,0(sp)
    800046b8:	1000                	addi	s0,sp,32
    800046ba:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046bc:	00850913          	addi	s2,a0,8
    800046c0:	854a                	mv	a0,s2
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	522080e7          	jalr	1314(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800046ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ce:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffe097          	auipc	ra,0xffffe
    800046d8:	e38080e7          	jalr	-456(ra) # 8000250c <wakeup>
  release(&lk->lk);
    800046dc:	854a                	mv	a0,s2
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5ba080e7          	jalr	1466(ra) # 80000c98 <release>
}
    800046e6:	60e2                	ld	ra,24(sp)
    800046e8:	6442                	ld	s0,16(sp)
    800046ea:	64a2                	ld	s1,8(sp)
    800046ec:	6902                	ld	s2,0(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret

00000000800046f2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046f2:	7179                	addi	sp,sp,-48
    800046f4:	f406                	sd	ra,40(sp)
    800046f6:	f022                	sd	s0,32(sp)
    800046f8:	ec26                	sd	s1,24(sp)
    800046fa:	e84a                	sd	s2,16(sp)
    800046fc:	e44e                	sd	s3,8(sp)
    800046fe:	1800                	addi	s0,sp,48
    80004700:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004702:	00850913          	addi	s2,a0,8
    80004706:	854a                	mv	a0,s2
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	4dc080e7          	jalr	1244(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004710:	409c                	lw	a5,0(s1)
    80004712:	ef99                	bnez	a5,80004730 <holdingsleep+0x3e>
    80004714:	4481                	li	s1,0
  release(&lk->lk);
    80004716:	854a                	mv	a0,s2
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	580080e7          	jalr	1408(ra) # 80000c98 <release>
  return r;
}
    80004720:	8526                	mv	a0,s1
    80004722:	70a2                	ld	ra,40(sp)
    80004724:	7402                	ld	s0,32(sp)
    80004726:	64e2                	ld	s1,24(sp)
    80004728:	6942                	ld	s2,16(sp)
    8000472a:	69a2                	ld	s3,8(sp)
    8000472c:	6145                	addi	sp,sp,48
    8000472e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004730:	0284a983          	lw	s3,40(s1)
    80004734:	ffffd097          	auipc	ra,0xffffd
    80004738:	540080e7          	jalr	1344(ra) # 80001c74 <myproc>
    8000473c:	5904                	lw	s1,48(a0)
    8000473e:	413484b3          	sub	s1,s1,s3
    80004742:	0014b493          	seqz	s1,s1
    80004746:	bfc1                	j	80004716 <holdingsleep+0x24>

0000000080004748 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004748:	1141                	addi	sp,sp,-16
    8000474a:	e406                	sd	ra,8(sp)
    8000474c:	e022                	sd	s0,0(sp)
    8000474e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004750:	00004597          	auipc	a1,0x4
    80004754:	fe058593          	addi	a1,a1,-32 # 80008730 <syscalls+0x250>
    80004758:	0001d517          	auipc	a0,0x1d
    8000475c:	28050513          	addi	a0,a0,640 # 800219d8 <ftable>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	3f4080e7          	jalr	1012(ra) # 80000b54 <initlock>
}
    80004768:	60a2                	ld	ra,8(sp)
    8000476a:	6402                	ld	s0,0(sp)
    8000476c:	0141                	addi	sp,sp,16
    8000476e:	8082                	ret

0000000080004770 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004770:	1101                	addi	sp,sp,-32
    80004772:	ec06                	sd	ra,24(sp)
    80004774:	e822                	sd	s0,16(sp)
    80004776:	e426                	sd	s1,8(sp)
    80004778:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000477a:	0001d517          	auipc	a0,0x1d
    8000477e:	25e50513          	addi	a0,a0,606 # 800219d8 <ftable>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	462080e7          	jalr	1122(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000478a:	0001d497          	auipc	s1,0x1d
    8000478e:	26648493          	addi	s1,s1,614 # 800219f0 <ftable+0x18>
    80004792:	0001e717          	auipc	a4,0x1e
    80004796:	1fe70713          	addi	a4,a4,510 # 80022990 <ftable+0xfb8>
    if(f->ref == 0){
    8000479a:	40dc                	lw	a5,4(s1)
    8000479c:	cf99                	beqz	a5,800047ba <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000479e:	02848493          	addi	s1,s1,40
    800047a2:	fee49ce3          	bne	s1,a4,8000479a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047a6:	0001d517          	auipc	a0,0x1d
    800047aa:	23250513          	addi	a0,a0,562 # 800219d8 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	4ea080e7          	jalr	1258(ra) # 80000c98 <release>
  return 0;
    800047b6:	4481                	li	s1,0
    800047b8:	a819                	j	800047ce <filealloc+0x5e>
      f->ref = 1;
    800047ba:	4785                	li	a5,1
    800047bc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047be:	0001d517          	auipc	a0,0x1d
    800047c2:	21a50513          	addi	a0,a0,538 # 800219d8 <ftable>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	4d2080e7          	jalr	1234(ra) # 80000c98 <release>
}
    800047ce:	8526                	mv	a0,s1
    800047d0:	60e2                	ld	ra,24(sp)
    800047d2:	6442                	ld	s0,16(sp)
    800047d4:	64a2                	ld	s1,8(sp)
    800047d6:	6105                	addi	sp,sp,32
    800047d8:	8082                	ret

00000000800047da <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047da:	1101                	addi	sp,sp,-32
    800047dc:	ec06                	sd	ra,24(sp)
    800047de:	e822                	sd	s0,16(sp)
    800047e0:	e426                	sd	s1,8(sp)
    800047e2:	1000                	addi	s0,sp,32
    800047e4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047e6:	0001d517          	auipc	a0,0x1d
    800047ea:	1f250513          	addi	a0,a0,498 # 800219d8 <ftable>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047f6:	40dc                	lw	a5,4(s1)
    800047f8:	02f05263          	blez	a5,8000481c <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047fc:	2785                	addiw	a5,a5,1
    800047fe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004800:	0001d517          	auipc	a0,0x1d
    80004804:	1d850513          	addi	a0,a0,472 # 800219d8 <ftable>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	490080e7          	jalr	1168(ra) # 80000c98 <release>
  return f;
}
    80004810:	8526                	mv	a0,s1
    80004812:	60e2                	ld	ra,24(sp)
    80004814:	6442                	ld	s0,16(sp)
    80004816:	64a2                	ld	s1,8(sp)
    80004818:	6105                	addi	sp,sp,32
    8000481a:	8082                	ret
    panic("filedup");
    8000481c:	00004517          	auipc	a0,0x4
    80004820:	f1c50513          	addi	a0,a0,-228 # 80008738 <syscalls+0x258>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	d1a080e7          	jalr	-742(ra) # 8000053e <panic>

000000008000482c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000482c:	7139                	addi	sp,sp,-64
    8000482e:	fc06                	sd	ra,56(sp)
    80004830:	f822                	sd	s0,48(sp)
    80004832:	f426                	sd	s1,40(sp)
    80004834:	f04a                	sd	s2,32(sp)
    80004836:	ec4e                	sd	s3,24(sp)
    80004838:	e852                	sd	s4,16(sp)
    8000483a:	e456                	sd	s5,8(sp)
    8000483c:	0080                	addi	s0,sp,64
    8000483e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004840:	0001d517          	auipc	a0,0x1d
    80004844:	19850513          	addi	a0,a0,408 # 800219d8 <ftable>
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	39c080e7          	jalr	924(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004850:	40dc                	lw	a5,4(s1)
    80004852:	06f05163          	blez	a5,800048b4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004856:	37fd                	addiw	a5,a5,-1
    80004858:	0007871b          	sext.w	a4,a5
    8000485c:	c0dc                	sw	a5,4(s1)
    8000485e:	06e04363          	bgtz	a4,800048c4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004862:	0004a903          	lw	s2,0(s1)
    80004866:	0094ca83          	lbu	s5,9(s1)
    8000486a:	0104ba03          	ld	s4,16(s1)
    8000486e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004872:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004876:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000487a:	0001d517          	auipc	a0,0x1d
    8000487e:	15e50513          	addi	a0,a0,350 # 800219d8 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	416080e7          	jalr	1046(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000488a:	4785                	li	a5,1
    8000488c:	04f90d63          	beq	s2,a5,800048e6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004890:	3979                	addiw	s2,s2,-2
    80004892:	4785                	li	a5,1
    80004894:	0527e063          	bltu	a5,s2,800048d4 <fileclose+0xa8>
    begin_op();
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	ac8080e7          	jalr	-1336(ra) # 80004360 <begin_op>
    iput(ff.ip);
    800048a0:	854e                	mv	a0,s3
    800048a2:	fffff097          	auipc	ra,0xfffff
    800048a6:	2a6080e7          	jalr	678(ra) # 80003b48 <iput>
    end_op();
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	b36080e7          	jalr	-1226(ra) # 800043e0 <end_op>
    800048b2:	a00d                	j	800048d4 <fileclose+0xa8>
    panic("fileclose");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	e8c50513          	addi	a0,a0,-372 # 80008740 <syscalls+0x260>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048c4:	0001d517          	auipc	a0,0x1d
    800048c8:	11450513          	addi	a0,a0,276 # 800219d8 <ftable>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3cc080e7          	jalr	972(ra) # 80000c98 <release>
  }
}
    800048d4:	70e2                	ld	ra,56(sp)
    800048d6:	7442                	ld	s0,48(sp)
    800048d8:	74a2                	ld	s1,40(sp)
    800048da:	7902                	ld	s2,32(sp)
    800048dc:	69e2                	ld	s3,24(sp)
    800048de:	6a42                	ld	s4,16(sp)
    800048e0:	6aa2                	ld	s5,8(sp)
    800048e2:	6121                	addi	sp,sp,64
    800048e4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048e6:	85d6                	mv	a1,s5
    800048e8:	8552                	mv	a0,s4
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	34c080e7          	jalr	844(ra) # 80004c36 <pipeclose>
    800048f2:	b7cd                	j	800048d4 <fileclose+0xa8>

00000000800048f4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048f4:	715d                	addi	sp,sp,-80
    800048f6:	e486                	sd	ra,72(sp)
    800048f8:	e0a2                	sd	s0,64(sp)
    800048fa:	fc26                	sd	s1,56(sp)
    800048fc:	f84a                	sd	s2,48(sp)
    800048fe:	f44e                	sd	s3,40(sp)
    80004900:	0880                	addi	s0,sp,80
    80004902:	84aa                	mv	s1,a0
    80004904:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004906:	ffffd097          	auipc	ra,0xffffd
    8000490a:	36e080e7          	jalr	878(ra) # 80001c74 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000490e:	409c                	lw	a5,0(s1)
    80004910:	37f9                	addiw	a5,a5,-2
    80004912:	4705                	li	a4,1
    80004914:	04f76763          	bltu	a4,a5,80004962 <filestat+0x6e>
    80004918:	892a                	mv	s2,a0
    ilock(f->ip);
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	072080e7          	jalr	114(ra) # 8000398e <ilock>
    stati(f->ip, &st);
    80004924:	fb840593          	addi	a1,s0,-72
    80004928:	6c88                	ld	a0,24(s1)
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	2ee080e7          	jalr	750(ra) # 80003c18 <stati>
    iunlock(f->ip);
    80004932:	6c88                	ld	a0,24(s1)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	11c080e7          	jalr	284(ra) # 80003a50 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000493c:	46e1                	li	a3,24
    8000493e:	fb840613          	addi	a2,s0,-72
    80004942:	85ce                	mv	a1,s3
    80004944:	06893503          	ld	a0,104(s2)
    80004948:	ffffd097          	auipc	ra,0xffffd
    8000494c:	d2a080e7          	jalr	-726(ra) # 80001672 <copyout>
    80004950:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004954:	60a6                	ld	ra,72(sp)
    80004956:	6406                	ld	s0,64(sp)
    80004958:	74e2                	ld	s1,56(sp)
    8000495a:	7942                	ld	s2,48(sp)
    8000495c:	79a2                	ld	s3,40(sp)
    8000495e:	6161                	addi	sp,sp,80
    80004960:	8082                	ret
  return -1;
    80004962:	557d                	li	a0,-1
    80004964:	bfc5                	j	80004954 <filestat+0x60>

0000000080004966 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004966:	7179                	addi	sp,sp,-48
    80004968:	f406                	sd	ra,40(sp)
    8000496a:	f022                	sd	s0,32(sp)
    8000496c:	ec26                	sd	s1,24(sp)
    8000496e:	e84a                	sd	s2,16(sp)
    80004970:	e44e                	sd	s3,8(sp)
    80004972:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004974:	00854783          	lbu	a5,8(a0)
    80004978:	c3d5                	beqz	a5,80004a1c <fileread+0xb6>
    8000497a:	84aa                	mv	s1,a0
    8000497c:	89ae                	mv	s3,a1
    8000497e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004980:	411c                	lw	a5,0(a0)
    80004982:	4705                	li	a4,1
    80004984:	04e78963          	beq	a5,a4,800049d6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004988:	470d                	li	a4,3
    8000498a:	04e78d63          	beq	a5,a4,800049e4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000498e:	4709                	li	a4,2
    80004990:	06e79e63          	bne	a5,a4,80004a0c <fileread+0xa6>
    ilock(f->ip);
    80004994:	6d08                	ld	a0,24(a0)
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	ff8080e7          	jalr	-8(ra) # 8000398e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000499e:	874a                	mv	a4,s2
    800049a0:	5094                	lw	a3,32(s1)
    800049a2:	864e                	mv	a2,s3
    800049a4:	4585                	li	a1,1
    800049a6:	6c88                	ld	a0,24(s1)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	29a080e7          	jalr	666(ra) # 80003c42 <readi>
    800049b0:	892a                	mv	s2,a0
    800049b2:	00a05563          	blez	a0,800049bc <fileread+0x56>
      f->off += r;
    800049b6:	509c                	lw	a5,32(s1)
    800049b8:	9fa9                	addw	a5,a5,a0
    800049ba:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049bc:	6c88                	ld	a0,24(s1)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	092080e7          	jalr	146(ra) # 80003a50 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049c6:	854a                	mv	a0,s2
    800049c8:	70a2                	ld	ra,40(sp)
    800049ca:	7402                	ld	s0,32(sp)
    800049cc:	64e2                	ld	s1,24(sp)
    800049ce:	6942                	ld	s2,16(sp)
    800049d0:	69a2                	ld	s3,8(sp)
    800049d2:	6145                	addi	sp,sp,48
    800049d4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049d6:	6908                	ld	a0,16(a0)
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	3c8080e7          	jalr	968(ra) # 80004da0 <piperead>
    800049e0:	892a                	mv	s2,a0
    800049e2:	b7d5                	j	800049c6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049e4:	02451783          	lh	a5,36(a0)
    800049e8:	03079693          	slli	a3,a5,0x30
    800049ec:	92c1                	srli	a3,a3,0x30
    800049ee:	4725                	li	a4,9
    800049f0:	02d76863          	bltu	a4,a3,80004a20 <fileread+0xba>
    800049f4:	0792                	slli	a5,a5,0x4
    800049f6:	0001d717          	auipc	a4,0x1d
    800049fa:	f4270713          	addi	a4,a4,-190 # 80021938 <devsw>
    800049fe:	97ba                	add	a5,a5,a4
    80004a00:	639c                	ld	a5,0(a5)
    80004a02:	c38d                	beqz	a5,80004a24 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a04:	4505                	li	a0,1
    80004a06:	9782                	jalr	a5
    80004a08:	892a                	mv	s2,a0
    80004a0a:	bf75                	j	800049c6 <fileread+0x60>
    panic("fileread");
    80004a0c:	00004517          	auipc	a0,0x4
    80004a10:	d4450513          	addi	a0,a0,-700 # 80008750 <syscalls+0x270>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>
    return -1;
    80004a1c:	597d                	li	s2,-1
    80004a1e:	b765                	j	800049c6 <fileread+0x60>
      return -1;
    80004a20:	597d                	li	s2,-1
    80004a22:	b755                	j	800049c6 <fileread+0x60>
    80004a24:	597d                	li	s2,-1
    80004a26:	b745                	j	800049c6 <fileread+0x60>

0000000080004a28 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a28:	715d                	addi	sp,sp,-80
    80004a2a:	e486                	sd	ra,72(sp)
    80004a2c:	e0a2                	sd	s0,64(sp)
    80004a2e:	fc26                	sd	s1,56(sp)
    80004a30:	f84a                	sd	s2,48(sp)
    80004a32:	f44e                	sd	s3,40(sp)
    80004a34:	f052                	sd	s4,32(sp)
    80004a36:	ec56                	sd	s5,24(sp)
    80004a38:	e85a                	sd	s6,16(sp)
    80004a3a:	e45e                	sd	s7,8(sp)
    80004a3c:	e062                	sd	s8,0(sp)
    80004a3e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a40:	00954783          	lbu	a5,9(a0)
    80004a44:	10078663          	beqz	a5,80004b50 <filewrite+0x128>
    80004a48:	892a                	mv	s2,a0
    80004a4a:	8aae                	mv	s5,a1
    80004a4c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a4e:	411c                	lw	a5,0(a0)
    80004a50:	4705                	li	a4,1
    80004a52:	02e78263          	beq	a5,a4,80004a76 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a56:	470d                	li	a4,3
    80004a58:	02e78663          	beq	a5,a4,80004a84 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a5c:	4709                	li	a4,2
    80004a5e:	0ee79163          	bne	a5,a4,80004b40 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a62:	0ac05d63          	blez	a2,80004b1c <filewrite+0xf4>
    int i = 0;
    80004a66:	4981                	li	s3,0
    80004a68:	6b05                	lui	s6,0x1
    80004a6a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a6e:	6b85                	lui	s7,0x1
    80004a70:	c00b8b9b          	addiw	s7,s7,-1024
    80004a74:	a861                	j	80004b0c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a76:	6908                	ld	a0,16(a0)
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	22e080e7          	jalr	558(ra) # 80004ca6 <pipewrite>
    80004a80:	8a2a                	mv	s4,a0
    80004a82:	a045                	j	80004b22 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a84:	02451783          	lh	a5,36(a0)
    80004a88:	03079693          	slli	a3,a5,0x30
    80004a8c:	92c1                	srli	a3,a3,0x30
    80004a8e:	4725                	li	a4,9
    80004a90:	0cd76263          	bltu	a4,a3,80004b54 <filewrite+0x12c>
    80004a94:	0792                	slli	a5,a5,0x4
    80004a96:	0001d717          	auipc	a4,0x1d
    80004a9a:	ea270713          	addi	a4,a4,-350 # 80021938 <devsw>
    80004a9e:	97ba                	add	a5,a5,a4
    80004aa0:	679c                	ld	a5,8(a5)
    80004aa2:	cbdd                	beqz	a5,80004b58 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004aa4:	4505                	li	a0,1
    80004aa6:	9782                	jalr	a5
    80004aa8:	8a2a                	mv	s4,a0
    80004aaa:	a8a5                	j	80004b22 <filewrite+0xfa>
    80004aac:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	8b0080e7          	jalr	-1872(ra) # 80004360 <begin_op>
      ilock(f->ip);
    80004ab8:	01893503          	ld	a0,24(s2)
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	ed2080e7          	jalr	-302(ra) # 8000398e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ac4:	8762                	mv	a4,s8
    80004ac6:	02092683          	lw	a3,32(s2)
    80004aca:	01598633          	add	a2,s3,s5
    80004ace:	4585                	li	a1,1
    80004ad0:	01893503          	ld	a0,24(s2)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	266080e7          	jalr	614(ra) # 80003d3a <writei>
    80004adc:	84aa                	mv	s1,a0
    80004ade:	00a05763          	blez	a0,80004aec <filewrite+0xc4>
        f->off += r;
    80004ae2:	02092783          	lw	a5,32(s2)
    80004ae6:	9fa9                	addw	a5,a5,a0
    80004ae8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004aec:	01893503          	ld	a0,24(s2)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	f60080e7          	jalr	-160(ra) # 80003a50 <iunlock>
      end_op();
    80004af8:	00000097          	auipc	ra,0x0
    80004afc:	8e8080e7          	jalr	-1816(ra) # 800043e0 <end_op>

      if(r != n1){
    80004b00:	009c1f63          	bne	s8,s1,80004b1e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b04:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b08:	0149db63          	bge	s3,s4,80004b1e <filewrite+0xf6>
      int n1 = n - i;
    80004b0c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b10:	84be                	mv	s1,a5
    80004b12:	2781                	sext.w	a5,a5
    80004b14:	f8fb5ce3          	bge	s6,a5,80004aac <filewrite+0x84>
    80004b18:	84de                	mv	s1,s7
    80004b1a:	bf49                	j	80004aac <filewrite+0x84>
    int i = 0;
    80004b1c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b1e:	013a1f63          	bne	s4,s3,80004b3c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b22:	8552                	mv	a0,s4
    80004b24:	60a6                	ld	ra,72(sp)
    80004b26:	6406                	ld	s0,64(sp)
    80004b28:	74e2                	ld	s1,56(sp)
    80004b2a:	7942                	ld	s2,48(sp)
    80004b2c:	79a2                	ld	s3,40(sp)
    80004b2e:	7a02                	ld	s4,32(sp)
    80004b30:	6ae2                	ld	s5,24(sp)
    80004b32:	6b42                	ld	s6,16(sp)
    80004b34:	6ba2                	ld	s7,8(sp)
    80004b36:	6c02                	ld	s8,0(sp)
    80004b38:	6161                	addi	sp,sp,80
    80004b3a:	8082                	ret
    ret = (i == n ? n : -1);
    80004b3c:	5a7d                	li	s4,-1
    80004b3e:	b7d5                	j	80004b22 <filewrite+0xfa>
    panic("filewrite");
    80004b40:	00004517          	auipc	a0,0x4
    80004b44:	c2050513          	addi	a0,a0,-992 # 80008760 <syscalls+0x280>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
    return -1;
    80004b50:	5a7d                	li	s4,-1
    80004b52:	bfc1                	j	80004b22 <filewrite+0xfa>
      return -1;
    80004b54:	5a7d                	li	s4,-1
    80004b56:	b7f1                	j	80004b22 <filewrite+0xfa>
    80004b58:	5a7d                	li	s4,-1
    80004b5a:	b7e1                	j	80004b22 <filewrite+0xfa>

0000000080004b5c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b5c:	7179                	addi	sp,sp,-48
    80004b5e:	f406                	sd	ra,40(sp)
    80004b60:	f022                	sd	s0,32(sp)
    80004b62:	ec26                	sd	s1,24(sp)
    80004b64:	e84a                	sd	s2,16(sp)
    80004b66:	e44e                	sd	s3,8(sp)
    80004b68:	e052                	sd	s4,0(sp)
    80004b6a:	1800                	addi	s0,sp,48
    80004b6c:	84aa                	mv	s1,a0
    80004b6e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b70:	0005b023          	sd	zero,0(a1)
    80004b74:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b78:	00000097          	auipc	ra,0x0
    80004b7c:	bf8080e7          	jalr	-1032(ra) # 80004770 <filealloc>
    80004b80:	e088                	sd	a0,0(s1)
    80004b82:	c551                	beqz	a0,80004c0e <pipealloc+0xb2>
    80004b84:	00000097          	auipc	ra,0x0
    80004b88:	bec080e7          	jalr	-1044(ra) # 80004770 <filealloc>
    80004b8c:	00aa3023          	sd	a0,0(s4)
    80004b90:	c92d                	beqz	a0,80004c02 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	f62080e7          	jalr	-158(ra) # 80000af4 <kalloc>
    80004b9a:	892a                	mv	s2,a0
    80004b9c:	c125                	beqz	a0,80004bfc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b9e:	4985                	li	s3,1
    80004ba0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ba4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ba8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bac:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bb0:	00004597          	auipc	a1,0x4
    80004bb4:	bc058593          	addi	a1,a1,-1088 # 80008770 <syscalls+0x290>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	f9c080e7          	jalr	-100(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bc0:	609c                	ld	a5,0(s1)
    80004bc2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bc6:	609c                	ld	a5,0(s1)
    80004bc8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bcc:	609c                	ld	a5,0(s1)
    80004bce:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bd2:	609c                	ld	a5,0(s1)
    80004bd4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bd8:	000a3783          	ld	a5,0(s4)
    80004bdc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004be0:	000a3783          	ld	a5,0(s4)
    80004be4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004be8:	000a3783          	ld	a5,0(s4)
    80004bec:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bf0:	000a3783          	ld	a5,0(s4)
    80004bf4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bf8:	4501                	li	a0,0
    80004bfa:	a025                	j	80004c22 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bfc:	6088                	ld	a0,0(s1)
    80004bfe:	e501                	bnez	a0,80004c06 <pipealloc+0xaa>
    80004c00:	a039                	j	80004c0e <pipealloc+0xb2>
    80004c02:	6088                	ld	a0,0(s1)
    80004c04:	c51d                	beqz	a0,80004c32 <pipealloc+0xd6>
    fileclose(*f0);
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	c26080e7          	jalr	-986(ra) # 8000482c <fileclose>
  if(*f1)
    80004c0e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c12:	557d                	li	a0,-1
  if(*f1)
    80004c14:	c799                	beqz	a5,80004c22 <pipealloc+0xc6>
    fileclose(*f1);
    80004c16:	853e                	mv	a0,a5
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	c14080e7          	jalr	-1004(ra) # 8000482c <fileclose>
  return -1;
    80004c20:	557d                	li	a0,-1
}
    80004c22:	70a2                	ld	ra,40(sp)
    80004c24:	7402                	ld	s0,32(sp)
    80004c26:	64e2                	ld	s1,24(sp)
    80004c28:	6942                	ld	s2,16(sp)
    80004c2a:	69a2                	ld	s3,8(sp)
    80004c2c:	6a02                	ld	s4,0(sp)
    80004c2e:	6145                	addi	sp,sp,48
    80004c30:	8082                	ret
  return -1;
    80004c32:	557d                	li	a0,-1
    80004c34:	b7fd                	j	80004c22 <pipealloc+0xc6>

0000000080004c36 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c36:	1101                	addi	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	e04a                	sd	s2,0(sp)
    80004c40:	1000                	addi	s0,sp,32
    80004c42:	84aa                	mv	s1,a0
    80004c44:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  if(writable){
    80004c4e:	02090d63          	beqz	s2,80004c88 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c52:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c56:	21848513          	addi	a0,s1,536
    80004c5a:	ffffe097          	auipc	ra,0xffffe
    80004c5e:	8b2080e7          	jalr	-1870(ra) # 8000250c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c62:	2204b783          	ld	a5,544(s1)
    80004c66:	eb95                	bnez	a5,80004c9a <pipeclose+0x64>
    release(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	02e080e7          	jalr	46(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	d84080e7          	jalr	-636(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c7c:	60e2                	ld	ra,24(sp)
    80004c7e:	6442                	ld	s0,16(sp)
    80004c80:	64a2                	ld	s1,8(sp)
    80004c82:	6902                	ld	s2,0(sp)
    80004c84:	6105                	addi	sp,sp,32
    80004c86:	8082                	ret
    pi->readopen = 0;
    80004c88:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c8c:	21c48513          	addi	a0,s1,540
    80004c90:	ffffe097          	auipc	ra,0xffffe
    80004c94:	87c080e7          	jalr	-1924(ra) # 8000250c <wakeup>
    80004c98:	b7e9                	j	80004c62 <pipeclose+0x2c>
    release(&pi->lock);
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
}
    80004ca4:	bfe1                	j	80004c7c <pipeclose+0x46>

0000000080004ca6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ca6:	7159                	addi	sp,sp,-112
    80004ca8:	f486                	sd	ra,104(sp)
    80004caa:	f0a2                	sd	s0,96(sp)
    80004cac:	eca6                	sd	s1,88(sp)
    80004cae:	e8ca                	sd	s2,80(sp)
    80004cb0:	e4ce                	sd	s3,72(sp)
    80004cb2:	e0d2                	sd	s4,64(sp)
    80004cb4:	fc56                	sd	s5,56(sp)
    80004cb6:	f85a                	sd	s6,48(sp)
    80004cb8:	f45e                	sd	s7,40(sp)
    80004cba:	f062                	sd	s8,32(sp)
    80004cbc:	ec66                	sd	s9,24(sp)
    80004cbe:	1880                	addi	s0,sp,112
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	8aae                	mv	s5,a1
    80004cc4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	fae080e7          	jalr	-82(ra) # 80001c74 <myproc>
    80004cce:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	f12080e7          	jalr	-238(ra) # 80000be4 <acquire>
  while(i < n){
    80004cda:	0d405163          	blez	s4,80004d9c <pipewrite+0xf6>
    80004cde:	8ba6                	mv	s7,s1
  int i = 0;
    80004ce0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ce4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce8:	21c48c13          	addi	s8,s1,540
    80004cec:	a08d                	j	80004d4e <pipewrite+0xa8>
      release(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	fa8080e7          	jalr	-88(ra) # 80000c98 <release>
      return -1;
    80004cf8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cfa:	854a                	mv	a0,s2
    80004cfc:	70a6                	ld	ra,104(sp)
    80004cfe:	7406                	ld	s0,96(sp)
    80004d00:	64e6                	ld	s1,88(sp)
    80004d02:	6946                	ld	s2,80(sp)
    80004d04:	69a6                	ld	s3,72(sp)
    80004d06:	6a06                	ld	s4,64(sp)
    80004d08:	7ae2                	ld	s5,56(sp)
    80004d0a:	7b42                	ld	s6,48(sp)
    80004d0c:	7ba2                	ld	s7,40(sp)
    80004d0e:	7c02                	ld	s8,32(sp)
    80004d10:	6ce2                	ld	s9,24(sp)
    80004d12:	6165                	addi	sp,sp,112
    80004d14:	8082                	ret
      wakeup(&pi->nread);
    80004d16:	8566                	mv	a0,s9
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	7f4080e7          	jalr	2036(ra) # 8000250c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d20:	85de                	mv	a1,s7
    80004d22:	8562                	mv	a0,s8
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	616080e7          	jalr	1558(ra) # 8000233a <sleep>
    80004d2c:	a839                	j	80004d4a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d2e:	21c4a783          	lw	a5,540(s1)
    80004d32:	0017871b          	addiw	a4,a5,1
    80004d36:	20e4ae23          	sw	a4,540(s1)
    80004d3a:	1ff7f793          	andi	a5,a5,511
    80004d3e:	97a6                	add	a5,a5,s1
    80004d40:	f9f44703          	lbu	a4,-97(s0)
    80004d44:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d48:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d4a:	03495d63          	bge	s2,s4,80004d84 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d4e:	2204a783          	lw	a5,544(s1)
    80004d52:	dfd1                	beqz	a5,80004cee <pipewrite+0x48>
    80004d54:	0289a783          	lw	a5,40(s3)
    80004d58:	fbd9                	bnez	a5,80004cee <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d5a:	2184a783          	lw	a5,536(s1)
    80004d5e:	21c4a703          	lw	a4,540(s1)
    80004d62:	2007879b          	addiw	a5,a5,512
    80004d66:	faf708e3          	beq	a4,a5,80004d16 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d6a:	4685                	li	a3,1
    80004d6c:	01590633          	add	a2,s2,s5
    80004d70:	f9f40593          	addi	a1,s0,-97
    80004d74:	0689b503          	ld	a0,104(s3)
    80004d78:	ffffd097          	auipc	ra,0xffffd
    80004d7c:	986080e7          	jalr	-1658(ra) # 800016fe <copyin>
    80004d80:	fb6517e3          	bne	a0,s6,80004d2e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d84:	21848513          	addi	a0,s1,536
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	784080e7          	jalr	1924(ra) # 8000250c <wakeup>
  release(&pi->lock);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>
  return i;
    80004d9a:	b785                	j	80004cfa <pipewrite+0x54>
  int i = 0;
    80004d9c:	4901                	li	s2,0
    80004d9e:	b7dd                	j	80004d84 <pipewrite+0xde>

0000000080004da0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004da0:	715d                	addi	sp,sp,-80
    80004da2:	e486                	sd	ra,72(sp)
    80004da4:	e0a2                	sd	s0,64(sp)
    80004da6:	fc26                	sd	s1,56(sp)
    80004da8:	f84a                	sd	s2,48(sp)
    80004daa:	f44e                	sd	s3,40(sp)
    80004dac:	f052                	sd	s4,32(sp)
    80004dae:	ec56                	sd	s5,24(sp)
    80004db0:	e85a                	sd	s6,16(sp)
    80004db2:	0880                	addi	s0,sp,80
    80004db4:	84aa                	mv	s1,a0
    80004db6:	892e                	mv	s2,a1
    80004db8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	eba080e7          	jalr	-326(ra) # 80001c74 <myproc>
    80004dc2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dc4:	8b26                	mv	s6,s1
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	e1c080e7          	jalr	-484(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd0:	2184a703          	lw	a4,536(s1)
    80004dd4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ddc:	02f71463          	bne	a4,a5,80004e04 <piperead+0x64>
    80004de0:	2244a783          	lw	a5,548(s1)
    80004de4:	c385                	beqz	a5,80004e04 <piperead+0x64>
    if(pr->killed){
    80004de6:	028a2783          	lw	a5,40(s4)
    80004dea:	ebc1                	bnez	a5,80004e7a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dec:	85da                	mv	a1,s6
    80004dee:	854e                	mv	a0,s3
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	54a080e7          	jalr	1354(ra) # 8000233a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df8:	2184a703          	lw	a4,536(s1)
    80004dfc:	21c4a783          	lw	a5,540(s1)
    80004e00:	fef700e3          	beq	a4,a5,80004de0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e04:	09505263          	blez	s5,80004e88 <piperead+0xe8>
    80004e08:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e0a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e0c:	2184a783          	lw	a5,536(s1)
    80004e10:	21c4a703          	lw	a4,540(s1)
    80004e14:	02f70d63          	beq	a4,a5,80004e4e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e18:	0017871b          	addiw	a4,a5,1
    80004e1c:	20e4ac23          	sw	a4,536(s1)
    80004e20:	1ff7f793          	andi	a5,a5,511
    80004e24:	97a6                	add	a5,a5,s1
    80004e26:	0187c783          	lbu	a5,24(a5)
    80004e2a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e2e:	4685                	li	a3,1
    80004e30:	fbf40613          	addi	a2,s0,-65
    80004e34:	85ca                	mv	a1,s2
    80004e36:	068a3503          	ld	a0,104(s4)
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	838080e7          	jalr	-1992(ra) # 80001672 <copyout>
    80004e42:	01650663          	beq	a0,s6,80004e4e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e46:	2985                	addiw	s3,s3,1
    80004e48:	0905                	addi	s2,s2,1
    80004e4a:	fd3a91e3          	bne	s5,s3,80004e0c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e4e:	21c48513          	addi	a0,s1,540
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	6ba080e7          	jalr	1722(ra) # 8000250c <wakeup>
  release(&pi->lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e3c080e7          	jalr	-452(ra) # 80000c98 <release>
  return i;
}
    80004e64:	854e                	mv	a0,s3
    80004e66:	60a6                	ld	ra,72(sp)
    80004e68:	6406                	ld	s0,64(sp)
    80004e6a:	74e2                	ld	s1,56(sp)
    80004e6c:	7942                	ld	s2,48(sp)
    80004e6e:	79a2                	ld	s3,40(sp)
    80004e70:	7a02                	ld	s4,32(sp)
    80004e72:	6ae2                	ld	s5,24(sp)
    80004e74:	6b42                	ld	s6,16(sp)
    80004e76:	6161                	addi	sp,sp,80
    80004e78:	8082                	ret
      release(&pi->lock);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	e1c080e7          	jalr	-484(ra) # 80000c98 <release>
      return -1;
    80004e84:	59fd                	li	s3,-1
    80004e86:	bff9                	j	80004e64 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e88:	4981                	li	s3,0
    80004e8a:	b7d1                	j	80004e4e <piperead+0xae>

0000000080004e8c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e8c:	df010113          	addi	sp,sp,-528
    80004e90:	20113423          	sd	ra,520(sp)
    80004e94:	20813023          	sd	s0,512(sp)
    80004e98:	ffa6                	sd	s1,504(sp)
    80004e9a:	fbca                	sd	s2,496(sp)
    80004e9c:	f7ce                	sd	s3,488(sp)
    80004e9e:	f3d2                	sd	s4,480(sp)
    80004ea0:	efd6                	sd	s5,472(sp)
    80004ea2:	ebda                	sd	s6,464(sp)
    80004ea4:	e7de                	sd	s7,456(sp)
    80004ea6:	e3e2                	sd	s8,448(sp)
    80004ea8:	ff66                	sd	s9,440(sp)
    80004eaa:	fb6a                	sd	s10,432(sp)
    80004eac:	f76e                	sd	s11,424(sp)
    80004eae:	0c00                	addi	s0,sp,528
    80004eb0:	84aa                	mv	s1,a0
    80004eb2:	dea43c23          	sd	a0,-520(s0)
    80004eb6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	dba080e7          	jalr	-582(ra) # 80001c74 <myproc>
    80004ec2:	892a                	mv	s2,a0

  begin_op();
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	49c080e7          	jalr	1180(ra) # 80004360 <begin_op>

  if((ip = namei(path)) == 0){
    80004ecc:	8526                	mv	a0,s1
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	276080e7          	jalr	630(ra) # 80004144 <namei>
    80004ed6:	c92d                	beqz	a0,80004f48 <exec+0xbc>
    80004ed8:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	ab4080e7          	jalr	-1356(ra) # 8000398e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ee2:	04000713          	li	a4,64
    80004ee6:	4681                	li	a3,0
    80004ee8:	e5040613          	addi	a2,s0,-432
    80004eec:	4581                	li	a1,0
    80004eee:	8526                	mv	a0,s1
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	d52080e7          	jalr	-686(ra) # 80003c42 <readi>
    80004ef8:	04000793          	li	a5,64
    80004efc:	00f51a63          	bne	a0,a5,80004f10 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f00:	e5042703          	lw	a4,-432(s0)
    80004f04:	464c47b7          	lui	a5,0x464c4
    80004f08:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f0c:	04f70463          	beq	a4,a5,80004f54 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f10:	8526                	mv	a0,s1
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	cde080e7          	jalr	-802(ra) # 80003bf0 <iunlockput>
    end_op();
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	4c6080e7          	jalr	1222(ra) # 800043e0 <end_op>
  }
  return -1;
    80004f22:	557d                	li	a0,-1
}
    80004f24:	20813083          	ld	ra,520(sp)
    80004f28:	20013403          	ld	s0,512(sp)
    80004f2c:	74fe                	ld	s1,504(sp)
    80004f2e:	795e                	ld	s2,496(sp)
    80004f30:	79be                	ld	s3,488(sp)
    80004f32:	7a1e                	ld	s4,480(sp)
    80004f34:	6afe                	ld	s5,472(sp)
    80004f36:	6b5e                	ld	s6,464(sp)
    80004f38:	6bbe                	ld	s7,456(sp)
    80004f3a:	6c1e                	ld	s8,448(sp)
    80004f3c:	7cfa                	ld	s9,440(sp)
    80004f3e:	7d5a                	ld	s10,432(sp)
    80004f40:	7dba                	ld	s11,424(sp)
    80004f42:	21010113          	addi	sp,sp,528
    80004f46:	8082                	ret
    end_op();
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	498080e7          	jalr	1176(ra) # 800043e0 <end_op>
    return -1;
    80004f50:	557d                	li	a0,-1
    80004f52:	bfc9                	j	80004f24 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f54:	854a                	mv	a0,s2
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	de2080e7          	jalr	-542(ra) # 80001d38 <proc_pagetable>
    80004f5e:	8baa                	mv	s7,a0
    80004f60:	d945                	beqz	a0,80004f10 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f62:	e7042983          	lw	s3,-400(s0)
    80004f66:	e8845783          	lhu	a5,-376(s0)
    80004f6a:	c7ad                	beqz	a5,80004fd4 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f6c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f70:	6c85                	lui	s9,0x1
    80004f72:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f76:	def43823          	sd	a5,-528(s0)
    80004f7a:	a42d                	j	800051a4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f7c:	00003517          	auipc	a0,0x3
    80004f80:	7fc50513          	addi	a0,a0,2044 # 80008778 <syscalls+0x298>
    80004f84:	ffffb097          	auipc	ra,0xffffb
    80004f88:	5ba080e7          	jalr	1466(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f8c:	8756                	mv	a4,s5
    80004f8e:	012d86bb          	addw	a3,s11,s2
    80004f92:	4581                	li	a1,0
    80004f94:	8526                	mv	a0,s1
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	cac080e7          	jalr	-852(ra) # 80003c42 <readi>
    80004f9e:	2501                	sext.w	a0,a0
    80004fa0:	1aaa9963          	bne	s5,a0,80005152 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fa4:	6785                	lui	a5,0x1
    80004fa6:	0127893b          	addw	s2,a5,s2
    80004faa:	77fd                	lui	a5,0xfffff
    80004fac:	01478a3b          	addw	s4,a5,s4
    80004fb0:	1f897163          	bgeu	s2,s8,80005192 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fb4:	02091593          	slli	a1,s2,0x20
    80004fb8:	9181                	srli	a1,a1,0x20
    80004fba:	95ea                	add	a1,a1,s10
    80004fbc:	855e                	mv	a0,s7
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	0b0080e7          	jalr	176(ra) # 8000106e <walkaddr>
    80004fc6:	862a                	mv	a2,a0
    if(pa == 0)
    80004fc8:	d955                	beqz	a0,80004f7c <exec+0xf0>
      n = PGSIZE;
    80004fca:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fcc:	fd9a70e3          	bgeu	s4,s9,80004f8c <exec+0x100>
      n = sz - i;
    80004fd0:	8ad2                	mv	s5,s4
    80004fd2:	bf6d                	j	80004f8c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fd4:	4901                	li	s2,0
  iunlockput(ip);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	c18080e7          	jalr	-1000(ra) # 80003bf0 <iunlockput>
  end_op();
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	400080e7          	jalr	1024(ra) # 800043e0 <end_op>
  p = myproc();
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	c8c080e7          	jalr	-884(ra) # 80001c74 <myproc>
    80004ff0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ff2:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004ff6:	6785                	lui	a5,0x1
    80004ff8:	17fd                	addi	a5,a5,-1
    80004ffa:	993e                	add	s2,s2,a5
    80004ffc:	757d                	lui	a0,0xfffff
    80004ffe:	00a977b3          	and	a5,s2,a0
    80005002:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005006:	6609                	lui	a2,0x2
    80005008:	963e                	add	a2,a2,a5
    8000500a:	85be                	mv	a1,a5
    8000500c:	855e                	mv	a0,s7
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	414080e7          	jalr	1044(ra) # 80001422 <uvmalloc>
    80005016:	8b2a                	mv	s6,a0
  ip = 0;
    80005018:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000501a:	12050c63          	beqz	a0,80005152 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000501e:	75f9                	lui	a1,0xffffe
    80005020:	95aa                	add	a1,a1,a0
    80005022:	855e                	mv	a0,s7
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	61c080e7          	jalr	1564(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000502c:	7c7d                	lui	s8,0xfffff
    8000502e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005030:	e0043783          	ld	a5,-512(s0)
    80005034:	6388                	ld	a0,0(a5)
    80005036:	c535                	beqz	a0,800050a2 <exec+0x216>
    80005038:	e9040993          	addi	s3,s0,-368
    8000503c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005040:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	e22080e7          	jalr	-478(ra) # 80000e64 <strlen>
    8000504a:	2505                	addiw	a0,a0,1
    8000504c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005050:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005054:	13896363          	bltu	s2,s8,8000517a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005058:	e0043d83          	ld	s11,-512(s0)
    8000505c:	000dba03          	ld	s4,0(s11)
    80005060:	8552                	mv	a0,s4
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	e02080e7          	jalr	-510(ra) # 80000e64 <strlen>
    8000506a:	0015069b          	addiw	a3,a0,1
    8000506e:	8652                	mv	a2,s4
    80005070:	85ca                	mv	a1,s2
    80005072:	855e                	mv	a0,s7
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	5fe080e7          	jalr	1534(ra) # 80001672 <copyout>
    8000507c:	10054363          	bltz	a0,80005182 <exec+0x2f6>
    ustack[argc] = sp;
    80005080:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005084:	0485                	addi	s1,s1,1
    80005086:	008d8793          	addi	a5,s11,8
    8000508a:	e0f43023          	sd	a5,-512(s0)
    8000508e:	008db503          	ld	a0,8(s11)
    80005092:	c911                	beqz	a0,800050a6 <exec+0x21a>
    if(argc >= MAXARG)
    80005094:	09a1                	addi	s3,s3,8
    80005096:	fb3c96e3          	bne	s9,s3,80005042 <exec+0x1b6>
  sz = sz1;
    8000509a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000509e:	4481                	li	s1,0
    800050a0:	a84d                	j	80005152 <exec+0x2c6>
  sp = sz;
    800050a2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050a4:	4481                	li	s1,0
  ustack[argc] = 0;
    800050a6:	00349793          	slli	a5,s1,0x3
    800050aa:	f9040713          	addi	a4,s0,-112
    800050ae:	97ba                	add	a5,a5,a4
    800050b0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050b4:	00148693          	addi	a3,s1,1
    800050b8:	068e                	slli	a3,a3,0x3
    800050ba:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050be:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050c2:	01897663          	bgeu	s2,s8,800050ce <exec+0x242>
  sz = sz1;
    800050c6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ca:	4481                	li	s1,0
    800050cc:	a059                	j	80005152 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ce:	e9040613          	addi	a2,s0,-368
    800050d2:	85ca                	mv	a1,s2
    800050d4:	855e                	mv	a0,s7
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	59c080e7          	jalr	1436(ra) # 80001672 <copyout>
    800050de:	0a054663          	bltz	a0,8000518a <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050e2:	070ab783          	ld	a5,112(s5)
    800050e6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050ea:	df843783          	ld	a5,-520(s0)
    800050ee:	0007c703          	lbu	a4,0(a5)
    800050f2:	cf11                	beqz	a4,8000510e <exec+0x282>
    800050f4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050f6:	02f00693          	li	a3,47
    800050fa:	a039                	j	80005108 <exec+0x27c>
      last = s+1;
    800050fc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005100:	0785                	addi	a5,a5,1
    80005102:	fff7c703          	lbu	a4,-1(a5)
    80005106:	c701                	beqz	a4,8000510e <exec+0x282>
    if(*s == '/')
    80005108:	fed71ce3          	bne	a4,a3,80005100 <exec+0x274>
    8000510c:	bfc5                	j	800050fc <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000510e:	4641                	li	a2,16
    80005110:	df843583          	ld	a1,-520(s0)
    80005114:	170a8513          	addi	a0,s5,368
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	d1a080e7          	jalr	-742(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005120:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    80005124:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    80005128:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000512c:	070ab783          	ld	a5,112(s5)
    80005130:	e6843703          	ld	a4,-408(s0)
    80005134:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005136:	070ab783          	ld	a5,112(s5)
    8000513a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000513e:	85ea                	mv	a1,s10
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	c94080e7          	jalr	-876(ra) # 80001dd4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005148:	0004851b          	sext.w	a0,s1
    8000514c:	bbe1                	j	80004f24 <exec+0x98>
    8000514e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005152:	e0843583          	ld	a1,-504(s0)
    80005156:	855e                	mv	a0,s7
    80005158:	ffffd097          	auipc	ra,0xffffd
    8000515c:	c7c080e7          	jalr	-900(ra) # 80001dd4 <proc_freepagetable>
  if(ip){
    80005160:	da0498e3          	bnez	s1,80004f10 <exec+0x84>
  return -1;
    80005164:	557d                	li	a0,-1
    80005166:	bb7d                	j	80004f24 <exec+0x98>
    80005168:	e1243423          	sd	s2,-504(s0)
    8000516c:	b7dd                	j	80005152 <exec+0x2c6>
    8000516e:	e1243423          	sd	s2,-504(s0)
    80005172:	b7c5                	j	80005152 <exec+0x2c6>
    80005174:	e1243423          	sd	s2,-504(s0)
    80005178:	bfe9                	j	80005152 <exec+0x2c6>
  sz = sz1;
    8000517a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000517e:	4481                	li	s1,0
    80005180:	bfc9                	j	80005152 <exec+0x2c6>
  sz = sz1;
    80005182:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005186:	4481                	li	s1,0
    80005188:	b7e9                	j	80005152 <exec+0x2c6>
  sz = sz1;
    8000518a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000518e:	4481                	li	s1,0
    80005190:	b7c9                	j	80005152 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005192:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005196:	2b05                	addiw	s6,s6,1
    80005198:	0389899b          	addiw	s3,s3,56
    8000519c:	e8845783          	lhu	a5,-376(s0)
    800051a0:	e2fb5be3          	bge	s6,a5,80004fd6 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051a4:	2981                	sext.w	s3,s3
    800051a6:	03800713          	li	a4,56
    800051aa:	86ce                	mv	a3,s3
    800051ac:	e1840613          	addi	a2,s0,-488
    800051b0:	4581                	li	a1,0
    800051b2:	8526                	mv	a0,s1
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	a8e080e7          	jalr	-1394(ra) # 80003c42 <readi>
    800051bc:	03800793          	li	a5,56
    800051c0:	f8f517e3          	bne	a0,a5,8000514e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051c4:	e1842783          	lw	a5,-488(s0)
    800051c8:	4705                	li	a4,1
    800051ca:	fce796e3          	bne	a5,a4,80005196 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051ce:	e4043603          	ld	a2,-448(s0)
    800051d2:	e3843783          	ld	a5,-456(s0)
    800051d6:	f8f669e3          	bltu	a2,a5,80005168 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051da:	e2843783          	ld	a5,-472(s0)
    800051de:	963e                	add	a2,a2,a5
    800051e0:	f8f667e3          	bltu	a2,a5,8000516e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051e4:	85ca                	mv	a1,s2
    800051e6:	855e                	mv	a0,s7
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	23a080e7          	jalr	570(ra) # 80001422 <uvmalloc>
    800051f0:	e0a43423          	sd	a0,-504(s0)
    800051f4:	d141                	beqz	a0,80005174 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051f6:	e2843d03          	ld	s10,-472(s0)
    800051fa:	df043783          	ld	a5,-528(s0)
    800051fe:	00fd77b3          	and	a5,s10,a5
    80005202:	fba1                	bnez	a5,80005152 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005204:	e2042d83          	lw	s11,-480(s0)
    80005208:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000520c:	f80c03e3          	beqz	s8,80005192 <exec+0x306>
    80005210:	8a62                	mv	s4,s8
    80005212:	4901                	li	s2,0
    80005214:	b345                	j	80004fb4 <exec+0x128>

0000000080005216 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005216:	7179                	addi	sp,sp,-48
    80005218:	f406                	sd	ra,40(sp)
    8000521a:	f022                	sd	s0,32(sp)
    8000521c:	ec26                	sd	s1,24(sp)
    8000521e:	e84a                	sd	s2,16(sp)
    80005220:	1800                	addi	s0,sp,48
    80005222:	892e                	mv	s2,a1
    80005224:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005226:	fdc40593          	addi	a1,s0,-36
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	b90080e7          	jalr	-1136(ra) # 80002dba <argint>
    80005232:	04054063          	bltz	a0,80005272 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005236:	fdc42703          	lw	a4,-36(s0)
    8000523a:	47bd                	li	a5,15
    8000523c:	02e7ed63          	bltu	a5,a4,80005276 <argfd+0x60>
    80005240:	ffffd097          	auipc	ra,0xffffd
    80005244:	a34080e7          	jalr	-1484(ra) # 80001c74 <myproc>
    80005248:	fdc42703          	lw	a4,-36(s0)
    8000524c:	01c70793          	addi	a5,a4,28
    80005250:	078e                	slli	a5,a5,0x3
    80005252:	953e                	add	a0,a0,a5
    80005254:	651c                	ld	a5,8(a0)
    80005256:	c395                	beqz	a5,8000527a <argfd+0x64>
    return -1;
  if(pfd)
    80005258:	00090463          	beqz	s2,80005260 <argfd+0x4a>
    *pfd = fd;
    8000525c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005260:	4501                	li	a0,0
  if(pf)
    80005262:	c091                	beqz	s1,80005266 <argfd+0x50>
    *pf = f;
    80005264:	e09c                	sd	a5,0(s1)
}
    80005266:	70a2                	ld	ra,40(sp)
    80005268:	7402                	ld	s0,32(sp)
    8000526a:	64e2                	ld	s1,24(sp)
    8000526c:	6942                	ld	s2,16(sp)
    8000526e:	6145                	addi	sp,sp,48
    80005270:	8082                	ret
    return -1;
    80005272:	557d                	li	a0,-1
    80005274:	bfcd                	j	80005266 <argfd+0x50>
    return -1;
    80005276:	557d                	li	a0,-1
    80005278:	b7fd                	j	80005266 <argfd+0x50>
    8000527a:	557d                	li	a0,-1
    8000527c:	b7ed                	j	80005266 <argfd+0x50>

000000008000527e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000527e:	1101                	addi	sp,sp,-32
    80005280:	ec06                	sd	ra,24(sp)
    80005282:	e822                	sd	s0,16(sp)
    80005284:	e426                	sd	s1,8(sp)
    80005286:	1000                	addi	s0,sp,32
    80005288:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000528a:	ffffd097          	auipc	ra,0xffffd
    8000528e:	9ea080e7          	jalr	-1558(ra) # 80001c74 <myproc>
    80005292:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005294:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    80005298:	4501                	li	a0,0
    8000529a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000529c:	6398                	ld	a4,0(a5)
    8000529e:	cb19                	beqz	a4,800052b4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052a0:	2505                	addiw	a0,a0,1
    800052a2:	07a1                	addi	a5,a5,8
    800052a4:	fed51ce3          	bne	a0,a3,8000529c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052a8:	557d                	li	a0,-1
}
    800052aa:	60e2                	ld	ra,24(sp)
    800052ac:	6442                	ld	s0,16(sp)
    800052ae:	64a2                	ld	s1,8(sp)
    800052b0:	6105                	addi	sp,sp,32
    800052b2:	8082                	ret
      p->ofile[fd] = f;
    800052b4:	01c50793          	addi	a5,a0,28
    800052b8:	078e                	slli	a5,a5,0x3
    800052ba:	963e                	add	a2,a2,a5
    800052bc:	e604                	sd	s1,8(a2)
      return fd;
    800052be:	b7f5                	j	800052aa <fdalloc+0x2c>

00000000800052c0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052c0:	715d                	addi	sp,sp,-80
    800052c2:	e486                	sd	ra,72(sp)
    800052c4:	e0a2                	sd	s0,64(sp)
    800052c6:	fc26                	sd	s1,56(sp)
    800052c8:	f84a                	sd	s2,48(sp)
    800052ca:	f44e                	sd	s3,40(sp)
    800052cc:	f052                	sd	s4,32(sp)
    800052ce:	ec56                	sd	s5,24(sp)
    800052d0:	0880                	addi	s0,sp,80
    800052d2:	89ae                	mv	s3,a1
    800052d4:	8ab2                	mv	s5,a2
    800052d6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052d8:	fb040593          	addi	a1,s0,-80
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	e86080e7          	jalr	-378(ra) # 80004162 <nameiparent>
    800052e4:	892a                	mv	s2,a0
    800052e6:	12050f63          	beqz	a0,80005424 <create+0x164>
    return 0;

  ilock(dp);
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	6a4080e7          	jalr	1700(ra) # 8000398e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052f2:	4601                	li	a2,0
    800052f4:	fb040593          	addi	a1,s0,-80
    800052f8:	854a                	mv	a0,s2
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	b78080e7          	jalr	-1160(ra) # 80003e72 <dirlookup>
    80005302:	84aa                	mv	s1,a0
    80005304:	c921                	beqz	a0,80005354 <create+0x94>
    iunlockput(dp);
    80005306:	854a                	mv	a0,s2
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	8e8080e7          	jalr	-1816(ra) # 80003bf0 <iunlockput>
    ilock(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	67c080e7          	jalr	1660(ra) # 8000398e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000531a:	2981                	sext.w	s3,s3
    8000531c:	4789                	li	a5,2
    8000531e:	02f99463          	bne	s3,a5,80005346 <create+0x86>
    80005322:	0444d783          	lhu	a5,68(s1)
    80005326:	37f9                	addiw	a5,a5,-2
    80005328:	17c2                	slli	a5,a5,0x30
    8000532a:	93c1                	srli	a5,a5,0x30
    8000532c:	4705                	li	a4,1
    8000532e:	00f76c63          	bltu	a4,a5,80005346 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005332:	8526                	mv	a0,s1
    80005334:	60a6                	ld	ra,72(sp)
    80005336:	6406                	ld	s0,64(sp)
    80005338:	74e2                	ld	s1,56(sp)
    8000533a:	7942                	ld	s2,48(sp)
    8000533c:	79a2                	ld	s3,40(sp)
    8000533e:	7a02                	ld	s4,32(sp)
    80005340:	6ae2                	ld	s5,24(sp)
    80005342:	6161                	addi	sp,sp,80
    80005344:	8082                	ret
    iunlockput(ip);
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	8a8080e7          	jalr	-1880(ra) # 80003bf0 <iunlockput>
    return 0;
    80005350:	4481                	li	s1,0
    80005352:	b7c5                	j	80005332 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005354:	85ce                	mv	a1,s3
    80005356:	00092503          	lw	a0,0(s2)
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	49c080e7          	jalr	1180(ra) # 800037f6 <ialloc>
    80005362:	84aa                	mv	s1,a0
    80005364:	c529                	beqz	a0,800053ae <create+0xee>
  ilock(ip);
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	628080e7          	jalr	1576(ra) # 8000398e <ilock>
  ip->major = major;
    8000536e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005372:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005376:	4785                	li	a5,1
    80005378:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	546080e7          	jalr	1350(ra) # 800038c4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005386:	2981                	sext.w	s3,s3
    80005388:	4785                	li	a5,1
    8000538a:	02f98a63          	beq	s3,a5,800053be <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000538e:	40d0                	lw	a2,4(s1)
    80005390:	fb040593          	addi	a1,s0,-80
    80005394:	854a                	mv	a0,s2
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	cec080e7          	jalr	-788(ra) # 80004082 <dirlink>
    8000539e:	06054b63          	bltz	a0,80005414 <create+0x154>
  iunlockput(dp);
    800053a2:	854a                	mv	a0,s2
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	84c080e7          	jalr	-1972(ra) # 80003bf0 <iunlockput>
  return ip;
    800053ac:	b759                	j	80005332 <create+0x72>
    panic("create: ialloc");
    800053ae:	00003517          	auipc	a0,0x3
    800053b2:	3ea50513          	addi	a0,a0,1002 # 80008798 <syscalls+0x2b8>
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	188080e7          	jalr	392(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053be:	04a95783          	lhu	a5,74(s2)
    800053c2:	2785                	addiw	a5,a5,1
    800053c4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053c8:	854a                	mv	a0,s2
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	4fa080e7          	jalr	1274(ra) # 800038c4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d2:	40d0                	lw	a2,4(s1)
    800053d4:	00003597          	auipc	a1,0x3
    800053d8:	3d458593          	addi	a1,a1,980 # 800087a8 <syscalls+0x2c8>
    800053dc:	8526                	mv	a0,s1
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	ca4080e7          	jalr	-860(ra) # 80004082 <dirlink>
    800053e6:	00054f63          	bltz	a0,80005404 <create+0x144>
    800053ea:	00492603          	lw	a2,4(s2)
    800053ee:	00003597          	auipc	a1,0x3
    800053f2:	3c258593          	addi	a1,a1,962 # 800087b0 <syscalls+0x2d0>
    800053f6:	8526                	mv	a0,s1
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	c8a080e7          	jalr	-886(ra) # 80004082 <dirlink>
    80005400:	f80557e3          	bgez	a0,8000538e <create+0xce>
      panic("create dots");
    80005404:	00003517          	auipc	a0,0x3
    80005408:	3b450513          	addi	a0,a0,948 # 800087b8 <syscalls+0x2d8>
    8000540c:	ffffb097          	auipc	ra,0xffffb
    80005410:	132080e7          	jalr	306(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005414:	00003517          	auipc	a0,0x3
    80005418:	3b450513          	addi	a0,a0,948 # 800087c8 <syscalls+0x2e8>
    8000541c:	ffffb097          	auipc	ra,0xffffb
    80005420:	122080e7          	jalr	290(ra) # 8000053e <panic>
    return 0;
    80005424:	84aa                	mv	s1,a0
    80005426:	b731                	j	80005332 <create+0x72>

0000000080005428 <sys_dup>:
{
    80005428:	7179                	addi	sp,sp,-48
    8000542a:	f406                	sd	ra,40(sp)
    8000542c:	f022                	sd	s0,32(sp)
    8000542e:	ec26                	sd	s1,24(sp)
    80005430:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005432:	fd840613          	addi	a2,s0,-40
    80005436:	4581                	li	a1,0
    80005438:	4501                	li	a0,0
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	ddc080e7          	jalr	-548(ra) # 80005216 <argfd>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005444:	02054363          	bltz	a0,8000546a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005448:	fd843503          	ld	a0,-40(s0)
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	e32080e7          	jalr	-462(ra) # 8000527e <fdalloc>
    80005454:	84aa                	mv	s1,a0
    return -1;
    80005456:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005458:	00054963          	bltz	a0,8000546a <sys_dup+0x42>
  filedup(f);
    8000545c:	fd843503          	ld	a0,-40(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	37a080e7          	jalr	890(ra) # 800047da <filedup>
  return fd;
    80005468:	87a6                	mv	a5,s1
}
    8000546a:	853e                	mv	a0,a5
    8000546c:	70a2                	ld	ra,40(sp)
    8000546e:	7402                	ld	s0,32(sp)
    80005470:	64e2                	ld	s1,24(sp)
    80005472:	6145                	addi	sp,sp,48
    80005474:	8082                	ret

0000000080005476 <sys_read>:
{
    80005476:	7179                	addi	sp,sp,-48
    80005478:	f406                	sd	ra,40(sp)
    8000547a:	f022                	sd	s0,32(sp)
    8000547c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	fe840613          	addi	a2,s0,-24
    80005482:	4581                	li	a1,0
    80005484:	4501                	li	a0,0
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	d90080e7          	jalr	-624(ra) # 80005216 <argfd>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005490:	04054163          	bltz	a0,800054d2 <sys_read+0x5c>
    80005494:	fe440593          	addi	a1,s0,-28
    80005498:	4509                	li	a0,2
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	920080e7          	jalr	-1760(ra) # 80002dba <argint>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a4:	02054763          	bltz	a0,800054d2 <sys_read+0x5c>
    800054a8:	fd840593          	addi	a1,s0,-40
    800054ac:	4505                	li	a0,1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	92e080e7          	jalr	-1746(ra) # 80002ddc <argaddr>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b8:	00054d63          	bltz	a0,800054d2 <sys_read+0x5c>
  return fileread(f, p, n);
    800054bc:	fe442603          	lw	a2,-28(s0)
    800054c0:	fd843583          	ld	a1,-40(s0)
    800054c4:	fe843503          	ld	a0,-24(s0)
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	49e080e7          	jalr	1182(ra) # 80004966 <fileread>
    800054d0:	87aa                	mv	a5,a0
}
    800054d2:	853e                	mv	a0,a5
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	6145                	addi	sp,sp,48
    800054da:	8082                	ret

00000000800054dc <sys_write>:
{
    800054dc:	7179                	addi	sp,sp,-48
    800054de:	f406                	sd	ra,40(sp)
    800054e0:	f022                	sd	s0,32(sp)
    800054e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	fe840613          	addi	a2,s0,-24
    800054e8:	4581                	li	a1,0
    800054ea:	4501                	li	a0,0
    800054ec:	00000097          	auipc	ra,0x0
    800054f0:	d2a080e7          	jalr	-726(ra) # 80005216 <argfd>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f6:	04054163          	bltz	a0,80005538 <sys_write+0x5c>
    800054fa:	fe440593          	addi	a1,s0,-28
    800054fe:	4509                	li	a0,2
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	8ba080e7          	jalr	-1862(ra) # 80002dba <argint>
    return -1;
    80005508:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550a:	02054763          	bltz	a0,80005538 <sys_write+0x5c>
    8000550e:	fd840593          	addi	a1,s0,-40
    80005512:	4505                	li	a0,1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	8c8080e7          	jalr	-1848(ra) # 80002ddc <argaddr>
    return -1;
    8000551c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551e:	00054d63          	bltz	a0,80005538 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005522:	fe442603          	lw	a2,-28(s0)
    80005526:	fd843583          	ld	a1,-40(s0)
    8000552a:	fe843503          	ld	a0,-24(s0)
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	4fa080e7          	jalr	1274(ra) # 80004a28 <filewrite>
    80005536:	87aa                	mv	a5,a0
}
    80005538:	853e                	mv	a0,a5
    8000553a:	70a2                	ld	ra,40(sp)
    8000553c:	7402                	ld	s0,32(sp)
    8000553e:	6145                	addi	sp,sp,48
    80005540:	8082                	ret

0000000080005542 <sys_close>:
{
    80005542:	1101                	addi	sp,sp,-32
    80005544:	ec06                	sd	ra,24(sp)
    80005546:	e822                	sd	s0,16(sp)
    80005548:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000554a:	fe040613          	addi	a2,s0,-32
    8000554e:	fec40593          	addi	a1,s0,-20
    80005552:	4501                	li	a0,0
    80005554:	00000097          	auipc	ra,0x0
    80005558:	cc2080e7          	jalr	-830(ra) # 80005216 <argfd>
    return -1;
    8000555c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000555e:	02054463          	bltz	a0,80005586 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005562:	ffffc097          	auipc	ra,0xffffc
    80005566:	712080e7          	jalr	1810(ra) # 80001c74 <myproc>
    8000556a:	fec42783          	lw	a5,-20(s0)
    8000556e:	07f1                	addi	a5,a5,28
    80005570:	078e                	slli	a5,a5,0x3
    80005572:	97aa                	add	a5,a5,a0
    80005574:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005578:	fe043503          	ld	a0,-32(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	2b0080e7          	jalr	688(ra) # 8000482c <fileclose>
  return 0;
    80005584:	4781                	li	a5,0
}
    80005586:	853e                	mv	a0,a5
    80005588:	60e2                	ld	ra,24(sp)
    8000558a:	6442                	ld	s0,16(sp)
    8000558c:	6105                	addi	sp,sp,32
    8000558e:	8082                	ret

0000000080005590 <sys_fstat>:
{
    80005590:	1101                	addi	sp,sp,-32
    80005592:	ec06                	sd	ra,24(sp)
    80005594:	e822                	sd	s0,16(sp)
    80005596:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005598:	fe840613          	addi	a2,s0,-24
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	c76080e7          	jalr	-906(ra) # 80005216 <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055aa:	02054563          	bltz	a0,800055d4 <sys_fstat+0x44>
    800055ae:	fe040593          	addi	a1,s0,-32
    800055b2:	4505                	li	a0,1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	828080e7          	jalr	-2008(ra) # 80002ddc <argaddr>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055be:	00054b63          	bltz	a0,800055d4 <sys_fstat+0x44>
  return filestat(f, st);
    800055c2:	fe043583          	ld	a1,-32(s0)
    800055c6:	fe843503          	ld	a0,-24(s0)
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	32a080e7          	jalr	810(ra) # 800048f4 <filestat>
    800055d2:	87aa                	mv	a5,a0
}
    800055d4:	853e                	mv	a0,a5
    800055d6:	60e2                	ld	ra,24(sp)
    800055d8:	6442                	ld	s0,16(sp)
    800055da:	6105                	addi	sp,sp,32
    800055dc:	8082                	ret

00000000800055de <sys_link>:
{
    800055de:	7169                	addi	sp,sp,-304
    800055e0:	f606                	sd	ra,296(sp)
    800055e2:	f222                	sd	s0,288(sp)
    800055e4:	ee26                	sd	s1,280(sp)
    800055e6:	ea4a                	sd	s2,272(sp)
    800055e8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ea:	08000613          	li	a2,128
    800055ee:	ed040593          	addi	a1,s0,-304
    800055f2:	4501                	li	a0,0
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	80a080e7          	jalr	-2038(ra) # 80002dfe <argstr>
    return -1;
    800055fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fe:	10054e63          	bltz	a0,8000571a <sys_link+0x13c>
    80005602:	08000613          	li	a2,128
    80005606:	f5040593          	addi	a1,s0,-176
    8000560a:	4505                	li	a0,1
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	7f2080e7          	jalr	2034(ra) # 80002dfe <argstr>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005616:	10054263          	bltz	a0,8000571a <sys_link+0x13c>
  begin_op();
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	d46080e7          	jalr	-698(ra) # 80004360 <begin_op>
  if((ip = namei(old)) == 0){
    80005622:	ed040513          	addi	a0,s0,-304
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	b1e080e7          	jalr	-1250(ra) # 80004144 <namei>
    8000562e:	84aa                	mv	s1,a0
    80005630:	c551                	beqz	a0,800056bc <sys_link+0xde>
  ilock(ip);
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	35c080e7          	jalr	860(ra) # 8000398e <ilock>
  if(ip->type == T_DIR){
    8000563a:	04449703          	lh	a4,68(s1)
    8000563e:	4785                	li	a5,1
    80005640:	08f70463          	beq	a4,a5,800056c8 <sys_link+0xea>
  ip->nlink++;
    80005644:	04a4d783          	lhu	a5,74(s1)
    80005648:	2785                	addiw	a5,a5,1
    8000564a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	274080e7          	jalr	628(ra) # 800038c4 <iupdate>
  iunlock(ip);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	3f6080e7          	jalr	1014(ra) # 80003a50 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005662:	fd040593          	addi	a1,s0,-48
    80005666:	f5040513          	addi	a0,s0,-176
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	af8080e7          	jalr	-1288(ra) # 80004162 <nameiparent>
    80005672:	892a                	mv	s2,a0
    80005674:	c935                	beqz	a0,800056e8 <sys_link+0x10a>
  ilock(dp);
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	318080e7          	jalr	792(ra) # 8000398e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000567e:	00092703          	lw	a4,0(s2)
    80005682:	409c                	lw	a5,0(s1)
    80005684:	04f71d63          	bne	a4,a5,800056de <sys_link+0x100>
    80005688:	40d0                	lw	a2,4(s1)
    8000568a:	fd040593          	addi	a1,s0,-48
    8000568e:	854a                	mv	a0,s2
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	9f2080e7          	jalr	-1550(ra) # 80004082 <dirlink>
    80005698:	04054363          	bltz	a0,800056de <sys_link+0x100>
  iunlockput(dp);
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	552080e7          	jalr	1362(ra) # 80003bf0 <iunlockput>
  iput(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	4a0080e7          	jalr	1184(ra) # 80003b48 <iput>
  end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	d30080e7          	jalr	-720(ra) # 800043e0 <end_op>
  return 0;
    800056b8:	4781                	li	a5,0
    800056ba:	a085                	j	8000571a <sys_link+0x13c>
    end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	d24080e7          	jalr	-732(ra) # 800043e0 <end_op>
    return -1;
    800056c4:	57fd                	li	a5,-1
    800056c6:	a891                	j	8000571a <sys_link+0x13c>
    iunlockput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	526080e7          	jalr	1318(ra) # 80003bf0 <iunlockput>
    end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	d0e080e7          	jalr	-754(ra) # 800043e0 <end_op>
    return -1;
    800056da:	57fd                	li	a5,-1
    800056dc:	a83d                	j	8000571a <sys_link+0x13c>
    iunlockput(dp);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	510080e7          	jalr	1296(ra) # 80003bf0 <iunlockput>
  ilock(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	2a4080e7          	jalr	676(ra) # 8000398e <ilock>
  ip->nlink--;
    800056f2:	04a4d783          	lhu	a5,74(s1)
    800056f6:	37fd                	addiw	a5,a5,-1
    800056f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	1c6080e7          	jalr	454(ra) # 800038c4 <iupdate>
  iunlockput(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	4e8080e7          	jalr	1256(ra) # 80003bf0 <iunlockput>
  end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	cd0080e7          	jalr	-816(ra) # 800043e0 <end_op>
  return -1;
    80005718:	57fd                	li	a5,-1
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	70b2                	ld	ra,296(sp)
    8000571e:	7412                	ld	s0,288(sp)
    80005720:	64f2                	ld	s1,280(sp)
    80005722:	6952                	ld	s2,272(sp)
    80005724:	6155                	addi	sp,sp,304
    80005726:	8082                	ret

0000000080005728 <sys_unlink>:
{
    80005728:	7151                	addi	sp,sp,-240
    8000572a:	f586                	sd	ra,232(sp)
    8000572c:	f1a2                	sd	s0,224(sp)
    8000572e:	eda6                	sd	s1,216(sp)
    80005730:	e9ca                	sd	s2,208(sp)
    80005732:	e5ce                	sd	s3,200(sp)
    80005734:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005736:	08000613          	li	a2,128
    8000573a:	f3040593          	addi	a1,s0,-208
    8000573e:	4501                	li	a0,0
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	6be080e7          	jalr	1726(ra) # 80002dfe <argstr>
    80005748:	18054163          	bltz	a0,800058ca <sys_unlink+0x1a2>
  begin_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	c14080e7          	jalr	-1004(ra) # 80004360 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005754:	fb040593          	addi	a1,s0,-80
    80005758:	f3040513          	addi	a0,s0,-208
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	a06080e7          	jalr	-1530(ra) # 80004162 <nameiparent>
    80005764:	84aa                	mv	s1,a0
    80005766:	c979                	beqz	a0,8000583c <sys_unlink+0x114>
  ilock(dp);
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	226080e7          	jalr	550(ra) # 8000398e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005770:	00003597          	auipc	a1,0x3
    80005774:	03858593          	addi	a1,a1,56 # 800087a8 <syscalls+0x2c8>
    80005778:	fb040513          	addi	a0,s0,-80
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	6dc080e7          	jalr	1756(ra) # 80003e58 <namecmp>
    80005784:	14050a63          	beqz	a0,800058d8 <sys_unlink+0x1b0>
    80005788:	00003597          	auipc	a1,0x3
    8000578c:	02858593          	addi	a1,a1,40 # 800087b0 <syscalls+0x2d0>
    80005790:	fb040513          	addi	a0,s0,-80
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	6c4080e7          	jalr	1732(ra) # 80003e58 <namecmp>
    8000579c:	12050e63          	beqz	a0,800058d8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057a0:	f2c40613          	addi	a2,s0,-212
    800057a4:	fb040593          	addi	a1,s0,-80
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	6c8080e7          	jalr	1736(ra) # 80003e72 <dirlookup>
    800057b2:	892a                	mv	s2,a0
    800057b4:	12050263          	beqz	a0,800058d8 <sys_unlink+0x1b0>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	1d6080e7          	jalr	470(ra) # 8000398e <ilock>
  if(ip->nlink < 1)
    800057c0:	04a91783          	lh	a5,74(s2)
    800057c4:	08f05263          	blez	a5,80005848 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057c8:	04491703          	lh	a4,68(s2)
    800057cc:	4785                	li	a5,1
    800057ce:	08f70563          	beq	a4,a5,80005858 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057d2:	4641                	li	a2,16
    800057d4:	4581                	li	a1,0
    800057d6:	fc040513          	addi	a0,s0,-64
    800057da:	ffffb097          	auipc	ra,0xffffb
    800057de:	506080e7          	jalr	1286(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e2:	4741                	li	a4,16
    800057e4:	f2c42683          	lw	a3,-212(s0)
    800057e8:	fc040613          	addi	a2,s0,-64
    800057ec:	4581                	li	a1,0
    800057ee:	8526                	mv	a0,s1
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	54a080e7          	jalr	1354(ra) # 80003d3a <writei>
    800057f8:	47c1                	li	a5,16
    800057fa:	0af51563          	bne	a0,a5,800058a4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	4785                	li	a5,1
    80005804:	0af70863          	beq	a4,a5,800058b4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	3e6080e7          	jalr	998(ra) # 80003bf0 <iunlockput>
  ip->nlink--;
    80005812:	04a95783          	lhu	a5,74(s2)
    80005816:	37fd                	addiw	a5,a5,-1
    80005818:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000581c:	854a                	mv	a0,s2
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	0a6080e7          	jalr	166(ra) # 800038c4 <iupdate>
  iunlockput(ip);
    80005826:	854a                	mv	a0,s2
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	3c8080e7          	jalr	968(ra) # 80003bf0 <iunlockput>
  end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	bb0080e7          	jalr	-1104(ra) # 800043e0 <end_op>
  return 0;
    80005838:	4501                	li	a0,0
    8000583a:	a84d                	j	800058ec <sys_unlink+0x1c4>
    end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	ba4080e7          	jalr	-1116(ra) # 800043e0 <end_op>
    return -1;
    80005844:	557d                	li	a0,-1
    80005846:	a05d                	j	800058ec <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005848:	00003517          	auipc	a0,0x3
    8000584c:	f9050513          	addi	a0,a0,-112 # 800087d8 <syscalls+0x2f8>
    80005850:	ffffb097          	auipc	ra,0xffffb
    80005854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005858:	04c92703          	lw	a4,76(s2)
    8000585c:	02000793          	li	a5,32
    80005860:	f6e7f9e3          	bgeu	a5,a4,800057d2 <sys_unlink+0xaa>
    80005864:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005868:	4741                	li	a4,16
    8000586a:	86ce                	mv	a3,s3
    8000586c:	f1840613          	addi	a2,s0,-232
    80005870:	4581                	li	a1,0
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	3ce080e7          	jalr	974(ra) # 80003c42 <readi>
    8000587c:	47c1                	li	a5,16
    8000587e:	00f51b63          	bne	a0,a5,80005894 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005882:	f1845783          	lhu	a5,-232(s0)
    80005886:	e7a1                	bnez	a5,800058ce <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005888:	29c1                	addiw	s3,s3,16
    8000588a:	04c92783          	lw	a5,76(s2)
    8000588e:	fcf9ede3          	bltu	s3,a5,80005868 <sys_unlink+0x140>
    80005892:	b781                	j	800057d2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005894:	00003517          	auipc	a0,0x3
    80005898:	f5c50513          	addi	a0,a0,-164 # 800087f0 <syscalls+0x310>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	ca2080e7          	jalr	-862(ra) # 8000053e <panic>
    panic("unlink: writei");
    800058a4:	00003517          	auipc	a0,0x3
    800058a8:	f6450513          	addi	a0,a0,-156 # 80008808 <syscalls+0x328>
    800058ac:	ffffb097          	auipc	ra,0xffffb
    800058b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>
    dp->nlink--;
    800058b4:	04a4d783          	lhu	a5,74(s1)
    800058b8:	37fd                	addiw	a5,a5,-1
    800058ba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	004080e7          	jalr	4(ra) # 800038c4 <iupdate>
    800058c8:	b781                	j	80005808 <sys_unlink+0xe0>
    return -1;
    800058ca:	557d                	li	a0,-1
    800058cc:	a005                	j	800058ec <sys_unlink+0x1c4>
    iunlockput(ip);
    800058ce:	854a                	mv	a0,s2
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	320080e7          	jalr	800(ra) # 80003bf0 <iunlockput>
  iunlockput(dp);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	316080e7          	jalr	790(ra) # 80003bf0 <iunlockput>
  end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	afe080e7          	jalr	-1282(ra) # 800043e0 <end_op>
  return -1;
    800058ea:	557d                	li	a0,-1
}
    800058ec:	70ae                	ld	ra,232(sp)
    800058ee:	740e                	ld	s0,224(sp)
    800058f0:	64ee                	ld	s1,216(sp)
    800058f2:	694e                	ld	s2,208(sp)
    800058f4:	69ae                	ld	s3,200(sp)
    800058f6:	616d                	addi	sp,sp,240
    800058f8:	8082                	ret

00000000800058fa <sys_open>:

uint64
sys_open(void)
{
    800058fa:	7131                	addi	sp,sp,-192
    800058fc:	fd06                	sd	ra,184(sp)
    800058fe:	f922                	sd	s0,176(sp)
    80005900:	f526                	sd	s1,168(sp)
    80005902:	f14a                	sd	s2,160(sp)
    80005904:	ed4e                	sd	s3,152(sp)
    80005906:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005908:	08000613          	li	a2,128
    8000590c:	f5040593          	addi	a1,s0,-176
    80005910:	4501                	li	a0,0
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	4ec080e7          	jalr	1260(ra) # 80002dfe <argstr>
    return -1;
    8000591a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000591c:	0c054163          	bltz	a0,800059de <sys_open+0xe4>
    80005920:	f4c40593          	addi	a1,s0,-180
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	494080e7          	jalr	1172(ra) # 80002dba <argint>
    8000592e:	0a054863          	bltz	a0,800059de <sys_open+0xe4>

  begin_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	a2e080e7          	jalr	-1490(ra) # 80004360 <begin_op>

  if(omode & O_CREATE){
    8000593a:	f4c42783          	lw	a5,-180(s0)
    8000593e:	2007f793          	andi	a5,a5,512
    80005942:	cbdd                	beqz	a5,800059f8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005944:	4681                	li	a3,0
    80005946:	4601                	li	a2,0
    80005948:	4589                	li	a1,2
    8000594a:	f5040513          	addi	a0,s0,-176
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	972080e7          	jalr	-1678(ra) # 800052c0 <create>
    80005956:	892a                	mv	s2,a0
    if(ip == 0){
    80005958:	c959                	beqz	a0,800059ee <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000595a:	04491703          	lh	a4,68(s2)
    8000595e:	478d                	li	a5,3
    80005960:	00f71763          	bne	a4,a5,8000596e <sys_open+0x74>
    80005964:	04695703          	lhu	a4,70(s2)
    80005968:	47a5                	li	a5,9
    8000596a:	0ce7ec63          	bltu	a5,a4,80005a42 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	e02080e7          	jalr	-510(ra) # 80004770 <filealloc>
    80005976:	89aa                	mv	s3,a0
    80005978:	10050263          	beqz	a0,80005a7c <sys_open+0x182>
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	902080e7          	jalr	-1790(ra) # 8000527e <fdalloc>
    80005984:	84aa                	mv	s1,a0
    80005986:	0e054663          	bltz	a0,80005a72 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	478d                	li	a5,3
    80005990:	0cf70463          	beq	a4,a5,80005a58 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005994:	4789                	li	a5,2
    80005996:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000599a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000599e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059a2:	f4c42783          	lw	a5,-180(s0)
    800059a6:	0017c713          	xori	a4,a5,1
    800059aa:	8b05                	andi	a4,a4,1
    800059ac:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059b0:	0037f713          	andi	a4,a5,3
    800059b4:	00e03733          	snez	a4,a4
    800059b8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059bc:	4007f793          	andi	a5,a5,1024
    800059c0:	c791                	beqz	a5,800059cc <sys_open+0xd2>
    800059c2:	04491703          	lh	a4,68(s2)
    800059c6:	4789                	li	a5,2
    800059c8:	08f70f63          	beq	a4,a5,80005a66 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	082080e7          	jalr	130(ra) # 80003a50 <iunlock>
  end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	a0a080e7          	jalr	-1526(ra) # 800043e0 <end_op>

  return fd;
}
    800059de:	8526                	mv	a0,s1
    800059e0:	70ea                	ld	ra,184(sp)
    800059e2:	744a                	ld	s0,176(sp)
    800059e4:	74aa                	ld	s1,168(sp)
    800059e6:	790a                	ld	s2,160(sp)
    800059e8:	69ea                	ld	s3,152(sp)
    800059ea:	6129                	addi	sp,sp,192
    800059ec:	8082                	ret
      end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	9f2080e7          	jalr	-1550(ra) # 800043e0 <end_op>
      return -1;
    800059f6:	b7e5                	j	800059de <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059f8:	f5040513          	addi	a0,s0,-176
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	748080e7          	jalr	1864(ra) # 80004144 <namei>
    80005a04:	892a                	mv	s2,a0
    80005a06:	c905                	beqz	a0,80005a36 <sys_open+0x13c>
    ilock(ip);
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	f86080e7          	jalr	-122(ra) # 8000398e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a10:	04491703          	lh	a4,68(s2)
    80005a14:	4785                	li	a5,1
    80005a16:	f4f712e3          	bne	a4,a5,8000595a <sys_open+0x60>
    80005a1a:	f4c42783          	lw	a5,-180(s0)
    80005a1e:	dba1                	beqz	a5,8000596e <sys_open+0x74>
      iunlockput(ip);
    80005a20:	854a                	mv	a0,s2
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	1ce080e7          	jalr	462(ra) # 80003bf0 <iunlockput>
      end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	9b6080e7          	jalr	-1610(ra) # 800043e0 <end_op>
      return -1;
    80005a32:	54fd                	li	s1,-1
    80005a34:	b76d                	j	800059de <sys_open+0xe4>
      end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	9aa080e7          	jalr	-1622(ra) # 800043e0 <end_op>
      return -1;
    80005a3e:	54fd                	li	s1,-1
    80005a40:	bf79                	j	800059de <sys_open+0xe4>
    iunlockput(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	1ac080e7          	jalr	428(ra) # 80003bf0 <iunlockput>
    end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	994080e7          	jalr	-1644(ra) # 800043e0 <end_op>
    return -1;
    80005a54:	54fd                	li	s1,-1
    80005a56:	b761                	j	800059de <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a58:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a5c:	04691783          	lh	a5,70(s2)
    80005a60:	02f99223          	sh	a5,36(s3)
    80005a64:	bf2d                	j	8000599e <sys_open+0xa4>
    itrunc(ip);
    80005a66:	854a                	mv	a0,s2
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	034080e7          	jalr	52(ra) # 80003a9c <itrunc>
    80005a70:	bfb1                	j	800059cc <sys_open+0xd2>
      fileclose(f);
    80005a72:	854e                	mv	a0,s3
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	db8080e7          	jalr	-584(ra) # 8000482c <fileclose>
    iunlockput(ip);
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	172080e7          	jalr	370(ra) # 80003bf0 <iunlockput>
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	95a080e7          	jalr	-1702(ra) # 800043e0 <end_op>
    return -1;
    80005a8e:	54fd                	li	s1,-1
    80005a90:	b7b9                	j	800059de <sys_open+0xe4>

0000000080005a92 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a92:	7175                	addi	sp,sp,-144
    80005a94:	e506                	sd	ra,136(sp)
    80005a96:	e122                	sd	s0,128(sp)
    80005a98:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	8c6080e7          	jalr	-1850(ra) # 80004360 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f7040593          	addi	a1,s0,-144
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	352080e7          	jalr	850(ra) # 80002dfe <argstr>
    80005ab4:	02054963          	bltz	a0,80005ae6 <sys_mkdir+0x54>
    80005ab8:	4681                	li	a3,0
    80005aba:	4601                	li	a2,0
    80005abc:	4585                	li	a1,1
    80005abe:	f7040513          	addi	a0,s0,-144
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	7fe080e7          	jalr	2046(ra) # 800052c0 <create>
    80005aca:	cd11                	beqz	a0,80005ae6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	124080e7          	jalr	292(ra) # 80003bf0 <iunlockput>
  end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	90c080e7          	jalr	-1780(ra) # 800043e0 <end_op>
  return 0;
    80005adc:	4501                	li	a0,0
}
    80005ade:	60aa                	ld	ra,136(sp)
    80005ae0:	640a                	ld	s0,128(sp)
    80005ae2:	6149                	addi	sp,sp,144
    80005ae4:	8082                	ret
    end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	8fa080e7          	jalr	-1798(ra) # 800043e0 <end_op>
    return -1;
    80005aee:	557d                	li	a0,-1
    80005af0:	b7fd                	j	80005ade <sys_mkdir+0x4c>

0000000080005af2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005af2:	7135                	addi	sp,sp,-160
    80005af4:	ed06                	sd	ra,152(sp)
    80005af6:	e922                	sd	s0,144(sp)
    80005af8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	866080e7          	jalr	-1946(ra) # 80004360 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b02:	08000613          	li	a2,128
    80005b06:	f7040593          	addi	a1,s0,-144
    80005b0a:	4501                	li	a0,0
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	2f2080e7          	jalr	754(ra) # 80002dfe <argstr>
    80005b14:	04054a63          	bltz	a0,80005b68 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b18:	f6c40593          	addi	a1,s0,-148
    80005b1c:	4505                	li	a0,1
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	29c080e7          	jalr	668(ra) # 80002dba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b26:	04054163          	bltz	a0,80005b68 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b2a:	f6840593          	addi	a1,s0,-152
    80005b2e:	4509                	li	a0,2
    80005b30:	ffffd097          	auipc	ra,0xffffd
    80005b34:	28a080e7          	jalr	650(ra) # 80002dba <argint>
     argint(1, &major) < 0 ||
    80005b38:	02054863          	bltz	a0,80005b68 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b3c:	f6841683          	lh	a3,-152(s0)
    80005b40:	f6c41603          	lh	a2,-148(s0)
    80005b44:	458d                	li	a1,3
    80005b46:	f7040513          	addi	a0,s0,-144
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	776080e7          	jalr	1910(ra) # 800052c0 <create>
     argint(2, &minor) < 0 ||
    80005b52:	c919                	beqz	a0,80005b68 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	09c080e7          	jalr	156(ra) # 80003bf0 <iunlockput>
  end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	884080e7          	jalr	-1916(ra) # 800043e0 <end_op>
  return 0;
    80005b64:	4501                	li	a0,0
    80005b66:	a031                	j	80005b72 <sys_mknod+0x80>
    end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	878080e7          	jalr	-1928(ra) # 800043e0 <end_op>
    return -1;
    80005b70:	557d                	li	a0,-1
}
    80005b72:	60ea                	ld	ra,152(sp)
    80005b74:	644a                	ld	s0,144(sp)
    80005b76:	610d                	addi	sp,sp,160
    80005b78:	8082                	ret

0000000080005b7a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b7a:	7135                	addi	sp,sp,-160
    80005b7c:	ed06                	sd	ra,152(sp)
    80005b7e:	e922                	sd	s0,144(sp)
    80005b80:	e526                	sd	s1,136(sp)
    80005b82:	e14a                	sd	s2,128(sp)
    80005b84:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b86:	ffffc097          	auipc	ra,0xffffc
    80005b8a:	0ee080e7          	jalr	238(ra) # 80001c74 <myproc>
    80005b8e:	892a                	mv	s2,a0
  
  begin_op();
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	7d0080e7          	jalr	2000(ra) # 80004360 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b98:	08000613          	li	a2,128
    80005b9c:	f6040593          	addi	a1,s0,-160
    80005ba0:	4501                	li	a0,0
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	25c080e7          	jalr	604(ra) # 80002dfe <argstr>
    80005baa:	04054b63          	bltz	a0,80005c00 <sys_chdir+0x86>
    80005bae:	f6040513          	addi	a0,s0,-160
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	592080e7          	jalr	1426(ra) # 80004144 <namei>
    80005bba:	84aa                	mv	s1,a0
    80005bbc:	c131                	beqz	a0,80005c00 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	dd0080e7          	jalr	-560(ra) # 8000398e <ilock>
  if(ip->type != T_DIR){
    80005bc6:	04449703          	lh	a4,68(s1)
    80005bca:	4785                	li	a5,1
    80005bcc:	04f71063          	bne	a4,a5,80005c0c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	e7e080e7          	jalr	-386(ra) # 80003a50 <iunlock>
  iput(p->cwd);
    80005bda:	16893503          	ld	a0,360(s2)
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	f6a080e7          	jalr	-150(ra) # 80003b48 <iput>
  end_op();
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	7fa080e7          	jalr	2042(ra) # 800043e0 <end_op>
  p->cwd = ip;
    80005bee:	16993423          	sd	s1,360(s2)
  return 0;
    80005bf2:	4501                	li	a0,0
}
    80005bf4:	60ea                	ld	ra,152(sp)
    80005bf6:	644a                	ld	s0,144(sp)
    80005bf8:	64aa                	ld	s1,136(sp)
    80005bfa:	690a                	ld	s2,128(sp)
    80005bfc:	610d                	addi	sp,sp,160
    80005bfe:	8082                	ret
    end_op();
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	7e0080e7          	jalr	2016(ra) # 800043e0 <end_op>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	b7ed                	j	80005bf4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	fe2080e7          	jalr	-30(ra) # 80003bf0 <iunlockput>
    end_op();
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	7ca080e7          	jalr	1994(ra) # 800043e0 <end_op>
    return -1;
    80005c1e:	557d                	li	a0,-1
    80005c20:	bfd1                	j	80005bf4 <sys_chdir+0x7a>

0000000080005c22 <sys_exec>:

uint64
sys_exec(void)
{
    80005c22:	7145                	addi	sp,sp,-464
    80005c24:	e786                	sd	ra,456(sp)
    80005c26:	e3a2                	sd	s0,448(sp)
    80005c28:	ff26                	sd	s1,440(sp)
    80005c2a:	fb4a                	sd	s2,432(sp)
    80005c2c:	f74e                	sd	s3,424(sp)
    80005c2e:	f352                	sd	s4,416(sp)
    80005c30:	ef56                	sd	s5,408(sp)
    80005c32:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c34:	08000613          	li	a2,128
    80005c38:	f4040593          	addi	a1,s0,-192
    80005c3c:	4501                	li	a0,0
    80005c3e:	ffffd097          	auipc	ra,0xffffd
    80005c42:	1c0080e7          	jalr	448(ra) # 80002dfe <argstr>
    return -1;
    80005c46:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c48:	0c054a63          	bltz	a0,80005d1c <sys_exec+0xfa>
    80005c4c:	e3840593          	addi	a1,s0,-456
    80005c50:	4505                	li	a0,1
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	18a080e7          	jalr	394(ra) # 80002ddc <argaddr>
    80005c5a:	0c054163          	bltz	a0,80005d1c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c5e:	10000613          	li	a2,256
    80005c62:	4581                	li	a1,0
    80005c64:	e4040513          	addi	a0,s0,-448
    80005c68:	ffffb097          	auipc	ra,0xffffb
    80005c6c:	078080e7          	jalr	120(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c70:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c74:	89a6                	mv	s3,s1
    80005c76:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c78:	02000a13          	li	s4,32
    80005c7c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c80:	00391513          	slli	a0,s2,0x3
    80005c84:	e3040593          	addi	a1,s0,-464
    80005c88:	e3843783          	ld	a5,-456(s0)
    80005c8c:	953e                	add	a0,a0,a5
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	092080e7          	jalr	146(ra) # 80002d20 <fetchaddr>
    80005c96:	02054a63          	bltz	a0,80005cca <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c9a:	e3043783          	ld	a5,-464(s0)
    80005c9e:	c3b9                	beqz	a5,80005ce4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca0:	ffffb097          	auipc	ra,0xffffb
    80005ca4:	e54080e7          	jalr	-428(ra) # 80000af4 <kalloc>
    80005ca8:	85aa                	mv	a1,a0
    80005caa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cae:	cd11                	beqz	a0,80005cca <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb0:	6605                	lui	a2,0x1
    80005cb2:	e3043503          	ld	a0,-464(s0)
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	0bc080e7          	jalr	188(ra) # 80002d72 <fetchstr>
    80005cbe:	00054663          	bltz	a0,80005cca <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cc2:	0905                	addi	s2,s2,1
    80005cc4:	09a1                	addi	s3,s3,8
    80005cc6:	fb491be3          	bne	s2,s4,80005c7c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cca:	10048913          	addi	s2,s1,256
    80005cce:	6088                	ld	a0,0(s1)
    80005cd0:	c529                	beqz	a0,80005d1a <sys_exec+0xf8>
    kfree(argv[i]);
    80005cd2:	ffffb097          	auipc	ra,0xffffb
    80005cd6:	d26080e7          	jalr	-730(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cda:	04a1                	addi	s1,s1,8
    80005cdc:	ff2499e3          	bne	s1,s2,80005cce <sys_exec+0xac>
  return -1;
    80005ce0:	597d                	li	s2,-1
    80005ce2:	a82d                	j	80005d1c <sys_exec+0xfa>
      argv[i] = 0;
    80005ce4:	0a8e                	slli	s5,s5,0x3
    80005ce6:	fc040793          	addi	a5,s0,-64
    80005cea:	9abe                	add	s5,s5,a5
    80005cec:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cf0:	e4040593          	addi	a1,s0,-448
    80005cf4:	f4040513          	addi	a0,s0,-192
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	194080e7          	jalr	404(ra) # 80004e8c <exec>
    80005d00:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d02:	10048993          	addi	s3,s1,256
    80005d06:	6088                	ld	a0,0(s1)
    80005d08:	c911                	beqz	a0,80005d1c <sys_exec+0xfa>
    kfree(argv[i]);
    80005d0a:	ffffb097          	auipc	ra,0xffffb
    80005d0e:	cee080e7          	jalr	-786(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d12:	04a1                	addi	s1,s1,8
    80005d14:	ff3499e3          	bne	s1,s3,80005d06 <sys_exec+0xe4>
    80005d18:	a011                	j	80005d1c <sys_exec+0xfa>
  return -1;
    80005d1a:	597d                	li	s2,-1
}
    80005d1c:	854a                	mv	a0,s2
    80005d1e:	60be                	ld	ra,456(sp)
    80005d20:	641e                	ld	s0,448(sp)
    80005d22:	74fa                	ld	s1,440(sp)
    80005d24:	795a                	ld	s2,432(sp)
    80005d26:	79ba                	ld	s3,424(sp)
    80005d28:	7a1a                	ld	s4,416(sp)
    80005d2a:	6afa                	ld	s5,408(sp)
    80005d2c:	6179                	addi	sp,sp,464
    80005d2e:	8082                	ret

0000000080005d30 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d30:	7139                	addi	sp,sp,-64
    80005d32:	fc06                	sd	ra,56(sp)
    80005d34:	f822                	sd	s0,48(sp)
    80005d36:	f426                	sd	s1,40(sp)
    80005d38:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d3a:	ffffc097          	auipc	ra,0xffffc
    80005d3e:	f3a080e7          	jalr	-198(ra) # 80001c74 <myproc>
    80005d42:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d44:	fd840593          	addi	a1,s0,-40
    80005d48:	4501                	li	a0,0
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	092080e7          	jalr	146(ra) # 80002ddc <argaddr>
    return -1;
    80005d52:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d54:	0e054063          	bltz	a0,80005e34 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d58:	fc840593          	addi	a1,s0,-56
    80005d5c:	fd040513          	addi	a0,s0,-48
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	dfc080e7          	jalr	-516(ra) # 80004b5c <pipealloc>
    return -1;
    80005d68:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d6a:	0c054563          	bltz	a0,80005e34 <sys_pipe+0x104>
  fd0 = -1;
    80005d6e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d72:	fd043503          	ld	a0,-48(s0)
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	508080e7          	jalr	1288(ra) # 8000527e <fdalloc>
    80005d7e:	fca42223          	sw	a0,-60(s0)
    80005d82:	08054c63          	bltz	a0,80005e1a <sys_pipe+0xea>
    80005d86:	fc843503          	ld	a0,-56(s0)
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	4f4080e7          	jalr	1268(ra) # 8000527e <fdalloc>
    80005d92:	fca42023          	sw	a0,-64(s0)
    80005d96:	06054863          	bltz	a0,80005e06 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9a:	4691                	li	a3,4
    80005d9c:	fc440613          	addi	a2,s0,-60
    80005da0:	fd843583          	ld	a1,-40(s0)
    80005da4:	74a8                	ld	a0,104(s1)
    80005da6:	ffffc097          	auipc	ra,0xffffc
    80005daa:	8cc080e7          	jalr	-1844(ra) # 80001672 <copyout>
    80005dae:	02054063          	bltz	a0,80005dce <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db2:	4691                	li	a3,4
    80005db4:	fc040613          	addi	a2,s0,-64
    80005db8:	fd843583          	ld	a1,-40(s0)
    80005dbc:	0591                	addi	a1,a1,4
    80005dbe:	74a8                	ld	a0,104(s1)
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	8b2080e7          	jalr	-1870(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dc8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dca:	06055563          	bgez	a0,80005e34 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dce:	fc442783          	lw	a5,-60(s0)
    80005dd2:	07f1                	addi	a5,a5,28
    80005dd4:	078e                	slli	a5,a5,0x3
    80005dd6:	97a6                	add	a5,a5,s1
    80005dd8:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005ddc:	fc042503          	lw	a0,-64(s0)
    80005de0:	0571                	addi	a0,a0,28
    80005de2:	050e                	slli	a0,a0,0x3
    80005de4:	9526                	add	a0,a0,s1
    80005de6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dea:	fd043503          	ld	a0,-48(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	a3e080e7          	jalr	-1474(ra) # 8000482c <fileclose>
    fileclose(wf);
    80005df6:	fc843503          	ld	a0,-56(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	a32080e7          	jalr	-1486(ra) # 8000482c <fileclose>
    return -1;
    80005e02:	57fd                	li	a5,-1
    80005e04:	a805                	j	80005e34 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e06:	fc442783          	lw	a5,-60(s0)
    80005e0a:	0007c863          	bltz	a5,80005e1a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e0e:	01c78513          	addi	a0,a5,28
    80005e12:	050e                	slli	a0,a0,0x3
    80005e14:	9526                	add	a0,a0,s1
    80005e16:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e1a:	fd043503          	ld	a0,-48(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	a0e080e7          	jalr	-1522(ra) # 8000482c <fileclose>
    fileclose(wf);
    80005e26:	fc843503          	ld	a0,-56(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	a02080e7          	jalr	-1534(ra) # 8000482c <fileclose>
    return -1;
    80005e32:	57fd                	li	a5,-1
}
    80005e34:	853e                	mv	a0,a5
    80005e36:	70e2                	ld	ra,56(sp)
    80005e38:	7442                	ld	s0,48(sp)
    80005e3a:	74a2                	ld	s1,40(sp)
    80005e3c:	6121                	addi	sp,sp,64
    80005e3e:	8082                	ret

0000000080005e40 <kernelvec>:
    80005e40:	7111                	addi	sp,sp,-256
    80005e42:	e006                	sd	ra,0(sp)
    80005e44:	e40a                	sd	sp,8(sp)
    80005e46:	e80e                	sd	gp,16(sp)
    80005e48:	ec12                	sd	tp,24(sp)
    80005e4a:	f016                	sd	t0,32(sp)
    80005e4c:	f41a                	sd	t1,40(sp)
    80005e4e:	f81e                	sd	t2,48(sp)
    80005e50:	fc22                	sd	s0,56(sp)
    80005e52:	e0a6                	sd	s1,64(sp)
    80005e54:	e4aa                	sd	a0,72(sp)
    80005e56:	e8ae                	sd	a1,80(sp)
    80005e58:	ecb2                	sd	a2,88(sp)
    80005e5a:	f0b6                	sd	a3,96(sp)
    80005e5c:	f4ba                	sd	a4,104(sp)
    80005e5e:	f8be                	sd	a5,112(sp)
    80005e60:	fcc2                	sd	a6,120(sp)
    80005e62:	e146                	sd	a7,128(sp)
    80005e64:	e54a                	sd	s2,136(sp)
    80005e66:	e94e                	sd	s3,144(sp)
    80005e68:	ed52                	sd	s4,152(sp)
    80005e6a:	f156                	sd	s5,160(sp)
    80005e6c:	f55a                	sd	s6,168(sp)
    80005e6e:	f95e                	sd	s7,176(sp)
    80005e70:	fd62                	sd	s8,184(sp)
    80005e72:	e1e6                	sd	s9,192(sp)
    80005e74:	e5ea                	sd	s10,200(sp)
    80005e76:	e9ee                	sd	s11,208(sp)
    80005e78:	edf2                	sd	t3,216(sp)
    80005e7a:	f1f6                	sd	t4,224(sp)
    80005e7c:	f5fa                	sd	t5,232(sp)
    80005e7e:	f9fe                	sd	t6,240(sp)
    80005e80:	d97fc0ef          	jal	ra,80002c16 <kerneltrap>
    80005e84:	6082                	ld	ra,0(sp)
    80005e86:	6122                	ld	sp,8(sp)
    80005e88:	61c2                	ld	gp,16(sp)
    80005e8a:	7282                	ld	t0,32(sp)
    80005e8c:	7322                	ld	t1,40(sp)
    80005e8e:	73c2                	ld	t2,48(sp)
    80005e90:	7462                	ld	s0,56(sp)
    80005e92:	6486                	ld	s1,64(sp)
    80005e94:	6526                	ld	a0,72(sp)
    80005e96:	65c6                	ld	a1,80(sp)
    80005e98:	6666                	ld	a2,88(sp)
    80005e9a:	7686                	ld	a3,96(sp)
    80005e9c:	7726                	ld	a4,104(sp)
    80005e9e:	77c6                	ld	a5,112(sp)
    80005ea0:	7866                	ld	a6,120(sp)
    80005ea2:	688a                	ld	a7,128(sp)
    80005ea4:	692a                	ld	s2,136(sp)
    80005ea6:	69ca                	ld	s3,144(sp)
    80005ea8:	6a6a                	ld	s4,152(sp)
    80005eaa:	7a8a                	ld	s5,160(sp)
    80005eac:	7b2a                	ld	s6,168(sp)
    80005eae:	7bca                	ld	s7,176(sp)
    80005eb0:	7c6a                	ld	s8,184(sp)
    80005eb2:	6c8e                	ld	s9,192(sp)
    80005eb4:	6d2e                	ld	s10,200(sp)
    80005eb6:	6dce                	ld	s11,208(sp)
    80005eb8:	6e6e                	ld	t3,216(sp)
    80005eba:	7e8e                	ld	t4,224(sp)
    80005ebc:	7f2e                	ld	t5,232(sp)
    80005ebe:	7fce                	ld	t6,240(sp)
    80005ec0:	6111                	addi	sp,sp,256
    80005ec2:	10200073          	sret
    80005ec6:	00000013          	nop
    80005eca:	00000013          	nop
    80005ece:	0001                	nop

0000000080005ed0 <timervec>:
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	e10c                	sd	a1,0(a0)
    80005ed6:	e510                	sd	a2,8(a0)
    80005ed8:	e914                	sd	a3,16(a0)
    80005eda:	6d0c                	ld	a1,24(a0)
    80005edc:	7110                	ld	a2,32(a0)
    80005ede:	6194                	ld	a3,0(a1)
    80005ee0:	96b2                	add	a3,a3,a2
    80005ee2:	e194                	sd	a3,0(a1)
    80005ee4:	4589                	li	a1,2
    80005ee6:	14459073          	csrw	sip,a1
    80005eea:	6914                	ld	a3,16(a0)
    80005eec:	6510                	ld	a2,8(a0)
    80005eee:	610c                	ld	a1,0(a0)
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	30200073          	mret
	...

0000000080005efa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005efa:	1141                	addi	sp,sp,-16
    80005efc:	e422                	sd	s0,8(sp)
    80005efe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f00:	0c0007b7          	lui	a5,0xc000
    80005f04:	4705                	li	a4,1
    80005f06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f08:	c3d8                	sw	a4,4(a5)
}
    80005f0a:	6422                	ld	s0,8(sp)
    80005f0c:	0141                	addi	sp,sp,16
    80005f0e:	8082                	ret

0000000080005f10 <plicinithart>:

void
plicinithart(void)
{
    80005f10:	1141                	addi	sp,sp,-16
    80005f12:	e406                	sd	ra,8(sp)
    80005f14:	e022                	sd	s0,0(sp)
    80005f16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	d30080e7          	jalr	-720(ra) # 80001c48 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f20:	0085171b          	slliw	a4,a0,0x8
    80005f24:	0c0027b7          	lui	a5,0xc002
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	40200713          	li	a4,1026
    80005f2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f32:	00d5151b          	slliw	a0,a0,0xd
    80005f36:	0c2017b7          	lui	a5,0xc201
    80005f3a:	953e                	add	a0,a0,a5
    80005f3c:	00052023          	sw	zero,0(a0)
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret

0000000080005f48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f48:	1141                	addi	sp,sp,-16
    80005f4a:	e406                	sd	ra,8(sp)
    80005f4c:	e022                	sd	s0,0(sp)
    80005f4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	cf8080e7          	jalr	-776(ra) # 80001c48 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f58:	00d5179b          	slliw	a5,a0,0xd
    80005f5c:	0c201537          	lui	a0,0xc201
    80005f60:	953e                	add	a0,a0,a5
  return irq;
}
    80005f62:	4148                	lw	a0,4(a0)
    80005f64:	60a2                	ld	ra,8(sp)
    80005f66:	6402                	ld	s0,0(sp)
    80005f68:	0141                	addi	sp,sp,16
    80005f6a:	8082                	ret

0000000080005f6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f6c:	1101                	addi	sp,sp,-32
    80005f6e:	ec06                	sd	ra,24(sp)
    80005f70:	e822                	sd	s0,16(sp)
    80005f72:	e426                	sd	s1,8(sp)
    80005f74:	1000                	addi	s0,sp,32
    80005f76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	cd0080e7          	jalr	-816(ra) # 80001c48 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f80:	00d5151b          	slliw	a0,a0,0xd
    80005f84:	0c2017b7          	lui	a5,0xc201
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	c3c4                	sw	s1,4(a5)
}
    80005f8c:	60e2                	ld	ra,24(sp)
    80005f8e:	6442                	ld	s0,16(sp)
    80005f90:	64a2                	ld	s1,8(sp)
    80005f92:	6105                	addi	sp,sp,32
    80005f94:	8082                	ret

0000000080005f96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f96:	1141                	addi	sp,sp,-16
    80005f98:	e406                	sd	ra,8(sp)
    80005f9a:	e022                	sd	s0,0(sp)
    80005f9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f9e:	479d                	li	a5,7
    80005fa0:	06a7c963          	blt	a5,a0,80006012 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005fa4:	0001d797          	auipc	a5,0x1d
    80005fa8:	05c78793          	addi	a5,a5,92 # 80023000 <disk>
    80005fac:	00a78733          	add	a4,a5,a0
    80005fb0:	6789                	lui	a5,0x2
    80005fb2:	97ba                	add	a5,a5,a4
    80005fb4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fb8:	e7ad                	bnez	a5,80006022 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fba:	00451793          	slli	a5,a0,0x4
    80005fbe:	0001f717          	auipc	a4,0x1f
    80005fc2:	04270713          	addi	a4,a4,66 # 80025000 <disk+0x2000>
    80005fc6:	6314                	ld	a3,0(a4)
    80005fc8:	96be                	add	a3,a3,a5
    80005fca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fce:	6314                	ld	a3,0(a4)
    80005fd0:	96be                	add	a3,a3,a5
    80005fd2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fd6:	6314                	ld	a3,0(a4)
    80005fd8:	96be                	add	a3,a3,a5
    80005fda:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fde:	6318                	ld	a4,0(a4)
    80005fe0:	97ba                	add	a5,a5,a4
    80005fe2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fe6:	0001d797          	auipc	a5,0x1d
    80005fea:	01a78793          	addi	a5,a5,26 # 80023000 <disk>
    80005fee:	97aa                	add	a5,a5,a0
    80005ff0:	6509                	lui	a0,0x2
    80005ff2:	953e                	add	a0,a0,a5
    80005ff4:	4785                	li	a5,1
    80005ff6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ffa:	0001f517          	auipc	a0,0x1f
    80005ffe:	01e50513          	addi	a0,a0,30 # 80025018 <disk+0x2018>
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	50a080e7          	jalr	1290(ra) # 8000250c <wakeup>
}
    8000600a:	60a2                	ld	ra,8(sp)
    8000600c:	6402                	ld	s0,0(sp)
    8000600e:	0141                	addi	sp,sp,16
    80006010:	8082                	ret
    panic("free_desc 1");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	80650513          	addi	a0,a0,-2042 # 80008818 <syscalls+0x338>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	80650513          	addi	a0,a0,-2042 # 80008828 <syscalls+0x348>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	514080e7          	jalr	1300(ra) # 8000053e <panic>

0000000080006032 <virtio_disk_init>:
{
    80006032:	1101                	addi	sp,sp,-32
    80006034:	ec06                	sd	ra,24(sp)
    80006036:	e822                	sd	s0,16(sp)
    80006038:	e426                	sd	s1,8(sp)
    8000603a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000603c:	00002597          	auipc	a1,0x2
    80006040:	7fc58593          	addi	a1,a1,2044 # 80008838 <syscalls+0x358>
    80006044:	0001f517          	auipc	a0,0x1f
    80006048:	0e450513          	addi	a0,a0,228 # 80025128 <disk+0x2128>
    8000604c:	ffffb097          	auipc	ra,0xffffb
    80006050:	b08080e7          	jalr	-1272(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	4398                	lw	a4,0(a5)
    8000605a:	2701                	sext.w	a4,a4
    8000605c:	747277b7          	lui	a5,0x74727
    80006060:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006064:	0ef71163          	bne	a4,a5,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	43dc                	lw	a5,4(a5)
    8000606e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006070:	4705                	li	a4,1
    80006072:	0ce79a63          	bne	a5,a4,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006076:	100017b7          	lui	a5,0x10001
    8000607a:	479c                	lw	a5,8(a5)
    8000607c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	4709                	li	a4,2
    80006080:	0ce79363          	bne	a5,a4,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	47d8                	lw	a4,12(a5)
    8000608a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	554d47b7          	lui	a5,0x554d4
    80006090:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006094:	0af71963          	bne	a4,a5,80006146 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006098:	100017b7          	lui	a5,0x10001
    8000609c:	4705                	li	a4,1
    8000609e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a0:	470d                	li	a4,3
    800060a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060a6:	c7ffe737          	lui	a4,0xc7ffe
    800060aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060b0:	2701                	sext.w	a4,a4
    800060b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b4:	472d                	li	a4,11
    800060b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b8:	473d                	li	a4,15
    800060ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060bc:	6705                	lui	a4,0x1
    800060be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060c4:	5bdc                	lw	a5,52(a5)
    800060c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c8:	c7d9                	beqz	a5,80006156 <virtio_disk_init+0x124>
  if(max < NUM)
    800060ca:	471d                	li	a4,7
    800060cc:	08f77d63          	bgeu	a4,a5,80006166 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060d0:	100014b7          	lui	s1,0x10001
    800060d4:	47a1                	li	a5,8
    800060d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060d8:	6609                	lui	a2,0x2
    800060da:	4581                	li	a1,0
    800060dc:	0001d517          	auipc	a0,0x1d
    800060e0:	f2450513          	addi	a0,a0,-220 # 80023000 <disk>
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	bfc080e7          	jalr	-1028(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060ec:	0001d717          	auipc	a4,0x1d
    800060f0:	f1470713          	addi	a4,a4,-236 # 80023000 <disk>
    800060f4:	00c75793          	srli	a5,a4,0xc
    800060f8:	2781                	sext.w	a5,a5
    800060fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060fc:	0001f797          	auipc	a5,0x1f
    80006100:	f0478793          	addi	a5,a5,-252 # 80025000 <disk+0x2000>
    80006104:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006106:	0001d717          	auipc	a4,0x1d
    8000610a:	f7a70713          	addi	a4,a4,-134 # 80023080 <disk+0x80>
    8000610e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006110:	0001e717          	auipc	a4,0x1e
    80006114:	ef070713          	addi	a4,a4,-272 # 80024000 <disk+0x1000>
    80006118:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000611a:	4705                	li	a4,1
    8000611c:	00e78c23          	sb	a4,24(a5)
    80006120:	00e78ca3          	sb	a4,25(a5)
    80006124:	00e78d23          	sb	a4,26(a5)
    80006128:	00e78da3          	sb	a4,27(a5)
    8000612c:	00e78e23          	sb	a4,28(a5)
    80006130:	00e78ea3          	sb	a4,29(a5)
    80006134:	00e78f23          	sb	a4,30(a5)
    80006138:	00e78fa3          	sb	a4,31(a5)
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret
    panic("could not find virtio disk");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	70250513          	addi	a0,a0,1794 # 80008848 <syscalls+0x368>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006156:	00002517          	auipc	a0,0x2
    8000615a:	71250513          	addi	a0,a0,1810 # 80008868 <syscalls+0x388>
    8000615e:	ffffa097          	auipc	ra,0xffffa
    80006162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006166:	00002517          	auipc	a0,0x2
    8000616a:	72250513          	addi	a0,a0,1826 # 80008888 <syscalls+0x3a8>
    8000616e:	ffffa097          	auipc	ra,0xffffa
    80006172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>

0000000080006176 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006176:	7159                	addi	sp,sp,-112
    80006178:	f486                	sd	ra,104(sp)
    8000617a:	f0a2                	sd	s0,96(sp)
    8000617c:	eca6                	sd	s1,88(sp)
    8000617e:	e8ca                	sd	s2,80(sp)
    80006180:	e4ce                	sd	s3,72(sp)
    80006182:	e0d2                	sd	s4,64(sp)
    80006184:	fc56                	sd	s5,56(sp)
    80006186:	f85a                	sd	s6,48(sp)
    80006188:	f45e                	sd	s7,40(sp)
    8000618a:	f062                	sd	s8,32(sp)
    8000618c:	ec66                	sd	s9,24(sp)
    8000618e:	e86a                	sd	s10,16(sp)
    80006190:	1880                	addi	s0,sp,112
    80006192:	892a                	mv	s2,a0
    80006194:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006196:	00c52c83          	lw	s9,12(a0)
    8000619a:	001c9c9b          	slliw	s9,s9,0x1
    8000619e:	1c82                	slli	s9,s9,0x20
    800061a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061a4:	0001f517          	auipc	a0,0x1f
    800061a8:	f8450513          	addi	a0,a0,-124 # 80025128 <disk+0x2128>
    800061ac:	ffffb097          	auipc	ra,0xffffb
    800061b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061b8:	0001db97          	auipc	s7,0x1d
    800061bc:	e48b8b93          	addi	s7,s7,-440 # 80023000 <disk>
    800061c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061c4:	8a4e                	mv	s4,s3
    800061c6:	a051                	j	8000624a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061c8:	00fb86b3          	add	a3,s7,a5
    800061cc:	96da                	add	a3,a3,s6
    800061ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061d4:	0207c563          	bltz	a5,800061fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061d8:	2485                	addiw	s1,s1,1
    800061da:	0711                	addi	a4,a4,4
    800061dc:	25548063          	beq	s1,s5,8000641c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061e2:	0001f697          	auipc	a3,0x1f
    800061e6:	e3668693          	addi	a3,a3,-458 # 80025018 <disk+0x2018>
    800061ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061ec:	0006c583          	lbu	a1,0(a3)
    800061f0:	fde1                	bnez	a1,800061c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061f2:	2785                	addiw	a5,a5,1
    800061f4:	0685                	addi	a3,a3,1
    800061f6:	ff879be3          	bne	a5,s8,800061ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061fa:	57fd                	li	a5,-1
    800061fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061fe:	02905a63          	blez	s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006202:	f9042503          	lw	a0,-112(s0)
    80006206:	00000097          	auipc	ra,0x0
    8000620a:	d90080e7          	jalr	-624(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    8000620e:	4785                	li	a5,1
    80006210:	0297d163          	bge	a5,s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006214:	f9442503          	lw	a0,-108(s0)
    80006218:	00000097          	auipc	ra,0x0
    8000621c:	d7e080e7          	jalr	-642(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    80006220:	4789                	li	a5,2
    80006222:	0097d863          	bge	a5,s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006226:	f9842503          	lw	a0,-104(s0)
    8000622a:	00000097          	auipc	ra,0x0
    8000622e:	d6c080e7          	jalr	-660(ra) # 80005f96 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006232:	0001f597          	auipc	a1,0x1f
    80006236:	ef658593          	addi	a1,a1,-266 # 80025128 <disk+0x2128>
    8000623a:	0001f517          	auipc	a0,0x1f
    8000623e:	dde50513          	addi	a0,a0,-546 # 80025018 <disk+0x2018>
    80006242:	ffffc097          	auipc	ra,0xffffc
    80006246:	0f8080e7          	jalr	248(ra) # 8000233a <sleep>
  for(int i = 0; i < 3; i++){
    8000624a:	f9040713          	addi	a4,s0,-112
    8000624e:	84ce                	mv	s1,s3
    80006250:	bf41                	j	800061e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006252:	20058713          	addi	a4,a1,512
    80006256:	00471693          	slli	a3,a4,0x4
    8000625a:	0001d717          	auipc	a4,0x1d
    8000625e:	da670713          	addi	a4,a4,-602 # 80023000 <disk>
    80006262:	9736                	add	a4,a4,a3
    80006264:	4685                	li	a3,1
    80006266:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000626a:	20058713          	addi	a4,a1,512
    8000626e:	00471693          	slli	a3,a4,0x4
    80006272:	0001d717          	auipc	a4,0x1d
    80006276:	d8e70713          	addi	a4,a4,-626 # 80023000 <disk>
    8000627a:	9736                	add	a4,a4,a3
    8000627c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006280:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006284:	7679                	lui	a2,0xffffe
    80006286:	963e                	add	a2,a2,a5
    80006288:	0001f697          	auipc	a3,0x1f
    8000628c:	d7868693          	addi	a3,a3,-648 # 80025000 <disk+0x2000>
    80006290:	6298                	ld	a4,0(a3)
    80006292:	9732                	add	a4,a4,a2
    80006294:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006296:	6298                	ld	a4,0(a3)
    80006298:	9732                	add	a4,a4,a2
    8000629a:	4541                	li	a0,16
    8000629c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000629e:	6298                	ld	a4,0(a3)
    800062a0:	9732                	add	a4,a4,a2
    800062a2:	4505                	li	a0,1
    800062a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062a8:	f9442703          	lw	a4,-108(s0)
    800062ac:	6288                	ld	a0,0(a3)
    800062ae:	962a                	add	a2,a2,a0
    800062b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062b4:	0712                	slli	a4,a4,0x4
    800062b6:	6290                	ld	a2,0(a3)
    800062b8:	963a                	add	a2,a2,a4
    800062ba:	05890513          	addi	a0,s2,88
    800062be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062c0:	6294                	ld	a3,0(a3)
    800062c2:	96ba                	add	a3,a3,a4
    800062c4:	40000613          	li	a2,1024
    800062c8:	c690                	sw	a2,8(a3)
  if(write)
    800062ca:	140d0063          	beqz	s10,8000640a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ce:	0001f697          	auipc	a3,0x1f
    800062d2:	d326b683          	ld	a3,-718(a3) # 80025000 <disk+0x2000>
    800062d6:	96ba                	add	a3,a3,a4
    800062d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062dc:	0001d817          	auipc	a6,0x1d
    800062e0:	d2480813          	addi	a6,a6,-732 # 80023000 <disk>
    800062e4:	0001f517          	auipc	a0,0x1f
    800062e8:	d1c50513          	addi	a0,a0,-740 # 80025000 <disk+0x2000>
    800062ec:	6114                	ld	a3,0(a0)
    800062ee:	96ba                	add	a3,a3,a4
    800062f0:	00c6d603          	lhu	a2,12(a3)
    800062f4:	00166613          	ori	a2,a2,1
    800062f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062fc:	f9842683          	lw	a3,-104(s0)
    80006300:	6110                	ld	a2,0(a0)
    80006302:	9732                	add	a4,a4,a2
    80006304:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006308:	20058613          	addi	a2,a1,512
    8000630c:	0612                	slli	a2,a2,0x4
    8000630e:	9642                	add	a2,a2,a6
    80006310:	577d                	li	a4,-1
    80006312:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006316:	00469713          	slli	a4,a3,0x4
    8000631a:	6114                	ld	a3,0(a0)
    8000631c:	96ba                	add	a3,a3,a4
    8000631e:	03078793          	addi	a5,a5,48
    80006322:	97c2                	add	a5,a5,a6
    80006324:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006326:	611c                	ld	a5,0(a0)
    80006328:	97ba                	add	a5,a5,a4
    8000632a:	4685                	li	a3,1
    8000632c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000632e:	611c                	ld	a5,0(a0)
    80006330:	97ba                	add	a5,a5,a4
    80006332:	4809                	li	a6,2
    80006334:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006338:	611c                	ld	a5,0(a0)
    8000633a:	973e                	add	a4,a4,a5
    8000633c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006340:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006344:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006348:	6518                	ld	a4,8(a0)
    8000634a:	00275783          	lhu	a5,2(a4)
    8000634e:	8b9d                	andi	a5,a5,7
    80006350:	0786                	slli	a5,a5,0x1
    80006352:	97ba                	add	a5,a5,a4
    80006354:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006358:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000635c:	6518                	ld	a4,8(a0)
    8000635e:	00275783          	lhu	a5,2(a4)
    80006362:	2785                	addiw	a5,a5,1
    80006364:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006368:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000636c:	100017b7          	lui	a5,0x10001
    80006370:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006374:	00492703          	lw	a4,4(s2)
    80006378:	4785                	li	a5,1
    8000637a:	02f71163          	bne	a4,a5,8000639c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000637e:	0001f997          	auipc	s3,0x1f
    80006382:	daa98993          	addi	s3,s3,-598 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006386:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006388:	85ce                	mv	a1,s3
    8000638a:	854a                	mv	a0,s2
    8000638c:	ffffc097          	auipc	ra,0xffffc
    80006390:	fae080e7          	jalr	-82(ra) # 8000233a <sleep>
  while(b->disk == 1) {
    80006394:	00492783          	lw	a5,4(s2)
    80006398:	fe9788e3          	beq	a5,s1,80006388 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000639c:	f9042903          	lw	s2,-112(s0)
    800063a0:	20090793          	addi	a5,s2,512
    800063a4:	00479713          	slli	a4,a5,0x4
    800063a8:	0001d797          	auipc	a5,0x1d
    800063ac:	c5878793          	addi	a5,a5,-936 # 80023000 <disk>
    800063b0:	97ba                	add	a5,a5,a4
    800063b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063b6:	0001f997          	auipc	s3,0x1f
    800063ba:	c4a98993          	addi	s3,s3,-950 # 80025000 <disk+0x2000>
    800063be:	00491713          	slli	a4,s2,0x4
    800063c2:	0009b783          	ld	a5,0(s3)
    800063c6:	97ba                	add	a5,a5,a4
    800063c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063cc:	854a                	mv	a0,s2
    800063ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063d2:	00000097          	auipc	ra,0x0
    800063d6:	bc4080e7          	jalr	-1084(ra) # 80005f96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063da:	8885                	andi	s1,s1,1
    800063dc:	f0ed                	bnez	s1,800063be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063de:	0001f517          	auipc	a0,0x1f
    800063e2:	d4a50513          	addi	a0,a0,-694 # 80025128 <disk+0x2128>
    800063e6:	ffffb097          	auipc	ra,0xffffb
    800063ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
}
    800063ee:	70a6                	ld	ra,104(sp)
    800063f0:	7406                	ld	s0,96(sp)
    800063f2:	64e6                	ld	s1,88(sp)
    800063f4:	6946                	ld	s2,80(sp)
    800063f6:	69a6                	ld	s3,72(sp)
    800063f8:	6a06                	ld	s4,64(sp)
    800063fa:	7ae2                	ld	s5,56(sp)
    800063fc:	7b42                	ld	s6,48(sp)
    800063fe:	7ba2                	ld	s7,40(sp)
    80006400:	7c02                	ld	s8,32(sp)
    80006402:	6ce2                	ld	s9,24(sp)
    80006404:	6d42                	ld	s10,16(sp)
    80006406:	6165                	addi	sp,sp,112
    80006408:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000640a:	0001f697          	auipc	a3,0x1f
    8000640e:	bf66b683          	ld	a3,-1034(a3) # 80025000 <disk+0x2000>
    80006412:	96ba                	add	a3,a3,a4
    80006414:	4609                	li	a2,2
    80006416:	00c69623          	sh	a2,12(a3)
    8000641a:	b5c9                	j	800062dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000641c:	f9042583          	lw	a1,-112(s0)
    80006420:	20058793          	addi	a5,a1,512
    80006424:	0792                	slli	a5,a5,0x4
    80006426:	0001d517          	auipc	a0,0x1d
    8000642a:	c8250513          	addi	a0,a0,-894 # 800230a8 <disk+0xa8>
    8000642e:	953e                	add	a0,a0,a5
  if(write)
    80006430:	e20d11e3          	bnez	s10,80006252 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006434:	20058713          	addi	a4,a1,512
    80006438:	00471693          	slli	a3,a4,0x4
    8000643c:	0001d717          	auipc	a4,0x1d
    80006440:	bc470713          	addi	a4,a4,-1084 # 80023000 <disk>
    80006444:	9736                	add	a4,a4,a3
    80006446:	0a072423          	sw	zero,168(a4)
    8000644a:	b505                	j	8000626a <virtio_disk_rw+0xf4>

000000008000644c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000644c:	1101                	addi	sp,sp,-32
    8000644e:	ec06                	sd	ra,24(sp)
    80006450:	e822                	sd	s0,16(sp)
    80006452:	e426                	sd	s1,8(sp)
    80006454:	e04a                	sd	s2,0(sp)
    80006456:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006458:	0001f517          	auipc	a0,0x1f
    8000645c:	cd050513          	addi	a0,a0,-816 # 80025128 <disk+0x2128>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006468:	10001737          	lui	a4,0x10001
    8000646c:	533c                	lw	a5,96(a4)
    8000646e:	8b8d                	andi	a5,a5,3
    80006470:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006472:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006476:	0001f797          	auipc	a5,0x1f
    8000647a:	b8a78793          	addi	a5,a5,-1142 # 80025000 <disk+0x2000>
    8000647e:	6b94                	ld	a3,16(a5)
    80006480:	0207d703          	lhu	a4,32(a5)
    80006484:	0026d783          	lhu	a5,2(a3)
    80006488:	06f70163          	beq	a4,a5,800064ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000648c:	0001d917          	auipc	s2,0x1d
    80006490:	b7490913          	addi	s2,s2,-1164 # 80023000 <disk>
    80006494:	0001f497          	auipc	s1,0x1f
    80006498:	b6c48493          	addi	s1,s1,-1172 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000649c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064a0:	6898                	ld	a4,16(s1)
    800064a2:	0204d783          	lhu	a5,32(s1)
    800064a6:	8b9d                	andi	a5,a5,7
    800064a8:	078e                	slli	a5,a5,0x3
    800064aa:	97ba                	add	a5,a5,a4
    800064ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064ae:	20078713          	addi	a4,a5,512
    800064b2:	0712                	slli	a4,a4,0x4
    800064b4:	974a                	add	a4,a4,s2
    800064b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064ba:	e731                	bnez	a4,80006506 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064bc:	20078793          	addi	a5,a5,512
    800064c0:	0792                	slli	a5,a5,0x4
    800064c2:	97ca                	add	a5,a5,s2
    800064c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064ca:	ffffc097          	auipc	ra,0xffffc
    800064ce:	042080e7          	jalr	66(ra) # 8000250c <wakeup>

    disk.used_idx += 1;
    800064d2:	0204d783          	lhu	a5,32(s1)
    800064d6:	2785                	addiw	a5,a5,1
    800064d8:	17c2                	slli	a5,a5,0x30
    800064da:	93c1                	srli	a5,a5,0x30
    800064dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064e0:	6898                	ld	a4,16(s1)
    800064e2:	00275703          	lhu	a4,2(a4)
    800064e6:	faf71be3          	bne	a4,a5,8000649c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ea:	0001f517          	auipc	a0,0x1f
    800064ee:	c3e50513          	addi	a0,a0,-962 # 80025128 <disk+0x2128>
    800064f2:	ffffa097          	auipc	ra,0xffffa
    800064f6:	7a6080e7          	jalr	1958(ra) # 80000c98 <release>
}
    800064fa:	60e2                	ld	ra,24(sp)
    800064fc:	6442                	ld	s0,16(sp)
    800064fe:	64a2                	ld	s1,8(sp)
    80006500:	6902                	ld	s2,0(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret
      panic("virtio_disk_intr status");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	3a250513          	addi	a0,a0,930 # 800088a8 <syscalls+0x3c8>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
