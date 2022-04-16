
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	bec78793          	addi	a5,a5,-1044 # 80005c50 <timervec>
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
    80000130:	42c080e7          	jalr	1068(ra) # 80002558 <either_copyin>
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
    800001c8:	9c2080e7          	jalr	-1598(ra) # 80001b86 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ffc080e7          	jalr	-4(ra) # 800021d0 <sleep>
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
    80000214:	2f2080e7          	jalr	754(ra) # 80002502 <either_copyout>
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
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
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
    8000044a:	f16080e7          	jalr	-234(ra) # 8000235c <wakeup>
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
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
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
    800008a4:	abc080e7          	jalr	-1348(ra) # 8000235c <wakeup>
    
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
    80000930:	8a4080e7          	jalr	-1884(ra) # 800021d0 <sleep>
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
    80000b82:	fec080e7          	jalr	-20(ra) # 80001b6a <mycpu>
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
    80000bb4:	fba080e7          	jalr	-70(ra) # 80001b6a <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fae080e7          	jalr	-82(ra) # 80001b6a <mycpu>
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
    80000bd8:	f96080e7          	jalr	-106(ra) # 80001b6a <mycpu>
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
    80000c18:	f56080e7          	jalr	-170(ra) # 80001b6a <mycpu>
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
    80000c44:	f2a080e7          	jalr	-214(ra) # 80001b6a <mycpu>
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
    80000e9a:	cc4080e7          	jalr	-828(ra) # 80001b5a <cpuid>
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
    80000eb6:	ca8080e7          	jalr	-856(ra) # 80001b5a <cpuid>
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
    80000ed8:	81a080e7          	jalr	-2022(ra) # 800026ee <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	db4080e7          	jalr	-588(ra) # 80005c90 <plicinithart>
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
    80000f48:	b66080e7          	jalr	-1178(ra) # 80001aaa <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	77a080e7          	jalr	1914(ra) # 800026c6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	79a080e7          	jalr	1946(ra) # 800026ee <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d1e080e7          	jalr	-738(ra) # 80005c7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d2c080e7          	jalr	-724(ra) # 80005c90 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f0e080e7          	jalr	-242(ra) # 80002e7a <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	59e080e7          	jalr	1438(ra) # 80003512 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	548080e7          	jalr	1352(ra) # 800044c4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e2e080e7          	jalr	-466(ra) # 80005db2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	ed2080e7          	jalr	-302(ra) # 80001e5e <userinit>
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
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
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
    800018a8:	16848493          	addi	s1,s1,360
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
    800018ec:	00015997          	auipc	s3,0x15
    800018f0:	7e498993          	addi	s3,s3,2020 # 800170d0 <tickslock>
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
    8000190e:	16848493          	addi	s1,s1,360
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
    8000196a:	00015997          	auipc	s3,0x15
    8000196e:	76698993          	addi	s3,s3,1894 # 800170d0 <tickslock>
    80001972:	a811                	j	80001986 <kill_sys+0x40>
      }
      //release(&p->lock);
    }
    release(&p->lock);
    80001974:	8526                	mv	a0,s1
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	322080e7          	jalr	802(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000197e:	16848493          	addi	s1,s1,360
    80001982:	03348863          	beq	s1,s3,800019b2 <kill_sys+0x6c>
    acquire(&p->lock);
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
    if((p->pid != proc[0].pid) && (p->pid != proc[1].pid)){
    80001990:	589c                	lw	a5,48(s1)
    80001992:	03092703          	lw	a4,48(s2) # 4000030 <_entry-0x7bffffd0>
    80001996:	fcf70fe3          	beq	a4,a5,80001974 <kill_sys+0x2e>
    8000199a:	19892703          	lw	a4,408(s2)
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
#ifdef FCFS
void
scheduler(void)
{
    800019c8:	715d                	addi	sp,sp,-80
    800019ca:	e486                	sd	ra,72(sp)
    800019cc:	e0a2                	sd	s0,64(sp)
    800019ce:	fc26                	sd	s1,56(sp)
    800019d0:	f84a                	sd	s2,48(sp)
    800019d2:	f44e                	sd	s3,40(sp)
    800019d4:	f052                	sd	s4,32(sp)
    800019d6:	ec56                	sd	s5,24(sp)
    800019d8:	e85a                	sd	s6,16(sp)
    800019da:	e45e                	sd	s7,8(sp)
    800019dc:	e062                	sd	s8,0(sp)
    800019de:	0880                	addi	s0,sp,80
  printf("FCFS\n");
    800019e0:	00007517          	auipc	a0,0x7
    800019e4:	80050513          	addi	a0,a0,-2048 # 800081e0 <digits+0x1a0>
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	ba0080e7          	jalr	-1120(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f0:	8792                	mv	a5,tp
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
    800019f2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800019f4:	00010c17          	auipc	s8,0x10
    800019f8:	8acc0c13          	addi	s8,s8,-1876 # 800112a0 <cpus>
    800019fc:	00779713          	slli	a4,a5,0x7
    80001a00:	00ec06b3          	add	a3,s8,a4
    80001a04:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
          swtch(&c->context, &p->context);
    80001a08:	0721                	addi	a4,a4,8
    80001a0a:	9c3a                	add	s8,s8,a4
          c->proc = p;
    80001a0c:	8bb6                	mv	s7,a3
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a0e:	00007a97          	auipc	s5,0x7
    80001a12:	61aa8a93          	addi	s5,s5,1562 # 80009028 <finish>
    80001a16:	00007a17          	auipc	s4,0x7
    80001a1a:	622a0a13          	addi	s4,s4,1570 # 80009038 <ticks>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a26:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a2a:	00010497          	auipc	s1,0x10
    80001a2e:	ca648493          	addi	s1,s1,-858 # 800116d0 <proc>
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a32:	8926                	mv	s2,s1
        if(p->state == RUNNABLE) {
    80001a34:	4b0d                	li	s6,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a36:	00015997          	auipc	s3,0x15
    80001a3a:	69a98993          	addi	s3,s3,1690 # 800170d0 <tickslock>
    80001a3e:	a015                	j	80001a62 <scheduler+0x9a>
        acquire(&p->lock);
    80001a40:	8526                	mv	a0,s1
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	1a2080e7          	jalr	418(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001a4a:	4c9c                	lw	a5,24(s1)
    80001a4c:	05678163          	beq	a5,s6,80001a8e <scheduler+0xc6>
        release(&p->lock);
    80001a50:	8526                	mv	a0,s1
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001a5a:	16848493          	addi	s1,s1,360
    80001a5e:	fd3480e3          	beq	s1,s3,80001a1e <scheduler+0x56>
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001a62:	5894                	lw	a3,48(s1)
    80001a64:	03092783          	lw	a5,48(s2)
    80001a68:	8f95                	sub	a5,a5,a3
    80001a6a:	0017b793          	seqz	a5,a5
    80001a6e:	19892703          	lw	a4,408(s2)
    80001a72:	8f15                	sub	a4,a4,a3
    80001a74:	00173713          	seqz	a4,a4
    80001a78:	8fd9                	or	a5,a5,a4
    80001a7a:	0ff7f793          	andi	a5,a5,255
    80001a7e:	f3e9                	bnez	a5,80001a40 <scheduler+0x78>
    80001a80:	000aa703          	lw	a4,0(s5)
    80001a84:	000a2783          	lw	a5,0(s4)
    80001a88:	fcf779e3          	bgeu	a4,a5,80001a5a <scheduler+0x92>
    80001a8c:	bf55                	j	80001a40 <scheduler+0x78>
          p->state = RUNNING;
    80001a8e:	4791                	li	a5,4
    80001a90:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001a92:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          swtch(&c->context, &p->context);
    80001a96:	06048593          	addi	a1,s1,96
    80001a9a:	8562                	mv	a0,s8
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	bc0080e7          	jalr	-1088(ra) # 8000265c <swtch>
          c->proc = 0;
    80001aa4:	000bb023          	sd	zero,0(s7)
    80001aa8:	b765                	j	80001a50 <scheduler+0x88>

0000000080001aaa <procinit>:
{
    80001aaa:	7139                	addi	sp,sp,-64
    80001aac:	fc06                	sd	ra,56(sp)
    80001aae:	f822                	sd	s0,48(sp)
    80001ab0:	f426                	sd	s1,40(sp)
    80001ab2:	f04a                	sd	s2,32(sp)
    80001ab4:	ec4e                	sd	s3,24(sp)
    80001ab6:	e852                	sd	s4,16(sp)
    80001ab8:	e456                	sd	s5,8(sp)
    80001aba:	e05a                	sd	s6,0(sp)
    80001abc:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001abe:	00006597          	auipc	a1,0x6
    80001ac2:	72a58593          	addi	a1,a1,1834 # 800081e8 <digits+0x1a8>
    80001ac6:	00010517          	auipc	a0,0x10
    80001aca:	bda50513          	addi	a0,a0,-1062 # 800116a0 <pid_lock>
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	086080e7          	jalr	134(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ad6:	00006597          	auipc	a1,0x6
    80001ada:	71a58593          	addi	a1,a1,1818 # 800081f0 <digits+0x1b0>
    80001ade:	00010517          	auipc	a0,0x10
    80001ae2:	bda50513          	addi	a0,a0,-1062 # 800116b8 <wait_lock>
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	06e080e7          	jalr	110(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aee:	00010497          	auipc	s1,0x10
    80001af2:	be248493          	addi	s1,s1,-1054 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001af6:	00006b17          	auipc	s6,0x6
    80001afa:	70ab0b13          	addi	s6,s6,1802 # 80008200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    80001afe:	8aa6                	mv	s5,s1
    80001b00:	00006a17          	auipc	s4,0x6
    80001b04:	500a0a13          	addi	s4,s4,1280 # 80008000 <etext>
    80001b08:	04000937          	lui	s2,0x4000
    80001b0c:	197d                	addi	s2,s2,-1
    80001b0e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b10:	00015997          	auipc	s3,0x15
    80001b14:	5c098993          	addi	s3,s3,1472 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001b18:	85da                	mv	a1,s6
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	038080e7          	jalr	56(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b24:	415487b3          	sub	a5,s1,s5
    80001b28:	878d                	srai	a5,a5,0x3
    80001b2a:	000a3703          	ld	a4,0(s4)
    80001b2e:	02e787b3          	mul	a5,a5,a4
    80001b32:	2785                	addiw	a5,a5,1
    80001b34:	00d7979b          	slliw	a5,a5,0xd
    80001b38:	40f907b3          	sub	a5,s2,a5
    80001b3c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b3e:	16848493          	addi	s1,s1,360
    80001b42:	fd349be3          	bne	s1,s3,80001b18 <procinit+0x6e>
}
    80001b46:	70e2                	ld	ra,56(sp)
    80001b48:	7442                	ld	s0,48(sp)
    80001b4a:	74a2                	ld	s1,40(sp)
    80001b4c:	7902                	ld	s2,32(sp)
    80001b4e:	69e2                	ld	s3,24(sp)
    80001b50:	6a42                	ld	s4,16(sp)
    80001b52:	6aa2                	ld	s5,8(sp)
    80001b54:	6b02                	ld	s6,0(sp)
    80001b56:	6121                	addi	sp,sp,64
    80001b58:	8082                	ret

0000000080001b5a <cpuid>:
{
    80001b5a:	1141                	addi	sp,sp,-16
    80001b5c:	e422                	sd	s0,8(sp)
    80001b5e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b60:	8512                	mv	a0,tp
  return id;
}
    80001b62:	2501                	sext.w	a0,a0
    80001b64:	6422                	ld	s0,8(sp)
    80001b66:	0141                	addi	sp,sp,16
    80001b68:	8082                	ret

0000000080001b6a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b6a:	1141                	addi	sp,sp,-16
    80001b6c:	e422                	sd	s0,8(sp)
    80001b6e:	0800                	addi	s0,sp,16
    80001b70:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b72:	2781                	sext.w	a5,a5
    80001b74:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b76:	0000f517          	auipc	a0,0xf
    80001b7a:	72a50513          	addi	a0,a0,1834 # 800112a0 <cpus>
    80001b7e:	953e                	add	a0,a0,a5
    80001b80:	6422                	ld	s0,8(sp)
    80001b82:	0141                	addi	sp,sp,16
    80001b84:	8082                	ret

0000000080001b86 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	1000                	addi	s0,sp,32
  push_off();
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	008080e7          	jalr	8(ra) # 80000b98 <push_off>
    80001b98:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b9a:	2781                	sext.w	a5,a5
    80001b9c:	079e                	slli	a5,a5,0x7
    80001b9e:	0000f717          	auipc	a4,0xf
    80001ba2:	70270713          	addi	a4,a4,1794 # 800112a0 <cpus>
    80001ba6:	97ba                	add	a5,a5,a4
    80001ba8:	6384                	ld	s1,0(a5)
  pop_off();
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	08e080e7          	jalr	142(ra) # 80000c38 <pop_off>
  return p;
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret

0000000080001bbe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bbe:	1141                	addi	sp,sp,-16
    80001bc0:	e406                	sd	ra,8(sp)
    80001bc2:	e022                	sd	s0,0(sp)
    80001bc4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	fc0080e7          	jalr	-64(ra) # 80001b86 <myproc>
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	0ca080e7          	jalr	202(ra) # 80000c98 <release>

  if (first) {
    80001bd6:	00007797          	auipc	a5,0x7
    80001bda:	c5a7a783          	lw	a5,-934(a5) # 80008830 <first.1695>
    80001bde:	eb89                	bnez	a5,80001bf0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001be0:	00001097          	auipc	ra,0x1
    80001be4:	b26080e7          	jalr	-1242(ra) # 80002706 <usertrapret>
}
    80001be8:	60a2                	ld	ra,8(sp)
    80001bea:	6402                	ld	s0,0(sp)
    80001bec:	0141                	addi	sp,sp,16
    80001bee:	8082                	ret
    first = 0;
    80001bf0:	00007797          	auipc	a5,0x7
    80001bf4:	c407a023          	sw	zero,-960(a5) # 80008830 <first.1695>
    fsinit(ROOTDEV);
    80001bf8:	4505                	li	a0,1
    80001bfa:	00002097          	auipc	ra,0x2
    80001bfe:	898080e7          	jalr	-1896(ra) # 80003492 <fsinit>
    80001c02:	bff9                	j	80001be0 <forkret+0x22>

0000000080001c04 <allocpid>:
allocpid() {
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c10:	00010917          	auipc	s2,0x10
    80001c14:	a9090913          	addi	s2,s2,-1392 # 800116a0 <pid_lock>
    80001c18:	854a                	mv	a0,s2
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fca080e7          	jalr	-54(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001c22:	00007797          	auipc	a5,0x7
    80001c26:	c1278793          	addi	a5,a5,-1006 # 80008834 <nextpid>
    80001c2a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c2c:	0014871b          	addiw	a4,s1,1
    80001c30:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c32:	854a                	mv	a0,s2
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	064080e7          	jalr	100(ra) # 80000c98 <release>
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <proc_pagetable>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	e04a                	sd	s2,0(sp)
    80001c54:	1000                	addi	s0,sp,32
    80001c56:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	6e2080e7          	jalr	1762(ra) # 8000133a <uvmcreate>
    80001c60:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c62:	c121                	beqz	a0,80001ca2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c64:	4729                	li	a4,10
    80001c66:	00005697          	auipc	a3,0x5
    80001c6a:	39a68693          	addi	a3,a3,922 # 80007000 <_trampoline>
    80001c6e:	6605                	lui	a2,0x1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	438080e7          	jalr	1080(ra) # 800010b0 <mappages>
    80001c80:	02054863          	bltz	a0,80001cb0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c84:	4719                	li	a4,6
    80001c86:	05893683          	ld	a3,88(s2)
    80001c8a:	6605                	lui	a2,0x1
    80001c8c:	020005b7          	lui	a1,0x2000
    80001c90:	15fd                	addi	a1,a1,-1
    80001c92:	05b6                	slli	a1,a1,0xd
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	41a080e7          	jalr	1050(ra) # 800010b0 <mappages>
    80001c9e:	02054163          	bltz	a0,80001cc0 <proc_pagetable+0x76>
}
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret
    uvmfree(pagetable, 0);
    80001cb0:	4581                	li	a1,0
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	882080e7          	jalr	-1918(ra) # 80001536 <uvmfree>
    return 0;
    80001cbc:	4481                	li	s1,0
    80001cbe:	b7d5                	j	80001ca2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc0:	4681                	li	a3,0
    80001cc2:	4605                	li	a2,1
    80001cc4:	040005b7          	lui	a1,0x4000
    80001cc8:	15fd                	addi	a1,a1,-1
    80001cca:	05b2                	slli	a1,a1,0xc
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	5a8080e7          	jalr	1448(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cd6:	4581                	li	a1,0
    80001cd8:	8526                	mv	a0,s1
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	85c080e7          	jalr	-1956(ra) # 80001536 <uvmfree>
    return 0;
    80001ce2:	4481                	li	s1,0
    80001ce4:	bf7d                	j	80001ca2 <proc_pagetable+0x58>

0000000080001ce6 <proc_freepagetable>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	e04a                	sd	s2,0(sp)
    80001cf0:	1000                	addi	s0,sp,32
    80001cf2:	84aa                	mv	s1,a0
    80001cf4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf6:	4681                	li	a3,0
    80001cf8:	4605                	li	a2,1
    80001cfa:	040005b7          	lui	a1,0x4000
    80001cfe:	15fd                	addi	a1,a1,-1
    80001d00:	05b2                	slli	a1,a1,0xc
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	574080e7          	jalr	1396(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d0a:	4681                	li	a3,0
    80001d0c:	4605                	li	a2,1
    80001d0e:	020005b7          	lui	a1,0x2000
    80001d12:	15fd                	addi	a1,a1,-1
    80001d14:	05b6                	slli	a1,a1,0xd
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	55e080e7          	jalr	1374(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d20:	85ca                	mv	a1,s2
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	812080e7          	jalr	-2030(ra) # 80001536 <uvmfree>
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <freeproc>:
{
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	1000                	addi	s0,sp,32
    80001d42:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d44:	6d28                	ld	a0,88(a0)
    80001d46:	c509                	beqz	a0,80001d50 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	cb0080e7          	jalr	-848(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d50:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d54:	68a8                	ld	a0,80(s1)
    80001d56:	c511                	beqz	a0,80001d62 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d58:	64ac                	ld	a1,72(s1)
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	f8c080e7          	jalr	-116(ra) # 80001ce6 <proc_freepagetable>
  p->pagetable = 0;
    80001d62:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d66:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d6a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d6e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d72:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d76:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d7a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d7e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d82:	0004ac23          	sw	zero,24(s1)
}
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret

0000000080001d90 <allocproc>:
{
    80001d90:	1101                	addi	sp,sp,-32
    80001d92:	ec06                	sd	ra,24(sp)
    80001d94:	e822                	sd	s0,16(sp)
    80001d96:	e426                	sd	s1,8(sp)
    80001d98:	e04a                	sd	s2,0(sp)
    80001d9a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d9c:	00010497          	auipc	s1,0x10
    80001da0:	93448493          	addi	s1,s1,-1740 # 800116d0 <proc>
    80001da4:	00015917          	auipc	s2,0x15
    80001da8:	32c90913          	addi	s2,s2,812 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	e36080e7          	jalr	-458(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001db6:	4c9c                	lw	a5,24(s1)
    80001db8:	cf81                	beqz	a5,80001dd0 <allocproc+0x40>
      release(&p->lock);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	edc080e7          	jalr	-292(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dc4:	16848493          	addi	s1,s1,360
    80001dc8:	ff2492e3          	bne	s1,s2,80001dac <allocproc+0x1c>
  return 0;
    80001dcc:	4481                	li	s1,0
    80001dce:	a889                	j	80001e20 <allocproc+0x90>
  p->pid = allocpid();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e34080e7          	jalr	-460(ra) # 80001c04 <allocpid>
    80001dd8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dda:	4785                	li	a5,1
    80001ddc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	d16080e7          	jalr	-746(ra) # 80000af4 <kalloc>
    80001de6:	892a                	mv	s2,a0
    80001de8:	eca8                	sd	a0,88(s1)
    80001dea:	c131                	beqz	a0,80001e2e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e5c080e7          	jalr	-420(ra) # 80001c4a <proc_pagetable>
    80001df6:	892a                	mv	s2,a0
    80001df8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dfa:	c531                	beqz	a0,80001e46 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001dfc:	07000613          	li	a2,112
    80001e00:	4581                	li	a1,0
    80001e02:	06048513          	addi	a0,s1,96
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	eda080e7          	jalr	-294(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001e0e:	00000797          	auipc	a5,0x0
    80001e12:	db078793          	addi	a5,a5,-592 # 80001bbe <forkret>
    80001e16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e18:	60bc                	ld	a5,64(s1)
    80001e1a:	6705                	lui	a4,0x1
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	f4bc                	sd	a5,104(s1)
}
    80001e20:	8526                	mv	a0,s1
    80001e22:	60e2                	ld	ra,24(sp)
    80001e24:	6442                	ld	s0,16(sp)
    80001e26:	64a2                	ld	s1,8(sp)
    80001e28:	6902                	ld	s2,0(sp)
    80001e2a:	6105                	addi	sp,sp,32
    80001e2c:	8082                	ret
    freeproc(p);
    80001e2e:	8526                	mv	a0,s1
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	f08080e7          	jalr	-248(ra) # 80001d38 <freeproc>
    release(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e5e080e7          	jalr	-418(ra) # 80000c98 <release>
    return 0;
    80001e42:	84ca                	mv	s1,s2
    80001e44:	bff1                	j	80001e20 <allocproc+0x90>
    freeproc(p);
    80001e46:	8526                	mv	a0,s1
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	ef0080e7          	jalr	-272(ra) # 80001d38 <freeproc>
    release(&p->lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>
    return 0;
    80001e5a:	84ca                	mv	s1,s2
    80001e5c:	b7d1                	j	80001e20 <allocproc+0x90>

0000000080001e5e <userinit>:
{
    80001e5e:	1101                	addi	sp,sp,-32
    80001e60:	ec06                	sd	ra,24(sp)
    80001e62:	e822                	sd	s0,16(sp)
    80001e64:	e426                	sd	s1,8(sp)
    80001e66:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	f28080e7          	jalr	-216(ra) # 80001d90 <allocproc>
    80001e70:	84aa                	mv	s1,a0
  initproc = p;
    80001e72:	00007797          	auipc	a5,0x7
    80001e76:	1aa7bf23          	sd	a0,446(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e7a:	03400613          	li	a2,52
    80001e7e:	00007597          	auipc	a1,0x7
    80001e82:	9c258593          	addi	a1,a1,-1598 # 80008840 <initcode>
    80001e86:	6928                	ld	a0,80(a0)
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	4e0080e7          	jalr	1248(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001e90:	6785                	lui	a5,0x1
    80001e92:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e94:	6cb8                	ld	a4,88(s1)
    80001e96:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e9a:	6cb8                	ld	a4,88(s1)
    80001e9c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9e:	4641                	li	a2,16
    80001ea0:	00006597          	auipc	a1,0x6
    80001ea4:	36858593          	addi	a1,a1,872 # 80008208 <digits+0x1c8>
    80001ea8:	15848513          	addi	a0,s1,344
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	f86080e7          	jalr	-122(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001eb4:	00006517          	auipc	a0,0x6
    80001eb8:	36450513          	addi	a0,a0,868 # 80008218 <digits+0x1d8>
    80001ebc:	00002097          	auipc	ra,0x2
    80001ec0:	004080e7          	jalr	4(ra) # 80003ec0 <namei>
    80001ec4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec8:	478d                	li	a5,3
    80001eca:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dca080e7          	jalr	-566(ra) # 80000c98 <release>
}
    80001ed6:	60e2                	ld	ra,24(sp)
    80001ed8:	6442                	ld	s0,16(sp)
    80001eda:	64a2                	ld	s1,8(sp)
    80001edc:	6105                	addi	sp,sp,32
    80001ede:	8082                	ret

0000000080001ee0 <growproc>:
{
    80001ee0:	1101                	addi	sp,sp,-32
    80001ee2:	ec06                	sd	ra,24(sp)
    80001ee4:	e822                	sd	s0,16(sp)
    80001ee6:	e426                	sd	s1,8(sp)
    80001ee8:	e04a                	sd	s2,0(sp)
    80001eea:	1000                	addi	s0,sp,32
    80001eec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	c98080e7          	jalr	-872(ra) # 80001b86 <myproc>
    80001ef6:	892a                	mv	s2,a0
  sz = p->sz;
    80001ef8:	652c                	ld	a1,72(a0)
    80001efa:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001efe:	00904f63          	bgtz	s1,80001f1c <growproc+0x3c>
  } else if(n < 0){
    80001f02:	0204cc63          	bltz	s1,80001f3a <growproc+0x5a>
  p->sz = sz;
    80001f06:	1602                	slli	a2,a2,0x20
    80001f08:	9201                	srli	a2,a2,0x20
    80001f0a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f0e:	4501                	li	a0,0
}
    80001f10:	60e2                	ld	ra,24(sp)
    80001f12:	6442                	ld	s0,16(sp)
    80001f14:	64a2                	ld	s1,8(sp)
    80001f16:	6902                	ld	s2,0(sp)
    80001f18:	6105                	addi	sp,sp,32
    80001f1a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f1c:	9e25                	addw	a2,a2,s1
    80001f1e:	1602                	slli	a2,a2,0x20
    80001f20:	9201                	srli	a2,a2,0x20
    80001f22:	1582                	slli	a1,a1,0x20
    80001f24:	9181                	srli	a1,a1,0x20
    80001f26:	6928                	ld	a0,80(a0)
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	4fa080e7          	jalr	1274(ra) # 80001422 <uvmalloc>
    80001f30:	0005061b          	sext.w	a2,a0
    80001f34:	fa69                	bnez	a2,80001f06 <growproc+0x26>
      return -1;
    80001f36:	557d                	li	a0,-1
    80001f38:	bfe1                	j	80001f10 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f3a:	9e25                	addw	a2,a2,s1
    80001f3c:	1602                	slli	a2,a2,0x20
    80001f3e:	9201                	srli	a2,a2,0x20
    80001f40:	1582                	slli	a1,a1,0x20
    80001f42:	9181                	srli	a1,a1,0x20
    80001f44:	6928                	ld	a0,80(a0)
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	494080e7          	jalr	1172(ra) # 800013da <uvmdealloc>
    80001f4e:	0005061b          	sext.w	a2,a0
    80001f52:	bf55                	j	80001f06 <growproc+0x26>

0000000080001f54 <fork>:
{
    80001f54:	7179                	addi	sp,sp,-48
    80001f56:	f406                	sd	ra,40(sp)
    80001f58:	f022                	sd	s0,32(sp)
    80001f5a:	ec26                	sd	s1,24(sp)
    80001f5c:	e84a                	sd	s2,16(sp)
    80001f5e:	e44e                	sd	s3,8(sp)
    80001f60:	e052                	sd	s4,0(sp)
    80001f62:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	c22080e7          	jalr	-990(ra) # 80001b86 <myproc>
    80001f6c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	e22080e7          	jalr	-478(ra) # 80001d90 <allocproc>
    80001f76:	10050b63          	beqz	a0,8000208c <fork+0x138>
    80001f7a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f7c:	04893603          	ld	a2,72(s2)
    80001f80:	692c                	ld	a1,80(a0)
    80001f82:	05093503          	ld	a0,80(s2)
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	5e8080e7          	jalr	1512(ra) # 8000156e <uvmcopy>
    80001f8e:	04054663          	bltz	a0,80001fda <fork+0x86>
  np->sz = p->sz;
    80001f92:	04893783          	ld	a5,72(s2)
    80001f96:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f9a:	05893683          	ld	a3,88(s2)
    80001f9e:	87b6                	mv	a5,a3
    80001fa0:	0589b703          	ld	a4,88(s3)
    80001fa4:	12068693          	addi	a3,a3,288
    80001fa8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fac:	6788                	ld	a0,8(a5)
    80001fae:	6b8c                	ld	a1,16(a5)
    80001fb0:	6f90                	ld	a2,24(a5)
    80001fb2:	01073023          	sd	a6,0(a4)
    80001fb6:	e708                	sd	a0,8(a4)
    80001fb8:	eb0c                	sd	a1,16(a4)
    80001fba:	ef10                	sd	a2,24(a4)
    80001fbc:	02078793          	addi	a5,a5,32
    80001fc0:	02070713          	addi	a4,a4,32
    80001fc4:	fed792e3          	bne	a5,a3,80001fa8 <fork+0x54>
  np->trapframe->a0 = 0;
    80001fc8:	0589b783          	ld	a5,88(s3)
    80001fcc:	0607b823          	sd	zero,112(a5)
    80001fd0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fd4:	15000a13          	li	s4,336
    80001fd8:	a03d                	j	80002006 <fork+0xb2>
    freeproc(np);
    80001fda:	854e                	mv	a0,s3
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	d5c080e7          	jalr	-676(ra) # 80001d38 <freeproc>
    release(&np->lock);
    80001fe4:	854e                	mv	a0,s3
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	cb2080e7          	jalr	-846(ra) # 80000c98 <release>
    return -1;
    80001fee:	5a7d                	li	s4,-1
    80001ff0:	a069                	j	8000207a <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ff2:	00002097          	auipc	ra,0x2
    80001ff6:	564080e7          	jalr	1380(ra) # 80004556 <filedup>
    80001ffa:	009987b3          	add	a5,s3,s1
    80001ffe:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002000:	04a1                	addi	s1,s1,8
    80002002:	01448763          	beq	s1,s4,80002010 <fork+0xbc>
    if(p->ofile[i])
    80002006:	009907b3          	add	a5,s2,s1
    8000200a:	6388                	ld	a0,0(a5)
    8000200c:	f17d                	bnez	a0,80001ff2 <fork+0x9e>
    8000200e:	bfcd                	j	80002000 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002010:	15093503          	ld	a0,336(s2)
    80002014:	00001097          	auipc	ra,0x1
    80002018:	6b8080e7          	jalr	1720(ra) # 800036cc <idup>
    8000201c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002020:	4641                	li	a2,16
    80002022:	15890593          	addi	a1,s2,344
    80002026:	15898513          	addi	a0,s3,344
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	e08080e7          	jalr	-504(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002032:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002036:	854e                	mv	a0,s3
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c60080e7          	jalr	-928(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002040:	0000f497          	auipc	s1,0xf
    80002044:	67848493          	addi	s1,s1,1656 # 800116b8 <wait_lock>
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	b9a080e7          	jalr	-1126(ra) # 80000be4 <acquire>
  np->parent = p;
    80002052:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002060:	854e                	mv	a0,s3
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	b82080e7          	jalr	-1150(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000206a:	478d                	li	a5,3
    8000206c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002070:	854e                	mv	a0,s3
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c26080e7          	jalr	-986(ra) # 80000c98 <release>
}
    8000207a:	8552                	mv	a0,s4
    8000207c:	70a2                	ld	ra,40(sp)
    8000207e:	7402                	ld	s0,32(sp)
    80002080:	64e2                	ld	s1,24(sp)
    80002082:	6942                	ld	s2,16(sp)
    80002084:	69a2                	ld	s3,8(sp)
    80002086:	6a02                	ld	s4,0(sp)
    80002088:	6145                	addi	sp,sp,48
    8000208a:	8082                	ret
    return -1;
    8000208c:	5a7d                	li	s4,-1
    8000208e:	b7f5                	j	8000207a <fork+0x126>

0000000080002090 <sched>:
{
    80002090:	7179                	addi	sp,sp,-48
    80002092:	f406                	sd	ra,40(sp)
    80002094:	f022                	sd	s0,32(sp)
    80002096:	ec26                	sd	s1,24(sp)
    80002098:	e84a                	sd	s2,16(sp)
    8000209a:	e44e                	sd	s3,8(sp)
    8000209c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	ae8080e7          	jalr	-1304(ra) # 80001b86 <myproc>
    800020a6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	ac2080e7          	jalr	-1342(ra) # 80000b6a <holding>
    800020b0:	c53d                	beqz	a0,8000211e <sched+0x8e>
    800020b2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	079e                	slli	a5,a5,0x7
    800020b8:	0000f717          	auipc	a4,0xf
    800020bc:	1e870713          	addi	a4,a4,488 # 800112a0 <cpus>
    800020c0:	97ba                	add	a5,a5,a4
    800020c2:	5fb8                	lw	a4,120(a5)
    800020c4:	4785                	li	a5,1
    800020c6:	06f71463          	bne	a4,a5,8000212e <sched+0x9e>
  if(p->state == RUNNING)
    800020ca:	4c98                	lw	a4,24(s1)
    800020cc:	4791                	li	a5,4
    800020ce:	06f70863          	beq	a4,a5,8000213e <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020d8:	ebbd                	bnez	a5,8000214e <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020da:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020dc:	0000f917          	auipc	s2,0xf
    800020e0:	1c490913          	addi	s2,s2,452 # 800112a0 <cpus>
    800020e4:	2781                	sext.w	a5,a5
    800020e6:	079e                	slli	a5,a5,0x7
    800020e8:	97ca                	add	a5,a5,s2
    800020ea:	07c7a983          	lw	s3,124(a5)
    800020ee:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800020f0:	2581                	sext.w	a1,a1
    800020f2:	059e                	slli	a1,a1,0x7
    800020f4:	05a1                	addi	a1,a1,8
    800020f6:	95ca                	add	a1,a1,s2
    800020f8:	06048513          	addi	a0,s1,96
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	560080e7          	jalr	1376(ra) # 8000265c <swtch>
    80002104:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002106:	2781                	sext.w	a5,a5
    80002108:	079e                	slli	a5,a5,0x7
    8000210a:	993e                	add	s2,s2,a5
    8000210c:	07392e23          	sw	s3,124(s2)
}
    80002110:	70a2                	ld	ra,40(sp)
    80002112:	7402                	ld	s0,32(sp)
    80002114:	64e2                	ld	s1,24(sp)
    80002116:	6942                	ld	s2,16(sp)
    80002118:	69a2                	ld	s3,8(sp)
    8000211a:	6145                	addi	sp,sp,48
    8000211c:	8082                	ret
    panic("sched p->lock");
    8000211e:	00006517          	auipc	a0,0x6
    80002122:	10250513          	addi	a0,a0,258 # 80008220 <digits+0x1e0>
    80002126:	ffffe097          	auipc	ra,0xffffe
    8000212a:	418080e7          	jalr	1048(ra) # 8000053e <panic>
    panic("sched locks");
    8000212e:	00006517          	auipc	a0,0x6
    80002132:	10250513          	addi	a0,a0,258 # 80008230 <digits+0x1f0>
    80002136:	ffffe097          	auipc	ra,0xffffe
    8000213a:	408080e7          	jalr	1032(ra) # 8000053e <panic>
    panic("sched running");
    8000213e:	00006517          	auipc	a0,0x6
    80002142:	10250513          	addi	a0,a0,258 # 80008240 <digits+0x200>
    80002146:	ffffe097          	auipc	ra,0xffffe
    8000214a:	3f8080e7          	jalr	1016(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000214e:	00006517          	auipc	a0,0x6
    80002152:	10250513          	addi	a0,a0,258 # 80008250 <digits+0x210>
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	3e8080e7          	jalr	1000(ra) # 8000053e <panic>

000000008000215e <yield>:
{
    8000215e:	1101                	addi	sp,sp,-32
    80002160:	ec06                	sd	ra,24(sp)
    80002162:	e822                	sd	s0,16(sp)
    80002164:	e426                	sd	s1,8(sp)
    80002166:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	a1e080e7          	jalr	-1506(ra) # 80001b86 <myproc>
    80002170:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a72080e7          	jalr	-1422(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000217a:	478d                	li	a5,3
    8000217c:	cc9c                	sw	a5,24(s1)
  sched();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	f12080e7          	jalr	-238(ra) # 80002090 <sched>
  release(&p->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	b10080e7          	jalr	-1264(ra) # 80000c98 <release>
}
    80002190:	60e2                	ld	ra,24(sp)
    80002192:	6442                	ld	s0,16(sp)
    80002194:	64a2                	ld	s1,8(sp)
    80002196:	6105                	addi	sp,sp,32
    80002198:	8082                	ret

000000008000219a <pause_sys>:
{
    8000219a:	1141                	addi	sp,sp,-16
    8000219c:	e406                	sd	ra,8(sp)
    8000219e:	e022                	sd	s0,0(sp)
    800021a0:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    800021a2:	0025179b          	slliw	a5,a0,0x2
    800021a6:	9fa9                	addw	a5,a5,a0
    800021a8:	0017979b          	slliw	a5,a5,0x1
    800021ac:	00007517          	auipc	a0,0x7
    800021b0:	e8c52503          	lw	a0,-372(a0) # 80009038 <ticks>
    800021b4:	9fa9                	addw	a5,a5,a0
    800021b6:	00007717          	auipc	a4,0x7
    800021ba:	e6f72923          	sw	a5,-398(a4) # 80009028 <finish>
  yield();
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	fa0080e7          	jalr	-96(ra) # 8000215e <yield>
}
    800021c6:	4501                	li	a0,0
    800021c8:	60a2                	ld	ra,8(sp)
    800021ca:	6402                	ld	s0,0(sp)
    800021cc:	0141                	addi	sp,sp,16
    800021ce:	8082                	ret

00000000800021d0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
    800021de:	89aa                	mv	s3,a0
    800021e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	9a4080e7          	jalr	-1628(ra) # 80001b86 <myproc>
    800021ea:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9f8080e7          	jalr	-1544(ra) # 80000be4 <acquire>
  release(lk);
    800021f4:	854a                	mv	a0,s2
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021fe:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002202:	4789                	li	a5,2
    80002204:	cc9c                	sw	a5,24(s1)

  sched();
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	e8a080e7          	jalr	-374(ra) # 80002090 <sched>

  // Tidy up.
  p->chan = 0;
    8000220e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a84080e7          	jalr	-1404(ra) # 80000c98 <release>
  acquire(lk);
    8000221c:	854a                	mv	a0,s2
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
}
    80002226:	70a2                	ld	ra,40(sp)
    80002228:	7402                	ld	s0,32(sp)
    8000222a:	64e2                	ld	s1,24(sp)
    8000222c:	6942                	ld	s2,16(sp)
    8000222e:	69a2                	ld	s3,8(sp)
    80002230:	6145                	addi	sp,sp,48
    80002232:	8082                	ret

0000000080002234 <wait>:
{
    80002234:	715d                	addi	sp,sp,-80
    80002236:	e486                	sd	ra,72(sp)
    80002238:	e0a2                	sd	s0,64(sp)
    8000223a:	fc26                	sd	s1,56(sp)
    8000223c:	f84a                	sd	s2,48(sp)
    8000223e:	f44e                	sd	s3,40(sp)
    80002240:	f052                	sd	s4,32(sp)
    80002242:	ec56                	sd	s5,24(sp)
    80002244:	e85a                	sd	s6,16(sp)
    80002246:	e45e                	sd	s7,8(sp)
    80002248:	e062                	sd	s8,0(sp)
    8000224a:	0880                	addi	s0,sp,80
    8000224c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	938080e7          	jalr	-1736(ra) # 80001b86 <myproc>
    80002256:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002258:	0000f517          	auipc	a0,0xf
    8000225c:	46050513          	addi	a0,a0,1120 # 800116b8 <wait_lock>
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	984080e7          	jalr	-1660(ra) # 80000be4 <acquire>
    havekids = 0;
    80002268:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000226a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000226c:	00015997          	auipc	s3,0x15
    80002270:	e6498993          	addi	s3,s3,-412 # 800170d0 <tickslock>
        havekids = 1;
    80002274:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002276:	0000fc17          	auipc	s8,0xf
    8000227a:	442c0c13          	addi	s8,s8,1090 # 800116b8 <wait_lock>
    havekids = 0;
    8000227e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002280:	0000f497          	auipc	s1,0xf
    80002284:	45048493          	addi	s1,s1,1104 # 800116d0 <proc>
    80002288:	a0bd                	j	800022f6 <wait+0xc2>
          pid = np->pid;
    8000228a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000228e:	000b0e63          	beqz	s6,800022aa <wait+0x76>
    80002292:	4691                	li	a3,4
    80002294:	02c48613          	addi	a2,s1,44
    80002298:	85da                	mv	a1,s6
    8000229a:	05093503          	ld	a0,80(s2)
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	3d4080e7          	jalr	980(ra) # 80001672 <copyout>
    800022a6:	02054563          	bltz	a0,800022d0 <wait+0x9c>
          freeproc(np);
    800022aa:	8526                	mv	a0,s1
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	a8c080e7          	jalr	-1396(ra) # 80001d38 <freeproc>
          release(&np->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
          release(&wait_lock);
    800022be:	0000f517          	auipc	a0,0xf
    800022c2:	3fa50513          	addi	a0,a0,1018 # 800116b8 <wait_lock>
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
          return pid;
    800022ce:	a09d                	j	80002334 <wait+0x100>
            release(&np->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
            release(&wait_lock);
    800022da:	0000f517          	auipc	a0,0xf
    800022de:	3de50513          	addi	a0,a0,990 # 800116b8 <wait_lock>
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9b6080e7          	jalr	-1610(ra) # 80000c98 <release>
            return -1;
    800022ea:	59fd                	li	s3,-1
    800022ec:	a0a1                	j	80002334 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800022ee:	16848493          	addi	s1,s1,360
    800022f2:	03348463          	beq	s1,s3,8000231a <wait+0xe6>
      if(np->parent == p){
    800022f6:	7c9c                	ld	a5,56(s1)
    800022f8:	ff279be3          	bne	a5,s2,800022ee <wait+0xba>
        acquire(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8e6080e7          	jalr	-1818(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002306:	4c9c                	lw	a5,24(s1)
    80002308:	f94781e3          	beq	a5,s4,8000228a <wait+0x56>
        release(&np->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
        havekids = 1;
    80002316:	8756                	mv	a4,s5
    80002318:	bfd9                	j	800022ee <wait+0xba>
    if(!havekids || p->killed){
    8000231a:	c701                	beqz	a4,80002322 <wait+0xee>
    8000231c:	02892783          	lw	a5,40(s2)
    80002320:	c79d                	beqz	a5,8000234e <wait+0x11a>
      release(&wait_lock);
    80002322:	0000f517          	auipc	a0,0xf
    80002326:	39650513          	addi	a0,a0,918 # 800116b8 <wait_lock>
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	96e080e7          	jalr	-1682(ra) # 80000c98 <release>
      return -1;
    80002332:	59fd                	li	s3,-1
}
    80002334:	854e                	mv	a0,s3
    80002336:	60a6                	ld	ra,72(sp)
    80002338:	6406                	ld	s0,64(sp)
    8000233a:	74e2                	ld	s1,56(sp)
    8000233c:	7942                	ld	s2,48(sp)
    8000233e:	79a2                	ld	s3,40(sp)
    80002340:	7a02                	ld	s4,32(sp)
    80002342:	6ae2                	ld	s5,24(sp)
    80002344:	6b42                	ld	s6,16(sp)
    80002346:	6ba2                	ld	s7,8(sp)
    80002348:	6c02                	ld	s8,0(sp)
    8000234a:	6161                	addi	sp,sp,80
    8000234c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000234e:	85e2                	mv	a1,s8
    80002350:	854a                	mv	a0,s2
    80002352:	00000097          	auipc	ra,0x0
    80002356:	e7e080e7          	jalr	-386(ra) # 800021d0 <sleep>
    havekids = 0;
    8000235a:	b715                	j	8000227e <wait+0x4a>

000000008000235c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000235c:	7139                	addi	sp,sp,-64
    8000235e:	fc06                	sd	ra,56(sp)
    80002360:	f822                	sd	s0,48(sp)
    80002362:	f426                	sd	s1,40(sp)
    80002364:	f04a                	sd	s2,32(sp)
    80002366:	ec4e                	sd	s3,24(sp)
    80002368:	e852                	sd	s4,16(sp)
    8000236a:	e456                	sd	s5,8(sp)
    8000236c:	0080                	addi	s0,sp,64
    8000236e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002370:	0000f497          	auipc	s1,0xf
    80002374:	36048493          	addi	s1,s1,864 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002378:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000237a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000237c:	00015917          	auipc	s2,0x15
    80002380:	d5490913          	addi	s2,s2,-684 # 800170d0 <tickslock>
    80002384:	a821                	j	8000239c <wakeup+0x40>
        p->state = RUNNABLE;
    80002386:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002394:	16848493          	addi	s1,s1,360
    80002398:	03248463          	beq	s1,s2,800023c0 <wakeup+0x64>
    if(p != myproc()){
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	7ea080e7          	jalr	2026(ra) # 80001b86 <myproc>
    800023a4:	fea488e3          	beq	s1,a0,80002394 <wakeup+0x38>
      acquire(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023b2:	4c9c                	lw	a5,24(s1)
    800023b4:	fd379be3          	bne	a5,s3,8000238a <wakeup+0x2e>
    800023b8:	709c                	ld	a5,32(s1)
    800023ba:	fd4798e3          	bne	a5,s4,8000238a <wakeup+0x2e>
    800023be:	b7e1                	j	80002386 <wakeup+0x2a>
    }
  }
}
    800023c0:	70e2                	ld	ra,56(sp)
    800023c2:	7442                	ld	s0,48(sp)
    800023c4:	74a2                	ld	s1,40(sp)
    800023c6:	7902                	ld	s2,32(sp)
    800023c8:	69e2                	ld	s3,24(sp)
    800023ca:	6a42                	ld	s4,16(sp)
    800023cc:	6aa2                	ld	s5,8(sp)
    800023ce:	6121                	addi	sp,sp,64
    800023d0:	8082                	ret

00000000800023d2 <reparent>:
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	e052                	sd	s4,0(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e4:	0000f497          	auipc	s1,0xf
    800023e8:	2ec48493          	addi	s1,s1,748 # 800116d0 <proc>
      pp->parent = initproc;
    800023ec:	00007a17          	auipc	s4,0x7
    800023f0:	c44a0a13          	addi	s4,s4,-956 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f4:	00015997          	auipc	s3,0x15
    800023f8:	cdc98993          	addi	s3,s3,-804 # 800170d0 <tickslock>
    800023fc:	a029                	j	80002406 <reparent+0x34>
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	01348d63          	beq	s1,s3,8000241c <reparent+0x4a>
    if(pp->parent == p){
    80002406:	7c9c                	ld	a5,56(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <reparent+0x2c>
      pp->parent = initproc;
    8000240c:	000a3503          	ld	a0,0(s4)
    80002410:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002412:	00000097          	auipc	ra,0x0
    80002416:	f4a080e7          	jalr	-182(ra) # 8000235c <wakeup>
    8000241a:	b7d5                	j	800023fe <reparent+0x2c>
}
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6a02                	ld	s4,0(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret

000000008000242c <exit>:
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	e052                	sd	s4,0(sp)
    8000243a:	1800                	addi	s0,sp,48
    8000243c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	748080e7          	jalr	1864(ra) # 80001b86 <myproc>
    80002446:	89aa                	mv	s3,a0
  if(p == initproc)
    80002448:	00007797          	auipc	a5,0x7
    8000244c:	be87b783          	ld	a5,-1048(a5) # 80009030 <initproc>
    80002450:	0d050493          	addi	s1,a0,208
    80002454:	15050913          	addi	s2,a0,336
    80002458:	02a79363          	bne	a5,a0,8000247e <exit+0x52>
    panic("init exiting");
    8000245c:	00006517          	auipc	a0,0x6
    80002460:	e0c50513          	addi	a0,a0,-500 # 80008268 <digits+0x228>
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	0da080e7          	jalr	218(ra) # 8000053e <panic>
      fileclose(f);
    8000246c:	00002097          	auipc	ra,0x2
    80002470:	13c080e7          	jalr	316(ra) # 800045a8 <fileclose>
      p->ofile[fd] = 0;
    80002474:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002478:	04a1                	addi	s1,s1,8
    8000247a:	01248563          	beq	s1,s2,80002484 <exit+0x58>
    if(p->ofile[fd]){
    8000247e:	6088                	ld	a0,0(s1)
    80002480:	f575                	bnez	a0,8000246c <exit+0x40>
    80002482:	bfdd                	j	80002478 <exit+0x4c>
  begin_op();
    80002484:	00002097          	auipc	ra,0x2
    80002488:	c58080e7          	jalr	-936(ra) # 800040dc <begin_op>
  iput(p->cwd);
    8000248c:	1509b503          	ld	a0,336(s3)
    80002490:	00001097          	auipc	ra,0x1
    80002494:	434080e7          	jalr	1076(ra) # 800038c4 <iput>
  end_op();
    80002498:	00002097          	auipc	ra,0x2
    8000249c:	cc4080e7          	jalr	-828(ra) # 8000415c <end_op>
  p->cwd = 0;
    800024a0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024a4:	0000f497          	auipc	s1,0xf
    800024a8:	21448493          	addi	s1,s1,532 # 800116b8 <wait_lock>
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
  reparent(p);
    800024b6:	854e                	mv	a0,s3
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	f1a080e7          	jalr	-230(ra) # 800023d2 <reparent>
  wakeup(p->parent);
    800024c0:	0389b503          	ld	a0,56(s3)
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	e98080e7          	jalr	-360(ra) # 8000235c <wakeup>
  acquire(&p->lock);
    800024cc:	854e                	mv	a0,s3
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
  p->xstate = status;
    800024d6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024da:	4795                	li	a5,5
    800024dc:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	7b6080e7          	jalr	1974(ra) # 80000c98 <release>
  sched();
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	ba6080e7          	jalr	-1114(ra) # 80002090 <sched>
  panic("zombie exit");
    800024f2:	00006517          	auipc	a0,0x6
    800024f6:	d8650513          	addi	a0,a0,-634 # 80008278 <digits+0x238>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	044080e7          	jalr	68(ra) # 8000053e <panic>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	66c080e7          	jalr	1644(ra) # 80001b86 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	146080e7          	jalr	326(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	7f4080e7          	jalr	2036(ra) # 80000d40 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	616080e7          	jalr	1558(ra) # 80001b86 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	17c080e7          	jalr	380(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	79e080e7          	jalr	1950(ra) # 80000d40 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800080c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbc080e7          	jalr	-68(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	25448493          	addi	s1,s1,596 # 80011828 <proc+0x158>
    800025dc:	00015917          	auipc	s2,0x15
    800025e0:	c4c90913          	addi	s2,s2,-948 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	addi	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	ccab8b93          	addi	s7,s7,-822 # 800082c8 <states.1725>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7a080e7          	jalr	-134(ra) # 80000588 <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f70080e7          	jalr	-144(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	16848493          	addi	s1,s1,360
    80002624:	03248163          	beq	s1,s2,80002646 <procdump+0x98>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	1782                	slli	a5,a5,0x20
    80002638:	9381                	srli	a5,a5,0x20
    8000263a:	078e                	slli	a5,a5,0x3
    8000263c:	97de                	add	a5,a5,s7
    8000263e:	6390                	ld	a2,0(a5)
    80002640:	f661                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002642:	864e                	mv	a2,s3
    80002644:	b7d1                	j	80002608 <procdump+0x5a>
  }
}
    80002646:	60a6                	ld	ra,72(sp)
    80002648:	6406                	ld	s0,64(sp)
    8000264a:	74e2                	ld	s1,56(sp)
    8000264c:	7942                	ld	s2,48(sp)
    8000264e:	79a2                	ld	s3,40(sp)
    80002650:	7a02                	ld	s4,32(sp)
    80002652:	6ae2                	ld	s5,24(sp)
    80002654:	6b42                	ld	s6,16(sp)
    80002656:	6ba2                	ld	s7,8(sp)
    80002658:	6161                	addi	sp,sp,80
    8000265a:	8082                	ret

000000008000265c <swtch>:
    8000265c:	00153023          	sd	ra,0(a0)
    80002660:	00253423          	sd	sp,8(a0)
    80002664:	e900                	sd	s0,16(a0)
    80002666:	ed04                	sd	s1,24(a0)
    80002668:	03253023          	sd	s2,32(a0)
    8000266c:	03353423          	sd	s3,40(a0)
    80002670:	03453823          	sd	s4,48(a0)
    80002674:	03553c23          	sd	s5,56(a0)
    80002678:	05653023          	sd	s6,64(a0)
    8000267c:	05753423          	sd	s7,72(a0)
    80002680:	05853823          	sd	s8,80(a0)
    80002684:	05953c23          	sd	s9,88(a0)
    80002688:	07a53023          	sd	s10,96(a0)
    8000268c:	07b53423          	sd	s11,104(a0)
    80002690:	0005b083          	ld	ra,0(a1)
    80002694:	0085b103          	ld	sp,8(a1)
    80002698:	6980                	ld	s0,16(a1)
    8000269a:	6d84                	ld	s1,24(a1)
    8000269c:	0205b903          	ld	s2,32(a1)
    800026a0:	0285b983          	ld	s3,40(a1)
    800026a4:	0305ba03          	ld	s4,48(a1)
    800026a8:	0385ba83          	ld	s5,56(a1)
    800026ac:	0405bb03          	ld	s6,64(a1)
    800026b0:	0485bb83          	ld	s7,72(a1)
    800026b4:	0505bc03          	ld	s8,80(a1)
    800026b8:	0585bc83          	ld	s9,88(a1)
    800026bc:	0605bd03          	ld	s10,96(a1)
    800026c0:	0685bd83          	ld	s11,104(a1)
    800026c4:	8082                	ret

00000000800026c6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e406                	sd	ra,8(sp)
    800026ca:	e022                	sd	s0,0(sp)
    800026cc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026ce:	00006597          	auipc	a1,0x6
    800026d2:	c2a58593          	addi	a1,a1,-982 # 800082f8 <states.1725+0x30>
    800026d6:	00015517          	auipc	a0,0x15
    800026da:	9fa50513          	addi	a0,a0,-1542 # 800170d0 <tickslock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	476080e7          	jalr	1142(ra) # 80000b54 <initlock>
}
    800026e6:	60a2                	ld	ra,8(sp)
    800026e8:	6402                	ld	s0,0(sp)
    800026ea:	0141                	addi	sp,sp,16
    800026ec:	8082                	ret

00000000800026ee <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ee:	1141                	addi	sp,sp,-16
    800026f0:	e422                	sd	s0,8(sp)
    800026f2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f4:	00003797          	auipc	a5,0x3
    800026f8:	4cc78793          	addi	a5,a5,1228 # 80005bc0 <kernelvec>
    800026fc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002700:	6422                	ld	s0,8(sp)
    80002702:	0141                	addi	sp,sp,16
    80002704:	8082                	ret

0000000080002706 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002706:	1141                	addi	sp,sp,-16
    80002708:	e406                	sd	ra,8(sp)
    8000270a:	e022                	sd	s0,0(sp)
    8000270c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	478080e7          	jalr	1144(ra) # 80001b86 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002716:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002720:	00005617          	auipc	a2,0x5
    80002724:	8e060613          	addi	a2,a2,-1824 # 80007000 <_trampoline>
    80002728:	00005697          	auipc	a3,0x5
    8000272c:	8d868693          	addi	a3,a3,-1832 # 80007000 <_trampoline>
    80002730:	8e91                	sub	a3,a3,a2
    80002732:	040007b7          	lui	a5,0x4000
    80002736:	17fd                	addi	a5,a5,-1
    80002738:	07b2                	slli	a5,a5,0xc
    8000273a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002740:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002742:	180026f3          	csrr	a3,satp
    80002746:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002748:	6d38                	ld	a4,88(a0)
    8000274a:	6134                	ld	a3,64(a0)
    8000274c:	6585                	lui	a1,0x1
    8000274e:	96ae                	add	a3,a3,a1
    80002750:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002752:	6d38                	ld	a4,88(a0)
    80002754:	00000697          	auipc	a3,0x0
    80002758:	13868693          	addi	a3,a3,312 # 8000288c <usertrap>
    8000275c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000275e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002760:	8692                	mv	a3,tp
    80002762:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002764:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002768:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002770:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002774:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002776:	6f18                	ld	a4,24(a4)
    80002778:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277c:	692c                	ld	a1,80(a0)
    8000277e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002780:	00005717          	auipc	a4,0x5
    80002784:	91070713          	addi	a4,a4,-1776 # 80007090 <userret>
    80002788:	8f11                	sub	a4,a4,a2
    8000278a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000278c:	577d                	li	a4,-1
    8000278e:	177e                	slli	a4,a4,0x3f
    80002790:	8dd9                	or	a1,a1,a4
    80002792:	02000537          	lui	a0,0x2000
    80002796:	157d                	addi	a0,a0,-1
    80002798:	0536                	slli	a0,a0,0xd
    8000279a:	9782                	jalr	a5
}
    8000279c:	60a2                	ld	ra,8(sp)
    8000279e:	6402                	ld	s0,0(sp)
    800027a0:	0141                	addi	sp,sp,16
    800027a2:	8082                	ret

00000000800027a4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a4:	1101                	addi	sp,sp,-32
    800027a6:	ec06                	sd	ra,24(sp)
    800027a8:	e822                	sd	s0,16(sp)
    800027aa:	e426                	sd	s1,8(sp)
    800027ac:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ae:	00015497          	auipc	s1,0x15
    800027b2:	92248493          	addi	s1,s1,-1758 # 800170d0 <tickslock>
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	42c080e7          	jalr	1068(ra) # 80000be4 <acquire>
  ticks++;
    800027c0:	00007517          	auipc	a0,0x7
    800027c4:	87850513          	addi	a0,a0,-1928 # 80009038 <ticks>
    800027c8:	411c                	lw	a5,0(a0)
    800027ca:	2785                	addiw	a5,a5,1
    800027cc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	b8e080e7          	jalr	-1138(ra) # 8000235c <wakeup>
  release(&tickslock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4c0080e7          	jalr	1216(ra) # 80000c98 <release>
}
    800027e0:	60e2                	ld	ra,24(sp)
    800027e2:	6442                	ld	s0,16(sp)
    800027e4:	64a2                	ld	s1,8(sp)
    800027e6:	6105                	addi	sp,sp,32
    800027e8:	8082                	ret

00000000800027ea <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ea:	1101                	addi	sp,sp,-32
    800027ec:	ec06                	sd	ra,24(sp)
    800027ee:	e822                	sd	s0,16(sp)
    800027f0:	e426                	sd	s1,8(sp)
    800027f2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027f8:	00074d63          	bltz	a4,80002812 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fc:	57fd                	li	a5,-1
    800027fe:	17fe                	slli	a5,a5,0x3f
    80002800:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002802:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002804:	06f70363          	beq	a4,a5,8000286a <devintr+0x80>
  }
}
    80002808:	60e2                	ld	ra,24(sp)
    8000280a:	6442                	ld	s0,16(sp)
    8000280c:	64a2                	ld	s1,8(sp)
    8000280e:	6105                	addi	sp,sp,32
    80002810:	8082                	ret
     (scause & 0xff) == 9){
    80002812:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002816:	46a5                	li	a3,9
    80002818:	fed792e3          	bne	a5,a3,800027fc <devintr+0x12>
    int irq = plic_claim();
    8000281c:	00003097          	auipc	ra,0x3
    80002820:	4ac080e7          	jalr	1196(ra) # 80005cc8 <plic_claim>
    80002824:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002826:	47a9                	li	a5,10
    80002828:	02f50763          	beq	a0,a5,80002856 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282c:	4785                	li	a5,1
    8000282e:	02f50963          	beq	a0,a5,80002860 <devintr+0x76>
    return 1;
    80002832:	4505                	li	a0,1
    } else if(irq){
    80002834:	d8f1                	beqz	s1,80002808 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002836:	85a6                	mv	a1,s1
    80002838:	00006517          	auipc	a0,0x6
    8000283c:	ac850513          	addi	a0,a0,-1336 # 80008300 <states.1725+0x38>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	d48080e7          	jalr	-696(ra) # 80000588 <printf>
      plic_complete(irq);
    80002848:	8526                	mv	a0,s1
    8000284a:	00003097          	auipc	ra,0x3
    8000284e:	4a2080e7          	jalr	1186(ra) # 80005cec <plic_complete>
    return 1;
    80002852:	4505                	li	a0,1
    80002854:	bf55                	j	80002808 <devintr+0x1e>
      uartintr();
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	152080e7          	jalr	338(ra) # 800009a8 <uartintr>
    8000285e:	b7ed                	j	80002848 <devintr+0x5e>
      virtio_disk_intr();
    80002860:	00004097          	auipc	ra,0x4
    80002864:	96c080e7          	jalr	-1684(ra) # 800061cc <virtio_disk_intr>
    80002868:	b7c5                	j	80002848 <devintr+0x5e>
    if(cpuid() == 0){
    8000286a:	fffff097          	auipc	ra,0xfffff
    8000286e:	2f0080e7          	jalr	752(ra) # 80001b5a <cpuid>
    80002872:	c901                	beqz	a0,80002882 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002874:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002878:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287a:	14479073          	csrw	sip,a5
    return 2;
    8000287e:	4509                	li	a0,2
    80002880:	b761                	j	80002808 <devintr+0x1e>
      clockintr();
    80002882:	00000097          	auipc	ra,0x0
    80002886:	f22080e7          	jalr	-222(ra) # 800027a4 <clockintr>
    8000288a:	b7ed                	j	80002874 <devintr+0x8a>

000000008000288c <usertrap>:
{
    8000288c:	1101                	addi	sp,sp,-32
    8000288e:	ec06                	sd	ra,24(sp)
    80002890:	e822                	sd	s0,16(sp)
    80002892:	e426                	sd	s1,8(sp)
    80002894:	e04a                	sd	s2,0(sp)
    80002896:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002898:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289c:	1007f793          	andi	a5,a5,256
    800028a0:	e3ad                	bnez	a5,80002902 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a2:	00003797          	auipc	a5,0x3
    800028a6:	31e78793          	addi	a5,a5,798 # 80005bc0 <kernelvec>
    800028aa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	2d8080e7          	jalr	728(ra) # 80001b86 <myproc>
    800028b6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ba:	14102773          	csrr	a4,sepc
    800028be:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c4:	47a1                	li	a5,8
    800028c6:	04f71c63          	bne	a4,a5,8000291e <usertrap+0x92>
    if(p->killed)
    800028ca:	551c                	lw	a5,40(a0)
    800028cc:	e3b9                	bnez	a5,80002912 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028ce:	6cb8                	ld	a4,88(s1)
    800028d0:	6f1c                	ld	a5,24(a4)
    800028d2:	0791                	addi	a5,a5,4
    800028d4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028de:	10079073          	csrw	sstatus,a5
    syscall();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	2e0080e7          	jalr	736(ra) # 80002bc2 <syscall>
  if(p->killed)
    800028ea:	549c                	lw	a5,40(s1)
    800028ec:	ebc1                	bnez	a5,8000297c <usertrap+0xf0>
  usertrapret();
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	e18080e7          	jalr	-488(ra) # 80002706 <usertrapret>
}
    800028f6:	60e2                	ld	ra,24(sp)
    800028f8:	6442                	ld	s0,16(sp)
    800028fa:	64a2                	ld	s1,8(sp)
    800028fc:	6902                	ld	s2,0(sp)
    800028fe:	6105                	addi	sp,sp,32
    80002900:	8082                	ret
    panic("usertrap: not from user mode");
    80002902:	00006517          	auipc	a0,0x6
    80002906:	a1e50513          	addi	a0,a0,-1506 # 80008320 <states.1725+0x58>
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>
      exit(-1);
    80002912:	557d                	li	a0,-1
    80002914:	00000097          	auipc	ra,0x0
    80002918:	b18080e7          	jalr	-1256(ra) # 8000242c <exit>
    8000291c:	bf4d                	j	800028ce <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	ecc080e7          	jalr	-308(ra) # 800027ea <devintr>
    80002926:	892a                	mv	s2,a0
    80002928:	c501                	beqz	a0,80002930 <usertrap+0xa4>
  if(p->killed)
    8000292a:	549c                	lw	a5,40(s1)
    8000292c:	c3a1                	beqz	a5,8000296c <usertrap+0xe0>
    8000292e:	a815                	j	80002962 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002930:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002934:	5890                	lw	a2,48(s1)
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a0a50513          	addi	a0,a0,-1526 # 80008340 <states.1725+0x78>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c4a080e7          	jalr	-950(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002946:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000294a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	a2250513          	addi	a0,a0,-1502 # 80008370 <states.1725+0xa8>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	c32080e7          	jalr	-974(ra) # 80000588 <printf>
    p->killed = 1;
    8000295e:	4785                	li	a5,1
    80002960:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002962:	557d                	li	a0,-1
    80002964:	00000097          	auipc	ra,0x0
    80002968:	ac8080e7          	jalr	-1336(ra) # 8000242c <exit>
  if(which_dev == 2)
    8000296c:	4789                	li	a5,2
    8000296e:	f8f910e3          	bne	s2,a5,800028ee <usertrap+0x62>
    yield();
    80002972:	fffff097          	auipc	ra,0xfffff
    80002976:	7ec080e7          	jalr	2028(ra) # 8000215e <yield>
    8000297a:	bf95                	j	800028ee <usertrap+0x62>
  int which_dev = 0;
    8000297c:	4901                	li	s2,0
    8000297e:	b7d5                	j	80002962 <usertrap+0xd6>

0000000080002980 <kerneltrap>:
{
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000299a:	1004f793          	andi	a5,s1,256
    8000299e:	cb85                	beqz	a5,800029ce <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029a6:	ef85                	bnez	a5,800029de <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	e42080e7          	jalr	-446(ra) # 800027ea <devintr>
    800029b0:	cd1d                	beqz	a0,800029ee <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b2:	4789                	li	a5,2
    800029b4:	06f50a63          	beq	a0,a5,80002a28 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10049073          	csrw	sstatus,s1
}
    800029c0:	70a2                	ld	ra,40(sp)
    800029c2:	7402                	ld	s0,32(sp)
    800029c4:	64e2                	ld	s1,24(sp)
    800029c6:	6942                	ld	s2,16(sp)
    800029c8:	69a2                	ld	s3,8(sp)
    800029ca:	6145                	addi	sp,sp,48
    800029cc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9c250513          	addi	a0,a0,-1598 # 80008390 <states.1725+0xc8>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	9da50513          	addi	a0,a0,-1574 # 800083b8 <states.1725+0xf0>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b58080e7          	jalr	-1192(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029ee:	85ce                	mv	a1,s3
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	9e850513          	addi	a0,a0,-1560 # 800083d8 <states.1725+0x110>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b90080e7          	jalr	-1136(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a04:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	9e050513          	addi	a0,a0,-1568 # 800083e8 <states.1725+0x120>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b78080e7          	jalr	-1160(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	9e850513          	addi	a0,a0,-1560 # 80008400 <states.1725+0x138>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b1e080e7          	jalr	-1250(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	15e080e7          	jalr	350(ra) # 80001b86 <myproc>
    80002a30:	d541                	beqz	a0,800029b8 <kerneltrap+0x38>
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	154080e7          	jalr	340(ra) # 80001b86 <myproc>
    80002a3a:	4d18                	lw	a4,24(a0)
    80002a3c:	4791                	li	a5,4
    80002a3e:	f6f71de3          	bne	a4,a5,800029b8 <kerneltrap+0x38>
    yield();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	71c080e7          	jalr	1820(ra) # 8000215e <yield>
    80002a4a:	b7bd                	j	800029b8 <kerneltrap+0x38>

0000000080002a4c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	1000                	addi	s0,sp,32
    80002a56:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	12e080e7          	jalr	302(ra) # 80001b86 <myproc>
  switch (n) {
    80002a60:	4795                	li	a5,5
    80002a62:	0497e163          	bltu	a5,s1,80002aa4 <argraw+0x58>
    80002a66:	048a                	slli	s1,s1,0x2
    80002a68:	00006717          	auipc	a4,0x6
    80002a6c:	9d070713          	addi	a4,a4,-1584 # 80008438 <states.1725+0x170>
    80002a70:	94ba                	add	s1,s1,a4
    80002a72:	409c                	lw	a5,0(s1)
    80002a74:	97ba                	add	a5,a5,a4
    80002a76:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret
    return p->trapframe->a1;
    80002a86:	6d3c                	ld	a5,88(a0)
    80002a88:	7fa8                	ld	a0,120(a5)
    80002a8a:	bfcd                	j	80002a7c <argraw+0x30>
    return p->trapframe->a2;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	63c8                	ld	a0,128(a5)
    80002a90:	b7f5                	j	80002a7c <argraw+0x30>
    return p->trapframe->a3;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	67c8                	ld	a0,136(a5)
    80002a96:	b7dd                	j	80002a7c <argraw+0x30>
    return p->trapframe->a4;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	6bc8                	ld	a0,144(a5)
    80002a9c:	b7c5                	j	80002a7c <argraw+0x30>
    return p->trapframe->a5;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6fc8                	ld	a0,152(a5)
    80002aa2:	bfe9                	j	80002a7c <argraw+0x30>
  panic("argraw");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	96c50513          	addi	a0,a0,-1684 # 80008410 <states.1725+0x148>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>

0000000080002ab4 <fetchaddr>:
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
    80002ac0:	84aa                	mv	s1,a0
    80002ac2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	0c2080e7          	jalr	194(ra) # 80001b86 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002acc:	653c                	ld	a5,72(a0)
    80002ace:	02f4f863          	bgeu	s1,a5,80002afe <fetchaddr+0x4a>
    80002ad2:	00848713          	addi	a4,s1,8
    80002ad6:	02e7e663          	bltu	a5,a4,80002b02 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ada:	46a1                	li	a3,8
    80002adc:	8626                	mv	a2,s1
    80002ade:	85ca                	mv	a1,s2
    80002ae0:	6928                	ld	a0,80(a0)
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	c1c080e7          	jalr	-996(ra) # 800016fe <copyin>
    80002aea:	00a03533          	snez	a0,a0
    80002aee:	40a00533          	neg	a0,a0
}
    80002af2:	60e2                	ld	ra,24(sp)
    80002af4:	6442                	ld	s0,16(sp)
    80002af6:	64a2                	ld	s1,8(sp)
    80002af8:	6902                	ld	s2,0(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret
    return -1;
    80002afe:	557d                	li	a0,-1
    80002b00:	bfcd                	j	80002af2 <fetchaddr+0x3e>
    80002b02:	557d                	li	a0,-1
    80002b04:	b7fd                	j	80002af2 <fetchaddr+0x3e>

0000000080002b06 <fetchstr>:
{
    80002b06:	7179                	addi	sp,sp,-48
    80002b08:	f406                	sd	ra,40(sp)
    80002b0a:	f022                	sd	s0,32(sp)
    80002b0c:	ec26                	sd	s1,24(sp)
    80002b0e:	e84a                	sd	s2,16(sp)
    80002b10:	e44e                	sd	s3,8(sp)
    80002b12:	1800                	addi	s0,sp,48
    80002b14:	892a                	mv	s2,a0
    80002b16:	84ae                	mv	s1,a1
    80002b18:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	06c080e7          	jalr	108(ra) # 80001b86 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b22:	86ce                	mv	a3,s3
    80002b24:	864a                	mv	a2,s2
    80002b26:	85a6                	mv	a1,s1
    80002b28:	6928                	ld	a0,80(a0)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	c60080e7          	jalr	-928(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b32:	00054763          	bltz	a0,80002b40 <fetchstr+0x3a>
  return strlen(buf);
    80002b36:	8526                	mv	a0,s1
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	32c080e7          	jalr	812(ra) # 80000e64 <strlen>
}
    80002b40:	70a2                	ld	ra,40(sp)
    80002b42:	7402                	ld	s0,32(sp)
    80002b44:	64e2                	ld	s1,24(sp)
    80002b46:	6942                	ld	s2,16(sp)
    80002b48:	69a2                	ld	s3,8(sp)
    80002b4a:	6145                	addi	sp,sp,48
    80002b4c:	8082                	ret

0000000080002b4e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
    80002b58:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	ef2080e7          	jalr	-270(ra) # 80002a4c <argraw>
    80002b62:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b64:	4501                	li	a0,0
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	ed0080e7          	jalr	-304(ra) # 80002a4c <argraw>
    80002b84:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b86:	4501                	li	a0,0
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	e04a                	sd	s2,0(sp)
    80002b9c:	1000                	addi	s0,sp,32
    80002b9e:	84ae                	mv	s1,a1
    80002ba0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	eaa080e7          	jalr	-342(ra) # 80002a4c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002baa:	864a                	mv	a2,s2
    80002bac:	85a6                	mv	a1,s1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	f58080e7          	jalr	-168(ra) # 80002b06 <fetchstr>
}
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	64a2                	ld	s1,8(sp)
    80002bbc:	6902                	ld	s2,0(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <syscall>:
[SYS_pause_sys] sys_pause_sys
};

void
syscall(void)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	fb8080e7          	jalr	-72(ra) # 80001b86 <myproc>
    80002bd6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bd8:	05853903          	ld	s2,88(a0)
    80002bdc:	0a893783          	ld	a5,168(s2)
    80002be0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be4:	37fd                	addiw	a5,a5,-1
    80002be6:	4759                	li	a4,22
    80002be8:	00f76f63          	bltu	a4,a5,80002c06 <syscall+0x44>
    80002bec:	00369713          	slli	a4,a3,0x3
    80002bf0:	00006797          	auipc	a5,0x6
    80002bf4:	86078793          	addi	a5,a5,-1952 # 80008450 <syscalls>
    80002bf8:	97ba                	add	a5,a5,a4
    80002bfa:	639c                	ld	a5,0(a5)
    80002bfc:	c789                	beqz	a5,80002c06 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bfe:	9782                	jalr	a5
    80002c00:	06a93823          	sd	a0,112(s2)
    80002c04:	a839                	j	80002c22 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c06:	15848613          	addi	a2,s1,344
    80002c0a:	588c                	lw	a1,48(s1)
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	80c50513          	addi	a0,a0,-2036 # 80008418 <states.1725+0x150>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	974080e7          	jalr	-1676(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c1c:	6cbc                	ld	a5,88(s1)
    80002c1e:	577d                	li	a4,-1
    80002c20:	fbb8                	sd	a4,112(a5)
  }
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	64a2                	ld	s1,8(sp)
    80002c28:	6902                	ld	s2,0(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c36:	fec40593          	addi	a1,s0,-20
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f12080e7          	jalr	-238(ra) # 80002b4e <argint>
    return -1;
    80002c44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c46:	00054963          	bltz	a0,80002c58 <sys_exit+0x2a>
  exit(n);
    80002c4a:	fec42503          	lw	a0,-20(s0)
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	7de080e7          	jalr	2014(ra) # 8000242c <exit>
  return 0;  // not reached
    80002c56:	4781                	li	a5,0
}
    80002c58:	853e                	mv	a0,a5
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	6105                	addi	sp,sp,32
    80002c60:	8082                	ret

0000000080002c62 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c62:	1141                	addi	sp,sp,-16
    80002c64:	e406                	sd	ra,8(sp)
    80002c66:	e022                	sd	s0,0(sp)
    80002c68:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	f1c080e7          	jalr	-228(ra) # 80001b86 <myproc>
}
    80002c72:	5908                	lw	a0,48(a0)
    80002c74:	60a2                	ld	ra,8(sp)
    80002c76:	6402                	ld	s0,0(sp)
    80002c78:	0141                	addi	sp,sp,16
    80002c7a:	8082                	ret

0000000080002c7c <sys_fork>:

uint64
sys_fork(void)
{
    80002c7c:	1141                	addi	sp,sp,-16
    80002c7e:	e406                	sd	ra,8(sp)
    80002c80:	e022                	sd	s0,0(sp)
    80002c82:	0800                	addi	s0,sp,16
  return fork();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	2d0080e7          	jalr	720(ra) # 80001f54 <fork>
}
    80002c8c:	60a2                	ld	ra,8(sp)
    80002c8e:	6402                	ld	s0,0(sp)
    80002c90:	0141                	addi	sp,sp,16
    80002c92:	8082                	ret

0000000080002c94 <sys_wait>:

uint64
sys_wait(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c9c:	fe840593          	addi	a1,s0,-24
    80002ca0:	4501                	li	a0,0
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	ece080e7          	jalr	-306(ra) # 80002b70 <argaddr>
    80002caa:	87aa                	mv	a5,a0
    return -1;
    80002cac:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cae:	0007c863          	bltz	a5,80002cbe <sys_wait+0x2a>
  return wait(p);
    80002cb2:	fe843503          	ld	a0,-24(s0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	57e080e7          	jalr	1406(ra) # 80002234 <wait>
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	6105                	addi	sp,sp,32
    80002cc4:	8082                	ret

0000000080002cc6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cc6:	7179                	addi	sp,sp,-48
    80002cc8:	f406                	sd	ra,40(sp)
    80002cca:	f022                	sd	s0,32(sp)
    80002ccc:	ec26                	sd	s1,24(sp)
    80002cce:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cd0:	fdc40593          	addi	a1,s0,-36
    80002cd4:	4501                	li	a0,0
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	e78080e7          	jalr	-392(ra) # 80002b4e <argint>
    80002cde:	87aa                	mv	a5,a0
    return -1;
    80002ce0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ce2:	0207c063          	bltz	a5,80002d02 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	ea0080e7          	jalr	-352(ra) # 80001b86 <myproc>
    80002cee:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cf0:	fdc42503          	lw	a0,-36(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	1ec080e7          	jalr	492(ra) # 80001ee0 <growproc>
    80002cfc:	00054863          	bltz	a0,80002d0c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d00:	8526                	mv	a0,s1
}
    80002d02:	70a2                	ld	ra,40(sp)
    80002d04:	7402                	ld	s0,32(sp)
    80002d06:	64e2                	ld	s1,24(sp)
    80002d08:	6145                	addi	sp,sp,48
    80002d0a:	8082                	ret
    return -1;
    80002d0c:	557d                	li	a0,-1
    80002d0e:	bfd5                	j	80002d02 <sys_sbrk+0x3c>

0000000080002d10 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d10:	7139                	addi	sp,sp,-64
    80002d12:	fc06                	sd	ra,56(sp)
    80002d14:	f822                	sd	s0,48(sp)
    80002d16:	f426                	sd	s1,40(sp)
    80002d18:	f04a                	sd	s2,32(sp)
    80002d1a:	ec4e                	sd	s3,24(sp)
    80002d1c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d1e:	fcc40593          	addi	a1,s0,-52
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	e2a080e7          	jalr	-470(ra) # 80002b4e <argint>
    return -1;
    80002d2c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d2e:	06054563          	bltz	a0,80002d98 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d32:	00014517          	auipc	a0,0x14
    80002d36:	39e50513          	addi	a0,a0,926 # 800170d0 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	eaa080e7          	jalr	-342(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d42:	00006917          	auipc	s2,0x6
    80002d46:	2f692903          	lw	s2,758(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002d4a:	fcc42783          	lw	a5,-52(s0)
    80002d4e:	cf85                	beqz	a5,80002d86 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d50:	00014997          	auipc	s3,0x14
    80002d54:	38098993          	addi	s3,s3,896 # 800170d0 <tickslock>
    80002d58:	00006497          	auipc	s1,0x6
    80002d5c:	2e048493          	addi	s1,s1,736 # 80009038 <ticks>
    if(myproc()->killed){
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	e26080e7          	jalr	-474(ra) # 80001b86 <myproc>
    80002d68:	551c                	lw	a5,40(a0)
    80002d6a:	ef9d                	bnez	a5,80002da8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d6c:	85ce                	mv	a1,s3
    80002d6e:	8526                	mv	a0,s1
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	460080e7          	jalr	1120(ra) # 800021d0 <sleep>
  while(ticks - ticks0 < n){
    80002d78:	409c                	lw	a5,0(s1)
    80002d7a:	412787bb          	subw	a5,a5,s2
    80002d7e:	fcc42703          	lw	a4,-52(s0)
    80002d82:	fce7efe3          	bltu	a5,a4,80002d60 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d86:	00014517          	auipc	a0,0x14
    80002d8a:	34a50513          	addi	a0,a0,842 # 800170d0 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f0a080e7          	jalr	-246(ra) # 80000c98 <release>
  return 0;
    80002d96:	4781                	li	a5,0
}
    80002d98:	853e                	mv	a0,a5
    80002d9a:	70e2                	ld	ra,56(sp)
    80002d9c:	7442                	ld	s0,48(sp)
    80002d9e:	74a2                	ld	s1,40(sp)
    80002da0:	7902                	ld	s2,32(sp)
    80002da2:	69e2                	ld	s3,24(sp)
    80002da4:	6121                	addi	sp,sp,64
    80002da6:	8082                	ret
      release(&tickslock);
    80002da8:	00014517          	auipc	a0,0x14
    80002dac:	32850513          	addi	a0,a0,808 # 800170d0 <tickslock>
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	ee8080e7          	jalr	-280(ra) # 80000c98 <release>
      return -1;
    80002db8:	57fd                	li	a5,-1
    80002dba:	bff9                	j	80002d98 <sys_sleep+0x88>

0000000080002dbc <sys_kill>:

uint64
sys_kill(void)
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dc4:	fec40593          	addi	a1,s0,-20
    80002dc8:	4501                	li	a0,0
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	d84080e7          	jalr	-636(ra) # 80002b4e <argint>
    80002dd2:	87aa                	mv	a5,a0
    return -1;
    80002dd4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dd6:	0007c863          	bltz	a5,80002de6 <sys_kill+0x2a>
  return kill(pid);
    80002dda:	fec42503          	lw	a0,-20(s0)
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	af6080e7          	jalr	-1290(ra) # 800018d4 <kill>
}
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <sys_kill_sys>:

uint64
sys_kill_sys(void)
{
    80002dee:	1141                	addi	sp,sp,-16
    80002df0:	e406                	sd	ra,8(sp)
    80002df2:	e022                	sd	s0,0(sp)
    80002df4:	0800                	addi	s0,sp,16
  return kill_sys();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	b50080e7          	jalr	-1200(ra) # 80001946 <kill_sys>
}
    80002dfe:	60a2                	ld	ra,8(sp)
    80002e00:	6402                	ld	s0,0(sp)
    80002e02:	0141                	addi	sp,sp,16
    80002e04:	8082                	ret

0000000080002e06 <sys_pause_sys>:


uint64
sys_pause_sys(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80002e0e:	fec40593          	addi	a1,s0,-20
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	d3a080e7          	jalr	-710(ra) # 80002b4e <argint>
    80002e1c:	87aa                	mv	a5,a0
    return -1;
    80002e1e:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80002e20:	0007c863          	bltz	a5,80002e30 <sys_pause_sys+0x2a>
  return pause_sys(time);
    80002e24:	fec42503          	lw	a0,-20(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	372080e7          	jalr	882(ra) # 8000219a <pause_sys>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	e426                	sd	s1,8(sp)
    80002e40:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e42:	00014517          	auipc	a0,0x14
    80002e46:	28e50513          	addi	a0,a0,654 # 800170d0 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	d9a080e7          	jalr	-614(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e52:	00006497          	auipc	s1,0x6
    80002e56:	1e64a483          	lw	s1,486(s1) # 80009038 <ticks>
  release(&tickslock);
    80002e5a:	00014517          	auipc	a0,0x14
    80002e5e:	27650513          	addi	a0,a0,630 # 800170d0 <tickslock>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  return xticks;
}
    80002e6a:	02049513          	slli	a0,s1,0x20
    80002e6e:	9101                	srli	a0,a0,0x20
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	64a2                	ld	s1,8(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e7a:	7179                	addi	sp,sp,-48
    80002e7c:	f406                	sd	ra,40(sp)
    80002e7e:	f022                	sd	s0,32(sp)
    80002e80:	ec26                	sd	s1,24(sp)
    80002e82:	e84a                	sd	s2,16(sp)
    80002e84:	e44e                	sd	s3,8(sp)
    80002e86:	e052                	sd	s4,0(sp)
    80002e88:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e8a:	00005597          	auipc	a1,0x5
    80002e8e:	68658593          	addi	a1,a1,1670 # 80008510 <syscalls+0xc0>
    80002e92:	00014517          	auipc	a0,0x14
    80002e96:	25650513          	addi	a0,a0,598 # 800170e8 <bcache>
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	cba080e7          	jalr	-838(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ea2:	0001c797          	auipc	a5,0x1c
    80002ea6:	24678793          	addi	a5,a5,582 # 8001f0e8 <bcache+0x8000>
    80002eaa:	0001c717          	auipc	a4,0x1c
    80002eae:	4a670713          	addi	a4,a4,1190 # 8001f350 <bcache+0x8268>
    80002eb2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eb6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eba:	00014497          	auipc	s1,0x14
    80002ebe:	24648493          	addi	s1,s1,582 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ec2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ec4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ec6:	00005a17          	auipc	s4,0x5
    80002eca:	652a0a13          	addi	s4,s4,1618 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ece:	2b893783          	ld	a5,696(s2)
    80002ed2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ed4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ed8:	85d2                	mv	a1,s4
    80002eda:	01048513          	addi	a0,s1,16
    80002ede:	00001097          	auipc	ra,0x1
    80002ee2:	4bc080e7          	jalr	1212(ra) # 8000439a <initsleeplock>
    bcache.head.next->prev = b;
    80002ee6:	2b893783          	ld	a5,696(s2)
    80002eea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef0:	45848493          	addi	s1,s1,1112
    80002ef4:	fd349de3          	bne	s1,s3,80002ece <binit+0x54>
  }
}
    80002ef8:	70a2                	ld	ra,40(sp)
    80002efa:	7402                	ld	s0,32(sp)
    80002efc:	64e2                	ld	s1,24(sp)
    80002efe:	6942                	ld	s2,16(sp)
    80002f00:	69a2                	ld	s3,8(sp)
    80002f02:	6a02                	ld	s4,0(sp)
    80002f04:	6145                	addi	sp,sp,48
    80002f06:	8082                	ret

0000000080002f08 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	1800                	addi	s0,sp,48
    80002f16:	89aa                	mv	s3,a0
    80002f18:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f1a:	00014517          	auipc	a0,0x14
    80002f1e:	1ce50513          	addi	a0,a0,462 # 800170e8 <bcache>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	cc2080e7          	jalr	-830(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f2a:	0001c497          	auipc	s1,0x1c
    80002f2e:	4764b483          	ld	s1,1142(s1) # 8001f3a0 <bcache+0x82b8>
    80002f32:	0001c797          	auipc	a5,0x1c
    80002f36:	41e78793          	addi	a5,a5,1054 # 8001f350 <bcache+0x8268>
    80002f3a:	02f48f63          	beq	s1,a5,80002f78 <bread+0x70>
    80002f3e:	873e                	mv	a4,a5
    80002f40:	a021                	j	80002f48 <bread+0x40>
    80002f42:	68a4                	ld	s1,80(s1)
    80002f44:	02e48a63          	beq	s1,a4,80002f78 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f48:	449c                	lw	a5,8(s1)
    80002f4a:	ff379ce3          	bne	a5,s3,80002f42 <bread+0x3a>
    80002f4e:	44dc                	lw	a5,12(s1)
    80002f50:	ff2799e3          	bne	a5,s2,80002f42 <bread+0x3a>
      b->refcnt++;
    80002f54:	40bc                	lw	a5,64(s1)
    80002f56:	2785                	addiw	a5,a5,1
    80002f58:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f5a:	00014517          	auipc	a0,0x14
    80002f5e:	18e50513          	addi	a0,a0,398 # 800170e8 <bcache>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d36080e7          	jalr	-714(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f6a:	01048513          	addi	a0,s1,16
    80002f6e:	00001097          	auipc	ra,0x1
    80002f72:	466080e7          	jalr	1126(ra) # 800043d4 <acquiresleep>
      return b;
    80002f76:	a8b9                	j	80002fd4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f78:	0001c497          	auipc	s1,0x1c
    80002f7c:	4204b483          	ld	s1,1056(s1) # 8001f398 <bcache+0x82b0>
    80002f80:	0001c797          	auipc	a5,0x1c
    80002f84:	3d078793          	addi	a5,a5,976 # 8001f350 <bcache+0x8268>
    80002f88:	00f48863          	beq	s1,a5,80002f98 <bread+0x90>
    80002f8c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f8e:	40bc                	lw	a5,64(s1)
    80002f90:	cf81                	beqz	a5,80002fa8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f92:	64a4                	ld	s1,72(s1)
    80002f94:	fee49de3          	bne	s1,a4,80002f8e <bread+0x86>
  panic("bget: no buffers");
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	58850513          	addi	a0,a0,1416 # 80008520 <syscalls+0xd0>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	59e080e7          	jalr	1438(ra) # 8000053e <panic>
      b->dev = dev;
    80002fa8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fac:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fb0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fb4:	4785                	li	a5,1
    80002fb6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	13050513          	addi	a0,a0,304 # 800170e8 <bcache>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	cd8080e7          	jalr	-808(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fc8:	01048513          	addi	a0,s1,16
    80002fcc:	00001097          	auipc	ra,0x1
    80002fd0:	408080e7          	jalr	1032(ra) # 800043d4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fd4:	409c                	lw	a5,0(s1)
    80002fd6:	cb89                	beqz	a5,80002fe8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fd8:	8526                	mv	a0,s1
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6145                	addi	sp,sp,48
    80002fe6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fe8:	4581                	li	a1,0
    80002fea:	8526                	mv	a0,s1
    80002fec:	00003097          	auipc	ra,0x3
    80002ff0:	f0a080e7          	jalr	-246(ra) # 80005ef6 <virtio_disk_rw>
    b->valid = 1;
    80002ff4:	4785                	li	a5,1
    80002ff6:	c09c                	sw	a5,0(s1)
  return b;
    80002ff8:	b7c5                	j	80002fd8 <bread+0xd0>

0000000080002ffa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003006:	0541                	addi	a0,a0,16
    80003008:	00001097          	auipc	ra,0x1
    8000300c:	466080e7          	jalr	1126(ra) # 8000446e <holdingsleep>
    80003010:	cd01                	beqz	a0,80003028 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003012:	4585                	li	a1,1
    80003014:	8526                	mv	a0,s1
    80003016:	00003097          	auipc	ra,0x3
    8000301a:	ee0080e7          	jalr	-288(ra) # 80005ef6 <virtio_disk_rw>
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret
    panic("bwrite");
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	51050513          	addi	a0,a0,1296 # 80008538 <syscalls+0xe8>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>

0000000080003038 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	e04a                	sd	s2,0(sp)
    80003042:	1000                	addi	s0,sp,32
    80003044:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003046:	01050913          	addi	s2,a0,16
    8000304a:	854a                	mv	a0,s2
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	422080e7          	jalr	1058(ra) # 8000446e <holdingsleep>
    80003054:	c92d                	beqz	a0,800030c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003056:	854a                	mv	a0,s2
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	3d2080e7          	jalr	978(ra) # 8000442a <releasesleep>

  acquire(&bcache.lock);
    80003060:	00014517          	auipc	a0,0x14
    80003064:	08850513          	addi	a0,a0,136 # 800170e8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	b7c080e7          	jalr	-1156(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003070:	40bc                	lw	a5,64(s1)
    80003072:	37fd                	addiw	a5,a5,-1
    80003074:	0007871b          	sext.w	a4,a5
    80003078:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000307a:	eb05                	bnez	a4,800030aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000307c:	68bc                	ld	a5,80(s1)
    8000307e:	64b8                	ld	a4,72(s1)
    80003080:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003082:	64bc                	ld	a5,72(s1)
    80003084:	68b8                	ld	a4,80(s1)
    80003086:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003088:	0001c797          	auipc	a5,0x1c
    8000308c:	06078793          	addi	a5,a5,96 # 8001f0e8 <bcache+0x8000>
    80003090:	2b87b703          	ld	a4,696(a5)
    80003094:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003096:	0001c717          	auipc	a4,0x1c
    8000309a:	2ba70713          	addi	a4,a4,698 # 8001f350 <bcache+0x8268>
    8000309e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030a0:	2b87b703          	ld	a4,696(a5)
    800030a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	03e50513          	addi	a0,a0,62 # 800170e8 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	be6080e7          	jalr	-1050(ra) # 80000c98 <release>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6902                	ld	s2,0(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret
    panic("brelse");
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	47a50513          	addi	a0,a0,1146 # 80008540 <syscalls+0xf0>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>

00000000800030d6 <bpin>:

void
bpin(struct buf *b) {
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	1000                	addi	s0,sp,32
    800030e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030e2:	00014517          	auipc	a0,0x14
    800030e6:	00650513          	addi	a0,a0,6 # 800170e8 <bcache>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	afa080e7          	jalr	-1286(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030f2:	40bc                	lw	a5,64(s1)
    800030f4:	2785                	addiw	a5,a5,1
    800030f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	ff050513          	addi	a0,a0,-16 # 800170e8 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	b98080e7          	jalr	-1128(ra) # 80000c98 <release>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <bunpin>:

void
bunpin(struct buf *b) {
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000311e:	00014517          	auipc	a0,0x14
    80003122:	fca50513          	addi	a0,a0,-54 # 800170e8 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	abe080e7          	jalr	-1346(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000312e:	40bc                	lw	a5,64(s1)
    80003130:	37fd                	addiw	a5,a5,-1
    80003132:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	fb450513          	addi	a0,a0,-76 # 800170e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
}
    80003144:	60e2                	ld	ra,24(sp)
    80003146:	6442                	ld	s0,16(sp)
    80003148:	64a2                	ld	s1,8(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	e04a                	sd	s2,0(sp)
    80003158:	1000                	addi	s0,sp,32
    8000315a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000315c:	00d5d59b          	srliw	a1,a1,0xd
    80003160:	0001c797          	auipc	a5,0x1c
    80003164:	6647a783          	lw	a5,1636(a5) # 8001f7c4 <sb+0x1c>
    80003168:	9dbd                	addw	a1,a1,a5
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	d9e080e7          	jalr	-610(ra) # 80002f08 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003172:	0074f713          	andi	a4,s1,7
    80003176:	4785                	li	a5,1
    80003178:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000317c:	14ce                	slli	s1,s1,0x33
    8000317e:	90d9                	srli	s1,s1,0x36
    80003180:	00950733          	add	a4,a0,s1
    80003184:	05874703          	lbu	a4,88(a4)
    80003188:	00e7f6b3          	and	a3,a5,a4
    8000318c:	c69d                	beqz	a3,800031ba <bfree+0x6c>
    8000318e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003190:	94aa                	add	s1,s1,a0
    80003192:	fff7c793          	not	a5,a5
    80003196:	8ff9                	and	a5,a5,a4
    80003198:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	118080e7          	jalr	280(ra) # 800042b4 <log_write>
  brelse(bp);
    800031a4:	854a                	mv	a0,s2
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	e92080e7          	jalr	-366(ra) # 80003038 <brelse>
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6902                	ld	s2,0(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret
    panic("freeing free block");
    800031ba:	00005517          	auipc	a0,0x5
    800031be:	38e50513          	addi	a0,a0,910 # 80008548 <syscalls+0xf8>
    800031c2:	ffffd097          	auipc	ra,0xffffd
    800031c6:	37c080e7          	jalr	892(ra) # 8000053e <panic>

00000000800031ca <balloc>:
{
    800031ca:	711d                	addi	sp,sp,-96
    800031cc:	ec86                	sd	ra,88(sp)
    800031ce:	e8a2                	sd	s0,80(sp)
    800031d0:	e4a6                	sd	s1,72(sp)
    800031d2:	e0ca                	sd	s2,64(sp)
    800031d4:	fc4e                	sd	s3,56(sp)
    800031d6:	f852                	sd	s4,48(sp)
    800031d8:	f456                	sd	s5,40(sp)
    800031da:	f05a                	sd	s6,32(sp)
    800031dc:	ec5e                	sd	s7,24(sp)
    800031de:	e862                	sd	s8,16(sp)
    800031e0:	e466                	sd	s9,8(sp)
    800031e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031e4:	0001c797          	auipc	a5,0x1c
    800031e8:	5c87a783          	lw	a5,1480(a5) # 8001f7ac <sb+0x4>
    800031ec:	cbd1                	beqz	a5,80003280 <balloc+0xb6>
    800031ee:	8baa                	mv	s7,a0
    800031f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031f2:	0001cb17          	auipc	s6,0x1c
    800031f6:	5b6b0b13          	addi	s6,s6,1462 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003200:	6c89                	lui	s9,0x2
    80003202:	a831                	j	8000321e <balloc+0x54>
    brelse(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	e32080e7          	jalr	-462(ra) # 80003038 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000320e:	015c87bb          	addw	a5,s9,s5
    80003212:	00078a9b          	sext.w	s5,a5
    80003216:	004b2703          	lw	a4,4(s6)
    8000321a:	06eaf363          	bgeu	s5,a4,80003280 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000321e:	41fad79b          	sraiw	a5,s5,0x1f
    80003222:	0137d79b          	srliw	a5,a5,0x13
    80003226:	015787bb          	addw	a5,a5,s5
    8000322a:	40d7d79b          	sraiw	a5,a5,0xd
    8000322e:	01cb2583          	lw	a1,28(s6)
    80003232:	9dbd                	addw	a1,a1,a5
    80003234:	855e                	mv	a0,s7
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	cd2080e7          	jalr	-814(ra) # 80002f08 <bread>
    8000323e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	004b2503          	lw	a0,4(s6)
    80003244:	000a849b          	sext.w	s1,s5
    80003248:	8662                	mv	a2,s8
    8000324a:	faa4fde3          	bgeu	s1,a0,80003204 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000324e:	41f6579b          	sraiw	a5,a2,0x1f
    80003252:	01d7d69b          	srliw	a3,a5,0x1d
    80003256:	00c6873b          	addw	a4,a3,a2
    8000325a:	00777793          	andi	a5,a4,7
    8000325e:	9f95                	subw	a5,a5,a3
    80003260:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003264:	4037571b          	sraiw	a4,a4,0x3
    80003268:	00e906b3          	add	a3,s2,a4
    8000326c:	0586c683          	lbu	a3,88(a3)
    80003270:	00d7f5b3          	and	a1,a5,a3
    80003274:	cd91                	beqz	a1,80003290 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003276:	2605                	addiw	a2,a2,1
    80003278:	2485                	addiw	s1,s1,1
    8000327a:	fd4618e3          	bne	a2,s4,8000324a <balloc+0x80>
    8000327e:	b759                	j	80003204 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003280:	00005517          	auipc	a0,0x5
    80003284:	2e050513          	addi	a0,a0,736 # 80008560 <syscalls+0x110>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2b6080e7          	jalr	694(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003290:	974a                	add	a4,a4,s2
    80003292:	8fd5                	or	a5,a5,a3
    80003294:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003298:	854a                	mv	a0,s2
    8000329a:	00001097          	auipc	ra,0x1
    8000329e:	01a080e7          	jalr	26(ra) # 800042b4 <log_write>
        brelse(bp);
    800032a2:	854a                	mv	a0,s2
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	d94080e7          	jalr	-620(ra) # 80003038 <brelse>
  bp = bread(dev, bno);
    800032ac:	85a6                	mv	a1,s1
    800032ae:	855e                	mv	a0,s7
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	c58080e7          	jalr	-936(ra) # 80002f08 <bread>
    800032b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ba:	40000613          	li	a2,1024
    800032be:	4581                	li	a1,0
    800032c0:	05850513          	addi	a0,a0,88
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	a1c080e7          	jalr	-1508(ra) # 80000ce0 <memset>
  log_write(bp);
    800032cc:	854a                	mv	a0,s2
    800032ce:	00001097          	auipc	ra,0x1
    800032d2:	fe6080e7          	jalr	-26(ra) # 800042b4 <log_write>
  brelse(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	d60080e7          	jalr	-672(ra) # 80003038 <brelse>
}
    800032e0:	8526                	mv	a0,s1
    800032e2:	60e6                	ld	ra,88(sp)
    800032e4:	6446                	ld	s0,80(sp)
    800032e6:	64a6                	ld	s1,72(sp)
    800032e8:	6906                	ld	s2,64(sp)
    800032ea:	79e2                	ld	s3,56(sp)
    800032ec:	7a42                	ld	s4,48(sp)
    800032ee:	7aa2                	ld	s5,40(sp)
    800032f0:	7b02                	ld	s6,32(sp)
    800032f2:	6be2                	ld	s7,24(sp)
    800032f4:	6c42                	ld	s8,16(sp)
    800032f6:	6ca2                	ld	s9,8(sp)
    800032f8:	6125                	addi	sp,sp,96
    800032fa:	8082                	ret

00000000800032fc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032fc:	7179                	addi	sp,sp,-48
    800032fe:	f406                	sd	ra,40(sp)
    80003300:	f022                	sd	s0,32(sp)
    80003302:	ec26                	sd	s1,24(sp)
    80003304:	e84a                	sd	s2,16(sp)
    80003306:	e44e                	sd	s3,8(sp)
    80003308:	e052                	sd	s4,0(sp)
    8000330a:	1800                	addi	s0,sp,48
    8000330c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000330e:	47ad                	li	a5,11
    80003310:	04b7fe63          	bgeu	a5,a1,8000336c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003314:	ff45849b          	addiw	s1,a1,-12
    80003318:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000331c:	0ff00793          	li	a5,255
    80003320:	0ae7e363          	bltu	a5,a4,800033c6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003324:	08052583          	lw	a1,128(a0)
    80003328:	c5ad                	beqz	a1,80003392 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000332a:	00092503          	lw	a0,0(s2)
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	bda080e7          	jalr	-1062(ra) # 80002f08 <bread>
    80003336:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003338:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000333c:	02049593          	slli	a1,s1,0x20
    80003340:	9181                	srli	a1,a1,0x20
    80003342:	058a                	slli	a1,a1,0x2
    80003344:	00b784b3          	add	s1,a5,a1
    80003348:	0004a983          	lw	s3,0(s1)
    8000334c:	04098d63          	beqz	s3,800033a6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003350:	8552                	mv	a0,s4
    80003352:	00000097          	auipc	ra,0x0
    80003356:	ce6080e7          	jalr	-794(ra) # 80003038 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000335a:	854e                	mv	a0,s3
    8000335c:	70a2                	ld	ra,40(sp)
    8000335e:	7402                	ld	s0,32(sp)
    80003360:	64e2                	ld	s1,24(sp)
    80003362:	6942                	ld	s2,16(sp)
    80003364:	69a2                	ld	s3,8(sp)
    80003366:	6a02                	ld	s4,0(sp)
    80003368:	6145                	addi	sp,sp,48
    8000336a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000336c:	02059493          	slli	s1,a1,0x20
    80003370:	9081                	srli	s1,s1,0x20
    80003372:	048a                	slli	s1,s1,0x2
    80003374:	94aa                	add	s1,s1,a0
    80003376:	0504a983          	lw	s3,80(s1)
    8000337a:	fe0990e3          	bnez	s3,8000335a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000337e:	4108                	lw	a0,0(a0)
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e4a080e7          	jalr	-438(ra) # 800031ca <balloc>
    80003388:	0005099b          	sext.w	s3,a0
    8000338c:	0534a823          	sw	s3,80(s1)
    80003390:	b7e9                	j	8000335a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003392:	4108                	lw	a0,0(a0)
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e36080e7          	jalr	-458(ra) # 800031ca <balloc>
    8000339c:	0005059b          	sext.w	a1,a0
    800033a0:	08b92023          	sw	a1,128(s2)
    800033a4:	b759                	j	8000332a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033a6:	00092503          	lw	a0,0(s2)
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e20080e7          	jalr	-480(ra) # 800031ca <balloc>
    800033b2:	0005099b          	sext.w	s3,a0
    800033b6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ba:	8552                	mv	a0,s4
    800033bc:	00001097          	auipc	ra,0x1
    800033c0:	ef8080e7          	jalr	-264(ra) # 800042b4 <log_write>
    800033c4:	b771                	j	80003350 <bmap+0x54>
  panic("bmap: out of range");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	1b250513          	addi	a0,a0,434 # 80008578 <syscalls+0x128>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800033d6 <iget>:
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	e052                	sd	s4,0(sp)
    800033e4:	1800                	addi	s0,sp,48
    800033e6:	89aa                	mv	s3,a0
    800033e8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033ea:	0001c517          	auipc	a0,0x1c
    800033ee:	3de50513          	addi	a0,a0,990 # 8001f7c8 <itable>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	7f2080e7          	jalr	2034(ra) # 80000be4 <acquire>
  empty = 0;
    800033fa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033fc:	0001c497          	auipc	s1,0x1c
    80003400:	3e448493          	addi	s1,s1,996 # 8001f7e0 <itable+0x18>
    80003404:	0001e697          	auipc	a3,0x1e
    80003408:	e6c68693          	addi	a3,a3,-404 # 80021270 <log>
    8000340c:	a039                	j	8000341a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000340e:	02090b63          	beqz	s2,80003444 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003412:	08848493          	addi	s1,s1,136
    80003416:	02d48a63          	beq	s1,a3,8000344a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000341a:	449c                	lw	a5,8(s1)
    8000341c:	fef059e3          	blez	a5,8000340e <iget+0x38>
    80003420:	4098                	lw	a4,0(s1)
    80003422:	ff3716e3          	bne	a4,s3,8000340e <iget+0x38>
    80003426:	40d8                	lw	a4,4(s1)
    80003428:	ff4713e3          	bne	a4,s4,8000340e <iget+0x38>
      ip->ref++;
    8000342c:	2785                	addiw	a5,a5,1
    8000342e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003430:	0001c517          	auipc	a0,0x1c
    80003434:	39850513          	addi	a0,a0,920 # 8001f7c8 <itable>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
      return ip;
    80003440:	8926                	mv	s2,s1
    80003442:	a03d                	j	80003470 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003444:	f7f9                	bnez	a5,80003412 <iget+0x3c>
    80003446:	8926                	mv	s2,s1
    80003448:	b7e9                	j	80003412 <iget+0x3c>
  if(empty == 0)
    8000344a:	02090c63          	beqz	s2,80003482 <iget+0xac>
  ip->dev = dev;
    8000344e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003452:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003456:	4785                	li	a5,1
    80003458:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000345c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003460:	0001c517          	auipc	a0,0x1c
    80003464:	36850513          	addi	a0,a0,872 # 8001f7c8 <itable>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	830080e7          	jalr	-2000(ra) # 80000c98 <release>
}
    80003470:	854a                	mv	a0,s2
    80003472:	70a2                	ld	ra,40(sp)
    80003474:	7402                	ld	s0,32(sp)
    80003476:	64e2                	ld	s1,24(sp)
    80003478:	6942                	ld	s2,16(sp)
    8000347a:	69a2                	ld	s3,8(sp)
    8000347c:	6a02                	ld	s4,0(sp)
    8000347e:	6145                	addi	sp,sp,48
    80003480:	8082                	ret
    panic("iget: no inodes");
    80003482:	00005517          	auipc	a0,0x5
    80003486:	10e50513          	addi	a0,a0,270 # 80008590 <syscalls+0x140>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080003492 <fsinit>:
fsinit(int dev) {
    80003492:	7179                	addi	sp,sp,-48
    80003494:	f406                	sd	ra,40(sp)
    80003496:	f022                	sd	s0,32(sp)
    80003498:	ec26                	sd	s1,24(sp)
    8000349a:	e84a                	sd	s2,16(sp)
    8000349c:	e44e                	sd	s3,8(sp)
    8000349e:	1800                	addi	s0,sp,48
    800034a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034a2:	4585                	li	a1,1
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	a64080e7          	jalr	-1436(ra) # 80002f08 <bread>
    800034ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ae:	0001c997          	auipc	s3,0x1c
    800034b2:	2fa98993          	addi	s3,s3,762 # 8001f7a8 <sb>
    800034b6:	02000613          	li	a2,32
    800034ba:	05850593          	addi	a1,a0,88
    800034be:	854e                	mv	a0,s3
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	880080e7          	jalr	-1920(ra) # 80000d40 <memmove>
  brelse(bp);
    800034c8:	8526                	mv	a0,s1
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	b6e080e7          	jalr	-1170(ra) # 80003038 <brelse>
  if(sb.magic != FSMAGIC)
    800034d2:	0009a703          	lw	a4,0(s3)
    800034d6:	102037b7          	lui	a5,0x10203
    800034da:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034de:	02f71263          	bne	a4,a5,80003502 <fsinit+0x70>
  initlog(dev, &sb);
    800034e2:	0001c597          	auipc	a1,0x1c
    800034e6:	2c658593          	addi	a1,a1,710 # 8001f7a8 <sb>
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	b4c080e7          	jalr	-1204(ra) # 80004038 <initlog>
}
    800034f4:	70a2                	ld	ra,40(sp)
    800034f6:	7402                	ld	s0,32(sp)
    800034f8:	64e2                	ld	s1,24(sp)
    800034fa:	6942                	ld	s2,16(sp)
    800034fc:	69a2                	ld	s3,8(sp)
    800034fe:	6145                	addi	sp,sp,48
    80003500:	8082                	ret
    panic("invalid file system");
    80003502:	00005517          	auipc	a0,0x5
    80003506:	09e50513          	addi	a0,a0,158 # 800085a0 <syscalls+0x150>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	034080e7          	jalr	52(ra) # 8000053e <panic>

0000000080003512 <iinit>:
{
    80003512:	7179                	addi	sp,sp,-48
    80003514:	f406                	sd	ra,40(sp)
    80003516:	f022                	sd	s0,32(sp)
    80003518:	ec26                	sd	s1,24(sp)
    8000351a:	e84a                	sd	s2,16(sp)
    8000351c:	e44e                	sd	s3,8(sp)
    8000351e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003520:	00005597          	auipc	a1,0x5
    80003524:	09858593          	addi	a1,a1,152 # 800085b8 <syscalls+0x168>
    80003528:	0001c517          	auipc	a0,0x1c
    8000352c:	2a050513          	addi	a0,a0,672 # 8001f7c8 <itable>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	624080e7          	jalr	1572(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003538:	0001c497          	auipc	s1,0x1c
    8000353c:	2b848493          	addi	s1,s1,696 # 8001f7f0 <itable+0x28>
    80003540:	0001e997          	auipc	s3,0x1e
    80003544:	d4098993          	addi	s3,s3,-704 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003548:	00005917          	auipc	s2,0x5
    8000354c:	07890913          	addi	s2,s2,120 # 800085c0 <syscalls+0x170>
    80003550:	85ca                	mv	a1,s2
    80003552:	8526                	mv	a0,s1
    80003554:	00001097          	auipc	ra,0x1
    80003558:	e46080e7          	jalr	-442(ra) # 8000439a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000355c:	08848493          	addi	s1,s1,136
    80003560:	ff3498e3          	bne	s1,s3,80003550 <iinit+0x3e>
}
    80003564:	70a2                	ld	ra,40(sp)
    80003566:	7402                	ld	s0,32(sp)
    80003568:	64e2                	ld	s1,24(sp)
    8000356a:	6942                	ld	s2,16(sp)
    8000356c:	69a2                	ld	s3,8(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret

0000000080003572 <ialloc>:
{
    80003572:	715d                	addi	sp,sp,-80
    80003574:	e486                	sd	ra,72(sp)
    80003576:	e0a2                	sd	s0,64(sp)
    80003578:	fc26                	sd	s1,56(sp)
    8000357a:	f84a                	sd	s2,48(sp)
    8000357c:	f44e                	sd	s3,40(sp)
    8000357e:	f052                	sd	s4,32(sp)
    80003580:	ec56                	sd	s5,24(sp)
    80003582:	e85a                	sd	s6,16(sp)
    80003584:	e45e                	sd	s7,8(sp)
    80003586:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003588:	0001c717          	auipc	a4,0x1c
    8000358c:	22c72703          	lw	a4,556(a4) # 8001f7b4 <sb+0xc>
    80003590:	4785                	li	a5,1
    80003592:	04e7fa63          	bgeu	a5,a4,800035e6 <ialloc+0x74>
    80003596:	8aaa                	mv	s5,a0
    80003598:	8bae                	mv	s7,a1
    8000359a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000359c:	0001ca17          	auipc	s4,0x1c
    800035a0:	20ca0a13          	addi	s4,s4,524 # 8001f7a8 <sb>
    800035a4:	00048b1b          	sext.w	s6,s1
    800035a8:	0044d593          	srli	a1,s1,0x4
    800035ac:	018a2783          	lw	a5,24(s4)
    800035b0:	9dbd                	addw	a1,a1,a5
    800035b2:	8556                	mv	a0,s5
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	954080e7          	jalr	-1708(ra) # 80002f08 <bread>
    800035bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035be:	05850993          	addi	s3,a0,88
    800035c2:	00f4f793          	andi	a5,s1,15
    800035c6:	079a                	slli	a5,a5,0x6
    800035c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ca:	00099783          	lh	a5,0(s3)
    800035ce:	c785                	beqz	a5,800035f6 <ialloc+0x84>
    brelse(bp);
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	a68080e7          	jalr	-1432(ra) # 80003038 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d8:	0485                	addi	s1,s1,1
    800035da:	00ca2703          	lw	a4,12(s4)
    800035de:	0004879b          	sext.w	a5,s1
    800035e2:	fce7e1e3          	bltu	a5,a4,800035a4 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	fe250513          	addi	a0,a0,-30 # 800085c8 <syscalls+0x178>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035f6:	04000613          	li	a2,64
    800035fa:	4581                	li	a1,0
    800035fc:	854e                	mv	a0,s3
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	6e2080e7          	jalr	1762(ra) # 80000ce0 <memset>
      dip->type = type;
    80003606:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000360a:	854a                	mv	a0,s2
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	ca8080e7          	jalr	-856(ra) # 800042b4 <log_write>
      brelse(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	a22080e7          	jalr	-1502(ra) # 80003038 <brelse>
      return iget(dev, inum);
    8000361e:	85da                	mv	a1,s6
    80003620:	8556                	mv	a0,s5
    80003622:	00000097          	auipc	ra,0x0
    80003626:	db4080e7          	jalr	-588(ra) # 800033d6 <iget>
}
    8000362a:	60a6                	ld	ra,72(sp)
    8000362c:	6406                	ld	s0,64(sp)
    8000362e:	74e2                	ld	s1,56(sp)
    80003630:	7942                	ld	s2,48(sp)
    80003632:	79a2                	ld	s3,40(sp)
    80003634:	7a02                	ld	s4,32(sp)
    80003636:	6ae2                	ld	s5,24(sp)
    80003638:	6b42                	ld	s6,16(sp)
    8000363a:	6ba2                	ld	s7,8(sp)
    8000363c:	6161                	addi	sp,sp,80
    8000363e:	8082                	ret

0000000080003640 <iupdate>:
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000364e:	415c                	lw	a5,4(a0)
    80003650:	0047d79b          	srliw	a5,a5,0x4
    80003654:	0001c597          	auipc	a1,0x1c
    80003658:	16c5a583          	lw	a1,364(a1) # 8001f7c0 <sb+0x18>
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	4108                	lw	a0,0(a0)
    80003660:	00000097          	auipc	ra,0x0
    80003664:	8a8080e7          	jalr	-1880(ra) # 80002f08 <bread>
    80003668:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366a:	05850793          	addi	a5,a0,88
    8000366e:	40c8                	lw	a0,4(s1)
    80003670:	893d                	andi	a0,a0,15
    80003672:	051a                	slli	a0,a0,0x6
    80003674:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003676:	04449703          	lh	a4,68(s1)
    8000367a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000367e:	04649703          	lh	a4,70(s1)
    80003682:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003686:	04849703          	lh	a4,72(s1)
    8000368a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000368e:	04a49703          	lh	a4,74(s1)
    80003692:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003696:	44f8                	lw	a4,76(s1)
    80003698:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000369a:	03400613          	li	a2,52
    8000369e:	05048593          	addi	a1,s1,80
    800036a2:	0531                	addi	a0,a0,12
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	69c080e7          	jalr	1692(ra) # 80000d40 <memmove>
  log_write(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	c06080e7          	jalr	-1018(ra) # 800042b4 <log_write>
  brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	980080e7          	jalr	-1664(ra) # 80003038 <brelse>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6902                	ld	s2,0(sp)
    800036c8:	6105                	addi	sp,sp,32
    800036ca:	8082                	ret

00000000800036cc <idup>:
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036d8:	0001c517          	auipc	a0,0x1c
    800036dc:	0f050513          	addi	a0,a0,240 # 8001f7c8 <itable>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	504080e7          	jalr	1284(ra) # 80000be4 <acquire>
  ip->ref++;
    800036e8:	449c                	lw	a5,8(s1)
    800036ea:	2785                	addiw	a5,a5,1
    800036ec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036ee:	0001c517          	auipc	a0,0x1c
    800036f2:	0da50513          	addi	a0,a0,218 # 8001f7c8 <itable>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5a2080e7          	jalr	1442(ra) # 80000c98 <release>
}
    800036fe:	8526                	mv	a0,s1
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <ilock>:
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003716:	c115                	beqz	a0,8000373a <ilock+0x30>
    80003718:	84aa                	mv	s1,a0
    8000371a:	451c                	lw	a5,8(a0)
    8000371c:	00f05f63          	blez	a5,8000373a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003720:	0541                	addi	a0,a0,16
    80003722:	00001097          	auipc	ra,0x1
    80003726:	cb2080e7          	jalr	-846(ra) # 800043d4 <acquiresleep>
  if(ip->valid == 0){
    8000372a:	40bc                	lw	a5,64(s1)
    8000372c:	cf99                	beqz	a5,8000374a <ilock+0x40>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret
    panic("ilock");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	ea650513          	addi	a0,a0,-346 # 800085e0 <syscalls+0x190>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	dfc080e7          	jalr	-516(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000374a:	40dc                	lw	a5,4(s1)
    8000374c:	0047d79b          	srliw	a5,a5,0x4
    80003750:	0001c597          	auipc	a1,0x1c
    80003754:	0705a583          	lw	a1,112(a1) # 8001f7c0 <sb+0x18>
    80003758:	9dbd                	addw	a1,a1,a5
    8000375a:	4088                	lw	a0,0(s1)
    8000375c:	fffff097          	auipc	ra,0xfffff
    80003760:	7ac080e7          	jalr	1964(ra) # 80002f08 <bread>
    80003764:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003766:	05850593          	addi	a1,a0,88
    8000376a:	40dc                	lw	a5,4(s1)
    8000376c:	8bbd                	andi	a5,a5,15
    8000376e:	079a                	slli	a5,a5,0x6
    80003770:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003772:	00059783          	lh	a5,0(a1)
    80003776:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000377a:	00259783          	lh	a5,2(a1)
    8000377e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003782:	00459783          	lh	a5,4(a1)
    80003786:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000378a:	00659783          	lh	a5,6(a1)
    8000378e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003792:	459c                	lw	a5,8(a1)
    80003794:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003796:	03400613          	li	a2,52
    8000379a:	05b1                	addi	a1,a1,12
    8000379c:	05048513          	addi	a0,s1,80
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	5a0080e7          	jalr	1440(ra) # 80000d40 <memmove>
    brelse(bp);
    800037a8:	854a                	mv	a0,s2
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	88e080e7          	jalr	-1906(ra) # 80003038 <brelse>
    ip->valid = 1;
    800037b2:	4785                	li	a5,1
    800037b4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037b6:	04449783          	lh	a5,68(s1)
    800037ba:	fbb5                	bnez	a5,8000372e <ilock+0x24>
      panic("ilock: no type");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	e2c50513          	addi	a0,a0,-468 # 800085e8 <syscalls+0x198>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>

00000000800037cc <iunlock>:
{
    800037cc:	1101                	addi	sp,sp,-32
    800037ce:	ec06                	sd	ra,24(sp)
    800037d0:	e822                	sd	s0,16(sp)
    800037d2:	e426                	sd	s1,8(sp)
    800037d4:	e04a                	sd	s2,0(sp)
    800037d6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037d8:	c905                	beqz	a0,80003808 <iunlock+0x3c>
    800037da:	84aa                	mv	s1,a0
    800037dc:	01050913          	addi	s2,a0,16
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	c8c080e7          	jalr	-884(ra) # 8000446e <holdingsleep>
    800037ea:	cd19                	beqz	a0,80003808 <iunlock+0x3c>
    800037ec:	449c                	lw	a5,8(s1)
    800037ee:	00f05d63          	blez	a5,80003808 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	c36080e7          	jalr	-970(ra) # 8000442a <releasesleep>
}
    800037fc:	60e2                	ld	ra,24(sp)
    800037fe:	6442                	ld	s0,16(sp)
    80003800:	64a2                	ld	s1,8(sp)
    80003802:	6902                	ld	s2,0(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret
    panic("iunlock");
    80003808:	00005517          	auipc	a0,0x5
    8000380c:	df050513          	addi	a0,a0,-528 # 800085f8 <syscalls+0x1a8>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	d2e080e7          	jalr	-722(ra) # 8000053e <panic>

0000000080003818 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003818:	7179                	addi	sp,sp,-48
    8000381a:	f406                	sd	ra,40(sp)
    8000381c:	f022                	sd	s0,32(sp)
    8000381e:	ec26                	sd	s1,24(sp)
    80003820:	e84a                	sd	s2,16(sp)
    80003822:	e44e                	sd	s3,8(sp)
    80003824:	e052                	sd	s4,0(sp)
    80003826:	1800                	addi	s0,sp,48
    80003828:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000382a:	05050493          	addi	s1,a0,80
    8000382e:	08050913          	addi	s2,a0,128
    80003832:	a021                	j	8000383a <itrunc+0x22>
    80003834:	0491                	addi	s1,s1,4
    80003836:	01248d63          	beq	s1,s2,80003850 <itrunc+0x38>
    if(ip->addrs[i]){
    8000383a:	408c                	lw	a1,0(s1)
    8000383c:	dde5                	beqz	a1,80003834 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000383e:	0009a503          	lw	a0,0(s3)
    80003842:	00000097          	auipc	ra,0x0
    80003846:	90c080e7          	jalr	-1780(ra) # 8000314e <bfree>
      ip->addrs[i] = 0;
    8000384a:	0004a023          	sw	zero,0(s1)
    8000384e:	b7dd                	j	80003834 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003850:	0809a583          	lw	a1,128(s3)
    80003854:	e185                	bnez	a1,80003874 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003856:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000385a:	854e                	mv	a0,s3
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	de4080e7          	jalr	-540(ra) # 80003640 <iupdate>
}
    80003864:	70a2                	ld	ra,40(sp)
    80003866:	7402                	ld	s0,32(sp)
    80003868:	64e2                	ld	s1,24(sp)
    8000386a:	6942                	ld	s2,16(sp)
    8000386c:	69a2                	ld	s3,8(sp)
    8000386e:	6a02                	ld	s4,0(sp)
    80003870:	6145                	addi	sp,sp,48
    80003872:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003874:	0009a503          	lw	a0,0(s3)
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	690080e7          	jalr	1680(ra) # 80002f08 <bread>
    80003880:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003882:	05850493          	addi	s1,a0,88
    80003886:	45850913          	addi	s2,a0,1112
    8000388a:	a811                	j	8000389e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000388c:	0009a503          	lw	a0,0(s3)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	8be080e7          	jalr	-1858(ra) # 8000314e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003898:	0491                	addi	s1,s1,4
    8000389a:	01248563          	beq	s1,s2,800038a4 <itrunc+0x8c>
      if(a[j])
    8000389e:	408c                	lw	a1,0(s1)
    800038a0:	dde5                	beqz	a1,80003898 <itrunc+0x80>
    800038a2:	b7ed                	j	8000388c <itrunc+0x74>
    brelse(bp);
    800038a4:	8552                	mv	a0,s4
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	792080e7          	jalr	1938(ra) # 80003038 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ae:	0809a583          	lw	a1,128(s3)
    800038b2:	0009a503          	lw	a0,0(s3)
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	898080e7          	jalr	-1896(ra) # 8000314e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038be:	0809a023          	sw	zero,128(s3)
    800038c2:	bf51                	j	80003856 <itrunc+0x3e>

00000000800038c4 <iput>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d2:	0001c517          	auipc	a0,0x1c
    800038d6:	ef650513          	addi	a0,a0,-266 # 8001f7c8 <itable>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	30a080e7          	jalr	778(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e2:	4498                	lw	a4,8(s1)
    800038e4:	4785                	li	a5,1
    800038e6:	02f70363          	beq	a4,a5,8000390c <iput+0x48>
  ip->ref--;
    800038ea:	449c                	lw	a5,8(s1)
    800038ec:	37fd                	addiw	a5,a5,-1
    800038ee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f0:	0001c517          	auipc	a0,0x1c
    800038f4:	ed850513          	addi	a0,a0,-296 # 8001f7c8 <itable>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	3a0080e7          	jalr	928(ra) # 80000c98 <release>
}
    80003900:	60e2                	ld	ra,24(sp)
    80003902:	6442                	ld	s0,16(sp)
    80003904:	64a2                	ld	s1,8(sp)
    80003906:	6902                	ld	s2,0(sp)
    80003908:	6105                	addi	sp,sp,32
    8000390a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000390c:	40bc                	lw	a5,64(s1)
    8000390e:	dff1                	beqz	a5,800038ea <iput+0x26>
    80003910:	04a49783          	lh	a5,74(s1)
    80003914:	fbf9                	bnez	a5,800038ea <iput+0x26>
    acquiresleep(&ip->lock);
    80003916:	01048913          	addi	s2,s1,16
    8000391a:	854a                	mv	a0,s2
    8000391c:	00001097          	auipc	ra,0x1
    80003920:	ab8080e7          	jalr	-1352(ra) # 800043d4 <acquiresleep>
    release(&itable.lock);
    80003924:	0001c517          	auipc	a0,0x1c
    80003928:	ea450513          	addi	a0,a0,-348 # 8001f7c8 <itable>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
    itrunc(ip);
    80003934:	8526                	mv	a0,s1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	ee2080e7          	jalr	-286(ra) # 80003818 <itrunc>
    ip->type = 0;
    8000393e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003942:	8526                	mv	a0,s1
    80003944:	00000097          	auipc	ra,0x0
    80003948:	cfc080e7          	jalr	-772(ra) # 80003640 <iupdate>
    ip->valid = 0;
    8000394c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	ad8080e7          	jalr	-1320(ra) # 8000442a <releasesleep>
    acquire(&itable.lock);
    8000395a:	0001c517          	auipc	a0,0x1c
    8000395e:	e6e50513          	addi	a0,a0,-402 # 8001f7c8 <itable>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	282080e7          	jalr	642(ra) # 80000be4 <acquire>
    8000396a:	b741                	j	800038ea <iput+0x26>

000000008000396c <iunlockput>:
{
    8000396c:	1101                	addi	sp,sp,-32
    8000396e:	ec06                	sd	ra,24(sp)
    80003970:	e822                	sd	s0,16(sp)
    80003972:	e426                	sd	s1,8(sp)
    80003974:	1000                	addi	s0,sp,32
    80003976:	84aa                	mv	s1,a0
  iunlock(ip);
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	e54080e7          	jalr	-428(ra) # 800037cc <iunlock>
  iput(ip);
    80003980:	8526                	mv	a0,s1
    80003982:	00000097          	auipc	ra,0x0
    80003986:	f42080e7          	jalr	-190(ra) # 800038c4 <iput>
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret

0000000080003994 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003994:	1141                	addi	sp,sp,-16
    80003996:	e422                	sd	s0,8(sp)
    80003998:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000399a:	411c                	lw	a5,0(a0)
    8000399c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000399e:	415c                	lw	a5,4(a0)
    800039a0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a2:	04451783          	lh	a5,68(a0)
    800039a6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039aa:	04a51783          	lh	a5,74(a0)
    800039ae:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b2:	04c56783          	lwu	a5,76(a0)
    800039b6:	e99c                	sd	a5,16(a1)
}
    800039b8:	6422                	ld	s0,8(sp)
    800039ba:	0141                	addi	sp,sp,16
    800039bc:	8082                	ret

00000000800039be <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039be:	457c                	lw	a5,76(a0)
    800039c0:	0ed7e963          	bltu	a5,a3,80003ab2 <readi+0xf4>
{
    800039c4:	7159                	addi	sp,sp,-112
    800039c6:	f486                	sd	ra,104(sp)
    800039c8:	f0a2                	sd	s0,96(sp)
    800039ca:	eca6                	sd	s1,88(sp)
    800039cc:	e8ca                	sd	s2,80(sp)
    800039ce:	e4ce                	sd	s3,72(sp)
    800039d0:	e0d2                	sd	s4,64(sp)
    800039d2:	fc56                	sd	s5,56(sp)
    800039d4:	f85a                	sd	s6,48(sp)
    800039d6:	f45e                	sd	s7,40(sp)
    800039d8:	f062                	sd	s8,32(sp)
    800039da:	ec66                	sd	s9,24(sp)
    800039dc:	e86a                	sd	s10,16(sp)
    800039de:	e46e                	sd	s11,8(sp)
    800039e0:	1880                	addi	s0,sp,112
    800039e2:	8baa                	mv	s7,a0
    800039e4:	8c2e                	mv	s8,a1
    800039e6:	8ab2                	mv	s5,a2
    800039e8:	84b6                	mv	s1,a3
    800039ea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ec:	9f35                	addw	a4,a4,a3
    return 0;
    800039ee:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f0:	0ad76063          	bltu	a4,a3,80003a90 <readi+0xd2>
  if(off + n > ip->size)
    800039f4:	00e7f463          	bgeu	a5,a4,800039fc <readi+0x3e>
    n = ip->size - off;
    800039f8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039fc:	0a0b0963          	beqz	s6,80003aae <readi+0xf0>
    80003a00:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a02:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a06:	5cfd                	li	s9,-1
    80003a08:	a82d                	j	80003a42 <readi+0x84>
    80003a0a:	020a1d93          	slli	s11,s4,0x20
    80003a0e:	020ddd93          	srli	s11,s11,0x20
    80003a12:	05890613          	addi	a2,s2,88
    80003a16:	86ee                	mv	a3,s11
    80003a18:	963a                	add	a2,a2,a4
    80003a1a:	85d6                	mv	a1,s5
    80003a1c:	8562                	mv	a0,s8
    80003a1e:	fffff097          	auipc	ra,0xfffff
    80003a22:	ae4080e7          	jalr	-1308(ra) # 80002502 <either_copyout>
    80003a26:	05950d63          	beq	a0,s9,80003a80 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	60c080e7          	jalr	1548(ra) # 80003038 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a34:	013a09bb          	addw	s3,s4,s3
    80003a38:	009a04bb          	addw	s1,s4,s1
    80003a3c:	9aee                	add	s5,s5,s11
    80003a3e:	0569f763          	bgeu	s3,s6,80003a8c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a42:	000ba903          	lw	s2,0(s7)
    80003a46:	00a4d59b          	srliw	a1,s1,0xa
    80003a4a:	855e                	mv	a0,s7
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	8b0080e7          	jalr	-1872(ra) # 800032fc <bmap>
    80003a54:	0005059b          	sext.w	a1,a0
    80003a58:	854a                	mv	a0,s2
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	4ae080e7          	jalr	1198(ra) # 80002f08 <bread>
    80003a62:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a64:	3ff4f713          	andi	a4,s1,1023
    80003a68:	40ed07bb          	subw	a5,s10,a4
    80003a6c:	413b06bb          	subw	a3,s6,s3
    80003a70:	8a3e                	mv	s4,a5
    80003a72:	2781                	sext.w	a5,a5
    80003a74:	0006861b          	sext.w	a2,a3
    80003a78:	f8f679e3          	bgeu	a2,a5,80003a0a <readi+0x4c>
    80003a7c:	8a36                	mv	s4,a3
    80003a7e:	b771                	j	80003a0a <readi+0x4c>
      brelse(bp);
    80003a80:	854a                	mv	a0,s2
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	5b6080e7          	jalr	1462(ra) # 80003038 <brelse>
      tot = -1;
    80003a8a:	59fd                	li	s3,-1
  }
  return tot;
    80003a8c:	0009851b          	sext.w	a0,s3
}
    80003a90:	70a6                	ld	ra,104(sp)
    80003a92:	7406                	ld	s0,96(sp)
    80003a94:	64e6                	ld	s1,88(sp)
    80003a96:	6946                	ld	s2,80(sp)
    80003a98:	69a6                	ld	s3,72(sp)
    80003a9a:	6a06                	ld	s4,64(sp)
    80003a9c:	7ae2                	ld	s5,56(sp)
    80003a9e:	7b42                	ld	s6,48(sp)
    80003aa0:	7ba2                	ld	s7,40(sp)
    80003aa2:	7c02                	ld	s8,32(sp)
    80003aa4:	6ce2                	ld	s9,24(sp)
    80003aa6:	6d42                	ld	s10,16(sp)
    80003aa8:	6da2                	ld	s11,8(sp)
    80003aaa:	6165                	addi	sp,sp,112
    80003aac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aae:	89da                	mv	s3,s6
    80003ab0:	bff1                	j	80003a8c <readi+0xce>
    return 0;
    80003ab2:	4501                	li	a0,0
}
    80003ab4:	8082                	ret

0000000080003ab6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ab6:	457c                	lw	a5,76(a0)
    80003ab8:	10d7e863          	bltu	a5,a3,80003bc8 <writei+0x112>
{
    80003abc:	7159                	addi	sp,sp,-112
    80003abe:	f486                	sd	ra,104(sp)
    80003ac0:	f0a2                	sd	s0,96(sp)
    80003ac2:	eca6                	sd	s1,88(sp)
    80003ac4:	e8ca                	sd	s2,80(sp)
    80003ac6:	e4ce                	sd	s3,72(sp)
    80003ac8:	e0d2                	sd	s4,64(sp)
    80003aca:	fc56                	sd	s5,56(sp)
    80003acc:	f85a                	sd	s6,48(sp)
    80003ace:	f45e                	sd	s7,40(sp)
    80003ad0:	f062                	sd	s8,32(sp)
    80003ad2:	ec66                	sd	s9,24(sp)
    80003ad4:	e86a                	sd	s10,16(sp)
    80003ad6:	e46e                	sd	s11,8(sp)
    80003ad8:	1880                	addi	s0,sp,112
    80003ada:	8b2a                	mv	s6,a0
    80003adc:	8c2e                	mv	s8,a1
    80003ade:	8ab2                	mv	s5,a2
    80003ae0:	8936                	mv	s2,a3
    80003ae2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ae4:	00e687bb          	addw	a5,a3,a4
    80003ae8:	0ed7e263          	bltu	a5,a3,80003bcc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aec:	00043737          	lui	a4,0x43
    80003af0:	0ef76063          	bltu	a4,a5,80003bd0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003af4:	0c0b8863          	beqz	s7,80003bc4 <writei+0x10e>
    80003af8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003afa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003afe:	5cfd                	li	s9,-1
    80003b00:	a091                	j	80003b44 <writei+0x8e>
    80003b02:	02099d93          	slli	s11,s3,0x20
    80003b06:	020ddd93          	srli	s11,s11,0x20
    80003b0a:	05848513          	addi	a0,s1,88
    80003b0e:	86ee                	mv	a3,s11
    80003b10:	8656                	mv	a2,s5
    80003b12:	85e2                	mv	a1,s8
    80003b14:	953a                	add	a0,a0,a4
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	a42080e7          	jalr	-1470(ra) # 80002558 <either_copyin>
    80003b1e:	07950263          	beq	a0,s9,80003b82 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b22:	8526                	mv	a0,s1
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	790080e7          	jalr	1936(ra) # 800042b4 <log_write>
    brelse(bp);
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	50a080e7          	jalr	1290(ra) # 80003038 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b36:	01498a3b          	addw	s4,s3,s4
    80003b3a:	0129893b          	addw	s2,s3,s2
    80003b3e:	9aee                	add	s5,s5,s11
    80003b40:	057a7663          	bgeu	s4,s7,80003b8c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b44:	000b2483          	lw	s1,0(s6)
    80003b48:	00a9559b          	srliw	a1,s2,0xa
    80003b4c:	855a                	mv	a0,s6
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	7ae080e7          	jalr	1966(ra) # 800032fc <bmap>
    80003b56:	0005059b          	sext.w	a1,a0
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	3ac080e7          	jalr	940(ra) # 80002f08 <bread>
    80003b64:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b66:	3ff97713          	andi	a4,s2,1023
    80003b6a:	40ed07bb          	subw	a5,s10,a4
    80003b6e:	414b86bb          	subw	a3,s7,s4
    80003b72:	89be                	mv	s3,a5
    80003b74:	2781                	sext.w	a5,a5
    80003b76:	0006861b          	sext.w	a2,a3
    80003b7a:	f8f674e3          	bgeu	a2,a5,80003b02 <writei+0x4c>
    80003b7e:	89b6                	mv	s3,a3
    80003b80:	b749                	j	80003b02 <writei+0x4c>
      brelse(bp);
    80003b82:	8526                	mv	a0,s1
    80003b84:	fffff097          	auipc	ra,0xfffff
    80003b88:	4b4080e7          	jalr	1204(ra) # 80003038 <brelse>
  }

  if(off > ip->size)
    80003b8c:	04cb2783          	lw	a5,76(s6)
    80003b90:	0127f463          	bgeu	a5,s2,80003b98 <writei+0xe2>
    ip->size = off;
    80003b94:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b98:	855a                	mv	a0,s6
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	aa6080e7          	jalr	-1370(ra) # 80003640 <iupdate>

  return tot;
    80003ba2:	000a051b          	sext.w	a0,s4
}
    80003ba6:	70a6                	ld	ra,104(sp)
    80003ba8:	7406                	ld	s0,96(sp)
    80003baa:	64e6                	ld	s1,88(sp)
    80003bac:	6946                	ld	s2,80(sp)
    80003bae:	69a6                	ld	s3,72(sp)
    80003bb0:	6a06                	ld	s4,64(sp)
    80003bb2:	7ae2                	ld	s5,56(sp)
    80003bb4:	7b42                	ld	s6,48(sp)
    80003bb6:	7ba2                	ld	s7,40(sp)
    80003bb8:	7c02                	ld	s8,32(sp)
    80003bba:	6ce2                	ld	s9,24(sp)
    80003bbc:	6d42                	ld	s10,16(sp)
    80003bbe:	6da2                	ld	s11,8(sp)
    80003bc0:	6165                	addi	sp,sp,112
    80003bc2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc4:	8a5e                	mv	s4,s7
    80003bc6:	bfc9                	j	80003b98 <writei+0xe2>
    return -1;
    80003bc8:	557d                	li	a0,-1
}
    80003bca:	8082                	ret
    return -1;
    80003bcc:	557d                	li	a0,-1
    80003bce:	bfe1                	j	80003ba6 <writei+0xf0>
    return -1;
    80003bd0:	557d                	li	a0,-1
    80003bd2:	bfd1                	j	80003ba6 <writei+0xf0>

0000000080003bd4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bd4:	1141                	addi	sp,sp,-16
    80003bd6:	e406                	sd	ra,8(sp)
    80003bd8:	e022                	sd	s0,0(sp)
    80003bda:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bdc:	4639                	li	a2,14
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	1da080e7          	jalr	474(ra) # 80000db8 <strncmp>
}
    80003be6:	60a2                	ld	ra,8(sp)
    80003be8:	6402                	ld	s0,0(sp)
    80003bea:	0141                	addi	sp,sp,16
    80003bec:	8082                	ret

0000000080003bee <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bee:	7139                	addi	sp,sp,-64
    80003bf0:	fc06                	sd	ra,56(sp)
    80003bf2:	f822                	sd	s0,48(sp)
    80003bf4:	f426                	sd	s1,40(sp)
    80003bf6:	f04a                	sd	s2,32(sp)
    80003bf8:	ec4e                	sd	s3,24(sp)
    80003bfa:	e852                	sd	s4,16(sp)
    80003bfc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bfe:	04451703          	lh	a4,68(a0)
    80003c02:	4785                	li	a5,1
    80003c04:	00f71a63          	bne	a4,a5,80003c18 <dirlookup+0x2a>
    80003c08:	892a                	mv	s2,a0
    80003c0a:	89ae                	mv	s3,a1
    80003c0c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c0e:	457c                	lw	a5,76(a0)
    80003c10:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c12:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	e79d                	bnez	a5,80003c42 <dirlookup+0x54>
    80003c16:	a8a5                	j	80003c8e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c18:	00005517          	auipc	a0,0x5
    80003c1c:	9e850513          	addi	a0,a0,-1560 # 80008600 <syscalls+0x1b0>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c28:	00005517          	auipc	a0,0x5
    80003c2c:	9f050513          	addi	a0,a0,-1552 # 80008618 <syscalls+0x1c8>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c38:	24c1                	addiw	s1,s1,16
    80003c3a:	04c92783          	lw	a5,76(s2)
    80003c3e:	04f4f763          	bgeu	s1,a5,80003c8c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c42:	4741                	li	a4,16
    80003c44:	86a6                	mv	a3,s1
    80003c46:	fc040613          	addi	a2,s0,-64
    80003c4a:	4581                	li	a1,0
    80003c4c:	854a                	mv	a0,s2
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	d70080e7          	jalr	-656(ra) # 800039be <readi>
    80003c56:	47c1                	li	a5,16
    80003c58:	fcf518e3          	bne	a0,a5,80003c28 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c5c:	fc045783          	lhu	a5,-64(s0)
    80003c60:	dfe1                	beqz	a5,80003c38 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c62:	fc240593          	addi	a1,s0,-62
    80003c66:	854e                	mv	a0,s3
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	f6c080e7          	jalr	-148(ra) # 80003bd4 <namecmp>
    80003c70:	f561                	bnez	a0,80003c38 <dirlookup+0x4a>
      if(poff)
    80003c72:	000a0463          	beqz	s4,80003c7a <dirlookup+0x8c>
        *poff = off;
    80003c76:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c7a:	fc045583          	lhu	a1,-64(s0)
    80003c7e:	00092503          	lw	a0,0(s2)
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	754080e7          	jalr	1876(ra) # 800033d6 <iget>
    80003c8a:	a011                	j	80003c8e <dirlookup+0xa0>
  return 0;
    80003c8c:	4501                	li	a0,0
}
    80003c8e:	70e2                	ld	ra,56(sp)
    80003c90:	7442                	ld	s0,48(sp)
    80003c92:	74a2                	ld	s1,40(sp)
    80003c94:	7902                	ld	s2,32(sp)
    80003c96:	69e2                	ld	s3,24(sp)
    80003c98:	6a42                	ld	s4,16(sp)
    80003c9a:	6121                	addi	sp,sp,64
    80003c9c:	8082                	ret

0000000080003c9e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c9e:	711d                	addi	sp,sp,-96
    80003ca0:	ec86                	sd	ra,88(sp)
    80003ca2:	e8a2                	sd	s0,80(sp)
    80003ca4:	e4a6                	sd	s1,72(sp)
    80003ca6:	e0ca                	sd	s2,64(sp)
    80003ca8:	fc4e                	sd	s3,56(sp)
    80003caa:	f852                	sd	s4,48(sp)
    80003cac:	f456                	sd	s5,40(sp)
    80003cae:	f05a                	sd	s6,32(sp)
    80003cb0:	ec5e                	sd	s7,24(sp)
    80003cb2:	e862                	sd	s8,16(sp)
    80003cb4:	e466                	sd	s9,8(sp)
    80003cb6:	1080                	addi	s0,sp,96
    80003cb8:	84aa                	mv	s1,a0
    80003cba:	8b2e                	mv	s6,a1
    80003cbc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cbe:	00054703          	lbu	a4,0(a0)
    80003cc2:	02f00793          	li	a5,47
    80003cc6:	02f70363          	beq	a4,a5,80003cec <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cca:	ffffe097          	auipc	ra,0xffffe
    80003cce:	ebc080e7          	jalr	-324(ra) # 80001b86 <myproc>
    80003cd2:	15053503          	ld	a0,336(a0)
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	9f6080e7          	jalr	-1546(ra) # 800036cc <idup>
    80003cde:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ce0:	02f00913          	li	s2,47
  len = path - s;
    80003ce4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ce6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ce8:	4c05                	li	s8,1
    80003cea:	a865                	j	80003da2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cec:	4585                	li	a1,1
    80003cee:	4505                	li	a0,1
    80003cf0:	fffff097          	auipc	ra,0xfffff
    80003cf4:	6e6080e7          	jalr	1766(ra) # 800033d6 <iget>
    80003cf8:	89aa                	mv	s3,a0
    80003cfa:	b7dd                	j	80003ce0 <namex+0x42>
      iunlockput(ip);
    80003cfc:	854e                	mv	a0,s3
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	c6e080e7          	jalr	-914(ra) # 8000396c <iunlockput>
      return 0;
    80003d06:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d08:	854e                	mv	a0,s3
    80003d0a:	60e6                	ld	ra,88(sp)
    80003d0c:	6446                	ld	s0,80(sp)
    80003d0e:	64a6                	ld	s1,72(sp)
    80003d10:	6906                	ld	s2,64(sp)
    80003d12:	79e2                	ld	s3,56(sp)
    80003d14:	7a42                	ld	s4,48(sp)
    80003d16:	7aa2                	ld	s5,40(sp)
    80003d18:	7b02                	ld	s6,32(sp)
    80003d1a:	6be2                	ld	s7,24(sp)
    80003d1c:	6c42                	ld	s8,16(sp)
    80003d1e:	6ca2                	ld	s9,8(sp)
    80003d20:	6125                	addi	sp,sp,96
    80003d22:	8082                	ret
      iunlock(ip);
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	aa6080e7          	jalr	-1370(ra) # 800037cc <iunlock>
      return ip;
    80003d2e:	bfe9                	j	80003d08 <namex+0x6a>
      iunlockput(ip);
    80003d30:	854e                	mv	a0,s3
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	c3a080e7          	jalr	-966(ra) # 8000396c <iunlockput>
      return 0;
    80003d3a:	89d2                	mv	s3,s4
    80003d3c:	b7f1                	j	80003d08 <namex+0x6a>
  len = path - s;
    80003d3e:	40b48633          	sub	a2,s1,a1
    80003d42:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d46:	094cd463          	bge	s9,s4,80003dce <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d4a:	4639                	li	a2,14
    80003d4c:	8556                	mv	a0,s5
    80003d4e:	ffffd097          	auipc	ra,0xffffd
    80003d52:	ff2080e7          	jalr	-14(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d56:	0004c783          	lbu	a5,0(s1)
    80003d5a:	01279763          	bne	a5,s2,80003d68 <namex+0xca>
    path++;
    80003d5e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d60:	0004c783          	lbu	a5,0(s1)
    80003d64:	ff278de3          	beq	a5,s2,80003d5e <namex+0xc0>
    ilock(ip);
    80003d68:	854e                	mv	a0,s3
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	9a0080e7          	jalr	-1632(ra) # 8000370a <ilock>
    if(ip->type != T_DIR){
    80003d72:	04499783          	lh	a5,68(s3)
    80003d76:	f98793e3          	bne	a5,s8,80003cfc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d7a:	000b0563          	beqz	s6,80003d84 <namex+0xe6>
    80003d7e:	0004c783          	lbu	a5,0(s1)
    80003d82:	d3cd                	beqz	a5,80003d24 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d84:	865e                	mv	a2,s7
    80003d86:	85d6                	mv	a1,s5
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	e64080e7          	jalr	-412(ra) # 80003bee <dirlookup>
    80003d92:	8a2a                	mv	s4,a0
    80003d94:	dd51                	beqz	a0,80003d30 <namex+0x92>
    iunlockput(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	bd4080e7          	jalr	-1068(ra) # 8000396c <iunlockput>
    ip = next;
    80003da0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	05279763          	bne	a5,s2,80003df4 <namex+0x156>
    path++;
    80003daa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dac:	0004c783          	lbu	a5,0(s1)
    80003db0:	ff278de3          	beq	a5,s2,80003daa <namex+0x10c>
  if(*path == 0)
    80003db4:	c79d                	beqz	a5,80003de2 <namex+0x144>
    path++;
    80003db6:	85a6                	mv	a1,s1
  len = path - s;
    80003db8:	8a5e                	mv	s4,s7
    80003dba:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dbc:	01278963          	beq	a5,s2,80003dce <namex+0x130>
    80003dc0:	dfbd                	beqz	a5,80003d3e <namex+0xa0>
    path++;
    80003dc2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dc4:	0004c783          	lbu	a5,0(s1)
    80003dc8:	ff279ce3          	bne	a5,s2,80003dc0 <namex+0x122>
    80003dcc:	bf8d                	j	80003d3e <namex+0xa0>
    memmove(name, s, len);
    80003dce:	2601                	sext.w	a2,a2
    80003dd0:	8556                	mv	a0,s5
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	f6e080e7          	jalr	-146(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003dda:	9a56                	add	s4,s4,s5
    80003ddc:	000a0023          	sb	zero,0(s4)
    80003de0:	bf9d                	j	80003d56 <namex+0xb8>
  if(nameiparent){
    80003de2:	f20b03e3          	beqz	s6,80003d08 <namex+0x6a>
    iput(ip);
    80003de6:	854e                	mv	a0,s3
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	adc080e7          	jalr	-1316(ra) # 800038c4 <iput>
    return 0;
    80003df0:	4981                	li	s3,0
    80003df2:	bf19                	j	80003d08 <namex+0x6a>
  if(*path == 0)
    80003df4:	d7fd                	beqz	a5,80003de2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003df6:	0004c783          	lbu	a5,0(s1)
    80003dfa:	85a6                	mv	a1,s1
    80003dfc:	b7d1                	j	80003dc0 <namex+0x122>

0000000080003dfe <dirlink>:
{
    80003dfe:	7139                	addi	sp,sp,-64
    80003e00:	fc06                	sd	ra,56(sp)
    80003e02:	f822                	sd	s0,48(sp)
    80003e04:	f426                	sd	s1,40(sp)
    80003e06:	f04a                	sd	s2,32(sp)
    80003e08:	ec4e                	sd	s3,24(sp)
    80003e0a:	e852                	sd	s4,16(sp)
    80003e0c:	0080                	addi	s0,sp,64
    80003e0e:	892a                	mv	s2,a0
    80003e10:	8a2e                	mv	s4,a1
    80003e12:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e14:	4601                	li	a2,0
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	dd8080e7          	jalr	-552(ra) # 80003bee <dirlookup>
    80003e1e:	e93d                	bnez	a0,80003e94 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e20:	04c92483          	lw	s1,76(s2)
    80003e24:	c49d                	beqz	s1,80003e52 <dirlink+0x54>
    80003e26:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e28:	4741                	li	a4,16
    80003e2a:	86a6                	mv	a3,s1
    80003e2c:	fc040613          	addi	a2,s0,-64
    80003e30:	4581                	li	a1,0
    80003e32:	854a                	mv	a0,s2
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	b8a080e7          	jalr	-1142(ra) # 800039be <readi>
    80003e3c:	47c1                	li	a5,16
    80003e3e:	06f51163          	bne	a0,a5,80003ea0 <dirlink+0xa2>
    if(de.inum == 0)
    80003e42:	fc045783          	lhu	a5,-64(s0)
    80003e46:	c791                	beqz	a5,80003e52 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e48:	24c1                	addiw	s1,s1,16
    80003e4a:	04c92783          	lw	a5,76(s2)
    80003e4e:	fcf4ede3          	bltu	s1,a5,80003e28 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e52:	4639                	li	a2,14
    80003e54:	85d2                	mv	a1,s4
    80003e56:	fc240513          	addi	a0,s0,-62
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	f9a080e7          	jalr	-102(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e62:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e66:	4741                	li	a4,16
    80003e68:	86a6                	mv	a3,s1
    80003e6a:	fc040613          	addi	a2,s0,-64
    80003e6e:	4581                	li	a1,0
    80003e70:	854a                	mv	a0,s2
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	c44080e7          	jalr	-956(ra) # 80003ab6 <writei>
    80003e7a:	872a                	mv	a4,a0
    80003e7c:	47c1                	li	a5,16
  return 0;
    80003e7e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e80:	02f71863          	bne	a4,a5,80003eb0 <dirlink+0xb2>
}
    80003e84:	70e2                	ld	ra,56(sp)
    80003e86:	7442                	ld	s0,48(sp)
    80003e88:	74a2                	ld	s1,40(sp)
    80003e8a:	7902                	ld	s2,32(sp)
    80003e8c:	69e2                	ld	s3,24(sp)
    80003e8e:	6a42                	ld	s4,16(sp)
    80003e90:	6121                	addi	sp,sp,64
    80003e92:	8082                	ret
    iput(ip);
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	a30080e7          	jalr	-1488(ra) # 800038c4 <iput>
    return -1;
    80003e9c:	557d                	li	a0,-1
    80003e9e:	b7dd                	j	80003e84 <dirlink+0x86>
      panic("dirlink read");
    80003ea0:	00004517          	auipc	a0,0x4
    80003ea4:	78850513          	addi	a0,a0,1928 # 80008628 <syscalls+0x1d8>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	696080e7          	jalr	1686(ra) # 8000053e <panic>
    panic("dirlink");
    80003eb0:	00005517          	auipc	a0,0x5
    80003eb4:	88850513          	addi	a0,a0,-1912 # 80008738 <syscalls+0x2e8>
    80003eb8:	ffffc097          	auipc	ra,0xffffc
    80003ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>

0000000080003ec0 <namei>:

struct inode*
namei(char *path)
{
    80003ec0:	1101                	addi	sp,sp,-32
    80003ec2:	ec06                	sd	ra,24(sp)
    80003ec4:	e822                	sd	s0,16(sp)
    80003ec6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ec8:	fe040613          	addi	a2,s0,-32
    80003ecc:	4581                	li	a1,0
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	dd0080e7          	jalr	-560(ra) # 80003c9e <namex>
}
    80003ed6:	60e2                	ld	ra,24(sp)
    80003ed8:	6442                	ld	s0,16(sp)
    80003eda:	6105                	addi	sp,sp,32
    80003edc:	8082                	ret

0000000080003ede <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ede:	1141                	addi	sp,sp,-16
    80003ee0:	e406                	sd	ra,8(sp)
    80003ee2:	e022                	sd	s0,0(sp)
    80003ee4:	0800                	addi	s0,sp,16
    80003ee6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ee8:	4585                	li	a1,1
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	db4080e7          	jalr	-588(ra) # 80003c9e <namex>
}
    80003ef2:	60a2                	ld	ra,8(sp)
    80003ef4:	6402                	ld	s0,0(sp)
    80003ef6:	0141                	addi	sp,sp,16
    80003ef8:	8082                	ret

0000000080003efa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003efa:	1101                	addi	sp,sp,-32
    80003efc:	ec06                	sd	ra,24(sp)
    80003efe:	e822                	sd	s0,16(sp)
    80003f00:	e426                	sd	s1,8(sp)
    80003f02:	e04a                	sd	s2,0(sp)
    80003f04:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f06:	0001d917          	auipc	s2,0x1d
    80003f0a:	36a90913          	addi	s2,s2,874 # 80021270 <log>
    80003f0e:	01892583          	lw	a1,24(s2)
    80003f12:	02892503          	lw	a0,40(s2)
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	ff2080e7          	jalr	-14(ra) # 80002f08 <bread>
    80003f1e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f20:	02c92683          	lw	a3,44(s2)
    80003f24:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f26:	02d05763          	blez	a3,80003f54 <write_head+0x5a>
    80003f2a:	0001d797          	auipc	a5,0x1d
    80003f2e:	37678793          	addi	a5,a5,886 # 800212a0 <log+0x30>
    80003f32:	05c50713          	addi	a4,a0,92
    80003f36:	36fd                	addiw	a3,a3,-1
    80003f38:	1682                	slli	a3,a3,0x20
    80003f3a:	9281                	srli	a3,a3,0x20
    80003f3c:	068a                	slli	a3,a3,0x2
    80003f3e:	0001d617          	auipc	a2,0x1d
    80003f42:	36660613          	addi	a2,a2,870 # 800212a4 <log+0x34>
    80003f46:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f48:	4390                	lw	a2,0(a5)
    80003f4a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f4c:	0791                	addi	a5,a5,4
    80003f4e:	0711                	addi	a4,a4,4
    80003f50:	fed79ce3          	bne	a5,a3,80003f48 <write_head+0x4e>
  }
  bwrite(buf);
    80003f54:	8526                	mv	a0,s1
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	0a4080e7          	jalr	164(ra) # 80002ffa <bwrite>
  brelse(buf);
    80003f5e:	8526                	mv	a0,s1
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	0d8080e7          	jalr	216(ra) # 80003038 <brelse>
}
    80003f68:	60e2                	ld	ra,24(sp)
    80003f6a:	6442                	ld	s0,16(sp)
    80003f6c:	64a2                	ld	s1,8(sp)
    80003f6e:	6902                	ld	s2,0(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f74:	0001d797          	auipc	a5,0x1d
    80003f78:	3287a783          	lw	a5,808(a5) # 8002129c <log+0x2c>
    80003f7c:	0af05d63          	blez	a5,80004036 <install_trans+0xc2>
{
    80003f80:	7139                	addi	sp,sp,-64
    80003f82:	fc06                	sd	ra,56(sp)
    80003f84:	f822                	sd	s0,48(sp)
    80003f86:	f426                	sd	s1,40(sp)
    80003f88:	f04a                	sd	s2,32(sp)
    80003f8a:	ec4e                	sd	s3,24(sp)
    80003f8c:	e852                	sd	s4,16(sp)
    80003f8e:	e456                	sd	s5,8(sp)
    80003f90:	e05a                	sd	s6,0(sp)
    80003f92:	0080                	addi	s0,sp,64
    80003f94:	8b2a                	mv	s6,a0
    80003f96:	0001da97          	auipc	s5,0x1d
    80003f9a:	30aa8a93          	addi	s5,s5,778 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f9e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fa0:	0001d997          	auipc	s3,0x1d
    80003fa4:	2d098993          	addi	s3,s3,720 # 80021270 <log>
    80003fa8:	a035                	j	80003fd4 <install_trans+0x60>
      bunpin(dbuf);
    80003faa:	8526                	mv	a0,s1
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	166080e7          	jalr	358(ra) # 80003112 <bunpin>
    brelse(lbuf);
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	082080e7          	jalr	130(ra) # 80003038 <brelse>
    brelse(dbuf);
    80003fbe:	8526                	mv	a0,s1
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	078080e7          	jalr	120(ra) # 80003038 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc8:	2a05                	addiw	s4,s4,1
    80003fca:	0a91                	addi	s5,s5,4
    80003fcc:	02c9a783          	lw	a5,44(s3)
    80003fd0:	04fa5963          	bge	s4,a5,80004022 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd4:	0189a583          	lw	a1,24(s3)
    80003fd8:	014585bb          	addw	a1,a1,s4
    80003fdc:	2585                	addiw	a1,a1,1
    80003fde:	0289a503          	lw	a0,40(s3)
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	f26080e7          	jalr	-218(ra) # 80002f08 <bread>
    80003fea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fec:	000aa583          	lw	a1,0(s5)
    80003ff0:	0289a503          	lw	a0,40(s3)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	f14080e7          	jalr	-236(ra) # 80002f08 <bread>
    80003ffc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ffe:	40000613          	li	a2,1024
    80004002:	05890593          	addi	a1,s2,88
    80004006:	05850513          	addi	a0,a0,88
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	d36080e7          	jalr	-714(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	fe6080e7          	jalr	-26(ra) # 80002ffa <bwrite>
    if(recovering == 0)
    8000401c:	f80b1ce3          	bnez	s6,80003fb4 <install_trans+0x40>
    80004020:	b769                	j	80003faa <install_trans+0x36>
}
    80004022:	70e2                	ld	ra,56(sp)
    80004024:	7442                	ld	s0,48(sp)
    80004026:	74a2                	ld	s1,40(sp)
    80004028:	7902                	ld	s2,32(sp)
    8000402a:	69e2                	ld	s3,24(sp)
    8000402c:	6a42                	ld	s4,16(sp)
    8000402e:	6aa2                	ld	s5,8(sp)
    80004030:	6b02                	ld	s6,0(sp)
    80004032:	6121                	addi	sp,sp,64
    80004034:	8082                	ret
    80004036:	8082                	ret

0000000080004038 <initlog>:
{
    80004038:	7179                	addi	sp,sp,-48
    8000403a:	f406                	sd	ra,40(sp)
    8000403c:	f022                	sd	s0,32(sp)
    8000403e:	ec26                	sd	s1,24(sp)
    80004040:	e84a                	sd	s2,16(sp)
    80004042:	e44e                	sd	s3,8(sp)
    80004044:	1800                	addi	s0,sp,48
    80004046:	892a                	mv	s2,a0
    80004048:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000404a:	0001d497          	auipc	s1,0x1d
    8000404e:	22648493          	addi	s1,s1,550 # 80021270 <log>
    80004052:	00004597          	auipc	a1,0x4
    80004056:	5e658593          	addi	a1,a1,1510 # 80008638 <syscalls+0x1e8>
    8000405a:	8526                	mv	a0,s1
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	af8080e7          	jalr	-1288(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004064:	0149a583          	lw	a1,20(s3)
    80004068:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000406a:	0109a783          	lw	a5,16(s3)
    8000406e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004070:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004074:	854a                	mv	a0,s2
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	e92080e7          	jalr	-366(ra) # 80002f08 <bread>
  log.lh.n = lh->n;
    8000407e:	4d3c                	lw	a5,88(a0)
    80004080:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004082:	02f05563          	blez	a5,800040ac <initlog+0x74>
    80004086:	05c50713          	addi	a4,a0,92
    8000408a:	0001d697          	auipc	a3,0x1d
    8000408e:	21668693          	addi	a3,a3,534 # 800212a0 <log+0x30>
    80004092:	37fd                	addiw	a5,a5,-1
    80004094:	1782                	slli	a5,a5,0x20
    80004096:	9381                	srli	a5,a5,0x20
    80004098:	078a                	slli	a5,a5,0x2
    8000409a:	06050613          	addi	a2,a0,96
    8000409e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040a0:	4310                	lw	a2,0(a4)
    800040a2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040a4:	0711                	addi	a4,a4,4
    800040a6:	0691                	addi	a3,a3,4
    800040a8:	fef71ce3          	bne	a4,a5,800040a0 <initlog+0x68>
  brelse(buf);
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	f8c080e7          	jalr	-116(ra) # 80003038 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040b4:	4505                	li	a0,1
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	ebe080e7          	jalr	-322(ra) # 80003f74 <install_trans>
  log.lh.n = 0;
    800040be:	0001d797          	auipc	a5,0x1d
    800040c2:	1c07af23          	sw	zero,478(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	e34080e7          	jalr	-460(ra) # 80003efa <write_head>
}
    800040ce:	70a2                	ld	ra,40(sp)
    800040d0:	7402                	ld	s0,32(sp)
    800040d2:	64e2                	ld	s1,24(sp)
    800040d4:	6942                	ld	s2,16(sp)
    800040d6:	69a2                	ld	s3,8(sp)
    800040d8:	6145                	addi	sp,sp,48
    800040da:	8082                	ret

00000000800040dc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040dc:	1101                	addi	sp,sp,-32
    800040de:	ec06                	sd	ra,24(sp)
    800040e0:	e822                	sd	s0,16(sp)
    800040e2:	e426                	sd	s1,8(sp)
    800040e4:	e04a                	sd	s2,0(sp)
    800040e6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040e8:	0001d517          	auipc	a0,0x1d
    800040ec:	18850513          	addi	a0,a0,392 # 80021270 <log>
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	af4080e7          	jalr	-1292(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040f8:	0001d497          	auipc	s1,0x1d
    800040fc:	17848493          	addi	s1,s1,376 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004100:	4979                	li	s2,30
    80004102:	a039                	j	80004110 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004104:	85a6                	mv	a1,s1
    80004106:	8526                	mv	a0,s1
    80004108:	ffffe097          	auipc	ra,0xffffe
    8000410c:	0c8080e7          	jalr	200(ra) # 800021d0 <sleep>
    if(log.committing){
    80004110:	50dc                	lw	a5,36(s1)
    80004112:	fbed                	bnez	a5,80004104 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004114:	509c                	lw	a5,32(s1)
    80004116:	0017871b          	addiw	a4,a5,1
    8000411a:	0007069b          	sext.w	a3,a4
    8000411e:	0027179b          	slliw	a5,a4,0x2
    80004122:	9fb9                	addw	a5,a5,a4
    80004124:	0017979b          	slliw	a5,a5,0x1
    80004128:	54d8                	lw	a4,44(s1)
    8000412a:	9fb9                	addw	a5,a5,a4
    8000412c:	00f95963          	bge	s2,a5,8000413e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004130:	85a6                	mv	a1,s1
    80004132:	8526                	mv	a0,s1
    80004134:	ffffe097          	auipc	ra,0xffffe
    80004138:	09c080e7          	jalr	156(ra) # 800021d0 <sleep>
    8000413c:	bfd1                	j	80004110 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000413e:	0001d517          	auipc	a0,0x1d
    80004142:	13250513          	addi	a0,a0,306 # 80021270 <log>
    80004146:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004150:	60e2                	ld	ra,24(sp)
    80004152:	6442                	ld	s0,16(sp)
    80004154:	64a2                	ld	s1,8(sp)
    80004156:	6902                	ld	s2,0(sp)
    80004158:	6105                	addi	sp,sp,32
    8000415a:	8082                	ret

000000008000415c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000415c:	7139                	addi	sp,sp,-64
    8000415e:	fc06                	sd	ra,56(sp)
    80004160:	f822                	sd	s0,48(sp)
    80004162:	f426                	sd	s1,40(sp)
    80004164:	f04a                	sd	s2,32(sp)
    80004166:	ec4e                	sd	s3,24(sp)
    80004168:	e852                	sd	s4,16(sp)
    8000416a:	e456                	sd	s5,8(sp)
    8000416c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000416e:	0001d497          	auipc	s1,0x1d
    80004172:	10248493          	addi	s1,s1,258 # 80021270 <log>
    80004176:	8526                	mv	a0,s1
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004180:	509c                	lw	a5,32(s1)
    80004182:	37fd                	addiw	a5,a5,-1
    80004184:	0007891b          	sext.w	s2,a5
    80004188:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000418a:	50dc                	lw	a5,36(s1)
    8000418c:	efb9                	bnez	a5,800041ea <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000418e:	06091663          	bnez	s2,800041fa <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004192:	0001d497          	auipc	s1,0x1d
    80004196:	0de48493          	addi	s1,s1,222 # 80021270 <log>
    8000419a:	4785                	li	a5,1
    8000419c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	af8080e7          	jalr	-1288(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041a8:	54dc                	lw	a5,44(s1)
    800041aa:	06f04763          	bgtz	a5,80004218 <end_op+0xbc>
    acquire(&log.lock);
    800041ae:	0001d497          	auipc	s1,0x1d
    800041b2:	0c248493          	addi	s1,s1,194 # 80021270 <log>
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	a2c080e7          	jalr	-1492(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041c0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041c4:	8526                	mv	a0,s1
    800041c6:	ffffe097          	auipc	ra,0xffffe
    800041ca:	196080e7          	jalr	406(ra) # 8000235c <wakeup>
    release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ac8080e7          	jalr	-1336(ra) # 80000c98 <release>
}
    800041d8:	70e2                	ld	ra,56(sp)
    800041da:	7442                	ld	s0,48(sp)
    800041dc:	74a2                	ld	s1,40(sp)
    800041de:	7902                	ld	s2,32(sp)
    800041e0:	69e2                	ld	s3,24(sp)
    800041e2:	6a42                	ld	s4,16(sp)
    800041e4:	6aa2                	ld	s5,8(sp)
    800041e6:	6121                	addi	sp,sp,64
    800041e8:	8082                	ret
    panic("log.committing");
    800041ea:	00004517          	auipc	a0,0x4
    800041ee:	45650513          	addi	a0,a0,1110 # 80008640 <syscalls+0x1f0>
    800041f2:	ffffc097          	auipc	ra,0xffffc
    800041f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>
    wakeup(&log);
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	07648493          	addi	s1,s1,118 # 80021270 <log>
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	158080e7          	jalr	344(ra) # 8000235c <wakeup>
  release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
  if(do_commit){
    80004216:	b7c9                	j	800041d8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004218:	0001da97          	auipc	s5,0x1d
    8000421c:	088a8a93          	addi	s5,s5,136 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004220:	0001da17          	auipc	s4,0x1d
    80004224:	050a0a13          	addi	s4,s4,80 # 80021270 <log>
    80004228:	018a2583          	lw	a1,24(s4)
    8000422c:	012585bb          	addw	a1,a1,s2
    80004230:	2585                	addiw	a1,a1,1
    80004232:	028a2503          	lw	a0,40(s4)
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	cd2080e7          	jalr	-814(ra) # 80002f08 <bread>
    8000423e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004240:	000aa583          	lw	a1,0(s5)
    80004244:	028a2503          	lw	a0,40(s4)
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	cc0080e7          	jalr	-832(ra) # 80002f08 <bread>
    80004250:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004252:	40000613          	li	a2,1024
    80004256:	05850593          	addi	a1,a0,88
    8000425a:	05848513          	addi	a0,s1,88
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	ae2080e7          	jalr	-1310(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004266:	8526                	mv	a0,s1
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	d92080e7          	jalr	-622(ra) # 80002ffa <bwrite>
    brelse(from);
    80004270:	854e                	mv	a0,s3
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	dc6080e7          	jalr	-570(ra) # 80003038 <brelse>
    brelse(to);
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	dbc080e7          	jalr	-580(ra) # 80003038 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004284:	2905                	addiw	s2,s2,1
    80004286:	0a91                	addi	s5,s5,4
    80004288:	02ca2783          	lw	a5,44(s4)
    8000428c:	f8f94ee3          	blt	s2,a5,80004228 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004290:	00000097          	auipc	ra,0x0
    80004294:	c6a080e7          	jalr	-918(ra) # 80003efa <write_head>
    install_trans(0); // Now install writes to home locations
    80004298:	4501                	li	a0,0
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	cda080e7          	jalr	-806(ra) # 80003f74 <install_trans>
    log.lh.n = 0;
    800042a2:	0001d797          	auipc	a5,0x1d
    800042a6:	fe07ad23          	sw	zero,-6(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	c50080e7          	jalr	-944(ra) # 80003efa <write_head>
    800042b2:	bdf5                	j	800041ae <end_op+0x52>

00000000800042b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042b4:	1101                	addi	sp,sp,-32
    800042b6:	ec06                	sd	ra,24(sp)
    800042b8:	e822                	sd	s0,16(sp)
    800042ba:	e426                	sd	s1,8(sp)
    800042bc:	e04a                	sd	s2,0(sp)
    800042be:	1000                	addi	s0,sp,32
    800042c0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042c2:	0001d917          	auipc	s2,0x1d
    800042c6:	fae90913          	addi	s2,s2,-82 # 80021270 <log>
    800042ca:	854a                	mv	a0,s2
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	918080e7          	jalr	-1768(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042d4:	02c92603          	lw	a2,44(s2)
    800042d8:	47f5                	li	a5,29
    800042da:	06c7c563          	blt	a5,a2,80004344 <log_write+0x90>
    800042de:	0001d797          	auipc	a5,0x1d
    800042e2:	fae7a783          	lw	a5,-82(a5) # 8002128c <log+0x1c>
    800042e6:	37fd                	addiw	a5,a5,-1
    800042e8:	04f65e63          	bge	a2,a5,80004344 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042ec:	0001d797          	auipc	a5,0x1d
    800042f0:	fa47a783          	lw	a5,-92(a5) # 80021290 <log+0x20>
    800042f4:	06f05063          	blez	a5,80004354 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042f8:	4781                	li	a5,0
    800042fa:	06c05563          	blez	a2,80004364 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042fe:	44cc                	lw	a1,12(s1)
    80004300:	0001d717          	auipc	a4,0x1d
    80004304:	fa070713          	addi	a4,a4,-96 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004308:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000430a:	4314                	lw	a3,0(a4)
    8000430c:	04b68c63          	beq	a3,a1,80004364 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004310:	2785                	addiw	a5,a5,1
    80004312:	0711                	addi	a4,a4,4
    80004314:	fef61be3          	bne	a2,a5,8000430a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004318:	0621                	addi	a2,a2,8
    8000431a:	060a                	slli	a2,a2,0x2
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	f5478793          	addi	a5,a5,-172 # 80021270 <log>
    80004324:	963e                	add	a2,a2,a5
    80004326:	44dc                	lw	a5,12(s1)
    80004328:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000432a:	8526                	mv	a0,s1
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	daa080e7          	jalr	-598(ra) # 800030d6 <bpin>
    log.lh.n++;
    80004334:	0001d717          	auipc	a4,0x1d
    80004338:	f3c70713          	addi	a4,a4,-196 # 80021270 <log>
    8000433c:	575c                	lw	a5,44(a4)
    8000433e:	2785                	addiw	a5,a5,1
    80004340:	d75c                	sw	a5,44(a4)
    80004342:	a835                	j	8000437e <log_write+0xca>
    panic("too big a transaction");
    80004344:	00004517          	auipc	a0,0x4
    80004348:	30c50513          	addi	a0,a0,780 # 80008650 <syscalls+0x200>
    8000434c:	ffffc097          	auipc	ra,0xffffc
    80004350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004354:	00004517          	auipc	a0,0x4
    80004358:	31450513          	addi	a0,a0,788 # 80008668 <syscalls+0x218>
    8000435c:	ffffc097          	auipc	ra,0xffffc
    80004360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004364:	00878713          	addi	a4,a5,8
    80004368:	00271693          	slli	a3,a4,0x2
    8000436c:	0001d717          	auipc	a4,0x1d
    80004370:	f0470713          	addi	a4,a4,-252 # 80021270 <log>
    80004374:	9736                	add	a4,a4,a3
    80004376:	44d4                	lw	a3,12(s1)
    80004378:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000437a:	faf608e3          	beq	a2,a5,8000432a <log_write+0x76>
  }
  release(&log.lock);
    8000437e:	0001d517          	auipc	a0,0x1d
    80004382:	ef250513          	addi	a0,a0,-270 # 80021270 <log>
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
}
    8000438e:	60e2                	ld	ra,24(sp)
    80004390:	6442                	ld	s0,16(sp)
    80004392:	64a2                	ld	s1,8(sp)
    80004394:	6902                	ld	s2,0(sp)
    80004396:	6105                	addi	sp,sp,32
    80004398:	8082                	ret

000000008000439a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000439a:	1101                	addi	sp,sp,-32
    8000439c:	ec06                	sd	ra,24(sp)
    8000439e:	e822                	sd	s0,16(sp)
    800043a0:	e426                	sd	s1,8(sp)
    800043a2:	e04a                	sd	s2,0(sp)
    800043a4:	1000                	addi	s0,sp,32
    800043a6:	84aa                	mv	s1,a0
    800043a8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043aa:	00004597          	auipc	a1,0x4
    800043ae:	2de58593          	addi	a1,a1,734 # 80008688 <syscalls+0x238>
    800043b2:	0521                	addi	a0,a0,8
    800043b4:	ffffc097          	auipc	ra,0xffffc
    800043b8:	7a0080e7          	jalr	1952(ra) # 80000b54 <initlock>
  lk->name = name;
    800043bc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043c4:	0204a423          	sw	zero,40(s1)
}
    800043c8:	60e2                	ld	ra,24(sp)
    800043ca:	6442                	ld	s0,16(sp)
    800043cc:	64a2                	ld	s1,8(sp)
    800043ce:	6902                	ld	s2,0(sp)
    800043d0:	6105                	addi	sp,sp,32
    800043d2:	8082                	ret

00000000800043d4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043d4:	1101                	addi	sp,sp,-32
    800043d6:	ec06                	sd	ra,24(sp)
    800043d8:	e822                	sd	s0,16(sp)
    800043da:	e426                	sd	s1,8(sp)
    800043dc:	e04a                	sd	s2,0(sp)
    800043de:	1000                	addi	s0,sp,32
    800043e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043e2:	00850913          	addi	s2,a0,8
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	7fc080e7          	jalr	2044(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043f0:	409c                	lw	a5,0(s1)
    800043f2:	cb89                	beqz	a5,80004404 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043f4:	85ca                	mv	a1,s2
    800043f6:	8526                	mv	a0,s1
    800043f8:	ffffe097          	auipc	ra,0xffffe
    800043fc:	dd8080e7          	jalr	-552(ra) # 800021d0 <sleep>
  while (lk->locked) {
    80004400:	409c                	lw	a5,0(s1)
    80004402:	fbed                	bnez	a5,800043f4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004404:	4785                	li	a5,1
    80004406:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	77e080e7          	jalr	1918(ra) # 80001b86 <myproc>
    80004410:	591c                	lw	a5,48(a0)
    80004412:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004414:	854a                	mv	a0,s2
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	882080e7          	jalr	-1918(ra) # 80000c98 <release>
}
    8000441e:	60e2                	ld	ra,24(sp)
    80004420:	6442                	ld	s0,16(sp)
    80004422:	64a2                	ld	s1,8(sp)
    80004424:	6902                	ld	s2,0(sp)
    80004426:	6105                	addi	sp,sp,32
    80004428:	8082                	ret

000000008000442a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	e04a                	sd	s2,0(sp)
    80004434:	1000                	addi	s0,sp,32
    80004436:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004438:	00850913          	addi	s2,a0,8
    8000443c:	854a                	mv	a0,s2
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	7a6080e7          	jalr	1958(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004446:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000444a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffe097          	auipc	ra,0xffffe
    80004454:	f0c080e7          	jalr	-244(ra) # 8000235c <wakeup>
  release(&lk->lk);
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
}
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6902                	ld	s2,0(sp)
    8000446a:	6105                	addi	sp,sp,32
    8000446c:	8082                	ret

000000008000446e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000446e:	7179                	addi	sp,sp,-48
    80004470:	f406                	sd	ra,40(sp)
    80004472:	f022                	sd	s0,32(sp)
    80004474:	ec26                	sd	s1,24(sp)
    80004476:	e84a                	sd	s2,16(sp)
    80004478:	e44e                	sd	s3,8(sp)
    8000447a:	1800                	addi	s0,sp,48
    8000447c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000447e:	00850913          	addi	s2,a0,8
    80004482:	854a                	mv	a0,s2
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	760080e7          	jalr	1888(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000448c:	409c                	lw	a5,0(s1)
    8000448e:	ef99                	bnez	a5,800044ac <holdingsleep+0x3e>
    80004490:	4481                	li	s1,0
  release(&lk->lk);
    80004492:	854a                	mv	a0,s2
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  return r;
}
    8000449c:	8526                	mv	a0,s1
    8000449e:	70a2                	ld	ra,40(sp)
    800044a0:	7402                	ld	s0,32(sp)
    800044a2:	64e2                	ld	s1,24(sp)
    800044a4:	6942                	ld	s2,16(sp)
    800044a6:	69a2                	ld	s3,8(sp)
    800044a8:	6145                	addi	sp,sp,48
    800044aa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ac:	0284a983          	lw	s3,40(s1)
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	6d6080e7          	jalr	1750(ra) # 80001b86 <myproc>
    800044b8:	5904                	lw	s1,48(a0)
    800044ba:	413484b3          	sub	s1,s1,s3
    800044be:	0014b493          	seqz	s1,s1
    800044c2:	bfc1                	j	80004492 <holdingsleep+0x24>

00000000800044c4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044c4:	1141                	addi	sp,sp,-16
    800044c6:	e406                	sd	ra,8(sp)
    800044c8:	e022                	sd	s0,0(sp)
    800044ca:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044cc:	00004597          	auipc	a1,0x4
    800044d0:	1cc58593          	addi	a1,a1,460 # 80008698 <syscalls+0x248>
    800044d4:	0001d517          	auipc	a0,0x1d
    800044d8:	ee450513          	addi	a0,a0,-284 # 800213b8 <ftable>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	678080e7          	jalr	1656(ra) # 80000b54 <initlock>
}
    800044e4:	60a2                	ld	ra,8(sp)
    800044e6:	6402                	ld	s0,0(sp)
    800044e8:	0141                	addi	sp,sp,16
    800044ea:	8082                	ret

00000000800044ec <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	ec250513          	addi	a0,a0,-318 # 800213b8 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6e6080e7          	jalr	1766(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004506:	0001d497          	auipc	s1,0x1d
    8000450a:	eca48493          	addi	s1,s1,-310 # 800213d0 <ftable+0x18>
    8000450e:	0001e717          	auipc	a4,0x1e
    80004512:	e6270713          	addi	a4,a4,-414 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004516:	40dc                	lw	a5,4(s1)
    80004518:	cf99                	beqz	a5,80004536 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000451a:	02848493          	addi	s1,s1,40
    8000451e:	fee49ce3          	bne	s1,a4,80004516 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004522:	0001d517          	auipc	a0,0x1d
    80004526:	e9650513          	addi	a0,a0,-362 # 800213b8 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
  return 0;
    80004532:	4481                	li	s1,0
    80004534:	a819                	j	8000454a <filealloc+0x5e>
      f->ref = 1;
    80004536:	4785                	li	a5,1
    80004538:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	e7e50513          	addi	a0,a0,-386 # 800213b8 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	756080e7          	jalr	1878(ra) # 80000c98 <release>
}
    8000454a:	8526                	mv	a0,s1
    8000454c:	60e2                	ld	ra,24(sp)
    8000454e:	6442                	ld	s0,16(sp)
    80004550:	64a2                	ld	s1,8(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004556:	1101                	addi	sp,sp,-32
    80004558:	ec06                	sd	ra,24(sp)
    8000455a:	e822                	sd	s0,16(sp)
    8000455c:	e426                	sd	s1,8(sp)
    8000455e:	1000                	addi	s0,sp,32
    80004560:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	e5650513          	addi	a0,a0,-426 # 800213b8 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	67a080e7          	jalr	1658(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004572:	40dc                	lw	a5,4(s1)
    80004574:	02f05263          	blez	a5,80004598 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004578:	2785                	addiw	a5,a5,1
    8000457a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000457c:	0001d517          	auipc	a0,0x1d
    80004580:	e3c50513          	addi	a0,a0,-452 # 800213b8 <ftable>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	714080e7          	jalr	1812(ra) # 80000c98 <release>
  return f;
}
    8000458c:	8526                	mv	a0,s1
    8000458e:	60e2                	ld	ra,24(sp)
    80004590:	6442                	ld	s0,16(sp)
    80004592:	64a2                	ld	s1,8(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret
    panic("filedup");
    80004598:	00004517          	auipc	a0,0x4
    8000459c:	10850513          	addi	a0,a0,264 # 800086a0 <syscalls+0x250>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	f9e080e7          	jalr	-98(ra) # 8000053e <panic>

00000000800045a8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045a8:	7139                	addi	sp,sp,-64
    800045aa:	fc06                	sd	ra,56(sp)
    800045ac:	f822                	sd	s0,48(sp)
    800045ae:	f426                	sd	s1,40(sp)
    800045b0:	f04a                	sd	s2,32(sp)
    800045b2:	ec4e                	sd	s3,24(sp)
    800045b4:	e852                	sd	s4,16(sp)
    800045b6:	e456                	sd	s5,8(sp)
    800045b8:	0080                	addi	s0,sp,64
    800045ba:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045bc:	0001d517          	auipc	a0,0x1d
    800045c0:	dfc50513          	addi	a0,a0,-516 # 800213b8 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	620080e7          	jalr	1568(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045cc:	40dc                	lw	a5,4(s1)
    800045ce:	06f05163          	blez	a5,80004630 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045d2:	37fd                	addiw	a5,a5,-1
    800045d4:	0007871b          	sext.w	a4,a5
    800045d8:	c0dc                	sw	a5,4(s1)
    800045da:	06e04363          	bgtz	a4,80004640 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045de:	0004a903          	lw	s2,0(s1)
    800045e2:	0094ca83          	lbu	s5,9(s1)
    800045e6:	0104ba03          	ld	s4,16(s1)
    800045ea:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045ee:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045f2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	dc250513          	addi	a0,a0,-574 # 800213b8 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	69a080e7          	jalr	1690(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004606:	4785                	li	a5,1
    80004608:	04f90d63          	beq	s2,a5,80004662 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000460c:	3979                	addiw	s2,s2,-2
    8000460e:	4785                	li	a5,1
    80004610:	0527e063          	bltu	a5,s2,80004650 <fileclose+0xa8>
    begin_op();
    80004614:	00000097          	auipc	ra,0x0
    80004618:	ac8080e7          	jalr	-1336(ra) # 800040dc <begin_op>
    iput(ff.ip);
    8000461c:	854e                	mv	a0,s3
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	2a6080e7          	jalr	678(ra) # 800038c4 <iput>
    end_op();
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	b36080e7          	jalr	-1226(ra) # 8000415c <end_op>
    8000462e:	a00d                	j	80004650 <fileclose+0xa8>
    panic("fileclose");
    80004630:	00004517          	auipc	a0,0x4
    80004634:	07850513          	addi	a0,a0,120 # 800086a8 <syscalls+0x258>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004640:	0001d517          	auipc	a0,0x1d
    80004644:	d7850513          	addi	a0,a0,-648 # 800213b8 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	650080e7          	jalr	1616(ra) # 80000c98 <release>
  }
}
    80004650:	70e2                	ld	ra,56(sp)
    80004652:	7442                	ld	s0,48(sp)
    80004654:	74a2                	ld	s1,40(sp)
    80004656:	7902                	ld	s2,32(sp)
    80004658:	69e2                	ld	s3,24(sp)
    8000465a:	6a42                	ld	s4,16(sp)
    8000465c:	6aa2                	ld	s5,8(sp)
    8000465e:	6121                	addi	sp,sp,64
    80004660:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004662:	85d6                	mv	a1,s5
    80004664:	8552                	mv	a0,s4
    80004666:	00000097          	auipc	ra,0x0
    8000466a:	34c080e7          	jalr	844(ra) # 800049b2 <pipeclose>
    8000466e:	b7cd                	j	80004650 <fileclose+0xa8>

0000000080004670 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004670:	715d                	addi	sp,sp,-80
    80004672:	e486                	sd	ra,72(sp)
    80004674:	e0a2                	sd	s0,64(sp)
    80004676:	fc26                	sd	s1,56(sp)
    80004678:	f84a                	sd	s2,48(sp)
    8000467a:	f44e                	sd	s3,40(sp)
    8000467c:	0880                	addi	s0,sp,80
    8000467e:	84aa                	mv	s1,a0
    80004680:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004682:	ffffd097          	auipc	ra,0xffffd
    80004686:	504080e7          	jalr	1284(ra) # 80001b86 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000468a:	409c                	lw	a5,0(s1)
    8000468c:	37f9                	addiw	a5,a5,-2
    8000468e:	4705                	li	a4,1
    80004690:	04f76763          	bltu	a4,a5,800046de <filestat+0x6e>
    80004694:	892a                	mv	s2,a0
    ilock(f->ip);
    80004696:	6c88                	ld	a0,24(s1)
    80004698:	fffff097          	auipc	ra,0xfffff
    8000469c:	072080e7          	jalr	114(ra) # 8000370a <ilock>
    stati(f->ip, &st);
    800046a0:	fb840593          	addi	a1,s0,-72
    800046a4:	6c88                	ld	a0,24(s1)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	2ee080e7          	jalr	750(ra) # 80003994 <stati>
    iunlock(f->ip);
    800046ae:	6c88                	ld	a0,24(s1)
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	11c080e7          	jalr	284(ra) # 800037cc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046b8:	46e1                	li	a3,24
    800046ba:	fb840613          	addi	a2,s0,-72
    800046be:	85ce                	mv	a1,s3
    800046c0:	05093503          	ld	a0,80(s2)
    800046c4:	ffffd097          	auipc	ra,0xffffd
    800046c8:	fae080e7          	jalr	-82(ra) # 80001672 <copyout>
    800046cc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046d0:	60a6                	ld	ra,72(sp)
    800046d2:	6406                	ld	s0,64(sp)
    800046d4:	74e2                	ld	s1,56(sp)
    800046d6:	7942                	ld	s2,48(sp)
    800046d8:	79a2                	ld	s3,40(sp)
    800046da:	6161                	addi	sp,sp,80
    800046dc:	8082                	ret
  return -1;
    800046de:	557d                	li	a0,-1
    800046e0:	bfc5                	j	800046d0 <filestat+0x60>

00000000800046e2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046e2:	7179                	addi	sp,sp,-48
    800046e4:	f406                	sd	ra,40(sp)
    800046e6:	f022                	sd	s0,32(sp)
    800046e8:	ec26                	sd	s1,24(sp)
    800046ea:	e84a                	sd	s2,16(sp)
    800046ec:	e44e                	sd	s3,8(sp)
    800046ee:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046f0:	00854783          	lbu	a5,8(a0)
    800046f4:	c3d5                	beqz	a5,80004798 <fileread+0xb6>
    800046f6:	84aa                	mv	s1,a0
    800046f8:	89ae                	mv	s3,a1
    800046fa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046fc:	411c                	lw	a5,0(a0)
    800046fe:	4705                	li	a4,1
    80004700:	04e78963          	beq	a5,a4,80004752 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004704:	470d                	li	a4,3
    80004706:	04e78d63          	beq	a5,a4,80004760 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000470a:	4709                	li	a4,2
    8000470c:	06e79e63          	bne	a5,a4,80004788 <fileread+0xa6>
    ilock(f->ip);
    80004710:	6d08                	ld	a0,24(a0)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	ff8080e7          	jalr	-8(ra) # 8000370a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000471a:	874a                	mv	a4,s2
    8000471c:	5094                	lw	a3,32(s1)
    8000471e:	864e                	mv	a2,s3
    80004720:	4585                	li	a1,1
    80004722:	6c88                	ld	a0,24(s1)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	29a080e7          	jalr	666(ra) # 800039be <readi>
    8000472c:	892a                	mv	s2,a0
    8000472e:	00a05563          	blez	a0,80004738 <fileread+0x56>
      f->off += r;
    80004732:	509c                	lw	a5,32(s1)
    80004734:	9fa9                	addw	a5,a5,a0
    80004736:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	092080e7          	jalr	146(ra) # 800037cc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004742:	854a                	mv	a0,s2
    80004744:	70a2                	ld	ra,40(sp)
    80004746:	7402                	ld	s0,32(sp)
    80004748:	64e2                	ld	s1,24(sp)
    8000474a:	6942                	ld	s2,16(sp)
    8000474c:	69a2                	ld	s3,8(sp)
    8000474e:	6145                	addi	sp,sp,48
    80004750:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004752:	6908                	ld	a0,16(a0)
    80004754:	00000097          	auipc	ra,0x0
    80004758:	3c8080e7          	jalr	968(ra) # 80004b1c <piperead>
    8000475c:	892a                	mv	s2,a0
    8000475e:	b7d5                	j	80004742 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004760:	02451783          	lh	a5,36(a0)
    80004764:	03079693          	slli	a3,a5,0x30
    80004768:	92c1                	srli	a3,a3,0x30
    8000476a:	4725                	li	a4,9
    8000476c:	02d76863          	bltu	a4,a3,8000479c <fileread+0xba>
    80004770:	0792                	slli	a5,a5,0x4
    80004772:	0001d717          	auipc	a4,0x1d
    80004776:	ba670713          	addi	a4,a4,-1114 # 80021318 <devsw>
    8000477a:	97ba                	add	a5,a5,a4
    8000477c:	639c                	ld	a5,0(a5)
    8000477e:	c38d                	beqz	a5,800047a0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004780:	4505                	li	a0,1
    80004782:	9782                	jalr	a5
    80004784:	892a                	mv	s2,a0
    80004786:	bf75                	j	80004742 <fileread+0x60>
    panic("fileread");
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	f3050513          	addi	a0,a0,-208 # 800086b8 <syscalls+0x268>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	dae080e7          	jalr	-594(ra) # 8000053e <panic>
    return -1;
    80004798:	597d                	li	s2,-1
    8000479a:	b765                	j	80004742 <fileread+0x60>
      return -1;
    8000479c:	597d                	li	s2,-1
    8000479e:	b755                	j	80004742 <fileread+0x60>
    800047a0:	597d                	li	s2,-1
    800047a2:	b745                	j	80004742 <fileread+0x60>

00000000800047a4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047a4:	715d                	addi	sp,sp,-80
    800047a6:	e486                	sd	ra,72(sp)
    800047a8:	e0a2                	sd	s0,64(sp)
    800047aa:	fc26                	sd	s1,56(sp)
    800047ac:	f84a                	sd	s2,48(sp)
    800047ae:	f44e                	sd	s3,40(sp)
    800047b0:	f052                	sd	s4,32(sp)
    800047b2:	ec56                	sd	s5,24(sp)
    800047b4:	e85a                	sd	s6,16(sp)
    800047b6:	e45e                	sd	s7,8(sp)
    800047b8:	e062                	sd	s8,0(sp)
    800047ba:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047bc:	00954783          	lbu	a5,9(a0)
    800047c0:	10078663          	beqz	a5,800048cc <filewrite+0x128>
    800047c4:	892a                	mv	s2,a0
    800047c6:	8aae                	mv	s5,a1
    800047c8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ca:	411c                	lw	a5,0(a0)
    800047cc:	4705                	li	a4,1
    800047ce:	02e78263          	beq	a5,a4,800047f2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047d2:	470d                	li	a4,3
    800047d4:	02e78663          	beq	a5,a4,80004800 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d8:	4709                	li	a4,2
    800047da:	0ee79163          	bne	a5,a4,800048bc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047de:	0ac05d63          	blez	a2,80004898 <filewrite+0xf4>
    int i = 0;
    800047e2:	4981                	li	s3,0
    800047e4:	6b05                	lui	s6,0x1
    800047e6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047ea:	6b85                	lui	s7,0x1
    800047ec:	c00b8b9b          	addiw	s7,s7,-1024
    800047f0:	a861                	j	80004888 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047f2:	6908                	ld	a0,16(a0)
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	22e080e7          	jalr	558(ra) # 80004a22 <pipewrite>
    800047fc:	8a2a                	mv	s4,a0
    800047fe:	a045                	j	8000489e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004800:	02451783          	lh	a5,36(a0)
    80004804:	03079693          	slli	a3,a5,0x30
    80004808:	92c1                	srli	a3,a3,0x30
    8000480a:	4725                	li	a4,9
    8000480c:	0cd76263          	bltu	a4,a3,800048d0 <filewrite+0x12c>
    80004810:	0792                	slli	a5,a5,0x4
    80004812:	0001d717          	auipc	a4,0x1d
    80004816:	b0670713          	addi	a4,a4,-1274 # 80021318 <devsw>
    8000481a:	97ba                	add	a5,a5,a4
    8000481c:	679c                	ld	a5,8(a5)
    8000481e:	cbdd                	beqz	a5,800048d4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004820:	4505                	li	a0,1
    80004822:	9782                	jalr	a5
    80004824:	8a2a                	mv	s4,a0
    80004826:	a8a5                	j	8000489e <filewrite+0xfa>
    80004828:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	8b0080e7          	jalr	-1872(ra) # 800040dc <begin_op>
      ilock(f->ip);
    80004834:	01893503          	ld	a0,24(s2)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	ed2080e7          	jalr	-302(ra) # 8000370a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004840:	8762                	mv	a4,s8
    80004842:	02092683          	lw	a3,32(s2)
    80004846:	01598633          	add	a2,s3,s5
    8000484a:	4585                	li	a1,1
    8000484c:	01893503          	ld	a0,24(s2)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	266080e7          	jalr	614(ra) # 80003ab6 <writei>
    80004858:	84aa                	mv	s1,a0
    8000485a:	00a05763          	blez	a0,80004868 <filewrite+0xc4>
        f->off += r;
    8000485e:	02092783          	lw	a5,32(s2)
    80004862:	9fa9                	addw	a5,a5,a0
    80004864:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	f60080e7          	jalr	-160(ra) # 800037cc <iunlock>
      end_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	8e8080e7          	jalr	-1816(ra) # 8000415c <end_op>

      if(r != n1){
    8000487c:	009c1f63          	bne	s8,s1,8000489a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004880:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004884:	0149db63          	bge	s3,s4,8000489a <filewrite+0xf6>
      int n1 = n - i;
    80004888:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000488c:	84be                	mv	s1,a5
    8000488e:	2781                	sext.w	a5,a5
    80004890:	f8fb5ce3          	bge	s6,a5,80004828 <filewrite+0x84>
    80004894:	84de                	mv	s1,s7
    80004896:	bf49                	j	80004828 <filewrite+0x84>
    int i = 0;
    80004898:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000489a:	013a1f63          	bne	s4,s3,800048b8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000489e:	8552                	mv	a0,s4
    800048a0:	60a6                	ld	ra,72(sp)
    800048a2:	6406                	ld	s0,64(sp)
    800048a4:	74e2                	ld	s1,56(sp)
    800048a6:	7942                	ld	s2,48(sp)
    800048a8:	79a2                	ld	s3,40(sp)
    800048aa:	7a02                	ld	s4,32(sp)
    800048ac:	6ae2                	ld	s5,24(sp)
    800048ae:	6b42                	ld	s6,16(sp)
    800048b0:	6ba2                	ld	s7,8(sp)
    800048b2:	6c02                	ld	s8,0(sp)
    800048b4:	6161                	addi	sp,sp,80
    800048b6:	8082                	ret
    ret = (i == n ? n : -1);
    800048b8:	5a7d                	li	s4,-1
    800048ba:	b7d5                	j	8000489e <filewrite+0xfa>
    panic("filewrite");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	e0c50513          	addi	a0,a0,-500 # 800086c8 <syscalls+0x278>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>
    return -1;
    800048cc:	5a7d                	li	s4,-1
    800048ce:	bfc1                	j	8000489e <filewrite+0xfa>
      return -1;
    800048d0:	5a7d                	li	s4,-1
    800048d2:	b7f1                	j	8000489e <filewrite+0xfa>
    800048d4:	5a7d                	li	s4,-1
    800048d6:	b7e1                	j	8000489e <filewrite+0xfa>

00000000800048d8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d8:	7179                	addi	sp,sp,-48
    800048da:	f406                	sd	ra,40(sp)
    800048dc:	f022                	sd	s0,32(sp)
    800048de:	ec26                	sd	s1,24(sp)
    800048e0:	e84a                	sd	s2,16(sp)
    800048e2:	e44e                	sd	s3,8(sp)
    800048e4:	e052                	sd	s4,0(sp)
    800048e6:	1800                	addi	s0,sp,48
    800048e8:	84aa                	mv	s1,a0
    800048ea:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048ec:	0005b023          	sd	zero,0(a1)
    800048f0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	bf8080e7          	jalr	-1032(ra) # 800044ec <filealloc>
    800048fc:	e088                	sd	a0,0(s1)
    800048fe:	c551                	beqz	a0,8000498a <pipealloc+0xb2>
    80004900:	00000097          	auipc	ra,0x0
    80004904:	bec080e7          	jalr	-1044(ra) # 800044ec <filealloc>
    80004908:	00aa3023          	sd	a0,0(s4)
    8000490c:	c92d                	beqz	a0,8000497e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	1e6080e7          	jalr	486(ra) # 80000af4 <kalloc>
    80004916:	892a                	mv	s2,a0
    80004918:	c125                	beqz	a0,80004978 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000491a:	4985                	li	s3,1
    8000491c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004920:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004924:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004928:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000492c:	00004597          	auipc	a1,0x4
    80004930:	dac58593          	addi	a1,a1,-596 # 800086d8 <syscalls+0x288>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	220080e7          	jalr	544(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000493c:	609c                	ld	a5,0(s1)
    8000493e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004942:	609c                	ld	a5,0(s1)
    80004944:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004948:	609c                	ld	a5,0(s1)
    8000494a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000494e:	609c                	ld	a5,0(s1)
    80004950:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004954:	000a3783          	ld	a5,0(s4)
    80004958:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000495c:	000a3783          	ld	a5,0(s4)
    80004960:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004964:	000a3783          	ld	a5,0(s4)
    80004968:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000496c:	000a3783          	ld	a5,0(s4)
    80004970:	0127b823          	sd	s2,16(a5)
  return 0;
    80004974:	4501                	li	a0,0
    80004976:	a025                	j	8000499e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004978:	6088                	ld	a0,0(s1)
    8000497a:	e501                	bnez	a0,80004982 <pipealloc+0xaa>
    8000497c:	a039                	j	8000498a <pipealloc+0xb2>
    8000497e:	6088                	ld	a0,0(s1)
    80004980:	c51d                	beqz	a0,800049ae <pipealloc+0xd6>
    fileclose(*f0);
    80004982:	00000097          	auipc	ra,0x0
    80004986:	c26080e7          	jalr	-986(ra) # 800045a8 <fileclose>
  if(*f1)
    8000498a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000498e:	557d                	li	a0,-1
  if(*f1)
    80004990:	c799                	beqz	a5,8000499e <pipealloc+0xc6>
    fileclose(*f1);
    80004992:	853e                	mv	a0,a5
    80004994:	00000097          	auipc	ra,0x0
    80004998:	c14080e7          	jalr	-1004(ra) # 800045a8 <fileclose>
  return -1;
    8000499c:	557d                	li	a0,-1
}
    8000499e:	70a2                	ld	ra,40(sp)
    800049a0:	7402                	ld	s0,32(sp)
    800049a2:	64e2                	ld	s1,24(sp)
    800049a4:	6942                	ld	s2,16(sp)
    800049a6:	69a2                	ld	s3,8(sp)
    800049a8:	6a02                	ld	s4,0(sp)
    800049aa:	6145                	addi	sp,sp,48
    800049ac:	8082                	ret
  return -1;
    800049ae:	557d                	li	a0,-1
    800049b0:	b7fd                	j	8000499e <pipealloc+0xc6>

00000000800049b2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	e04a                	sd	s2,0(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
    800049c0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	222080e7          	jalr	546(ra) # 80000be4 <acquire>
  if(writable){
    800049ca:	02090d63          	beqz	s2,80004a04 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ce:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049d2:	21848513          	addi	a0,s1,536
    800049d6:	ffffe097          	auipc	ra,0xffffe
    800049da:	986080e7          	jalr	-1658(ra) # 8000235c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049de:	2204b783          	ld	a5,544(s1)
    800049e2:	eb95                	bnez	a5,80004a16 <pipeclose+0x64>
    release(&pi->lock);
    800049e4:	8526                	mv	a0,s1
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049ee:	8526                	mv	a0,s1
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	008080e7          	jalr	8(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049f8:	60e2                	ld	ra,24(sp)
    800049fa:	6442                	ld	s0,16(sp)
    800049fc:	64a2                	ld	s1,8(sp)
    800049fe:	6902                	ld	s2,0(sp)
    80004a00:	6105                	addi	sp,sp,32
    80004a02:	8082                	ret
    pi->readopen = 0;
    80004a04:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a08:	21c48513          	addi	a0,s1,540
    80004a0c:	ffffe097          	auipc	ra,0xffffe
    80004a10:	950080e7          	jalr	-1712(ra) # 8000235c <wakeup>
    80004a14:	b7e9                	j	800049de <pipeclose+0x2c>
    release(&pi->lock);
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>
}
    80004a20:	bfe1                	j	800049f8 <pipeclose+0x46>

0000000080004a22 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a22:	7159                	addi	sp,sp,-112
    80004a24:	f486                	sd	ra,104(sp)
    80004a26:	f0a2                	sd	s0,96(sp)
    80004a28:	eca6                	sd	s1,88(sp)
    80004a2a:	e8ca                	sd	s2,80(sp)
    80004a2c:	e4ce                	sd	s3,72(sp)
    80004a2e:	e0d2                	sd	s4,64(sp)
    80004a30:	fc56                	sd	s5,56(sp)
    80004a32:	f85a                	sd	s6,48(sp)
    80004a34:	f45e                	sd	s7,40(sp)
    80004a36:	f062                	sd	s8,32(sp)
    80004a38:	ec66                	sd	s9,24(sp)
    80004a3a:	1880                	addi	s0,sp,112
    80004a3c:	84aa                	mv	s1,a0
    80004a3e:	8aae                	mv	s5,a1
    80004a40:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a42:	ffffd097          	auipc	ra,0xffffd
    80004a46:	144080e7          	jalr	324(ra) # 80001b86 <myproc>
    80004a4a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	196080e7          	jalr	406(ra) # 80000be4 <acquire>
  while(i < n){
    80004a56:	0d405163          	blez	s4,80004b18 <pipewrite+0xf6>
    80004a5a:	8ba6                	mv	s7,s1
  int i = 0;
    80004a5c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a5e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a60:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a64:	21c48c13          	addi	s8,s1,540
    80004a68:	a08d                	j	80004aca <pipewrite+0xa8>
      release(&pi->lock);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	22c080e7          	jalr	556(ra) # 80000c98 <release>
      return -1;
    80004a74:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a76:	854a                	mv	a0,s2
    80004a78:	70a6                	ld	ra,104(sp)
    80004a7a:	7406                	ld	s0,96(sp)
    80004a7c:	64e6                	ld	s1,88(sp)
    80004a7e:	6946                	ld	s2,80(sp)
    80004a80:	69a6                	ld	s3,72(sp)
    80004a82:	6a06                	ld	s4,64(sp)
    80004a84:	7ae2                	ld	s5,56(sp)
    80004a86:	7b42                	ld	s6,48(sp)
    80004a88:	7ba2                	ld	s7,40(sp)
    80004a8a:	7c02                	ld	s8,32(sp)
    80004a8c:	6ce2                	ld	s9,24(sp)
    80004a8e:	6165                	addi	sp,sp,112
    80004a90:	8082                	ret
      wakeup(&pi->nread);
    80004a92:	8566                	mv	a0,s9
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	8c8080e7          	jalr	-1848(ra) # 8000235c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a9c:	85de                	mv	a1,s7
    80004a9e:	8562                	mv	a0,s8
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	730080e7          	jalr	1840(ra) # 800021d0 <sleep>
    80004aa8:	a839                	j	80004ac6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aaa:	21c4a783          	lw	a5,540(s1)
    80004aae:	0017871b          	addiw	a4,a5,1
    80004ab2:	20e4ae23          	sw	a4,540(s1)
    80004ab6:	1ff7f793          	andi	a5,a5,511
    80004aba:	97a6                	add	a5,a5,s1
    80004abc:	f9f44703          	lbu	a4,-97(s0)
    80004ac0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ac4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ac6:	03495d63          	bge	s2,s4,80004b00 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004aca:	2204a783          	lw	a5,544(s1)
    80004ace:	dfd1                	beqz	a5,80004a6a <pipewrite+0x48>
    80004ad0:	0289a783          	lw	a5,40(s3)
    80004ad4:	fbd9                	bnez	a5,80004a6a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ad6:	2184a783          	lw	a5,536(s1)
    80004ada:	21c4a703          	lw	a4,540(s1)
    80004ade:	2007879b          	addiw	a5,a5,512
    80004ae2:	faf708e3          	beq	a4,a5,80004a92 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae6:	4685                	li	a3,1
    80004ae8:	01590633          	add	a2,s2,s5
    80004aec:	f9f40593          	addi	a1,s0,-97
    80004af0:	0509b503          	ld	a0,80(s3)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	c0a080e7          	jalr	-1014(ra) # 800016fe <copyin>
    80004afc:	fb6517e3          	bne	a0,s6,80004aaa <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b00:	21848513          	addi	a0,s1,536
    80004b04:	ffffe097          	auipc	ra,0xffffe
    80004b08:	858080e7          	jalr	-1960(ra) # 8000235c <wakeup>
  release(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
  return i;
    80004b16:	b785                	j	80004a76 <pipewrite+0x54>
  int i = 0;
    80004b18:	4901                	li	s2,0
    80004b1a:	b7dd                	j	80004b00 <pipewrite+0xde>

0000000080004b1c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b1c:	715d                	addi	sp,sp,-80
    80004b1e:	e486                	sd	ra,72(sp)
    80004b20:	e0a2                	sd	s0,64(sp)
    80004b22:	fc26                	sd	s1,56(sp)
    80004b24:	f84a                	sd	s2,48(sp)
    80004b26:	f44e                	sd	s3,40(sp)
    80004b28:	f052                	sd	s4,32(sp)
    80004b2a:	ec56                	sd	s5,24(sp)
    80004b2c:	e85a                	sd	s6,16(sp)
    80004b2e:	0880                	addi	s0,sp,80
    80004b30:	84aa                	mv	s1,a0
    80004b32:	892e                	mv	s2,a1
    80004b34:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	050080e7          	jalr	80(ra) # 80001b86 <myproc>
    80004b3e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b40:	8b26                	mv	s6,s1
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	0a0080e7          	jalr	160(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4c:	2184a703          	lw	a4,536(s1)
    80004b50:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b54:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b58:	02f71463          	bne	a4,a5,80004b80 <piperead+0x64>
    80004b5c:	2244a783          	lw	a5,548(s1)
    80004b60:	c385                	beqz	a5,80004b80 <piperead+0x64>
    if(pr->killed){
    80004b62:	028a2783          	lw	a5,40(s4)
    80004b66:	ebc1                	bnez	a5,80004bf6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b68:	85da                	mv	a1,s6
    80004b6a:	854e                	mv	a0,s3
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	664080e7          	jalr	1636(ra) # 800021d0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b74:	2184a703          	lw	a4,536(s1)
    80004b78:	21c4a783          	lw	a5,540(s1)
    80004b7c:	fef700e3          	beq	a4,a5,80004b5c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b80:	09505263          	blez	s5,80004c04 <piperead+0xe8>
    80004b84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b86:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b88:	2184a783          	lw	a5,536(s1)
    80004b8c:	21c4a703          	lw	a4,540(s1)
    80004b90:	02f70d63          	beq	a4,a5,80004bca <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b94:	0017871b          	addiw	a4,a5,1
    80004b98:	20e4ac23          	sw	a4,536(s1)
    80004b9c:	1ff7f793          	andi	a5,a5,511
    80004ba0:	97a6                	add	a5,a5,s1
    80004ba2:	0187c783          	lbu	a5,24(a5)
    80004ba6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004baa:	4685                	li	a3,1
    80004bac:	fbf40613          	addi	a2,s0,-65
    80004bb0:	85ca                	mv	a1,s2
    80004bb2:	050a3503          	ld	a0,80(s4)
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	abc080e7          	jalr	-1348(ra) # 80001672 <copyout>
    80004bbe:	01650663          	beq	a0,s6,80004bca <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc2:	2985                	addiw	s3,s3,1
    80004bc4:	0905                	addi	s2,s2,1
    80004bc6:	fd3a91e3          	bne	s5,s3,80004b88 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bca:	21c48513          	addi	a0,s1,540
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	78e080e7          	jalr	1934(ra) # 8000235c <wakeup>
  release(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	0c0080e7          	jalr	192(ra) # 80000c98 <release>
  return i;
}
    80004be0:	854e                	mv	a0,s3
    80004be2:	60a6                	ld	ra,72(sp)
    80004be4:	6406                	ld	s0,64(sp)
    80004be6:	74e2                	ld	s1,56(sp)
    80004be8:	7942                	ld	s2,48(sp)
    80004bea:	79a2                	ld	s3,40(sp)
    80004bec:	7a02                	ld	s4,32(sp)
    80004bee:	6ae2                	ld	s5,24(sp)
    80004bf0:	6b42                	ld	s6,16(sp)
    80004bf2:	6161                	addi	sp,sp,80
    80004bf4:	8082                	ret
      release(&pi->lock);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	0a0080e7          	jalr	160(ra) # 80000c98 <release>
      return -1;
    80004c00:	59fd                	li	s3,-1
    80004c02:	bff9                	j	80004be0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c04:	4981                	li	s3,0
    80004c06:	b7d1                	j	80004bca <piperead+0xae>

0000000080004c08 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c08:	df010113          	addi	sp,sp,-528
    80004c0c:	20113423          	sd	ra,520(sp)
    80004c10:	20813023          	sd	s0,512(sp)
    80004c14:	ffa6                	sd	s1,504(sp)
    80004c16:	fbca                	sd	s2,496(sp)
    80004c18:	f7ce                	sd	s3,488(sp)
    80004c1a:	f3d2                	sd	s4,480(sp)
    80004c1c:	efd6                	sd	s5,472(sp)
    80004c1e:	ebda                	sd	s6,464(sp)
    80004c20:	e7de                	sd	s7,456(sp)
    80004c22:	e3e2                	sd	s8,448(sp)
    80004c24:	ff66                	sd	s9,440(sp)
    80004c26:	fb6a                	sd	s10,432(sp)
    80004c28:	f76e                	sd	s11,424(sp)
    80004c2a:	0c00                	addi	s0,sp,528
    80004c2c:	84aa                	mv	s1,a0
    80004c2e:	dea43c23          	sd	a0,-520(s0)
    80004c32:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	f50080e7          	jalr	-176(ra) # 80001b86 <myproc>
    80004c3e:	892a                	mv	s2,a0

  begin_op();
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	49c080e7          	jalr	1180(ra) # 800040dc <begin_op>

  if((ip = namei(path)) == 0){
    80004c48:	8526                	mv	a0,s1
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	276080e7          	jalr	630(ra) # 80003ec0 <namei>
    80004c52:	c92d                	beqz	a0,80004cc4 <exec+0xbc>
    80004c54:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	ab4080e7          	jalr	-1356(ra) # 8000370a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c5e:	04000713          	li	a4,64
    80004c62:	4681                	li	a3,0
    80004c64:	e5040613          	addi	a2,s0,-432
    80004c68:	4581                	li	a1,0
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	d52080e7          	jalr	-686(ra) # 800039be <readi>
    80004c74:	04000793          	li	a5,64
    80004c78:	00f51a63          	bne	a0,a5,80004c8c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c7c:	e5042703          	lw	a4,-432(s0)
    80004c80:	464c47b7          	lui	a5,0x464c4
    80004c84:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c88:	04f70463          	beq	a4,a5,80004cd0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	cde080e7          	jalr	-802(ra) # 8000396c <iunlockput>
    end_op();
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	4c6080e7          	jalr	1222(ra) # 8000415c <end_op>
  }
  return -1;
    80004c9e:	557d                	li	a0,-1
}
    80004ca0:	20813083          	ld	ra,520(sp)
    80004ca4:	20013403          	ld	s0,512(sp)
    80004ca8:	74fe                	ld	s1,504(sp)
    80004caa:	795e                	ld	s2,496(sp)
    80004cac:	79be                	ld	s3,488(sp)
    80004cae:	7a1e                	ld	s4,480(sp)
    80004cb0:	6afe                	ld	s5,472(sp)
    80004cb2:	6b5e                	ld	s6,464(sp)
    80004cb4:	6bbe                	ld	s7,456(sp)
    80004cb6:	6c1e                	ld	s8,448(sp)
    80004cb8:	7cfa                	ld	s9,440(sp)
    80004cba:	7d5a                	ld	s10,432(sp)
    80004cbc:	7dba                	ld	s11,424(sp)
    80004cbe:	21010113          	addi	sp,sp,528
    80004cc2:	8082                	ret
    end_op();
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	498080e7          	jalr	1176(ra) # 8000415c <end_op>
    return -1;
    80004ccc:	557d                	li	a0,-1
    80004cce:	bfc9                	j	80004ca0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cd0:	854a                	mv	a0,s2
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	f78080e7          	jalr	-136(ra) # 80001c4a <proc_pagetable>
    80004cda:	8baa                	mv	s7,a0
    80004cdc:	d945                	beqz	a0,80004c8c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cde:	e7042983          	lw	s3,-400(s0)
    80004ce2:	e8845783          	lhu	a5,-376(s0)
    80004ce6:	c7ad                	beqz	a5,80004d50 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ce8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cea:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004cec:	6c85                	lui	s9,0x1
    80004cee:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cf2:	def43823          	sd	a5,-528(s0)
    80004cf6:	a42d                	j	80004f20 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cf8:	00004517          	auipc	a0,0x4
    80004cfc:	9e850513          	addi	a0,a0,-1560 # 800086e0 <syscalls+0x290>
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	83e080e7          	jalr	-1986(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d08:	8756                	mv	a4,s5
    80004d0a:	012d86bb          	addw	a3,s11,s2
    80004d0e:	4581                	li	a1,0
    80004d10:	8526                	mv	a0,s1
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	cac080e7          	jalr	-852(ra) # 800039be <readi>
    80004d1a:	2501                	sext.w	a0,a0
    80004d1c:	1aaa9963          	bne	s5,a0,80004ece <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d20:	6785                	lui	a5,0x1
    80004d22:	0127893b          	addw	s2,a5,s2
    80004d26:	77fd                	lui	a5,0xfffff
    80004d28:	01478a3b          	addw	s4,a5,s4
    80004d2c:	1f897163          	bgeu	s2,s8,80004f0e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d30:	02091593          	slli	a1,s2,0x20
    80004d34:	9181                	srli	a1,a1,0x20
    80004d36:	95ea                	add	a1,a1,s10
    80004d38:	855e                	mv	a0,s7
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	334080e7          	jalr	820(ra) # 8000106e <walkaddr>
    80004d42:	862a                	mv	a2,a0
    if(pa == 0)
    80004d44:	d955                	beqz	a0,80004cf8 <exec+0xf0>
      n = PGSIZE;
    80004d46:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d48:	fd9a70e3          	bgeu	s4,s9,80004d08 <exec+0x100>
      n = sz - i;
    80004d4c:	8ad2                	mv	s5,s4
    80004d4e:	bf6d                	j	80004d08 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d50:	4901                	li	s2,0
  iunlockput(ip);
    80004d52:	8526                	mv	a0,s1
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	c18080e7          	jalr	-1000(ra) # 8000396c <iunlockput>
  end_op();
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	400080e7          	jalr	1024(ra) # 8000415c <end_op>
  p = myproc();
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	e22080e7          	jalr	-478(ra) # 80001b86 <myproc>
    80004d6c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d6e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d72:	6785                	lui	a5,0x1
    80004d74:	17fd                	addi	a5,a5,-1
    80004d76:	993e                	add	s2,s2,a5
    80004d78:	757d                	lui	a0,0xfffff
    80004d7a:	00a977b3          	and	a5,s2,a0
    80004d7e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d82:	6609                	lui	a2,0x2
    80004d84:	963e                	add	a2,a2,a5
    80004d86:	85be                	mv	a1,a5
    80004d88:	855e                	mv	a0,s7
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	698080e7          	jalr	1688(ra) # 80001422 <uvmalloc>
    80004d92:	8b2a                	mv	s6,a0
  ip = 0;
    80004d94:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d96:	12050c63          	beqz	a0,80004ece <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d9a:	75f9                	lui	a1,0xffffe
    80004d9c:	95aa                	add	a1,a1,a0
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	8a0080e7          	jalr	-1888(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004da8:	7c7d                	lui	s8,0xfffff
    80004daa:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	e0043783          	ld	a5,-512(s0)
    80004db0:	6388                	ld	a0,0(a5)
    80004db2:	c535                	beqz	a0,80004e1e <exec+0x216>
    80004db4:	e9040993          	addi	s3,s0,-368
    80004db8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dbc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	0a6080e7          	jalr	166(ra) # 80000e64 <strlen>
    80004dc6:	2505                	addiw	a0,a0,1
    80004dc8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dcc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dd0:	13896363          	bltu	s2,s8,80004ef6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dd4:	e0043d83          	ld	s11,-512(s0)
    80004dd8:	000dba03          	ld	s4,0(s11)
    80004ddc:	8552                	mv	a0,s4
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	086080e7          	jalr	134(ra) # 80000e64 <strlen>
    80004de6:	0015069b          	addiw	a3,a0,1
    80004dea:	8652                	mv	a2,s4
    80004dec:	85ca                	mv	a1,s2
    80004dee:	855e                	mv	a0,s7
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	882080e7          	jalr	-1918(ra) # 80001672 <copyout>
    80004df8:	10054363          	bltz	a0,80004efe <exec+0x2f6>
    ustack[argc] = sp;
    80004dfc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e00:	0485                	addi	s1,s1,1
    80004e02:	008d8793          	addi	a5,s11,8
    80004e06:	e0f43023          	sd	a5,-512(s0)
    80004e0a:	008db503          	ld	a0,8(s11)
    80004e0e:	c911                	beqz	a0,80004e22 <exec+0x21a>
    if(argc >= MAXARG)
    80004e10:	09a1                	addi	s3,s3,8
    80004e12:	fb3c96e3          	bne	s9,s3,80004dbe <exec+0x1b6>
  sz = sz1;
    80004e16:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e1a:	4481                	li	s1,0
    80004e1c:	a84d                	j	80004ece <exec+0x2c6>
  sp = sz;
    80004e1e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e20:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e22:	00349793          	slli	a5,s1,0x3
    80004e26:	f9040713          	addi	a4,s0,-112
    80004e2a:	97ba                	add	a5,a5,a4
    80004e2c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e30:	00148693          	addi	a3,s1,1
    80004e34:	068e                	slli	a3,a3,0x3
    80004e36:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e3a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e3e:	01897663          	bgeu	s2,s8,80004e4a <exec+0x242>
  sz = sz1;
    80004e42:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e46:	4481                	li	s1,0
    80004e48:	a059                	j	80004ece <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e4a:	e9040613          	addi	a2,s0,-368
    80004e4e:	85ca                	mv	a1,s2
    80004e50:	855e                	mv	a0,s7
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	820080e7          	jalr	-2016(ra) # 80001672 <copyout>
    80004e5a:	0a054663          	bltz	a0,80004f06 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e5e:	058ab783          	ld	a5,88(s5)
    80004e62:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e66:	df843783          	ld	a5,-520(s0)
    80004e6a:	0007c703          	lbu	a4,0(a5)
    80004e6e:	cf11                	beqz	a4,80004e8a <exec+0x282>
    80004e70:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e72:	02f00693          	li	a3,47
    80004e76:	a039                	j	80004e84 <exec+0x27c>
      last = s+1;
    80004e78:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e7c:	0785                	addi	a5,a5,1
    80004e7e:	fff7c703          	lbu	a4,-1(a5)
    80004e82:	c701                	beqz	a4,80004e8a <exec+0x282>
    if(*s == '/')
    80004e84:	fed71ce3          	bne	a4,a3,80004e7c <exec+0x274>
    80004e88:	bfc5                	j	80004e78 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e8a:	4641                	li	a2,16
    80004e8c:	df843583          	ld	a1,-520(s0)
    80004e90:	158a8513          	addi	a0,s5,344
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	f9e080e7          	jalr	-98(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e9c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ea0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ea4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ea8:	058ab783          	ld	a5,88(s5)
    80004eac:	e6843703          	ld	a4,-408(s0)
    80004eb0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eb2:	058ab783          	ld	a5,88(s5)
    80004eb6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eba:	85ea                	mv	a1,s10
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	e2a080e7          	jalr	-470(ra) # 80001ce6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ec4:	0004851b          	sext.w	a0,s1
    80004ec8:	bbe1                	j	80004ca0 <exec+0x98>
    80004eca:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ece:	e0843583          	ld	a1,-504(s0)
    80004ed2:	855e                	mv	a0,s7
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	e12080e7          	jalr	-494(ra) # 80001ce6 <proc_freepagetable>
  if(ip){
    80004edc:	da0498e3          	bnez	s1,80004c8c <exec+0x84>
  return -1;
    80004ee0:	557d                	li	a0,-1
    80004ee2:	bb7d                	j	80004ca0 <exec+0x98>
    80004ee4:	e1243423          	sd	s2,-504(s0)
    80004ee8:	b7dd                	j	80004ece <exec+0x2c6>
    80004eea:	e1243423          	sd	s2,-504(s0)
    80004eee:	b7c5                	j	80004ece <exec+0x2c6>
    80004ef0:	e1243423          	sd	s2,-504(s0)
    80004ef4:	bfe9                	j	80004ece <exec+0x2c6>
  sz = sz1;
    80004ef6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004efa:	4481                	li	s1,0
    80004efc:	bfc9                	j	80004ece <exec+0x2c6>
  sz = sz1;
    80004efe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f02:	4481                	li	s1,0
    80004f04:	b7e9                	j	80004ece <exec+0x2c6>
  sz = sz1;
    80004f06:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f0a:	4481                	li	s1,0
    80004f0c:	b7c9                	j	80004ece <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f0e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f12:	2b05                	addiw	s6,s6,1
    80004f14:	0389899b          	addiw	s3,s3,56
    80004f18:	e8845783          	lhu	a5,-376(s0)
    80004f1c:	e2fb5be3          	bge	s6,a5,80004d52 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f20:	2981                	sext.w	s3,s3
    80004f22:	03800713          	li	a4,56
    80004f26:	86ce                	mv	a3,s3
    80004f28:	e1840613          	addi	a2,s0,-488
    80004f2c:	4581                	li	a1,0
    80004f2e:	8526                	mv	a0,s1
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	a8e080e7          	jalr	-1394(ra) # 800039be <readi>
    80004f38:	03800793          	li	a5,56
    80004f3c:	f8f517e3          	bne	a0,a5,80004eca <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f40:	e1842783          	lw	a5,-488(s0)
    80004f44:	4705                	li	a4,1
    80004f46:	fce796e3          	bne	a5,a4,80004f12 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f4a:	e4043603          	ld	a2,-448(s0)
    80004f4e:	e3843783          	ld	a5,-456(s0)
    80004f52:	f8f669e3          	bltu	a2,a5,80004ee4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f56:	e2843783          	ld	a5,-472(s0)
    80004f5a:	963e                	add	a2,a2,a5
    80004f5c:	f8f667e3          	bltu	a2,a5,80004eea <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f60:	85ca                	mv	a1,s2
    80004f62:	855e                	mv	a0,s7
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	4be080e7          	jalr	1214(ra) # 80001422 <uvmalloc>
    80004f6c:	e0a43423          	sd	a0,-504(s0)
    80004f70:	d141                	beqz	a0,80004ef0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f72:	e2843d03          	ld	s10,-472(s0)
    80004f76:	df043783          	ld	a5,-528(s0)
    80004f7a:	00fd77b3          	and	a5,s10,a5
    80004f7e:	fba1                	bnez	a5,80004ece <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f80:	e2042d83          	lw	s11,-480(s0)
    80004f84:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f88:	f80c03e3          	beqz	s8,80004f0e <exec+0x306>
    80004f8c:	8a62                	mv	s4,s8
    80004f8e:	4901                	li	s2,0
    80004f90:	b345                	j	80004d30 <exec+0x128>

0000000080004f92 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f92:	7179                	addi	sp,sp,-48
    80004f94:	f406                	sd	ra,40(sp)
    80004f96:	f022                	sd	s0,32(sp)
    80004f98:	ec26                	sd	s1,24(sp)
    80004f9a:	e84a                	sd	s2,16(sp)
    80004f9c:	1800                	addi	s0,sp,48
    80004f9e:	892e                	mv	s2,a1
    80004fa0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fa2:	fdc40593          	addi	a1,s0,-36
    80004fa6:	ffffe097          	auipc	ra,0xffffe
    80004faa:	ba8080e7          	jalr	-1112(ra) # 80002b4e <argint>
    80004fae:	04054063          	bltz	a0,80004fee <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fb2:	fdc42703          	lw	a4,-36(s0)
    80004fb6:	47bd                	li	a5,15
    80004fb8:	02e7ed63          	bltu	a5,a4,80004ff2 <argfd+0x60>
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	bca080e7          	jalr	-1078(ra) # 80001b86 <myproc>
    80004fc4:	fdc42703          	lw	a4,-36(s0)
    80004fc8:	01a70793          	addi	a5,a4,26
    80004fcc:	078e                	slli	a5,a5,0x3
    80004fce:	953e                	add	a0,a0,a5
    80004fd0:	611c                	ld	a5,0(a0)
    80004fd2:	c395                	beqz	a5,80004ff6 <argfd+0x64>
    return -1;
  if(pfd)
    80004fd4:	00090463          	beqz	s2,80004fdc <argfd+0x4a>
    *pfd = fd;
    80004fd8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fdc:	4501                	li	a0,0
  if(pf)
    80004fde:	c091                	beqz	s1,80004fe2 <argfd+0x50>
    *pf = f;
    80004fe0:	e09c                	sd	a5,0(s1)
}
    80004fe2:	70a2                	ld	ra,40(sp)
    80004fe4:	7402                	ld	s0,32(sp)
    80004fe6:	64e2                	ld	s1,24(sp)
    80004fe8:	6942                	ld	s2,16(sp)
    80004fea:	6145                	addi	sp,sp,48
    80004fec:	8082                	ret
    return -1;
    80004fee:	557d                	li	a0,-1
    80004ff0:	bfcd                	j	80004fe2 <argfd+0x50>
    return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	b7fd                	j	80004fe2 <argfd+0x50>
    80004ff6:	557d                	li	a0,-1
    80004ff8:	b7ed                	j	80004fe2 <argfd+0x50>

0000000080004ffa <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ffa:	1101                	addi	sp,sp,-32
    80004ffc:	ec06                	sd	ra,24(sp)
    80004ffe:	e822                	sd	s0,16(sp)
    80005000:	e426                	sd	s1,8(sp)
    80005002:	1000                	addi	s0,sp,32
    80005004:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	b80080e7          	jalr	-1152(ra) # 80001b86 <myproc>
    8000500e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005010:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005014:	4501                	li	a0,0
    80005016:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005018:	6398                	ld	a4,0(a5)
    8000501a:	cb19                	beqz	a4,80005030 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000501c:	2505                	addiw	a0,a0,1
    8000501e:	07a1                	addi	a5,a5,8
    80005020:	fed51ce3          	bne	a0,a3,80005018 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005024:	557d                	li	a0,-1
}
    80005026:	60e2                	ld	ra,24(sp)
    80005028:	6442                	ld	s0,16(sp)
    8000502a:	64a2                	ld	s1,8(sp)
    8000502c:	6105                	addi	sp,sp,32
    8000502e:	8082                	ret
      p->ofile[fd] = f;
    80005030:	01a50793          	addi	a5,a0,26
    80005034:	078e                	slli	a5,a5,0x3
    80005036:	963e                	add	a2,a2,a5
    80005038:	e204                	sd	s1,0(a2)
      return fd;
    8000503a:	b7f5                	j	80005026 <fdalloc+0x2c>

000000008000503c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000503c:	715d                	addi	sp,sp,-80
    8000503e:	e486                	sd	ra,72(sp)
    80005040:	e0a2                	sd	s0,64(sp)
    80005042:	fc26                	sd	s1,56(sp)
    80005044:	f84a                	sd	s2,48(sp)
    80005046:	f44e                	sd	s3,40(sp)
    80005048:	f052                	sd	s4,32(sp)
    8000504a:	ec56                	sd	s5,24(sp)
    8000504c:	0880                	addi	s0,sp,80
    8000504e:	89ae                	mv	s3,a1
    80005050:	8ab2                	mv	s5,a2
    80005052:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005054:	fb040593          	addi	a1,s0,-80
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	e86080e7          	jalr	-378(ra) # 80003ede <nameiparent>
    80005060:	892a                	mv	s2,a0
    80005062:	12050f63          	beqz	a0,800051a0 <create+0x164>
    return 0;

  ilock(dp);
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	6a4080e7          	jalr	1700(ra) # 8000370a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000506e:	4601                	li	a2,0
    80005070:	fb040593          	addi	a1,s0,-80
    80005074:	854a                	mv	a0,s2
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	b78080e7          	jalr	-1160(ra) # 80003bee <dirlookup>
    8000507e:	84aa                	mv	s1,a0
    80005080:	c921                	beqz	a0,800050d0 <create+0x94>
    iunlockput(dp);
    80005082:	854a                	mv	a0,s2
    80005084:	fffff097          	auipc	ra,0xfffff
    80005088:	8e8080e7          	jalr	-1816(ra) # 8000396c <iunlockput>
    ilock(ip);
    8000508c:	8526                	mv	a0,s1
    8000508e:	ffffe097          	auipc	ra,0xffffe
    80005092:	67c080e7          	jalr	1660(ra) # 8000370a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005096:	2981                	sext.w	s3,s3
    80005098:	4789                	li	a5,2
    8000509a:	02f99463          	bne	s3,a5,800050c2 <create+0x86>
    8000509e:	0444d783          	lhu	a5,68(s1)
    800050a2:	37f9                	addiw	a5,a5,-2
    800050a4:	17c2                	slli	a5,a5,0x30
    800050a6:	93c1                	srli	a5,a5,0x30
    800050a8:	4705                	li	a4,1
    800050aa:	00f76c63          	bltu	a4,a5,800050c2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050ae:	8526                	mv	a0,s1
    800050b0:	60a6                	ld	ra,72(sp)
    800050b2:	6406                	ld	s0,64(sp)
    800050b4:	74e2                	ld	s1,56(sp)
    800050b6:	7942                	ld	s2,48(sp)
    800050b8:	79a2                	ld	s3,40(sp)
    800050ba:	7a02                	ld	s4,32(sp)
    800050bc:	6ae2                	ld	s5,24(sp)
    800050be:	6161                	addi	sp,sp,80
    800050c0:	8082                	ret
    iunlockput(ip);
    800050c2:	8526                	mv	a0,s1
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	8a8080e7          	jalr	-1880(ra) # 8000396c <iunlockput>
    return 0;
    800050cc:	4481                	li	s1,0
    800050ce:	b7c5                	j	800050ae <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050d0:	85ce                	mv	a1,s3
    800050d2:	00092503          	lw	a0,0(s2)
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	49c080e7          	jalr	1180(ra) # 80003572 <ialloc>
    800050de:	84aa                	mv	s1,a0
    800050e0:	c529                	beqz	a0,8000512a <create+0xee>
  ilock(ip);
    800050e2:	ffffe097          	auipc	ra,0xffffe
    800050e6:	628080e7          	jalr	1576(ra) # 8000370a <ilock>
  ip->major = major;
    800050ea:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ee:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050f2:	4785                	li	a5,1
    800050f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050f8:	8526                	mv	a0,s1
    800050fa:	ffffe097          	auipc	ra,0xffffe
    800050fe:	546080e7          	jalr	1350(ra) # 80003640 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005102:	2981                	sext.w	s3,s3
    80005104:	4785                	li	a5,1
    80005106:	02f98a63          	beq	s3,a5,8000513a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000510a:	40d0                	lw	a2,4(s1)
    8000510c:	fb040593          	addi	a1,s0,-80
    80005110:	854a                	mv	a0,s2
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	cec080e7          	jalr	-788(ra) # 80003dfe <dirlink>
    8000511a:	06054b63          	bltz	a0,80005190 <create+0x154>
  iunlockput(dp);
    8000511e:	854a                	mv	a0,s2
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	84c080e7          	jalr	-1972(ra) # 8000396c <iunlockput>
  return ip;
    80005128:	b759                	j	800050ae <create+0x72>
    panic("create: ialloc");
    8000512a:	00003517          	auipc	a0,0x3
    8000512e:	5d650513          	addi	a0,a0,1494 # 80008700 <syscalls+0x2b0>
    80005132:	ffffb097          	auipc	ra,0xffffb
    80005136:	40c080e7          	jalr	1036(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000513a:	04a95783          	lhu	a5,74(s2)
    8000513e:	2785                	addiw	a5,a5,1
    80005140:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005144:	854a                	mv	a0,s2
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	4fa080e7          	jalr	1274(ra) # 80003640 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000514e:	40d0                	lw	a2,4(s1)
    80005150:	00003597          	auipc	a1,0x3
    80005154:	5c058593          	addi	a1,a1,1472 # 80008710 <syscalls+0x2c0>
    80005158:	8526                	mv	a0,s1
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	ca4080e7          	jalr	-860(ra) # 80003dfe <dirlink>
    80005162:	00054f63          	bltz	a0,80005180 <create+0x144>
    80005166:	00492603          	lw	a2,4(s2)
    8000516a:	00003597          	auipc	a1,0x3
    8000516e:	5ae58593          	addi	a1,a1,1454 # 80008718 <syscalls+0x2c8>
    80005172:	8526                	mv	a0,s1
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	c8a080e7          	jalr	-886(ra) # 80003dfe <dirlink>
    8000517c:	f80557e3          	bgez	a0,8000510a <create+0xce>
      panic("create dots");
    80005180:	00003517          	auipc	a0,0x3
    80005184:	5a050513          	addi	a0,a0,1440 # 80008720 <syscalls+0x2d0>
    80005188:	ffffb097          	auipc	ra,0xffffb
    8000518c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005190:	00003517          	auipc	a0,0x3
    80005194:	5a050513          	addi	a0,a0,1440 # 80008730 <syscalls+0x2e0>
    80005198:	ffffb097          	auipc	ra,0xffffb
    8000519c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
    return 0;
    800051a0:	84aa                	mv	s1,a0
    800051a2:	b731                	j	800050ae <create+0x72>

00000000800051a4 <sys_dup>:
{
    800051a4:	7179                	addi	sp,sp,-48
    800051a6:	f406                	sd	ra,40(sp)
    800051a8:	f022                	sd	s0,32(sp)
    800051aa:	ec26                	sd	s1,24(sp)
    800051ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ae:	fd840613          	addi	a2,s0,-40
    800051b2:	4581                	li	a1,0
    800051b4:	4501                	li	a0,0
    800051b6:	00000097          	auipc	ra,0x0
    800051ba:	ddc080e7          	jalr	-548(ra) # 80004f92 <argfd>
    return -1;
    800051be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051c0:	02054363          	bltz	a0,800051e6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051c4:	fd843503          	ld	a0,-40(s0)
    800051c8:	00000097          	auipc	ra,0x0
    800051cc:	e32080e7          	jalr	-462(ra) # 80004ffa <fdalloc>
    800051d0:	84aa                	mv	s1,a0
    return -1;
    800051d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051d4:	00054963          	bltz	a0,800051e6 <sys_dup+0x42>
  filedup(f);
    800051d8:	fd843503          	ld	a0,-40(s0)
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	37a080e7          	jalr	890(ra) # 80004556 <filedup>
  return fd;
    800051e4:	87a6                	mv	a5,s1
}
    800051e6:	853e                	mv	a0,a5
    800051e8:	70a2                	ld	ra,40(sp)
    800051ea:	7402                	ld	s0,32(sp)
    800051ec:	64e2                	ld	s1,24(sp)
    800051ee:	6145                	addi	sp,sp,48
    800051f0:	8082                	ret

00000000800051f2 <sys_read>:
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fa:	fe840613          	addi	a2,s0,-24
    800051fe:	4581                	li	a1,0
    80005200:	4501                	li	a0,0
    80005202:	00000097          	auipc	ra,0x0
    80005206:	d90080e7          	jalr	-624(ra) # 80004f92 <argfd>
    return -1;
    8000520a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520c:	04054163          	bltz	a0,8000524e <sys_read+0x5c>
    80005210:	fe440593          	addi	a1,s0,-28
    80005214:	4509                	li	a0,2
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	938080e7          	jalr	-1736(ra) # 80002b4e <argint>
    return -1;
    8000521e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005220:	02054763          	bltz	a0,8000524e <sys_read+0x5c>
    80005224:	fd840593          	addi	a1,s0,-40
    80005228:	4505                	li	a0,1
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	946080e7          	jalr	-1722(ra) # 80002b70 <argaddr>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005234:	00054d63          	bltz	a0,8000524e <sys_read+0x5c>
  return fileread(f, p, n);
    80005238:	fe442603          	lw	a2,-28(s0)
    8000523c:	fd843583          	ld	a1,-40(s0)
    80005240:	fe843503          	ld	a0,-24(s0)
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	49e080e7          	jalr	1182(ra) # 800046e2 <fileread>
    8000524c:	87aa                	mv	a5,a0
}
    8000524e:	853e                	mv	a0,a5
    80005250:	70a2                	ld	ra,40(sp)
    80005252:	7402                	ld	s0,32(sp)
    80005254:	6145                	addi	sp,sp,48
    80005256:	8082                	ret

0000000080005258 <sys_write>:
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
    8000526c:	d2a080e7          	jalr	-726(ra) # 80004f92 <argfd>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005272:	04054163          	bltz	a0,800052b4 <sys_write+0x5c>
    80005276:	fe440593          	addi	a1,s0,-28
    8000527a:	4509                	li	a0,2
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	8d2080e7          	jalr	-1838(ra) # 80002b4e <argint>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005286:	02054763          	bltz	a0,800052b4 <sys_write+0x5c>
    8000528a:	fd840593          	addi	a1,s0,-40
    8000528e:	4505                	li	a0,1
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	8e0080e7          	jalr	-1824(ra) # 80002b70 <argaddr>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529a:	00054d63          	bltz	a0,800052b4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000529e:	fe442603          	lw	a2,-28(s0)
    800052a2:	fd843583          	ld	a1,-40(s0)
    800052a6:	fe843503          	ld	a0,-24(s0)
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	4fa080e7          	jalr	1274(ra) # 800047a4 <filewrite>
    800052b2:	87aa                	mv	a5,a0
}
    800052b4:	853e                	mv	a0,a5
    800052b6:	70a2                	ld	ra,40(sp)
    800052b8:	7402                	ld	s0,32(sp)
    800052ba:	6145                	addi	sp,sp,48
    800052bc:	8082                	ret

00000000800052be <sys_close>:
{
    800052be:	1101                	addi	sp,sp,-32
    800052c0:	ec06                	sd	ra,24(sp)
    800052c2:	e822                	sd	s0,16(sp)
    800052c4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052c6:	fe040613          	addi	a2,s0,-32
    800052ca:	fec40593          	addi	a1,s0,-20
    800052ce:	4501                	li	a0,0
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	cc2080e7          	jalr	-830(ra) # 80004f92 <argfd>
    return -1;
    800052d8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052da:	02054463          	bltz	a0,80005302 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052de:	ffffd097          	auipc	ra,0xffffd
    800052e2:	8a8080e7          	jalr	-1880(ra) # 80001b86 <myproc>
    800052e6:	fec42783          	lw	a5,-20(s0)
    800052ea:	07e9                	addi	a5,a5,26
    800052ec:	078e                	slli	a5,a5,0x3
    800052ee:	97aa                	add	a5,a5,a0
    800052f0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052f4:	fe043503          	ld	a0,-32(s0)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	2b0080e7          	jalr	688(ra) # 800045a8 <fileclose>
  return 0;
    80005300:	4781                	li	a5,0
}
    80005302:	853e                	mv	a0,a5
    80005304:	60e2                	ld	ra,24(sp)
    80005306:	6442                	ld	s0,16(sp)
    80005308:	6105                	addi	sp,sp,32
    8000530a:	8082                	ret

000000008000530c <sys_fstat>:
{
    8000530c:	1101                	addi	sp,sp,-32
    8000530e:	ec06                	sd	ra,24(sp)
    80005310:	e822                	sd	s0,16(sp)
    80005312:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005314:	fe840613          	addi	a2,s0,-24
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	c76080e7          	jalr	-906(ra) # 80004f92 <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005326:	02054563          	bltz	a0,80005350 <sys_fstat+0x44>
    8000532a:	fe040593          	addi	a1,s0,-32
    8000532e:	4505                	li	a0,1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	840080e7          	jalr	-1984(ra) # 80002b70 <argaddr>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000533a:	00054b63          	bltz	a0,80005350 <sys_fstat+0x44>
  return filestat(f, st);
    8000533e:	fe043583          	ld	a1,-32(s0)
    80005342:	fe843503          	ld	a0,-24(s0)
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	32a080e7          	jalr	810(ra) # 80004670 <filestat>
    8000534e:	87aa                	mv	a5,a0
}
    80005350:	853e                	mv	a0,a5
    80005352:	60e2                	ld	ra,24(sp)
    80005354:	6442                	ld	s0,16(sp)
    80005356:	6105                	addi	sp,sp,32
    80005358:	8082                	ret

000000008000535a <sys_link>:
{
    8000535a:	7169                	addi	sp,sp,-304
    8000535c:	f606                	sd	ra,296(sp)
    8000535e:	f222                	sd	s0,288(sp)
    80005360:	ee26                	sd	s1,280(sp)
    80005362:	ea4a                	sd	s2,272(sp)
    80005364:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005366:	08000613          	li	a2,128
    8000536a:	ed040593          	addi	a1,s0,-304
    8000536e:	4501                	li	a0,0
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	822080e7          	jalr	-2014(ra) # 80002b92 <argstr>
    return -1;
    80005378:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000537a:	10054e63          	bltz	a0,80005496 <sys_link+0x13c>
    8000537e:	08000613          	li	a2,128
    80005382:	f5040593          	addi	a1,s0,-176
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	80a080e7          	jalr	-2038(ra) # 80002b92 <argstr>
    return -1;
    80005390:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005392:	10054263          	bltz	a0,80005496 <sys_link+0x13c>
  begin_op();
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	d46080e7          	jalr	-698(ra) # 800040dc <begin_op>
  if((ip = namei(old)) == 0){
    8000539e:	ed040513          	addi	a0,s0,-304
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	b1e080e7          	jalr	-1250(ra) # 80003ec0 <namei>
    800053aa:	84aa                	mv	s1,a0
    800053ac:	c551                	beqz	a0,80005438 <sys_link+0xde>
  ilock(ip);
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	35c080e7          	jalr	860(ra) # 8000370a <ilock>
  if(ip->type == T_DIR){
    800053b6:	04449703          	lh	a4,68(s1)
    800053ba:	4785                	li	a5,1
    800053bc:	08f70463          	beq	a4,a5,80005444 <sys_link+0xea>
  ip->nlink++;
    800053c0:	04a4d783          	lhu	a5,74(s1)
    800053c4:	2785                	addiw	a5,a5,1
    800053c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ca:	8526                	mv	a0,s1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	274080e7          	jalr	628(ra) # 80003640 <iupdate>
  iunlock(ip);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	3f6080e7          	jalr	1014(ra) # 800037cc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053de:	fd040593          	addi	a1,s0,-48
    800053e2:	f5040513          	addi	a0,s0,-176
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	af8080e7          	jalr	-1288(ra) # 80003ede <nameiparent>
    800053ee:	892a                	mv	s2,a0
    800053f0:	c935                	beqz	a0,80005464 <sys_link+0x10a>
  ilock(dp);
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	318080e7          	jalr	792(ra) # 8000370a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053fa:	00092703          	lw	a4,0(s2)
    800053fe:	409c                	lw	a5,0(s1)
    80005400:	04f71d63          	bne	a4,a5,8000545a <sys_link+0x100>
    80005404:	40d0                	lw	a2,4(s1)
    80005406:	fd040593          	addi	a1,s0,-48
    8000540a:	854a                	mv	a0,s2
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	9f2080e7          	jalr	-1550(ra) # 80003dfe <dirlink>
    80005414:	04054363          	bltz	a0,8000545a <sys_link+0x100>
  iunlockput(dp);
    80005418:	854a                	mv	a0,s2
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	552080e7          	jalr	1362(ra) # 8000396c <iunlockput>
  iput(ip);
    80005422:	8526                	mv	a0,s1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	4a0080e7          	jalr	1184(ra) # 800038c4 <iput>
  end_op();
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	d30080e7          	jalr	-720(ra) # 8000415c <end_op>
  return 0;
    80005434:	4781                	li	a5,0
    80005436:	a085                	j	80005496 <sys_link+0x13c>
    end_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	d24080e7          	jalr	-732(ra) # 8000415c <end_op>
    return -1;
    80005440:	57fd                	li	a5,-1
    80005442:	a891                	j	80005496 <sys_link+0x13c>
    iunlockput(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	526080e7          	jalr	1318(ra) # 8000396c <iunlockput>
    end_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	d0e080e7          	jalr	-754(ra) # 8000415c <end_op>
    return -1;
    80005456:	57fd                	li	a5,-1
    80005458:	a83d                	j	80005496 <sys_link+0x13c>
    iunlockput(dp);
    8000545a:	854a                	mv	a0,s2
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	510080e7          	jalr	1296(ra) # 8000396c <iunlockput>
  ilock(ip);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	2a4080e7          	jalr	676(ra) # 8000370a <ilock>
  ip->nlink--;
    8000546e:	04a4d783          	lhu	a5,74(s1)
    80005472:	37fd                	addiw	a5,a5,-1
    80005474:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005478:	8526                	mv	a0,s1
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	1c6080e7          	jalr	454(ra) # 80003640 <iupdate>
  iunlockput(ip);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	4e8080e7          	jalr	1256(ra) # 8000396c <iunlockput>
  end_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	cd0080e7          	jalr	-816(ra) # 8000415c <end_op>
  return -1;
    80005494:	57fd                	li	a5,-1
}
    80005496:	853e                	mv	a0,a5
    80005498:	70b2                	ld	ra,296(sp)
    8000549a:	7412                	ld	s0,288(sp)
    8000549c:	64f2                	ld	s1,280(sp)
    8000549e:	6952                	ld	s2,272(sp)
    800054a0:	6155                	addi	sp,sp,304
    800054a2:	8082                	ret

00000000800054a4 <sys_unlink>:
{
    800054a4:	7151                	addi	sp,sp,-240
    800054a6:	f586                	sd	ra,232(sp)
    800054a8:	f1a2                	sd	s0,224(sp)
    800054aa:	eda6                	sd	s1,216(sp)
    800054ac:	e9ca                	sd	s2,208(sp)
    800054ae:	e5ce                	sd	s3,200(sp)
    800054b0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054b2:	08000613          	li	a2,128
    800054b6:	f3040593          	addi	a1,s0,-208
    800054ba:	4501                	li	a0,0
    800054bc:	ffffd097          	auipc	ra,0xffffd
    800054c0:	6d6080e7          	jalr	1750(ra) # 80002b92 <argstr>
    800054c4:	18054163          	bltz	a0,80005646 <sys_unlink+0x1a2>
  begin_op();
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	c14080e7          	jalr	-1004(ra) # 800040dc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054d0:	fb040593          	addi	a1,s0,-80
    800054d4:	f3040513          	addi	a0,s0,-208
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	a06080e7          	jalr	-1530(ra) # 80003ede <nameiparent>
    800054e0:	84aa                	mv	s1,a0
    800054e2:	c979                	beqz	a0,800055b8 <sys_unlink+0x114>
  ilock(dp);
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	226080e7          	jalr	550(ra) # 8000370a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ec:	00003597          	auipc	a1,0x3
    800054f0:	22458593          	addi	a1,a1,548 # 80008710 <syscalls+0x2c0>
    800054f4:	fb040513          	addi	a0,s0,-80
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	6dc080e7          	jalr	1756(ra) # 80003bd4 <namecmp>
    80005500:	14050a63          	beqz	a0,80005654 <sys_unlink+0x1b0>
    80005504:	00003597          	auipc	a1,0x3
    80005508:	21458593          	addi	a1,a1,532 # 80008718 <syscalls+0x2c8>
    8000550c:	fb040513          	addi	a0,s0,-80
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	6c4080e7          	jalr	1732(ra) # 80003bd4 <namecmp>
    80005518:	12050e63          	beqz	a0,80005654 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000551c:	f2c40613          	addi	a2,s0,-212
    80005520:	fb040593          	addi	a1,s0,-80
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	6c8080e7          	jalr	1736(ra) # 80003bee <dirlookup>
    8000552e:	892a                	mv	s2,a0
    80005530:	12050263          	beqz	a0,80005654 <sys_unlink+0x1b0>
  ilock(ip);
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	1d6080e7          	jalr	470(ra) # 8000370a <ilock>
  if(ip->nlink < 1)
    8000553c:	04a91783          	lh	a5,74(s2)
    80005540:	08f05263          	blez	a5,800055c4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005544:	04491703          	lh	a4,68(s2)
    80005548:	4785                	li	a5,1
    8000554a:	08f70563          	beq	a4,a5,800055d4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000554e:	4641                	li	a2,16
    80005550:	4581                	li	a1,0
    80005552:	fc040513          	addi	a0,s0,-64
    80005556:	ffffb097          	auipc	ra,0xffffb
    8000555a:	78a080e7          	jalr	1930(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000555e:	4741                	li	a4,16
    80005560:	f2c42683          	lw	a3,-212(s0)
    80005564:	fc040613          	addi	a2,s0,-64
    80005568:	4581                	li	a1,0
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	54a080e7          	jalr	1354(ra) # 80003ab6 <writei>
    80005574:	47c1                	li	a5,16
    80005576:	0af51563          	bne	a0,a5,80005620 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000557a:	04491703          	lh	a4,68(s2)
    8000557e:	4785                	li	a5,1
    80005580:	0af70863          	beq	a4,a5,80005630 <sys_unlink+0x18c>
  iunlockput(dp);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	3e6080e7          	jalr	998(ra) # 8000396c <iunlockput>
  ip->nlink--;
    8000558e:	04a95783          	lhu	a5,74(s2)
    80005592:	37fd                	addiw	a5,a5,-1
    80005594:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	0a6080e7          	jalr	166(ra) # 80003640 <iupdate>
  iunlockput(ip);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	3c8080e7          	jalr	968(ra) # 8000396c <iunlockput>
  end_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	bb0080e7          	jalr	-1104(ra) # 8000415c <end_op>
  return 0;
    800055b4:	4501                	li	a0,0
    800055b6:	a84d                	j	80005668 <sys_unlink+0x1c4>
    end_op();
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	ba4080e7          	jalr	-1116(ra) # 8000415c <end_op>
    return -1;
    800055c0:	557d                	li	a0,-1
    800055c2:	a05d                	j	80005668 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055c4:	00003517          	auipc	a0,0x3
    800055c8:	17c50513          	addi	a0,a0,380 # 80008740 <syscalls+0x2f0>
    800055cc:	ffffb097          	auipc	ra,0xffffb
    800055d0:	f72080e7          	jalr	-142(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d4:	04c92703          	lw	a4,76(s2)
    800055d8:	02000793          	li	a5,32
    800055dc:	f6e7f9e3          	bgeu	a5,a4,8000554e <sys_unlink+0xaa>
    800055e0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e4:	4741                	li	a4,16
    800055e6:	86ce                	mv	a3,s3
    800055e8:	f1840613          	addi	a2,s0,-232
    800055ec:	4581                	li	a1,0
    800055ee:	854a                	mv	a0,s2
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	3ce080e7          	jalr	974(ra) # 800039be <readi>
    800055f8:	47c1                	li	a5,16
    800055fa:	00f51b63          	bne	a0,a5,80005610 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055fe:	f1845783          	lhu	a5,-232(s0)
    80005602:	e7a1                	bnez	a5,8000564a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005604:	29c1                	addiw	s3,s3,16
    80005606:	04c92783          	lw	a5,76(s2)
    8000560a:	fcf9ede3          	bltu	s3,a5,800055e4 <sys_unlink+0x140>
    8000560e:	b781                	j	8000554e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005610:	00003517          	auipc	a0,0x3
    80005614:	14850513          	addi	a0,a0,328 # 80008758 <syscalls+0x308>
    80005618:	ffffb097          	auipc	ra,0xffffb
    8000561c:	f26080e7          	jalr	-218(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005620:	00003517          	auipc	a0,0x3
    80005624:	15050513          	addi	a0,a0,336 # 80008770 <syscalls+0x320>
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>
    dp->nlink--;
    80005630:	04a4d783          	lhu	a5,74(s1)
    80005634:	37fd                	addiw	a5,a5,-1
    80005636:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	004080e7          	jalr	4(ra) # 80003640 <iupdate>
    80005644:	b781                	j	80005584 <sys_unlink+0xe0>
    return -1;
    80005646:	557d                	li	a0,-1
    80005648:	a005                	j	80005668 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	320080e7          	jalr	800(ra) # 8000396c <iunlockput>
  iunlockput(dp);
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	316080e7          	jalr	790(ra) # 8000396c <iunlockput>
  end_op();
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	afe080e7          	jalr	-1282(ra) # 8000415c <end_op>
  return -1;
    80005666:	557d                	li	a0,-1
}
    80005668:	70ae                	ld	ra,232(sp)
    8000566a:	740e                	ld	s0,224(sp)
    8000566c:	64ee                	ld	s1,216(sp)
    8000566e:	694e                	ld	s2,208(sp)
    80005670:	69ae                	ld	s3,200(sp)
    80005672:	616d                	addi	sp,sp,240
    80005674:	8082                	ret

0000000080005676 <sys_open>:

uint64
sys_open(void)
{
    80005676:	7131                	addi	sp,sp,-192
    80005678:	fd06                	sd	ra,184(sp)
    8000567a:	f922                	sd	s0,176(sp)
    8000567c:	f526                	sd	s1,168(sp)
    8000567e:	f14a                	sd	s2,160(sp)
    80005680:	ed4e                	sd	s3,152(sp)
    80005682:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005684:	08000613          	li	a2,128
    80005688:	f5040593          	addi	a1,s0,-176
    8000568c:	4501                	li	a0,0
    8000568e:	ffffd097          	auipc	ra,0xffffd
    80005692:	504080e7          	jalr	1284(ra) # 80002b92 <argstr>
    return -1;
    80005696:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005698:	0c054163          	bltz	a0,8000575a <sys_open+0xe4>
    8000569c:	f4c40593          	addi	a1,s0,-180
    800056a0:	4505                	li	a0,1
    800056a2:	ffffd097          	auipc	ra,0xffffd
    800056a6:	4ac080e7          	jalr	1196(ra) # 80002b4e <argint>
    800056aa:	0a054863          	bltz	a0,8000575a <sys_open+0xe4>

  begin_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	a2e080e7          	jalr	-1490(ra) # 800040dc <begin_op>

  if(omode & O_CREATE){
    800056b6:	f4c42783          	lw	a5,-180(s0)
    800056ba:	2007f793          	andi	a5,a5,512
    800056be:	cbdd                	beqz	a5,80005774 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056c0:	4681                	li	a3,0
    800056c2:	4601                	li	a2,0
    800056c4:	4589                	li	a1,2
    800056c6:	f5040513          	addi	a0,s0,-176
    800056ca:	00000097          	auipc	ra,0x0
    800056ce:	972080e7          	jalr	-1678(ra) # 8000503c <create>
    800056d2:	892a                	mv	s2,a0
    if(ip == 0){
    800056d4:	c959                	beqz	a0,8000576a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056d6:	04491703          	lh	a4,68(s2)
    800056da:	478d                	li	a5,3
    800056dc:	00f71763          	bne	a4,a5,800056ea <sys_open+0x74>
    800056e0:	04695703          	lhu	a4,70(s2)
    800056e4:	47a5                	li	a5,9
    800056e6:	0ce7ec63          	bltu	a5,a4,800057be <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	e02080e7          	jalr	-510(ra) # 800044ec <filealloc>
    800056f2:	89aa                	mv	s3,a0
    800056f4:	10050263          	beqz	a0,800057f8 <sys_open+0x182>
    800056f8:	00000097          	auipc	ra,0x0
    800056fc:	902080e7          	jalr	-1790(ra) # 80004ffa <fdalloc>
    80005700:	84aa                	mv	s1,a0
    80005702:	0e054663          	bltz	a0,800057ee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005706:	04491703          	lh	a4,68(s2)
    8000570a:	478d                	li	a5,3
    8000570c:	0cf70463          	beq	a4,a5,800057d4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005710:	4789                	li	a5,2
    80005712:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005716:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000571a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000571e:	f4c42783          	lw	a5,-180(s0)
    80005722:	0017c713          	xori	a4,a5,1
    80005726:	8b05                	andi	a4,a4,1
    80005728:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000572c:	0037f713          	andi	a4,a5,3
    80005730:	00e03733          	snez	a4,a4
    80005734:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005738:	4007f793          	andi	a5,a5,1024
    8000573c:	c791                	beqz	a5,80005748 <sys_open+0xd2>
    8000573e:	04491703          	lh	a4,68(s2)
    80005742:	4789                	li	a5,2
    80005744:	08f70f63          	beq	a4,a5,800057e2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005748:	854a                	mv	a0,s2
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	082080e7          	jalr	130(ra) # 800037cc <iunlock>
  end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	a0a080e7          	jalr	-1526(ra) # 8000415c <end_op>

  return fd;
}
    8000575a:	8526                	mv	a0,s1
    8000575c:	70ea                	ld	ra,184(sp)
    8000575e:	744a                	ld	s0,176(sp)
    80005760:	74aa                	ld	s1,168(sp)
    80005762:	790a                	ld	s2,160(sp)
    80005764:	69ea                	ld	s3,152(sp)
    80005766:	6129                	addi	sp,sp,192
    80005768:	8082                	ret
      end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	9f2080e7          	jalr	-1550(ra) # 8000415c <end_op>
      return -1;
    80005772:	b7e5                	j	8000575a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005774:	f5040513          	addi	a0,s0,-176
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	748080e7          	jalr	1864(ra) # 80003ec0 <namei>
    80005780:	892a                	mv	s2,a0
    80005782:	c905                	beqz	a0,800057b2 <sys_open+0x13c>
    ilock(ip);
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	f86080e7          	jalr	-122(ra) # 8000370a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000578c:	04491703          	lh	a4,68(s2)
    80005790:	4785                	li	a5,1
    80005792:	f4f712e3          	bne	a4,a5,800056d6 <sys_open+0x60>
    80005796:	f4c42783          	lw	a5,-180(s0)
    8000579a:	dba1                	beqz	a5,800056ea <sys_open+0x74>
      iunlockput(ip);
    8000579c:	854a                	mv	a0,s2
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	1ce080e7          	jalr	462(ra) # 8000396c <iunlockput>
      end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	9b6080e7          	jalr	-1610(ra) # 8000415c <end_op>
      return -1;
    800057ae:	54fd                	li	s1,-1
    800057b0:	b76d                	j	8000575a <sys_open+0xe4>
      end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	9aa080e7          	jalr	-1622(ra) # 8000415c <end_op>
      return -1;
    800057ba:	54fd                	li	s1,-1
    800057bc:	bf79                	j	8000575a <sys_open+0xe4>
    iunlockput(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	1ac080e7          	jalr	428(ra) # 8000396c <iunlockput>
    end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	994080e7          	jalr	-1644(ra) # 8000415c <end_op>
    return -1;
    800057d0:	54fd                	li	s1,-1
    800057d2:	b761                	j	8000575a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057d4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057d8:	04691783          	lh	a5,70(s2)
    800057dc:	02f99223          	sh	a5,36(s3)
    800057e0:	bf2d                	j	8000571a <sys_open+0xa4>
    itrunc(ip);
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	034080e7          	jalr	52(ra) # 80003818 <itrunc>
    800057ec:	bfb1                	j	80005748 <sys_open+0xd2>
      fileclose(f);
    800057ee:	854e                	mv	a0,s3
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	db8080e7          	jalr	-584(ra) # 800045a8 <fileclose>
    iunlockput(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	172080e7          	jalr	370(ra) # 8000396c <iunlockput>
    end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	95a080e7          	jalr	-1702(ra) # 8000415c <end_op>
    return -1;
    8000580a:	54fd                	li	s1,-1
    8000580c:	b7b9                	j	8000575a <sys_open+0xe4>

000000008000580e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000580e:	7175                	addi	sp,sp,-144
    80005810:	e506                	sd	ra,136(sp)
    80005812:	e122                	sd	s0,128(sp)
    80005814:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	8c6080e7          	jalr	-1850(ra) # 800040dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000581e:	08000613          	li	a2,128
    80005822:	f7040593          	addi	a1,s0,-144
    80005826:	4501                	li	a0,0
    80005828:	ffffd097          	auipc	ra,0xffffd
    8000582c:	36a080e7          	jalr	874(ra) # 80002b92 <argstr>
    80005830:	02054963          	bltz	a0,80005862 <sys_mkdir+0x54>
    80005834:	4681                	li	a3,0
    80005836:	4601                	li	a2,0
    80005838:	4585                	li	a1,1
    8000583a:	f7040513          	addi	a0,s0,-144
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	7fe080e7          	jalr	2046(ra) # 8000503c <create>
    80005846:	cd11                	beqz	a0,80005862 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	124080e7          	jalr	292(ra) # 8000396c <iunlockput>
  end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	90c080e7          	jalr	-1780(ra) # 8000415c <end_op>
  return 0;
    80005858:	4501                	li	a0,0
}
    8000585a:	60aa                	ld	ra,136(sp)
    8000585c:	640a                	ld	s0,128(sp)
    8000585e:	6149                	addi	sp,sp,144
    80005860:	8082                	ret
    end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	8fa080e7          	jalr	-1798(ra) # 8000415c <end_op>
    return -1;
    8000586a:	557d                	li	a0,-1
    8000586c:	b7fd                	j	8000585a <sys_mkdir+0x4c>

000000008000586e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000586e:	7135                	addi	sp,sp,-160
    80005870:	ed06                	sd	ra,152(sp)
    80005872:	e922                	sd	s0,144(sp)
    80005874:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	866080e7          	jalr	-1946(ra) # 800040dc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000587e:	08000613          	li	a2,128
    80005882:	f7040593          	addi	a1,s0,-144
    80005886:	4501                	li	a0,0
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	30a080e7          	jalr	778(ra) # 80002b92 <argstr>
    80005890:	04054a63          	bltz	a0,800058e4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005894:	f6c40593          	addi	a1,s0,-148
    80005898:	4505                	li	a0,1
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	2b4080e7          	jalr	692(ra) # 80002b4e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a2:	04054163          	bltz	a0,800058e4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058a6:	f6840593          	addi	a1,s0,-152
    800058aa:	4509                	li	a0,2
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	2a2080e7          	jalr	674(ra) # 80002b4e <argint>
     argint(1, &major) < 0 ||
    800058b4:	02054863          	bltz	a0,800058e4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058b8:	f6841683          	lh	a3,-152(s0)
    800058bc:	f6c41603          	lh	a2,-148(s0)
    800058c0:	458d                	li	a1,3
    800058c2:	f7040513          	addi	a0,s0,-144
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	776080e7          	jalr	1910(ra) # 8000503c <create>
     argint(2, &minor) < 0 ||
    800058ce:	c919                	beqz	a0,800058e4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	09c080e7          	jalr	156(ra) # 8000396c <iunlockput>
  end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	884080e7          	jalr	-1916(ra) # 8000415c <end_op>
  return 0;
    800058e0:	4501                	li	a0,0
    800058e2:	a031                	j	800058ee <sys_mknod+0x80>
    end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	878080e7          	jalr	-1928(ra) # 8000415c <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
}
    800058ee:	60ea                	ld	ra,152(sp)
    800058f0:	644a                	ld	s0,144(sp)
    800058f2:	610d                	addi	sp,sp,160
    800058f4:	8082                	ret

00000000800058f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058f6:	7135                	addi	sp,sp,-160
    800058f8:	ed06                	sd	ra,152(sp)
    800058fa:	e922                	sd	s0,144(sp)
    800058fc:	e526                	sd	s1,136(sp)
    800058fe:	e14a                	sd	s2,128(sp)
    80005900:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	284080e7          	jalr	644(ra) # 80001b86 <myproc>
    8000590a:	892a                	mv	s2,a0
  
  begin_op();
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	7d0080e7          	jalr	2000(ra) # 800040dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005914:	08000613          	li	a2,128
    80005918:	f6040593          	addi	a1,s0,-160
    8000591c:	4501                	li	a0,0
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	274080e7          	jalr	628(ra) # 80002b92 <argstr>
    80005926:	04054b63          	bltz	a0,8000597c <sys_chdir+0x86>
    8000592a:	f6040513          	addi	a0,s0,-160
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	592080e7          	jalr	1426(ra) # 80003ec0 <namei>
    80005936:	84aa                	mv	s1,a0
    80005938:	c131                	beqz	a0,8000597c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	dd0080e7          	jalr	-560(ra) # 8000370a <ilock>
  if(ip->type != T_DIR){
    80005942:	04449703          	lh	a4,68(s1)
    80005946:	4785                	li	a5,1
    80005948:	04f71063          	bne	a4,a5,80005988 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	e7e080e7          	jalr	-386(ra) # 800037cc <iunlock>
  iput(p->cwd);
    80005956:	15093503          	ld	a0,336(s2)
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	f6a080e7          	jalr	-150(ra) # 800038c4 <iput>
  end_op();
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	7fa080e7          	jalr	2042(ra) # 8000415c <end_op>
  p->cwd = ip;
    8000596a:	14993823          	sd	s1,336(s2)
  return 0;
    8000596e:	4501                	li	a0,0
}
    80005970:	60ea                	ld	ra,152(sp)
    80005972:	644a                	ld	s0,144(sp)
    80005974:	64aa                	ld	s1,136(sp)
    80005976:	690a                	ld	s2,128(sp)
    80005978:	610d                	addi	sp,sp,160
    8000597a:	8082                	ret
    end_op();
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	7e0080e7          	jalr	2016(ra) # 8000415c <end_op>
    return -1;
    80005984:	557d                	li	a0,-1
    80005986:	b7ed                	j	80005970 <sys_chdir+0x7a>
    iunlockput(ip);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	fe2080e7          	jalr	-30(ra) # 8000396c <iunlockput>
    end_op();
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	7ca080e7          	jalr	1994(ra) # 8000415c <end_op>
    return -1;
    8000599a:	557d                	li	a0,-1
    8000599c:	bfd1                	j	80005970 <sys_chdir+0x7a>

000000008000599e <sys_exec>:

uint64
sys_exec(void)
{
    8000599e:	7145                	addi	sp,sp,-464
    800059a0:	e786                	sd	ra,456(sp)
    800059a2:	e3a2                	sd	s0,448(sp)
    800059a4:	ff26                	sd	s1,440(sp)
    800059a6:	fb4a                	sd	s2,432(sp)
    800059a8:	f74e                	sd	s3,424(sp)
    800059aa:	f352                	sd	s4,416(sp)
    800059ac:	ef56                	sd	s5,408(sp)
    800059ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059b0:	08000613          	li	a2,128
    800059b4:	f4040593          	addi	a1,s0,-192
    800059b8:	4501                	li	a0,0
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	1d8080e7          	jalr	472(ra) # 80002b92 <argstr>
    return -1;
    800059c2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059c4:	0c054a63          	bltz	a0,80005a98 <sys_exec+0xfa>
    800059c8:	e3840593          	addi	a1,s0,-456
    800059cc:	4505                	li	a0,1
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	1a2080e7          	jalr	418(ra) # 80002b70 <argaddr>
    800059d6:	0c054163          	bltz	a0,80005a98 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059da:	10000613          	li	a2,256
    800059de:	4581                	li	a1,0
    800059e0:	e4040513          	addi	a0,s0,-448
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	2fc080e7          	jalr	764(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059f0:	89a6                	mv	s3,s1
    800059f2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059f4:	02000a13          	li	s4,32
    800059f8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059fc:	00391513          	slli	a0,s2,0x3
    80005a00:	e3040593          	addi	a1,s0,-464
    80005a04:	e3843783          	ld	a5,-456(s0)
    80005a08:	953e                	add	a0,a0,a5
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	0aa080e7          	jalr	170(ra) # 80002ab4 <fetchaddr>
    80005a12:	02054a63          	bltz	a0,80005a46 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a16:	e3043783          	ld	a5,-464(s0)
    80005a1a:	c3b9                	beqz	a5,80005a60 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	0d8080e7          	jalr	216(ra) # 80000af4 <kalloc>
    80005a24:	85aa                	mv	a1,a0
    80005a26:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a2a:	cd11                	beqz	a0,80005a46 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a2c:	6605                	lui	a2,0x1
    80005a2e:	e3043503          	ld	a0,-464(s0)
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	0d4080e7          	jalr	212(ra) # 80002b06 <fetchstr>
    80005a3a:	00054663          	bltz	a0,80005a46 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a3e:	0905                	addi	s2,s2,1
    80005a40:	09a1                	addi	s3,s3,8
    80005a42:	fb491be3          	bne	s2,s4,800059f8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a46:	10048913          	addi	s2,s1,256
    80005a4a:	6088                	ld	a0,0(s1)
    80005a4c:	c529                	beqz	a0,80005a96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	faa080e7          	jalr	-86(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a56:	04a1                	addi	s1,s1,8
    80005a58:	ff2499e3          	bne	s1,s2,80005a4a <sys_exec+0xac>
  return -1;
    80005a5c:	597d                	li	s2,-1
    80005a5e:	a82d                	j	80005a98 <sys_exec+0xfa>
      argv[i] = 0;
    80005a60:	0a8e                	slli	s5,s5,0x3
    80005a62:	fc040793          	addi	a5,s0,-64
    80005a66:	9abe                	add	s5,s5,a5
    80005a68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a6c:	e4040593          	addi	a1,s0,-448
    80005a70:	f4040513          	addi	a0,s0,-192
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	194080e7          	jalr	404(ra) # 80004c08 <exec>
    80005a7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a7e:	10048993          	addi	s3,s1,256
    80005a82:	6088                	ld	a0,0(s1)
    80005a84:	c911                	beqz	a0,80005a98 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	f72080e7          	jalr	-142(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a8e:	04a1                	addi	s1,s1,8
    80005a90:	ff3499e3          	bne	s1,s3,80005a82 <sys_exec+0xe4>
    80005a94:	a011                	j	80005a98 <sys_exec+0xfa>
  return -1;
    80005a96:	597d                	li	s2,-1
}
    80005a98:	854a                	mv	a0,s2
    80005a9a:	60be                	ld	ra,456(sp)
    80005a9c:	641e                	ld	s0,448(sp)
    80005a9e:	74fa                	ld	s1,440(sp)
    80005aa0:	795a                	ld	s2,432(sp)
    80005aa2:	79ba                	ld	s3,424(sp)
    80005aa4:	7a1a                	ld	s4,416(sp)
    80005aa6:	6afa                	ld	s5,408(sp)
    80005aa8:	6179                	addi	sp,sp,464
    80005aaa:	8082                	ret

0000000080005aac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aac:	7139                	addi	sp,sp,-64
    80005aae:	fc06                	sd	ra,56(sp)
    80005ab0:	f822                	sd	s0,48(sp)
    80005ab2:	f426                	sd	s1,40(sp)
    80005ab4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ab6:	ffffc097          	auipc	ra,0xffffc
    80005aba:	0d0080e7          	jalr	208(ra) # 80001b86 <myproc>
    80005abe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ac0:	fd840593          	addi	a1,s0,-40
    80005ac4:	4501                	li	a0,0
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	0aa080e7          	jalr	170(ra) # 80002b70 <argaddr>
    return -1;
    80005ace:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ad0:	0e054063          	bltz	a0,80005bb0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ad4:	fc840593          	addi	a1,s0,-56
    80005ad8:	fd040513          	addi	a0,s0,-48
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	dfc080e7          	jalr	-516(ra) # 800048d8 <pipealloc>
    return -1;
    80005ae4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ae6:	0c054563          	bltz	a0,80005bb0 <sys_pipe+0x104>
  fd0 = -1;
    80005aea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aee:	fd043503          	ld	a0,-48(s0)
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	508080e7          	jalr	1288(ra) # 80004ffa <fdalloc>
    80005afa:	fca42223          	sw	a0,-60(s0)
    80005afe:	08054c63          	bltz	a0,80005b96 <sys_pipe+0xea>
    80005b02:	fc843503          	ld	a0,-56(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	4f4080e7          	jalr	1268(ra) # 80004ffa <fdalloc>
    80005b0e:	fca42023          	sw	a0,-64(s0)
    80005b12:	06054863          	bltz	a0,80005b82 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b16:	4691                	li	a3,4
    80005b18:	fc440613          	addi	a2,s0,-60
    80005b1c:	fd843583          	ld	a1,-40(s0)
    80005b20:	68a8                	ld	a0,80(s1)
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	b50080e7          	jalr	-1200(ra) # 80001672 <copyout>
    80005b2a:	02054063          	bltz	a0,80005b4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b2e:	4691                	li	a3,4
    80005b30:	fc040613          	addi	a2,s0,-64
    80005b34:	fd843583          	ld	a1,-40(s0)
    80005b38:	0591                	addi	a1,a1,4
    80005b3a:	68a8                	ld	a0,80(s1)
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	b36080e7          	jalr	-1226(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b46:	06055563          	bgez	a0,80005bb0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b4a:	fc442783          	lw	a5,-60(s0)
    80005b4e:	07e9                	addi	a5,a5,26
    80005b50:	078e                	slli	a5,a5,0x3
    80005b52:	97a6                	add	a5,a5,s1
    80005b54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b58:	fc042503          	lw	a0,-64(s0)
    80005b5c:	0569                	addi	a0,a0,26
    80005b5e:	050e                	slli	a0,a0,0x3
    80005b60:	9526                	add	a0,a0,s1
    80005b62:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b66:	fd043503          	ld	a0,-48(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	a3e080e7          	jalr	-1474(ra) # 800045a8 <fileclose>
    fileclose(wf);
    80005b72:	fc843503          	ld	a0,-56(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	a32080e7          	jalr	-1486(ra) # 800045a8 <fileclose>
    return -1;
    80005b7e:	57fd                	li	a5,-1
    80005b80:	a805                	j	80005bb0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b82:	fc442783          	lw	a5,-60(s0)
    80005b86:	0007c863          	bltz	a5,80005b96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b8a:	01a78513          	addi	a0,a5,26
    80005b8e:	050e                	slli	a0,a0,0x3
    80005b90:	9526                	add	a0,a0,s1
    80005b92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b96:	fd043503          	ld	a0,-48(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	a0e080e7          	jalr	-1522(ra) # 800045a8 <fileclose>
    fileclose(wf);
    80005ba2:	fc843503          	ld	a0,-56(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	a02080e7          	jalr	-1534(ra) # 800045a8 <fileclose>
    return -1;
    80005bae:	57fd                	li	a5,-1
}
    80005bb0:	853e                	mv	a0,a5
    80005bb2:	70e2                	ld	ra,56(sp)
    80005bb4:	7442                	ld	s0,48(sp)
    80005bb6:	74a2                	ld	s1,40(sp)
    80005bb8:	6121                	addi	sp,sp,64
    80005bba:	8082                	ret
    80005bbc:	0000                	unimp
	...

0000000080005bc0 <kernelvec>:
    80005bc0:	7111                	addi	sp,sp,-256
    80005bc2:	e006                	sd	ra,0(sp)
    80005bc4:	e40a                	sd	sp,8(sp)
    80005bc6:	e80e                	sd	gp,16(sp)
    80005bc8:	ec12                	sd	tp,24(sp)
    80005bca:	f016                	sd	t0,32(sp)
    80005bcc:	f41a                	sd	t1,40(sp)
    80005bce:	f81e                	sd	t2,48(sp)
    80005bd0:	fc22                	sd	s0,56(sp)
    80005bd2:	e0a6                	sd	s1,64(sp)
    80005bd4:	e4aa                	sd	a0,72(sp)
    80005bd6:	e8ae                	sd	a1,80(sp)
    80005bd8:	ecb2                	sd	a2,88(sp)
    80005bda:	f0b6                	sd	a3,96(sp)
    80005bdc:	f4ba                	sd	a4,104(sp)
    80005bde:	f8be                	sd	a5,112(sp)
    80005be0:	fcc2                	sd	a6,120(sp)
    80005be2:	e146                	sd	a7,128(sp)
    80005be4:	e54a                	sd	s2,136(sp)
    80005be6:	e94e                	sd	s3,144(sp)
    80005be8:	ed52                	sd	s4,152(sp)
    80005bea:	f156                	sd	s5,160(sp)
    80005bec:	f55a                	sd	s6,168(sp)
    80005bee:	f95e                	sd	s7,176(sp)
    80005bf0:	fd62                	sd	s8,184(sp)
    80005bf2:	e1e6                	sd	s9,192(sp)
    80005bf4:	e5ea                	sd	s10,200(sp)
    80005bf6:	e9ee                	sd	s11,208(sp)
    80005bf8:	edf2                	sd	t3,216(sp)
    80005bfa:	f1f6                	sd	t4,224(sp)
    80005bfc:	f5fa                	sd	t5,232(sp)
    80005bfe:	f9fe                	sd	t6,240(sp)
    80005c00:	d81fc0ef          	jal	ra,80002980 <kerneltrap>
    80005c04:	6082                	ld	ra,0(sp)
    80005c06:	6122                	ld	sp,8(sp)
    80005c08:	61c2                	ld	gp,16(sp)
    80005c0a:	7282                	ld	t0,32(sp)
    80005c0c:	7322                	ld	t1,40(sp)
    80005c0e:	73c2                	ld	t2,48(sp)
    80005c10:	7462                	ld	s0,56(sp)
    80005c12:	6486                	ld	s1,64(sp)
    80005c14:	6526                	ld	a0,72(sp)
    80005c16:	65c6                	ld	a1,80(sp)
    80005c18:	6666                	ld	a2,88(sp)
    80005c1a:	7686                	ld	a3,96(sp)
    80005c1c:	7726                	ld	a4,104(sp)
    80005c1e:	77c6                	ld	a5,112(sp)
    80005c20:	7866                	ld	a6,120(sp)
    80005c22:	688a                	ld	a7,128(sp)
    80005c24:	692a                	ld	s2,136(sp)
    80005c26:	69ca                	ld	s3,144(sp)
    80005c28:	6a6a                	ld	s4,152(sp)
    80005c2a:	7a8a                	ld	s5,160(sp)
    80005c2c:	7b2a                	ld	s6,168(sp)
    80005c2e:	7bca                	ld	s7,176(sp)
    80005c30:	7c6a                	ld	s8,184(sp)
    80005c32:	6c8e                	ld	s9,192(sp)
    80005c34:	6d2e                	ld	s10,200(sp)
    80005c36:	6dce                	ld	s11,208(sp)
    80005c38:	6e6e                	ld	t3,216(sp)
    80005c3a:	7e8e                	ld	t4,224(sp)
    80005c3c:	7f2e                	ld	t5,232(sp)
    80005c3e:	7fce                	ld	t6,240(sp)
    80005c40:	6111                	addi	sp,sp,256
    80005c42:	10200073          	sret
    80005c46:	00000013          	nop
    80005c4a:	00000013          	nop
    80005c4e:	0001                	nop

0000000080005c50 <timervec>:
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	e10c                	sd	a1,0(a0)
    80005c56:	e510                	sd	a2,8(a0)
    80005c58:	e914                	sd	a3,16(a0)
    80005c5a:	6d0c                	ld	a1,24(a0)
    80005c5c:	7110                	ld	a2,32(a0)
    80005c5e:	6194                	ld	a3,0(a1)
    80005c60:	96b2                	add	a3,a3,a2
    80005c62:	e194                	sd	a3,0(a1)
    80005c64:	4589                	li	a1,2
    80005c66:	14459073          	csrw	sip,a1
    80005c6a:	6914                	ld	a3,16(a0)
    80005c6c:	6510                	ld	a2,8(a0)
    80005c6e:	610c                	ld	a1,0(a0)
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	30200073          	mret
	...

0000000080005c7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c7a:	1141                	addi	sp,sp,-16
    80005c7c:	e422                	sd	s0,8(sp)
    80005c7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c80:	0c0007b7          	lui	a5,0xc000
    80005c84:	4705                	li	a4,1
    80005c86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c88:	c3d8                	sw	a4,4(a5)
}
    80005c8a:	6422                	ld	s0,8(sp)
    80005c8c:	0141                	addi	sp,sp,16
    80005c8e:	8082                	ret

0000000080005c90 <plicinithart>:

void
plicinithart(void)
{
    80005c90:	1141                	addi	sp,sp,-16
    80005c92:	e406                	sd	ra,8(sp)
    80005c94:	e022                	sd	s0,0(sp)
    80005c96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	ec2080e7          	jalr	-318(ra) # 80001b5a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ca0:	0085171b          	slliw	a4,a0,0x8
    80005ca4:	0c0027b7          	lui	a5,0xc002
    80005ca8:	97ba                	add	a5,a5,a4
    80005caa:	40200713          	li	a4,1026
    80005cae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cb2:	00d5151b          	slliw	a0,a0,0xd
    80005cb6:	0c2017b7          	lui	a5,0xc201
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	00052023          	sw	zero,0(a0)
}
    80005cc0:	60a2                	ld	ra,8(sp)
    80005cc2:	6402                	ld	s0,0(sp)
    80005cc4:	0141                	addi	sp,sp,16
    80005cc6:	8082                	ret

0000000080005cc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	e8a080e7          	jalr	-374(ra) # 80001b5a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cd8:	00d5179b          	slliw	a5,a0,0xd
    80005cdc:	0c201537          	lui	a0,0xc201
    80005ce0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ce2:	4148                	lw	a0,4(a0)
    80005ce4:	60a2                	ld	ra,8(sp)
    80005ce6:	6402                	ld	s0,0(sp)
    80005ce8:	0141                	addi	sp,sp,16
    80005cea:	8082                	ret

0000000080005cec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cec:	1101                	addi	sp,sp,-32
    80005cee:	ec06                	sd	ra,24(sp)
    80005cf0:	e822                	sd	s0,16(sp)
    80005cf2:	e426                	sd	s1,8(sp)
    80005cf4:	1000                	addi	s0,sp,32
    80005cf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	e62080e7          	jalr	-414(ra) # 80001b5a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d00:	00d5151b          	slliw	a0,a0,0xd
    80005d04:	0c2017b7          	lui	a5,0xc201
    80005d08:	97aa                	add	a5,a5,a0
    80005d0a:	c3c4                	sw	s1,4(a5)
}
    80005d0c:	60e2                	ld	ra,24(sp)
    80005d0e:	6442                	ld	s0,16(sp)
    80005d10:	64a2                	ld	s1,8(sp)
    80005d12:	6105                	addi	sp,sp,32
    80005d14:	8082                	ret

0000000080005d16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d16:	1141                	addi	sp,sp,-16
    80005d18:	e406                	sd	ra,8(sp)
    80005d1a:	e022                	sd	s0,0(sp)
    80005d1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d1e:	479d                	li	a5,7
    80005d20:	06a7c963          	blt	a5,a0,80005d92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d24:	0001d797          	auipc	a5,0x1d
    80005d28:	2dc78793          	addi	a5,a5,732 # 80023000 <disk>
    80005d2c:	00a78733          	add	a4,a5,a0
    80005d30:	6789                	lui	a5,0x2
    80005d32:	97ba                	add	a5,a5,a4
    80005d34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d38:	e7ad                	bnez	a5,80005da2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d3a:	00451793          	slli	a5,a0,0x4
    80005d3e:	0001f717          	auipc	a4,0x1f
    80005d42:	2c270713          	addi	a4,a4,706 # 80025000 <disk+0x2000>
    80005d46:	6314                	ld	a3,0(a4)
    80005d48:	96be                	add	a3,a3,a5
    80005d4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d4e:	6314                	ld	a3,0(a4)
    80005d50:	96be                	add	a3,a3,a5
    80005d52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d56:	6314                	ld	a3,0(a4)
    80005d58:	96be                	add	a3,a3,a5
    80005d5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d5e:	6318                	ld	a4,0(a4)
    80005d60:	97ba                	add	a5,a5,a4
    80005d62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d66:	0001d797          	auipc	a5,0x1d
    80005d6a:	29a78793          	addi	a5,a5,666 # 80023000 <disk>
    80005d6e:	97aa                	add	a5,a5,a0
    80005d70:	6509                	lui	a0,0x2
    80005d72:	953e                	add	a0,a0,a5
    80005d74:	4785                	li	a5,1
    80005d76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d7a:	0001f517          	auipc	a0,0x1f
    80005d7e:	29e50513          	addi	a0,a0,670 # 80025018 <disk+0x2018>
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	5da080e7          	jalr	1498(ra) # 8000235c <wakeup>
}
    80005d8a:	60a2                	ld	ra,8(sp)
    80005d8c:	6402                	ld	s0,0(sp)
    80005d8e:	0141                	addi	sp,sp,16
    80005d90:	8082                	ret
    panic("free_desc 1");
    80005d92:	00003517          	auipc	a0,0x3
    80005d96:	9ee50513          	addi	a0,a0,-1554 # 80008780 <syscalls+0x330>
    80005d9a:	ffffa097          	auipc	ra,0xffffa
    80005d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005da2:	00003517          	auipc	a0,0x3
    80005da6:	9ee50513          	addi	a0,a0,-1554 # 80008790 <syscalls+0x340>
    80005daa:	ffffa097          	auipc	ra,0xffffa
    80005dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>

0000000080005db2 <virtio_disk_init>:
{
    80005db2:	1101                	addi	sp,sp,-32
    80005db4:	ec06                	sd	ra,24(sp)
    80005db6:	e822                	sd	s0,16(sp)
    80005db8:	e426                	sd	s1,8(sp)
    80005dba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dbc:	00003597          	auipc	a1,0x3
    80005dc0:	9e458593          	addi	a1,a1,-1564 # 800087a0 <syscalls+0x350>
    80005dc4:	0001f517          	auipc	a0,0x1f
    80005dc8:	36450513          	addi	a0,a0,868 # 80025128 <disk+0x2128>
    80005dcc:	ffffb097          	auipc	ra,0xffffb
    80005dd0:	d88080e7          	jalr	-632(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd4:	100017b7          	lui	a5,0x10001
    80005dd8:	4398                	lw	a4,0(a5)
    80005dda:	2701                	sext.w	a4,a4
    80005ddc:	747277b7          	lui	a5,0x74727
    80005de0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005de4:	0ef71163          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005de8:	100017b7          	lui	a5,0x10001
    80005dec:	43dc                	lw	a5,4(a5)
    80005dee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df0:	4705                	li	a4,1
    80005df2:	0ce79a63          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005df6:	100017b7          	lui	a5,0x10001
    80005dfa:	479c                	lw	a5,8(a5)
    80005dfc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dfe:	4709                	li	a4,2
    80005e00:	0ce79363          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	47d8                	lw	a4,12(a5)
    80005e0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e0c:	554d47b7          	lui	a5,0x554d4
    80005e10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e14:	0af71963          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	4705                	li	a4,1
    80005e1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e20:	470d                	li	a4,3
    80005e22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e26:	c7ffe737          	lui	a4,0xc7ffe
    80005e2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e34:	472d                	li	a4,11
    80005e36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e38:	473d                	li	a4,15
    80005e3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e3c:	6705                	lui	a4,0x1
    80005e3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e44:	5bdc                	lw	a5,52(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e48:	c7d9                	beqz	a5,80005ed6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e4a:	471d                	li	a4,7
    80005e4c:	08f77d63          	bgeu	a4,a5,80005ee6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e50:	100014b7          	lui	s1,0x10001
    80005e54:	47a1                	li	a5,8
    80005e56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e58:	6609                	lui	a2,0x2
    80005e5a:	4581                	li	a1,0
    80005e5c:	0001d517          	auipc	a0,0x1d
    80005e60:	1a450513          	addi	a0,a0,420 # 80023000 <disk>
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	e7c080e7          	jalr	-388(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e6c:	0001d717          	auipc	a4,0x1d
    80005e70:	19470713          	addi	a4,a4,404 # 80023000 <disk>
    80005e74:	00c75793          	srli	a5,a4,0xc
    80005e78:	2781                	sext.w	a5,a5
    80005e7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e7c:	0001f797          	auipc	a5,0x1f
    80005e80:	18478793          	addi	a5,a5,388 # 80025000 <disk+0x2000>
    80005e84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e86:	0001d717          	auipc	a4,0x1d
    80005e8a:	1fa70713          	addi	a4,a4,506 # 80023080 <disk+0x80>
    80005e8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e90:	0001e717          	auipc	a4,0x1e
    80005e94:	17070713          	addi	a4,a4,368 # 80024000 <disk+0x1000>
    80005e98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e9a:	4705                	li	a4,1
    80005e9c:	00e78c23          	sb	a4,24(a5)
    80005ea0:	00e78ca3          	sb	a4,25(a5)
    80005ea4:	00e78d23          	sb	a4,26(a5)
    80005ea8:	00e78da3          	sb	a4,27(a5)
    80005eac:	00e78e23          	sb	a4,28(a5)
    80005eb0:	00e78ea3          	sb	a4,29(a5)
    80005eb4:	00e78f23          	sb	a4,30(a5)
    80005eb8:	00e78fa3          	sb	a4,31(a5)
}
    80005ebc:	60e2                	ld	ra,24(sp)
    80005ebe:	6442                	ld	s0,16(sp)
    80005ec0:	64a2                	ld	s1,8(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret
    panic("could not find virtio disk");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	8ea50513          	addi	a0,a0,-1814 # 800087b0 <syscalls+0x360>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	670080e7          	jalr	1648(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	8fa50513          	addi	a0,a0,-1798 # 800087d0 <syscalls+0x380>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ee6:	00003517          	auipc	a0,0x3
    80005eea:	90a50513          	addi	a0,a0,-1782 # 800087f0 <syscalls+0x3a0>
    80005eee:	ffffa097          	auipc	ra,0xffffa
    80005ef2:	650080e7          	jalr	1616(ra) # 8000053e <panic>

0000000080005ef6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ef6:	7159                	addi	sp,sp,-112
    80005ef8:	f486                	sd	ra,104(sp)
    80005efa:	f0a2                	sd	s0,96(sp)
    80005efc:	eca6                	sd	s1,88(sp)
    80005efe:	e8ca                	sd	s2,80(sp)
    80005f00:	e4ce                	sd	s3,72(sp)
    80005f02:	e0d2                	sd	s4,64(sp)
    80005f04:	fc56                	sd	s5,56(sp)
    80005f06:	f85a                	sd	s6,48(sp)
    80005f08:	f45e                	sd	s7,40(sp)
    80005f0a:	f062                	sd	s8,32(sp)
    80005f0c:	ec66                	sd	s9,24(sp)
    80005f0e:	e86a                	sd	s10,16(sp)
    80005f10:	1880                	addi	s0,sp,112
    80005f12:	892a                	mv	s2,a0
    80005f14:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f16:	00c52c83          	lw	s9,12(a0)
    80005f1a:	001c9c9b          	slliw	s9,s9,0x1
    80005f1e:	1c82                	slli	s9,s9,0x20
    80005f20:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f24:	0001f517          	auipc	a0,0x1f
    80005f28:	20450513          	addi	a0,a0,516 # 80025128 <disk+0x2128>
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	cb8080e7          	jalr	-840(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f34:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f36:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f38:	0001db97          	auipc	s7,0x1d
    80005f3c:	0c8b8b93          	addi	s7,s7,200 # 80023000 <disk>
    80005f40:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f42:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f44:	8a4e                	mv	s4,s3
    80005f46:	a051                	j	80005fca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f48:	00fb86b3          	add	a3,s7,a5
    80005f4c:	96da                	add	a3,a3,s6
    80005f4e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f52:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f54:	0207c563          	bltz	a5,80005f7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f58:	2485                	addiw	s1,s1,1
    80005f5a:	0711                	addi	a4,a4,4
    80005f5c:	25548063          	beq	s1,s5,8000619c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f60:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f62:	0001f697          	auipc	a3,0x1f
    80005f66:	0b668693          	addi	a3,a3,182 # 80025018 <disk+0x2018>
    80005f6a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f6c:	0006c583          	lbu	a1,0(a3)
    80005f70:	fde1                	bnez	a1,80005f48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f72:	2785                	addiw	a5,a5,1
    80005f74:	0685                	addi	a3,a3,1
    80005f76:	ff879be3          	bne	a5,s8,80005f6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f7e:	02905a63          	blez	s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f82:	f9042503          	lw	a0,-112(s0)
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	d90080e7          	jalr	-624(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005f8e:	4785                	li	a5,1
    80005f90:	0297d163          	bge	a5,s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f94:	f9442503          	lw	a0,-108(s0)
    80005f98:	00000097          	auipc	ra,0x0
    80005f9c:	d7e080e7          	jalr	-642(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005fa0:	4789                	li	a5,2
    80005fa2:	0097d863          	bge	a5,s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fa6:	f9842503          	lw	a0,-104(s0)
    80005faa:	00000097          	auipc	ra,0x0
    80005fae:	d6c080e7          	jalr	-660(ra) # 80005d16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fb2:	0001f597          	auipc	a1,0x1f
    80005fb6:	17658593          	addi	a1,a1,374 # 80025128 <disk+0x2128>
    80005fba:	0001f517          	auipc	a0,0x1f
    80005fbe:	05e50513          	addi	a0,a0,94 # 80025018 <disk+0x2018>
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	20e080e7          	jalr	526(ra) # 800021d0 <sleep>
  for(int i = 0; i < 3; i++){
    80005fca:	f9040713          	addi	a4,s0,-112
    80005fce:	84ce                	mv	s1,s3
    80005fd0:	bf41                	j	80005f60 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005fd2:	20058713          	addi	a4,a1,512
    80005fd6:	00471693          	slli	a3,a4,0x4
    80005fda:	0001d717          	auipc	a4,0x1d
    80005fde:	02670713          	addi	a4,a4,38 # 80023000 <disk>
    80005fe2:	9736                	add	a4,a4,a3
    80005fe4:	4685                	li	a3,1
    80005fe6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fea:	20058713          	addi	a4,a1,512
    80005fee:	00471693          	slli	a3,a4,0x4
    80005ff2:	0001d717          	auipc	a4,0x1d
    80005ff6:	00e70713          	addi	a4,a4,14 # 80023000 <disk>
    80005ffa:	9736                	add	a4,a4,a3
    80005ffc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006000:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006004:	7679                	lui	a2,0xffffe
    80006006:	963e                	add	a2,a2,a5
    80006008:	0001f697          	auipc	a3,0x1f
    8000600c:	ff868693          	addi	a3,a3,-8 # 80025000 <disk+0x2000>
    80006010:	6298                	ld	a4,0(a3)
    80006012:	9732                	add	a4,a4,a2
    80006014:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006016:	6298                	ld	a4,0(a3)
    80006018:	9732                	add	a4,a4,a2
    8000601a:	4541                	li	a0,16
    8000601c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000601e:	6298                	ld	a4,0(a3)
    80006020:	9732                	add	a4,a4,a2
    80006022:	4505                	li	a0,1
    80006024:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006028:	f9442703          	lw	a4,-108(s0)
    8000602c:	6288                	ld	a0,0(a3)
    8000602e:	962a                	add	a2,a2,a0
    80006030:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006034:	0712                	slli	a4,a4,0x4
    80006036:	6290                	ld	a2,0(a3)
    80006038:	963a                	add	a2,a2,a4
    8000603a:	05890513          	addi	a0,s2,88
    8000603e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006040:	6294                	ld	a3,0(a3)
    80006042:	96ba                	add	a3,a3,a4
    80006044:	40000613          	li	a2,1024
    80006048:	c690                	sw	a2,8(a3)
  if(write)
    8000604a:	140d0063          	beqz	s10,8000618a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000604e:	0001f697          	auipc	a3,0x1f
    80006052:	fb26b683          	ld	a3,-78(a3) # 80025000 <disk+0x2000>
    80006056:	96ba                	add	a3,a3,a4
    80006058:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000605c:	0001d817          	auipc	a6,0x1d
    80006060:	fa480813          	addi	a6,a6,-92 # 80023000 <disk>
    80006064:	0001f517          	auipc	a0,0x1f
    80006068:	f9c50513          	addi	a0,a0,-100 # 80025000 <disk+0x2000>
    8000606c:	6114                	ld	a3,0(a0)
    8000606e:	96ba                	add	a3,a3,a4
    80006070:	00c6d603          	lhu	a2,12(a3)
    80006074:	00166613          	ori	a2,a2,1
    80006078:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000607c:	f9842683          	lw	a3,-104(s0)
    80006080:	6110                	ld	a2,0(a0)
    80006082:	9732                	add	a4,a4,a2
    80006084:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006088:	20058613          	addi	a2,a1,512
    8000608c:	0612                	slli	a2,a2,0x4
    8000608e:	9642                	add	a2,a2,a6
    80006090:	577d                	li	a4,-1
    80006092:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006096:	00469713          	slli	a4,a3,0x4
    8000609a:	6114                	ld	a3,0(a0)
    8000609c:	96ba                	add	a3,a3,a4
    8000609e:	03078793          	addi	a5,a5,48
    800060a2:	97c2                	add	a5,a5,a6
    800060a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060a6:	611c                	ld	a5,0(a0)
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	4685                	li	a3,1
    800060ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ae:	611c                	ld	a5,0(a0)
    800060b0:	97ba                	add	a5,a5,a4
    800060b2:	4809                	li	a6,2
    800060b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060b8:	611c                	ld	a5,0(a0)
    800060ba:	973e                	add	a4,a4,a5
    800060bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060c8:	6518                	ld	a4,8(a0)
    800060ca:	00275783          	lhu	a5,2(a4)
    800060ce:	8b9d                	andi	a5,a5,7
    800060d0:	0786                	slli	a5,a5,0x1
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060dc:	6518                	ld	a4,8(a0)
    800060de:	00275783          	lhu	a5,2(a4)
    800060e2:	2785                	addiw	a5,a5,1
    800060e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060ec:	100017b7          	lui	a5,0x10001
    800060f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060f4:	00492703          	lw	a4,4(s2)
    800060f8:	4785                	li	a5,1
    800060fa:	02f71163          	bne	a4,a5,8000611c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800060fe:	0001f997          	auipc	s3,0x1f
    80006102:	02a98993          	addi	s3,s3,42 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006106:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006108:	85ce                	mv	a1,s3
    8000610a:	854a                	mv	a0,s2
    8000610c:	ffffc097          	auipc	ra,0xffffc
    80006110:	0c4080e7          	jalr	196(ra) # 800021d0 <sleep>
  while(b->disk == 1) {
    80006114:	00492783          	lw	a5,4(s2)
    80006118:	fe9788e3          	beq	a5,s1,80006108 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000611c:	f9042903          	lw	s2,-112(s0)
    80006120:	20090793          	addi	a5,s2,512
    80006124:	00479713          	slli	a4,a5,0x4
    80006128:	0001d797          	auipc	a5,0x1d
    8000612c:	ed878793          	addi	a5,a5,-296 # 80023000 <disk>
    80006130:	97ba                	add	a5,a5,a4
    80006132:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006136:	0001f997          	auipc	s3,0x1f
    8000613a:	eca98993          	addi	s3,s3,-310 # 80025000 <disk+0x2000>
    8000613e:	00491713          	slli	a4,s2,0x4
    80006142:	0009b783          	ld	a5,0(s3)
    80006146:	97ba                	add	a5,a5,a4
    80006148:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000614c:	854a                	mv	a0,s2
    8000614e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006152:	00000097          	auipc	ra,0x0
    80006156:	bc4080e7          	jalr	-1084(ra) # 80005d16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000615a:	8885                	andi	s1,s1,1
    8000615c:	f0ed                	bnez	s1,8000613e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000615e:	0001f517          	auipc	a0,0x1f
    80006162:	fca50513          	addi	a0,a0,-54 # 80025128 <disk+0x2128>
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
}
    8000616e:	70a6                	ld	ra,104(sp)
    80006170:	7406                	ld	s0,96(sp)
    80006172:	64e6                	ld	s1,88(sp)
    80006174:	6946                	ld	s2,80(sp)
    80006176:	69a6                	ld	s3,72(sp)
    80006178:	6a06                	ld	s4,64(sp)
    8000617a:	7ae2                	ld	s5,56(sp)
    8000617c:	7b42                	ld	s6,48(sp)
    8000617e:	7ba2                	ld	s7,40(sp)
    80006180:	7c02                	ld	s8,32(sp)
    80006182:	6ce2                	ld	s9,24(sp)
    80006184:	6d42                	ld	s10,16(sp)
    80006186:	6165                	addi	sp,sp,112
    80006188:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618a:	0001f697          	auipc	a3,0x1f
    8000618e:	e766b683          	ld	a3,-394(a3) # 80025000 <disk+0x2000>
    80006192:	96ba                	add	a3,a3,a4
    80006194:	4609                	li	a2,2
    80006196:	00c69623          	sh	a2,12(a3)
    8000619a:	b5c9                	j	8000605c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000619c:	f9042583          	lw	a1,-112(s0)
    800061a0:	20058793          	addi	a5,a1,512
    800061a4:	0792                	slli	a5,a5,0x4
    800061a6:	0001d517          	auipc	a0,0x1d
    800061aa:	f0250513          	addi	a0,a0,-254 # 800230a8 <disk+0xa8>
    800061ae:	953e                	add	a0,a0,a5
  if(write)
    800061b0:	e20d11e3          	bnez	s10,80005fd2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061b4:	20058713          	addi	a4,a1,512
    800061b8:	00471693          	slli	a3,a4,0x4
    800061bc:	0001d717          	auipc	a4,0x1d
    800061c0:	e4470713          	addi	a4,a4,-444 # 80023000 <disk>
    800061c4:	9736                	add	a4,a4,a3
    800061c6:	0a072423          	sw	zero,168(a4)
    800061ca:	b505                	j	80005fea <virtio_disk_rw+0xf4>

00000000800061cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061cc:	1101                	addi	sp,sp,-32
    800061ce:	ec06                	sd	ra,24(sp)
    800061d0:	e822                	sd	s0,16(sp)
    800061d2:	e426                	sd	s1,8(sp)
    800061d4:	e04a                	sd	s2,0(sp)
    800061d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061d8:	0001f517          	auipc	a0,0x1f
    800061dc:	f5050513          	addi	a0,a0,-176 # 80025128 <disk+0x2128>
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e8:	10001737          	lui	a4,0x10001
    800061ec:	533c                	lw	a5,96(a4)
    800061ee:	8b8d                	andi	a5,a5,3
    800061f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061f6:	0001f797          	auipc	a5,0x1f
    800061fa:	e0a78793          	addi	a5,a5,-502 # 80025000 <disk+0x2000>
    800061fe:	6b94                	ld	a3,16(a5)
    80006200:	0207d703          	lhu	a4,32(a5)
    80006204:	0026d783          	lhu	a5,2(a3)
    80006208:	06f70163          	beq	a4,a5,8000626a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000620c:	0001d917          	auipc	s2,0x1d
    80006210:	df490913          	addi	s2,s2,-524 # 80023000 <disk>
    80006214:	0001f497          	auipc	s1,0x1f
    80006218:	dec48493          	addi	s1,s1,-532 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000621c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006220:	6898                	ld	a4,16(s1)
    80006222:	0204d783          	lhu	a5,32(s1)
    80006226:	8b9d                	andi	a5,a5,7
    80006228:	078e                	slli	a5,a5,0x3
    8000622a:	97ba                	add	a5,a5,a4
    8000622c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000622e:	20078713          	addi	a4,a5,512
    80006232:	0712                	slli	a4,a4,0x4
    80006234:	974a                	add	a4,a4,s2
    80006236:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000623a:	e731                	bnez	a4,80006286 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000623c:	20078793          	addi	a5,a5,512
    80006240:	0792                	slli	a5,a5,0x4
    80006242:	97ca                	add	a5,a5,s2
    80006244:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006246:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000624a:	ffffc097          	auipc	ra,0xffffc
    8000624e:	112080e7          	jalr	274(ra) # 8000235c <wakeup>

    disk.used_idx += 1;
    80006252:	0204d783          	lhu	a5,32(s1)
    80006256:	2785                	addiw	a5,a5,1
    80006258:	17c2                	slli	a5,a5,0x30
    8000625a:	93c1                	srli	a5,a5,0x30
    8000625c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006260:	6898                	ld	a4,16(s1)
    80006262:	00275703          	lhu	a4,2(a4)
    80006266:	faf71be3          	bne	a4,a5,8000621c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000626a:	0001f517          	auipc	a0,0x1f
    8000626e:	ebe50513          	addi	a0,a0,-322 # 80025128 <disk+0x2128>
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	a26080e7          	jalr	-1498(ra) # 80000c98 <release>
}
    8000627a:	60e2                	ld	ra,24(sp)
    8000627c:	6442                	ld	s0,16(sp)
    8000627e:	64a2                	ld	s1,8(sp)
    80006280:	6902                	ld	s2,0(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret
      panic("virtio_disk_intr status");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	58a50513          	addi	a0,a0,1418 # 80008810 <syscalls+0x3c0>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
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
