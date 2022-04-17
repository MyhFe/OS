
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	c5c78793          	addi	a5,a5,-932 # 80005cc0 <timervec>
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
    80000130:	492080e7          	jalr	1170(ra) # 800025be <either_copyin>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c8:	a20080e7          	jalr	-1504(ra) # 80001be4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	062080e7          	jalr	98(ra) # 80002236 <sleep>
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
    80000214:	358080e7          	jalr	856(ra) # 80002568 <either_copyout>
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
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f6:	322080e7          	jalr	802(ra) # 80002614 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f7c080e7          	jalr	-132(ra) # 800023c2 <wakeup>
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
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
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
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	b22080e7          	jalr	-1246(ra) # 800023c2 <wakeup>
    
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
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	90a080e7          	jalr	-1782(ra) # 80002236 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
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
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
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
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000b82:	04a080e7          	jalr	74(ra) # 80001bc8 <mycpu>
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
    80000bb4:	018080e7          	jalr	24(ra) # 80001bc8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	00c080e7          	jalr	12(ra) # 80001bc8 <mycpu>
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
    80000bd8:	ff4080e7          	jalr	-12(ra) # 80001bc8 <mycpu>
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
    80000c18:	fb4080e7          	jalr	-76(ra) # 80001bc8 <mycpu>
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
    80000c44:	f88080e7          	jalr	-120(ra) # 80001bc8 <mycpu>
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
    80000e9a:	d22080e7          	jalr	-734(ra) # 80001bb8 <cpuid>
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
    80000eb6:	d06080e7          	jalr	-762(ra) # 80001bb8 <cpuid>
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
    80000ed8:	880080e7          	jalr	-1920(ra) # 80002754 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e24080e7          	jalr	-476(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	ae4080e7          	jalr	-1308(ra) # 800019c8 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
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
    80000f48:	bc4080e7          	jalr	-1084(ra) # 80001b08 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7e0080e7          	jalr	2016(ra) # 8000272c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	800080e7          	jalr	-2048(ra) # 80002754 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d8e080e7          	jalr	-626(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d9c080e7          	jalr	-612(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f74080e7          	jalr	-140(ra) # 80002ee0 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	604080e7          	jalr	1540(ra) # 80003578 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	5ae080e7          	jalr	1454(ra) # 8000452a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e9e080e7          	jalr	-354(ra) # 80005e22 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	f38080e7          	jalr	-200(ra) # 80001ec4 <userinit>
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
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
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
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
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
    800018a8:	17048493          	addi	s1,s1,368
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
    800018e8:	dec48493          	addi	s1,s1,-532 # 800116d0 <proc>
    800018ec:	00016997          	auipc	s3,0x16
    800018f0:	9e498993          	addi	s3,s3,-1564 # 800172d0 <tickslock>
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
    8000190e:	17048493          	addi	s1,s1,368
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
    8000195e:	d7648493          	addi	s1,s1,-650 # 800116d0 <proc>
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
    8000196e:	96698993          	addi	s3,s3,-1690 # 800172d0 <tickslock>
    80001972:	a811                	j	80001986 <kill_sys+0x40>
      }
      //release(&p->lock);
    }
    release(&p->lock);
    80001974:	8526                	mv	a0,s1
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	322080e7          	jalr	802(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000197e:	17048493          	addi	s1,s1,368
    80001982:	03348863          	beq	s1,s3,800019b2 <kill_sys+0x6c>
    acquire(&p->lock);
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    80001990:	589c                	lw	a5,48(s1)
    80001992:	03092703          	lw	a4,48(s2) # 4000030 <_entry-0x7bffffd0>
    80001996:	fcf70fe3          	beq	a4,a5,80001974 <kill_sys+0x2e>
    8000199a:	1a092703          	lw	a4,416(s2)
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

00000000800019c8 <scheduler>:
}
#endif
#ifdef SJF
void
scheduler(void)
{
    800019c8:	711d                	addi	sp,sp,-96
    800019ca:	ec86                	sd	ra,88(sp)
    800019cc:	e8a2                	sd	s0,80(sp)
    800019ce:	e4a6                	sd	s1,72(sp)
    800019d0:	e0ca                	sd	s2,64(sp)
    800019d2:	fc4e                	sd	s3,56(sp)
    800019d4:	f852                	sd	s4,48(sp)
    800019d6:	f456                	sd	s5,40(sp)
    800019d8:	f05a                	sd	s6,32(sp)
    800019da:	ec5e                	sd	s7,24(sp)
    800019dc:	e862                	sd	s8,16(sp)
    800019de:	e466                	sd	s9,8(sp)
    800019e0:	1080                	addi	s0,sp,96
  printf("SJF\n");
    800019e2:	00006517          	auipc	a0,0x6
    800019e6:	7fe50513          	addi	a0,a0,2046 # 800081e0 <digits+0x1a0>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	b9e080e7          	jalr	-1122(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f2:	8792                	mv	a5,tp
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
    800019f4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800019f6:	00010697          	auipc	a3,0x10
    800019fa:	8aa68693          	addi	a3,a3,-1878 # 800112a0 <cpus>
    800019fe:	00779713          	slli	a4,a5,0x7
    80001a02:	00e68633          	add	a2,a3,a4
    80001a06:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
        swtch(&c->context, &p->context);
    80001a0a:	0721                	addi	a4,a4,8
    80001a0c:	00e68c33          	add	s8,a3,a4
    if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a10:	00007b97          	auipc	s7,0x7
    80001a14:	618b8b93          	addi	s7,s7,1560 # 80009028 <finish>
    80001a18:	00007b17          	auipc	s6,0x7
    80001a1c:	620b0b13          	addi	s6,s6,1568 # 80009038 <ticks>
    80001a20:	00010997          	auipc	s3,0x10
    80001a24:	cb098993          	addi	s3,s3,-848 # 800116d0 <proc>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a28:	00016917          	auipc	s2,0x16
    80001a2c:	8a890913          	addi	s2,s2,-1880 # 800172d0 <tickslock>
    struct proc *tmp = &proc[0];
    80001a30:	8a4e                	mv	s4,s3
        c->proc = p;
    80001a32:	8ab2                	mv	s5,a2
    80001a34:	a87d                	j	80001af2 <scheduler+0x12a>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a36:	17078793          	addi	a5,a5,368
    80001a3a:	01278863          	beq	a5,s2,80001a4a <scheduler+0x82>
      if ((p->mean_ticks < tmp->mean_ticks)){
    80001a3e:	5bd4                	lw	a3,52(a5)
    80001a40:	58d8                	lw	a4,52(s1)
    80001a42:	fee6dae3          	bge	a3,a4,80001a36 <scheduler+0x6e>
    80001a46:	84be                	mv	s1,a5
    80001a48:	b7fd                	j	80001a36 <scheduler+0x6e>
    if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a4a:	5898                	lw	a4,48(s1)
    80001a4c:	40a707b3          	sub	a5,a4,a0
    80001a50:	0017b793          	seqz	a5,a5
    80001a54:	8f0d                	sub	a4,a4,a1
    80001a56:	00173713          	seqz	a4,a4
    80001a5a:	8fd9                	or	a5,a5,a4
    80001a5c:	0ff7f793          	andi	a5,a5,255
    80001a60:	eb99                	bnez	a5,80001a76 <scheduler+0xae>
    80001a62:	ea11                	bnez	a2,80001a76 <scheduler+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a6c:	10079073          	csrw	sstatus,a5
    struct proc *tmp = &proc[0];
    80001a70:	84d2                	mv	s1,s4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a72:	87ce                	mv	a5,s3
    80001a74:	b7e9                	j	80001a3e <scheduler+0x76>
      acquire(&p->lock);
    80001a76:	8ca6                	mv	s9,s1
    80001a78:	8526                	mv	a0,s1
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	16a080e7          	jalr	362(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001a82:	4c98                	lw	a4,24(s1)
    80001a84:	478d                	li	a5,3
    80001a86:	06f71163          	bne	a4,a5,80001ae8 <scheduler+0x120>
        p->state = RUNNING;
    80001a8a:	4791                	li	a5,4
    80001a8c:	cc9c                	sw	a5,24(s1)
        p->last_ticks = ticks;
    80001a8e:	000b2783          	lw	a5,0(s6)
    80001a92:	dc9c                	sw	a5,56(s1)
        c->proc = p;
    80001a94:	009ab023          	sd	s1,0(s5)
        swtch(&c->context, &p->context);
    80001a98:	06848593          	addi	a1,s1,104
    80001a9c:	8562                	mv	a0,s8
    80001a9e:	00001097          	auipc	ra,0x1
    80001aa2:	c24080e7          	jalr	-988(ra) # 800026c2 <swtch>
        p->last_ticks =  ticks - p->last_ticks;
    80001aa6:	000b2583          	lw	a1,0(s6)
    80001aaa:	5c9c                	lw	a5,56(s1)
    80001aac:	40f587bb          	subw	a5,a1,a5
    80001ab0:	dc9c                	sw	a5,56(s1)
        printf("ticks2 %d\n",ticks);
    80001ab2:	00006517          	auipc	a0,0x6
    80001ab6:	73650513          	addi	a0,a0,1846 # 800081e8 <digits+0x1a8>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	ace080e7          	jalr	-1330(ra) # 80000588 <printf>
        p->mean_ticks = ((10-rate)*p->mean_ticks+p->last_ticks*rate)/10;
    80001ac2:	00007617          	auipc	a2,0x7
    80001ac6:	d8662603          	lw	a2,-634(a2) # 80008848 <rate>
    80001aca:	46a9                	li	a3,10
    80001acc:	40c687bb          	subw	a5,a3,a2
    80001ad0:	58d8                	lw	a4,52(s1)
    80001ad2:	02e787bb          	mulw	a5,a5,a4
    80001ad6:	5c98                	lw	a4,56(s1)
    80001ad8:	02c7073b          	mulw	a4,a4,a2
    80001adc:	9fb9                	addw	a5,a5,a4
    80001ade:	02d7c7bb          	divw	a5,a5,a3
    80001ae2:	d8dc                	sw	a5,52(s1)
        c->proc = 0;
    80001ae4:	000ab023          	sd	zero,0(s5)
      release(&p->lock);
    80001ae8:	8566                	mv	a0,s9
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	1ae080e7          	jalr	430(ra) # 80000c98 <release>
    if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001af2:	000ba603          	lw	a2,0(s7)
    80001af6:	000b2783          	lw	a5,0(s6)
    80001afa:	00f63633          	sltu	a2,a2,a5
    80001afe:	0309a503          	lw	a0,48(s3)
    80001b02:	1a09a583          	lw	a1,416(s3)
    80001b06:	bfb9                	j	80001a64 <scheduler+0x9c>

0000000080001b08 <procinit>:
{
    80001b08:	7139                	addi	sp,sp,-64
    80001b0a:	fc06                	sd	ra,56(sp)
    80001b0c:	f822                	sd	s0,48(sp)
    80001b0e:	f426                	sd	s1,40(sp)
    80001b10:	f04a                	sd	s2,32(sp)
    80001b12:	ec4e                	sd	s3,24(sp)
    80001b14:	e852                	sd	s4,16(sp)
    80001b16:	e456                	sd	s5,8(sp)
    80001b18:	e05a                	sd	s6,0(sp)
    80001b1a:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001b1c:	00006597          	auipc	a1,0x6
    80001b20:	6dc58593          	addi	a1,a1,1756 # 800081f8 <digits+0x1b8>
    80001b24:	00010517          	auipc	a0,0x10
    80001b28:	b7c50513          	addi	a0,a0,-1156 # 800116a0 <pid_lock>
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	028080e7          	jalr	40(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b34:	00006597          	auipc	a1,0x6
    80001b38:	6cc58593          	addi	a1,a1,1740 # 80008200 <digits+0x1c0>
    80001b3c:	00010517          	auipc	a0,0x10
    80001b40:	b7c50513          	addi	a0,a0,-1156 # 800116b8 <wait_lock>
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	010080e7          	jalr	16(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b4c:	00010497          	auipc	s1,0x10
    80001b50:	b8448493          	addi	s1,s1,-1148 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001b54:	00006b17          	auipc	s6,0x6
    80001b58:	6bcb0b13          	addi	s6,s6,1724 # 80008210 <digits+0x1d0>
      p->kstack = KSTACK((int) (p - proc));
    80001b5c:	8aa6                	mv	s5,s1
    80001b5e:	00006a17          	auipc	s4,0x6
    80001b62:	4a2a0a13          	addi	s4,s4,1186 # 80008000 <etext>
    80001b66:	04000937          	lui	s2,0x4000
    80001b6a:	197d                	addi	s2,s2,-1
    80001b6c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6e:	00015997          	auipc	s3,0x15
    80001b72:	76298993          	addi	s3,s3,1890 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001b76:	85da                	mv	a1,s6
    80001b78:	8526                	mv	a0,s1
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	fda080e7          	jalr	-38(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b82:	415487b3          	sub	a5,s1,s5
    80001b86:	8791                	srai	a5,a5,0x4
    80001b88:	000a3703          	ld	a4,0(s4)
    80001b8c:	02e787b3          	mul	a5,a5,a4
    80001b90:	2785                	addiw	a5,a5,1
    80001b92:	00d7979b          	slliw	a5,a5,0xd
    80001b96:	40f907b3          	sub	a5,s2,a5
    80001b9a:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b9c:	17048493          	addi	s1,s1,368
    80001ba0:	fd349be3          	bne	s1,s3,80001b76 <procinit+0x6e>
}
    80001ba4:	70e2                	ld	ra,56(sp)
    80001ba6:	7442                	ld	s0,48(sp)
    80001ba8:	74a2                	ld	s1,40(sp)
    80001baa:	7902                	ld	s2,32(sp)
    80001bac:	69e2                	ld	s3,24(sp)
    80001bae:	6a42                	ld	s4,16(sp)
    80001bb0:	6aa2                	ld	s5,8(sp)
    80001bb2:	6b02                	ld	s6,0(sp)
    80001bb4:	6121                	addi	sp,sp,64
    80001bb6:	8082                	ret

0000000080001bb8 <cpuid>:
{
    80001bb8:	1141                	addi	sp,sp,-16
    80001bba:	e422                	sd	s0,8(sp)
    80001bbc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bbe:	8512                	mv	a0,tp
  return id;
}
    80001bc0:	2501                	sext.w	a0,a0
    80001bc2:	6422                	ld	s0,8(sp)
    80001bc4:	0141                	addi	sp,sp,16
    80001bc6:	8082                	ret

0000000080001bc8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bc8:	1141                	addi	sp,sp,-16
    80001bca:	e422                	sd	s0,8(sp)
    80001bcc:	0800                	addi	s0,sp,16
    80001bce:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bd0:	2781                	sext.w	a5,a5
    80001bd2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bd4:	0000f517          	auipc	a0,0xf
    80001bd8:	6cc50513          	addi	a0,a0,1740 # 800112a0 <cpus>
    80001bdc:	953e                	add	a0,a0,a5
    80001bde:	6422                	ld	s0,8(sp)
    80001be0:	0141                	addi	sp,sp,16
    80001be2:	8082                	ret

0000000080001be4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001be4:	1101                	addi	sp,sp,-32
    80001be6:	ec06                	sd	ra,24(sp)
    80001be8:	e822                	sd	s0,16(sp)
    80001bea:	e426                	sd	s1,8(sp)
    80001bec:	1000                	addi	s0,sp,32
  push_off();
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	faa080e7          	jalr	-86(ra) # 80000b98 <push_off>
    80001bf6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bf8:	2781                	sext.w	a5,a5
    80001bfa:	079e                	slli	a5,a5,0x7
    80001bfc:	0000f717          	auipc	a4,0xf
    80001c00:	6a470713          	addi	a4,a4,1700 # 800112a0 <cpus>
    80001c04:	97ba                	add	a5,a5,a4
    80001c06:	6384                	ld	s1,0(a5)
  pop_off();
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	030080e7          	jalr	48(ra) # 80000c38 <pop_off>
  return p;
}
    80001c10:	8526                	mv	a0,s1
    80001c12:	60e2                	ld	ra,24(sp)
    80001c14:	6442                	ld	s0,16(sp)
    80001c16:	64a2                	ld	s1,8(sp)
    80001c18:	6105                	addi	sp,sp,32
    80001c1a:	8082                	ret

0000000080001c1c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c1c:	1141                	addi	sp,sp,-16
    80001c1e:	e406                	sd	ra,8(sp)
    80001c20:	e022                	sd	s0,0(sp)
    80001c22:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	fc0080e7          	jalr	-64(ra) # 80001be4 <myproc>
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	06c080e7          	jalr	108(ra) # 80000c98 <release>

  if (first) {
    80001c34:	00007797          	auipc	a5,0x7
    80001c38:	c0c7a783          	lw	a5,-1012(a5) # 80008840 <first.1698>
    80001c3c:	eb89                	bnez	a5,80001c4e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c3e:	00001097          	auipc	ra,0x1
    80001c42:	b2e080e7          	jalr	-1234(ra) # 8000276c <usertrapret>
}
    80001c46:	60a2                	ld	ra,8(sp)
    80001c48:	6402                	ld	s0,0(sp)
    80001c4a:	0141                	addi	sp,sp,16
    80001c4c:	8082                	ret
    first = 0;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	be07a923          	sw	zero,-1038(a5) # 80008840 <first.1698>
    fsinit(ROOTDEV);
    80001c56:	4505                	li	a0,1
    80001c58:	00002097          	auipc	ra,0x2
    80001c5c:	8a0080e7          	jalr	-1888(ra) # 800034f8 <fsinit>
    80001c60:	bff9                	j	80001c3e <forkret+0x22>

0000000080001c62 <allocpid>:
allocpid() {
    80001c62:	1101                	addi	sp,sp,-32
    80001c64:	ec06                	sd	ra,24(sp)
    80001c66:	e822                	sd	s0,16(sp)
    80001c68:	e426                	sd	s1,8(sp)
    80001c6a:	e04a                	sd	s2,0(sp)
    80001c6c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c6e:	00010917          	auipc	s2,0x10
    80001c72:	a3290913          	addi	s2,s2,-1486 # 800116a0 <pid_lock>
    80001c76:	854a                	mv	a0,s2
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	f6c080e7          	jalr	-148(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	bc478793          	addi	a5,a5,-1084 # 80008844 <nextpid>
    80001c88:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c8a:	0014871b          	addiw	a4,s1,1
    80001c8e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c90:	854a                	mv	a0,s2
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
}
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	60e2                	ld	ra,24(sp)
    80001c9e:	6442                	ld	s0,16(sp)
    80001ca0:	64a2                	ld	s1,8(sp)
    80001ca2:	6902                	ld	s2,0(sp)
    80001ca4:	6105                	addi	sp,sp,32
    80001ca6:	8082                	ret

0000000080001ca8 <proc_pagetable>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	e04a                	sd	s2,0(sp)
    80001cb2:	1000                	addi	s0,sp,32
    80001cb4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	684080e7          	jalr	1668(ra) # 8000133a <uvmcreate>
    80001cbe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cc0:	c121                	beqz	a0,80001d00 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cc2:	4729                	li	a4,10
    80001cc4:	00005697          	auipc	a3,0x5
    80001cc8:	33c68693          	addi	a3,a3,828 # 80007000 <_trampoline>
    80001ccc:	6605                	lui	a2,0x1
    80001cce:	040005b7          	lui	a1,0x4000
    80001cd2:	15fd                	addi	a1,a1,-1
    80001cd4:	05b2                	slli	a1,a1,0xc
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	3da080e7          	jalr	986(ra) # 800010b0 <mappages>
    80001cde:	02054863          	bltz	a0,80001d0e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ce2:	4719                	li	a4,6
    80001ce4:	06093683          	ld	a3,96(s2)
    80001ce8:	6605                	lui	a2,0x1
    80001cea:	020005b7          	lui	a1,0x2000
    80001cee:	15fd                	addi	a1,a1,-1
    80001cf0:	05b6                	slli	a1,a1,0xd
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	3bc080e7          	jalr	956(ra) # 800010b0 <mappages>
    80001cfc:	02054163          	bltz	a0,80001d1e <proc_pagetable+0x76>
}
    80001d00:	8526                	mv	a0,s1
    80001d02:	60e2                	ld	ra,24(sp)
    80001d04:	6442                	ld	s0,16(sp)
    80001d06:	64a2                	ld	s1,8(sp)
    80001d08:	6902                	ld	s2,0(sp)
    80001d0a:	6105                	addi	sp,sp,32
    80001d0c:	8082                	ret
    uvmfree(pagetable, 0);
    80001d0e:	4581                	li	a1,0
    80001d10:	8526                	mv	a0,s1
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	824080e7          	jalr	-2012(ra) # 80001536 <uvmfree>
    return 0;
    80001d1a:	4481                	li	s1,0
    80001d1c:	b7d5                	j	80001d00 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d1e:	4681                	li	a3,0
    80001d20:	4605                	li	a2,1
    80001d22:	040005b7          	lui	a1,0x4000
    80001d26:	15fd                	addi	a1,a1,-1
    80001d28:	05b2                	slli	a1,a1,0xc
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	54a080e7          	jalr	1354(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d34:	4581                	li	a1,0
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	7fe080e7          	jalr	2046(ra) # 80001536 <uvmfree>
    return 0;
    80001d40:	4481                	li	s1,0
    80001d42:	bf7d                	j	80001d00 <proc_pagetable+0x58>

0000000080001d44 <proc_freepagetable>:
{
    80001d44:	1101                	addi	sp,sp,-32
    80001d46:	ec06                	sd	ra,24(sp)
    80001d48:	e822                	sd	s0,16(sp)
    80001d4a:	e426                	sd	s1,8(sp)
    80001d4c:	e04a                	sd	s2,0(sp)
    80001d4e:	1000                	addi	s0,sp,32
    80001d50:	84aa                	mv	s1,a0
    80001d52:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d54:	4681                	li	a3,0
    80001d56:	4605                	li	a2,1
    80001d58:	040005b7          	lui	a1,0x4000
    80001d5c:	15fd                	addi	a1,a1,-1
    80001d5e:	05b2                	slli	a1,a1,0xc
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	516080e7          	jalr	1302(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d68:	4681                	li	a3,0
    80001d6a:	4605                	li	a2,1
    80001d6c:	020005b7          	lui	a1,0x2000
    80001d70:	15fd                	addi	a1,a1,-1
    80001d72:	05b6                	slli	a1,a1,0xd
    80001d74:	8526                	mv	a0,s1
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	500080e7          	jalr	1280(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d7e:	85ca                	mv	a1,s2
    80001d80:	8526                	mv	a0,s1
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	7b4080e7          	jalr	1972(ra) # 80001536 <uvmfree>
}
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6902                	ld	s2,0(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <freeproc>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	1000                	addi	s0,sp,32
    80001da0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001da2:	7128                	ld	a0,96(a0)
    80001da4:	c509                	beqz	a0,80001dae <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	c52080e7          	jalr	-942(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001dae:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001db2:	6ca8                	ld	a0,88(s1)
    80001db4:	c511                	beqz	a0,80001dc0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001db6:	68ac                	ld	a1,80(s1)
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	f8c080e7          	jalr	-116(ra) # 80001d44 <proc_freepagetable>
  p->pagetable = 0;
    80001dc0:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001dc4:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001dc8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dcc:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001dd0:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001dd4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dd8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ddc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001de0:	0004ac23          	sw	zero,24(s1)
}
    80001de4:	60e2                	ld	ra,24(sp)
    80001de6:	6442                	ld	s0,16(sp)
    80001de8:	64a2                	ld	s1,8(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret

0000000080001dee <allocproc>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	e04a                	sd	s2,0(sp)
    80001df8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dfa:	00010497          	auipc	s1,0x10
    80001dfe:	8d648493          	addi	s1,s1,-1834 # 800116d0 <proc>
    80001e02:	00015917          	auipc	s2,0x15
    80001e06:	4ce90913          	addi	s2,s2,1230 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	dd8080e7          	jalr	-552(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001e14:	4c9c                	lw	a5,24(s1)
    80001e16:	cf81                	beqz	a5,80001e2e <allocproc+0x40>
      release(&p->lock);
    80001e18:	8526                	mv	a0,s1
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	e7e080e7          	jalr	-386(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e22:	17048493          	addi	s1,s1,368
    80001e26:	ff2492e3          	bne	s1,s2,80001e0a <allocproc+0x1c>
  return 0;
    80001e2a:	4481                	li	s1,0
    80001e2c:	a8a9                	j	80001e86 <allocproc+0x98>
  p->pid = allocpid();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	e34080e7          	jalr	-460(ra) # 80001c62 <allocpid>
    80001e36:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e38:	4785                	li	a5,1
    80001e3a:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001e3c:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001e40:	0204ac23          	sw	zero,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	cb0080e7          	jalr	-848(ra) # 80000af4 <kalloc>
    80001e4c:	892a                	mv	s2,a0
    80001e4e:	f0a8                	sd	a0,96(s1)
    80001e50:	c131                	beqz	a0,80001e94 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001e52:	8526                	mv	a0,s1
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	e54080e7          	jalr	-428(ra) # 80001ca8 <proc_pagetable>
    80001e5c:	892a                	mv	s2,a0
    80001e5e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001e60:	c531                	beqz	a0,80001eac <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001e62:	07000613          	li	a2,112
    80001e66:	4581                	li	a1,0
    80001e68:	06848513          	addi	a0,s1,104
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e74080e7          	jalr	-396(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001e74:	00000797          	auipc	a5,0x0
    80001e78:	da878793          	addi	a5,a5,-600 # 80001c1c <forkret>
    80001e7c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e7e:	64bc                	ld	a5,72(s1)
    80001e80:	6705                	lui	a4,0x1
    80001e82:	97ba                	add	a5,a5,a4
    80001e84:	f8bc                	sd	a5,112(s1)
}
    80001e86:	8526                	mv	a0,s1
    80001e88:	60e2                	ld	ra,24(sp)
    80001e8a:	6442                	ld	s0,16(sp)
    80001e8c:	64a2                	ld	s1,8(sp)
    80001e8e:	6902                	ld	s2,0(sp)
    80001e90:	6105                	addi	sp,sp,32
    80001e92:	8082                	ret
    freeproc(p);
    80001e94:	8526                	mv	a0,s1
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	f00080e7          	jalr	-256(ra) # 80001d96 <freeproc>
    release(&p->lock);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
    return 0;
    80001ea8:	84ca                	mv	s1,s2
    80001eaa:	bff1                	j	80001e86 <allocproc+0x98>
    freeproc(p);
    80001eac:	8526                	mv	a0,s1
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	ee8080e7          	jalr	-280(ra) # 80001d96 <freeproc>
    release(&p->lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
    return 0;
    80001ec0:	84ca                	mv	s1,s2
    80001ec2:	b7d1                	j	80001e86 <allocproc+0x98>

0000000080001ec4 <userinit>:
{
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	f20080e7          	jalr	-224(ra) # 80001dee <allocproc>
    80001ed6:	84aa                	mv	s1,a0
  initproc = p;
    80001ed8:	00007797          	auipc	a5,0x7
    80001edc:	14a7bc23          	sd	a0,344(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ee0:	03400613          	li	a2,52
    80001ee4:	00007597          	auipc	a1,0x7
    80001ee8:	96c58593          	addi	a1,a1,-1684 # 80008850 <initcode>
    80001eec:	6d28                	ld	a0,88(a0)
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	47a080e7          	jalr	1146(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001ef6:	6785                	lui	a5,0x1
    80001ef8:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001efa:	70b8                	ld	a4,96(s1)
    80001efc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f00:	70b8                	ld	a4,96(s1)
    80001f02:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f04:	4641                	li	a2,16
    80001f06:	00006597          	auipc	a1,0x6
    80001f0a:	31258593          	addi	a1,a1,786 # 80008218 <digits+0x1d8>
    80001f0e:	16048513          	addi	a0,s1,352
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	f20080e7          	jalr	-224(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001f1a:	00006517          	auipc	a0,0x6
    80001f1e:	30e50513          	addi	a0,a0,782 # 80008228 <digits+0x1e8>
    80001f22:	00002097          	auipc	ra,0x2
    80001f26:	004080e7          	jalr	4(ra) # 80003f26 <namei>
    80001f2a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001f2e:	478d                	li	a5,3
    80001f30:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	d64080e7          	jalr	-668(ra) # 80000c98 <release>
}
    80001f3c:	60e2                	ld	ra,24(sp)
    80001f3e:	6442                	ld	s0,16(sp)
    80001f40:	64a2                	ld	s1,8(sp)
    80001f42:	6105                	addi	sp,sp,32
    80001f44:	8082                	ret

0000000080001f46 <growproc>:
{
    80001f46:	1101                	addi	sp,sp,-32
    80001f48:	ec06                	sd	ra,24(sp)
    80001f4a:	e822                	sd	s0,16(sp)
    80001f4c:	e426                	sd	s1,8(sp)
    80001f4e:	e04a                	sd	s2,0(sp)
    80001f50:	1000                	addi	s0,sp,32
    80001f52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	c90080e7          	jalr	-880(ra) # 80001be4 <myproc>
    80001f5c:	892a                	mv	s2,a0
  sz = p->sz;
    80001f5e:	692c                	ld	a1,80(a0)
    80001f60:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f64:	00904f63          	bgtz	s1,80001f82 <growproc+0x3c>
  } else if(n < 0){
    80001f68:	0204cc63          	bltz	s1,80001fa0 <growproc+0x5a>
  p->sz = sz;
    80001f6c:	1602                	slli	a2,a2,0x20
    80001f6e:	9201                	srli	a2,a2,0x20
    80001f70:	04c93823          	sd	a2,80(s2)
  return 0;
    80001f74:	4501                	li	a0,0
}
    80001f76:	60e2                	ld	ra,24(sp)
    80001f78:	6442                	ld	s0,16(sp)
    80001f7a:	64a2                	ld	s1,8(sp)
    80001f7c:	6902                	ld	s2,0(sp)
    80001f7e:	6105                	addi	sp,sp,32
    80001f80:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f82:	9e25                	addw	a2,a2,s1
    80001f84:	1602                	slli	a2,a2,0x20
    80001f86:	9201                	srli	a2,a2,0x20
    80001f88:	1582                	slli	a1,a1,0x20
    80001f8a:	9181                	srli	a1,a1,0x20
    80001f8c:	6d28                	ld	a0,88(a0)
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	494080e7          	jalr	1172(ra) # 80001422 <uvmalloc>
    80001f96:	0005061b          	sext.w	a2,a0
    80001f9a:	fa69                	bnez	a2,80001f6c <growproc+0x26>
      return -1;
    80001f9c:	557d                	li	a0,-1
    80001f9e:	bfe1                	j	80001f76 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fa0:	9e25                	addw	a2,a2,s1
    80001fa2:	1602                	slli	a2,a2,0x20
    80001fa4:	9201                	srli	a2,a2,0x20
    80001fa6:	1582                	slli	a1,a1,0x20
    80001fa8:	9181                	srli	a1,a1,0x20
    80001faa:	6d28                	ld	a0,88(a0)
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	42e080e7          	jalr	1070(ra) # 800013da <uvmdealloc>
    80001fb4:	0005061b          	sext.w	a2,a0
    80001fb8:	bf55                	j	80001f6c <growproc+0x26>

0000000080001fba <fork>:
{
    80001fba:	7179                	addi	sp,sp,-48
    80001fbc:	f406                	sd	ra,40(sp)
    80001fbe:	f022                	sd	s0,32(sp)
    80001fc0:	ec26                	sd	s1,24(sp)
    80001fc2:	e84a                	sd	s2,16(sp)
    80001fc4:	e44e                	sd	s3,8(sp)
    80001fc6:	e052                	sd	s4,0(sp)
    80001fc8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	c1a080e7          	jalr	-998(ra) # 80001be4 <myproc>
    80001fd2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	e1a080e7          	jalr	-486(ra) # 80001dee <allocproc>
    80001fdc:	10050b63          	beqz	a0,800020f2 <fork+0x138>
    80001fe0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fe2:	05093603          	ld	a2,80(s2)
    80001fe6:	6d2c                	ld	a1,88(a0)
    80001fe8:	05893503          	ld	a0,88(s2)
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	582080e7          	jalr	1410(ra) # 8000156e <uvmcopy>
    80001ff4:	04054663          	bltz	a0,80002040 <fork+0x86>
  np->sz = p->sz;
    80001ff8:	05093783          	ld	a5,80(s2)
    80001ffc:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80002000:	06093683          	ld	a3,96(s2)
    80002004:	87b6                	mv	a5,a3
    80002006:	0609b703          	ld	a4,96(s3)
    8000200a:	12068693          	addi	a3,a3,288
    8000200e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002012:	6788                	ld	a0,8(a5)
    80002014:	6b8c                	ld	a1,16(a5)
    80002016:	6f90                	ld	a2,24(a5)
    80002018:	01073023          	sd	a6,0(a4)
    8000201c:	e708                	sd	a0,8(a4)
    8000201e:	eb0c                	sd	a1,16(a4)
    80002020:	ef10                	sd	a2,24(a4)
    80002022:	02078793          	addi	a5,a5,32
    80002026:	02070713          	addi	a4,a4,32
    8000202a:	fed792e3          	bne	a5,a3,8000200e <fork+0x54>
  np->trapframe->a0 = 0;
    8000202e:	0609b783          	ld	a5,96(s3)
    80002032:	0607b823          	sd	zero,112(a5)
    80002036:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000203a:	15800a13          	li	s4,344
    8000203e:	a03d                	j	8000206c <fork+0xb2>
    freeproc(np);
    80002040:	854e                	mv	a0,s3
    80002042:	00000097          	auipc	ra,0x0
    80002046:	d54080e7          	jalr	-684(ra) # 80001d96 <freeproc>
    release(&np->lock);
    8000204a:	854e                	mv	a0,s3
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c4c080e7          	jalr	-948(ra) # 80000c98 <release>
    return -1;
    80002054:	5a7d                	li	s4,-1
    80002056:	a069                	j	800020e0 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80002058:	00002097          	auipc	ra,0x2
    8000205c:	564080e7          	jalr	1380(ra) # 800045bc <filedup>
    80002060:	009987b3          	add	a5,s3,s1
    80002064:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002066:	04a1                	addi	s1,s1,8
    80002068:	01448763          	beq	s1,s4,80002076 <fork+0xbc>
    if(p->ofile[i])
    8000206c:	009907b3          	add	a5,s2,s1
    80002070:	6388                	ld	a0,0(a5)
    80002072:	f17d                	bnez	a0,80002058 <fork+0x9e>
    80002074:	bfcd                	j	80002066 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002076:	15893503          	ld	a0,344(s2)
    8000207a:	00001097          	auipc	ra,0x1
    8000207e:	6b8080e7          	jalr	1720(ra) # 80003732 <idup>
    80002082:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002086:	4641                	li	a2,16
    80002088:	16090593          	addi	a1,s2,352
    8000208c:	16098513          	addi	a0,s3,352
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	da2080e7          	jalr	-606(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002098:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    8000209c:	854e                	mv	a0,s3
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	bfa080e7          	jalr	-1030(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800020a6:	0000f497          	auipc	s1,0xf
    800020aa:	61248493          	addi	s1,s1,1554 # 800116b8 <wait_lock>
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	b34080e7          	jalr	-1228(ra) # 80000be4 <acquire>
  np->parent = p;
    800020b8:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
  acquire(&np->lock);
    800020c6:	854e                	mv	a0,s3
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b1c080e7          	jalr	-1252(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800020d0:	478d                	li	a5,3
    800020d2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020d6:	854e                	mv	a0,s3
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
}
    800020e0:	8552                	mv	a0,s4
    800020e2:	70a2                	ld	ra,40(sp)
    800020e4:	7402                	ld	s0,32(sp)
    800020e6:	64e2                	ld	s1,24(sp)
    800020e8:	6942                	ld	s2,16(sp)
    800020ea:	69a2                	ld	s3,8(sp)
    800020ec:	6a02                	ld	s4,0(sp)
    800020ee:	6145                	addi	sp,sp,48
    800020f0:	8082                	ret
    return -1;
    800020f2:	5a7d                	li	s4,-1
    800020f4:	b7f5                	j	800020e0 <fork+0x126>

00000000800020f6 <sched>:
{
    800020f6:	7179                	addi	sp,sp,-48
    800020f8:	f406                	sd	ra,40(sp)
    800020fa:	f022                	sd	s0,32(sp)
    800020fc:	ec26                	sd	s1,24(sp)
    800020fe:	e84a                	sd	s2,16(sp)
    80002100:	e44e                	sd	s3,8(sp)
    80002102:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	ae0080e7          	jalr	-1312(ra) # 80001be4 <myproc>
    8000210c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	a5c080e7          	jalr	-1444(ra) # 80000b6a <holding>
    80002116:	c53d                	beqz	a0,80002184 <sched+0x8e>
    80002118:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000211a:	2781                	sext.w	a5,a5
    8000211c:	079e                	slli	a5,a5,0x7
    8000211e:	0000f717          	auipc	a4,0xf
    80002122:	18270713          	addi	a4,a4,386 # 800112a0 <cpus>
    80002126:	97ba                	add	a5,a5,a4
    80002128:	5fb8                	lw	a4,120(a5)
    8000212a:	4785                	li	a5,1
    8000212c:	06f71463          	bne	a4,a5,80002194 <sched+0x9e>
  if(p->state == RUNNING)
    80002130:	4c98                	lw	a4,24(s1)
    80002132:	4791                	li	a5,4
    80002134:	06f70863          	beq	a4,a5,800021a4 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002138:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000213c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000213e:	ebbd                	bnez	a5,800021b4 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002140:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002142:	0000f917          	auipc	s2,0xf
    80002146:	15e90913          	addi	s2,s2,350 # 800112a0 <cpus>
    8000214a:	2781                	sext.w	a5,a5
    8000214c:	079e                	slli	a5,a5,0x7
    8000214e:	97ca                	add	a5,a5,s2
    80002150:	07c7a983          	lw	s3,124(a5)
    80002154:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002156:	2581                	sext.w	a1,a1
    80002158:	059e                	slli	a1,a1,0x7
    8000215a:	05a1                	addi	a1,a1,8
    8000215c:	95ca                	add	a1,a1,s2
    8000215e:	06848513          	addi	a0,s1,104
    80002162:	00000097          	auipc	ra,0x0
    80002166:	560080e7          	jalr	1376(ra) # 800026c2 <swtch>
    8000216a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000216c:	2781                	sext.w	a5,a5
    8000216e:	079e                	slli	a5,a5,0x7
    80002170:	993e                	add	s2,s2,a5
    80002172:	07392e23          	sw	s3,124(s2)
}
    80002176:	70a2                	ld	ra,40(sp)
    80002178:	7402                	ld	s0,32(sp)
    8000217a:	64e2                	ld	s1,24(sp)
    8000217c:	6942                	ld	s2,16(sp)
    8000217e:	69a2                	ld	s3,8(sp)
    80002180:	6145                	addi	sp,sp,48
    80002182:	8082                	ret
    panic("sched p->lock");
    80002184:	00006517          	auipc	a0,0x6
    80002188:	0ac50513          	addi	a0,a0,172 # 80008230 <digits+0x1f0>
    8000218c:	ffffe097          	auipc	ra,0xffffe
    80002190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
    panic("sched locks");
    80002194:	00006517          	auipc	a0,0x6
    80002198:	0ac50513          	addi	a0,a0,172 # 80008240 <digits+0x200>
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>
    panic("sched running");
    800021a4:	00006517          	auipc	a0,0x6
    800021a8:	0ac50513          	addi	a0,a0,172 # 80008250 <digits+0x210>
    800021ac:	ffffe097          	auipc	ra,0xffffe
    800021b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021b4:	00006517          	auipc	a0,0x6
    800021b8:	0ac50513          	addi	a0,a0,172 # 80008260 <digits+0x220>
    800021bc:	ffffe097          	auipc	ra,0xffffe
    800021c0:	382080e7          	jalr	898(ra) # 8000053e <panic>

00000000800021c4 <yield>:
{
    800021c4:	1101                	addi	sp,sp,-32
    800021c6:	ec06                	sd	ra,24(sp)
    800021c8:	e822                	sd	s0,16(sp)
    800021ca:	e426                	sd	s1,8(sp)
    800021cc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	a16080e7          	jalr	-1514(ra) # 80001be4 <myproc>
    800021d6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	a0c080e7          	jalr	-1524(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021e0:	478d                	li	a5,3
    800021e2:	cc9c                	sw	a5,24(s1)
  sched();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	f12080e7          	jalr	-238(ra) # 800020f6 <sched>
  release(&p->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
}
    800021f6:	60e2                	ld	ra,24(sp)
    800021f8:	6442                	ld	s0,16(sp)
    800021fa:	64a2                	ld	s1,8(sp)
    800021fc:	6105                	addi	sp,sp,32
    800021fe:	8082                	ret

0000000080002200 <pause_sys>:
{
    80002200:	1141                	addi	sp,sp,-16
    80002202:	e406                	sd	ra,8(sp)
    80002204:	e022                	sd	s0,0(sp)
    80002206:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    80002208:	0025179b          	slliw	a5,a0,0x2
    8000220c:	9fa9                	addw	a5,a5,a0
    8000220e:	0017979b          	slliw	a5,a5,0x1
    80002212:	00007517          	auipc	a0,0x7
    80002216:	e2652503          	lw	a0,-474(a0) # 80009038 <ticks>
    8000221a:	9fa9                	addw	a5,a5,a0
    8000221c:	00007717          	auipc	a4,0x7
    80002220:	e0f72623          	sw	a5,-500(a4) # 80009028 <finish>
  yield();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	fa0080e7          	jalr	-96(ra) # 800021c4 <yield>
}
    8000222c:	4501                	li	a0,0
    8000222e:	60a2                	ld	ra,8(sp)
    80002230:	6402                	ld	s0,0(sp)
    80002232:	0141                	addi	sp,sp,16
    80002234:	8082                	ret

0000000080002236 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002236:	7179                	addi	sp,sp,-48
    80002238:	f406                	sd	ra,40(sp)
    8000223a:	f022                	sd	s0,32(sp)
    8000223c:	ec26                	sd	s1,24(sp)
    8000223e:	e84a                	sd	s2,16(sp)
    80002240:	e44e                	sd	s3,8(sp)
    80002242:	1800                	addi	s0,sp,48
    80002244:	89aa                	mv	s3,a0
    80002246:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	99c080e7          	jalr	-1636(ra) # 80001be4 <myproc>
    80002250:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	992080e7          	jalr	-1646(ra) # 80000be4 <acquire>
  release(lk);
    8000225a:	854a                	mv	a0,s2
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a3c080e7          	jalr	-1476(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002264:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002268:	4789                	li	a5,2
    8000226a:	cc9c                	sw	a5,24(s1)

  sched();
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	e8a080e7          	jalr	-374(ra) # 800020f6 <sched>

  // Tidy up.
  p->chan = 0;
    80002274:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a1e080e7          	jalr	-1506(ra) # 80000c98 <release>
  acquire(lk);
    80002282:	854a                	mv	a0,s2
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
}
    8000228c:	70a2                	ld	ra,40(sp)
    8000228e:	7402                	ld	s0,32(sp)
    80002290:	64e2                	ld	s1,24(sp)
    80002292:	6942                	ld	s2,16(sp)
    80002294:	69a2                	ld	s3,8(sp)
    80002296:	6145                	addi	sp,sp,48
    80002298:	8082                	ret

000000008000229a <wait>:
{
    8000229a:	715d                	addi	sp,sp,-80
    8000229c:	e486                	sd	ra,72(sp)
    8000229e:	e0a2                	sd	s0,64(sp)
    800022a0:	fc26                	sd	s1,56(sp)
    800022a2:	f84a                	sd	s2,48(sp)
    800022a4:	f44e                	sd	s3,40(sp)
    800022a6:	f052                	sd	s4,32(sp)
    800022a8:	ec56                	sd	s5,24(sp)
    800022aa:	e85a                	sd	s6,16(sp)
    800022ac:	e45e                	sd	s7,8(sp)
    800022ae:	e062                	sd	s8,0(sp)
    800022b0:	0880                	addi	s0,sp,80
    800022b2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	930080e7          	jalr	-1744(ra) # 80001be4 <myproc>
    800022bc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022be:	0000f517          	auipc	a0,0xf
    800022c2:	3fa50513          	addi	a0,a0,1018 # 800116b8 <wait_lock>
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	91e080e7          	jalr	-1762(ra) # 80000be4 <acquire>
    havekids = 0;
    800022ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022d0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022d2:	00015997          	auipc	s3,0x15
    800022d6:	ffe98993          	addi	s3,s3,-2 # 800172d0 <tickslock>
        havekids = 1;
    800022da:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022dc:	0000fc17          	auipc	s8,0xf
    800022e0:	3dcc0c13          	addi	s8,s8,988 # 800116b8 <wait_lock>
    havekids = 0;
    800022e4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022e6:	0000f497          	auipc	s1,0xf
    800022ea:	3ea48493          	addi	s1,s1,1002 # 800116d0 <proc>
    800022ee:	a0bd                	j	8000235c <wait+0xc2>
          pid = np->pid;
    800022f0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022f4:	000b0e63          	beqz	s6,80002310 <wait+0x76>
    800022f8:	4691                	li	a3,4
    800022fa:	02c48613          	addi	a2,s1,44
    800022fe:	85da                	mv	a1,s6
    80002300:	05893503          	ld	a0,88(s2)
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	36e080e7          	jalr	878(ra) # 80001672 <copyout>
    8000230c:	02054563          	bltz	a0,80002336 <wait+0x9c>
          freeproc(np);
    80002310:	8526                	mv	a0,s1
    80002312:	00000097          	auipc	ra,0x0
    80002316:	a84080e7          	jalr	-1404(ra) # 80001d96 <freeproc>
          release(&np->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
          release(&wait_lock);
    80002324:	0000f517          	auipc	a0,0xf
    80002328:	39450513          	addi	a0,a0,916 # 800116b8 <wait_lock>
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	96c080e7          	jalr	-1684(ra) # 80000c98 <release>
          return pid;
    80002334:	a09d                	j	8000239a <wait+0x100>
            release(&np->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	960080e7          	jalr	-1696(ra) # 80000c98 <release>
            release(&wait_lock);
    80002340:	0000f517          	auipc	a0,0xf
    80002344:	37850513          	addi	a0,a0,888 # 800116b8 <wait_lock>
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
            return -1;
    80002350:	59fd                	li	s3,-1
    80002352:	a0a1                	j	8000239a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002354:	17048493          	addi	s1,s1,368
    80002358:	03348463          	beq	s1,s3,80002380 <wait+0xe6>
      if(np->parent == p){
    8000235c:	60bc                	ld	a5,64(s1)
    8000235e:	ff279be3          	bne	a5,s2,80002354 <wait+0xba>
        acquire(&np->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	880080e7          	jalr	-1920(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000236c:	4c9c                	lw	a5,24(s1)
    8000236e:	f94781e3          	beq	a5,s4,800022f0 <wait+0x56>
        release(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
        havekids = 1;
    8000237c:	8756                	mv	a4,s5
    8000237e:	bfd9                	j	80002354 <wait+0xba>
    if(!havekids || p->killed){
    80002380:	c701                	beqz	a4,80002388 <wait+0xee>
    80002382:	02892783          	lw	a5,40(s2)
    80002386:	c79d                	beqz	a5,800023b4 <wait+0x11a>
      release(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	33050513          	addi	a0,a0,816 # 800116b8 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
      return -1;
    80002398:	59fd                	li	s3,-1
}
    8000239a:	854e                	mv	a0,s3
    8000239c:	60a6                	ld	ra,72(sp)
    8000239e:	6406                	ld	s0,64(sp)
    800023a0:	74e2                	ld	s1,56(sp)
    800023a2:	7942                	ld	s2,48(sp)
    800023a4:	79a2                	ld	s3,40(sp)
    800023a6:	7a02                	ld	s4,32(sp)
    800023a8:	6ae2                	ld	s5,24(sp)
    800023aa:	6b42                	ld	s6,16(sp)
    800023ac:	6ba2                	ld	s7,8(sp)
    800023ae:	6c02                	ld	s8,0(sp)
    800023b0:	6161                	addi	sp,sp,80
    800023b2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023b4:	85e2                	mv	a1,s8
    800023b6:	854a                	mv	a0,s2
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	e7e080e7          	jalr	-386(ra) # 80002236 <sleep>
    havekids = 0;
    800023c0:	b715                	j	800022e4 <wait+0x4a>

00000000800023c2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	0080                	addi	s0,sp,64
    800023d4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023d6:	0000f497          	auipc	s1,0xf
    800023da:	2fa48493          	addi	s1,s1,762 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023e0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e2:	00015917          	auipc	s2,0x15
    800023e6:	eee90913          	addi	s2,s2,-274 # 800172d0 <tickslock>
    800023ea:	a821                	j	80002402 <wakeup+0x40>
        p->state = RUNNABLE;
    800023ec:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	17048493          	addi	s1,s1,368
    800023fe:	03248463          	beq	s1,s2,80002426 <wakeup+0x64>
    if(p != myproc()){
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	7e2080e7          	jalr	2018(ra) # 80001be4 <myproc>
    8000240a:	fea488e3          	beq	s1,a0,800023fa <wakeup+0x38>
      acquire(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	fd379be3          	bne	a5,s3,800023f0 <wakeup+0x2e>
    8000241e:	709c                	ld	a5,32(s1)
    80002420:	fd4798e3          	bne	a5,s4,800023f0 <wakeup+0x2e>
    80002424:	b7e1                	j	800023ec <wakeup+0x2a>
    }
  }
}
    80002426:	70e2                	ld	ra,56(sp)
    80002428:	7442                	ld	s0,48(sp)
    8000242a:	74a2                	ld	s1,40(sp)
    8000242c:	7902                	ld	s2,32(sp)
    8000242e:	69e2                	ld	s3,24(sp)
    80002430:	6a42                	ld	s4,16(sp)
    80002432:	6aa2                	ld	s5,8(sp)
    80002434:	6121                	addi	sp,sp,64
    80002436:	8082                	ret

0000000080002438 <reparent>:
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	e052                	sd	s4,0(sp)
    80002446:	1800                	addi	s0,sp,48
    80002448:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000244a:	0000f497          	auipc	s1,0xf
    8000244e:	28648493          	addi	s1,s1,646 # 800116d0 <proc>
      pp->parent = initproc;
    80002452:	00007a17          	auipc	s4,0x7
    80002456:	bdea0a13          	addi	s4,s4,-1058 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245a:	00015997          	auipc	s3,0x15
    8000245e:	e7698993          	addi	s3,s3,-394 # 800172d0 <tickslock>
    80002462:	a029                	j	8000246c <reparent+0x34>
    80002464:	17048493          	addi	s1,s1,368
    80002468:	01348d63          	beq	s1,s3,80002482 <reparent+0x4a>
    if(pp->parent == p){
    8000246c:	60bc                	ld	a5,64(s1)
    8000246e:	ff279be3          	bne	a5,s2,80002464 <reparent+0x2c>
      pp->parent = initproc;
    80002472:	000a3503          	ld	a0,0(s4)
    80002476:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	f4a080e7          	jalr	-182(ra) # 800023c2 <wakeup>
    80002480:	b7d5                	j	80002464 <reparent+0x2c>
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret

0000000080002492 <exit>:
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	740080e7          	jalr	1856(ra) # 80001be4 <myproc>
    800024ac:	89aa                	mv	s3,a0
  if(p == initproc)
    800024ae:	00007797          	auipc	a5,0x7
    800024b2:	b827b783          	ld	a5,-1150(a5) # 80009030 <initproc>
    800024b6:	0d850493          	addi	s1,a0,216
    800024ba:	15850913          	addi	s2,a0,344
    800024be:	02a79363          	bne	a5,a0,800024e4 <exit+0x52>
    panic("init exiting");
    800024c2:	00006517          	auipc	a0,0x6
    800024c6:	db650513          	addi	a0,a0,-586 # 80008278 <digits+0x238>
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	074080e7          	jalr	116(ra) # 8000053e <panic>
      fileclose(f);
    800024d2:	00002097          	auipc	ra,0x2
    800024d6:	13c080e7          	jalr	316(ra) # 8000460e <fileclose>
      p->ofile[fd] = 0;
    800024da:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024de:	04a1                	addi	s1,s1,8
    800024e0:	01248563          	beq	s1,s2,800024ea <exit+0x58>
    if(p->ofile[fd]){
    800024e4:	6088                	ld	a0,0(s1)
    800024e6:	f575                	bnez	a0,800024d2 <exit+0x40>
    800024e8:	bfdd                	j	800024de <exit+0x4c>
  begin_op();
    800024ea:	00002097          	auipc	ra,0x2
    800024ee:	c58080e7          	jalr	-936(ra) # 80004142 <begin_op>
  iput(p->cwd);
    800024f2:	1589b503          	ld	a0,344(s3)
    800024f6:	00001097          	auipc	ra,0x1
    800024fa:	434080e7          	jalr	1076(ra) # 8000392a <iput>
  end_op();
    800024fe:	00002097          	auipc	ra,0x2
    80002502:	cc4080e7          	jalr	-828(ra) # 800041c2 <end_op>
  p->cwd = 0;
    80002506:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000250a:	0000f497          	auipc	s1,0xf
    8000250e:	1ae48493          	addi	s1,s1,430 # 800116b8 <wait_lock>
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6d0080e7          	jalr	1744(ra) # 80000be4 <acquire>
  reparent(p);
    8000251c:	854e                	mv	a0,s3
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	f1a080e7          	jalr	-230(ra) # 80002438 <reparent>
  wakeup(p->parent);
    80002526:	0409b503          	ld	a0,64(s3)
    8000252a:	00000097          	auipc	ra,0x0
    8000252e:	e98080e7          	jalr	-360(ra) # 800023c2 <wakeup>
  acquire(&p->lock);
    80002532:	854e                	mv	a0,s3
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	6b0080e7          	jalr	1712(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000253c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002540:	4795                	li	a5,5
    80002542:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	750080e7          	jalr	1872(ra) # 80000c98 <release>
  sched();
    80002550:	00000097          	auipc	ra,0x0
    80002554:	ba6080e7          	jalr	-1114(ra) # 800020f6 <sched>
  panic("zombie exit");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	d3050513          	addi	a0,a0,-720 # 80008288 <digits+0x248>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	fde080e7          	jalr	-34(ra) # 8000053e <panic>

0000000080002568 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	e052                	sd	s4,0(sp)
    80002576:	1800                	addi	s0,sp,48
    80002578:	84aa                	mv	s1,a0
    8000257a:	892e                	mv	s2,a1
    8000257c:	89b2                	mv	s3,a2
    8000257e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	664080e7          	jalr	1636(ra) # 80001be4 <myproc>
  if(user_dst){
    80002588:	c08d                	beqz	s1,800025aa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000258a:	86d2                	mv	a3,s4
    8000258c:	864e                	mv	a2,s3
    8000258e:	85ca                	mv	a1,s2
    80002590:	6d28                	ld	a0,88(a0)
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	0e0080e7          	jalr	224(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6a02                	ld	s4,0(sp)
    800025a6:	6145                	addi	sp,sp,48
    800025a8:	8082                	ret
    memmove((char *)dst, src, len);
    800025aa:	000a061b          	sext.w	a2,s4
    800025ae:	85ce                	mv	a1,s3
    800025b0:	854a                	mv	a0,s2
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	78e080e7          	jalr	1934(ra) # 80000d40 <memmove>
    return 0;
    800025ba:	8526                	mv	a0,s1
    800025bc:	bff9                	j	8000259a <either_copyout+0x32>

00000000800025be <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	892a                	mv	s2,a0
    800025d0:	84ae                	mv	s1,a1
    800025d2:	89b2                	mv	s3,a2
    800025d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	60e080e7          	jalr	1550(ra) # 80001be4 <myproc>
  if(user_src){
    800025de:	c08d                	beqz	s1,80002600 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025e0:	86d2                	mv	a3,s4
    800025e2:	864e                	mv	a2,s3
    800025e4:	85ca                	mv	a1,s2
    800025e6:	6d28                	ld	a0,88(a0)
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	116080e7          	jalr	278(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025f0:	70a2                	ld	ra,40(sp)
    800025f2:	7402                	ld	s0,32(sp)
    800025f4:	64e2                	ld	s1,24(sp)
    800025f6:	6942                	ld	s2,16(sp)
    800025f8:	69a2                	ld	s3,8(sp)
    800025fa:	6a02                	ld	s4,0(sp)
    800025fc:	6145                	addi	sp,sp,48
    800025fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002600:	000a061b          	sext.w	a2,s4
    80002604:	85ce                	mv	a1,s3
    80002606:	854a                	mv	a0,s2
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	738080e7          	jalr	1848(ra) # 80000d40 <memmove>
    return 0;
    80002610:	8526                	mv	a0,s1
    80002612:	bff9                	j	800025f0 <either_copyin+0x32>

0000000080002614 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002614:	715d                	addi	sp,sp,-80
    80002616:	e486                	sd	ra,72(sp)
    80002618:	e0a2                	sd	s0,64(sp)
    8000261a:	fc26                	sd	s1,56(sp)
    8000261c:	f84a                	sd	s2,48(sp)
    8000261e:	f44e                	sd	s3,40(sp)
    80002620:	f052                	sd	s4,32(sp)
    80002622:	ec56                	sd	s5,24(sp)
    80002624:	e85a                	sd	s6,16(sp)
    80002626:	e45e                	sd	s7,8(sp)
    80002628:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000262a:	00006517          	auipc	a0,0x6
    8000262e:	a9e50513          	addi	a0,a0,-1378 # 800080c8 <digits+0x88>
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	f56080e7          	jalr	-170(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263a:	0000f497          	auipc	s1,0xf
    8000263e:	1f648493          	addi	s1,s1,502 # 80011830 <proc+0x160>
    80002642:	00015917          	auipc	s2,0x15
    80002646:	dee90913          	addi	s2,s2,-530 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000264c:	00006997          	auipc	s3,0x6
    80002650:	c4c98993          	addi	s3,s3,-948 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002654:	00006a97          	auipc	s5,0x6
    80002658:	c4ca8a93          	addi	s5,s5,-948 # 800082a0 <digits+0x260>
    printf("\n");
    8000265c:	00006a17          	auipc	s4,0x6
    80002660:	a6ca0a13          	addi	s4,s4,-1428 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002664:	00006b97          	auipc	s7,0x6
    80002668:	c74b8b93          	addi	s7,s7,-908 # 800082d8 <states.1728>
    8000266c:	a00d                	j	8000268e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000266e:	ed06a583          	lw	a1,-304(a3)
    80002672:	8556                	mv	a0,s5
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f14080e7          	jalr	-236(ra) # 80000588 <printf>
    printf("\n");
    8000267c:	8552                	mv	a0,s4
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	f0a080e7          	jalr	-246(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002686:	17048493          	addi	s1,s1,368
    8000268a:	03248163          	beq	s1,s2,800026ac <procdump+0x98>
    if(p->state == UNUSED)
    8000268e:	86a6                	mv	a3,s1
    80002690:	eb84a783          	lw	a5,-328(s1)
    80002694:	dbed                	beqz	a5,80002686 <procdump+0x72>
      state = "???";
    80002696:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002698:	fcfb6be3          	bltu	s6,a5,8000266e <procdump+0x5a>
    8000269c:	1782                	slli	a5,a5,0x20
    8000269e:	9381                	srli	a5,a5,0x20
    800026a0:	078e                	slli	a5,a5,0x3
    800026a2:	97de                	add	a5,a5,s7
    800026a4:	6390                	ld	a2,0(a5)
    800026a6:	f661                	bnez	a2,8000266e <procdump+0x5a>
      state = "???";
    800026a8:	864e                	mv	a2,s3
    800026aa:	b7d1                	j	8000266e <procdump+0x5a>
  }
}
    800026ac:	60a6                	ld	ra,72(sp)
    800026ae:	6406                	ld	s0,64(sp)
    800026b0:	74e2                	ld	s1,56(sp)
    800026b2:	7942                	ld	s2,48(sp)
    800026b4:	79a2                	ld	s3,40(sp)
    800026b6:	7a02                	ld	s4,32(sp)
    800026b8:	6ae2                	ld	s5,24(sp)
    800026ba:	6b42                	ld	s6,16(sp)
    800026bc:	6ba2                	ld	s7,8(sp)
    800026be:	6161                	addi	sp,sp,80
    800026c0:	8082                	ret

00000000800026c2 <swtch>:
    800026c2:	00153023          	sd	ra,0(a0)
    800026c6:	00253423          	sd	sp,8(a0)
    800026ca:	e900                	sd	s0,16(a0)
    800026cc:	ed04                	sd	s1,24(a0)
    800026ce:	03253023          	sd	s2,32(a0)
    800026d2:	03353423          	sd	s3,40(a0)
    800026d6:	03453823          	sd	s4,48(a0)
    800026da:	03553c23          	sd	s5,56(a0)
    800026de:	05653023          	sd	s6,64(a0)
    800026e2:	05753423          	sd	s7,72(a0)
    800026e6:	05853823          	sd	s8,80(a0)
    800026ea:	05953c23          	sd	s9,88(a0)
    800026ee:	07a53023          	sd	s10,96(a0)
    800026f2:	07b53423          	sd	s11,104(a0)
    800026f6:	0005b083          	ld	ra,0(a1)
    800026fa:	0085b103          	ld	sp,8(a1)
    800026fe:	6980                	ld	s0,16(a1)
    80002700:	6d84                	ld	s1,24(a1)
    80002702:	0205b903          	ld	s2,32(a1)
    80002706:	0285b983          	ld	s3,40(a1)
    8000270a:	0305ba03          	ld	s4,48(a1)
    8000270e:	0385ba83          	ld	s5,56(a1)
    80002712:	0405bb03          	ld	s6,64(a1)
    80002716:	0485bb83          	ld	s7,72(a1)
    8000271a:	0505bc03          	ld	s8,80(a1)
    8000271e:	0585bc83          	ld	s9,88(a1)
    80002722:	0605bd03          	ld	s10,96(a1)
    80002726:	0685bd83          	ld	s11,104(a1)
    8000272a:	8082                	ret

000000008000272c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000272c:	1141                	addi	sp,sp,-16
    8000272e:	e406                	sd	ra,8(sp)
    80002730:	e022                	sd	s0,0(sp)
    80002732:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002734:	00006597          	auipc	a1,0x6
    80002738:	bd458593          	addi	a1,a1,-1068 # 80008308 <states.1728+0x30>
    8000273c:	00015517          	auipc	a0,0x15
    80002740:	b9450513          	addi	a0,a0,-1132 # 800172d0 <tickslock>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	410080e7          	jalr	1040(ra) # 80000b54 <initlock>
}
    8000274c:	60a2                	ld	ra,8(sp)
    8000274e:	6402                	ld	s0,0(sp)
    80002750:	0141                	addi	sp,sp,16
    80002752:	8082                	ret

0000000080002754 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002754:	1141                	addi	sp,sp,-16
    80002756:	e422                	sd	s0,8(sp)
    80002758:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275a:	00003797          	auipc	a5,0x3
    8000275e:	4d678793          	addi	a5,a5,1238 # 80005c30 <kernelvec>
    80002762:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002766:	6422                	ld	s0,8(sp)
    80002768:	0141                	addi	sp,sp,16
    8000276a:	8082                	ret

000000008000276c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000276c:	1141                	addi	sp,sp,-16
    8000276e:	e406                	sd	ra,8(sp)
    80002770:	e022                	sd	s0,0(sp)
    80002772:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	470080e7          	jalr	1136(ra) # 80001be4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002780:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002782:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002786:	00005617          	auipc	a2,0x5
    8000278a:	87a60613          	addi	a2,a2,-1926 # 80007000 <_trampoline>
    8000278e:	00005697          	auipc	a3,0x5
    80002792:	87268693          	addi	a3,a3,-1934 # 80007000 <_trampoline>
    80002796:	8e91                	sub	a3,a3,a2
    80002798:	040007b7          	lui	a5,0x4000
    8000279c:	17fd                	addi	a5,a5,-1
    8000279e:	07b2                	slli	a5,a5,0xc
    800027a0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a6:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027a8:	180026f3          	csrr	a3,satp
    800027ac:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027ae:	7138                	ld	a4,96(a0)
    800027b0:	6534                	ld	a3,72(a0)
    800027b2:	6585                	lui	a1,0x1
    800027b4:	96ae                	add	a3,a3,a1
    800027b6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027b8:	7138                	ld	a4,96(a0)
    800027ba:	00000697          	auipc	a3,0x0
    800027be:	13868693          	addi	a3,a3,312 # 800028f2 <usertrap>
    800027c2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c4:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c6:	8692                	mv	a3,tp
    800027c8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ca:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ce:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027da:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027dc:	6f18                	ld	a4,24(a4)
    800027de:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e2:	6d2c                	ld	a1,88(a0)
    800027e4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027e6:	00005717          	auipc	a4,0x5
    800027ea:	8aa70713          	addi	a4,a4,-1878 # 80007090 <userret>
    800027ee:	8f11                	sub	a4,a4,a2
    800027f0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027f2:	577d                	li	a4,-1
    800027f4:	177e                	slli	a4,a4,0x3f
    800027f6:	8dd9                	or	a1,a1,a4
    800027f8:	02000537          	lui	a0,0x2000
    800027fc:	157d                	addi	a0,a0,-1
    800027fe:	0536                	slli	a0,a0,0xd
    80002800:	9782                	jalr	a5
}
    80002802:	60a2                	ld	ra,8(sp)
    80002804:	6402                	ld	s0,0(sp)
    80002806:	0141                	addi	sp,sp,16
    80002808:	8082                	ret

000000008000280a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000280a:	1101                	addi	sp,sp,-32
    8000280c:	ec06                	sd	ra,24(sp)
    8000280e:	e822                	sd	s0,16(sp)
    80002810:	e426                	sd	s1,8(sp)
    80002812:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002814:	00015497          	auipc	s1,0x15
    80002818:	abc48493          	addi	s1,s1,-1348 # 800172d0 <tickslock>
    8000281c:	8526                	mv	a0,s1
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	3c6080e7          	jalr	966(ra) # 80000be4 <acquire>
  ticks++;
    80002826:	00007517          	auipc	a0,0x7
    8000282a:	81250513          	addi	a0,a0,-2030 # 80009038 <ticks>
    8000282e:	411c                	lw	a5,0(a0)
    80002830:	2785                	addiw	a5,a5,1
    80002832:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002834:	00000097          	auipc	ra,0x0
    80002838:	b8e080e7          	jalr	-1138(ra) # 800023c2 <wakeup>
  release(&tickslock);
    8000283c:	8526                	mv	a0,s1
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	45a080e7          	jalr	1114(ra) # 80000c98 <release>
}
    80002846:	60e2                	ld	ra,24(sp)
    80002848:	6442                	ld	s0,16(sp)
    8000284a:	64a2                	ld	s1,8(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret

0000000080002850 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002850:	1101                	addi	sp,sp,-32
    80002852:	ec06                	sd	ra,24(sp)
    80002854:	e822                	sd	s0,16(sp)
    80002856:	e426                	sd	s1,8(sp)
    80002858:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000285e:	00074d63          	bltz	a4,80002878 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002862:	57fd                	li	a5,-1
    80002864:	17fe                	slli	a5,a5,0x3f
    80002866:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002868:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000286a:	06f70363          	beq	a4,a5,800028d0 <devintr+0x80>
  }
}
    8000286e:	60e2                	ld	ra,24(sp)
    80002870:	6442                	ld	s0,16(sp)
    80002872:	64a2                	ld	s1,8(sp)
    80002874:	6105                	addi	sp,sp,32
    80002876:	8082                	ret
     (scause & 0xff) == 9){
    80002878:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000287c:	46a5                	li	a3,9
    8000287e:	fed792e3          	bne	a5,a3,80002862 <devintr+0x12>
    int irq = plic_claim();
    80002882:	00003097          	auipc	ra,0x3
    80002886:	4b6080e7          	jalr	1206(ra) # 80005d38 <plic_claim>
    8000288a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000288c:	47a9                	li	a5,10
    8000288e:	02f50763          	beq	a0,a5,800028bc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002892:	4785                	li	a5,1
    80002894:	02f50963          	beq	a0,a5,800028c6 <devintr+0x76>
    return 1;
    80002898:	4505                	li	a0,1
    } else if(irq){
    8000289a:	d8f1                	beqz	s1,8000286e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000289c:	85a6                	mv	a1,s1
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	a7250513          	addi	a0,a0,-1422 # 80008310 <states.1728+0x38>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
      plic_complete(irq);
    800028ae:	8526                	mv	a0,s1
    800028b0:	00003097          	auipc	ra,0x3
    800028b4:	4ac080e7          	jalr	1196(ra) # 80005d5c <plic_complete>
    return 1;
    800028b8:	4505                	li	a0,1
    800028ba:	bf55                	j	8000286e <devintr+0x1e>
      uartintr();
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	0ec080e7          	jalr	236(ra) # 800009a8 <uartintr>
    800028c4:	b7ed                	j	800028ae <devintr+0x5e>
      virtio_disk_intr();
    800028c6:	00004097          	auipc	ra,0x4
    800028ca:	976080e7          	jalr	-1674(ra) # 8000623c <virtio_disk_intr>
    800028ce:	b7c5                	j	800028ae <devintr+0x5e>
    if(cpuid() == 0){
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	2e8080e7          	jalr	744(ra) # 80001bb8 <cpuid>
    800028d8:	c901                	beqz	a0,800028e8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028da:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028de:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028e0:	14479073          	csrw	sip,a5
    return 2;
    800028e4:	4509                	li	a0,2
    800028e6:	b761                	j	8000286e <devintr+0x1e>
      clockintr();
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	f22080e7          	jalr	-222(ra) # 8000280a <clockintr>
    800028f0:	b7ed                	j	800028da <devintr+0x8a>

00000000800028f2 <usertrap>:
{
    800028f2:	1101                	addi	sp,sp,-32
    800028f4:	ec06                	sd	ra,24(sp)
    800028f6:	e822                	sd	s0,16(sp)
    800028f8:	e426                	sd	s1,8(sp)
    800028fa:	e04a                	sd	s2,0(sp)
    800028fc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002902:	1007f793          	andi	a5,a5,256
    80002906:	e3ad                	bnez	a5,80002968 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002908:	00003797          	auipc	a5,0x3
    8000290c:	32878793          	addi	a5,a5,808 # 80005c30 <kernelvec>
    80002910:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	2d0080e7          	jalr	720(ra) # 80001be4 <myproc>
    8000291c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000291e:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	14102773          	csrr	a4,sepc
    80002924:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002926:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000292a:	47a1                	li	a5,8
    8000292c:	04f71c63          	bne	a4,a5,80002984 <usertrap+0x92>
    if(p->killed)
    80002930:	551c                	lw	a5,40(a0)
    80002932:	e3b9                	bnez	a5,80002978 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002934:	70b8                	ld	a4,96(s1)
    80002936:	6f1c                	ld	a5,24(a4)
    80002938:	0791                	addi	a5,a5,4
    8000293a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002940:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002944:	10079073          	csrw	sstatus,a5
    syscall();
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	2e0080e7          	jalr	736(ra) # 80002c28 <syscall>
  if(p->killed)
    80002950:	549c                	lw	a5,40(s1)
    80002952:	ebc1                	bnez	a5,800029e2 <usertrap+0xf0>
  usertrapret();
    80002954:	00000097          	auipc	ra,0x0
    80002958:	e18080e7          	jalr	-488(ra) # 8000276c <usertrapret>
}
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6902                	ld	s2,0(sp)
    80002964:	6105                	addi	sp,sp,32
    80002966:	8082                	ret
    panic("usertrap: not from user mode");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	9c850513          	addi	a0,a0,-1592 # 80008330 <states.1728+0x58>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
      exit(-1);
    80002978:	557d                	li	a0,-1
    8000297a:	00000097          	auipc	ra,0x0
    8000297e:	b18080e7          	jalr	-1256(ra) # 80002492 <exit>
    80002982:	bf4d                	j	80002934 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002984:	00000097          	auipc	ra,0x0
    80002988:	ecc080e7          	jalr	-308(ra) # 80002850 <devintr>
    8000298c:	892a                	mv	s2,a0
    8000298e:	c501                	beqz	a0,80002996 <usertrap+0xa4>
  if(p->killed)
    80002990:	549c                	lw	a5,40(s1)
    80002992:	c3a1                	beqz	a5,800029d2 <usertrap+0xe0>
    80002994:	a815                	j	800029c8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000299a:	5890                	lw	a2,48(s1)
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	9b450513          	addi	a0,a0,-1612 # 80008350 <states.1728+0x78>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	be4080e7          	jalr	-1052(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	9cc50513          	addi	a0,a0,-1588 # 80008380 <states.1728+0xa8>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bcc080e7          	jalr	-1076(ra) # 80000588 <printf>
    p->killed = 1;
    800029c4:	4785                	li	a5,1
    800029c6:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029c8:	557d                	li	a0,-1
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	ac8080e7          	jalr	-1336(ra) # 80002492 <exit>
  if(which_dev == 2)
    800029d2:	4789                	li	a5,2
    800029d4:	f8f910e3          	bne	s2,a5,80002954 <usertrap+0x62>
    yield();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	7ec080e7          	jalr	2028(ra) # 800021c4 <yield>
    800029e0:	bf95                	j	80002954 <usertrap+0x62>
  int which_dev = 0;
    800029e2:	4901                	li	s2,0
    800029e4:	b7d5                	j	800029c8 <usertrap+0xd6>

00000000800029e6 <kerneltrap>:
{
    800029e6:	7179                	addi	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a00:	1004f793          	andi	a5,s1,256
    80002a04:	cb85                	beqz	a5,80002a34 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0c:	ef85                	bnez	a5,80002a44 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0e:	00000097          	auipc	ra,0x0
    80002a12:	e42080e7          	jalr	-446(ra) # 80002850 <devintr>
    80002a16:	cd1d                	beqz	a0,80002a54 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a18:	4789                	li	a5,2
    80002a1a:	06f50a63          	beq	a0,a5,80002a8e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a22:	10049073          	csrw	sstatus,s1
}
    80002a26:	70a2                	ld	ra,40(sp)
    80002a28:	7402                	ld	s0,32(sp)
    80002a2a:	64e2                	ld	s1,24(sp)
    80002a2c:	6942                	ld	s2,16(sp)
    80002a2e:	69a2                	ld	s3,8(sp)
    80002a30:	6145                	addi	sp,sp,48
    80002a32:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	96c50513          	addi	a0,a0,-1684 # 800083a0 <states.1728+0xc8>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	98450513          	addi	a0,a0,-1660 # 800083c8 <states.1728+0xf0>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a54:	85ce                	mv	a1,s3
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	99250513          	addi	a0,a0,-1646 # 800083e8 <states.1728+0x110>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	b2a080e7          	jalr	-1238(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	98a50513          	addi	a0,a0,-1654 # 800083f8 <states.1728+0x120>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b12080e7          	jalr	-1262(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	99250513          	addi	a0,a0,-1646 # 80008410 <states.1728+0x138>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	156080e7          	jalr	342(ra) # 80001be4 <myproc>
    80002a96:	d541                	beqz	a0,80002a1e <kerneltrap+0x38>
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	14c080e7          	jalr	332(ra) # 80001be4 <myproc>
    80002aa0:	4d18                	lw	a4,24(a0)
    80002aa2:	4791                	li	a5,4
    80002aa4:	f6f71de3          	bne	a4,a5,80002a1e <kerneltrap+0x38>
    yield();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	71c080e7          	jalr	1820(ra) # 800021c4 <yield>
    80002ab0:	b7bd                	j	80002a1e <kerneltrap+0x38>

0000000080002ab2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab2:	1101                	addi	sp,sp,-32
    80002ab4:	ec06                	sd	ra,24(sp)
    80002ab6:	e822                	sd	s0,16(sp)
    80002ab8:	e426                	sd	s1,8(sp)
    80002aba:	1000                	addi	s0,sp,32
    80002abc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	126080e7          	jalr	294(ra) # 80001be4 <myproc>
  switch (n) {
    80002ac6:	4795                	li	a5,5
    80002ac8:	0497e163          	bltu	a5,s1,80002b0a <argraw+0x58>
    80002acc:	048a                	slli	s1,s1,0x2
    80002ace:	00006717          	auipc	a4,0x6
    80002ad2:	97a70713          	addi	a4,a4,-1670 # 80008448 <states.1728+0x170>
    80002ad6:	94ba                	add	s1,s1,a4
    80002ad8:	409c                	lw	a5,0(s1)
    80002ada:	97ba                	add	a5,a5,a4
    80002adc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ade:	713c                	ld	a5,96(a0)
    80002ae0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret
    return p->trapframe->a1;
    80002aec:	713c                	ld	a5,96(a0)
    80002aee:	7fa8                	ld	a0,120(a5)
    80002af0:	bfcd                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a2;
    80002af2:	713c                	ld	a5,96(a0)
    80002af4:	63c8                	ld	a0,128(a5)
    80002af6:	b7f5                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a3;
    80002af8:	713c                	ld	a5,96(a0)
    80002afa:	67c8                	ld	a0,136(a5)
    80002afc:	b7dd                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a4;
    80002afe:	713c                	ld	a5,96(a0)
    80002b00:	6bc8                	ld	a0,144(a5)
    80002b02:	b7c5                	j	80002ae2 <argraw+0x30>
    return p->trapframe->a5;
    80002b04:	713c                	ld	a5,96(a0)
    80002b06:	6fc8                	ld	a0,152(a5)
    80002b08:	bfe9                	j	80002ae2 <argraw+0x30>
  panic("argraw");
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	91650513          	addi	a0,a0,-1770 # 80008420 <states.1728+0x148>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a2c080e7          	jalr	-1492(ra) # 8000053e <panic>

0000000080002b1a <fetchaddr>:
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	e04a                	sd	s2,0(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84aa                	mv	s1,a0
    80002b28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	0ba080e7          	jalr	186(ra) # 80001be4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b32:	693c                	ld	a5,80(a0)
    80002b34:	02f4f863          	bgeu	s1,a5,80002b64 <fetchaddr+0x4a>
    80002b38:	00848713          	addi	a4,s1,8
    80002b3c:	02e7e663          	bltu	a5,a4,80002b68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b40:	46a1                	li	a3,8
    80002b42:	8626                	mv	a2,s1
    80002b44:	85ca                	mv	a1,s2
    80002b46:	6d28                	ld	a0,88(a0)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	bb6080e7          	jalr	-1098(ra) # 800016fe <copyin>
    80002b50:	00a03533          	snez	a0,a0
    80002b54:	40a00533          	neg	a0,a0
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6902                	ld	s2,0(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret
    return -1;
    80002b64:	557d                	li	a0,-1
    80002b66:	bfcd                	j	80002b58 <fetchaddr+0x3e>
    80002b68:	557d                	li	a0,-1
    80002b6a:	b7fd                	j	80002b58 <fetchaddr+0x3e>

0000000080002b6c <fetchstr>:
{
    80002b6c:	7179                	addi	sp,sp,-48
    80002b6e:	f406                	sd	ra,40(sp)
    80002b70:	f022                	sd	s0,32(sp)
    80002b72:	ec26                	sd	s1,24(sp)
    80002b74:	e84a                	sd	s2,16(sp)
    80002b76:	e44e                	sd	s3,8(sp)
    80002b78:	1800                	addi	s0,sp,48
    80002b7a:	892a                	mv	s2,a0
    80002b7c:	84ae                	mv	s1,a1
    80002b7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	064080e7          	jalr	100(ra) # 80001be4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b88:	86ce                	mv	a3,s3
    80002b8a:	864a                	mv	a2,s2
    80002b8c:	85a6                	mv	a1,s1
    80002b8e:	6d28                	ld	a0,88(a0)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	bfa080e7          	jalr	-1030(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b98:	00054763          	bltz	a0,80002ba6 <fetchstr+0x3a>
  return strlen(buf);
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	2c6080e7          	jalr	710(ra) # 80000e64 <strlen>
}
    80002ba6:	70a2                	ld	ra,40(sp)
    80002ba8:	7402                	ld	s0,32(sp)
    80002baa:	64e2                	ld	s1,24(sp)
    80002bac:	6942                	ld	s2,16(sp)
    80002bae:	69a2                	ld	s3,8(sp)
    80002bb0:	6145                	addi	sp,sp,48
    80002bb2:	8082                	ret

0000000080002bb4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	ef2080e7          	jalr	-270(ra) # 80002ab2 <argraw>
    80002bc8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bca:	4501                	li	a0,0
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	64a2                	ld	s1,8(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret

0000000080002bd6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	ed0080e7          	jalr	-304(ra) # 80002ab2 <argraw>
    80002bea:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bec:	4501                	li	a0,0
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf8:	1101                	addi	sp,sp,-32
    80002bfa:	ec06                	sd	ra,24(sp)
    80002bfc:	e822                	sd	s0,16(sp)
    80002bfe:	e426                	sd	s1,8(sp)
    80002c00:	e04a                	sd	s2,0(sp)
    80002c02:	1000                	addi	s0,sp,32
    80002c04:	84ae                	mv	s1,a1
    80002c06:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	eaa080e7          	jalr	-342(ra) # 80002ab2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c10:	864a                	mv	a2,s2
    80002c12:	85a6                	mv	a1,s1
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	f58080e7          	jalr	-168(ra) # 80002b6c <fetchstr>
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	64a2                	ld	s1,8(sp)
    80002c22:	6902                	ld	s2,0(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret

0000000080002c28 <syscall>:
[SYS_pause_sys] sys_pause_sys
};

void
syscall(void)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	e04a                	sd	s2,0(sp)
    80002c32:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	fb0080e7          	jalr	-80(ra) # 80001be4 <myproc>
    80002c3c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3e:	06053903          	ld	s2,96(a0)
    80002c42:	0a893783          	ld	a5,168(s2)
    80002c46:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4a:	37fd                	addiw	a5,a5,-1
    80002c4c:	4759                	li	a4,22
    80002c4e:	00f76f63          	bltu	a4,a5,80002c6c <syscall+0x44>
    80002c52:	00369713          	slli	a4,a3,0x3
    80002c56:	00006797          	auipc	a5,0x6
    80002c5a:	80a78793          	addi	a5,a5,-2038 # 80008460 <syscalls>
    80002c5e:	97ba                	add	a5,a5,a4
    80002c60:	639c                	ld	a5,0(a5)
    80002c62:	c789                	beqz	a5,80002c6c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c64:	9782                	jalr	a5
    80002c66:	06a93823          	sd	a0,112(s2)
    80002c6a:	a839                	j	80002c88 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c6c:	16048613          	addi	a2,s1,352
    80002c70:	588c                	lw	a1,48(s1)
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	7b650513          	addi	a0,a0,1974 # 80008428 <states.1728+0x150>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	90e080e7          	jalr	-1778(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c82:	70bc                	ld	a5,96(s1)
    80002c84:	577d                	li	a4,-1
    80002c86:	fbb8                	sd	a4,112(a5)
  }
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6902                	ld	s2,0(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c9c:	fec40593          	addi	a1,s0,-20
    80002ca0:	4501                	li	a0,0
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	f12080e7          	jalr	-238(ra) # 80002bb4 <argint>
    return -1;
    80002caa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cac:	00054963          	bltz	a0,80002cbe <sys_exit+0x2a>
  exit(n);
    80002cb0:	fec42503          	lw	a0,-20(s0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	7de080e7          	jalr	2014(ra) # 80002492 <exit>
  return 0;  // not reached
    80002cbc:	4781                	li	a5,0
}
    80002cbe:	853e                	mv	a0,a5
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc8:	1141                	addi	sp,sp,-16
    80002cca:	e406                	sd	ra,8(sp)
    80002ccc:	e022                	sd	s0,0(sp)
    80002cce:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	f14080e7          	jalr	-236(ra) # 80001be4 <myproc>
}
    80002cd8:	5908                	lw	a0,48(a0)
    80002cda:	60a2                	ld	ra,8(sp)
    80002cdc:	6402                	ld	s0,0(sp)
    80002cde:	0141                	addi	sp,sp,16
    80002ce0:	8082                	ret

0000000080002ce2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce2:	1141                	addi	sp,sp,-16
    80002ce4:	e406                	sd	ra,8(sp)
    80002ce6:	e022                	sd	s0,0(sp)
    80002ce8:	0800                	addi	s0,sp,16
  return fork();
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	2d0080e7          	jalr	720(ra) # 80001fba <fork>
}
    80002cf2:	60a2                	ld	ra,8(sp)
    80002cf4:	6402                	ld	s0,0(sp)
    80002cf6:	0141                	addi	sp,sp,16
    80002cf8:	8082                	ret

0000000080002cfa <sys_wait>:

uint64
sys_wait(void)
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d02:	fe840593          	addi	a1,s0,-24
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	ece080e7          	jalr	-306(ra) # 80002bd6 <argaddr>
    80002d10:	87aa                	mv	a5,a0
    return -1;
    80002d12:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d14:	0007c863          	bltz	a5,80002d24 <sys_wait+0x2a>
  return wait(p);
    80002d18:	fe843503          	ld	a0,-24(s0)
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	57e080e7          	jalr	1406(ra) # 8000229a <wait>
}
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d2c:	7179                	addi	sp,sp,-48
    80002d2e:	f406                	sd	ra,40(sp)
    80002d30:	f022                	sd	s0,32(sp)
    80002d32:	ec26                	sd	s1,24(sp)
    80002d34:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d36:	fdc40593          	addi	a1,s0,-36
    80002d3a:	4501                	li	a0,0
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	e78080e7          	jalr	-392(ra) # 80002bb4 <argint>
    80002d44:	87aa                	mv	a5,a0
    return -1;
    80002d46:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d48:	0207c063          	bltz	a5,80002d68 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	e98080e7          	jalr	-360(ra) # 80001be4 <myproc>
    80002d54:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002d56:	fdc42503          	lw	a0,-36(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	1ec080e7          	jalr	492(ra) # 80001f46 <growproc>
    80002d62:	00054863          	bltz	a0,80002d72 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d66:	8526                	mv	a0,s1
}
    80002d68:	70a2                	ld	ra,40(sp)
    80002d6a:	7402                	ld	s0,32(sp)
    80002d6c:	64e2                	ld	s1,24(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret
    return -1;
    80002d72:	557d                	li	a0,-1
    80002d74:	bfd5                	j	80002d68 <sys_sbrk+0x3c>

0000000080002d76 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d76:	7139                	addi	sp,sp,-64
    80002d78:	fc06                	sd	ra,56(sp)
    80002d7a:	f822                	sd	s0,48(sp)
    80002d7c:	f426                	sd	s1,40(sp)
    80002d7e:	f04a                	sd	s2,32(sp)
    80002d80:	ec4e                	sd	s3,24(sp)
    80002d82:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d84:	fcc40593          	addi	a1,s0,-52
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	e2a080e7          	jalr	-470(ra) # 80002bb4 <argint>
    return -1;
    80002d92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d94:	06054563          	bltz	a0,80002dfe <sys_sleep+0x88>
  acquire(&tickslock);
    80002d98:	00014517          	auipc	a0,0x14
    80002d9c:	53850513          	addi	a0,a0,1336 # 800172d0 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	e44080e7          	jalr	-444(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002da8:	00006917          	auipc	s2,0x6
    80002dac:	29092903          	lw	s2,656(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002db0:	fcc42783          	lw	a5,-52(s0)
    80002db4:	cf85                	beqz	a5,80002dec <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db6:	00014997          	auipc	s3,0x14
    80002dba:	51a98993          	addi	s3,s3,1306 # 800172d0 <tickslock>
    80002dbe:	00006497          	auipc	s1,0x6
    80002dc2:	27a48493          	addi	s1,s1,634 # 80009038 <ticks>
    if(myproc()->killed){
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	e1e080e7          	jalr	-482(ra) # 80001be4 <myproc>
    80002dce:	551c                	lw	a5,40(a0)
    80002dd0:	ef9d                	bnez	a5,80002e0e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dd2:	85ce                	mv	a1,s3
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	460080e7          	jalr	1120(ra) # 80002236 <sleep>
  while(ticks - ticks0 < n){
    80002dde:	409c                	lw	a5,0(s1)
    80002de0:	412787bb          	subw	a5,a5,s2
    80002de4:	fcc42703          	lw	a4,-52(s0)
    80002de8:	fce7efe3          	bltu	a5,a4,80002dc6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dec:	00014517          	auipc	a0,0x14
    80002df0:	4e450513          	addi	a0,a0,1252 # 800172d0 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	ea4080e7          	jalr	-348(ra) # 80000c98 <release>
  return 0;
    80002dfc:	4781                	li	a5,0
}
    80002dfe:	853e                	mv	a0,a5
    80002e00:	70e2                	ld	ra,56(sp)
    80002e02:	7442                	ld	s0,48(sp)
    80002e04:	74a2                	ld	s1,40(sp)
    80002e06:	7902                	ld	s2,32(sp)
    80002e08:	69e2                	ld	s3,24(sp)
    80002e0a:	6121                	addi	sp,sp,64
    80002e0c:	8082                	ret
      release(&tickslock);
    80002e0e:	00014517          	auipc	a0,0x14
    80002e12:	4c250513          	addi	a0,a0,1218 # 800172d0 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	e82080e7          	jalr	-382(ra) # 80000c98 <release>
      return -1;
    80002e1e:	57fd                	li	a5,-1
    80002e20:	bff9                	j	80002dfe <sys_sleep+0x88>

0000000080002e22 <sys_kill>:

uint64
sys_kill(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e2a:	fec40593          	addi	a1,s0,-20
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	d84080e7          	jalr	-636(ra) # 80002bb4 <argint>
    80002e38:	87aa                	mv	a5,a0
    return -1;
    80002e3a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e3c:	0007c863          	bltz	a5,80002e4c <sys_kill+0x2a>
  return kill(pid);
    80002e40:	fec42503          	lw	a0,-20(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	a90080e7          	jalr	-1392(ra) # 800018d4 <kill>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_kill_sys>:

uint64
sys_kill_sys(void)
{
    80002e54:	1141                	addi	sp,sp,-16
    80002e56:	e406                	sd	ra,8(sp)
    80002e58:	e022                	sd	s0,0(sp)
    80002e5a:	0800                	addi	s0,sp,16
  return kill_sys();
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	aea080e7          	jalr	-1302(ra) # 80001946 <kill_sys>
}
    80002e64:	60a2                	ld	ra,8(sp)
    80002e66:	6402                	ld	s0,0(sp)
    80002e68:	0141                	addi	sp,sp,16
    80002e6a:	8082                	ret

0000000080002e6c <sys_pause_sys>:


uint64
sys_pause_sys(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80002e74:	fec40593          	addi	a1,s0,-20
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	d3a080e7          	jalr	-710(ra) # 80002bb4 <argint>
    80002e82:	87aa                	mv	a5,a0
    return -1;
    80002e84:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80002e86:	0007c863          	bltz	a5,80002e96 <sys_pause_sys+0x2a>
  return pause_sys(time);
    80002e8a:	fec42503          	lw	a0,-20(s0)
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	372080e7          	jalr	882(ra) # 80002200 <pause_sys>
}
    80002e96:	60e2                	ld	ra,24(sp)
    80002e98:	6442                	ld	s0,16(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	e426                	sd	s1,8(sp)
    80002ea6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	42850513          	addi	a0,a0,1064 # 800172d0 <tickslock>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d34080e7          	jalr	-716(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002eb8:	00006497          	auipc	s1,0x6
    80002ebc:	1804a483          	lw	s1,384(s1) # 80009038 <ticks>
  release(&tickslock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	41050513          	addi	a0,a0,1040 # 800172d0 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
  return xticks;
}
    80002ed0:	02049513          	slli	a0,s1,0x20
    80002ed4:	9101                	srli	a0,a0,0x20
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	64a2                	ld	s1,8(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ee0:	7179                	addi	sp,sp,-48
    80002ee2:	f406                	sd	ra,40(sp)
    80002ee4:	f022                	sd	s0,32(sp)
    80002ee6:	ec26                	sd	s1,24(sp)
    80002ee8:	e84a                	sd	s2,16(sp)
    80002eea:	e44e                	sd	s3,8(sp)
    80002eec:	e052                	sd	s4,0(sp)
    80002eee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ef0:	00005597          	auipc	a1,0x5
    80002ef4:	63058593          	addi	a1,a1,1584 # 80008520 <syscalls+0xc0>
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	3f050513          	addi	a0,a0,1008 # 800172e8 <bcache>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	c54080e7          	jalr	-940(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f08:	0001c797          	auipc	a5,0x1c
    80002f0c:	3e078793          	addi	a5,a5,992 # 8001f2e8 <bcache+0x8000>
    80002f10:	0001c717          	auipc	a4,0x1c
    80002f14:	64070713          	addi	a4,a4,1600 # 8001f550 <bcache+0x8268>
    80002f18:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f1c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	00014497          	auipc	s1,0x14
    80002f24:	3e048493          	addi	s1,s1,992 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f28:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f2a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f2c:	00005a17          	auipc	s4,0x5
    80002f30:	5fca0a13          	addi	s4,s4,1532 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f34:	2b893783          	ld	a5,696(s2)
    80002f38:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f3a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f3e:	85d2                	mv	a1,s4
    80002f40:	01048513          	addi	a0,s1,16
    80002f44:	00001097          	auipc	ra,0x1
    80002f48:	4bc080e7          	jalr	1212(ra) # 80004400 <initsleeplock>
    bcache.head.next->prev = b;
    80002f4c:	2b893783          	ld	a5,696(s2)
    80002f50:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f52:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f56:	45848493          	addi	s1,s1,1112
    80002f5a:	fd349de3          	bne	s1,s3,80002f34 <binit+0x54>
  }
}
    80002f5e:	70a2                	ld	ra,40(sp)
    80002f60:	7402                	ld	s0,32(sp)
    80002f62:	64e2                	ld	s1,24(sp)
    80002f64:	6942                	ld	s2,16(sp)
    80002f66:	69a2                	ld	s3,8(sp)
    80002f68:	6a02                	ld	s4,0(sp)
    80002f6a:	6145                	addi	sp,sp,48
    80002f6c:	8082                	ret

0000000080002f6e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f6e:	7179                	addi	sp,sp,-48
    80002f70:	f406                	sd	ra,40(sp)
    80002f72:	f022                	sd	s0,32(sp)
    80002f74:	ec26                	sd	s1,24(sp)
    80002f76:	e84a                	sd	s2,16(sp)
    80002f78:	e44e                	sd	s3,8(sp)
    80002f7a:	1800                	addi	s0,sp,48
    80002f7c:	89aa                	mv	s3,a0
    80002f7e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f80:	00014517          	auipc	a0,0x14
    80002f84:	36850513          	addi	a0,a0,872 # 800172e8 <bcache>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	c5c080e7          	jalr	-932(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f90:	0001c497          	auipc	s1,0x1c
    80002f94:	6104b483          	ld	s1,1552(s1) # 8001f5a0 <bcache+0x82b8>
    80002f98:	0001c797          	auipc	a5,0x1c
    80002f9c:	5b878793          	addi	a5,a5,1464 # 8001f550 <bcache+0x8268>
    80002fa0:	02f48f63          	beq	s1,a5,80002fde <bread+0x70>
    80002fa4:	873e                	mv	a4,a5
    80002fa6:	a021                	j	80002fae <bread+0x40>
    80002fa8:	68a4                	ld	s1,80(s1)
    80002faa:	02e48a63          	beq	s1,a4,80002fde <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fae:	449c                	lw	a5,8(s1)
    80002fb0:	ff379ce3          	bne	a5,s3,80002fa8 <bread+0x3a>
    80002fb4:	44dc                	lw	a5,12(s1)
    80002fb6:	ff2799e3          	bne	a5,s2,80002fa8 <bread+0x3a>
      b->refcnt++;
    80002fba:	40bc                	lw	a5,64(s1)
    80002fbc:	2785                	addiw	a5,a5,1
    80002fbe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	32850513          	addi	a0,a0,808 # 800172e8 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	cd0080e7          	jalr	-816(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fd0:	01048513          	addi	a0,s1,16
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	466080e7          	jalr	1126(ra) # 8000443a <acquiresleep>
      return b;
    80002fdc:	a8b9                	j	8000303a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fde:	0001c497          	auipc	s1,0x1c
    80002fe2:	5ba4b483          	ld	s1,1466(s1) # 8001f598 <bcache+0x82b0>
    80002fe6:	0001c797          	auipc	a5,0x1c
    80002fea:	56a78793          	addi	a5,a5,1386 # 8001f550 <bcache+0x8268>
    80002fee:	00f48863          	beq	s1,a5,80002ffe <bread+0x90>
    80002ff2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ff4:	40bc                	lw	a5,64(s1)
    80002ff6:	cf81                	beqz	a5,8000300e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff8:	64a4                	ld	s1,72(s1)
    80002ffa:	fee49de3          	bne	s1,a4,80002ff4 <bread+0x86>
  panic("bget: no buffers");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	53250513          	addi	a0,a0,1330 # 80008530 <syscalls+0xd0>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	538080e7          	jalr	1336(ra) # 8000053e <panic>
      b->dev = dev;
    8000300e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003012:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003016:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000301a:	4785                	li	a5,1
    8000301c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301e:	00014517          	auipc	a0,0x14
    80003022:	2ca50513          	addi	a0,a0,714 # 800172e8 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	c72080e7          	jalr	-910(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000302e:	01048513          	addi	a0,s1,16
    80003032:	00001097          	auipc	ra,0x1
    80003036:	408080e7          	jalr	1032(ra) # 8000443a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000303a:	409c                	lw	a5,0(s1)
    8000303c:	cb89                	beqz	a5,8000304e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000303e:	8526                	mv	a0,s1
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	69a2                	ld	s3,8(sp)
    8000304a:	6145                	addi	sp,sp,48
    8000304c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000304e:	4581                	li	a1,0
    80003050:	8526                	mv	a0,s1
    80003052:	00003097          	auipc	ra,0x3
    80003056:	f14080e7          	jalr	-236(ra) # 80005f66 <virtio_disk_rw>
    b->valid = 1;
    8000305a:	4785                	li	a5,1
    8000305c:	c09c                	sw	a5,0(s1)
  return b;
    8000305e:	b7c5                	j	8000303e <bread+0xd0>

0000000080003060 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	1000                	addi	s0,sp,32
    8000306a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306c:	0541                	addi	a0,a0,16
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	466080e7          	jalr	1126(ra) # 800044d4 <holdingsleep>
    80003076:	cd01                	beqz	a0,8000308e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003078:	4585                	li	a1,1
    8000307a:	8526                	mv	a0,s1
    8000307c:	00003097          	auipc	ra,0x3
    80003080:	eea080e7          	jalr	-278(ra) # 80005f66 <virtio_disk_rw>
}
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	64a2                	ld	s1,8(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret
    panic("bwrite");
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	4ba50513          	addi	a0,a0,1210 # 80008548 <syscalls+0xe8>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4a8080e7          	jalr	1192(ra) # 8000053e <panic>

000000008000309e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	e04a                	sd	s2,0(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ac:	01050913          	addi	s2,a0,16
    800030b0:	854a                	mv	a0,s2
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	422080e7          	jalr	1058(ra) # 800044d4 <holdingsleep>
    800030ba:	c92d                	beqz	a0,8000312c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030bc:	854a                	mv	a0,s2
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	3d2080e7          	jalr	978(ra) # 80004490 <releasesleep>

  acquire(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	22250513          	addi	a0,a0,546 # 800172e8 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	b16080e7          	jalr	-1258(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	37fd                	addiw	a5,a5,-1
    800030da:	0007871b          	sext.w	a4,a5
    800030de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030e0:	eb05                	bnez	a4,80003110 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030e2:	68bc                	ld	a5,80(s1)
    800030e4:	64b8                	ld	a4,72(s1)
    800030e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030e8:	64bc                	ld	a5,72(s1)
    800030ea:	68b8                	ld	a4,80(s1)
    800030ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ee:	0001c797          	auipc	a5,0x1c
    800030f2:	1fa78793          	addi	a5,a5,506 # 8001f2e8 <bcache+0x8000>
    800030f6:	2b87b703          	ld	a4,696(a5)
    800030fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030fc:	0001c717          	auipc	a4,0x1c
    80003100:	45470713          	addi	a4,a4,1108 # 8001f550 <bcache+0x8268>
    80003104:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003106:	2b87b703          	ld	a4,696(a5)
    8000310a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000310c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	1d850513          	addi	a0,a0,472 # 800172e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6902                	ld	s2,0(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret
    panic("brelse");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	42450513          	addi	a0,a0,1060 # 80008550 <syscalls+0xf0>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	40a080e7          	jalr	1034(ra) # 8000053e <panic>

000000008000313c <bpin>:

void
bpin(struct buf *b) {
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	1000                	addi	s0,sp,32
    80003146:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	1a050513          	addi	a0,a0,416 # 800172e8 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	a94080e7          	jalr	-1388(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003158:	40bc                	lw	a5,64(s1)
    8000315a:	2785                	addiw	a5,a5,1
    8000315c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315e:	00014517          	auipc	a0,0x14
    80003162:	18a50513          	addi	a0,a0,394 # 800172e8 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <bunpin>:

void
bunpin(struct buf *b) {
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	16450513          	addi	a0,a0,356 # 800172e8 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a58080e7          	jalr	-1448(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003194:	40bc                	lw	a5,64(s1)
    80003196:	37fd                	addiw	a5,a5,-1
    80003198:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000319a:	00014517          	auipc	a0,0x14
    8000319e:	14e50513          	addi	a0,a0,334 # 800172e8 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	e04a                	sd	s2,0(sp)
    800031be:	1000                	addi	s0,sp,32
    800031c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031c2:	00d5d59b          	srliw	a1,a1,0xd
    800031c6:	0001c797          	auipc	a5,0x1c
    800031ca:	7fe7a783          	lw	a5,2046(a5) # 8001f9c4 <sb+0x1c>
    800031ce:	9dbd                	addw	a1,a1,a5
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	d9e080e7          	jalr	-610(ra) # 80002f6e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031d8:	0074f713          	andi	a4,s1,7
    800031dc:	4785                	li	a5,1
    800031de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031e2:	14ce                	slli	s1,s1,0x33
    800031e4:	90d9                	srli	s1,s1,0x36
    800031e6:	00950733          	add	a4,a0,s1
    800031ea:	05874703          	lbu	a4,88(a4)
    800031ee:	00e7f6b3          	and	a3,a5,a4
    800031f2:	c69d                	beqz	a3,80003220 <bfree+0x6c>
    800031f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031f6:	94aa                	add	s1,s1,a0
    800031f8:	fff7c793          	not	a5,a5
    800031fc:	8ff9                	and	a5,a5,a4
    800031fe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003202:	00001097          	auipc	ra,0x1
    80003206:	118080e7          	jalr	280(ra) # 8000431a <log_write>
  brelse(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	e92080e7          	jalr	-366(ra) # 8000309e <brelse>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	64a2                	ld	s1,8(sp)
    8000321a:	6902                	ld	s2,0(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret
    panic("freeing free block");
    80003220:	00005517          	auipc	a0,0x5
    80003224:	33850513          	addi	a0,a0,824 # 80008558 <syscalls+0xf8>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	316080e7          	jalr	790(ra) # 8000053e <panic>

0000000080003230 <balloc>:
{
    80003230:	711d                	addi	sp,sp,-96
    80003232:	ec86                	sd	ra,88(sp)
    80003234:	e8a2                	sd	s0,80(sp)
    80003236:	e4a6                	sd	s1,72(sp)
    80003238:	e0ca                	sd	s2,64(sp)
    8000323a:	fc4e                	sd	s3,56(sp)
    8000323c:	f852                	sd	s4,48(sp)
    8000323e:	f456                	sd	s5,40(sp)
    80003240:	f05a                	sd	s6,32(sp)
    80003242:	ec5e                	sd	s7,24(sp)
    80003244:	e862                	sd	s8,16(sp)
    80003246:	e466                	sd	s9,8(sp)
    80003248:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000324a:	0001c797          	auipc	a5,0x1c
    8000324e:	7627a783          	lw	a5,1890(a5) # 8001f9ac <sb+0x4>
    80003252:	cbd1                	beqz	a5,800032e6 <balloc+0xb6>
    80003254:	8baa                	mv	s7,a0
    80003256:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003258:	0001cb17          	auipc	s6,0x1c
    8000325c:	750b0b13          	addi	s6,s6,1872 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003260:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003262:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003264:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003266:	6c89                	lui	s9,0x2
    80003268:	a831                	j	80003284 <balloc+0x54>
    brelse(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	e32080e7          	jalr	-462(ra) # 8000309e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003274:	015c87bb          	addw	a5,s9,s5
    80003278:	00078a9b          	sext.w	s5,a5
    8000327c:	004b2703          	lw	a4,4(s6)
    80003280:	06eaf363          	bgeu	s5,a4,800032e6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003284:	41fad79b          	sraiw	a5,s5,0x1f
    80003288:	0137d79b          	srliw	a5,a5,0x13
    8000328c:	015787bb          	addw	a5,a5,s5
    80003290:	40d7d79b          	sraiw	a5,a5,0xd
    80003294:	01cb2583          	lw	a1,28(s6)
    80003298:	9dbd                	addw	a1,a1,a5
    8000329a:	855e                	mv	a0,s7
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	cd2080e7          	jalr	-814(ra) # 80002f6e <bread>
    800032a4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	004b2503          	lw	a0,4(s6)
    800032aa:	000a849b          	sext.w	s1,s5
    800032ae:	8662                	mv	a2,s8
    800032b0:	faa4fde3          	bgeu	s1,a0,8000326a <balloc+0x3a>
      m = 1 << (bi % 8);
    800032b4:	41f6579b          	sraiw	a5,a2,0x1f
    800032b8:	01d7d69b          	srliw	a3,a5,0x1d
    800032bc:	00c6873b          	addw	a4,a3,a2
    800032c0:	00777793          	andi	a5,a4,7
    800032c4:	9f95                	subw	a5,a5,a3
    800032c6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ca:	4037571b          	sraiw	a4,a4,0x3
    800032ce:	00e906b3          	add	a3,s2,a4
    800032d2:	0586c683          	lbu	a3,88(a3)
    800032d6:	00d7f5b3          	and	a1,a5,a3
    800032da:	cd91                	beqz	a1,800032f6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032dc:	2605                	addiw	a2,a2,1
    800032de:	2485                	addiw	s1,s1,1
    800032e0:	fd4618e3          	bne	a2,s4,800032b0 <balloc+0x80>
    800032e4:	b759                	j	8000326a <balloc+0x3a>
  panic("balloc: out of blocks");
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	28a50513          	addi	a0,a0,650 # 80008570 <syscalls+0x110>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032f6:	974a                	add	a4,a4,s2
    800032f8:	8fd5                	or	a5,a5,a3
    800032fa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032fe:	854a                	mv	a0,s2
    80003300:	00001097          	auipc	ra,0x1
    80003304:	01a080e7          	jalr	26(ra) # 8000431a <log_write>
        brelse(bp);
    80003308:	854a                	mv	a0,s2
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	d94080e7          	jalr	-620(ra) # 8000309e <brelse>
  bp = bread(dev, bno);
    80003312:	85a6                	mv	a1,s1
    80003314:	855e                	mv	a0,s7
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	c58080e7          	jalr	-936(ra) # 80002f6e <bread>
    8000331e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003320:	40000613          	li	a2,1024
    80003324:	4581                	li	a1,0
    80003326:	05850513          	addi	a0,a0,88
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	9b6080e7          	jalr	-1610(ra) # 80000ce0 <memset>
  log_write(bp);
    80003332:	854a                	mv	a0,s2
    80003334:	00001097          	auipc	ra,0x1
    80003338:	fe6080e7          	jalr	-26(ra) # 8000431a <log_write>
  brelse(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d60080e7          	jalr	-672(ra) # 8000309e <brelse>
}
    80003346:	8526                	mv	a0,s1
    80003348:	60e6                	ld	ra,88(sp)
    8000334a:	6446                	ld	s0,80(sp)
    8000334c:	64a6                	ld	s1,72(sp)
    8000334e:	6906                	ld	s2,64(sp)
    80003350:	79e2                	ld	s3,56(sp)
    80003352:	7a42                	ld	s4,48(sp)
    80003354:	7aa2                	ld	s5,40(sp)
    80003356:	7b02                	ld	s6,32(sp)
    80003358:	6be2                	ld	s7,24(sp)
    8000335a:	6c42                	ld	s8,16(sp)
    8000335c:	6ca2                	ld	s9,8(sp)
    8000335e:	6125                	addi	sp,sp,96
    80003360:	8082                	ret

0000000080003362 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003362:	7179                	addi	sp,sp,-48
    80003364:	f406                	sd	ra,40(sp)
    80003366:	f022                	sd	s0,32(sp)
    80003368:	ec26                	sd	s1,24(sp)
    8000336a:	e84a                	sd	s2,16(sp)
    8000336c:	e44e                	sd	s3,8(sp)
    8000336e:	e052                	sd	s4,0(sp)
    80003370:	1800                	addi	s0,sp,48
    80003372:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003374:	47ad                	li	a5,11
    80003376:	04b7fe63          	bgeu	a5,a1,800033d2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000337a:	ff45849b          	addiw	s1,a1,-12
    8000337e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003382:	0ff00793          	li	a5,255
    80003386:	0ae7e363          	bltu	a5,a4,8000342c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000338a:	08052583          	lw	a1,128(a0)
    8000338e:	c5ad                	beqz	a1,800033f8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003390:	00092503          	lw	a0,0(s2)
    80003394:	00000097          	auipc	ra,0x0
    80003398:	bda080e7          	jalr	-1062(ra) # 80002f6e <bread>
    8000339c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000339e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033a2:	02049593          	slli	a1,s1,0x20
    800033a6:	9181                	srli	a1,a1,0x20
    800033a8:	058a                	slli	a1,a1,0x2
    800033aa:	00b784b3          	add	s1,a5,a1
    800033ae:	0004a983          	lw	s3,0(s1)
    800033b2:	04098d63          	beqz	s3,8000340c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033b6:	8552                	mv	a0,s4
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	ce6080e7          	jalr	-794(ra) # 8000309e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033c0:	854e                	mv	a0,s3
    800033c2:	70a2                	ld	ra,40(sp)
    800033c4:	7402                	ld	s0,32(sp)
    800033c6:	64e2                	ld	s1,24(sp)
    800033c8:	6942                	ld	s2,16(sp)
    800033ca:	69a2                	ld	s3,8(sp)
    800033cc:	6a02                	ld	s4,0(sp)
    800033ce:	6145                	addi	sp,sp,48
    800033d0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033d2:	02059493          	slli	s1,a1,0x20
    800033d6:	9081                	srli	s1,s1,0x20
    800033d8:	048a                	slli	s1,s1,0x2
    800033da:	94aa                	add	s1,s1,a0
    800033dc:	0504a983          	lw	s3,80(s1)
    800033e0:	fe0990e3          	bnez	s3,800033c0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033e4:	4108                	lw	a0,0(a0)
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	e4a080e7          	jalr	-438(ra) # 80003230 <balloc>
    800033ee:	0005099b          	sext.w	s3,a0
    800033f2:	0534a823          	sw	s3,80(s1)
    800033f6:	b7e9                	j	800033c0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033f8:	4108                	lw	a0,0(a0)
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	e36080e7          	jalr	-458(ra) # 80003230 <balloc>
    80003402:	0005059b          	sext.w	a1,a0
    80003406:	08b92023          	sw	a1,128(s2)
    8000340a:	b759                	j	80003390 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000340c:	00092503          	lw	a0,0(s2)
    80003410:	00000097          	auipc	ra,0x0
    80003414:	e20080e7          	jalr	-480(ra) # 80003230 <balloc>
    80003418:	0005099b          	sext.w	s3,a0
    8000341c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003420:	8552                	mv	a0,s4
    80003422:	00001097          	auipc	ra,0x1
    80003426:	ef8080e7          	jalr	-264(ra) # 8000431a <log_write>
    8000342a:	b771                	j	800033b6 <bmap+0x54>
  panic("bmap: out of range");
    8000342c:	00005517          	auipc	a0,0x5
    80003430:	15c50513          	addi	a0,a0,348 # 80008588 <syscalls+0x128>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	10a080e7          	jalr	266(ra) # 8000053e <panic>

000000008000343c <iget>:
{
    8000343c:	7179                	addi	sp,sp,-48
    8000343e:	f406                	sd	ra,40(sp)
    80003440:	f022                	sd	s0,32(sp)
    80003442:	ec26                	sd	s1,24(sp)
    80003444:	e84a                	sd	s2,16(sp)
    80003446:	e44e                	sd	s3,8(sp)
    80003448:	e052                	sd	s4,0(sp)
    8000344a:	1800                	addi	s0,sp,48
    8000344c:	89aa                	mv	s3,a0
    8000344e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003450:	0001c517          	auipc	a0,0x1c
    80003454:	57850513          	addi	a0,a0,1400 # 8001f9c8 <itable>
    80003458:	ffffd097          	auipc	ra,0xffffd
    8000345c:	78c080e7          	jalr	1932(ra) # 80000be4 <acquire>
  empty = 0;
    80003460:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003462:	0001c497          	auipc	s1,0x1c
    80003466:	57e48493          	addi	s1,s1,1406 # 8001f9e0 <itable+0x18>
    8000346a:	0001e697          	auipc	a3,0x1e
    8000346e:	00668693          	addi	a3,a3,6 # 80021470 <log>
    80003472:	a039                	j	80003480 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003474:	02090b63          	beqz	s2,800034aa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003478:	08848493          	addi	s1,s1,136
    8000347c:	02d48a63          	beq	s1,a3,800034b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003480:	449c                	lw	a5,8(s1)
    80003482:	fef059e3          	blez	a5,80003474 <iget+0x38>
    80003486:	4098                	lw	a4,0(s1)
    80003488:	ff3716e3          	bne	a4,s3,80003474 <iget+0x38>
    8000348c:	40d8                	lw	a4,4(s1)
    8000348e:	ff4713e3          	bne	a4,s4,80003474 <iget+0x38>
      ip->ref++;
    80003492:	2785                	addiw	a5,a5,1
    80003494:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003496:	0001c517          	auipc	a0,0x1c
    8000349a:	53250513          	addi	a0,a0,1330 # 8001f9c8 <itable>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	7fa080e7          	jalr	2042(ra) # 80000c98 <release>
      return ip;
    800034a6:	8926                	mv	s2,s1
    800034a8:	a03d                	j	800034d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034aa:	f7f9                	bnez	a5,80003478 <iget+0x3c>
    800034ac:	8926                	mv	s2,s1
    800034ae:	b7e9                	j	80003478 <iget+0x3c>
  if(empty == 0)
    800034b0:	02090c63          	beqz	s2,800034e8 <iget+0xac>
  ip->dev = dev;
    800034b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034bc:	4785                	li	a5,1
    800034be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034c6:	0001c517          	auipc	a0,0x1c
    800034ca:	50250513          	addi	a0,a0,1282 # 8001f9c8 <itable>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
}
    800034d6:	854a                	mv	a0,s2
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6a02                	ld	s4,0(sp)
    800034e4:	6145                	addi	sp,sp,48
    800034e6:	8082                	ret
    panic("iget: no inodes");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	0b850513          	addi	a0,a0,184 # 800085a0 <syscalls+0x140>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800034f8 <fsinit>:
fsinit(int dev) {
    800034f8:	7179                	addi	sp,sp,-48
    800034fa:	f406                	sd	ra,40(sp)
    800034fc:	f022                	sd	s0,32(sp)
    800034fe:	ec26                	sd	s1,24(sp)
    80003500:	e84a                	sd	s2,16(sp)
    80003502:	e44e                	sd	s3,8(sp)
    80003504:	1800                	addi	s0,sp,48
    80003506:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003508:	4585                	li	a1,1
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	a64080e7          	jalr	-1436(ra) # 80002f6e <bread>
    80003512:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003514:	0001c997          	auipc	s3,0x1c
    80003518:	49498993          	addi	s3,s3,1172 # 8001f9a8 <sb>
    8000351c:	02000613          	li	a2,32
    80003520:	05850593          	addi	a1,a0,88
    80003524:	854e                	mv	a0,s3
    80003526:	ffffe097          	auipc	ra,0xffffe
    8000352a:	81a080e7          	jalr	-2022(ra) # 80000d40 <memmove>
  brelse(bp);
    8000352e:	8526                	mv	a0,s1
    80003530:	00000097          	auipc	ra,0x0
    80003534:	b6e080e7          	jalr	-1170(ra) # 8000309e <brelse>
  if(sb.magic != FSMAGIC)
    80003538:	0009a703          	lw	a4,0(s3)
    8000353c:	102037b7          	lui	a5,0x10203
    80003540:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003544:	02f71263          	bne	a4,a5,80003568 <fsinit+0x70>
  initlog(dev, &sb);
    80003548:	0001c597          	auipc	a1,0x1c
    8000354c:	46058593          	addi	a1,a1,1120 # 8001f9a8 <sb>
    80003550:	854a                	mv	a0,s2
    80003552:	00001097          	auipc	ra,0x1
    80003556:	b4c080e7          	jalr	-1204(ra) # 8000409e <initlog>
}
    8000355a:	70a2                	ld	ra,40(sp)
    8000355c:	7402                	ld	s0,32(sp)
    8000355e:	64e2                	ld	s1,24(sp)
    80003560:	6942                	ld	s2,16(sp)
    80003562:	69a2                	ld	s3,8(sp)
    80003564:	6145                	addi	sp,sp,48
    80003566:	8082                	ret
    panic("invalid file system");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	04850513          	addi	a0,a0,72 # 800085b0 <syscalls+0x150>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>

0000000080003578 <iinit>:
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003586:	00005597          	auipc	a1,0x5
    8000358a:	04258593          	addi	a1,a1,66 # 800085c8 <syscalls+0x168>
    8000358e:	0001c517          	auipc	a0,0x1c
    80003592:	43a50513          	addi	a0,a0,1082 # 8001f9c8 <itable>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	5be080e7          	jalr	1470(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000359e:	0001c497          	auipc	s1,0x1c
    800035a2:	45248493          	addi	s1,s1,1106 # 8001f9f0 <itable+0x28>
    800035a6:	0001e997          	auipc	s3,0x1e
    800035aa:	eda98993          	addi	s3,s3,-294 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ae:	00005917          	auipc	s2,0x5
    800035b2:	02290913          	addi	s2,s2,34 # 800085d0 <syscalls+0x170>
    800035b6:	85ca                	mv	a1,s2
    800035b8:	8526                	mv	a0,s1
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	e46080e7          	jalr	-442(ra) # 80004400 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035c2:	08848493          	addi	s1,s1,136
    800035c6:	ff3498e3          	bne	s1,s3,800035b6 <iinit+0x3e>
}
    800035ca:	70a2                	ld	ra,40(sp)
    800035cc:	7402                	ld	s0,32(sp)
    800035ce:	64e2                	ld	s1,24(sp)
    800035d0:	6942                	ld	s2,16(sp)
    800035d2:	69a2                	ld	s3,8(sp)
    800035d4:	6145                	addi	sp,sp,48
    800035d6:	8082                	ret

00000000800035d8 <ialloc>:
{
    800035d8:	715d                	addi	sp,sp,-80
    800035da:	e486                	sd	ra,72(sp)
    800035dc:	e0a2                	sd	s0,64(sp)
    800035de:	fc26                	sd	s1,56(sp)
    800035e0:	f84a                	sd	s2,48(sp)
    800035e2:	f44e                	sd	s3,40(sp)
    800035e4:	f052                	sd	s4,32(sp)
    800035e6:	ec56                	sd	s5,24(sp)
    800035e8:	e85a                	sd	s6,16(sp)
    800035ea:	e45e                	sd	s7,8(sp)
    800035ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ee:	0001c717          	auipc	a4,0x1c
    800035f2:	3c672703          	lw	a4,966(a4) # 8001f9b4 <sb+0xc>
    800035f6:	4785                	li	a5,1
    800035f8:	04e7fa63          	bgeu	a5,a4,8000364c <ialloc+0x74>
    800035fc:	8aaa                	mv	s5,a0
    800035fe:	8bae                	mv	s7,a1
    80003600:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003602:	0001ca17          	auipc	s4,0x1c
    80003606:	3a6a0a13          	addi	s4,s4,934 # 8001f9a8 <sb>
    8000360a:	00048b1b          	sext.w	s6,s1
    8000360e:	0044d593          	srli	a1,s1,0x4
    80003612:	018a2783          	lw	a5,24(s4)
    80003616:	9dbd                	addw	a1,a1,a5
    80003618:	8556                	mv	a0,s5
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	954080e7          	jalr	-1708(ra) # 80002f6e <bread>
    80003622:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003624:	05850993          	addi	s3,a0,88
    80003628:	00f4f793          	andi	a5,s1,15
    8000362c:	079a                	slli	a5,a5,0x6
    8000362e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003630:	00099783          	lh	a5,0(s3)
    80003634:	c785                	beqz	a5,8000365c <ialloc+0x84>
    brelse(bp);
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	a68080e7          	jalr	-1432(ra) # 8000309e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363e:	0485                	addi	s1,s1,1
    80003640:	00ca2703          	lw	a4,12(s4)
    80003644:	0004879b          	sext.w	a5,s1
    80003648:	fce7e1e3          	bltu	a5,a4,8000360a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	f8c50513          	addi	a0,a0,-116 # 800085d8 <syscalls+0x178>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000365c:	04000613          	li	a2,64
    80003660:	4581                	li	a1,0
    80003662:	854e                	mv	a0,s3
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	67c080e7          	jalr	1660(ra) # 80000ce0 <memset>
      dip->type = type;
    8000366c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003670:	854a                	mv	a0,s2
    80003672:	00001097          	auipc	ra,0x1
    80003676:	ca8080e7          	jalr	-856(ra) # 8000431a <log_write>
      brelse(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	a22080e7          	jalr	-1502(ra) # 8000309e <brelse>
      return iget(dev, inum);
    80003684:	85da                	mv	a1,s6
    80003686:	8556                	mv	a0,s5
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	db4080e7          	jalr	-588(ra) # 8000343c <iget>
}
    80003690:	60a6                	ld	ra,72(sp)
    80003692:	6406                	ld	s0,64(sp)
    80003694:	74e2                	ld	s1,56(sp)
    80003696:	7942                	ld	s2,48(sp)
    80003698:	79a2                	ld	s3,40(sp)
    8000369a:	7a02                	ld	s4,32(sp)
    8000369c:	6ae2                	ld	s5,24(sp)
    8000369e:	6b42                	ld	s6,16(sp)
    800036a0:	6ba2                	ld	s7,8(sp)
    800036a2:	6161                	addi	sp,sp,80
    800036a4:	8082                	ret

00000000800036a6 <iupdate>:
{
    800036a6:	1101                	addi	sp,sp,-32
    800036a8:	ec06                	sd	ra,24(sp)
    800036aa:	e822                	sd	s0,16(sp)
    800036ac:	e426                	sd	s1,8(sp)
    800036ae:	e04a                	sd	s2,0(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b4:	415c                	lw	a5,4(a0)
    800036b6:	0047d79b          	srliw	a5,a5,0x4
    800036ba:	0001c597          	auipc	a1,0x1c
    800036be:	3065a583          	lw	a1,774(a1) # 8001f9c0 <sb+0x18>
    800036c2:	9dbd                	addw	a1,a1,a5
    800036c4:	4108                	lw	a0,0(a0)
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	8a8080e7          	jalr	-1880(ra) # 80002f6e <bread>
    800036ce:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d0:	05850793          	addi	a5,a0,88
    800036d4:	40c8                	lw	a0,4(s1)
    800036d6:	893d                	andi	a0,a0,15
    800036d8:	051a                	slli	a0,a0,0x6
    800036da:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036dc:	04449703          	lh	a4,68(s1)
    800036e0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036e4:	04649703          	lh	a4,70(s1)
    800036e8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ec:	04849703          	lh	a4,72(s1)
    800036f0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036f4:	04a49703          	lh	a4,74(s1)
    800036f8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036fc:	44f8                	lw	a4,76(s1)
    800036fe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003700:	03400613          	li	a2,52
    80003704:	05048593          	addi	a1,s1,80
    80003708:	0531                	addi	a0,a0,12
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	636080e7          	jalr	1590(ra) # 80000d40 <memmove>
  log_write(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00001097          	auipc	ra,0x1
    80003718:	c06080e7          	jalr	-1018(ra) # 8000431a <log_write>
  brelse(bp);
    8000371c:	854a                	mv	a0,s2
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	980080e7          	jalr	-1664(ra) # 8000309e <brelse>
}
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6902                	ld	s2,0(sp)
    8000372e:	6105                	addi	sp,sp,32
    80003730:	8082                	ret

0000000080003732 <idup>:
{
    80003732:	1101                	addi	sp,sp,-32
    80003734:	ec06                	sd	ra,24(sp)
    80003736:	e822                	sd	s0,16(sp)
    80003738:	e426                	sd	s1,8(sp)
    8000373a:	1000                	addi	s0,sp,32
    8000373c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000373e:	0001c517          	auipc	a0,0x1c
    80003742:	28a50513          	addi	a0,a0,650 # 8001f9c8 <itable>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
  ip->ref++;
    8000374e:	449c                	lw	a5,8(s1)
    80003750:	2785                	addiw	a5,a5,1
    80003752:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003754:	0001c517          	auipc	a0,0x1c
    80003758:	27450513          	addi	a0,a0,628 # 8001f9c8 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	53c080e7          	jalr	1340(ra) # 80000c98 <release>
}
    80003764:	8526                	mv	a0,s1
    80003766:	60e2                	ld	ra,24(sp)
    80003768:	6442                	ld	s0,16(sp)
    8000376a:	64a2                	ld	s1,8(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret

0000000080003770 <ilock>:
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	e04a                	sd	s2,0(sp)
    8000377a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000377c:	c115                	beqz	a0,800037a0 <ilock+0x30>
    8000377e:	84aa                	mv	s1,a0
    80003780:	451c                	lw	a5,8(a0)
    80003782:	00f05f63          	blez	a5,800037a0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003786:	0541                	addi	a0,a0,16
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	cb2080e7          	jalr	-846(ra) # 8000443a <acquiresleep>
  if(ip->valid == 0){
    80003790:	40bc                	lw	a5,64(s1)
    80003792:	cf99                	beqz	a5,800037b0 <ilock+0x40>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6902                	ld	s2,0(sp)
    8000379c:	6105                	addi	sp,sp,32
    8000379e:	8082                	ret
    panic("ilock");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	e5050513          	addi	a0,a0,-432 # 800085f0 <syscalls+0x190>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b0:	40dc                	lw	a5,4(s1)
    800037b2:	0047d79b          	srliw	a5,a5,0x4
    800037b6:	0001c597          	auipc	a1,0x1c
    800037ba:	20a5a583          	lw	a1,522(a1) # 8001f9c0 <sb+0x18>
    800037be:	9dbd                	addw	a1,a1,a5
    800037c0:	4088                	lw	a0,0(s1)
    800037c2:	fffff097          	auipc	ra,0xfffff
    800037c6:	7ac080e7          	jalr	1964(ra) # 80002f6e <bread>
    800037ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037cc:	05850593          	addi	a1,a0,88
    800037d0:	40dc                	lw	a5,4(s1)
    800037d2:	8bbd                	andi	a5,a5,15
    800037d4:	079a                	slli	a5,a5,0x6
    800037d6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037d8:	00059783          	lh	a5,0(a1)
    800037dc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037e0:	00259783          	lh	a5,2(a1)
    800037e4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037e8:	00459783          	lh	a5,4(a1)
    800037ec:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037f0:	00659783          	lh	a5,6(a1)
    800037f4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037f8:	459c                	lw	a5,8(a1)
    800037fa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037fc:	03400613          	li	a2,52
    80003800:	05b1                	addi	a1,a1,12
    80003802:	05048513          	addi	a0,s1,80
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	53a080e7          	jalr	1338(ra) # 80000d40 <memmove>
    brelse(bp);
    8000380e:	854a                	mv	a0,s2
    80003810:	00000097          	auipc	ra,0x0
    80003814:	88e080e7          	jalr	-1906(ra) # 8000309e <brelse>
    ip->valid = 1;
    80003818:	4785                	li	a5,1
    8000381a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000381c:	04449783          	lh	a5,68(s1)
    80003820:	fbb5                	bnez	a5,80003794 <ilock+0x24>
      panic("ilock: no type");
    80003822:	00005517          	auipc	a0,0x5
    80003826:	dd650513          	addi	a0,a0,-554 # 800085f8 <syscalls+0x198>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080003832 <iunlock>:
{
    80003832:	1101                	addi	sp,sp,-32
    80003834:	ec06                	sd	ra,24(sp)
    80003836:	e822                	sd	s0,16(sp)
    80003838:	e426                	sd	s1,8(sp)
    8000383a:	e04a                	sd	s2,0(sp)
    8000383c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000383e:	c905                	beqz	a0,8000386e <iunlock+0x3c>
    80003840:	84aa                	mv	s1,a0
    80003842:	01050913          	addi	s2,a0,16
    80003846:	854a                	mv	a0,s2
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	c8c080e7          	jalr	-884(ra) # 800044d4 <holdingsleep>
    80003850:	cd19                	beqz	a0,8000386e <iunlock+0x3c>
    80003852:	449c                	lw	a5,8(s1)
    80003854:	00f05d63          	blez	a5,8000386e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	c36080e7          	jalr	-970(ra) # 80004490 <releasesleep>
}
    80003862:	60e2                	ld	ra,24(sp)
    80003864:	6442                	ld	s0,16(sp)
    80003866:	64a2                	ld	s1,8(sp)
    80003868:	6902                	ld	s2,0(sp)
    8000386a:	6105                	addi	sp,sp,32
    8000386c:	8082                	ret
    panic("iunlock");
    8000386e:	00005517          	auipc	a0,0x5
    80003872:	d9a50513          	addi	a0,a0,-614 # 80008608 <syscalls+0x1a8>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	cc8080e7          	jalr	-824(ra) # 8000053e <panic>

000000008000387e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000387e:	7179                	addi	sp,sp,-48
    80003880:	f406                	sd	ra,40(sp)
    80003882:	f022                	sd	s0,32(sp)
    80003884:	ec26                	sd	s1,24(sp)
    80003886:	e84a                	sd	s2,16(sp)
    80003888:	e44e                	sd	s3,8(sp)
    8000388a:	e052                	sd	s4,0(sp)
    8000388c:	1800                	addi	s0,sp,48
    8000388e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003890:	05050493          	addi	s1,a0,80
    80003894:	08050913          	addi	s2,a0,128
    80003898:	a021                	j	800038a0 <itrunc+0x22>
    8000389a:	0491                	addi	s1,s1,4
    8000389c:	01248d63          	beq	s1,s2,800038b6 <itrunc+0x38>
    if(ip->addrs[i]){
    800038a0:	408c                	lw	a1,0(s1)
    800038a2:	dde5                	beqz	a1,8000389a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	90c080e7          	jalr	-1780(ra) # 800031b4 <bfree>
      ip->addrs[i] = 0;
    800038b0:	0004a023          	sw	zero,0(s1)
    800038b4:	b7dd                	j	8000389a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038b6:	0809a583          	lw	a1,128(s3)
    800038ba:	e185                	bnez	a1,800038da <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038bc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c0:	854e                	mv	a0,s3
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	de4080e7          	jalr	-540(ra) # 800036a6 <iupdate>
}
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6a02                	ld	s4,0(sp)
    800038d6:	6145                	addi	sp,sp,48
    800038d8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038da:	0009a503          	lw	a0,0(s3)
    800038de:	fffff097          	auipc	ra,0xfffff
    800038e2:	690080e7          	jalr	1680(ra) # 80002f6e <bread>
    800038e6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e8:	05850493          	addi	s1,a0,88
    800038ec:	45850913          	addi	s2,a0,1112
    800038f0:	a811                	j	80003904 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	8be080e7          	jalr	-1858(ra) # 800031b4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038fe:	0491                	addi	s1,s1,4
    80003900:	01248563          	beq	s1,s2,8000390a <itrunc+0x8c>
      if(a[j])
    80003904:	408c                	lw	a1,0(s1)
    80003906:	dde5                	beqz	a1,800038fe <itrunc+0x80>
    80003908:	b7ed                	j	800038f2 <itrunc+0x74>
    brelse(bp);
    8000390a:	8552                	mv	a0,s4
    8000390c:	fffff097          	auipc	ra,0xfffff
    80003910:	792080e7          	jalr	1938(ra) # 8000309e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003914:	0809a583          	lw	a1,128(s3)
    80003918:	0009a503          	lw	a0,0(s3)
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	898080e7          	jalr	-1896(ra) # 800031b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003924:	0809a023          	sw	zero,128(s3)
    80003928:	bf51                	j	800038bc <itrunc+0x3e>

000000008000392a <iput>:
{
    8000392a:	1101                	addi	sp,sp,-32
    8000392c:	ec06                	sd	ra,24(sp)
    8000392e:	e822                	sd	s0,16(sp)
    80003930:	e426                	sd	s1,8(sp)
    80003932:	e04a                	sd	s2,0(sp)
    80003934:	1000                	addi	s0,sp,32
    80003936:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003938:	0001c517          	auipc	a0,0x1c
    8000393c:	09050513          	addi	a0,a0,144 # 8001f9c8 <itable>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	2a4080e7          	jalr	676(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003948:	4498                	lw	a4,8(s1)
    8000394a:	4785                	li	a5,1
    8000394c:	02f70363          	beq	a4,a5,80003972 <iput+0x48>
  ip->ref--;
    80003950:	449c                	lw	a5,8(s1)
    80003952:	37fd                	addiw	a5,a5,-1
    80003954:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003956:	0001c517          	auipc	a0,0x1c
    8000395a:	07250513          	addi	a0,a0,114 # 8001f9c8 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
}
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6902                	ld	s2,0(sp)
    8000396e:	6105                	addi	sp,sp,32
    80003970:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003972:	40bc                	lw	a5,64(s1)
    80003974:	dff1                	beqz	a5,80003950 <iput+0x26>
    80003976:	04a49783          	lh	a5,74(s1)
    8000397a:	fbf9                	bnez	a5,80003950 <iput+0x26>
    acquiresleep(&ip->lock);
    8000397c:	01048913          	addi	s2,s1,16
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ab8080e7          	jalr	-1352(ra) # 8000443a <acquiresleep>
    release(&itable.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	03e50513          	addi	a0,a0,62 # 8001f9c8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	306080e7          	jalr	774(ra) # 80000c98 <release>
    itrunc(ip);
    8000399a:	8526                	mv	a0,s1
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	ee2080e7          	jalr	-286(ra) # 8000387e <itrunc>
    ip->type = 0;
    800039a4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a8:	8526                	mv	a0,s1
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	cfc080e7          	jalr	-772(ra) # 800036a6 <iupdate>
    ip->valid = 0;
    800039b2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b6:	854a                	mv	a0,s2
    800039b8:	00001097          	auipc	ra,0x1
    800039bc:	ad8080e7          	jalr	-1320(ra) # 80004490 <releasesleep>
    acquire(&itable.lock);
    800039c0:	0001c517          	auipc	a0,0x1c
    800039c4:	00850513          	addi	a0,a0,8 # 8001f9c8 <itable>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	21c080e7          	jalr	540(ra) # 80000be4 <acquire>
    800039d0:	b741                	j	80003950 <iput+0x26>

00000000800039d2 <iunlockput>:
{
    800039d2:	1101                	addi	sp,sp,-32
    800039d4:	ec06                	sd	ra,24(sp)
    800039d6:	e822                	sd	s0,16(sp)
    800039d8:	e426                	sd	s1,8(sp)
    800039da:	1000                	addi	s0,sp,32
    800039dc:	84aa                	mv	s1,a0
  iunlock(ip);
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	e54080e7          	jalr	-428(ra) # 80003832 <iunlock>
  iput(ip);
    800039e6:	8526                	mv	a0,s1
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	f42080e7          	jalr	-190(ra) # 8000392a <iput>
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6105                	addi	sp,sp,32
    800039f8:	8082                	ret

00000000800039fa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039fa:	1141                	addi	sp,sp,-16
    800039fc:	e422                	sd	s0,8(sp)
    800039fe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a00:	411c                	lw	a5,0(a0)
    80003a02:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a04:	415c                	lw	a5,4(a0)
    80003a06:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a08:	04451783          	lh	a5,68(a0)
    80003a0c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a10:	04a51783          	lh	a5,74(a0)
    80003a14:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a18:	04c56783          	lwu	a5,76(a0)
    80003a1c:	e99c                	sd	a5,16(a1)
}
    80003a1e:	6422                	ld	s0,8(sp)
    80003a20:	0141                	addi	sp,sp,16
    80003a22:	8082                	ret

0000000080003a24 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a24:	457c                	lw	a5,76(a0)
    80003a26:	0ed7e963          	bltu	a5,a3,80003b18 <readi+0xf4>
{
    80003a2a:	7159                	addi	sp,sp,-112
    80003a2c:	f486                	sd	ra,104(sp)
    80003a2e:	f0a2                	sd	s0,96(sp)
    80003a30:	eca6                	sd	s1,88(sp)
    80003a32:	e8ca                	sd	s2,80(sp)
    80003a34:	e4ce                	sd	s3,72(sp)
    80003a36:	e0d2                	sd	s4,64(sp)
    80003a38:	fc56                	sd	s5,56(sp)
    80003a3a:	f85a                	sd	s6,48(sp)
    80003a3c:	f45e                	sd	s7,40(sp)
    80003a3e:	f062                	sd	s8,32(sp)
    80003a40:	ec66                	sd	s9,24(sp)
    80003a42:	e86a                	sd	s10,16(sp)
    80003a44:	e46e                	sd	s11,8(sp)
    80003a46:	1880                	addi	s0,sp,112
    80003a48:	8baa                	mv	s7,a0
    80003a4a:	8c2e                	mv	s8,a1
    80003a4c:	8ab2                	mv	s5,a2
    80003a4e:	84b6                	mv	s1,a3
    80003a50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a52:	9f35                	addw	a4,a4,a3
    return 0;
    80003a54:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a56:	0ad76063          	bltu	a4,a3,80003af6 <readi+0xd2>
  if(off + n > ip->size)
    80003a5a:	00e7f463          	bgeu	a5,a4,80003a62 <readi+0x3e>
    n = ip->size - off;
    80003a5e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a62:	0a0b0963          	beqz	s6,80003b14 <readi+0xf0>
    80003a66:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a68:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a6c:	5cfd                	li	s9,-1
    80003a6e:	a82d                	j	80003aa8 <readi+0x84>
    80003a70:	020a1d93          	slli	s11,s4,0x20
    80003a74:	020ddd93          	srli	s11,s11,0x20
    80003a78:	05890613          	addi	a2,s2,88
    80003a7c:	86ee                	mv	a3,s11
    80003a7e:	963a                	add	a2,a2,a4
    80003a80:	85d6                	mv	a1,s5
    80003a82:	8562                	mv	a0,s8
    80003a84:	fffff097          	auipc	ra,0xfffff
    80003a88:	ae4080e7          	jalr	-1308(ra) # 80002568 <either_copyout>
    80003a8c:	05950d63          	beq	a0,s9,80003ae6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a90:	854a                	mv	a0,s2
    80003a92:	fffff097          	auipc	ra,0xfffff
    80003a96:	60c080e7          	jalr	1548(ra) # 8000309e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9a:	013a09bb          	addw	s3,s4,s3
    80003a9e:	009a04bb          	addw	s1,s4,s1
    80003aa2:	9aee                	add	s5,s5,s11
    80003aa4:	0569f763          	bgeu	s3,s6,80003af2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aa8:	000ba903          	lw	s2,0(s7)
    80003aac:	00a4d59b          	srliw	a1,s1,0xa
    80003ab0:	855e                	mv	a0,s7
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	8b0080e7          	jalr	-1872(ra) # 80003362 <bmap>
    80003aba:	0005059b          	sext.w	a1,a0
    80003abe:	854a                	mv	a0,s2
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	4ae080e7          	jalr	1198(ra) # 80002f6e <bread>
    80003ac8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aca:	3ff4f713          	andi	a4,s1,1023
    80003ace:	40ed07bb          	subw	a5,s10,a4
    80003ad2:	413b06bb          	subw	a3,s6,s3
    80003ad6:	8a3e                	mv	s4,a5
    80003ad8:	2781                	sext.w	a5,a5
    80003ada:	0006861b          	sext.w	a2,a3
    80003ade:	f8f679e3          	bgeu	a2,a5,80003a70 <readi+0x4c>
    80003ae2:	8a36                	mv	s4,a3
    80003ae4:	b771                	j	80003a70 <readi+0x4c>
      brelse(bp);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	5b6080e7          	jalr	1462(ra) # 8000309e <brelse>
      tot = -1;
    80003af0:	59fd                	li	s3,-1
  }
  return tot;
    80003af2:	0009851b          	sext.w	a0,s3
}
    80003af6:	70a6                	ld	ra,104(sp)
    80003af8:	7406                	ld	s0,96(sp)
    80003afa:	64e6                	ld	s1,88(sp)
    80003afc:	6946                	ld	s2,80(sp)
    80003afe:	69a6                	ld	s3,72(sp)
    80003b00:	6a06                	ld	s4,64(sp)
    80003b02:	7ae2                	ld	s5,56(sp)
    80003b04:	7b42                	ld	s6,48(sp)
    80003b06:	7ba2                	ld	s7,40(sp)
    80003b08:	7c02                	ld	s8,32(sp)
    80003b0a:	6ce2                	ld	s9,24(sp)
    80003b0c:	6d42                	ld	s10,16(sp)
    80003b0e:	6da2                	ld	s11,8(sp)
    80003b10:	6165                	addi	sp,sp,112
    80003b12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b14:	89da                	mv	s3,s6
    80003b16:	bff1                	j	80003af2 <readi+0xce>
    return 0;
    80003b18:	4501                	li	a0,0
}
    80003b1a:	8082                	ret

0000000080003b1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1c:	457c                	lw	a5,76(a0)
    80003b1e:	10d7e863          	bltu	a5,a3,80003c2e <writei+0x112>
{
    80003b22:	7159                	addi	sp,sp,-112
    80003b24:	f486                	sd	ra,104(sp)
    80003b26:	f0a2                	sd	s0,96(sp)
    80003b28:	eca6                	sd	s1,88(sp)
    80003b2a:	e8ca                	sd	s2,80(sp)
    80003b2c:	e4ce                	sd	s3,72(sp)
    80003b2e:	e0d2                	sd	s4,64(sp)
    80003b30:	fc56                	sd	s5,56(sp)
    80003b32:	f85a                	sd	s6,48(sp)
    80003b34:	f45e                	sd	s7,40(sp)
    80003b36:	f062                	sd	s8,32(sp)
    80003b38:	ec66                	sd	s9,24(sp)
    80003b3a:	e86a                	sd	s10,16(sp)
    80003b3c:	e46e                	sd	s11,8(sp)
    80003b3e:	1880                	addi	s0,sp,112
    80003b40:	8b2a                	mv	s6,a0
    80003b42:	8c2e                	mv	s8,a1
    80003b44:	8ab2                	mv	s5,a2
    80003b46:	8936                	mv	s2,a3
    80003b48:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b4a:	00e687bb          	addw	a5,a3,a4
    80003b4e:	0ed7e263          	bltu	a5,a3,80003c32 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b52:	00043737          	lui	a4,0x43
    80003b56:	0ef76063          	bltu	a4,a5,80003c36 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5a:	0c0b8863          	beqz	s7,80003c2a <writei+0x10e>
    80003b5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b64:	5cfd                	li	s9,-1
    80003b66:	a091                	j	80003baa <writei+0x8e>
    80003b68:	02099d93          	slli	s11,s3,0x20
    80003b6c:	020ddd93          	srli	s11,s11,0x20
    80003b70:	05848513          	addi	a0,s1,88
    80003b74:	86ee                	mv	a3,s11
    80003b76:	8656                	mv	a2,s5
    80003b78:	85e2                	mv	a1,s8
    80003b7a:	953a                	add	a0,a0,a4
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	a42080e7          	jalr	-1470(ra) # 800025be <either_copyin>
    80003b84:	07950263          	beq	a0,s9,80003be8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	790080e7          	jalr	1936(ra) # 8000431a <log_write>
    brelse(bp);
    80003b92:	8526                	mv	a0,s1
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	50a080e7          	jalr	1290(ra) # 8000309e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9c:	01498a3b          	addw	s4,s3,s4
    80003ba0:	0129893b          	addw	s2,s3,s2
    80003ba4:	9aee                	add	s5,s5,s11
    80003ba6:	057a7663          	bgeu	s4,s7,80003bf2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003baa:	000b2483          	lw	s1,0(s6)
    80003bae:	00a9559b          	srliw	a1,s2,0xa
    80003bb2:	855a                	mv	a0,s6
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	7ae080e7          	jalr	1966(ra) # 80003362 <bmap>
    80003bbc:	0005059b          	sext.w	a1,a0
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	3ac080e7          	jalr	940(ra) # 80002f6e <bread>
    80003bca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bcc:	3ff97713          	andi	a4,s2,1023
    80003bd0:	40ed07bb          	subw	a5,s10,a4
    80003bd4:	414b86bb          	subw	a3,s7,s4
    80003bd8:	89be                	mv	s3,a5
    80003bda:	2781                	sext.w	a5,a5
    80003bdc:	0006861b          	sext.w	a2,a3
    80003be0:	f8f674e3          	bgeu	a2,a5,80003b68 <writei+0x4c>
    80003be4:	89b6                	mv	s3,a3
    80003be6:	b749                	j	80003b68 <writei+0x4c>
      brelse(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	4b4080e7          	jalr	1204(ra) # 8000309e <brelse>
  }

  if(off > ip->size)
    80003bf2:	04cb2783          	lw	a5,76(s6)
    80003bf6:	0127f463          	bgeu	a5,s2,80003bfe <writei+0xe2>
    ip->size = off;
    80003bfa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bfe:	855a                	mv	a0,s6
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	aa6080e7          	jalr	-1370(ra) # 800036a6 <iupdate>

  return tot;
    80003c08:	000a051b          	sext.w	a0,s4
}
    80003c0c:	70a6                	ld	ra,104(sp)
    80003c0e:	7406                	ld	s0,96(sp)
    80003c10:	64e6                	ld	s1,88(sp)
    80003c12:	6946                	ld	s2,80(sp)
    80003c14:	69a6                	ld	s3,72(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	7c02                	ld	s8,32(sp)
    80003c20:	6ce2                	ld	s9,24(sp)
    80003c22:	6d42                	ld	s10,16(sp)
    80003c24:	6da2                	ld	s11,8(sp)
    80003c26:	6165                	addi	sp,sp,112
    80003c28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2a:	8a5e                	mv	s4,s7
    80003c2c:	bfc9                	j	80003bfe <writei+0xe2>
    return -1;
    80003c2e:	557d                	li	a0,-1
}
    80003c30:	8082                	ret
    return -1;
    80003c32:	557d                	li	a0,-1
    80003c34:	bfe1                	j	80003c0c <writei+0xf0>
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	bfd1                	j	80003c0c <writei+0xf0>

0000000080003c3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3a:	1141                	addi	sp,sp,-16
    80003c3c:	e406                	sd	ra,8(sp)
    80003c3e:	e022                	sd	s0,0(sp)
    80003c40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c42:	4639                	li	a2,14
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	174080e7          	jalr	372(ra) # 80000db8 <strncmp>
}
    80003c4c:	60a2                	ld	ra,8(sp)
    80003c4e:	6402                	ld	s0,0(sp)
    80003c50:	0141                	addi	sp,sp,16
    80003c52:	8082                	ret

0000000080003c54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c54:	7139                	addi	sp,sp,-64
    80003c56:	fc06                	sd	ra,56(sp)
    80003c58:	f822                	sd	s0,48(sp)
    80003c5a:	f426                	sd	s1,40(sp)
    80003c5c:	f04a                	sd	s2,32(sp)
    80003c5e:	ec4e                	sd	s3,24(sp)
    80003c60:	e852                	sd	s4,16(sp)
    80003c62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c64:	04451703          	lh	a4,68(a0)
    80003c68:	4785                	li	a5,1
    80003c6a:	00f71a63          	bne	a4,a5,80003c7e <dirlookup+0x2a>
    80003c6e:	892a                	mv	s2,a0
    80003c70:	89ae                	mv	s3,a1
    80003c72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c74:	457c                	lw	a5,76(a0)
    80003c76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	e79d                	bnez	a5,80003ca8 <dirlookup+0x54>
    80003c7c:	a8a5                	j	80003cf4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	99250513          	addi	a0,a0,-1646 # 80008610 <syscalls+0x1b0>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8b8080e7          	jalr	-1864(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	99a50513          	addi	a0,a0,-1638 # 80008628 <syscalls+0x1c8>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8a8080e7          	jalr	-1880(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	24c1                	addiw	s1,s1,16
    80003ca0:	04c92783          	lw	a5,76(s2)
    80003ca4:	04f4f763          	bgeu	s1,a5,80003cf2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca8:	4741                	li	a4,16
    80003caa:	86a6                	mv	a3,s1
    80003cac:	fc040613          	addi	a2,s0,-64
    80003cb0:	4581                	li	a1,0
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	d70080e7          	jalr	-656(ra) # 80003a24 <readi>
    80003cbc:	47c1                	li	a5,16
    80003cbe:	fcf518e3          	bne	a0,a5,80003c8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc2:	fc045783          	lhu	a5,-64(s0)
    80003cc6:	dfe1                	beqz	a5,80003c9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc8:	fc240593          	addi	a1,s0,-62
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	f6c080e7          	jalr	-148(ra) # 80003c3a <namecmp>
    80003cd6:	f561                	bnez	a0,80003c9e <dirlookup+0x4a>
      if(poff)
    80003cd8:	000a0463          	beqz	s4,80003ce0 <dirlookup+0x8c>
        *poff = off;
    80003cdc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce0:	fc045583          	lhu	a1,-64(s0)
    80003ce4:	00092503          	lw	a0,0(s2)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	754080e7          	jalr	1876(ra) # 8000343c <iget>
    80003cf0:	a011                	j	80003cf4 <dirlookup+0xa0>
  return 0;
    80003cf2:	4501                	li	a0,0
}
    80003cf4:	70e2                	ld	ra,56(sp)
    80003cf6:	7442                	ld	s0,48(sp)
    80003cf8:	74a2                	ld	s1,40(sp)
    80003cfa:	7902                	ld	s2,32(sp)
    80003cfc:	69e2                	ld	s3,24(sp)
    80003cfe:	6a42                	ld	s4,16(sp)
    80003d00:	6121                	addi	sp,sp,64
    80003d02:	8082                	ret

0000000080003d04 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d04:	711d                	addi	sp,sp,-96
    80003d06:	ec86                	sd	ra,88(sp)
    80003d08:	e8a2                	sd	s0,80(sp)
    80003d0a:	e4a6                	sd	s1,72(sp)
    80003d0c:	e0ca                	sd	s2,64(sp)
    80003d0e:	fc4e                	sd	s3,56(sp)
    80003d10:	f852                	sd	s4,48(sp)
    80003d12:	f456                	sd	s5,40(sp)
    80003d14:	f05a                	sd	s6,32(sp)
    80003d16:	ec5e                	sd	s7,24(sp)
    80003d18:	e862                	sd	s8,16(sp)
    80003d1a:	e466                	sd	s9,8(sp)
    80003d1c:	1080                	addi	s0,sp,96
    80003d1e:	84aa                	mv	s1,a0
    80003d20:	8b2e                	mv	s6,a1
    80003d22:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d24:	00054703          	lbu	a4,0(a0)
    80003d28:	02f00793          	li	a5,47
    80003d2c:	02f70363          	beq	a4,a5,80003d52 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d30:	ffffe097          	auipc	ra,0xffffe
    80003d34:	eb4080e7          	jalr	-332(ra) # 80001be4 <myproc>
    80003d38:	15853503          	ld	a0,344(a0)
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	9f6080e7          	jalr	-1546(ra) # 80003732 <idup>
    80003d44:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d46:	02f00913          	li	s2,47
  len = path - s;
    80003d4a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d4c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d4e:	4c05                	li	s8,1
    80003d50:	a865                	j	80003e08 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d52:	4585                	li	a1,1
    80003d54:	4505                	li	a0,1
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	6e6080e7          	jalr	1766(ra) # 8000343c <iget>
    80003d5e:	89aa                	mv	s3,a0
    80003d60:	b7dd                	j	80003d46 <namex+0x42>
      iunlockput(ip);
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	c6e080e7          	jalr	-914(ra) # 800039d2 <iunlockput>
      return 0;
    80003d6c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d6e:	854e                	mv	a0,s3
    80003d70:	60e6                	ld	ra,88(sp)
    80003d72:	6446                	ld	s0,80(sp)
    80003d74:	64a6                	ld	s1,72(sp)
    80003d76:	6906                	ld	s2,64(sp)
    80003d78:	79e2                	ld	s3,56(sp)
    80003d7a:	7a42                	ld	s4,48(sp)
    80003d7c:	7aa2                	ld	s5,40(sp)
    80003d7e:	7b02                	ld	s6,32(sp)
    80003d80:	6be2                	ld	s7,24(sp)
    80003d82:	6c42                	ld	s8,16(sp)
    80003d84:	6ca2                	ld	s9,8(sp)
    80003d86:	6125                	addi	sp,sp,96
    80003d88:	8082                	ret
      iunlock(ip);
    80003d8a:	854e                	mv	a0,s3
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	aa6080e7          	jalr	-1370(ra) # 80003832 <iunlock>
      return ip;
    80003d94:	bfe9                	j	80003d6e <namex+0x6a>
      iunlockput(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	c3a080e7          	jalr	-966(ra) # 800039d2 <iunlockput>
      return 0;
    80003da0:	89d2                	mv	s3,s4
    80003da2:	b7f1                	j	80003d6e <namex+0x6a>
  len = path - s;
    80003da4:	40b48633          	sub	a2,s1,a1
    80003da8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dac:	094cd463          	bge	s9,s4,80003e34 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003db0:	4639                	li	a2,14
    80003db2:	8556                	mv	a0,s5
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	f8c080e7          	jalr	-116(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	01279763          	bne	a5,s2,80003dce <namex+0xca>
    path++;
    80003dc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc6:	0004c783          	lbu	a5,0(s1)
    80003dca:	ff278de3          	beq	a5,s2,80003dc4 <namex+0xc0>
    ilock(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	9a0080e7          	jalr	-1632(ra) # 80003770 <ilock>
    if(ip->type != T_DIR){
    80003dd8:	04499783          	lh	a5,68(s3)
    80003ddc:	f98793e3          	bne	a5,s8,80003d62 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003de0:	000b0563          	beqz	s6,80003dea <namex+0xe6>
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	d3cd                	beqz	a5,80003d8a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dea:	865e                	mv	a2,s7
    80003dec:	85d6                	mv	a1,s5
    80003dee:	854e                	mv	a0,s3
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	e64080e7          	jalr	-412(ra) # 80003c54 <dirlookup>
    80003df8:	8a2a                	mv	s4,a0
    80003dfa:	dd51                	beqz	a0,80003d96 <namex+0x92>
    iunlockput(ip);
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	bd4080e7          	jalr	-1068(ra) # 800039d2 <iunlockput>
    ip = next;
    80003e06:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	05279763          	bne	a5,s2,80003e5a <namex+0x156>
    path++;
    80003e10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	ff278de3          	beq	a5,s2,80003e10 <namex+0x10c>
  if(*path == 0)
    80003e1a:	c79d                	beqz	a5,80003e48 <namex+0x144>
    path++;
    80003e1c:	85a6                	mv	a1,s1
  len = path - s;
    80003e1e:	8a5e                	mv	s4,s7
    80003e20:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e22:	01278963          	beq	a5,s2,80003e34 <namex+0x130>
    80003e26:	dfbd                	beqz	a5,80003da4 <namex+0xa0>
    path++;
    80003e28:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	ff279ce3          	bne	a5,s2,80003e26 <namex+0x122>
    80003e32:	bf8d                	j	80003da4 <namex+0xa0>
    memmove(name, s, len);
    80003e34:	2601                	sext.w	a2,a2
    80003e36:	8556                	mv	a0,s5
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	f08080e7          	jalr	-248(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e40:	9a56                	add	s4,s4,s5
    80003e42:	000a0023          	sb	zero,0(s4)
    80003e46:	bf9d                	j	80003dbc <namex+0xb8>
  if(nameiparent){
    80003e48:	f20b03e3          	beqz	s6,80003d6e <namex+0x6a>
    iput(ip);
    80003e4c:	854e                	mv	a0,s3
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	adc080e7          	jalr	-1316(ra) # 8000392a <iput>
    return 0;
    80003e56:	4981                	li	s3,0
    80003e58:	bf19                	j	80003d6e <namex+0x6a>
  if(*path == 0)
    80003e5a:	d7fd                	beqz	a5,80003e48 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	85a6                	mv	a1,s1
    80003e62:	b7d1                	j	80003e26 <namex+0x122>

0000000080003e64 <dirlink>:
{
    80003e64:	7139                	addi	sp,sp,-64
    80003e66:	fc06                	sd	ra,56(sp)
    80003e68:	f822                	sd	s0,48(sp)
    80003e6a:	f426                	sd	s1,40(sp)
    80003e6c:	f04a                	sd	s2,32(sp)
    80003e6e:	ec4e                	sd	s3,24(sp)
    80003e70:	e852                	sd	s4,16(sp)
    80003e72:	0080                	addi	s0,sp,64
    80003e74:	892a                	mv	s2,a0
    80003e76:	8a2e                	mv	s4,a1
    80003e78:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e7a:	4601                	li	a2,0
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	dd8080e7          	jalr	-552(ra) # 80003c54 <dirlookup>
    80003e84:	e93d                	bnez	a0,80003efa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e86:	04c92483          	lw	s1,76(s2)
    80003e8a:	c49d                	beqz	s1,80003eb8 <dirlink+0x54>
    80003e8c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8e:	4741                	li	a4,16
    80003e90:	86a6                	mv	a3,s1
    80003e92:	fc040613          	addi	a2,s0,-64
    80003e96:	4581                	li	a1,0
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	b8a080e7          	jalr	-1142(ra) # 80003a24 <readi>
    80003ea2:	47c1                	li	a5,16
    80003ea4:	06f51163          	bne	a0,a5,80003f06 <dirlink+0xa2>
    if(de.inum == 0)
    80003ea8:	fc045783          	lhu	a5,-64(s0)
    80003eac:	c791                	beqz	a5,80003eb8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eae:	24c1                	addiw	s1,s1,16
    80003eb0:	04c92783          	lw	a5,76(s2)
    80003eb4:	fcf4ede3          	bltu	s1,a5,80003e8e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eb8:	4639                	li	a2,14
    80003eba:	85d2                	mv	a1,s4
    80003ebc:	fc240513          	addi	a0,s0,-62
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	f34080e7          	jalr	-204(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003ec8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	4741                	li	a4,16
    80003ece:	86a6                	mv	a3,s1
    80003ed0:	fc040613          	addi	a2,s0,-64
    80003ed4:	4581                	li	a1,0
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	c44080e7          	jalr	-956(ra) # 80003b1c <writei>
    80003ee0:	872a                	mv	a4,a0
    80003ee2:	47c1                	li	a5,16
  return 0;
    80003ee4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	02f71863          	bne	a4,a5,80003f16 <dirlink+0xb2>
}
    80003eea:	70e2                	ld	ra,56(sp)
    80003eec:	7442                	ld	s0,48(sp)
    80003eee:	74a2                	ld	s1,40(sp)
    80003ef0:	7902                	ld	s2,32(sp)
    80003ef2:	69e2                	ld	s3,24(sp)
    80003ef4:	6a42                	ld	s4,16(sp)
    80003ef6:	6121                	addi	sp,sp,64
    80003ef8:	8082                	ret
    iput(ip);
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	a30080e7          	jalr	-1488(ra) # 8000392a <iput>
    return -1;
    80003f02:	557d                	li	a0,-1
    80003f04:	b7dd                	j	80003eea <dirlink+0x86>
      panic("dirlink read");
    80003f06:	00004517          	auipc	a0,0x4
    80003f0a:	73250513          	addi	a0,a0,1842 # 80008638 <syscalls+0x1d8>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    panic("dirlink");
    80003f16:	00005517          	auipc	a0,0x5
    80003f1a:	83250513          	addi	a0,a0,-1998 # 80008748 <syscalls+0x2e8>
    80003f1e:	ffffc097          	auipc	ra,0xffffc
    80003f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>

0000000080003f26 <namei>:

struct inode*
namei(char *path)
{
    80003f26:	1101                	addi	sp,sp,-32
    80003f28:	ec06                	sd	ra,24(sp)
    80003f2a:	e822                	sd	s0,16(sp)
    80003f2c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f2e:	fe040613          	addi	a2,s0,-32
    80003f32:	4581                	li	a1,0
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	dd0080e7          	jalr	-560(ra) # 80003d04 <namex>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	6105                	addi	sp,sp,32
    80003f42:	8082                	ret

0000000080003f44 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f44:	1141                	addi	sp,sp,-16
    80003f46:	e406                	sd	ra,8(sp)
    80003f48:	e022                	sd	s0,0(sp)
    80003f4a:	0800                	addi	s0,sp,16
    80003f4c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f4e:	4585                	li	a1,1
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	db4080e7          	jalr	-588(ra) # 80003d04 <namex>
}
    80003f58:	60a2                	ld	ra,8(sp)
    80003f5a:	6402                	ld	s0,0(sp)
    80003f5c:	0141                	addi	sp,sp,16
    80003f5e:	8082                	ret

0000000080003f60 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	e426                	sd	s1,8(sp)
    80003f68:	e04a                	sd	s2,0(sp)
    80003f6a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f6c:	0001d917          	auipc	s2,0x1d
    80003f70:	50490913          	addi	s2,s2,1284 # 80021470 <log>
    80003f74:	01892583          	lw	a1,24(s2)
    80003f78:	02892503          	lw	a0,40(s2)
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	ff2080e7          	jalr	-14(ra) # 80002f6e <bread>
    80003f84:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f86:	02c92683          	lw	a3,44(s2)
    80003f8a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f8c:	02d05763          	blez	a3,80003fba <write_head+0x5a>
    80003f90:	0001d797          	auipc	a5,0x1d
    80003f94:	51078793          	addi	a5,a5,1296 # 800214a0 <log+0x30>
    80003f98:	05c50713          	addi	a4,a0,92
    80003f9c:	36fd                	addiw	a3,a3,-1
    80003f9e:	1682                	slli	a3,a3,0x20
    80003fa0:	9281                	srli	a3,a3,0x20
    80003fa2:	068a                	slli	a3,a3,0x2
    80003fa4:	0001d617          	auipc	a2,0x1d
    80003fa8:	50060613          	addi	a2,a2,1280 # 800214a4 <log+0x34>
    80003fac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fae:	4390                	lw	a2,0(a5)
    80003fb0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb2:	0791                	addi	a5,a5,4
    80003fb4:	0711                	addi	a4,a4,4
    80003fb6:	fed79ce3          	bne	a5,a3,80003fae <write_head+0x4e>
  }
  bwrite(buf);
    80003fba:	8526                	mv	a0,s1
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	0a4080e7          	jalr	164(ra) # 80003060 <bwrite>
  brelse(buf);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	0d8080e7          	jalr	216(ra) # 8000309e <brelse>
}
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	64a2                	ld	s1,8(sp)
    80003fd4:	6902                	ld	s2,0(sp)
    80003fd6:	6105                	addi	sp,sp,32
    80003fd8:	8082                	ret

0000000080003fda <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fda:	0001d797          	auipc	a5,0x1d
    80003fde:	4c27a783          	lw	a5,1218(a5) # 8002149c <log+0x2c>
    80003fe2:	0af05d63          	blez	a5,8000409c <install_trans+0xc2>
{
    80003fe6:	7139                	addi	sp,sp,-64
    80003fe8:	fc06                	sd	ra,56(sp)
    80003fea:	f822                	sd	s0,48(sp)
    80003fec:	f426                	sd	s1,40(sp)
    80003fee:	f04a                	sd	s2,32(sp)
    80003ff0:	ec4e                	sd	s3,24(sp)
    80003ff2:	e852                	sd	s4,16(sp)
    80003ff4:	e456                	sd	s5,8(sp)
    80003ff6:	e05a                	sd	s6,0(sp)
    80003ff8:	0080                	addi	s0,sp,64
    80003ffa:	8b2a                	mv	s6,a0
    80003ffc:	0001da97          	auipc	s5,0x1d
    80004000:	4a4a8a93          	addi	s5,s5,1188 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004004:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004006:	0001d997          	auipc	s3,0x1d
    8000400a:	46a98993          	addi	s3,s3,1130 # 80021470 <log>
    8000400e:	a035                	j	8000403a <install_trans+0x60>
      bunpin(dbuf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	166080e7          	jalr	358(ra) # 80003178 <bunpin>
    brelse(lbuf);
    8000401a:	854a                	mv	a0,s2
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	082080e7          	jalr	130(ra) # 8000309e <brelse>
    brelse(dbuf);
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	078080e7          	jalr	120(ra) # 8000309e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402e:	2a05                	addiw	s4,s4,1
    80004030:	0a91                	addi	s5,s5,4
    80004032:	02c9a783          	lw	a5,44(s3)
    80004036:	04fa5963          	bge	s4,a5,80004088 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403a:	0189a583          	lw	a1,24(s3)
    8000403e:	014585bb          	addw	a1,a1,s4
    80004042:	2585                	addiw	a1,a1,1
    80004044:	0289a503          	lw	a0,40(s3)
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	f26080e7          	jalr	-218(ra) # 80002f6e <bread>
    80004050:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004052:	000aa583          	lw	a1,0(s5)
    80004056:	0289a503          	lw	a0,40(s3)
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	f14080e7          	jalr	-236(ra) # 80002f6e <bread>
    80004062:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004064:	40000613          	li	a2,1024
    80004068:	05890593          	addi	a1,s2,88
    8000406c:	05850513          	addi	a0,a0,88
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	cd0080e7          	jalr	-816(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004078:	8526                	mv	a0,s1
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	fe6080e7          	jalr	-26(ra) # 80003060 <bwrite>
    if(recovering == 0)
    80004082:	f80b1ce3          	bnez	s6,8000401a <install_trans+0x40>
    80004086:	b769                	j	80004010 <install_trans+0x36>
}
    80004088:	70e2                	ld	ra,56(sp)
    8000408a:	7442                	ld	s0,48(sp)
    8000408c:	74a2                	ld	s1,40(sp)
    8000408e:	7902                	ld	s2,32(sp)
    80004090:	69e2                	ld	s3,24(sp)
    80004092:	6a42                	ld	s4,16(sp)
    80004094:	6aa2                	ld	s5,8(sp)
    80004096:	6b02                	ld	s6,0(sp)
    80004098:	6121                	addi	sp,sp,64
    8000409a:	8082                	ret
    8000409c:	8082                	ret

000000008000409e <initlog>:
{
    8000409e:	7179                	addi	sp,sp,-48
    800040a0:	f406                	sd	ra,40(sp)
    800040a2:	f022                	sd	s0,32(sp)
    800040a4:	ec26                	sd	s1,24(sp)
    800040a6:	e84a                	sd	s2,16(sp)
    800040a8:	e44e                	sd	s3,8(sp)
    800040aa:	1800                	addi	s0,sp,48
    800040ac:	892a                	mv	s2,a0
    800040ae:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040b0:	0001d497          	auipc	s1,0x1d
    800040b4:	3c048493          	addi	s1,s1,960 # 80021470 <log>
    800040b8:	00004597          	auipc	a1,0x4
    800040bc:	59058593          	addi	a1,a1,1424 # 80008648 <syscalls+0x1e8>
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	a92080e7          	jalr	-1390(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040ca:	0149a583          	lw	a1,20(s3)
    800040ce:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040d0:	0109a783          	lw	a5,16(s3)
    800040d4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040d6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040da:	854a                	mv	a0,s2
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	e92080e7          	jalr	-366(ra) # 80002f6e <bread>
  log.lh.n = lh->n;
    800040e4:	4d3c                	lw	a5,88(a0)
    800040e6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040e8:	02f05563          	blez	a5,80004112 <initlog+0x74>
    800040ec:	05c50713          	addi	a4,a0,92
    800040f0:	0001d697          	auipc	a3,0x1d
    800040f4:	3b068693          	addi	a3,a3,944 # 800214a0 <log+0x30>
    800040f8:	37fd                	addiw	a5,a5,-1
    800040fa:	1782                	slli	a5,a5,0x20
    800040fc:	9381                	srli	a5,a5,0x20
    800040fe:	078a                	slli	a5,a5,0x2
    80004100:	06050613          	addi	a2,a0,96
    80004104:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004106:	4310                	lw	a2,0(a4)
    80004108:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000410a:	0711                	addi	a4,a4,4
    8000410c:	0691                	addi	a3,a3,4
    8000410e:	fef71ce3          	bne	a4,a5,80004106 <initlog+0x68>
  brelse(buf);
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	f8c080e7          	jalr	-116(ra) # 8000309e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000411a:	4505                	li	a0,1
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	ebe080e7          	jalr	-322(ra) # 80003fda <install_trans>
  log.lh.n = 0;
    80004124:	0001d797          	auipc	a5,0x1d
    80004128:	3607ac23          	sw	zero,888(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	e34080e7          	jalr	-460(ra) # 80003f60 <write_head>
}
    80004134:	70a2                	ld	ra,40(sp)
    80004136:	7402                	ld	s0,32(sp)
    80004138:	64e2                	ld	s1,24(sp)
    8000413a:	6942                	ld	s2,16(sp)
    8000413c:	69a2                	ld	s3,8(sp)
    8000413e:	6145                	addi	sp,sp,48
    80004140:	8082                	ret

0000000080004142 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004142:	1101                	addi	sp,sp,-32
    80004144:	ec06                	sd	ra,24(sp)
    80004146:	e822                	sd	s0,16(sp)
    80004148:	e426                	sd	s1,8(sp)
    8000414a:	e04a                	sd	s2,0(sp)
    8000414c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000414e:	0001d517          	auipc	a0,0x1d
    80004152:	32250513          	addi	a0,a0,802 # 80021470 <log>
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	a8e080e7          	jalr	-1394(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000415e:	0001d497          	auipc	s1,0x1d
    80004162:	31248493          	addi	s1,s1,786 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004166:	4979                	li	s2,30
    80004168:	a039                	j	80004176 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000416a:	85a6                	mv	a1,s1
    8000416c:	8526                	mv	a0,s1
    8000416e:	ffffe097          	auipc	ra,0xffffe
    80004172:	0c8080e7          	jalr	200(ra) # 80002236 <sleep>
    if(log.committing){
    80004176:	50dc                	lw	a5,36(s1)
    80004178:	fbed                	bnez	a5,8000416a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000417a:	509c                	lw	a5,32(s1)
    8000417c:	0017871b          	addiw	a4,a5,1
    80004180:	0007069b          	sext.w	a3,a4
    80004184:	0027179b          	slliw	a5,a4,0x2
    80004188:	9fb9                	addw	a5,a5,a4
    8000418a:	0017979b          	slliw	a5,a5,0x1
    8000418e:	54d8                	lw	a4,44(s1)
    80004190:	9fb9                	addw	a5,a5,a4
    80004192:	00f95963          	bge	s2,a5,800041a4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004196:	85a6                	mv	a1,s1
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffe097          	auipc	ra,0xffffe
    8000419e:	09c080e7          	jalr	156(ra) # 80002236 <sleep>
    800041a2:	bfd1                	j	80004176 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041a4:	0001d517          	auipc	a0,0x1d
    800041a8:	2cc50513          	addi	a0,a0,716 # 80021470 <log>
    800041ac:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041b6:	60e2                	ld	ra,24(sp)
    800041b8:	6442                	ld	s0,16(sp)
    800041ba:	64a2                	ld	s1,8(sp)
    800041bc:	6902                	ld	s2,0(sp)
    800041be:	6105                	addi	sp,sp,32
    800041c0:	8082                	ret

00000000800041c2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041c2:	7139                	addi	sp,sp,-64
    800041c4:	fc06                	sd	ra,56(sp)
    800041c6:	f822                	sd	s0,48(sp)
    800041c8:	f426                	sd	s1,40(sp)
    800041ca:	f04a                	sd	s2,32(sp)
    800041cc:	ec4e                	sd	s3,24(sp)
    800041ce:	e852                	sd	s4,16(sp)
    800041d0:	e456                	sd	s5,8(sp)
    800041d2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041d4:	0001d497          	auipc	s1,0x1d
    800041d8:	29c48493          	addi	s1,s1,668 # 80021470 <log>
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	a06080e7          	jalr	-1530(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800041e6:	509c                	lw	a5,32(s1)
    800041e8:	37fd                	addiw	a5,a5,-1
    800041ea:	0007891b          	sext.w	s2,a5
    800041ee:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041f0:	50dc                	lw	a5,36(s1)
    800041f2:	efb9                	bnez	a5,80004250 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041f4:	06091663          	bnez	s2,80004260 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041f8:	0001d497          	auipc	s1,0x1d
    800041fc:	27848493          	addi	s1,s1,632 # 80021470 <log>
    80004200:	4785                	li	a5,1
    80004202:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004204:	8526                	mv	a0,s1
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000420e:	54dc                	lw	a5,44(s1)
    80004210:	06f04763          	bgtz	a5,8000427e <end_op+0xbc>
    acquire(&log.lock);
    80004214:	0001d497          	auipc	s1,0x1d
    80004218:	25c48493          	addi	s1,s1,604 # 80021470 <log>
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004226:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffe097          	auipc	ra,0xffffe
    80004230:	196080e7          	jalr	406(ra) # 800023c2 <wakeup>
    release(&log.lock);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a62080e7          	jalr	-1438(ra) # 80000c98 <release>
}
    8000423e:	70e2                	ld	ra,56(sp)
    80004240:	7442                	ld	s0,48(sp)
    80004242:	74a2                	ld	s1,40(sp)
    80004244:	7902                	ld	s2,32(sp)
    80004246:	69e2                	ld	s3,24(sp)
    80004248:	6a42                	ld	s4,16(sp)
    8000424a:	6aa2                	ld	s5,8(sp)
    8000424c:	6121                	addi	sp,sp,64
    8000424e:	8082                	ret
    panic("log.committing");
    80004250:	00004517          	auipc	a0,0x4
    80004254:	40050513          	addi	a0,a0,1024 # 80008650 <syscalls+0x1f0>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2e6080e7          	jalr	742(ra) # 8000053e <panic>
    wakeup(&log);
    80004260:	0001d497          	auipc	s1,0x1d
    80004264:	21048493          	addi	s1,s1,528 # 80021470 <log>
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffe097          	auipc	ra,0xffffe
    8000426e:	158080e7          	jalr	344(ra) # 800023c2 <wakeup>
  release(&log.lock);
    80004272:	8526                	mv	a0,s1
    80004274:	ffffd097          	auipc	ra,0xffffd
    80004278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
  if(do_commit){
    8000427c:	b7c9                	j	8000423e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427e:	0001da97          	auipc	s5,0x1d
    80004282:	222a8a93          	addi	s5,s5,546 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004286:	0001da17          	auipc	s4,0x1d
    8000428a:	1eaa0a13          	addi	s4,s4,490 # 80021470 <log>
    8000428e:	018a2583          	lw	a1,24(s4)
    80004292:	012585bb          	addw	a1,a1,s2
    80004296:	2585                	addiw	a1,a1,1
    80004298:	028a2503          	lw	a0,40(s4)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	cd2080e7          	jalr	-814(ra) # 80002f6e <bread>
    800042a4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042a6:	000aa583          	lw	a1,0(s5)
    800042aa:	028a2503          	lw	a0,40(s4)
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	cc0080e7          	jalr	-832(ra) # 80002f6e <bread>
    800042b6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042b8:	40000613          	li	a2,1024
    800042bc:	05850593          	addi	a1,a0,88
    800042c0:	05848513          	addi	a0,s1,88
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a7c080e7          	jalr	-1412(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	d92080e7          	jalr	-622(ra) # 80003060 <bwrite>
    brelse(from);
    800042d6:	854e                	mv	a0,s3
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	dc6080e7          	jalr	-570(ra) # 8000309e <brelse>
    brelse(to);
    800042e0:	8526                	mv	a0,s1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	dbc080e7          	jalr	-580(ra) # 8000309e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ea:	2905                	addiw	s2,s2,1
    800042ec:	0a91                	addi	s5,s5,4
    800042ee:	02ca2783          	lw	a5,44(s4)
    800042f2:	f8f94ee3          	blt	s2,a5,8000428e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	c6a080e7          	jalr	-918(ra) # 80003f60 <write_head>
    install_trans(0); // Now install writes to home locations
    800042fe:	4501                	li	a0,0
    80004300:	00000097          	auipc	ra,0x0
    80004304:	cda080e7          	jalr	-806(ra) # 80003fda <install_trans>
    log.lh.n = 0;
    80004308:	0001d797          	auipc	a5,0x1d
    8000430c:	1807aa23          	sw	zero,404(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004310:	00000097          	auipc	ra,0x0
    80004314:	c50080e7          	jalr	-944(ra) # 80003f60 <write_head>
    80004318:	bdf5                	j	80004214 <end_op+0x52>

000000008000431a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000431a:	1101                	addi	sp,sp,-32
    8000431c:	ec06                	sd	ra,24(sp)
    8000431e:	e822                	sd	s0,16(sp)
    80004320:	e426                	sd	s1,8(sp)
    80004322:	e04a                	sd	s2,0(sp)
    80004324:	1000                	addi	s0,sp,32
    80004326:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004328:	0001d917          	auipc	s2,0x1d
    8000432c:	14890913          	addi	s2,s2,328 # 80021470 <log>
    80004330:	854a                	mv	a0,s2
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000433a:	02c92603          	lw	a2,44(s2)
    8000433e:	47f5                	li	a5,29
    80004340:	06c7c563          	blt	a5,a2,800043aa <log_write+0x90>
    80004344:	0001d797          	auipc	a5,0x1d
    80004348:	1487a783          	lw	a5,328(a5) # 8002148c <log+0x1c>
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	04f65e63          	bge	a2,a5,800043aa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004352:	0001d797          	auipc	a5,0x1d
    80004356:	13e7a783          	lw	a5,318(a5) # 80021490 <log+0x20>
    8000435a:	06f05063          	blez	a5,800043ba <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000435e:	4781                	li	a5,0
    80004360:	06c05563          	blez	a2,800043ca <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004364:	44cc                	lw	a1,12(s1)
    80004366:	0001d717          	auipc	a4,0x1d
    8000436a:	13a70713          	addi	a4,a4,314 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000436e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004370:	4314                	lw	a3,0(a4)
    80004372:	04b68c63          	beq	a3,a1,800043ca <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004376:	2785                	addiw	a5,a5,1
    80004378:	0711                	addi	a4,a4,4
    8000437a:	fef61be3          	bne	a2,a5,80004370 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000437e:	0621                	addi	a2,a2,8
    80004380:	060a                	slli	a2,a2,0x2
    80004382:	0001d797          	auipc	a5,0x1d
    80004386:	0ee78793          	addi	a5,a5,238 # 80021470 <log>
    8000438a:	963e                	add	a2,a2,a5
    8000438c:	44dc                	lw	a5,12(s1)
    8000438e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	daa080e7          	jalr	-598(ra) # 8000313c <bpin>
    log.lh.n++;
    8000439a:	0001d717          	auipc	a4,0x1d
    8000439e:	0d670713          	addi	a4,a4,214 # 80021470 <log>
    800043a2:	575c                	lw	a5,44(a4)
    800043a4:	2785                	addiw	a5,a5,1
    800043a6:	d75c                	sw	a5,44(a4)
    800043a8:	a835                	j	800043e4 <log_write+0xca>
    panic("too big a transaction");
    800043aa:	00004517          	auipc	a0,0x4
    800043ae:	2b650513          	addi	a0,a0,694 # 80008660 <syscalls+0x200>
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	18c080e7          	jalr	396(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043ba:	00004517          	auipc	a0,0x4
    800043be:	2be50513          	addi	a0,a0,702 # 80008678 <syscalls+0x218>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	17c080e7          	jalr	380(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043ca:	00878713          	addi	a4,a5,8
    800043ce:	00271693          	slli	a3,a4,0x2
    800043d2:	0001d717          	auipc	a4,0x1d
    800043d6:	09e70713          	addi	a4,a4,158 # 80021470 <log>
    800043da:	9736                	add	a4,a4,a3
    800043dc:	44d4                	lw	a3,12(s1)
    800043de:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043e0:	faf608e3          	beq	a2,a5,80004390 <log_write+0x76>
  }
  release(&log.lock);
    800043e4:	0001d517          	auipc	a0,0x1d
    800043e8:	08c50513          	addi	a0,a0,140 # 80021470 <log>
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
}
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	64a2                	ld	s1,8(sp)
    800043fa:	6902                	ld	s2,0(sp)
    800043fc:	6105                	addi	sp,sp,32
    800043fe:	8082                	ret

0000000080004400 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004400:	1101                	addi	sp,sp,-32
    80004402:	ec06                	sd	ra,24(sp)
    80004404:	e822                	sd	s0,16(sp)
    80004406:	e426                	sd	s1,8(sp)
    80004408:	e04a                	sd	s2,0(sp)
    8000440a:	1000                	addi	s0,sp,32
    8000440c:	84aa                	mv	s1,a0
    8000440e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004410:	00004597          	auipc	a1,0x4
    80004414:	28858593          	addi	a1,a1,648 # 80008698 <syscalls+0x238>
    80004418:	0521                	addi	a0,a0,8
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	73a080e7          	jalr	1850(ra) # 80000b54 <initlock>
  lk->name = name;
    80004422:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004426:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000442a:	0204a423          	sw	zero,40(s1)
}
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6902                	ld	s2,0(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004448:	00850913          	addi	s2,a0,8
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004456:	409c                	lw	a5,0(s1)
    80004458:	cb89                	beqz	a5,8000446a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000445a:	85ca                	mv	a1,s2
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	dd8080e7          	jalr	-552(ra) # 80002236 <sleep>
  while (lk->locked) {
    80004466:	409c                	lw	a5,0(s1)
    80004468:	fbed                	bnez	a5,8000445a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000446a:	4785                	li	a5,1
    8000446c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	776080e7          	jalr	1910(ra) # 80001be4 <myproc>
    80004476:	591c                	lw	a5,48(a0)
    80004478:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
}
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6902                	ld	s2,0(sp)
    8000448c:	6105                	addi	sp,sp,32
    8000448e:	8082                	ret

0000000080004490 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004490:	1101                	addi	sp,sp,-32
    80004492:	ec06                	sd	ra,24(sp)
    80004494:	e822                	sd	s0,16(sp)
    80004496:	e426                	sd	s1,8(sp)
    80004498:	e04a                	sd	s2,0(sp)
    8000449a:	1000                	addi	s0,sp,32
    8000449c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000449e:	00850913          	addi	s2,a0,8
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044b0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffe097          	auipc	ra,0xffffe
    800044ba:	f0c080e7          	jalr	-244(ra) # 800023c2 <wakeup>
  release(&lk->lk);
    800044be:	854a                	mv	a0,s2
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	7d8080e7          	jalr	2008(ra) # 80000c98 <release>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret

00000000800044d4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044d4:	7179                	addi	sp,sp,-48
    800044d6:	f406                	sd	ra,40(sp)
    800044d8:	f022                	sd	s0,32(sp)
    800044da:	ec26                	sd	s1,24(sp)
    800044dc:	e84a                	sd	s2,16(sp)
    800044de:	e44e                	sd	s3,8(sp)
    800044e0:	1800                	addi	s0,sp,48
    800044e2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044e4:	00850913          	addi	s2,a0,8
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6fa080e7          	jalr	1786(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f2:	409c                	lw	a5,0(s1)
    800044f4:	ef99                	bnez	a5,80004512 <holdingsleep+0x3e>
    800044f6:	4481                	li	s1,0
  release(&lk->lk);
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>
  return r;
}
    80004502:	8526                	mv	a0,s1
    80004504:	70a2                	ld	ra,40(sp)
    80004506:	7402                	ld	s0,32(sp)
    80004508:	64e2                	ld	s1,24(sp)
    8000450a:	6942                	ld	s2,16(sp)
    8000450c:	69a2                	ld	s3,8(sp)
    8000450e:	6145                	addi	sp,sp,48
    80004510:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004512:	0284a983          	lw	s3,40(s1)
    80004516:	ffffd097          	auipc	ra,0xffffd
    8000451a:	6ce080e7          	jalr	1742(ra) # 80001be4 <myproc>
    8000451e:	5904                	lw	s1,48(a0)
    80004520:	413484b3          	sub	s1,s1,s3
    80004524:	0014b493          	seqz	s1,s1
    80004528:	bfc1                	j	800044f8 <holdingsleep+0x24>

000000008000452a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000452a:	1141                	addi	sp,sp,-16
    8000452c:	e406                	sd	ra,8(sp)
    8000452e:	e022                	sd	s0,0(sp)
    80004530:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004532:	00004597          	auipc	a1,0x4
    80004536:	17658593          	addi	a1,a1,374 # 800086a8 <syscalls+0x248>
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	07e50513          	addi	a0,a0,126 # 800215b8 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	612080e7          	jalr	1554(ra) # 80000b54 <initlock>
}
    8000454a:	60a2                	ld	ra,8(sp)
    8000454c:	6402                	ld	s0,0(sp)
    8000454e:	0141                	addi	sp,sp,16
    80004550:	8082                	ret

0000000080004552 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004552:	1101                	addi	sp,sp,-32
    80004554:	ec06                	sd	ra,24(sp)
    80004556:	e822                	sd	s0,16(sp)
    80004558:	e426                	sd	s1,8(sp)
    8000455a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000455c:	0001d517          	auipc	a0,0x1d
    80004560:	05c50513          	addi	a0,a0,92 # 800215b8 <ftable>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	680080e7          	jalr	1664(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000456c:	0001d497          	auipc	s1,0x1d
    80004570:	06448493          	addi	s1,s1,100 # 800215d0 <ftable+0x18>
    80004574:	0001e717          	auipc	a4,0x1e
    80004578:	ffc70713          	addi	a4,a4,-4 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    8000457c:	40dc                	lw	a5,4(s1)
    8000457e:	cf99                	beqz	a5,8000459c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004580:	02848493          	addi	s1,s1,40
    80004584:	fee49ce3          	bne	s1,a4,8000457c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004588:	0001d517          	auipc	a0,0x1d
    8000458c:	03050513          	addi	a0,a0,48 # 800215b8 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
  return 0;
    80004598:	4481                	li	s1,0
    8000459a:	a819                	j	800045b0 <filealloc+0x5e>
      f->ref = 1;
    8000459c:	4785                	li	a5,1
    8000459e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	01850513          	addi	a0,a0,24 # 800215b8 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	6f0080e7          	jalr	1776(ra) # 80000c98 <release>
}
    800045b0:	8526                	mv	a0,s1
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret

00000000800045bc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045bc:	1101                	addi	sp,sp,-32
    800045be:	ec06                	sd	ra,24(sp)
    800045c0:	e822                	sd	s0,16(sp)
    800045c2:	e426                	sd	s1,8(sp)
    800045c4:	1000                	addi	s0,sp,32
    800045c6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	ff050513          	addi	a0,a0,-16 # 800215b8 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045d8:	40dc                	lw	a5,4(s1)
    800045da:	02f05263          	blez	a5,800045fe <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045de:	2785                	addiw	a5,a5,1
    800045e0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045e2:	0001d517          	auipc	a0,0x1d
    800045e6:	fd650513          	addi	a0,a0,-42 # 800215b8 <ftable>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
  return f;
}
    800045f2:	8526                	mv	a0,s1
    800045f4:	60e2                	ld	ra,24(sp)
    800045f6:	6442                	ld	s0,16(sp)
    800045f8:	64a2                	ld	s1,8(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret
    panic("filedup");
    800045fe:	00004517          	auipc	a0,0x4
    80004602:	0b250513          	addi	a0,a0,178 # 800086b0 <syscalls+0x250>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>

000000008000460e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000460e:	7139                	addi	sp,sp,-64
    80004610:	fc06                	sd	ra,56(sp)
    80004612:	f822                	sd	s0,48(sp)
    80004614:	f426                	sd	s1,40(sp)
    80004616:	f04a                	sd	s2,32(sp)
    80004618:	ec4e                	sd	s3,24(sp)
    8000461a:	e852                	sd	s4,16(sp)
    8000461c:	e456                	sd	s5,8(sp)
    8000461e:	0080                	addi	s0,sp,64
    80004620:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	f9650513          	addi	a0,a0,-106 # 800215b8 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5ba080e7          	jalr	1466(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004632:	40dc                	lw	a5,4(s1)
    80004634:	06f05163          	blez	a5,80004696 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004638:	37fd                	addiw	a5,a5,-1
    8000463a:	0007871b          	sext.w	a4,a5
    8000463e:	c0dc                	sw	a5,4(s1)
    80004640:	06e04363          	bgtz	a4,800046a6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004644:	0004a903          	lw	s2,0(s1)
    80004648:	0094ca83          	lbu	s5,9(s1)
    8000464c:	0104ba03          	ld	s4,16(s1)
    80004650:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004654:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004658:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	f5c50513          	addi	a0,a0,-164 # 800215b8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	634080e7          	jalr	1588(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000466c:	4785                	li	a5,1
    8000466e:	04f90d63          	beq	s2,a5,800046c8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004672:	3979                	addiw	s2,s2,-2
    80004674:	4785                	li	a5,1
    80004676:	0527e063          	bltu	a5,s2,800046b6 <fileclose+0xa8>
    begin_op();
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	ac8080e7          	jalr	-1336(ra) # 80004142 <begin_op>
    iput(ff.ip);
    80004682:	854e                	mv	a0,s3
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	2a6080e7          	jalr	678(ra) # 8000392a <iput>
    end_op();
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	b36080e7          	jalr	-1226(ra) # 800041c2 <end_op>
    80004694:	a00d                	j	800046b6 <fileclose+0xa8>
    panic("fileclose");
    80004696:	00004517          	auipc	a0,0x4
    8000469a:	02250513          	addi	a0,a0,34 # 800086b8 <syscalls+0x258>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	f1250513          	addi	a0,a0,-238 # 800215b8 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
  }
}
    800046b6:	70e2                	ld	ra,56(sp)
    800046b8:	7442                	ld	s0,48(sp)
    800046ba:	74a2                	ld	s1,40(sp)
    800046bc:	7902                	ld	s2,32(sp)
    800046be:	69e2                	ld	s3,24(sp)
    800046c0:	6a42                	ld	s4,16(sp)
    800046c2:	6aa2                	ld	s5,8(sp)
    800046c4:	6121                	addi	sp,sp,64
    800046c6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c8:	85d6                	mv	a1,s5
    800046ca:	8552                	mv	a0,s4
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	34c080e7          	jalr	844(ra) # 80004a18 <pipeclose>
    800046d4:	b7cd                	j	800046b6 <fileclose+0xa8>

00000000800046d6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046d6:	715d                	addi	sp,sp,-80
    800046d8:	e486                	sd	ra,72(sp)
    800046da:	e0a2                	sd	s0,64(sp)
    800046dc:	fc26                	sd	s1,56(sp)
    800046de:	f84a                	sd	s2,48(sp)
    800046e0:	f44e                	sd	s3,40(sp)
    800046e2:	0880                	addi	s0,sp,80
    800046e4:	84aa                	mv	s1,a0
    800046e6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046e8:	ffffd097          	auipc	ra,0xffffd
    800046ec:	4fc080e7          	jalr	1276(ra) # 80001be4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046f0:	409c                	lw	a5,0(s1)
    800046f2:	37f9                	addiw	a5,a5,-2
    800046f4:	4705                	li	a4,1
    800046f6:	04f76763          	bltu	a4,a5,80004744 <filestat+0x6e>
    800046fa:	892a                	mv	s2,a0
    ilock(f->ip);
    800046fc:	6c88                	ld	a0,24(s1)
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	072080e7          	jalr	114(ra) # 80003770 <ilock>
    stati(f->ip, &st);
    80004706:	fb840593          	addi	a1,s0,-72
    8000470a:	6c88                	ld	a0,24(s1)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	2ee080e7          	jalr	750(ra) # 800039fa <stati>
    iunlock(f->ip);
    80004714:	6c88                	ld	a0,24(s1)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	11c080e7          	jalr	284(ra) # 80003832 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000471e:	46e1                	li	a3,24
    80004720:	fb840613          	addi	a2,s0,-72
    80004724:	85ce                	mv	a1,s3
    80004726:	05893503          	ld	a0,88(s2)
    8000472a:	ffffd097          	auipc	ra,0xffffd
    8000472e:	f48080e7          	jalr	-184(ra) # 80001672 <copyout>
    80004732:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004736:	60a6                	ld	ra,72(sp)
    80004738:	6406                	ld	s0,64(sp)
    8000473a:	74e2                	ld	s1,56(sp)
    8000473c:	7942                	ld	s2,48(sp)
    8000473e:	79a2                	ld	s3,40(sp)
    80004740:	6161                	addi	sp,sp,80
    80004742:	8082                	ret
  return -1;
    80004744:	557d                	li	a0,-1
    80004746:	bfc5                	j	80004736 <filestat+0x60>

0000000080004748 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004748:	7179                	addi	sp,sp,-48
    8000474a:	f406                	sd	ra,40(sp)
    8000474c:	f022                	sd	s0,32(sp)
    8000474e:	ec26                	sd	s1,24(sp)
    80004750:	e84a                	sd	s2,16(sp)
    80004752:	e44e                	sd	s3,8(sp)
    80004754:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004756:	00854783          	lbu	a5,8(a0)
    8000475a:	c3d5                	beqz	a5,800047fe <fileread+0xb6>
    8000475c:	84aa                	mv	s1,a0
    8000475e:	89ae                	mv	s3,a1
    80004760:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004762:	411c                	lw	a5,0(a0)
    80004764:	4705                	li	a4,1
    80004766:	04e78963          	beq	a5,a4,800047b8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000476a:	470d                	li	a4,3
    8000476c:	04e78d63          	beq	a5,a4,800047c6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004770:	4709                	li	a4,2
    80004772:	06e79e63          	bne	a5,a4,800047ee <fileread+0xa6>
    ilock(f->ip);
    80004776:	6d08                	ld	a0,24(a0)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	ff8080e7          	jalr	-8(ra) # 80003770 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004780:	874a                	mv	a4,s2
    80004782:	5094                	lw	a3,32(s1)
    80004784:	864e                	mv	a2,s3
    80004786:	4585                	li	a1,1
    80004788:	6c88                	ld	a0,24(s1)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	29a080e7          	jalr	666(ra) # 80003a24 <readi>
    80004792:	892a                	mv	s2,a0
    80004794:	00a05563          	blez	a0,8000479e <fileread+0x56>
      f->off += r;
    80004798:	509c                	lw	a5,32(s1)
    8000479a:	9fa9                	addw	a5,a5,a0
    8000479c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000479e:	6c88                	ld	a0,24(s1)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	092080e7          	jalr	146(ra) # 80003832 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047a8:	854a                	mv	a0,s2
    800047aa:	70a2                	ld	ra,40(sp)
    800047ac:	7402                	ld	s0,32(sp)
    800047ae:	64e2                	ld	s1,24(sp)
    800047b0:	6942                	ld	s2,16(sp)
    800047b2:	69a2                	ld	s3,8(sp)
    800047b4:	6145                	addi	sp,sp,48
    800047b6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047b8:	6908                	ld	a0,16(a0)
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	3c8080e7          	jalr	968(ra) # 80004b82 <piperead>
    800047c2:	892a                	mv	s2,a0
    800047c4:	b7d5                	j	800047a8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047c6:	02451783          	lh	a5,36(a0)
    800047ca:	03079693          	slli	a3,a5,0x30
    800047ce:	92c1                	srli	a3,a3,0x30
    800047d0:	4725                	li	a4,9
    800047d2:	02d76863          	bltu	a4,a3,80004802 <fileread+0xba>
    800047d6:	0792                	slli	a5,a5,0x4
    800047d8:	0001d717          	auipc	a4,0x1d
    800047dc:	d4070713          	addi	a4,a4,-704 # 80021518 <devsw>
    800047e0:	97ba                	add	a5,a5,a4
    800047e2:	639c                	ld	a5,0(a5)
    800047e4:	c38d                	beqz	a5,80004806 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047e6:	4505                	li	a0,1
    800047e8:	9782                	jalr	a5
    800047ea:	892a                	mv	s2,a0
    800047ec:	bf75                	j	800047a8 <fileread+0x60>
    panic("fileread");
    800047ee:	00004517          	auipc	a0,0x4
    800047f2:	eda50513          	addi	a0,a0,-294 # 800086c8 <syscalls+0x268>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>
    return -1;
    800047fe:	597d                	li	s2,-1
    80004800:	b765                	j	800047a8 <fileread+0x60>
      return -1;
    80004802:	597d                	li	s2,-1
    80004804:	b755                	j	800047a8 <fileread+0x60>
    80004806:	597d                	li	s2,-1
    80004808:	b745                	j	800047a8 <fileread+0x60>

000000008000480a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000480a:	715d                	addi	sp,sp,-80
    8000480c:	e486                	sd	ra,72(sp)
    8000480e:	e0a2                	sd	s0,64(sp)
    80004810:	fc26                	sd	s1,56(sp)
    80004812:	f84a                	sd	s2,48(sp)
    80004814:	f44e                	sd	s3,40(sp)
    80004816:	f052                	sd	s4,32(sp)
    80004818:	ec56                	sd	s5,24(sp)
    8000481a:	e85a                	sd	s6,16(sp)
    8000481c:	e45e                	sd	s7,8(sp)
    8000481e:	e062                	sd	s8,0(sp)
    80004820:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004822:	00954783          	lbu	a5,9(a0)
    80004826:	10078663          	beqz	a5,80004932 <filewrite+0x128>
    8000482a:	892a                	mv	s2,a0
    8000482c:	8aae                	mv	s5,a1
    8000482e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004830:	411c                	lw	a5,0(a0)
    80004832:	4705                	li	a4,1
    80004834:	02e78263          	beq	a5,a4,80004858 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004838:	470d                	li	a4,3
    8000483a:	02e78663          	beq	a5,a4,80004866 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000483e:	4709                	li	a4,2
    80004840:	0ee79163          	bne	a5,a4,80004922 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004844:	0ac05d63          	blez	a2,800048fe <filewrite+0xf4>
    int i = 0;
    80004848:	4981                	li	s3,0
    8000484a:	6b05                	lui	s6,0x1
    8000484c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004850:	6b85                	lui	s7,0x1
    80004852:	c00b8b9b          	addiw	s7,s7,-1024
    80004856:	a861                	j	800048ee <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004858:	6908                	ld	a0,16(a0)
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	22e080e7          	jalr	558(ra) # 80004a88 <pipewrite>
    80004862:	8a2a                	mv	s4,a0
    80004864:	a045                	j	80004904 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004866:	02451783          	lh	a5,36(a0)
    8000486a:	03079693          	slli	a3,a5,0x30
    8000486e:	92c1                	srli	a3,a3,0x30
    80004870:	4725                	li	a4,9
    80004872:	0cd76263          	bltu	a4,a3,80004936 <filewrite+0x12c>
    80004876:	0792                	slli	a5,a5,0x4
    80004878:	0001d717          	auipc	a4,0x1d
    8000487c:	ca070713          	addi	a4,a4,-864 # 80021518 <devsw>
    80004880:	97ba                	add	a5,a5,a4
    80004882:	679c                	ld	a5,8(a5)
    80004884:	cbdd                	beqz	a5,8000493a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004886:	4505                	li	a0,1
    80004888:	9782                	jalr	a5
    8000488a:	8a2a                	mv	s4,a0
    8000488c:	a8a5                	j	80004904 <filewrite+0xfa>
    8000488e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004892:	00000097          	auipc	ra,0x0
    80004896:	8b0080e7          	jalr	-1872(ra) # 80004142 <begin_op>
      ilock(f->ip);
    8000489a:	01893503          	ld	a0,24(s2)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	ed2080e7          	jalr	-302(ra) # 80003770 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048a6:	8762                	mv	a4,s8
    800048a8:	02092683          	lw	a3,32(s2)
    800048ac:	01598633          	add	a2,s3,s5
    800048b0:	4585                	li	a1,1
    800048b2:	01893503          	ld	a0,24(s2)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	266080e7          	jalr	614(ra) # 80003b1c <writei>
    800048be:	84aa                	mv	s1,a0
    800048c0:	00a05763          	blez	a0,800048ce <filewrite+0xc4>
        f->off += r;
    800048c4:	02092783          	lw	a5,32(s2)
    800048c8:	9fa9                	addw	a5,a5,a0
    800048ca:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048ce:	01893503          	ld	a0,24(s2)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	f60080e7          	jalr	-160(ra) # 80003832 <iunlock>
      end_op();
    800048da:	00000097          	auipc	ra,0x0
    800048de:	8e8080e7          	jalr	-1816(ra) # 800041c2 <end_op>

      if(r != n1){
    800048e2:	009c1f63          	bne	s8,s1,80004900 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048e6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048ea:	0149db63          	bge	s3,s4,80004900 <filewrite+0xf6>
      int n1 = n - i;
    800048ee:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048f2:	84be                	mv	s1,a5
    800048f4:	2781                	sext.w	a5,a5
    800048f6:	f8fb5ce3          	bge	s6,a5,8000488e <filewrite+0x84>
    800048fa:	84de                	mv	s1,s7
    800048fc:	bf49                	j	8000488e <filewrite+0x84>
    int i = 0;
    800048fe:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004900:	013a1f63          	bne	s4,s3,8000491e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004904:	8552                	mv	a0,s4
    80004906:	60a6                	ld	ra,72(sp)
    80004908:	6406                	ld	s0,64(sp)
    8000490a:	74e2                	ld	s1,56(sp)
    8000490c:	7942                	ld	s2,48(sp)
    8000490e:	79a2                	ld	s3,40(sp)
    80004910:	7a02                	ld	s4,32(sp)
    80004912:	6ae2                	ld	s5,24(sp)
    80004914:	6b42                	ld	s6,16(sp)
    80004916:	6ba2                	ld	s7,8(sp)
    80004918:	6c02                	ld	s8,0(sp)
    8000491a:	6161                	addi	sp,sp,80
    8000491c:	8082                	ret
    ret = (i == n ? n : -1);
    8000491e:	5a7d                	li	s4,-1
    80004920:	b7d5                	j	80004904 <filewrite+0xfa>
    panic("filewrite");
    80004922:	00004517          	auipc	a0,0x4
    80004926:	db650513          	addi	a0,a0,-586 # 800086d8 <syscalls+0x278>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>
    return -1;
    80004932:	5a7d                	li	s4,-1
    80004934:	bfc1                	j	80004904 <filewrite+0xfa>
      return -1;
    80004936:	5a7d                	li	s4,-1
    80004938:	b7f1                	j	80004904 <filewrite+0xfa>
    8000493a:	5a7d                	li	s4,-1
    8000493c:	b7e1                	j	80004904 <filewrite+0xfa>

000000008000493e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000493e:	7179                	addi	sp,sp,-48
    80004940:	f406                	sd	ra,40(sp)
    80004942:	f022                	sd	s0,32(sp)
    80004944:	ec26                	sd	s1,24(sp)
    80004946:	e84a                	sd	s2,16(sp)
    80004948:	e44e                	sd	s3,8(sp)
    8000494a:	e052                	sd	s4,0(sp)
    8000494c:	1800                	addi	s0,sp,48
    8000494e:	84aa                	mv	s1,a0
    80004950:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004952:	0005b023          	sd	zero,0(a1)
    80004956:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	bf8080e7          	jalr	-1032(ra) # 80004552 <filealloc>
    80004962:	e088                	sd	a0,0(s1)
    80004964:	c551                	beqz	a0,800049f0 <pipealloc+0xb2>
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	bec080e7          	jalr	-1044(ra) # 80004552 <filealloc>
    8000496e:	00aa3023          	sd	a0,0(s4)
    80004972:	c92d                	beqz	a0,800049e4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	180080e7          	jalr	384(ra) # 80000af4 <kalloc>
    8000497c:	892a                	mv	s2,a0
    8000497e:	c125                	beqz	a0,800049de <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004980:	4985                	li	s3,1
    80004982:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004986:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000498a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000498e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004992:	00004597          	auipc	a1,0x4
    80004996:	d5658593          	addi	a1,a1,-682 # 800086e8 <syscalls+0x288>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	1ba080e7          	jalr	442(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049a2:	609c                	ld	a5,0(s1)
    800049a4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a8:	609c                	ld	a5,0(s1)
    800049aa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ae:	609c                	ld	a5,0(s1)
    800049b0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049b4:	609c                	ld	a5,0(s1)
    800049b6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049ba:	000a3783          	ld	a5,0(s4)
    800049be:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049c2:	000a3783          	ld	a5,0(s4)
    800049c6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ca:	000a3783          	ld	a5,0(s4)
    800049ce:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049d2:	000a3783          	ld	a5,0(s4)
    800049d6:	0127b823          	sd	s2,16(a5)
  return 0;
    800049da:	4501                	li	a0,0
    800049dc:	a025                	j	80004a04 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049de:	6088                	ld	a0,0(s1)
    800049e0:	e501                	bnez	a0,800049e8 <pipealloc+0xaa>
    800049e2:	a039                	j	800049f0 <pipealloc+0xb2>
    800049e4:	6088                	ld	a0,0(s1)
    800049e6:	c51d                	beqz	a0,80004a14 <pipealloc+0xd6>
    fileclose(*f0);
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	c26080e7          	jalr	-986(ra) # 8000460e <fileclose>
  if(*f1)
    800049f0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049f4:	557d                	li	a0,-1
  if(*f1)
    800049f6:	c799                	beqz	a5,80004a04 <pipealloc+0xc6>
    fileclose(*f1);
    800049f8:	853e                	mv	a0,a5
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	c14080e7          	jalr	-1004(ra) # 8000460e <fileclose>
  return -1;
    80004a02:	557d                	li	a0,-1
}
    80004a04:	70a2                	ld	ra,40(sp)
    80004a06:	7402                	ld	s0,32(sp)
    80004a08:	64e2                	ld	s1,24(sp)
    80004a0a:	6942                	ld	s2,16(sp)
    80004a0c:	69a2                	ld	s3,8(sp)
    80004a0e:	6a02                	ld	s4,0(sp)
    80004a10:	6145                	addi	sp,sp,48
    80004a12:	8082                	ret
  return -1;
    80004a14:	557d                	li	a0,-1
    80004a16:	b7fd                	j	80004a04 <pipealloc+0xc6>

0000000080004a18 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a18:	1101                	addi	sp,sp,-32
    80004a1a:	ec06                	sd	ra,24(sp)
    80004a1c:	e822                	sd	s0,16(sp)
    80004a1e:	e426                	sd	s1,8(sp)
    80004a20:	e04a                	sd	s2,0(sp)
    80004a22:	1000                	addi	s0,sp,32
    80004a24:	84aa                	mv	s1,a0
    80004a26:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
  if(writable){
    80004a30:	02090d63          	beqz	s2,80004a6a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a34:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a38:	21848513          	addi	a0,s1,536
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	986080e7          	jalr	-1658(ra) # 800023c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a44:	2204b783          	ld	a5,544(s1)
    80004a48:	eb95                	bnez	a5,80004a7c <pipeclose+0x64>
    release(&pi->lock);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	fa2080e7          	jalr	-94(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a5e:	60e2                	ld	ra,24(sp)
    80004a60:	6442                	ld	s0,16(sp)
    80004a62:	64a2                	ld	s1,8(sp)
    80004a64:	6902                	ld	s2,0(sp)
    80004a66:	6105                	addi	sp,sp,32
    80004a68:	8082                	ret
    pi->readopen = 0;
    80004a6a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a6e:	21c48513          	addi	a0,s1,540
    80004a72:	ffffe097          	auipc	ra,0xffffe
    80004a76:	950080e7          	jalr	-1712(ra) # 800023c2 <wakeup>
    80004a7a:	b7e9                	j	80004a44 <pipeclose+0x2c>
    release(&pi->lock);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
}
    80004a86:	bfe1                	j	80004a5e <pipeclose+0x46>

0000000080004a88 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a88:	7159                	addi	sp,sp,-112
    80004a8a:	f486                	sd	ra,104(sp)
    80004a8c:	f0a2                	sd	s0,96(sp)
    80004a8e:	eca6                	sd	s1,88(sp)
    80004a90:	e8ca                	sd	s2,80(sp)
    80004a92:	e4ce                	sd	s3,72(sp)
    80004a94:	e0d2                	sd	s4,64(sp)
    80004a96:	fc56                	sd	s5,56(sp)
    80004a98:	f85a                	sd	s6,48(sp)
    80004a9a:	f45e                	sd	s7,40(sp)
    80004a9c:	f062                	sd	s8,32(sp)
    80004a9e:	ec66                	sd	s9,24(sp)
    80004aa0:	1880                	addi	s0,sp,112
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	8aae                	mv	s5,a1
    80004aa6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	13c080e7          	jalr	316(ra) # 80001be4 <myproc>
    80004ab0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	130080e7          	jalr	304(ra) # 80000be4 <acquire>
  while(i < n){
    80004abc:	0d405163          	blez	s4,80004b7e <pipewrite+0xf6>
    80004ac0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ac2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ac4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ac6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aca:	21c48c13          	addi	s8,s1,540
    80004ace:	a08d                	j	80004b30 <pipewrite+0xa8>
      release(&pi->lock);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1c6080e7          	jalr	454(ra) # 80000c98 <release>
      return -1;
    80004ada:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004adc:	854a                	mv	a0,s2
    80004ade:	70a6                	ld	ra,104(sp)
    80004ae0:	7406                	ld	s0,96(sp)
    80004ae2:	64e6                	ld	s1,88(sp)
    80004ae4:	6946                	ld	s2,80(sp)
    80004ae6:	69a6                	ld	s3,72(sp)
    80004ae8:	6a06                	ld	s4,64(sp)
    80004aea:	7ae2                	ld	s5,56(sp)
    80004aec:	7b42                	ld	s6,48(sp)
    80004aee:	7ba2                	ld	s7,40(sp)
    80004af0:	7c02                	ld	s8,32(sp)
    80004af2:	6ce2                	ld	s9,24(sp)
    80004af4:	6165                	addi	sp,sp,112
    80004af6:	8082                	ret
      wakeup(&pi->nread);
    80004af8:	8566                	mv	a0,s9
    80004afa:	ffffe097          	auipc	ra,0xffffe
    80004afe:	8c8080e7          	jalr	-1848(ra) # 800023c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b02:	85de                	mv	a1,s7
    80004b04:	8562                	mv	a0,s8
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	730080e7          	jalr	1840(ra) # 80002236 <sleep>
    80004b0e:	a839                	j	80004b2c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b10:	21c4a783          	lw	a5,540(s1)
    80004b14:	0017871b          	addiw	a4,a5,1
    80004b18:	20e4ae23          	sw	a4,540(s1)
    80004b1c:	1ff7f793          	andi	a5,a5,511
    80004b20:	97a6                	add	a5,a5,s1
    80004b22:	f9f44703          	lbu	a4,-97(s0)
    80004b26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b2a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b2c:	03495d63          	bge	s2,s4,80004b66 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b30:	2204a783          	lw	a5,544(s1)
    80004b34:	dfd1                	beqz	a5,80004ad0 <pipewrite+0x48>
    80004b36:	0289a783          	lw	a5,40(s3)
    80004b3a:	fbd9                	bnez	a5,80004ad0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b3c:	2184a783          	lw	a5,536(s1)
    80004b40:	21c4a703          	lw	a4,540(s1)
    80004b44:	2007879b          	addiw	a5,a5,512
    80004b48:	faf708e3          	beq	a4,a5,80004af8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b4c:	4685                	li	a3,1
    80004b4e:	01590633          	add	a2,s2,s5
    80004b52:	f9f40593          	addi	a1,s0,-97
    80004b56:	0589b503          	ld	a0,88(s3)
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	ba4080e7          	jalr	-1116(ra) # 800016fe <copyin>
    80004b62:	fb6517e3          	bne	a0,s6,80004b10 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b66:	21848513          	addi	a0,s1,536
    80004b6a:	ffffe097          	auipc	ra,0xffffe
    80004b6e:	858080e7          	jalr	-1960(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004b72:	8526                	mv	a0,s1
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
  return i;
    80004b7c:	b785                	j	80004adc <pipewrite+0x54>
  int i = 0;
    80004b7e:	4901                	li	s2,0
    80004b80:	b7dd                	j	80004b66 <pipewrite+0xde>

0000000080004b82 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b82:	715d                	addi	sp,sp,-80
    80004b84:	e486                	sd	ra,72(sp)
    80004b86:	e0a2                	sd	s0,64(sp)
    80004b88:	fc26                	sd	s1,56(sp)
    80004b8a:	f84a                	sd	s2,48(sp)
    80004b8c:	f44e                	sd	s3,40(sp)
    80004b8e:	f052                	sd	s4,32(sp)
    80004b90:	ec56                	sd	s5,24(sp)
    80004b92:	e85a                	sd	s6,16(sp)
    80004b94:	0880                	addi	s0,sp,80
    80004b96:	84aa                	mv	s1,a0
    80004b98:	892e                	mv	s2,a1
    80004b9a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	048080e7          	jalr	72(ra) # 80001be4 <myproc>
    80004ba4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ba6:	8b26                	mv	s6,s1
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	03a080e7          	jalr	58(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb2:	2184a703          	lw	a4,536(s1)
    80004bb6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bbe:	02f71463          	bne	a4,a5,80004be6 <piperead+0x64>
    80004bc2:	2244a783          	lw	a5,548(s1)
    80004bc6:	c385                	beqz	a5,80004be6 <piperead+0x64>
    if(pr->killed){
    80004bc8:	028a2783          	lw	a5,40(s4)
    80004bcc:	ebc1                	bnez	a5,80004c5c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bce:	85da                	mv	a1,s6
    80004bd0:	854e                	mv	a0,s3
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	664080e7          	jalr	1636(ra) # 80002236 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bda:	2184a703          	lw	a4,536(s1)
    80004bde:	21c4a783          	lw	a5,540(s1)
    80004be2:	fef700e3          	beq	a4,a5,80004bc2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be6:	09505263          	blez	s5,80004c6a <piperead+0xe8>
    80004bea:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bec:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bee:	2184a783          	lw	a5,536(s1)
    80004bf2:	21c4a703          	lw	a4,540(s1)
    80004bf6:	02f70d63          	beq	a4,a5,80004c30 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bfa:	0017871b          	addiw	a4,a5,1
    80004bfe:	20e4ac23          	sw	a4,536(s1)
    80004c02:	1ff7f793          	andi	a5,a5,511
    80004c06:	97a6                	add	a5,a5,s1
    80004c08:	0187c783          	lbu	a5,24(a5)
    80004c0c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c10:	4685                	li	a3,1
    80004c12:	fbf40613          	addi	a2,s0,-65
    80004c16:	85ca                	mv	a1,s2
    80004c18:	058a3503          	ld	a0,88(s4)
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	a56080e7          	jalr	-1450(ra) # 80001672 <copyout>
    80004c24:	01650663          	beq	a0,s6,80004c30 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c28:	2985                	addiw	s3,s3,1
    80004c2a:	0905                	addi	s2,s2,1
    80004c2c:	fd3a91e3          	bne	s5,s3,80004bee <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c30:	21c48513          	addi	a0,s1,540
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	78e080e7          	jalr	1934(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	05a080e7          	jalr	90(ra) # 80000c98 <release>
  return i;
}
    80004c46:	854e                	mv	a0,s3
    80004c48:	60a6                	ld	ra,72(sp)
    80004c4a:	6406                	ld	s0,64(sp)
    80004c4c:	74e2                	ld	s1,56(sp)
    80004c4e:	7942                	ld	s2,48(sp)
    80004c50:	79a2                	ld	s3,40(sp)
    80004c52:	7a02                	ld	s4,32(sp)
    80004c54:	6ae2                	ld	s5,24(sp)
    80004c56:	6b42                	ld	s6,16(sp)
    80004c58:	6161                	addi	sp,sp,80
    80004c5a:	8082                	ret
      release(&pi->lock);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	03a080e7          	jalr	58(ra) # 80000c98 <release>
      return -1;
    80004c66:	59fd                	li	s3,-1
    80004c68:	bff9                	j	80004c46 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6a:	4981                	li	s3,0
    80004c6c:	b7d1                	j	80004c30 <piperead+0xae>

0000000080004c6e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c6e:	df010113          	addi	sp,sp,-528
    80004c72:	20113423          	sd	ra,520(sp)
    80004c76:	20813023          	sd	s0,512(sp)
    80004c7a:	ffa6                	sd	s1,504(sp)
    80004c7c:	fbca                	sd	s2,496(sp)
    80004c7e:	f7ce                	sd	s3,488(sp)
    80004c80:	f3d2                	sd	s4,480(sp)
    80004c82:	efd6                	sd	s5,472(sp)
    80004c84:	ebda                	sd	s6,464(sp)
    80004c86:	e7de                	sd	s7,456(sp)
    80004c88:	e3e2                	sd	s8,448(sp)
    80004c8a:	ff66                	sd	s9,440(sp)
    80004c8c:	fb6a                	sd	s10,432(sp)
    80004c8e:	f76e                	sd	s11,424(sp)
    80004c90:	0c00                	addi	s0,sp,528
    80004c92:	84aa                	mv	s1,a0
    80004c94:	dea43c23          	sd	a0,-520(s0)
    80004c98:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	f48080e7          	jalr	-184(ra) # 80001be4 <myproc>
    80004ca4:	892a                	mv	s2,a0

  begin_op();
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	49c080e7          	jalr	1180(ra) # 80004142 <begin_op>

  if((ip = namei(path)) == 0){
    80004cae:	8526                	mv	a0,s1
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	276080e7          	jalr	630(ra) # 80003f26 <namei>
    80004cb8:	c92d                	beqz	a0,80004d2a <exec+0xbc>
    80004cba:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	ab4080e7          	jalr	-1356(ra) # 80003770 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cc4:	04000713          	li	a4,64
    80004cc8:	4681                	li	a3,0
    80004cca:	e5040613          	addi	a2,s0,-432
    80004cce:	4581                	li	a1,0
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	d52080e7          	jalr	-686(ra) # 80003a24 <readi>
    80004cda:	04000793          	li	a5,64
    80004cde:	00f51a63          	bne	a0,a5,80004cf2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ce2:	e5042703          	lw	a4,-432(s0)
    80004ce6:	464c47b7          	lui	a5,0x464c4
    80004cea:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cee:	04f70463          	beq	a4,a5,80004d36 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	cde080e7          	jalr	-802(ra) # 800039d2 <iunlockput>
    end_op();
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	4c6080e7          	jalr	1222(ra) # 800041c2 <end_op>
  }
  return -1;
    80004d04:	557d                	li	a0,-1
}
    80004d06:	20813083          	ld	ra,520(sp)
    80004d0a:	20013403          	ld	s0,512(sp)
    80004d0e:	74fe                	ld	s1,504(sp)
    80004d10:	795e                	ld	s2,496(sp)
    80004d12:	79be                	ld	s3,488(sp)
    80004d14:	7a1e                	ld	s4,480(sp)
    80004d16:	6afe                	ld	s5,472(sp)
    80004d18:	6b5e                	ld	s6,464(sp)
    80004d1a:	6bbe                	ld	s7,456(sp)
    80004d1c:	6c1e                	ld	s8,448(sp)
    80004d1e:	7cfa                	ld	s9,440(sp)
    80004d20:	7d5a                	ld	s10,432(sp)
    80004d22:	7dba                	ld	s11,424(sp)
    80004d24:	21010113          	addi	sp,sp,528
    80004d28:	8082                	ret
    end_op();
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	498080e7          	jalr	1176(ra) # 800041c2 <end_op>
    return -1;
    80004d32:	557d                	li	a0,-1
    80004d34:	bfc9                	j	80004d06 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d36:	854a                	mv	a0,s2
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	f70080e7          	jalr	-144(ra) # 80001ca8 <proc_pagetable>
    80004d40:	8baa                	mv	s7,a0
    80004d42:	d945                	beqz	a0,80004cf2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d44:	e7042983          	lw	s3,-400(s0)
    80004d48:	e8845783          	lhu	a5,-376(s0)
    80004d4c:	c7ad                	beqz	a5,80004db6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d4e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d50:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d52:	6c85                	lui	s9,0x1
    80004d54:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d58:	def43823          	sd	a5,-528(s0)
    80004d5c:	a42d                	j	80004f86 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d5e:	00004517          	auipc	a0,0x4
    80004d62:	99250513          	addi	a0,a0,-1646 # 800086f0 <syscalls+0x290>
    80004d66:	ffffb097          	auipc	ra,0xffffb
    80004d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d6e:	8756                	mv	a4,s5
    80004d70:	012d86bb          	addw	a3,s11,s2
    80004d74:	4581                	li	a1,0
    80004d76:	8526                	mv	a0,s1
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	cac080e7          	jalr	-852(ra) # 80003a24 <readi>
    80004d80:	2501                	sext.w	a0,a0
    80004d82:	1aaa9963          	bne	s5,a0,80004f34 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d86:	6785                	lui	a5,0x1
    80004d88:	0127893b          	addw	s2,a5,s2
    80004d8c:	77fd                	lui	a5,0xfffff
    80004d8e:	01478a3b          	addw	s4,a5,s4
    80004d92:	1f897163          	bgeu	s2,s8,80004f74 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d96:	02091593          	slli	a1,s2,0x20
    80004d9a:	9181                	srli	a1,a1,0x20
    80004d9c:	95ea                	add	a1,a1,s10
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	2ce080e7          	jalr	718(ra) # 8000106e <walkaddr>
    80004da8:	862a                	mv	a2,a0
    if(pa == 0)
    80004daa:	d955                	beqz	a0,80004d5e <exec+0xf0>
      n = PGSIZE;
    80004dac:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dae:	fd9a70e3          	bgeu	s4,s9,80004d6e <exec+0x100>
      n = sz - i;
    80004db2:	8ad2                	mv	s5,s4
    80004db4:	bf6d                	j	80004d6e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db6:	4901                	li	s2,0
  iunlockput(ip);
    80004db8:	8526                	mv	a0,s1
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	c18080e7          	jalr	-1000(ra) # 800039d2 <iunlockput>
  end_op();
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	400080e7          	jalr	1024(ra) # 800041c2 <end_op>
  p = myproc();
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	e1a080e7          	jalr	-486(ra) # 80001be4 <myproc>
    80004dd2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dd4:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004dd8:	6785                	lui	a5,0x1
    80004dda:	17fd                	addi	a5,a5,-1
    80004ddc:	993e                	add	s2,s2,a5
    80004dde:	757d                	lui	a0,0xfffff
    80004de0:	00a977b3          	and	a5,s2,a0
    80004de4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004de8:	6609                	lui	a2,0x2
    80004dea:	963e                	add	a2,a2,a5
    80004dec:	85be                	mv	a1,a5
    80004dee:	855e                	mv	a0,s7
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	632080e7          	jalr	1586(ra) # 80001422 <uvmalloc>
    80004df8:	8b2a                	mv	s6,a0
  ip = 0;
    80004dfa:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dfc:	12050c63          	beqz	a0,80004f34 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e00:	75f9                	lui	a1,0xffffe
    80004e02:	95aa                	add	a1,a1,a0
    80004e04:	855e                	mv	a0,s7
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	83a080e7          	jalr	-1990(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e0e:	7c7d                	lui	s8,0xfffff
    80004e10:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e12:	e0043783          	ld	a5,-512(s0)
    80004e16:	6388                	ld	a0,0(a5)
    80004e18:	c535                	beqz	a0,80004e84 <exec+0x216>
    80004e1a:	e9040993          	addi	s3,s0,-368
    80004e1e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e22:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	040080e7          	jalr	64(ra) # 80000e64 <strlen>
    80004e2c:	2505                	addiw	a0,a0,1
    80004e2e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e32:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e36:	13896363          	bltu	s2,s8,80004f5c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e3a:	e0043d83          	ld	s11,-512(s0)
    80004e3e:	000dba03          	ld	s4,0(s11)
    80004e42:	8552                	mv	a0,s4
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	020080e7          	jalr	32(ra) # 80000e64 <strlen>
    80004e4c:	0015069b          	addiw	a3,a0,1
    80004e50:	8652                	mv	a2,s4
    80004e52:	85ca                	mv	a1,s2
    80004e54:	855e                	mv	a0,s7
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	81c080e7          	jalr	-2020(ra) # 80001672 <copyout>
    80004e5e:	10054363          	bltz	a0,80004f64 <exec+0x2f6>
    ustack[argc] = sp;
    80004e62:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e66:	0485                	addi	s1,s1,1
    80004e68:	008d8793          	addi	a5,s11,8
    80004e6c:	e0f43023          	sd	a5,-512(s0)
    80004e70:	008db503          	ld	a0,8(s11)
    80004e74:	c911                	beqz	a0,80004e88 <exec+0x21a>
    if(argc >= MAXARG)
    80004e76:	09a1                	addi	s3,s3,8
    80004e78:	fb3c96e3          	bne	s9,s3,80004e24 <exec+0x1b6>
  sz = sz1;
    80004e7c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e80:	4481                	li	s1,0
    80004e82:	a84d                	j	80004f34 <exec+0x2c6>
  sp = sz;
    80004e84:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e86:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e88:	00349793          	slli	a5,s1,0x3
    80004e8c:	f9040713          	addi	a4,s0,-112
    80004e90:	97ba                	add	a5,a5,a4
    80004e92:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e96:	00148693          	addi	a3,s1,1
    80004e9a:	068e                	slli	a3,a3,0x3
    80004e9c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ea0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ea4:	01897663          	bgeu	s2,s8,80004eb0 <exec+0x242>
  sz = sz1;
    80004ea8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eac:	4481                	li	s1,0
    80004eae:	a059                	j	80004f34 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eb0:	e9040613          	addi	a2,s0,-368
    80004eb4:	85ca                	mv	a1,s2
    80004eb6:	855e                	mv	a0,s7
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	7ba080e7          	jalr	1978(ra) # 80001672 <copyout>
    80004ec0:	0a054663          	bltz	a0,80004f6c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ec4:	060ab783          	ld	a5,96(s5)
    80004ec8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ecc:	df843783          	ld	a5,-520(s0)
    80004ed0:	0007c703          	lbu	a4,0(a5)
    80004ed4:	cf11                	beqz	a4,80004ef0 <exec+0x282>
    80004ed6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ed8:	02f00693          	li	a3,47
    80004edc:	a039                	j	80004eea <exec+0x27c>
      last = s+1;
    80004ede:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ee2:	0785                	addi	a5,a5,1
    80004ee4:	fff7c703          	lbu	a4,-1(a5)
    80004ee8:	c701                	beqz	a4,80004ef0 <exec+0x282>
    if(*s == '/')
    80004eea:	fed71ce3          	bne	a4,a3,80004ee2 <exec+0x274>
    80004eee:	bfc5                	j	80004ede <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ef0:	4641                	li	a2,16
    80004ef2:	df843583          	ld	a1,-520(s0)
    80004ef6:	160a8513          	addi	a0,s5,352
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	f38080e7          	jalr	-200(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f02:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80004f06:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80004f0a:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f0e:	060ab783          	ld	a5,96(s5)
    80004f12:	e6843703          	ld	a4,-408(s0)
    80004f16:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f18:	060ab783          	ld	a5,96(s5)
    80004f1c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f20:	85ea                	mv	a1,s10
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	e22080e7          	jalr	-478(ra) # 80001d44 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f2a:	0004851b          	sext.w	a0,s1
    80004f2e:	bbe1                	j	80004d06 <exec+0x98>
    80004f30:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f34:	e0843583          	ld	a1,-504(s0)
    80004f38:	855e                	mv	a0,s7
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	e0a080e7          	jalr	-502(ra) # 80001d44 <proc_freepagetable>
  if(ip){
    80004f42:	da0498e3          	bnez	s1,80004cf2 <exec+0x84>
  return -1;
    80004f46:	557d                	li	a0,-1
    80004f48:	bb7d                	j	80004d06 <exec+0x98>
    80004f4a:	e1243423          	sd	s2,-504(s0)
    80004f4e:	b7dd                	j	80004f34 <exec+0x2c6>
    80004f50:	e1243423          	sd	s2,-504(s0)
    80004f54:	b7c5                	j	80004f34 <exec+0x2c6>
    80004f56:	e1243423          	sd	s2,-504(s0)
    80004f5a:	bfe9                	j	80004f34 <exec+0x2c6>
  sz = sz1;
    80004f5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f60:	4481                	li	s1,0
    80004f62:	bfc9                	j	80004f34 <exec+0x2c6>
  sz = sz1;
    80004f64:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f68:	4481                	li	s1,0
    80004f6a:	b7e9                	j	80004f34 <exec+0x2c6>
  sz = sz1;
    80004f6c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f70:	4481                	li	s1,0
    80004f72:	b7c9                	j	80004f34 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f74:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f78:	2b05                	addiw	s6,s6,1
    80004f7a:	0389899b          	addiw	s3,s3,56
    80004f7e:	e8845783          	lhu	a5,-376(s0)
    80004f82:	e2fb5be3          	bge	s6,a5,80004db8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f86:	2981                	sext.w	s3,s3
    80004f88:	03800713          	li	a4,56
    80004f8c:	86ce                	mv	a3,s3
    80004f8e:	e1840613          	addi	a2,s0,-488
    80004f92:	4581                	li	a1,0
    80004f94:	8526                	mv	a0,s1
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	a8e080e7          	jalr	-1394(ra) # 80003a24 <readi>
    80004f9e:	03800793          	li	a5,56
    80004fa2:	f8f517e3          	bne	a0,a5,80004f30 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fa6:	e1842783          	lw	a5,-488(s0)
    80004faa:	4705                	li	a4,1
    80004fac:	fce796e3          	bne	a5,a4,80004f78 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fb0:	e4043603          	ld	a2,-448(s0)
    80004fb4:	e3843783          	ld	a5,-456(s0)
    80004fb8:	f8f669e3          	bltu	a2,a5,80004f4a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fbc:	e2843783          	ld	a5,-472(s0)
    80004fc0:	963e                	add	a2,a2,a5
    80004fc2:	f8f667e3          	bltu	a2,a5,80004f50 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fc6:	85ca                	mv	a1,s2
    80004fc8:	855e                	mv	a0,s7
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	458080e7          	jalr	1112(ra) # 80001422 <uvmalloc>
    80004fd2:	e0a43423          	sd	a0,-504(s0)
    80004fd6:	d141                	beqz	a0,80004f56 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004fd8:	e2843d03          	ld	s10,-472(s0)
    80004fdc:	df043783          	ld	a5,-528(s0)
    80004fe0:	00fd77b3          	and	a5,s10,a5
    80004fe4:	fba1                	bnez	a5,80004f34 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fe6:	e2042d83          	lw	s11,-480(s0)
    80004fea:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fee:	f80c03e3          	beqz	s8,80004f74 <exec+0x306>
    80004ff2:	8a62                	mv	s4,s8
    80004ff4:	4901                	li	s2,0
    80004ff6:	b345                	j	80004d96 <exec+0x128>

0000000080004ff8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ff8:	7179                	addi	sp,sp,-48
    80004ffa:	f406                	sd	ra,40(sp)
    80004ffc:	f022                	sd	s0,32(sp)
    80004ffe:	ec26                	sd	s1,24(sp)
    80005000:	e84a                	sd	s2,16(sp)
    80005002:	1800                	addi	s0,sp,48
    80005004:	892e                	mv	s2,a1
    80005006:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005008:	fdc40593          	addi	a1,s0,-36
    8000500c:	ffffe097          	auipc	ra,0xffffe
    80005010:	ba8080e7          	jalr	-1112(ra) # 80002bb4 <argint>
    80005014:	04054063          	bltz	a0,80005054 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005018:	fdc42703          	lw	a4,-36(s0)
    8000501c:	47bd                	li	a5,15
    8000501e:	02e7ed63          	bltu	a5,a4,80005058 <argfd+0x60>
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	bc2080e7          	jalr	-1086(ra) # 80001be4 <myproc>
    8000502a:	fdc42703          	lw	a4,-36(s0)
    8000502e:	01a70793          	addi	a5,a4,26
    80005032:	078e                	slli	a5,a5,0x3
    80005034:	953e                	add	a0,a0,a5
    80005036:	651c                	ld	a5,8(a0)
    80005038:	c395                	beqz	a5,8000505c <argfd+0x64>
    return -1;
  if(pfd)
    8000503a:	00090463          	beqz	s2,80005042 <argfd+0x4a>
    *pfd = fd;
    8000503e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005042:	4501                	li	a0,0
  if(pf)
    80005044:	c091                	beqz	s1,80005048 <argfd+0x50>
    *pf = f;
    80005046:	e09c                	sd	a5,0(s1)
}
    80005048:	70a2                	ld	ra,40(sp)
    8000504a:	7402                	ld	s0,32(sp)
    8000504c:	64e2                	ld	s1,24(sp)
    8000504e:	6942                	ld	s2,16(sp)
    80005050:	6145                	addi	sp,sp,48
    80005052:	8082                	ret
    return -1;
    80005054:	557d                	li	a0,-1
    80005056:	bfcd                	j	80005048 <argfd+0x50>
    return -1;
    80005058:	557d                	li	a0,-1
    8000505a:	b7fd                	j	80005048 <argfd+0x50>
    8000505c:	557d                	li	a0,-1
    8000505e:	b7ed                	j	80005048 <argfd+0x50>

0000000080005060 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005060:	1101                	addi	sp,sp,-32
    80005062:	ec06                	sd	ra,24(sp)
    80005064:	e822                	sd	s0,16(sp)
    80005066:	e426                	sd	s1,8(sp)
    80005068:	1000                	addi	s0,sp,32
    8000506a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	b78080e7          	jalr	-1160(ra) # 80001be4 <myproc>
    80005074:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005076:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    8000507a:	4501                	li	a0,0
    8000507c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000507e:	6398                	ld	a4,0(a5)
    80005080:	cb19                	beqz	a4,80005096 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005082:	2505                	addiw	a0,a0,1
    80005084:	07a1                	addi	a5,a5,8
    80005086:	fed51ce3          	bne	a0,a3,8000507e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000508a:	557d                	li	a0,-1
}
    8000508c:	60e2                	ld	ra,24(sp)
    8000508e:	6442                	ld	s0,16(sp)
    80005090:	64a2                	ld	s1,8(sp)
    80005092:	6105                	addi	sp,sp,32
    80005094:	8082                	ret
      p->ofile[fd] = f;
    80005096:	01a50793          	addi	a5,a0,26
    8000509a:	078e                	slli	a5,a5,0x3
    8000509c:	963e                	add	a2,a2,a5
    8000509e:	e604                	sd	s1,8(a2)
      return fd;
    800050a0:	b7f5                	j	8000508c <fdalloc+0x2c>

00000000800050a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050a2:	715d                	addi	sp,sp,-80
    800050a4:	e486                	sd	ra,72(sp)
    800050a6:	e0a2                	sd	s0,64(sp)
    800050a8:	fc26                	sd	s1,56(sp)
    800050aa:	f84a                	sd	s2,48(sp)
    800050ac:	f44e                	sd	s3,40(sp)
    800050ae:	f052                	sd	s4,32(sp)
    800050b0:	ec56                	sd	s5,24(sp)
    800050b2:	0880                	addi	s0,sp,80
    800050b4:	89ae                	mv	s3,a1
    800050b6:	8ab2                	mv	s5,a2
    800050b8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ba:	fb040593          	addi	a1,s0,-80
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	e86080e7          	jalr	-378(ra) # 80003f44 <nameiparent>
    800050c6:	892a                	mv	s2,a0
    800050c8:	12050f63          	beqz	a0,80005206 <create+0x164>
    return 0;

  ilock(dp);
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	6a4080e7          	jalr	1700(ra) # 80003770 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050d4:	4601                	li	a2,0
    800050d6:	fb040593          	addi	a1,s0,-80
    800050da:	854a                	mv	a0,s2
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	b78080e7          	jalr	-1160(ra) # 80003c54 <dirlookup>
    800050e4:	84aa                	mv	s1,a0
    800050e6:	c921                	beqz	a0,80005136 <create+0x94>
    iunlockput(dp);
    800050e8:	854a                	mv	a0,s2
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	8e8080e7          	jalr	-1816(ra) # 800039d2 <iunlockput>
    ilock(ip);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffe097          	auipc	ra,0xffffe
    800050f8:	67c080e7          	jalr	1660(ra) # 80003770 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050fc:	2981                	sext.w	s3,s3
    800050fe:	4789                	li	a5,2
    80005100:	02f99463          	bne	s3,a5,80005128 <create+0x86>
    80005104:	0444d783          	lhu	a5,68(s1)
    80005108:	37f9                	addiw	a5,a5,-2
    8000510a:	17c2                	slli	a5,a5,0x30
    8000510c:	93c1                	srli	a5,a5,0x30
    8000510e:	4705                	li	a4,1
    80005110:	00f76c63          	bltu	a4,a5,80005128 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005114:	8526                	mv	a0,s1
    80005116:	60a6                	ld	ra,72(sp)
    80005118:	6406                	ld	s0,64(sp)
    8000511a:	74e2                	ld	s1,56(sp)
    8000511c:	7942                	ld	s2,48(sp)
    8000511e:	79a2                	ld	s3,40(sp)
    80005120:	7a02                	ld	s4,32(sp)
    80005122:	6ae2                	ld	s5,24(sp)
    80005124:	6161                	addi	sp,sp,80
    80005126:	8082                	ret
    iunlockput(ip);
    80005128:	8526                	mv	a0,s1
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	8a8080e7          	jalr	-1880(ra) # 800039d2 <iunlockput>
    return 0;
    80005132:	4481                	li	s1,0
    80005134:	b7c5                	j	80005114 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005136:	85ce                	mv	a1,s3
    80005138:	00092503          	lw	a0,0(s2)
    8000513c:	ffffe097          	auipc	ra,0xffffe
    80005140:	49c080e7          	jalr	1180(ra) # 800035d8 <ialloc>
    80005144:	84aa                	mv	s1,a0
    80005146:	c529                	beqz	a0,80005190 <create+0xee>
  ilock(ip);
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	628080e7          	jalr	1576(ra) # 80003770 <ilock>
  ip->major = major;
    80005150:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005154:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005158:	4785                	li	a5,1
    8000515a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000515e:	8526                	mv	a0,s1
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	546080e7          	jalr	1350(ra) # 800036a6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005168:	2981                	sext.w	s3,s3
    8000516a:	4785                	li	a5,1
    8000516c:	02f98a63          	beq	s3,a5,800051a0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005170:	40d0                	lw	a2,4(s1)
    80005172:	fb040593          	addi	a1,s0,-80
    80005176:	854a                	mv	a0,s2
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	cec080e7          	jalr	-788(ra) # 80003e64 <dirlink>
    80005180:	06054b63          	bltz	a0,800051f6 <create+0x154>
  iunlockput(dp);
    80005184:	854a                	mv	a0,s2
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	84c080e7          	jalr	-1972(ra) # 800039d2 <iunlockput>
  return ip;
    8000518e:	b759                	j	80005114 <create+0x72>
    panic("create: ialloc");
    80005190:	00003517          	auipc	a0,0x3
    80005194:	58050513          	addi	a0,a0,1408 # 80008710 <syscalls+0x2b0>
    80005198:	ffffb097          	auipc	ra,0xffffb
    8000519c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051a0:	04a95783          	lhu	a5,74(s2)
    800051a4:	2785                	addiw	a5,a5,1
    800051a6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051aa:	854a                	mv	a0,s2
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	4fa080e7          	jalr	1274(ra) # 800036a6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051b4:	40d0                	lw	a2,4(s1)
    800051b6:	00003597          	auipc	a1,0x3
    800051ba:	56a58593          	addi	a1,a1,1386 # 80008720 <syscalls+0x2c0>
    800051be:	8526                	mv	a0,s1
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	ca4080e7          	jalr	-860(ra) # 80003e64 <dirlink>
    800051c8:	00054f63          	bltz	a0,800051e6 <create+0x144>
    800051cc:	00492603          	lw	a2,4(s2)
    800051d0:	00003597          	auipc	a1,0x3
    800051d4:	55858593          	addi	a1,a1,1368 # 80008728 <syscalls+0x2c8>
    800051d8:	8526                	mv	a0,s1
    800051da:	fffff097          	auipc	ra,0xfffff
    800051de:	c8a080e7          	jalr	-886(ra) # 80003e64 <dirlink>
    800051e2:	f80557e3          	bgez	a0,80005170 <create+0xce>
      panic("create dots");
    800051e6:	00003517          	auipc	a0,0x3
    800051ea:	54a50513          	addi	a0,a0,1354 # 80008730 <syscalls+0x2d0>
    800051ee:	ffffb097          	auipc	ra,0xffffb
    800051f2:	350080e7          	jalr	848(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051f6:	00003517          	auipc	a0,0x3
    800051fa:	54a50513          	addi	a0,a0,1354 # 80008740 <syscalls+0x2e0>
    800051fe:	ffffb097          	auipc	ra,0xffffb
    80005202:	340080e7          	jalr	832(ra) # 8000053e <panic>
    return 0;
    80005206:	84aa                	mv	s1,a0
    80005208:	b731                	j	80005114 <create+0x72>

000000008000520a <sys_dup>:
{
    8000520a:	7179                	addi	sp,sp,-48
    8000520c:	f406                	sd	ra,40(sp)
    8000520e:	f022                	sd	s0,32(sp)
    80005210:	ec26                	sd	s1,24(sp)
    80005212:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005214:	fd840613          	addi	a2,s0,-40
    80005218:	4581                	li	a1,0
    8000521a:	4501                	li	a0,0
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	ddc080e7          	jalr	-548(ra) # 80004ff8 <argfd>
    return -1;
    80005224:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005226:	02054363          	bltz	a0,8000524c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000522a:	fd843503          	ld	a0,-40(s0)
    8000522e:	00000097          	auipc	ra,0x0
    80005232:	e32080e7          	jalr	-462(ra) # 80005060 <fdalloc>
    80005236:	84aa                	mv	s1,a0
    return -1;
    80005238:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000523a:	00054963          	bltz	a0,8000524c <sys_dup+0x42>
  filedup(f);
    8000523e:	fd843503          	ld	a0,-40(s0)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	37a080e7          	jalr	890(ra) # 800045bc <filedup>
  return fd;
    8000524a:	87a6                	mv	a5,s1
}
    8000524c:	853e                	mv	a0,a5
    8000524e:	70a2                	ld	ra,40(sp)
    80005250:	7402                	ld	s0,32(sp)
    80005252:	64e2                	ld	s1,24(sp)
    80005254:	6145                	addi	sp,sp,48
    80005256:	8082                	ret

0000000080005258 <sys_read>:
{
    80005258:	7179                	addi	sp,sp,-48
    8000525a:	f406                	sd	ra,40(sp)
    8000525c:	f022                	sd	s0,32(sp)
    8000525e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005260:	fe840613          	addi	a2,s0,-24
    80005264:	4581                	li	a1,0
    80005266:	4501                	li	a0,0
    80005268:	00000097          	auipc	ra,0x0
    8000526c:	d90080e7          	jalr	-624(ra) # 80004ff8 <argfd>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005272:	04054163          	bltz	a0,800052b4 <sys_read+0x5c>
    80005276:	fe440593          	addi	a1,s0,-28
    8000527a:	4509                	li	a0,2
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	938080e7          	jalr	-1736(ra) # 80002bb4 <argint>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005286:	02054763          	bltz	a0,800052b4 <sys_read+0x5c>
    8000528a:	fd840593          	addi	a1,s0,-40
    8000528e:	4505                	li	a0,1
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	946080e7          	jalr	-1722(ra) # 80002bd6 <argaddr>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529a:	00054d63          	bltz	a0,800052b4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000529e:	fe442603          	lw	a2,-28(s0)
    800052a2:	fd843583          	ld	a1,-40(s0)
    800052a6:	fe843503          	ld	a0,-24(s0)
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	49e080e7          	jalr	1182(ra) # 80004748 <fileread>
    800052b2:	87aa                	mv	a5,a0
}
    800052b4:	853e                	mv	a0,a5
    800052b6:	70a2                	ld	ra,40(sp)
    800052b8:	7402                	ld	s0,32(sp)
    800052ba:	6145                	addi	sp,sp,48
    800052bc:	8082                	ret

00000000800052be <sys_write>:
{
    800052be:	7179                	addi	sp,sp,-48
    800052c0:	f406                	sd	ra,40(sp)
    800052c2:	f022                	sd	s0,32(sp)
    800052c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c6:	fe840613          	addi	a2,s0,-24
    800052ca:	4581                	li	a1,0
    800052cc:	4501                	li	a0,0
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	d2a080e7          	jalr	-726(ra) # 80004ff8 <argfd>
    return -1;
    800052d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d8:	04054163          	bltz	a0,8000531a <sys_write+0x5c>
    800052dc:	fe440593          	addi	a1,s0,-28
    800052e0:	4509                	li	a0,2
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	8d2080e7          	jalr	-1838(ra) # 80002bb4 <argint>
    return -1;
    800052ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ec:	02054763          	bltz	a0,8000531a <sys_write+0x5c>
    800052f0:	fd840593          	addi	a1,s0,-40
    800052f4:	4505                	li	a0,1
    800052f6:	ffffe097          	auipc	ra,0xffffe
    800052fa:	8e0080e7          	jalr	-1824(ra) # 80002bd6 <argaddr>
    return -1;
    800052fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005300:	00054d63          	bltz	a0,8000531a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005304:	fe442603          	lw	a2,-28(s0)
    80005308:	fd843583          	ld	a1,-40(s0)
    8000530c:	fe843503          	ld	a0,-24(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	4fa080e7          	jalr	1274(ra) # 8000480a <filewrite>
    80005318:	87aa                	mv	a5,a0
}
    8000531a:	853e                	mv	a0,a5
    8000531c:	70a2                	ld	ra,40(sp)
    8000531e:	7402                	ld	s0,32(sp)
    80005320:	6145                	addi	sp,sp,48
    80005322:	8082                	ret

0000000080005324 <sys_close>:
{
    80005324:	1101                	addi	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000532c:	fe040613          	addi	a2,s0,-32
    80005330:	fec40593          	addi	a1,s0,-20
    80005334:	4501                	li	a0,0
    80005336:	00000097          	auipc	ra,0x0
    8000533a:	cc2080e7          	jalr	-830(ra) # 80004ff8 <argfd>
    return -1;
    8000533e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005340:	02054463          	bltz	a0,80005368 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	8a0080e7          	jalr	-1888(ra) # 80001be4 <myproc>
    8000534c:	fec42783          	lw	a5,-20(s0)
    80005350:	07e9                	addi	a5,a5,26
    80005352:	078e                	slli	a5,a5,0x3
    80005354:	97aa                	add	a5,a5,a0
    80005356:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000535a:	fe043503          	ld	a0,-32(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	2b0080e7          	jalr	688(ra) # 8000460e <fileclose>
  return 0;
    80005366:	4781                	li	a5,0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	60e2                	ld	ra,24(sp)
    8000536c:	6442                	ld	s0,16(sp)
    8000536e:	6105                	addi	sp,sp,32
    80005370:	8082                	ret

0000000080005372 <sys_fstat>:
{
    80005372:	1101                	addi	sp,sp,-32
    80005374:	ec06                	sd	ra,24(sp)
    80005376:	e822                	sd	s0,16(sp)
    80005378:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000537a:	fe840613          	addi	a2,s0,-24
    8000537e:	4581                	li	a1,0
    80005380:	4501                	li	a0,0
    80005382:	00000097          	auipc	ra,0x0
    80005386:	c76080e7          	jalr	-906(ra) # 80004ff8 <argfd>
    return -1;
    8000538a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000538c:	02054563          	bltz	a0,800053b6 <sys_fstat+0x44>
    80005390:	fe040593          	addi	a1,s0,-32
    80005394:	4505                	li	a0,1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	840080e7          	jalr	-1984(ra) # 80002bd6 <argaddr>
    return -1;
    8000539e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a0:	00054b63          	bltz	a0,800053b6 <sys_fstat+0x44>
  return filestat(f, st);
    800053a4:	fe043583          	ld	a1,-32(s0)
    800053a8:	fe843503          	ld	a0,-24(s0)
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	32a080e7          	jalr	810(ra) # 800046d6 <filestat>
    800053b4:	87aa                	mv	a5,a0
}
    800053b6:	853e                	mv	a0,a5
    800053b8:	60e2                	ld	ra,24(sp)
    800053ba:	6442                	ld	s0,16(sp)
    800053bc:	6105                	addi	sp,sp,32
    800053be:	8082                	ret

00000000800053c0 <sys_link>:
{
    800053c0:	7169                	addi	sp,sp,-304
    800053c2:	f606                	sd	ra,296(sp)
    800053c4:	f222                	sd	s0,288(sp)
    800053c6:	ee26                	sd	s1,280(sp)
    800053c8:	ea4a                	sd	s2,272(sp)
    800053ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053cc:	08000613          	li	a2,128
    800053d0:	ed040593          	addi	a1,s0,-304
    800053d4:	4501                	li	a0,0
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	822080e7          	jalr	-2014(ra) # 80002bf8 <argstr>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e0:	10054e63          	bltz	a0,800054fc <sys_link+0x13c>
    800053e4:	08000613          	li	a2,128
    800053e8:	f5040593          	addi	a1,s0,-176
    800053ec:	4505                	li	a0,1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	80a080e7          	jalr	-2038(ra) # 80002bf8 <argstr>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f8:	10054263          	bltz	a0,800054fc <sys_link+0x13c>
  begin_op();
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	d46080e7          	jalr	-698(ra) # 80004142 <begin_op>
  if((ip = namei(old)) == 0){
    80005404:	ed040513          	addi	a0,s0,-304
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	b1e080e7          	jalr	-1250(ra) # 80003f26 <namei>
    80005410:	84aa                	mv	s1,a0
    80005412:	c551                	beqz	a0,8000549e <sys_link+0xde>
  ilock(ip);
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	35c080e7          	jalr	860(ra) # 80003770 <ilock>
  if(ip->type == T_DIR){
    8000541c:	04449703          	lh	a4,68(s1)
    80005420:	4785                	li	a5,1
    80005422:	08f70463          	beq	a4,a5,800054aa <sys_link+0xea>
  ip->nlink++;
    80005426:	04a4d783          	lhu	a5,74(s1)
    8000542a:	2785                	addiw	a5,a5,1
    8000542c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	274080e7          	jalr	628(ra) # 800036a6 <iupdate>
  iunlock(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	3f6080e7          	jalr	1014(ra) # 80003832 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005444:	fd040593          	addi	a1,s0,-48
    80005448:	f5040513          	addi	a0,s0,-176
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	af8080e7          	jalr	-1288(ra) # 80003f44 <nameiparent>
    80005454:	892a                	mv	s2,a0
    80005456:	c935                	beqz	a0,800054ca <sys_link+0x10a>
  ilock(dp);
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	318080e7          	jalr	792(ra) # 80003770 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005460:	00092703          	lw	a4,0(s2)
    80005464:	409c                	lw	a5,0(s1)
    80005466:	04f71d63          	bne	a4,a5,800054c0 <sys_link+0x100>
    8000546a:	40d0                	lw	a2,4(s1)
    8000546c:	fd040593          	addi	a1,s0,-48
    80005470:	854a                	mv	a0,s2
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	9f2080e7          	jalr	-1550(ra) # 80003e64 <dirlink>
    8000547a:	04054363          	bltz	a0,800054c0 <sys_link+0x100>
  iunlockput(dp);
    8000547e:	854a                	mv	a0,s2
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	552080e7          	jalr	1362(ra) # 800039d2 <iunlockput>
  iput(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	4a0080e7          	jalr	1184(ra) # 8000392a <iput>
  end_op();
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	d30080e7          	jalr	-720(ra) # 800041c2 <end_op>
  return 0;
    8000549a:	4781                	li	a5,0
    8000549c:	a085                	j	800054fc <sys_link+0x13c>
    end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	d24080e7          	jalr	-732(ra) # 800041c2 <end_op>
    return -1;
    800054a6:	57fd                	li	a5,-1
    800054a8:	a891                	j	800054fc <sys_link+0x13c>
    iunlockput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	526080e7          	jalr	1318(ra) # 800039d2 <iunlockput>
    end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	d0e080e7          	jalr	-754(ra) # 800041c2 <end_op>
    return -1;
    800054bc:	57fd                	li	a5,-1
    800054be:	a83d                	j	800054fc <sys_link+0x13c>
    iunlockput(dp);
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	510080e7          	jalr	1296(ra) # 800039d2 <iunlockput>
  ilock(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	2a4080e7          	jalr	676(ra) # 80003770 <ilock>
  ip->nlink--;
    800054d4:	04a4d783          	lhu	a5,74(s1)
    800054d8:	37fd                	addiw	a5,a5,-1
    800054da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	1c6080e7          	jalr	454(ra) # 800036a6 <iupdate>
  iunlockput(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	4e8080e7          	jalr	1256(ra) # 800039d2 <iunlockput>
  end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cd0080e7          	jalr	-816(ra) # 800041c2 <end_op>
  return -1;
    800054fa:	57fd                	li	a5,-1
}
    800054fc:	853e                	mv	a0,a5
    800054fe:	70b2                	ld	ra,296(sp)
    80005500:	7412                	ld	s0,288(sp)
    80005502:	64f2                	ld	s1,280(sp)
    80005504:	6952                	ld	s2,272(sp)
    80005506:	6155                	addi	sp,sp,304
    80005508:	8082                	ret

000000008000550a <sys_unlink>:
{
    8000550a:	7151                	addi	sp,sp,-240
    8000550c:	f586                	sd	ra,232(sp)
    8000550e:	f1a2                	sd	s0,224(sp)
    80005510:	eda6                	sd	s1,216(sp)
    80005512:	e9ca                	sd	s2,208(sp)
    80005514:	e5ce                	sd	s3,200(sp)
    80005516:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005518:	08000613          	li	a2,128
    8000551c:	f3040593          	addi	a1,s0,-208
    80005520:	4501                	li	a0,0
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	6d6080e7          	jalr	1750(ra) # 80002bf8 <argstr>
    8000552a:	18054163          	bltz	a0,800056ac <sys_unlink+0x1a2>
  begin_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	c14080e7          	jalr	-1004(ra) # 80004142 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005536:	fb040593          	addi	a1,s0,-80
    8000553a:	f3040513          	addi	a0,s0,-208
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	a06080e7          	jalr	-1530(ra) # 80003f44 <nameiparent>
    80005546:	84aa                	mv	s1,a0
    80005548:	c979                	beqz	a0,8000561e <sys_unlink+0x114>
  ilock(dp);
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	226080e7          	jalr	550(ra) # 80003770 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005552:	00003597          	auipc	a1,0x3
    80005556:	1ce58593          	addi	a1,a1,462 # 80008720 <syscalls+0x2c0>
    8000555a:	fb040513          	addi	a0,s0,-80
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	6dc080e7          	jalr	1756(ra) # 80003c3a <namecmp>
    80005566:	14050a63          	beqz	a0,800056ba <sys_unlink+0x1b0>
    8000556a:	00003597          	auipc	a1,0x3
    8000556e:	1be58593          	addi	a1,a1,446 # 80008728 <syscalls+0x2c8>
    80005572:	fb040513          	addi	a0,s0,-80
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	6c4080e7          	jalr	1732(ra) # 80003c3a <namecmp>
    8000557e:	12050e63          	beqz	a0,800056ba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005582:	f2c40613          	addi	a2,s0,-212
    80005586:	fb040593          	addi	a1,s0,-80
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	6c8080e7          	jalr	1736(ra) # 80003c54 <dirlookup>
    80005594:	892a                	mv	s2,a0
    80005596:	12050263          	beqz	a0,800056ba <sys_unlink+0x1b0>
  ilock(ip);
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	1d6080e7          	jalr	470(ra) # 80003770 <ilock>
  if(ip->nlink < 1)
    800055a2:	04a91783          	lh	a5,74(s2)
    800055a6:	08f05263          	blez	a5,8000562a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055aa:	04491703          	lh	a4,68(s2)
    800055ae:	4785                	li	a5,1
    800055b0:	08f70563          	beq	a4,a5,8000563a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055b4:	4641                	li	a2,16
    800055b6:	4581                	li	a1,0
    800055b8:	fc040513          	addi	a0,s0,-64
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	724080e7          	jalr	1828(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c4:	4741                	li	a4,16
    800055c6:	f2c42683          	lw	a3,-212(s0)
    800055ca:	fc040613          	addi	a2,s0,-64
    800055ce:	4581                	li	a1,0
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	54a080e7          	jalr	1354(ra) # 80003b1c <writei>
    800055da:	47c1                	li	a5,16
    800055dc:	0af51563          	bne	a0,a5,80005686 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055e0:	04491703          	lh	a4,68(s2)
    800055e4:	4785                	li	a5,1
    800055e6:	0af70863          	beq	a4,a5,80005696 <sys_unlink+0x18c>
  iunlockput(dp);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	3e6080e7          	jalr	998(ra) # 800039d2 <iunlockput>
  ip->nlink--;
    800055f4:	04a95783          	lhu	a5,74(s2)
    800055f8:	37fd                	addiw	a5,a5,-1
    800055fa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	0a6080e7          	jalr	166(ra) # 800036a6 <iupdate>
  iunlockput(ip);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	3c8080e7          	jalr	968(ra) # 800039d2 <iunlockput>
  end_op();
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	bb0080e7          	jalr	-1104(ra) # 800041c2 <end_op>
  return 0;
    8000561a:	4501                	li	a0,0
    8000561c:	a84d                	j	800056ce <sys_unlink+0x1c4>
    end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	ba4080e7          	jalr	-1116(ra) # 800041c2 <end_op>
    return -1;
    80005626:	557d                	li	a0,-1
    80005628:	a05d                	j	800056ce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000562a:	00003517          	auipc	a0,0x3
    8000562e:	12650513          	addi	a0,a0,294 # 80008750 <syscalls+0x2f0>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000563a:	04c92703          	lw	a4,76(s2)
    8000563e:	02000793          	li	a5,32
    80005642:	f6e7f9e3          	bgeu	a5,a4,800055b4 <sys_unlink+0xaa>
    80005646:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564a:	4741                	li	a4,16
    8000564c:	86ce                	mv	a3,s3
    8000564e:	f1840613          	addi	a2,s0,-232
    80005652:	4581                	li	a1,0
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	3ce080e7          	jalr	974(ra) # 80003a24 <readi>
    8000565e:	47c1                	li	a5,16
    80005660:	00f51b63          	bne	a0,a5,80005676 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005664:	f1845783          	lhu	a5,-232(s0)
    80005668:	e7a1                	bnez	a5,800056b0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000566a:	29c1                	addiw	s3,s3,16
    8000566c:	04c92783          	lw	a5,76(s2)
    80005670:	fcf9ede3          	bltu	s3,a5,8000564a <sys_unlink+0x140>
    80005674:	b781                	j	800055b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005676:	00003517          	auipc	a0,0x3
    8000567a:	0f250513          	addi	a0,a0,242 # 80008768 <syscalls+0x308>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005686:	00003517          	auipc	a0,0x3
    8000568a:	0fa50513          	addi	a0,a0,250 # 80008780 <syscalls+0x320>
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
    dp->nlink--;
    80005696:	04a4d783          	lhu	a5,74(s1)
    8000569a:	37fd                	addiw	a5,a5,-1
    8000569c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	004080e7          	jalr	4(ra) # 800036a6 <iupdate>
    800056aa:	b781                	j	800055ea <sys_unlink+0xe0>
    return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	a005                	j	800056ce <sys_unlink+0x1c4>
    iunlockput(ip);
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	320080e7          	jalr	800(ra) # 800039d2 <iunlockput>
  iunlockput(dp);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	316080e7          	jalr	790(ra) # 800039d2 <iunlockput>
  end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	afe080e7          	jalr	-1282(ra) # 800041c2 <end_op>
  return -1;
    800056cc:	557d                	li	a0,-1
}
    800056ce:	70ae                	ld	ra,232(sp)
    800056d0:	740e                	ld	s0,224(sp)
    800056d2:	64ee                	ld	s1,216(sp)
    800056d4:	694e                	ld	s2,208(sp)
    800056d6:	69ae                	ld	s3,200(sp)
    800056d8:	616d                	addi	sp,sp,240
    800056da:	8082                	ret

00000000800056dc <sys_open>:

uint64
sys_open(void)
{
    800056dc:	7131                	addi	sp,sp,-192
    800056de:	fd06                	sd	ra,184(sp)
    800056e0:	f922                	sd	s0,176(sp)
    800056e2:	f526                	sd	s1,168(sp)
    800056e4:	f14a                	sd	s2,160(sp)
    800056e6:	ed4e                	sd	s3,152(sp)
    800056e8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ea:	08000613          	li	a2,128
    800056ee:	f5040593          	addi	a1,s0,-176
    800056f2:	4501                	li	a0,0
    800056f4:	ffffd097          	auipc	ra,0xffffd
    800056f8:	504080e7          	jalr	1284(ra) # 80002bf8 <argstr>
    return -1;
    800056fc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056fe:	0c054163          	bltz	a0,800057c0 <sys_open+0xe4>
    80005702:	f4c40593          	addi	a1,s0,-180
    80005706:	4505                	li	a0,1
    80005708:	ffffd097          	auipc	ra,0xffffd
    8000570c:	4ac080e7          	jalr	1196(ra) # 80002bb4 <argint>
    80005710:	0a054863          	bltz	a0,800057c0 <sys_open+0xe4>

  begin_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	a2e080e7          	jalr	-1490(ra) # 80004142 <begin_op>

  if(omode & O_CREATE){
    8000571c:	f4c42783          	lw	a5,-180(s0)
    80005720:	2007f793          	andi	a5,a5,512
    80005724:	cbdd                	beqz	a5,800057da <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005726:	4681                	li	a3,0
    80005728:	4601                	li	a2,0
    8000572a:	4589                	li	a1,2
    8000572c:	f5040513          	addi	a0,s0,-176
    80005730:	00000097          	auipc	ra,0x0
    80005734:	972080e7          	jalr	-1678(ra) # 800050a2 <create>
    80005738:	892a                	mv	s2,a0
    if(ip == 0){
    8000573a:	c959                	beqz	a0,800057d0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000573c:	04491703          	lh	a4,68(s2)
    80005740:	478d                	li	a5,3
    80005742:	00f71763          	bne	a4,a5,80005750 <sys_open+0x74>
    80005746:	04695703          	lhu	a4,70(s2)
    8000574a:	47a5                	li	a5,9
    8000574c:	0ce7ec63          	bltu	a5,a4,80005824 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	e02080e7          	jalr	-510(ra) # 80004552 <filealloc>
    80005758:	89aa                	mv	s3,a0
    8000575a:	10050263          	beqz	a0,8000585e <sys_open+0x182>
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	902080e7          	jalr	-1790(ra) # 80005060 <fdalloc>
    80005766:	84aa                	mv	s1,a0
    80005768:	0e054663          	bltz	a0,80005854 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000576c:	04491703          	lh	a4,68(s2)
    80005770:	478d                	li	a5,3
    80005772:	0cf70463          	beq	a4,a5,8000583a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005776:	4789                	li	a5,2
    80005778:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000577c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005780:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005784:	f4c42783          	lw	a5,-180(s0)
    80005788:	0017c713          	xori	a4,a5,1
    8000578c:	8b05                	andi	a4,a4,1
    8000578e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005792:	0037f713          	andi	a4,a5,3
    80005796:	00e03733          	snez	a4,a4
    8000579a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000579e:	4007f793          	andi	a5,a5,1024
    800057a2:	c791                	beqz	a5,800057ae <sys_open+0xd2>
    800057a4:	04491703          	lh	a4,68(s2)
    800057a8:	4789                	li	a5,2
    800057aa:	08f70f63          	beq	a4,a5,80005848 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ae:	854a                	mv	a0,s2
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	082080e7          	jalr	130(ra) # 80003832 <iunlock>
  end_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	a0a080e7          	jalr	-1526(ra) # 800041c2 <end_op>

  return fd;
}
    800057c0:	8526                	mv	a0,s1
    800057c2:	70ea                	ld	ra,184(sp)
    800057c4:	744a                	ld	s0,176(sp)
    800057c6:	74aa                	ld	s1,168(sp)
    800057c8:	790a                	ld	s2,160(sp)
    800057ca:	69ea                	ld	s3,152(sp)
    800057cc:	6129                	addi	sp,sp,192
    800057ce:	8082                	ret
      end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	9f2080e7          	jalr	-1550(ra) # 800041c2 <end_op>
      return -1;
    800057d8:	b7e5                	j	800057c0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057da:	f5040513          	addi	a0,s0,-176
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	748080e7          	jalr	1864(ra) # 80003f26 <namei>
    800057e6:	892a                	mv	s2,a0
    800057e8:	c905                	beqz	a0,80005818 <sys_open+0x13c>
    ilock(ip);
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	f86080e7          	jalr	-122(ra) # 80003770 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057f2:	04491703          	lh	a4,68(s2)
    800057f6:	4785                	li	a5,1
    800057f8:	f4f712e3          	bne	a4,a5,8000573c <sys_open+0x60>
    800057fc:	f4c42783          	lw	a5,-180(s0)
    80005800:	dba1                	beqz	a5,80005750 <sys_open+0x74>
      iunlockput(ip);
    80005802:	854a                	mv	a0,s2
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	1ce080e7          	jalr	462(ra) # 800039d2 <iunlockput>
      end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	9b6080e7          	jalr	-1610(ra) # 800041c2 <end_op>
      return -1;
    80005814:	54fd                	li	s1,-1
    80005816:	b76d                	j	800057c0 <sys_open+0xe4>
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	9aa080e7          	jalr	-1622(ra) # 800041c2 <end_op>
      return -1;
    80005820:	54fd                	li	s1,-1
    80005822:	bf79                	j	800057c0 <sys_open+0xe4>
    iunlockput(ip);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	1ac080e7          	jalr	428(ra) # 800039d2 <iunlockput>
    end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	994080e7          	jalr	-1644(ra) # 800041c2 <end_op>
    return -1;
    80005836:	54fd                	li	s1,-1
    80005838:	b761                	j	800057c0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000583a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000583e:	04691783          	lh	a5,70(s2)
    80005842:	02f99223          	sh	a5,36(s3)
    80005846:	bf2d                	j	80005780 <sys_open+0xa4>
    itrunc(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	034080e7          	jalr	52(ra) # 8000387e <itrunc>
    80005852:	bfb1                	j	800057ae <sys_open+0xd2>
      fileclose(f);
    80005854:	854e                	mv	a0,s3
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	db8080e7          	jalr	-584(ra) # 8000460e <fileclose>
    iunlockput(ip);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	172080e7          	jalr	370(ra) # 800039d2 <iunlockput>
    end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	95a080e7          	jalr	-1702(ra) # 800041c2 <end_op>
    return -1;
    80005870:	54fd                	li	s1,-1
    80005872:	b7b9                	j	800057c0 <sys_open+0xe4>

0000000080005874 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005874:	7175                	addi	sp,sp,-144
    80005876:	e506                	sd	ra,136(sp)
    80005878:	e122                	sd	s0,128(sp)
    8000587a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	8c6080e7          	jalr	-1850(ra) # 80004142 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005884:	08000613          	li	a2,128
    80005888:	f7040593          	addi	a1,s0,-144
    8000588c:	4501                	li	a0,0
    8000588e:	ffffd097          	auipc	ra,0xffffd
    80005892:	36a080e7          	jalr	874(ra) # 80002bf8 <argstr>
    80005896:	02054963          	bltz	a0,800058c8 <sys_mkdir+0x54>
    8000589a:	4681                	li	a3,0
    8000589c:	4601                	li	a2,0
    8000589e:	4585                	li	a1,1
    800058a0:	f7040513          	addi	a0,s0,-144
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	7fe080e7          	jalr	2046(ra) # 800050a2 <create>
    800058ac:	cd11                	beqz	a0,800058c8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	124080e7          	jalr	292(ra) # 800039d2 <iunlockput>
  end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	90c080e7          	jalr	-1780(ra) # 800041c2 <end_op>
  return 0;
    800058be:	4501                	li	a0,0
}
    800058c0:	60aa                	ld	ra,136(sp)
    800058c2:	640a                	ld	s0,128(sp)
    800058c4:	6149                	addi	sp,sp,144
    800058c6:	8082                	ret
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	8fa080e7          	jalr	-1798(ra) # 800041c2 <end_op>
    return -1;
    800058d0:	557d                	li	a0,-1
    800058d2:	b7fd                	j	800058c0 <sys_mkdir+0x4c>

00000000800058d4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058d4:	7135                	addi	sp,sp,-160
    800058d6:	ed06                	sd	ra,152(sp)
    800058d8:	e922                	sd	s0,144(sp)
    800058da:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	866080e7          	jalr	-1946(ra) # 80004142 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058e4:	08000613          	li	a2,128
    800058e8:	f7040593          	addi	a1,s0,-144
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	30a080e7          	jalr	778(ra) # 80002bf8 <argstr>
    800058f6:	04054a63          	bltz	a0,8000594a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058fa:	f6c40593          	addi	a1,s0,-148
    800058fe:	4505                	li	a0,1
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	2b4080e7          	jalr	692(ra) # 80002bb4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005908:	04054163          	bltz	a0,8000594a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000590c:	f6840593          	addi	a1,s0,-152
    80005910:	4509                	li	a0,2
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	2a2080e7          	jalr	674(ra) # 80002bb4 <argint>
     argint(1, &major) < 0 ||
    8000591a:	02054863          	bltz	a0,8000594a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000591e:	f6841683          	lh	a3,-152(s0)
    80005922:	f6c41603          	lh	a2,-148(s0)
    80005926:	458d                	li	a1,3
    80005928:	f7040513          	addi	a0,s0,-144
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	776080e7          	jalr	1910(ra) # 800050a2 <create>
     argint(2, &minor) < 0 ||
    80005934:	c919                	beqz	a0,8000594a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	09c080e7          	jalr	156(ra) # 800039d2 <iunlockput>
  end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	884080e7          	jalr	-1916(ra) # 800041c2 <end_op>
  return 0;
    80005946:	4501                	li	a0,0
    80005948:	a031                	j	80005954 <sys_mknod+0x80>
    end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	878080e7          	jalr	-1928(ra) # 800041c2 <end_op>
    return -1;
    80005952:	557d                	li	a0,-1
}
    80005954:	60ea                	ld	ra,152(sp)
    80005956:	644a                	ld	s0,144(sp)
    80005958:	610d                	addi	sp,sp,160
    8000595a:	8082                	ret

000000008000595c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000595c:	7135                	addi	sp,sp,-160
    8000595e:	ed06                	sd	ra,152(sp)
    80005960:	e922                	sd	s0,144(sp)
    80005962:	e526                	sd	s1,136(sp)
    80005964:	e14a                	sd	s2,128(sp)
    80005966:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005968:	ffffc097          	auipc	ra,0xffffc
    8000596c:	27c080e7          	jalr	636(ra) # 80001be4 <myproc>
    80005970:	892a                	mv	s2,a0
  
  begin_op();
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	7d0080e7          	jalr	2000(ra) # 80004142 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f6040593          	addi	a1,s0,-160
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	274080e7          	jalr	628(ra) # 80002bf8 <argstr>
    8000598c:	04054b63          	bltz	a0,800059e2 <sys_chdir+0x86>
    80005990:	f6040513          	addi	a0,s0,-160
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	592080e7          	jalr	1426(ra) # 80003f26 <namei>
    8000599c:	84aa                	mv	s1,a0
    8000599e:	c131                	beqz	a0,800059e2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	dd0080e7          	jalr	-560(ra) # 80003770 <ilock>
  if(ip->type != T_DIR){
    800059a8:	04449703          	lh	a4,68(s1)
    800059ac:	4785                	li	a5,1
    800059ae:	04f71063          	bne	a4,a5,800059ee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	e7e080e7          	jalr	-386(ra) # 80003832 <iunlock>
  iput(p->cwd);
    800059bc:	15893503          	ld	a0,344(s2)
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	f6a080e7          	jalr	-150(ra) # 8000392a <iput>
  end_op();
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	7fa080e7          	jalr	2042(ra) # 800041c2 <end_op>
  p->cwd = ip;
    800059d0:	14993c23          	sd	s1,344(s2)
  return 0;
    800059d4:	4501                	li	a0,0
}
    800059d6:	60ea                	ld	ra,152(sp)
    800059d8:	644a                	ld	s0,144(sp)
    800059da:	64aa                	ld	s1,136(sp)
    800059dc:	690a                	ld	s2,128(sp)
    800059de:	610d                	addi	sp,sp,160
    800059e0:	8082                	ret
    end_op();
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	7e0080e7          	jalr	2016(ra) # 800041c2 <end_op>
    return -1;
    800059ea:	557d                	li	a0,-1
    800059ec:	b7ed                	j	800059d6 <sys_chdir+0x7a>
    iunlockput(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	fe2080e7          	jalr	-30(ra) # 800039d2 <iunlockput>
    end_op();
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	7ca080e7          	jalr	1994(ra) # 800041c2 <end_op>
    return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	bfd1                	j	800059d6 <sys_chdir+0x7a>

0000000080005a04 <sys_exec>:

uint64
sys_exec(void)
{
    80005a04:	7145                	addi	sp,sp,-464
    80005a06:	e786                	sd	ra,456(sp)
    80005a08:	e3a2                	sd	s0,448(sp)
    80005a0a:	ff26                	sd	s1,440(sp)
    80005a0c:	fb4a                	sd	s2,432(sp)
    80005a0e:	f74e                	sd	s3,424(sp)
    80005a10:	f352                	sd	s4,416(sp)
    80005a12:	ef56                	sd	s5,408(sp)
    80005a14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a16:	08000613          	li	a2,128
    80005a1a:	f4040593          	addi	a1,s0,-192
    80005a1e:	4501                	li	a0,0
    80005a20:	ffffd097          	auipc	ra,0xffffd
    80005a24:	1d8080e7          	jalr	472(ra) # 80002bf8 <argstr>
    return -1;
    80005a28:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a2a:	0c054a63          	bltz	a0,80005afe <sys_exec+0xfa>
    80005a2e:	e3840593          	addi	a1,s0,-456
    80005a32:	4505                	li	a0,1
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	1a2080e7          	jalr	418(ra) # 80002bd6 <argaddr>
    80005a3c:	0c054163          	bltz	a0,80005afe <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a40:	10000613          	li	a2,256
    80005a44:	4581                	li	a1,0
    80005a46:	e4040513          	addi	a0,s0,-448
    80005a4a:	ffffb097          	auipc	ra,0xffffb
    80005a4e:	296080e7          	jalr	662(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a56:	89a6                	mv	s3,s1
    80005a58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a5a:	02000a13          	li	s4,32
    80005a5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a62:	00391513          	slli	a0,s2,0x3
    80005a66:	e3040593          	addi	a1,s0,-464
    80005a6a:	e3843783          	ld	a5,-456(s0)
    80005a6e:	953e                	add	a0,a0,a5
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	0aa080e7          	jalr	170(ra) # 80002b1a <fetchaddr>
    80005a78:	02054a63          	bltz	a0,80005aac <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a7c:	e3043783          	ld	a5,-464(s0)
    80005a80:	c3b9                	beqz	a5,80005ac6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a82:	ffffb097          	auipc	ra,0xffffb
    80005a86:	072080e7          	jalr	114(ra) # 80000af4 <kalloc>
    80005a8a:	85aa                	mv	a1,a0
    80005a8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a90:	cd11                	beqz	a0,80005aac <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a92:	6605                	lui	a2,0x1
    80005a94:	e3043503          	ld	a0,-464(s0)
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	0d4080e7          	jalr	212(ra) # 80002b6c <fetchstr>
    80005aa0:	00054663          	bltz	a0,80005aac <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aa4:	0905                	addi	s2,s2,1
    80005aa6:	09a1                	addi	s3,s3,8
    80005aa8:	fb491be3          	bne	s2,s4,80005a5e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aac:	10048913          	addi	s2,s1,256
    80005ab0:	6088                	ld	a0,0(s1)
    80005ab2:	c529                	beqz	a0,80005afc <sys_exec+0xf8>
    kfree(argv[i]);
    80005ab4:	ffffb097          	auipc	ra,0xffffb
    80005ab8:	f44080e7          	jalr	-188(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abc:	04a1                	addi	s1,s1,8
    80005abe:	ff2499e3          	bne	s1,s2,80005ab0 <sys_exec+0xac>
  return -1;
    80005ac2:	597d                	li	s2,-1
    80005ac4:	a82d                	j	80005afe <sys_exec+0xfa>
      argv[i] = 0;
    80005ac6:	0a8e                	slli	s5,s5,0x3
    80005ac8:	fc040793          	addi	a5,s0,-64
    80005acc:	9abe                	add	s5,s5,a5
    80005ace:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ad2:	e4040593          	addi	a1,s0,-448
    80005ad6:	f4040513          	addi	a0,s0,-192
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	194080e7          	jalr	404(ra) # 80004c6e <exec>
    80005ae2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae4:	10048993          	addi	s3,s1,256
    80005ae8:	6088                	ld	a0,0(s1)
    80005aea:	c911                	beqz	a0,80005afe <sys_exec+0xfa>
    kfree(argv[i]);
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	f0c080e7          	jalr	-244(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af4:	04a1                	addi	s1,s1,8
    80005af6:	ff3499e3          	bne	s1,s3,80005ae8 <sys_exec+0xe4>
    80005afa:	a011                	j	80005afe <sys_exec+0xfa>
  return -1;
    80005afc:	597d                	li	s2,-1
}
    80005afe:	854a                	mv	a0,s2
    80005b00:	60be                	ld	ra,456(sp)
    80005b02:	641e                	ld	s0,448(sp)
    80005b04:	74fa                	ld	s1,440(sp)
    80005b06:	795a                	ld	s2,432(sp)
    80005b08:	79ba                	ld	s3,424(sp)
    80005b0a:	7a1a                	ld	s4,416(sp)
    80005b0c:	6afa                	ld	s5,408(sp)
    80005b0e:	6179                	addi	sp,sp,464
    80005b10:	8082                	ret

0000000080005b12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b12:	7139                	addi	sp,sp,-64
    80005b14:	fc06                	sd	ra,56(sp)
    80005b16:	f822                	sd	s0,48(sp)
    80005b18:	f426                	sd	s1,40(sp)
    80005b1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b1c:	ffffc097          	auipc	ra,0xffffc
    80005b20:	0c8080e7          	jalr	200(ra) # 80001be4 <myproc>
    80005b24:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b26:	fd840593          	addi	a1,s0,-40
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	0aa080e7          	jalr	170(ra) # 80002bd6 <argaddr>
    return -1;
    80005b34:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b36:	0e054063          	bltz	a0,80005c16 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b3a:	fc840593          	addi	a1,s0,-56
    80005b3e:	fd040513          	addi	a0,s0,-48
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	dfc080e7          	jalr	-516(ra) # 8000493e <pipealloc>
    return -1;
    80005b4a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b4c:	0c054563          	bltz	a0,80005c16 <sys_pipe+0x104>
  fd0 = -1;
    80005b50:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b54:	fd043503          	ld	a0,-48(s0)
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	508080e7          	jalr	1288(ra) # 80005060 <fdalloc>
    80005b60:	fca42223          	sw	a0,-60(s0)
    80005b64:	08054c63          	bltz	a0,80005bfc <sys_pipe+0xea>
    80005b68:	fc843503          	ld	a0,-56(s0)
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	4f4080e7          	jalr	1268(ra) # 80005060 <fdalloc>
    80005b74:	fca42023          	sw	a0,-64(s0)
    80005b78:	06054863          	bltz	a0,80005be8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b7c:	4691                	li	a3,4
    80005b7e:	fc440613          	addi	a2,s0,-60
    80005b82:	fd843583          	ld	a1,-40(s0)
    80005b86:	6ca8                	ld	a0,88(s1)
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	aea080e7          	jalr	-1302(ra) # 80001672 <copyout>
    80005b90:	02054063          	bltz	a0,80005bb0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b94:	4691                	li	a3,4
    80005b96:	fc040613          	addi	a2,s0,-64
    80005b9a:	fd843583          	ld	a1,-40(s0)
    80005b9e:	0591                	addi	a1,a1,4
    80005ba0:	6ca8                	ld	a0,88(s1)
    80005ba2:	ffffc097          	auipc	ra,0xffffc
    80005ba6:	ad0080e7          	jalr	-1328(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005baa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bac:	06055563          	bgez	a0,80005c16 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bb0:	fc442783          	lw	a5,-60(s0)
    80005bb4:	07e9                	addi	a5,a5,26
    80005bb6:	078e                	slli	a5,a5,0x3
    80005bb8:	97a6                	add	a5,a5,s1
    80005bba:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005bbe:	fc042503          	lw	a0,-64(s0)
    80005bc2:	0569                	addi	a0,a0,26
    80005bc4:	050e                	slli	a0,a0,0x3
    80005bc6:	9526                	add	a0,a0,s1
    80005bc8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005bcc:	fd043503          	ld	a0,-48(s0)
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	a3e080e7          	jalr	-1474(ra) # 8000460e <fileclose>
    fileclose(wf);
    80005bd8:	fc843503          	ld	a0,-56(s0)
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	a32080e7          	jalr	-1486(ra) # 8000460e <fileclose>
    return -1;
    80005be4:	57fd                	li	a5,-1
    80005be6:	a805                	j	80005c16 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005be8:	fc442783          	lw	a5,-60(s0)
    80005bec:	0007c863          	bltz	a5,80005bfc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bf0:	01a78513          	addi	a0,a5,26
    80005bf4:	050e                	slli	a0,a0,0x3
    80005bf6:	9526                	add	a0,a0,s1
    80005bf8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005bfc:	fd043503          	ld	a0,-48(s0)
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	a0e080e7          	jalr	-1522(ra) # 8000460e <fileclose>
    fileclose(wf);
    80005c08:	fc843503          	ld	a0,-56(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	a02080e7          	jalr	-1534(ra) # 8000460e <fileclose>
    return -1;
    80005c14:	57fd                	li	a5,-1
}
    80005c16:	853e                	mv	a0,a5
    80005c18:	70e2                	ld	ra,56(sp)
    80005c1a:	7442                	ld	s0,48(sp)
    80005c1c:	74a2                	ld	s1,40(sp)
    80005c1e:	6121                	addi	sp,sp,64
    80005c20:	8082                	ret
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	d77fc0ef          	jal	ra,800029e6 <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	6d0c                	ld	a1,24(a0)
    80005ccc:	7110                	ld	a2,32(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	eb0080e7          	jalr	-336(ra) # 80001bb8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	e78080e7          	jalr	-392(ra) # 80001bb8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	e50080e7          	jalr	-432(ra) # 80001bb8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	06a7c963          	blt	a5,a0,80005e02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	26c78793          	addi	a5,a5,620 # 80023000 <disk>
    80005d9c:	00a78733          	add	a4,a5,a0
    80005da0:	6789                	lui	a5,0x2
    80005da2:	97ba                	add	a5,a5,a4
    80005da4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005da8:	e7ad                	bnez	a5,80005e12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005daa:	00451793          	slli	a5,a0,0x4
    80005dae:	0001f717          	auipc	a4,0x1f
    80005db2:	25270713          	addi	a4,a4,594 # 80025000 <disk+0x2000>
    80005db6:	6314                	ld	a3,0(a4)
    80005db8:	96be                	add	a3,a3,a5
    80005dba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dbe:	6314                	ld	a3,0(a4)
    80005dc0:	96be                	add	a3,a3,a5
    80005dc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005dc6:	6314                	ld	a3,0(a4)
    80005dc8:	96be                	add	a3,a3,a5
    80005dca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dce:	6318                	ld	a4,0(a4)
    80005dd0:	97ba                	add	a5,a5,a4
    80005dd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005dd6:	0001d797          	auipc	a5,0x1d
    80005dda:	22a78793          	addi	a5,a5,554 # 80023000 <disk>
    80005dde:	97aa                	add	a5,a5,a0
    80005de0:	6509                	lui	a0,0x2
    80005de2:	953e                	add	a0,a0,a5
    80005de4:	4785                	li	a5,1
    80005de6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dea:	0001f517          	auipc	a0,0x1f
    80005dee:	22e50513          	addi	a0,a0,558 # 80025018 <disk+0x2018>
    80005df2:	ffffc097          	auipc	ra,0xffffc
    80005df6:	5d0080e7          	jalr	1488(ra) # 800023c2 <wakeup>
}
    80005dfa:	60a2                	ld	ra,8(sp)
    80005dfc:	6402                	ld	s0,0(sp)
    80005dfe:	0141                	addi	sp,sp,16
    80005e00:	8082                	ret
    panic("free_desc 1");
    80005e02:	00003517          	auipc	a0,0x3
    80005e06:	98e50513          	addi	a0,a0,-1650 # 80008790 <syscalls+0x330>
    80005e0a:	ffffa097          	auipc	ra,0xffffa
    80005e0e:	734080e7          	jalr	1844(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	98e50513          	addi	a0,a0,-1650 # 800087a0 <syscalls+0x340>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	724080e7          	jalr	1828(ra) # 8000053e <panic>

0000000080005e22 <virtio_disk_init>:
{
    80005e22:	1101                	addi	sp,sp,-32
    80005e24:	ec06                	sd	ra,24(sp)
    80005e26:	e822                	sd	s0,16(sp)
    80005e28:	e426                	sd	s1,8(sp)
    80005e2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e2c:	00003597          	auipc	a1,0x3
    80005e30:	98458593          	addi	a1,a1,-1660 # 800087b0 <syscalls+0x350>
    80005e34:	0001f517          	auipc	a0,0x1f
    80005e38:	2f450513          	addi	a0,a0,756 # 80025128 <disk+0x2128>
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	d18080e7          	jalr	-744(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e44:	100017b7          	lui	a5,0x10001
    80005e48:	4398                	lw	a4,0(a5)
    80005e4a:	2701                	sext.w	a4,a4
    80005e4c:	747277b7          	lui	a5,0x74727
    80005e50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e54:	0ef71163          	bne	a4,a5,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e58:	100017b7          	lui	a5,0x10001
    80005e5c:	43dc                	lw	a5,4(a5)
    80005e5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e60:	4705                	li	a4,1
    80005e62:	0ce79a63          	bne	a5,a4,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e66:	100017b7          	lui	a5,0x10001
    80005e6a:	479c                	lw	a5,8(a5)
    80005e6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e6e:	4709                	li	a4,2
    80005e70:	0ce79363          	bne	a5,a4,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	47d8                	lw	a4,12(a5)
    80005e7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7c:	554d47b7          	lui	a5,0x554d4
    80005e80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e84:	0af71963          	bne	a4,a5,80005f36 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	4705                	li	a4,1
    80005e8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e90:	470d                	li	a4,3
    80005e92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e96:	c7ffe737          	lui	a4,0xc7ffe
    80005e9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea0:	2701                	sext.w	a4,a4
    80005ea2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea4:	472d                	li	a4,11
    80005ea6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea8:	473d                	li	a4,15
    80005eaa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eac:	6705                	lui	a4,0x1
    80005eae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eb4:	5bdc                	lw	a5,52(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eb8:	c7d9                	beqz	a5,80005f46 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eba:	471d                	li	a4,7
    80005ebc:	08f77d63          	bgeu	a4,a5,80005f56 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec0:	100014b7          	lui	s1,0x10001
    80005ec4:	47a1                	li	a5,8
    80005ec6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ec8:	6609                	lui	a2,0x2
    80005eca:	4581                	li	a1,0
    80005ecc:	0001d517          	auipc	a0,0x1d
    80005ed0:	13450513          	addi	a0,a0,308 # 80023000 <disk>
    80005ed4:	ffffb097          	auipc	ra,0xffffb
    80005ed8:	e0c080e7          	jalr	-500(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005edc:	0001d717          	auipc	a4,0x1d
    80005ee0:	12470713          	addi	a4,a4,292 # 80023000 <disk>
    80005ee4:	00c75793          	srli	a5,a4,0xc
    80005ee8:	2781                	sext.w	a5,a5
    80005eea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005eec:	0001f797          	auipc	a5,0x1f
    80005ef0:	11478793          	addi	a5,a5,276 # 80025000 <disk+0x2000>
    80005ef4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ef6:	0001d717          	auipc	a4,0x1d
    80005efa:	18a70713          	addi	a4,a4,394 # 80023080 <disk+0x80>
    80005efe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f00:	0001e717          	auipc	a4,0x1e
    80005f04:	10070713          	addi	a4,a4,256 # 80024000 <disk+0x1000>
    80005f08:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f0a:	4705                	li	a4,1
    80005f0c:	00e78c23          	sb	a4,24(a5)
    80005f10:	00e78ca3          	sb	a4,25(a5)
    80005f14:	00e78d23          	sb	a4,26(a5)
    80005f18:	00e78da3          	sb	a4,27(a5)
    80005f1c:	00e78e23          	sb	a4,28(a5)
    80005f20:	00e78ea3          	sb	a4,29(a5)
    80005f24:	00e78f23          	sb	a4,30(a5)
    80005f28:	00e78fa3          	sb	a4,31(a5)
}
    80005f2c:	60e2                	ld	ra,24(sp)
    80005f2e:	6442                	ld	s0,16(sp)
    80005f30:	64a2                	ld	s1,8(sp)
    80005f32:	6105                	addi	sp,sp,32
    80005f34:	8082                	ret
    panic("could not find virtio disk");
    80005f36:	00003517          	auipc	a0,0x3
    80005f3a:	88a50513          	addi	a0,a0,-1910 # 800087c0 <syscalls+0x360>
    80005f3e:	ffffa097          	auipc	ra,0xffffa
    80005f42:	600080e7          	jalr	1536(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f46:	00003517          	auipc	a0,0x3
    80005f4a:	89a50513          	addi	a0,a0,-1894 # 800087e0 <syscalls+0x380>
    80005f4e:	ffffa097          	auipc	ra,0xffffa
    80005f52:	5f0080e7          	jalr	1520(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f56:	00003517          	auipc	a0,0x3
    80005f5a:	8aa50513          	addi	a0,a0,-1878 # 80008800 <syscalls+0x3a0>
    80005f5e:	ffffa097          	auipc	ra,0xffffa
    80005f62:	5e0080e7          	jalr	1504(ra) # 8000053e <panic>

0000000080005f66 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f66:	7159                	addi	sp,sp,-112
    80005f68:	f486                	sd	ra,104(sp)
    80005f6a:	f0a2                	sd	s0,96(sp)
    80005f6c:	eca6                	sd	s1,88(sp)
    80005f6e:	e8ca                	sd	s2,80(sp)
    80005f70:	e4ce                	sd	s3,72(sp)
    80005f72:	e0d2                	sd	s4,64(sp)
    80005f74:	fc56                	sd	s5,56(sp)
    80005f76:	f85a                	sd	s6,48(sp)
    80005f78:	f45e                	sd	s7,40(sp)
    80005f7a:	f062                	sd	s8,32(sp)
    80005f7c:	ec66                	sd	s9,24(sp)
    80005f7e:	e86a                	sd	s10,16(sp)
    80005f80:	1880                	addi	s0,sp,112
    80005f82:	892a                	mv	s2,a0
    80005f84:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f86:	00c52c83          	lw	s9,12(a0)
    80005f8a:	001c9c9b          	slliw	s9,s9,0x1
    80005f8e:	1c82                	slli	s9,s9,0x20
    80005f90:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f94:	0001f517          	auipc	a0,0x1f
    80005f98:	19450513          	addi	a0,a0,404 # 80025128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	c48080e7          	jalr	-952(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005fa4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fa6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fa8:	0001db97          	auipc	s7,0x1d
    80005fac:	058b8b93          	addi	s7,s7,88 # 80023000 <disk>
    80005fb0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fb2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fb4:	8a4e                	mv	s4,s3
    80005fb6:	a051                	j	8000603a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fb8:	00fb86b3          	add	a3,s7,a5
    80005fbc:	96da                	add	a3,a3,s6
    80005fbe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fc2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fc4:	0207c563          	bltz	a5,80005fee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fc8:	2485                	addiw	s1,s1,1
    80005fca:	0711                	addi	a4,a4,4
    80005fcc:	25548063          	beq	s1,s5,8000620c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005fd0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fd2:	0001f697          	auipc	a3,0x1f
    80005fd6:	04668693          	addi	a3,a3,70 # 80025018 <disk+0x2018>
    80005fda:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fdc:	0006c583          	lbu	a1,0(a3)
    80005fe0:	fde1                	bnez	a1,80005fb8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe2:	2785                	addiw	a5,a5,1
    80005fe4:	0685                	addi	a3,a3,1
    80005fe6:	ff879be3          	bne	a5,s8,80005fdc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fea:	57fd                	li	a5,-1
    80005fec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fee:	02905a63          	blez	s1,80006022 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff2:	f9042503          	lw	a0,-112(s0)
    80005ff6:	00000097          	auipc	ra,0x0
    80005ffa:	d90080e7          	jalr	-624(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005ffe:	4785                	li	a5,1
    80006000:	0297d163          	bge	a5,s1,80006022 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006004:	f9442503          	lw	a0,-108(s0)
    80006008:	00000097          	auipc	ra,0x0
    8000600c:	d7e080e7          	jalr	-642(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80006010:	4789                	li	a5,2
    80006012:	0097d863          	bge	a5,s1,80006022 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006016:	f9842503          	lw	a0,-104(s0)
    8000601a:	00000097          	auipc	ra,0x0
    8000601e:	d6c080e7          	jalr	-660(ra) # 80005d86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006022:	0001f597          	auipc	a1,0x1f
    80006026:	10658593          	addi	a1,a1,262 # 80025128 <disk+0x2128>
    8000602a:	0001f517          	auipc	a0,0x1f
    8000602e:	fee50513          	addi	a0,a0,-18 # 80025018 <disk+0x2018>
    80006032:	ffffc097          	auipc	ra,0xffffc
    80006036:	204080e7          	jalr	516(ra) # 80002236 <sleep>
  for(int i = 0; i < 3; i++){
    8000603a:	f9040713          	addi	a4,s0,-112
    8000603e:	84ce                	mv	s1,s3
    80006040:	bf41                	j	80005fd0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006042:	20058713          	addi	a4,a1,512
    80006046:	00471693          	slli	a3,a4,0x4
    8000604a:	0001d717          	auipc	a4,0x1d
    8000604e:	fb670713          	addi	a4,a4,-74 # 80023000 <disk>
    80006052:	9736                	add	a4,a4,a3
    80006054:	4685                	li	a3,1
    80006056:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000605a:	20058713          	addi	a4,a1,512
    8000605e:	00471693          	slli	a3,a4,0x4
    80006062:	0001d717          	auipc	a4,0x1d
    80006066:	f9e70713          	addi	a4,a4,-98 # 80023000 <disk>
    8000606a:	9736                	add	a4,a4,a3
    8000606c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006070:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006074:	7679                	lui	a2,0xffffe
    80006076:	963e                	add	a2,a2,a5
    80006078:	0001f697          	auipc	a3,0x1f
    8000607c:	f8868693          	addi	a3,a3,-120 # 80025000 <disk+0x2000>
    80006080:	6298                	ld	a4,0(a3)
    80006082:	9732                	add	a4,a4,a2
    80006084:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006086:	6298                	ld	a4,0(a3)
    80006088:	9732                	add	a4,a4,a2
    8000608a:	4541                	li	a0,16
    8000608c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000608e:	6298                	ld	a4,0(a3)
    80006090:	9732                	add	a4,a4,a2
    80006092:	4505                	li	a0,1
    80006094:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006098:	f9442703          	lw	a4,-108(s0)
    8000609c:	6288                	ld	a0,0(a3)
    8000609e:	962a                	add	a2,a2,a0
    800060a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a4:	0712                	slli	a4,a4,0x4
    800060a6:	6290                	ld	a2,0(a3)
    800060a8:	963a                	add	a2,a2,a4
    800060aa:	05890513          	addi	a0,s2,88
    800060ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060b0:	6294                	ld	a3,0(a3)
    800060b2:	96ba                	add	a3,a3,a4
    800060b4:	40000613          	li	a2,1024
    800060b8:	c690                	sw	a2,8(a3)
  if(write)
    800060ba:	140d0063          	beqz	s10,800061fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060be:	0001f697          	auipc	a3,0x1f
    800060c2:	f426b683          	ld	a3,-190(a3) # 80025000 <disk+0x2000>
    800060c6:	96ba                	add	a3,a3,a4
    800060c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060cc:	0001d817          	auipc	a6,0x1d
    800060d0:	f3480813          	addi	a6,a6,-204 # 80023000 <disk>
    800060d4:	0001f517          	auipc	a0,0x1f
    800060d8:	f2c50513          	addi	a0,a0,-212 # 80025000 <disk+0x2000>
    800060dc:	6114                	ld	a3,0(a0)
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00c6d603          	lhu	a2,12(a3)
    800060e4:	00166613          	ori	a2,a2,1
    800060e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ec:	f9842683          	lw	a3,-104(s0)
    800060f0:	6110                	ld	a2,0(a0)
    800060f2:	9732                	add	a4,a4,a2
    800060f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060f8:	20058613          	addi	a2,a1,512
    800060fc:	0612                	slli	a2,a2,0x4
    800060fe:	9642                	add	a2,a2,a6
    80006100:	577d                	li	a4,-1
    80006102:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006106:	00469713          	slli	a4,a3,0x4
    8000610a:	6114                	ld	a3,0(a0)
    8000610c:	96ba                	add	a3,a3,a4
    8000610e:	03078793          	addi	a5,a5,48
    80006112:	97c2                	add	a5,a5,a6
    80006114:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006116:	611c                	ld	a5,0(a0)
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	4685                	li	a3,1
    8000611c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000611e:	611c                	ld	a5,0(a0)
    80006120:	97ba                	add	a5,a5,a4
    80006122:	4809                	li	a6,2
    80006124:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006128:	611c                	ld	a5,0(a0)
    8000612a:	973e                	add	a4,a4,a5
    8000612c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006130:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006134:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006138:	6518                	ld	a4,8(a0)
    8000613a:	00275783          	lhu	a5,2(a4)
    8000613e:	8b9d                	andi	a5,a5,7
    80006140:	0786                	slli	a5,a5,0x1
    80006142:	97ba                	add	a5,a5,a4
    80006144:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006148:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000614c:	6518                	ld	a4,8(a0)
    8000614e:	00275783          	lhu	a5,2(a4)
    80006152:	2785                	addiw	a5,a5,1
    80006154:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006158:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006164:	00492703          	lw	a4,4(s2)
    80006168:	4785                	li	a5,1
    8000616a:	02f71163          	bne	a4,a5,8000618c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	fba98993          	addi	s3,s3,-70 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006176:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006178:	85ce                	mv	a1,s3
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	0ba080e7          	jalr	186(ra) # 80002236 <sleep>
  while(b->disk == 1) {
    80006184:	00492783          	lw	a5,4(s2)
    80006188:	fe9788e3          	beq	a5,s1,80006178 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000618c:	f9042903          	lw	s2,-112(s0)
    80006190:	20090793          	addi	a5,s2,512
    80006194:	00479713          	slli	a4,a5,0x4
    80006198:	0001d797          	auipc	a5,0x1d
    8000619c:	e6878793          	addi	a5,a5,-408 # 80023000 <disk>
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061a6:	0001f997          	auipc	s3,0x1f
    800061aa:	e5a98993          	addi	s3,s3,-422 # 80025000 <disk+0x2000>
    800061ae:	00491713          	slli	a4,s2,0x4
    800061b2:	0009b783          	ld	a5,0(s3)
    800061b6:	97ba                	add	a5,a5,a4
    800061b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061bc:	854a                	mv	a0,s2
    800061be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061c2:	00000097          	auipc	ra,0x0
    800061c6:	bc4080e7          	jalr	-1084(ra) # 80005d86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061ca:	8885                	andi	s1,s1,1
    800061cc:	f0ed                	bnez	s1,800061ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061ce:	0001f517          	auipc	a0,0x1f
    800061d2:	f5a50513          	addi	a0,a0,-166 # 80025128 <disk+0x2128>
    800061d6:	ffffb097          	auipc	ra,0xffffb
    800061da:	ac2080e7          	jalr	-1342(ra) # 80000c98 <release>
}
    800061de:	70a6                	ld	ra,104(sp)
    800061e0:	7406                	ld	s0,96(sp)
    800061e2:	64e6                	ld	s1,88(sp)
    800061e4:	6946                	ld	s2,80(sp)
    800061e6:	69a6                	ld	s3,72(sp)
    800061e8:	6a06                	ld	s4,64(sp)
    800061ea:	7ae2                	ld	s5,56(sp)
    800061ec:	7b42                	ld	s6,48(sp)
    800061ee:	7ba2                	ld	s7,40(sp)
    800061f0:	7c02                	ld	s8,32(sp)
    800061f2:	6ce2                	ld	s9,24(sp)
    800061f4:	6d42                	ld	s10,16(sp)
    800061f6:	6165                	addi	sp,sp,112
    800061f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061fa:	0001f697          	auipc	a3,0x1f
    800061fe:	e066b683          	ld	a3,-506(a3) # 80025000 <disk+0x2000>
    80006202:	96ba                	add	a3,a3,a4
    80006204:	4609                	li	a2,2
    80006206:	00c69623          	sh	a2,12(a3)
    8000620a:	b5c9                	j	800060cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000620c:	f9042583          	lw	a1,-112(s0)
    80006210:	20058793          	addi	a5,a1,512
    80006214:	0792                	slli	a5,a5,0x4
    80006216:	0001d517          	auipc	a0,0x1d
    8000621a:	e9250513          	addi	a0,a0,-366 # 800230a8 <disk+0xa8>
    8000621e:	953e                	add	a0,a0,a5
  if(write)
    80006220:	e20d11e3          	bnez	s10,80006042 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006224:	20058713          	addi	a4,a1,512
    80006228:	00471693          	slli	a3,a4,0x4
    8000622c:	0001d717          	auipc	a4,0x1d
    80006230:	dd470713          	addi	a4,a4,-556 # 80023000 <disk>
    80006234:	9736                	add	a4,a4,a3
    80006236:	0a072423          	sw	zero,168(a4)
    8000623a:	b505                	j	8000605a <virtio_disk_rw+0xf4>

000000008000623c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000623c:	1101                	addi	sp,sp,-32
    8000623e:	ec06                	sd	ra,24(sp)
    80006240:	e822                	sd	s0,16(sp)
    80006242:	e426                	sd	s1,8(sp)
    80006244:	e04a                	sd	s2,0(sp)
    80006246:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006248:	0001f517          	auipc	a0,0x1f
    8000624c:	ee050513          	addi	a0,a0,-288 # 80025128 <disk+0x2128>
    80006250:	ffffb097          	auipc	ra,0xffffb
    80006254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006258:	10001737          	lui	a4,0x10001
    8000625c:	533c                	lw	a5,96(a4)
    8000625e:	8b8d                	andi	a5,a5,3
    80006260:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006262:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006266:	0001f797          	auipc	a5,0x1f
    8000626a:	d9a78793          	addi	a5,a5,-614 # 80025000 <disk+0x2000>
    8000626e:	6b94                	ld	a3,16(a5)
    80006270:	0207d703          	lhu	a4,32(a5)
    80006274:	0026d783          	lhu	a5,2(a3)
    80006278:	06f70163          	beq	a4,a5,800062da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000627c:	0001d917          	auipc	s2,0x1d
    80006280:	d8490913          	addi	s2,s2,-636 # 80023000 <disk>
    80006284:	0001f497          	auipc	s1,0x1f
    80006288:	d7c48493          	addi	s1,s1,-644 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000628c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006290:	6898                	ld	a4,16(s1)
    80006292:	0204d783          	lhu	a5,32(s1)
    80006296:	8b9d                	andi	a5,a5,7
    80006298:	078e                	slli	a5,a5,0x3
    8000629a:	97ba                	add	a5,a5,a4
    8000629c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000629e:	20078713          	addi	a4,a5,512
    800062a2:	0712                	slli	a4,a4,0x4
    800062a4:	974a                	add	a4,a4,s2
    800062a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062aa:	e731                	bnez	a4,800062f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062ac:	20078793          	addi	a5,a5,512
    800062b0:	0792                	slli	a5,a5,0x4
    800062b2:	97ca                	add	a5,a5,s2
    800062b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ba:	ffffc097          	auipc	ra,0xffffc
    800062be:	108080e7          	jalr	264(ra) # 800023c2 <wakeup>

    disk.used_idx += 1;
    800062c2:	0204d783          	lhu	a5,32(s1)
    800062c6:	2785                	addiw	a5,a5,1
    800062c8:	17c2                	slli	a5,a5,0x30
    800062ca:	93c1                	srli	a5,a5,0x30
    800062cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062d0:	6898                	ld	a4,16(s1)
    800062d2:	00275703          	lhu	a4,2(a4)
    800062d6:	faf71be3          	bne	a4,a5,8000628c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062da:	0001f517          	auipc	a0,0x1f
    800062de:	e4e50513          	addi	a0,a0,-434 # 80025128 <disk+0x2128>
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	9b6080e7          	jalr	-1610(ra) # 80000c98 <release>
}
    800062ea:	60e2                	ld	ra,24(sp)
    800062ec:	6442                	ld	s0,16(sp)
    800062ee:	64a2                	ld	s1,8(sp)
    800062f0:	6902                	ld	s2,0(sp)
    800062f2:	6105                	addi	sp,sp,32
    800062f4:	8082                	ret
      panic("virtio_disk_intr status");
    800062f6:	00002517          	auipc	a0,0x2
    800062fa:	52a50513          	addi	a0,a0,1322 # 80008820 <syscalls+0x3c0>
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	240080e7          	jalr	576(ra) # 8000053e <panic>
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
