
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	e5c78793          	addi	a5,a5,-420 # 80005ec0 <timervec>
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
    80000130:	6cc080e7          	jalr	1740(ra) # 800027f8 <either_copyin>
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
    800001c8:	b2c080e7          	jalr	-1236(ra) # 80001cf0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1b2080e7          	jalr	434(ra) # 80002386 <sleep>
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
    80000214:	592080e7          	jalr	1426(ra) # 800027a2 <either_copyout>
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
    800002f6:	55c080e7          	jalr	1372(ra) # 8000284e <procdump>
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
    8000044a:	0e6080e7          	jalr	230(ra) # 8000252c <wakeup>
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
    800008a4:	c8c080e7          	jalr	-884(ra) # 8000252c <wakeup>
    
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
    80000930:	a5a080e7          	jalr	-1446(ra) # 80002386 <sleep>
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
    80000b82:	156080e7          	jalr	342(ra) # 80001cd4 <mycpu>
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
    80000bb4:	124080e7          	jalr	292(ra) # 80001cd4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	118080e7          	jalr	280(ra) # 80001cd4 <mycpu>
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
    80000bd8:	100080e7          	jalr	256(ra) # 80001cd4 <mycpu>
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
    80000c18:	0c0080e7          	jalr	192(ra) # 80001cd4 <mycpu>
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
    80000c44:	094080e7          	jalr	148(ra) # 80001cd4 <mycpu>
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
    80000e9a:	e2e080e7          	jalr	-466(ra) # 80001cc4 <cpuid>
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
    80000eb6:	e12080e7          	jalr	-494(ra) # 80001cc4 <cpuid>
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
    80000ed8:	aba080e7          	jalr	-1350(ra) # 8000298e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	024080e7          	jalr	36(ra) # 80005f00 <plicinithart>
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
    80000f48:	cc0080e7          	jalr	-832(ra) # 80001c04 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	a1a080e7          	jalr	-1510(ra) # 80002966 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a3a080e7          	jalr	-1478(ra) # 8000298e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f8e080e7          	jalr	-114(ra) # 80005eea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f9c080e7          	jalr	-100(ra) # 80005f00 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	17e080e7          	jalr	382(ra) # 800030ea <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	80e080e7          	jalr	-2034(ra) # 80003782 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	7b8080e7          	jalr	1976(ra) # 80004734 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	09e080e7          	jalr	158(ra) # 80006022 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	050080e7          	jalr	80(ra) # 80001fdc <userinit>
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

0000000080001950 <kill_sys>:


int
kill_sys(void)
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
    80001986:	a811                	j	8000199a <kill_sys+0x4a>
      }
      //release(&p->lock);
    }
    release(&p->lock);
    80001988:	8526                	mv	a0,s1
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	30e080e7          	jalr	782(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001992:	18048493          	addi	s1,s1,384
    80001996:	03348b63          	beq	s1,s3,800019cc <kill_sys+0x7c>
    acquire(&p->lock);
    8000199a:	8526                	mv	a0,s1
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	248080e7          	jalr	584(ra) # 80000be4 <acquire>
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    800019a4:	589c                	lw	a5,48(s1)
    800019a6:	03092703          	lw	a4,48(s2) # 4000030 <_entry-0x7bffffd0>
    800019aa:	fcf70fe3          	beq	a4,a5,80001988 <kill_sys+0x38>
    800019ae:	1b092703          	lw	a4,432(s2)
    800019b2:	fcf70be3          	beq	a4,a5,80001988 <kill_sys+0x38>
      p->killed = 1;
    800019b6:	0354a423          	sw	s5,40(s1)
      if(p->state == SLEEPING){
    800019ba:	4c9c                	lw	a5,24(s1)
    800019bc:	fd4796e3          	bne	a5,s4,80001988 <kill_sys+0x38>
        p->state = RUNNABLE;
    800019c0:	0174ac23          	sw	s7,24(s1)
        p->last_runnable_time = ticks;
    800019c4:	000b2783          	lw	a5,0(s6)
    800019c8:	dcdc                	sw	a5,60(s1)
    800019ca:	bf7d                	j	80001988 <kill_sys+0x38>
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
#ifdef SJF
void
scheduler(void)
{
    80001a6c:	711d                	addi	sp,sp,-96
    80001a6e:	ec86                	sd	ra,88(sp)
    80001a70:	e8a2                	sd	s0,80(sp)
    80001a72:	e4a6                	sd	s1,72(sp)
    80001a74:	e0ca                	sd	s2,64(sp)
    80001a76:	fc4e                	sd	s3,56(sp)
    80001a78:	f852                	sd	s4,48(sp)
    80001a7a:	f456                	sd	s5,40(sp)
    80001a7c:	f05a                	sd	s6,32(sp)
    80001a7e:	ec5e                	sd	s7,24(sp)
    80001a80:	e862                	sd	s8,16(sp)
    80001a82:	e466                	sd	s9,8(sp)
    80001a84:	e06a                	sd	s10,0(sp)
    80001a86:	1080                	addi	s0,sp,96
  printf("SJF\n");
    80001a88:	00006517          	auipc	a0,0x6
    80001a8c:	7e850513          	addi	a0,a0,2024 # 80008270 <digits+0x230>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	af8080e7          	jalr	-1288(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a98:	8792                	mv	a5,tp
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
    80001a9a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001a9c:	00010b97          	auipc	s7,0x10
    80001aa0:	824b8b93          	addi	s7,s7,-2012 # 800112c0 <cpus>
    80001aa4:	00779713          	slli	a4,a5,0x7
    80001aa8:	00eb86b3          	add	a3,s7,a4
    80001aac:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
        swtch(&c->context, &p->context);
    80001ab0:	0721                	addi	a4,a4,8
    80001ab2:	9bba                	add	s7,s7,a4
    struct proc *tmp = &proc[0];
    80001ab4:	00010a17          	auipc	s4,0x10
    80001ab8:	c3ca0a13          	addi	s4,s4,-964 # 800116f0 <proc>
    int min = __INT_MAX__;
    80001abc:	80000ab7          	lui	s5,0x80000
    80001ac0:	fffaca93          	not	s5,s5
        if (p->state == RUNNABLE){
    80001ac4:	490d                	li	s2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ac6:	00016497          	auipc	s1,0x16
    80001aca:	c2a48493          	addi	s1,s1,-982 # 800176f0 <tickslock>
        c->proc = p;
    80001ace:	8b36                	mv	s6,a3
    80001ad0:	a08d                	j	80001b32 <scheduler+0xc6>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ad2:	18078793          	addi	a5,a5,384
    80001ad6:	00978b63          	beq	a5,s1,80001aec <scheduler+0x80>
      if (p->mean_ticks < min) {
    80001ada:	5bd8                	lw	a4,52(a5)
    80001adc:	fed75be3          	bge	a4,a3,80001ad2 <scheduler+0x66>
        if (p->state == RUNNABLE){
    80001ae0:	4f90                	lw	a2,24(a5)
    80001ae2:	ff2618e3          	bne	a2,s2,80001ad2 <scheduler+0x66>
    80001ae6:	89be                	mv	s3,a5
          min = tmp->mean_ticks;
    80001ae8:	86ba                	mv	a3,a4
    80001aea:	b7e5                	j	80001ad2 <scheduler+0x66>
    acquire(&p->lock);
    80001aec:	8c4e                	mv	s8,s3
    80001aee:	854e                	mv	a0,s3
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	0f4080e7          	jalr	244(ra) # 80000be4 <acquire>
    if ((finish < ticks) || (p->pid==proc[0].pid) || (p->pid==proc[1].pid)){
    80001af8:	00007d17          	auipc	s10,0x7
    80001afc:	558d2d03          	lw	s10,1368(s10) # 80009050 <ticks>
    80001b00:	00007797          	auipc	a5,0x7
    80001b04:	5447a783          	lw	a5,1348(a5) # 80009044 <finish>
    80001b08:	01a7ec63          	bltu	a5,s10,80001b20 <scheduler+0xb4>
    80001b0c:	0309a783          	lw	a5,48(s3)
    80001b10:	030a2703          	lw	a4,48(s4)
    80001b14:	00f70663          	beq	a4,a5,80001b20 <scheduler+0xb4>
    80001b18:	1b0a2703          	lw	a4,432(s4)
    80001b1c:	00f71663          	bne	a4,a5,80001b28 <scheduler+0xbc>
      if(p->state == RUNNABLE) {
    80001b20:	0189a783          	lw	a5,24(s3)
    80001b24:	03278163          	beq	a5,s2,80001b46 <scheduler+0xda>
  release(&p->lock);
    80001b28:	8562                	mv	a0,s8
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001b36:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001b3a:	10079073          	csrw	sstatus,a5
    struct proc *tmp = &proc[0];
    80001b3e:	89d2                	mv	s3,s4
    int min = __INT_MAX__;
    80001b40:	86d6                	mv	a3,s5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001b42:	87d2                	mv	a5,s4
    80001b44:	bf59                	j	80001ada <scheduler+0x6e>
        p->state = RUNNING;
    80001b46:	4791                	li	a5,4
    80001b48:	00f9ac23          	sw	a5,24(s3)
        c->proc = p;
    80001b4c:	013b3023          	sd	s3,0(s6)
        int ticks_now = ticks;
    80001b50:	000d0c9b          	sext.w	s9,s10
        if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b54:	0309a783          	lw	a5,48(s3)
    80001b58:	030a2703          	lw	a4,48(s4)
    80001b5c:	00f70f63          	beq	a4,a5,80001b7a <scheduler+0x10e>
    80001b60:	1b0a2703          	lw	a4,432(s4)
    80001b64:	00f70b63          	beq	a4,a5,80001b7a <scheduler+0x10e>
          p->runnable_time = p->runnable_time + ticks - p->last_runnable_time;
    80001b68:	0449a783          	lw	a5,68(s3)
    80001b6c:	01a787bb          	addw	a5,a5,s10
    80001b70:	03c9a703          	lw	a4,60(s3)
    80001b74:	9f99                	subw	a5,a5,a4
    80001b76:	04f9a223          	sw	a5,68(s3)
        swtch(&c->context, &p->context);
    80001b7a:	07898593          	addi	a1,s3,120
    80001b7e:	855e                	mv	a0,s7
    80001b80:	00001097          	auipc	ra,0x1
    80001b84:	d7c080e7          	jalr	-644(ra) # 800028fc <swtch>
        if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b88:	0309a583          	lw	a1,48(s3)
    80001b8c:	030a2783          	lw	a5,48(s4)
    80001b90:	02b78263          	beq	a5,a1,80001bb4 <scheduler+0x148>
    80001b94:	1b0a2783          	lw	a5,432(s4)
    80001b98:	00b78e63          	beq	a5,a1,80001bb4 <scheduler+0x148>
          p->running_time = p->running_time + ticks - ticks_now;
    80001b9c:	00007797          	auipc	a5,0x7
    80001ba0:	4b47a783          	lw	a5,1204(a5) # 80009050 <ticks>
    80001ba4:	41a78d3b          	subw	s10,a5,s10
    80001ba8:	0489a783          	lw	a5,72(s3)
    80001bac:	01a787bb          	addw	a5,a5,s10
    80001bb0:	04f9a423          	sw	a5,72(s3)
        int t = ticks;
    80001bb4:	00007697          	auipc	a3,0x7
    80001bb8:	49c6a683          	lw	a3,1180(a3) # 80009050 <ticks>
        p->last_ticks =  t - ticks_now;
    80001bbc:	4196873b          	subw	a4,a3,s9
    80001bc0:	02e9ac23          	sw	a4,56(s3)
        p->mean_ticks = ((10-rate)*p->mean_ticks+p->last_ticks*rate)/10;
    80001bc4:	00007617          	auipc	a2,0x7
    80001bc8:	d3462603          	lw	a2,-716(a2) # 800088f8 <rate>
    80001bcc:	4529                	li	a0,10
    80001bce:	40c507bb          	subw	a5,a0,a2
    80001bd2:	0349a803          	lw	a6,52(s3)
    80001bd6:	030787bb          	mulw	a5,a5,a6
    80001bda:	02c7063b          	mulw	a2,a4,a2
    80001bde:	9fb1                	addw	a5,a5,a2
    80001be0:	02a7d7bb          	divuw	a5,a5,a0
    80001be4:	02f9aa23          	sw	a5,52(s3)
        printf("pid: %d start: %d end: %d last: %d mean: %d\n",p->pid,ticks_now,t,p->last_ticks,p->mean_ticks);
    80001be8:	2781                	sext.w	a5,a5
    80001bea:	2701                	sext.w	a4,a4
    80001bec:	8666                	mv	a2,s9
    80001bee:	00006517          	auipc	a0,0x6
    80001bf2:	68a50513          	addi	a0,a0,1674 # 80008278 <digits+0x238>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	992080e7          	jalr	-1646(ra) # 80000588 <printf>
        c->proc = 0;
    80001bfe:	000b3023          	sd	zero,0(s6)
    80001c02:	b71d                	j	80001b28 <scheduler+0xbc>

0000000080001c04 <procinit>:
{
    80001c04:	7139                	addi	sp,sp,-64
    80001c06:	fc06                	sd	ra,56(sp)
    80001c08:	f822                	sd	s0,48(sp)
    80001c0a:	f426                	sd	s1,40(sp)
    80001c0c:	f04a                	sd	s2,32(sp)
    80001c0e:	ec4e                	sd	s3,24(sp)
    80001c10:	e852                	sd	s4,16(sp)
    80001c12:	e456                	sd	s5,8(sp)
    80001c14:	e05a                	sd	s6,0(sp)
    80001c16:	0080                	addi	s0,sp,64
  start_time = ticks;
    80001c18:	00007797          	auipc	a5,0x7
    80001c1c:	4387a783          	lw	a5,1080(a5) # 80009050 <ticks>
    80001c20:	00007717          	auipc	a4,0x7
    80001c24:	40f72823          	sw	a5,1040(a4) # 80009030 <start_time>
  initlock(&pid_lock, "nextpid");
    80001c28:	00006597          	auipc	a1,0x6
    80001c2c:	68058593          	addi	a1,a1,1664 # 800082a8 <digits+0x268>
    80001c30:	00010517          	auipc	a0,0x10
    80001c34:	a9050513          	addi	a0,a0,-1392 # 800116c0 <pid_lock>
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	f1c080e7          	jalr	-228(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c40:	00006597          	auipc	a1,0x6
    80001c44:	67058593          	addi	a1,a1,1648 # 800082b0 <digits+0x270>
    80001c48:	00010517          	auipc	a0,0x10
    80001c4c:	a9050513          	addi	a0,a0,-1392 # 800116d8 <wait_lock>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	f04080e7          	jalr	-252(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	a9848493          	addi	s1,s1,-1384 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001c60:	00006b17          	auipc	s6,0x6
    80001c64:	660b0b13          	addi	s6,s6,1632 # 800082c0 <digits+0x280>
      p->kstack = KSTACK((int) (p - proc));
    80001c68:	8aa6                	mv	s5,s1
    80001c6a:	00006a17          	auipc	s4,0x6
    80001c6e:	396a0a13          	addi	s4,s4,918 # 80008000 <etext>
    80001c72:	04000937          	lui	s2,0x4000
    80001c76:	197d                	addi	s2,s2,-1
    80001c78:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c7a:	00016997          	auipc	s3,0x16
    80001c7e:	a7698993          	addi	s3,s3,-1418 # 800176f0 <tickslock>
      initlock(&p->lock, "proc");
    80001c82:	85da                	mv	a1,s6
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	ece080e7          	jalr	-306(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c8e:	415487b3          	sub	a5,s1,s5
    80001c92:	879d                	srai	a5,a5,0x7
    80001c94:	000a3703          	ld	a4,0(s4)
    80001c98:	02e787b3          	mul	a5,a5,a4
    80001c9c:	2785                	addiw	a5,a5,1
    80001c9e:	00d7979b          	slliw	a5,a5,0xd
    80001ca2:	40f907b3          	sub	a5,s2,a5
    80001ca6:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca8:	18048493          	addi	s1,s1,384
    80001cac:	fd349be3          	bne	s1,s3,80001c82 <procinit+0x7e>
}
    80001cb0:	70e2                	ld	ra,56(sp)
    80001cb2:	7442                	ld	s0,48(sp)
    80001cb4:	74a2                	ld	s1,40(sp)
    80001cb6:	7902                	ld	s2,32(sp)
    80001cb8:	69e2                	ld	s3,24(sp)
    80001cba:	6a42                	ld	s4,16(sp)
    80001cbc:	6aa2                	ld	s5,8(sp)
    80001cbe:	6b02                	ld	s6,0(sp)
    80001cc0:	6121                	addi	sp,sp,64
    80001cc2:	8082                	ret

0000000080001cc4 <cpuid>:
{
    80001cc4:	1141                	addi	sp,sp,-16
    80001cc6:	e422                	sd	s0,8(sp)
    80001cc8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cca:	8512                	mv	a0,tp
  return id;
}
    80001ccc:	2501                	sext.w	a0,a0
    80001cce:	6422                	ld	s0,8(sp)
    80001cd0:	0141                	addi	sp,sp,16
    80001cd2:	8082                	ret

0000000080001cd4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001cd4:	1141                	addi	sp,sp,-16
    80001cd6:	e422                	sd	s0,8(sp)
    80001cd8:	0800                	addi	s0,sp,16
    80001cda:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cdc:	2781                	sext.w	a5,a5
    80001cde:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ce0:	0000f517          	auipc	a0,0xf
    80001ce4:	5e050513          	addi	a0,a0,1504 # 800112c0 <cpus>
    80001ce8:	953e                	add	a0,a0,a5
    80001cea:	6422                	ld	s0,8(sp)
    80001cec:	0141                	addi	sp,sp,16
    80001cee:	8082                	ret

0000000080001cf0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	1000                	addi	s0,sp,32
  push_off();
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	e9e080e7          	jalr	-354(ra) # 80000b98 <push_off>
    80001d02:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d04:	2781                	sext.w	a5,a5
    80001d06:	079e                	slli	a5,a5,0x7
    80001d08:	0000f717          	auipc	a4,0xf
    80001d0c:	5b870713          	addi	a4,a4,1464 # 800112c0 <cpus>
    80001d10:	97ba                	add	a5,a5,a4
    80001d12:	6384                	ld	s1,0(a5)
  pop_off();
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f24080e7          	jalr	-220(ra) # 80000c38 <pop_off>
  return p;
}
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret

0000000080001d28 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d28:	1141                	addi	sp,sp,-16
    80001d2a:	e406                	sd	ra,8(sp)
    80001d2c:	e022                	sd	s0,0(sp)
    80001d2e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	fc0080e7          	jalr	-64(ra) # 80001cf0 <myproc>
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	f60080e7          	jalr	-160(ra) # 80000c98 <release>

  if (first) {
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	bb07a783          	lw	a5,-1104(a5) # 800088f0 <first.1717>
    80001d48:	eb89                	bnez	a5,80001d5a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d4a:	00001097          	auipc	ra,0x1
    80001d4e:	c5c080e7          	jalr	-932(ra) # 800029a6 <usertrapret>
}
    80001d52:	60a2                	ld	ra,8(sp)
    80001d54:	6402                	ld	s0,0(sp)
    80001d56:	0141                	addi	sp,sp,16
    80001d58:	8082                	ret
    first = 0;
    80001d5a:	00007797          	auipc	a5,0x7
    80001d5e:	b807ab23          	sw	zero,-1130(a5) # 800088f0 <first.1717>
    fsinit(ROOTDEV);
    80001d62:	4505                	li	a0,1
    80001d64:	00002097          	auipc	ra,0x2
    80001d68:	99e080e7          	jalr	-1634(ra) # 80003702 <fsinit>
    80001d6c:	bff9                	j	80001d4a <forkret+0x22>

0000000080001d6e <allocpid>:
allocpid() {
    80001d6e:	1101                	addi	sp,sp,-32
    80001d70:	ec06                	sd	ra,24(sp)
    80001d72:	e822                	sd	s0,16(sp)
    80001d74:	e426                	sd	s1,8(sp)
    80001d76:	e04a                	sd	s2,0(sp)
    80001d78:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d7a:	00010917          	auipc	s2,0x10
    80001d7e:	94690913          	addi	s2,s2,-1722 # 800116c0 <pid_lock>
    80001d82:	854a                	mv	a0,s2
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	e60080e7          	jalr	-416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001d8c:	00007797          	auipc	a5,0x7
    80001d90:	b6878793          	addi	a5,a5,-1176 # 800088f4 <nextpid>
    80001d94:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d96:	0014871b          	addiw	a4,s1,1
    80001d9a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d9c:	854a                	mv	a0,s2
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	efa080e7          	jalr	-262(ra) # 80000c98 <release>
}
    80001da6:	8526                	mv	a0,s1
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6902                	ld	s2,0(sp)
    80001db0:	6105                	addi	sp,sp,32
    80001db2:	8082                	ret

0000000080001db4 <proc_pagetable>:
{
    80001db4:	1101                	addi	sp,sp,-32
    80001db6:	ec06                	sd	ra,24(sp)
    80001db8:	e822                	sd	s0,16(sp)
    80001dba:	e426                	sd	s1,8(sp)
    80001dbc:	e04a                	sd	s2,0(sp)
    80001dbe:	1000                	addi	s0,sp,32
    80001dc0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	578080e7          	jalr	1400(ra) # 8000133a <uvmcreate>
    80001dca:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dcc:	c121                	beqz	a0,80001e0c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dce:	4729                	li	a4,10
    80001dd0:	00005697          	auipc	a3,0x5
    80001dd4:	23068693          	addi	a3,a3,560 # 80007000 <_trampoline>
    80001dd8:	6605                	lui	a2,0x1
    80001dda:	040005b7          	lui	a1,0x4000
    80001dde:	15fd                	addi	a1,a1,-1
    80001de0:	05b2                	slli	a1,a1,0xc
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	2ce080e7          	jalr	718(ra) # 800010b0 <mappages>
    80001dea:	02054863          	bltz	a0,80001e1a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dee:	4719                	li	a4,6
    80001df0:	07093683          	ld	a3,112(s2)
    80001df4:	6605                	lui	a2,0x1
    80001df6:	020005b7          	lui	a1,0x2000
    80001dfa:	15fd                	addi	a1,a1,-1
    80001dfc:	05b6                	slli	a1,a1,0xd
    80001dfe:	8526                	mv	a0,s1
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	2b0080e7          	jalr	688(ra) # 800010b0 <mappages>
    80001e08:	02054163          	bltz	a0,80001e2a <proc_pagetable+0x76>
}
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6902                	ld	s2,0(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret
    uvmfree(pagetable, 0);
    80001e1a:	4581                	li	a1,0
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	718080e7          	jalr	1816(ra) # 80001536 <uvmfree>
    return 0;
    80001e26:	4481                	li	s1,0
    80001e28:	b7d5                	j	80001e0c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e2a:	4681                	li	a3,0
    80001e2c:	4605                	li	a2,1
    80001e2e:	040005b7          	lui	a1,0x4000
    80001e32:	15fd                	addi	a1,a1,-1
    80001e34:	05b2                	slli	a1,a1,0xc
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	43e080e7          	jalr	1086(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e40:	4581                	li	a1,0
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	6f2080e7          	jalr	1778(ra) # 80001536 <uvmfree>
    return 0;
    80001e4c:	4481                	li	s1,0
    80001e4e:	bf7d                	j	80001e0c <proc_pagetable+0x58>

0000000080001e50 <proc_freepagetable>:
{
    80001e50:	1101                	addi	sp,sp,-32
    80001e52:	ec06                	sd	ra,24(sp)
    80001e54:	e822                	sd	s0,16(sp)
    80001e56:	e426                	sd	s1,8(sp)
    80001e58:	e04a                	sd	s2,0(sp)
    80001e5a:	1000                	addi	s0,sp,32
    80001e5c:	84aa                	mv	s1,a0
    80001e5e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e60:	4681                	li	a3,0
    80001e62:	4605                	li	a2,1
    80001e64:	040005b7          	lui	a1,0x4000
    80001e68:	15fd                	addi	a1,a1,-1
    80001e6a:	05b2                	slli	a1,a1,0xc
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	40a080e7          	jalr	1034(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e74:	4681                	li	a3,0
    80001e76:	4605                	li	a2,1
    80001e78:	020005b7          	lui	a1,0x2000
    80001e7c:	15fd                	addi	a1,a1,-1
    80001e7e:	05b6                	slli	a1,a1,0xd
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	3f4080e7          	jalr	1012(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e8a:	85ca                	mv	a1,s2
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	6a8080e7          	jalr	1704(ra) # 80001536 <uvmfree>
}
    80001e96:	60e2                	ld	ra,24(sp)
    80001e98:	6442                	ld	s0,16(sp)
    80001e9a:	64a2                	ld	s1,8(sp)
    80001e9c:	6902                	ld	s2,0(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret

0000000080001ea2 <freeproc>:
{
    80001ea2:	1101                	addi	sp,sp,-32
    80001ea4:	ec06                	sd	ra,24(sp)
    80001ea6:	e822                	sd	s0,16(sp)
    80001ea8:	e426                	sd	s1,8(sp)
    80001eaa:	1000                	addi	s0,sp,32
    80001eac:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001eae:	7928                	ld	a0,112(a0)
    80001eb0:	c509                	beqz	a0,80001eba <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	b46080e7          	jalr	-1210(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001eba:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001ebe:	74a8                	ld	a0,104(s1)
    80001ec0:	c511                	beqz	a0,80001ecc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ec2:	70ac                	ld	a1,96(s1)
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	f8c080e7          	jalr	-116(ra) # 80001e50 <proc_freepagetable>
  p->pagetable = 0;
    80001ecc:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001ed0:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001ed4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ed8:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001edc:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001ee0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ee4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ee8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001eec:	0004ac23          	sw	zero,24(s1)
}
    80001ef0:	60e2                	ld	ra,24(sp)
    80001ef2:	6442                	ld	s0,16(sp)
    80001ef4:	64a2                	ld	s1,8(sp)
    80001ef6:	6105                	addi	sp,sp,32
    80001ef8:	8082                	ret

0000000080001efa <allocproc>:
{
    80001efa:	1101                	addi	sp,sp,-32
    80001efc:	ec06                	sd	ra,24(sp)
    80001efe:	e822                	sd	s0,16(sp)
    80001f00:	e426                	sd	s1,8(sp)
    80001f02:	e04a                	sd	s2,0(sp)
    80001f04:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f06:	0000f497          	auipc	s1,0xf
    80001f0a:	7ea48493          	addi	s1,s1,2026 # 800116f0 <proc>
    80001f0e:	00015917          	auipc	s2,0x15
    80001f12:	7e290913          	addi	s2,s2,2018 # 800176f0 <tickslock>
    acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	ccc080e7          	jalr	-820(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	cf81                	beqz	a5,80001f3a <allocproc+0x40>
      release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d72080e7          	jalr	-654(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f2e:	18048493          	addi	s1,s1,384
    80001f32:	ff2492e3          	bne	s1,s2,80001f16 <allocproc+0x1c>
  return 0;
    80001f36:	4481                	li	s1,0
    80001f38:	a09d                	j	80001f9e <allocproc+0xa4>
  p->pid = allocpid();
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	e34080e7          	jalr	-460(ra) # 80001d6e <allocpid>
    80001f42:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f44:	4785                	li	a5,1
    80001f46:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001f48:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001f4c:	0204ac23          	sw	zero,56(s1)
  p->sleeping_time = 0;
    80001f50:	0404a023          	sw	zero,64(s1)
  p->runnable_time = 0;
    80001f54:	0404a223          	sw	zero,68(s1)
  p->running_time = 0;
    80001f58:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	b98080e7          	jalr	-1128(ra) # 80000af4 <kalloc>
    80001f64:	892a                	mv	s2,a0
    80001f66:	f8a8                	sd	a0,112(s1)
    80001f68:	c131                	beqz	a0,80001fac <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	e48080e7          	jalr	-440(ra) # 80001db4 <proc_pagetable>
    80001f74:	892a                	mv	s2,a0
    80001f76:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001f78:	c531                	beqz	a0,80001fc4 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001f7a:	07000613          	li	a2,112
    80001f7e:	4581                	li	a1,0
    80001f80:	07848513          	addi	a0,s1,120
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d5c080e7          	jalr	-676(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f8c:	00000797          	auipc	a5,0x0
    80001f90:	d9c78793          	addi	a5,a5,-612 # 80001d28 <forkret>
    80001f94:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f96:	6cbc                	ld	a5,88(s1)
    80001f98:	6705                	lui	a4,0x1
    80001f9a:	97ba                	add	a5,a5,a4
    80001f9c:	e0dc                	sd	a5,128(s1)
}
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	60e2                	ld	ra,24(sp)
    80001fa2:	6442                	ld	s0,16(sp)
    80001fa4:	64a2                	ld	s1,8(sp)
    80001fa6:	6902                	ld	s2,0(sp)
    80001fa8:	6105                	addi	sp,sp,32
    80001faa:	8082                	ret
    freeproc(p);
    80001fac:	8526                	mv	a0,s1
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	ef4080e7          	jalr	-268(ra) # 80001ea2 <freeproc>
    release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
    return 0;
    80001fc0:	84ca                	mv	s1,s2
    80001fc2:	bff1                	j	80001f9e <allocproc+0xa4>
    freeproc(p);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	edc080e7          	jalr	-292(ra) # 80001ea2 <freeproc>
    release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	cc8080e7          	jalr	-824(ra) # 80000c98 <release>
    return 0;
    80001fd8:	84ca                	mv	s1,s2
    80001fda:	b7d1                	j	80001f9e <allocproc+0xa4>

0000000080001fdc <userinit>:
{
    80001fdc:	1101                	addi	sp,sp,-32
    80001fde:	ec06                	sd	ra,24(sp)
    80001fe0:	e822                	sd	s0,16(sp)
    80001fe2:	e426                	sd	s1,8(sp)
    80001fe4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	f14080e7          	jalr	-236(ra) # 80001efa <allocproc>
    80001fee:	84aa                	mv	s1,a0
  initproc = p;
    80001ff0:	00007797          	auipc	a5,0x7
    80001ff4:	04a7bc23          	sd	a0,88(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ff8:	03400613          	li	a2,52
    80001ffc:	00007597          	auipc	a1,0x7
    80002000:	90458593          	addi	a1,a1,-1788 # 80008900 <initcode>
    80002004:	7528                	ld	a0,104(a0)
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	362080e7          	jalr	866(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000200e:	6785                	lui	a5,0x1
    80002010:	f0bc                	sd	a5,96(s1)
  sleeping_processes_mean = 0;
    80002012:	00007717          	auipc	a4,0x7
    80002016:	02072723          	sw	zero,46(a4) # 80009040 <sleeping_processes_mean>
  running_processes_mean = 0;
    8000201a:	00007717          	auipc	a4,0x7
    8000201e:	02072123          	sw	zero,34(a4) # 8000903c <running_processes_mean>
  runnable_processes_mean = 0;
    80002022:	00007717          	auipc	a4,0x7
    80002026:	00072b23          	sw	zero,22(a4) # 80009038 <runnable_processes_mean>
  p->trapframe->epc = 0;      // user program counter
    8000202a:	78b8                	ld	a4,112(s1)
    8000202c:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002030:	78b8                	ld	a4,112(s1)
    80002032:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002034:	4641                	li	a2,16
    80002036:	00006597          	auipc	a1,0x6
    8000203a:	29258593          	addi	a1,a1,658 # 800082c8 <digits+0x288>
    8000203e:	17048513          	addi	a0,s1,368
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	df0080e7          	jalr	-528(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	28e50513          	addi	a0,a0,654 # 800082d8 <digits+0x298>
    80002052:	00002097          	auipc	ra,0x2
    80002056:	0de080e7          	jalr	222(ra) # 80004130 <namei>
    8000205a:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    8000205e:	478d                	li	a5,3
    80002060:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002062:	00007797          	auipc	a5,0x7
    80002066:	fee7a783          	lw	a5,-18(a5) # 80009050 <ticks>
    8000206a:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    8000206c:	8526                	mv	a0,s1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	c2a080e7          	jalr	-982(ra) # 80000c98 <release>
}
    80002076:	60e2                	ld	ra,24(sp)
    80002078:	6442                	ld	s0,16(sp)
    8000207a:	64a2                	ld	s1,8(sp)
    8000207c:	6105                	addi	sp,sp,32
    8000207e:	8082                	ret

0000000080002080 <growproc>:
{
    80002080:	1101                	addi	sp,sp,-32
    80002082:	ec06                	sd	ra,24(sp)
    80002084:	e822                	sd	s0,16(sp)
    80002086:	e426                	sd	s1,8(sp)
    80002088:	e04a                	sd	s2,0(sp)
    8000208a:	1000                	addi	s0,sp,32
    8000208c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	c62080e7          	jalr	-926(ra) # 80001cf0 <myproc>
    80002096:	892a                	mv	s2,a0
  sz = p->sz;
    80002098:	712c                	ld	a1,96(a0)
    8000209a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000209e:	00904f63          	bgtz	s1,800020bc <growproc+0x3c>
  } else if(n < 0){
    800020a2:	0204cc63          	bltz	s1,800020da <growproc+0x5a>
  p->sz = sz;
    800020a6:	1602                	slli	a2,a2,0x20
    800020a8:	9201                	srli	a2,a2,0x20
    800020aa:	06c93023          	sd	a2,96(s2)
  return 0;
    800020ae:	4501                	li	a0,0
}
    800020b0:	60e2                	ld	ra,24(sp)
    800020b2:	6442                	ld	s0,16(sp)
    800020b4:	64a2                	ld	s1,8(sp)
    800020b6:	6902                	ld	s2,0(sp)
    800020b8:	6105                	addi	sp,sp,32
    800020ba:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020bc:	9e25                	addw	a2,a2,s1
    800020be:	1602                	slli	a2,a2,0x20
    800020c0:	9201                	srli	a2,a2,0x20
    800020c2:	1582                	slli	a1,a1,0x20
    800020c4:	9181                	srli	a1,a1,0x20
    800020c6:	7528                	ld	a0,104(a0)
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	35a080e7          	jalr	858(ra) # 80001422 <uvmalloc>
    800020d0:	0005061b          	sext.w	a2,a0
    800020d4:	fa69                	bnez	a2,800020a6 <growproc+0x26>
      return -1;
    800020d6:	557d                	li	a0,-1
    800020d8:	bfe1                	j	800020b0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020da:	9e25                	addw	a2,a2,s1
    800020dc:	1602                	slli	a2,a2,0x20
    800020de:	9201                	srli	a2,a2,0x20
    800020e0:	1582                	slli	a1,a1,0x20
    800020e2:	9181                	srli	a1,a1,0x20
    800020e4:	7528                	ld	a0,104(a0)
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	2f4080e7          	jalr	756(ra) # 800013da <uvmdealloc>
    800020ee:	0005061b          	sext.w	a2,a0
    800020f2:	bf55                	j	800020a6 <growproc+0x26>

00000000800020f4 <fork>:
{
    800020f4:	7179                	addi	sp,sp,-48
    800020f6:	f406                	sd	ra,40(sp)
    800020f8:	f022                	sd	s0,32(sp)
    800020fa:	ec26                	sd	s1,24(sp)
    800020fc:	e84a                	sd	s2,16(sp)
    800020fe:	e44e                	sd	s3,8(sp)
    80002100:	e052                	sd	s4,0(sp)
    80002102:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	bec080e7          	jalr	-1044(ra) # 80001cf0 <myproc>
    8000210c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	dec080e7          	jalr	-532(ra) # 80001efa <allocproc>
    80002116:	12050163          	beqz	a0,80002238 <fork+0x144>
    8000211a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000211c:	06093603          	ld	a2,96(s2)
    80002120:	752c                	ld	a1,104(a0)
    80002122:	06893503          	ld	a0,104(s2)
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	448080e7          	jalr	1096(ra) # 8000156e <uvmcopy>
    8000212e:	04054663          	bltz	a0,8000217a <fork+0x86>
  np->sz = p->sz;
    80002132:	06093783          	ld	a5,96(s2)
    80002136:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    8000213a:	07093683          	ld	a3,112(s2)
    8000213e:	87b6                	mv	a5,a3
    80002140:	0709b703          	ld	a4,112(s3)
    80002144:	12068693          	addi	a3,a3,288
    80002148:	0007b803          	ld	a6,0(a5)
    8000214c:	6788                	ld	a0,8(a5)
    8000214e:	6b8c                	ld	a1,16(a5)
    80002150:	6f90                	ld	a2,24(a5)
    80002152:	01073023          	sd	a6,0(a4)
    80002156:	e708                	sd	a0,8(a4)
    80002158:	eb0c                	sd	a1,16(a4)
    8000215a:	ef10                	sd	a2,24(a4)
    8000215c:	02078793          	addi	a5,a5,32
    80002160:	02070713          	addi	a4,a4,32
    80002164:	fed792e3          	bne	a5,a3,80002148 <fork+0x54>
  np->trapframe->a0 = 0;
    80002168:	0709b783          	ld	a5,112(s3)
    8000216c:	0607b823          	sd	zero,112(a5)
    80002170:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    80002174:	16800a13          	li	s4,360
    80002178:	a03d                	j	800021a6 <fork+0xb2>
    freeproc(np);
    8000217a:	854e                	mv	a0,s3
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	d26080e7          	jalr	-730(ra) # 80001ea2 <freeproc>
    release(&np->lock);
    80002184:	854e                	mv	a0,s3
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
    return -1;
    8000218e:	5a7d                	li	s4,-1
    80002190:	a859                	j	80002226 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80002192:	00002097          	auipc	ra,0x2
    80002196:	634080e7          	jalr	1588(ra) # 800047c6 <filedup>
    8000219a:	009987b3          	add	a5,s3,s1
    8000219e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021a0:	04a1                	addi	s1,s1,8
    800021a2:	01448763          	beq	s1,s4,800021b0 <fork+0xbc>
    if(p->ofile[i])
    800021a6:	009907b3          	add	a5,s2,s1
    800021aa:	6388                	ld	a0,0(a5)
    800021ac:	f17d                	bnez	a0,80002192 <fork+0x9e>
    800021ae:	bfcd                	j	800021a0 <fork+0xac>
  np->cwd = idup(p->cwd);
    800021b0:	16893503          	ld	a0,360(s2)
    800021b4:	00001097          	auipc	ra,0x1
    800021b8:	788080e7          	jalr	1928(ra) # 8000393c <idup>
    800021bc:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021c0:	4641                	li	a2,16
    800021c2:	17090593          	addi	a1,s2,368
    800021c6:	17098513          	addi	a0,s3,368
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	c68080e7          	jalr	-920(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800021d2:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800021d6:	854e                	mv	a0,s3
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	ac0080e7          	jalr	-1344(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800021e0:	0000f497          	auipc	s1,0xf
    800021e4:	4f848493          	addi	s1,s1,1272 # 800116d8 <wait_lock>
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
  np->parent = p;
    800021f2:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002200:	854e                	mv	a0,s3
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  np->last_runnable_time = ticks;
    8000220a:	00007797          	auipc	a5,0x7
    8000220e:	e467a783          	lw	a5,-442(a5) # 80009050 <ticks>
    80002212:	02f9ae23          	sw	a5,60(s3)
  np->state = RUNNABLE;
    80002216:	478d                	li	a5,3
    80002218:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000221c:	854e                	mv	a0,s3
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a7a080e7          	jalr	-1414(ra) # 80000c98 <release>
}
    80002226:	8552                	mv	a0,s4
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6a02                	ld	s4,0(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret
    return -1;
    80002238:	5a7d                	li	s4,-1
    8000223a:	b7f5                	j	80002226 <fork+0x132>

000000008000223c <sched>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	aa6080e7          	jalr	-1370(ra) # 80001cf0 <myproc>
    80002252:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	916080e7          	jalr	-1770(ra) # 80000b6a <holding>
    8000225c:	c53d                	beqz	a0,800022ca <sched+0x8e>
    8000225e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002260:	2781                	sext.w	a5,a5
    80002262:	079e                	slli	a5,a5,0x7
    80002264:	0000f717          	auipc	a4,0xf
    80002268:	05c70713          	addi	a4,a4,92 # 800112c0 <cpus>
    8000226c:	97ba                	add	a5,a5,a4
    8000226e:	5fb8                	lw	a4,120(a5)
    80002270:	4785                	li	a5,1
    80002272:	06f71463          	bne	a4,a5,800022da <sched+0x9e>
  if(p->state == RUNNING)
    80002276:	4c98                	lw	a4,24(s1)
    80002278:	4791                	li	a5,4
    8000227a:	06f70863          	beq	a4,a5,800022ea <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000227e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002282:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002284:	ebbd                	bnez	a5,800022fa <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002286:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002288:	0000f917          	auipc	s2,0xf
    8000228c:	03890913          	addi	s2,s2,56 # 800112c0 <cpus>
    80002290:	2781                	sext.w	a5,a5
    80002292:	079e                	slli	a5,a5,0x7
    80002294:	97ca                	add	a5,a5,s2
    80002296:	07c7a983          	lw	s3,124(a5)
    8000229a:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000229c:	2581                	sext.w	a1,a1
    8000229e:	059e                	slli	a1,a1,0x7
    800022a0:	05a1                	addi	a1,a1,8
    800022a2:	95ca                	add	a1,a1,s2
    800022a4:	07848513          	addi	a0,s1,120
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	654080e7          	jalr	1620(ra) # 800028fc <swtch>
    800022b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022b2:	2781                	sext.w	a5,a5
    800022b4:	079e                	slli	a5,a5,0x7
    800022b6:	993e                	add	s2,s2,a5
    800022b8:	07392e23          	sw	s3,124(s2)
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
    panic("sched p->lock");
    800022ca:	00006517          	auipc	a0,0x6
    800022ce:	01650513          	addi	a0,a0,22 # 800082e0 <digits+0x2a0>
    800022d2:	ffffe097          	auipc	ra,0xffffe
    800022d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
    panic("sched locks");
    800022da:	00006517          	auipc	a0,0x6
    800022de:	01650513          	addi	a0,a0,22 # 800082f0 <digits+0x2b0>
    800022e2:	ffffe097          	auipc	ra,0xffffe
    800022e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    panic("sched running");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	01650513          	addi	a0,a0,22 # 80008300 <digits+0x2c0>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022fa:	00006517          	auipc	a0,0x6
    800022fe:	01650513          	addi	a0,a0,22 # 80008310 <digits+0x2d0>
    80002302:	ffffe097          	auipc	ra,0xffffe
    80002306:	23c080e7          	jalr	572(ra) # 8000053e <panic>

000000008000230a <yield>:
{
    8000230a:	1101                	addi	sp,sp,-32
    8000230c:	ec06                	sd	ra,24(sp)
    8000230e:	e822                	sd	s0,16(sp)
    80002310:	e426                	sd	s1,8(sp)
    80002312:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002314:	00000097          	auipc	ra,0x0
    80002318:	9dc080e7          	jalr	-1572(ra) # 80001cf0 <myproc>
    8000231c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002326:	478d                	li	a5,3
    80002328:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000232a:	00007797          	auipc	a5,0x7
    8000232e:	d267a783          	lw	a5,-730(a5) # 80009050 <ticks>
    80002332:	dcdc                	sw	a5,60(s1)
  sched();
    80002334:	00000097          	auipc	ra,0x0
    80002338:	f08080e7          	jalr	-248(ra) # 8000223c <sched>
  release(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	95a080e7          	jalr	-1702(ra) # 80000c98 <release>
}
    80002346:	60e2                	ld	ra,24(sp)
    80002348:	6442                	ld	s0,16(sp)
    8000234a:	64a2                	ld	s1,8(sp)
    8000234c:	6105                	addi	sp,sp,32
    8000234e:	8082                	ret

0000000080002350 <pause_sys>:
{
    80002350:	1141                	addi	sp,sp,-16
    80002352:	e406                	sd	ra,8(sp)
    80002354:	e022                	sd	s0,0(sp)
    80002356:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    80002358:	0025179b          	slliw	a5,a0,0x2
    8000235c:	9fa9                	addw	a5,a5,a0
    8000235e:	0017979b          	slliw	a5,a5,0x1
    80002362:	00007517          	auipc	a0,0x7
    80002366:	cee52503          	lw	a0,-786(a0) # 80009050 <ticks>
    8000236a:	9fa9                	addw	a5,a5,a0
    8000236c:	00007717          	auipc	a4,0x7
    80002370:	ccf72c23          	sw	a5,-808(a4) # 80009044 <finish>
  yield();
    80002374:	00000097          	auipc	ra,0x0
    80002378:	f96080e7          	jalr	-106(ra) # 8000230a <yield>
}
    8000237c:	4501                	li	a0,0
    8000237e:	60a2                	ld	ra,8(sp)
    80002380:	6402                	ld	s0,0(sp)
    80002382:	0141                	addi	sp,sp,16
    80002384:	8082                	ret

0000000080002386 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002386:	7179                	addi	sp,sp,-48
    80002388:	f406                	sd	ra,40(sp)
    8000238a:	f022                	sd	s0,32(sp)
    8000238c:	ec26                	sd	s1,24(sp)
    8000238e:	e84a                	sd	s2,16(sp)
    80002390:	e44e                	sd	s3,8(sp)
    80002392:	e052                	sd	s4,0(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	89aa                	mv	s3,a0
    80002398:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	956080e7          	jalr	-1706(ra) # 80001cf0 <myproc>
    800023a2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	840080e7          	jalr	-1984(ra) # 80000be4 <acquire>
  release(lk);
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8ea080e7          	jalr	-1814(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800023b6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023ba:	4789                	li	a5,2
    800023bc:	cc9c                	sw	a5,24(s1)
  int sleep_start = ticks;
    800023be:	00007997          	auipc	s3,0x7
    800023c2:	c9298993          	addi	s3,s3,-878 # 80009050 <ticks>
    800023c6:	0009aa03          	lw	s4,0(s3)
  sched();
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	e72080e7          	jalr	-398(ra) # 8000223c <sched>
  p->sleeping_time = ticks - sleep_start;
    800023d2:	0009a783          	lw	a5,0(s3)
    800023d6:	414787bb          	subw	a5,a5,s4
    800023da:	c0bc                	sw	a5,64(s1)
  // Tidy up.
  p->chan = 0;
    800023dc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
  acquire(lk);
    800023ea:	854a                	mv	a0,s2
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7f8080e7          	jalr	2040(ra) # 80000be4 <acquire>
}
    800023f4:	70a2                	ld	ra,40(sp)
    800023f6:	7402                	ld	s0,32(sp)
    800023f8:	64e2                	ld	s1,24(sp)
    800023fa:	6942                	ld	s2,16(sp)
    800023fc:	69a2                	ld	s3,8(sp)
    800023fe:	6a02                	ld	s4,0(sp)
    80002400:	6145                	addi	sp,sp,48
    80002402:	8082                	ret

0000000080002404 <wait>:
{
    80002404:	715d                	addi	sp,sp,-80
    80002406:	e486                	sd	ra,72(sp)
    80002408:	e0a2                	sd	s0,64(sp)
    8000240a:	fc26                	sd	s1,56(sp)
    8000240c:	f84a                	sd	s2,48(sp)
    8000240e:	f44e                	sd	s3,40(sp)
    80002410:	f052                	sd	s4,32(sp)
    80002412:	ec56                	sd	s5,24(sp)
    80002414:	e85a                	sd	s6,16(sp)
    80002416:	e45e                	sd	s7,8(sp)
    80002418:	e062                	sd	s8,0(sp)
    8000241a:	0880                	addi	s0,sp,80
    8000241c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	8d2080e7          	jalr	-1838(ra) # 80001cf0 <myproc>
    80002426:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002428:	0000f517          	auipc	a0,0xf
    8000242c:	2b050513          	addi	a0,a0,688 # 800116d8 <wait_lock>
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
    havekids = 0;
    80002438:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000243a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000243c:	00015997          	auipc	s3,0x15
    80002440:	2b498993          	addi	s3,s3,692 # 800176f0 <tickslock>
        havekids = 1;
    80002444:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002446:	0000fc17          	auipc	s8,0xf
    8000244a:	292c0c13          	addi	s8,s8,658 # 800116d8 <wait_lock>
    havekids = 0;
    8000244e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002450:	0000f497          	auipc	s1,0xf
    80002454:	2a048493          	addi	s1,s1,672 # 800116f0 <proc>
    80002458:	a0bd                	j	800024c6 <wait+0xc2>
          pid = np->pid;
    8000245a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000245e:	000b0e63          	beqz	s6,8000247a <wait+0x76>
    80002462:	4691                	li	a3,4
    80002464:	02c48613          	addi	a2,s1,44
    80002468:	85da                	mv	a1,s6
    8000246a:	06893503          	ld	a0,104(s2)
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	204080e7          	jalr	516(ra) # 80001672 <copyout>
    80002476:	02054563          	bltz	a0,800024a0 <wait+0x9c>
          freeproc(np);
    8000247a:	8526                	mv	a0,s1
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	a26080e7          	jalr	-1498(ra) # 80001ea2 <freeproc>
          release(&np->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
          release(&wait_lock);
    8000248e:	0000f517          	auipc	a0,0xf
    80002492:	24a50513          	addi	a0,a0,586 # 800116d8 <wait_lock>
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	802080e7          	jalr	-2046(ra) # 80000c98 <release>
          return pid;
    8000249e:	a09d                	j	80002504 <wait+0x100>
            release(&np->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
            release(&wait_lock);
    800024aa:	0000f517          	auipc	a0,0xf
    800024ae:	22e50513          	addi	a0,a0,558 # 800116d8 <wait_lock>
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
            return -1;
    800024ba:	59fd                	li	s3,-1
    800024bc:	a0a1                	j	80002504 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800024be:	18048493          	addi	s1,s1,384
    800024c2:	03348463          	beq	s1,s3,800024ea <wait+0xe6>
      if(np->parent == p){
    800024c6:	68bc                	ld	a5,80(s1)
    800024c8:	ff279be3          	bne	a5,s2,800024be <wait+0xba>
        acquire(&np->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024d6:	4c9c                	lw	a5,24(s1)
    800024d8:	f94781e3          	beq	a5,s4,8000245a <wait+0x56>
        release(&np->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
        havekids = 1;
    800024e6:	8756                	mv	a4,s5
    800024e8:	bfd9                	j	800024be <wait+0xba>
    if(!havekids || p->killed){
    800024ea:	c701                	beqz	a4,800024f2 <wait+0xee>
    800024ec:	02892783          	lw	a5,40(s2)
    800024f0:	c79d                	beqz	a5,8000251e <wait+0x11a>
      release(&wait_lock);
    800024f2:	0000f517          	auipc	a0,0xf
    800024f6:	1e650513          	addi	a0,a0,486 # 800116d8 <wait_lock>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>
      return -1;
    80002502:	59fd                	li	s3,-1
}
    80002504:	854e                	mv	a0,s3
    80002506:	60a6                	ld	ra,72(sp)
    80002508:	6406                	ld	s0,64(sp)
    8000250a:	74e2                	ld	s1,56(sp)
    8000250c:	7942                	ld	s2,48(sp)
    8000250e:	79a2                	ld	s3,40(sp)
    80002510:	7a02                	ld	s4,32(sp)
    80002512:	6ae2                	ld	s5,24(sp)
    80002514:	6b42                	ld	s6,16(sp)
    80002516:	6ba2                	ld	s7,8(sp)
    80002518:	6c02                	ld	s8,0(sp)
    8000251a:	6161                	addi	sp,sp,80
    8000251c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000251e:	85e2                	mv	a1,s8
    80002520:	854a                	mv	a0,s2
    80002522:	00000097          	auipc	ra,0x0
    80002526:	e64080e7          	jalr	-412(ra) # 80002386 <sleep>
    havekids = 0;
    8000252a:	b715                	j	8000244e <wait+0x4a>

000000008000252c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000252c:	7139                	addi	sp,sp,-64
    8000252e:	fc06                	sd	ra,56(sp)
    80002530:	f822                	sd	s0,48(sp)
    80002532:	f426                	sd	s1,40(sp)
    80002534:	f04a                	sd	s2,32(sp)
    80002536:	ec4e                	sd	s3,24(sp)
    80002538:	e852                	sd	s4,16(sp)
    8000253a:	e456                	sd	s5,8(sp)
    8000253c:	e05a                	sd	s6,0(sp)
    8000253e:	0080                	addi	s0,sp,64
    80002540:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002542:	0000f497          	auipc	s1,0xf
    80002546:	1ae48493          	addi	s1,s1,430 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000254a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000254c:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    8000254e:	00007a97          	auipc	s5,0x7
    80002552:	b02a8a93          	addi	s5,s5,-1278 # 80009050 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	19a90913          	addi	s2,s2,410 # 800176f0 <tickslock>
    8000255e:	a839                	j	8000257c <wakeup+0x50>
        p->state = RUNNABLE;
    80002560:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002564:	000aa783          	lw	a5,0(s5)
    80002568:	dcdc                	sw	a5,60(s1)

      }
      release(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	72c080e7          	jalr	1836(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002574:	18048493          	addi	s1,s1,384
    80002578:	03248463          	beq	s1,s2,800025a0 <wakeup+0x74>
    if(p != myproc()){
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	774080e7          	jalr	1908(ra) # 80001cf0 <myproc>
    80002584:	fea488e3          	beq	s1,a0,80002574 <wakeup+0x48>
      acquire(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	65a080e7          	jalr	1626(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002592:	4c9c                	lw	a5,24(s1)
    80002594:	fd379be3          	bne	a5,s3,8000256a <wakeup+0x3e>
    80002598:	709c                	ld	a5,32(s1)
    8000259a:	fd4798e3          	bne	a5,s4,8000256a <wakeup+0x3e>
    8000259e:	b7c9                	j	80002560 <wakeup+0x34>
    }
  }
}
    800025a0:	70e2                	ld	ra,56(sp)
    800025a2:	7442                	ld	s0,48(sp)
    800025a4:	74a2                	ld	s1,40(sp)
    800025a6:	7902                	ld	s2,32(sp)
    800025a8:	69e2                	ld	s3,24(sp)
    800025aa:	6a42                	ld	s4,16(sp)
    800025ac:	6aa2                	ld	s5,8(sp)
    800025ae:	6b02                	ld	s6,0(sp)
    800025b0:	6121                	addi	sp,sp,64
    800025b2:	8082                	ret

00000000800025b4 <reparent>:
{
    800025b4:	7179                	addi	sp,sp,-48
    800025b6:	f406                	sd	ra,40(sp)
    800025b8:	f022                	sd	s0,32(sp)
    800025ba:	ec26                	sd	s1,24(sp)
    800025bc:	e84a                	sd	s2,16(sp)
    800025be:	e44e                	sd	s3,8(sp)
    800025c0:	e052                	sd	s4,0(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	12a48493          	addi	s1,s1,298 # 800116f0 <proc>
      pp->parent = initproc;
    800025ce:	00007a17          	auipc	s4,0x7
    800025d2:	a7aa0a13          	addi	s4,s4,-1414 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d6:	00015997          	auipc	s3,0x15
    800025da:	11a98993          	addi	s3,s3,282 # 800176f0 <tickslock>
    800025de:	a029                	j	800025e8 <reparent+0x34>
    800025e0:	18048493          	addi	s1,s1,384
    800025e4:	01348d63          	beq	s1,s3,800025fe <reparent+0x4a>
    if(pp->parent == p){
    800025e8:	68bc                	ld	a5,80(s1)
    800025ea:	ff279be3          	bne	a5,s2,800025e0 <reparent+0x2c>
      pp->parent = initproc;
    800025ee:	000a3503          	ld	a0,0(s4)
    800025f2:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    800025f4:	00000097          	auipc	ra,0x0
    800025f8:	f38080e7          	jalr	-200(ra) # 8000252c <wakeup>
    800025fc:	b7d5                	j	800025e0 <reparent+0x2c>
}
    800025fe:	70a2                	ld	ra,40(sp)
    80002600:	7402                	ld	s0,32(sp)
    80002602:	64e2                	ld	s1,24(sp)
    80002604:	6942                	ld	s2,16(sp)
    80002606:	69a2                	ld	s3,8(sp)
    80002608:	6a02                	ld	s4,0(sp)
    8000260a:	6145                	addi	sp,sp,48
    8000260c:	8082                	ret

000000008000260e <exit>:
{
    8000260e:	7179                	addi	sp,sp,-48
    80002610:	f406                	sd	ra,40(sp)
    80002612:	f022                	sd	s0,32(sp)
    80002614:	ec26                	sd	s1,24(sp)
    80002616:	e84a                	sd	s2,16(sp)
    80002618:	e44e                	sd	s3,8(sp)
    8000261a:	e052                	sd	s4,0(sp)
    8000261c:	1800                	addi	s0,sp,48
    8000261e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	6d0080e7          	jalr	1744(ra) # 80001cf0 <myproc>
    80002628:	89aa                	mv	s3,a0
  if(p == initproc)
    8000262a:	00007797          	auipc	a5,0x7
    8000262e:	a1e7b783          	ld	a5,-1506(a5) # 80009048 <initproc>
    80002632:	0e850493          	addi	s1,a0,232
    80002636:	16850913          	addi	s2,a0,360
    8000263a:	02a79363          	bne	a5,a0,80002660 <exit+0x52>
    panic("init exiting");
    8000263e:	00006517          	auipc	a0,0x6
    80002642:	cea50513          	addi	a0,a0,-790 # 80008328 <digits+0x2e8>
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>
      fileclose(f);
    8000264e:	00002097          	auipc	ra,0x2
    80002652:	1ca080e7          	jalr	458(ra) # 80004818 <fileclose>
      p->ofile[fd] = 0;
    80002656:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000265a:	04a1                	addi	s1,s1,8
    8000265c:	01248563          	beq	s1,s2,80002666 <exit+0x58>
    if(p->ofile[fd]){
    80002660:	6088                	ld	a0,0(s1)
    80002662:	f575                	bnez	a0,8000264e <exit+0x40>
    80002664:	bfdd                	j	8000265a <exit+0x4c>
  begin_op();
    80002666:	00002097          	auipc	ra,0x2
    8000266a:	ce6080e7          	jalr	-794(ra) # 8000434c <begin_op>
  iput(p->cwd);
    8000266e:	1689b503          	ld	a0,360(s3)
    80002672:	00001097          	auipc	ra,0x1
    80002676:	4c2080e7          	jalr	1218(ra) # 80003b34 <iput>
  end_op();
    8000267a:	00002097          	auipc	ra,0x2
    8000267e:	d52080e7          	jalr	-686(ra) # 800043cc <end_op>
  p->cwd = 0;
    80002682:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    80002686:	0000f517          	auipc	a0,0xf
    8000268a:	05250513          	addi	a0,a0,82 # 800116d8 <wait_lock>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	556080e7          	jalr	1366(ra) # 80000be4 <acquire>
  if((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)){
    80002696:	0309a783          	lw	a5,48(s3)
    8000269a:	0000f717          	auipc	a4,0xf
    8000269e:	08672703          	lw	a4,134(a4) # 80011720 <proc+0x30>
    800026a2:	0af70063          	beq	a4,a5,80002742 <exit+0x134>
    800026a6:	0000f717          	auipc	a4,0xf
    800026aa:	1fa72703          	lw	a4,506(a4) # 800118a0 <proc+0x1b0>
    800026ae:	08f70a63          	beq	a4,a5,80002742 <exit+0x134>
    program_time = program_time + p->running_time;
    800026b2:	0489a503          	lw	a0,72(s3)
    800026b6:	00007717          	auipc	a4,0x7
    800026ba:	97670713          	addi	a4,a4,-1674 # 8000902c <program_time>
    800026be:	431c                	lw	a5,0(a4)
    800026c0:	00a786bb          	addw	a3,a5,a0
    800026c4:	c314                	sw	a3,0(a4)
    cpu_utilization = (100*program_time)/(ticks-start_time);
    800026c6:	06400793          	li	a5,100
    800026ca:	02d787bb          	mulw	a5,a5,a3
    800026ce:	00007697          	auipc	a3,0x7
    800026d2:	9826a683          	lw	a3,-1662(a3) # 80009050 <ticks>
    800026d6:	00007717          	auipc	a4,0x7
    800026da:	95a72703          	lw	a4,-1702(a4) # 80009030 <start_time>
    800026de:	9e99                	subw	a3,a3,a4
    800026e0:	02d7d7bb          	divuw	a5,a5,a3
    800026e4:	00007717          	auipc	a4,0x7
    800026e8:	94f72223          	sw	a5,-1724(a4) # 80009028 <cpu_utilization>
    sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/(exited+1);
    800026ec:	00007617          	auipc	a2,0x7
    800026f0:	94862603          	lw	a2,-1720(a2) # 80009034 <exited>
    800026f4:	0016059b          	addiw	a1,a2,1
    800026f8:	00007797          	auipc	a5,0x7
    800026fc:	94878793          	addi	a5,a5,-1720 # 80009040 <sleeping_processes_mean>
    80002700:	4394                	lw	a3,0(a5)
    80002702:	02c686bb          	mulw	a3,a3,a2
    80002706:	0409a703          	lw	a4,64(s3)
    8000270a:	9eb9                	addw	a3,a3,a4
    8000270c:	02b6c6bb          	divw	a3,a3,a1
    80002710:	c394                	sw	a3,0(a5)
    running_processes_mean = ((running_processes_mean*exited) + p->running_time)/(exited+1);
    80002712:	00007797          	auipc	a5,0x7
    80002716:	92a78793          	addi	a5,a5,-1750 # 8000903c <running_processes_mean>
    8000271a:	4398                	lw	a4,0(a5)
    8000271c:	02c7073b          	mulw	a4,a4,a2
    80002720:	9f29                	addw	a4,a4,a0
    80002722:	02b7473b          	divw	a4,a4,a1
    80002726:	c398                	sw	a4,0(a5)
    runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/(exited+1);
    80002728:	00007717          	auipc	a4,0x7
    8000272c:	91070713          	addi	a4,a4,-1776 # 80009038 <runnable_processes_mean>
    80002730:	431c                	lw	a5,0(a4)
    80002732:	02c787bb          	mulw	a5,a5,a2
    80002736:	0449a683          	lw	a3,68(s3)
    8000273a:	9fb5                	addw	a5,a5,a3
    8000273c:	02b7c7bb          	divw	a5,a5,a1
    80002740:	c31c                	sw	a5,0(a4)
  exited = exited + 1;
    80002742:	00007717          	auipc	a4,0x7
    80002746:	8f270713          	addi	a4,a4,-1806 # 80009034 <exited>
    8000274a:	431c                	lw	a5,0(a4)
    8000274c:	2785                	addiw	a5,a5,1
    8000274e:	c31c                	sw	a5,0(a4)
  reparent(p);
    80002750:	854e                	mv	a0,s3
    80002752:	00000097          	auipc	ra,0x0
    80002756:	e62080e7          	jalr	-414(ra) # 800025b4 <reparent>
  wakeup(p->parent);
    8000275a:	0509b503          	ld	a0,80(s3)
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	dce080e7          	jalr	-562(ra) # 8000252c <wakeup>
  acquire(&p->lock);
    80002766:	854e                	mv	a0,s3
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	47c080e7          	jalr	1148(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002770:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002774:	4795                	li	a5,5
    80002776:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000277a:	0000f517          	auipc	a0,0xf
    8000277e:	f5e50513          	addi	a0,a0,-162 # 800116d8 <wait_lock>
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
  sched();
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	ab2080e7          	jalr	-1358(ra) # 8000223c <sched>
  panic("zombie exit");
    80002792:	00006517          	auipc	a0,0x6
    80002796:	ba650513          	addi	a0,a0,-1114 # 80008338 <digits+0x2f8>
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800027a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027a2:	7179                	addi	sp,sp,-48
    800027a4:	f406                	sd	ra,40(sp)
    800027a6:	f022                	sd	s0,32(sp)
    800027a8:	ec26                	sd	s1,24(sp)
    800027aa:	e84a                	sd	s2,16(sp)
    800027ac:	e44e                	sd	s3,8(sp)
    800027ae:	e052                	sd	s4,0(sp)
    800027b0:	1800                	addi	s0,sp,48
    800027b2:	84aa                	mv	s1,a0
    800027b4:	892e                	mv	s2,a1
    800027b6:	89b2                	mv	s3,a2
    800027b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	536080e7          	jalr	1334(ra) # 80001cf0 <myproc>
  if(user_dst){
    800027c2:	c08d                	beqz	s1,800027e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027c4:	86d2                	mv	a3,s4
    800027c6:	864e                	mv	a2,s3
    800027c8:	85ca                	mv	a1,s2
    800027ca:	7528                	ld	a0,104(a0)
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	ea6080e7          	jalr	-346(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d4:	70a2                	ld	ra,40(sp)
    800027d6:	7402                	ld	s0,32(sp)
    800027d8:	64e2                	ld	s1,24(sp)
    800027da:	6942                	ld	s2,16(sp)
    800027dc:	69a2                	ld	s3,8(sp)
    800027de:	6a02                	ld	s4,0(sp)
    800027e0:	6145                	addi	sp,sp,48
    800027e2:	8082                	ret
    memmove((char *)dst, src, len);
    800027e4:	000a061b          	sext.w	a2,s4
    800027e8:	85ce                	mv	a1,s3
    800027ea:	854a                	mv	a0,s2
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	554080e7          	jalr	1364(ra) # 80000d40 <memmove>
    return 0;
    800027f4:	8526                	mv	a0,s1
    800027f6:	bff9                	j	800027d4 <either_copyout+0x32>

00000000800027f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f8:	7179                	addi	sp,sp,-48
    800027fa:	f406                	sd	ra,40(sp)
    800027fc:	f022                	sd	s0,32(sp)
    800027fe:	ec26                	sd	s1,24(sp)
    80002800:	e84a                	sd	s2,16(sp)
    80002802:	e44e                	sd	s3,8(sp)
    80002804:	e052                	sd	s4,0(sp)
    80002806:	1800                	addi	s0,sp,48
    80002808:	892a                	mv	s2,a0
    8000280a:	84ae                	mv	s1,a1
    8000280c:	89b2                	mv	s3,a2
    8000280e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	4e0080e7          	jalr	1248(ra) # 80001cf0 <myproc>
  if(user_src){
    80002818:	c08d                	beqz	s1,8000283a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000281a:	86d2                	mv	a3,s4
    8000281c:	864e                	mv	a2,s3
    8000281e:	85ca                	mv	a1,s2
    80002820:	7528                	ld	a0,104(a0)
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	edc080e7          	jalr	-292(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000282a:	70a2                	ld	ra,40(sp)
    8000282c:	7402                	ld	s0,32(sp)
    8000282e:	64e2                	ld	s1,24(sp)
    80002830:	6942                	ld	s2,16(sp)
    80002832:	69a2                	ld	s3,8(sp)
    80002834:	6a02                	ld	s4,0(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret
    memmove(dst, (char*)src, len);
    8000283a:	000a061b          	sext.w	a2,s4
    8000283e:	85ce                	mv	a1,s3
    80002840:	854a                	mv	a0,s2
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	4fe080e7          	jalr	1278(ra) # 80000d40 <memmove>
    return 0;
    8000284a:	8526                	mv	a0,s1
    8000284c:	bff9                	j	8000282a <either_copyin+0x32>

000000008000284e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000284e:	715d                	addi	sp,sp,-80
    80002850:	e486                	sd	ra,72(sp)
    80002852:	e0a2                	sd	s0,64(sp)
    80002854:	fc26                	sd	s1,56(sp)
    80002856:	f84a                	sd	s2,48(sp)
    80002858:	f44e                	sd	s3,40(sp)
    8000285a:	f052                	sd	s4,32(sp)
    8000285c:	ec56                	sd	s5,24(sp)
    8000285e:	e85a                	sd	s6,16(sp)
    80002860:	e45e                	sd	s7,8(sp)
    80002862:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002864:	00006517          	auipc	a0,0x6
    80002868:	9a450513          	addi	a0,a0,-1628 # 80008208 <digits+0x1c8>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	d1c080e7          	jalr	-740(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002874:	0000f497          	auipc	s1,0xf
    80002878:	fec48493          	addi	s1,s1,-20 # 80011860 <proc+0x170>
    8000287c:	00015917          	auipc	s2,0x15
    80002880:	fe490913          	addi	s2,s2,-28 # 80017860 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002884:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002886:	00006997          	auipc	s3,0x6
    8000288a:	ac298993          	addi	s3,s3,-1342 # 80008348 <digits+0x308>
    printf("%d %s %s", p->pid, state, p->name);
    8000288e:	00006a97          	auipc	s5,0x6
    80002892:	ac2a8a93          	addi	s5,s5,-1342 # 80008350 <digits+0x310>
    printf("\n");
    80002896:	00006a17          	auipc	s4,0x6
    8000289a:	972a0a13          	addi	s4,s4,-1678 # 80008208 <digits+0x1c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289e:	00006b97          	auipc	s7,0x6
    800028a2:	aeab8b93          	addi	s7,s7,-1302 # 80008388 <states.1748>
    800028a6:	a00d                	j	800028c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a8:	ec06a583          	lw	a1,-320(a3)
    800028ac:	8556                	mv	a0,s5
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	cda080e7          	jalr	-806(ra) # 80000588 <printf>
    printf("\n");
    800028b6:	8552                	mv	a0,s4
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	cd0080e7          	jalr	-816(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028c0:	18048493          	addi	s1,s1,384
    800028c4:	03248163          	beq	s1,s2,800028e6 <procdump+0x98>
    if(p->state == UNUSED)
    800028c8:	86a6                	mv	a3,s1
    800028ca:	ea84a783          	lw	a5,-344(s1)
    800028ce:	dbed                	beqz	a5,800028c0 <procdump+0x72>
      state = "???";
    800028d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028d2:	fcfb6be3          	bltu	s6,a5,800028a8 <procdump+0x5a>
    800028d6:	1782                	slli	a5,a5,0x20
    800028d8:	9381                	srli	a5,a5,0x20
    800028da:	078e                	slli	a5,a5,0x3
    800028dc:	97de                	add	a5,a5,s7
    800028de:	6390                	ld	a2,0(a5)
    800028e0:	f661                	bnez	a2,800028a8 <procdump+0x5a>
      state = "???";
    800028e2:	864e                	mv	a2,s3
    800028e4:	b7d1                	j	800028a8 <procdump+0x5a>
  }
}
    800028e6:	60a6                	ld	ra,72(sp)
    800028e8:	6406                	ld	s0,64(sp)
    800028ea:	74e2                	ld	s1,56(sp)
    800028ec:	7942                	ld	s2,48(sp)
    800028ee:	79a2                	ld	s3,40(sp)
    800028f0:	7a02                	ld	s4,32(sp)
    800028f2:	6ae2                	ld	s5,24(sp)
    800028f4:	6b42                	ld	s6,16(sp)
    800028f6:	6ba2                	ld	s7,8(sp)
    800028f8:	6161                	addi	sp,sp,80
    800028fa:	8082                	ret

00000000800028fc <swtch>:
    800028fc:	00153023          	sd	ra,0(a0)
    80002900:	00253423          	sd	sp,8(a0)
    80002904:	e900                	sd	s0,16(a0)
    80002906:	ed04                	sd	s1,24(a0)
    80002908:	03253023          	sd	s2,32(a0)
    8000290c:	03353423          	sd	s3,40(a0)
    80002910:	03453823          	sd	s4,48(a0)
    80002914:	03553c23          	sd	s5,56(a0)
    80002918:	05653023          	sd	s6,64(a0)
    8000291c:	05753423          	sd	s7,72(a0)
    80002920:	05853823          	sd	s8,80(a0)
    80002924:	05953c23          	sd	s9,88(a0)
    80002928:	07a53023          	sd	s10,96(a0)
    8000292c:	07b53423          	sd	s11,104(a0)
    80002930:	0005b083          	ld	ra,0(a1)
    80002934:	0085b103          	ld	sp,8(a1)
    80002938:	6980                	ld	s0,16(a1)
    8000293a:	6d84                	ld	s1,24(a1)
    8000293c:	0205b903          	ld	s2,32(a1)
    80002940:	0285b983          	ld	s3,40(a1)
    80002944:	0305ba03          	ld	s4,48(a1)
    80002948:	0385ba83          	ld	s5,56(a1)
    8000294c:	0405bb03          	ld	s6,64(a1)
    80002950:	0485bb83          	ld	s7,72(a1)
    80002954:	0505bc03          	ld	s8,80(a1)
    80002958:	0585bc83          	ld	s9,88(a1)
    8000295c:	0605bd03          	ld	s10,96(a1)
    80002960:	0685bd83          	ld	s11,104(a1)
    80002964:	8082                	ret

0000000080002966 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002966:	1141                	addi	sp,sp,-16
    80002968:	e406                	sd	ra,8(sp)
    8000296a:	e022                	sd	s0,0(sp)
    8000296c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296e:	00006597          	auipc	a1,0x6
    80002972:	a4a58593          	addi	a1,a1,-1462 # 800083b8 <states.1748+0x30>
    80002976:	00015517          	auipc	a0,0x15
    8000297a:	d7a50513          	addi	a0,a0,-646 # 800176f0 <tickslock>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	1d6080e7          	jalr	470(ra) # 80000b54 <initlock>
}
    80002986:	60a2                	ld	ra,8(sp)
    80002988:	6402                	ld	s0,0(sp)
    8000298a:	0141                	addi	sp,sp,16
    8000298c:	8082                	ret

000000008000298e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298e:	1141                	addi	sp,sp,-16
    80002990:	e422                	sd	s0,8(sp)
    80002992:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002994:	00003797          	auipc	a5,0x3
    80002998:	49c78793          	addi	a5,a5,1180 # 80005e30 <kernelvec>
    8000299c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029a0:	6422                	ld	s0,8(sp)
    800029a2:	0141                	addi	sp,sp,16
    800029a4:	8082                	ret

00000000800029a6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a6:	1141                	addi	sp,sp,-16
    800029a8:	e406                	sd	ra,8(sp)
    800029aa:	e022                	sd	s0,0(sp)
    800029ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	342080e7          	jalr	834(ra) # 80001cf0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029c0:	00004617          	auipc	a2,0x4
    800029c4:	64060613          	addi	a2,a2,1600 # 80007000 <_trampoline>
    800029c8:	00004697          	auipc	a3,0x4
    800029cc:	63868693          	addi	a3,a3,1592 # 80007000 <_trampoline>
    800029d0:	8e91                	sub	a3,a3,a2
    800029d2:	040007b7          	lui	a5,0x4000
    800029d6:	17fd                	addi	a5,a5,-1
    800029d8:	07b2                	slli	a5,a5,0xc
    800029da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029dc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e0:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e2:	180026f3          	csrr	a3,satp
    800029e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e8:	7938                	ld	a4,112(a0)
    800029ea:	6d34                	ld	a3,88(a0)
    800029ec:	6585                	lui	a1,0x1
    800029ee:	96ae                	add	a3,a3,a1
    800029f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f2:	7938                	ld	a4,112(a0)
    800029f4:	00000697          	auipc	a3,0x0
    800029f8:	13868693          	addi	a3,a3,312 # 80002b2c <usertrap>
    800029fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fe:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a00:	8692                	mv	a3,tp
    80002a02:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a08:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a10:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a14:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a16:	6f18                	ld	a4,24(a4)
    80002a18:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1c:	752c                	ld	a1,104(a0)
    80002a1e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a20:	00004717          	auipc	a4,0x4
    80002a24:	67070713          	addi	a4,a4,1648 # 80007090 <userret>
    80002a28:	8f11                	sub	a4,a4,a2
    80002a2a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a2c:	577d                	li	a4,-1
    80002a2e:	177e                	slli	a4,a4,0x3f
    80002a30:	8dd9                	or	a1,a1,a4
    80002a32:	02000537          	lui	a0,0x2000
    80002a36:	157d                	addi	a0,a0,-1
    80002a38:	0536                	slli	a0,a0,0xd
    80002a3a:	9782                	jalr	a5
}
    80002a3c:	60a2                	ld	ra,8(sp)
    80002a3e:	6402                	ld	s0,0(sp)
    80002a40:	0141                	addi	sp,sp,16
    80002a42:	8082                	ret

0000000080002a44 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a44:	1101                	addi	sp,sp,-32
    80002a46:	ec06                	sd	ra,24(sp)
    80002a48:	e822                	sd	s0,16(sp)
    80002a4a:	e426                	sd	s1,8(sp)
    80002a4c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4e:	00015497          	auipc	s1,0x15
    80002a52:	ca248493          	addi	s1,s1,-862 # 800176f0 <tickslock>
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  ticks++;
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	5f050513          	addi	a0,a0,1520 # 80009050 <ticks>
    80002a68:	411c                	lw	a5,0(a0)
    80002a6a:	2785                	addiw	a5,a5,1
    80002a6c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	abe080e7          	jalr	-1346(ra) # 8000252c <wakeup>
  release(&tickslock);
    80002a76:	8526                	mv	a0,s1
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	220080e7          	jalr	544(ra) # 80000c98 <release>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret

0000000080002a8a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a8a:	1101                	addi	sp,sp,-32
    80002a8c:	ec06                	sd	ra,24(sp)
    80002a8e:	e822                	sd	s0,16(sp)
    80002a90:	e426                	sd	s1,8(sp)
    80002a92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a98:	00074d63          	bltz	a4,80002ab2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a9c:	57fd                	li	a5,-1
    80002a9e:	17fe                	slli	a5,a5,0x3f
    80002aa0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa4:	06f70363          	beq	a4,a5,80002b0a <devintr+0x80>
  }
}
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
     (scause & 0xff) == 9){
    80002ab2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab6:	46a5                	li	a3,9
    80002ab8:	fed792e3          	bne	a5,a3,80002a9c <devintr+0x12>
    int irq = plic_claim();
    80002abc:	00003097          	auipc	ra,0x3
    80002ac0:	47c080e7          	jalr	1148(ra) # 80005f38 <plic_claim>
    80002ac4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac6:	47a9                	li	a5,10
    80002ac8:	02f50763          	beq	a0,a5,80002af6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002acc:	4785                	li	a5,1
    80002ace:	02f50963          	beq	a0,a5,80002b00 <devintr+0x76>
    return 1;
    80002ad2:	4505                	li	a0,1
    } else if(irq){
    80002ad4:	d8f1                	beqz	s1,80002aa8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad6:	85a6                	mv	a1,s1
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	8e850513          	addi	a0,a0,-1816 # 800083c0 <states.1748+0x38>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	aa8080e7          	jalr	-1368(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	00003097          	auipc	ra,0x3
    80002aee:	472080e7          	jalr	1138(ra) # 80005f5c <plic_complete>
    return 1;
    80002af2:	4505                	li	a0,1
    80002af4:	bf55                	j	80002aa8 <devintr+0x1e>
      uartintr();
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	eb2080e7          	jalr	-334(ra) # 800009a8 <uartintr>
    80002afe:	b7ed                	j	80002ae8 <devintr+0x5e>
      virtio_disk_intr();
    80002b00:	00004097          	auipc	ra,0x4
    80002b04:	93c080e7          	jalr	-1732(ra) # 8000643c <virtio_disk_intr>
    80002b08:	b7c5                	j	80002ae8 <devintr+0x5e>
    if(cpuid() == 0){
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	1ba080e7          	jalr	442(ra) # 80001cc4 <cpuid>
    80002b12:	c901                	beqz	a0,80002b22 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b14:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b1a:	14479073          	csrw	sip,a5
    return 2;
    80002b1e:	4509                	li	a0,2
    80002b20:	b761                	j	80002aa8 <devintr+0x1e>
      clockintr();
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	f22080e7          	jalr	-222(ra) # 80002a44 <clockintr>
    80002b2a:	b7ed                	j	80002b14 <devintr+0x8a>

0000000080002b2c <usertrap>:
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b3a:	1007f793          	andi	a5,a5,256
    80002b3e:	e3a5                	bnez	a5,80002b9e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b40:	00003797          	auipc	a5,0x3
    80002b44:	2f078793          	addi	a5,a5,752 # 80005e30 <kernelvec>
    80002b48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	1a4080e7          	jalr	420(ra) # 80001cf0 <myproc>
    80002b54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b56:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102773          	csrr	a4,sepc
    80002b5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b62:	47a1                	li	a5,8
    80002b64:	04f71b63          	bne	a4,a5,80002bba <usertrap+0x8e>
    if(p->killed)
    80002b68:	551c                	lw	a5,40(a0)
    80002b6a:	e3b1                	bnez	a5,80002bae <usertrap+0x82>
    p->trapframe->epc += 4;
    80002b6c:	78b8                	ld	a4,112(s1)
    80002b6e:	6f1c                	ld	a5,24(a4)
    80002b70:	0791                	addi	a5,a5,4
    80002b72:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	29a080e7          	jalr	666(ra) # 80002e1a <syscall>
  if(p->killed)
    80002b88:	549c                	lw	a5,40(s1)
    80002b8a:	e7b5                	bnez	a5,80002bf6 <usertrap+0xca>
  usertrapret();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	e1a080e7          	jalr	-486(ra) # 800029a6 <usertrapret>
}
    80002b94:	60e2                	ld	ra,24(sp)
    80002b96:	6442                	ld	s0,16(sp)
    80002b98:	64a2                	ld	s1,8(sp)
    80002b9a:	6105                	addi	sp,sp,32
    80002b9c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	84250513          	addi	a0,a0,-1982 # 800083e0 <states.1748+0x58>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	998080e7          	jalr	-1640(ra) # 8000053e <panic>
      exit(-1);
    80002bae:	557d                	li	a0,-1
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	a5e080e7          	jalr	-1442(ra) # 8000260e <exit>
    80002bb8:	bf55                	j	80002b6c <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	ed0080e7          	jalr	-304(ra) # 80002a8a <devintr>
    80002bc2:	f179                	bnez	a0,80002b88 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bc4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc8:	5890                	lw	a2,48(s1)
    80002bca:	00006517          	auipc	a0,0x6
    80002bce:	83650513          	addi	a0,a0,-1994 # 80008400 <states.1748+0x78>
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9b6080e7          	jalr	-1610(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bda:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bde:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002be2:	00006517          	auipc	a0,0x6
    80002be6:	84e50513          	addi	a0,a0,-1970 # 80008430 <states.1748+0xa8>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	99e080e7          	jalr	-1634(ra) # 80000588 <printf>
    p->killed = 1;
    80002bf2:	4785                	li	a5,1
    80002bf4:	d49c                	sw	a5,40(s1)
    exit(-1); 
    80002bf6:	557d                	li	a0,-1
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	a16080e7          	jalr	-1514(ra) # 8000260e <exit>
    80002c00:	b771                	j	80002b8c <usertrap+0x60>

0000000080002c02 <kerneltrap>:
{
    80002c02:	7179                	addi	sp,sp,-48
    80002c04:	f406                	sd	ra,40(sp)
    80002c06:	f022                	sd	s0,32(sp)
    80002c08:	ec26                	sd	s1,24(sp)
    80002c0a:	e84a                	sd	s2,16(sp)
    80002c0c:	e44e                	sd	s3,8(sp)
    80002c0e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c10:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c18:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c1c:	1004f793          	andi	a5,s1,256
    80002c20:	c78d                	beqz	a5,80002c4a <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c26:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c28:	eb8d                	bnez	a5,80002c5a <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	e60080e7          	jalr	-416(ra) # 80002a8a <devintr>
    80002c32:	cd05                	beqz	a0,80002c6a <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c34:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c38:	10049073          	csrw	sstatus,s1
}
    80002c3c:	70a2                	ld	ra,40(sp)
    80002c3e:	7402                	ld	s0,32(sp)
    80002c40:	64e2                	ld	s1,24(sp)
    80002c42:	6942                	ld	s2,16(sp)
    80002c44:	69a2                	ld	s3,8(sp)
    80002c46:	6145                	addi	sp,sp,48
    80002c48:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c4a:	00006517          	auipc	a0,0x6
    80002c4e:	80650513          	addi	a0,a0,-2042 # 80008450 <states.1748+0xc8>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c5a:	00006517          	auipc	a0,0x6
    80002c5e:	81e50513          	addi	a0,a0,-2018 # 80008478 <states.1748+0xf0>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8dc080e7          	jalr	-1828(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c6a:	85ce                	mv	a1,s3
    80002c6c:	00006517          	auipc	a0,0x6
    80002c70:	82c50513          	addi	a0,a0,-2004 # 80008498 <states.1748+0x110>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	914080e7          	jalr	-1772(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c80:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c84:	00006517          	auipc	a0,0x6
    80002c88:	82450513          	addi	a0,a0,-2012 # 800084a8 <states.1748+0x120>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fc080e7          	jalr	-1796(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c94:	00006517          	auipc	a0,0x6
    80002c98:	82c50513          	addi	a0,a0,-2004 # 800084c0 <states.1748+0x138>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8a2080e7          	jalr	-1886(ra) # 8000053e <panic>

0000000080002ca4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	e426                	sd	s1,8(sp)
    80002cac:	1000                	addi	s0,sp,32
    80002cae:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	040080e7          	jalr	64(ra) # 80001cf0 <myproc>
  switch (n) {
    80002cb8:	4795                	li	a5,5
    80002cba:	0497e163          	bltu	a5,s1,80002cfc <argraw+0x58>
    80002cbe:	048a                	slli	s1,s1,0x2
    80002cc0:	00006717          	auipc	a4,0x6
    80002cc4:	83870713          	addi	a4,a4,-1992 # 800084f8 <states.1748+0x170>
    80002cc8:	94ba                	add	s1,s1,a4
    80002cca:	409c                	lw	a5,0(s1)
    80002ccc:	97ba                	add	a5,a5,a4
    80002cce:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cd0:	793c                	ld	a5,112(a0)
    80002cd2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	64a2                	ld	s1,8(sp)
    80002cda:	6105                	addi	sp,sp,32
    80002cdc:	8082                	ret
    return p->trapframe->a1;
    80002cde:	793c                	ld	a5,112(a0)
    80002ce0:	7fa8                	ld	a0,120(a5)
    80002ce2:	bfcd                	j	80002cd4 <argraw+0x30>
    return p->trapframe->a2;
    80002ce4:	793c                	ld	a5,112(a0)
    80002ce6:	63c8                	ld	a0,128(a5)
    80002ce8:	b7f5                	j	80002cd4 <argraw+0x30>
    return p->trapframe->a3;
    80002cea:	793c                	ld	a5,112(a0)
    80002cec:	67c8                	ld	a0,136(a5)
    80002cee:	b7dd                	j	80002cd4 <argraw+0x30>
    return p->trapframe->a4;
    80002cf0:	793c                	ld	a5,112(a0)
    80002cf2:	6bc8                	ld	a0,144(a5)
    80002cf4:	b7c5                	j	80002cd4 <argraw+0x30>
    return p->trapframe->a5;
    80002cf6:	793c                	ld	a5,112(a0)
    80002cf8:	6fc8                	ld	a0,152(a5)
    80002cfa:	bfe9                	j	80002cd4 <argraw+0x30>
  panic("argraw");
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	7d450513          	addi	a0,a0,2004 # 800084d0 <states.1748+0x148>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>

0000000080002d0c <fetchaddr>:
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	e04a                	sd	s2,0(sp)
    80002d16:	1000                	addi	s0,sp,32
    80002d18:	84aa                	mv	s1,a0
    80002d1a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	fd4080e7          	jalr	-44(ra) # 80001cf0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d24:	713c                	ld	a5,96(a0)
    80002d26:	02f4f863          	bgeu	s1,a5,80002d56 <fetchaddr+0x4a>
    80002d2a:	00848713          	addi	a4,s1,8
    80002d2e:	02e7e663          	bltu	a5,a4,80002d5a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d32:	46a1                	li	a3,8
    80002d34:	8626                	mv	a2,s1
    80002d36:	85ca                	mv	a1,s2
    80002d38:	7528                	ld	a0,104(a0)
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	9c4080e7          	jalr	-1596(ra) # 800016fe <copyin>
    80002d42:	00a03533          	snez	a0,a0
    80002d46:	40a00533          	neg	a0,a0
}
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6902                	ld	s2,0(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret
    return -1;
    80002d56:	557d                	li	a0,-1
    80002d58:	bfcd                	j	80002d4a <fetchaddr+0x3e>
    80002d5a:	557d                	li	a0,-1
    80002d5c:	b7fd                	j	80002d4a <fetchaddr+0x3e>

0000000080002d5e <fetchstr>:
{
    80002d5e:	7179                	addi	sp,sp,-48
    80002d60:	f406                	sd	ra,40(sp)
    80002d62:	f022                	sd	s0,32(sp)
    80002d64:	ec26                	sd	s1,24(sp)
    80002d66:	e84a                	sd	s2,16(sp)
    80002d68:	e44e                	sd	s3,8(sp)
    80002d6a:	1800                	addi	s0,sp,48
    80002d6c:	892a                	mv	s2,a0
    80002d6e:	84ae                	mv	s1,a1
    80002d70:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	f7e080e7          	jalr	-130(ra) # 80001cf0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d7a:	86ce                	mv	a3,s3
    80002d7c:	864a                	mv	a2,s2
    80002d7e:	85a6                	mv	a1,s1
    80002d80:	7528                	ld	a0,104(a0)
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	a08080e7          	jalr	-1528(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d8a:	00054763          	bltz	a0,80002d98 <fetchstr+0x3a>
  return strlen(buf);
    80002d8e:	8526                	mv	a0,s1
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	0d4080e7          	jalr	212(ra) # 80000e64 <strlen>
}
    80002d98:	70a2                	ld	ra,40(sp)
    80002d9a:	7402                	ld	s0,32(sp)
    80002d9c:	64e2                	ld	s1,24(sp)
    80002d9e:	6942                	ld	s2,16(sp)
    80002da0:	69a2                	ld	s3,8(sp)
    80002da2:	6145                	addi	sp,sp,48
    80002da4:	8082                	ret

0000000080002da6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002da6:	1101                	addi	sp,sp,-32
    80002da8:	ec06                	sd	ra,24(sp)
    80002daa:	e822                	sd	s0,16(sp)
    80002dac:	e426                	sd	s1,8(sp)
    80002dae:	1000                	addi	s0,sp,32
    80002db0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	ef2080e7          	jalr	-270(ra) # 80002ca4 <argraw>
    80002dba:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dbc:	4501                	li	a0,0
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret

0000000080002dc8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	e426                	sd	s1,8(sp)
    80002dd0:	1000                	addi	s0,sp,32
    80002dd2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	ed0080e7          	jalr	-304(ra) # 80002ca4 <argraw>
    80002ddc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dde:	4501                	li	a0,0
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	64a2                	ld	s1,8(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	e04a                	sd	s2,0(sp)
    80002df4:	1000                	addi	s0,sp,32
    80002df6:	84ae                	mv	s1,a1
    80002df8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	eaa080e7          	jalr	-342(ra) # 80002ca4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e02:	864a                	mv	a2,s2
    80002e04:	85a6                	mv	a1,s1
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	f58080e7          	jalr	-168(ra) # 80002d5e <fetchstr>
}
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	64a2                	ld	s1,8(sp)
    80002e14:	6902                	ld	s2,0(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	e04a                	sd	s2,0(sp)
    80002e24:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	eca080e7          	jalr	-310(ra) # 80001cf0 <myproc>
    80002e2e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e30:	07053903          	ld	s2,112(a0)
    80002e34:	0a893783          	ld	a5,168(s2)
    80002e38:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e3c:	37fd                	addiw	a5,a5,-1
    80002e3e:	475d                	li	a4,23
    80002e40:	00f76f63          	bltu	a4,a5,80002e5e <syscall+0x44>
    80002e44:	00369713          	slli	a4,a3,0x3
    80002e48:	00005797          	auipc	a5,0x5
    80002e4c:	6c878793          	addi	a5,a5,1736 # 80008510 <syscalls>
    80002e50:	97ba                	add	a5,a5,a4
    80002e52:	639c                	ld	a5,0(a5)
    80002e54:	c789                	beqz	a5,80002e5e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e56:	9782                	jalr	a5
    80002e58:	06a93823          	sd	a0,112(s2)
    80002e5c:	a839                	j	80002e7a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e5e:	17048613          	addi	a2,s1,368
    80002e62:	588c                	lw	a1,48(s1)
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	67450513          	addi	a0,a0,1652 # 800084d8 <states.1748+0x150>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	71c080e7          	jalr	1820(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e74:	78bc                	ld	a5,112(s1)
    80002e76:	577d                	li	a4,-1
    80002e78:	fbb8                	sd	a4,112(a5)
  }
}
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	64a2                	ld	s1,8(sp)
    80002e80:	6902                	ld	s2,0(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e86:	1101                	addi	sp,sp,-32
    80002e88:	ec06                	sd	ra,24(sp)
    80002e8a:	e822                	sd	s0,16(sp)
    80002e8c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e8e:	fec40593          	addi	a1,s0,-20
    80002e92:	4501                	li	a0,0
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	f12080e7          	jalr	-238(ra) # 80002da6 <argint>
    return -1;
    80002e9c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e9e:	00054963          	bltz	a0,80002eb0 <sys_exit+0x2a>
  exit(n);
    80002ea2:	fec42503          	lw	a0,-20(s0)
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	768080e7          	jalr	1896(ra) # 8000260e <exit>
  return 0;  // not reached
    80002eae:	4781                	li	a5,0
}
    80002eb0:	853e                	mv	a0,a5
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eba:	1141                	addi	sp,sp,-16
    80002ebc:	e406                	sd	ra,8(sp)
    80002ebe:	e022                	sd	s0,0(sp)
    80002ec0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	e2e080e7          	jalr	-466(ra) # 80001cf0 <myproc>
}
    80002eca:	5908                	lw	a0,48(a0)
    80002ecc:	60a2                	ld	ra,8(sp)
    80002ece:	6402                	ld	s0,0(sp)
    80002ed0:	0141                	addi	sp,sp,16
    80002ed2:	8082                	ret

0000000080002ed4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ed4:	1141                	addi	sp,sp,-16
    80002ed6:	e406                	sd	ra,8(sp)
    80002ed8:	e022                	sd	s0,0(sp)
    80002eda:	0800                	addi	s0,sp,16
  return fork();
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	218080e7          	jalr	536(ra) # 800020f4 <fork>
}
    80002ee4:	60a2                	ld	ra,8(sp)
    80002ee6:	6402                	ld	s0,0(sp)
    80002ee8:	0141                	addi	sp,sp,16
    80002eea:	8082                	ret

0000000080002eec <sys_wait>:

uint64
sys_wait(void)
{
    80002eec:	1101                	addi	sp,sp,-32
    80002eee:	ec06                	sd	ra,24(sp)
    80002ef0:	e822                	sd	s0,16(sp)
    80002ef2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ef4:	fe840593          	addi	a1,s0,-24
    80002ef8:	4501                	li	a0,0
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	ece080e7          	jalr	-306(ra) # 80002dc8 <argaddr>
    80002f02:	87aa                	mv	a5,a0
    return -1;
    80002f04:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f06:	0007c863          	bltz	a5,80002f16 <sys_wait+0x2a>
  return wait(p);
    80002f0a:	fe843503          	ld	a0,-24(s0)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	4f6080e7          	jalr	1270(ra) # 80002404 <wait>
}
    80002f16:	60e2                	ld	ra,24(sp)
    80002f18:	6442                	ld	s0,16(sp)
    80002f1a:	6105                	addi	sp,sp,32
    80002f1c:	8082                	ret

0000000080002f1e <sys_print_stats>:

void
sys_print_stats(void)
{
    80002f1e:	1141                	addi	sp,sp,-16
    80002f20:	e406                	sd	ra,8(sp)
    80002f22:	e022                	sd	s0,0(sp)
    80002f24:	0800                	addi	s0,sp,16
  return print_stats();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	abe080e7          	jalr	-1346(ra) # 800019e4 <print_stats>
}
    80002f2e:	60a2                	ld	ra,8(sp)
    80002f30:	6402                	ld	s0,0(sp)
    80002f32:	0141                	addi	sp,sp,16
    80002f34:	8082                	ret

0000000080002f36 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f36:	7179                	addi	sp,sp,-48
    80002f38:	f406                	sd	ra,40(sp)
    80002f3a:	f022                	sd	s0,32(sp)
    80002f3c:	ec26                	sd	s1,24(sp)
    80002f3e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f40:	fdc40593          	addi	a1,s0,-36
    80002f44:	4501                	li	a0,0
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	e60080e7          	jalr	-416(ra) # 80002da6 <argint>
    80002f4e:	87aa                	mv	a5,a0
    return -1;
    80002f50:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f52:	0207c063          	bltz	a5,80002f72 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	d9a080e7          	jalr	-614(ra) # 80001cf0 <myproc>
    80002f5e:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80002f60:	fdc42503          	lw	a0,-36(s0)
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	11c080e7          	jalr	284(ra) # 80002080 <growproc>
    80002f6c:	00054863          	bltz	a0,80002f7c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f70:	8526                	mv	a0,s1
}
    80002f72:	70a2                	ld	ra,40(sp)
    80002f74:	7402                	ld	s0,32(sp)
    80002f76:	64e2                	ld	s1,24(sp)
    80002f78:	6145                	addi	sp,sp,48
    80002f7a:	8082                	ret
    return -1;
    80002f7c:	557d                	li	a0,-1
    80002f7e:	bfd5                	j	80002f72 <sys_sbrk+0x3c>

0000000080002f80 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f80:	7139                	addi	sp,sp,-64
    80002f82:	fc06                	sd	ra,56(sp)
    80002f84:	f822                	sd	s0,48(sp)
    80002f86:	f426                	sd	s1,40(sp)
    80002f88:	f04a                	sd	s2,32(sp)
    80002f8a:	ec4e                	sd	s3,24(sp)
    80002f8c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f8e:	fcc40593          	addi	a1,s0,-52
    80002f92:	4501                	li	a0,0
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	e12080e7          	jalr	-494(ra) # 80002da6 <argint>
    return -1;
    80002f9c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f9e:	06054563          	bltz	a0,80003008 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	74e50513          	addi	a0,a0,1870 # 800176f0 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c3a080e7          	jalr	-966(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002fb2:	00006917          	auipc	s2,0x6
    80002fb6:	09e92903          	lw	s2,158(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002fba:	fcc42783          	lw	a5,-52(s0)
    80002fbe:	cf85                	beqz	a5,80002ff6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fc0:	00014997          	auipc	s3,0x14
    80002fc4:	73098993          	addi	s3,s3,1840 # 800176f0 <tickslock>
    80002fc8:	00006497          	auipc	s1,0x6
    80002fcc:	08848493          	addi	s1,s1,136 # 80009050 <ticks>
    if(myproc()->killed){
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	d20080e7          	jalr	-736(ra) # 80001cf0 <myproc>
    80002fd8:	551c                	lw	a5,40(a0)
    80002fda:	ef9d                	bnez	a5,80003018 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fdc:	85ce                	mv	a1,s3
    80002fde:	8526                	mv	a0,s1
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	3a6080e7          	jalr	934(ra) # 80002386 <sleep>
  while(ticks - ticks0 < n){
    80002fe8:	409c                	lw	a5,0(s1)
    80002fea:	412787bb          	subw	a5,a5,s2
    80002fee:	fcc42703          	lw	a4,-52(s0)
    80002ff2:	fce7efe3          	bltu	a5,a4,80002fd0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ff6:	00014517          	auipc	a0,0x14
    80002ffa:	6fa50513          	addi	a0,a0,1786 # 800176f0 <tickslock>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	c9a080e7          	jalr	-870(ra) # 80000c98 <release>
  return 0;
    80003006:	4781                	li	a5,0
}
    80003008:	853e                	mv	a0,a5
    8000300a:	70e2                	ld	ra,56(sp)
    8000300c:	7442                	ld	s0,48(sp)
    8000300e:	74a2                	ld	s1,40(sp)
    80003010:	7902                	ld	s2,32(sp)
    80003012:	69e2                	ld	s3,24(sp)
    80003014:	6121                	addi	sp,sp,64
    80003016:	8082                	ret
      release(&tickslock);
    80003018:	00014517          	auipc	a0,0x14
    8000301c:	6d850513          	addi	a0,a0,1752 # 800176f0 <tickslock>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	c78080e7          	jalr	-904(ra) # 80000c98 <release>
      return -1;
    80003028:	57fd                	li	a5,-1
    8000302a:	bff9                	j	80003008 <sys_sleep+0x88>

000000008000302c <sys_kill>:

uint64
sys_kill(void)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003034:	fec40593          	addi	a1,s0,-20
    80003038:	4501                	li	a0,0
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	d6c080e7          	jalr	-660(ra) # 80002da6 <argint>
    80003042:	87aa                	mv	a5,a0
    return -1;
    80003044:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003046:	0007c863          	bltz	a5,80003056 <sys_kill+0x2a>
  return kill(pid);
    8000304a:	fec42503          	lw	a0,-20(s0)
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	886080e7          	jalr	-1914(ra) # 800018d4 <kill>
}
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	6105                	addi	sp,sp,32
    8000305c:	8082                	ret

000000008000305e <sys_kill_sys>:

uint64
sys_kill_sys(void)
{
    8000305e:	1141                	addi	sp,sp,-16
    80003060:	e406                	sd	ra,8(sp)
    80003062:	e022                	sd	s0,0(sp)
    80003064:	0800                	addi	s0,sp,16
  return kill_sys();
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	8ea080e7          	jalr	-1814(ra) # 80001950 <kill_sys>
}
    8000306e:	60a2                	ld	ra,8(sp)
    80003070:	6402                	ld	s0,0(sp)
    80003072:	0141                	addi	sp,sp,16
    80003074:	8082                	ret

0000000080003076 <sys_pause_sys>:


uint64
sys_pause_sys(void)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    8000307e:	fec40593          	addi	a1,s0,-20
    80003082:	4501                	li	a0,0
    80003084:	00000097          	auipc	ra,0x0
    80003088:	d22080e7          	jalr	-734(ra) # 80002da6 <argint>
    8000308c:	87aa                	mv	a5,a0
    return -1;
    8000308e:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80003090:	0007c863          	bltz	a5,800030a0 <sys_pause_sys+0x2a>
  return pause_sys(time);
    80003094:	fec42503          	lw	a0,-20(s0)
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	2b8080e7          	jalr	696(ra) # 80002350 <pause_sys>
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	63e50513          	addi	a0,a0,1598 # 800176f0 <tickslock>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030c2:	00006497          	auipc	s1,0x6
    800030c6:	f8e4a483          	lw	s1,-114(s1) # 80009050 <ticks>
  release(&tickslock);
    800030ca:	00014517          	auipc	a0,0x14
    800030ce:	62650513          	addi	a0,a0,1574 # 800176f0 <tickslock>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	bc6080e7          	jalr	-1082(ra) # 80000c98 <release>
  return xticks;
}
    800030da:	02049513          	slli	a0,s1,0x20
    800030de:	9101                	srli	a0,a0,0x20
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6105                	addi	sp,sp,32
    800030e8:	8082                	ret

00000000800030ea <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030ea:	7179                	addi	sp,sp,-48
    800030ec:	f406                	sd	ra,40(sp)
    800030ee:	f022                	sd	s0,32(sp)
    800030f0:	ec26                	sd	s1,24(sp)
    800030f2:	e84a                	sd	s2,16(sp)
    800030f4:	e44e                	sd	s3,8(sp)
    800030f6:	e052                	sd	s4,0(sp)
    800030f8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030fa:	00005597          	auipc	a1,0x5
    800030fe:	4de58593          	addi	a1,a1,1246 # 800085d8 <syscalls+0xc8>
    80003102:	00014517          	auipc	a0,0x14
    80003106:	60650513          	addi	a0,a0,1542 # 80017708 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	a4a080e7          	jalr	-1462(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003112:	0001c797          	auipc	a5,0x1c
    80003116:	5f678793          	addi	a5,a5,1526 # 8001f708 <bcache+0x8000>
    8000311a:	0001d717          	auipc	a4,0x1d
    8000311e:	85670713          	addi	a4,a4,-1962 # 8001f970 <bcache+0x8268>
    80003122:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003126:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000312a:	00014497          	auipc	s1,0x14
    8000312e:	5f648493          	addi	s1,s1,1526 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    80003132:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003134:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003136:	00005a17          	auipc	s4,0x5
    8000313a:	4aaa0a13          	addi	s4,s4,1194 # 800085e0 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000313e:	2b893783          	ld	a5,696(s2)
    80003142:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003144:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003148:	85d2                	mv	a1,s4
    8000314a:	01048513          	addi	a0,s1,16
    8000314e:	00001097          	auipc	ra,0x1
    80003152:	4bc080e7          	jalr	1212(ra) # 8000460a <initsleeplock>
    bcache.head.next->prev = b;
    80003156:	2b893783          	ld	a5,696(s2)
    8000315a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000315c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003160:	45848493          	addi	s1,s1,1112
    80003164:	fd349de3          	bne	s1,s3,8000313e <binit+0x54>
  }
}
    80003168:	70a2                	ld	ra,40(sp)
    8000316a:	7402                	ld	s0,32(sp)
    8000316c:	64e2                	ld	s1,24(sp)
    8000316e:	6942                	ld	s2,16(sp)
    80003170:	69a2                	ld	s3,8(sp)
    80003172:	6a02                	ld	s4,0(sp)
    80003174:	6145                	addi	sp,sp,48
    80003176:	8082                	ret

0000000080003178 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003178:	7179                	addi	sp,sp,-48
    8000317a:	f406                	sd	ra,40(sp)
    8000317c:	f022                	sd	s0,32(sp)
    8000317e:	ec26                	sd	s1,24(sp)
    80003180:	e84a                	sd	s2,16(sp)
    80003182:	e44e                	sd	s3,8(sp)
    80003184:	1800                	addi	s0,sp,48
    80003186:	89aa                	mv	s3,a0
    80003188:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000318a:	00014517          	auipc	a0,0x14
    8000318e:	57e50513          	addi	a0,a0,1406 # 80017708 <bcache>
    80003192:	ffffe097          	auipc	ra,0xffffe
    80003196:	a52080e7          	jalr	-1454(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000319a:	0001d497          	auipc	s1,0x1d
    8000319e:	8264b483          	ld	s1,-2010(s1) # 8001f9c0 <bcache+0x82b8>
    800031a2:	0001c797          	auipc	a5,0x1c
    800031a6:	7ce78793          	addi	a5,a5,1998 # 8001f970 <bcache+0x8268>
    800031aa:	02f48f63          	beq	s1,a5,800031e8 <bread+0x70>
    800031ae:	873e                	mv	a4,a5
    800031b0:	a021                	j	800031b8 <bread+0x40>
    800031b2:	68a4                	ld	s1,80(s1)
    800031b4:	02e48a63          	beq	s1,a4,800031e8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b8:	449c                	lw	a5,8(s1)
    800031ba:	ff379ce3          	bne	a5,s3,800031b2 <bread+0x3a>
    800031be:	44dc                	lw	a5,12(s1)
    800031c0:	ff2799e3          	bne	a5,s2,800031b2 <bread+0x3a>
      b->refcnt++;
    800031c4:	40bc                	lw	a5,64(s1)
    800031c6:	2785                	addiw	a5,a5,1
    800031c8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ca:	00014517          	auipc	a0,0x14
    800031ce:	53e50513          	addi	a0,a0,1342 # 80017708 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031da:	01048513          	addi	a0,s1,16
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	466080e7          	jalr	1126(ra) # 80004644 <acquiresleep>
      return b;
    800031e6:	a8b9                	j	80003244 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e8:	0001c497          	auipc	s1,0x1c
    800031ec:	7d04b483          	ld	s1,2000(s1) # 8001f9b8 <bcache+0x82b0>
    800031f0:	0001c797          	auipc	a5,0x1c
    800031f4:	78078793          	addi	a5,a5,1920 # 8001f970 <bcache+0x8268>
    800031f8:	00f48863          	beq	s1,a5,80003208 <bread+0x90>
    800031fc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031fe:	40bc                	lw	a5,64(s1)
    80003200:	cf81                	beqz	a5,80003218 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003202:	64a4                	ld	s1,72(s1)
    80003204:	fee49de3          	bne	s1,a4,800031fe <bread+0x86>
  panic("bget: no buffers");
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	3e050513          	addi	a0,a0,992 # 800085e8 <syscalls+0xd8>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	32e080e7          	jalr	814(ra) # 8000053e <panic>
      b->dev = dev;
    80003218:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000321c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003220:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003224:	4785                	li	a5,1
    80003226:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003228:	00014517          	auipc	a0,0x14
    8000322c:	4e050513          	addi	a0,a0,1248 # 80017708 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	a68080e7          	jalr	-1432(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003238:	01048513          	addi	a0,s1,16
    8000323c:	00001097          	auipc	ra,0x1
    80003240:	408080e7          	jalr	1032(ra) # 80004644 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003244:	409c                	lw	a5,0(s1)
    80003246:	cb89                	beqz	a5,80003258 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003248:	8526                	mv	a0,s1
    8000324a:	70a2                	ld	ra,40(sp)
    8000324c:	7402                	ld	s0,32(sp)
    8000324e:	64e2                	ld	s1,24(sp)
    80003250:	6942                	ld	s2,16(sp)
    80003252:	69a2                	ld	s3,8(sp)
    80003254:	6145                	addi	sp,sp,48
    80003256:	8082                	ret
    virtio_disk_rw(b, 0);
    80003258:	4581                	li	a1,0
    8000325a:	8526                	mv	a0,s1
    8000325c:	00003097          	auipc	ra,0x3
    80003260:	f0a080e7          	jalr	-246(ra) # 80006166 <virtio_disk_rw>
    b->valid = 1;
    80003264:	4785                	li	a5,1
    80003266:	c09c                	sw	a5,0(s1)
  return b;
    80003268:	b7c5                	j	80003248 <bread+0xd0>

000000008000326a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	e426                	sd	s1,8(sp)
    80003272:	1000                	addi	s0,sp,32
    80003274:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003276:	0541                	addi	a0,a0,16
    80003278:	00001097          	auipc	ra,0x1
    8000327c:	466080e7          	jalr	1126(ra) # 800046de <holdingsleep>
    80003280:	cd01                	beqz	a0,80003298 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003282:	4585                	li	a1,1
    80003284:	8526                	mv	a0,s1
    80003286:	00003097          	auipc	ra,0x3
    8000328a:	ee0080e7          	jalr	-288(ra) # 80006166 <virtio_disk_rw>
}
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	64a2                	ld	s1,8(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret
    panic("bwrite");
    80003298:	00005517          	auipc	a0,0x5
    8000329c:	36850513          	addi	a0,a0,872 # 80008600 <syscalls+0xf0>
    800032a0:	ffffd097          	auipc	ra,0xffffd
    800032a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>

00000000800032a8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	e04a                	sd	s2,0(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b6:	01050913          	addi	s2,a0,16
    800032ba:	854a                	mv	a0,s2
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	422080e7          	jalr	1058(ra) # 800046de <holdingsleep>
    800032c4:	c92d                	beqz	a0,80003336 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032c6:	854a                	mv	a0,s2
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	3d2080e7          	jalr	978(ra) # 8000469a <releasesleep>

  acquire(&bcache.lock);
    800032d0:	00014517          	auipc	a0,0x14
    800032d4:	43850513          	addi	a0,a0,1080 # 80017708 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	90c080e7          	jalr	-1780(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032e0:	40bc                	lw	a5,64(s1)
    800032e2:	37fd                	addiw	a5,a5,-1
    800032e4:	0007871b          	sext.w	a4,a5
    800032e8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032ea:	eb05                	bnez	a4,8000331a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ec:	68bc                	ld	a5,80(s1)
    800032ee:	64b8                	ld	a4,72(s1)
    800032f0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032f2:	64bc                	ld	a5,72(s1)
    800032f4:	68b8                	ld	a4,80(s1)
    800032f6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032f8:	0001c797          	auipc	a5,0x1c
    800032fc:	41078793          	addi	a5,a5,1040 # 8001f708 <bcache+0x8000>
    80003300:	2b87b703          	ld	a4,696(a5)
    80003304:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003306:	0001c717          	auipc	a4,0x1c
    8000330a:	66a70713          	addi	a4,a4,1642 # 8001f970 <bcache+0x8268>
    8000330e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003310:	2b87b703          	ld	a4,696(a5)
    80003314:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003316:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000331a:	00014517          	auipc	a0,0x14
    8000331e:	3ee50513          	addi	a0,a0,1006 # 80017708 <bcache>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
}
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6902                	ld	s2,0(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret
    panic("brelse");
    80003336:	00005517          	auipc	a0,0x5
    8000333a:	2d250513          	addi	a0,a0,722 # 80008608 <syscalls+0xf8>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080003346 <bpin>:

void
bpin(struct buf *b) {
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	e426                	sd	s1,8(sp)
    8000334e:	1000                	addi	s0,sp,32
    80003350:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003352:	00014517          	auipc	a0,0x14
    80003356:	3b650513          	addi	a0,a0,950 # 80017708 <bcache>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	88a080e7          	jalr	-1910(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003362:	40bc                	lw	a5,64(s1)
    80003364:	2785                	addiw	a5,a5,1
    80003366:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003368:	00014517          	auipc	a0,0x14
    8000336c:	3a050513          	addi	a0,a0,928 # 80017708 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	928080e7          	jalr	-1752(ra) # 80000c98 <release>
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6105                	addi	sp,sp,32
    80003380:	8082                	ret

0000000080003382 <bunpin>:

void
bunpin(struct buf *b) {
    80003382:	1101                	addi	sp,sp,-32
    80003384:	ec06                	sd	ra,24(sp)
    80003386:	e822                	sd	s0,16(sp)
    80003388:	e426                	sd	s1,8(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000338e:	00014517          	auipc	a0,0x14
    80003392:	37a50513          	addi	a0,a0,890 # 80017708 <bcache>
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	84e080e7          	jalr	-1970(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000339e:	40bc                	lw	a5,64(s1)
    800033a0:	37fd                	addiw	a5,a5,-1
    800033a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a4:	00014517          	auipc	a0,0x14
    800033a8:	36450513          	addi	a0,a0,868 # 80017708 <bcache>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>
}
    800033b4:	60e2                	ld	ra,24(sp)
    800033b6:	6442                	ld	s0,16(sp)
    800033b8:	64a2                	ld	s1,8(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033be:	1101                	addi	sp,sp,-32
    800033c0:	ec06                	sd	ra,24(sp)
    800033c2:	e822                	sd	s0,16(sp)
    800033c4:	e426                	sd	s1,8(sp)
    800033c6:	e04a                	sd	s2,0(sp)
    800033c8:	1000                	addi	s0,sp,32
    800033ca:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033cc:	00d5d59b          	srliw	a1,a1,0xd
    800033d0:	0001d797          	auipc	a5,0x1d
    800033d4:	a147a783          	lw	a5,-1516(a5) # 8001fde4 <sb+0x1c>
    800033d8:	9dbd                	addw	a1,a1,a5
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d9e080e7          	jalr	-610(ra) # 80003178 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033e2:	0074f713          	andi	a4,s1,7
    800033e6:	4785                	li	a5,1
    800033e8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ec:	14ce                	slli	s1,s1,0x33
    800033ee:	90d9                	srli	s1,s1,0x36
    800033f0:	00950733          	add	a4,a0,s1
    800033f4:	05874703          	lbu	a4,88(a4)
    800033f8:	00e7f6b3          	and	a3,a5,a4
    800033fc:	c69d                	beqz	a3,8000342a <bfree+0x6c>
    800033fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003400:	94aa                	add	s1,s1,a0
    80003402:	fff7c793          	not	a5,a5
    80003406:	8ff9                	and	a5,a5,a4
    80003408:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000340c:	00001097          	auipc	ra,0x1
    80003410:	118080e7          	jalr	280(ra) # 80004524 <log_write>
  brelse(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	e92080e7          	jalr	-366(ra) # 800032a8 <brelse>
}
    8000341e:	60e2                	ld	ra,24(sp)
    80003420:	6442                	ld	s0,16(sp)
    80003422:	64a2                	ld	s1,8(sp)
    80003424:	6902                	ld	s2,0(sp)
    80003426:	6105                	addi	sp,sp,32
    80003428:	8082                	ret
    panic("freeing free block");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	1e650513          	addi	a0,a0,486 # 80008610 <syscalls+0x100>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	10c080e7          	jalr	268(ra) # 8000053e <panic>

000000008000343a <balloc>:
{
    8000343a:	711d                	addi	sp,sp,-96
    8000343c:	ec86                	sd	ra,88(sp)
    8000343e:	e8a2                	sd	s0,80(sp)
    80003440:	e4a6                	sd	s1,72(sp)
    80003442:	e0ca                	sd	s2,64(sp)
    80003444:	fc4e                	sd	s3,56(sp)
    80003446:	f852                	sd	s4,48(sp)
    80003448:	f456                	sd	s5,40(sp)
    8000344a:	f05a                	sd	s6,32(sp)
    8000344c:	ec5e                	sd	s7,24(sp)
    8000344e:	e862                	sd	s8,16(sp)
    80003450:	e466                	sd	s9,8(sp)
    80003452:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003454:	0001d797          	auipc	a5,0x1d
    80003458:	9787a783          	lw	a5,-1672(a5) # 8001fdcc <sb+0x4>
    8000345c:	cbd1                	beqz	a5,800034f0 <balloc+0xb6>
    8000345e:	8baa                	mv	s7,a0
    80003460:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003462:	0001db17          	auipc	s6,0x1d
    80003466:	966b0b13          	addi	s6,s6,-1690 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000346c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003470:	6c89                	lui	s9,0x2
    80003472:	a831                	j	8000348e <balloc+0x54>
    brelse(bp);
    80003474:	854a                	mv	a0,s2
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	e32080e7          	jalr	-462(ra) # 800032a8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000347e:	015c87bb          	addw	a5,s9,s5
    80003482:	00078a9b          	sext.w	s5,a5
    80003486:	004b2703          	lw	a4,4(s6)
    8000348a:	06eaf363          	bgeu	s5,a4,800034f0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000348e:	41fad79b          	sraiw	a5,s5,0x1f
    80003492:	0137d79b          	srliw	a5,a5,0x13
    80003496:	015787bb          	addw	a5,a5,s5
    8000349a:	40d7d79b          	sraiw	a5,a5,0xd
    8000349e:	01cb2583          	lw	a1,28(s6)
    800034a2:	9dbd                	addw	a1,a1,a5
    800034a4:	855e                	mv	a0,s7
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	cd2080e7          	jalr	-814(ra) # 80003178 <bread>
    800034ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b0:	004b2503          	lw	a0,4(s6)
    800034b4:	000a849b          	sext.w	s1,s5
    800034b8:	8662                	mv	a2,s8
    800034ba:	faa4fde3          	bgeu	s1,a0,80003474 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034be:	41f6579b          	sraiw	a5,a2,0x1f
    800034c2:	01d7d69b          	srliw	a3,a5,0x1d
    800034c6:	00c6873b          	addw	a4,a3,a2
    800034ca:	00777793          	andi	a5,a4,7
    800034ce:	9f95                	subw	a5,a5,a3
    800034d0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034d4:	4037571b          	sraiw	a4,a4,0x3
    800034d8:	00e906b3          	add	a3,s2,a4
    800034dc:	0586c683          	lbu	a3,88(a3)
    800034e0:	00d7f5b3          	and	a1,a5,a3
    800034e4:	cd91                	beqz	a1,80003500 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e6:	2605                	addiw	a2,a2,1
    800034e8:	2485                	addiw	s1,s1,1
    800034ea:	fd4618e3          	bne	a2,s4,800034ba <balloc+0x80>
    800034ee:	b759                	j	80003474 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034f0:	00005517          	auipc	a0,0x5
    800034f4:	13850513          	addi	a0,a0,312 # 80008628 <syscalls+0x118>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	046080e7          	jalr	70(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003500:	974a                	add	a4,a4,s2
    80003502:	8fd5                	or	a5,a5,a3
    80003504:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003508:	854a                	mv	a0,s2
    8000350a:	00001097          	auipc	ra,0x1
    8000350e:	01a080e7          	jalr	26(ra) # 80004524 <log_write>
        brelse(bp);
    80003512:	854a                	mv	a0,s2
    80003514:	00000097          	auipc	ra,0x0
    80003518:	d94080e7          	jalr	-620(ra) # 800032a8 <brelse>
  bp = bread(dev, bno);
    8000351c:	85a6                	mv	a1,s1
    8000351e:	855e                	mv	a0,s7
    80003520:	00000097          	auipc	ra,0x0
    80003524:	c58080e7          	jalr	-936(ra) # 80003178 <bread>
    80003528:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000352a:	40000613          	li	a2,1024
    8000352e:	4581                	li	a1,0
    80003530:	05850513          	addi	a0,a0,88
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	7ac080e7          	jalr	1964(ra) # 80000ce0 <memset>
  log_write(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	fe6080e7          	jalr	-26(ra) # 80004524 <log_write>
  brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	d60080e7          	jalr	-672(ra) # 800032a8 <brelse>
}
    80003550:	8526                	mv	a0,s1
    80003552:	60e6                	ld	ra,88(sp)
    80003554:	6446                	ld	s0,80(sp)
    80003556:	64a6                	ld	s1,72(sp)
    80003558:	6906                	ld	s2,64(sp)
    8000355a:	79e2                	ld	s3,56(sp)
    8000355c:	7a42                	ld	s4,48(sp)
    8000355e:	7aa2                	ld	s5,40(sp)
    80003560:	7b02                	ld	s6,32(sp)
    80003562:	6be2                	ld	s7,24(sp)
    80003564:	6c42                	ld	s8,16(sp)
    80003566:	6ca2                	ld	s9,8(sp)
    80003568:	6125                	addi	sp,sp,96
    8000356a:	8082                	ret

000000008000356c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000356c:	7179                	addi	sp,sp,-48
    8000356e:	f406                	sd	ra,40(sp)
    80003570:	f022                	sd	s0,32(sp)
    80003572:	ec26                	sd	s1,24(sp)
    80003574:	e84a                	sd	s2,16(sp)
    80003576:	e44e                	sd	s3,8(sp)
    80003578:	e052                	sd	s4,0(sp)
    8000357a:	1800                	addi	s0,sp,48
    8000357c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000357e:	47ad                	li	a5,11
    80003580:	04b7fe63          	bgeu	a5,a1,800035dc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003584:	ff45849b          	addiw	s1,a1,-12
    80003588:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000358c:	0ff00793          	li	a5,255
    80003590:	0ae7e363          	bltu	a5,a4,80003636 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003594:	08052583          	lw	a1,128(a0)
    80003598:	c5ad                	beqz	a1,80003602 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000359a:	00092503          	lw	a0,0(s2)
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	bda080e7          	jalr	-1062(ra) # 80003178 <bread>
    800035a6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035a8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035ac:	02049593          	slli	a1,s1,0x20
    800035b0:	9181                	srli	a1,a1,0x20
    800035b2:	058a                	slli	a1,a1,0x2
    800035b4:	00b784b3          	add	s1,a5,a1
    800035b8:	0004a983          	lw	s3,0(s1)
    800035bc:	04098d63          	beqz	s3,80003616 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035c0:	8552                	mv	a0,s4
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	ce6080e7          	jalr	-794(ra) # 800032a8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ca:	854e                	mv	a0,s3
    800035cc:	70a2                	ld	ra,40(sp)
    800035ce:	7402                	ld	s0,32(sp)
    800035d0:	64e2                	ld	s1,24(sp)
    800035d2:	6942                	ld	s2,16(sp)
    800035d4:	69a2                	ld	s3,8(sp)
    800035d6:	6a02                	ld	s4,0(sp)
    800035d8:	6145                	addi	sp,sp,48
    800035da:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035dc:	02059493          	slli	s1,a1,0x20
    800035e0:	9081                	srli	s1,s1,0x20
    800035e2:	048a                	slli	s1,s1,0x2
    800035e4:	94aa                	add	s1,s1,a0
    800035e6:	0504a983          	lw	s3,80(s1)
    800035ea:	fe0990e3          	bnez	s3,800035ca <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035ee:	4108                	lw	a0,0(a0)
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	e4a080e7          	jalr	-438(ra) # 8000343a <balloc>
    800035f8:	0005099b          	sext.w	s3,a0
    800035fc:	0534a823          	sw	s3,80(s1)
    80003600:	b7e9                	j	800035ca <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003602:	4108                	lw	a0,0(a0)
    80003604:	00000097          	auipc	ra,0x0
    80003608:	e36080e7          	jalr	-458(ra) # 8000343a <balloc>
    8000360c:	0005059b          	sext.w	a1,a0
    80003610:	08b92023          	sw	a1,128(s2)
    80003614:	b759                	j	8000359a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003616:	00092503          	lw	a0,0(s2)
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	e20080e7          	jalr	-480(ra) # 8000343a <balloc>
    80003622:	0005099b          	sext.w	s3,a0
    80003626:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000362a:	8552                	mv	a0,s4
    8000362c:	00001097          	auipc	ra,0x1
    80003630:	ef8080e7          	jalr	-264(ra) # 80004524 <log_write>
    80003634:	b771                	j	800035c0 <bmap+0x54>
  panic("bmap: out of range");
    80003636:	00005517          	auipc	a0,0x5
    8000363a:	00a50513          	addi	a0,a0,10 # 80008640 <syscalls+0x130>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>

0000000080003646 <iget>:
{
    80003646:	7179                	addi	sp,sp,-48
    80003648:	f406                	sd	ra,40(sp)
    8000364a:	f022                	sd	s0,32(sp)
    8000364c:	ec26                	sd	s1,24(sp)
    8000364e:	e84a                	sd	s2,16(sp)
    80003650:	e44e                	sd	s3,8(sp)
    80003652:	e052                	sd	s4,0(sp)
    80003654:	1800                	addi	s0,sp,48
    80003656:	89aa                	mv	s3,a0
    80003658:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000365a:	0001c517          	auipc	a0,0x1c
    8000365e:	78e50513          	addi	a0,a0,1934 # 8001fde8 <itable>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	582080e7          	jalr	1410(ra) # 80000be4 <acquire>
  empty = 0;
    8000366a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000366c:	0001c497          	auipc	s1,0x1c
    80003670:	79448493          	addi	s1,s1,1940 # 8001fe00 <itable+0x18>
    80003674:	0001e697          	auipc	a3,0x1e
    80003678:	21c68693          	addi	a3,a3,540 # 80021890 <log>
    8000367c:	a039                	j	8000368a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000367e:	02090b63          	beqz	s2,800036b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003682:	08848493          	addi	s1,s1,136
    80003686:	02d48a63          	beq	s1,a3,800036ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000368a:	449c                	lw	a5,8(s1)
    8000368c:	fef059e3          	blez	a5,8000367e <iget+0x38>
    80003690:	4098                	lw	a4,0(s1)
    80003692:	ff3716e3          	bne	a4,s3,8000367e <iget+0x38>
    80003696:	40d8                	lw	a4,4(s1)
    80003698:	ff4713e3          	bne	a4,s4,8000367e <iget+0x38>
      ip->ref++;
    8000369c:	2785                	addiw	a5,a5,1
    8000369e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036a0:	0001c517          	auipc	a0,0x1c
    800036a4:	74850513          	addi	a0,a0,1864 # 8001fde8 <itable>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	5f0080e7          	jalr	1520(ra) # 80000c98 <release>
      return ip;
    800036b0:	8926                	mv	s2,s1
    800036b2:	a03d                	j	800036e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b4:	f7f9                	bnez	a5,80003682 <iget+0x3c>
    800036b6:	8926                	mv	s2,s1
    800036b8:	b7e9                	j	80003682 <iget+0x3c>
  if(empty == 0)
    800036ba:	02090c63          	beqz	s2,800036f2 <iget+0xac>
  ip->dev = dev;
    800036be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036c6:	4785                	li	a5,1
    800036c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036d0:	0001c517          	auipc	a0,0x1c
    800036d4:	71850513          	addi	a0,a0,1816 # 8001fde8 <itable>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	5c0080e7          	jalr	1472(ra) # 80000c98 <release>
}
    800036e0:	854a                	mv	a0,s2
    800036e2:	70a2                	ld	ra,40(sp)
    800036e4:	7402                	ld	s0,32(sp)
    800036e6:	64e2                	ld	s1,24(sp)
    800036e8:	6942                	ld	s2,16(sp)
    800036ea:	69a2                	ld	s3,8(sp)
    800036ec:	6a02                	ld	s4,0(sp)
    800036ee:	6145                	addi	sp,sp,48
    800036f0:	8082                	ret
    panic("iget: no inodes");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	f6650513          	addi	a0,a0,-154 # 80008658 <syscalls+0x148>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>

0000000080003702 <fsinit>:
fsinit(int dev) {
    80003702:	7179                	addi	sp,sp,-48
    80003704:	f406                	sd	ra,40(sp)
    80003706:	f022                	sd	s0,32(sp)
    80003708:	ec26                	sd	s1,24(sp)
    8000370a:	e84a                	sd	s2,16(sp)
    8000370c:	e44e                	sd	s3,8(sp)
    8000370e:	1800                	addi	s0,sp,48
    80003710:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003712:	4585                	li	a1,1
    80003714:	00000097          	auipc	ra,0x0
    80003718:	a64080e7          	jalr	-1436(ra) # 80003178 <bread>
    8000371c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000371e:	0001c997          	auipc	s3,0x1c
    80003722:	6aa98993          	addi	s3,s3,1706 # 8001fdc8 <sb>
    80003726:	02000613          	li	a2,32
    8000372a:	05850593          	addi	a1,a0,88
    8000372e:	854e                	mv	a0,s3
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	610080e7          	jalr	1552(ra) # 80000d40 <memmove>
  brelse(bp);
    80003738:	8526                	mv	a0,s1
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	b6e080e7          	jalr	-1170(ra) # 800032a8 <brelse>
  if(sb.magic != FSMAGIC)
    80003742:	0009a703          	lw	a4,0(s3)
    80003746:	102037b7          	lui	a5,0x10203
    8000374a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000374e:	02f71263          	bne	a4,a5,80003772 <fsinit+0x70>
  initlog(dev, &sb);
    80003752:	0001c597          	auipc	a1,0x1c
    80003756:	67658593          	addi	a1,a1,1654 # 8001fdc8 <sb>
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	b4c080e7          	jalr	-1204(ra) # 800042a8 <initlog>
}
    80003764:	70a2                	ld	ra,40(sp)
    80003766:	7402                	ld	s0,32(sp)
    80003768:	64e2                	ld	s1,24(sp)
    8000376a:	6942                	ld	s2,16(sp)
    8000376c:	69a2                	ld	s3,8(sp)
    8000376e:	6145                	addi	sp,sp,48
    80003770:	8082                	ret
    panic("invalid file system");
    80003772:	00005517          	auipc	a0,0x5
    80003776:	ef650513          	addi	a0,a0,-266 # 80008668 <syscalls+0x158>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>

0000000080003782 <iinit>:
{
    80003782:	7179                	addi	sp,sp,-48
    80003784:	f406                	sd	ra,40(sp)
    80003786:	f022                	sd	s0,32(sp)
    80003788:	ec26                	sd	s1,24(sp)
    8000378a:	e84a                	sd	s2,16(sp)
    8000378c:	e44e                	sd	s3,8(sp)
    8000378e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003790:	00005597          	auipc	a1,0x5
    80003794:	ef058593          	addi	a1,a1,-272 # 80008680 <syscalls+0x170>
    80003798:	0001c517          	auipc	a0,0x1c
    8000379c:	65050513          	addi	a0,a0,1616 # 8001fde8 <itable>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	3b4080e7          	jalr	948(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a8:	0001c497          	auipc	s1,0x1c
    800037ac:	66848493          	addi	s1,s1,1640 # 8001fe10 <itable+0x28>
    800037b0:	0001e997          	auipc	s3,0x1e
    800037b4:	0f098993          	addi	s3,s3,240 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037b8:	00005917          	auipc	s2,0x5
    800037bc:	ed090913          	addi	s2,s2,-304 # 80008688 <syscalls+0x178>
    800037c0:	85ca                	mv	a1,s2
    800037c2:	8526                	mv	a0,s1
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	e46080e7          	jalr	-442(ra) # 8000460a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037cc:	08848493          	addi	s1,s1,136
    800037d0:	ff3498e3          	bne	s1,s3,800037c0 <iinit+0x3e>
}
    800037d4:	70a2                	ld	ra,40(sp)
    800037d6:	7402                	ld	s0,32(sp)
    800037d8:	64e2                	ld	s1,24(sp)
    800037da:	6942                	ld	s2,16(sp)
    800037dc:	69a2                	ld	s3,8(sp)
    800037de:	6145                	addi	sp,sp,48
    800037e0:	8082                	ret

00000000800037e2 <ialloc>:
{
    800037e2:	715d                	addi	sp,sp,-80
    800037e4:	e486                	sd	ra,72(sp)
    800037e6:	e0a2                	sd	s0,64(sp)
    800037e8:	fc26                	sd	s1,56(sp)
    800037ea:	f84a                	sd	s2,48(sp)
    800037ec:	f44e                	sd	s3,40(sp)
    800037ee:	f052                	sd	s4,32(sp)
    800037f0:	ec56                	sd	s5,24(sp)
    800037f2:	e85a                	sd	s6,16(sp)
    800037f4:	e45e                	sd	s7,8(sp)
    800037f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f8:	0001c717          	auipc	a4,0x1c
    800037fc:	5dc72703          	lw	a4,1500(a4) # 8001fdd4 <sb+0xc>
    80003800:	4785                	li	a5,1
    80003802:	04e7fa63          	bgeu	a5,a4,80003856 <ialloc+0x74>
    80003806:	8aaa                	mv	s5,a0
    80003808:	8bae                	mv	s7,a1
    8000380a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000380c:	0001ca17          	auipc	s4,0x1c
    80003810:	5bca0a13          	addi	s4,s4,1468 # 8001fdc8 <sb>
    80003814:	00048b1b          	sext.w	s6,s1
    80003818:	0044d593          	srli	a1,s1,0x4
    8000381c:	018a2783          	lw	a5,24(s4)
    80003820:	9dbd                	addw	a1,a1,a5
    80003822:	8556                	mv	a0,s5
    80003824:	00000097          	auipc	ra,0x0
    80003828:	954080e7          	jalr	-1708(ra) # 80003178 <bread>
    8000382c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000382e:	05850993          	addi	s3,a0,88
    80003832:	00f4f793          	andi	a5,s1,15
    80003836:	079a                	slli	a5,a5,0x6
    80003838:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000383a:	00099783          	lh	a5,0(s3)
    8000383e:	c785                	beqz	a5,80003866 <ialloc+0x84>
    brelse(bp);
    80003840:	00000097          	auipc	ra,0x0
    80003844:	a68080e7          	jalr	-1432(ra) # 800032a8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003848:	0485                	addi	s1,s1,1
    8000384a:	00ca2703          	lw	a4,12(s4)
    8000384e:	0004879b          	sext.w	a5,s1
    80003852:	fce7e1e3          	bltu	a5,a4,80003814 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	e3a50513          	addi	a0,a0,-454 # 80008690 <syscalls+0x180>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003866:	04000613          	li	a2,64
    8000386a:	4581                	li	a1,0
    8000386c:	854e                	mv	a0,s3
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	472080e7          	jalr	1138(ra) # 80000ce0 <memset>
      dip->type = type;
    80003876:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000387a:	854a                	mv	a0,s2
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	ca8080e7          	jalr	-856(ra) # 80004524 <log_write>
      brelse(bp);
    80003884:	854a                	mv	a0,s2
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	a22080e7          	jalr	-1502(ra) # 800032a8 <brelse>
      return iget(dev, inum);
    8000388e:	85da                	mv	a1,s6
    80003890:	8556                	mv	a0,s5
    80003892:	00000097          	auipc	ra,0x0
    80003896:	db4080e7          	jalr	-588(ra) # 80003646 <iget>
}
    8000389a:	60a6                	ld	ra,72(sp)
    8000389c:	6406                	ld	s0,64(sp)
    8000389e:	74e2                	ld	s1,56(sp)
    800038a0:	7942                	ld	s2,48(sp)
    800038a2:	79a2                	ld	s3,40(sp)
    800038a4:	7a02                	ld	s4,32(sp)
    800038a6:	6ae2                	ld	s5,24(sp)
    800038a8:	6b42                	ld	s6,16(sp)
    800038aa:	6ba2                	ld	s7,8(sp)
    800038ac:	6161                	addi	sp,sp,80
    800038ae:	8082                	ret

00000000800038b0 <iupdate>:
{
    800038b0:	1101                	addi	sp,sp,-32
    800038b2:	ec06                	sd	ra,24(sp)
    800038b4:	e822                	sd	s0,16(sp)
    800038b6:	e426                	sd	s1,8(sp)
    800038b8:	e04a                	sd	s2,0(sp)
    800038ba:	1000                	addi	s0,sp,32
    800038bc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038be:	415c                	lw	a5,4(a0)
    800038c0:	0047d79b          	srliw	a5,a5,0x4
    800038c4:	0001c597          	auipc	a1,0x1c
    800038c8:	51c5a583          	lw	a1,1308(a1) # 8001fde0 <sb+0x18>
    800038cc:	9dbd                	addw	a1,a1,a5
    800038ce:	4108                	lw	a0,0(a0)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	8a8080e7          	jalr	-1880(ra) # 80003178 <bread>
    800038d8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038da:	05850793          	addi	a5,a0,88
    800038de:	40c8                	lw	a0,4(s1)
    800038e0:	893d                	andi	a0,a0,15
    800038e2:	051a                	slli	a0,a0,0x6
    800038e4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038e6:	04449703          	lh	a4,68(s1)
    800038ea:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038ee:	04649703          	lh	a4,70(s1)
    800038f2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038f6:	04849703          	lh	a4,72(s1)
    800038fa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038fe:	04a49703          	lh	a4,74(s1)
    80003902:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003906:	44f8                	lw	a4,76(s1)
    80003908:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000390a:	03400613          	li	a2,52
    8000390e:	05048593          	addi	a1,s1,80
    80003912:	0531                	addi	a0,a0,12
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	42c080e7          	jalr	1068(ra) # 80000d40 <memmove>
  log_write(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	c06080e7          	jalr	-1018(ra) # 80004524 <log_write>
  brelse(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	980080e7          	jalr	-1664(ra) # 800032a8 <brelse>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret

000000008000393c <idup>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	1000                	addi	s0,sp,32
    80003946:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003948:	0001c517          	auipc	a0,0x1c
    8000394c:	4a050513          	addi	a0,a0,1184 # 8001fde8 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	294080e7          	jalr	660(ra) # 80000be4 <acquire>
  ip->ref++;
    80003958:	449c                	lw	a5,8(s1)
    8000395a:	2785                	addiw	a5,a5,1
    8000395c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	48a50513          	addi	a0,a0,1162 # 8001fde8 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	332080e7          	jalr	818(ra) # 80000c98 <release>
}
    8000396e:	8526                	mv	a0,s1
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret

000000008000397a <ilock>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	e04a                	sd	s2,0(sp)
    80003984:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003986:	c115                	beqz	a0,800039aa <ilock+0x30>
    80003988:	84aa                	mv	s1,a0
    8000398a:	451c                	lw	a5,8(a0)
    8000398c:	00f05f63          	blez	a5,800039aa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003990:	0541                	addi	a0,a0,16
    80003992:	00001097          	auipc	ra,0x1
    80003996:	cb2080e7          	jalr	-846(ra) # 80004644 <acquiresleep>
  if(ip->valid == 0){
    8000399a:	40bc                	lw	a5,64(s1)
    8000399c:	cf99                	beqz	a5,800039ba <ilock+0x40>
}
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6902                	ld	s2,0(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret
    panic("ilock");
    800039aa:	00005517          	auipc	a0,0x5
    800039ae:	cfe50513          	addi	a0,a0,-770 # 800086a8 <syscalls+0x198>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b8c080e7          	jalr	-1140(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ba:	40dc                	lw	a5,4(s1)
    800039bc:	0047d79b          	srliw	a5,a5,0x4
    800039c0:	0001c597          	auipc	a1,0x1c
    800039c4:	4205a583          	lw	a1,1056(a1) # 8001fde0 <sb+0x18>
    800039c8:	9dbd                	addw	a1,a1,a5
    800039ca:	4088                	lw	a0,0(s1)
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	7ac080e7          	jalr	1964(ra) # 80003178 <bread>
    800039d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d6:	05850593          	addi	a1,a0,88
    800039da:	40dc                	lw	a5,4(s1)
    800039dc:	8bbd                	andi	a5,a5,15
    800039de:	079a                	slli	a5,a5,0x6
    800039e0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e2:	00059783          	lh	a5,0(a1)
    800039e6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039ea:	00259783          	lh	a5,2(a1)
    800039ee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039f2:	00459783          	lh	a5,4(a1)
    800039f6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039fa:	00659783          	lh	a5,6(a1)
    800039fe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a02:	459c                	lw	a5,8(a1)
    80003a04:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a06:	03400613          	li	a2,52
    80003a0a:	05b1                	addi	a1,a1,12
    80003a0c:	05048513          	addi	a0,s1,80
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	330080e7          	jalr	816(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	88e080e7          	jalr	-1906(ra) # 800032a8 <brelse>
    ip->valid = 1;
    80003a22:	4785                	li	a5,1
    80003a24:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a26:	04449783          	lh	a5,68(s1)
    80003a2a:	fbb5                	bnez	a5,8000399e <ilock+0x24>
      panic("ilock: no type");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	c8450513          	addi	a0,a0,-892 # 800086b0 <syscalls+0x1a0>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>

0000000080003a3c <iunlock>:
{
    80003a3c:	1101                	addi	sp,sp,-32
    80003a3e:	ec06                	sd	ra,24(sp)
    80003a40:	e822                	sd	s0,16(sp)
    80003a42:	e426                	sd	s1,8(sp)
    80003a44:	e04a                	sd	s2,0(sp)
    80003a46:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a48:	c905                	beqz	a0,80003a78 <iunlock+0x3c>
    80003a4a:	84aa                	mv	s1,a0
    80003a4c:	01050913          	addi	s2,a0,16
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	c8c080e7          	jalr	-884(ra) # 800046de <holdingsleep>
    80003a5a:	cd19                	beqz	a0,80003a78 <iunlock+0x3c>
    80003a5c:	449c                	lw	a5,8(s1)
    80003a5e:	00f05d63          	blez	a5,80003a78 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	c36080e7          	jalr	-970(ra) # 8000469a <releasesleep>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6902                	ld	s2,0(sp)
    80003a74:	6105                	addi	sp,sp,32
    80003a76:	8082                	ret
    panic("iunlock");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	c4850513          	addi	a0,a0,-952 # 800086c0 <syscalls+0x1b0>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	abe080e7          	jalr	-1346(ra) # 8000053e <panic>

0000000080003a88 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a88:	7179                	addi	sp,sp,-48
    80003a8a:	f406                	sd	ra,40(sp)
    80003a8c:	f022                	sd	s0,32(sp)
    80003a8e:	ec26                	sd	s1,24(sp)
    80003a90:	e84a                	sd	s2,16(sp)
    80003a92:	e44e                	sd	s3,8(sp)
    80003a94:	e052                	sd	s4,0(sp)
    80003a96:	1800                	addi	s0,sp,48
    80003a98:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a9a:	05050493          	addi	s1,a0,80
    80003a9e:	08050913          	addi	s2,a0,128
    80003aa2:	a021                	j	80003aaa <itrunc+0x22>
    80003aa4:	0491                	addi	s1,s1,4
    80003aa6:	01248d63          	beq	s1,s2,80003ac0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aaa:	408c                	lw	a1,0(s1)
    80003aac:	dde5                	beqz	a1,80003aa4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aae:	0009a503          	lw	a0,0(s3)
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	90c080e7          	jalr	-1780(ra) # 800033be <bfree>
      ip->addrs[i] = 0;
    80003aba:	0004a023          	sw	zero,0(s1)
    80003abe:	b7dd                	j	80003aa4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ac0:	0809a583          	lw	a1,128(s3)
    80003ac4:	e185                	bnez	a1,80003ae4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ac6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aca:	854e                	mv	a0,s3
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	de4080e7          	jalr	-540(ra) # 800038b0 <iupdate>
}
    80003ad4:	70a2                	ld	ra,40(sp)
    80003ad6:	7402                	ld	s0,32(sp)
    80003ad8:	64e2                	ld	s1,24(sp)
    80003ada:	6942                	ld	s2,16(sp)
    80003adc:	69a2                	ld	s3,8(sp)
    80003ade:	6a02                	ld	s4,0(sp)
    80003ae0:	6145                	addi	sp,sp,48
    80003ae2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae4:	0009a503          	lw	a0,0(s3)
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	690080e7          	jalr	1680(ra) # 80003178 <bread>
    80003af0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af2:	05850493          	addi	s1,a0,88
    80003af6:	45850913          	addi	s2,a0,1112
    80003afa:	a811                	j	80003b0e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003afc:	0009a503          	lw	a0,0(s3)
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	8be080e7          	jalr	-1858(ra) # 800033be <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b08:	0491                	addi	s1,s1,4
    80003b0a:	01248563          	beq	s1,s2,80003b14 <itrunc+0x8c>
      if(a[j])
    80003b0e:	408c                	lw	a1,0(s1)
    80003b10:	dde5                	beqz	a1,80003b08 <itrunc+0x80>
    80003b12:	b7ed                	j	80003afc <itrunc+0x74>
    brelse(bp);
    80003b14:	8552                	mv	a0,s4
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	792080e7          	jalr	1938(ra) # 800032a8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b1e:	0809a583          	lw	a1,128(s3)
    80003b22:	0009a503          	lw	a0,0(s3)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	898080e7          	jalr	-1896(ra) # 800033be <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b2e:	0809a023          	sw	zero,128(s3)
    80003b32:	bf51                	j	80003ac6 <itrunc+0x3e>

0000000080003b34 <iput>:
{
    80003b34:	1101                	addi	sp,sp,-32
    80003b36:	ec06                	sd	ra,24(sp)
    80003b38:	e822                	sd	s0,16(sp)
    80003b3a:	e426                	sd	s1,8(sp)
    80003b3c:	e04a                	sd	s2,0(sp)
    80003b3e:	1000                	addi	s0,sp,32
    80003b40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	2a650513          	addi	a0,a0,678 # 8001fde8 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b52:	4498                	lw	a4,8(s1)
    80003b54:	4785                	li	a5,1
    80003b56:	02f70363          	beq	a4,a5,80003b7c <iput+0x48>
  ip->ref--;
    80003b5a:	449c                	lw	a5,8(s1)
    80003b5c:	37fd                	addiw	a5,a5,-1
    80003b5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b60:	0001c517          	auipc	a0,0x1c
    80003b64:	28850513          	addi	a0,a0,648 # 8001fde8 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
}
    80003b70:	60e2                	ld	ra,24(sp)
    80003b72:	6442                	ld	s0,16(sp)
    80003b74:	64a2                	ld	s1,8(sp)
    80003b76:	6902                	ld	s2,0(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b7c:	40bc                	lw	a5,64(s1)
    80003b7e:	dff1                	beqz	a5,80003b5a <iput+0x26>
    80003b80:	04a49783          	lh	a5,74(s1)
    80003b84:	fbf9                	bnez	a5,80003b5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b86:	01048913          	addi	s2,s1,16
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00001097          	auipc	ra,0x1
    80003b90:	ab8080e7          	jalr	-1352(ra) # 80004644 <acquiresleep>
    release(&itable.lock);
    80003b94:	0001c517          	auipc	a0,0x1c
    80003b98:	25450513          	addi	a0,a0,596 # 8001fde8 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	0fc080e7          	jalr	252(ra) # 80000c98 <release>
    itrunc(ip);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	ee2080e7          	jalr	-286(ra) # 80003a88 <itrunc>
    ip->type = 0;
    80003bae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	cfc080e7          	jalr	-772(ra) # 800038b0 <iupdate>
    ip->valid = 0;
    80003bbc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	ad8080e7          	jalr	-1320(ra) # 8000469a <releasesleep>
    acquire(&itable.lock);
    80003bca:	0001c517          	auipc	a0,0x1c
    80003bce:	21e50513          	addi	a0,a0,542 # 8001fde8 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	012080e7          	jalr	18(ra) # 80000be4 <acquire>
    80003bda:	b741                	j	80003b5a <iput+0x26>

0000000080003bdc <iunlockput>:
{
    80003bdc:	1101                	addi	sp,sp,-32
    80003bde:	ec06                	sd	ra,24(sp)
    80003be0:	e822                	sd	s0,16(sp)
    80003be2:	e426                	sd	s1,8(sp)
    80003be4:	1000                	addi	s0,sp,32
    80003be6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	e54080e7          	jalr	-428(ra) # 80003a3c <iunlock>
  iput(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	f42080e7          	jalr	-190(ra) # 80003b34 <iput>
}
    80003bfa:	60e2                	ld	ra,24(sp)
    80003bfc:	6442                	ld	s0,16(sp)
    80003bfe:	64a2                	ld	s1,8(sp)
    80003c00:	6105                	addi	sp,sp,32
    80003c02:	8082                	ret

0000000080003c04 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c04:	1141                	addi	sp,sp,-16
    80003c06:	e422                	sd	s0,8(sp)
    80003c08:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c0a:	411c                	lw	a5,0(a0)
    80003c0c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c0e:	415c                	lw	a5,4(a0)
    80003c10:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c12:	04451783          	lh	a5,68(a0)
    80003c16:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c1a:	04a51783          	lh	a5,74(a0)
    80003c1e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c22:	04c56783          	lwu	a5,76(a0)
    80003c26:	e99c                	sd	a5,16(a1)
}
    80003c28:	6422                	ld	s0,8(sp)
    80003c2a:	0141                	addi	sp,sp,16
    80003c2c:	8082                	ret

0000000080003c2e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c2e:	457c                	lw	a5,76(a0)
    80003c30:	0ed7e963          	bltu	a5,a3,80003d22 <readi+0xf4>
{
    80003c34:	7159                	addi	sp,sp,-112
    80003c36:	f486                	sd	ra,104(sp)
    80003c38:	f0a2                	sd	s0,96(sp)
    80003c3a:	eca6                	sd	s1,88(sp)
    80003c3c:	e8ca                	sd	s2,80(sp)
    80003c3e:	e4ce                	sd	s3,72(sp)
    80003c40:	e0d2                	sd	s4,64(sp)
    80003c42:	fc56                	sd	s5,56(sp)
    80003c44:	f85a                	sd	s6,48(sp)
    80003c46:	f45e                	sd	s7,40(sp)
    80003c48:	f062                	sd	s8,32(sp)
    80003c4a:	ec66                	sd	s9,24(sp)
    80003c4c:	e86a                	sd	s10,16(sp)
    80003c4e:	e46e                	sd	s11,8(sp)
    80003c50:	1880                	addi	s0,sp,112
    80003c52:	8baa                	mv	s7,a0
    80003c54:	8c2e                	mv	s8,a1
    80003c56:	8ab2                	mv	s5,a2
    80003c58:	84b6                	mv	s1,a3
    80003c5a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c5c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c5e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c60:	0ad76063          	bltu	a4,a3,80003d00 <readi+0xd2>
  if(off + n > ip->size)
    80003c64:	00e7f463          	bgeu	a5,a4,80003c6c <readi+0x3e>
    n = ip->size - off;
    80003c68:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c6c:	0a0b0963          	beqz	s6,80003d1e <readi+0xf0>
    80003c70:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c72:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c76:	5cfd                	li	s9,-1
    80003c78:	a82d                	j	80003cb2 <readi+0x84>
    80003c7a:	020a1d93          	slli	s11,s4,0x20
    80003c7e:	020ddd93          	srli	s11,s11,0x20
    80003c82:	05890613          	addi	a2,s2,88
    80003c86:	86ee                	mv	a3,s11
    80003c88:	963a                	add	a2,a2,a4
    80003c8a:	85d6                	mv	a1,s5
    80003c8c:	8562                	mv	a0,s8
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	b14080e7          	jalr	-1260(ra) # 800027a2 <either_copyout>
    80003c96:	05950d63          	beq	a0,s9,80003cf0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	60c080e7          	jalr	1548(ra) # 800032a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca4:	013a09bb          	addw	s3,s4,s3
    80003ca8:	009a04bb          	addw	s1,s4,s1
    80003cac:	9aee                	add	s5,s5,s11
    80003cae:	0569f763          	bgeu	s3,s6,80003cfc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb2:	000ba903          	lw	s2,0(s7)
    80003cb6:	00a4d59b          	srliw	a1,s1,0xa
    80003cba:	855e                	mv	a0,s7
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	8b0080e7          	jalr	-1872(ra) # 8000356c <bmap>
    80003cc4:	0005059b          	sext.w	a1,a0
    80003cc8:	854a                	mv	a0,s2
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	4ae080e7          	jalr	1198(ra) # 80003178 <bread>
    80003cd2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd4:	3ff4f713          	andi	a4,s1,1023
    80003cd8:	40ed07bb          	subw	a5,s10,a4
    80003cdc:	413b06bb          	subw	a3,s6,s3
    80003ce0:	8a3e                	mv	s4,a5
    80003ce2:	2781                	sext.w	a5,a5
    80003ce4:	0006861b          	sext.w	a2,a3
    80003ce8:	f8f679e3          	bgeu	a2,a5,80003c7a <readi+0x4c>
    80003cec:	8a36                	mv	s4,a3
    80003cee:	b771                	j	80003c7a <readi+0x4c>
      brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	5b6080e7          	jalr	1462(ra) # 800032a8 <brelse>
      tot = -1;
    80003cfa:	59fd                	li	s3,-1
  }
  return tot;
    80003cfc:	0009851b          	sext.w	a0,s3
}
    80003d00:	70a6                	ld	ra,104(sp)
    80003d02:	7406                	ld	s0,96(sp)
    80003d04:	64e6                	ld	s1,88(sp)
    80003d06:	6946                	ld	s2,80(sp)
    80003d08:	69a6                	ld	s3,72(sp)
    80003d0a:	6a06                	ld	s4,64(sp)
    80003d0c:	7ae2                	ld	s5,56(sp)
    80003d0e:	7b42                	ld	s6,48(sp)
    80003d10:	7ba2                	ld	s7,40(sp)
    80003d12:	7c02                	ld	s8,32(sp)
    80003d14:	6ce2                	ld	s9,24(sp)
    80003d16:	6d42                	ld	s10,16(sp)
    80003d18:	6da2                	ld	s11,8(sp)
    80003d1a:	6165                	addi	sp,sp,112
    80003d1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d1e:	89da                	mv	s3,s6
    80003d20:	bff1                	j	80003cfc <readi+0xce>
    return 0;
    80003d22:	4501                	li	a0,0
}
    80003d24:	8082                	ret

0000000080003d26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d26:	457c                	lw	a5,76(a0)
    80003d28:	10d7e863          	bltu	a5,a3,80003e38 <writei+0x112>
{
    80003d2c:	7159                	addi	sp,sp,-112
    80003d2e:	f486                	sd	ra,104(sp)
    80003d30:	f0a2                	sd	s0,96(sp)
    80003d32:	eca6                	sd	s1,88(sp)
    80003d34:	e8ca                	sd	s2,80(sp)
    80003d36:	e4ce                	sd	s3,72(sp)
    80003d38:	e0d2                	sd	s4,64(sp)
    80003d3a:	fc56                	sd	s5,56(sp)
    80003d3c:	f85a                	sd	s6,48(sp)
    80003d3e:	f45e                	sd	s7,40(sp)
    80003d40:	f062                	sd	s8,32(sp)
    80003d42:	ec66                	sd	s9,24(sp)
    80003d44:	e86a                	sd	s10,16(sp)
    80003d46:	e46e                	sd	s11,8(sp)
    80003d48:	1880                	addi	s0,sp,112
    80003d4a:	8b2a                	mv	s6,a0
    80003d4c:	8c2e                	mv	s8,a1
    80003d4e:	8ab2                	mv	s5,a2
    80003d50:	8936                	mv	s2,a3
    80003d52:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d54:	00e687bb          	addw	a5,a3,a4
    80003d58:	0ed7e263          	bltu	a5,a3,80003e3c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d5c:	00043737          	lui	a4,0x43
    80003d60:	0ef76063          	bltu	a4,a5,80003e40 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d64:	0c0b8863          	beqz	s7,80003e34 <writei+0x10e>
    80003d68:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d6e:	5cfd                	li	s9,-1
    80003d70:	a091                	j	80003db4 <writei+0x8e>
    80003d72:	02099d93          	slli	s11,s3,0x20
    80003d76:	020ddd93          	srli	s11,s11,0x20
    80003d7a:	05848513          	addi	a0,s1,88
    80003d7e:	86ee                	mv	a3,s11
    80003d80:	8656                	mv	a2,s5
    80003d82:	85e2                	mv	a1,s8
    80003d84:	953a                	add	a0,a0,a4
    80003d86:	fffff097          	auipc	ra,0xfffff
    80003d8a:	a72080e7          	jalr	-1422(ra) # 800027f8 <either_copyin>
    80003d8e:	07950263          	beq	a0,s9,80003df2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d92:	8526                	mv	a0,s1
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	790080e7          	jalr	1936(ra) # 80004524 <log_write>
    brelse(bp);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	50a080e7          	jalr	1290(ra) # 800032a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da6:	01498a3b          	addw	s4,s3,s4
    80003daa:	0129893b          	addw	s2,s3,s2
    80003dae:	9aee                	add	s5,s5,s11
    80003db0:	057a7663          	bgeu	s4,s7,80003dfc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003db4:	000b2483          	lw	s1,0(s6)
    80003db8:	00a9559b          	srliw	a1,s2,0xa
    80003dbc:	855a                	mv	a0,s6
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	7ae080e7          	jalr	1966(ra) # 8000356c <bmap>
    80003dc6:	0005059b          	sext.w	a1,a0
    80003dca:	8526                	mv	a0,s1
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	3ac080e7          	jalr	940(ra) # 80003178 <bread>
    80003dd4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd6:	3ff97713          	andi	a4,s2,1023
    80003dda:	40ed07bb          	subw	a5,s10,a4
    80003dde:	414b86bb          	subw	a3,s7,s4
    80003de2:	89be                	mv	s3,a5
    80003de4:	2781                	sext.w	a5,a5
    80003de6:	0006861b          	sext.w	a2,a3
    80003dea:	f8f674e3          	bgeu	a2,a5,80003d72 <writei+0x4c>
    80003dee:	89b6                	mv	s3,a3
    80003df0:	b749                	j	80003d72 <writei+0x4c>
      brelse(bp);
    80003df2:	8526                	mv	a0,s1
    80003df4:	fffff097          	auipc	ra,0xfffff
    80003df8:	4b4080e7          	jalr	1204(ra) # 800032a8 <brelse>
  }

  if(off > ip->size)
    80003dfc:	04cb2783          	lw	a5,76(s6)
    80003e00:	0127f463          	bgeu	a5,s2,80003e08 <writei+0xe2>
    ip->size = off;
    80003e04:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e08:	855a                	mv	a0,s6
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	aa6080e7          	jalr	-1370(ra) # 800038b0 <iupdate>

  return tot;
    80003e12:	000a051b          	sext.w	a0,s4
}
    80003e16:	70a6                	ld	ra,104(sp)
    80003e18:	7406                	ld	s0,96(sp)
    80003e1a:	64e6                	ld	s1,88(sp)
    80003e1c:	6946                	ld	s2,80(sp)
    80003e1e:	69a6                	ld	s3,72(sp)
    80003e20:	6a06                	ld	s4,64(sp)
    80003e22:	7ae2                	ld	s5,56(sp)
    80003e24:	7b42                	ld	s6,48(sp)
    80003e26:	7ba2                	ld	s7,40(sp)
    80003e28:	7c02                	ld	s8,32(sp)
    80003e2a:	6ce2                	ld	s9,24(sp)
    80003e2c:	6d42                	ld	s10,16(sp)
    80003e2e:	6da2                	ld	s11,8(sp)
    80003e30:	6165                	addi	sp,sp,112
    80003e32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e34:	8a5e                	mv	s4,s7
    80003e36:	bfc9                	j	80003e08 <writei+0xe2>
    return -1;
    80003e38:	557d                	li	a0,-1
}
    80003e3a:	8082                	ret
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	bfe1                	j	80003e16 <writei+0xf0>
    return -1;
    80003e40:	557d                	li	a0,-1
    80003e42:	bfd1                	j	80003e16 <writei+0xf0>

0000000080003e44 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e44:	1141                	addi	sp,sp,-16
    80003e46:	e406                	sd	ra,8(sp)
    80003e48:	e022                	sd	s0,0(sp)
    80003e4a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e4c:	4639                	li	a2,14
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	f6a080e7          	jalr	-150(ra) # 80000db8 <strncmp>
}
    80003e56:	60a2                	ld	ra,8(sp)
    80003e58:	6402                	ld	s0,0(sp)
    80003e5a:	0141                	addi	sp,sp,16
    80003e5c:	8082                	ret

0000000080003e5e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5e:	7139                	addi	sp,sp,-64
    80003e60:	fc06                	sd	ra,56(sp)
    80003e62:	f822                	sd	s0,48(sp)
    80003e64:	f426                	sd	s1,40(sp)
    80003e66:	f04a                	sd	s2,32(sp)
    80003e68:	ec4e                	sd	s3,24(sp)
    80003e6a:	e852                	sd	s4,16(sp)
    80003e6c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6e:	04451703          	lh	a4,68(a0)
    80003e72:	4785                	li	a5,1
    80003e74:	00f71a63          	bne	a4,a5,80003e88 <dirlookup+0x2a>
    80003e78:	892a                	mv	s2,a0
    80003e7a:	89ae                	mv	s3,a1
    80003e7c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7e:	457c                	lw	a5,76(a0)
    80003e80:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e82:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	e79d                	bnez	a5,80003eb2 <dirlookup+0x54>
    80003e86:	a8a5                	j	80003efe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e88:	00005517          	auipc	a0,0x5
    80003e8c:	84050513          	addi	a0,a0,-1984 # 800086c8 <syscalls+0x1b8>
    80003e90:	ffffc097          	auipc	ra,0xffffc
    80003e94:	6ae080e7          	jalr	1710(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e98:	00005517          	auipc	a0,0x5
    80003e9c:	84850513          	addi	a0,a0,-1976 # 800086e0 <syscalls+0x1d0>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	69e080e7          	jalr	1694(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea8:	24c1                	addiw	s1,s1,16
    80003eaa:	04c92783          	lw	a5,76(s2)
    80003eae:	04f4f763          	bgeu	s1,a5,80003efc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb2:	4741                	li	a4,16
    80003eb4:	86a6                	mv	a3,s1
    80003eb6:	fc040613          	addi	a2,s0,-64
    80003eba:	4581                	li	a1,0
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	d70080e7          	jalr	-656(ra) # 80003c2e <readi>
    80003ec6:	47c1                	li	a5,16
    80003ec8:	fcf518e3          	bne	a0,a5,80003e98 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ecc:	fc045783          	lhu	a5,-64(s0)
    80003ed0:	dfe1                	beqz	a5,80003ea8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed2:	fc240593          	addi	a1,s0,-62
    80003ed6:	854e                	mv	a0,s3
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	f6c080e7          	jalr	-148(ra) # 80003e44 <namecmp>
    80003ee0:	f561                	bnez	a0,80003ea8 <dirlookup+0x4a>
      if(poff)
    80003ee2:	000a0463          	beqz	s4,80003eea <dirlookup+0x8c>
        *poff = off;
    80003ee6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eea:	fc045583          	lhu	a1,-64(s0)
    80003eee:	00092503          	lw	a0,0(s2)
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	754080e7          	jalr	1876(ra) # 80003646 <iget>
    80003efa:	a011                	j	80003efe <dirlookup+0xa0>
  return 0;
    80003efc:	4501                	li	a0,0
}
    80003efe:	70e2                	ld	ra,56(sp)
    80003f00:	7442                	ld	s0,48(sp)
    80003f02:	74a2                	ld	s1,40(sp)
    80003f04:	7902                	ld	s2,32(sp)
    80003f06:	69e2                	ld	s3,24(sp)
    80003f08:	6a42                	ld	s4,16(sp)
    80003f0a:	6121                	addi	sp,sp,64
    80003f0c:	8082                	ret

0000000080003f0e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0e:	711d                	addi	sp,sp,-96
    80003f10:	ec86                	sd	ra,88(sp)
    80003f12:	e8a2                	sd	s0,80(sp)
    80003f14:	e4a6                	sd	s1,72(sp)
    80003f16:	e0ca                	sd	s2,64(sp)
    80003f18:	fc4e                	sd	s3,56(sp)
    80003f1a:	f852                	sd	s4,48(sp)
    80003f1c:	f456                	sd	s5,40(sp)
    80003f1e:	f05a                	sd	s6,32(sp)
    80003f20:	ec5e                	sd	s7,24(sp)
    80003f22:	e862                	sd	s8,16(sp)
    80003f24:	e466                	sd	s9,8(sp)
    80003f26:	1080                	addi	s0,sp,96
    80003f28:	84aa                	mv	s1,a0
    80003f2a:	8b2e                	mv	s6,a1
    80003f2c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2e:	00054703          	lbu	a4,0(a0)
    80003f32:	02f00793          	li	a5,47
    80003f36:	02f70363          	beq	a4,a5,80003f5c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f3a:	ffffe097          	auipc	ra,0xffffe
    80003f3e:	db6080e7          	jalr	-586(ra) # 80001cf0 <myproc>
    80003f42:	16853503          	ld	a0,360(a0)
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	9f6080e7          	jalr	-1546(ra) # 8000393c <idup>
    80003f4e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f50:	02f00913          	li	s2,47
  len = path - s;
    80003f54:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f56:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f58:	4c05                	li	s8,1
    80003f5a:	a865                	j	80004012 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f5c:	4585                	li	a1,1
    80003f5e:	4505                	li	a0,1
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	6e6080e7          	jalr	1766(ra) # 80003646 <iget>
    80003f68:	89aa                	mv	s3,a0
    80003f6a:	b7dd                	j	80003f50 <namex+0x42>
      iunlockput(ip);
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	c6e080e7          	jalr	-914(ra) # 80003bdc <iunlockput>
      return 0;
    80003f76:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f78:	854e                	mv	a0,s3
    80003f7a:	60e6                	ld	ra,88(sp)
    80003f7c:	6446                	ld	s0,80(sp)
    80003f7e:	64a6                	ld	s1,72(sp)
    80003f80:	6906                	ld	s2,64(sp)
    80003f82:	79e2                	ld	s3,56(sp)
    80003f84:	7a42                	ld	s4,48(sp)
    80003f86:	7aa2                	ld	s5,40(sp)
    80003f88:	7b02                	ld	s6,32(sp)
    80003f8a:	6be2                	ld	s7,24(sp)
    80003f8c:	6c42                	ld	s8,16(sp)
    80003f8e:	6ca2                	ld	s9,8(sp)
    80003f90:	6125                	addi	sp,sp,96
    80003f92:	8082                	ret
      iunlock(ip);
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	aa6080e7          	jalr	-1370(ra) # 80003a3c <iunlock>
      return ip;
    80003f9e:	bfe9                	j	80003f78 <namex+0x6a>
      iunlockput(ip);
    80003fa0:	854e                	mv	a0,s3
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	c3a080e7          	jalr	-966(ra) # 80003bdc <iunlockput>
      return 0;
    80003faa:	89d2                	mv	s3,s4
    80003fac:	b7f1                	j	80003f78 <namex+0x6a>
  len = path - s;
    80003fae:	40b48633          	sub	a2,s1,a1
    80003fb2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fb6:	094cd463          	bge	s9,s4,8000403e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fba:	4639                	li	a2,14
    80003fbc:	8556                	mv	a0,s5
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	d82080e7          	jalr	-638(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fc6:	0004c783          	lbu	a5,0(s1)
    80003fca:	01279763          	bne	a5,s2,80003fd8 <namex+0xca>
    path++;
    80003fce:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	ff278de3          	beq	a5,s2,80003fce <namex+0xc0>
    ilock(ip);
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	9a0080e7          	jalr	-1632(ra) # 8000397a <ilock>
    if(ip->type != T_DIR){
    80003fe2:	04499783          	lh	a5,68(s3)
    80003fe6:	f98793e3          	bne	a5,s8,80003f6c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fea:	000b0563          	beqz	s6,80003ff4 <namex+0xe6>
    80003fee:	0004c783          	lbu	a5,0(s1)
    80003ff2:	d3cd                	beqz	a5,80003f94 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff4:	865e                	mv	a2,s7
    80003ff6:	85d6                	mv	a1,s5
    80003ff8:	854e                	mv	a0,s3
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	e64080e7          	jalr	-412(ra) # 80003e5e <dirlookup>
    80004002:	8a2a                	mv	s4,a0
    80004004:	dd51                	beqz	a0,80003fa0 <namex+0x92>
    iunlockput(ip);
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	bd4080e7          	jalr	-1068(ra) # 80003bdc <iunlockput>
    ip = next;
    80004010:	89d2                	mv	s3,s4
  while(*path == '/')
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	05279763          	bne	a5,s2,80004064 <namex+0x156>
    path++;
    8000401a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	ff278de3          	beq	a5,s2,8000401a <namex+0x10c>
  if(*path == 0)
    80004024:	c79d                	beqz	a5,80004052 <namex+0x144>
    path++;
    80004026:	85a6                	mv	a1,s1
  len = path - s;
    80004028:	8a5e                	mv	s4,s7
    8000402a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000402c:	01278963          	beq	a5,s2,8000403e <namex+0x130>
    80004030:	dfbd                	beqz	a5,80003fae <namex+0xa0>
    path++;
    80004032:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004034:	0004c783          	lbu	a5,0(s1)
    80004038:	ff279ce3          	bne	a5,s2,80004030 <namex+0x122>
    8000403c:	bf8d                	j	80003fae <namex+0xa0>
    memmove(name, s, len);
    8000403e:	2601                	sext.w	a2,a2
    80004040:	8556                	mv	a0,s5
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	cfe080e7          	jalr	-770(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000404a:	9a56                	add	s4,s4,s5
    8000404c:	000a0023          	sb	zero,0(s4)
    80004050:	bf9d                	j	80003fc6 <namex+0xb8>
  if(nameiparent){
    80004052:	f20b03e3          	beqz	s6,80003f78 <namex+0x6a>
    iput(ip);
    80004056:	854e                	mv	a0,s3
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	adc080e7          	jalr	-1316(ra) # 80003b34 <iput>
    return 0;
    80004060:	4981                	li	s3,0
    80004062:	bf19                	j	80003f78 <namex+0x6a>
  if(*path == 0)
    80004064:	d7fd                	beqz	a5,80004052 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	85a6                	mv	a1,s1
    8000406c:	b7d1                	j	80004030 <namex+0x122>

000000008000406e <dirlink>:
{
    8000406e:	7139                	addi	sp,sp,-64
    80004070:	fc06                	sd	ra,56(sp)
    80004072:	f822                	sd	s0,48(sp)
    80004074:	f426                	sd	s1,40(sp)
    80004076:	f04a                	sd	s2,32(sp)
    80004078:	ec4e                	sd	s3,24(sp)
    8000407a:	e852                	sd	s4,16(sp)
    8000407c:	0080                	addi	s0,sp,64
    8000407e:	892a                	mv	s2,a0
    80004080:	8a2e                	mv	s4,a1
    80004082:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004084:	4601                	li	a2,0
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	dd8080e7          	jalr	-552(ra) # 80003e5e <dirlookup>
    8000408e:	e93d                	bnez	a0,80004104 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004090:	04c92483          	lw	s1,76(s2)
    80004094:	c49d                	beqz	s1,800040c2 <dirlink+0x54>
    80004096:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004098:	4741                	li	a4,16
    8000409a:	86a6                	mv	a3,s1
    8000409c:	fc040613          	addi	a2,s0,-64
    800040a0:	4581                	li	a1,0
    800040a2:	854a                	mv	a0,s2
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	b8a080e7          	jalr	-1142(ra) # 80003c2e <readi>
    800040ac:	47c1                	li	a5,16
    800040ae:	06f51163          	bne	a0,a5,80004110 <dirlink+0xa2>
    if(de.inum == 0)
    800040b2:	fc045783          	lhu	a5,-64(s0)
    800040b6:	c791                	beqz	a5,800040c2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b8:	24c1                	addiw	s1,s1,16
    800040ba:	04c92783          	lw	a5,76(s2)
    800040be:	fcf4ede3          	bltu	s1,a5,80004098 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c2:	4639                	li	a2,14
    800040c4:	85d2                	mv	a1,s4
    800040c6:	fc240513          	addi	a0,s0,-62
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	d2a080e7          	jalr	-726(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040d2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d6:	4741                	li	a4,16
    800040d8:	86a6                	mv	a3,s1
    800040da:	fc040613          	addi	a2,s0,-64
    800040de:	4581                	li	a1,0
    800040e0:	854a                	mv	a0,s2
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	c44080e7          	jalr	-956(ra) # 80003d26 <writei>
    800040ea:	872a                	mv	a4,a0
    800040ec:	47c1                	li	a5,16
  return 0;
    800040ee:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f0:	02f71863          	bne	a4,a5,80004120 <dirlink+0xb2>
}
    800040f4:	70e2                	ld	ra,56(sp)
    800040f6:	7442                	ld	s0,48(sp)
    800040f8:	74a2                	ld	s1,40(sp)
    800040fa:	7902                	ld	s2,32(sp)
    800040fc:	69e2                	ld	s3,24(sp)
    800040fe:	6a42                	ld	s4,16(sp)
    80004100:	6121                	addi	sp,sp,64
    80004102:	8082                	ret
    iput(ip);
    80004104:	00000097          	auipc	ra,0x0
    80004108:	a30080e7          	jalr	-1488(ra) # 80003b34 <iput>
    return -1;
    8000410c:	557d                	li	a0,-1
    8000410e:	b7dd                	j	800040f4 <dirlink+0x86>
      panic("dirlink read");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	5e050513          	addi	a0,a0,1504 # 800086f0 <syscalls+0x1e0>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
    panic("dirlink");
    80004120:	00004517          	auipc	a0,0x4
    80004124:	6e050513          	addi	a0,a0,1760 # 80008800 <syscalls+0x2f0>
    80004128:	ffffc097          	auipc	ra,0xffffc
    8000412c:	416080e7          	jalr	1046(ra) # 8000053e <panic>

0000000080004130 <namei>:

struct inode*
namei(char *path)
{
    80004130:	1101                	addi	sp,sp,-32
    80004132:	ec06                	sd	ra,24(sp)
    80004134:	e822                	sd	s0,16(sp)
    80004136:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004138:	fe040613          	addi	a2,s0,-32
    8000413c:	4581                	li	a1,0
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	dd0080e7          	jalr	-560(ra) # 80003f0e <namex>
}
    80004146:	60e2                	ld	ra,24(sp)
    80004148:	6442                	ld	s0,16(sp)
    8000414a:	6105                	addi	sp,sp,32
    8000414c:	8082                	ret

000000008000414e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000414e:	1141                	addi	sp,sp,-16
    80004150:	e406                	sd	ra,8(sp)
    80004152:	e022                	sd	s0,0(sp)
    80004154:	0800                	addi	s0,sp,16
    80004156:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004158:	4585                	li	a1,1
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	db4080e7          	jalr	-588(ra) # 80003f0e <namex>
}
    80004162:	60a2                	ld	ra,8(sp)
    80004164:	6402                	ld	s0,0(sp)
    80004166:	0141                	addi	sp,sp,16
    80004168:	8082                	ret

000000008000416a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004176:	0001d917          	auipc	s2,0x1d
    8000417a:	71a90913          	addi	s2,s2,1818 # 80021890 <log>
    8000417e:	01892583          	lw	a1,24(s2)
    80004182:	02892503          	lw	a0,40(s2)
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	ff2080e7          	jalr	-14(ra) # 80003178 <bread>
    8000418e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004190:	02c92683          	lw	a3,44(s2)
    80004194:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004196:	02d05763          	blez	a3,800041c4 <write_head+0x5a>
    8000419a:	0001d797          	auipc	a5,0x1d
    8000419e:	72678793          	addi	a5,a5,1830 # 800218c0 <log+0x30>
    800041a2:	05c50713          	addi	a4,a0,92
    800041a6:	36fd                	addiw	a3,a3,-1
    800041a8:	1682                	slli	a3,a3,0x20
    800041aa:	9281                	srli	a3,a3,0x20
    800041ac:	068a                	slli	a3,a3,0x2
    800041ae:	0001d617          	auipc	a2,0x1d
    800041b2:	71660613          	addi	a2,a2,1814 # 800218c4 <log+0x34>
    800041b6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b8:	4390                	lw	a2,0(a5)
    800041ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041bc:	0791                	addi	a5,a5,4
    800041be:	0711                	addi	a4,a4,4
    800041c0:	fed79ce3          	bne	a5,a3,800041b8 <write_head+0x4e>
  }
  bwrite(buf);
    800041c4:	8526                	mv	a0,s1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	0a4080e7          	jalr	164(ra) # 8000326a <bwrite>
  brelse(buf);
    800041ce:	8526                	mv	a0,s1
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	0d8080e7          	jalr	216(ra) # 800032a8 <brelse>
}
    800041d8:	60e2                	ld	ra,24(sp)
    800041da:	6442                	ld	s0,16(sp)
    800041dc:	64a2                	ld	s1,8(sp)
    800041de:	6902                	ld	s2,0(sp)
    800041e0:	6105                	addi	sp,sp,32
    800041e2:	8082                	ret

00000000800041e4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e4:	0001d797          	auipc	a5,0x1d
    800041e8:	6d87a783          	lw	a5,1752(a5) # 800218bc <log+0x2c>
    800041ec:	0af05d63          	blez	a5,800042a6 <install_trans+0xc2>
{
    800041f0:	7139                	addi	sp,sp,-64
    800041f2:	fc06                	sd	ra,56(sp)
    800041f4:	f822                	sd	s0,48(sp)
    800041f6:	f426                	sd	s1,40(sp)
    800041f8:	f04a                	sd	s2,32(sp)
    800041fa:	ec4e                	sd	s3,24(sp)
    800041fc:	e852                	sd	s4,16(sp)
    800041fe:	e456                	sd	s5,8(sp)
    80004200:	e05a                	sd	s6,0(sp)
    80004202:	0080                	addi	s0,sp,64
    80004204:	8b2a                	mv	s6,a0
    80004206:	0001da97          	auipc	s5,0x1d
    8000420a:	6baa8a93          	addi	s5,s5,1722 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004210:	0001d997          	auipc	s3,0x1d
    80004214:	68098993          	addi	s3,s3,1664 # 80021890 <log>
    80004218:	a035                	j	80004244 <install_trans+0x60>
      bunpin(dbuf);
    8000421a:	8526                	mv	a0,s1
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	166080e7          	jalr	358(ra) # 80003382 <bunpin>
    brelse(lbuf);
    80004224:	854a                	mv	a0,s2
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	082080e7          	jalr	130(ra) # 800032a8 <brelse>
    brelse(dbuf);
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	078080e7          	jalr	120(ra) # 800032a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004238:	2a05                	addiw	s4,s4,1
    8000423a:	0a91                	addi	s5,s5,4
    8000423c:	02c9a783          	lw	a5,44(s3)
    80004240:	04fa5963          	bge	s4,a5,80004292 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004244:	0189a583          	lw	a1,24(s3)
    80004248:	014585bb          	addw	a1,a1,s4
    8000424c:	2585                	addiw	a1,a1,1
    8000424e:	0289a503          	lw	a0,40(s3)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	f26080e7          	jalr	-218(ra) # 80003178 <bread>
    8000425a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000425c:	000aa583          	lw	a1,0(s5)
    80004260:	0289a503          	lw	a0,40(s3)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	f14080e7          	jalr	-236(ra) # 80003178 <bread>
    8000426c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000426e:	40000613          	li	a2,1024
    80004272:	05890593          	addi	a1,s2,88
    80004276:	05850513          	addi	a0,a0,88
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	ac6080e7          	jalr	-1338(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	fe6080e7          	jalr	-26(ra) # 8000326a <bwrite>
    if(recovering == 0)
    8000428c:	f80b1ce3          	bnez	s6,80004224 <install_trans+0x40>
    80004290:	b769                	j	8000421a <install_trans+0x36>
}
    80004292:	70e2                	ld	ra,56(sp)
    80004294:	7442                	ld	s0,48(sp)
    80004296:	74a2                	ld	s1,40(sp)
    80004298:	7902                	ld	s2,32(sp)
    8000429a:	69e2                	ld	s3,24(sp)
    8000429c:	6a42                	ld	s4,16(sp)
    8000429e:	6aa2                	ld	s5,8(sp)
    800042a0:	6b02                	ld	s6,0(sp)
    800042a2:	6121                	addi	sp,sp,64
    800042a4:	8082                	ret
    800042a6:	8082                	ret

00000000800042a8 <initlog>:
{
    800042a8:	7179                	addi	sp,sp,-48
    800042aa:	f406                	sd	ra,40(sp)
    800042ac:	f022                	sd	s0,32(sp)
    800042ae:	ec26                	sd	s1,24(sp)
    800042b0:	e84a                	sd	s2,16(sp)
    800042b2:	e44e                	sd	s3,8(sp)
    800042b4:	1800                	addi	s0,sp,48
    800042b6:	892a                	mv	s2,a0
    800042b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ba:	0001d497          	auipc	s1,0x1d
    800042be:	5d648493          	addi	s1,s1,1494 # 80021890 <log>
    800042c2:	00004597          	auipc	a1,0x4
    800042c6:	43e58593          	addi	a1,a1,1086 # 80008700 <syscalls+0x1f0>
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	888080e7          	jalr	-1912(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042d4:	0149a583          	lw	a1,20(s3)
    800042d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042da:	0109a783          	lw	a5,16(s3)
    800042de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042e4:	854a                	mv	a0,s2
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	e92080e7          	jalr	-366(ra) # 80003178 <bread>
  log.lh.n = lh->n;
    800042ee:	4d3c                	lw	a5,88(a0)
    800042f0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042f2:	02f05563          	blez	a5,8000431c <initlog+0x74>
    800042f6:	05c50713          	addi	a4,a0,92
    800042fa:	0001d697          	auipc	a3,0x1d
    800042fe:	5c668693          	addi	a3,a3,1478 # 800218c0 <log+0x30>
    80004302:	37fd                	addiw	a5,a5,-1
    80004304:	1782                	slli	a5,a5,0x20
    80004306:	9381                	srli	a5,a5,0x20
    80004308:	078a                	slli	a5,a5,0x2
    8000430a:	06050613          	addi	a2,a0,96
    8000430e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004310:	4310                	lw	a2,0(a4)
    80004312:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004314:	0711                	addi	a4,a4,4
    80004316:	0691                	addi	a3,a3,4
    80004318:	fef71ce3          	bne	a4,a5,80004310 <initlog+0x68>
  brelse(buf);
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	f8c080e7          	jalr	-116(ra) # 800032a8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004324:	4505                	li	a0,1
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	ebe080e7          	jalr	-322(ra) # 800041e4 <install_trans>
  log.lh.n = 0;
    8000432e:	0001d797          	auipc	a5,0x1d
    80004332:	5807a723          	sw	zero,1422(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	e34080e7          	jalr	-460(ra) # 8000416a <write_head>
}
    8000433e:	70a2                	ld	ra,40(sp)
    80004340:	7402                	ld	s0,32(sp)
    80004342:	64e2                	ld	s1,24(sp)
    80004344:	6942                	ld	s2,16(sp)
    80004346:	69a2                	ld	s3,8(sp)
    80004348:	6145                	addi	sp,sp,48
    8000434a:	8082                	ret

000000008000434c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004358:	0001d517          	auipc	a0,0x1d
    8000435c:	53850513          	addi	a0,a0,1336 # 80021890 <log>
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	884080e7          	jalr	-1916(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	52848493          	addi	s1,s1,1320 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004370:	4979                	li	s2,30
    80004372:	a039                	j	80004380 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004374:	85a6                	mv	a1,s1
    80004376:	8526                	mv	a0,s1
    80004378:	ffffe097          	auipc	ra,0xffffe
    8000437c:	00e080e7          	jalr	14(ra) # 80002386 <sleep>
    if(log.committing){
    80004380:	50dc                	lw	a5,36(s1)
    80004382:	fbed                	bnez	a5,80004374 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004384:	509c                	lw	a5,32(s1)
    80004386:	0017871b          	addiw	a4,a5,1
    8000438a:	0007069b          	sext.w	a3,a4
    8000438e:	0027179b          	slliw	a5,a4,0x2
    80004392:	9fb9                	addw	a5,a5,a4
    80004394:	0017979b          	slliw	a5,a5,0x1
    80004398:	54d8                	lw	a4,44(s1)
    8000439a:	9fb9                	addw	a5,a5,a4
    8000439c:	00f95963          	bge	s2,a5,800043ae <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a0:	85a6                	mv	a1,s1
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffe097          	auipc	ra,0xffffe
    800043a8:	fe2080e7          	jalr	-30(ra) # 80002386 <sleep>
    800043ac:	bfd1                	j	80004380 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043ae:	0001d517          	auipc	a0,0x1d
    800043b2:	4e250513          	addi	a0,a0,1250 # 80021890 <log>
    800043b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6902                	ld	s2,0(sp)
    800043c8:	6105                	addi	sp,sp,32
    800043ca:	8082                	ret

00000000800043cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043cc:	7139                	addi	sp,sp,-64
    800043ce:	fc06                	sd	ra,56(sp)
    800043d0:	f822                	sd	s0,48(sp)
    800043d2:	f426                	sd	s1,40(sp)
    800043d4:	f04a                	sd	s2,32(sp)
    800043d6:	ec4e                	sd	s3,24(sp)
    800043d8:	e852                	sd	s4,16(sp)
    800043da:	e456                	sd	s5,8(sp)
    800043dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043de:	0001d497          	auipc	s1,0x1d
    800043e2:	4b248493          	addi	s1,s1,1202 # 80021890 <log>
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	7fc080e7          	jalr	2044(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043f0:	509c                	lw	a5,32(s1)
    800043f2:	37fd                	addiw	a5,a5,-1
    800043f4:	0007891b          	sext.w	s2,a5
    800043f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043fa:	50dc                	lw	a5,36(s1)
    800043fc:	efb9                	bnez	a5,8000445a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043fe:	06091663          	bnez	s2,8000446a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004402:	0001d497          	auipc	s1,0x1d
    80004406:	48e48493          	addi	s1,s1,1166 # 80021890 <log>
    8000440a:	4785                	li	a5,1
    8000440c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	888080e7          	jalr	-1912(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004418:	54dc                	lw	a5,44(s1)
    8000441a:	06f04763          	bgtz	a5,80004488 <end_op+0xbc>
    acquire(&log.lock);
    8000441e:	0001d497          	auipc	s1,0x1d
    80004422:	47248493          	addi	s1,s1,1138 # 80021890 <log>
    80004426:	8526                	mv	a0,s1
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	7bc080e7          	jalr	1980(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004430:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	0f6080e7          	jalr	246(ra) # 8000252c <wakeup>
    release(&log.lock);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
}
    80004448:	70e2                	ld	ra,56(sp)
    8000444a:	7442                	ld	s0,48(sp)
    8000444c:	74a2                	ld	s1,40(sp)
    8000444e:	7902                	ld	s2,32(sp)
    80004450:	69e2                	ld	s3,24(sp)
    80004452:	6a42                	ld	s4,16(sp)
    80004454:	6aa2                	ld	s5,8(sp)
    80004456:	6121                	addi	sp,sp,64
    80004458:	8082                	ret
    panic("log.committing");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	2ae50513          	addi	a0,a0,686 # 80008708 <syscalls+0x1f8>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	0dc080e7          	jalr	220(ra) # 8000053e <panic>
    wakeup(&log);
    8000446a:	0001d497          	auipc	s1,0x1d
    8000446e:	42648493          	addi	s1,s1,1062 # 80021890 <log>
    80004472:	8526                	mv	a0,s1
    80004474:	ffffe097          	auipc	ra,0xffffe
    80004478:	0b8080e7          	jalr	184(ra) # 8000252c <wakeup>
  release(&log.lock);
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	81a080e7          	jalr	-2022(ra) # 80000c98 <release>
  if(do_commit){
    80004486:	b7c9                	j	80004448 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004488:	0001da97          	auipc	s5,0x1d
    8000448c:	438a8a93          	addi	s5,s5,1080 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004490:	0001da17          	auipc	s4,0x1d
    80004494:	400a0a13          	addi	s4,s4,1024 # 80021890 <log>
    80004498:	018a2583          	lw	a1,24(s4)
    8000449c:	012585bb          	addw	a1,a1,s2
    800044a0:	2585                	addiw	a1,a1,1
    800044a2:	028a2503          	lw	a0,40(s4)
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	cd2080e7          	jalr	-814(ra) # 80003178 <bread>
    800044ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044b0:	000aa583          	lw	a1,0(s5)
    800044b4:	028a2503          	lw	a0,40(s4)
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	cc0080e7          	jalr	-832(ra) # 80003178 <bread>
    800044c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044c2:	40000613          	li	a2,1024
    800044c6:	05850593          	addi	a1,a0,88
    800044ca:	05848513          	addi	a0,s1,88
    800044ce:	ffffd097          	auipc	ra,0xffffd
    800044d2:	872080e7          	jalr	-1934(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044d6:	8526                	mv	a0,s1
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	d92080e7          	jalr	-622(ra) # 8000326a <bwrite>
    brelse(from);
    800044e0:	854e                	mv	a0,s3
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	dc6080e7          	jalr	-570(ra) # 800032a8 <brelse>
    brelse(to);
    800044ea:	8526                	mv	a0,s1
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	dbc080e7          	jalr	-580(ra) # 800032a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f4:	2905                	addiw	s2,s2,1
    800044f6:	0a91                	addi	s5,s5,4
    800044f8:	02ca2783          	lw	a5,44(s4)
    800044fc:	f8f94ee3          	blt	s2,a5,80004498 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004500:	00000097          	auipc	ra,0x0
    80004504:	c6a080e7          	jalr	-918(ra) # 8000416a <write_head>
    install_trans(0); // Now install writes to home locations
    80004508:	4501                	li	a0,0
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	cda080e7          	jalr	-806(ra) # 800041e4 <install_trans>
    log.lh.n = 0;
    80004512:	0001d797          	auipc	a5,0x1d
    80004516:	3a07a523          	sw	zero,938(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000451a:	00000097          	auipc	ra,0x0
    8000451e:	c50080e7          	jalr	-944(ra) # 8000416a <write_head>
    80004522:	bdf5                	j	8000441e <end_op+0x52>

0000000080004524 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004524:	1101                	addi	sp,sp,-32
    80004526:	ec06                	sd	ra,24(sp)
    80004528:	e822                	sd	s0,16(sp)
    8000452a:	e426                	sd	s1,8(sp)
    8000452c:	e04a                	sd	s2,0(sp)
    8000452e:	1000                	addi	s0,sp,32
    80004530:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004532:	0001d917          	auipc	s2,0x1d
    80004536:	35e90913          	addi	s2,s2,862 # 80021890 <log>
    8000453a:	854a                	mv	a0,s2
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	6a8080e7          	jalr	1704(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004544:	02c92603          	lw	a2,44(s2)
    80004548:	47f5                	li	a5,29
    8000454a:	06c7c563          	blt	a5,a2,800045b4 <log_write+0x90>
    8000454e:	0001d797          	auipc	a5,0x1d
    80004552:	35e7a783          	lw	a5,862(a5) # 800218ac <log+0x1c>
    80004556:	37fd                	addiw	a5,a5,-1
    80004558:	04f65e63          	bge	a2,a5,800045b4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000455c:	0001d797          	auipc	a5,0x1d
    80004560:	3547a783          	lw	a5,852(a5) # 800218b0 <log+0x20>
    80004564:	06f05063          	blez	a5,800045c4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004568:	4781                	li	a5,0
    8000456a:	06c05563          	blez	a2,800045d4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000456e:	44cc                	lw	a1,12(s1)
    80004570:	0001d717          	auipc	a4,0x1d
    80004574:	35070713          	addi	a4,a4,848 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004578:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000457a:	4314                	lw	a3,0(a4)
    8000457c:	04b68c63          	beq	a3,a1,800045d4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004580:	2785                	addiw	a5,a5,1
    80004582:	0711                	addi	a4,a4,4
    80004584:	fef61be3          	bne	a2,a5,8000457a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004588:	0621                	addi	a2,a2,8
    8000458a:	060a                	slli	a2,a2,0x2
    8000458c:	0001d797          	auipc	a5,0x1d
    80004590:	30478793          	addi	a5,a5,772 # 80021890 <log>
    80004594:	963e                	add	a2,a2,a5
    80004596:	44dc                	lw	a5,12(s1)
    80004598:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	daa080e7          	jalr	-598(ra) # 80003346 <bpin>
    log.lh.n++;
    800045a4:	0001d717          	auipc	a4,0x1d
    800045a8:	2ec70713          	addi	a4,a4,748 # 80021890 <log>
    800045ac:	575c                	lw	a5,44(a4)
    800045ae:	2785                	addiw	a5,a5,1
    800045b0:	d75c                	sw	a5,44(a4)
    800045b2:	a835                	j	800045ee <log_write+0xca>
    panic("too big a transaction");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	16450513          	addi	a0,a0,356 # 80008718 <syscalls+0x208>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045c4:	00004517          	auipc	a0,0x4
    800045c8:	16c50513          	addi	a0,a0,364 # 80008730 <syscalls+0x220>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	f72080e7          	jalr	-142(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045d4:	00878713          	addi	a4,a5,8
    800045d8:	00271693          	slli	a3,a4,0x2
    800045dc:	0001d717          	auipc	a4,0x1d
    800045e0:	2b470713          	addi	a4,a4,692 # 80021890 <log>
    800045e4:	9736                	add	a4,a4,a3
    800045e6:	44d4                	lw	a3,12(s1)
    800045e8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ea:	faf608e3          	beq	a2,a5,8000459a <log_write+0x76>
  }
  release(&log.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	2a250513          	addi	a0,a0,674 # 80021890 <log>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
}
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6902                	ld	s2,0(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	e04a                	sd	s2,0(sp)
    80004614:	1000                	addi	s0,sp,32
    80004616:	84aa                	mv	s1,a0
    80004618:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000461a:	00004597          	auipc	a1,0x4
    8000461e:	13658593          	addi	a1,a1,310 # 80008750 <syscalls+0x240>
    80004622:	0521                	addi	a0,a0,8
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	530080e7          	jalr	1328(ra) # 80000b54 <initlock>
  lk->name = name;
    8000462c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004630:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004634:	0204a423          	sw	zero,40(s1)
}
    80004638:	60e2                	ld	ra,24(sp)
    8000463a:	6442                	ld	s0,16(sp)
    8000463c:	64a2                	ld	s1,8(sp)
    8000463e:	6902                	ld	s2,0(sp)
    80004640:	6105                	addi	sp,sp,32
    80004642:	8082                	ret

0000000080004644 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004644:	1101                	addi	sp,sp,-32
    80004646:	ec06                	sd	ra,24(sp)
    80004648:	e822                	sd	s0,16(sp)
    8000464a:	e426                	sd	s1,8(sp)
    8000464c:	e04a                	sd	s2,0(sp)
    8000464e:	1000                	addi	s0,sp,32
    80004650:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004652:	00850913          	addi	s2,a0,8
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	58c080e7          	jalr	1420(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	cb89                	beqz	a5,80004674 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004664:	85ca                	mv	a1,s2
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	d1e080e7          	jalr	-738(ra) # 80002386 <sleep>
  while (lk->locked) {
    80004670:	409c                	lw	a5,0(s1)
    80004672:	fbed                	bnez	a5,80004664 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004674:	4785                	li	a5,1
    80004676:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004678:	ffffd097          	auipc	ra,0xffffd
    8000467c:	678080e7          	jalr	1656(ra) # 80001cf0 <myproc>
    80004680:	591c                	lw	a5,48(a0)
    80004682:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004684:	854a                	mv	a0,s2
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
}
    8000468e:	60e2                	ld	ra,24(sp)
    80004690:	6442                	ld	s0,16(sp)
    80004692:	64a2                	ld	s1,8(sp)
    80004694:	6902                	ld	s2,0(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret

000000008000469a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000469a:	1101                	addi	sp,sp,-32
    8000469c:	ec06                	sd	ra,24(sp)
    8000469e:	e822                	sd	s0,16(sp)
    800046a0:	e426                	sd	s1,8(sp)
    800046a2:	e04a                	sd	s2,0(sp)
    800046a4:	1000                	addi	s0,sp,32
    800046a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a8:	00850913          	addi	s2,a0,8
    800046ac:	854a                	mv	a0,s2
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	536080e7          	jalr	1334(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800046b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffe097          	auipc	ra,0xffffe
    800046c4:	e6c080e7          	jalr	-404(ra) # 8000252c <wakeup>
  release(&lk->lk);
    800046c8:	854a                	mv	a0,s2
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
}
    800046d2:	60e2                	ld	ra,24(sp)
    800046d4:	6442                	ld	s0,16(sp)
    800046d6:	64a2                	ld	s1,8(sp)
    800046d8:	6902                	ld	s2,0(sp)
    800046da:	6105                	addi	sp,sp,32
    800046dc:	8082                	ret

00000000800046de <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046de:	7179                	addi	sp,sp,-48
    800046e0:	f406                	sd	ra,40(sp)
    800046e2:	f022                	sd	s0,32(sp)
    800046e4:	ec26                	sd	s1,24(sp)
    800046e6:	e84a                	sd	s2,16(sp)
    800046e8:	e44e                	sd	s3,8(sp)
    800046ea:	1800                	addi	s0,sp,48
    800046ec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ee:	00850913          	addi	s2,a0,8
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	ef99                	bnez	a5,8000471c <holdingsleep+0x3e>
    80004700:	4481                	li	s1,0
  release(&lk->lk);
    80004702:	854a                	mv	a0,s2
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	594080e7          	jalr	1428(ra) # 80000c98 <release>
  return r;
}
    8000470c:	8526                	mv	a0,s1
    8000470e:	70a2                	ld	ra,40(sp)
    80004710:	7402                	ld	s0,32(sp)
    80004712:	64e2                	ld	s1,24(sp)
    80004714:	6942                	ld	s2,16(sp)
    80004716:	69a2                	ld	s3,8(sp)
    80004718:	6145                	addi	sp,sp,48
    8000471a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000471c:	0284a983          	lw	s3,40(s1)
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	5d0080e7          	jalr	1488(ra) # 80001cf0 <myproc>
    80004728:	5904                	lw	s1,48(a0)
    8000472a:	413484b3          	sub	s1,s1,s3
    8000472e:	0014b493          	seqz	s1,s1
    80004732:	bfc1                	j	80004702 <holdingsleep+0x24>

0000000080004734 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004734:	1141                	addi	sp,sp,-16
    80004736:	e406                	sd	ra,8(sp)
    80004738:	e022                	sd	s0,0(sp)
    8000473a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000473c:	00004597          	auipc	a1,0x4
    80004740:	02458593          	addi	a1,a1,36 # 80008760 <syscalls+0x250>
    80004744:	0001d517          	auipc	a0,0x1d
    80004748:	29450513          	addi	a0,a0,660 # 800219d8 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	408080e7          	jalr	1032(ra) # 80000b54 <initlock>
}
    80004754:	60a2                	ld	ra,8(sp)
    80004756:	6402                	ld	s0,0(sp)
    80004758:	0141                	addi	sp,sp,16
    8000475a:	8082                	ret

000000008000475c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004766:	0001d517          	auipc	a0,0x1d
    8000476a:	27250513          	addi	a0,a0,626 # 800219d8 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	476080e7          	jalr	1142(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004776:	0001d497          	auipc	s1,0x1d
    8000477a:	27a48493          	addi	s1,s1,634 # 800219f0 <ftable+0x18>
    8000477e:	0001e717          	auipc	a4,0x1e
    80004782:	21270713          	addi	a4,a4,530 # 80022990 <ftable+0xfb8>
    if(f->ref == 0){
    80004786:	40dc                	lw	a5,4(s1)
    80004788:	cf99                	beqz	a5,800047a6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000478a:	02848493          	addi	s1,s1,40
    8000478e:	fee49ce3          	bne	s1,a4,80004786 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004792:	0001d517          	auipc	a0,0x1d
    80004796:	24650513          	addi	a0,a0,582 # 800219d8 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	4fe080e7          	jalr	1278(ra) # 80000c98 <release>
  return 0;
    800047a2:	4481                	li	s1,0
    800047a4:	a819                	j	800047ba <filealloc+0x5e>
      f->ref = 1;
    800047a6:	4785                	li	a5,1
    800047a8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047aa:	0001d517          	auipc	a0,0x1d
    800047ae:	22e50513          	addi	a0,a0,558 # 800219d8 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	4e6080e7          	jalr	1254(ra) # 80000c98 <release>
}
    800047ba:	8526                	mv	a0,s1
    800047bc:	60e2                	ld	ra,24(sp)
    800047be:	6442                	ld	s0,16(sp)
    800047c0:	64a2                	ld	s1,8(sp)
    800047c2:	6105                	addi	sp,sp,32
    800047c4:	8082                	ret

00000000800047c6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c6:	1101                	addi	sp,sp,-32
    800047c8:	ec06                	sd	ra,24(sp)
    800047ca:	e822                	sd	s0,16(sp)
    800047cc:	e426                	sd	s1,8(sp)
    800047ce:	1000                	addi	s0,sp,32
    800047d0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d2:	0001d517          	auipc	a0,0x1d
    800047d6:	20650513          	addi	a0,a0,518 # 800219d8 <ftable>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	40a080e7          	jalr	1034(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047e2:	40dc                	lw	a5,4(s1)
    800047e4:	02f05263          	blez	a5,80004808 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e8:	2785                	addiw	a5,a5,1
    800047ea:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ec:	0001d517          	auipc	a0,0x1d
    800047f0:	1ec50513          	addi	a0,a0,492 # 800219d8 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	4a4080e7          	jalr	1188(ra) # 80000c98 <release>
  return f;
}
    800047fc:	8526                	mv	a0,s1
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6105                	addi	sp,sp,32
    80004806:	8082                	ret
    panic("filedup");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	f6050513          	addi	a0,a0,-160 # 80008768 <syscalls+0x258>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d2e080e7          	jalr	-722(ra) # 8000053e <panic>

0000000080004818 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004818:	7139                	addi	sp,sp,-64
    8000481a:	fc06                	sd	ra,56(sp)
    8000481c:	f822                	sd	s0,48(sp)
    8000481e:	f426                	sd	s1,40(sp)
    80004820:	f04a                	sd	s2,32(sp)
    80004822:	ec4e                	sd	s3,24(sp)
    80004824:	e852                	sd	s4,16(sp)
    80004826:	e456                	sd	s5,8(sp)
    80004828:	0080                	addi	s0,sp,64
    8000482a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000482c:	0001d517          	auipc	a0,0x1d
    80004830:	1ac50513          	addi	a0,a0,428 # 800219d8 <ftable>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	3b0080e7          	jalr	944(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000483c:	40dc                	lw	a5,4(s1)
    8000483e:	06f05163          	blez	a5,800048a0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004842:	37fd                	addiw	a5,a5,-1
    80004844:	0007871b          	sext.w	a4,a5
    80004848:	c0dc                	sw	a5,4(s1)
    8000484a:	06e04363          	bgtz	a4,800048b0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000484e:	0004a903          	lw	s2,0(s1)
    80004852:	0094ca83          	lbu	s5,9(s1)
    80004856:	0104ba03          	ld	s4,16(s1)
    8000485a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000485e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004862:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004866:	0001d517          	auipc	a0,0x1d
    8000486a:	17250513          	addi	a0,a0,370 # 800219d8 <ftable>
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004876:	4785                	li	a5,1
    80004878:	04f90d63          	beq	s2,a5,800048d2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000487c:	3979                	addiw	s2,s2,-2
    8000487e:	4785                	li	a5,1
    80004880:	0527e063          	bltu	a5,s2,800048c0 <fileclose+0xa8>
    begin_op();
    80004884:	00000097          	auipc	ra,0x0
    80004888:	ac8080e7          	jalr	-1336(ra) # 8000434c <begin_op>
    iput(ff.ip);
    8000488c:	854e                	mv	a0,s3
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	2a6080e7          	jalr	678(ra) # 80003b34 <iput>
    end_op();
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	b36080e7          	jalr	-1226(ra) # 800043cc <end_op>
    8000489e:	a00d                	j	800048c0 <fileclose+0xa8>
    panic("fileclose");
    800048a0:	00004517          	auipc	a0,0x4
    800048a4:	ed050513          	addi	a0,a0,-304 # 80008770 <syscalls+0x260>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048b0:	0001d517          	auipc	a0,0x1d
    800048b4:	12850513          	addi	a0,a0,296 # 800219d8 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	3e0080e7          	jalr	992(ra) # 80000c98 <release>
  }
}
    800048c0:	70e2                	ld	ra,56(sp)
    800048c2:	7442                	ld	s0,48(sp)
    800048c4:	74a2                	ld	s1,40(sp)
    800048c6:	7902                	ld	s2,32(sp)
    800048c8:	69e2                	ld	s3,24(sp)
    800048ca:	6a42                	ld	s4,16(sp)
    800048cc:	6aa2                	ld	s5,8(sp)
    800048ce:	6121                	addi	sp,sp,64
    800048d0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d2:	85d6                	mv	a1,s5
    800048d4:	8552                	mv	a0,s4
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	34c080e7          	jalr	844(ra) # 80004c22 <pipeclose>
    800048de:	b7cd                	j	800048c0 <fileclose+0xa8>

00000000800048e0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e0:	715d                	addi	sp,sp,-80
    800048e2:	e486                	sd	ra,72(sp)
    800048e4:	e0a2                	sd	s0,64(sp)
    800048e6:	fc26                	sd	s1,56(sp)
    800048e8:	f84a                	sd	s2,48(sp)
    800048ea:	f44e                	sd	s3,40(sp)
    800048ec:	0880                	addi	s0,sp,80
    800048ee:	84aa                	mv	s1,a0
    800048f0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f2:	ffffd097          	auipc	ra,0xffffd
    800048f6:	3fe080e7          	jalr	1022(ra) # 80001cf0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048fa:	409c                	lw	a5,0(s1)
    800048fc:	37f9                	addiw	a5,a5,-2
    800048fe:	4705                	li	a4,1
    80004900:	04f76763          	bltu	a4,a5,8000494e <filestat+0x6e>
    80004904:	892a                	mv	s2,a0
    ilock(f->ip);
    80004906:	6c88                	ld	a0,24(s1)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	072080e7          	jalr	114(ra) # 8000397a <ilock>
    stati(f->ip, &st);
    80004910:	fb840593          	addi	a1,s0,-72
    80004914:	6c88                	ld	a0,24(s1)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	2ee080e7          	jalr	750(ra) # 80003c04 <stati>
    iunlock(f->ip);
    8000491e:	6c88                	ld	a0,24(s1)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	11c080e7          	jalr	284(ra) # 80003a3c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004928:	46e1                	li	a3,24
    8000492a:	fb840613          	addi	a2,s0,-72
    8000492e:	85ce                	mv	a1,s3
    80004930:	06893503          	ld	a0,104(s2)
    80004934:	ffffd097          	auipc	ra,0xffffd
    80004938:	d3e080e7          	jalr	-706(ra) # 80001672 <copyout>
    8000493c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004940:	60a6                	ld	ra,72(sp)
    80004942:	6406                	ld	s0,64(sp)
    80004944:	74e2                	ld	s1,56(sp)
    80004946:	7942                	ld	s2,48(sp)
    80004948:	79a2                	ld	s3,40(sp)
    8000494a:	6161                	addi	sp,sp,80
    8000494c:	8082                	ret
  return -1;
    8000494e:	557d                	li	a0,-1
    80004950:	bfc5                	j	80004940 <filestat+0x60>

0000000080004952 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004952:	7179                	addi	sp,sp,-48
    80004954:	f406                	sd	ra,40(sp)
    80004956:	f022                	sd	s0,32(sp)
    80004958:	ec26                	sd	s1,24(sp)
    8000495a:	e84a                	sd	s2,16(sp)
    8000495c:	e44e                	sd	s3,8(sp)
    8000495e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004960:	00854783          	lbu	a5,8(a0)
    80004964:	c3d5                	beqz	a5,80004a08 <fileread+0xb6>
    80004966:	84aa                	mv	s1,a0
    80004968:	89ae                	mv	s3,a1
    8000496a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000496c:	411c                	lw	a5,0(a0)
    8000496e:	4705                	li	a4,1
    80004970:	04e78963          	beq	a5,a4,800049c2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004974:	470d                	li	a4,3
    80004976:	04e78d63          	beq	a5,a4,800049d0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000497a:	4709                	li	a4,2
    8000497c:	06e79e63          	bne	a5,a4,800049f8 <fileread+0xa6>
    ilock(f->ip);
    80004980:	6d08                	ld	a0,24(a0)
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	ff8080e7          	jalr	-8(ra) # 8000397a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000498a:	874a                	mv	a4,s2
    8000498c:	5094                	lw	a3,32(s1)
    8000498e:	864e                	mv	a2,s3
    80004990:	4585                	li	a1,1
    80004992:	6c88                	ld	a0,24(s1)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	29a080e7          	jalr	666(ra) # 80003c2e <readi>
    8000499c:	892a                	mv	s2,a0
    8000499e:	00a05563          	blez	a0,800049a8 <fileread+0x56>
      f->off += r;
    800049a2:	509c                	lw	a5,32(s1)
    800049a4:	9fa9                	addw	a5,a5,a0
    800049a6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a8:	6c88                	ld	a0,24(s1)
    800049aa:	fffff097          	auipc	ra,0xfffff
    800049ae:	092080e7          	jalr	146(ra) # 80003a3c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b2:	854a                	mv	a0,s2
    800049b4:	70a2                	ld	ra,40(sp)
    800049b6:	7402                	ld	s0,32(sp)
    800049b8:	64e2                	ld	s1,24(sp)
    800049ba:	6942                	ld	s2,16(sp)
    800049bc:	69a2                	ld	s3,8(sp)
    800049be:	6145                	addi	sp,sp,48
    800049c0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c2:	6908                	ld	a0,16(a0)
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	3c8080e7          	jalr	968(ra) # 80004d8c <piperead>
    800049cc:	892a                	mv	s2,a0
    800049ce:	b7d5                	j	800049b2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d0:	02451783          	lh	a5,36(a0)
    800049d4:	03079693          	slli	a3,a5,0x30
    800049d8:	92c1                	srli	a3,a3,0x30
    800049da:	4725                	li	a4,9
    800049dc:	02d76863          	bltu	a4,a3,80004a0c <fileread+0xba>
    800049e0:	0792                	slli	a5,a5,0x4
    800049e2:	0001d717          	auipc	a4,0x1d
    800049e6:	f5670713          	addi	a4,a4,-170 # 80021938 <devsw>
    800049ea:	97ba                	add	a5,a5,a4
    800049ec:	639c                	ld	a5,0(a5)
    800049ee:	c38d                	beqz	a5,80004a10 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f0:	4505                	li	a0,1
    800049f2:	9782                	jalr	a5
    800049f4:	892a                	mv	s2,a0
    800049f6:	bf75                	j	800049b2 <fileread+0x60>
    panic("fileread");
    800049f8:	00004517          	auipc	a0,0x4
    800049fc:	d8850513          	addi	a0,a0,-632 # 80008780 <syscalls+0x270>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    return -1;
    80004a08:	597d                	li	s2,-1
    80004a0a:	b765                	j	800049b2 <fileread+0x60>
      return -1;
    80004a0c:	597d                	li	s2,-1
    80004a0e:	b755                	j	800049b2 <fileread+0x60>
    80004a10:	597d                	li	s2,-1
    80004a12:	b745                	j	800049b2 <fileread+0x60>

0000000080004a14 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a14:	715d                	addi	sp,sp,-80
    80004a16:	e486                	sd	ra,72(sp)
    80004a18:	e0a2                	sd	s0,64(sp)
    80004a1a:	fc26                	sd	s1,56(sp)
    80004a1c:	f84a                	sd	s2,48(sp)
    80004a1e:	f44e                	sd	s3,40(sp)
    80004a20:	f052                	sd	s4,32(sp)
    80004a22:	ec56                	sd	s5,24(sp)
    80004a24:	e85a                	sd	s6,16(sp)
    80004a26:	e45e                	sd	s7,8(sp)
    80004a28:	e062                	sd	s8,0(sp)
    80004a2a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a2c:	00954783          	lbu	a5,9(a0)
    80004a30:	10078663          	beqz	a5,80004b3c <filewrite+0x128>
    80004a34:	892a                	mv	s2,a0
    80004a36:	8aae                	mv	s5,a1
    80004a38:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3a:	411c                	lw	a5,0(a0)
    80004a3c:	4705                	li	a4,1
    80004a3e:	02e78263          	beq	a5,a4,80004a62 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a42:	470d                	li	a4,3
    80004a44:	02e78663          	beq	a5,a4,80004a70 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a48:	4709                	li	a4,2
    80004a4a:	0ee79163          	bne	a5,a4,80004b2c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a4e:	0ac05d63          	blez	a2,80004b08 <filewrite+0xf4>
    int i = 0;
    80004a52:	4981                	li	s3,0
    80004a54:	6b05                	lui	s6,0x1
    80004a56:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a5a:	6b85                	lui	s7,0x1
    80004a5c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a60:	a861                	j	80004af8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a62:	6908                	ld	a0,16(a0)
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	22e080e7          	jalr	558(ra) # 80004c92 <pipewrite>
    80004a6c:	8a2a                	mv	s4,a0
    80004a6e:	a045                	j	80004b0e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a70:	02451783          	lh	a5,36(a0)
    80004a74:	03079693          	slli	a3,a5,0x30
    80004a78:	92c1                	srli	a3,a3,0x30
    80004a7a:	4725                	li	a4,9
    80004a7c:	0cd76263          	bltu	a4,a3,80004b40 <filewrite+0x12c>
    80004a80:	0792                	slli	a5,a5,0x4
    80004a82:	0001d717          	auipc	a4,0x1d
    80004a86:	eb670713          	addi	a4,a4,-330 # 80021938 <devsw>
    80004a8a:	97ba                	add	a5,a5,a4
    80004a8c:	679c                	ld	a5,8(a5)
    80004a8e:	cbdd                	beqz	a5,80004b44 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a90:	4505                	li	a0,1
    80004a92:	9782                	jalr	a5
    80004a94:	8a2a                	mv	s4,a0
    80004a96:	a8a5                	j	80004b0e <filewrite+0xfa>
    80004a98:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	8b0080e7          	jalr	-1872(ra) # 8000434c <begin_op>
      ilock(f->ip);
    80004aa4:	01893503          	ld	a0,24(s2)
    80004aa8:	fffff097          	auipc	ra,0xfffff
    80004aac:	ed2080e7          	jalr	-302(ra) # 8000397a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab0:	8762                	mv	a4,s8
    80004ab2:	02092683          	lw	a3,32(s2)
    80004ab6:	01598633          	add	a2,s3,s5
    80004aba:	4585                	li	a1,1
    80004abc:	01893503          	ld	a0,24(s2)
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	266080e7          	jalr	614(ra) # 80003d26 <writei>
    80004ac8:	84aa                	mv	s1,a0
    80004aca:	00a05763          	blez	a0,80004ad8 <filewrite+0xc4>
        f->off += r;
    80004ace:	02092783          	lw	a5,32(s2)
    80004ad2:	9fa9                	addw	a5,a5,a0
    80004ad4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad8:	01893503          	ld	a0,24(s2)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	f60080e7          	jalr	-160(ra) # 80003a3c <iunlock>
      end_op();
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	8e8080e7          	jalr	-1816(ra) # 800043cc <end_op>

      if(r != n1){
    80004aec:	009c1f63          	bne	s8,s1,80004b0a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004af0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af4:	0149db63          	bge	s3,s4,80004b0a <filewrite+0xf6>
      int n1 = n - i;
    80004af8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004afc:	84be                	mv	s1,a5
    80004afe:	2781                	sext.w	a5,a5
    80004b00:	f8fb5ce3          	bge	s6,a5,80004a98 <filewrite+0x84>
    80004b04:	84de                	mv	s1,s7
    80004b06:	bf49                	j	80004a98 <filewrite+0x84>
    int i = 0;
    80004b08:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b0a:	013a1f63          	bne	s4,s3,80004b28 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b0e:	8552                	mv	a0,s4
    80004b10:	60a6                	ld	ra,72(sp)
    80004b12:	6406                	ld	s0,64(sp)
    80004b14:	74e2                	ld	s1,56(sp)
    80004b16:	7942                	ld	s2,48(sp)
    80004b18:	79a2                	ld	s3,40(sp)
    80004b1a:	7a02                	ld	s4,32(sp)
    80004b1c:	6ae2                	ld	s5,24(sp)
    80004b1e:	6b42                	ld	s6,16(sp)
    80004b20:	6ba2                	ld	s7,8(sp)
    80004b22:	6c02                	ld	s8,0(sp)
    80004b24:	6161                	addi	sp,sp,80
    80004b26:	8082                	ret
    ret = (i == n ? n : -1);
    80004b28:	5a7d                	li	s4,-1
    80004b2a:	b7d5                	j	80004b0e <filewrite+0xfa>
    panic("filewrite");
    80004b2c:	00004517          	auipc	a0,0x4
    80004b30:	c6450513          	addi	a0,a0,-924 # 80008790 <syscalls+0x280>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	a0a080e7          	jalr	-1526(ra) # 8000053e <panic>
    return -1;
    80004b3c:	5a7d                	li	s4,-1
    80004b3e:	bfc1                	j	80004b0e <filewrite+0xfa>
      return -1;
    80004b40:	5a7d                	li	s4,-1
    80004b42:	b7f1                	j	80004b0e <filewrite+0xfa>
    80004b44:	5a7d                	li	s4,-1
    80004b46:	b7e1                	j	80004b0e <filewrite+0xfa>

0000000080004b48 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b48:	7179                	addi	sp,sp,-48
    80004b4a:	f406                	sd	ra,40(sp)
    80004b4c:	f022                	sd	s0,32(sp)
    80004b4e:	ec26                	sd	s1,24(sp)
    80004b50:	e84a                	sd	s2,16(sp)
    80004b52:	e44e                	sd	s3,8(sp)
    80004b54:	e052                	sd	s4,0(sp)
    80004b56:	1800                	addi	s0,sp,48
    80004b58:	84aa                	mv	s1,a0
    80004b5a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b5c:	0005b023          	sd	zero,0(a1)
    80004b60:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	bf8080e7          	jalr	-1032(ra) # 8000475c <filealloc>
    80004b6c:	e088                	sd	a0,0(s1)
    80004b6e:	c551                	beqz	a0,80004bfa <pipealloc+0xb2>
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	bec080e7          	jalr	-1044(ra) # 8000475c <filealloc>
    80004b78:	00aa3023          	sd	a0,0(s4)
    80004b7c:	c92d                	beqz	a0,80004bee <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	f76080e7          	jalr	-138(ra) # 80000af4 <kalloc>
    80004b86:	892a                	mv	s2,a0
    80004b88:	c125                	beqz	a0,80004be8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b8a:	4985                	li	s3,1
    80004b8c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b90:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b94:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b98:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b9c:	00004597          	auipc	a1,0x4
    80004ba0:	c0458593          	addi	a1,a1,-1020 # 800087a0 <syscalls+0x290>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	fb0080e7          	jalr	-80(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bac:	609c                	ld	a5,0(s1)
    80004bae:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bb2:	609c                	ld	a5,0(s1)
    80004bb4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bb8:	609c                	ld	a5,0(s1)
    80004bba:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bbe:	609c                	ld	a5,0(s1)
    80004bc0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bd4:	000a3783          	ld	a5,0(s4)
    80004bd8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bdc:	000a3783          	ld	a5,0(s4)
    80004be0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004be4:	4501                	li	a0,0
    80004be6:	a025                	j	80004c0e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004be8:	6088                	ld	a0,0(s1)
    80004bea:	e501                	bnez	a0,80004bf2 <pipealloc+0xaa>
    80004bec:	a039                	j	80004bfa <pipealloc+0xb2>
    80004bee:	6088                	ld	a0,0(s1)
    80004bf0:	c51d                	beqz	a0,80004c1e <pipealloc+0xd6>
    fileclose(*f0);
    80004bf2:	00000097          	auipc	ra,0x0
    80004bf6:	c26080e7          	jalr	-986(ra) # 80004818 <fileclose>
  if(*f1)
    80004bfa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bfe:	557d                	li	a0,-1
  if(*f1)
    80004c00:	c799                	beqz	a5,80004c0e <pipealloc+0xc6>
    fileclose(*f1);
    80004c02:	853e                	mv	a0,a5
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	c14080e7          	jalr	-1004(ra) # 80004818 <fileclose>
  return -1;
    80004c0c:	557d                	li	a0,-1
}
    80004c0e:	70a2                	ld	ra,40(sp)
    80004c10:	7402                	ld	s0,32(sp)
    80004c12:	64e2                	ld	s1,24(sp)
    80004c14:	6942                	ld	s2,16(sp)
    80004c16:	69a2                	ld	s3,8(sp)
    80004c18:	6a02                	ld	s4,0(sp)
    80004c1a:	6145                	addi	sp,sp,48
    80004c1c:	8082                	ret
  return -1;
    80004c1e:	557d                	li	a0,-1
    80004c20:	b7fd                	j	80004c0e <pipealloc+0xc6>

0000000080004c22 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c22:	1101                	addi	sp,sp,-32
    80004c24:	ec06                	sd	ra,24(sp)
    80004c26:	e822                	sd	s0,16(sp)
    80004c28:	e426                	sd	s1,8(sp)
    80004c2a:	e04a                	sd	s2,0(sp)
    80004c2c:	1000                	addi	s0,sp,32
    80004c2e:	84aa                	mv	s1,a0
    80004c30:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	fb2080e7          	jalr	-78(ra) # 80000be4 <acquire>
  if(writable){
    80004c3a:	02090d63          	beqz	s2,80004c74 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c3e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c42:	21848513          	addi	a0,s1,536
    80004c46:	ffffe097          	auipc	ra,0xffffe
    80004c4a:	8e6080e7          	jalr	-1818(ra) # 8000252c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c4e:	2204b783          	ld	a5,544(s1)
    80004c52:	eb95                	bnez	a5,80004c86 <pipeclose+0x64>
    release(&pi->lock);
    80004c54:	8526                	mv	a0,s1
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	d98080e7          	jalr	-616(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c68:	60e2                	ld	ra,24(sp)
    80004c6a:	6442                	ld	s0,16(sp)
    80004c6c:	64a2                	ld	s1,8(sp)
    80004c6e:	6902                	ld	s2,0(sp)
    80004c70:	6105                	addi	sp,sp,32
    80004c72:	8082                	ret
    pi->readopen = 0;
    80004c74:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c78:	21c48513          	addi	a0,s1,540
    80004c7c:	ffffe097          	auipc	ra,0xffffe
    80004c80:	8b0080e7          	jalr	-1872(ra) # 8000252c <wakeup>
    80004c84:	b7e9                	j	80004c4e <pipeclose+0x2c>
    release(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
}
    80004c90:	bfe1                	j	80004c68 <pipeclose+0x46>

0000000080004c92 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c92:	7159                	addi	sp,sp,-112
    80004c94:	f486                	sd	ra,104(sp)
    80004c96:	f0a2                	sd	s0,96(sp)
    80004c98:	eca6                	sd	s1,88(sp)
    80004c9a:	e8ca                	sd	s2,80(sp)
    80004c9c:	e4ce                	sd	s3,72(sp)
    80004c9e:	e0d2                	sd	s4,64(sp)
    80004ca0:	fc56                	sd	s5,56(sp)
    80004ca2:	f85a                	sd	s6,48(sp)
    80004ca4:	f45e                	sd	s7,40(sp)
    80004ca6:	f062                	sd	s8,32(sp)
    80004ca8:	ec66                	sd	s9,24(sp)
    80004caa:	1880                	addi	s0,sp,112
    80004cac:	84aa                	mv	s1,a0
    80004cae:	8aae                	mv	s5,a1
    80004cb0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	03e080e7          	jalr	62(ra) # 80001cf0 <myproc>
    80004cba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f26080e7          	jalr	-218(ra) # 80000be4 <acquire>
  while(i < n){
    80004cc6:	0d405163          	blez	s4,80004d88 <pipewrite+0xf6>
    80004cca:	8ba6                	mv	s7,s1
  int i = 0;
    80004ccc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cce:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cd0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cd4:	21c48c13          	addi	s8,s1,540
    80004cd8:	a08d                	j	80004d3a <pipewrite+0xa8>
      release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	fbc080e7          	jalr	-68(ra) # 80000c98 <release>
      return -1;
    80004ce4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ce6:	854a                	mv	a0,s2
    80004ce8:	70a6                	ld	ra,104(sp)
    80004cea:	7406                	ld	s0,96(sp)
    80004cec:	64e6                	ld	s1,88(sp)
    80004cee:	6946                	ld	s2,80(sp)
    80004cf0:	69a6                	ld	s3,72(sp)
    80004cf2:	6a06                	ld	s4,64(sp)
    80004cf4:	7ae2                	ld	s5,56(sp)
    80004cf6:	7b42                	ld	s6,48(sp)
    80004cf8:	7ba2                	ld	s7,40(sp)
    80004cfa:	7c02                	ld	s8,32(sp)
    80004cfc:	6ce2                	ld	s9,24(sp)
    80004cfe:	6165                	addi	sp,sp,112
    80004d00:	8082                	ret
      wakeup(&pi->nread);
    80004d02:	8566                	mv	a0,s9
    80004d04:	ffffe097          	auipc	ra,0xffffe
    80004d08:	828080e7          	jalr	-2008(ra) # 8000252c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d0c:	85de                	mv	a1,s7
    80004d0e:	8562                	mv	a0,s8
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	676080e7          	jalr	1654(ra) # 80002386 <sleep>
    80004d18:	a839                	j	80004d36 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d1a:	21c4a783          	lw	a5,540(s1)
    80004d1e:	0017871b          	addiw	a4,a5,1
    80004d22:	20e4ae23          	sw	a4,540(s1)
    80004d26:	1ff7f793          	andi	a5,a5,511
    80004d2a:	97a6                	add	a5,a5,s1
    80004d2c:	f9f44703          	lbu	a4,-97(s0)
    80004d30:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d34:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d36:	03495d63          	bge	s2,s4,80004d70 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d3a:	2204a783          	lw	a5,544(s1)
    80004d3e:	dfd1                	beqz	a5,80004cda <pipewrite+0x48>
    80004d40:	0289a783          	lw	a5,40(s3)
    80004d44:	fbd9                	bnez	a5,80004cda <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d46:	2184a783          	lw	a5,536(s1)
    80004d4a:	21c4a703          	lw	a4,540(s1)
    80004d4e:	2007879b          	addiw	a5,a5,512
    80004d52:	faf708e3          	beq	a4,a5,80004d02 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d56:	4685                	li	a3,1
    80004d58:	01590633          	add	a2,s2,s5
    80004d5c:	f9f40593          	addi	a1,s0,-97
    80004d60:	0689b503          	ld	a0,104(s3)
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	99a080e7          	jalr	-1638(ra) # 800016fe <copyin>
    80004d6c:	fb6517e3          	bne	a0,s6,80004d1a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d70:	21848513          	addi	a0,s1,536
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	7b8080e7          	jalr	1976(ra) # 8000252c <wakeup>
  release(&pi->lock);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	f1a080e7          	jalr	-230(ra) # 80000c98 <release>
  return i;
    80004d86:	b785                	j	80004ce6 <pipewrite+0x54>
  int i = 0;
    80004d88:	4901                	li	s2,0
    80004d8a:	b7dd                	j	80004d70 <pipewrite+0xde>

0000000080004d8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d8c:	715d                	addi	sp,sp,-80
    80004d8e:	e486                	sd	ra,72(sp)
    80004d90:	e0a2                	sd	s0,64(sp)
    80004d92:	fc26                	sd	s1,56(sp)
    80004d94:	f84a                	sd	s2,48(sp)
    80004d96:	f44e                	sd	s3,40(sp)
    80004d98:	f052                	sd	s4,32(sp)
    80004d9a:	ec56                	sd	s5,24(sp)
    80004d9c:	e85a                	sd	s6,16(sp)
    80004d9e:	0880                	addi	s0,sp,80
    80004da0:	84aa                	mv	s1,a0
    80004da2:	892e                	mv	s2,a1
    80004da4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	f4a080e7          	jalr	-182(ra) # 80001cf0 <myproc>
    80004dae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004db0:	8b26                	mv	s6,s1
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	e30080e7          	jalr	-464(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbc:	2184a703          	lw	a4,536(s1)
    80004dc0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc8:	02f71463          	bne	a4,a5,80004df0 <piperead+0x64>
    80004dcc:	2244a783          	lw	a5,548(s1)
    80004dd0:	c385                	beqz	a5,80004df0 <piperead+0x64>
    if(pr->killed){
    80004dd2:	028a2783          	lw	a5,40(s4)
    80004dd6:	ebc1                	bnez	a5,80004e66 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd8:	85da                	mv	a1,s6
    80004dda:	854e                	mv	a0,s3
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	5aa080e7          	jalr	1450(ra) # 80002386 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de4:	2184a703          	lw	a4,536(s1)
    80004de8:	21c4a783          	lw	a5,540(s1)
    80004dec:	fef700e3          	beq	a4,a5,80004dcc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df0:	09505263          	blez	s5,80004e74 <piperead+0xe8>
    80004df4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004df8:	2184a783          	lw	a5,536(s1)
    80004dfc:	21c4a703          	lw	a4,540(s1)
    80004e00:	02f70d63          	beq	a4,a5,80004e3a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e04:	0017871b          	addiw	a4,a5,1
    80004e08:	20e4ac23          	sw	a4,536(s1)
    80004e0c:	1ff7f793          	andi	a5,a5,511
    80004e10:	97a6                	add	a5,a5,s1
    80004e12:	0187c783          	lbu	a5,24(a5)
    80004e16:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e1a:	4685                	li	a3,1
    80004e1c:	fbf40613          	addi	a2,s0,-65
    80004e20:	85ca                	mv	a1,s2
    80004e22:	068a3503          	ld	a0,104(s4)
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	84c080e7          	jalr	-1972(ra) # 80001672 <copyout>
    80004e2e:	01650663          	beq	a0,s6,80004e3a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e32:	2985                	addiw	s3,s3,1
    80004e34:	0905                	addi	s2,s2,1
    80004e36:	fd3a91e3          	bne	s5,s3,80004df8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e3a:	21c48513          	addi	a0,s1,540
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	6ee080e7          	jalr	1774(ra) # 8000252c <wakeup>
  release(&pi->lock);
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
  return i;
}
    80004e50:	854e                	mv	a0,s3
    80004e52:	60a6                	ld	ra,72(sp)
    80004e54:	6406                	ld	s0,64(sp)
    80004e56:	74e2                	ld	s1,56(sp)
    80004e58:	7942                	ld	s2,48(sp)
    80004e5a:	79a2                	ld	s3,40(sp)
    80004e5c:	7a02                	ld	s4,32(sp)
    80004e5e:	6ae2                	ld	s5,24(sp)
    80004e60:	6b42                	ld	s6,16(sp)
    80004e62:	6161                	addi	sp,sp,80
    80004e64:	8082                	ret
      release(&pi->lock);
    80004e66:	8526                	mv	a0,s1
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
      return -1;
    80004e70:	59fd                	li	s3,-1
    80004e72:	bff9                	j	80004e50 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e74:	4981                	li	s3,0
    80004e76:	b7d1                	j	80004e3a <piperead+0xae>

0000000080004e78 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e78:	df010113          	addi	sp,sp,-528
    80004e7c:	20113423          	sd	ra,520(sp)
    80004e80:	20813023          	sd	s0,512(sp)
    80004e84:	ffa6                	sd	s1,504(sp)
    80004e86:	fbca                	sd	s2,496(sp)
    80004e88:	f7ce                	sd	s3,488(sp)
    80004e8a:	f3d2                	sd	s4,480(sp)
    80004e8c:	efd6                	sd	s5,472(sp)
    80004e8e:	ebda                	sd	s6,464(sp)
    80004e90:	e7de                	sd	s7,456(sp)
    80004e92:	e3e2                	sd	s8,448(sp)
    80004e94:	ff66                	sd	s9,440(sp)
    80004e96:	fb6a                	sd	s10,432(sp)
    80004e98:	f76e                	sd	s11,424(sp)
    80004e9a:	0c00                	addi	s0,sp,528
    80004e9c:	84aa                	mv	s1,a0
    80004e9e:	dea43c23          	sd	a0,-520(s0)
    80004ea2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	e4a080e7          	jalr	-438(ra) # 80001cf0 <myproc>
    80004eae:	892a                	mv	s2,a0

  begin_op();
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	49c080e7          	jalr	1180(ra) # 8000434c <begin_op>

  if((ip = namei(path)) == 0){
    80004eb8:	8526                	mv	a0,s1
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	276080e7          	jalr	630(ra) # 80004130 <namei>
    80004ec2:	c92d                	beqz	a0,80004f34 <exec+0xbc>
    80004ec4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ec6:	fffff097          	auipc	ra,0xfffff
    80004eca:	ab4080e7          	jalr	-1356(ra) # 8000397a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ece:	04000713          	li	a4,64
    80004ed2:	4681                	li	a3,0
    80004ed4:	e5040613          	addi	a2,s0,-432
    80004ed8:	4581                	li	a1,0
    80004eda:	8526                	mv	a0,s1
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	d52080e7          	jalr	-686(ra) # 80003c2e <readi>
    80004ee4:	04000793          	li	a5,64
    80004ee8:	00f51a63          	bne	a0,a5,80004efc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004eec:	e5042703          	lw	a4,-432(s0)
    80004ef0:	464c47b7          	lui	a5,0x464c4
    80004ef4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ef8:	04f70463          	beq	a4,a5,80004f40 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004efc:	8526                	mv	a0,s1
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	cde080e7          	jalr	-802(ra) # 80003bdc <iunlockput>
    end_op();
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	4c6080e7          	jalr	1222(ra) # 800043cc <end_op>
  }
  return -1;
    80004f0e:	557d                	li	a0,-1
}
    80004f10:	20813083          	ld	ra,520(sp)
    80004f14:	20013403          	ld	s0,512(sp)
    80004f18:	74fe                	ld	s1,504(sp)
    80004f1a:	795e                	ld	s2,496(sp)
    80004f1c:	79be                	ld	s3,488(sp)
    80004f1e:	7a1e                	ld	s4,480(sp)
    80004f20:	6afe                	ld	s5,472(sp)
    80004f22:	6b5e                	ld	s6,464(sp)
    80004f24:	6bbe                	ld	s7,456(sp)
    80004f26:	6c1e                	ld	s8,448(sp)
    80004f28:	7cfa                	ld	s9,440(sp)
    80004f2a:	7d5a                	ld	s10,432(sp)
    80004f2c:	7dba                	ld	s11,424(sp)
    80004f2e:	21010113          	addi	sp,sp,528
    80004f32:	8082                	ret
    end_op();
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	498080e7          	jalr	1176(ra) # 800043cc <end_op>
    return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	bfc9                	j	80004f10 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f40:	854a                	mv	a0,s2
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	e72080e7          	jalr	-398(ra) # 80001db4 <proc_pagetable>
    80004f4a:	8baa                	mv	s7,a0
    80004f4c:	d945                	beqz	a0,80004efc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4e:	e7042983          	lw	s3,-400(s0)
    80004f52:	e8845783          	lhu	a5,-376(s0)
    80004f56:	c7ad                	beqz	a5,80004fc0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f58:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f5c:	6c85                	lui	s9,0x1
    80004f5e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f62:	def43823          	sd	a5,-528(s0)
    80004f66:	a42d                	j	80005190 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f68:	00004517          	auipc	a0,0x4
    80004f6c:	84050513          	addi	a0,a0,-1984 # 800087a8 <syscalls+0x298>
    80004f70:	ffffb097          	auipc	ra,0xffffb
    80004f74:	5ce080e7          	jalr	1486(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f78:	8756                	mv	a4,s5
    80004f7a:	012d86bb          	addw	a3,s11,s2
    80004f7e:	4581                	li	a1,0
    80004f80:	8526                	mv	a0,s1
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	cac080e7          	jalr	-852(ra) # 80003c2e <readi>
    80004f8a:	2501                	sext.w	a0,a0
    80004f8c:	1aaa9963          	bne	s5,a0,8000513e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f90:	6785                	lui	a5,0x1
    80004f92:	0127893b          	addw	s2,a5,s2
    80004f96:	77fd                	lui	a5,0xfffff
    80004f98:	01478a3b          	addw	s4,a5,s4
    80004f9c:	1f897163          	bgeu	s2,s8,8000517e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fa0:	02091593          	slli	a1,s2,0x20
    80004fa4:	9181                	srli	a1,a1,0x20
    80004fa6:	95ea                	add	a1,a1,s10
    80004fa8:	855e                	mv	a0,s7
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	0c4080e7          	jalr	196(ra) # 8000106e <walkaddr>
    80004fb2:	862a                	mv	a2,a0
    if(pa == 0)
    80004fb4:	d955                	beqz	a0,80004f68 <exec+0xf0>
      n = PGSIZE;
    80004fb6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fb8:	fd9a70e3          	bgeu	s4,s9,80004f78 <exec+0x100>
      n = sz - i;
    80004fbc:	8ad2                	mv	s5,s4
    80004fbe:	bf6d                	j	80004f78 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fc0:	4901                	li	s2,0
  iunlockput(ip);
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	c18080e7          	jalr	-1000(ra) # 80003bdc <iunlockput>
  end_op();
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	400080e7          	jalr	1024(ra) # 800043cc <end_op>
  p = myproc();
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	d1c080e7          	jalr	-740(ra) # 80001cf0 <myproc>
    80004fdc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fde:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004fe2:	6785                	lui	a5,0x1
    80004fe4:	17fd                	addi	a5,a5,-1
    80004fe6:	993e                	add	s2,s2,a5
    80004fe8:	757d                	lui	a0,0xfffff
    80004fea:	00a977b3          	and	a5,s2,a0
    80004fee:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ff2:	6609                	lui	a2,0x2
    80004ff4:	963e                	add	a2,a2,a5
    80004ff6:	85be                	mv	a1,a5
    80004ff8:	855e                	mv	a0,s7
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	428080e7          	jalr	1064(ra) # 80001422 <uvmalloc>
    80005002:	8b2a                	mv	s6,a0
  ip = 0;
    80005004:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005006:	12050c63          	beqz	a0,8000513e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000500a:	75f9                	lui	a1,0xffffe
    8000500c:	95aa                	add	a1,a1,a0
    8000500e:	855e                	mv	a0,s7
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	630080e7          	jalr	1584(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005018:	7c7d                	lui	s8,0xfffff
    8000501a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000501c:	e0043783          	ld	a5,-512(s0)
    80005020:	6388                	ld	a0,0(a5)
    80005022:	c535                	beqz	a0,8000508e <exec+0x216>
    80005024:	e9040993          	addi	s3,s0,-368
    80005028:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000502c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	e36080e7          	jalr	-458(ra) # 80000e64 <strlen>
    80005036:	2505                	addiw	a0,a0,1
    80005038:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000503c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005040:	13896363          	bltu	s2,s8,80005166 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005044:	e0043d83          	ld	s11,-512(s0)
    80005048:	000dba03          	ld	s4,0(s11)
    8000504c:	8552                	mv	a0,s4
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	e16080e7          	jalr	-490(ra) # 80000e64 <strlen>
    80005056:	0015069b          	addiw	a3,a0,1
    8000505a:	8652                	mv	a2,s4
    8000505c:	85ca                	mv	a1,s2
    8000505e:	855e                	mv	a0,s7
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	612080e7          	jalr	1554(ra) # 80001672 <copyout>
    80005068:	10054363          	bltz	a0,8000516e <exec+0x2f6>
    ustack[argc] = sp;
    8000506c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005070:	0485                	addi	s1,s1,1
    80005072:	008d8793          	addi	a5,s11,8
    80005076:	e0f43023          	sd	a5,-512(s0)
    8000507a:	008db503          	ld	a0,8(s11)
    8000507e:	c911                	beqz	a0,80005092 <exec+0x21a>
    if(argc >= MAXARG)
    80005080:	09a1                	addi	s3,s3,8
    80005082:	fb3c96e3          	bne	s9,s3,8000502e <exec+0x1b6>
  sz = sz1;
    80005086:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000508a:	4481                	li	s1,0
    8000508c:	a84d                	j	8000513e <exec+0x2c6>
  sp = sz;
    8000508e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005090:	4481                	li	s1,0
  ustack[argc] = 0;
    80005092:	00349793          	slli	a5,s1,0x3
    80005096:	f9040713          	addi	a4,s0,-112
    8000509a:	97ba                	add	a5,a5,a4
    8000509c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050a0:	00148693          	addi	a3,s1,1
    800050a4:	068e                	slli	a3,a3,0x3
    800050a6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050aa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050ae:	01897663          	bgeu	s2,s8,800050ba <exec+0x242>
  sz = sz1;
    800050b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050b6:	4481                	li	s1,0
    800050b8:	a059                	j	8000513e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ba:	e9040613          	addi	a2,s0,-368
    800050be:	85ca                	mv	a1,s2
    800050c0:	855e                	mv	a0,s7
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	5b0080e7          	jalr	1456(ra) # 80001672 <copyout>
    800050ca:	0a054663          	bltz	a0,80005176 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050ce:	070ab783          	ld	a5,112(s5)
    800050d2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050d6:	df843783          	ld	a5,-520(s0)
    800050da:	0007c703          	lbu	a4,0(a5)
    800050de:	cf11                	beqz	a4,800050fa <exec+0x282>
    800050e0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050e2:	02f00693          	li	a3,47
    800050e6:	a039                	j	800050f4 <exec+0x27c>
      last = s+1;
    800050e8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050ec:	0785                	addi	a5,a5,1
    800050ee:	fff7c703          	lbu	a4,-1(a5)
    800050f2:	c701                	beqz	a4,800050fa <exec+0x282>
    if(*s == '/')
    800050f4:	fed71ce3          	bne	a4,a3,800050ec <exec+0x274>
    800050f8:	bfc5                	j	800050e8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050fa:	4641                	li	a2,16
    800050fc:	df843583          	ld	a1,-520(s0)
    80005100:	170a8513          	addi	a0,s5,368
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	d2e080e7          	jalr	-722(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000510c:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    80005110:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    80005114:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005118:	070ab783          	ld	a5,112(s5)
    8000511c:	e6843703          	ld	a4,-408(s0)
    80005120:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005122:	070ab783          	ld	a5,112(s5)
    80005126:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000512a:	85ea                	mv	a1,s10
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	d24080e7          	jalr	-732(ra) # 80001e50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005134:	0004851b          	sext.w	a0,s1
    80005138:	bbe1                	j	80004f10 <exec+0x98>
    8000513a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000513e:	e0843583          	ld	a1,-504(s0)
    80005142:	855e                	mv	a0,s7
    80005144:	ffffd097          	auipc	ra,0xffffd
    80005148:	d0c080e7          	jalr	-756(ra) # 80001e50 <proc_freepagetable>
  if(ip){
    8000514c:	da0498e3          	bnez	s1,80004efc <exec+0x84>
  return -1;
    80005150:	557d                	li	a0,-1
    80005152:	bb7d                	j	80004f10 <exec+0x98>
    80005154:	e1243423          	sd	s2,-504(s0)
    80005158:	b7dd                	j	8000513e <exec+0x2c6>
    8000515a:	e1243423          	sd	s2,-504(s0)
    8000515e:	b7c5                	j	8000513e <exec+0x2c6>
    80005160:	e1243423          	sd	s2,-504(s0)
    80005164:	bfe9                	j	8000513e <exec+0x2c6>
  sz = sz1;
    80005166:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516a:	4481                	li	s1,0
    8000516c:	bfc9                	j	8000513e <exec+0x2c6>
  sz = sz1;
    8000516e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005172:	4481                	li	s1,0
    80005174:	b7e9                	j	8000513e <exec+0x2c6>
  sz = sz1;
    80005176:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000517a:	4481                	li	s1,0
    8000517c:	b7c9                	j	8000513e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000517e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005182:	2b05                	addiw	s6,s6,1
    80005184:	0389899b          	addiw	s3,s3,56
    80005188:	e8845783          	lhu	a5,-376(s0)
    8000518c:	e2fb5be3          	bge	s6,a5,80004fc2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005190:	2981                	sext.w	s3,s3
    80005192:	03800713          	li	a4,56
    80005196:	86ce                	mv	a3,s3
    80005198:	e1840613          	addi	a2,s0,-488
    8000519c:	4581                	li	a1,0
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	a8e080e7          	jalr	-1394(ra) # 80003c2e <readi>
    800051a8:	03800793          	li	a5,56
    800051ac:	f8f517e3          	bne	a0,a5,8000513a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051b0:	e1842783          	lw	a5,-488(s0)
    800051b4:	4705                	li	a4,1
    800051b6:	fce796e3          	bne	a5,a4,80005182 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051ba:	e4043603          	ld	a2,-448(s0)
    800051be:	e3843783          	ld	a5,-456(s0)
    800051c2:	f8f669e3          	bltu	a2,a5,80005154 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051c6:	e2843783          	ld	a5,-472(s0)
    800051ca:	963e                	add	a2,a2,a5
    800051cc:	f8f667e3          	bltu	a2,a5,8000515a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d0:	85ca                	mv	a1,s2
    800051d2:	855e                	mv	a0,s7
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	24e080e7          	jalr	590(ra) # 80001422 <uvmalloc>
    800051dc:	e0a43423          	sd	a0,-504(s0)
    800051e0:	d141                	beqz	a0,80005160 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051e2:	e2843d03          	ld	s10,-472(s0)
    800051e6:	df043783          	ld	a5,-528(s0)
    800051ea:	00fd77b3          	and	a5,s10,a5
    800051ee:	fba1                	bnez	a5,8000513e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051f0:	e2042d83          	lw	s11,-480(s0)
    800051f4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051f8:	f80c03e3          	beqz	s8,8000517e <exec+0x306>
    800051fc:	8a62                	mv	s4,s8
    800051fe:	4901                	li	s2,0
    80005200:	b345                	j	80004fa0 <exec+0x128>

0000000080005202 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005202:	7179                	addi	sp,sp,-48
    80005204:	f406                	sd	ra,40(sp)
    80005206:	f022                	sd	s0,32(sp)
    80005208:	ec26                	sd	s1,24(sp)
    8000520a:	e84a                	sd	s2,16(sp)
    8000520c:	1800                	addi	s0,sp,48
    8000520e:	892e                	mv	s2,a1
    80005210:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005212:	fdc40593          	addi	a1,s0,-36
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	b90080e7          	jalr	-1136(ra) # 80002da6 <argint>
    8000521e:	04054063          	bltz	a0,8000525e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005222:	fdc42703          	lw	a4,-36(s0)
    80005226:	47bd                	li	a5,15
    80005228:	02e7ed63          	bltu	a5,a4,80005262 <argfd+0x60>
    8000522c:	ffffd097          	auipc	ra,0xffffd
    80005230:	ac4080e7          	jalr	-1340(ra) # 80001cf0 <myproc>
    80005234:	fdc42703          	lw	a4,-36(s0)
    80005238:	01c70793          	addi	a5,a4,28
    8000523c:	078e                	slli	a5,a5,0x3
    8000523e:	953e                	add	a0,a0,a5
    80005240:	651c                	ld	a5,8(a0)
    80005242:	c395                	beqz	a5,80005266 <argfd+0x64>
    return -1;
  if(pfd)
    80005244:	00090463          	beqz	s2,8000524c <argfd+0x4a>
    *pfd = fd;
    80005248:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000524c:	4501                	li	a0,0
  if(pf)
    8000524e:	c091                	beqz	s1,80005252 <argfd+0x50>
    *pf = f;
    80005250:	e09c                	sd	a5,0(s1)
}
    80005252:	70a2                	ld	ra,40(sp)
    80005254:	7402                	ld	s0,32(sp)
    80005256:	64e2                	ld	s1,24(sp)
    80005258:	6942                	ld	s2,16(sp)
    8000525a:	6145                	addi	sp,sp,48
    8000525c:	8082                	ret
    return -1;
    8000525e:	557d                	li	a0,-1
    80005260:	bfcd                	j	80005252 <argfd+0x50>
    return -1;
    80005262:	557d                	li	a0,-1
    80005264:	b7fd                	j	80005252 <argfd+0x50>
    80005266:	557d                	li	a0,-1
    80005268:	b7ed                	j	80005252 <argfd+0x50>

000000008000526a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000526a:	1101                	addi	sp,sp,-32
    8000526c:	ec06                	sd	ra,24(sp)
    8000526e:	e822                	sd	s0,16(sp)
    80005270:	e426                	sd	s1,8(sp)
    80005272:	1000                	addi	s0,sp,32
    80005274:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005276:	ffffd097          	auipc	ra,0xffffd
    8000527a:	a7a080e7          	jalr	-1414(ra) # 80001cf0 <myproc>
    8000527e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005280:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    80005284:	4501                	li	a0,0
    80005286:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005288:	6398                	ld	a4,0(a5)
    8000528a:	cb19                	beqz	a4,800052a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000528c:	2505                	addiw	a0,a0,1
    8000528e:	07a1                	addi	a5,a5,8
    80005290:	fed51ce3          	bne	a0,a3,80005288 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005294:	557d                	li	a0,-1
}
    80005296:	60e2                	ld	ra,24(sp)
    80005298:	6442                	ld	s0,16(sp)
    8000529a:	64a2                	ld	s1,8(sp)
    8000529c:	6105                	addi	sp,sp,32
    8000529e:	8082                	ret
      p->ofile[fd] = f;
    800052a0:	01c50793          	addi	a5,a0,28
    800052a4:	078e                	slli	a5,a5,0x3
    800052a6:	963e                	add	a2,a2,a5
    800052a8:	e604                	sd	s1,8(a2)
      return fd;
    800052aa:	b7f5                	j	80005296 <fdalloc+0x2c>

00000000800052ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ac:	715d                	addi	sp,sp,-80
    800052ae:	e486                	sd	ra,72(sp)
    800052b0:	e0a2                	sd	s0,64(sp)
    800052b2:	fc26                	sd	s1,56(sp)
    800052b4:	f84a                	sd	s2,48(sp)
    800052b6:	f44e                	sd	s3,40(sp)
    800052b8:	f052                	sd	s4,32(sp)
    800052ba:	ec56                	sd	s5,24(sp)
    800052bc:	0880                	addi	s0,sp,80
    800052be:	89ae                	mv	s3,a1
    800052c0:	8ab2                	mv	s5,a2
    800052c2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052c4:	fb040593          	addi	a1,s0,-80
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	e86080e7          	jalr	-378(ra) # 8000414e <nameiparent>
    800052d0:	892a                	mv	s2,a0
    800052d2:	12050f63          	beqz	a0,80005410 <create+0x164>
    return 0;

  ilock(dp);
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	6a4080e7          	jalr	1700(ra) # 8000397a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052de:	4601                	li	a2,0
    800052e0:	fb040593          	addi	a1,s0,-80
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	b78080e7          	jalr	-1160(ra) # 80003e5e <dirlookup>
    800052ee:	84aa                	mv	s1,a0
    800052f0:	c921                	beqz	a0,80005340 <create+0x94>
    iunlockput(dp);
    800052f2:	854a                	mv	a0,s2
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	8e8080e7          	jalr	-1816(ra) # 80003bdc <iunlockput>
    ilock(ip);
    800052fc:	8526                	mv	a0,s1
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	67c080e7          	jalr	1660(ra) # 8000397a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005306:	2981                	sext.w	s3,s3
    80005308:	4789                	li	a5,2
    8000530a:	02f99463          	bne	s3,a5,80005332 <create+0x86>
    8000530e:	0444d783          	lhu	a5,68(s1)
    80005312:	37f9                	addiw	a5,a5,-2
    80005314:	17c2                	slli	a5,a5,0x30
    80005316:	93c1                	srli	a5,a5,0x30
    80005318:	4705                	li	a4,1
    8000531a:	00f76c63          	bltu	a4,a5,80005332 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000531e:	8526                	mv	a0,s1
    80005320:	60a6                	ld	ra,72(sp)
    80005322:	6406                	ld	s0,64(sp)
    80005324:	74e2                	ld	s1,56(sp)
    80005326:	7942                	ld	s2,48(sp)
    80005328:	79a2                	ld	s3,40(sp)
    8000532a:	7a02                	ld	s4,32(sp)
    8000532c:	6ae2                	ld	s5,24(sp)
    8000532e:	6161                	addi	sp,sp,80
    80005330:	8082                	ret
    iunlockput(ip);
    80005332:	8526                	mv	a0,s1
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	8a8080e7          	jalr	-1880(ra) # 80003bdc <iunlockput>
    return 0;
    8000533c:	4481                	li	s1,0
    8000533e:	b7c5                	j	8000531e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005340:	85ce                	mv	a1,s3
    80005342:	00092503          	lw	a0,0(s2)
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	49c080e7          	jalr	1180(ra) # 800037e2 <ialloc>
    8000534e:	84aa                	mv	s1,a0
    80005350:	c529                	beqz	a0,8000539a <create+0xee>
  ilock(ip);
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	628080e7          	jalr	1576(ra) # 8000397a <ilock>
  ip->major = major;
    8000535a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000535e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005362:	4785                	li	a5,1
    80005364:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005368:	8526                	mv	a0,s1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	546080e7          	jalr	1350(ra) # 800038b0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005372:	2981                	sext.w	s3,s3
    80005374:	4785                	li	a5,1
    80005376:	02f98a63          	beq	s3,a5,800053aa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000537a:	40d0                	lw	a2,4(s1)
    8000537c:	fb040593          	addi	a1,s0,-80
    80005380:	854a                	mv	a0,s2
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	cec080e7          	jalr	-788(ra) # 8000406e <dirlink>
    8000538a:	06054b63          	bltz	a0,80005400 <create+0x154>
  iunlockput(dp);
    8000538e:	854a                	mv	a0,s2
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	84c080e7          	jalr	-1972(ra) # 80003bdc <iunlockput>
  return ip;
    80005398:	b759                	j	8000531e <create+0x72>
    panic("create: ialloc");
    8000539a:	00003517          	auipc	a0,0x3
    8000539e:	42e50513          	addi	a0,a0,1070 # 800087c8 <syscalls+0x2b8>
    800053a2:	ffffb097          	auipc	ra,0xffffb
    800053a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053aa:	04a95783          	lhu	a5,74(s2)
    800053ae:	2785                	addiw	a5,a5,1
    800053b0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053b4:	854a                	mv	a0,s2
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	4fa080e7          	jalr	1274(ra) # 800038b0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053be:	40d0                	lw	a2,4(s1)
    800053c0:	00003597          	auipc	a1,0x3
    800053c4:	41858593          	addi	a1,a1,1048 # 800087d8 <syscalls+0x2c8>
    800053c8:	8526                	mv	a0,s1
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	ca4080e7          	jalr	-860(ra) # 8000406e <dirlink>
    800053d2:	00054f63          	bltz	a0,800053f0 <create+0x144>
    800053d6:	00492603          	lw	a2,4(s2)
    800053da:	00003597          	auipc	a1,0x3
    800053de:	40658593          	addi	a1,a1,1030 # 800087e0 <syscalls+0x2d0>
    800053e2:	8526                	mv	a0,s1
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	c8a080e7          	jalr	-886(ra) # 8000406e <dirlink>
    800053ec:	f80557e3          	bgez	a0,8000537a <create+0xce>
      panic("create dots");
    800053f0:	00003517          	auipc	a0,0x3
    800053f4:	3f850513          	addi	a0,a0,1016 # 800087e8 <syscalls+0x2d8>
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005400:	00003517          	auipc	a0,0x3
    80005404:	3f850513          	addi	a0,a0,1016 # 800087f8 <syscalls+0x2e8>
    80005408:	ffffb097          	auipc	ra,0xffffb
    8000540c:	136080e7          	jalr	310(ra) # 8000053e <panic>
    return 0;
    80005410:	84aa                	mv	s1,a0
    80005412:	b731                	j	8000531e <create+0x72>

0000000080005414 <sys_dup>:
{
    80005414:	7179                	addi	sp,sp,-48
    80005416:	f406                	sd	ra,40(sp)
    80005418:	f022                	sd	s0,32(sp)
    8000541a:	ec26                	sd	s1,24(sp)
    8000541c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000541e:	fd840613          	addi	a2,s0,-40
    80005422:	4581                	li	a1,0
    80005424:	4501                	li	a0,0
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	ddc080e7          	jalr	-548(ra) # 80005202 <argfd>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005430:	02054363          	bltz	a0,80005456 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005434:	fd843503          	ld	a0,-40(s0)
    80005438:	00000097          	auipc	ra,0x0
    8000543c:	e32080e7          	jalr	-462(ra) # 8000526a <fdalloc>
    80005440:	84aa                	mv	s1,a0
    return -1;
    80005442:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005444:	00054963          	bltz	a0,80005456 <sys_dup+0x42>
  filedup(f);
    80005448:	fd843503          	ld	a0,-40(s0)
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	37a080e7          	jalr	890(ra) # 800047c6 <filedup>
  return fd;
    80005454:	87a6                	mv	a5,s1
}
    80005456:	853e                	mv	a0,a5
    80005458:	70a2                	ld	ra,40(sp)
    8000545a:	7402                	ld	s0,32(sp)
    8000545c:	64e2                	ld	s1,24(sp)
    8000545e:	6145                	addi	sp,sp,48
    80005460:	8082                	ret

0000000080005462 <sys_read>:
{
    80005462:	7179                	addi	sp,sp,-48
    80005464:	f406                	sd	ra,40(sp)
    80005466:	f022                	sd	s0,32(sp)
    80005468:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546a:	fe840613          	addi	a2,s0,-24
    8000546e:	4581                	li	a1,0
    80005470:	4501                	li	a0,0
    80005472:	00000097          	auipc	ra,0x0
    80005476:	d90080e7          	jalr	-624(ra) # 80005202 <argfd>
    return -1;
    8000547a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547c:	04054163          	bltz	a0,800054be <sys_read+0x5c>
    80005480:	fe440593          	addi	a1,s0,-28
    80005484:	4509                	li	a0,2
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	920080e7          	jalr	-1760(ra) # 80002da6 <argint>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005490:	02054763          	bltz	a0,800054be <sys_read+0x5c>
    80005494:	fd840593          	addi	a1,s0,-40
    80005498:	4505                	li	a0,1
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	92e080e7          	jalr	-1746(ra) # 80002dc8 <argaddr>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a4:	00054d63          	bltz	a0,800054be <sys_read+0x5c>
  return fileread(f, p, n);
    800054a8:	fe442603          	lw	a2,-28(s0)
    800054ac:	fd843583          	ld	a1,-40(s0)
    800054b0:	fe843503          	ld	a0,-24(s0)
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	49e080e7          	jalr	1182(ra) # 80004952 <fileread>
    800054bc:	87aa                	mv	a5,a0
}
    800054be:	853e                	mv	a0,a5
    800054c0:	70a2                	ld	ra,40(sp)
    800054c2:	7402                	ld	s0,32(sp)
    800054c4:	6145                	addi	sp,sp,48
    800054c6:	8082                	ret

00000000800054c8 <sys_write>:
{
    800054c8:	7179                	addi	sp,sp,-48
    800054ca:	f406                	sd	ra,40(sp)
    800054cc:	f022                	sd	s0,32(sp)
    800054ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	fe840613          	addi	a2,s0,-24
    800054d4:	4581                	li	a1,0
    800054d6:	4501                	li	a0,0
    800054d8:	00000097          	auipc	ra,0x0
    800054dc:	d2a080e7          	jalr	-726(ra) # 80005202 <argfd>
    return -1;
    800054e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e2:	04054163          	bltz	a0,80005524 <sys_write+0x5c>
    800054e6:	fe440593          	addi	a1,s0,-28
    800054ea:	4509                	li	a0,2
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	8ba080e7          	jalr	-1862(ra) # 80002da6 <argint>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f6:	02054763          	bltz	a0,80005524 <sys_write+0x5c>
    800054fa:	fd840593          	addi	a1,s0,-40
    800054fe:	4505                	li	a0,1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	8c8080e7          	jalr	-1848(ra) # 80002dc8 <argaddr>
    return -1;
    80005508:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550a:	00054d63          	bltz	a0,80005524 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000550e:	fe442603          	lw	a2,-28(s0)
    80005512:	fd843583          	ld	a1,-40(s0)
    80005516:	fe843503          	ld	a0,-24(s0)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	4fa080e7          	jalr	1274(ra) # 80004a14 <filewrite>
    80005522:	87aa                	mv	a5,a0
}
    80005524:	853e                	mv	a0,a5
    80005526:	70a2                	ld	ra,40(sp)
    80005528:	7402                	ld	s0,32(sp)
    8000552a:	6145                	addi	sp,sp,48
    8000552c:	8082                	ret

000000008000552e <sys_close>:
{
    8000552e:	1101                	addi	sp,sp,-32
    80005530:	ec06                	sd	ra,24(sp)
    80005532:	e822                	sd	s0,16(sp)
    80005534:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005536:	fe040613          	addi	a2,s0,-32
    8000553a:	fec40593          	addi	a1,s0,-20
    8000553e:	4501                	li	a0,0
    80005540:	00000097          	auipc	ra,0x0
    80005544:	cc2080e7          	jalr	-830(ra) # 80005202 <argfd>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000554a:	02054463          	bltz	a0,80005572 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000554e:	ffffc097          	auipc	ra,0xffffc
    80005552:	7a2080e7          	jalr	1954(ra) # 80001cf0 <myproc>
    80005556:	fec42783          	lw	a5,-20(s0)
    8000555a:	07f1                	addi	a5,a5,28
    8000555c:	078e                	slli	a5,a5,0x3
    8000555e:	97aa                	add	a5,a5,a0
    80005560:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005564:	fe043503          	ld	a0,-32(s0)
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	2b0080e7          	jalr	688(ra) # 80004818 <fileclose>
  return 0;
    80005570:	4781                	li	a5,0
}
    80005572:	853e                	mv	a0,a5
    80005574:	60e2                	ld	ra,24(sp)
    80005576:	6442                	ld	s0,16(sp)
    80005578:	6105                	addi	sp,sp,32
    8000557a:	8082                	ret

000000008000557c <sys_fstat>:
{
    8000557c:	1101                	addi	sp,sp,-32
    8000557e:	ec06                	sd	ra,24(sp)
    80005580:	e822                	sd	s0,16(sp)
    80005582:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005584:	fe840613          	addi	a2,s0,-24
    80005588:	4581                	li	a1,0
    8000558a:	4501                	li	a0,0
    8000558c:	00000097          	auipc	ra,0x0
    80005590:	c76080e7          	jalr	-906(ra) # 80005202 <argfd>
    return -1;
    80005594:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005596:	02054563          	bltz	a0,800055c0 <sys_fstat+0x44>
    8000559a:	fe040593          	addi	a1,s0,-32
    8000559e:	4505                	li	a0,1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	828080e7          	jalr	-2008(ra) # 80002dc8 <argaddr>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055aa:	00054b63          	bltz	a0,800055c0 <sys_fstat+0x44>
  return filestat(f, st);
    800055ae:	fe043583          	ld	a1,-32(s0)
    800055b2:	fe843503          	ld	a0,-24(s0)
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	32a080e7          	jalr	810(ra) # 800048e0 <filestat>
    800055be:	87aa                	mv	a5,a0
}
    800055c0:	853e                	mv	a0,a5
    800055c2:	60e2                	ld	ra,24(sp)
    800055c4:	6442                	ld	s0,16(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret

00000000800055ca <sys_link>:
{
    800055ca:	7169                	addi	sp,sp,-304
    800055cc:	f606                	sd	ra,296(sp)
    800055ce:	f222                	sd	s0,288(sp)
    800055d0:	ee26                	sd	s1,280(sp)
    800055d2:	ea4a                	sd	s2,272(sp)
    800055d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d6:	08000613          	li	a2,128
    800055da:	ed040593          	addi	a1,s0,-304
    800055de:	4501                	li	a0,0
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	80a080e7          	jalr	-2038(ra) # 80002dea <argstr>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ea:	10054e63          	bltz	a0,80005706 <sys_link+0x13c>
    800055ee:	08000613          	li	a2,128
    800055f2:	f5040593          	addi	a1,s0,-176
    800055f6:	4505                	li	a0,1
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	7f2080e7          	jalr	2034(ra) # 80002dea <argstr>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005602:	10054263          	bltz	a0,80005706 <sys_link+0x13c>
  begin_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	d46080e7          	jalr	-698(ra) # 8000434c <begin_op>
  if((ip = namei(old)) == 0){
    8000560e:	ed040513          	addi	a0,s0,-304
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	b1e080e7          	jalr	-1250(ra) # 80004130 <namei>
    8000561a:	84aa                	mv	s1,a0
    8000561c:	c551                	beqz	a0,800056a8 <sys_link+0xde>
  ilock(ip);
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	35c080e7          	jalr	860(ra) # 8000397a <ilock>
  if(ip->type == T_DIR){
    80005626:	04449703          	lh	a4,68(s1)
    8000562a:	4785                	li	a5,1
    8000562c:	08f70463          	beq	a4,a5,800056b4 <sys_link+0xea>
  ip->nlink++;
    80005630:	04a4d783          	lhu	a5,74(s1)
    80005634:	2785                	addiw	a5,a5,1
    80005636:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	274080e7          	jalr	628(ra) # 800038b0 <iupdate>
  iunlock(ip);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3f6080e7          	jalr	1014(ra) # 80003a3c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000564e:	fd040593          	addi	a1,s0,-48
    80005652:	f5040513          	addi	a0,s0,-176
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	af8080e7          	jalr	-1288(ra) # 8000414e <nameiparent>
    8000565e:	892a                	mv	s2,a0
    80005660:	c935                	beqz	a0,800056d4 <sys_link+0x10a>
  ilock(dp);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	318080e7          	jalr	792(ra) # 8000397a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000566a:	00092703          	lw	a4,0(s2)
    8000566e:	409c                	lw	a5,0(s1)
    80005670:	04f71d63          	bne	a4,a5,800056ca <sys_link+0x100>
    80005674:	40d0                	lw	a2,4(s1)
    80005676:	fd040593          	addi	a1,s0,-48
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	9f2080e7          	jalr	-1550(ra) # 8000406e <dirlink>
    80005684:	04054363          	bltz	a0,800056ca <sys_link+0x100>
  iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	552080e7          	jalr	1362(ra) # 80003bdc <iunlockput>
  iput(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	4a0080e7          	jalr	1184(ra) # 80003b34 <iput>
  end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	d30080e7          	jalr	-720(ra) # 800043cc <end_op>
  return 0;
    800056a4:	4781                	li	a5,0
    800056a6:	a085                	j	80005706 <sys_link+0x13c>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	d24080e7          	jalr	-732(ra) # 800043cc <end_op>
    return -1;
    800056b0:	57fd                	li	a5,-1
    800056b2:	a891                	j	80005706 <sys_link+0x13c>
    iunlockput(ip);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	526080e7          	jalr	1318(ra) # 80003bdc <iunlockput>
    end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	d0e080e7          	jalr	-754(ra) # 800043cc <end_op>
    return -1;
    800056c6:	57fd                	li	a5,-1
    800056c8:	a83d                	j	80005706 <sys_link+0x13c>
    iunlockput(dp);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	510080e7          	jalr	1296(ra) # 80003bdc <iunlockput>
  ilock(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	2a4080e7          	jalr	676(ra) # 8000397a <ilock>
  ip->nlink--;
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	1c6080e7          	jalr	454(ra) # 800038b0 <iupdate>
  iunlockput(ip);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	4e8080e7          	jalr	1256(ra) # 80003bdc <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	cd0080e7          	jalr	-816(ra) # 800043cc <end_op>
  return -1;
    80005704:	57fd                	li	a5,-1
}
    80005706:	853e                	mv	a0,a5
    80005708:	70b2                	ld	ra,296(sp)
    8000570a:	7412                	ld	s0,288(sp)
    8000570c:	64f2                	ld	s1,280(sp)
    8000570e:	6952                	ld	s2,272(sp)
    80005710:	6155                	addi	sp,sp,304
    80005712:	8082                	ret

0000000080005714 <sys_unlink>:
{
    80005714:	7151                	addi	sp,sp,-240
    80005716:	f586                	sd	ra,232(sp)
    80005718:	f1a2                	sd	s0,224(sp)
    8000571a:	eda6                	sd	s1,216(sp)
    8000571c:	e9ca                	sd	s2,208(sp)
    8000571e:	e5ce                	sd	s3,200(sp)
    80005720:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005722:	08000613          	li	a2,128
    80005726:	f3040593          	addi	a1,s0,-208
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	6be080e7          	jalr	1726(ra) # 80002dea <argstr>
    80005734:	18054163          	bltz	a0,800058b6 <sys_unlink+0x1a2>
  begin_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	c14080e7          	jalr	-1004(ra) # 8000434c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005740:	fb040593          	addi	a1,s0,-80
    80005744:	f3040513          	addi	a0,s0,-208
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	a06080e7          	jalr	-1530(ra) # 8000414e <nameiparent>
    80005750:	84aa                	mv	s1,a0
    80005752:	c979                	beqz	a0,80005828 <sys_unlink+0x114>
  ilock(dp);
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	226080e7          	jalr	550(ra) # 8000397a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000575c:	00003597          	auipc	a1,0x3
    80005760:	07c58593          	addi	a1,a1,124 # 800087d8 <syscalls+0x2c8>
    80005764:	fb040513          	addi	a0,s0,-80
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	6dc080e7          	jalr	1756(ra) # 80003e44 <namecmp>
    80005770:	14050a63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
    80005774:	00003597          	auipc	a1,0x3
    80005778:	06c58593          	addi	a1,a1,108 # 800087e0 <syscalls+0x2d0>
    8000577c:	fb040513          	addi	a0,s0,-80
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	6c4080e7          	jalr	1732(ra) # 80003e44 <namecmp>
    80005788:	12050e63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000578c:	f2c40613          	addi	a2,s0,-212
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	6c8080e7          	jalr	1736(ra) # 80003e5e <dirlookup>
    8000579e:	892a                	mv	s2,a0
    800057a0:	12050263          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  ilock(ip);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	1d6080e7          	jalr	470(ra) # 8000397a <ilock>
  if(ip->nlink < 1)
    800057ac:	04a91783          	lh	a5,74(s2)
    800057b0:	08f05263          	blez	a5,80005834 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057b4:	04491703          	lh	a4,68(s2)
    800057b8:	4785                	li	a5,1
    800057ba:	08f70563          	beq	a4,a5,80005844 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057be:	4641                	li	a2,16
    800057c0:	4581                	li	a1,0
    800057c2:	fc040513          	addi	a0,s0,-64
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	51a080e7          	jalr	1306(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ce:	4741                	li	a4,16
    800057d0:	f2c42683          	lw	a3,-212(s0)
    800057d4:	fc040613          	addi	a2,s0,-64
    800057d8:	4581                	li	a1,0
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	54a080e7          	jalr	1354(ra) # 80003d26 <writei>
    800057e4:	47c1                	li	a5,16
    800057e6:	0af51563          	bne	a0,a5,80005890 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4785                	li	a5,1
    800057f0:	0af70863          	beq	a4,a5,800058a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	3e6080e7          	jalr	998(ra) # 80003bdc <iunlockput>
  ip->nlink--;
    800057fe:	04a95783          	lhu	a5,74(s2)
    80005802:	37fd                	addiw	a5,a5,-1
    80005804:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	0a6080e7          	jalr	166(ra) # 800038b0 <iupdate>
  iunlockput(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	3c8080e7          	jalr	968(ra) # 80003bdc <iunlockput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	bb0080e7          	jalr	-1104(ra) # 800043cc <end_op>
  return 0;
    80005824:	4501                	li	a0,0
    80005826:	a84d                	j	800058d8 <sys_unlink+0x1c4>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	ba4080e7          	jalr	-1116(ra) # 800043cc <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	a05d                	j	800058d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005834:	00003517          	auipc	a0,0x3
    80005838:	fd450513          	addi	a0,a0,-44 # 80008808 <syscalls+0x2f8>
    8000583c:	ffffb097          	auipc	ra,0xffffb
    80005840:	d02080e7          	jalr	-766(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005844:	04c92703          	lw	a4,76(s2)
    80005848:	02000793          	li	a5,32
    8000584c:	f6e7f9e3          	bgeu	a5,a4,800057be <sys_unlink+0xaa>
    80005850:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005854:	4741                	li	a4,16
    80005856:	86ce                	mv	a3,s3
    80005858:	f1840613          	addi	a2,s0,-232
    8000585c:	4581                	li	a1,0
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	3ce080e7          	jalr	974(ra) # 80003c2e <readi>
    80005868:	47c1                	li	a5,16
    8000586a:	00f51b63          	bne	a0,a5,80005880 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000586e:	f1845783          	lhu	a5,-232(s0)
    80005872:	e7a1                	bnez	a5,800058ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005874:	29c1                	addiw	s3,s3,16
    80005876:	04c92783          	lw	a5,76(s2)
    8000587a:	fcf9ede3          	bltu	s3,a5,80005854 <sys_unlink+0x140>
    8000587e:	b781                	j	800057be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	fa050513          	addi	a0,a0,-96 # 80008820 <syscalls+0x310>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005890:	00003517          	auipc	a0,0x3
    80005894:	fa850513          	addi	a0,a0,-88 # 80008838 <syscalls+0x328>
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>
    dp->nlink--;
    800058a0:	04a4d783          	lhu	a5,74(s1)
    800058a4:	37fd                	addiw	a5,a5,-1
    800058a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	004080e7          	jalr	4(ra) # 800038b0 <iupdate>
    800058b4:	b781                	j	800057f4 <sys_unlink+0xe0>
    return -1;
    800058b6:	557d                	li	a0,-1
    800058b8:	a005                	j	800058d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	320080e7          	jalr	800(ra) # 80003bdc <iunlockput>
  iunlockput(dp);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	316080e7          	jalr	790(ra) # 80003bdc <iunlockput>
  end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	afe080e7          	jalr	-1282(ra) # 800043cc <end_op>
  return -1;
    800058d6:	557d                	li	a0,-1
}
    800058d8:	70ae                	ld	ra,232(sp)
    800058da:	740e                	ld	s0,224(sp)
    800058dc:	64ee                	ld	s1,216(sp)
    800058de:	694e                	ld	s2,208(sp)
    800058e0:	69ae                	ld	s3,200(sp)
    800058e2:	616d                	addi	sp,sp,240
    800058e4:	8082                	ret

00000000800058e6 <sys_open>:

uint64
sys_open(void)
{
    800058e6:	7131                	addi	sp,sp,-192
    800058e8:	fd06                	sd	ra,184(sp)
    800058ea:	f922                	sd	s0,176(sp)
    800058ec:	f526                	sd	s1,168(sp)
    800058ee:	f14a                	sd	s2,160(sp)
    800058f0:	ed4e                	sd	s3,152(sp)
    800058f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f4:	08000613          	li	a2,128
    800058f8:	f5040593          	addi	a1,s0,-176
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	4ec080e7          	jalr	1260(ra) # 80002dea <argstr>
    return -1;
    80005906:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005908:	0c054163          	bltz	a0,800059ca <sys_open+0xe4>
    8000590c:	f4c40593          	addi	a1,s0,-180
    80005910:	4505                	li	a0,1
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	494080e7          	jalr	1172(ra) # 80002da6 <argint>
    8000591a:	0a054863          	bltz	a0,800059ca <sys_open+0xe4>

  begin_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	a2e080e7          	jalr	-1490(ra) # 8000434c <begin_op>

  if(omode & O_CREATE){
    80005926:	f4c42783          	lw	a5,-180(s0)
    8000592a:	2007f793          	andi	a5,a5,512
    8000592e:	cbdd                	beqz	a5,800059e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005930:	4681                	li	a3,0
    80005932:	4601                	li	a2,0
    80005934:	4589                	li	a1,2
    80005936:	f5040513          	addi	a0,s0,-176
    8000593a:	00000097          	auipc	ra,0x0
    8000593e:	972080e7          	jalr	-1678(ra) # 800052ac <create>
    80005942:	892a                	mv	s2,a0
    if(ip == 0){
    80005944:	c959                	beqz	a0,800059da <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005946:	04491703          	lh	a4,68(s2)
    8000594a:	478d                	li	a5,3
    8000594c:	00f71763          	bne	a4,a5,8000595a <sys_open+0x74>
    80005950:	04695703          	lhu	a4,70(s2)
    80005954:	47a5                	li	a5,9
    80005956:	0ce7ec63          	bltu	a5,a4,80005a2e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	e02080e7          	jalr	-510(ra) # 8000475c <filealloc>
    80005962:	89aa                	mv	s3,a0
    80005964:	10050263          	beqz	a0,80005a68 <sys_open+0x182>
    80005968:	00000097          	auipc	ra,0x0
    8000596c:	902080e7          	jalr	-1790(ra) # 8000526a <fdalloc>
    80005970:	84aa                	mv	s1,a0
    80005972:	0e054663          	bltz	a0,80005a5e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005976:	04491703          	lh	a4,68(s2)
    8000597a:	478d                	li	a5,3
    8000597c:	0cf70463          	beq	a4,a5,80005a44 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005980:	4789                	li	a5,2
    80005982:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005986:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000598a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000598e:	f4c42783          	lw	a5,-180(s0)
    80005992:	0017c713          	xori	a4,a5,1
    80005996:	8b05                	andi	a4,a4,1
    80005998:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000599c:	0037f713          	andi	a4,a5,3
    800059a0:	00e03733          	snez	a4,a4
    800059a4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059a8:	4007f793          	andi	a5,a5,1024
    800059ac:	c791                	beqz	a5,800059b8 <sys_open+0xd2>
    800059ae:	04491703          	lh	a4,68(s2)
    800059b2:	4789                	li	a5,2
    800059b4:	08f70f63          	beq	a4,a5,80005a52 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	082080e7          	jalr	130(ra) # 80003a3c <iunlock>
  end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	a0a080e7          	jalr	-1526(ra) # 800043cc <end_op>

  return fd;
}
    800059ca:	8526                	mv	a0,s1
    800059cc:	70ea                	ld	ra,184(sp)
    800059ce:	744a                	ld	s0,176(sp)
    800059d0:	74aa                	ld	s1,168(sp)
    800059d2:	790a                	ld	s2,160(sp)
    800059d4:	69ea                	ld	s3,152(sp)
    800059d6:	6129                	addi	sp,sp,192
    800059d8:	8082                	ret
      end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	9f2080e7          	jalr	-1550(ra) # 800043cc <end_op>
      return -1;
    800059e2:	b7e5                	j	800059ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059e4:	f5040513          	addi	a0,s0,-176
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	748080e7          	jalr	1864(ra) # 80004130 <namei>
    800059f0:	892a                	mv	s2,a0
    800059f2:	c905                	beqz	a0,80005a22 <sys_open+0x13c>
    ilock(ip);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	f86080e7          	jalr	-122(ra) # 8000397a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059fc:	04491703          	lh	a4,68(s2)
    80005a00:	4785                	li	a5,1
    80005a02:	f4f712e3          	bne	a4,a5,80005946 <sys_open+0x60>
    80005a06:	f4c42783          	lw	a5,-180(s0)
    80005a0a:	dba1                	beqz	a5,8000595a <sys_open+0x74>
      iunlockput(ip);
    80005a0c:	854a                	mv	a0,s2
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	1ce080e7          	jalr	462(ra) # 80003bdc <iunlockput>
      end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	9b6080e7          	jalr	-1610(ra) # 800043cc <end_op>
      return -1;
    80005a1e:	54fd                	li	s1,-1
    80005a20:	b76d                	j	800059ca <sys_open+0xe4>
      end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	9aa080e7          	jalr	-1622(ra) # 800043cc <end_op>
      return -1;
    80005a2a:	54fd                	li	s1,-1
    80005a2c:	bf79                	j	800059ca <sys_open+0xe4>
    iunlockput(ip);
    80005a2e:	854a                	mv	a0,s2
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	1ac080e7          	jalr	428(ra) # 80003bdc <iunlockput>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	994080e7          	jalr	-1644(ra) # 800043cc <end_op>
    return -1;
    80005a40:	54fd                	li	s1,-1
    80005a42:	b761                	j	800059ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a44:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a48:	04691783          	lh	a5,70(s2)
    80005a4c:	02f99223          	sh	a5,36(s3)
    80005a50:	bf2d                	j	8000598a <sys_open+0xa4>
    itrunc(ip);
    80005a52:	854a                	mv	a0,s2
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	034080e7          	jalr	52(ra) # 80003a88 <itrunc>
    80005a5c:	bfb1                	j	800059b8 <sys_open+0xd2>
      fileclose(f);
    80005a5e:	854e                	mv	a0,s3
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	db8080e7          	jalr	-584(ra) # 80004818 <fileclose>
    iunlockput(ip);
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	172080e7          	jalr	370(ra) # 80003bdc <iunlockput>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	95a080e7          	jalr	-1702(ra) # 800043cc <end_op>
    return -1;
    80005a7a:	54fd                	li	s1,-1
    80005a7c:	b7b9                	j	800059ca <sys_open+0xe4>

0000000080005a7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a7e:	7175                	addi	sp,sp,-144
    80005a80:	e506                	sd	ra,136(sp)
    80005a82:	e122                	sd	s0,128(sp)
    80005a84:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	8c6080e7          	jalr	-1850(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a8e:	08000613          	li	a2,128
    80005a92:	f7040593          	addi	a1,s0,-144
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	352080e7          	jalr	850(ra) # 80002dea <argstr>
    80005aa0:	02054963          	bltz	a0,80005ad2 <sys_mkdir+0x54>
    80005aa4:	4681                	li	a3,0
    80005aa6:	4601                	li	a2,0
    80005aa8:	4585                	li	a1,1
    80005aaa:	f7040513          	addi	a0,s0,-144
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	7fe080e7          	jalr	2046(ra) # 800052ac <create>
    80005ab6:	cd11                	beqz	a0,80005ad2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	124080e7          	jalr	292(ra) # 80003bdc <iunlockput>
  end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	90c080e7          	jalr	-1780(ra) # 800043cc <end_op>
  return 0;
    80005ac8:	4501                	li	a0,0
}
    80005aca:	60aa                	ld	ra,136(sp)
    80005acc:	640a                	ld	s0,128(sp)
    80005ace:	6149                	addi	sp,sp,144
    80005ad0:	8082                	ret
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	8fa080e7          	jalr	-1798(ra) # 800043cc <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	b7fd                	j	80005aca <sys_mkdir+0x4c>

0000000080005ade <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ade:	7135                	addi	sp,sp,-160
    80005ae0:	ed06                	sd	ra,152(sp)
    80005ae2:	e922                	sd	s0,144(sp)
    80005ae4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	866080e7          	jalr	-1946(ra) # 8000434c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aee:	08000613          	li	a2,128
    80005af2:	f7040593          	addi	a1,s0,-144
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	2f2080e7          	jalr	754(ra) # 80002dea <argstr>
    80005b00:	04054a63          	bltz	a0,80005b54 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b04:	f6c40593          	addi	a1,s0,-148
    80005b08:	4505                	li	a0,1
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	29c080e7          	jalr	668(ra) # 80002da6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b12:	04054163          	bltz	a0,80005b54 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b16:	f6840593          	addi	a1,s0,-152
    80005b1a:	4509                	li	a0,2
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	28a080e7          	jalr	650(ra) # 80002da6 <argint>
     argint(1, &major) < 0 ||
    80005b24:	02054863          	bltz	a0,80005b54 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b28:	f6841683          	lh	a3,-152(s0)
    80005b2c:	f6c41603          	lh	a2,-148(s0)
    80005b30:	458d                	li	a1,3
    80005b32:	f7040513          	addi	a0,s0,-144
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	776080e7          	jalr	1910(ra) # 800052ac <create>
     argint(2, &minor) < 0 ||
    80005b3e:	c919                	beqz	a0,80005b54 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	09c080e7          	jalr	156(ra) # 80003bdc <iunlockput>
  end_op();
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	884080e7          	jalr	-1916(ra) # 800043cc <end_op>
  return 0;
    80005b50:	4501                	li	a0,0
    80005b52:	a031                	j	80005b5e <sys_mknod+0x80>
    end_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	878080e7          	jalr	-1928(ra) # 800043cc <end_op>
    return -1;
    80005b5c:	557d                	li	a0,-1
}
    80005b5e:	60ea                	ld	ra,152(sp)
    80005b60:	644a                	ld	s0,144(sp)
    80005b62:	610d                	addi	sp,sp,160
    80005b64:	8082                	ret

0000000080005b66 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b66:	7135                	addi	sp,sp,-160
    80005b68:	ed06                	sd	ra,152(sp)
    80005b6a:	e922                	sd	s0,144(sp)
    80005b6c:	e526                	sd	s1,136(sp)
    80005b6e:	e14a                	sd	s2,128(sp)
    80005b70:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b72:	ffffc097          	auipc	ra,0xffffc
    80005b76:	17e080e7          	jalr	382(ra) # 80001cf0 <myproc>
    80005b7a:	892a                	mv	s2,a0
  
  begin_op();
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	7d0080e7          	jalr	2000(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b84:	08000613          	li	a2,128
    80005b88:	f6040593          	addi	a1,s0,-160
    80005b8c:	4501                	li	a0,0
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	25c080e7          	jalr	604(ra) # 80002dea <argstr>
    80005b96:	04054b63          	bltz	a0,80005bec <sys_chdir+0x86>
    80005b9a:	f6040513          	addi	a0,s0,-160
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	592080e7          	jalr	1426(ra) # 80004130 <namei>
    80005ba6:	84aa                	mv	s1,a0
    80005ba8:	c131                	beqz	a0,80005bec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	dd0080e7          	jalr	-560(ra) # 8000397a <ilock>
  if(ip->type != T_DIR){
    80005bb2:	04449703          	lh	a4,68(s1)
    80005bb6:	4785                	li	a5,1
    80005bb8:	04f71063          	bne	a4,a5,80005bf8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	e7e080e7          	jalr	-386(ra) # 80003a3c <iunlock>
  iput(p->cwd);
    80005bc6:	16893503          	ld	a0,360(s2)
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	f6a080e7          	jalr	-150(ra) # 80003b34 <iput>
  end_op();
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	7fa080e7          	jalr	2042(ra) # 800043cc <end_op>
  p->cwd = ip;
    80005bda:	16993423          	sd	s1,360(s2)
  return 0;
    80005bde:	4501                	li	a0,0
}
    80005be0:	60ea                	ld	ra,152(sp)
    80005be2:	644a                	ld	s0,144(sp)
    80005be4:	64aa                	ld	s1,136(sp)
    80005be6:	690a                	ld	s2,128(sp)
    80005be8:	610d                	addi	sp,sp,160
    80005bea:	8082                	ret
    end_op();
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	7e0080e7          	jalr	2016(ra) # 800043cc <end_op>
    return -1;
    80005bf4:	557d                	li	a0,-1
    80005bf6:	b7ed                	j	80005be0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bf8:	8526                	mv	a0,s1
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	fe2080e7          	jalr	-30(ra) # 80003bdc <iunlockput>
    end_op();
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	7ca080e7          	jalr	1994(ra) # 800043cc <end_op>
    return -1;
    80005c0a:	557d                	li	a0,-1
    80005c0c:	bfd1                	j	80005be0 <sys_chdir+0x7a>

0000000080005c0e <sys_exec>:

uint64
sys_exec(void)
{
    80005c0e:	7145                	addi	sp,sp,-464
    80005c10:	e786                	sd	ra,456(sp)
    80005c12:	e3a2                	sd	s0,448(sp)
    80005c14:	ff26                	sd	s1,440(sp)
    80005c16:	fb4a                	sd	s2,432(sp)
    80005c18:	f74e                	sd	s3,424(sp)
    80005c1a:	f352                	sd	s4,416(sp)
    80005c1c:	ef56                	sd	s5,408(sp)
    80005c1e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c20:	08000613          	li	a2,128
    80005c24:	f4040593          	addi	a1,s0,-192
    80005c28:	4501                	li	a0,0
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	1c0080e7          	jalr	448(ra) # 80002dea <argstr>
    return -1;
    80005c32:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c34:	0c054a63          	bltz	a0,80005d08 <sys_exec+0xfa>
    80005c38:	e3840593          	addi	a1,s0,-456
    80005c3c:	4505                	li	a0,1
    80005c3e:	ffffd097          	auipc	ra,0xffffd
    80005c42:	18a080e7          	jalr	394(ra) # 80002dc8 <argaddr>
    80005c46:	0c054163          	bltz	a0,80005d08 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c4a:	10000613          	li	a2,256
    80005c4e:	4581                	li	a1,0
    80005c50:	e4040513          	addi	a0,s0,-448
    80005c54:	ffffb097          	auipc	ra,0xffffb
    80005c58:	08c080e7          	jalr	140(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c5c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c60:	89a6                	mv	s3,s1
    80005c62:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c64:	02000a13          	li	s4,32
    80005c68:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c6c:	00391513          	slli	a0,s2,0x3
    80005c70:	e3040593          	addi	a1,s0,-464
    80005c74:	e3843783          	ld	a5,-456(s0)
    80005c78:	953e                	add	a0,a0,a5
    80005c7a:	ffffd097          	auipc	ra,0xffffd
    80005c7e:	092080e7          	jalr	146(ra) # 80002d0c <fetchaddr>
    80005c82:	02054a63          	bltz	a0,80005cb6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c86:	e3043783          	ld	a5,-464(s0)
    80005c8a:	c3b9                	beqz	a5,80005cd0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	e68080e7          	jalr	-408(ra) # 80000af4 <kalloc>
    80005c94:	85aa                	mv	a1,a0
    80005c96:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c9a:	cd11                	beqz	a0,80005cb6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c9c:	6605                	lui	a2,0x1
    80005c9e:	e3043503          	ld	a0,-464(s0)
    80005ca2:	ffffd097          	auipc	ra,0xffffd
    80005ca6:	0bc080e7          	jalr	188(ra) # 80002d5e <fetchstr>
    80005caa:	00054663          	bltz	a0,80005cb6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cae:	0905                	addi	s2,s2,1
    80005cb0:	09a1                	addi	s3,s3,8
    80005cb2:	fb491be3          	bne	s2,s4,80005c68 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb6:	10048913          	addi	s2,s1,256
    80005cba:	6088                	ld	a0,0(s1)
    80005cbc:	c529                	beqz	a0,80005d06 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cbe:	ffffb097          	auipc	ra,0xffffb
    80005cc2:	d3a080e7          	jalr	-710(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc6:	04a1                	addi	s1,s1,8
    80005cc8:	ff2499e3          	bne	s1,s2,80005cba <sys_exec+0xac>
  return -1;
    80005ccc:	597d                	li	s2,-1
    80005cce:	a82d                	j	80005d08 <sys_exec+0xfa>
      argv[i] = 0;
    80005cd0:	0a8e                	slli	s5,s5,0x3
    80005cd2:	fc040793          	addi	a5,s0,-64
    80005cd6:	9abe                	add	s5,s5,a5
    80005cd8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cdc:	e4040593          	addi	a1,s0,-448
    80005ce0:	f4040513          	addi	a0,s0,-192
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	194080e7          	jalr	404(ra) # 80004e78 <exec>
    80005cec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cee:	10048993          	addi	s3,s1,256
    80005cf2:	6088                	ld	a0,0(s1)
    80005cf4:	c911                	beqz	a0,80005d08 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	d02080e7          	jalr	-766(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfe:	04a1                	addi	s1,s1,8
    80005d00:	ff3499e3          	bne	s1,s3,80005cf2 <sys_exec+0xe4>
    80005d04:	a011                	j	80005d08 <sys_exec+0xfa>
  return -1;
    80005d06:	597d                	li	s2,-1
}
    80005d08:	854a                	mv	a0,s2
    80005d0a:	60be                	ld	ra,456(sp)
    80005d0c:	641e                	ld	s0,448(sp)
    80005d0e:	74fa                	ld	s1,440(sp)
    80005d10:	795a                	ld	s2,432(sp)
    80005d12:	79ba                	ld	s3,424(sp)
    80005d14:	7a1a                	ld	s4,416(sp)
    80005d16:	6afa                	ld	s5,408(sp)
    80005d18:	6179                	addi	sp,sp,464
    80005d1a:	8082                	ret

0000000080005d1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d1c:	7139                	addi	sp,sp,-64
    80005d1e:	fc06                	sd	ra,56(sp)
    80005d20:	f822                	sd	s0,48(sp)
    80005d22:	f426                	sd	s1,40(sp)
    80005d24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d26:	ffffc097          	auipc	ra,0xffffc
    80005d2a:	fca080e7          	jalr	-54(ra) # 80001cf0 <myproc>
    80005d2e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d30:	fd840593          	addi	a1,s0,-40
    80005d34:	4501                	li	a0,0
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	092080e7          	jalr	146(ra) # 80002dc8 <argaddr>
    return -1;
    80005d3e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d40:	0e054063          	bltz	a0,80005e20 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d44:	fc840593          	addi	a1,s0,-56
    80005d48:	fd040513          	addi	a0,s0,-48
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	dfc080e7          	jalr	-516(ra) # 80004b48 <pipealloc>
    return -1;
    80005d54:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d56:	0c054563          	bltz	a0,80005e20 <sys_pipe+0x104>
  fd0 = -1;
    80005d5a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d5e:	fd043503          	ld	a0,-48(s0)
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	508080e7          	jalr	1288(ra) # 8000526a <fdalloc>
    80005d6a:	fca42223          	sw	a0,-60(s0)
    80005d6e:	08054c63          	bltz	a0,80005e06 <sys_pipe+0xea>
    80005d72:	fc843503          	ld	a0,-56(s0)
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	4f4080e7          	jalr	1268(ra) # 8000526a <fdalloc>
    80005d7e:	fca42023          	sw	a0,-64(s0)
    80005d82:	06054863          	bltz	a0,80005df2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d86:	4691                	li	a3,4
    80005d88:	fc440613          	addi	a2,s0,-60
    80005d8c:	fd843583          	ld	a1,-40(s0)
    80005d90:	74a8                	ld	a0,104(s1)
    80005d92:	ffffc097          	auipc	ra,0xffffc
    80005d96:	8e0080e7          	jalr	-1824(ra) # 80001672 <copyout>
    80005d9a:	02054063          	bltz	a0,80005dba <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d9e:	4691                	li	a3,4
    80005da0:	fc040613          	addi	a2,s0,-64
    80005da4:	fd843583          	ld	a1,-40(s0)
    80005da8:	0591                	addi	a1,a1,4
    80005daa:	74a8                	ld	a0,104(s1)
    80005dac:	ffffc097          	auipc	ra,0xffffc
    80005db0:	8c6080e7          	jalr	-1850(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005db4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005db6:	06055563          	bgez	a0,80005e20 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dba:	fc442783          	lw	a5,-60(s0)
    80005dbe:	07f1                	addi	a5,a5,28
    80005dc0:	078e                	slli	a5,a5,0x3
    80005dc2:	97a6                	add	a5,a5,s1
    80005dc4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005dc8:	fc042503          	lw	a0,-64(s0)
    80005dcc:	0571                	addi	a0,a0,28
    80005dce:	050e                	slli	a0,a0,0x3
    80005dd0:	9526                	add	a0,a0,s1
    80005dd2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dd6:	fd043503          	ld	a0,-48(s0)
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	a3e080e7          	jalr	-1474(ra) # 80004818 <fileclose>
    fileclose(wf);
    80005de2:	fc843503          	ld	a0,-56(s0)
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	a32080e7          	jalr	-1486(ra) # 80004818 <fileclose>
    return -1;
    80005dee:	57fd                	li	a5,-1
    80005df0:	a805                	j	80005e20 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005df2:	fc442783          	lw	a5,-60(s0)
    80005df6:	0007c863          	bltz	a5,80005e06 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dfa:	01c78513          	addi	a0,a5,28
    80005dfe:	050e                	slli	a0,a0,0x3
    80005e00:	9526                	add	a0,a0,s1
    80005e02:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e06:	fd043503          	ld	a0,-48(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	a0e080e7          	jalr	-1522(ra) # 80004818 <fileclose>
    fileclose(wf);
    80005e12:	fc843503          	ld	a0,-56(s0)
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	a02080e7          	jalr	-1534(ra) # 80004818 <fileclose>
    return -1;
    80005e1e:	57fd                	li	a5,-1
}
    80005e20:	853e                	mv	a0,a5
    80005e22:	70e2                	ld	ra,56(sp)
    80005e24:	7442                	ld	s0,48(sp)
    80005e26:	74a2                	ld	s1,40(sp)
    80005e28:	6121                	addi	sp,sp,64
    80005e2a:	8082                	ret
    80005e2c:	0000                	unimp
	...

0000000080005e30 <kernelvec>:
    80005e30:	7111                	addi	sp,sp,-256
    80005e32:	e006                	sd	ra,0(sp)
    80005e34:	e40a                	sd	sp,8(sp)
    80005e36:	e80e                	sd	gp,16(sp)
    80005e38:	ec12                	sd	tp,24(sp)
    80005e3a:	f016                	sd	t0,32(sp)
    80005e3c:	f41a                	sd	t1,40(sp)
    80005e3e:	f81e                	sd	t2,48(sp)
    80005e40:	fc22                	sd	s0,56(sp)
    80005e42:	e0a6                	sd	s1,64(sp)
    80005e44:	e4aa                	sd	a0,72(sp)
    80005e46:	e8ae                	sd	a1,80(sp)
    80005e48:	ecb2                	sd	a2,88(sp)
    80005e4a:	f0b6                	sd	a3,96(sp)
    80005e4c:	f4ba                	sd	a4,104(sp)
    80005e4e:	f8be                	sd	a5,112(sp)
    80005e50:	fcc2                	sd	a6,120(sp)
    80005e52:	e146                	sd	a7,128(sp)
    80005e54:	e54a                	sd	s2,136(sp)
    80005e56:	e94e                	sd	s3,144(sp)
    80005e58:	ed52                	sd	s4,152(sp)
    80005e5a:	f156                	sd	s5,160(sp)
    80005e5c:	f55a                	sd	s6,168(sp)
    80005e5e:	f95e                	sd	s7,176(sp)
    80005e60:	fd62                	sd	s8,184(sp)
    80005e62:	e1e6                	sd	s9,192(sp)
    80005e64:	e5ea                	sd	s10,200(sp)
    80005e66:	e9ee                	sd	s11,208(sp)
    80005e68:	edf2                	sd	t3,216(sp)
    80005e6a:	f1f6                	sd	t4,224(sp)
    80005e6c:	f5fa                	sd	t5,232(sp)
    80005e6e:	f9fe                	sd	t6,240(sp)
    80005e70:	d93fc0ef          	jal	ra,80002c02 <kerneltrap>
    80005e74:	6082                	ld	ra,0(sp)
    80005e76:	6122                	ld	sp,8(sp)
    80005e78:	61c2                	ld	gp,16(sp)
    80005e7a:	7282                	ld	t0,32(sp)
    80005e7c:	7322                	ld	t1,40(sp)
    80005e7e:	73c2                	ld	t2,48(sp)
    80005e80:	7462                	ld	s0,56(sp)
    80005e82:	6486                	ld	s1,64(sp)
    80005e84:	6526                	ld	a0,72(sp)
    80005e86:	65c6                	ld	a1,80(sp)
    80005e88:	6666                	ld	a2,88(sp)
    80005e8a:	7686                	ld	a3,96(sp)
    80005e8c:	7726                	ld	a4,104(sp)
    80005e8e:	77c6                	ld	a5,112(sp)
    80005e90:	7866                	ld	a6,120(sp)
    80005e92:	688a                	ld	a7,128(sp)
    80005e94:	692a                	ld	s2,136(sp)
    80005e96:	69ca                	ld	s3,144(sp)
    80005e98:	6a6a                	ld	s4,152(sp)
    80005e9a:	7a8a                	ld	s5,160(sp)
    80005e9c:	7b2a                	ld	s6,168(sp)
    80005e9e:	7bca                	ld	s7,176(sp)
    80005ea0:	7c6a                	ld	s8,184(sp)
    80005ea2:	6c8e                	ld	s9,192(sp)
    80005ea4:	6d2e                	ld	s10,200(sp)
    80005ea6:	6dce                	ld	s11,208(sp)
    80005ea8:	6e6e                	ld	t3,216(sp)
    80005eaa:	7e8e                	ld	t4,224(sp)
    80005eac:	7f2e                	ld	t5,232(sp)
    80005eae:	7fce                	ld	t6,240(sp)
    80005eb0:	6111                	addi	sp,sp,256
    80005eb2:	10200073          	sret
    80005eb6:	00000013          	nop
    80005eba:	00000013          	nop
    80005ebe:	0001                	nop

0000000080005ec0 <timervec>:
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	e10c                	sd	a1,0(a0)
    80005ec6:	e510                	sd	a2,8(a0)
    80005ec8:	e914                	sd	a3,16(a0)
    80005eca:	6d0c                	ld	a1,24(a0)
    80005ecc:	7110                	ld	a2,32(a0)
    80005ece:	6194                	ld	a3,0(a1)
    80005ed0:	96b2                	add	a3,a3,a2
    80005ed2:	e194                	sd	a3,0(a1)
    80005ed4:	4589                	li	a1,2
    80005ed6:	14459073          	csrw	sip,a1
    80005eda:	6914                	ld	a3,16(a0)
    80005edc:	6510                	ld	a2,8(a0)
    80005ede:	610c                	ld	a1,0(a0)
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	30200073          	mret
	...

0000000080005eea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eea:	1141                	addi	sp,sp,-16
    80005eec:	e422                	sd	s0,8(sp)
    80005eee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ef0:	0c0007b7          	lui	a5,0xc000
    80005ef4:	4705                	li	a4,1
    80005ef6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ef8:	c3d8                	sw	a4,4(a5)
}
    80005efa:	6422                	ld	s0,8(sp)
    80005efc:	0141                	addi	sp,sp,16
    80005efe:	8082                	ret

0000000080005f00 <plicinithart>:

void
plicinithart(void)
{
    80005f00:	1141                	addi	sp,sp,-16
    80005f02:	e406                	sd	ra,8(sp)
    80005f04:	e022                	sd	s0,0(sp)
    80005f06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	dbc080e7          	jalr	-580(ra) # 80001cc4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f10:	0085171b          	slliw	a4,a0,0x8
    80005f14:	0c0027b7          	lui	a5,0xc002
    80005f18:	97ba                	add	a5,a5,a4
    80005f1a:	40200713          	li	a4,1026
    80005f1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f22:	00d5151b          	slliw	a0,a0,0xd
    80005f26:	0c2017b7          	lui	a5,0xc201
    80005f2a:	953e                	add	a0,a0,a5
    80005f2c:	00052023          	sw	zero,0(a0)
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	addi	sp,sp,16
    80005f36:	8082                	ret

0000000080005f38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f38:	1141                	addi	sp,sp,-16
    80005f3a:	e406                	sd	ra,8(sp)
    80005f3c:	e022                	sd	s0,0(sp)
    80005f3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	d84080e7          	jalr	-636(ra) # 80001cc4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f48:	00d5179b          	slliw	a5,a0,0xd
    80005f4c:	0c201537          	lui	a0,0xc201
    80005f50:	953e                	add	a0,a0,a5
  return irq;
}
    80005f52:	4148                	lw	a0,4(a0)
    80005f54:	60a2                	ld	ra,8(sp)
    80005f56:	6402                	ld	s0,0(sp)
    80005f58:	0141                	addi	sp,sp,16
    80005f5a:	8082                	ret

0000000080005f5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f5c:	1101                	addi	sp,sp,-32
    80005f5e:	ec06                	sd	ra,24(sp)
    80005f60:	e822                	sd	s0,16(sp)
    80005f62:	e426                	sd	s1,8(sp)
    80005f64:	1000                	addi	s0,sp,32
    80005f66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	d5c080e7          	jalr	-676(ra) # 80001cc4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f70:	00d5151b          	slliw	a0,a0,0xd
    80005f74:	0c2017b7          	lui	a5,0xc201
    80005f78:	97aa                	add	a5,a5,a0
    80005f7a:	c3c4                	sw	s1,4(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6105                	addi	sp,sp,32
    80005f84:	8082                	ret

0000000080005f86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f86:	1141                	addi	sp,sp,-16
    80005f88:	e406                	sd	ra,8(sp)
    80005f8a:	e022                	sd	s0,0(sp)
    80005f8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f8e:	479d                	li	a5,7
    80005f90:	06a7c963          	blt	a5,a0,80006002 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f94:	0001d797          	auipc	a5,0x1d
    80005f98:	06c78793          	addi	a5,a5,108 # 80023000 <disk>
    80005f9c:	00a78733          	add	a4,a5,a0
    80005fa0:	6789                	lui	a5,0x2
    80005fa2:	97ba                	add	a5,a5,a4
    80005fa4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fa8:	e7ad                	bnez	a5,80006012 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005faa:	00451793          	slli	a5,a0,0x4
    80005fae:	0001f717          	auipc	a4,0x1f
    80005fb2:	05270713          	addi	a4,a4,82 # 80025000 <disk+0x2000>
    80005fb6:	6314                	ld	a3,0(a4)
    80005fb8:	96be                	add	a3,a3,a5
    80005fba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fbe:	6314                	ld	a3,0(a4)
    80005fc0:	96be                	add	a3,a3,a5
    80005fc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fc6:	6314                	ld	a3,0(a4)
    80005fc8:	96be                	add	a3,a3,a5
    80005fca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fce:	6318                	ld	a4,0(a4)
    80005fd0:	97ba                	add	a5,a5,a4
    80005fd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fd6:	0001d797          	auipc	a5,0x1d
    80005fda:	02a78793          	addi	a5,a5,42 # 80023000 <disk>
    80005fde:	97aa                	add	a5,a5,a0
    80005fe0:	6509                	lui	a0,0x2
    80005fe2:	953e                	add	a0,a0,a5
    80005fe4:	4785                	li	a5,1
    80005fe6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fea:	0001f517          	auipc	a0,0x1f
    80005fee:	02e50513          	addi	a0,a0,46 # 80025018 <disk+0x2018>
    80005ff2:	ffffc097          	auipc	ra,0xffffc
    80005ff6:	53a080e7          	jalr	1338(ra) # 8000252c <wakeup>
}
    80005ffa:	60a2                	ld	ra,8(sp)
    80005ffc:	6402                	ld	s0,0(sp)
    80005ffe:	0141                	addi	sp,sp,16
    80006000:	8082                	ret
    panic("free_desc 1");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	84650513          	addi	a0,a0,-1978 # 80008848 <syscalls+0x338>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	534080e7          	jalr	1332(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	84650513          	addi	a0,a0,-1978 # 80008858 <syscalls+0x348>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	524080e7          	jalr	1316(ra) # 8000053e <panic>

0000000080006022 <virtio_disk_init>:
{
    80006022:	1101                	addi	sp,sp,-32
    80006024:	ec06                	sd	ra,24(sp)
    80006026:	e822                	sd	s0,16(sp)
    80006028:	e426                	sd	s1,8(sp)
    8000602a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000602c:	00003597          	auipc	a1,0x3
    80006030:	83c58593          	addi	a1,a1,-1988 # 80008868 <syscalls+0x358>
    80006034:	0001f517          	auipc	a0,0x1f
    80006038:	0f450513          	addi	a0,a0,244 # 80025128 <disk+0x2128>
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	b18080e7          	jalr	-1256(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	4398                	lw	a4,0(a5)
    8000604a:	2701                	sext.w	a4,a4
    8000604c:	747277b7          	lui	a5,0x74727
    80006050:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006054:	0ef71163          	bne	a4,a5,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	43dc                	lw	a5,4(a5)
    8000605e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006060:	4705                	li	a4,1
    80006062:	0ce79a63          	bne	a5,a4,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006066:	100017b7          	lui	a5,0x10001
    8000606a:	479c                	lw	a5,8(a5)
    8000606c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000606e:	4709                	li	a4,2
    80006070:	0ce79363          	bne	a5,a4,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	47d8                	lw	a4,12(a5)
    8000607a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000607c:	554d47b7          	lui	a5,0x554d4
    80006080:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006084:	0af71963          	bne	a4,a5,80006136 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	4705                	li	a4,1
    8000608e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006090:	470d                	li	a4,3
    80006092:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006094:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006096:	c7ffe737          	lui	a4,0xc7ffe
    8000609a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000609e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060a0:	2701                	sext.w	a4,a4
    800060a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a4:	472d                	li	a4,11
    800060a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a8:	473d                	li	a4,15
    800060aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060ac:	6705                	lui	a4,0x1
    800060ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060b4:	5bdc                	lw	a5,52(a5)
    800060b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060b8:	c7d9                	beqz	a5,80006146 <virtio_disk_init+0x124>
  if(max < NUM)
    800060ba:	471d                	li	a4,7
    800060bc:	08f77d63          	bgeu	a4,a5,80006156 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060c0:	100014b7          	lui	s1,0x10001
    800060c4:	47a1                	li	a5,8
    800060c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060c8:	6609                	lui	a2,0x2
    800060ca:	4581                	li	a1,0
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	c0c080e7          	jalr	-1012(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060dc:	0001d717          	auipc	a4,0x1d
    800060e0:	f2470713          	addi	a4,a4,-220 # 80023000 <disk>
    800060e4:	00c75793          	srli	a5,a4,0xc
    800060e8:	2781                	sext.w	a5,a5
    800060ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060ec:	0001f797          	auipc	a5,0x1f
    800060f0:	f1478793          	addi	a5,a5,-236 # 80025000 <disk+0x2000>
    800060f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060f6:	0001d717          	auipc	a4,0x1d
    800060fa:	f8a70713          	addi	a4,a4,-118 # 80023080 <disk+0x80>
    800060fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006100:	0001e717          	auipc	a4,0x1e
    80006104:	f0070713          	addi	a4,a4,-256 # 80024000 <disk+0x1000>
    80006108:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000610a:	4705                	li	a4,1
    8000610c:	00e78c23          	sb	a4,24(a5)
    80006110:	00e78ca3          	sb	a4,25(a5)
    80006114:	00e78d23          	sb	a4,26(a5)
    80006118:	00e78da3          	sb	a4,27(a5)
    8000611c:	00e78e23          	sb	a4,28(a5)
    80006120:	00e78ea3          	sb	a4,29(a5)
    80006124:	00e78f23          	sb	a4,30(a5)
    80006128:	00e78fa3          	sb	a4,31(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret
    panic("could not find virtio disk");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	74250513          	addi	a0,a0,1858 # 80008878 <syscalls+0x368>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	75250513          	addi	a0,a0,1874 # 80008898 <syscalls+0x388>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006156:	00002517          	auipc	a0,0x2
    8000615a:	76250513          	addi	a0,a0,1890 # 800088b8 <syscalls+0x3a8>
    8000615e:	ffffa097          	auipc	ra,0xffffa
    80006162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>

0000000080006166 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006166:	7159                	addi	sp,sp,-112
    80006168:	f486                	sd	ra,104(sp)
    8000616a:	f0a2                	sd	s0,96(sp)
    8000616c:	eca6                	sd	s1,88(sp)
    8000616e:	e8ca                	sd	s2,80(sp)
    80006170:	e4ce                	sd	s3,72(sp)
    80006172:	e0d2                	sd	s4,64(sp)
    80006174:	fc56                	sd	s5,56(sp)
    80006176:	f85a                	sd	s6,48(sp)
    80006178:	f45e                	sd	s7,40(sp)
    8000617a:	f062                	sd	s8,32(sp)
    8000617c:	ec66                	sd	s9,24(sp)
    8000617e:	e86a                	sd	s10,16(sp)
    80006180:	1880                	addi	s0,sp,112
    80006182:	892a                	mv	s2,a0
    80006184:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006186:	00c52c83          	lw	s9,12(a0)
    8000618a:	001c9c9b          	slliw	s9,s9,0x1
    8000618e:	1c82                	slli	s9,s9,0x20
    80006190:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006194:	0001f517          	auipc	a0,0x1f
    80006198:	f9450513          	addi	a0,a0,-108 # 80025128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061a8:	0001db97          	auipc	s7,0x1d
    800061ac:	e58b8b93          	addi	s7,s7,-424 # 80023000 <disk>
    800061b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061b4:	8a4e                	mv	s4,s3
    800061b6:	a051                	j	8000623a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061b8:	00fb86b3          	add	a3,s7,a5
    800061bc:	96da                	add	a3,a3,s6
    800061be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061c4:	0207c563          	bltz	a5,800061ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061c8:	2485                	addiw	s1,s1,1
    800061ca:	0711                	addi	a4,a4,4
    800061cc:	25548063          	beq	s1,s5,8000640c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061d2:	0001f697          	auipc	a3,0x1f
    800061d6:	e4668693          	addi	a3,a3,-442 # 80025018 <disk+0x2018>
    800061da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061dc:	0006c583          	lbu	a1,0(a3)
    800061e0:	fde1                	bnez	a1,800061b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061e2:	2785                	addiw	a5,a5,1
    800061e4:	0685                	addi	a3,a3,1
    800061e6:	ff879be3          	bne	a5,s8,800061dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ea:	57fd                	li	a5,-1
    800061ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ee:	02905a63          	blez	s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f2:	f9042503          	lw	a0,-112(s0)
    800061f6:	00000097          	auipc	ra,0x0
    800061fa:	d90080e7          	jalr	-624(ra) # 80005f86 <free_desc>
      for(int j = 0; j < i; j++)
    800061fe:	4785                	li	a5,1
    80006200:	0297d163          	bge	a5,s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006204:	f9442503          	lw	a0,-108(s0)
    80006208:	00000097          	auipc	ra,0x0
    8000620c:	d7e080e7          	jalr	-642(ra) # 80005f86 <free_desc>
      for(int j = 0; j < i; j++)
    80006210:	4789                	li	a5,2
    80006212:	0097d863          	bge	a5,s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006216:	f9842503          	lw	a0,-104(s0)
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	d6c080e7          	jalr	-660(ra) # 80005f86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006222:	0001f597          	auipc	a1,0x1f
    80006226:	f0658593          	addi	a1,a1,-250 # 80025128 <disk+0x2128>
    8000622a:	0001f517          	auipc	a0,0x1f
    8000622e:	dee50513          	addi	a0,a0,-530 # 80025018 <disk+0x2018>
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	154080e7          	jalr	340(ra) # 80002386 <sleep>
  for(int i = 0; i < 3; i++){
    8000623a:	f9040713          	addi	a4,s0,-112
    8000623e:	84ce                	mv	s1,s3
    80006240:	bf41                	j	800061d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006242:	20058713          	addi	a4,a1,512
    80006246:	00471693          	slli	a3,a4,0x4
    8000624a:	0001d717          	auipc	a4,0x1d
    8000624e:	db670713          	addi	a4,a4,-586 # 80023000 <disk>
    80006252:	9736                	add	a4,a4,a3
    80006254:	4685                	li	a3,1
    80006256:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000625a:	20058713          	addi	a4,a1,512
    8000625e:	00471693          	slli	a3,a4,0x4
    80006262:	0001d717          	auipc	a4,0x1d
    80006266:	d9e70713          	addi	a4,a4,-610 # 80023000 <disk>
    8000626a:	9736                	add	a4,a4,a3
    8000626c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006270:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006274:	7679                	lui	a2,0xffffe
    80006276:	963e                	add	a2,a2,a5
    80006278:	0001f697          	auipc	a3,0x1f
    8000627c:	d8868693          	addi	a3,a3,-632 # 80025000 <disk+0x2000>
    80006280:	6298                	ld	a4,0(a3)
    80006282:	9732                	add	a4,a4,a2
    80006284:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006286:	6298                	ld	a4,0(a3)
    80006288:	9732                	add	a4,a4,a2
    8000628a:	4541                	li	a0,16
    8000628c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000628e:	6298                	ld	a4,0(a3)
    80006290:	9732                	add	a4,a4,a2
    80006292:	4505                	li	a0,1
    80006294:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006298:	f9442703          	lw	a4,-108(s0)
    8000629c:	6288                	ld	a0,0(a3)
    8000629e:	962a                	add	a2,a2,a0
    800062a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a4:	0712                	slli	a4,a4,0x4
    800062a6:	6290                	ld	a2,0(a3)
    800062a8:	963a                	add	a2,a2,a4
    800062aa:	05890513          	addi	a0,s2,88
    800062ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062b0:	6294                	ld	a3,0(a3)
    800062b2:	96ba                	add	a3,a3,a4
    800062b4:	40000613          	li	a2,1024
    800062b8:	c690                	sw	a2,8(a3)
  if(write)
    800062ba:	140d0063          	beqz	s10,800063fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062be:	0001f697          	auipc	a3,0x1f
    800062c2:	d426b683          	ld	a3,-702(a3) # 80025000 <disk+0x2000>
    800062c6:	96ba                	add	a3,a3,a4
    800062c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062cc:	0001d817          	auipc	a6,0x1d
    800062d0:	d3480813          	addi	a6,a6,-716 # 80023000 <disk>
    800062d4:	0001f517          	auipc	a0,0x1f
    800062d8:	d2c50513          	addi	a0,a0,-724 # 80025000 <disk+0x2000>
    800062dc:	6114                	ld	a3,0(a0)
    800062de:	96ba                	add	a3,a3,a4
    800062e0:	00c6d603          	lhu	a2,12(a3)
    800062e4:	00166613          	ori	a2,a2,1
    800062e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ec:	f9842683          	lw	a3,-104(s0)
    800062f0:	6110                	ld	a2,0(a0)
    800062f2:	9732                	add	a4,a4,a2
    800062f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062f8:	20058613          	addi	a2,a1,512
    800062fc:	0612                	slli	a2,a2,0x4
    800062fe:	9642                	add	a2,a2,a6
    80006300:	577d                	li	a4,-1
    80006302:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006306:	00469713          	slli	a4,a3,0x4
    8000630a:	6114                	ld	a3,0(a0)
    8000630c:	96ba                	add	a3,a3,a4
    8000630e:	03078793          	addi	a5,a5,48
    80006312:	97c2                	add	a5,a5,a6
    80006314:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006316:	611c                	ld	a5,0(a0)
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	4685                	li	a3,1
    8000631c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000631e:	611c                	ld	a5,0(a0)
    80006320:	97ba                	add	a5,a5,a4
    80006322:	4809                	li	a6,2
    80006324:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006328:	611c                	ld	a5,0(a0)
    8000632a:	973e                	add	a4,a4,a5
    8000632c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006330:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006334:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006338:	6518                	ld	a4,8(a0)
    8000633a:	00275783          	lhu	a5,2(a4)
    8000633e:	8b9d                	andi	a5,a5,7
    80006340:	0786                	slli	a5,a5,0x1
    80006342:	97ba                	add	a5,a5,a4
    80006344:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006348:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000634c:	6518                	ld	a4,8(a0)
    8000634e:	00275783          	lhu	a5,2(a4)
    80006352:	2785                	addiw	a5,a5,1
    80006354:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006358:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000635c:	100017b7          	lui	a5,0x10001
    80006360:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006364:	00492703          	lw	a4,4(s2)
    80006368:	4785                	li	a5,1
    8000636a:	02f71163          	bne	a4,a5,8000638c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000636e:	0001f997          	auipc	s3,0x1f
    80006372:	dba98993          	addi	s3,s3,-582 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006376:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006378:	85ce                	mv	a1,s3
    8000637a:	854a                	mv	a0,s2
    8000637c:	ffffc097          	auipc	ra,0xffffc
    80006380:	00a080e7          	jalr	10(ra) # 80002386 <sleep>
  while(b->disk == 1) {
    80006384:	00492783          	lw	a5,4(s2)
    80006388:	fe9788e3          	beq	a5,s1,80006378 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000638c:	f9042903          	lw	s2,-112(s0)
    80006390:	20090793          	addi	a5,s2,512
    80006394:	00479713          	slli	a4,a5,0x4
    80006398:	0001d797          	auipc	a5,0x1d
    8000639c:	c6878793          	addi	a5,a5,-920 # 80023000 <disk>
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063a6:	0001f997          	auipc	s3,0x1f
    800063aa:	c5a98993          	addi	s3,s3,-934 # 80025000 <disk+0x2000>
    800063ae:	00491713          	slli	a4,s2,0x4
    800063b2:	0009b783          	ld	a5,0(s3)
    800063b6:	97ba                	add	a5,a5,a4
    800063b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063bc:	854a                	mv	a0,s2
    800063be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063c2:	00000097          	auipc	ra,0x0
    800063c6:	bc4080e7          	jalr	-1084(ra) # 80005f86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ca:	8885                	andi	s1,s1,1
    800063cc:	f0ed                	bnez	s1,800063ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ce:	0001f517          	auipc	a0,0x1f
    800063d2:	d5a50513          	addi	a0,a0,-678 # 80025128 <disk+0x2128>
    800063d6:	ffffb097          	auipc	ra,0xffffb
    800063da:	8c2080e7          	jalr	-1854(ra) # 80000c98 <release>
}
    800063de:	70a6                	ld	ra,104(sp)
    800063e0:	7406                	ld	s0,96(sp)
    800063e2:	64e6                	ld	s1,88(sp)
    800063e4:	6946                	ld	s2,80(sp)
    800063e6:	69a6                	ld	s3,72(sp)
    800063e8:	6a06                	ld	s4,64(sp)
    800063ea:	7ae2                	ld	s5,56(sp)
    800063ec:	7b42                	ld	s6,48(sp)
    800063ee:	7ba2                	ld	s7,40(sp)
    800063f0:	7c02                	ld	s8,32(sp)
    800063f2:	6ce2                	ld	s9,24(sp)
    800063f4:	6d42                	ld	s10,16(sp)
    800063f6:	6165                	addi	sp,sp,112
    800063f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063fa:	0001f697          	auipc	a3,0x1f
    800063fe:	c066b683          	ld	a3,-1018(a3) # 80025000 <disk+0x2000>
    80006402:	96ba                	add	a3,a3,a4
    80006404:	4609                	li	a2,2
    80006406:	00c69623          	sh	a2,12(a3)
    8000640a:	b5c9                	j	800062cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000640c:	f9042583          	lw	a1,-112(s0)
    80006410:	20058793          	addi	a5,a1,512
    80006414:	0792                	slli	a5,a5,0x4
    80006416:	0001d517          	auipc	a0,0x1d
    8000641a:	c9250513          	addi	a0,a0,-878 # 800230a8 <disk+0xa8>
    8000641e:	953e                	add	a0,a0,a5
  if(write)
    80006420:	e20d11e3          	bnez	s10,80006242 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006424:	20058713          	addi	a4,a1,512
    80006428:	00471693          	slli	a3,a4,0x4
    8000642c:	0001d717          	auipc	a4,0x1d
    80006430:	bd470713          	addi	a4,a4,-1068 # 80023000 <disk>
    80006434:	9736                	add	a4,a4,a3
    80006436:	0a072423          	sw	zero,168(a4)
    8000643a:	b505                	j	8000625a <virtio_disk_rw+0xf4>

000000008000643c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000643c:	1101                	addi	sp,sp,-32
    8000643e:	ec06                	sd	ra,24(sp)
    80006440:	e822                	sd	s0,16(sp)
    80006442:	e426                	sd	s1,8(sp)
    80006444:	e04a                	sd	s2,0(sp)
    80006446:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006448:	0001f517          	auipc	a0,0x1f
    8000644c:	ce050513          	addi	a0,a0,-800 # 80025128 <disk+0x2128>
    80006450:	ffffa097          	auipc	ra,0xffffa
    80006454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006458:	10001737          	lui	a4,0x10001
    8000645c:	533c                	lw	a5,96(a4)
    8000645e:	8b8d                	andi	a5,a5,3
    80006460:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006462:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006466:	0001f797          	auipc	a5,0x1f
    8000646a:	b9a78793          	addi	a5,a5,-1126 # 80025000 <disk+0x2000>
    8000646e:	6b94                	ld	a3,16(a5)
    80006470:	0207d703          	lhu	a4,32(a5)
    80006474:	0026d783          	lhu	a5,2(a3)
    80006478:	06f70163          	beq	a4,a5,800064da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000647c:	0001d917          	auipc	s2,0x1d
    80006480:	b8490913          	addi	s2,s2,-1148 # 80023000 <disk>
    80006484:	0001f497          	auipc	s1,0x1f
    80006488:	b7c48493          	addi	s1,s1,-1156 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000648c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006490:	6898                	ld	a4,16(s1)
    80006492:	0204d783          	lhu	a5,32(s1)
    80006496:	8b9d                	andi	a5,a5,7
    80006498:	078e                	slli	a5,a5,0x3
    8000649a:	97ba                	add	a5,a5,a4
    8000649c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000649e:	20078713          	addi	a4,a5,512
    800064a2:	0712                	slli	a4,a4,0x4
    800064a4:	974a                	add	a4,a4,s2
    800064a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064aa:	e731                	bnez	a4,800064f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064ac:	20078793          	addi	a5,a5,512
    800064b0:	0792                	slli	a5,a5,0x4
    800064b2:	97ca                	add	a5,a5,s2
    800064b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064ba:	ffffc097          	auipc	ra,0xffffc
    800064be:	072080e7          	jalr	114(ra) # 8000252c <wakeup>

    disk.used_idx += 1;
    800064c2:	0204d783          	lhu	a5,32(s1)
    800064c6:	2785                	addiw	a5,a5,1
    800064c8:	17c2                	slli	a5,a5,0x30
    800064ca:	93c1                	srli	a5,a5,0x30
    800064cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064d0:	6898                	ld	a4,16(s1)
    800064d2:	00275703          	lhu	a4,2(a4)
    800064d6:	faf71be3          	bne	a4,a5,8000648c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064da:	0001f517          	auipc	a0,0x1f
    800064de:	c4e50513          	addi	a0,a0,-946 # 80025128 <disk+0x2128>
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	7b6080e7          	jalr	1974(ra) # 80000c98 <release>
}
    800064ea:	60e2                	ld	ra,24(sp)
    800064ec:	6442                	ld	s0,16(sp)
    800064ee:	64a2                	ld	s1,8(sp)
    800064f0:	6902                	ld	s2,0(sp)
    800064f2:	6105                	addi	sp,sp,32
    800064f4:	8082                	ret
      panic("virtio_disk_intr status");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	3e250513          	addi	a0,a0,994 # 800088d8 <syscalls+0x3c8>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>
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
