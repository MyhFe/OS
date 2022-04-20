
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	dec78793          	addi	a5,a5,-532 # 80005e50 <timervec>
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
    80000130:	60e080e7          	jalr	1550(ra) # 8000273a <either_copyin>
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
    800001c8:	aac080e7          	jalr	-1364(ra) # 80001c70 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	11c080e7          	jalr	284(ra) # 800022f0 <sleep>
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
    80000214:	4d4080e7          	jalr	1236(ra) # 800026e4 <either_copyout>
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
    800002f6:	49e080e7          	jalr	1182(ra) # 80002790 <procdump>
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
    8000044a:	046080e7          	jalr	70(ra) # 8000248c <wakeup>
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
    800008a4:	bec080e7          	jalr	-1044(ra) # 8000248c <wakeup>
    
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
    80000930:	9c4080e7          	jalr	-1596(ra) # 800022f0 <sleep>
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
    80000b82:	0d6080e7          	jalr	214(ra) # 80001c54 <mycpu>
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
    80000bb4:	0a4080e7          	jalr	164(ra) # 80001c54 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	098080e7          	jalr	152(ra) # 80001c54 <mycpu>
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
    80000bd8:	080080e7          	jalr	128(ra) # 80001c54 <mycpu>
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
    80000c18:	040080e7          	jalr	64(ra) # 80001c54 <mycpu>
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
    80000c44:	014080e7          	jalr	20(ra) # 80001c54 <mycpu>
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
    80000e9a:	dae080e7          	jalr	-594(ra) # 80001c44 <cpuid>
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
    80000eb6:	d92080e7          	jalr	-622(ra) # 80001c44 <cpuid>
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
    80000ed8:	9fc080e7          	jalr	-1540(ra) # 800028d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	fb4080e7          	jalr	-76(ra) # 80005e90 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	b6c080e7          	jalr	-1172(ra) # 80001a50 <scheduler>
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
    80000f48:	c40080e7          	jalr	-960(ra) # 80001b84 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	95c080e7          	jalr	-1700(ra) # 800028a8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	97c080e7          	jalr	-1668(ra) # 800028d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f1e080e7          	jalr	-226(ra) # 80005e7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f2c080e7          	jalr	-212(ra) # 80005e90 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	108080e7          	jalr	264(ra) # 80003074 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	798080e7          	jalr	1944(ra) # 8000370c <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	742080e7          	jalr	1858(ra) # 800046be <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	02e080e7          	jalr	46(ra) # 80005fb2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	fd0080e7          	jalr	-48(ra) # 80001f5c <userinit>
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
        p->state = RUNNABLE;
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
    80001944:	b7cd                	j	80001926 <kill+0x52>

0000000080001946 <kill_sys>:


int
kill_sys(void)
{
    80001946:	7139                	addi	sp,sp,-64
    80001948:	fc06                	sd	ra,56(sp)
    8000194a:	f822                	sd	s0,48(sp)
    8000194c:	f426                	sd	s1,40(sp)
    8000194e:	f04a                	sd	s2,32(sp)
    80001950:	ec4e                	sd	s3,24(sp)
    80001952:	e852                	sd	s4,16(sp)
    80001954:	e456                	sd	s5,8(sp)
    80001956:	e05a                	sd	s6,0(sp)
    80001958:	0080                	addi	s0,sp,64
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000195a:	00010497          	auipc	s1,0x10
    8000195e:	d9648493          	addi	s1,s1,-618 # 800116f0 <proc>
    acquire(&p->lock);
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    80001962:	8926                	mv	s2,s1
      p->killed = 1;
    80001964:	4a85                	li	s5,1
      if(p->state == SLEEPING){
    80001966:	4a09                	li	s4,2
        // Wake process from sleep().
        p->state = RUNNABLE;
    80001968:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++){
    8000196a:	00016997          	auipc	s3,0x16
    8000196e:	d8698993          	addi	s3,s3,-634 # 800176f0 <tickslock>
    80001972:	a811                	j	80001986 <kill_sys+0x40>
      }
      //release(&p->lock);
    }
    release(&p->lock);
    80001974:	8526                	mv	a0,s1
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	322080e7          	jalr	802(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000197e:	18048493          	addi	s1,s1,384
    80001982:	03348863          	beq	s1,s3,800019b2 <kill_sys+0x6c>
    acquire(&p->lock);
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    80001990:	589c                	lw	a5,48(s1)
    80001992:	03092703          	lw	a4,48(s2) # 4000030 <_entry-0x7bffffd0>
    80001996:	fcf70fe3          	beq	a4,a5,80001974 <kill_sys+0x2e>
    8000199a:	1b092703          	lw	a4,432(s2)
    8000199e:	fcf70be3          	beq	a4,a5,80001974 <kill_sys+0x2e>
      p->killed = 1;
    800019a2:	0354a423          	sw	s5,40(s1)
      if(p->state == SLEEPING){
    800019a6:	4c9c                	lw	a5,24(s1)
    800019a8:	fd4796e3          	bne	a5,s4,80001974 <kill_sys+0x2e>
        p->state = RUNNABLE;
    800019ac:	0164ac23          	sw	s6,24(s1)
    800019b0:	b7d1                	j	80001974 <kill_sys+0x2e>
  }
  return 0;
}
    800019b2:	4501                	li	a0,0
    800019b4:	70e2                	ld	ra,56(sp)
    800019b6:	7442                	ld	s0,48(sp)
    800019b8:	74a2                	ld	s1,40(sp)
    800019ba:	7902                	ld	s2,32(sp)
    800019bc:	69e2                	ld	s3,24(sp)
    800019be:	6a42                	ld	s4,16(sp)
    800019c0:	6aa2                	ld	s5,8(sp)
    800019c2:	6b02                	ld	s6,0(sp)
    800019c4:	6121                	addi	sp,sp,64
    800019c6:	8082                	ret

00000000800019c8 <print_stats>:
  yield();
  return 0;
}

void
print_stats(void){
    800019c8:	1141                	addi	sp,sp,-16
    800019ca:	e406                	sd	ra,8(sp)
    800019cc:	e022                	sd	s0,0(sp)
    800019ce:	0800                	addi	s0,sp,16
  printf("cpu_utilization: %d\n", cpu_utilization);
    800019d0:	00007597          	auipc	a1,0x7
    800019d4:	6585a583          	lw	a1,1624(a1) # 80009028 <cpu_utilization>
    800019d8:	00007517          	auipc	a0,0x7
    800019dc:	80850513          	addi	a0,a0,-2040 # 800081e0 <digits+0x1a0>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	ba8080e7          	jalr	-1112(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    800019e8:	00007597          	auipc	a1,0x7
    800019ec:	6445a583          	lw	a1,1604(a1) # 8000902c <program_time>
    800019f0:	00007517          	auipc	a0,0x7
    800019f4:	80850513          	addi	a0,a0,-2040 # 800081f8 <digits+0x1b8>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	b90080e7          	jalr	-1136(ra) # 80000588 <printf>
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    80001a00:	00007597          	auipc	a1,0x7
    80001a04:	6405a583          	lw	a1,1600(a1) # 80009040 <sleeping_processes_mean>
    80001a08:	00007517          	auipc	a0,0x7
    80001a0c:	80850513          	addi	a0,a0,-2040 # 80008210 <digits+0x1d0>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	b78080e7          	jalr	-1160(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    80001a18:	00007597          	auipc	a1,0x7
    80001a1c:	6245a583          	lw	a1,1572(a1) # 8000903c <running_processes_mean>
    80001a20:	00007517          	auipc	a0,0x7
    80001a24:	81050513          	addi	a0,a0,-2032 # 80008230 <digits+0x1f0>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	b60080e7          	jalr	-1184(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    80001a30:	00007597          	auipc	a1,0x7
    80001a34:	6085a583          	lw	a1,1544(a1) # 80009038 <runnable_processes_mean>
    80001a38:	00007517          	auipc	a0,0x7
    80001a3c:	81850513          	addi	a0,a0,-2024 # 80008250 <digits+0x210>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
}
    80001a48:	60a2                	ld	ra,8(sp)
    80001a4a:	6402                	ld	s0,0(sp)
    80001a4c:	0141                	addi	sp,sp,16
    80001a4e:	8082                	ret

0000000080001a50 <scheduler>:
//    via swtch back to the scheduler.

#ifdef DEFAULT
void
scheduler(void)
{
    80001a50:	711d                	addi	sp,sp,-96
    80001a52:	ec86                	sd	ra,88(sp)
    80001a54:	e8a2                	sd	s0,80(sp)
    80001a56:	e4a6                	sd	s1,72(sp)
    80001a58:	e0ca                	sd	s2,64(sp)
    80001a5a:	fc4e                	sd	s3,56(sp)
    80001a5c:	f852                	sd	s4,48(sp)
    80001a5e:	f456                	sd	s5,40(sp)
    80001a60:	f05a                	sd	s6,32(sp)
    80001a62:	ec5e                	sd	s7,24(sp)
    80001a64:	e862                	sd	s8,16(sp)
    80001a66:	e466                	sd	s9,8(sp)
    80001a68:	e06a                	sd	s10,0(sp)
    80001a6a:	1080                	addi	s0,sp,96
  printf("DEFAULT\n");
    80001a6c:	00007517          	auipc	a0,0x7
    80001a70:	80450513          	addi	a0,a0,-2044 # 80008270 <digits+0x230>
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	b14080e7          	jalr	-1260(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a7c:	8792                	mv	a5,tp
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
    80001a7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001a80:	00010c17          	auipc	s8,0x10
    80001a84:	840c0c13          	addi	s8,s8,-1984 # 800112c0 <cpus>
    80001a88:	00779713          	slli	a4,a5,0x7
    80001a8c:	00ec06b3          	add	a3,s8,a4
    80001a90:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
          swtch(&c->context, &p->context);
    80001a94:	0721                	addi	a4,a4,8
    80001a96:	9c3a                	add	s8,s8,a4
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a98:	00010917          	auipc	s2,0x10
    80001a9c:	c5890913          	addi	s2,s2,-936 # 800116f0 <proc>
          int before_switch = ticks;
    80001aa0:	00007a17          	auipc	s4,0x7
    80001aa4:	5b0a0a13          	addi	s4,s4,1456 # 80009050 <ticks>
          c->proc = p;
    80001aa8:	8bb6                	mv	s7,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001aaa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001aae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ab2:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ab6:	00010497          	auipc	s1,0x10
    80001aba:	c3a48493          	addi	s1,s1,-966 # 800116f0 <proc>
        if(p->state == RUNNABLE) {
    80001abe:	4b0d                	li	s6,3
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001ac0:	00007a97          	auipc	s5,0x7
    80001ac4:	584a8a93          	addi	s5,s5,1412 # 80009044 <finish>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ac8:	00016997          	auipc	s3,0x16
    80001acc:	c2898993          	addi	s3,s3,-984 # 800176f0 <tickslock>
    80001ad0:	a01d                	j	80001af6 <scheduler+0xa6>
        acquire(&p->lock);
    80001ad2:	8ca6                	mv	s9,s1
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	10e080e7          	jalr	270(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001ade:	4c9c                	lw	a5,24(s1)
    80001ae0:	05678163          	beq	a5,s6,80001b22 <scheduler+0xd2>
        release(&p->lock);
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	1b2080e7          	jalr	434(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001aee:	18048493          	addi	s1,s1,384
    80001af2:	fb348ce3          	beq	s1,s3,80001aaa <scheduler+0x5a>
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001af6:	5894                	lw	a3,48(s1)
    80001af8:	03092783          	lw	a5,48(s2)
    80001afc:	8f95                	sub	a5,a5,a3
    80001afe:	0017b793          	seqz	a5,a5
    80001b02:	1b092703          	lw	a4,432(s2)
    80001b06:	8f15                	sub	a4,a4,a3
    80001b08:	00173713          	seqz	a4,a4
    80001b0c:	8fd9                	or	a5,a5,a4
    80001b0e:	0ff7f793          	andi	a5,a5,255
    80001b12:	f3e1                	bnez	a5,80001ad2 <scheduler+0x82>
    80001b14:	000aa703          	lw	a4,0(s5)
    80001b18:	000a2783          	lw	a5,0(s4)
    80001b1c:	fcf779e3          	bgeu	a4,a5,80001aee <scheduler+0x9e>
    80001b20:	bf4d                	j	80001ad2 <scheduler+0x82>
          p->state = RUNNING;
    80001b22:	4791                	li	a5,4
    80001b24:	cc9c                	sw	a5,24(s1)
          int before_switch = ticks;
    80001b26:	000a2d03          	lw	s10,0(s4)
          c->proc = p;
    80001b2a:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b2e:	589c                	lw	a5,48(s1)
    80001b30:	03092703          	lw	a4,48(s2)
    80001b34:	00f70c63          	beq	a4,a5,80001b4c <scheduler+0xfc>
    80001b38:	1b092703          	lw	a4,432(s2)
    80001b3c:	00f70863          	beq	a4,a5,80001b4c <scheduler+0xfc>
            p->running_time = p->runnable_time + ticks - p->last_runnable_time;
    80001b40:	40fc                	lw	a5,68(s1)
    80001b42:	01a787bb          	addw	a5,a5,s10
    80001b46:	5cd8                	lw	a4,60(s1)
    80001b48:	9f99                	subw	a5,a5,a4
    80001b4a:	c4bc                	sw	a5,72(s1)
          swtch(&c->context, &p->context);
    80001b4c:	078c8593          	addi	a1,s9,120
    80001b50:	8562                	mv	a0,s8
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	cec080e7          	jalr	-788(ra) # 8000283e <swtch>
          if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b5a:	589c                	lw	a5,48(s1)
    80001b5c:	03092703          	lw	a4,48(s2)
    80001b60:	00f70f63          	beq	a4,a5,80001b7e <scheduler+0x12e>
    80001b64:	1b092703          	lw	a4,432(s2)
    80001b68:	00f70b63          	beq	a4,a5,80001b7e <scheduler+0x12e>
            p->runnable_time = p->running_time + ticks - before_switch;
    80001b6c:	000a2783          	lw	a5,0(s4)
    80001b70:	41a78d3b          	subw	s10,a5,s10
    80001b74:	44bc                	lw	a5,72(s1)
    80001b76:	00fd0d3b          	addw	s10,s10,a5
    80001b7a:	05a4a223          	sw	s10,68(s1)
          c->proc = 0;
    80001b7e:	000bb023          	sd	zero,0(s7)
    80001b82:	b78d                	j	80001ae4 <scheduler+0x94>

0000000080001b84 <procinit>:
{
    80001b84:	7139                	addi	sp,sp,-64
    80001b86:	fc06                	sd	ra,56(sp)
    80001b88:	f822                	sd	s0,48(sp)
    80001b8a:	f426                	sd	s1,40(sp)
    80001b8c:	f04a                	sd	s2,32(sp)
    80001b8e:	ec4e                	sd	s3,24(sp)
    80001b90:	e852                	sd	s4,16(sp)
    80001b92:	e456                	sd	s5,8(sp)
    80001b94:	e05a                	sd	s6,0(sp)
    80001b96:	0080                	addi	s0,sp,64
  start_time = ticks;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	4b87a783          	lw	a5,1208(a5) # 80009050 <ticks>
    80001ba0:	00007717          	auipc	a4,0x7
    80001ba4:	48f72823          	sw	a5,1168(a4) # 80009030 <start_time>
  initlock(&pid_lock, "nextpid");
    80001ba8:	00006597          	auipc	a1,0x6
    80001bac:	6d858593          	addi	a1,a1,1752 # 80008280 <digits+0x240>
    80001bb0:	00010517          	auipc	a0,0x10
    80001bb4:	b1050513          	addi	a0,a0,-1264 # 800116c0 <pid_lock>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	f9c080e7          	jalr	-100(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bc0:	00006597          	auipc	a1,0x6
    80001bc4:	6c858593          	addi	a1,a1,1736 # 80008288 <digits+0x248>
    80001bc8:	00010517          	auipc	a0,0x10
    80001bcc:	b1050513          	addi	a0,a0,-1264 # 800116d8 <wait_lock>
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	f84080e7          	jalr	-124(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd8:	00010497          	auipc	s1,0x10
    80001bdc:	b1848493          	addi	s1,s1,-1256 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001be0:	00006b17          	auipc	s6,0x6
    80001be4:	6b8b0b13          	addi	s6,s6,1720 # 80008298 <digits+0x258>
      p->kstack = KSTACK((int) (p - proc));
    80001be8:	8aa6                	mv	s5,s1
    80001bea:	00006a17          	auipc	s4,0x6
    80001bee:	416a0a13          	addi	s4,s4,1046 # 80008000 <etext>
    80001bf2:	04000937          	lui	s2,0x4000
    80001bf6:	197d                	addi	s2,s2,-1
    80001bf8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	00016997          	auipc	s3,0x16
    80001bfe:	af698993          	addi	s3,s3,-1290 # 800176f0 <tickslock>
      initlock(&p->lock, "proc");
    80001c02:	85da                	mv	a1,s6
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	f4e080e7          	jalr	-178(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c0e:	415487b3          	sub	a5,s1,s5
    80001c12:	879d                	srai	a5,a5,0x7
    80001c14:	000a3703          	ld	a4,0(s4)
    80001c18:	02e787b3          	mul	a5,a5,a4
    80001c1c:	2785                	addiw	a5,a5,1
    80001c1e:	00d7979b          	slliw	a5,a5,0xd
    80001c22:	40f907b3          	sub	a5,s2,a5
    80001c26:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c28:	18048493          	addi	s1,s1,384
    80001c2c:	fd349be3          	bne	s1,s3,80001c02 <procinit+0x7e>
}
    80001c30:	70e2                	ld	ra,56(sp)
    80001c32:	7442                	ld	s0,48(sp)
    80001c34:	74a2                	ld	s1,40(sp)
    80001c36:	7902                	ld	s2,32(sp)
    80001c38:	69e2                	ld	s3,24(sp)
    80001c3a:	6a42                	ld	s4,16(sp)
    80001c3c:	6aa2                	ld	s5,8(sp)
    80001c3e:	6b02                	ld	s6,0(sp)
    80001c40:	6121                	addi	sp,sp,64
    80001c42:	8082                	ret

0000000080001c44 <cpuid>:
{
    80001c44:	1141                	addi	sp,sp,-16
    80001c46:	e422                	sd	s0,8(sp)
    80001c48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c4a:	8512                	mv	a0,tp
  return id;
}
    80001c4c:	2501                	sext.w	a0,a0
    80001c4e:	6422                	ld	s0,8(sp)
    80001c50:	0141                	addi	sp,sp,16
    80001c52:	8082                	ret

0000000080001c54 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c54:	1141                	addi	sp,sp,-16
    80001c56:	e422                	sd	s0,8(sp)
    80001c58:	0800                	addi	s0,sp,16
    80001c5a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c5c:	2781                	sext.w	a5,a5
    80001c5e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c60:	0000f517          	auipc	a0,0xf
    80001c64:	66050513          	addi	a0,a0,1632 # 800112c0 <cpus>
    80001c68:	953e                	add	a0,a0,a5
    80001c6a:	6422                	ld	s0,8(sp)
    80001c6c:	0141                	addi	sp,sp,16
    80001c6e:	8082                	ret

0000000080001c70 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	addi	s0,sp,32
  push_off();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	f1e080e7          	jalr	-226(ra) # 80000b98 <push_off>
    80001c82:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c84:	2781                	sext.w	a5,a5
    80001c86:	079e                	slli	a5,a5,0x7
    80001c88:	0000f717          	auipc	a4,0xf
    80001c8c:	63870713          	addi	a4,a4,1592 # 800112c0 <cpus>
    80001c90:	97ba                	add	a5,a5,a4
    80001c92:	6384                	ld	s1,0(a5)
  pop_off();
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	fa4080e7          	jalr	-92(ra) # 80000c38 <pop_off>
  return p;
}
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6105                	addi	sp,sp,32
    80001ca6:	8082                	ret

0000000080001ca8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ca8:	1141                	addi	sp,sp,-16
    80001caa:	e406                	sd	ra,8(sp)
    80001cac:	e022                	sd	s0,0(sp)
    80001cae:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	fc0080e7          	jalr	-64(ra) # 80001c70 <myproc>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fe0080e7          	jalr	-32(ra) # 80000c98 <release>

  if (first) {
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	c107a783          	lw	a5,-1008(a5) # 800088d0 <first.1714>
    80001cc8:	eb89                	bnez	a5,80001cda <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cca:	00001097          	auipc	ra,0x1
    80001cce:	c1e080e7          	jalr	-994(ra) # 800028e8 <usertrapret>
}
    80001cd2:	60a2                	ld	ra,8(sp)
    80001cd4:	6402                	ld	s0,0(sp)
    80001cd6:	0141                	addi	sp,sp,16
    80001cd8:	8082                	ret
    first = 0;
    80001cda:	00007797          	auipc	a5,0x7
    80001cde:	be07ab23          	sw	zero,-1034(a5) # 800088d0 <first.1714>
    fsinit(ROOTDEV);
    80001ce2:	4505                	li	a0,1
    80001ce4:	00002097          	auipc	ra,0x2
    80001ce8:	9a8080e7          	jalr	-1624(ra) # 8000368c <fsinit>
    80001cec:	bff9                	j	80001cca <forkret+0x22>

0000000080001cee <allocpid>:
allocpid() {
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	e04a                	sd	s2,0(sp)
    80001cf8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cfa:	00010917          	auipc	s2,0x10
    80001cfe:	9c690913          	addi	s2,s2,-1594 # 800116c0 <pid_lock>
    80001d02:	854a                	mv	a0,s2
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	ee0080e7          	jalr	-288(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001d0c:	00007797          	auipc	a5,0x7
    80001d10:	bc878793          	addi	a5,a5,-1080 # 800088d4 <nextpid>
    80001d14:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d16:	0014871b          	addiw	a4,s1,1
    80001d1a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d1c:	854a                	mv	a0,s2
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>
}
    80001d26:	8526                	mv	a0,s1
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6902                	ld	s2,0(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <proc_pagetable>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	5f8080e7          	jalr	1528(ra) # 8000133a <uvmcreate>
    80001d4a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d4c:	c121                	beqz	a0,80001d8c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d4e:	4729                	li	a4,10
    80001d50:	00005697          	auipc	a3,0x5
    80001d54:	2b068693          	addi	a3,a3,688 # 80007000 <_trampoline>
    80001d58:	6605                	lui	a2,0x1
    80001d5a:	040005b7          	lui	a1,0x4000
    80001d5e:	15fd                	addi	a1,a1,-1
    80001d60:	05b2                	slli	a1,a1,0xc
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	34e080e7          	jalr	846(ra) # 800010b0 <mappages>
    80001d6a:	02054863          	bltz	a0,80001d9a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d6e:	4719                	li	a4,6
    80001d70:	07093683          	ld	a3,112(s2)
    80001d74:	6605                	lui	a2,0x1
    80001d76:	020005b7          	lui	a1,0x2000
    80001d7a:	15fd                	addi	a1,a1,-1
    80001d7c:	05b6                	slli	a1,a1,0xd
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	330080e7          	jalr	816(ra) # 800010b0 <mappages>
    80001d88:	02054163          	bltz	a0,80001daa <proc_pagetable+0x76>
}
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	60e2                	ld	ra,24(sp)
    80001d90:	6442                	ld	s0,16(sp)
    80001d92:	64a2                	ld	s1,8(sp)
    80001d94:	6902                	ld	s2,0(sp)
    80001d96:	6105                	addi	sp,sp,32
    80001d98:	8082                	ret
    uvmfree(pagetable, 0);
    80001d9a:	4581                	li	a1,0
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	798080e7          	jalr	1944(ra) # 80001536 <uvmfree>
    return 0;
    80001da6:	4481                	li	s1,0
    80001da8:	b7d5                	j	80001d8c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001daa:	4681                	li	a3,0
    80001dac:	4605                	li	a2,1
    80001dae:	040005b7          	lui	a1,0x4000
    80001db2:	15fd                	addi	a1,a1,-1
    80001db4:	05b2                	slli	a1,a1,0xc
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	4be080e7          	jalr	1214(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dc0:	4581                	li	a1,0
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	772080e7          	jalr	1906(ra) # 80001536 <uvmfree>
    return 0;
    80001dcc:	4481                	li	s1,0
    80001dce:	bf7d                	j	80001d8c <proc_pagetable+0x58>

0000000080001dd0 <proc_freepagetable>:
{
    80001dd0:	1101                	addi	sp,sp,-32
    80001dd2:	ec06                	sd	ra,24(sp)
    80001dd4:	e822                	sd	s0,16(sp)
    80001dd6:	e426                	sd	s1,8(sp)
    80001dd8:	e04a                	sd	s2,0(sp)
    80001dda:	1000                	addi	s0,sp,32
    80001ddc:	84aa                	mv	s1,a0
    80001dde:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001de0:	4681                	li	a3,0
    80001de2:	4605                	li	a2,1
    80001de4:	040005b7          	lui	a1,0x4000
    80001de8:	15fd                	addi	a1,a1,-1
    80001dea:	05b2                	slli	a1,a1,0xc
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	48a080e7          	jalr	1162(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001df4:	4681                	li	a3,0
    80001df6:	4605                	li	a2,1
    80001df8:	020005b7          	lui	a1,0x2000
    80001dfc:	15fd                	addi	a1,a1,-1
    80001dfe:	05b6                	slli	a1,a1,0xd
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	474080e7          	jalr	1140(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e0a:	85ca                	mv	a1,s2
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	728080e7          	jalr	1832(ra) # 80001536 <uvmfree>
}
    80001e16:	60e2                	ld	ra,24(sp)
    80001e18:	6442                	ld	s0,16(sp)
    80001e1a:	64a2                	ld	s1,8(sp)
    80001e1c:	6902                	ld	s2,0(sp)
    80001e1e:	6105                	addi	sp,sp,32
    80001e20:	8082                	ret

0000000080001e22 <freeproc>:
{
    80001e22:	1101                	addi	sp,sp,-32
    80001e24:	ec06                	sd	ra,24(sp)
    80001e26:	e822                	sd	s0,16(sp)
    80001e28:	e426                	sd	s1,8(sp)
    80001e2a:	1000                	addi	s0,sp,32
    80001e2c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e2e:	7928                	ld	a0,112(a0)
    80001e30:	c509                	beqz	a0,80001e3a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	bc6080e7          	jalr	-1082(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e3a:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001e3e:	74a8                	ld	a0,104(s1)
    80001e40:	c511                	beqz	a0,80001e4c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e42:	70ac                	ld	a1,96(s1)
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	f8c080e7          	jalr	-116(ra) # 80001dd0 <proc_freepagetable>
  p->pagetable = 0;
    80001e4c:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001e50:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001e54:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e58:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001e5c:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001e60:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e64:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e68:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e6c:	0004ac23          	sw	zero,24(s1)
}
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <allocproc>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	e04a                	sd	s2,0(sp)
    80001e84:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e86:	00010497          	auipc	s1,0x10
    80001e8a:	86a48493          	addi	s1,s1,-1942 # 800116f0 <proc>
    80001e8e:	00016917          	auipc	s2,0x16
    80001e92:	86290913          	addi	s2,s2,-1950 # 800176f0 <tickslock>
    acquire(&p->lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	d4c080e7          	jalr	-692(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001ea0:	4c9c                	lw	a5,24(s1)
    80001ea2:	cf81                	beqz	a5,80001eba <allocproc+0x40>
      release(&p->lock);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	df2080e7          	jalr	-526(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eae:	18048493          	addi	s1,s1,384
    80001eb2:	ff2492e3          	bne	s1,s2,80001e96 <allocproc+0x1c>
  return 0;
    80001eb6:	4481                	li	s1,0
    80001eb8:	a09d                	j	80001f1e <allocproc+0xa4>
  p->pid = allocpid();
    80001eba:	00000097          	auipc	ra,0x0
    80001ebe:	e34080e7          	jalr	-460(ra) # 80001cee <allocpid>
    80001ec2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ec4:	4785                	li	a5,1
    80001ec6:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001ec8:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001ecc:	0204ac23          	sw	zero,56(s1)
  p->sleeping_time = 0;
    80001ed0:	0404a023          	sw	zero,64(s1)
  p->runnable_time = 0;
    80001ed4:	0404a223          	sw	zero,68(s1)
  p->running_time = 0;
    80001ed8:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	c18080e7          	jalr	-1000(ra) # 80000af4 <kalloc>
    80001ee4:	892a                	mv	s2,a0
    80001ee6:	f8a8                	sd	a0,112(s1)
    80001ee8:	c131                	beqz	a0,80001f2c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001eea:	8526                	mv	a0,s1
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	e48080e7          	jalr	-440(ra) # 80001d34 <proc_pagetable>
    80001ef4:	892a                	mv	s2,a0
    80001ef6:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001ef8:	c531                	beqz	a0,80001f44 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001efa:	07000613          	li	a2,112
    80001efe:	4581                	li	a1,0
    80001f00:	07848513          	addi	a0,s1,120
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	ddc080e7          	jalr	-548(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f0c:	00000797          	auipc	a5,0x0
    80001f10:	d9c78793          	addi	a5,a5,-612 # 80001ca8 <forkret>
    80001f14:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f16:	6cbc                	ld	a5,88(s1)
    80001f18:	6705                	lui	a4,0x1
    80001f1a:	97ba                	add	a5,a5,a4
    80001f1c:	e0dc                	sd	a5,128(s1)
}
    80001f1e:	8526                	mv	a0,s1
    80001f20:	60e2                	ld	ra,24(sp)
    80001f22:	6442                	ld	s0,16(sp)
    80001f24:	64a2                	ld	s1,8(sp)
    80001f26:	6902                	ld	s2,0(sp)
    80001f28:	6105                	addi	sp,sp,32
    80001f2a:	8082                	ret
    freeproc(p);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	ef4080e7          	jalr	-268(ra) # 80001e22 <freeproc>
    release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	d60080e7          	jalr	-672(ra) # 80000c98 <release>
    return 0;
    80001f40:	84ca                	mv	s1,s2
    80001f42:	bff1                	j	80001f1e <allocproc+0xa4>
    freeproc(p);
    80001f44:	8526                	mv	a0,s1
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	edc080e7          	jalr	-292(ra) # 80001e22 <freeproc>
    release(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	d48080e7          	jalr	-696(ra) # 80000c98 <release>
    return 0;
    80001f58:	84ca                	mv	s1,s2
    80001f5a:	b7d1                	j	80001f1e <allocproc+0xa4>

0000000080001f5c <userinit>:
{
    80001f5c:	1101                	addi	sp,sp,-32
    80001f5e:	ec06                	sd	ra,24(sp)
    80001f60:	e822                	sd	s0,16(sp)
    80001f62:	e426                	sd	s1,8(sp)
    80001f64:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	f14080e7          	jalr	-236(ra) # 80001e7a <allocproc>
    80001f6e:	84aa                	mv	s1,a0
  initproc = p;
    80001f70:	00007797          	auipc	a5,0x7
    80001f74:	0ca7bc23          	sd	a0,216(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f78:	03400613          	li	a2,52
    80001f7c:	00007597          	auipc	a1,0x7
    80001f80:	96458593          	addi	a1,a1,-1692 # 800088e0 <initcode>
    80001f84:	7528                	ld	a0,104(a0)
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	3e2080e7          	jalr	994(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001f8e:	6785                	lui	a5,0x1
    80001f90:	f0bc                	sd	a5,96(s1)
  p->last_runnable_time = ticks;
    80001f92:	00007717          	auipc	a4,0x7
    80001f96:	0be72703          	lw	a4,190(a4) # 80009050 <ticks>
    80001f9a:	dcd8                	sw	a4,60(s1)
  sleeping_processes_mean = 0;
    80001f9c:	00007717          	auipc	a4,0x7
    80001fa0:	0a072223          	sw	zero,164(a4) # 80009040 <sleeping_processes_mean>
  running_processes_mean = 0;
    80001fa4:	00007717          	auipc	a4,0x7
    80001fa8:	08072c23          	sw	zero,152(a4) # 8000903c <running_processes_mean>
  runnable_processes_mean = 0;
    80001fac:	00007717          	auipc	a4,0x7
    80001fb0:	08072623          	sw	zero,140(a4) # 80009038 <runnable_processes_mean>
  p->trapframe->epc = 0;      // user program counter
    80001fb4:	78b8                	ld	a4,112(s1)
    80001fb6:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fba:	78b8                	ld	a4,112(s1)
    80001fbc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fbe:	4641                	li	a2,16
    80001fc0:	00006597          	auipc	a1,0x6
    80001fc4:	2e058593          	addi	a1,a1,736 # 800082a0 <digits+0x260>
    80001fc8:	17048513          	addi	a0,s1,368
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	e66080e7          	jalr	-410(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001fd4:	00006517          	auipc	a0,0x6
    80001fd8:	2dc50513          	addi	a0,a0,732 # 800082b0 <digits+0x270>
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	0de080e7          	jalr	222(ra) # 800040ba <namei>
    80001fe4:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001fe8:	478d                	li	a5,3
    80001fea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fec:	8526                	mv	a0,s1
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
}
    80001ff6:	60e2                	ld	ra,24(sp)
    80001ff8:	6442                	ld	s0,16(sp)
    80001ffa:	64a2                	ld	s1,8(sp)
    80001ffc:	6105                	addi	sp,sp,32
    80001ffe:	8082                	ret

0000000080002000 <growproc>:
{
    80002000:	1101                	addi	sp,sp,-32
    80002002:	ec06                	sd	ra,24(sp)
    80002004:	e822                	sd	s0,16(sp)
    80002006:	e426                	sd	s1,8(sp)
    80002008:	e04a                	sd	s2,0(sp)
    8000200a:	1000                	addi	s0,sp,32
    8000200c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	c62080e7          	jalr	-926(ra) # 80001c70 <myproc>
    80002016:	892a                	mv	s2,a0
  sz = p->sz;
    80002018:	712c                	ld	a1,96(a0)
    8000201a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000201e:	00904f63          	bgtz	s1,8000203c <growproc+0x3c>
  } else if(n < 0){
    80002022:	0204cc63          	bltz	s1,8000205a <growproc+0x5a>
  p->sz = sz;
    80002026:	1602                	slli	a2,a2,0x20
    80002028:	9201                	srli	a2,a2,0x20
    8000202a:	06c93023          	sd	a2,96(s2)
  return 0;
    8000202e:	4501                	li	a0,0
}
    80002030:	60e2                	ld	ra,24(sp)
    80002032:	6442                	ld	s0,16(sp)
    80002034:	64a2                	ld	s1,8(sp)
    80002036:	6902                	ld	s2,0(sp)
    80002038:	6105                	addi	sp,sp,32
    8000203a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000203c:	9e25                	addw	a2,a2,s1
    8000203e:	1602                	slli	a2,a2,0x20
    80002040:	9201                	srli	a2,a2,0x20
    80002042:	1582                	slli	a1,a1,0x20
    80002044:	9181                	srli	a1,a1,0x20
    80002046:	7528                	ld	a0,104(a0)
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	3da080e7          	jalr	986(ra) # 80001422 <uvmalloc>
    80002050:	0005061b          	sext.w	a2,a0
    80002054:	fa69                	bnez	a2,80002026 <growproc+0x26>
      return -1;
    80002056:	557d                	li	a0,-1
    80002058:	bfe1                	j	80002030 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000205a:	9e25                	addw	a2,a2,s1
    8000205c:	1602                	slli	a2,a2,0x20
    8000205e:	9201                	srli	a2,a2,0x20
    80002060:	1582                	slli	a1,a1,0x20
    80002062:	9181                	srli	a1,a1,0x20
    80002064:	7528                	ld	a0,104(a0)
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	374080e7          	jalr	884(ra) # 800013da <uvmdealloc>
    8000206e:	0005061b          	sext.w	a2,a0
    80002072:	bf55                	j	80002026 <growproc+0x26>

0000000080002074 <fork>:
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	e052                	sd	s4,0(sp)
    80002082:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	bec080e7          	jalr	-1044(ra) # 80001c70 <myproc>
    8000208c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	dec080e7          	jalr	-532(ra) # 80001e7a <allocproc>
    80002096:	10050b63          	beqz	a0,800021ac <fork+0x138>
    8000209a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000209c:	06093603          	ld	a2,96(s2)
    800020a0:	752c                	ld	a1,104(a0)
    800020a2:	06893503          	ld	a0,104(s2)
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	4c8080e7          	jalr	1224(ra) # 8000156e <uvmcopy>
    800020ae:	04054663          	bltz	a0,800020fa <fork+0x86>
  np->sz = p->sz;
    800020b2:	06093783          	ld	a5,96(s2)
    800020b6:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    800020ba:	07093683          	ld	a3,112(s2)
    800020be:	87b6                	mv	a5,a3
    800020c0:	0709b703          	ld	a4,112(s3)
    800020c4:	12068693          	addi	a3,a3,288
    800020c8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020cc:	6788                	ld	a0,8(a5)
    800020ce:	6b8c                	ld	a1,16(a5)
    800020d0:	6f90                	ld	a2,24(a5)
    800020d2:	01073023          	sd	a6,0(a4)
    800020d6:	e708                	sd	a0,8(a4)
    800020d8:	eb0c                	sd	a1,16(a4)
    800020da:	ef10                	sd	a2,24(a4)
    800020dc:	02078793          	addi	a5,a5,32
    800020e0:	02070713          	addi	a4,a4,32
    800020e4:	fed792e3          	bne	a5,a3,800020c8 <fork+0x54>
  np->trapframe->a0 = 0;
    800020e8:	0709b783          	ld	a5,112(s3)
    800020ec:	0607b823          	sd	zero,112(a5)
    800020f0:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    800020f4:	16800a13          	li	s4,360
    800020f8:	a03d                	j	80002126 <fork+0xb2>
    freeproc(np);
    800020fa:	854e                	mv	a0,s3
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	d26080e7          	jalr	-730(ra) # 80001e22 <freeproc>
    release(&np->lock);
    80002104:	854e                	mv	a0,s3
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
    return -1;
    8000210e:	5a7d                	li	s4,-1
    80002110:	a069                	j	8000219a <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80002112:	00002097          	auipc	ra,0x2
    80002116:	63e080e7          	jalr	1598(ra) # 80004750 <filedup>
    8000211a:	009987b3          	add	a5,s3,s1
    8000211e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002120:	04a1                	addi	s1,s1,8
    80002122:	01448763          	beq	s1,s4,80002130 <fork+0xbc>
    if(p->ofile[i])
    80002126:	009907b3          	add	a5,s2,s1
    8000212a:	6388                	ld	a0,0(a5)
    8000212c:	f17d                	bnez	a0,80002112 <fork+0x9e>
    8000212e:	bfcd                	j	80002120 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002130:	16893503          	ld	a0,360(s2)
    80002134:	00001097          	auipc	ra,0x1
    80002138:	792080e7          	jalr	1938(ra) # 800038c6 <idup>
    8000213c:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002140:	4641                	li	a2,16
    80002142:	17090593          	addi	a1,s2,368
    80002146:	17098513          	addi	a0,s3,368
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	ce8080e7          	jalr	-792(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002152:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002156:	854e                	mv	a0,s3
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b40080e7          	jalr	-1216(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002160:	0000f497          	auipc	s1,0xf
    80002164:	57848493          	addi	s1,s1,1400 # 800116d8 <wait_lock>
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	a7a080e7          	jalr	-1414(ra) # 80000be4 <acquire>
  np->parent = p;
    80002172:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002180:	854e                	mv	a0,s3
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	a62080e7          	jalr	-1438(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000218a:	478d                	li	a5,3
    8000218c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002190:	854e                	mv	a0,s3
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
}
    8000219a:	8552                	mv	a0,s4
    8000219c:	70a2                	ld	ra,40(sp)
    8000219e:	7402                	ld	s0,32(sp)
    800021a0:	64e2                	ld	s1,24(sp)
    800021a2:	6942                	ld	s2,16(sp)
    800021a4:	69a2                	ld	s3,8(sp)
    800021a6:	6a02                	ld	s4,0(sp)
    800021a8:	6145                	addi	sp,sp,48
    800021aa:	8082                	ret
    return -1;
    800021ac:	5a7d                	li	s4,-1
    800021ae:	b7f5                	j	8000219a <fork+0x126>

00000000800021b0 <sched>:
{
    800021b0:	7179                	addi	sp,sp,-48
    800021b2:	f406                	sd	ra,40(sp)
    800021b4:	f022                	sd	s0,32(sp)
    800021b6:	ec26                	sd	s1,24(sp)
    800021b8:	e84a                	sd	s2,16(sp)
    800021ba:	e44e                	sd	s3,8(sp)
    800021bc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	ab2080e7          	jalr	-1358(ra) # 80001c70 <myproc>
    800021c6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	9a2080e7          	jalr	-1630(ra) # 80000b6a <holding>
    800021d0:	c53d                	beqz	a0,8000223e <sched+0x8e>
    800021d2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021d4:	2781                	sext.w	a5,a5
    800021d6:	079e                	slli	a5,a5,0x7
    800021d8:	0000f717          	auipc	a4,0xf
    800021dc:	0e870713          	addi	a4,a4,232 # 800112c0 <cpus>
    800021e0:	97ba                	add	a5,a5,a4
    800021e2:	5fb8                	lw	a4,120(a5)
    800021e4:	4785                	li	a5,1
    800021e6:	06f71463          	bne	a4,a5,8000224e <sched+0x9e>
  if(p->state == RUNNING)
    800021ea:	4c98                	lw	a4,24(s1)
    800021ec:	4791                	li	a5,4
    800021ee:	06f70863          	beq	a4,a5,8000225e <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021f6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021f8:	ebbd                	bnez	a5,8000226e <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021fa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021fc:	0000f917          	auipc	s2,0xf
    80002200:	0c490913          	addi	s2,s2,196 # 800112c0 <cpus>
    80002204:	2781                	sext.w	a5,a5
    80002206:	079e                	slli	a5,a5,0x7
    80002208:	97ca                	add	a5,a5,s2
    8000220a:	07c7a983          	lw	s3,124(a5)
    8000220e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002210:	2581                	sext.w	a1,a1
    80002212:	059e                	slli	a1,a1,0x7
    80002214:	05a1                	addi	a1,a1,8
    80002216:	95ca                	add	a1,a1,s2
    80002218:	07848513          	addi	a0,s1,120
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	622080e7          	jalr	1570(ra) # 8000283e <swtch>
    80002224:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002226:	2781                	sext.w	a5,a5
    80002228:	079e                	slli	a5,a5,0x7
    8000222a:	993e                	add	s2,s2,a5
    8000222c:	07392e23          	sw	s3,124(s2)
}
    80002230:	70a2                	ld	ra,40(sp)
    80002232:	7402                	ld	s0,32(sp)
    80002234:	64e2                	ld	s1,24(sp)
    80002236:	6942                	ld	s2,16(sp)
    80002238:	69a2                	ld	s3,8(sp)
    8000223a:	6145                	addi	sp,sp,48
    8000223c:	8082                	ret
    panic("sched p->lock");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	07a50513          	addi	a0,a0,122 # 800082b8 <digits+0x278>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>
    panic("sched locks");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	07a50513          	addi	a0,a0,122 # 800082c8 <digits+0x288>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>
    panic("sched running");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	07a50513          	addi	a0,a0,122 # 800082d8 <digits+0x298>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2d8080e7          	jalr	728(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	07a50513          	addi	a0,a0,122 # 800082e8 <digits+0x2a8>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000227e <yield>:
{
    8000227e:	1101                	addi	sp,sp,-32
    80002280:	ec06                	sd	ra,24(sp)
    80002282:	e822                	sd	s0,16(sp)
    80002284:	e426                	sd	s1,8(sp)
    80002286:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	9e8080e7          	jalr	-1560(ra) # 80001c70 <myproc>
    80002290:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	952080e7          	jalr	-1710(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000229a:	478d                	li	a5,3
    8000229c:	cc9c                	sw	a5,24(s1)
  sched();
    8000229e:	00000097          	auipc	ra,0x0
    800022a2:	f12080e7          	jalr	-238(ra) # 800021b0 <sched>
  release(&p->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
}
    800022b0:	60e2                	ld	ra,24(sp)
    800022b2:	6442                	ld	s0,16(sp)
    800022b4:	64a2                	ld	s1,8(sp)
    800022b6:	6105                	addi	sp,sp,32
    800022b8:	8082                	ret

00000000800022ba <pause_sys>:
{
    800022ba:	1141                	addi	sp,sp,-16
    800022bc:	e406                	sd	ra,8(sp)
    800022be:	e022                	sd	s0,0(sp)
    800022c0:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    800022c2:	0025179b          	slliw	a5,a0,0x2
    800022c6:	9fa9                	addw	a5,a5,a0
    800022c8:	0017979b          	slliw	a5,a5,0x1
    800022cc:	00007517          	auipc	a0,0x7
    800022d0:	d8452503          	lw	a0,-636(a0) # 80009050 <ticks>
    800022d4:	9fa9                	addw	a5,a5,a0
    800022d6:	00007717          	auipc	a4,0x7
    800022da:	d6f72723          	sw	a5,-658(a4) # 80009044 <finish>
  yield();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	fa0080e7          	jalr	-96(ra) # 8000227e <yield>
}
    800022e6:	4501                	li	a0,0
    800022e8:	60a2                	ld	ra,8(sp)
    800022ea:	6402                	ld	s0,0(sp)
    800022ec:	0141                	addi	sp,sp,16
    800022ee:	8082                	ret

00000000800022f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022f0:	7179                	addi	sp,sp,-48
    800022f2:	f406                	sd	ra,40(sp)
    800022f4:	f022                	sd	s0,32(sp)
    800022f6:	ec26                	sd	s1,24(sp)
    800022f8:	e84a                	sd	s2,16(sp)
    800022fa:	e44e                	sd	s3,8(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	89aa                	mv	s3,a0
    80002300:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	96e080e7          	jalr	-1682(ra) # 80001c70 <myproc>
    8000230a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8d8080e7          	jalr	-1832(ra) # 80000be4 <acquire>
  release(lk);
    80002314:	854a                	mv	a0,s2
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000231e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002322:	4789                	li	a5,2
    80002324:	cc9c                	sw	a5,24(s1)
  int sleep_start = ticks;
    80002326:	00007997          	auipc	s3,0x7
    8000232a:	d2a9a983          	lw	s3,-726(s3) # 80009050 <ticks>
  sched();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	e82080e7          	jalr	-382(ra) # 800021b0 <sched>
  p->sleeping_time = p->sleeping_time - sleep_start;
    80002336:	40bc                	lw	a5,64(s1)
    80002338:	413787bb          	subw	a5,a5,s3
    8000233c:	c0bc                	sw	a5,64(s1)
  // Tidy up.
  p->chan = 0;
    8000233e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	954080e7          	jalr	-1708(ra) # 80000c98 <release>
  acquire(lk);
    8000234c:	854a                	mv	a0,s2
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	896080e7          	jalr	-1898(ra) # 80000be4 <acquire>
}
    80002356:	70a2                	ld	ra,40(sp)
    80002358:	7402                	ld	s0,32(sp)
    8000235a:	64e2                	ld	s1,24(sp)
    8000235c:	6942                	ld	s2,16(sp)
    8000235e:	69a2                	ld	s3,8(sp)
    80002360:	6145                	addi	sp,sp,48
    80002362:	8082                	ret

0000000080002364 <wait>:
{
    80002364:	715d                	addi	sp,sp,-80
    80002366:	e486                	sd	ra,72(sp)
    80002368:	e0a2                	sd	s0,64(sp)
    8000236a:	fc26                	sd	s1,56(sp)
    8000236c:	f84a                	sd	s2,48(sp)
    8000236e:	f44e                	sd	s3,40(sp)
    80002370:	f052                	sd	s4,32(sp)
    80002372:	ec56                	sd	s5,24(sp)
    80002374:	e85a                	sd	s6,16(sp)
    80002376:	e45e                	sd	s7,8(sp)
    80002378:	e062                	sd	s8,0(sp)
    8000237a:	0880                	addi	s0,sp,80
    8000237c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	8f2080e7          	jalr	-1806(ra) # 80001c70 <myproc>
    80002386:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	35050513          	addi	a0,a0,848 # 800116d8 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
    havekids = 0;
    80002398:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000239a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000239c:	00015997          	auipc	s3,0x15
    800023a0:	35498993          	addi	s3,s3,852 # 800176f0 <tickslock>
        havekids = 1;
    800023a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023a6:	0000fc17          	auipc	s8,0xf
    800023aa:	332c0c13          	addi	s8,s8,818 # 800116d8 <wait_lock>
    havekids = 0;
    800023ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023b0:	0000f497          	auipc	s1,0xf
    800023b4:	34048493          	addi	s1,s1,832 # 800116f0 <proc>
    800023b8:	a0bd                	j	80002426 <wait+0xc2>
          pid = np->pid;
    800023ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023be:	000b0e63          	beqz	s6,800023da <wait+0x76>
    800023c2:	4691                	li	a3,4
    800023c4:	02c48613          	addi	a2,s1,44
    800023c8:	85da                	mv	a1,s6
    800023ca:	06893503          	ld	a0,104(s2)
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	2a4080e7          	jalr	676(ra) # 80001672 <copyout>
    800023d6:	02054563          	bltz	a0,80002400 <wait+0x9c>
          freeproc(np);
    800023da:	8526                	mv	a0,s1
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	a46080e7          	jalr	-1466(ra) # 80001e22 <freeproc>
          release(&np->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
          release(&wait_lock);
    800023ee:	0000f517          	auipc	a0,0xf
    800023f2:	2ea50513          	addi	a0,a0,746 # 800116d8 <wait_lock>
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
          return pid;
    800023fe:	a09d                	j	80002464 <wait+0x100>
            release(&np->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
            release(&wait_lock);
    8000240a:	0000f517          	auipc	a0,0xf
    8000240e:	2ce50513          	addi	a0,a0,718 # 800116d8 <wait_lock>
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
            return -1;
    8000241a:	59fd                	li	s3,-1
    8000241c:	a0a1                	j	80002464 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000241e:	18048493          	addi	s1,s1,384
    80002422:	03348463          	beq	s1,s3,8000244a <wait+0xe6>
      if(np->parent == p){
    80002426:	68bc                	ld	a5,80(s1)
    80002428:	ff279be3          	bne	a5,s2,8000241e <wait+0xba>
        acquire(&np->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7b6080e7          	jalr	1974(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002436:	4c9c                	lw	a5,24(s1)
    80002438:	f94781e3          	beq	a5,s4,800023ba <wait+0x56>
        release(&np->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	85a080e7          	jalr	-1958(ra) # 80000c98 <release>
        havekids = 1;
    80002446:	8756                	mv	a4,s5
    80002448:	bfd9                	j	8000241e <wait+0xba>
    if(!havekids || p->killed){
    8000244a:	c701                	beqz	a4,80002452 <wait+0xee>
    8000244c:	02892783          	lw	a5,40(s2)
    80002450:	c79d                	beqz	a5,8000247e <wait+0x11a>
      release(&wait_lock);
    80002452:	0000f517          	auipc	a0,0xf
    80002456:	28650513          	addi	a0,a0,646 # 800116d8 <wait_lock>
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
      return -1;
    80002462:	59fd                	li	s3,-1
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000247e:	85e2                	mv	a1,s8
    80002480:	854a                	mv	a0,s2
    80002482:	00000097          	auipc	ra,0x0
    80002486:	e6e080e7          	jalr	-402(ra) # 800022f0 <sleep>
    havekids = 0;
    8000248a:	b715                	j	800023ae <wait+0x4a>

000000008000248c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000248c:	7139                	addi	sp,sp,-64
    8000248e:	fc06                	sd	ra,56(sp)
    80002490:	f822                	sd	s0,48(sp)
    80002492:	f426                	sd	s1,40(sp)
    80002494:	f04a                	sd	s2,32(sp)
    80002496:	ec4e                	sd	s3,24(sp)
    80002498:	e852                	sd	s4,16(sp)
    8000249a:	e456                	sd	s5,8(sp)
    8000249c:	0080                	addi	s0,sp,64
    8000249e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024a0:	0000f497          	auipc	s1,0xf
    800024a4:	25048493          	addi	s1,s1,592 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024a8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024aa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ac:	00015917          	auipc	s2,0x15
    800024b0:	24490913          	addi	s2,s2,580 # 800176f0 <tickslock>
    800024b4:	a821                	j	800024cc <wakeup+0x40>
        p->state = RUNNABLE;
    800024b6:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c4:	18048493          	addi	s1,s1,384
    800024c8:	03248463          	beq	s1,s2,800024f0 <wakeup+0x64>
    if(p != myproc()){
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	7a4080e7          	jalr	1956(ra) # 80001c70 <myproc>
    800024d4:	fea488e3          	beq	s1,a0,800024c4 <wakeup+0x38>
      acquire(&p->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024e2:	4c9c                	lw	a5,24(s1)
    800024e4:	fd379be3          	bne	a5,s3,800024ba <wakeup+0x2e>
    800024e8:	709c                	ld	a5,32(s1)
    800024ea:	fd4798e3          	bne	a5,s4,800024ba <wakeup+0x2e>
    800024ee:	b7e1                	j	800024b6 <wakeup+0x2a>
    }
  }
}
    800024f0:	70e2                	ld	ra,56(sp)
    800024f2:	7442                	ld	s0,48(sp)
    800024f4:	74a2                	ld	s1,40(sp)
    800024f6:	7902                	ld	s2,32(sp)
    800024f8:	69e2                	ld	s3,24(sp)
    800024fa:	6a42                	ld	s4,16(sp)
    800024fc:	6aa2                	ld	s5,8(sp)
    800024fe:	6121                	addi	sp,sp,64
    80002500:	8082                	ret

0000000080002502 <reparent>:
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002514:	0000f497          	auipc	s1,0xf
    80002518:	1dc48493          	addi	s1,s1,476 # 800116f0 <proc>
      pp->parent = initproc;
    8000251c:	00007a17          	auipc	s4,0x7
    80002520:	b2ca0a13          	addi	s4,s4,-1236 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002524:	00015997          	auipc	s3,0x15
    80002528:	1cc98993          	addi	s3,s3,460 # 800176f0 <tickslock>
    8000252c:	a029                	j	80002536 <reparent+0x34>
    8000252e:	18048493          	addi	s1,s1,384
    80002532:	01348d63          	beq	s1,s3,8000254c <reparent+0x4a>
    if(pp->parent == p){
    80002536:	68bc                	ld	a5,80(s1)
    80002538:	ff279be3          	bne	a5,s2,8000252e <reparent+0x2c>
      pp->parent = initproc;
    8000253c:	000a3503          	ld	a0,0(s4)
    80002540:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002542:	00000097          	auipc	ra,0x0
    80002546:	f4a080e7          	jalr	-182(ra) # 8000248c <wakeup>
    8000254a:	b7d5                	j	8000252e <reparent+0x2c>
}
    8000254c:	70a2                	ld	ra,40(sp)
    8000254e:	7402                	ld	s0,32(sp)
    80002550:	64e2                	ld	s1,24(sp)
    80002552:	6942                	ld	s2,16(sp)
    80002554:	69a2                	ld	s3,8(sp)
    80002556:	6a02                	ld	s4,0(sp)
    80002558:	6145                	addi	sp,sp,48
    8000255a:	8082                	ret

000000008000255c <exit>:
{
    8000255c:	7179                	addi	sp,sp,-48
    8000255e:	f406                	sd	ra,40(sp)
    80002560:	f022                	sd	s0,32(sp)
    80002562:	ec26                	sd	s1,24(sp)
    80002564:	e84a                	sd	s2,16(sp)
    80002566:	e44e                	sd	s3,8(sp)
    80002568:	e052                	sd	s4,0(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	702080e7          	jalr	1794(ra) # 80001c70 <myproc>
    80002576:	892a                	mv	s2,a0
  if(p == initproc)
    80002578:	00007797          	auipc	a5,0x7
    8000257c:	ad07b783          	ld	a5,-1328(a5) # 80009048 <initproc>
    80002580:	0e850493          	addi	s1,a0,232
    80002584:	16850993          	addi	s3,a0,360
    80002588:	02a79363          	bne	a5,a0,800025ae <exit+0x52>
    panic("init exiting");
    8000258c:	00006517          	auipc	a0,0x6
    80002590:	d7450513          	addi	a0,a0,-652 # 80008300 <digits+0x2c0>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>
      fileclose(f);
    8000259c:	00002097          	auipc	ra,0x2
    800025a0:	206080e7          	jalr	518(ra) # 800047a2 <fileclose>
      p->ofile[fd] = 0;
    800025a4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025a8:	04a1                	addi	s1,s1,8
    800025aa:	01348563          	beq	s1,s3,800025b4 <exit+0x58>
    if(p->ofile[fd]){
    800025ae:	6088                	ld	a0,0(s1)
    800025b0:	f575                	bnez	a0,8000259c <exit+0x40>
    800025b2:	bfdd                	j	800025a8 <exit+0x4c>
  begin_op();
    800025b4:	00002097          	auipc	ra,0x2
    800025b8:	d22080e7          	jalr	-734(ra) # 800042d6 <begin_op>
  iput(p->cwd);
    800025bc:	16893503          	ld	a0,360(s2)
    800025c0:	00001097          	auipc	ra,0x1
    800025c4:	4fe080e7          	jalr	1278(ra) # 80003abe <iput>
  end_op();
    800025c8:	00002097          	auipc	ra,0x2
    800025cc:	d8e080e7          	jalr	-626(ra) # 80004356 <end_op>
  p->cwd = 0;
    800025d0:	16093423          	sd	zero,360(s2)
  acquire(&wait_lock);
    800025d4:	0000f517          	auipc	a0,0xf
    800025d8:	10450513          	addi	a0,a0,260 # 800116d8 <wait_lock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	608080e7          	jalr	1544(ra) # 80000be4 <acquire>
  sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/exited+1;
    800025e4:	00007797          	auipc	a5,0x7
    800025e8:	a507a783          	lw	a5,-1456(a5) # 80009034 <exited>
    800025ec:	00007697          	auipc	a3,0x7
    800025f0:	a5468693          	addi	a3,a3,-1452 # 80009040 <sleeping_processes_mean>
    800025f4:	4298                	lw	a4,0(a3)
    800025f6:	02f7073b          	mulw	a4,a4,a5
    800025fa:	04092603          	lw	a2,64(s2)
    800025fe:	9f31                	addw	a4,a4,a2
    80002600:	02f7473b          	divw	a4,a4,a5
    80002604:	2705                	addiw	a4,a4,1
    80002606:	c298                	sw	a4,0(a3)
  running_processes_mean = ((running_processes_mean*exited) + p->running_time)/exited+1;
    80002608:	04892603          	lw	a2,72(s2)
    8000260c:	00007697          	auipc	a3,0x7
    80002610:	a3068693          	addi	a3,a3,-1488 # 8000903c <running_processes_mean>
    80002614:	4298                	lw	a4,0(a3)
    80002616:	02f7073b          	mulw	a4,a4,a5
    8000261a:	9f31                	addw	a4,a4,a2
    8000261c:	02f7473b          	divw	a4,a4,a5
    80002620:	2705                	addiw	a4,a4,1
    80002622:	c298                	sw	a4,0(a3)
  runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/exited+1;
    80002624:	00007697          	auipc	a3,0x7
    80002628:	a1468693          	addi	a3,a3,-1516 # 80009038 <runnable_processes_mean>
    8000262c:	4298                	lw	a4,0(a3)
    8000262e:	02f7073b          	mulw	a4,a4,a5
    80002632:	04492583          	lw	a1,68(s2)
    80002636:	9f2d                	addw	a4,a4,a1
    80002638:	02f7473b          	divw	a4,a4,a5
    8000263c:	2705                	addiw	a4,a4,1
    8000263e:	c298                	sw	a4,0(a3)
  if((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)){
    80002640:	03092683          	lw	a3,48(s2)
    80002644:	0000f717          	auipc	a4,0xf
    80002648:	0dc72703          	lw	a4,220(a4) # 80011720 <proc+0x30>
    8000264c:	02d70e63          	beq	a4,a3,80002688 <exit+0x12c>
    80002650:	0000f717          	auipc	a4,0xf
    80002654:	25072703          	lw	a4,592(a4) # 800118a0 <proc+0x1b0>
    80002658:	02d70863          	beq	a4,a3,80002688 <exit+0x12c>
    program_time = program_time + p->running_time;
    8000265c:	00007697          	auipc	a3,0x7
    80002660:	9d068693          	addi	a3,a3,-1584 # 8000902c <program_time>
    80002664:	4298                	lw	a4,0(a3)
    80002666:	9f31                	addw	a4,a4,a2
    80002668:	c298                	sw	a4,0(a3)
    cpu_utilization = program_time/(ticks-start_time);
    8000266a:	00007697          	auipc	a3,0x7
    8000266e:	9e66a683          	lw	a3,-1562(a3) # 80009050 <ticks>
    80002672:	00007617          	auipc	a2,0x7
    80002676:	9be62603          	lw	a2,-1602(a2) # 80009030 <start_time>
    8000267a:	9e91                	subw	a3,a3,a2
    8000267c:	02d7573b          	divuw	a4,a4,a3
    80002680:	00007697          	auipc	a3,0x7
    80002684:	9ae6a423          	sw	a4,-1624(a3) # 80009028 <cpu_utilization>
  exited = exited + 1;
    80002688:	2785                	addiw	a5,a5,1
    8000268a:	00007717          	auipc	a4,0x7
    8000268e:	9af72523          	sw	a5,-1622(a4) # 80009034 <exited>
  reparent(p);
    80002692:	854a                	mv	a0,s2
    80002694:	00000097          	auipc	ra,0x0
    80002698:	e6e080e7          	jalr	-402(ra) # 80002502 <reparent>
  wakeup(p->parent);
    8000269c:	05093503          	ld	a0,80(s2)
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	dec080e7          	jalr	-532(ra) # 8000248c <wakeup>
  acquire(&p->lock);
    800026a8:	854a                	mv	a0,s2
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	53a080e7          	jalr	1338(ra) # 80000be4 <acquire>
  p->xstate = status;
    800026b2:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    800026b6:	4795                	li	a5,5
    800026b8:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    800026bc:	0000f517          	auipc	a0,0xf
    800026c0:	01c50513          	addi	a0,a0,28 # 800116d8 <wait_lock>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	5d4080e7          	jalr	1492(ra) # 80000c98 <release>
  sched();
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	ae4080e7          	jalr	-1308(ra) # 800021b0 <sched>
  panic("zombie exit");
    800026d4:	00006517          	auipc	a0,0x6
    800026d8:	c3c50513          	addi	a0,a0,-964 # 80008310 <digits+0x2d0>
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	e62080e7          	jalr	-414(ra) # 8000053e <panic>

00000000800026e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026e4:	7179                	addi	sp,sp,-48
    800026e6:	f406                	sd	ra,40(sp)
    800026e8:	f022                	sd	s0,32(sp)
    800026ea:	ec26                	sd	s1,24(sp)
    800026ec:	e84a                	sd	s2,16(sp)
    800026ee:	e44e                	sd	s3,8(sp)
    800026f0:	e052                	sd	s4,0(sp)
    800026f2:	1800                	addi	s0,sp,48
    800026f4:	84aa                	mv	s1,a0
    800026f6:	892e                	mv	s2,a1
    800026f8:	89b2                	mv	s3,a2
    800026fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	574080e7          	jalr	1396(ra) # 80001c70 <myproc>
  if(user_dst){
    80002704:	c08d                	beqz	s1,80002726 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002706:	86d2                	mv	a3,s4
    80002708:	864e                	mv	a2,s3
    8000270a:	85ca                	mv	a1,s2
    8000270c:	7528                	ld	a0,104(a0)
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	f64080e7          	jalr	-156(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002716:	70a2                	ld	ra,40(sp)
    80002718:	7402                	ld	s0,32(sp)
    8000271a:	64e2                	ld	s1,24(sp)
    8000271c:	6942                	ld	s2,16(sp)
    8000271e:	69a2                	ld	s3,8(sp)
    80002720:	6a02                	ld	s4,0(sp)
    80002722:	6145                	addi	sp,sp,48
    80002724:	8082                	ret
    memmove((char *)dst, src, len);
    80002726:	000a061b          	sext.w	a2,s4
    8000272a:	85ce                	mv	a1,s3
    8000272c:	854a                	mv	a0,s2
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	612080e7          	jalr	1554(ra) # 80000d40 <memmove>
    return 0;
    80002736:	8526                	mv	a0,s1
    80002738:	bff9                	j	80002716 <either_copyout+0x32>

000000008000273a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	e052                	sd	s4,0(sp)
    80002748:	1800                	addi	s0,sp,48
    8000274a:	892a                	mv	s2,a0
    8000274c:	84ae                	mv	s1,a1
    8000274e:	89b2                	mv	s3,a2
    80002750:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	51e080e7          	jalr	1310(ra) # 80001c70 <myproc>
  if(user_src){
    8000275a:	c08d                	beqz	s1,8000277c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000275c:	86d2                	mv	a3,s4
    8000275e:	864e                	mv	a2,s3
    80002760:	85ca                	mv	a1,s2
    80002762:	7528                	ld	a0,104(a0)
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	f9a080e7          	jalr	-102(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000276c:	70a2                	ld	ra,40(sp)
    8000276e:	7402                	ld	s0,32(sp)
    80002770:	64e2                	ld	s1,24(sp)
    80002772:	6942                	ld	s2,16(sp)
    80002774:	69a2                	ld	s3,8(sp)
    80002776:	6a02                	ld	s4,0(sp)
    80002778:	6145                	addi	sp,sp,48
    8000277a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000277c:	000a061b          	sext.w	a2,s4
    80002780:	85ce                	mv	a1,s3
    80002782:	854a                	mv	a0,s2
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	5bc080e7          	jalr	1468(ra) # 80000d40 <memmove>
    return 0;
    8000278c:	8526                	mv	a0,s1
    8000278e:	bff9                	j	8000276c <either_copyin+0x32>

0000000080002790 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002790:	715d                	addi	sp,sp,-80
    80002792:	e486                	sd	ra,72(sp)
    80002794:	e0a2                	sd	s0,64(sp)
    80002796:	fc26                	sd	s1,56(sp)
    80002798:	f84a                	sd	s2,48(sp)
    8000279a:	f44e                	sd	s3,40(sp)
    8000279c:	f052                	sd	s4,32(sp)
    8000279e:	ec56                	sd	s5,24(sp)
    800027a0:	e85a                	sd	s6,16(sp)
    800027a2:	e45e                	sd	s7,8(sp)
    800027a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027a6:	00006517          	auipc	a0,0x6
    800027aa:	a6250513          	addi	a0,a0,-1438 # 80008208 <digits+0x1c8>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	dda080e7          	jalr	-550(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b6:	0000f497          	auipc	s1,0xf
    800027ba:	0aa48493          	addi	s1,s1,170 # 80011860 <proc+0x170>
    800027be:	00015917          	auipc	s2,0x15
    800027c2:	0a290913          	addi	s2,s2,162 # 80017860 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027c8:	00006997          	auipc	s3,0x6
    800027cc:	b5898993          	addi	s3,s3,-1192 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    800027d0:	00006a97          	auipc	s5,0x6
    800027d4:	b58a8a93          	addi	s5,s5,-1192 # 80008328 <digits+0x2e8>
    printf("\n");
    800027d8:	00006a17          	auipc	s4,0x6
    800027dc:	a30a0a13          	addi	s4,s4,-1488 # 80008208 <digits+0x1c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e0:	00006b97          	auipc	s7,0x6
    800027e4:	b80b8b93          	addi	s7,s7,-1152 # 80008360 <states.1745>
    800027e8:	a00d                	j	8000280a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027ea:	ec06a583          	lw	a1,-320(a3)
    800027ee:	8556                	mv	a0,s5
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	d98080e7          	jalr	-616(ra) # 80000588 <printf>
    printf("\n");
    800027f8:	8552                	mv	a0,s4
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d8e080e7          	jalr	-626(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002802:	18048493          	addi	s1,s1,384
    80002806:	03248163          	beq	s1,s2,80002828 <procdump+0x98>
    if(p->state == UNUSED)
    8000280a:	86a6                	mv	a3,s1
    8000280c:	ea84a783          	lw	a5,-344(s1)
    80002810:	dbed                	beqz	a5,80002802 <procdump+0x72>
      state = "???";
    80002812:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002814:	fcfb6be3          	bltu	s6,a5,800027ea <procdump+0x5a>
    80002818:	1782                	slli	a5,a5,0x20
    8000281a:	9381                	srli	a5,a5,0x20
    8000281c:	078e                	slli	a5,a5,0x3
    8000281e:	97de                	add	a5,a5,s7
    80002820:	6390                	ld	a2,0(a5)
    80002822:	f661                	bnez	a2,800027ea <procdump+0x5a>
      state = "???";
    80002824:	864e                	mv	a2,s3
    80002826:	b7d1                	j	800027ea <procdump+0x5a>
  }
}
    80002828:	60a6                	ld	ra,72(sp)
    8000282a:	6406                	ld	s0,64(sp)
    8000282c:	74e2                	ld	s1,56(sp)
    8000282e:	7942                	ld	s2,48(sp)
    80002830:	79a2                	ld	s3,40(sp)
    80002832:	7a02                	ld	s4,32(sp)
    80002834:	6ae2                	ld	s5,24(sp)
    80002836:	6b42                	ld	s6,16(sp)
    80002838:	6ba2                	ld	s7,8(sp)
    8000283a:	6161                	addi	sp,sp,80
    8000283c:	8082                	ret

000000008000283e <swtch>:
    8000283e:	00153023          	sd	ra,0(a0)
    80002842:	00253423          	sd	sp,8(a0)
    80002846:	e900                	sd	s0,16(a0)
    80002848:	ed04                	sd	s1,24(a0)
    8000284a:	03253023          	sd	s2,32(a0)
    8000284e:	03353423          	sd	s3,40(a0)
    80002852:	03453823          	sd	s4,48(a0)
    80002856:	03553c23          	sd	s5,56(a0)
    8000285a:	05653023          	sd	s6,64(a0)
    8000285e:	05753423          	sd	s7,72(a0)
    80002862:	05853823          	sd	s8,80(a0)
    80002866:	05953c23          	sd	s9,88(a0)
    8000286a:	07a53023          	sd	s10,96(a0)
    8000286e:	07b53423          	sd	s11,104(a0)
    80002872:	0005b083          	ld	ra,0(a1)
    80002876:	0085b103          	ld	sp,8(a1)
    8000287a:	6980                	ld	s0,16(a1)
    8000287c:	6d84                	ld	s1,24(a1)
    8000287e:	0205b903          	ld	s2,32(a1)
    80002882:	0285b983          	ld	s3,40(a1)
    80002886:	0305ba03          	ld	s4,48(a1)
    8000288a:	0385ba83          	ld	s5,56(a1)
    8000288e:	0405bb03          	ld	s6,64(a1)
    80002892:	0485bb83          	ld	s7,72(a1)
    80002896:	0505bc03          	ld	s8,80(a1)
    8000289a:	0585bc83          	ld	s9,88(a1)
    8000289e:	0605bd03          	ld	s10,96(a1)
    800028a2:	0685bd83          	ld	s11,104(a1)
    800028a6:	8082                	ret

00000000800028a8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028a8:	1141                	addi	sp,sp,-16
    800028aa:	e406                	sd	ra,8(sp)
    800028ac:	e022                	sd	s0,0(sp)
    800028ae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028b0:	00006597          	auipc	a1,0x6
    800028b4:	ae058593          	addi	a1,a1,-1312 # 80008390 <states.1745+0x30>
    800028b8:	00015517          	auipc	a0,0x15
    800028bc:	e3850513          	addi	a0,a0,-456 # 800176f0 <tickslock>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	294080e7          	jalr	660(ra) # 80000b54 <initlock>
}
    800028c8:	60a2                	ld	ra,8(sp)
    800028ca:	6402                	ld	s0,0(sp)
    800028cc:	0141                	addi	sp,sp,16
    800028ce:	8082                	ret

00000000800028d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028d0:	1141                	addi	sp,sp,-16
    800028d2:	e422                	sd	s0,8(sp)
    800028d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d6:	00003797          	auipc	a5,0x3
    800028da:	4ea78793          	addi	a5,a5,1258 # 80005dc0 <kernelvec>
    800028de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028e2:	6422                	ld	s0,8(sp)
    800028e4:	0141                	addi	sp,sp,16
    800028e6:	8082                	ret

00000000800028e8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028e8:	1141                	addi	sp,sp,-16
    800028ea:	e406                	sd	ra,8(sp)
    800028ec:	e022                	sd	s0,0(sp)
    800028ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028f0:	fffff097          	auipc	ra,0xfffff
    800028f4:	380080e7          	jalr	896(ra) # 80001c70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028fe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002902:	00004617          	auipc	a2,0x4
    80002906:	6fe60613          	addi	a2,a2,1790 # 80007000 <_trampoline>
    8000290a:	00004697          	auipc	a3,0x4
    8000290e:	6f668693          	addi	a3,a3,1782 # 80007000 <_trampoline>
    80002912:	8e91                	sub	a3,a3,a2
    80002914:	040007b7          	lui	a5,0x4000
    80002918:	17fd                	addi	a5,a5,-1
    8000291a:	07b2                	slli	a5,a5,0xc
    8000291c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000291e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002922:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002924:	180026f3          	csrr	a3,satp
    80002928:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000292a:	7938                	ld	a4,112(a0)
    8000292c:	6d34                	ld	a3,88(a0)
    8000292e:	6585                	lui	a1,0x1
    80002930:	96ae                	add	a3,a3,a1
    80002932:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002934:	7938                	ld	a4,112(a0)
    80002936:	00000697          	auipc	a3,0x0
    8000293a:	13868693          	addi	a3,a3,312 # 80002a6e <usertrap>
    8000293e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002940:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002942:	8692                	mv	a3,tp
    80002944:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000294a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000294e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002952:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002956:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002958:	6f18                	ld	a4,24(a4)
    8000295a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000295e:	752c                	ld	a1,104(a0)
    80002960:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002962:	00004717          	auipc	a4,0x4
    80002966:	72e70713          	addi	a4,a4,1838 # 80007090 <userret>
    8000296a:	8f11                	sub	a4,a4,a2
    8000296c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000296e:	577d                	li	a4,-1
    80002970:	177e                	slli	a4,a4,0x3f
    80002972:	8dd9                	or	a1,a1,a4
    80002974:	02000537          	lui	a0,0x2000
    80002978:	157d                	addi	a0,a0,-1
    8000297a:	0536                	slli	a0,a0,0xd
    8000297c:	9782                	jalr	a5
}
    8000297e:	60a2                	ld	ra,8(sp)
    80002980:	6402                	ld	s0,0(sp)
    80002982:	0141                	addi	sp,sp,16
    80002984:	8082                	ret

0000000080002986 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002986:	1101                	addi	sp,sp,-32
    80002988:	ec06                	sd	ra,24(sp)
    8000298a:	e822                	sd	s0,16(sp)
    8000298c:	e426                	sd	s1,8(sp)
    8000298e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002990:	00015497          	auipc	s1,0x15
    80002994:	d6048493          	addi	s1,s1,-672 # 800176f0 <tickslock>
    80002998:	8526                	mv	a0,s1
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
  ticks++;
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	6ae50513          	addi	a0,a0,1710 # 80009050 <ticks>
    800029aa:	411c                	lw	a5,0(a0)
    800029ac:	2785                	addiw	a5,a5,1
    800029ae:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	adc080e7          	jalr	-1316(ra) # 8000248c <wakeup>
  release(&tickslock);
    800029b8:	8526                	mv	a0,s1
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	2de080e7          	jalr	734(ra) # 80000c98 <release>
}
    800029c2:	60e2                	ld	ra,24(sp)
    800029c4:	6442                	ld	s0,16(sp)
    800029c6:	64a2                	ld	s1,8(sp)
    800029c8:	6105                	addi	sp,sp,32
    800029ca:	8082                	ret

00000000800029cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029cc:	1101                	addi	sp,sp,-32
    800029ce:	ec06                	sd	ra,24(sp)
    800029d0:	e822                	sd	s0,16(sp)
    800029d2:	e426                	sd	s1,8(sp)
    800029d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029da:	00074d63          	bltz	a4,800029f4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029de:	57fd                	li	a5,-1
    800029e0:	17fe                	slli	a5,a5,0x3f
    800029e2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029e4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029e6:	06f70363          	beq	a4,a5,80002a4c <devintr+0x80>
  }
}
    800029ea:	60e2                	ld	ra,24(sp)
    800029ec:	6442                	ld	s0,16(sp)
    800029ee:	64a2                	ld	s1,8(sp)
    800029f0:	6105                	addi	sp,sp,32
    800029f2:	8082                	ret
     (scause & 0xff) == 9){
    800029f4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029f8:	46a5                	li	a3,9
    800029fa:	fed792e3          	bne	a5,a3,800029de <devintr+0x12>
    int irq = plic_claim();
    800029fe:	00003097          	auipc	ra,0x3
    80002a02:	4ca080e7          	jalr	1226(ra) # 80005ec8 <plic_claim>
    80002a06:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a08:	47a9                	li	a5,10
    80002a0a:	02f50763          	beq	a0,a5,80002a38 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a0e:	4785                	li	a5,1
    80002a10:	02f50963          	beq	a0,a5,80002a42 <devintr+0x76>
    return 1;
    80002a14:	4505                	li	a0,1
    } else if(irq){
    80002a16:	d8f1                	beqz	s1,800029ea <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a18:	85a6                	mv	a1,s1
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	97e50513          	addi	a0,a0,-1666 # 80008398 <states.1745+0x38>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b66080e7          	jalr	-1178(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	00003097          	auipc	ra,0x3
    80002a30:	4c0080e7          	jalr	1216(ra) # 80005eec <plic_complete>
    return 1;
    80002a34:	4505                	li	a0,1
    80002a36:	bf55                	j	800029ea <devintr+0x1e>
      uartintr();
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	f70080e7          	jalr	-144(ra) # 800009a8 <uartintr>
    80002a40:	b7ed                	j	80002a2a <devintr+0x5e>
      virtio_disk_intr();
    80002a42:	00004097          	auipc	ra,0x4
    80002a46:	98a080e7          	jalr	-1654(ra) # 800063cc <virtio_disk_intr>
    80002a4a:	b7c5                	j	80002a2a <devintr+0x5e>
    if(cpuid() == 0){
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	1f8080e7          	jalr	504(ra) # 80001c44 <cpuid>
    80002a54:	c901                	beqz	a0,80002a64 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a56:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a5a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a5c:	14479073          	csrw	sip,a5
    return 2;
    80002a60:	4509                	li	a0,2
    80002a62:	b761                	j	800029ea <devintr+0x1e>
      clockintr();
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	f22080e7          	jalr	-222(ra) # 80002986 <clockintr>
    80002a6c:	b7ed                	j	80002a56 <devintr+0x8a>

0000000080002a6e <usertrap>:
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	e04a                	sd	s2,0(sp)
    80002a78:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a7e:	1007f793          	andi	a5,a5,256
    80002a82:	e3ad                	bnez	a5,80002ae4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a84:	00003797          	auipc	a5,0x3
    80002a88:	33c78793          	addi	a5,a5,828 # 80005dc0 <kernelvec>
    80002a8c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	1e0080e7          	jalr	480(ra) # 80001c70 <myproc>
    80002a98:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a9a:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9c:	14102773          	csrr	a4,sepc
    80002aa0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aa6:	47a1                	li	a5,8
    80002aa8:	04f71c63          	bne	a4,a5,80002b00 <usertrap+0x92>
    if(p->killed)
    80002aac:	551c                	lw	a5,40(a0)
    80002aae:	e3b9                	bnez	a5,80002af4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ab0:	78b8                	ld	a4,112(s1)
    80002ab2:	6f1c                	ld	a5,24(a4)
    80002ab4:	0791                	addi	a5,a5,4
    80002ab6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002abc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac0:	10079073          	csrw	sstatus,a5
    syscall();
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	2e0080e7          	jalr	736(ra) # 80002da4 <syscall>
  if(p->killed)
    80002acc:	549c                	lw	a5,40(s1)
    80002ace:	ebc1                	bnez	a5,80002b5e <usertrap+0xf0>
  usertrapret();
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	e18080e7          	jalr	-488(ra) # 800028e8 <usertrapret>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6902                	ld	s2,0(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret
    panic("usertrap: not from user mode");
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8d450513          	addi	a0,a0,-1836 # 800083b8 <states.1745+0x58>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a52080e7          	jalr	-1454(ra) # 8000053e <panic>
      exit(-1);
    80002af4:	557d                	li	a0,-1
    80002af6:	00000097          	auipc	ra,0x0
    80002afa:	a66080e7          	jalr	-1434(ra) # 8000255c <exit>
    80002afe:	bf4d                	j	80002ab0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	ecc080e7          	jalr	-308(ra) # 800029cc <devintr>
    80002b08:	892a                	mv	s2,a0
    80002b0a:	c501                	beqz	a0,80002b12 <usertrap+0xa4>
  if(p->killed)
    80002b0c:	549c                	lw	a5,40(s1)
    80002b0e:	c3a1                	beqz	a5,80002b4e <usertrap+0xe0>
    80002b10:	a815                	j	80002b44 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b12:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b16:	5890                	lw	a2,48(s1)
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	8c050513          	addi	a0,a0,-1856 # 800083d8 <states.1745+0x78>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a68080e7          	jalr	-1432(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b2c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	8d850513          	addi	a0,a0,-1832 # 80008408 <states.1745+0xa8>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a50080e7          	jalr	-1456(ra) # 80000588 <printf>
    p->killed = 1;
    80002b40:	4785                	li	a5,1
    80002b42:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b44:	557d                	li	a0,-1
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	a16080e7          	jalr	-1514(ra) # 8000255c <exit>
  if(which_dev == 2)
    80002b4e:	4789                	li	a5,2
    80002b50:	f8f910e3          	bne	s2,a5,80002ad0 <usertrap+0x62>
    yield();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	72a080e7          	jalr	1834(ra) # 8000227e <yield>
    80002b5c:	bf95                	j	80002ad0 <usertrap+0x62>
  int which_dev = 0;
    80002b5e:	4901                	li	s2,0
    80002b60:	b7d5                	j	80002b44 <usertrap+0xd6>

0000000080002b62 <kerneltrap>:
{
    80002b62:	7179                	addi	sp,sp,-48
    80002b64:	f406                	sd	ra,40(sp)
    80002b66:	f022                	sd	s0,32(sp)
    80002b68:	ec26                	sd	s1,24(sp)
    80002b6a:	e84a                	sd	s2,16(sp)
    80002b6c:	e44e                	sd	s3,8(sp)
    80002b6e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b70:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b78:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b7c:	1004f793          	andi	a5,s1,256
    80002b80:	cb85                	beqz	a5,80002bb0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b82:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b86:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b88:	ef85                	bnez	a5,80002bc0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	e42080e7          	jalr	-446(ra) # 800029cc <devintr>
    80002b92:	cd1d                	beqz	a0,80002bd0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b94:	4789                	li	a5,2
    80002b96:	06f50a63          	beq	a0,a5,80002c0a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b9a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b9e:	10049073          	csrw	sstatus,s1
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	87850513          	addi	a0,a0,-1928 # 80008428 <states.1745+0xc8>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	89050513          	addi	a0,a0,-1904 # 80008450 <states.1745+0xf0>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	976080e7          	jalr	-1674(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bd0:	85ce                	mv	a1,s3
    80002bd2:	00006517          	auipc	a0,0x6
    80002bd6:	89e50513          	addi	a0,a0,-1890 # 80008470 <states.1745+0x110>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9ae080e7          	jalr	-1618(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	89650513          	addi	a0,a0,-1898 # 80008480 <states.1745+0x120>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	996080e7          	jalr	-1642(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bfa:	00006517          	auipc	a0,0x6
    80002bfe:	89e50513          	addi	a0,a0,-1890 # 80008498 <states.1745+0x138>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	93c080e7          	jalr	-1732(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	066080e7          	jalr	102(ra) # 80001c70 <myproc>
    80002c12:	d541                	beqz	a0,80002b9a <kerneltrap+0x38>
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	05c080e7          	jalr	92(ra) # 80001c70 <myproc>
    80002c1c:	4d18                	lw	a4,24(a0)
    80002c1e:	4791                	li	a5,4
    80002c20:	f6f71de3          	bne	a4,a5,80002b9a <kerneltrap+0x38>
    yield();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	65a080e7          	jalr	1626(ra) # 8000227e <yield>
    80002c2c:	b7bd                	j	80002b9a <kerneltrap+0x38>

0000000080002c2e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	e426                	sd	s1,8(sp)
    80002c36:	1000                	addi	s0,sp,32
    80002c38:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	036080e7          	jalr	54(ra) # 80001c70 <myproc>
  switch (n) {
    80002c42:	4795                	li	a5,5
    80002c44:	0497e163          	bltu	a5,s1,80002c86 <argraw+0x58>
    80002c48:	048a                	slli	s1,s1,0x2
    80002c4a:	00006717          	auipc	a4,0x6
    80002c4e:	88670713          	addi	a4,a4,-1914 # 800084d0 <states.1745+0x170>
    80002c52:	94ba                	add	s1,s1,a4
    80002c54:	409c                	lw	a5,0(s1)
    80002c56:	97ba                	add	a5,a5,a4
    80002c58:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c5a:	793c                	ld	a5,112(a0)
    80002c5c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    return p->trapframe->a1;
    80002c68:	793c                	ld	a5,112(a0)
    80002c6a:	7fa8                	ld	a0,120(a5)
    80002c6c:	bfcd                	j	80002c5e <argraw+0x30>
    return p->trapframe->a2;
    80002c6e:	793c                	ld	a5,112(a0)
    80002c70:	63c8                	ld	a0,128(a5)
    80002c72:	b7f5                	j	80002c5e <argraw+0x30>
    return p->trapframe->a3;
    80002c74:	793c                	ld	a5,112(a0)
    80002c76:	67c8                	ld	a0,136(a5)
    80002c78:	b7dd                	j	80002c5e <argraw+0x30>
    return p->trapframe->a4;
    80002c7a:	793c                	ld	a5,112(a0)
    80002c7c:	6bc8                	ld	a0,144(a5)
    80002c7e:	b7c5                	j	80002c5e <argraw+0x30>
    return p->trapframe->a5;
    80002c80:	793c                	ld	a5,112(a0)
    80002c82:	6fc8                	ld	a0,152(a5)
    80002c84:	bfe9                	j	80002c5e <argraw+0x30>
  panic("argraw");
    80002c86:	00006517          	auipc	a0,0x6
    80002c8a:	82250513          	addi	a0,a0,-2014 # 800084a8 <states.1745+0x148>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8b0080e7          	jalr	-1872(ra) # 8000053e <panic>

0000000080002c96 <fetchaddr>:
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	e04a                	sd	s2,0(sp)
    80002ca0:	1000                	addi	s0,sp,32
    80002ca2:	84aa                	mv	s1,a0
    80002ca4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	fca080e7          	jalr	-54(ra) # 80001c70 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cae:	713c                	ld	a5,96(a0)
    80002cb0:	02f4f863          	bgeu	s1,a5,80002ce0 <fetchaddr+0x4a>
    80002cb4:	00848713          	addi	a4,s1,8
    80002cb8:	02e7e663          	bltu	a5,a4,80002ce4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cbc:	46a1                	li	a3,8
    80002cbe:	8626                	mv	a2,s1
    80002cc0:	85ca                	mv	a1,s2
    80002cc2:	7528                	ld	a0,104(a0)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	a3a080e7          	jalr	-1478(ra) # 800016fe <copyin>
    80002ccc:	00a03533          	snez	a0,a0
    80002cd0:	40a00533          	neg	a0,a0
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	64a2                	ld	s1,8(sp)
    80002cda:	6902                	ld	s2,0(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret
    return -1;
    80002ce0:	557d                	li	a0,-1
    80002ce2:	bfcd                	j	80002cd4 <fetchaddr+0x3e>
    80002ce4:	557d                	li	a0,-1
    80002ce6:	b7fd                	j	80002cd4 <fetchaddr+0x3e>

0000000080002ce8 <fetchstr>:
{
    80002ce8:	7179                	addi	sp,sp,-48
    80002cea:	f406                	sd	ra,40(sp)
    80002cec:	f022                	sd	s0,32(sp)
    80002cee:	ec26                	sd	s1,24(sp)
    80002cf0:	e84a                	sd	s2,16(sp)
    80002cf2:	e44e                	sd	s3,8(sp)
    80002cf4:	1800                	addi	s0,sp,48
    80002cf6:	892a                	mv	s2,a0
    80002cf8:	84ae                	mv	s1,a1
    80002cfa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	f74080e7          	jalr	-140(ra) # 80001c70 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d04:	86ce                	mv	a3,s3
    80002d06:	864a                	mv	a2,s2
    80002d08:	85a6                	mv	a1,s1
    80002d0a:	7528                	ld	a0,104(a0)
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	a7e080e7          	jalr	-1410(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d14:	00054763          	bltz	a0,80002d22 <fetchstr+0x3a>
  return strlen(buf);
    80002d18:	8526                	mv	a0,s1
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	14a080e7          	jalr	330(ra) # 80000e64 <strlen>
}
    80002d22:	70a2                	ld	ra,40(sp)
    80002d24:	7402                	ld	s0,32(sp)
    80002d26:	64e2                	ld	s1,24(sp)
    80002d28:	6942                	ld	s2,16(sp)
    80002d2a:	69a2                	ld	s3,8(sp)
    80002d2c:	6145                	addi	sp,sp,48
    80002d2e:	8082                	ret

0000000080002d30 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	1000                	addi	s0,sp,32
    80002d3a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	ef2080e7          	jalr	-270(ra) # 80002c2e <argraw>
    80002d44:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d46:	4501                	li	a0,0
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	ed0080e7          	jalr	-304(ra) # 80002c2e <argraw>
    80002d66:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d68:	4501                	li	a0,0
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6105                	addi	sp,sp,32
    80002d72:	8082                	ret

0000000080002d74 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	e426                	sd	s1,8(sp)
    80002d7c:	e04a                	sd	s2,0(sp)
    80002d7e:	1000                	addi	s0,sp,32
    80002d80:	84ae                	mv	s1,a1
    80002d82:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	eaa080e7          	jalr	-342(ra) # 80002c2e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d8c:	864a                	mv	a2,s2
    80002d8e:	85a6                	mv	a1,s1
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	f58080e7          	jalr	-168(ra) # 80002ce8 <fetchstr>
}
    80002d98:	60e2                	ld	ra,24(sp)
    80002d9a:	6442                	ld	s0,16(sp)
    80002d9c:	64a2                	ld	s1,8(sp)
    80002d9e:	6902                	ld	s2,0(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	e04a                	sd	s2,0(sp)
    80002dae:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	ec0080e7          	jalr	-320(ra) # 80001c70 <myproc>
    80002db8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dba:	07053903          	ld	s2,112(a0)
    80002dbe:	0a893783          	ld	a5,168(s2)
    80002dc2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dc6:	37fd                	addiw	a5,a5,-1
    80002dc8:	475d                	li	a4,23
    80002dca:	00f76f63          	bltu	a4,a5,80002de8 <syscall+0x44>
    80002dce:	00369713          	slli	a4,a3,0x3
    80002dd2:	00005797          	auipc	a5,0x5
    80002dd6:	71678793          	addi	a5,a5,1814 # 800084e8 <syscalls>
    80002dda:	97ba                	add	a5,a5,a4
    80002ddc:	639c                	ld	a5,0(a5)
    80002dde:	c789                	beqz	a5,80002de8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002de0:	9782                	jalr	a5
    80002de2:	06a93823          	sd	a0,112(s2)
    80002de6:	a839                	j	80002e04 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002de8:	17048613          	addi	a2,s1,368
    80002dec:	588c                	lw	a1,48(s1)
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	6c250513          	addi	a0,a0,1730 # 800084b0 <states.1745+0x150>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	792080e7          	jalr	1938(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dfe:	78bc                	ld	a5,112(s1)
    80002e00:	577d                	li	a4,-1
    80002e02:	fbb8                	sd	a4,112(a5)
  }
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6902                	ld	s2,0(sp)
    80002e0c:	6105                	addi	sp,sp,32
    80002e0e:	8082                	ret

0000000080002e10 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e18:	fec40593          	addi	a1,s0,-20
    80002e1c:	4501                	li	a0,0
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	f12080e7          	jalr	-238(ra) # 80002d30 <argint>
    return -1;
    80002e26:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e28:	00054963          	bltz	a0,80002e3a <sys_exit+0x2a>
  exit(n);
    80002e2c:	fec42503          	lw	a0,-20(s0)
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	72c080e7          	jalr	1836(ra) # 8000255c <exit>
  return 0;  // not reached
    80002e38:	4781                	li	a5,0
}
    80002e3a:	853e                	mv	a0,a5
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e44:	1141                	addi	sp,sp,-16
    80002e46:	e406                	sd	ra,8(sp)
    80002e48:	e022                	sd	s0,0(sp)
    80002e4a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	e24080e7          	jalr	-476(ra) # 80001c70 <myproc>
}
    80002e54:	5908                	lw	a0,48(a0)
    80002e56:	60a2                	ld	ra,8(sp)
    80002e58:	6402                	ld	s0,0(sp)
    80002e5a:	0141                	addi	sp,sp,16
    80002e5c:	8082                	ret

0000000080002e5e <sys_fork>:

uint64
sys_fork(void)
{
    80002e5e:	1141                	addi	sp,sp,-16
    80002e60:	e406                	sd	ra,8(sp)
    80002e62:	e022                	sd	s0,0(sp)
    80002e64:	0800                	addi	s0,sp,16
  return fork();
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	20e080e7          	jalr	526(ra) # 80002074 <fork>
}
    80002e6e:	60a2                	ld	ra,8(sp)
    80002e70:	6402                	ld	s0,0(sp)
    80002e72:	0141                	addi	sp,sp,16
    80002e74:	8082                	ret

0000000080002e76 <sys_wait>:

uint64
sys_wait(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e7e:	fe840593          	addi	a1,s0,-24
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	ece080e7          	jalr	-306(ra) # 80002d52 <argaddr>
    80002e8c:	87aa                	mv	a5,a0
    return -1;
    80002e8e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e90:	0007c863          	bltz	a5,80002ea0 <sys_wait+0x2a>
  return wait(p);
    80002e94:	fe843503          	ld	a0,-24(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	4cc080e7          	jalr	1228(ra) # 80002364 <wait>
}
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_print_stats>:

void
sys_print_stats(void)
{
    80002ea8:	1141                	addi	sp,sp,-16
    80002eaa:	e406                	sd	ra,8(sp)
    80002eac:	e022                	sd	s0,0(sp)
    80002eae:	0800                	addi	s0,sp,16
  return print_stats();
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	b18080e7          	jalr	-1256(ra) # 800019c8 <print_stats>
}
    80002eb8:	60a2                	ld	ra,8(sp)
    80002eba:	6402                	ld	s0,0(sp)
    80002ebc:	0141                	addi	sp,sp,16
    80002ebe:	8082                	ret

0000000080002ec0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ec0:	7179                	addi	sp,sp,-48
    80002ec2:	f406                	sd	ra,40(sp)
    80002ec4:	f022                	sd	s0,32(sp)
    80002ec6:	ec26                	sd	s1,24(sp)
    80002ec8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002eca:	fdc40593          	addi	a1,s0,-36
    80002ece:	4501                	li	a0,0
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	e60080e7          	jalr	-416(ra) # 80002d30 <argint>
    80002ed8:	87aa                	mv	a5,a0
    return -1;
    80002eda:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002edc:	0207c063          	bltz	a5,80002efc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	d90080e7          	jalr	-624(ra) # 80001c70 <myproc>
    80002ee8:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80002eea:	fdc42503          	lw	a0,-36(s0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	112080e7          	jalr	274(ra) # 80002000 <growproc>
    80002ef6:	00054863          	bltz	a0,80002f06 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002efa:	8526                	mv	a0,s1
}
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6145                	addi	sp,sp,48
    80002f04:	8082                	ret
    return -1;
    80002f06:	557d                	li	a0,-1
    80002f08:	bfd5                	j	80002efc <sys_sbrk+0x3c>

0000000080002f0a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f0a:	7139                	addi	sp,sp,-64
    80002f0c:	fc06                	sd	ra,56(sp)
    80002f0e:	f822                	sd	s0,48(sp)
    80002f10:	f426                	sd	s1,40(sp)
    80002f12:	f04a                	sd	s2,32(sp)
    80002f14:	ec4e                	sd	s3,24(sp)
    80002f16:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f18:	fcc40593          	addi	a1,s0,-52
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	e12080e7          	jalr	-494(ra) # 80002d30 <argint>
    return -1;
    80002f26:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f28:	06054563          	bltz	a0,80002f92 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f2c:	00014517          	auipc	a0,0x14
    80002f30:	7c450513          	addi	a0,a0,1988 # 800176f0 <tickslock>
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f3c:	00006917          	auipc	s2,0x6
    80002f40:	11492903          	lw	s2,276(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002f44:	fcc42783          	lw	a5,-52(s0)
    80002f48:	cf85                	beqz	a5,80002f80 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f4a:	00014997          	auipc	s3,0x14
    80002f4e:	7a698993          	addi	s3,s3,1958 # 800176f0 <tickslock>
    80002f52:	00006497          	auipc	s1,0x6
    80002f56:	0fe48493          	addi	s1,s1,254 # 80009050 <ticks>
    if(myproc()->killed){
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	d16080e7          	jalr	-746(ra) # 80001c70 <myproc>
    80002f62:	551c                	lw	a5,40(a0)
    80002f64:	ef9d                	bnez	a5,80002fa2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f66:	85ce                	mv	a1,s3
    80002f68:	8526                	mv	a0,s1
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	386080e7          	jalr	902(ra) # 800022f0 <sleep>
  while(ticks - ticks0 < n){
    80002f72:	409c                	lw	a5,0(s1)
    80002f74:	412787bb          	subw	a5,a5,s2
    80002f78:	fcc42703          	lw	a4,-52(s0)
    80002f7c:	fce7efe3          	bltu	a5,a4,80002f5a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f80:	00014517          	auipc	a0,0x14
    80002f84:	77050513          	addi	a0,a0,1904 # 800176f0 <tickslock>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	d10080e7          	jalr	-752(ra) # 80000c98 <release>
  return 0;
    80002f90:	4781                	li	a5,0
}
    80002f92:	853e                	mv	a0,a5
    80002f94:	70e2                	ld	ra,56(sp)
    80002f96:	7442                	ld	s0,48(sp)
    80002f98:	74a2                	ld	s1,40(sp)
    80002f9a:	7902                	ld	s2,32(sp)
    80002f9c:	69e2                	ld	s3,24(sp)
    80002f9e:	6121                	addi	sp,sp,64
    80002fa0:	8082                	ret
      release(&tickslock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	74e50513          	addi	a0,a0,1870 # 800176f0 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	cee080e7          	jalr	-786(ra) # 80000c98 <release>
      return -1;
    80002fb2:	57fd                	li	a5,-1
    80002fb4:	bff9                	j	80002f92 <sys_sleep+0x88>

0000000080002fb6 <sys_kill>:

uint64
sys_kill(void)
{
    80002fb6:	1101                	addi	sp,sp,-32
    80002fb8:	ec06                	sd	ra,24(sp)
    80002fba:	e822                	sd	s0,16(sp)
    80002fbc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fbe:	fec40593          	addi	a1,s0,-20
    80002fc2:	4501                	li	a0,0
    80002fc4:	00000097          	auipc	ra,0x0
    80002fc8:	d6c080e7          	jalr	-660(ra) # 80002d30 <argint>
    80002fcc:	87aa                	mv	a5,a0
    return -1;
    80002fce:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fd0:	0007c863          	bltz	a5,80002fe0 <sys_kill+0x2a>
  return kill(pid);
    80002fd4:	fec42503          	lw	a0,-20(s0)
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	8fc080e7          	jalr	-1796(ra) # 800018d4 <kill>
}
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret

0000000080002fe8 <sys_kill_sys>:

uint64
sys_kill_sys(void)
{
    80002fe8:	1141                	addi	sp,sp,-16
    80002fea:	e406                	sd	ra,8(sp)
    80002fec:	e022                	sd	s0,0(sp)
    80002fee:	0800                	addi	s0,sp,16
  return kill_sys();
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	956080e7          	jalr	-1706(ra) # 80001946 <kill_sys>
}
    80002ff8:	60a2                	ld	ra,8(sp)
    80002ffa:	6402                	ld	s0,0(sp)
    80002ffc:	0141                	addi	sp,sp,16
    80002ffe:	8082                	ret

0000000080003000 <sys_pause_sys>:


uint64
sys_pause_sys(void)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80003008:	fec40593          	addi	a1,s0,-20
    8000300c:	4501                	li	a0,0
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	d22080e7          	jalr	-734(ra) # 80002d30 <argint>
    80003016:	87aa                	mv	a5,a0
    return -1;
    80003018:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    8000301a:	0007c863          	bltz	a5,8000302a <sys_pause_sys+0x2a>
  return pause_sys(time);
    8000301e:	fec42503          	lw	a0,-20(s0)
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	298080e7          	jalr	664(ra) # 800022ba <pause_sys>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret

0000000080003032 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000303c:	00014517          	auipc	a0,0x14
    80003040:	6b450513          	addi	a0,a0,1716 # 800176f0 <tickslock>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000304c:	00006497          	auipc	s1,0x6
    80003050:	0044a483          	lw	s1,4(s1) # 80009050 <ticks>
  release(&tickslock);
    80003054:	00014517          	auipc	a0,0x14
    80003058:	69c50513          	addi	a0,a0,1692 # 800176f0 <tickslock>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	c3c080e7          	jalr	-964(ra) # 80000c98 <release>
  return xticks;
}
    80003064:	02049513          	slli	a0,s1,0x20
    80003068:	9101                	srli	a0,a0,0x20
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	addi	sp,sp,32
    80003072:	8082                	ret

0000000080003074 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003074:	7179                	addi	sp,sp,-48
    80003076:	f406                	sd	ra,40(sp)
    80003078:	f022                	sd	s0,32(sp)
    8000307a:	ec26                	sd	s1,24(sp)
    8000307c:	e84a                	sd	s2,16(sp)
    8000307e:	e44e                	sd	s3,8(sp)
    80003080:	e052                	sd	s4,0(sp)
    80003082:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003084:	00005597          	auipc	a1,0x5
    80003088:	52c58593          	addi	a1,a1,1324 # 800085b0 <syscalls+0xc8>
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	67c50513          	addi	a0,a0,1660 # 80017708 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	ac0080e7          	jalr	-1344(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000309c:	0001c797          	auipc	a5,0x1c
    800030a0:	66c78793          	addi	a5,a5,1644 # 8001f708 <bcache+0x8000>
    800030a4:	0001d717          	auipc	a4,0x1d
    800030a8:	8cc70713          	addi	a4,a4,-1844 # 8001f970 <bcache+0x8268>
    800030ac:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030b0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b4:	00014497          	auipc	s1,0x14
    800030b8:	66c48493          	addi	s1,s1,1644 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    800030bc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030be:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030c0:	00005a17          	auipc	s4,0x5
    800030c4:	4f8a0a13          	addi	s4,s4,1272 # 800085b8 <syscalls+0xd0>
    b->next = bcache.head.next;
    800030c8:	2b893783          	ld	a5,696(s2)
    800030cc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030ce:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030d2:	85d2                	mv	a1,s4
    800030d4:	01048513          	addi	a0,s1,16
    800030d8:	00001097          	auipc	ra,0x1
    800030dc:	4bc080e7          	jalr	1212(ra) # 80004594 <initsleeplock>
    bcache.head.next->prev = b;
    800030e0:	2b893783          	ld	a5,696(s2)
    800030e4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030e6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ea:	45848493          	addi	s1,s1,1112
    800030ee:	fd349de3          	bne	s1,s3,800030c8 <binit+0x54>
  }
}
    800030f2:	70a2                	ld	ra,40(sp)
    800030f4:	7402                	ld	s0,32(sp)
    800030f6:	64e2                	ld	s1,24(sp)
    800030f8:	6942                	ld	s2,16(sp)
    800030fa:	69a2                	ld	s3,8(sp)
    800030fc:	6a02                	ld	s4,0(sp)
    800030fe:	6145                	addi	sp,sp,48
    80003100:	8082                	ret

0000000080003102 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003102:	7179                	addi	sp,sp,-48
    80003104:	f406                	sd	ra,40(sp)
    80003106:	f022                	sd	s0,32(sp)
    80003108:	ec26                	sd	s1,24(sp)
    8000310a:	e84a                	sd	s2,16(sp)
    8000310c:	e44e                	sd	s3,8(sp)
    8000310e:	1800                	addi	s0,sp,48
    80003110:	89aa                	mv	s3,a0
    80003112:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	5f450513          	addi	a0,a0,1524 # 80017708 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003124:	0001d497          	auipc	s1,0x1d
    80003128:	89c4b483          	ld	s1,-1892(s1) # 8001f9c0 <bcache+0x82b8>
    8000312c:	0001d797          	auipc	a5,0x1d
    80003130:	84478793          	addi	a5,a5,-1980 # 8001f970 <bcache+0x8268>
    80003134:	02f48f63          	beq	s1,a5,80003172 <bread+0x70>
    80003138:	873e                	mv	a4,a5
    8000313a:	a021                	j	80003142 <bread+0x40>
    8000313c:	68a4                	ld	s1,80(s1)
    8000313e:	02e48a63          	beq	s1,a4,80003172 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003142:	449c                	lw	a5,8(s1)
    80003144:	ff379ce3          	bne	a5,s3,8000313c <bread+0x3a>
    80003148:	44dc                	lw	a5,12(s1)
    8000314a:	ff2799e3          	bne	a5,s2,8000313c <bread+0x3a>
      b->refcnt++;
    8000314e:	40bc                	lw	a5,64(s1)
    80003150:	2785                	addiw	a5,a5,1
    80003152:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	5b450513          	addi	a0,a0,1460 # 80017708 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b3c080e7          	jalr	-1220(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003164:	01048513          	addi	a0,s1,16
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	466080e7          	jalr	1126(ra) # 800045ce <acquiresleep>
      return b;
    80003170:	a8b9                	j	800031ce <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003172:	0001d497          	auipc	s1,0x1d
    80003176:	8464b483          	ld	s1,-1978(s1) # 8001f9b8 <bcache+0x82b0>
    8000317a:	0001c797          	auipc	a5,0x1c
    8000317e:	7f678793          	addi	a5,a5,2038 # 8001f970 <bcache+0x8268>
    80003182:	00f48863          	beq	s1,a5,80003192 <bread+0x90>
    80003186:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003188:	40bc                	lw	a5,64(s1)
    8000318a:	cf81                	beqz	a5,800031a2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000318c:	64a4                	ld	s1,72(s1)
    8000318e:	fee49de3          	bne	s1,a4,80003188 <bread+0x86>
  panic("bget: no buffers");
    80003192:	00005517          	auipc	a0,0x5
    80003196:	42e50513          	addi	a0,a0,1070 # 800085c0 <syscalls+0xd8>
    8000319a:	ffffd097          	auipc	ra,0xffffd
    8000319e:	3a4080e7          	jalr	932(ra) # 8000053e <panic>
      b->dev = dev;
    800031a2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031a6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031aa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031ae:	4785                	li	a5,1
    800031b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b2:	00014517          	auipc	a0,0x14
    800031b6:	55650513          	addi	a0,a0,1366 # 80017708 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	ade080e7          	jalr	-1314(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031c2:	01048513          	addi	a0,s1,16
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	408080e7          	jalr	1032(ra) # 800045ce <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031ce:	409c                	lw	a5,0(s1)
    800031d0:	cb89                	beqz	a5,800031e2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031d2:	8526                	mv	a0,s1
    800031d4:	70a2                	ld	ra,40(sp)
    800031d6:	7402                	ld	s0,32(sp)
    800031d8:	64e2                	ld	s1,24(sp)
    800031da:	6942                	ld	s2,16(sp)
    800031dc:	69a2                	ld	s3,8(sp)
    800031de:	6145                	addi	sp,sp,48
    800031e0:	8082                	ret
    virtio_disk_rw(b, 0);
    800031e2:	4581                	li	a1,0
    800031e4:	8526                	mv	a0,s1
    800031e6:	00003097          	auipc	ra,0x3
    800031ea:	f10080e7          	jalr	-240(ra) # 800060f6 <virtio_disk_rw>
    b->valid = 1;
    800031ee:	4785                	li	a5,1
    800031f0:	c09c                	sw	a5,0(s1)
  return b;
    800031f2:	b7c5                	j	800031d2 <bread+0xd0>

00000000800031f4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	1000                	addi	s0,sp,32
    800031fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003200:	0541                	addi	a0,a0,16
    80003202:	00001097          	auipc	ra,0x1
    80003206:	466080e7          	jalr	1126(ra) # 80004668 <holdingsleep>
    8000320a:	cd01                	beqz	a0,80003222 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000320c:	4585                	li	a1,1
    8000320e:	8526                	mv	a0,s1
    80003210:	00003097          	auipc	ra,0x3
    80003214:	ee6080e7          	jalr	-282(ra) # 800060f6 <virtio_disk_rw>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret
    panic("bwrite");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	3b650513          	addi	a0,a0,950 # 800085d8 <syscalls+0xf0>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	314080e7          	jalr	788(ra) # 8000053e <panic>

0000000080003232 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	e426                	sd	s1,8(sp)
    8000323a:	e04a                	sd	s2,0(sp)
    8000323c:	1000                	addi	s0,sp,32
    8000323e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003240:	01050913          	addi	s2,a0,16
    80003244:	854a                	mv	a0,s2
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	422080e7          	jalr	1058(ra) # 80004668 <holdingsleep>
    8000324e:	c92d                	beqz	a0,800032c0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003250:	854a                	mv	a0,s2
    80003252:	00001097          	auipc	ra,0x1
    80003256:	3d2080e7          	jalr	978(ra) # 80004624 <releasesleep>

  acquire(&bcache.lock);
    8000325a:	00014517          	auipc	a0,0x14
    8000325e:	4ae50513          	addi	a0,a0,1198 # 80017708 <bcache>
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	982080e7          	jalr	-1662(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000326a:	40bc                	lw	a5,64(s1)
    8000326c:	37fd                	addiw	a5,a5,-1
    8000326e:	0007871b          	sext.w	a4,a5
    80003272:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003274:	eb05                	bnez	a4,800032a4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003276:	68bc                	ld	a5,80(s1)
    80003278:	64b8                	ld	a4,72(s1)
    8000327a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000327c:	64bc                	ld	a5,72(s1)
    8000327e:	68b8                	ld	a4,80(s1)
    80003280:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003282:	0001c797          	auipc	a5,0x1c
    80003286:	48678793          	addi	a5,a5,1158 # 8001f708 <bcache+0x8000>
    8000328a:	2b87b703          	ld	a4,696(a5)
    8000328e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003290:	0001c717          	auipc	a4,0x1c
    80003294:	6e070713          	addi	a4,a4,1760 # 8001f970 <bcache+0x8268>
    80003298:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000329a:	2b87b703          	ld	a4,696(a5)
    8000329e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032a0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032a4:	00014517          	auipc	a0,0x14
    800032a8:	46450513          	addi	a0,a0,1124 # 80017708 <bcache>
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	9ec080e7          	jalr	-1556(ra) # 80000c98 <release>
}
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	64a2                	ld	s1,8(sp)
    800032ba:	6902                	ld	s2,0(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret
    panic("brelse");
    800032c0:	00005517          	auipc	a0,0x5
    800032c4:	32050513          	addi	a0,a0,800 # 800085e0 <syscalls+0xf8>
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	276080e7          	jalr	630(ra) # 8000053e <panic>

00000000800032d0 <bpin>:

void
bpin(struct buf *b) {
    800032d0:	1101                	addi	sp,sp,-32
    800032d2:	ec06                	sd	ra,24(sp)
    800032d4:	e822                	sd	s0,16(sp)
    800032d6:	e426                	sd	s1,8(sp)
    800032d8:	1000                	addi	s0,sp,32
    800032da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032dc:	00014517          	auipc	a0,0x14
    800032e0:	42c50513          	addi	a0,a0,1068 # 80017708 <bcache>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	900080e7          	jalr	-1792(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032ec:	40bc                	lw	a5,64(s1)
    800032ee:	2785                	addiw	a5,a5,1
    800032f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f2:	00014517          	auipc	a0,0x14
    800032f6:	41650513          	addi	a0,a0,1046 # 80017708 <bcache>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	99e080e7          	jalr	-1634(ra) # 80000c98 <release>
}
    80003302:	60e2                	ld	ra,24(sp)
    80003304:	6442                	ld	s0,16(sp)
    80003306:	64a2                	ld	s1,8(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret

000000008000330c <bunpin>:

void
bunpin(struct buf *b) {
    8000330c:	1101                	addi	sp,sp,-32
    8000330e:	ec06                	sd	ra,24(sp)
    80003310:	e822                	sd	s0,16(sp)
    80003312:	e426                	sd	s1,8(sp)
    80003314:	1000                	addi	s0,sp,32
    80003316:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003318:	00014517          	auipc	a0,0x14
    8000331c:	3f050513          	addi	a0,a0,1008 # 80017708 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003328:	40bc                	lw	a5,64(s1)
    8000332a:	37fd                	addiw	a5,a5,-1
    8000332c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000332e:	00014517          	auipc	a0,0x14
    80003332:	3da50513          	addi	a0,a0,986 # 80017708 <bcache>
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret

0000000080003348 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003348:	1101                	addi	sp,sp,-32
    8000334a:	ec06                	sd	ra,24(sp)
    8000334c:	e822                	sd	s0,16(sp)
    8000334e:	e426                	sd	s1,8(sp)
    80003350:	e04a                	sd	s2,0(sp)
    80003352:	1000                	addi	s0,sp,32
    80003354:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003356:	00d5d59b          	srliw	a1,a1,0xd
    8000335a:	0001d797          	auipc	a5,0x1d
    8000335e:	a8a7a783          	lw	a5,-1398(a5) # 8001fde4 <sb+0x1c>
    80003362:	9dbd                	addw	a1,a1,a5
    80003364:	00000097          	auipc	ra,0x0
    80003368:	d9e080e7          	jalr	-610(ra) # 80003102 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000336c:	0074f713          	andi	a4,s1,7
    80003370:	4785                	li	a5,1
    80003372:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003376:	14ce                	slli	s1,s1,0x33
    80003378:	90d9                	srli	s1,s1,0x36
    8000337a:	00950733          	add	a4,a0,s1
    8000337e:	05874703          	lbu	a4,88(a4)
    80003382:	00e7f6b3          	and	a3,a5,a4
    80003386:	c69d                	beqz	a3,800033b4 <bfree+0x6c>
    80003388:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000338a:	94aa                	add	s1,s1,a0
    8000338c:	fff7c793          	not	a5,a5
    80003390:	8ff9                	and	a5,a5,a4
    80003392:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003396:	00001097          	auipc	ra,0x1
    8000339a:	118080e7          	jalr	280(ra) # 800044ae <log_write>
  brelse(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	e92080e7          	jalr	-366(ra) # 80003232 <brelse>
}
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	64a2                	ld	s1,8(sp)
    800033ae:	6902                	ld	s2,0(sp)
    800033b0:	6105                	addi	sp,sp,32
    800033b2:	8082                	ret
    panic("freeing free block");
    800033b4:	00005517          	auipc	a0,0x5
    800033b8:	23450513          	addi	a0,a0,564 # 800085e8 <syscalls+0x100>
    800033bc:	ffffd097          	auipc	ra,0xffffd
    800033c0:	182080e7          	jalr	386(ra) # 8000053e <panic>

00000000800033c4 <balloc>:
{
    800033c4:	711d                	addi	sp,sp,-96
    800033c6:	ec86                	sd	ra,88(sp)
    800033c8:	e8a2                	sd	s0,80(sp)
    800033ca:	e4a6                	sd	s1,72(sp)
    800033cc:	e0ca                	sd	s2,64(sp)
    800033ce:	fc4e                	sd	s3,56(sp)
    800033d0:	f852                	sd	s4,48(sp)
    800033d2:	f456                	sd	s5,40(sp)
    800033d4:	f05a                	sd	s6,32(sp)
    800033d6:	ec5e                	sd	s7,24(sp)
    800033d8:	e862                	sd	s8,16(sp)
    800033da:	e466                	sd	s9,8(sp)
    800033dc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033de:	0001d797          	auipc	a5,0x1d
    800033e2:	9ee7a783          	lw	a5,-1554(a5) # 8001fdcc <sb+0x4>
    800033e6:	cbd1                	beqz	a5,8000347a <balloc+0xb6>
    800033e8:	8baa                	mv	s7,a0
    800033ea:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033ec:	0001db17          	auipc	s6,0x1d
    800033f0:	9dcb0b13          	addi	s6,s6,-1572 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033f6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033fa:	6c89                	lui	s9,0x2
    800033fc:	a831                	j	80003418 <balloc+0x54>
    brelse(bp);
    800033fe:	854a                	mv	a0,s2
    80003400:	00000097          	auipc	ra,0x0
    80003404:	e32080e7          	jalr	-462(ra) # 80003232 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003408:	015c87bb          	addw	a5,s9,s5
    8000340c:	00078a9b          	sext.w	s5,a5
    80003410:	004b2703          	lw	a4,4(s6)
    80003414:	06eaf363          	bgeu	s5,a4,8000347a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003418:	41fad79b          	sraiw	a5,s5,0x1f
    8000341c:	0137d79b          	srliw	a5,a5,0x13
    80003420:	015787bb          	addw	a5,a5,s5
    80003424:	40d7d79b          	sraiw	a5,a5,0xd
    80003428:	01cb2583          	lw	a1,28(s6)
    8000342c:	9dbd                	addw	a1,a1,a5
    8000342e:	855e                	mv	a0,s7
    80003430:	00000097          	auipc	ra,0x0
    80003434:	cd2080e7          	jalr	-814(ra) # 80003102 <bread>
    80003438:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343a:	004b2503          	lw	a0,4(s6)
    8000343e:	000a849b          	sext.w	s1,s5
    80003442:	8662                	mv	a2,s8
    80003444:	faa4fde3          	bgeu	s1,a0,800033fe <balloc+0x3a>
      m = 1 << (bi % 8);
    80003448:	41f6579b          	sraiw	a5,a2,0x1f
    8000344c:	01d7d69b          	srliw	a3,a5,0x1d
    80003450:	00c6873b          	addw	a4,a3,a2
    80003454:	00777793          	andi	a5,a4,7
    80003458:	9f95                	subw	a5,a5,a3
    8000345a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000345e:	4037571b          	sraiw	a4,a4,0x3
    80003462:	00e906b3          	add	a3,s2,a4
    80003466:	0586c683          	lbu	a3,88(a3)
    8000346a:	00d7f5b3          	and	a1,a5,a3
    8000346e:	cd91                	beqz	a1,8000348a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003470:	2605                	addiw	a2,a2,1
    80003472:	2485                	addiw	s1,s1,1
    80003474:	fd4618e3          	bne	a2,s4,80003444 <balloc+0x80>
    80003478:	b759                	j	800033fe <balloc+0x3a>
  panic("balloc: out of blocks");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	18650513          	addi	a0,a0,390 # 80008600 <syscalls+0x118>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000348a:	974a                	add	a4,a4,s2
    8000348c:	8fd5                	or	a5,a5,a3
    8000348e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003492:	854a                	mv	a0,s2
    80003494:	00001097          	auipc	ra,0x1
    80003498:	01a080e7          	jalr	26(ra) # 800044ae <log_write>
        brelse(bp);
    8000349c:	854a                	mv	a0,s2
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	d94080e7          	jalr	-620(ra) # 80003232 <brelse>
  bp = bread(dev, bno);
    800034a6:	85a6                	mv	a1,s1
    800034a8:	855e                	mv	a0,s7
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	c58080e7          	jalr	-936(ra) # 80003102 <bread>
    800034b2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034b4:	40000613          	li	a2,1024
    800034b8:	4581                	li	a1,0
    800034ba:	05850513          	addi	a0,a0,88
    800034be:	ffffe097          	auipc	ra,0xffffe
    800034c2:	822080e7          	jalr	-2014(ra) # 80000ce0 <memset>
  log_write(bp);
    800034c6:	854a                	mv	a0,s2
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	fe6080e7          	jalr	-26(ra) # 800044ae <log_write>
  brelse(bp);
    800034d0:	854a                	mv	a0,s2
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	d60080e7          	jalr	-672(ra) # 80003232 <brelse>
}
    800034da:	8526                	mv	a0,s1
    800034dc:	60e6                	ld	ra,88(sp)
    800034de:	6446                	ld	s0,80(sp)
    800034e0:	64a6                	ld	s1,72(sp)
    800034e2:	6906                	ld	s2,64(sp)
    800034e4:	79e2                	ld	s3,56(sp)
    800034e6:	7a42                	ld	s4,48(sp)
    800034e8:	7aa2                	ld	s5,40(sp)
    800034ea:	7b02                	ld	s6,32(sp)
    800034ec:	6be2                	ld	s7,24(sp)
    800034ee:	6c42                	ld	s8,16(sp)
    800034f0:	6ca2                	ld	s9,8(sp)
    800034f2:	6125                	addi	sp,sp,96
    800034f4:	8082                	ret

00000000800034f6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034f6:	7179                	addi	sp,sp,-48
    800034f8:	f406                	sd	ra,40(sp)
    800034fa:	f022                	sd	s0,32(sp)
    800034fc:	ec26                	sd	s1,24(sp)
    800034fe:	e84a                	sd	s2,16(sp)
    80003500:	e44e                	sd	s3,8(sp)
    80003502:	e052                	sd	s4,0(sp)
    80003504:	1800                	addi	s0,sp,48
    80003506:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003508:	47ad                	li	a5,11
    8000350a:	04b7fe63          	bgeu	a5,a1,80003566 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000350e:	ff45849b          	addiw	s1,a1,-12
    80003512:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003516:	0ff00793          	li	a5,255
    8000351a:	0ae7e363          	bltu	a5,a4,800035c0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000351e:	08052583          	lw	a1,128(a0)
    80003522:	c5ad                	beqz	a1,8000358c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003524:	00092503          	lw	a0,0(s2)
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	bda080e7          	jalr	-1062(ra) # 80003102 <bread>
    80003530:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003532:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003536:	02049593          	slli	a1,s1,0x20
    8000353a:	9181                	srli	a1,a1,0x20
    8000353c:	058a                	slli	a1,a1,0x2
    8000353e:	00b784b3          	add	s1,a5,a1
    80003542:	0004a983          	lw	s3,0(s1)
    80003546:	04098d63          	beqz	s3,800035a0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000354a:	8552                	mv	a0,s4
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	ce6080e7          	jalr	-794(ra) # 80003232 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003554:	854e                	mv	a0,s3
    80003556:	70a2                	ld	ra,40(sp)
    80003558:	7402                	ld	s0,32(sp)
    8000355a:	64e2                	ld	s1,24(sp)
    8000355c:	6942                	ld	s2,16(sp)
    8000355e:	69a2                	ld	s3,8(sp)
    80003560:	6a02                	ld	s4,0(sp)
    80003562:	6145                	addi	sp,sp,48
    80003564:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003566:	02059493          	slli	s1,a1,0x20
    8000356a:	9081                	srli	s1,s1,0x20
    8000356c:	048a                	slli	s1,s1,0x2
    8000356e:	94aa                	add	s1,s1,a0
    80003570:	0504a983          	lw	s3,80(s1)
    80003574:	fe0990e3          	bnez	s3,80003554 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003578:	4108                	lw	a0,0(a0)
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	e4a080e7          	jalr	-438(ra) # 800033c4 <balloc>
    80003582:	0005099b          	sext.w	s3,a0
    80003586:	0534a823          	sw	s3,80(s1)
    8000358a:	b7e9                	j	80003554 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000358c:	4108                	lw	a0,0(a0)
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	e36080e7          	jalr	-458(ra) # 800033c4 <balloc>
    80003596:	0005059b          	sext.w	a1,a0
    8000359a:	08b92023          	sw	a1,128(s2)
    8000359e:	b759                	j	80003524 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035a0:	00092503          	lw	a0,0(s2)
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	e20080e7          	jalr	-480(ra) # 800033c4 <balloc>
    800035ac:	0005099b          	sext.w	s3,a0
    800035b0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035b4:	8552                	mv	a0,s4
    800035b6:	00001097          	auipc	ra,0x1
    800035ba:	ef8080e7          	jalr	-264(ra) # 800044ae <log_write>
    800035be:	b771                	j	8000354a <bmap+0x54>
  panic("bmap: out of range");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	05850513          	addi	a0,a0,88 # 80008618 <syscalls+0x130>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>

00000000800035d0 <iget>:
{
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	e84a                	sd	s2,16(sp)
    800035da:	e44e                	sd	s3,8(sp)
    800035dc:	e052                	sd	s4,0(sp)
    800035de:	1800                	addi	s0,sp,48
    800035e0:	89aa                	mv	s3,a0
    800035e2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035e4:	0001d517          	auipc	a0,0x1d
    800035e8:	80450513          	addi	a0,a0,-2044 # 8001fde8 <itable>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	5f8080e7          	jalr	1528(ra) # 80000be4 <acquire>
  empty = 0;
    800035f4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035f6:	0001d497          	auipc	s1,0x1d
    800035fa:	80a48493          	addi	s1,s1,-2038 # 8001fe00 <itable+0x18>
    800035fe:	0001e697          	auipc	a3,0x1e
    80003602:	29268693          	addi	a3,a3,658 # 80021890 <log>
    80003606:	a039                	j	80003614 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003608:	02090b63          	beqz	s2,8000363e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000360c:	08848493          	addi	s1,s1,136
    80003610:	02d48a63          	beq	s1,a3,80003644 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003614:	449c                	lw	a5,8(s1)
    80003616:	fef059e3          	blez	a5,80003608 <iget+0x38>
    8000361a:	4098                	lw	a4,0(s1)
    8000361c:	ff3716e3          	bne	a4,s3,80003608 <iget+0x38>
    80003620:	40d8                	lw	a4,4(s1)
    80003622:	ff4713e3          	bne	a4,s4,80003608 <iget+0x38>
      ip->ref++;
    80003626:	2785                	addiw	a5,a5,1
    80003628:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000362a:	0001c517          	auipc	a0,0x1c
    8000362e:	7be50513          	addi	a0,a0,1982 # 8001fde8 <itable>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
      return ip;
    8000363a:	8926                	mv	s2,s1
    8000363c:	a03d                	j	8000366a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363e:	f7f9                	bnez	a5,8000360c <iget+0x3c>
    80003640:	8926                	mv	s2,s1
    80003642:	b7e9                	j	8000360c <iget+0x3c>
  if(empty == 0)
    80003644:	02090c63          	beqz	s2,8000367c <iget+0xac>
  ip->dev = dev;
    80003648:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000364c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003650:	4785                	li	a5,1
    80003652:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003656:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000365a:	0001c517          	auipc	a0,0x1c
    8000365e:	78e50513          	addi	a0,a0,1934 # 8001fde8 <itable>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
}
    8000366a:	854a                	mv	a0,s2
    8000366c:	70a2                	ld	ra,40(sp)
    8000366e:	7402                	ld	s0,32(sp)
    80003670:	64e2                	ld	s1,24(sp)
    80003672:	6942                	ld	s2,16(sp)
    80003674:	69a2                	ld	s3,8(sp)
    80003676:	6a02                	ld	s4,0(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
    panic("iget: no inodes");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	fb450513          	addi	a0,a0,-76 # 80008630 <syscalls+0x148>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>

000000008000368c <fsinit>:
fsinit(int dev) {
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	1800                	addi	s0,sp,48
    8000369a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000369c:	4585                	li	a1,1
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	a64080e7          	jalr	-1436(ra) # 80003102 <bread>
    800036a6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036a8:	0001c997          	auipc	s3,0x1c
    800036ac:	72098993          	addi	s3,s3,1824 # 8001fdc8 <sb>
    800036b0:	02000613          	li	a2,32
    800036b4:	05850593          	addi	a1,a0,88
    800036b8:	854e                	mv	a0,s3
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	686080e7          	jalr	1670(ra) # 80000d40 <memmove>
  brelse(bp);
    800036c2:	8526                	mv	a0,s1
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	b6e080e7          	jalr	-1170(ra) # 80003232 <brelse>
  if(sb.magic != FSMAGIC)
    800036cc:	0009a703          	lw	a4,0(s3)
    800036d0:	102037b7          	lui	a5,0x10203
    800036d4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036d8:	02f71263          	bne	a4,a5,800036fc <fsinit+0x70>
  initlog(dev, &sb);
    800036dc:	0001c597          	auipc	a1,0x1c
    800036e0:	6ec58593          	addi	a1,a1,1772 # 8001fdc8 <sb>
    800036e4:	854a                	mv	a0,s2
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	b4c080e7          	jalr	-1204(ra) # 80004232 <initlog>
}
    800036ee:	70a2                	ld	ra,40(sp)
    800036f0:	7402                	ld	s0,32(sp)
    800036f2:	64e2                	ld	s1,24(sp)
    800036f4:	6942                	ld	s2,16(sp)
    800036f6:	69a2                	ld	s3,8(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret
    panic("invalid file system");
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	f4450513          	addi	a0,a0,-188 # 80008640 <syscalls+0x158>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>

000000008000370c <iinit>:
{
    8000370c:	7179                	addi	sp,sp,-48
    8000370e:	f406                	sd	ra,40(sp)
    80003710:	f022                	sd	s0,32(sp)
    80003712:	ec26                	sd	s1,24(sp)
    80003714:	e84a                	sd	s2,16(sp)
    80003716:	e44e                	sd	s3,8(sp)
    80003718:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000371a:	00005597          	auipc	a1,0x5
    8000371e:	f3e58593          	addi	a1,a1,-194 # 80008658 <syscalls+0x170>
    80003722:	0001c517          	auipc	a0,0x1c
    80003726:	6c650513          	addi	a0,a0,1734 # 8001fde8 <itable>
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	42a080e7          	jalr	1066(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003732:	0001c497          	auipc	s1,0x1c
    80003736:	6de48493          	addi	s1,s1,1758 # 8001fe10 <itable+0x28>
    8000373a:	0001e997          	auipc	s3,0x1e
    8000373e:	16698993          	addi	s3,s3,358 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003742:	00005917          	auipc	s2,0x5
    80003746:	f1e90913          	addi	s2,s2,-226 # 80008660 <syscalls+0x178>
    8000374a:	85ca                	mv	a1,s2
    8000374c:	8526                	mv	a0,s1
    8000374e:	00001097          	auipc	ra,0x1
    80003752:	e46080e7          	jalr	-442(ra) # 80004594 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003756:	08848493          	addi	s1,s1,136
    8000375a:	ff3498e3          	bne	s1,s3,8000374a <iinit+0x3e>
}
    8000375e:	70a2                	ld	ra,40(sp)
    80003760:	7402                	ld	s0,32(sp)
    80003762:	64e2                	ld	s1,24(sp)
    80003764:	6942                	ld	s2,16(sp)
    80003766:	69a2                	ld	s3,8(sp)
    80003768:	6145                	addi	sp,sp,48
    8000376a:	8082                	ret

000000008000376c <ialloc>:
{
    8000376c:	715d                	addi	sp,sp,-80
    8000376e:	e486                	sd	ra,72(sp)
    80003770:	e0a2                	sd	s0,64(sp)
    80003772:	fc26                	sd	s1,56(sp)
    80003774:	f84a                	sd	s2,48(sp)
    80003776:	f44e                	sd	s3,40(sp)
    80003778:	f052                	sd	s4,32(sp)
    8000377a:	ec56                	sd	s5,24(sp)
    8000377c:	e85a                	sd	s6,16(sp)
    8000377e:	e45e                	sd	s7,8(sp)
    80003780:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003782:	0001c717          	auipc	a4,0x1c
    80003786:	65272703          	lw	a4,1618(a4) # 8001fdd4 <sb+0xc>
    8000378a:	4785                	li	a5,1
    8000378c:	04e7fa63          	bgeu	a5,a4,800037e0 <ialloc+0x74>
    80003790:	8aaa                	mv	s5,a0
    80003792:	8bae                	mv	s7,a1
    80003794:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003796:	0001ca17          	auipc	s4,0x1c
    8000379a:	632a0a13          	addi	s4,s4,1586 # 8001fdc8 <sb>
    8000379e:	00048b1b          	sext.w	s6,s1
    800037a2:	0044d593          	srli	a1,s1,0x4
    800037a6:	018a2783          	lw	a5,24(s4)
    800037aa:	9dbd                	addw	a1,a1,a5
    800037ac:	8556                	mv	a0,s5
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	954080e7          	jalr	-1708(ra) # 80003102 <bread>
    800037b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037b8:	05850993          	addi	s3,a0,88
    800037bc:	00f4f793          	andi	a5,s1,15
    800037c0:	079a                	slli	a5,a5,0x6
    800037c2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037c4:	00099783          	lh	a5,0(s3)
    800037c8:	c785                	beqz	a5,800037f0 <ialloc+0x84>
    brelse(bp);
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	a68080e7          	jalr	-1432(ra) # 80003232 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037d2:	0485                	addi	s1,s1,1
    800037d4:	00ca2703          	lw	a4,12(s4)
    800037d8:	0004879b          	sext.w	a5,s1
    800037dc:	fce7e1e3          	bltu	a5,a4,8000379e <ialloc+0x32>
  panic("ialloc: no inodes");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	e8850513          	addi	a0,a0,-376 # 80008668 <syscalls+0x180>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037f0:	04000613          	li	a2,64
    800037f4:	4581                	li	a1,0
    800037f6:	854e                	mv	a0,s3
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	4e8080e7          	jalr	1256(ra) # 80000ce0 <memset>
      dip->type = type;
    80003800:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	ca8080e7          	jalr	-856(ra) # 800044ae <log_write>
      brelse(bp);
    8000380e:	854a                	mv	a0,s2
    80003810:	00000097          	auipc	ra,0x0
    80003814:	a22080e7          	jalr	-1502(ra) # 80003232 <brelse>
      return iget(dev, inum);
    80003818:	85da                	mv	a1,s6
    8000381a:	8556                	mv	a0,s5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	db4080e7          	jalr	-588(ra) # 800035d0 <iget>
}
    80003824:	60a6                	ld	ra,72(sp)
    80003826:	6406                	ld	s0,64(sp)
    80003828:	74e2                	ld	s1,56(sp)
    8000382a:	7942                	ld	s2,48(sp)
    8000382c:	79a2                	ld	s3,40(sp)
    8000382e:	7a02                	ld	s4,32(sp)
    80003830:	6ae2                	ld	s5,24(sp)
    80003832:	6b42                	ld	s6,16(sp)
    80003834:	6ba2                	ld	s7,8(sp)
    80003836:	6161                	addi	sp,sp,80
    80003838:	8082                	ret

000000008000383a <iupdate>:
{
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	e04a                	sd	s2,0(sp)
    80003844:	1000                	addi	s0,sp,32
    80003846:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003848:	415c                	lw	a5,4(a0)
    8000384a:	0047d79b          	srliw	a5,a5,0x4
    8000384e:	0001c597          	auipc	a1,0x1c
    80003852:	5925a583          	lw	a1,1426(a1) # 8001fde0 <sb+0x18>
    80003856:	9dbd                	addw	a1,a1,a5
    80003858:	4108                	lw	a0,0(a0)
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	8a8080e7          	jalr	-1880(ra) # 80003102 <bread>
    80003862:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003864:	05850793          	addi	a5,a0,88
    80003868:	40c8                	lw	a0,4(s1)
    8000386a:	893d                	andi	a0,a0,15
    8000386c:	051a                	slli	a0,a0,0x6
    8000386e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003870:	04449703          	lh	a4,68(s1)
    80003874:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003878:	04649703          	lh	a4,70(s1)
    8000387c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003880:	04849703          	lh	a4,72(s1)
    80003884:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003888:	04a49703          	lh	a4,74(s1)
    8000388c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003890:	44f8                	lw	a4,76(s1)
    80003892:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003894:	03400613          	li	a2,52
    80003898:	05048593          	addi	a1,s1,80
    8000389c:	0531                	addi	a0,a0,12
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	4a2080e7          	jalr	1186(ra) # 80000d40 <memmove>
  log_write(bp);
    800038a6:	854a                	mv	a0,s2
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	c06080e7          	jalr	-1018(ra) # 800044ae <log_write>
  brelse(bp);
    800038b0:	854a                	mv	a0,s2
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	980080e7          	jalr	-1664(ra) # 80003232 <brelse>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	64a2                	ld	s1,8(sp)
    800038c0:	6902                	ld	s2,0(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret

00000000800038c6 <idup>:
{
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d2:	0001c517          	auipc	a0,0x1c
    800038d6:	51650513          	addi	a0,a0,1302 # 8001fde8 <itable>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	30a080e7          	jalr	778(ra) # 80000be4 <acquire>
  ip->ref++;
    800038e2:	449c                	lw	a5,8(s1)
    800038e4:	2785                	addiw	a5,a5,1
    800038e6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e8:	0001c517          	auipc	a0,0x1c
    800038ec:	50050513          	addi	a0,a0,1280 # 8001fde8 <itable>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
}
    800038f8:	8526                	mv	a0,s1
    800038fa:	60e2                	ld	ra,24(sp)
    800038fc:	6442                	ld	s0,16(sp)
    800038fe:	64a2                	ld	s1,8(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret

0000000080003904 <ilock>:
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	e04a                	sd	s2,0(sp)
    8000390e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003910:	c115                	beqz	a0,80003934 <ilock+0x30>
    80003912:	84aa                	mv	s1,a0
    80003914:	451c                	lw	a5,8(a0)
    80003916:	00f05f63          	blez	a5,80003934 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000391a:	0541                	addi	a0,a0,16
    8000391c:	00001097          	auipc	ra,0x1
    80003920:	cb2080e7          	jalr	-846(ra) # 800045ce <acquiresleep>
  if(ip->valid == 0){
    80003924:	40bc                	lw	a5,64(s1)
    80003926:	cf99                	beqz	a5,80003944 <ilock+0x40>
}
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6902                	ld	s2,0(sp)
    80003930:	6105                	addi	sp,sp,32
    80003932:	8082                	ret
    panic("ilock");
    80003934:	00005517          	auipc	a0,0x5
    80003938:	d4c50513          	addi	a0,a0,-692 # 80008680 <syscalls+0x198>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	c02080e7          	jalr	-1022(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003944:	40dc                	lw	a5,4(s1)
    80003946:	0047d79b          	srliw	a5,a5,0x4
    8000394a:	0001c597          	auipc	a1,0x1c
    8000394e:	4965a583          	lw	a1,1174(a1) # 8001fde0 <sb+0x18>
    80003952:	9dbd                	addw	a1,a1,a5
    80003954:	4088                	lw	a0,0(s1)
    80003956:	fffff097          	auipc	ra,0xfffff
    8000395a:	7ac080e7          	jalr	1964(ra) # 80003102 <bread>
    8000395e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003960:	05850593          	addi	a1,a0,88
    80003964:	40dc                	lw	a5,4(s1)
    80003966:	8bbd                	andi	a5,a5,15
    80003968:	079a                	slli	a5,a5,0x6
    8000396a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000396c:	00059783          	lh	a5,0(a1)
    80003970:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003974:	00259783          	lh	a5,2(a1)
    80003978:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000397c:	00459783          	lh	a5,4(a1)
    80003980:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003984:	00659783          	lh	a5,6(a1)
    80003988:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000398c:	459c                	lw	a5,8(a1)
    8000398e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003990:	03400613          	li	a2,52
    80003994:	05b1                	addi	a1,a1,12
    80003996:	05048513          	addi	a0,s1,80
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	3a6080e7          	jalr	934(ra) # 80000d40 <memmove>
    brelse(bp);
    800039a2:	854a                	mv	a0,s2
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	88e080e7          	jalr	-1906(ra) # 80003232 <brelse>
    ip->valid = 1;
    800039ac:	4785                	li	a5,1
    800039ae:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039b0:	04449783          	lh	a5,68(s1)
    800039b4:	fbb5                	bnez	a5,80003928 <ilock+0x24>
      panic("ilock: no type");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	cd250513          	addi	a0,a0,-814 # 80008688 <syscalls+0x1a0>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <iunlock>:
{
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	e426                	sd	s1,8(sp)
    800039ce:	e04a                	sd	s2,0(sp)
    800039d0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039d2:	c905                	beqz	a0,80003a02 <iunlock+0x3c>
    800039d4:	84aa                	mv	s1,a0
    800039d6:	01050913          	addi	s2,a0,16
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	c8c080e7          	jalr	-884(ra) # 80004668 <holdingsleep>
    800039e4:	cd19                	beqz	a0,80003a02 <iunlock+0x3c>
    800039e6:	449c                	lw	a5,8(s1)
    800039e8:	00f05d63          	blez	a5,80003a02 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039ec:	854a                	mv	a0,s2
    800039ee:	00001097          	auipc	ra,0x1
    800039f2:	c36080e7          	jalr	-970(ra) # 80004624 <releasesleep>
}
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	64a2                	ld	s1,8(sp)
    800039fc:	6902                	ld	s2,0(sp)
    800039fe:	6105                	addi	sp,sp,32
    80003a00:	8082                	ret
    panic("iunlock");
    80003a02:	00005517          	auipc	a0,0x5
    80003a06:	c9650513          	addi	a0,a0,-874 # 80008698 <syscalls+0x1b0>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080003a12 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a12:	7179                	addi	sp,sp,-48
    80003a14:	f406                	sd	ra,40(sp)
    80003a16:	f022                	sd	s0,32(sp)
    80003a18:	ec26                	sd	s1,24(sp)
    80003a1a:	e84a                	sd	s2,16(sp)
    80003a1c:	e44e                	sd	s3,8(sp)
    80003a1e:	e052                	sd	s4,0(sp)
    80003a20:	1800                	addi	s0,sp,48
    80003a22:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a24:	05050493          	addi	s1,a0,80
    80003a28:	08050913          	addi	s2,a0,128
    80003a2c:	a021                	j	80003a34 <itrunc+0x22>
    80003a2e:	0491                	addi	s1,s1,4
    80003a30:	01248d63          	beq	s1,s2,80003a4a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a34:	408c                	lw	a1,0(s1)
    80003a36:	dde5                	beqz	a1,80003a2e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a38:	0009a503          	lw	a0,0(s3)
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	90c080e7          	jalr	-1780(ra) # 80003348 <bfree>
      ip->addrs[i] = 0;
    80003a44:	0004a023          	sw	zero,0(s1)
    80003a48:	b7dd                	j	80003a2e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a4a:	0809a583          	lw	a1,128(s3)
    80003a4e:	e185                	bnez	a1,80003a6e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a50:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a54:	854e                	mv	a0,s3
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	de4080e7          	jalr	-540(ra) # 8000383a <iupdate>
}
    80003a5e:	70a2                	ld	ra,40(sp)
    80003a60:	7402                	ld	s0,32(sp)
    80003a62:	64e2                	ld	s1,24(sp)
    80003a64:	6942                	ld	s2,16(sp)
    80003a66:	69a2                	ld	s3,8(sp)
    80003a68:	6a02                	ld	s4,0(sp)
    80003a6a:	6145                	addi	sp,sp,48
    80003a6c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a6e:	0009a503          	lw	a0,0(s3)
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	690080e7          	jalr	1680(ra) # 80003102 <bread>
    80003a7a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a7c:	05850493          	addi	s1,a0,88
    80003a80:	45850913          	addi	s2,a0,1112
    80003a84:	a811                	j	80003a98 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a86:	0009a503          	lw	a0,0(s3)
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	8be080e7          	jalr	-1858(ra) # 80003348 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a92:	0491                	addi	s1,s1,4
    80003a94:	01248563          	beq	s1,s2,80003a9e <itrunc+0x8c>
      if(a[j])
    80003a98:	408c                	lw	a1,0(s1)
    80003a9a:	dde5                	beqz	a1,80003a92 <itrunc+0x80>
    80003a9c:	b7ed                	j	80003a86 <itrunc+0x74>
    brelse(bp);
    80003a9e:	8552                	mv	a0,s4
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	792080e7          	jalr	1938(ra) # 80003232 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa8:	0809a583          	lw	a1,128(s3)
    80003aac:	0009a503          	lw	a0,0(s3)
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	898080e7          	jalr	-1896(ra) # 80003348 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab8:	0809a023          	sw	zero,128(s3)
    80003abc:	bf51                	j	80003a50 <itrunc+0x3e>

0000000080003abe <iput>:
{
    80003abe:	1101                	addi	sp,sp,-32
    80003ac0:	ec06                	sd	ra,24(sp)
    80003ac2:	e822                	sd	s0,16(sp)
    80003ac4:	e426                	sd	s1,8(sp)
    80003ac6:	e04a                	sd	s2,0(sp)
    80003ac8:	1000                	addi	s0,sp,32
    80003aca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003acc:	0001c517          	auipc	a0,0x1c
    80003ad0:	31c50513          	addi	a0,a0,796 # 8001fde8 <itable>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	110080e7          	jalr	272(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003adc:	4498                	lw	a4,8(s1)
    80003ade:	4785                	li	a5,1
    80003ae0:	02f70363          	beq	a4,a5,80003b06 <iput+0x48>
  ip->ref--;
    80003ae4:	449c                	lw	a5,8(s1)
    80003ae6:	37fd                	addiw	a5,a5,-1
    80003ae8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aea:	0001c517          	auipc	a0,0x1c
    80003aee:	2fe50513          	addi	a0,a0,766 # 8001fde8 <itable>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	1a6080e7          	jalr	422(ra) # 80000c98 <release>
}
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6902                	ld	s2,0(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b06:	40bc                	lw	a5,64(s1)
    80003b08:	dff1                	beqz	a5,80003ae4 <iput+0x26>
    80003b0a:	04a49783          	lh	a5,74(s1)
    80003b0e:	fbf9                	bnez	a5,80003ae4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b10:	01048913          	addi	s2,s1,16
    80003b14:	854a                	mv	a0,s2
    80003b16:	00001097          	auipc	ra,0x1
    80003b1a:	ab8080e7          	jalr	-1352(ra) # 800045ce <acquiresleep>
    release(&itable.lock);
    80003b1e:	0001c517          	auipc	a0,0x1c
    80003b22:	2ca50513          	addi	a0,a0,714 # 8001fde8 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
    itrunc(ip);
    80003b2e:	8526                	mv	a0,s1
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	ee2080e7          	jalr	-286(ra) # 80003a12 <itrunc>
    ip->type = 0;
    80003b38:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b3c:	8526                	mv	a0,s1
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	cfc080e7          	jalr	-772(ra) # 8000383a <iupdate>
    ip->valid = 0;
    80003b46:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b4a:	854a                	mv	a0,s2
    80003b4c:	00001097          	auipc	ra,0x1
    80003b50:	ad8080e7          	jalr	-1320(ra) # 80004624 <releasesleep>
    acquire(&itable.lock);
    80003b54:	0001c517          	auipc	a0,0x1c
    80003b58:	29450513          	addi	a0,a0,660 # 8001fde8 <itable>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	088080e7          	jalr	136(ra) # 80000be4 <acquire>
    80003b64:	b741                	j	80003ae4 <iput+0x26>

0000000080003b66 <iunlockput>:
{
    80003b66:	1101                	addi	sp,sp,-32
    80003b68:	ec06                	sd	ra,24(sp)
    80003b6a:	e822                	sd	s0,16(sp)
    80003b6c:	e426                	sd	s1,8(sp)
    80003b6e:	1000                	addi	s0,sp,32
    80003b70:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	e54080e7          	jalr	-428(ra) # 800039c6 <iunlock>
  iput(ip);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	f42080e7          	jalr	-190(ra) # 80003abe <iput>
}
    80003b84:	60e2                	ld	ra,24(sp)
    80003b86:	6442                	ld	s0,16(sp)
    80003b88:	64a2                	ld	s1,8(sp)
    80003b8a:	6105                	addi	sp,sp,32
    80003b8c:	8082                	ret

0000000080003b8e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b8e:	1141                	addi	sp,sp,-16
    80003b90:	e422                	sd	s0,8(sp)
    80003b92:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b94:	411c                	lw	a5,0(a0)
    80003b96:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b98:	415c                	lw	a5,4(a0)
    80003b9a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b9c:	04451783          	lh	a5,68(a0)
    80003ba0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ba4:	04a51783          	lh	a5,74(a0)
    80003ba8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bac:	04c56783          	lwu	a5,76(a0)
    80003bb0:	e99c                	sd	a5,16(a1)
}
    80003bb2:	6422                	ld	s0,8(sp)
    80003bb4:	0141                	addi	sp,sp,16
    80003bb6:	8082                	ret

0000000080003bb8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb8:	457c                	lw	a5,76(a0)
    80003bba:	0ed7e963          	bltu	a5,a3,80003cac <readi+0xf4>
{
    80003bbe:	7159                	addi	sp,sp,-112
    80003bc0:	f486                	sd	ra,104(sp)
    80003bc2:	f0a2                	sd	s0,96(sp)
    80003bc4:	eca6                	sd	s1,88(sp)
    80003bc6:	e8ca                	sd	s2,80(sp)
    80003bc8:	e4ce                	sd	s3,72(sp)
    80003bca:	e0d2                	sd	s4,64(sp)
    80003bcc:	fc56                	sd	s5,56(sp)
    80003bce:	f85a                	sd	s6,48(sp)
    80003bd0:	f45e                	sd	s7,40(sp)
    80003bd2:	f062                	sd	s8,32(sp)
    80003bd4:	ec66                	sd	s9,24(sp)
    80003bd6:	e86a                	sd	s10,16(sp)
    80003bd8:	e46e                	sd	s11,8(sp)
    80003bda:	1880                	addi	s0,sp,112
    80003bdc:	8baa                	mv	s7,a0
    80003bde:	8c2e                	mv	s8,a1
    80003be0:	8ab2                	mv	s5,a2
    80003be2:	84b6                	mv	s1,a3
    80003be4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003be6:	9f35                	addw	a4,a4,a3
    return 0;
    80003be8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bea:	0ad76063          	bltu	a4,a3,80003c8a <readi+0xd2>
  if(off + n > ip->size)
    80003bee:	00e7f463          	bgeu	a5,a4,80003bf6 <readi+0x3e>
    n = ip->size - off;
    80003bf2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf6:	0a0b0963          	beqz	s6,80003ca8 <readi+0xf0>
    80003bfa:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c00:	5cfd                	li	s9,-1
    80003c02:	a82d                	j	80003c3c <readi+0x84>
    80003c04:	020a1d93          	slli	s11,s4,0x20
    80003c08:	020ddd93          	srli	s11,s11,0x20
    80003c0c:	05890613          	addi	a2,s2,88
    80003c10:	86ee                	mv	a3,s11
    80003c12:	963a                	add	a2,a2,a4
    80003c14:	85d6                	mv	a1,s5
    80003c16:	8562                	mv	a0,s8
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	acc080e7          	jalr	-1332(ra) # 800026e4 <either_copyout>
    80003c20:	05950d63          	beq	a0,s9,80003c7a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c24:	854a                	mv	a0,s2
    80003c26:	fffff097          	auipc	ra,0xfffff
    80003c2a:	60c080e7          	jalr	1548(ra) # 80003232 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2e:	013a09bb          	addw	s3,s4,s3
    80003c32:	009a04bb          	addw	s1,s4,s1
    80003c36:	9aee                	add	s5,s5,s11
    80003c38:	0569f763          	bgeu	s3,s6,80003c86 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c3c:	000ba903          	lw	s2,0(s7)
    80003c40:	00a4d59b          	srliw	a1,s1,0xa
    80003c44:	855e                	mv	a0,s7
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	8b0080e7          	jalr	-1872(ra) # 800034f6 <bmap>
    80003c4e:	0005059b          	sext.w	a1,a0
    80003c52:	854a                	mv	a0,s2
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	4ae080e7          	jalr	1198(ra) # 80003102 <bread>
    80003c5c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5e:	3ff4f713          	andi	a4,s1,1023
    80003c62:	40ed07bb          	subw	a5,s10,a4
    80003c66:	413b06bb          	subw	a3,s6,s3
    80003c6a:	8a3e                	mv	s4,a5
    80003c6c:	2781                	sext.w	a5,a5
    80003c6e:	0006861b          	sext.w	a2,a3
    80003c72:	f8f679e3          	bgeu	a2,a5,80003c04 <readi+0x4c>
    80003c76:	8a36                	mv	s4,a3
    80003c78:	b771                	j	80003c04 <readi+0x4c>
      brelse(bp);
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	5b6080e7          	jalr	1462(ra) # 80003232 <brelse>
      tot = -1;
    80003c84:	59fd                	li	s3,-1
  }
  return tot;
    80003c86:	0009851b          	sext.w	a0,s3
}
    80003c8a:	70a6                	ld	ra,104(sp)
    80003c8c:	7406                	ld	s0,96(sp)
    80003c8e:	64e6                	ld	s1,88(sp)
    80003c90:	6946                	ld	s2,80(sp)
    80003c92:	69a6                	ld	s3,72(sp)
    80003c94:	6a06                	ld	s4,64(sp)
    80003c96:	7ae2                	ld	s5,56(sp)
    80003c98:	7b42                	ld	s6,48(sp)
    80003c9a:	7ba2                	ld	s7,40(sp)
    80003c9c:	7c02                	ld	s8,32(sp)
    80003c9e:	6ce2                	ld	s9,24(sp)
    80003ca0:	6d42                	ld	s10,16(sp)
    80003ca2:	6da2                	ld	s11,8(sp)
    80003ca4:	6165                	addi	sp,sp,112
    80003ca6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca8:	89da                	mv	s3,s6
    80003caa:	bff1                	j	80003c86 <readi+0xce>
    return 0;
    80003cac:	4501                	li	a0,0
}
    80003cae:	8082                	ret

0000000080003cb0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cb0:	457c                	lw	a5,76(a0)
    80003cb2:	10d7e863          	bltu	a5,a3,80003dc2 <writei+0x112>
{
    80003cb6:	7159                	addi	sp,sp,-112
    80003cb8:	f486                	sd	ra,104(sp)
    80003cba:	f0a2                	sd	s0,96(sp)
    80003cbc:	eca6                	sd	s1,88(sp)
    80003cbe:	e8ca                	sd	s2,80(sp)
    80003cc0:	e4ce                	sd	s3,72(sp)
    80003cc2:	e0d2                	sd	s4,64(sp)
    80003cc4:	fc56                	sd	s5,56(sp)
    80003cc6:	f85a                	sd	s6,48(sp)
    80003cc8:	f45e                	sd	s7,40(sp)
    80003cca:	f062                	sd	s8,32(sp)
    80003ccc:	ec66                	sd	s9,24(sp)
    80003cce:	e86a                	sd	s10,16(sp)
    80003cd0:	e46e                	sd	s11,8(sp)
    80003cd2:	1880                	addi	s0,sp,112
    80003cd4:	8b2a                	mv	s6,a0
    80003cd6:	8c2e                	mv	s8,a1
    80003cd8:	8ab2                	mv	s5,a2
    80003cda:	8936                	mv	s2,a3
    80003cdc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cde:	00e687bb          	addw	a5,a3,a4
    80003ce2:	0ed7e263          	bltu	a5,a3,80003dc6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ce6:	00043737          	lui	a4,0x43
    80003cea:	0ef76063          	bltu	a4,a5,80003dca <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cee:	0c0b8863          	beqz	s7,80003dbe <writei+0x10e>
    80003cf2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cf8:	5cfd                	li	s9,-1
    80003cfa:	a091                	j	80003d3e <writei+0x8e>
    80003cfc:	02099d93          	slli	s11,s3,0x20
    80003d00:	020ddd93          	srli	s11,s11,0x20
    80003d04:	05848513          	addi	a0,s1,88
    80003d08:	86ee                	mv	a3,s11
    80003d0a:	8656                	mv	a2,s5
    80003d0c:	85e2                	mv	a1,s8
    80003d0e:	953a                	add	a0,a0,a4
    80003d10:	fffff097          	auipc	ra,0xfffff
    80003d14:	a2a080e7          	jalr	-1494(ra) # 8000273a <either_copyin>
    80003d18:	07950263          	beq	a0,s9,80003d7c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d1c:	8526                	mv	a0,s1
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	790080e7          	jalr	1936(ra) # 800044ae <log_write>
    brelse(bp);
    80003d26:	8526                	mv	a0,s1
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	50a080e7          	jalr	1290(ra) # 80003232 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d30:	01498a3b          	addw	s4,s3,s4
    80003d34:	0129893b          	addw	s2,s3,s2
    80003d38:	9aee                	add	s5,s5,s11
    80003d3a:	057a7663          	bgeu	s4,s7,80003d86 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d3e:	000b2483          	lw	s1,0(s6)
    80003d42:	00a9559b          	srliw	a1,s2,0xa
    80003d46:	855a                	mv	a0,s6
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	7ae080e7          	jalr	1966(ra) # 800034f6 <bmap>
    80003d50:	0005059b          	sext.w	a1,a0
    80003d54:	8526                	mv	a0,s1
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	3ac080e7          	jalr	940(ra) # 80003102 <bread>
    80003d5e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d60:	3ff97713          	andi	a4,s2,1023
    80003d64:	40ed07bb          	subw	a5,s10,a4
    80003d68:	414b86bb          	subw	a3,s7,s4
    80003d6c:	89be                	mv	s3,a5
    80003d6e:	2781                	sext.w	a5,a5
    80003d70:	0006861b          	sext.w	a2,a3
    80003d74:	f8f674e3          	bgeu	a2,a5,80003cfc <writei+0x4c>
    80003d78:	89b6                	mv	s3,a3
    80003d7a:	b749                	j	80003cfc <writei+0x4c>
      brelse(bp);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	4b4080e7          	jalr	1204(ra) # 80003232 <brelse>
  }

  if(off > ip->size)
    80003d86:	04cb2783          	lw	a5,76(s6)
    80003d8a:	0127f463          	bgeu	a5,s2,80003d92 <writei+0xe2>
    ip->size = off;
    80003d8e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d92:	855a                	mv	a0,s6
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	aa6080e7          	jalr	-1370(ra) # 8000383a <iupdate>

  return tot;
    80003d9c:	000a051b          	sext.w	a0,s4
}
    80003da0:	70a6                	ld	ra,104(sp)
    80003da2:	7406                	ld	s0,96(sp)
    80003da4:	64e6                	ld	s1,88(sp)
    80003da6:	6946                	ld	s2,80(sp)
    80003da8:	69a6                	ld	s3,72(sp)
    80003daa:	6a06                	ld	s4,64(sp)
    80003dac:	7ae2                	ld	s5,56(sp)
    80003dae:	7b42                	ld	s6,48(sp)
    80003db0:	7ba2                	ld	s7,40(sp)
    80003db2:	7c02                	ld	s8,32(sp)
    80003db4:	6ce2                	ld	s9,24(sp)
    80003db6:	6d42                	ld	s10,16(sp)
    80003db8:	6da2                	ld	s11,8(sp)
    80003dba:	6165                	addi	sp,sp,112
    80003dbc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dbe:	8a5e                	mv	s4,s7
    80003dc0:	bfc9                	j	80003d92 <writei+0xe2>
    return -1;
    80003dc2:	557d                	li	a0,-1
}
    80003dc4:	8082                	ret
    return -1;
    80003dc6:	557d                	li	a0,-1
    80003dc8:	bfe1                	j	80003da0 <writei+0xf0>
    return -1;
    80003dca:	557d                	li	a0,-1
    80003dcc:	bfd1                	j	80003da0 <writei+0xf0>

0000000080003dce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dce:	1141                	addi	sp,sp,-16
    80003dd0:	e406                	sd	ra,8(sp)
    80003dd2:	e022                	sd	s0,0(sp)
    80003dd4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dd6:	4639                	li	a2,14
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	fe0080e7          	jalr	-32(ra) # 80000db8 <strncmp>
}
    80003de0:	60a2                	ld	ra,8(sp)
    80003de2:	6402                	ld	s0,0(sp)
    80003de4:	0141                	addi	sp,sp,16
    80003de6:	8082                	ret

0000000080003de8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003de8:	7139                	addi	sp,sp,-64
    80003dea:	fc06                	sd	ra,56(sp)
    80003dec:	f822                	sd	s0,48(sp)
    80003dee:	f426                	sd	s1,40(sp)
    80003df0:	f04a                	sd	s2,32(sp)
    80003df2:	ec4e                	sd	s3,24(sp)
    80003df4:	e852                	sd	s4,16(sp)
    80003df6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003df8:	04451703          	lh	a4,68(a0)
    80003dfc:	4785                	li	a5,1
    80003dfe:	00f71a63          	bne	a4,a5,80003e12 <dirlookup+0x2a>
    80003e02:	892a                	mv	s2,a0
    80003e04:	89ae                	mv	s3,a1
    80003e06:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e08:	457c                	lw	a5,76(a0)
    80003e0a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e0c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0e:	e79d                	bnez	a5,80003e3c <dirlookup+0x54>
    80003e10:	a8a5                	j	80003e88 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e12:	00005517          	auipc	a0,0x5
    80003e16:	88e50513          	addi	a0,a0,-1906 # 800086a0 <syscalls+0x1b8>
    80003e1a:	ffffc097          	auipc	ra,0xffffc
    80003e1e:	724080e7          	jalr	1828(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e22:	00005517          	auipc	a0,0x5
    80003e26:	89650513          	addi	a0,a0,-1898 # 800086b8 <syscalls+0x1d0>
    80003e2a:	ffffc097          	auipc	ra,0xffffc
    80003e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e32:	24c1                	addiw	s1,s1,16
    80003e34:	04c92783          	lw	a5,76(s2)
    80003e38:	04f4f763          	bgeu	s1,a5,80003e86 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e3c:	4741                	li	a4,16
    80003e3e:	86a6                	mv	a3,s1
    80003e40:	fc040613          	addi	a2,s0,-64
    80003e44:	4581                	li	a1,0
    80003e46:	854a                	mv	a0,s2
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	d70080e7          	jalr	-656(ra) # 80003bb8 <readi>
    80003e50:	47c1                	li	a5,16
    80003e52:	fcf518e3          	bne	a0,a5,80003e22 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e56:	fc045783          	lhu	a5,-64(s0)
    80003e5a:	dfe1                	beqz	a5,80003e32 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e5c:	fc240593          	addi	a1,s0,-62
    80003e60:	854e                	mv	a0,s3
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	f6c080e7          	jalr	-148(ra) # 80003dce <namecmp>
    80003e6a:	f561                	bnez	a0,80003e32 <dirlookup+0x4a>
      if(poff)
    80003e6c:	000a0463          	beqz	s4,80003e74 <dirlookup+0x8c>
        *poff = off;
    80003e70:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e74:	fc045583          	lhu	a1,-64(s0)
    80003e78:	00092503          	lw	a0,0(s2)
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	754080e7          	jalr	1876(ra) # 800035d0 <iget>
    80003e84:	a011                	j	80003e88 <dirlookup+0xa0>
  return 0;
    80003e86:	4501                	li	a0,0
}
    80003e88:	70e2                	ld	ra,56(sp)
    80003e8a:	7442                	ld	s0,48(sp)
    80003e8c:	74a2                	ld	s1,40(sp)
    80003e8e:	7902                	ld	s2,32(sp)
    80003e90:	69e2                	ld	s3,24(sp)
    80003e92:	6a42                	ld	s4,16(sp)
    80003e94:	6121                	addi	sp,sp,64
    80003e96:	8082                	ret

0000000080003e98 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e98:	711d                	addi	sp,sp,-96
    80003e9a:	ec86                	sd	ra,88(sp)
    80003e9c:	e8a2                	sd	s0,80(sp)
    80003e9e:	e4a6                	sd	s1,72(sp)
    80003ea0:	e0ca                	sd	s2,64(sp)
    80003ea2:	fc4e                	sd	s3,56(sp)
    80003ea4:	f852                	sd	s4,48(sp)
    80003ea6:	f456                	sd	s5,40(sp)
    80003ea8:	f05a                	sd	s6,32(sp)
    80003eaa:	ec5e                	sd	s7,24(sp)
    80003eac:	e862                	sd	s8,16(sp)
    80003eae:	e466                	sd	s9,8(sp)
    80003eb0:	1080                	addi	s0,sp,96
    80003eb2:	84aa                	mv	s1,a0
    80003eb4:	8b2e                	mv	s6,a1
    80003eb6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eb8:	00054703          	lbu	a4,0(a0)
    80003ebc:	02f00793          	li	a5,47
    80003ec0:	02f70363          	beq	a4,a5,80003ee6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ec4:	ffffe097          	auipc	ra,0xffffe
    80003ec8:	dac080e7          	jalr	-596(ra) # 80001c70 <myproc>
    80003ecc:	16853503          	ld	a0,360(a0)
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	9f6080e7          	jalr	-1546(ra) # 800038c6 <idup>
    80003ed8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eda:	02f00913          	li	s2,47
  len = path - s;
    80003ede:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ee0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ee2:	4c05                	li	s8,1
    80003ee4:	a865                	j	80003f9c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ee6:	4585                	li	a1,1
    80003ee8:	4505                	li	a0,1
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	6e6080e7          	jalr	1766(ra) # 800035d0 <iget>
    80003ef2:	89aa                	mv	s3,a0
    80003ef4:	b7dd                	j	80003eda <namex+0x42>
      iunlockput(ip);
    80003ef6:	854e                	mv	a0,s3
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	c6e080e7          	jalr	-914(ra) # 80003b66 <iunlockput>
      return 0;
    80003f00:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f02:	854e                	mv	a0,s3
    80003f04:	60e6                	ld	ra,88(sp)
    80003f06:	6446                	ld	s0,80(sp)
    80003f08:	64a6                	ld	s1,72(sp)
    80003f0a:	6906                	ld	s2,64(sp)
    80003f0c:	79e2                	ld	s3,56(sp)
    80003f0e:	7a42                	ld	s4,48(sp)
    80003f10:	7aa2                	ld	s5,40(sp)
    80003f12:	7b02                	ld	s6,32(sp)
    80003f14:	6be2                	ld	s7,24(sp)
    80003f16:	6c42                	ld	s8,16(sp)
    80003f18:	6ca2                	ld	s9,8(sp)
    80003f1a:	6125                	addi	sp,sp,96
    80003f1c:	8082                	ret
      iunlock(ip);
    80003f1e:	854e                	mv	a0,s3
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	aa6080e7          	jalr	-1370(ra) # 800039c6 <iunlock>
      return ip;
    80003f28:	bfe9                	j	80003f02 <namex+0x6a>
      iunlockput(ip);
    80003f2a:	854e                	mv	a0,s3
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	c3a080e7          	jalr	-966(ra) # 80003b66 <iunlockput>
      return 0;
    80003f34:	89d2                	mv	s3,s4
    80003f36:	b7f1                	j	80003f02 <namex+0x6a>
  len = path - s;
    80003f38:	40b48633          	sub	a2,s1,a1
    80003f3c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f40:	094cd463          	bge	s9,s4,80003fc8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f44:	4639                	li	a2,14
    80003f46:	8556                	mv	a0,s5
    80003f48:	ffffd097          	auipc	ra,0xffffd
    80003f4c:	df8080e7          	jalr	-520(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f50:	0004c783          	lbu	a5,0(s1)
    80003f54:	01279763          	bne	a5,s2,80003f62 <namex+0xca>
    path++;
    80003f58:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	ff278de3          	beq	a5,s2,80003f58 <namex+0xc0>
    ilock(ip);
    80003f62:	854e                	mv	a0,s3
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	9a0080e7          	jalr	-1632(ra) # 80003904 <ilock>
    if(ip->type != T_DIR){
    80003f6c:	04499783          	lh	a5,68(s3)
    80003f70:	f98793e3          	bne	a5,s8,80003ef6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f74:	000b0563          	beqz	s6,80003f7e <namex+0xe6>
    80003f78:	0004c783          	lbu	a5,0(s1)
    80003f7c:	d3cd                	beqz	a5,80003f1e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f7e:	865e                	mv	a2,s7
    80003f80:	85d6                	mv	a1,s5
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	e64080e7          	jalr	-412(ra) # 80003de8 <dirlookup>
    80003f8c:	8a2a                	mv	s4,a0
    80003f8e:	dd51                	beqz	a0,80003f2a <namex+0x92>
    iunlockput(ip);
    80003f90:	854e                	mv	a0,s3
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	bd4080e7          	jalr	-1068(ra) # 80003b66 <iunlockput>
    ip = next;
    80003f9a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	05279763          	bne	a5,s2,80003fee <namex+0x156>
    path++;
    80003fa4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fa6:	0004c783          	lbu	a5,0(s1)
    80003faa:	ff278de3          	beq	a5,s2,80003fa4 <namex+0x10c>
  if(*path == 0)
    80003fae:	c79d                	beqz	a5,80003fdc <namex+0x144>
    path++;
    80003fb0:	85a6                	mv	a1,s1
  len = path - s;
    80003fb2:	8a5e                	mv	s4,s7
    80003fb4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fb6:	01278963          	beq	a5,s2,80003fc8 <namex+0x130>
    80003fba:	dfbd                	beqz	a5,80003f38 <namex+0xa0>
    path++;
    80003fbc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fbe:	0004c783          	lbu	a5,0(s1)
    80003fc2:	ff279ce3          	bne	a5,s2,80003fba <namex+0x122>
    80003fc6:	bf8d                	j	80003f38 <namex+0xa0>
    memmove(name, s, len);
    80003fc8:	2601                	sext.w	a2,a2
    80003fca:	8556                	mv	a0,s5
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	d74080e7          	jalr	-652(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fd4:	9a56                	add	s4,s4,s5
    80003fd6:	000a0023          	sb	zero,0(s4)
    80003fda:	bf9d                	j	80003f50 <namex+0xb8>
  if(nameiparent){
    80003fdc:	f20b03e3          	beqz	s6,80003f02 <namex+0x6a>
    iput(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	adc080e7          	jalr	-1316(ra) # 80003abe <iput>
    return 0;
    80003fea:	4981                	li	s3,0
    80003fec:	bf19                	j	80003f02 <namex+0x6a>
  if(*path == 0)
    80003fee:	d7fd                	beqz	a5,80003fdc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ff0:	0004c783          	lbu	a5,0(s1)
    80003ff4:	85a6                	mv	a1,s1
    80003ff6:	b7d1                	j	80003fba <namex+0x122>

0000000080003ff8 <dirlink>:
{
    80003ff8:	7139                	addi	sp,sp,-64
    80003ffa:	fc06                	sd	ra,56(sp)
    80003ffc:	f822                	sd	s0,48(sp)
    80003ffe:	f426                	sd	s1,40(sp)
    80004000:	f04a                	sd	s2,32(sp)
    80004002:	ec4e                	sd	s3,24(sp)
    80004004:	e852                	sd	s4,16(sp)
    80004006:	0080                	addi	s0,sp,64
    80004008:	892a                	mv	s2,a0
    8000400a:	8a2e                	mv	s4,a1
    8000400c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000400e:	4601                	li	a2,0
    80004010:	00000097          	auipc	ra,0x0
    80004014:	dd8080e7          	jalr	-552(ra) # 80003de8 <dirlookup>
    80004018:	e93d                	bnez	a0,8000408e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401a:	04c92483          	lw	s1,76(s2)
    8000401e:	c49d                	beqz	s1,8000404c <dirlink+0x54>
    80004020:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004022:	4741                	li	a4,16
    80004024:	86a6                	mv	a3,s1
    80004026:	fc040613          	addi	a2,s0,-64
    8000402a:	4581                	li	a1,0
    8000402c:	854a                	mv	a0,s2
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	b8a080e7          	jalr	-1142(ra) # 80003bb8 <readi>
    80004036:	47c1                	li	a5,16
    80004038:	06f51163          	bne	a0,a5,8000409a <dirlink+0xa2>
    if(de.inum == 0)
    8000403c:	fc045783          	lhu	a5,-64(s0)
    80004040:	c791                	beqz	a5,8000404c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004042:	24c1                	addiw	s1,s1,16
    80004044:	04c92783          	lw	a5,76(s2)
    80004048:	fcf4ede3          	bltu	s1,a5,80004022 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000404c:	4639                	li	a2,14
    8000404e:	85d2                	mv	a1,s4
    80004050:	fc240513          	addi	a0,s0,-62
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	da0080e7          	jalr	-608(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000405c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004060:	4741                	li	a4,16
    80004062:	86a6                	mv	a3,s1
    80004064:	fc040613          	addi	a2,s0,-64
    80004068:	4581                	li	a1,0
    8000406a:	854a                	mv	a0,s2
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	c44080e7          	jalr	-956(ra) # 80003cb0 <writei>
    80004074:	872a                	mv	a4,a0
    80004076:	47c1                	li	a5,16
  return 0;
    80004078:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000407a:	02f71863          	bne	a4,a5,800040aa <dirlink+0xb2>
}
    8000407e:	70e2                	ld	ra,56(sp)
    80004080:	7442                	ld	s0,48(sp)
    80004082:	74a2                	ld	s1,40(sp)
    80004084:	7902                	ld	s2,32(sp)
    80004086:	69e2                	ld	s3,24(sp)
    80004088:	6a42                	ld	s4,16(sp)
    8000408a:	6121                	addi	sp,sp,64
    8000408c:	8082                	ret
    iput(ip);
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	a30080e7          	jalr	-1488(ra) # 80003abe <iput>
    return -1;
    80004096:	557d                	li	a0,-1
    80004098:	b7dd                	j	8000407e <dirlink+0x86>
      panic("dirlink read");
    8000409a:	00004517          	auipc	a0,0x4
    8000409e:	62e50513          	addi	a0,a0,1582 # 800086c8 <syscalls+0x1e0>
    800040a2:	ffffc097          	auipc	ra,0xffffc
    800040a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
    panic("dirlink");
    800040aa:	00004517          	auipc	a0,0x4
    800040ae:	72e50513          	addi	a0,a0,1838 # 800087d8 <syscalls+0x2f0>
    800040b2:	ffffc097          	auipc	ra,0xffffc
    800040b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>

00000000800040ba <namei>:

struct inode*
namei(char *path)
{
    800040ba:	1101                	addi	sp,sp,-32
    800040bc:	ec06                	sd	ra,24(sp)
    800040be:	e822                	sd	s0,16(sp)
    800040c0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040c2:	fe040613          	addi	a2,s0,-32
    800040c6:	4581                	li	a1,0
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	dd0080e7          	jalr	-560(ra) # 80003e98 <namex>
}
    800040d0:	60e2                	ld	ra,24(sp)
    800040d2:	6442                	ld	s0,16(sp)
    800040d4:	6105                	addi	sp,sp,32
    800040d6:	8082                	ret

00000000800040d8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040d8:	1141                	addi	sp,sp,-16
    800040da:	e406                	sd	ra,8(sp)
    800040dc:	e022                	sd	s0,0(sp)
    800040de:	0800                	addi	s0,sp,16
    800040e0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040e2:	4585                	li	a1,1
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	db4080e7          	jalr	-588(ra) # 80003e98 <namex>
}
    800040ec:	60a2                	ld	ra,8(sp)
    800040ee:	6402                	ld	s0,0(sp)
    800040f0:	0141                	addi	sp,sp,16
    800040f2:	8082                	ret

00000000800040f4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040f4:	1101                	addi	sp,sp,-32
    800040f6:	ec06                	sd	ra,24(sp)
    800040f8:	e822                	sd	s0,16(sp)
    800040fa:	e426                	sd	s1,8(sp)
    800040fc:	e04a                	sd	s2,0(sp)
    800040fe:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004100:	0001d917          	auipc	s2,0x1d
    80004104:	79090913          	addi	s2,s2,1936 # 80021890 <log>
    80004108:	01892583          	lw	a1,24(s2)
    8000410c:	02892503          	lw	a0,40(s2)
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	ff2080e7          	jalr	-14(ra) # 80003102 <bread>
    80004118:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000411a:	02c92683          	lw	a3,44(s2)
    8000411e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004120:	02d05763          	blez	a3,8000414e <write_head+0x5a>
    80004124:	0001d797          	auipc	a5,0x1d
    80004128:	79c78793          	addi	a5,a5,1948 # 800218c0 <log+0x30>
    8000412c:	05c50713          	addi	a4,a0,92
    80004130:	36fd                	addiw	a3,a3,-1
    80004132:	1682                	slli	a3,a3,0x20
    80004134:	9281                	srli	a3,a3,0x20
    80004136:	068a                	slli	a3,a3,0x2
    80004138:	0001d617          	auipc	a2,0x1d
    8000413c:	78c60613          	addi	a2,a2,1932 # 800218c4 <log+0x34>
    80004140:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004142:	4390                	lw	a2,0(a5)
    80004144:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004146:	0791                	addi	a5,a5,4
    80004148:	0711                	addi	a4,a4,4
    8000414a:	fed79ce3          	bne	a5,a3,80004142 <write_head+0x4e>
  }
  bwrite(buf);
    8000414e:	8526                	mv	a0,s1
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	0a4080e7          	jalr	164(ra) # 800031f4 <bwrite>
  brelse(buf);
    80004158:	8526                	mv	a0,s1
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	0d8080e7          	jalr	216(ra) # 80003232 <brelse>
}
    80004162:	60e2                	ld	ra,24(sp)
    80004164:	6442                	ld	s0,16(sp)
    80004166:	64a2                	ld	s1,8(sp)
    80004168:	6902                	ld	s2,0(sp)
    8000416a:	6105                	addi	sp,sp,32
    8000416c:	8082                	ret

000000008000416e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416e:	0001d797          	auipc	a5,0x1d
    80004172:	74e7a783          	lw	a5,1870(a5) # 800218bc <log+0x2c>
    80004176:	0af05d63          	blez	a5,80004230 <install_trans+0xc2>
{
    8000417a:	7139                	addi	sp,sp,-64
    8000417c:	fc06                	sd	ra,56(sp)
    8000417e:	f822                	sd	s0,48(sp)
    80004180:	f426                	sd	s1,40(sp)
    80004182:	f04a                	sd	s2,32(sp)
    80004184:	ec4e                	sd	s3,24(sp)
    80004186:	e852                	sd	s4,16(sp)
    80004188:	e456                	sd	s5,8(sp)
    8000418a:	e05a                	sd	s6,0(sp)
    8000418c:	0080                	addi	s0,sp,64
    8000418e:	8b2a                	mv	s6,a0
    80004190:	0001da97          	auipc	s5,0x1d
    80004194:	730a8a93          	addi	s5,s5,1840 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004198:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000419a:	0001d997          	auipc	s3,0x1d
    8000419e:	6f698993          	addi	s3,s3,1782 # 80021890 <log>
    800041a2:	a035                	j	800041ce <install_trans+0x60>
      bunpin(dbuf);
    800041a4:	8526                	mv	a0,s1
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	166080e7          	jalr	358(ra) # 8000330c <bunpin>
    brelse(lbuf);
    800041ae:	854a                	mv	a0,s2
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	082080e7          	jalr	130(ra) # 80003232 <brelse>
    brelse(dbuf);
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	078080e7          	jalr	120(ra) # 80003232 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c2:	2a05                	addiw	s4,s4,1
    800041c4:	0a91                	addi	s5,s5,4
    800041c6:	02c9a783          	lw	a5,44(s3)
    800041ca:	04fa5963          	bge	s4,a5,8000421c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ce:	0189a583          	lw	a1,24(s3)
    800041d2:	014585bb          	addw	a1,a1,s4
    800041d6:	2585                	addiw	a1,a1,1
    800041d8:	0289a503          	lw	a0,40(s3)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	f26080e7          	jalr	-218(ra) # 80003102 <bread>
    800041e4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041e6:	000aa583          	lw	a1,0(s5)
    800041ea:	0289a503          	lw	a0,40(s3)
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	f14080e7          	jalr	-236(ra) # 80003102 <bread>
    800041f6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041f8:	40000613          	li	a2,1024
    800041fc:	05890593          	addi	a1,s2,88
    80004200:	05850513          	addi	a0,a0,88
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	b3c080e7          	jalr	-1220(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000420c:	8526                	mv	a0,s1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	fe6080e7          	jalr	-26(ra) # 800031f4 <bwrite>
    if(recovering == 0)
    80004216:	f80b1ce3          	bnez	s6,800041ae <install_trans+0x40>
    8000421a:	b769                	j	800041a4 <install_trans+0x36>
}
    8000421c:	70e2                	ld	ra,56(sp)
    8000421e:	7442                	ld	s0,48(sp)
    80004220:	74a2                	ld	s1,40(sp)
    80004222:	7902                	ld	s2,32(sp)
    80004224:	69e2                	ld	s3,24(sp)
    80004226:	6a42                	ld	s4,16(sp)
    80004228:	6aa2                	ld	s5,8(sp)
    8000422a:	6b02                	ld	s6,0(sp)
    8000422c:	6121                	addi	sp,sp,64
    8000422e:	8082                	ret
    80004230:	8082                	ret

0000000080004232 <initlog>:
{
    80004232:	7179                	addi	sp,sp,-48
    80004234:	f406                	sd	ra,40(sp)
    80004236:	f022                	sd	s0,32(sp)
    80004238:	ec26                	sd	s1,24(sp)
    8000423a:	e84a                	sd	s2,16(sp)
    8000423c:	e44e                	sd	s3,8(sp)
    8000423e:	1800                	addi	s0,sp,48
    80004240:	892a                	mv	s2,a0
    80004242:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	64c48493          	addi	s1,s1,1612 # 80021890 <log>
    8000424c:	00004597          	auipc	a1,0x4
    80004250:	48c58593          	addi	a1,a1,1164 # 800086d8 <syscalls+0x1f0>
    80004254:	8526                	mv	a0,s1
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	8fe080e7          	jalr	-1794(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000425e:	0149a583          	lw	a1,20(s3)
    80004262:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004264:	0109a783          	lw	a5,16(s3)
    80004268:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000426a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000426e:	854a                	mv	a0,s2
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	e92080e7          	jalr	-366(ra) # 80003102 <bread>
  log.lh.n = lh->n;
    80004278:	4d3c                	lw	a5,88(a0)
    8000427a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000427c:	02f05563          	blez	a5,800042a6 <initlog+0x74>
    80004280:	05c50713          	addi	a4,a0,92
    80004284:	0001d697          	auipc	a3,0x1d
    80004288:	63c68693          	addi	a3,a3,1596 # 800218c0 <log+0x30>
    8000428c:	37fd                	addiw	a5,a5,-1
    8000428e:	1782                	slli	a5,a5,0x20
    80004290:	9381                	srli	a5,a5,0x20
    80004292:	078a                	slli	a5,a5,0x2
    80004294:	06050613          	addi	a2,a0,96
    80004298:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000429a:	4310                	lw	a2,0(a4)
    8000429c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000429e:	0711                	addi	a4,a4,4
    800042a0:	0691                	addi	a3,a3,4
    800042a2:	fef71ce3          	bne	a4,a5,8000429a <initlog+0x68>
  brelse(buf);
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	f8c080e7          	jalr	-116(ra) # 80003232 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042ae:	4505                	li	a0,1
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	ebe080e7          	jalr	-322(ra) # 8000416e <install_trans>
  log.lh.n = 0;
    800042b8:	0001d797          	auipc	a5,0x1d
    800042bc:	6007a223          	sw	zero,1540(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	e34080e7          	jalr	-460(ra) # 800040f4 <write_head>
}
    800042c8:	70a2                	ld	ra,40(sp)
    800042ca:	7402                	ld	s0,32(sp)
    800042cc:	64e2                	ld	s1,24(sp)
    800042ce:	6942                	ld	s2,16(sp)
    800042d0:	69a2                	ld	s3,8(sp)
    800042d2:	6145                	addi	sp,sp,48
    800042d4:	8082                	ret

00000000800042d6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042d6:	1101                	addi	sp,sp,-32
    800042d8:	ec06                	sd	ra,24(sp)
    800042da:	e822                	sd	s0,16(sp)
    800042dc:	e426                	sd	s1,8(sp)
    800042de:	e04a                	sd	s2,0(sp)
    800042e0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042e2:	0001d517          	auipc	a0,0x1d
    800042e6:	5ae50513          	addi	a0,a0,1454 # 80021890 <log>
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042f2:	0001d497          	auipc	s1,0x1d
    800042f6:	59e48493          	addi	s1,s1,1438 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042fa:	4979                	li	s2,30
    800042fc:	a039                	j	8000430a <begin_op+0x34>
      sleep(&log, &log.lock);
    800042fe:	85a6                	mv	a1,s1
    80004300:	8526                	mv	a0,s1
    80004302:	ffffe097          	auipc	ra,0xffffe
    80004306:	fee080e7          	jalr	-18(ra) # 800022f0 <sleep>
    if(log.committing){
    8000430a:	50dc                	lw	a5,36(s1)
    8000430c:	fbed                	bnez	a5,800042fe <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000430e:	509c                	lw	a5,32(s1)
    80004310:	0017871b          	addiw	a4,a5,1
    80004314:	0007069b          	sext.w	a3,a4
    80004318:	0027179b          	slliw	a5,a4,0x2
    8000431c:	9fb9                	addw	a5,a5,a4
    8000431e:	0017979b          	slliw	a5,a5,0x1
    80004322:	54d8                	lw	a4,44(s1)
    80004324:	9fb9                	addw	a5,a5,a4
    80004326:	00f95963          	bge	s2,a5,80004338 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000432a:	85a6                	mv	a1,s1
    8000432c:	8526                	mv	a0,s1
    8000432e:	ffffe097          	auipc	ra,0xffffe
    80004332:	fc2080e7          	jalr	-62(ra) # 800022f0 <sleep>
    80004336:	bfd1                	j	8000430a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004338:	0001d517          	auipc	a0,0x1d
    8000433c:	55850513          	addi	a0,a0,1368 # 80021890 <log>
    80004340:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	956080e7          	jalr	-1706(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000434a:	60e2                	ld	ra,24(sp)
    8000434c:	6442                	ld	s0,16(sp)
    8000434e:	64a2                	ld	s1,8(sp)
    80004350:	6902                	ld	s2,0(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004356:	7139                	addi	sp,sp,-64
    80004358:	fc06                	sd	ra,56(sp)
    8000435a:	f822                	sd	s0,48(sp)
    8000435c:	f426                	sd	s1,40(sp)
    8000435e:	f04a                	sd	s2,32(sp)
    80004360:	ec4e                	sd	s3,24(sp)
    80004362:	e852                	sd	s4,16(sp)
    80004364:	e456                	sd	s5,8(sp)
    80004366:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	52848493          	addi	s1,s1,1320 # 80021890 <log>
    80004370:	8526                	mv	a0,s1
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	872080e7          	jalr	-1934(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000437a:	509c                	lw	a5,32(s1)
    8000437c:	37fd                	addiw	a5,a5,-1
    8000437e:	0007891b          	sext.w	s2,a5
    80004382:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004384:	50dc                	lw	a5,36(s1)
    80004386:	efb9                	bnez	a5,800043e4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004388:	06091663          	bnez	s2,800043f4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000438c:	0001d497          	auipc	s1,0x1d
    80004390:	50448493          	addi	s1,s1,1284 # 80021890 <log>
    80004394:	4785                	li	a5,1
    80004396:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043a2:	54dc                	lw	a5,44(s1)
    800043a4:	06f04763          	bgtz	a5,80004412 <end_op+0xbc>
    acquire(&log.lock);
    800043a8:	0001d497          	auipc	s1,0x1d
    800043ac:	4e848493          	addi	s1,s1,1256 # 80021890 <log>
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	832080e7          	jalr	-1998(ra) # 80000be4 <acquire>
    log.committing = 0;
    800043ba:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffe097          	auipc	ra,0xffffe
    800043c4:	0cc080e7          	jalr	204(ra) # 8000248c <wakeup>
    release(&log.lock);
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	8ce080e7          	jalr	-1842(ra) # 80000c98 <release>
}
    800043d2:	70e2                	ld	ra,56(sp)
    800043d4:	7442                	ld	s0,48(sp)
    800043d6:	74a2                	ld	s1,40(sp)
    800043d8:	7902                	ld	s2,32(sp)
    800043da:	69e2                	ld	s3,24(sp)
    800043dc:	6a42                	ld	s4,16(sp)
    800043de:	6aa2                	ld	s5,8(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret
    panic("log.committing");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	2fc50513          	addi	a0,a0,764 # 800086e0 <syscalls+0x1f8>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
    wakeup(&log);
    800043f4:	0001d497          	auipc	s1,0x1d
    800043f8:	49c48493          	addi	s1,s1,1180 # 80021890 <log>
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffe097          	auipc	ra,0xffffe
    80004402:	08e080e7          	jalr	142(ra) # 8000248c <wakeup>
  release(&log.lock);
    80004406:	8526                	mv	a0,s1
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
  if(do_commit){
    80004410:	b7c9                	j	800043d2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004412:	0001da97          	auipc	s5,0x1d
    80004416:	4aea8a93          	addi	s5,s5,1198 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000441a:	0001da17          	auipc	s4,0x1d
    8000441e:	476a0a13          	addi	s4,s4,1142 # 80021890 <log>
    80004422:	018a2583          	lw	a1,24(s4)
    80004426:	012585bb          	addw	a1,a1,s2
    8000442a:	2585                	addiw	a1,a1,1
    8000442c:	028a2503          	lw	a0,40(s4)
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	cd2080e7          	jalr	-814(ra) # 80003102 <bread>
    80004438:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000443a:	000aa583          	lw	a1,0(s5)
    8000443e:	028a2503          	lw	a0,40(s4)
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	cc0080e7          	jalr	-832(ra) # 80003102 <bread>
    8000444a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000444c:	40000613          	li	a2,1024
    80004450:	05850593          	addi	a1,a0,88
    80004454:	05848513          	addi	a0,s1,88
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	8e8080e7          	jalr	-1816(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004460:	8526                	mv	a0,s1
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	d92080e7          	jalr	-622(ra) # 800031f4 <bwrite>
    brelse(from);
    8000446a:	854e                	mv	a0,s3
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	dc6080e7          	jalr	-570(ra) # 80003232 <brelse>
    brelse(to);
    80004474:	8526                	mv	a0,s1
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	dbc080e7          	jalr	-580(ra) # 80003232 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447e:	2905                	addiw	s2,s2,1
    80004480:	0a91                	addi	s5,s5,4
    80004482:	02ca2783          	lw	a5,44(s4)
    80004486:	f8f94ee3          	blt	s2,a5,80004422 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000448a:	00000097          	auipc	ra,0x0
    8000448e:	c6a080e7          	jalr	-918(ra) # 800040f4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004492:	4501                	li	a0,0
    80004494:	00000097          	auipc	ra,0x0
    80004498:	cda080e7          	jalr	-806(ra) # 8000416e <install_trans>
    log.lh.n = 0;
    8000449c:	0001d797          	auipc	a5,0x1d
    800044a0:	4207a023          	sw	zero,1056(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	c50080e7          	jalr	-944(ra) # 800040f4 <write_head>
    800044ac:	bdf5                	j	800043a8 <end_op+0x52>

00000000800044ae <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044ae:	1101                	addi	sp,sp,-32
    800044b0:	ec06                	sd	ra,24(sp)
    800044b2:	e822                	sd	s0,16(sp)
    800044b4:	e426                	sd	s1,8(sp)
    800044b6:	e04a                	sd	s2,0(sp)
    800044b8:	1000                	addi	s0,sp,32
    800044ba:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044bc:	0001d917          	auipc	s2,0x1d
    800044c0:	3d490913          	addi	s2,s2,980 # 80021890 <log>
    800044c4:	854a                	mv	a0,s2
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	71e080e7          	jalr	1822(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044ce:	02c92603          	lw	a2,44(s2)
    800044d2:	47f5                	li	a5,29
    800044d4:	06c7c563          	blt	a5,a2,8000453e <log_write+0x90>
    800044d8:	0001d797          	auipc	a5,0x1d
    800044dc:	3d47a783          	lw	a5,980(a5) # 800218ac <log+0x1c>
    800044e0:	37fd                	addiw	a5,a5,-1
    800044e2:	04f65e63          	bge	a2,a5,8000453e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044e6:	0001d797          	auipc	a5,0x1d
    800044ea:	3ca7a783          	lw	a5,970(a5) # 800218b0 <log+0x20>
    800044ee:	06f05063          	blez	a5,8000454e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044f2:	4781                	li	a5,0
    800044f4:	06c05563          	blez	a2,8000455e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044f8:	44cc                	lw	a1,12(s1)
    800044fa:	0001d717          	auipc	a4,0x1d
    800044fe:	3c670713          	addi	a4,a4,966 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004502:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004504:	4314                	lw	a3,0(a4)
    80004506:	04b68c63          	beq	a3,a1,8000455e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000450a:	2785                	addiw	a5,a5,1
    8000450c:	0711                	addi	a4,a4,4
    8000450e:	fef61be3          	bne	a2,a5,80004504 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004512:	0621                	addi	a2,a2,8
    80004514:	060a                	slli	a2,a2,0x2
    80004516:	0001d797          	auipc	a5,0x1d
    8000451a:	37a78793          	addi	a5,a5,890 # 80021890 <log>
    8000451e:	963e                	add	a2,a2,a5
    80004520:	44dc                	lw	a5,12(s1)
    80004522:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004524:	8526                	mv	a0,s1
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	daa080e7          	jalr	-598(ra) # 800032d0 <bpin>
    log.lh.n++;
    8000452e:	0001d717          	auipc	a4,0x1d
    80004532:	36270713          	addi	a4,a4,866 # 80021890 <log>
    80004536:	575c                	lw	a5,44(a4)
    80004538:	2785                	addiw	a5,a5,1
    8000453a:	d75c                	sw	a5,44(a4)
    8000453c:	a835                	j	80004578 <log_write+0xca>
    panic("too big a transaction");
    8000453e:	00004517          	auipc	a0,0x4
    80004542:	1b250513          	addi	a0,a0,434 # 800086f0 <syscalls+0x208>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	ff8080e7          	jalr	-8(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000454e:	00004517          	auipc	a0,0x4
    80004552:	1ba50513          	addi	a0,a0,442 # 80008708 <syscalls+0x220>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	fe8080e7          	jalr	-24(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000455e:	00878713          	addi	a4,a5,8
    80004562:	00271693          	slli	a3,a4,0x2
    80004566:	0001d717          	auipc	a4,0x1d
    8000456a:	32a70713          	addi	a4,a4,810 # 80021890 <log>
    8000456e:	9736                	add	a4,a4,a3
    80004570:	44d4                	lw	a3,12(s1)
    80004572:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004574:	faf608e3          	beq	a2,a5,80004524 <log_write+0x76>
  }
  release(&log.lock);
    80004578:	0001d517          	auipc	a0,0x1d
    8000457c:	31850513          	addi	a0,a0,792 # 80021890 <log>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	718080e7          	jalr	1816(ra) # 80000c98 <release>
}
    80004588:	60e2                	ld	ra,24(sp)
    8000458a:	6442                	ld	s0,16(sp)
    8000458c:	64a2                	ld	s1,8(sp)
    8000458e:	6902                	ld	s2,0(sp)
    80004590:	6105                	addi	sp,sp,32
    80004592:	8082                	ret

0000000080004594 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	e04a                	sd	s2,0(sp)
    8000459e:	1000                	addi	s0,sp,32
    800045a0:	84aa                	mv	s1,a0
    800045a2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045a4:	00004597          	auipc	a1,0x4
    800045a8:	18458593          	addi	a1,a1,388 # 80008728 <syscalls+0x240>
    800045ac:	0521                	addi	a0,a0,8
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	5a6080e7          	jalr	1446(ra) # 80000b54 <initlock>
  lk->name = name;
    800045b6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045be:	0204a423          	sw	zero,40(s1)
}
    800045c2:	60e2                	ld	ra,24(sp)
    800045c4:	6442                	ld	s0,16(sp)
    800045c6:	64a2                	ld	s1,8(sp)
    800045c8:	6902                	ld	s2,0(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	e426                	sd	s1,8(sp)
    800045d6:	e04a                	sd	s2,0(sp)
    800045d8:	1000                	addi	s0,sp,32
    800045da:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045dc:	00850913          	addi	s2,a0,8
    800045e0:	854a                	mv	a0,s2
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	602080e7          	jalr	1538(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045ea:	409c                	lw	a5,0(s1)
    800045ec:	cb89                	beqz	a5,800045fe <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ee:	85ca                	mv	a1,s2
    800045f0:	8526                	mv	a0,s1
    800045f2:	ffffe097          	auipc	ra,0xffffe
    800045f6:	cfe080e7          	jalr	-770(ra) # 800022f0 <sleep>
  while (lk->locked) {
    800045fa:	409c                	lw	a5,0(s1)
    800045fc:	fbed                	bnez	a5,800045ee <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045fe:	4785                	li	a5,1
    80004600:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004602:	ffffd097          	auipc	ra,0xffffd
    80004606:	66e080e7          	jalr	1646(ra) # 80001c70 <myproc>
    8000460a:	591c                	lw	a5,48(a0)
    8000460c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	688080e7          	jalr	1672(ra) # 80000c98 <release>
}
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6902                	ld	s2,0(sp)
    80004620:	6105                	addi	sp,sp,32
    80004622:	8082                	ret

0000000080004624 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	e04a                	sd	s2,0(sp)
    8000462e:	1000                	addi	s0,sp,32
    80004630:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004632:	00850913          	addi	s2,a0,8
    80004636:	854a                	mv	a0,s2
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	5ac080e7          	jalr	1452(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004640:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004644:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffe097          	auipc	ra,0xffffe
    8000464e:	e42080e7          	jalr	-446(ra) # 8000248c <wakeup>
  release(&lk->lk);
    80004652:	854a                	mv	a0,s2
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	644080e7          	jalr	1604(ra) # 80000c98 <release>
}
    8000465c:	60e2                	ld	ra,24(sp)
    8000465e:	6442                	ld	s0,16(sp)
    80004660:	64a2                	ld	s1,8(sp)
    80004662:	6902                	ld	s2,0(sp)
    80004664:	6105                	addi	sp,sp,32
    80004666:	8082                	ret

0000000080004668 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004668:	7179                	addi	sp,sp,-48
    8000466a:	f406                	sd	ra,40(sp)
    8000466c:	f022                	sd	s0,32(sp)
    8000466e:	ec26                	sd	s1,24(sp)
    80004670:	e84a                	sd	s2,16(sp)
    80004672:	e44e                	sd	s3,8(sp)
    80004674:	1800                	addi	s0,sp,48
    80004676:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004678:	00850913          	addi	s2,a0,8
    8000467c:	854a                	mv	a0,s2
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	566080e7          	jalr	1382(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004686:	409c                	lw	a5,0(s1)
    80004688:	ef99                	bnez	a5,800046a6 <holdingsleep+0x3e>
    8000468a:	4481                	li	s1,0
  release(&lk->lk);
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
  return r;
}
    80004696:	8526                	mv	a0,s1
    80004698:	70a2                	ld	ra,40(sp)
    8000469a:	7402                	ld	s0,32(sp)
    8000469c:	64e2                	ld	s1,24(sp)
    8000469e:	6942                	ld	s2,16(sp)
    800046a0:	69a2                	ld	s3,8(sp)
    800046a2:	6145                	addi	sp,sp,48
    800046a4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a6:	0284a983          	lw	s3,40(s1)
    800046aa:	ffffd097          	auipc	ra,0xffffd
    800046ae:	5c6080e7          	jalr	1478(ra) # 80001c70 <myproc>
    800046b2:	5904                	lw	s1,48(a0)
    800046b4:	413484b3          	sub	s1,s1,s3
    800046b8:	0014b493          	seqz	s1,s1
    800046bc:	bfc1                	j	8000468c <holdingsleep+0x24>

00000000800046be <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046be:	1141                	addi	sp,sp,-16
    800046c0:	e406                	sd	ra,8(sp)
    800046c2:	e022                	sd	s0,0(sp)
    800046c4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046c6:	00004597          	auipc	a1,0x4
    800046ca:	07258593          	addi	a1,a1,114 # 80008738 <syscalls+0x250>
    800046ce:	0001d517          	auipc	a0,0x1d
    800046d2:	30a50513          	addi	a0,a0,778 # 800219d8 <ftable>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	47e080e7          	jalr	1150(ra) # 80000b54 <initlock>
}
    800046de:	60a2                	ld	ra,8(sp)
    800046e0:	6402                	ld	s0,0(sp)
    800046e2:	0141                	addi	sp,sp,16
    800046e4:	8082                	ret

00000000800046e6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046e6:	1101                	addi	sp,sp,-32
    800046e8:	ec06                	sd	ra,24(sp)
    800046ea:	e822                	sd	s0,16(sp)
    800046ec:	e426                	sd	s1,8(sp)
    800046ee:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046f0:	0001d517          	auipc	a0,0x1d
    800046f4:	2e850513          	addi	a0,a0,744 # 800219d8 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4ec080e7          	jalr	1260(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004700:	0001d497          	auipc	s1,0x1d
    80004704:	2f048493          	addi	s1,s1,752 # 800219f0 <ftable+0x18>
    80004708:	0001e717          	auipc	a4,0x1e
    8000470c:	28870713          	addi	a4,a4,648 # 80022990 <ftable+0xfb8>
    if(f->ref == 0){
    80004710:	40dc                	lw	a5,4(s1)
    80004712:	cf99                	beqz	a5,80004730 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004714:	02848493          	addi	s1,s1,40
    80004718:	fee49ce3          	bne	s1,a4,80004710 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000471c:	0001d517          	auipc	a0,0x1d
    80004720:	2bc50513          	addi	a0,a0,700 # 800219d8 <ftable>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	574080e7          	jalr	1396(ra) # 80000c98 <release>
  return 0;
    8000472c:	4481                	li	s1,0
    8000472e:	a819                	j	80004744 <filealloc+0x5e>
      f->ref = 1;
    80004730:	4785                	li	a5,1
    80004732:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004734:	0001d517          	auipc	a0,0x1d
    80004738:	2a450513          	addi	a0,a0,676 # 800219d8 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
}
    80004744:	8526                	mv	a0,s1
    80004746:	60e2                	ld	ra,24(sp)
    80004748:	6442                	ld	s0,16(sp)
    8000474a:	64a2                	ld	s1,8(sp)
    8000474c:	6105                	addi	sp,sp,32
    8000474e:	8082                	ret

0000000080004750 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	1000                	addi	s0,sp,32
    8000475a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000475c:	0001d517          	auipc	a0,0x1d
    80004760:	27c50513          	addi	a0,a0,636 # 800219d8 <ftable>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	480080e7          	jalr	1152(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000476c:	40dc                	lw	a5,4(s1)
    8000476e:	02f05263          	blez	a5,80004792 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004772:	2785                	addiw	a5,a5,1
    80004774:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004776:	0001d517          	auipc	a0,0x1d
    8000477a:	26250513          	addi	a0,a0,610 # 800219d8 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	51a080e7          	jalr	1306(ra) # 80000c98 <release>
  return f;
}
    80004786:	8526                	mv	a0,s1
    80004788:	60e2                	ld	ra,24(sp)
    8000478a:	6442                	ld	s0,16(sp)
    8000478c:	64a2                	ld	s1,8(sp)
    8000478e:	6105                	addi	sp,sp,32
    80004790:	8082                	ret
    panic("filedup");
    80004792:	00004517          	auipc	a0,0x4
    80004796:	fae50513          	addi	a0,a0,-82 # 80008740 <syscalls+0x258>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800047a2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047a2:	7139                	addi	sp,sp,-64
    800047a4:	fc06                	sd	ra,56(sp)
    800047a6:	f822                	sd	s0,48(sp)
    800047a8:	f426                	sd	s1,40(sp)
    800047aa:	f04a                	sd	s2,32(sp)
    800047ac:	ec4e                	sd	s3,24(sp)
    800047ae:	e852                	sd	s4,16(sp)
    800047b0:	e456                	sd	s5,8(sp)
    800047b2:	0080                	addi	s0,sp,64
    800047b4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047b6:	0001d517          	auipc	a0,0x1d
    800047ba:	22250513          	addi	a0,a0,546 # 800219d8 <ftable>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047c6:	40dc                	lw	a5,4(s1)
    800047c8:	06f05163          	blez	a5,8000482a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047cc:	37fd                	addiw	a5,a5,-1
    800047ce:	0007871b          	sext.w	a4,a5
    800047d2:	c0dc                	sw	a5,4(s1)
    800047d4:	06e04363          	bgtz	a4,8000483a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047d8:	0004a903          	lw	s2,0(s1)
    800047dc:	0094ca83          	lbu	s5,9(s1)
    800047e0:	0104ba03          	ld	s4,16(s1)
    800047e4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047e8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047ec:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047f0:	0001d517          	auipc	a0,0x1d
    800047f4:	1e850513          	addi	a0,a0,488 # 800219d8 <ftable>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	4a0080e7          	jalr	1184(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004800:	4785                	li	a5,1
    80004802:	04f90d63          	beq	s2,a5,8000485c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004806:	3979                	addiw	s2,s2,-2
    80004808:	4785                	li	a5,1
    8000480a:	0527e063          	bltu	a5,s2,8000484a <fileclose+0xa8>
    begin_op();
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	ac8080e7          	jalr	-1336(ra) # 800042d6 <begin_op>
    iput(ff.ip);
    80004816:	854e                	mv	a0,s3
    80004818:	fffff097          	auipc	ra,0xfffff
    8000481c:	2a6080e7          	jalr	678(ra) # 80003abe <iput>
    end_op();
    80004820:	00000097          	auipc	ra,0x0
    80004824:	b36080e7          	jalr	-1226(ra) # 80004356 <end_op>
    80004828:	a00d                	j	8000484a <fileclose+0xa8>
    panic("fileclose");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	f1e50513          	addi	a0,a0,-226 # 80008748 <syscalls+0x260>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d0c080e7          	jalr	-756(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000483a:	0001d517          	auipc	a0,0x1d
    8000483e:	19e50513          	addi	a0,a0,414 # 800219d8 <ftable>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	456080e7          	jalr	1110(ra) # 80000c98 <release>
  }
}
    8000484a:	70e2                	ld	ra,56(sp)
    8000484c:	7442                	ld	s0,48(sp)
    8000484e:	74a2                	ld	s1,40(sp)
    80004850:	7902                	ld	s2,32(sp)
    80004852:	69e2                	ld	s3,24(sp)
    80004854:	6a42                	ld	s4,16(sp)
    80004856:	6aa2                	ld	s5,8(sp)
    80004858:	6121                	addi	sp,sp,64
    8000485a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000485c:	85d6                	mv	a1,s5
    8000485e:	8552                	mv	a0,s4
    80004860:	00000097          	auipc	ra,0x0
    80004864:	34c080e7          	jalr	844(ra) # 80004bac <pipeclose>
    80004868:	b7cd                	j	8000484a <fileclose+0xa8>

000000008000486a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000486a:	715d                	addi	sp,sp,-80
    8000486c:	e486                	sd	ra,72(sp)
    8000486e:	e0a2                	sd	s0,64(sp)
    80004870:	fc26                	sd	s1,56(sp)
    80004872:	f84a                	sd	s2,48(sp)
    80004874:	f44e                	sd	s3,40(sp)
    80004876:	0880                	addi	s0,sp,80
    80004878:	84aa                	mv	s1,a0
    8000487a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000487c:	ffffd097          	auipc	ra,0xffffd
    80004880:	3f4080e7          	jalr	1012(ra) # 80001c70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004884:	409c                	lw	a5,0(s1)
    80004886:	37f9                	addiw	a5,a5,-2
    80004888:	4705                	li	a4,1
    8000488a:	04f76763          	bltu	a4,a5,800048d8 <filestat+0x6e>
    8000488e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004890:	6c88                	ld	a0,24(s1)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	072080e7          	jalr	114(ra) # 80003904 <ilock>
    stati(f->ip, &st);
    8000489a:	fb840593          	addi	a1,s0,-72
    8000489e:	6c88                	ld	a0,24(s1)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	2ee080e7          	jalr	750(ra) # 80003b8e <stati>
    iunlock(f->ip);
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	11c080e7          	jalr	284(ra) # 800039c6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048b2:	46e1                	li	a3,24
    800048b4:	fb840613          	addi	a2,s0,-72
    800048b8:	85ce                	mv	a1,s3
    800048ba:	06893503          	ld	a0,104(s2)
    800048be:	ffffd097          	auipc	ra,0xffffd
    800048c2:	db4080e7          	jalr	-588(ra) # 80001672 <copyout>
    800048c6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048ca:	60a6                	ld	ra,72(sp)
    800048cc:	6406                	ld	s0,64(sp)
    800048ce:	74e2                	ld	s1,56(sp)
    800048d0:	7942                	ld	s2,48(sp)
    800048d2:	79a2                	ld	s3,40(sp)
    800048d4:	6161                	addi	sp,sp,80
    800048d6:	8082                	ret
  return -1;
    800048d8:	557d                	li	a0,-1
    800048da:	bfc5                	j	800048ca <filestat+0x60>

00000000800048dc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048dc:	7179                	addi	sp,sp,-48
    800048de:	f406                	sd	ra,40(sp)
    800048e0:	f022                	sd	s0,32(sp)
    800048e2:	ec26                	sd	s1,24(sp)
    800048e4:	e84a                	sd	s2,16(sp)
    800048e6:	e44e                	sd	s3,8(sp)
    800048e8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048ea:	00854783          	lbu	a5,8(a0)
    800048ee:	c3d5                	beqz	a5,80004992 <fileread+0xb6>
    800048f0:	84aa                	mv	s1,a0
    800048f2:	89ae                	mv	s3,a1
    800048f4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f6:	411c                	lw	a5,0(a0)
    800048f8:	4705                	li	a4,1
    800048fa:	04e78963          	beq	a5,a4,8000494c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048fe:	470d                	li	a4,3
    80004900:	04e78d63          	beq	a5,a4,8000495a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004904:	4709                	li	a4,2
    80004906:	06e79e63          	bne	a5,a4,80004982 <fileread+0xa6>
    ilock(f->ip);
    8000490a:	6d08                	ld	a0,24(a0)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	ff8080e7          	jalr	-8(ra) # 80003904 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004914:	874a                	mv	a4,s2
    80004916:	5094                	lw	a3,32(s1)
    80004918:	864e                	mv	a2,s3
    8000491a:	4585                	li	a1,1
    8000491c:	6c88                	ld	a0,24(s1)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	29a080e7          	jalr	666(ra) # 80003bb8 <readi>
    80004926:	892a                	mv	s2,a0
    80004928:	00a05563          	blez	a0,80004932 <fileread+0x56>
      f->off += r;
    8000492c:	509c                	lw	a5,32(s1)
    8000492e:	9fa9                	addw	a5,a5,a0
    80004930:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004932:	6c88                	ld	a0,24(s1)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	092080e7          	jalr	146(ra) # 800039c6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000493c:	854a                	mv	a0,s2
    8000493e:	70a2                	ld	ra,40(sp)
    80004940:	7402                	ld	s0,32(sp)
    80004942:	64e2                	ld	s1,24(sp)
    80004944:	6942                	ld	s2,16(sp)
    80004946:	69a2                	ld	s3,8(sp)
    80004948:	6145                	addi	sp,sp,48
    8000494a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000494c:	6908                	ld	a0,16(a0)
    8000494e:	00000097          	auipc	ra,0x0
    80004952:	3c8080e7          	jalr	968(ra) # 80004d16 <piperead>
    80004956:	892a                	mv	s2,a0
    80004958:	b7d5                	j	8000493c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000495a:	02451783          	lh	a5,36(a0)
    8000495e:	03079693          	slli	a3,a5,0x30
    80004962:	92c1                	srli	a3,a3,0x30
    80004964:	4725                	li	a4,9
    80004966:	02d76863          	bltu	a4,a3,80004996 <fileread+0xba>
    8000496a:	0792                	slli	a5,a5,0x4
    8000496c:	0001d717          	auipc	a4,0x1d
    80004970:	fcc70713          	addi	a4,a4,-52 # 80021938 <devsw>
    80004974:	97ba                	add	a5,a5,a4
    80004976:	639c                	ld	a5,0(a5)
    80004978:	c38d                	beqz	a5,8000499a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000497a:	4505                	li	a0,1
    8000497c:	9782                	jalr	a5
    8000497e:	892a                	mv	s2,a0
    80004980:	bf75                	j	8000493c <fileread+0x60>
    panic("fileread");
    80004982:	00004517          	auipc	a0,0x4
    80004986:	dd650513          	addi	a0,a0,-554 # 80008758 <syscalls+0x270>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>
    return -1;
    80004992:	597d                	li	s2,-1
    80004994:	b765                	j	8000493c <fileread+0x60>
      return -1;
    80004996:	597d                	li	s2,-1
    80004998:	b755                	j	8000493c <fileread+0x60>
    8000499a:	597d                	li	s2,-1
    8000499c:	b745                	j	8000493c <fileread+0x60>

000000008000499e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000499e:	715d                	addi	sp,sp,-80
    800049a0:	e486                	sd	ra,72(sp)
    800049a2:	e0a2                	sd	s0,64(sp)
    800049a4:	fc26                	sd	s1,56(sp)
    800049a6:	f84a                	sd	s2,48(sp)
    800049a8:	f44e                	sd	s3,40(sp)
    800049aa:	f052                	sd	s4,32(sp)
    800049ac:	ec56                	sd	s5,24(sp)
    800049ae:	e85a                	sd	s6,16(sp)
    800049b0:	e45e                	sd	s7,8(sp)
    800049b2:	e062                	sd	s8,0(sp)
    800049b4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049b6:	00954783          	lbu	a5,9(a0)
    800049ba:	10078663          	beqz	a5,80004ac6 <filewrite+0x128>
    800049be:	892a                	mv	s2,a0
    800049c0:	8aae                	mv	s5,a1
    800049c2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049c4:	411c                	lw	a5,0(a0)
    800049c6:	4705                	li	a4,1
    800049c8:	02e78263          	beq	a5,a4,800049ec <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049cc:	470d                	li	a4,3
    800049ce:	02e78663          	beq	a5,a4,800049fa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049d2:	4709                	li	a4,2
    800049d4:	0ee79163          	bne	a5,a4,80004ab6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049d8:	0ac05d63          	blez	a2,80004a92 <filewrite+0xf4>
    int i = 0;
    800049dc:	4981                	li	s3,0
    800049de:	6b05                	lui	s6,0x1
    800049e0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049e4:	6b85                	lui	s7,0x1
    800049e6:	c00b8b9b          	addiw	s7,s7,-1024
    800049ea:	a861                	j	80004a82 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049ec:	6908                	ld	a0,16(a0)
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	22e080e7          	jalr	558(ra) # 80004c1c <pipewrite>
    800049f6:	8a2a                	mv	s4,a0
    800049f8:	a045                	j	80004a98 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049fa:	02451783          	lh	a5,36(a0)
    800049fe:	03079693          	slli	a3,a5,0x30
    80004a02:	92c1                	srli	a3,a3,0x30
    80004a04:	4725                	li	a4,9
    80004a06:	0cd76263          	bltu	a4,a3,80004aca <filewrite+0x12c>
    80004a0a:	0792                	slli	a5,a5,0x4
    80004a0c:	0001d717          	auipc	a4,0x1d
    80004a10:	f2c70713          	addi	a4,a4,-212 # 80021938 <devsw>
    80004a14:	97ba                	add	a5,a5,a4
    80004a16:	679c                	ld	a5,8(a5)
    80004a18:	cbdd                	beqz	a5,80004ace <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a1a:	4505                	li	a0,1
    80004a1c:	9782                	jalr	a5
    80004a1e:	8a2a                	mv	s4,a0
    80004a20:	a8a5                	j	80004a98 <filewrite+0xfa>
    80004a22:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	8b0080e7          	jalr	-1872(ra) # 800042d6 <begin_op>
      ilock(f->ip);
    80004a2e:	01893503          	ld	a0,24(s2)
    80004a32:	fffff097          	auipc	ra,0xfffff
    80004a36:	ed2080e7          	jalr	-302(ra) # 80003904 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a3a:	8762                	mv	a4,s8
    80004a3c:	02092683          	lw	a3,32(s2)
    80004a40:	01598633          	add	a2,s3,s5
    80004a44:	4585                	li	a1,1
    80004a46:	01893503          	ld	a0,24(s2)
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	266080e7          	jalr	614(ra) # 80003cb0 <writei>
    80004a52:	84aa                	mv	s1,a0
    80004a54:	00a05763          	blez	a0,80004a62 <filewrite+0xc4>
        f->off += r;
    80004a58:	02092783          	lw	a5,32(s2)
    80004a5c:	9fa9                	addw	a5,a5,a0
    80004a5e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a62:	01893503          	ld	a0,24(s2)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	f60080e7          	jalr	-160(ra) # 800039c6 <iunlock>
      end_op();
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	8e8080e7          	jalr	-1816(ra) # 80004356 <end_op>

      if(r != n1){
    80004a76:	009c1f63          	bne	s8,s1,80004a94 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a7a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a7e:	0149db63          	bge	s3,s4,80004a94 <filewrite+0xf6>
      int n1 = n - i;
    80004a82:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a86:	84be                	mv	s1,a5
    80004a88:	2781                	sext.w	a5,a5
    80004a8a:	f8fb5ce3          	bge	s6,a5,80004a22 <filewrite+0x84>
    80004a8e:	84de                	mv	s1,s7
    80004a90:	bf49                	j	80004a22 <filewrite+0x84>
    int i = 0;
    80004a92:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a94:	013a1f63          	bne	s4,s3,80004ab2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a98:	8552                	mv	a0,s4
    80004a9a:	60a6                	ld	ra,72(sp)
    80004a9c:	6406                	ld	s0,64(sp)
    80004a9e:	74e2                	ld	s1,56(sp)
    80004aa0:	7942                	ld	s2,48(sp)
    80004aa2:	79a2                	ld	s3,40(sp)
    80004aa4:	7a02                	ld	s4,32(sp)
    80004aa6:	6ae2                	ld	s5,24(sp)
    80004aa8:	6b42                	ld	s6,16(sp)
    80004aaa:	6ba2                	ld	s7,8(sp)
    80004aac:	6c02                	ld	s8,0(sp)
    80004aae:	6161                	addi	sp,sp,80
    80004ab0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ab2:	5a7d                	li	s4,-1
    80004ab4:	b7d5                	j	80004a98 <filewrite+0xfa>
    panic("filewrite");
    80004ab6:	00004517          	auipc	a0,0x4
    80004aba:	cb250513          	addi	a0,a0,-846 # 80008768 <syscalls+0x280>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	a80080e7          	jalr	-1408(ra) # 8000053e <panic>
    return -1;
    80004ac6:	5a7d                	li	s4,-1
    80004ac8:	bfc1                	j	80004a98 <filewrite+0xfa>
      return -1;
    80004aca:	5a7d                	li	s4,-1
    80004acc:	b7f1                	j	80004a98 <filewrite+0xfa>
    80004ace:	5a7d                	li	s4,-1
    80004ad0:	b7e1                	j	80004a98 <filewrite+0xfa>

0000000080004ad2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ad2:	7179                	addi	sp,sp,-48
    80004ad4:	f406                	sd	ra,40(sp)
    80004ad6:	f022                	sd	s0,32(sp)
    80004ad8:	ec26                	sd	s1,24(sp)
    80004ada:	e84a                	sd	s2,16(sp)
    80004adc:	e44e                	sd	s3,8(sp)
    80004ade:	e052                	sd	s4,0(sp)
    80004ae0:	1800                	addi	s0,sp,48
    80004ae2:	84aa                	mv	s1,a0
    80004ae4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ae6:	0005b023          	sd	zero,0(a1)
    80004aea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	bf8080e7          	jalr	-1032(ra) # 800046e6 <filealloc>
    80004af6:	e088                	sd	a0,0(s1)
    80004af8:	c551                	beqz	a0,80004b84 <pipealloc+0xb2>
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	bec080e7          	jalr	-1044(ra) # 800046e6 <filealloc>
    80004b02:	00aa3023          	sd	a0,0(s4)
    80004b06:	c92d                	beqz	a0,80004b78 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	fec080e7          	jalr	-20(ra) # 80000af4 <kalloc>
    80004b10:	892a                	mv	s2,a0
    80004b12:	c125                	beqz	a0,80004b72 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b14:	4985                	li	s3,1
    80004b16:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b1a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b1e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b22:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b26:	00004597          	auipc	a1,0x4
    80004b2a:	c5258593          	addi	a1,a1,-942 # 80008778 <syscalls+0x290>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	026080e7          	jalr	38(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b36:	609c                	ld	a5,0(s1)
    80004b38:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b3c:	609c                	ld	a5,0(s1)
    80004b3e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b42:	609c                	ld	a5,0(s1)
    80004b44:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b48:	609c                	ld	a5,0(s1)
    80004b4a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b4e:	000a3783          	ld	a5,0(s4)
    80004b52:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b56:	000a3783          	ld	a5,0(s4)
    80004b5a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b5e:	000a3783          	ld	a5,0(s4)
    80004b62:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b66:	000a3783          	ld	a5,0(s4)
    80004b6a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b6e:	4501                	li	a0,0
    80004b70:	a025                	j	80004b98 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b72:	6088                	ld	a0,0(s1)
    80004b74:	e501                	bnez	a0,80004b7c <pipealloc+0xaa>
    80004b76:	a039                	j	80004b84 <pipealloc+0xb2>
    80004b78:	6088                	ld	a0,0(s1)
    80004b7a:	c51d                	beqz	a0,80004ba8 <pipealloc+0xd6>
    fileclose(*f0);
    80004b7c:	00000097          	auipc	ra,0x0
    80004b80:	c26080e7          	jalr	-986(ra) # 800047a2 <fileclose>
  if(*f1)
    80004b84:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b88:	557d                	li	a0,-1
  if(*f1)
    80004b8a:	c799                	beqz	a5,80004b98 <pipealloc+0xc6>
    fileclose(*f1);
    80004b8c:	853e                	mv	a0,a5
    80004b8e:	00000097          	auipc	ra,0x0
    80004b92:	c14080e7          	jalr	-1004(ra) # 800047a2 <fileclose>
  return -1;
    80004b96:	557d                	li	a0,-1
}
    80004b98:	70a2                	ld	ra,40(sp)
    80004b9a:	7402                	ld	s0,32(sp)
    80004b9c:	64e2                	ld	s1,24(sp)
    80004b9e:	6942                	ld	s2,16(sp)
    80004ba0:	69a2                	ld	s3,8(sp)
    80004ba2:	6a02                	ld	s4,0(sp)
    80004ba4:	6145                	addi	sp,sp,48
    80004ba6:	8082                	ret
  return -1;
    80004ba8:	557d                	li	a0,-1
    80004baa:	b7fd                	j	80004b98 <pipealloc+0xc6>

0000000080004bac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bac:	1101                	addi	sp,sp,-32
    80004bae:	ec06                	sd	ra,24(sp)
    80004bb0:	e822                	sd	s0,16(sp)
    80004bb2:	e426                	sd	s1,8(sp)
    80004bb4:	e04a                	sd	s2,0(sp)
    80004bb6:	1000                	addi	s0,sp,32
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	028080e7          	jalr	40(ra) # 80000be4 <acquire>
  if(writable){
    80004bc4:	02090d63          	beqz	s2,80004bfe <pipeclose+0x52>
    pi->writeopen = 0;
    80004bc8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bcc:	21848513          	addi	a0,s1,536
    80004bd0:	ffffe097          	auipc	ra,0xffffe
    80004bd4:	8bc080e7          	jalr	-1860(ra) # 8000248c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bd8:	2204b783          	ld	a5,544(s1)
    80004bdc:	eb95                	bnez	a5,80004c10 <pipeclose+0x64>
    release(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	0b8080e7          	jalr	184(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	e0e080e7          	jalr	-498(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bf2:	60e2                	ld	ra,24(sp)
    80004bf4:	6442                	ld	s0,16(sp)
    80004bf6:	64a2                	ld	s1,8(sp)
    80004bf8:	6902                	ld	s2,0(sp)
    80004bfa:	6105                	addi	sp,sp,32
    80004bfc:	8082                	ret
    pi->readopen = 0;
    80004bfe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c02:	21c48513          	addi	a0,s1,540
    80004c06:	ffffe097          	auipc	ra,0xffffe
    80004c0a:	886080e7          	jalr	-1914(ra) # 8000248c <wakeup>
    80004c0e:	b7e9                	j	80004bd8 <pipeclose+0x2c>
    release(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	086080e7          	jalr	134(ra) # 80000c98 <release>
}
    80004c1a:	bfe1                	j	80004bf2 <pipeclose+0x46>

0000000080004c1c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c1c:	7159                	addi	sp,sp,-112
    80004c1e:	f486                	sd	ra,104(sp)
    80004c20:	f0a2                	sd	s0,96(sp)
    80004c22:	eca6                	sd	s1,88(sp)
    80004c24:	e8ca                	sd	s2,80(sp)
    80004c26:	e4ce                	sd	s3,72(sp)
    80004c28:	e0d2                	sd	s4,64(sp)
    80004c2a:	fc56                	sd	s5,56(sp)
    80004c2c:	f85a                	sd	s6,48(sp)
    80004c2e:	f45e                	sd	s7,40(sp)
    80004c30:	f062                	sd	s8,32(sp)
    80004c32:	ec66                	sd	s9,24(sp)
    80004c34:	1880                	addi	s0,sp,112
    80004c36:	84aa                	mv	s1,a0
    80004c38:	8aae                	mv	s5,a1
    80004c3a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	034080e7          	jalr	52(ra) # 80001c70 <myproc>
    80004c44:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  while(i < n){
    80004c50:	0d405163          	blez	s4,80004d12 <pipewrite+0xf6>
    80004c54:	8ba6                	mv	s7,s1
  int i = 0;
    80004c56:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c58:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c5a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c5e:	21c48c13          	addi	s8,s1,540
    80004c62:	a08d                	j	80004cc4 <pipewrite+0xa8>
      release(&pi->lock);
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	032080e7          	jalr	50(ra) # 80000c98 <release>
      return -1;
    80004c6e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c70:	854a                	mv	a0,s2
    80004c72:	70a6                	ld	ra,104(sp)
    80004c74:	7406                	ld	s0,96(sp)
    80004c76:	64e6                	ld	s1,88(sp)
    80004c78:	6946                	ld	s2,80(sp)
    80004c7a:	69a6                	ld	s3,72(sp)
    80004c7c:	6a06                	ld	s4,64(sp)
    80004c7e:	7ae2                	ld	s5,56(sp)
    80004c80:	7b42                	ld	s6,48(sp)
    80004c82:	7ba2                	ld	s7,40(sp)
    80004c84:	7c02                	ld	s8,32(sp)
    80004c86:	6ce2                	ld	s9,24(sp)
    80004c88:	6165                	addi	sp,sp,112
    80004c8a:	8082                	ret
      wakeup(&pi->nread);
    80004c8c:	8566                	mv	a0,s9
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	7fe080e7          	jalr	2046(ra) # 8000248c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c96:	85de                	mv	a1,s7
    80004c98:	8562                	mv	a0,s8
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	656080e7          	jalr	1622(ra) # 800022f0 <sleep>
    80004ca2:	a839                	j	80004cc0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ca4:	21c4a783          	lw	a5,540(s1)
    80004ca8:	0017871b          	addiw	a4,a5,1
    80004cac:	20e4ae23          	sw	a4,540(s1)
    80004cb0:	1ff7f793          	andi	a5,a5,511
    80004cb4:	97a6                	add	a5,a5,s1
    80004cb6:	f9f44703          	lbu	a4,-97(s0)
    80004cba:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cbe:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cc0:	03495d63          	bge	s2,s4,80004cfa <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004cc4:	2204a783          	lw	a5,544(s1)
    80004cc8:	dfd1                	beqz	a5,80004c64 <pipewrite+0x48>
    80004cca:	0289a783          	lw	a5,40(s3)
    80004cce:	fbd9                	bnez	a5,80004c64 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cd0:	2184a783          	lw	a5,536(s1)
    80004cd4:	21c4a703          	lw	a4,540(s1)
    80004cd8:	2007879b          	addiw	a5,a5,512
    80004cdc:	faf708e3          	beq	a4,a5,80004c8c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce0:	4685                	li	a3,1
    80004ce2:	01590633          	add	a2,s2,s5
    80004ce6:	f9f40593          	addi	a1,s0,-97
    80004cea:	0689b503          	ld	a0,104(s3)
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	a10080e7          	jalr	-1520(ra) # 800016fe <copyin>
    80004cf6:	fb6517e3          	bne	a0,s6,80004ca4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cfa:	21848513          	addi	a0,s1,536
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	78e080e7          	jalr	1934(ra) # 8000248c <wakeup>
  release(&pi->lock);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	f90080e7          	jalr	-112(ra) # 80000c98 <release>
  return i;
    80004d10:	b785                	j	80004c70 <pipewrite+0x54>
  int i = 0;
    80004d12:	4901                	li	s2,0
    80004d14:	b7dd                	j	80004cfa <pipewrite+0xde>

0000000080004d16 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d16:	715d                	addi	sp,sp,-80
    80004d18:	e486                	sd	ra,72(sp)
    80004d1a:	e0a2                	sd	s0,64(sp)
    80004d1c:	fc26                	sd	s1,56(sp)
    80004d1e:	f84a                	sd	s2,48(sp)
    80004d20:	f44e                	sd	s3,40(sp)
    80004d22:	f052                	sd	s4,32(sp)
    80004d24:	ec56                	sd	s5,24(sp)
    80004d26:	e85a                	sd	s6,16(sp)
    80004d28:	0880                	addi	s0,sp,80
    80004d2a:	84aa                	mv	s1,a0
    80004d2c:	892e                	mv	s2,a1
    80004d2e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	f40080e7          	jalr	-192(ra) # 80001c70 <myproc>
    80004d38:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d3a:	8b26                	mv	s6,s1
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	ea6080e7          	jalr	-346(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d46:	2184a703          	lw	a4,536(s1)
    80004d4a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d4e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d52:	02f71463          	bne	a4,a5,80004d7a <piperead+0x64>
    80004d56:	2244a783          	lw	a5,548(s1)
    80004d5a:	c385                	beqz	a5,80004d7a <piperead+0x64>
    if(pr->killed){
    80004d5c:	028a2783          	lw	a5,40(s4)
    80004d60:	ebc1                	bnez	a5,80004df0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d62:	85da                	mv	a1,s6
    80004d64:	854e                	mv	a0,s3
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	58a080e7          	jalr	1418(ra) # 800022f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d6e:	2184a703          	lw	a4,536(s1)
    80004d72:	21c4a783          	lw	a5,540(s1)
    80004d76:	fef700e3          	beq	a4,a5,80004d56 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7a:	09505263          	blez	s5,80004dfe <piperead+0xe8>
    80004d7e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d80:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d82:	2184a783          	lw	a5,536(s1)
    80004d86:	21c4a703          	lw	a4,540(s1)
    80004d8a:	02f70d63          	beq	a4,a5,80004dc4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d8e:	0017871b          	addiw	a4,a5,1
    80004d92:	20e4ac23          	sw	a4,536(s1)
    80004d96:	1ff7f793          	andi	a5,a5,511
    80004d9a:	97a6                	add	a5,a5,s1
    80004d9c:	0187c783          	lbu	a5,24(a5)
    80004da0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da4:	4685                	li	a3,1
    80004da6:	fbf40613          	addi	a2,s0,-65
    80004daa:	85ca                	mv	a1,s2
    80004dac:	068a3503          	ld	a0,104(s4)
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	8c2080e7          	jalr	-1854(ra) # 80001672 <copyout>
    80004db8:	01650663          	beq	a0,s6,80004dc4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dbc:	2985                	addiw	s3,s3,1
    80004dbe:	0905                	addi	s2,s2,1
    80004dc0:	fd3a91e3          	bne	s5,s3,80004d82 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dc4:	21c48513          	addi	a0,s1,540
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	6c4080e7          	jalr	1732(ra) # 8000248c <wakeup>
  release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	ec6080e7          	jalr	-314(ra) # 80000c98 <release>
  return i;
}
    80004dda:	854e                	mv	a0,s3
    80004ddc:	60a6                	ld	ra,72(sp)
    80004dde:	6406                	ld	s0,64(sp)
    80004de0:	74e2                	ld	s1,56(sp)
    80004de2:	7942                	ld	s2,48(sp)
    80004de4:	79a2                	ld	s3,40(sp)
    80004de6:	7a02                	ld	s4,32(sp)
    80004de8:	6ae2                	ld	s5,24(sp)
    80004dea:	6b42                	ld	s6,16(sp)
    80004dec:	6161                	addi	sp,sp,80
    80004dee:	8082                	ret
      release(&pi->lock);
    80004df0:	8526                	mv	a0,s1
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	ea6080e7          	jalr	-346(ra) # 80000c98 <release>
      return -1;
    80004dfa:	59fd                	li	s3,-1
    80004dfc:	bff9                	j	80004dda <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dfe:	4981                	li	s3,0
    80004e00:	b7d1                	j	80004dc4 <piperead+0xae>

0000000080004e02 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e02:	df010113          	addi	sp,sp,-528
    80004e06:	20113423          	sd	ra,520(sp)
    80004e0a:	20813023          	sd	s0,512(sp)
    80004e0e:	ffa6                	sd	s1,504(sp)
    80004e10:	fbca                	sd	s2,496(sp)
    80004e12:	f7ce                	sd	s3,488(sp)
    80004e14:	f3d2                	sd	s4,480(sp)
    80004e16:	efd6                	sd	s5,472(sp)
    80004e18:	ebda                	sd	s6,464(sp)
    80004e1a:	e7de                	sd	s7,456(sp)
    80004e1c:	e3e2                	sd	s8,448(sp)
    80004e1e:	ff66                	sd	s9,440(sp)
    80004e20:	fb6a                	sd	s10,432(sp)
    80004e22:	f76e                	sd	s11,424(sp)
    80004e24:	0c00                	addi	s0,sp,528
    80004e26:	84aa                	mv	s1,a0
    80004e28:	dea43c23          	sd	a0,-520(s0)
    80004e2c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	e40080e7          	jalr	-448(ra) # 80001c70 <myproc>
    80004e38:	892a                	mv	s2,a0

  begin_op();
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	49c080e7          	jalr	1180(ra) # 800042d6 <begin_op>

  if((ip = namei(path)) == 0){
    80004e42:	8526                	mv	a0,s1
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	276080e7          	jalr	630(ra) # 800040ba <namei>
    80004e4c:	c92d                	beqz	a0,80004ebe <exec+0xbc>
    80004e4e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	ab4080e7          	jalr	-1356(ra) # 80003904 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e58:	04000713          	li	a4,64
    80004e5c:	4681                	li	a3,0
    80004e5e:	e5040613          	addi	a2,s0,-432
    80004e62:	4581                	li	a1,0
    80004e64:	8526                	mv	a0,s1
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	d52080e7          	jalr	-686(ra) # 80003bb8 <readi>
    80004e6e:	04000793          	li	a5,64
    80004e72:	00f51a63          	bne	a0,a5,80004e86 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e76:	e5042703          	lw	a4,-432(s0)
    80004e7a:	464c47b7          	lui	a5,0x464c4
    80004e7e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e82:	04f70463          	beq	a4,a5,80004eca <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e86:	8526                	mv	a0,s1
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	cde080e7          	jalr	-802(ra) # 80003b66 <iunlockput>
    end_op();
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	4c6080e7          	jalr	1222(ra) # 80004356 <end_op>
  }
  return -1;
    80004e98:	557d                	li	a0,-1
}
    80004e9a:	20813083          	ld	ra,520(sp)
    80004e9e:	20013403          	ld	s0,512(sp)
    80004ea2:	74fe                	ld	s1,504(sp)
    80004ea4:	795e                	ld	s2,496(sp)
    80004ea6:	79be                	ld	s3,488(sp)
    80004ea8:	7a1e                	ld	s4,480(sp)
    80004eaa:	6afe                	ld	s5,472(sp)
    80004eac:	6b5e                	ld	s6,464(sp)
    80004eae:	6bbe                	ld	s7,456(sp)
    80004eb0:	6c1e                	ld	s8,448(sp)
    80004eb2:	7cfa                	ld	s9,440(sp)
    80004eb4:	7d5a                	ld	s10,432(sp)
    80004eb6:	7dba                	ld	s11,424(sp)
    80004eb8:	21010113          	addi	sp,sp,528
    80004ebc:	8082                	ret
    end_op();
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	498080e7          	jalr	1176(ra) # 80004356 <end_op>
    return -1;
    80004ec6:	557d                	li	a0,-1
    80004ec8:	bfc9                	j	80004e9a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eca:	854a                	mv	a0,s2
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	e68080e7          	jalr	-408(ra) # 80001d34 <proc_pagetable>
    80004ed4:	8baa                	mv	s7,a0
    80004ed6:	d945                	beqz	a0,80004e86 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed8:	e7042983          	lw	s3,-400(s0)
    80004edc:	e8845783          	lhu	a5,-376(s0)
    80004ee0:	c7ad                	beqz	a5,80004f4a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ee2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ee6:	6c85                	lui	s9,0x1
    80004ee8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eec:	def43823          	sd	a5,-528(s0)
    80004ef0:	a42d                	j	8000511a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ef2:	00004517          	auipc	a0,0x4
    80004ef6:	88e50513          	addi	a0,a0,-1906 # 80008780 <syscalls+0x298>
    80004efa:	ffffb097          	auipc	ra,0xffffb
    80004efe:	644080e7          	jalr	1604(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f02:	8756                	mv	a4,s5
    80004f04:	012d86bb          	addw	a3,s11,s2
    80004f08:	4581                	li	a1,0
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	cac080e7          	jalr	-852(ra) # 80003bb8 <readi>
    80004f14:	2501                	sext.w	a0,a0
    80004f16:	1aaa9963          	bne	s5,a0,800050c8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f1a:	6785                	lui	a5,0x1
    80004f1c:	0127893b          	addw	s2,a5,s2
    80004f20:	77fd                	lui	a5,0xfffff
    80004f22:	01478a3b          	addw	s4,a5,s4
    80004f26:	1f897163          	bgeu	s2,s8,80005108 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f2a:	02091593          	slli	a1,s2,0x20
    80004f2e:	9181                	srli	a1,a1,0x20
    80004f30:	95ea                	add	a1,a1,s10
    80004f32:	855e                	mv	a0,s7
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	13a080e7          	jalr	314(ra) # 8000106e <walkaddr>
    80004f3c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f3e:	d955                	beqz	a0,80004ef2 <exec+0xf0>
      n = PGSIZE;
    80004f40:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f42:	fd9a70e3          	bgeu	s4,s9,80004f02 <exec+0x100>
      n = sz - i;
    80004f46:	8ad2                	mv	s5,s4
    80004f48:	bf6d                	j	80004f02 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f4a:	4901                	li	s2,0
  iunlockput(ip);
    80004f4c:	8526                	mv	a0,s1
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	c18080e7          	jalr	-1000(ra) # 80003b66 <iunlockput>
  end_op();
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	400080e7          	jalr	1024(ra) # 80004356 <end_op>
  p = myproc();
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	d12080e7          	jalr	-750(ra) # 80001c70 <myproc>
    80004f66:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f68:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004f6c:	6785                	lui	a5,0x1
    80004f6e:	17fd                	addi	a5,a5,-1
    80004f70:	993e                	add	s2,s2,a5
    80004f72:	757d                	lui	a0,0xfffff
    80004f74:	00a977b3          	and	a5,s2,a0
    80004f78:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f7c:	6609                	lui	a2,0x2
    80004f7e:	963e                	add	a2,a2,a5
    80004f80:	85be                	mv	a1,a5
    80004f82:	855e                	mv	a0,s7
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	49e080e7          	jalr	1182(ra) # 80001422 <uvmalloc>
    80004f8c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f8e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f90:	12050c63          	beqz	a0,800050c8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f94:	75f9                	lui	a1,0xffffe
    80004f96:	95aa                	add	a1,a1,a0
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	6a6080e7          	jalr	1702(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fa2:	7c7d                	lui	s8,0xfffff
    80004fa4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fa6:	e0043783          	ld	a5,-512(s0)
    80004faa:	6388                	ld	a0,0(a5)
    80004fac:	c535                	beqz	a0,80005018 <exec+0x216>
    80004fae:	e9040993          	addi	s3,s0,-368
    80004fb2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fb6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	eac080e7          	jalr	-340(ra) # 80000e64 <strlen>
    80004fc0:	2505                	addiw	a0,a0,1
    80004fc2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fc6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fca:	13896363          	bltu	s2,s8,800050f0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fce:	e0043d83          	ld	s11,-512(s0)
    80004fd2:	000dba03          	ld	s4,0(s11)
    80004fd6:	8552                	mv	a0,s4
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	e8c080e7          	jalr	-372(ra) # 80000e64 <strlen>
    80004fe0:	0015069b          	addiw	a3,a0,1
    80004fe4:	8652                	mv	a2,s4
    80004fe6:	85ca                	mv	a1,s2
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	688080e7          	jalr	1672(ra) # 80001672 <copyout>
    80004ff2:	10054363          	bltz	a0,800050f8 <exec+0x2f6>
    ustack[argc] = sp;
    80004ff6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ffa:	0485                	addi	s1,s1,1
    80004ffc:	008d8793          	addi	a5,s11,8
    80005000:	e0f43023          	sd	a5,-512(s0)
    80005004:	008db503          	ld	a0,8(s11)
    80005008:	c911                	beqz	a0,8000501c <exec+0x21a>
    if(argc >= MAXARG)
    8000500a:	09a1                	addi	s3,s3,8
    8000500c:	fb3c96e3          	bne	s9,s3,80004fb8 <exec+0x1b6>
  sz = sz1;
    80005010:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005014:	4481                	li	s1,0
    80005016:	a84d                	j	800050c8 <exec+0x2c6>
  sp = sz;
    80005018:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000501a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000501c:	00349793          	slli	a5,s1,0x3
    80005020:	f9040713          	addi	a4,s0,-112
    80005024:	97ba                	add	a5,a5,a4
    80005026:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000502a:	00148693          	addi	a3,s1,1
    8000502e:	068e                	slli	a3,a3,0x3
    80005030:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005034:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005038:	01897663          	bgeu	s2,s8,80005044 <exec+0x242>
  sz = sz1;
    8000503c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005040:	4481                	li	s1,0
    80005042:	a059                	j	800050c8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005044:	e9040613          	addi	a2,s0,-368
    80005048:	85ca                	mv	a1,s2
    8000504a:	855e                	mv	a0,s7
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	626080e7          	jalr	1574(ra) # 80001672 <copyout>
    80005054:	0a054663          	bltz	a0,80005100 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005058:	070ab783          	ld	a5,112(s5)
    8000505c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005060:	df843783          	ld	a5,-520(s0)
    80005064:	0007c703          	lbu	a4,0(a5)
    80005068:	cf11                	beqz	a4,80005084 <exec+0x282>
    8000506a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000506c:	02f00693          	li	a3,47
    80005070:	a039                	j	8000507e <exec+0x27c>
      last = s+1;
    80005072:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005076:	0785                	addi	a5,a5,1
    80005078:	fff7c703          	lbu	a4,-1(a5)
    8000507c:	c701                	beqz	a4,80005084 <exec+0x282>
    if(*s == '/')
    8000507e:	fed71ce3          	bne	a4,a3,80005076 <exec+0x274>
    80005082:	bfc5                	j	80005072 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005084:	4641                	li	a2,16
    80005086:	df843583          	ld	a1,-520(s0)
    8000508a:	170a8513          	addi	a0,s5,368
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	da4080e7          	jalr	-604(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005096:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    8000509a:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    8000509e:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050a2:	070ab783          	ld	a5,112(s5)
    800050a6:	e6843703          	ld	a4,-408(s0)
    800050aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ac:	070ab783          	ld	a5,112(s5)
    800050b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050b4:	85ea                	mv	a1,s10
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	d1a080e7          	jalr	-742(ra) # 80001dd0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050be:	0004851b          	sext.w	a0,s1
    800050c2:	bbe1                	j	80004e9a <exec+0x98>
    800050c4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050c8:	e0843583          	ld	a1,-504(s0)
    800050cc:	855e                	mv	a0,s7
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	d02080e7          	jalr	-766(ra) # 80001dd0 <proc_freepagetable>
  if(ip){
    800050d6:	da0498e3          	bnez	s1,80004e86 <exec+0x84>
  return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	bb7d                	j	80004e9a <exec+0x98>
    800050de:	e1243423          	sd	s2,-504(s0)
    800050e2:	b7dd                	j	800050c8 <exec+0x2c6>
    800050e4:	e1243423          	sd	s2,-504(s0)
    800050e8:	b7c5                	j	800050c8 <exec+0x2c6>
    800050ea:	e1243423          	sd	s2,-504(s0)
    800050ee:	bfe9                	j	800050c8 <exec+0x2c6>
  sz = sz1;
    800050f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f4:	4481                	li	s1,0
    800050f6:	bfc9                	j	800050c8 <exec+0x2c6>
  sz = sz1;
    800050f8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050fc:	4481                	li	s1,0
    800050fe:	b7e9                	j	800050c8 <exec+0x2c6>
  sz = sz1;
    80005100:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005104:	4481                	li	s1,0
    80005106:	b7c9                	j	800050c8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005108:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000510c:	2b05                	addiw	s6,s6,1
    8000510e:	0389899b          	addiw	s3,s3,56
    80005112:	e8845783          	lhu	a5,-376(s0)
    80005116:	e2fb5be3          	bge	s6,a5,80004f4c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000511a:	2981                	sext.w	s3,s3
    8000511c:	03800713          	li	a4,56
    80005120:	86ce                	mv	a3,s3
    80005122:	e1840613          	addi	a2,s0,-488
    80005126:	4581                	li	a1,0
    80005128:	8526                	mv	a0,s1
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	a8e080e7          	jalr	-1394(ra) # 80003bb8 <readi>
    80005132:	03800793          	li	a5,56
    80005136:	f8f517e3          	bne	a0,a5,800050c4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000513a:	e1842783          	lw	a5,-488(s0)
    8000513e:	4705                	li	a4,1
    80005140:	fce796e3          	bne	a5,a4,8000510c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005144:	e4043603          	ld	a2,-448(s0)
    80005148:	e3843783          	ld	a5,-456(s0)
    8000514c:	f8f669e3          	bltu	a2,a5,800050de <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005150:	e2843783          	ld	a5,-472(s0)
    80005154:	963e                	add	a2,a2,a5
    80005156:	f8f667e3          	bltu	a2,a5,800050e4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000515a:	85ca                	mv	a1,s2
    8000515c:	855e                	mv	a0,s7
    8000515e:	ffffc097          	auipc	ra,0xffffc
    80005162:	2c4080e7          	jalr	708(ra) # 80001422 <uvmalloc>
    80005166:	e0a43423          	sd	a0,-504(s0)
    8000516a:	d141                	beqz	a0,800050ea <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000516c:	e2843d03          	ld	s10,-472(s0)
    80005170:	df043783          	ld	a5,-528(s0)
    80005174:	00fd77b3          	and	a5,s10,a5
    80005178:	fba1                	bnez	a5,800050c8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000517a:	e2042d83          	lw	s11,-480(s0)
    8000517e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005182:	f80c03e3          	beqz	s8,80005108 <exec+0x306>
    80005186:	8a62                	mv	s4,s8
    80005188:	4901                	li	s2,0
    8000518a:	b345                	j	80004f2a <exec+0x128>

000000008000518c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000518c:	7179                	addi	sp,sp,-48
    8000518e:	f406                	sd	ra,40(sp)
    80005190:	f022                	sd	s0,32(sp)
    80005192:	ec26                	sd	s1,24(sp)
    80005194:	e84a                	sd	s2,16(sp)
    80005196:	1800                	addi	s0,sp,48
    80005198:	892e                	mv	s2,a1
    8000519a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000519c:	fdc40593          	addi	a1,s0,-36
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	b90080e7          	jalr	-1136(ra) # 80002d30 <argint>
    800051a8:	04054063          	bltz	a0,800051e8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ac:	fdc42703          	lw	a4,-36(s0)
    800051b0:	47bd                	li	a5,15
    800051b2:	02e7ed63          	bltu	a5,a4,800051ec <argfd+0x60>
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	aba080e7          	jalr	-1350(ra) # 80001c70 <myproc>
    800051be:	fdc42703          	lw	a4,-36(s0)
    800051c2:	01c70793          	addi	a5,a4,28
    800051c6:	078e                	slli	a5,a5,0x3
    800051c8:	953e                	add	a0,a0,a5
    800051ca:	651c                	ld	a5,8(a0)
    800051cc:	c395                	beqz	a5,800051f0 <argfd+0x64>
    return -1;
  if(pfd)
    800051ce:	00090463          	beqz	s2,800051d6 <argfd+0x4a>
    *pfd = fd;
    800051d2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051d6:	4501                	li	a0,0
  if(pf)
    800051d8:	c091                	beqz	s1,800051dc <argfd+0x50>
    *pf = f;
    800051da:	e09c                	sd	a5,0(s1)
}
    800051dc:	70a2                	ld	ra,40(sp)
    800051de:	7402                	ld	s0,32(sp)
    800051e0:	64e2                	ld	s1,24(sp)
    800051e2:	6942                	ld	s2,16(sp)
    800051e4:	6145                	addi	sp,sp,48
    800051e6:	8082                	ret
    return -1;
    800051e8:	557d                	li	a0,-1
    800051ea:	bfcd                	j	800051dc <argfd+0x50>
    return -1;
    800051ec:	557d                	li	a0,-1
    800051ee:	b7fd                	j	800051dc <argfd+0x50>
    800051f0:	557d                	li	a0,-1
    800051f2:	b7ed                	j	800051dc <argfd+0x50>

00000000800051f4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051f4:	1101                	addi	sp,sp,-32
    800051f6:	ec06                	sd	ra,24(sp)
    800051f8:	e822                	sd	s0,16(sp)
    800051fa:	e426                	sd	s1,8(sp)
    800051fc:	1000                	addi	s0,sp,32
    800051fe:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005200:	ffffd097          	auipc	ra,0xffffd
    80005204:	a70080e7          	jalr	-1424(ra) # 80001c70 <myproc>
    80005208:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000520a:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    8000520e:	4501                	li	a0,0
    80005210:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005212:	6398                	ld	a4,0(a5)
    80005214:	cb19                	beqz	a4,8000522a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005216:	2505                	addiw	a0,a0,1
    80005218:	07a1                	addi	a5,a5,8
    8000521a:	fed51ce3          	bne	a0,a3,80005212 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000521e:	557d                	li	a0,-1
}
    80005220:	60e2                	ld	ra,24(sp)
    80005222:	6442                	ld	s0,16(sp)
    80005224:	64a2                	ld	s1,8(sp)
    80005226:	6105                	addi	sp,sp,32
    80005228:	8082                	ret
      p->ofile[fd] = f;
    8000522a:	01c50793          	addi	a5,a0,28
    8000522e:	078e                	slli	a5,a5,0x3
    80005230:	963e                	add	a2,a2,a5
    80005232:	e604                	sd	s1,8(a2)
      return fd;
    80005234:	b7f5                	j	80005220 <fdalloc+0x2c>

0000000080005236 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005236:	715d                	addi	sp,sp,-80
    80005238:	e486                	sd	ra,72(sp)
    8000523a:	e0a2                	sd	s0,64(sp)
    8000523c:	fc26                	sd	s1,56(sp)
    8000523e:	f84a                	sd	s2,48(sp)
    80005240:	f44e                	sd	s3,40(sp)
    80005242:	f052                	sd	s4,32(sp)
    80005244:	ec56                	sd	s5,24(sp)
    80005246:	0880                	addi	s0,sp,80
    80005248:	89ae                	mv	s3,a1
    8000524a:	8ab2                	mv	s5,a2
    8000524c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000524e:	fb040593          	addi	a1,s0,-80
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	e86080e7          	jalr	-378(ra) # 800040d8 <nameiparent>
    8000525a:	892a                	mv	s2,a0
    8000525c:	12050f63          	beqz	a0,8000539a <create+0x164>
    return 0;

  ilock(dp);
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	6a4080e7          	jalr	1700(ra) # 80003904 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005268:	4601                	li	a2,0
    8000526a:	fb040593          	addi	a1,s0,-80
    8000526e:	854a                	mv	a0,s2
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	b78080e7          	jalr	-1160(ra) # 80003de8 <dirlookup>
    80005278:	84aa                	mv	s1,a0
    8000527a:	c921                	beqz	a0,800052ca <create+0x94>
    iunlockput(dp);
    8000527c:	854a                	mv	a0,s2
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	8e8080e7          	jalr	-1816(ra) # 80003b66 <iunlockput>
    ilock(ip);
    80005286:	8526                	mv	a0,s1
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	67c080e7          	jalr	1660(ra) # 80003904 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005290:	2981                	sext.w	s3,s3
    80005292:	4789                	li	a5,2
    80005294:	02f99463          	bne	s3,a5,800052bc <create+0x86>
    80005298:	0444d783          	lhu	a5,68(s1)
    8000529c:	37f9                	addiw	a5,a5,-2
    8000529e:	17c2                	slli	a5,a5,0x30
    800052a0:	93c1                	srli	a5,a5,0x30
    800052a2:	4705                	li	a4,1
    800052a4:	00f76c63          	bltu	a4,a5,800052bc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052a8:	8526                	mv	a0,s1
    800052aa:	60a6                	ld	ra,72(sp)
    800052ac:	6406                	ld	s0,64(sp)
    800052ae:	74e2                	ld	s1,56(sp)
    800052b0:	7942                	ld	s2,48(sp)
    800052b2:	79a2                	ld	s3,40(sp)
    800052b4:	7a02                	ld	s4,32(sp)
    800052b6:	6ae2                	ld	s5,24(sp)
    800052b8:	6161                	addi	sp,sp,80
    800052ba:	8082                	ret
    iunlockput(ip);
    800052bc:	8526                	mv	a0,s1
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	8a8080e7          	jalr	-1880(ra) # 80003b66 <iunlockput>
    return 0;
    800052c6:	4481                	li	s1,0
    800052c8:	b7c5                	j	800052a8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ca:	85ce                	mv	a1,s3
    800052cc:	00092503          	lw	a0,0(s2)
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	49c080e7          	jalr	1180(ra) # 8000376c <ialloc>
    800052d8:	84aa                	mv	s1,a0
    800052da:	c529                	beqz	a0,80005324 <create+0xee>
  ilock(ip);
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	628080e7          	jalr	1576(ra) # 80003904 <ilock>
  ip->major = major;
    800052e4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052e8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052ec:	4785                	li	a5,1
    800052ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052f2:	8526                	mv	a0,s1
    800052f4:	ffffe097          	auipc	ra,0xffffe
    800052f8:	546080e7          	jalr	1350(ra) # 8000383a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052fc:	2981                	sext.w	s3,s3
    800052fe:	4785                	li	a5,1
    80005300:	02f98a63          	beq	s3,a5,80005334 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005304:	40d0                	lw	a2,4(s1)
    80005306:	fb040593          	addi	a1,s0,-80
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	cec080e7          	jalr	-788(ra) # 80003ff8 <dirlink>
    80005314:	06054b63          	bltz	a0,8000538a <create+0x154>
  iunlockput(dp);
    80005318:	854a                	mv	a0,s2
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	84c080e7          	jalr	-1972(ra) # 80003b66 <iunlockput>
  return ip;
    80005322:	b759                	j	800052a8 <create+0x72>
    panic("create: ialloc");
    80005324:	00003517          	auipc	a0,0x3
    80005328:	47c50513          	addi	a0,a0,1148 # 800087a0 <syscalls+0x2b8>
    8000532c:	ffffb097          	auipc	ra,0xffffb
    80005330:	212080e7          	jalr	530(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005334:	04a95783          	lhu	a5,74(s2)
    80005338:	2785                	addiw	a5,a5,1
    8000533a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000533e:	854a                	mv	a0,s2
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	4fa080e7          	jalr	1274(ra) # 8000383a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005348:	40d0                	lw	a2,4(s1)
    8000534a:	00003597          	auipc	a1,0x3
    8000534e:	46658593          	addi	a1,a1,1126 # 800087b0 <syscalls+0x2c8>
    80005352:	8526                	mv	a0,s1
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	ca4080e7          	jalr	-860(ra) # 80003ff8 <dirlink>
    8000535c:	00054f63          	bltz	a0,8000537a <create+0x144>
    80005360:	00492603          	lw	a2,4(s2)
    80005364:	00003597          	auipc	a1,0x3
    80005368:	45458593          	addi	a1,a1,1108 # 800087b8 <syscalls+0x2d0>
    8000536c:	8526                	mv	a0,s1
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	c8a080e7          	jalr	-886(ra) # 80003ff8 <dirlink>
    80005376:	f80557e3          	bgez	a0,80005304 <create+0xce>
      panic("create dots");
    8000537a:	00003517          	auipc	a0,0x3
    8000537e:	44650513          	addi	a0,a0,1094 # 800087c0 <syscalls+0x2d8>
    80005382:	ffffb097          	auipc	ra,0xffffb
    80005386:	1bc080e7          	jalr	444(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000538a:	00003517          	auipc	a0,0x3
    8000538e:	44650513          	addi	a0,a0,1094 # 800087d0 <syscalls+0x2e8>
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>
    return 0;
    8000539a:	84aa                	mv	s1,a0
    8000539c:	b731                	j	800052a8 <create+0x72>

000000008000539e <sys_dup>:
{
    8000539e:	7179                	addi	sp,sp,-48
    800053a0:	f406                	sd	ra,40(sp)
    800053a2:	f022                	sd	s0,32(sp)
    800053a4:	ec26                	sd	s1,24(sp)
    800053a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053a8:	fd840613          	addi	a2,s0,-40
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	ddc080e7          	jalr	-548(ra) # 8000518c <argfd>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ba:	02054363          	bltz	a0,800053e0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053be:	fd843503          	ld	a0,-40(s0)
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	e32080e7          	jalr	-462(ra) # 800051f4 <fdalloc>
    800053ca:	84aa                	mv	s1,a0
    return -1;
    800053cc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ce:	00054963          	bltz	a0,800053e0 <sys_dup+0x42>
  filedup(f);
    800053d2:	fd843503          	ld	a0,-40(s0)
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	37a080e7          	jalr	890(ra) # 80004750 <filedup>
  return fd;
    800053de:	87a6                	mv	a5,s1
}
    800053e0:	853e                	mv	a0,a5
    800053e2:	70a2                	ld	ra,40(sp)
    800053e4:	7402                	ld	s0,32(sp)
    800053e6:	64e2                	ld	s1,24(sp)
    800053e8:	6145                	addi	sp,sp,48
    800053ea:	8082                	ret

00000000800053ec <sys_read>:
{
    800053ec:	7179                	addi	sp,sp,-48
    800053ee:	f406                	sd	ra,40(sp)
    800053f0:	f022                	sd	s0,32(sp)
    800053f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f4:	fe840613          	addi	a2,s0,-24
    800053f8:	4581                	li	a1,0
    800053fa:	4501                	li	a0,0
    800053fc:	00000097          	auipc	ra,0x0
    80005400:	d90080e7          	jalr	-624(ra) # 8000518c <argfd>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005406:	04054163          	bltz	a0,80005448 <sys_read+0x5c>
    8000540a:	fe440593          	addi	a1,s0,-28
    8000540e:	4509                	li	a0,2
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	920080e7          	jalr	-1760(ra) # 80002d30 <argint>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541a:	02054763          	bltz	a0,80005448 <sys_read+0x5c>
    8000541e:	fd840593          	addi	a1,s0,-40
    80005422:	4505                	li	a0,1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	92e080e7          	jalr	-1746(ra) # 80002d52 <argaddr>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000542e:	00054d63          	bltz	a0,80005448 <sys_read+0x5c>
  return fileread(f, p, n);
    80005432:	fe442603          	lw	a2,-28(s0)
    80005436:	fd843583          	ld	a1,-40(s0)
    8000543a:	fe843503          	ld	a0,-24(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	49e080e7          	jalr	1182(ra) # 800048dc <fileread>
    80005446:	87aa                	mv	a5,a0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	70a2                	ld	ra,40(sp)
    8000544c:	7402                	ld	s0,32(sp)
    8000544e:	6145                	addi	sp,sp,48
    80005450:	8082                	ret

0000000080005452 <sys_write>:
{
    80005452:	7179                	addi	sp,sp,-48
    80005454:	f406                	sd	ra,40(sp)
    80005456:	f022                	sd	s0,32(sp)
    80005458:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	fe840613          	addi	a2,s0,-24
    8000545e:	4581                	li	a1,0
    80005460:	4501                	li	a0,0
    80005462:	00000097          	auipc	ra,0x0
    80005466:	d2a080e7          	jalr	-726(ra) # 8000518c <argfd>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546c:	04054163          	bltz	a0,800054ae <sys_write+0x5c>
    80005470:	fe440593          	addi	a1,s0,-28
    80005474:	4509                	li	a0,2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	8ba080e7          	jalr	-1862(ra) # 80002d30 <argint>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005480:	02054763          	bltz	a0,800054ae <sys_write+0x5c>
    80005484:	fd840593          	addi	a1,s0,-40
    80005488:	4505                	li	a0,1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	8c8080e7          	jalr	-1848(ra) # 80002d52 <argaddr>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005494:	00054d63          	bltz	a0,800054ae <sys_write+0x5c>
  return filewrite(f, p, n);
    80005498:	fe442603          	lw	a2,-28(s0)
    8000549c:	fd843583          	ld	a1,-40(s0)
    800054a0:	fe843503          	ld	a0,-24(s0)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	4fa080e7          	jalr	1274(ra) # 8000499e <filewrite>
    800054ac:	87aa                	mv	a5,a0
}
    800054ae:	853e                	mv	a0,a5
    800054b0:	70a2                	ld	ra,40(sp)
    800054b2:	7402                	ld	s0,32(sp)
    800054b4:	6145                	addi	sp,sp,48
    800054b6:	8082                	ret

00000000800054b8 <sys_close>:
{
    800054b8:	1101                	addi	sp,sp,-32
    800054ba:	ec06                	sd	ra,24(sp)
    800054bc:	e822                	sd	s0,16(sp)
    800054be:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054c0:	fe040613          	addi	a2,s0,-32
    800054c4:	fec40593          	addi	a1,s0,-20
    800054c8:	4501                	li	a0,0
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	cc2080e7          	jalr	-830(ra) # 8000518c <argfd>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054d4:	02054463          	bltz	a0,800054fc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	798080e7          	jalr	1944(ra) # 80001c70 <myproc>
    800054e0:	fec42783          	lw	a5,-20(s0)
    800054e4:	07f1                	addi	a5,a5,28
    800054e6:	078e                	slli	a5,a5,0x3
    800054e8:	97aa                	add	a5,a5,a0
    800054ea:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800054ee:	fe043503          	ld	a0,-32(s0)
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	2b0080e7          	jalr	688(ra) # 800047a2 <fileclose>
  return 0;
    800054fa:	4781                	li	a5,0
}
    800054fc:	853e                	mv	a0,a5
    800054fe:	60e2                	ld	ra,24(sp)
    80005500:	6442                	ld	s0,16(sp)
    80005502:	6105                	addi	sp,sp,32
    80005504:	8082                	ret

0000000080005506 <sys_fstat>:
{
    80005506:	1101                	addi	sp,sp,-32
    80005508:	ec06                	sd	ra,24(sp)
    8000550a:	e822                	sd	s0,16(sp)
    8000550c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000550e:	fe840613          	addi	a2,s0,-24
    80005512:	4581                	li	a1,0
    80005514:	4501                	li	a0,0
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	c76080e7          	jalr	-906(ra) # 8000518c <argfd>
    return -1;
    8000551e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005520:	02054563          	bltz	a0,8000554a <sys_fstat+0x44>
    80005524:	fe040593          	addi	a1,s0,-32
    80005528:	4505                	li	a0,1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	828080e7          	jalr	-2008(ra) # 80002d52 <argaddr>
    return -1;
    80005532:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005534:	00054b63          	bltz	a0,8000554a <sys_fstat+0x44>
  return filestat(f, st);
    80005538:	fe043583          	ld	a1,-32(s0)
    8000553c:	fe843503          	ld	a0,-24(s0)
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	32a080e7          	jalr	810(ra) # 8000486a <filestat>
    80005548:	87aa                	mv	a5,a0
}
    8000554a:	853e                	mv	a0,a5
    8000554c:	60e2                	ld	ra,24(sp)
    8000554e:	6442                	ld	s0,16(sp)
    80005550:	6105                	addi	sp,sp,32
    80005552:	8082                	ret

0000000080005554 <sys_link>:
{
    80005554:	7169                	addi	sp,sp,-304
    80005556:	f606                	sd	ra,296(sp)
    80005558:	f222                	sd	s0,288(sp)
    8000555a:	ee26                	sd	s1,280(sp)
    8000555c:	ea4a                	sd	s2,272(sp)
    8000555e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005560:	08000613          	li	a2,128
    80005564:	ed040593          	addi	a1,s0,-304
    80005568:	4501                	li	a0,0
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	80a080e7          	jalr	-2038(ra) # 80002d74 <argstr>
    return -1;
    80005572:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005574:	10054e63          	bltz	a0,80005690 <sys_link+0x13c>
    80005578:	08000613          	li	a2,128
    8000557c:	f5040593          	addi	a1,s0,-176
    80005580:	4505                	li	a0,1
    80005582:	ffffd097          	auipc	ra,0xffffd
    80005586:	7f2080e7          	jalr	2034(ra) # 80002d74 <argstr>
    return -1;
    8000558a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000558c:	10054263          	bltz	a0,80005690 <sys_link+0x13c>
  begin_op();
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	d46080e7          	jalr	-698(ra) # 800042d6 <begin_op>
  if((ip = namei(old)) == 0){
    80005598:	ed040513          	addi	a0,s0,-304
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	b1e080e7          	jalr	-1250(ra) # 800040ba <namei>
    800055a4:	84aa                	mv	s1,a0
    800055a6:	c551                	beqz	a0,80005632 <sys_link+0xde>
  ilock(ip);
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	35c080e7          	jalr	860(ra) # 80003904 <ilock>
  if(ip->type == T_DIR){
    800055b0:	04449703          	lh	a4,68(s1)
    800055b4:	4785                	li	a5,1
    800055b6:	08f70463          	beq	a4,a5,8000563e <sys_link+0xea>
  ip->nlink++;
    800055ba:	04a4d783          	lhu	a5,74(s1)
    800055be:	2785                	addiw	a5,a5,1
    800055c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	274080e7          	jalr	628(ra) # 8000383a <iupdate>
  iunlock(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	3f6080e7          	jalr	1014(ra) # 800039c6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055d8:	fd040593          	addi	a1,s0,-48
    800055dc:	f5040513          	addi	a0,s0,-176
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	af8080e7          	jalr	-1288(ra) # 800040d8 <nameiparent>
    800055e8:	892a                	mv	s2,a0
    800055ea:	c935                	beqz	a0,8000565e <sys_link+0x10a>
  ilock(dp);
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	318080e7          	jalr	792(ra) # 80003904 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055f4:	00092703          	lw	a4,0(s2)
    800055f8:	409c                	lw	a5,0(s1)
    800055fa:	04f71d63          	bne	a4,a5,80005654 <sys_link+0x100>
    800055fe:	40d0                	lw	a2,4(s1)
    80005600:	fd040593          	addi	a1,s0,-48
    80005604:	854a                	mv	a0,s2
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	9f2080e7          	jalr	-1550(ra) # 80003ff8 <dirlink>
    8000560e:	04054363          	bltz	a0,80005654 <sys_link+0x100>
  iunlockput(dp);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	552080e7          	jalr	1362(ra) # 80003b66 <iunlockput>
  iput(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	4a0080e7          	jalr	1184(ra) # 80003abe <iput>
  end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	d30080e7          	jalr	-720(ra) # 80004356 <end_op>
  return 0;
    8000562e:	4781                	li	a5,0
    80005630:	a085                	j	80005690 <sys_link+0x13c>
    end_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	d24080e7          	jalr	-732(ra) # 80004356 <end_op>
    return -1;
    8000563a:	57fd                	li	a5,-1
    8000563c:	a891                	j	80005690 <sys_link+0x13c>
    iunlockput(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	526080e7          	jalr	1318(ra) # 80003b66 <iunlockput>
    end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	d0e080e7          	jalr	-754(ra) # 80004356 <end_op>
    return -1;
    80005650:	57fd                	li	a5,-1
    80005652:	a83d                	j	80005690 <sys_link+0x13c>
    iunlockput(dp);
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	510080e7          	jalr	1296(ra) # 80003b66 <iunlockput>
  ilock(ip);
    8000565e:	8526                	mv	a0,s1
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	2a4080e7          	jalr	676(ra) # 80003904 <ilock>
  ip->nlink--;
    80005668:	04a4d783          	lhu	a5,74(s1)
    8000566c:	37fd                	addiw	a5,a5,-1
    8000566e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	1c6080e7          	jalr	454(ra) # 8000383a <iupdate>
  iunlockput(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	4e8080e7          	jalr	1256(ra) # 80003b66 <iunlockput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	cd0080e7          	jalr	-816(ra) # 80004356 <end_op>
  return -1;
    8000568e:	57fd                	li	a5,-1
}
    80005690:	853e                	mv	a0,a5
    80005692:	70b2                	ld	ra,296(sp)
    80005694:	7412                	ld	s0,288(sp)
    80005696:	64f2                	ld	s1,280(sp)
    80005698:	6952                	ld	s2,272(sp)
    8000569a:	6155                	addi	sp,sp,304
    8000569c:	8082                	ret

000000008000569e <sys_unlink>:
{
    8000569e:	7151                	addi	sp,sp,-240
    800056a0:	f586                	sd	ra,232(sp)
    800056a2:	f1a2                	sd	s0,224(sp)
    800056a4:	eda6                	sd	s1,216(sp)
    800056a6:	e9ca                	sd	s2,208(sp)
    800056a8:	e5ce                	sd	s3,200(sp)
    800056aa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056ac:	08000613          	li	a2,128
    800056b0:	f3040593          	addi	a1,s0,-208
    800056b4:	4501                	li	a0,0
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	6be080e7          	jalr	1726(ra) # 80002d74 <argstr>
    800056be:	18054163          	bltz	a0,80005840 <sys_unlink+0x1a2>
  begin_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	c14080e7          	jalr	-1004(ra) # 800042d6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ca:	fb040593          	addi	a1,s0,-80
    800056ce:	f3040513          	addi	a0,s0,-208
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	a06080e7          	jalr	-1530(ra) # 800040d8 <nameiparent>
    800056da:	84aa                	mv	s1,a0
    800056dc:	c979                	beqz	a0,800057b2 <sys_unlink+0x114>
  ilock(dp);
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	226080e7          	jalr	550(ra) # 80003904 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056e6:	00003597          	auipc	a1,0x3
    800056ea:	0ca58593          	addi	a1,a1,202 # 800087b0 <syscalls+0x2c8>
    800056ee:	fb040513          	addi	a0,s0,-80
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	6dc080e7          	jalr	1756(ra) # 80003dce <namecmp>
    800056fa:	14050a63          	beqz	a0,8000584e <sys_unlink+0x1b0>
    800056fe:	00003597          	auipc	a1,0x3
    80005702:	0ba58593          	addi	a1,a1,186 # 800087b8 <syscalls+0x2d0>
    80005706:	fb040513          	addi	a0,s0,-80
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	6c4080e7          	jalr	1732(ra) # 80003dce <namecmp>
    80005712:	12050e63          	beqz	a0,8000584e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005716:	f2c40613          	addi	a2,s0,-212
    8000571a:	fb040593          	addi	a1,s0,-80
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	6c8080e7          	jalr	1736(ra) # 80003de8 <dirlookup>
    80005728:	892a                	mv	s2,a0
    8000572a:	12050263          	beqz	a0,8000584e <sys_unlink+0x1b0>
  ilock(ip);
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	1d6080e7          	jalr	470(ra) # 80003904 <ilock>
  if(ip->nlink < 1)
    80005736:	04a91783          	lh	a5,74(s2)
    8000573a:	08f05263          	blez	a5,800057be <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000573e:	04491703          	lh	a4,68(s2)
    80005742:	4785                	li	a5,1
    80005744:	08f70563          	beq	a4,a5,800057ce <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005748:	4641                	li	a2,16
    8000574a:	4581                	li	a1,0
    8000574c:	fc040513          	addi	a0,s0,-64
    80005750:	ffffb097          	auipc	ra,0xffffb
    80005754:	590080e7          	jalr	1424(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005758:	4741                	li	a4,16
    8000575a:	f2c42683          	lw	a3,-212(s0)
    8000575e:	fc040613          	addi	a2,s0,-64
    80005762:	4581                	li	a1,0
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	54a080e7          	jalr	1354(ra) # 80003cb0 <writei>
    8000576e:	47c1                	li	a5,16
    80005770:	0af51563          	bne	a0,a5,8000581a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005774:	04491703          	lh	a4,68(s2)
    80005778:	4785                	li	a5,1
    8000577a:	0af70863          	beq	a4,a5,8000582a <sys_unlink+0x18c>
  iunlockput(dp);
    8000577e:	8526                	mv	a0,s1
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	3e6080e7          	jalr	998(ra) # 80003b66 <iunlockput>
  ip->nlink--;
    80005788:	04a95783          	lhu	a5,74(s2)
    8000578c:	37fd                	addiw	a5,a5,-1
    8000578e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	0a6080e7          	jalr	166(ra) # 8000383a <iupdate>
  iunlockput(ip);
    8000579c:	854a                	mv	a0,s2
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	3c8080e7          	jalr	968(ra) # 80003b66 <iunlockput>
  end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	bb0080e7          	jalr	-1104(ra) # 80004356 <end_op>
  return 0;
    800057ae:	4501                	li	a0,0
    800057b0:	a84d                	j	80005862 <sys_unlink+0x1c4>
    end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	ba4080e7          	jalr	-1116(ra) # 80004356 <end_op>
    return -1;
    800057ba:	557d                	li	a0,-1
    800057bc:	a05d                	j	80005862 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057be:	00003517          	auipc	a0,0x3
    800057c2:	02250513          	addi	a0,a0,34 # 800087e0 <syscalls+0x2f8>
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	d78080e7          	jalr	-648(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ce:	04c92703          	lw	a4,76(s2)
    800057d2:	02000793          	li	a5,32
    800057d6:	f6e7f9e3          	bgeu	a5,a4,80005748 <sys_unlink+0xaa>
    800057da:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057de:	4741                	li	a4,16
    800057e0:	86ce                	mv	a3,s3
    800057e2:	f1840613          	addi	a2,s0,-232
    800057e6:	4581                	li	a1,0
    800057e8:	854a                	mv	a0,s2
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	3ce080e7          	jalr	974(ra) # 80003bb8 <readi>
    800057f2:	47c1                	li	a5,16
    800057f4:	00f51b63          	bne	a0,a5,8000580a <sys_unlink+0x16c>
    if(de.inum != 0)
    800057f8:	f1845783          	lhu	a5,-232(s0)
    800057fc:	e7a1                	bnez	a5,80005844 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057fe:	29c1                	addiw	s3,s3,16
    80005800:	04c92783          	lw	a5,76(s2)
    80005804:	fcf9ede3          	bltu	s3,a5,800057de <sys_unlink+0x140>
    80005808:	b781                	j	80005748 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	fee50513          	addi	a0,a0,-18 # 800087f8 <syscalls+0x310>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000581a:	00003517          	auipc	a0,0x3
    8000581e:	ff650513          	addi	a0,a0,-10 # 80008810 <syscalls+0x328>
    80005822:	ffffb097          	auipc	ra,0xffffb
    80005826:	d1c080e7          	jalr	-740(ra) # 8000053e <panic>
    dp->nlink--;
    8000582a:	04a4d783          	lhu	a5,74(s1)
    8000582e:	37fd                	addiw	a5,a5,-1
    80005830:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	004080e7          	jalr	4(ra) # 8000383a <iupdate>
    8000583e:	b781                	j	8000577e <sys_unlink+0xe0>
    return -1;
    80005840:	557d                	li	a0,-1
    80005842:	a005                	j	80005862 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	320080e7          	jalr	800(ra) # 80003b66 <iunlockput>
  iunlockput(dp);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	316080e7          	jalr	790(ra) # 80003b66 <iunlockput>
  end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	afe080e7          	jalr	-1282(ra) # 80004356 <end_op>
  return -1;
    80005860:	557d                	li	a0,-1
}
    80005862:	70ae                	ld	ra,232(sp)
    80005864:	740e                	ld	s0,224(sp)
    80005866:	64ee                	ld	s1,216(sp)
    80005868:	694e                	ld	s2,208(sp)
    8000586a:	69ae                	ld	s3,200(sp)
    8000586c:	616d                	addi	sp,sp,240
    8000586e:	8082                	ret

0000000080005870 <sys_open>:

uint64
sys_open(void)
{
    80005870:	7131                	addi	sp,sp,-192
    80005872:	fd06                	sd	ra,184(sp)
    80005874:	f922                	sd	s0,176(sp)
    80005876:	f526                	sd	s1,168(sp)
    80005878:	f14a                	sd	s2,160(sp)
    8000587a:	ed4e                	sd	s3,152(sp)
    8000587c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000587e:	08000613          	li	a2,128
    80005882:	f5040593          	addi	a1,s0,-176
    80005886:	4501                	li	a0,0
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	4ec080e7          	jalr	1260(ra) # 80002d74 <argstr>
    return -1;
    80005890:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005892:	0c054163          	bltz	a0,80005954 <sys_open+0xe4>
    80005896:	f4c40593          	addi	a1,s0,-180
    8000589a:	4505                	li	a0,1
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	494080e7          	jalr	1172(ra) # 80002d30 <argint>
    800058a4:	0a054863          	bltz	a0,80005954 <sys_open+0xe4>

  begin_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	a2e080e7          	jalr	-1490(ra) # 800042d6 <begin_op>

  if(omode & O_CREATE){
    800058b0:	f4c42783          	lw	a5,-180(s0)
    800058b4:	2007f793          	andi	a5,a5,512
    800058b8:	cbdd                	beqz	a5,8000596e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058ba:	4681                	li	a3,0
    800058bc:	4601                	li	a2,0
    800058be:	4589                	li	a1,2
    800058c0:	f5040513          	addi	a0,s0,-176
    800058c4:	00000097          	auipc	ra,0x0
    800058c8:	972080e7          	jalr	-1678(ra) # 80005236 <create>
    800058cc:	892a                	mv	s2,a0
    if(ip == 0){
    800058ce:	c959                	beqz	a0,80005964 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058d0:	04491703          	lh	a4,68(s2)
    800058d4:	478d                	li	a5,3
    800058d6:	00f71763          	bne	a4,a5,800058e4 <sys_open+0x74>
    800058da:	04695703          	lhu	a4,70(s2)
    800058de:	47a5                	li	a5,9
    800058e0:	0ce7ec63          	bltu	a5,a4,800059b8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	e02080e7          	jalr	-510(ra) # 800046e6 <filealloc>
    800058ec:	89aa                	mv	s3,a0
    800058ee:	10050263          	beqz	a0,800059f2 <sys_open+0x182>
    800058f2:	00000097          	auipc	ra,0x0
    800058f6:	902080e7          	jalr	-1790(ra) # 800051f4 <fdalloc>
    800058fa:	84aa                	mv	s1,a0
    800058fc:	0e054663          	bltz	a0,800059e8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005900:	04491703          	lh	a4,68(s2)
    80005904:	478d                	li	a5,3
    80005906:	0cf70463          	beq	a4,a5,800059ce <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000590a:	4789                	li	a5,2
    8000590c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005910:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005914:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005918:	f4c42783          	lw	a5,-180(s0)
    8000591c:	0017c713          	xori	a4,a5,1
    80005920:	8b05                	andi	a4,a4,1
    80005922:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005926:	0037f713          	andi	a4,a5,3
    8000592a:	00e03733          	snez	a4,a4
    8000592e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005932:	4007f793          	andi	a5,a5,1024
    80005936:	c791                	beqz	a5,80005942 <sys_open+0xd2>
    80005938:	04491703          	lh	a4,68(s2)
    8000593c:	4789                	li	a5,2
    8000593e:	08f70f63          	beq	a4,a5,800059dc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005942:	854a                	mv	a0,s2
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	082080e7          	jalr	130(ra) # 800039c6 <iunlock>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	a0a080e7          	jalr	-1526(ra) # 80004356 <end_op>

  return fd;
}
    80005954:	8526                	mv	a0,s1
    80005956:	70ea                	ld	ra,184(sp)
    80005958:	744a                	ld	s0,176(sp)
    8000595a:	74aa                	ld	s1,168(sp)
    8000595c:	790a                	ld	s2,160(sp)
    8000595e:	69ea                	ld	s3,152(sp)
    80005960:	6129                	addi	sp,sp,192
    80005962:	8082                	ret
      end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	9f2080e7          	jalr	-1550(ra) # 80004356 <end_op>
      return -1;
    8000596c:	b7e5                	j	80005954 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000596e:	f5040513          	addi	a0,s0,-176
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	748080e7          	jalr	1864(ra) # 800040ba <namei>
    8000597a:	892a                	mv	s2,a0
    8000597c:	c905                	beqz	a0,800059ac <sys_open+0x13c>
    ilock(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	f86080e7          	jalr	-122(ra) # 80003904 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005986:	04491703          	lh	a4,68(s2)
    8000598a:	4785                	li	a5,1
    8000598c:	f4f712e3          	bne	a4,a5,800058d0 <sys_open+0x60>
    80005990:	f4c42783          	lw	a5,-180(s0)
    80005994:	dba1                	beqz	a5,800058e4 <sys_open+0x74>
      iunlockput(ip);
    80005996:	854a                	mv	a0,s2
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	1ce080e7          	jalr	462(ra) # 80003b66 <iunlockput>
      end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	9b6080e7          	jalr	-1610(ra) # 80004356 <end_op>
      return -1;
    800059a8:	54fd                	li	s1,-1
    800059aa:	b76d                	j	80005954 <sys_open+0xe4>
      end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	9aa080e7          	jalr	-1622(ra) # 80004356 <end_op>
      return -1;
    800059b4:	54fd                	li	s1,-1
    800059b6:	bf79                	j	80005954 <sys_open+0xe4>
    iunlockput(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	1ac080e7          	jalr	428(ra) # 80003b66 <iunlockput>
    end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	994080e7          	jalr	-1644(ra) # 80004356 <end_op>
    return -1;
    800059ca:	54fd                	li	s1,-1
    800059cc:	b761                	j	80005954 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059ce:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059d2:	04691783          	lh	a5,70(s2)
    800059d6:	02f99223          	sh	a5,36(s3)
    800059da:	bf2d                	j	80005914 <sys_open+0xa4>
    itrunc(ip);
    800059dc:	854a                	mv	a0,s2
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	034080e7          	jalr	52(ra) # 80003a12 <itrunc>
    800059e6:	bfb1                	j	80005942 <sys_open+0xd2>
      fileclose(f);
    800059e8:	854e                	mv	a0,s3
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	db8080e7          	jalr	-584(ra) # 800047a2 <fileclose>
    iunlockput(ip);
    800059f2:	854a                	mv	a0,s2
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	172080e7          	jalr	370(ra) # 80003b66 <iunlockput>
    end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	95a080e7          	jalr	-1702(ra) # 80004356 <end_op>
    return -1;
    80005a04:	54fd                	li	s1,-1
    80005a06:	b7b9                	j	80005954 <sys_open+0xe4>

0000000080005a08 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a08:	7175                	addi	sp,sp,-144
    80005a0a:	e506                	sd	ra,136(sp)
    80005a0c:	e122                	sd	s0,128(sp)
    80005a0e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	8c6080e7          	jalr	-1850(ra) # 800042d6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a18:	08000613          	li	a2,128
    80005a1c:	f7040593          	addi	a1,s0,-144
    80005a20:	4501                	li	a0,0
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	352080e7          	jalr	850(ra) # 80002d74 <argstr>
    80005a2a:	02054963          	bltz	a0,80005a5c <sys_mkdir+0x54>
    80005a2e:	4681                	li	a3,0
    80005a30:	4601                	li	a2,0
    80005a32:	4585                	li	a1,1
    80005a34:	f7040513          	addi	a0,s0,-144
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	7fe080e7          	jalr	2046(ra) # 80005236 <create>
    80005a40:	cd11                	beqz	a0,80005a5c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	124080e7          	jalr	292(ra) # 80003b66 <iunlockput>
  end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	90c080e7          	jalr	-1780(ra) # 80004356 <end_op>
  return 0;
    80005a52:	4501                	li	a0,0
}
    80005a54:	60aa                	ld	ra,136(sp)
    80005a56:	640a                	ld	s0,128(sp)
    80005a58:	6149                	addi	sp,sp,144
    80005a5a:	8082                	ret
    end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	8fa080e7          	jalr	-1798(ra) # 80004356 <end_op>
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	b7fd                	j	80005a54 <sys_mkdir+0x4c>

0000000080005a68 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a68:	7135                	addi	sp,sp,-160
    80005a6a:	ed06                	sd	ra,152(sp)
    80005a6c:	e922                	sd	s0,144(sp)
    80005a6e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	866080e7          	jalr	-1946(ra) # 800042d6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a78:	08000613          	li	a2,128
    80005a7c:	f7040593          	addi	a1,s0,-144
    80005a80:	4501                	li	a0,0
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	2f2080e7          	jalr	754(ra) # 80002d74 <argstr>
    80005a8a:	04054a63          	bltz	a0,80005ade <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a8e:	f6c40593          	addi	a1,s0,-148
    80005a92:	4505                	li	a0,1
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	29c080e7          	jalr	668(ra) # 80002d30 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9c:	04054163          	bltz	a0,80005ade <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005aa0:	f6840593          	addi	a1,s0,-152
    80005aa4:	4509                	li	a0,2
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	28a080e7          	jalr	650(ra) # 80002d30 <argint>
     argint(1, &major) < 0 ||
    80005aae:	02054863          	bltz	a0,80005ade <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab2:	f6841683          	lh	a3,-152(s0)
    80005ab6:	f6c41603          	lh	a2,-148(s0)
    80005aba:	458d                	li	a1,3
    80005abc:	f7040513          	addi	a0,s0,-144
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	776080e7          	jalr	1910(ra) # 80005236 <create>
     argint(2, &minor) < 0 ||
    80005ac8:	c919                	beqz	a0,80005ade <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	09c080e7          	jalr	156(ra) # 80003b66 <iunlockput>
  end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	884080e7          	jalr	-1916(ra) # 80004356 <end_op>
  return 0;
    80005ada:	4501                	li	a0,0
    80005adc:	a031                	j	80005ae8 <sys_mknod+0x80>
    end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	878080e7          	jalr	-1928(ra) # 80004356 <end_op>
    return -1;
    80005ae6:	557d                	li	a0,-1
}
    80005ae8:	60ea                	ld	ra,152(sp)
    80005aea:	644a                	ld	s0,144(sp)
    80005aec:	610d                	addi	sp,sp,160
    80005aee:	8082                	ret

0000000080005af0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af0:	7135                	addi	sp,sp,-160
    80005af2:	ed06                	sd	ra,152(sp)
    80005af4:	e922                	sd	s0,144(sp)
    80005af6:	e526                	sd	s1,136(sp)
    80005af8:	e14a                	sd	s2,128(sp)
    80005afa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	174080e7          	jalr	372(ra) # 80001c70 <myproc>
    80005b04:	892a                	mv	s2,a0
  
  begin_op();
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	7d0080e7          	jalr	2000(ra) # 800042d6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b0e:	08000613          	li	a2,128
    80005b12:	f6040593          	addi	a1,s0,-160
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	25c080e7          	jalr	604(ra) # 80002d74 <argstr>
    80005b20:	04054b63          	bltz	a0,80005b76 <sys_chdir+0x86>
    80005b24:	f6040513          	addi	a0,s0,-160
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	592080e7          	jalr	1426(ra) # 800040ba <namei>
    80005b30:	84aa                	mv	s1,a0
    80005b32:	c131                	beqz	a0,80005b76 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	dd0080e7          	jalr	-560(ra) # 80003904 <ilock>
  if(ip->type != T_DIR){
    80005b3c:	04449703          	lh	a4,68(s1)
    80005b40:	4785                	li	a5,1
    80005b42:	04f71063          	bne	a4,a5,80005b82 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	e7e080e7          	jalr	-386(ra) # 800039c6 <iunlock>
  iput(p->cwd);
    80005b50:	16893503          	ld	a0,360(s2)
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	f6a080e7          	jalr	-150(ra) # 80003abe <iput>
  end_op();
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	7fa080e7          	jalr	2042(ra) # 80004356 <end_op>
  p->cwd = ip;
    80005b64:	16993423          	sd	s1,360(s2)
  return 0;
    80005b68:	4501                	li	a0,0
}
    80005b6a:	60ea                	ld	ra,152(sp)
    80005b6c:	644a                	ld	s0,144(sp)
    80005b6e:	64aa                	ld	s1,136(sp)
    80005b70:	690a                	ld	s2,128(sp)
    80005b72:	610d                	addi	sp,sp,160
    80005b74:	8082                	ret
    end_op();
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	7e0080e7          	jalr	2016(ra) # 80004356 <end_op>
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	b7ed                	j	80005b6a <sys_chdir+0x7a>
    iunlockput(ip);
    80005b82:	8526                	mv	a0,s1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	fe2080e7          	jalr	-30(ra) # 80003b66 <iunlockput>
    end_op();
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	7ca080e7          	jalr	1994(ra) # 80004356 <end_op>
    return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	bfd1                	j	80005b6a <sys_chdir+0x7a>

0000000080005b98 <sys_exec>:

uint64
sys_exec(void)
{
    80005b98:	7145                	addi	sp,sp,-464
    80005b9a:	e786                	sd	ra,456(sp)
    80005b9c:	e3a2                	sd	s0,448(sp)
    80005b9e:	ff26                	sd	s1,440(sp)
    80005ba0:	fb4a                	sd	s2,432(sp)
    80005ba2:	f74e                	sd	s3,424(sp)
    80005ba4:	f352                	sd	s4,416(sp)
    80005ba6:	ef56                	sd	s5,408(sp)
    80005ba8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005baa:	08000613          	li	a2,128
    80005bae:	f4040593          	addi	a1,s0,-192
    80005bb2:	4501                	li	a0,0
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	1c0080e7          	jalr	448(ra) # 80002d74 <argstr>
    return -1;
    80005bbc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bbe:	0c054a63          	bltz	a0,80005c92 <sys_exec+0xfa>
    80005bc2:	e3840593          	addi	a1,s0,-456
    80005bc6:	4505                	li	a0,1
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	18a080e7          	jalr	394(ra) # 80002d52 <argaddr>
    80005bd0:	0c054163          	bltz	a0,80005c92 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bd4:	10000613          	li	a2,256
    80005bd8:	4581                	li	a1,0
    80005bda:	e4040513          	addi	a0,s0,-448
    80005bde:	ffffb097          	auipc	ra,0xffffb
    80005be2:	102080e7          	jalr	258(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005be6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bea:	89a6                	mv	s3,s1
    80005bec:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bee:	02000a13          	li	s4,32
    80005bf2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bf6:	00391513          	slli	a0,s2,0x3
    80005bfa:	e3040593          	addi	a1,s0,-464
    80005bfe:	e3843783          	ld	a5,-456(s0)
    80005c02:	953e                	add	a0,a0,a5
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	092080e7          	jalr	146(ra) # 80002c96 <fetchaddr>
    80005c0c:	02054a63          	bltz	a0,80005c40 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c10:	e3043783          	ld	a5,-464(s0)
    80005c14:	c3b9                	beqz	a5,80005c5a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c16:	ffffb097          	auipc	ra,0xffffb
    80005c1a:	ede080e7          	jalr	-290(ra) # 80000af4 <kalloc>
    80005c1e:	85aa                	mv	a1,a0
    80005c20:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c24:	cd11                	beqz	a0,80005c40 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c26:	6605                	lui	a2,0x1
    80005c28:	e3043503          	ld	a0,-464(s0)
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	0bc080e7          	jalr	188(ra) # 80002ce8 <fetchstr>
    80005c34:	00054663          	bltz	a0,80005c40 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c38:	0905                	addi	s2,s2,1
    80005c3a:	09a1                	addi	s3,s3,8
    80005c3c:	fb491be3          	bne	s2,s4,80005bf2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c40:	10048913          	addi	s2,s1,256
    80005c44:	6088                	ld	a0,0(s1)
    80005c46:	c529                	beqz	a0,80005c90 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	db0080e7          	jalr	-592(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c50:	04a1                	addi	s1,s1,8
    80005c52:	ff2499e3          	bne	s1,s2,80005c44 <sys_exec+0xac>
  return -1;
    80005c56:	597d                	li	s2,-1
    80005c58:	a82d                	j	80005c92 <sys_exec+0xfa>
      argv[i] = 0;
    80005c5a:	0a8e                	slli	s5,s5,0x3
    80005c5c:	fc040793          	addi	a5,s0,-64
    80005c60:	9abe                	add	s5,s5,a5
    80005c62:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c66:	e4040593          	addi	a1,s0,-448
    80005c6a:	f4040513          	addi	a0,s0,-192
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	194080e7          	jalr	404(ra) # 80004e02 <exec>
    80005c76:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c78:	10048993          	addi	s3,s1,256
    80005c7c:	6088                	ld	a0,0(s1)
    80005c7e:	c911                	beqz	a0,80005c92 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	d78080e7          	jalr	-648(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c88:	04a1                	addi	s1,s1,8
    80005c8a:	ff3499e3          	bne	s1,s3,80005c7c <sys_exec+0xe4>
    80005c8e:	a011                	j	80005c92 <sys_exec+0xfa>
  return -1;
    80005c90:	597d                	li	s2,-1
}
    80005c92:	854a                	mv	a0,s2
    80005c94:	60be                	ld	ra,456(sp)
    80005c96:	641e                	ld	s0,448(sp)
    80005c98:	74fa                	ld	s1,440(sp)
    80005c9a:	795a                	ld	s2,432(sp)
    80005c9c:	79ba                	ld	s3,424(sp)
    80005c9e:	7a1a                	ld	s4,416(sp)
    80005ca0:	6afa                	ld	s5,408(sp)
    80005ca2:	6179                	addi	sp,sp,464
    80005ca4:	8082                	ret

0000000080005ca6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ca6:	7139                	addi	sp,sp,-64
    80005ca8:	fc06                	sd	ra,56(sp)
    80005caa:	f822                	sd	s0,48(sp)
    80005cac:	f426                	sd	s1,40(sp)
    80005cae:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	fc0080e7          	jalr	-64(ra) # 80001c70 <myproc>
    80005cb8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cba:	fd840593          	addi	a1,s0,-40
    80005cbe:	4501                	li	a0,0
    80005cc0:	ffffd097          	auipc	ra,0xffffd
    80005cc4:	092080e7          	jalr	146(ra) # 80002d52 <argaddr>
    return -1;
    80005cc8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cca:	0e054063          	bltz	a0,80005daa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cce:	fc840593          	addi	a1,s0,-56
    80005cd2:	fd040513          	addi	a0,s0,-48
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	dfc080e7          	jalr	-516(ra) # 80004ad2 <pipealloc>
    return -1;
    80005cde:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ce0:	0c054563          	bltz	a0,80005daa <sys_pipe+0x104>
  fd0 = -1;
    80005ce4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ce8:	fd043503          	ld	a0,-48(s0)
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	508080e7          	jalr	1288(ra) # 800051f4 <fdalloc>
    80005cf4:	fca42223          	sw	a0,-60(s0)
    80005cf8:	08054c63          	bltz	a0,80005d90 <sys_pipe+0xea>
    80005cfc:	fc843503          	ld	a0,-56(s0)
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	4f4080e7          	jalr	1268(ra) # 800051f4 <fdalloc>
    80005d08:	fca42023          	sw	a0,-64(s0)
    80005d0c:	06054863          	bltz	a0,80005d7c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d10:	4691                	li	a3,4
    80005d12:	fc440613          	addi	a2,s0,-60
    80005d16:	fd843583          	ld	a1,-40(s0)
    80005d1a:	74a8                	ld	a0,104(s1)
    80005d1c:	ffffc097          	auipc	ra,0xffffc
    80005d20:	956080e7          	jalr	-1706(ra) # 80001672 <copyout>
    80005d24:	02054063          	bltz	a0,80005d44 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d28:	4691                	li	a3,4
    80005d2a:	fc040613          	addi	a2,s0,-64
    80005d2e:	fd843583          	ld	a1,-40(s0)
    80005d32:	0591                	addi	a1,a1,4
    80005d34:	74a8                	ld	a0,104(s1)
    80005d36:	ffffc097          	auipc	ra,0xffffc
    80005d3a:	93c080e7          	jalr	-1732(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d3e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d40:	06055563          	bgez	a0,80005daa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d44:	fc442783          	lw	a5,-60(s0)
    80005d48:	07f1                	addi	a5,a5,28
    80005d4a:	078e                	slli	a5,a5,0x3
    80005d4c:	97a6                	add	a5,a5,s1
    80005d4e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d52:	fc042503          	lw	a0,-64(s0)
    80005d56:	0571                	addi	a0,a0,28
    80005d58:	050e                	slli	a0,a0,0x3
    80005d5a:	9526                	add	a0,a0,s1
    80005d5c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d60:	fd043503          	ld	a0,-48(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	a3e080e7          	jalr	-1474(ra) # 800047a2 <fileclose>
    fileclose(wf);
    80005d6c:	fc843503          	ld	a0,-56(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	a32080e7          	jalr	-1486(ra) # 800047a2 <fileclose>
    return -1;
    80005d78:	57fd                	li	a5,-1
    80005d7a:	a805                	j	80005daa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d7c:	fc442783          	lw	a5,-60(s0)
    80005d80:	0007c863          	bltz	a5,80005d90 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d84:	01c78513          	addi	a0,a5,28
    80005d88:	050e                	slli	a0,a0,0x3
    80005d8a:	9526                	add	a0,a0,s1
    80005d8c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d90:	fd043503          	ld	a0,-48(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	a0e080e7          	jalr	-1522(ra) # 800047a2 <fileclose>
    fileclose(wf);
    80005d9c:	fc843503          	ld	a0,-56(s0)
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	a02080e7          	jalr	-1534(ra) # 800047a2 <fileclose>
    return -1;
    80005da8:	57fd                	li	a5,-1
}
    80005daa:	853e                	mv	a0,a5
    80005dac:	70e2                	ld	ra,56(sp)
    80005dae:	7442                	ld	s0,48(sp)
    80005db0:	74a2                	ld	s1,40(sp)
    80005db2:	6121                	addi	sp,sp,64
    80005db4:	8082                	ret
	...

0000000080005dc0 <kernelvec>:
    80005dc0:	7111                	addi	sp,sp,-256
    80005dc2:	e006                	sd	ra,0(sp)
    80005dc4:	e40a                	sd	sp,8(sp)
    80005dc6:	e80e                	sd	gp,16(sp)
    80005dc8:	ec12                	sd	tp,24(sp)
    80005dca:	f016                	sd	t0,32(sp)
    80005dcc:	f41a                	sd	t1,40(sp)
    80005dce:	f81e                	sd	t2,48(sp)
    80005dd0:	fc22                	sd	s0,56(sp)
    80005dd2:	e0a6                	sd	s1,64(sp)
    80005dd4:	e4aa                	sd	a0,72(sp)
    80005dd6:	e8ae                	sd	a1,80(sp)
    80005dd8:	ecb2                	sd	a2,88(sp)
    80005dda:	f0b6                	sd	a3,96(sp)
    80005ddc:	f4ba                	sd	a4,104(sp)
    80005dde:	f8be                	sd	a5,112(sp)
    80005de0:	fcc2                	sd	a6,120(sp)
    80005de2:	e146                	sd	a7,128(sp)
    80005de4:	e54a                	sd	s2,136(sp)
    80005de6:	e94e                	sd	s3,144(sp)
    80005de8:	ed52                	sd	s4,152(sp)
    80005dea:	f156                	sd	s5,160(sp)
    80005dec:	f55a                	sd	s6,168(sp)
    80005dee:	f95e                	sd	s7,176(sp)
    80005df0:	fd62                	sd	s8,184(sp)
    80005df2:	e1e6                	sd	s9,192(sp)
    80005df4:	e5ea                	sd	s10,200(sp)
    80005df6:	e9ee                	sd	s11,208(sp)
    80005df8:	edf2                	sd	t3,216(sp)
    80005dfa:	f1f6                	sd	t4,224(sp)
    80005dfc:	f5fa                	sd	t5,232(sp)
    80005dfe:	f9fe                	sd	t6,240(sp)
    80005e00:	d63fc0ef          	jal	ra,80002b62 <kerneltrap>
    80005e04:	6082                	ld	ra,0(sp)
    80005e06:	6122                	ld	sp,8(sp)
    80005e08:	61c2                	ld	gp,16(sp)
    80005e0a:	7282                	ld	t0,32(sp)
    80005e0c:	7322                	ld	t1,40(sp)
    80005e0e:	73c2                	ld	t2,48(sp)
    80005e10:	7462                	ld	s0,56(sp)
    80005e12:	6486                	ld	s1,64(sp)
    80005e14:	6526                	ld	a0,72(sp)
    80005e16:	65c6                	ld	a1,80(sp)
    80005e18:	6666                	ld	a2,88(sp)
    80005e1a:	7686                	ld	a3,96(sp)
    80005e1c:	7726                	ld	a4,104(sp)
    80005e1e:	77c6                	ld	a5,112(sp)
    80005e20:	7866                	ld	a6,120(sp)
    80005e22:	688a                	ld	a7,128(sp)
    80005e24:	692a                	ld	s2,136(sp)
    80005e26:	69ca                	ld	s3,144(sp)
    80005e28:	6a6a                	ld	s4,152(sp)
    80005e2a:	7a8a                	ld	s5,160(sp)
    80005e2c:	7b2a                	ld	s6,168(sp)
    80005e2e:	7bca                	ld	s7,176(sp)
    80005e30:	7c6a                	ld	s8,184(sp)
    80005e32:	6c8e                	ld	s9,192(sp)
    80005e34:	6d2e                	ld	s10,200(sp)
    80005e36:	6dce                	ld	s11,208(sp)
    80005e38:	6e6e                	ld	t3,216(sp)
    80005e3a:	7e8e                	ld	t4,224(sp)
    80005e3c:	7f2e                	ld	t5,232(sp)
    80005e3e:	7fce                	ld	t6,240(sp)
    80005e40:	6111                	addi	sp,sp,256
    80005e42:	10200073          	sret
    80005e46:	00000013          	nop
    80005e4a:	00000013          	nop
    80005e4e:	0001                	nop

0000000080005e50 <timervec>:
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	e10c                	sd	a1,0(a0)
    80005e56:	e510                	sd	a2,8(a0)
    80005e58:	e914                	sd	a3,16(a0)
    80005e5a:	6d0c                	ld	a1,24(a0)
    80005e5c:	7110                	ld	a2,32(a0)
    80005e5e:	6194                	ld	a3,0(a1)
    80005e60:	96b2                	add	a3,a3,a2
    80005e62:	e194                	sd	a3,0(a1)
    80005e64:	4589                	li	a1,2
    80005e66:	14459073          	csrw	sip,a1
    80005e6a:	6914                	ld	a3,16(a0)
    80005e6c:	6510                	ld	a2,8(a0)
    80005e6e:	610c                	ld	a1,0(a0)
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	30200073          	mret
	...

0000000080005e7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e7a:	1141                	addi	sp,sp,-16
    80005e7c:	e422                	sd	s0,8(sp)
    80005e7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e80:	0c0007b7          	lui	a5,0xc000
    80005e84:	4705                	li	a4,1
    80005e86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e88:	c3d8                	sw	a4,4(a5)
}
    80005e8a:	6422                	ld	s0,8(sp)
    80005e8c:	0141                	addi	sp,sp,16
    80005e8e:	8082                	ret

0000000080005e90 <plicinithart>:

void
plicinithart(void)
{
    80005e90:	1141                	addi	sp,sp,-16
    80005e92:	e406                	sd	ra,8(sp)
    80005e94:	e022                	sd	s0,0(sp)
    80005e96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	dac080e7          	jalr	-596(ra) # 80001c44 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ea0:	0085171b          	slliw	a4,a0,0x8
    80005ea4:	0c0027b7          	lui	a5,0xc002
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	40200713          	li	a4,1026
    80005eae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eb2:	00d5151b          	slliw	a0,a0,0xd
    80005eb6:	0c2017b7          	lui	a5,0xc201
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	00052023          	sw	zero,0(a0)
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	addi	sp,sp,16
    80005ec6:	8082                	ret

0000000080005ec8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ec8:	1141                	addi	sp,sp,-16
    80005eca:	e406                	sd	ra,8(sp)
    80005ecc:	e022                	sd	s0,0(sp)
    80005ece:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	d74080e7          	jalr	-652(ra) # 80001c44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ed8:	00d5179b          	slliw	a5,a0,0xd
    80005edc:	0c201537          	lui	a0,0xc201
    80005ee0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ee2:	4148                	lw	a0,4(a0)
    80005ee4:	60a2                	ld	ra,8(sp)
    80005ee6:	6402                	ld	s0,0(sp)
    80005ee8:	0141                	addi	sp,sp,16
    80005eea:	8082                	ret

0000000080005eec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eec:	1101                	addi	sp,sp,-32
    80005eee:	ec06                	sd	ra,24(sp)
    80005ef0:	e822                	sd	s0,16(sp)
    80005ef2:	e426                	sd	s1,8(sp)
    80005ef4:	1000                	addi	s0,sp,32
    80005ef6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	d4c080e7          	jalr	-692(ra) # 80001c44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f00:	00d5151b          	slliw	a0,a0,0xd
    80005f04:	0c2017b7          	lui	a5,0xc201
    80005f08:	97aa                	add	a5,a5,a0
    80005f0a:	c3c4                	sw	s1,4(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret

0000000080005f16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f16:	1141                	addi	sp,sp,-16
    80005f18:	e406                	sd	ra,8(sp)
    80005f1a:	e022                	sd	s0,0(sp)
    80005f1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f1e:	479d                	li	a5,7
    80005f20:	06a7c963          	blt	a5,a0,80005f92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f24:	0001d797          	auipc	a5,0x1d
    80005f28:	0dc78793          	addi	a5,a5,220 # 80023000 <disk>
    80005f2c:	00a78733          	add	a4,a5,a0
    80005f30:	6789                	lui	a5,0x2
    80005f32:	97ba                	add	a5,a5,a4
    80005f34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f38:	e7ad                	bnez	a5,80005fa2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f3a:	00451793          	slli	a5,a0,0x4
    80005f3e:	0001f717          	auipc	a4,0x1f
    80005f42:	0c270713          	addi	a4,a4,194 # 80025000 <disk+0x2000>
    80005f46:	6314                	ld	a3,0(a4)
    80005f48:	96be                	add	a3,a3,a5
    80005f4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f4e:	6314                	ld	a3,0(a4)
    80005f50:	96be                	add	a3,a3,a5
    80005f52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f56:	6314                	ld	a3,0(a4)
    80005f58:	96be                	add	a3,a3,a5
    80005f5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f5e:	6318                	ld	a4,0(a4)
    80005f60:	97ba                	add	a5,a5,a4
    80005f62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f66:	0001d797          	auipc	a5,0x1d
    80005f6a:	09a78793          	addi	a5,a5,154 # 80023000 <disk>
    80005f6e:	97aa                	add	a5,a5,a0
    80005f70:	6509                	lui	a0,0x2
    80005f72:	953e                	add	a0,a0,a5
    80005f74:	4785                	li	a5,1
    80005f76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	09e50513          	addi	a0,a0,158 # 80025018 <disk+0x2018>
    80005f82:	ffffc097          	auipc	ra,0xffffc
    80005f86:	50a080e7          	jalr	1290(ra) # 8000248c <wakeup>
}
    80005f8a:	60a2                	ld	ra,8(sp)
    80005f8c:	6402                	ld	s0,0(sp)
    80005f8e:	0141                	addi	sp,sp,16
    80005f90:	8082                	ret
    panic("free_desc 1");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	88e50513          	addi	a0,a0,-1906 # 80008820 <syscalls+0x338>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a4080e7          	jalr	1444(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	88e50513          	addi	a0,a0,-1906 # 80008830 <syscalls+0x348>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	594080e7          	jalr	1428(ra) # 8000053e <panic>

0000000080005fb2 <virtio_disk_init>:
{
    80005fb2:	1101                	addi	sp,sp,-32
    80005fb4:	ec06                	sd	ra,24(sp)
    80005fb6:	e822                	sd	s0,16(sp)
    80005fb8:	e426                	sd	s1,8(sp)
    80005fba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fbc:	00003597          	auipc	a1,0x3
    80005fc0:	88458593          	addi	a1,a1,-1916 # 80008840 <syscalls+0x358>
    80005fc4:	0001f517          	auipc	a0,0x1f
    80005fc8:	16450513          	addi	a0,a0,356 # 80025128 <disk+0x2128>
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	b88080e7          	jalr	-1144(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	4398                	lw	a4,0(a5)
    80005fda:	2701                	sext.w	a4,a4
    80005fdc:	747277b7          	lui	a5,0x74727
    80005fe0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fe4:	0ef71163          	bne	a4,a5,800060c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	43dc                	lw	a5,4(a5)
    80005fee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ff0:	4705                	li	a4,1
    80005ff2:	0ce79a63          	bne	a5,a4,800060c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff6:	100017b7          	lui	a5,0x10001
    80005ffa:	479c                	lw	a5,8(a5)
    80005ffc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ffe:	4709                	li	a4,2
    80006000:	0ce79363          	bne	a5,a4,800060c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006004:	100017b7          	lui	a5,0x10001
    80006008:	47d8                	lw	a4,12(a5)
    8000600a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600c:	554d47b7          	lui	a5,0x554d4
    80006010:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006014:	0af71963          	bne	a4,a5,800060c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	4705                	li	a4,1
    8000601e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006020:	470d                	li	a4,3
    80006022:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006024:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006026:	c7ffe737          	lui	a4,0xc7ffe
    8000602a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000602e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006030:	2701                	sext.w	a4,a4
    80006032:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006034:	472d                	li	a4,11
    80006036:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006038:	473d                	li	a4,15
    8000603a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000603c:	6705                	lui	a4,0x1
    8000603e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006040:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006044:	5bdc                	lw	a5,52(a5)
    80006046:	2781                	sext.w	a5,a5
  if(max == 0)
    80006048:	c7d9                	beqz	a5,800060d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000604a:	471d                	li	a4,7
    8000604c:	08f77d63          	bgeu	a4,a5,800060e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006050:	100014b7          	lui	s1,0x10001
    80006054:	47a1                	li	a5,8
    80006056:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006058:	6609                	lui	a2,0x2
    8000605a:	4581                	li	a1,0
    8000605c:	0001d517          	auipc	a0,0x1d
    80006060:	fa450513          	addi	a0,a0,-92 # 80023000 <disk>
    80006064:	ffffb097          	auipc	ra,0xffffb
    80006068:	c7c080e7          	jalr	-900(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000606c:	0001d717          	auipc	a4,0x1d
    80006070:	f9470713          	addi	a4,a4,-108 # 80023000 <disk>
    80006074:	00c75793          	srli	a5,a4,0xc
    80006078:	2781                	sext.w	a5,a5
    8000607a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000607c:	0001f797          	auipc	a5,0x1f
    80006080:	f8478793          	addi	a5,a5,-124 # 80025000 <disk+0x2000>
    80006084:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006086:	0001d717          	auipc	a4,0x1d
    8000608a:	ffa70713          	addi	a4,a4,-6 # 80023080 <disk+0x80>
    8000608e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006090:	0001e717          	auipc	a4,0x1e
    80006094:	f7070713          	addi	a4,a4,-144 # 80024000 <disk+0x1000>
    80006098:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000609a:	4705                	li	a4,1
    8000609c:	00e78c23          	sb	a4,24(a5)
    800060a0:	00e78ca3          	sb	a4,25(a5)
    800060a4:	00e78d23          	sb	a4,26(a5)
    800060a8:	00e78da3          	sb	a4,27(a5)
    800060ac:	00e78e23          	sb	a4,28(a5)
    800060b0:	00e78ea3          	sb	a4,29(a5)
    800060b4:	00e78f23          	sb	a4,30(a5)
    800060b8:	00e78fa3          	sb	a4,31(a5)
}
    800060bc:	60e2                	ld	ra,24(sp)
    800060be:	6442                	ld	s0,16(sp)
    800060c0:	64a2                	ld	s1,8(sp)
    800060c2:	6105                	addi	sp,sp,32
    800060c4:	8082                	ret
    panic("could not find virtio disk");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	78a50513          	addi	a0,a0,1930 # 80008850 <syscalls+0x368>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060d6:	00002517          	auipc	a0,0x2
    800060da:	79a50513          	addi	a0,a0,1946 # 80008870 <syscalls+0x388>
    800060de:	ffffa097          	auipc	ra,0xffffa
    800060e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060e6:	00002517          	auipc	a0,0x2
    800060ea:	7aa50513          	addi	a0,a0,1962 # 80008890 <syscalls+0x3a8>
    800060ee:	ffffa097          	auipc	ra,0xffffa
    800060f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>

00000000800060f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060f6:	7159                	addi	sp,sp,-112
    800060f8:	f486                	sd	ra,104(sp)
    800060fa:	f0a2                	sd	s0,96(sp)
    800060fc:	eca6                	sd	s1,88(sp)
    800060fe:	e8ca                	sd	s2,80(sp)
    80006100:	e4ce                	sd	s3,72(sp)
    80006102:	e0d2                	sd	s4,64(sp)
    80006104:	fc56                	sd	s5,56(sp)
    80006106:	f85a                	sd	s6,48(sp)
    80006108:	f45e                	sd	s7,40(sp)
    8000610a:	f062                	sd	s8,32(sp)
    8000610c:	ec66                	sd	s9,24(sp)
    8000610e:	e86a                	sd	s10,16(sp)
    80006110:	1880                	addi	s0,sp,112
    80006112:	892a                	mv	s2,a0
    80006114:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006116:	00c52c83          	lw	s9,12(a0)
    8000611a:	001c9c9b          	slliw	s9,s9,0x1
    8000611e:	1c82                	slli	s9,s9,0x20
    80006120:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006124:	0001f517          	auipc	a0,0x1f
    80006128:	00450513          	addi	a0,a0,4 # 80025128 <disk+0x2128>
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	ab8080e7          	jalr	-1352(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006134:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006136:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006138:	0001db97          	auipc	s7,0x1d
    8000613c:	ec8b8b93          	addi	s7,s7,-312 # 80023000 <disk>
    80006140:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006142:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006144:	8a4e                	mv	s4,s3
    80006146:	a051                	j	800061ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006148:	00fb86b3          	add	a3,s7,a5
    8000614c:	96da                	add	a3,a3,s6
    8000614e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006152:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006154:	0207c563          	bltz	a5,8000617e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006158:	2485                	addiw	s1,s1,1
    8000615a:	0711                	addi	a4,a4,4
    8000615c:	25548063          	beq	s1,s5,8000639c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006160:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006162:	0001f697          	auipc	a3,0x1f
    80006166:	eb668693          	addi	a3,a3,-330 # 80025018 <disk+0x2018>
    8000616a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000616c:	0006c583          	lbu	a1,0(a3)
    80006170:	fde1                	bnez	a1,80006148 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006172:	2785                	addiw	a5,a5,1
    80006174:	0685                	addi	a3,a3,1
    80006176:	ff879be3          	bne	a5,s8,8000616c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000617a:	57fd                	li	a5,-1
    8000617c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000617e:	02905a63          	blez	s1,800061b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006182:	f9042503          	lw	a0,-112(s0)
    80006186:	00000097          	auipc	ra,0x0
    8000618a:	d90080e7          	jalr	-624(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    8000618e:	4785                	li	a5,1
    80006190:	0297d163          	bge	a5,s1,800061b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006194:	f9442503          	lw	a0,-108(s0)
    80006198:	00000097          	auipc	ra,0x0
    8000619c:	d7e080e7          	jalr	-642(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    800061a0:	4789                	li	a5,2
    800061a2:	0097d863          	bge	a5,s1,800061b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061a6:	f9842503          	lw	a0,-104(s0)
    800061aa:	00000097          	auipc	ra,0x0
    800061ae:	d6c080e7          	jalr	-660(ra) # 80005f16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061b2:	0001f597          	auipc	a1,0x1f
    800061b6:	f7658593          	addi	a1,a1,-138 # 80025128 <disk+0x2128>
    800061ba:	0001f517          	auipc	a0,0x1f
    800061be:	e5e50513          	addi	a0,a0,-418 # 80025018 <disk+0x2018>
    800061c2:	ffffc097          	auipc	ra,0xffffc
    800061c6:	12e080e7          	jalr	302(ra) # 800022f0 <sleep>
  for(int i = 0; i < 3; i++){
    800061ca:	f9040713          	addi	a4,s0,-112
    800061ce:	84ce                	mv	s1,s3
    800061d0:	bf41                	j	80006160 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061d2:	20058713          	addi	a4,a1,512
    800061d6:	00471693          	slli	a3,a4,0x4
    800061da:	0001d717          	auipc	a4,0x1d
    800061de:	e2670713          	addi	a4,a4,-474 # 80023000 <disk>
    800061e2:	9736                	add	a4,a4,a3
    800061e4:	4685                	li	a3,1
    800061e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ea:	20058713          	addi	a4,a1,512
    800061ee:	00471693          	slli	a3,a4,0x4
    800061f2:	0001d717          	auipc	a4,0x1d
    800061f6:	e0e70713          	addi	a4,a4,-498 # 80023000 <disk>
    800061fa:	9736                	add	a4,a4,a3
    800061fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006200:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006204:	7679                	lui	a2,0xffffe
    80006206:	963e                	add	a2,a2,a5
    80006208:	0001f697          	auipc	a3,0x1f
    8000620c:	df868693          	addi	a3,a3,-520 # 80025000 <disk+0x2000>
    80006210:	6298                	ld	a4,0(a3)
    80006212:	9732                	add	a4,a4,a2
    80006214:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006216:	6298                	ld	a4,0(a3)
    80006218:	9732                	add	a4,a4,a2
    8000621a:	4541                	li	a0,16
    8000621c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000621e:	6298                	ld	a4,0(a3)
    80006220:	9732                	add	a4,a4,a2
    80006222:	4505                	li	a0,1
    80006224:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006228:	f9442703          	lw	a4,-108(s0)
    8000622c:	6288                	ld	a0,0(a3)
    8000622e:	962a                	add	a2,a2,a0
    80006230:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006234:	0712                	slli	a4,a4,0x4
    80006236:	6290                	ld	a2,0(a3)
    80006238:	963a                	add	a2,a2,a4
    8000623a:	05890513          	addi	a0,s2,88
    8000623e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006240:	6294                	ld	a3,0(a3)
    80006242:	96ba                	add	a3,a3,a4
    80006244:	40000613          	li	a2,1024
    80006248:	c690                	sw	a2,8(a3)
  if(write)
    8000624a:	140d0063          	beqz	s10,8000638a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000624e:	0001f697          	auipc	a3,0x1f
    80006252:	db26b683          	ld	a3,-590(a3) # 80025000 <disk+0x2000>
    80006256:	96ba                	add	a3,a3,a4
    80006258:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000625c:	0001d817          	auipc	a6,0x1d
    80006260:	da480813          	addi	a6,a6,-604 # 80023000 <disk>
    80006264:	0001f517          	auipc	a0,0x1f
    80006268:	d9c50513          	addi	a0,a0,-612 # 80025000 <disk+0x2000>
    8000626c:	6114                	ld	a3,0(a0)
    8000626e:	96ba                	add	a3,a3,a4
    80006270:	00c6d603          	lhu	a2,12(a3)
    80006274:	00166613          	ori	a2,a2,1
    80006278:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000627c:	f9842683          	lw	a3,-104(s0)
    80006280:	6110                	ld	a2,0(a0)
    80006282:	9732                	add	a4,a4,a2
    80006284:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006288:	20058613          	addi	a2,a1,512
    8000628c:	0612                	slli	a2,a2,0x4
    8000628e:	9642                	add	a2,a2,a6
    80006290:	577d                	li	a4,-1
    80006292:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006296:	00469713          	slli	a4,a3,0x4
    8000629a:	6114                	ld	a3,0(a0)
    8000629c:	96ba                	add	a3,a3,a4
    8000629e:	03078793          	addi	a5,a5,48
    800062a2:	97c2                	add	a5,a5,a6
    800062a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062a6:	611c                	ld	a5,0(a0)
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	4685                	li	a3,1
    800062ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062ae:	611c                	ld	a5,0(a0)
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	4809                	li	a6,2
    800062b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062b8:	611c                	ld	a5,0(a0)
    800062ba:	973e                	add	a4,a4,a5
    800062bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800062c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062c8:	6518                	ld	a4,8(a0)
    800062ca:	00275783          	lhu	a5,2(a4)
    800062ce:	8b9d                	andi	a5,a5,7
    800062d0:	0786                	slli	a5,a5,0x1
    800062d2:	97ba                	add	a5,a5,a4
    800062d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062dc:	6518                	ld	a4,8(a0)
    800062de:	00275783          	lhu	a5,2(a4)
    800062e2:	2785                	addiw	a5,a5,1
    800062e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ec:	100017b7          	lui	a5,0x10001
    800062f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f4:	00492703          	lw	a4,4(s2)
    800062f8:	4785                	li	a5,1
    800062fa:	02f71163          	bne	a4,a5,8000631c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062fe:	0001f997          	auipc	s3,0x1f
    80006302:	e2a98993          	addi	s3,s3,-470 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006306:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006308:	85ce                	mv	a1,s3
    8000630a:	854a                	mv	a0,s2
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	fe4080e7          	jalr	-28(ra) # 800022f0 <sleep>
  while(b->disk == 1) {
    80006314:	00492783          	lw	a5,4(s2)
    80006318:	fe9788e3          	beq	a5,s1,80006308 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000631c:	f9042903          	lw	s2,-112(s0)
    80006320:	20090793          	addi	a5,s2,512
    80006324:	00479713          	slli	a4,a5,0x4
    80006328:	0001d797          	auipc	a5,0x1d
    8000632c:	cd878793          	addi	a5,a5,-808 # 80023000 <disk>
    80006330:	97ba                	add	a5,a5,a4
    80006332:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006336:	0001f997          	auipc	s3,0x1f
    8000633a:	cca98993          	addi	s3,s3,-822 # 80025000 <disk+0x2000>
    8000633e:	00491713          	slli	a4,s2,0x4
    80006342:	0009b783          	ld	a5,0(s3)
    80006346:	97ba                	add	a5,a5,a4
    80006348:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000634c:	854a                	mv	a0,s2
    8000634e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006352:	00000097          	auipc	ra,0x0
    80006356:	bc4080e7          	jalr	-1084(ra) # 80005f16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000635a:	8885                	andi	s1,s1,1
    8000635c:	f0ed                	bnez	s1,8000633e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635e:	0001f517          	auipc	a0,0x1f
    80006362:	dca50513          	addi	a0,a0,-566 # 80025128 <disk+0x2128>
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
}
    8000636e:	70a6                	ld	ra,104(sp)
    80006370:	7406                	ld	s0,96(sp)
    80006372:	64e6                	ld	s1,88(sp)
    80006374:	6946                	ld	s2,80(sp)
    80006376:	69a6                	ld	s3,72(sp)
    80006378:	6a06                	ld	s4,64(sp)
    8000637a:	7ae2                	ld	s5,56(sp)
    8000637c:	7b42                	ld	s6,48(sp)
    8000637e:	7ba2                	ld	s7,40(sp)
    80006380:	7c02                	ld	s8,32(sp)
    80006382:	6ce2                	ld	s9,24(sp)
    80006384:	6d42                	ld	s10,16(sp)
    80006386:	6165                	addi	sp,sp,112
    80006388:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000638a:	0001f697          	auipc	a3,0x1f
    8000638e:	c766b683          	ld	a3,-906(a3) # 80025000 <disk+0x2000>
    80006392:	96ba                	add	a3,a3,a4
    80006394:	4609                	li	a2,2
    80006396:	00c69623          	sh	a2,12(a3)
    8000639a:	b5c9                	j	8000625c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000639c:	f9042583          	lw	a1,-112(s0)
    800063a0:	20058793          	addi	a5,a1,512
    800063a4:	0792                	slli	a5,a5,0x4
    800063a6:	0001d517          	auipc	a0,0x1d
    800063aa:	d0250513          	addi	a0,a0,-766 # 800230a8 <disk+0xa8>
    800063ae:	953e                	add	a0,a0,a5
  if(write)
    800063b0:	e20d11e3          	bnez	s10,800061d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063b4:	20058713          	addi	a4,a1,512
    800063b8:	00471693          	slli	a3,a4,0x4
    800063bc:	0001d717          	auipc	a4,0x1d
    800063c0:	c4470713          	addi	a4,a4,-956 # 80023000 <disk>
    800063c4:	9736                	add	a4,a4,a3
    800063c6:	0a072423          	sw	zero,168(a4)
    800063ca:	b505                	j	800061ea <virtio_disk_rw+0xf4>

00000000800063cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	e04a                	sd	s2,0(sp)
    800063d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063d8:	0001f517          	auipc	a0,0x1f
    800063dc:	d5050513          	addi	a0,a0,-688 # 80025128 <disk+0x2128>
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	804080e7          	jalr	-2044(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063e8:	10001737          	lui	a4,0x10001
    800063ec:	533c                	lw	a5,96(a4)
    800063ee:	8b8d                	andi	a5,a5,3
    800063f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063f6:	0001f797          	auipc	a5,0x1f
    800063fa:	c0a78793          	addi	a5,a5,-1014 # 80025000 <disk+0x2000>
    800063fe:	6b94                	ld	a3,16(a5)
    80006400:	0207d703          	lhu	a4,32(a5)
    80006404:	0026d783          	lhu	a5,2(a3)
    80006408:	06f70163          	beq	a4,a5,8000646a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000640c:	0001d917          	auipc	s2,0x1d
    80006410:	bf490913          	addi	s2,s2,-1036 # 80023000 <disk>
    80006414:	0001f497          	auipc	s1,0x1f
    80006418:	bec48493          	addi	s1,s1,-1044 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000641c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006420:	6898                	ld	a4,16(s1)
    80006422:	0204d783          	lhu	a5,32(s1)
    80006426:	8b9d                	andi	a5,a5,7
    80006428:	078e                	slli	a5,a5,0x3
    8000642a:	97ba                	add	a5,a5,a4
    8000642c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000642e:	20078713          	addi	a4,a5,512
    80006432:	0712                	slli	a4,a4,0x4
    80006434:	974a                	add	a4,a4,s2
    80006436:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000643a:	e731                	bnez	a4,80006486 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000643c:	20078793          	addi	a5,a5,512
    80006440:	0792                	slli	a5,a5,0x4
    80006442:	97ca                	add	a5,a5,s2
    80006444:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006446:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000644a:	ffffc097          	auipc	ra,0xffffc
    8000644e:	042080e7          	jalr	66(ra) # 8000248c <wakeup>

    disk.used_idx += 1;
    80006452:	0204d783          	lhu	a5,32(s1)
    80006456:	2785                	addiw	a5,a5,1
    80006458:	17c2                	slli	a5,a5,0x30
    8000645a:	93c1                	srli	a5,a5,0x30
    8000645c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006460:	6898                	ld	a4,16(s1)
    80006462:	00275703          	lhu	a4,2(a4)
    80006466:	faf71be3          	bne	a4,a5,8000641c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000646a:	0001f517          	auipc	a0,0x1f
    8000646e:	cbe50513          	addi	a0,a0,-834 # 80025128 <disk+0x2128>
    80006472:	ffffb097          	auipc	ra,0xffffb
    80006476:	826080e7          	jalr	-2010(ra) # 80000c98 <release>
}
    8000647a:	60e2                	ld	ra,24(sp)
    8000647c:	6442                	ld	s0,16(sp)
    8000647e:	64a2                	ld	s1,8(sp)
    80006480:	6902                	ld	s2,0(sp)
    80006482:	6105                	addi	sp,sp,32
    80006484:	8082                	ret
      panic("virtio_disk_intr status");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	42a50513          	addi	a0,a0,1066 # 800088b0 <syscalls+0x3c8>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
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
