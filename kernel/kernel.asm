
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
    80000068:	e3c78793          	addi	a5,a5,-452 # 80005ea0 <timervec>
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
    80000130:	666080e7          	jalr	1638(ra) # 80002792 <either_copyin>
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
    800001c8:	aca080e7          	jalr	-1334(ra) # 80001c8e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	150080e7          	jalr	336(ra) # 80002324 <sleep>
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
    80000214:	52c080e7          	jalr	1324(ra) # 8000273c <either_copyout>
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
    800002f6:	4f6080e7          	jalr	1270(ra) # 800027e8 <procdump>
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
    8000044a:	084080e7          	jalr	132(ra) # 800024ca <wakeup>
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
    800008a4:	c2a080e7          	jalr	-982(ra) # 800024ca <wakeup>
    
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
    80000930:	9f8080e7          	jalr	-1544(ra) # 80002324 <sleep>
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
    80000b82:	0f4080e7          	jalr	244(ra) # 80001c72 <mycpu>
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
    80000bb4:	0c2080e7          	jalr	194(ra) # 80001c72 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0b6080e7          	jalr	182(ra) # 80001c72 <mycpu>
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
    80000bd8:	09e080e7          	jalr	158(ra) # 80001c72 <mycpu>
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
    80000c18:	05e080e7          	jalr	94(ra) # 80001c72 <mycpu>
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
    80000c44:	032080e7          	jalr	50(ra) # 80001c72 <mycpu>
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
    80000e9a:	dcc080e7          	jalr	-564(ra) # 80001c62 <cpuid>
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
    80000eb6:	db0080e7          	jalr	-592(ra) # 80001c62 <cpuid>
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
    80000ed8:	a54080e7          	jalr	-1452(ra) # 80002928 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	004080e7          	jalr	4(ra) # 80005ee0 <plicinithart>
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
    80000f48:	c5e080e7          	jalr	-930(ra) # 80001ba2 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	9b4080e7          	jalr	-1612(ra) # 80002900 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9d4080e7          	jalr	-1580(ra) # 80002928 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f6e080e7          	jalr	-146(ra) # 80005eca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f7c080e7          	jalr	-132(ra) # 80005ee0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	160080e7          	jalr	352(ra) # 800030cc <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	7f0080e7          	jalr	2032(ra) # 80003764 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	79a080e7          	jalr	1946(ra) # 80004716 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	07e080e7          	jalr	126(ra) # 80006002 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	fee080e7          	jalr	-18(ra) # 80001f7a <userinit>
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
//    via swtch back to the scheduler.

#ifdef DEFAULT
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
  printf("DEFAULT\n");
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
    80001a9c:	00010c17          	auipc	s8,0x10
    80001aa0:	824c0c13          	addi	s8,s8,-2012 # 800112c0 <cpus>
    80001aa4:	00779713          	slli	a4,a5,0x7
    80001aa8:	00ec06b3          	add	a3,s8,a4
    80001aac:	0006b023          	sd	zero,0(a3) # 1000 <_entry-0x7ffff000>
          swtch(&c->context, &p->context);
    80001ab0:	0721                	addi	a4,a4,8
    80001ab2:	9c3a                	add	s8,s8,a4
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001ab4:	00010917          	auipc	s2,0x10
    80001ab8:	c3c90913          	addi	s2,s2,-964 # 800116f0 <proc>
          int before_switch = ticks;
    80001abc:	00007a17          	auipc	s4,0x7
    80001ac0:	594a0a13          	addi	s4,s4,1428 # 80009050 <ticks>
          c->proc = p;
    80001ac4:	8bb6                	mv	s7,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ac6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001aca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ace:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ad2:	00010497          	auipc	s1,0x10
    80001ad6:	c1e48493          	addi	s1,s1,-994 # 800116f0 <proc>
        if(p->state == RUNNABLE) {
    80001ada:	4b0d                	li	s6,3
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001adc:	00007a97          	auipc	s5,0x7
    80001ae0:	568a8a93          	addi	s5,s5,1384 # 80009044 <finish>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ae4:	00016997          	auipc	s3,0x16
    80001ae8:	c0c98993          	addi	s3,s3,-1012 # 800176f0 <tickslock>
    80001aec:	a01d                	j	80001b12 <scheduler+0xa6>
        acquire(&p->lock);
    80001aee:	8ca6                	mv	s9,s1
    80001af0:	8526                	mv	a0,s1
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	0f2080e7          	jalr	242(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001afa:	4c9c                	lw	a5,24(s1)
    80001afc:	05678163          	beq	a5,s6,80001b3e <scheduler+0xd2>
        release(&p->lock);
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	196080e7          	jalr	406(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001b0a:	18048493          	addi	s1,s1,384
    80001b0e:	fb348ce3          	beq	s1,s3,80001ac6 <scheduler+0x5a>
      if ((finish<ticks) | (p->pid==proc[0].pid) | (p->pid==proc[1].pid)){
    80001b12:	5894                	lw	a3,48(s1)
    80001b14:	03092783          	lw	a5,48(s2)
    80001b18:	8f95                	sub	a5,a5,a3
    80001b1a:	0017b793          	seqz	a5,a5
    80001b1e:	1b092703          	lw	a4,432(s2)
    80001b22:	8f15                	sub	a4,a4,a3
    80001b24:	00173713          	seqz	a4,a4
    80001b28:	8fd9                	or	a5,a5,a4
    80001b2a:	0ff7f793          	andi	a5,a5,255
    80001b2e:	f3e1                	bnez	a5,80001aee <scheduler+0x82>
    80001b30:	000aa703          	lw	a4,0(s5)
    80001b34:	000a2783          	lw	a5,0(s4)
    80001b38:	fcf779e3          	bgeu	a4,a5,80001b0a <scheduler+0x9e>
    80001b3c:	bf4d                	j	80001aee <scheduler+0x82>
          p->state = RUNNING;
    80001b3e:	4791                	li	a5,4
    80001b40:	cc9c                	sw	a5,24(s1)
          int before_switch = ticks;
    80001b42:	000a2d03          	lw	s10,0(s4)
          c->proc = p;
    80001b46:	009bb023          	sd	s1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b4a:	589c                	lw	a5,48(s1)
    80001b4c:	03092703          	lw	a4,48(s2)
    80001b50:	00f70c63          	beq	a4,a5,80001b68 <scheduler+0xfc>
    80001b54:	1b092703          	lw	a4,432(s2)
    80001b58:	00f70863          	beq	a4,a5,80001b68 <scheduler+0xfc>
            p->runnable_time = p->runnable_time + ticks - p->last_runnable_time;
    80001b5c:	40fc                	lw	a5,68(s1)
    80001b5e:	01a787bb          	addw	a5,a5,s10
    80001b62:	5cd8                	lw	a4,60(s1)
    80001b64:	9f99                	subw	a5,a5,a4
    80001b66:	c0fc                	sw	a5,68(s1)
          swtch(&c->context, &p->context);
    80001b68:	078c8593          	addi	a1,s9,120
    80001b6c:	8562                	mv	a0,s8
    80001b6e:	00001097          	auipc	ra,0x1
    80001b72:	d28080e7          	jalr	-728(ra) # 80002896 <swtch>
          if ((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)) {
    80001b76:	589c                	lw	a5,48(s1)
    80001b78:	03092703          	lw	a4,48(s2)
    80001b7c:	02f70063          	beq	a4,a5,80001b9c <scheduler+0x130>
    80001b80:	1b092703          	lw	a4,432(s2)
    80001b84:	00f70c63          	beq	a4,a5,80001b9c <scheduler+0x130>
            p->running_time = p->running_time + ticks - before_switch;
    80001b88:	000a2783          	lw	a5,0(s4)
    80001b8c:	41a787bb          	subw	a5,a5,s10
    80001b90:	0484ad03          	lw	s10,72(s1)
    80001b94:	00fd0d3b          	addw	s10,s10,a5
    80001b98:	05a4a423          	sw	s10,72(s1)
          c->proc = 0;
    80001b9c:	000bb023          	sd	zero,0(s7)
    80001ba0:	b785                	j	80001b00 <scheduler+0x94>

0000000080001ba2 <procinit>:
{
    80001ba2:	7139                	addi	sp,sp,-64
    80001ba4:	fc06                	sd	ra,56(sp)
    80001ba6:	f822                	sd	s0,48(sp)
    80001ba8:	f426                	sd	s1,40(sp)
    80001baa:	f04a                	sd	s2,32(sp)
    80001bac:	ec4e                	sd	s3,24(sp)
    80001bae:	e852                	sd	s4,16(sp)
    80001bb0:	e456                	sd	s5,8(sp)
    80001bb2:	e05a                	sd	s6,0(sp)
    80001bb4:	0080                	addi	s0,sp,64
  start_time = ticks;
    80001bb6:	00007797          	auipc	a5,0x7
    80001bba:	49a7a783          	lw	a5,1178(a5) # 80009050 <ticks>
    80001bbe:	00007717          	auipc	a4,0x7
    80001bc2:	46f72923          	sw	a5,1138(a4) # 80009030 <start_time>
  initlock(&pid_lock, "nextpid");
    80001bc6:	00006597          	auipc	a1,0x6
    80001bca:	6ba58593          	addi	a1,a1,1722 # 80008280 <digits+0x240>
    80001bce:	00010517          	auipc	a0,0x10
    80001bd2:	af250513          	addi	a0,a0,-1294 # 800116c0 <pid_lock>
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	f7e080e7          	jalr	-130(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bde:	00006597          	auipc	a1,0x6
    80001be2:	6aa58593          	addi	a1,a1,1706 # 80008288 <digits+0x248>
    80001be6:	00010517          	auipc	a0,0x10
    80001bea:	af250513          	addi	a0,a0,-1294 # 800116d8 <wait_lock>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	f66080e7          	jalr	-154(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	00010497          	auipc	s1,0x10
    80001bfa:	afa48493          	addi	s1,s1,-1286 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001bfe:	00006b17          	auipc	s6,0x6
    80001c02:	69ab0b13          	addi	s6,s6,1690 # 80008298 <digits+0x258>
      p->kstack = KSTACK((int) (p - proc));
    80001c06:	8aa6                	mv	s5,s1
    80001c08:	00006a17          	auipc	s4,0x6
    80001c0c:	3f8a0a13          	addi	s4,s4,1016 # 80008000 <etext>
    80001c10:	04000937          	lui	s2,0x4000
    80001c14:	197d                	addi	s2,s2,-1
    80001c16:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	00016997          	auipc	s3,0x16
    80001c1c:	ad898993          	addi	s3,s3,-1320 # 800176f0 <tickslock>
      initlock(&p->lock, "proc");
    80001c20:	85da                	mv	a1,s6
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	f30080e7          	jalr	-208(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c2c:	415487b3          	sub	a5,s1,s5
    80001c30:	879d                	srai	a5,a5,0x7
    80001c32:	000a3703          	ld	a4,0(s4)
    80001c36:	02e787b3          	mul	a5,a5,a4
    80001c3a:	2785                	addiw	a5,a5,1
    80001c3c:	00d7979b          	slliw	a5,a5,0xd
    80001c40:	40f907b3          	sub	a5,s2,a5
    80001c44:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	18048493          	addi	s1,s1,384
    80001c4a:	fd349be3          	bne	s1,s3,80001c20 <procinit+0x7e>
}
    80001c4e:	70e2                	ld	ra,56(sp)
    80001c50:	7442                	ld	s0,48(sp)
    80001c52:	74a2                	ld	s1,40(sp)
    80001c54:	7902                	ld	s2,32(sp)
    80001c56:	69e2                	ld	s3,24(sp)
    80001c58:	6a42                	ld	s4,16(sp)
    80001c5a:	6aa2                	ld	s5,8(sp)
    80001c5c:	6b02                	ld	s6,0(sp)
    80001c5e:	6121                	addi	sp,sp,64
    80001c60:	8082                	ret

0000000080001c62 <cpuid>:
{
    80001c62:	1141                	addi	sp,sp,-16
    80001c64:	e422                	sd	s0,8(sp)
    80001c66:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c68:	8512                	mv	a0,tp
  return id;
}
    80001c6a:	2501                	sext.w	a0,a0
    80001c6c:	6422                	ld	s0,8(sp)
    80001c6e:	0141                	addi	sp,sp,16
    80001c70:	8082                	ret

0000000080001c72 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c72:	1141                	addi	sp,sp,-16
    80001c74:	e422                	sd	s0,8(sp)
    80001c76:	0800                	addi	s0,sp,16
    80001c78:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c7a:	2781                	sext.w	a5,a5
    80001c7c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c7e:	0000f517          	auipc	a0,0xf
    80001c82:	64250513          	addi	a0,a0,1602 # 800112c0 <cpus>
    80001c86:	953e                	add	a0,a0,a5
    80001c88:	6422                	ld	s0,8(sp)
    80001c8a:	0141                	addi	sp,sp,16
    80001c8c:	8082                	ret

0000000080001c8e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c8e:	1101                	addi	sp,sp,-32
    80001c90:	ec06                	sd	ra,24(sp)
    80001c92:	e822                	sd	s0,16(sp)
    80001c94:	e426                	sd	s1,8(sp)
    80001c96:	1000                	addi	s0,sp,32
  push_off();
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	f00080e7          	jalr	-256(ra) # 80000b98 <push_off>
    80001ca0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ca2:	2781                	sext.w	a5,a5
    80001ca4:	079e                	slli	a5,a5,0x7
    80001ca6:	0000f717          	auipc	a4,0xf
    80001caa:	61a70713          	addi	a4,a4,1562 # 800112c0 <cpus>
    80001cae:	97ba                	add	a5,a5,a4
    80001cb0:	6384                	ld	s1,0(a5)
  pop_off();
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	f86080e7          	jalr	-122(ra) # 80000c38 <pop_off>
  return p;
}
    80001cba:	8526                	mv	a0,s1
    80001cbc:	60e2                	ld	ra,24(sp)
    80001cbe:	6442                	ld	s0,16(sp)
    80001cc0:	64a2                	ld	s1,8(sp)
    80001cc2:	6105                	addi	sp,sp,32
    80001cc4:	8082                	ret

0000000080001cc6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001cc6:	1141                	addi	sp,sp,-16
    80001cc8:	e406                	sd	ra,8(sp)
    80001cca:	e022                	sd	s0,0(sp)
    80001ccc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	fc0080e7          	jalr	-64(ra) # 80001c8e <myproc>
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	fc2080e7          	jalr	-62(ra) # 80000c98 <release>

  if (first) {
    80001cde:	00007797          	auipc	a5,0x7
    80001ce2:	bf27a783          	lw	a5,-1038(a5) # 800088d0 <first.1714>
    80001ce6:	eb89                	bnez	a5,80001cf8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ce8:	00001097          	auipc	ra,0x1
    80001cec:	c58080e7          	jalr	-936(ra) # 80002940 <usertrapret>
}
    80001cf0:	60a2                	ld	ra,8(sp)
    80001cf2:	6402                	ld	s0,0(sp)
    80001cf4:	0141                	addi	sp,sp,16
    80001cf6:	8082                	ret
    first = 0;
    80001cf8:	00007797          	auipc	a5,0x7
    80001cfc:	bc07ac23          	sw	zero,-1064(a5) # 800088d0 <first.1714>
    fsinit(ROOTDEV);
    80001d00:	4505                	li	a0,1
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	9e2080e7          	jalr	-1566(ra) # 800036e4 <fsinit>
    80001d0a:	bff9                	j	80001ce8 <forkret+0x22>

0000000080001d0c <allocpid>:
allocpid() {
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	e04a                	sd	s2,0(sp)
    80001d16:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d18:	00010917          	auipc	s2,0x10
    80001d1c:	9a890913          	addi	s2,s2,-1624 # 800116c0 <pid_lock>
    80001d20:	854a                	mv	a0,s2
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	ec2080e7          	jalr	-318(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001d2a:	00007797          	auipc	a5,0x7
    80001d2e:	baa78793          	addi	a5,a5,-1110 # 800088d4 <nextpid>
    80001d32:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d34:	0014871b          	addiw	a4,s1,1
    80001d38:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d3a:	854a                	mv	a0,s2
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f5c080e7          	jalr	-164(ra) # 80000c98 <release>
}
    80001d44:	8526                	mv	a0,s1
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <proc_pagetable>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	5da080e7          	jalr	1498(ra) # 8000133a <uvmcreate>
    80001d68:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d6a:	c121                	beqz	a0,80001daa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d6c:	4729                	li	a4,10
    80001d6e:	00005697          	auipc	a3,0x5
    80001d72:	29268693          	addi	a3,a3,658 # 80007000 <_trampoline>
    80001d76:	6605                	lui	a2,0x1
    80001d78:	040005b7          	lui	a1,0x4000
    80001d7c:	15fd                	addi	a1,a1,-1
    80001d7e:	05b2                	slli	a1,a1,0xc
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	330080e7          	jalr	816(ra) # 800010b0 <mappages>
    80001d88:	02054863          	bltz	a0,80001db8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d8c:	4719                	li	a4,6
    80001d8e:	07093683          	ld	a3,112(s2)
    80001d92:	6605                	lui	a2,0x1
    80001d94:	020005b7          	lui	a1,0x2000
    80001d98:	15fd                	addi	a1,a1,-1
    80001d9a:	05b6                	slli	a1,a1,0xd
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	312080e7          	jalr	786(ra) # 800010b0 <mappages>
    80001da6:	02054163          	bltz	a0,80001dc8 <proc_pagetable+0x76>
}
    80001daa:	8526                	mv	a0,s1
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6902                	ld	s2,0(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret
    uvmfree(pagetable, 0);
    80001db8:	4581                	li	a1,0
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	77a080e7          	jalr	1914(ra) # 80001536 <uvmfree>
    return 0;
    80001dc4:	4481                	li	s1,0
    80001dc6:	b7d5                	j	80001daa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc8:	4681                	li	a3,0
    80001dca:	4605                	li	a2,1
    80001dcc:	040005b7          	lui	a1,0x4000
    80001dd0:	15fd                	addi	a1,a1,-1
    80001dd2:	05b2                	slli	a1,a1,0xc
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	4a0080e7          	jalr	1184(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dde:	4581                	li	a1,0
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	754080e7          	jalr	1876(ra) # 80001536 <uvmfree>
    return 0;
    80001dea:	4481                	li	s1,0
    80001dec:	bf7d                	j	80001daa <proc_pagetable+0x58>

0000000080001dee <proc_freepagetable>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	e04a                	sd	s2,0(sp)
    80001df8:	1000                	addi	s0,sp,32
    80001dfa:	84aa                	mv	s1,a0
    80001dfc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dfe:	4681                	li	a3,0
    80001e00:	4605                	li	a2,1
    80001e02:	040005b7          	lui	a1,0x4000
    80001e06:	15fd                	addi	a1,a1,-1
    80001e08:	05b2                	slli	a1,a1,0xc
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	46c080e7          	jalr	1132(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e12:	4681                	li	a3,0
    80001e14:	4605                	li	a2,1
    80001e16:	020005b7          	lui	a1,0x2000
    80001e1a:	15fd                	addi	a1,a1,-1
    80001e1c:	05b6                	slli	a1,a1,0xd
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	456080e7          	jalr	1110(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e28:	85ca                	mv	a1,s2
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	70a080e7          	jalr	1802(ra) # 80001536 <uvmfree>
}
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6902                	ld	s2,0(sp)
    80001e3c:	6105                	addi	sp,sp,32
    80001e3e:	8082                	ret

0000000080001e40 <freeproc>:
{
    80001e40:	1101                	addi	sp,sp,-32
    80001e42:	ec06                	sd	ra,24(sp)
    80001e44:	e822                	sd	s0,16(sp)
    80001e46:	e426                	sd	s1,8(sp)
    80001e48:	1000                	addi	s0,sp,32
    80001e4a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e4c:	7928                	ld	a0,112(a0)
    80001e4e:	c509                	beqz	a0,80001e58 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	ba8080e7          	jalr	-1112(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e58:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001e5c:	74a8                	ld	a0,104(s1)
    80001e5e:	c511                	beqz	a0,80001e6a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e60:	70ac                	ld	a1,96(s1)
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	f8c080e7          	jalr	-116(ra) # 80001dee <proc_freepagetable>
  p->pagetable = 0;
    80001e6a:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001e6e:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001e72:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e76:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001e7a:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001e7e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e82:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e86:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e8a:	0004ac23          	sw	zero,24(s1)
}
    80001e8e:	60e2                	ld	ra,24(sp)
    80001e90:	6442                	ld	s0,16(sp)
    80001e92:	64a2                	ld	s1,8(sp)
    80001e94:	6105                	addi	sp,sp,32
    80001e96:	8082                	ret

0000000080001e98 <allocproc>:
{
    80001e98:	1101                	addi	sp,sp,-32
    80001e9a:	ec06                	sd	ra,24(sp)
    80001e9c:	e822                	sd	s0,16(sp)
    80001e9e:	e426                	sd	s1,8(sp)
    80001ea0:	e04a                	sd	s2,0(sp)
    80001ea2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ea4:	00010497          	auipc	s1,0x10
    80001ea8:	84c48493          	addi	s1,s1,-1972 # 800116f0 <proc>
    80001eac:	00016917          	auipc	s2,0x16
    80001eb0:	84490913          	addi	s2,s2,-1980 # 800176f0 <tickslock>
    acquire(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d2e080e7          	jalr	-722(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001ebe:	4c9c                	lw	a5,24(s1)
    80001ec0:	cf81                	beqz	a5,80001ed8 <allocproc+0x40>
      release(&p->lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ecc:	18048493          	addi	s1,s1,384
    80001ed0:	ff2492e3          	bne	s1,s2,80001eb4 <allocproc+0x1c>
  return 0;
    80001ed4:	4481                	li	s1,0
    80001ed6:	a09d                	j	80001f3c <allocproc+0xa4>
  p->pid = allocpid();
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	e34080e7          	jalr	-460(ra) # 80001d0c <allocpid>
    80001ee0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ee2:	4785                	li	a5,1
    80001ee4:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001ee6:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001eea:	0204ac23          	sw	zero,56(s1)
  p->sleeping_time = 0;
    80001eee:	0404a023          	sw	zero,64(s1)
  p->runnable_time = 0;
    80001ef2:	0404a223          	sw	zero,68(s1)
  p->running_time = 0;
    80001ef6:	0404a423          	sw	zero,72(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	bfa080e7          	jalr	-1030(ra) # 80000af4 <kalloc>
    80001f02:	892a                	mv	s2,a0
    80001f04:	f8a8                	sd	a0,112(s1)
    80001f06:	c131                	beqz	a0,80001f4a <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	e48080e7          	jalr	-440(ra) # 80001d52 <proc_pagetable>
    80001f12:	892a                	mv	s2,a0
    80001f14:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001f16:	c531                	beqz	a0,80001f62 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001f18:	07000613          	li	a2,112
    80001f1c:	4581                	li	a1,0
    80001f1e:	07848513          	addi	a0,s1,120
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	dbe080e7          	jalr	-578(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f2a:	00000797          	auipc	a5,0x0
    80001f2e:	d9c78793          	addi	a5,a5,-612 # 80001cc6 <forkret>
    80001f32:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f34:	6cbc                	ld	a5,88(s1)
    80001f36:	6705                	lui	a4,0x1
    80001f38:	97ba                	add	a5,a5,a4
    80001f3a:	e0dc                	sd	a5,128(s1)
}
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	60e2                	ld	ra,24(sp)
    80001f40:	6442                	ld	s0,16(sp)
    80001f42:	64a2                	ld	s1,8(sp)
    80001f44:	6902                	ld	s2,0(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret
    freeproc(p);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	ef4080e7          	jalr	-268(ra) # 80001e40 <freeproc>
    release(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d42080e7          	jalr	-702(ra) # 80000c98 <release>
    return 0;
    80001f5e:	84ca                	mv	s1,s2
    80001f60:	bff1                	j	80001f3c <allocproc+0xa4>
    freeproc(p);
    80001f62:	8526                	mv	a0,s1
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	edc080e7          	jalr	-292(ra) # 80001e40 <freeproc>
    release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d2a080e7          	jalr	-726(ra) # 80000c98 <release>
    return 0;
    80001f76:	84ca                	mv	s1,s2
    80001f78:	b7d1                	j	80001f3c <allocproc+0xa4>

0000000080001f7a <userinit>:
{
    80001f7a:	1101                	addi	sp,sp,-32
    80001f7c:	ec06                	sd	ra,24(sp)
    80001f7e:	e822                	sd	s0,16(sp)
    80001f80:	e426                	sd	s1,8(sp)
    80001f82:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	f14080e7          	jalr	-236(ra) # 80001e98 <allocproc>
    80001f8c:	84aa                	mv	s1,a0
  initproc = p;
    80001f8e:	00007797          	auipc	a5,0x7
    80001f92:	0aa7bd23          	sd	a0,186(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f96:	03400613          	li	a2,52
    80001f9a:	00007597          	auipc	a1,0x7
    80001f9e:	94658593          	addi	a1,a1,-1722 # 800088e0 <initcode>
    80001fa2:	7528                	ld	a0,104(a0)
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	3c4080e7          	jalr	964(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001fac:	6785                	lui	a5,0x1
    80001fae:	f0bc                	sd	a5,96(s1)
  sleeping_processes_mean = 0;
    80001fb0:	00007717          	auipc	a4,0x7
    80001fb4:	08072823          	sw	zero,144(a4) # 80009040 <sleeping_processes_mean>
  running_processes_mean = 0;
    80001fb8:	00007717          	auipc	a4,0x7
    80001fbc:	08072223          	sw	zero,132(a4) # 8000903c <running_processes_mean>
  runnable_processes_mean = 0;
    80001fc0:	00007717          	auipc	a4,0x7
    80001fc4:	06072c23          	sw	zero,120(a4) # 80009038 <runnable_processes_mean>
  p->trapframe->epc = 0;      // user program counter
    80001fc8:	78b8                	ld	a4,112(s1)
    80001fca:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fce:	78b8                	ld	a4,112(s1)
    80001fd0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fd2:	4641                	li	a2,16
    80001fd4:	00006597          	auipc	a1,0x6
    80001fd8:	2cc58593          	addi	a1,a1,716 # 800082a0 <digits+0x260>
    80001fdc:	17048513          	addi	a0,s1,368
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	e52080e7          	jalr	-430(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	2c850513          	addi	a0,a0,712 # 800082b0 <digits+0x270>
    80001ff0:	00002097          	auipc	ra,0x2
    80001ff4:	122080e7          	jalr	290(ra) # 80004112 <namei>
    80001ff8:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001ffc:	478d                	li	a5,3
    80001ffe:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002000:	00007797          	auipc	a5,0x7
    80002004:	0507a783          	lw	a5,80(a5) # 80009050 <ticks>
    80002008:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    8000200a:	8526                	mv	a0,s1
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c8c080e7          	jalr	-884(ra) # 80000c98 <release>
}
    80002014:	60e2                	ld	ra,24(sp)
    80002016:	6442                	ld	s0,16(sp)
    80002018:	64a2                	ld	s1,8(sp)
    8000201a:	6105                	addi	sp,sp,32
    8000201c:	8082                	ret

000000008000201e <growproc>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	e04a                	sd	s2,0(sp)
    80002028:	1000                	addi	s0,sp,32
    8000202a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	c62080e7          	jalr	-926(ra) # 80001c8e <myproc>
    80002034:	892a                	mv	s2,a0
  sz = p->sz;
    80002036:	712c                	ld	a1,96(a0)
    80002038:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000203c:	00904f63          	bgtz	s1,8000205a <growproc+0x3c>
  } else if(n < 0){
    80002040:	0204cc63          	bltz	s1,80002078 <growproc+0x5a>
  p->sz = sz;
    80002044:	1602                	slli	a2,a2,0x20
    80002046:	9201                	srli	a2,a2,0x20
    80002048:	06c93023          	sd	a2,96(s2)
  return 0;
    8000204c:	4501                	li	a0,0
}
    8000204e:	60e2                	ld	ra,24(sp)
    80002050:	6442                	ld	s0,16(sp)
    80002052:	64a2                	ld	s1,8(sp)
    80002054:	6902                	ld	s2,0(sp)
    80002056:	6105                	addi	sp,sp,32
    80002058:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000205a:	9e25                	addw	a2,a2,s1
    8000205c:	1602                	slli	a2,a2,0x20
    8000205e:	9201                	srli	a2,a2,0x20
    80002060:	1582                	slli	a1,a1,0x20
    80002062:	9181                	srli	a1,a1,0x20
    80002064:	7528                	ld	a0,104(a0)
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	3bc080e7          	jalr	956(ra) # 80001422 <uvmalloc>
    8000206e:	0005061b          	sext.w	a2,a0
    80002072:	fa69                	bnez	a2,80002044 <growproc+0x26>
      return -1;
    80002074:	557d                	li	a0,-1
    80002076:	bfe1                	j	8000204e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002078:	9e25                	addw	a2,a2,s1
    8000207a:	1602                	slli	a2,a2,0x20
    8000207c:	9201                	srli	a2,a2,0x20
    8000207e:	1582                	slli	a1,a1,0x20
    80002080:	9181                	srli	a1,a1,0x20
    80002082:	7528                	ld	a0,104(a0)
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	356080e7          	jalr	854(ra) # 800013da <uvmdealloc>
    8000208c:	0005061b          	sext.w	a2,a0
    80002090:	bf55                	j	80002044 <growproc+0x26>

0000000080002092 <fork>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	e052                	sd	s4,0(sp)
    800020a0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	bec080e7          	jalr	-1044(ra) # 80001c8e <myproc>
    800020aa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	dec080e7          	jalr	-532(ra) # 80001e98 <allocproc>
    800020b4:	12050163          	beqz	a0,800021d6 <fork+0x144>
    800020b8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020ba:	06093603          	ld	a2,96(s2)
    800020be:	752c                	ld	a1,104(a0)
    800020c0:	06893503          	ld	a0,104(s2)
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	4aa080e7          	jalr	1194(ra) # 8000156e <uvmcopy>
    800020cc:	04054663          	bltz	a0,80002118 <fork+0x86>
  np->sz = p->sz;
    800020d0:	06093783          	ld	a5,96(s2)
    800020d4:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    800020d8:	07093683          	ld	a3,112(s2)
    800020dc:	87b6                	mv	a5,a3
    800020de:	0709b703          	ld	a4,112(s3)
    800020e2:	12068693          	addi	a3,a3,288
    800020e6:	0007b803          	ld	a6,0(a5)
    800020ea:	6788                	ld	a0,8(a5)
    800020ec:	6b8c                	ld	a1,16(a5)
    800020ee:	6f90                	ld	a2,24(a5)
    800020f0:	01073023          	sd	a6,0(a4)
    800020f4:	e708                	sd	a0,8(a4)
    800020f6:	eb0c                	sd	a1,16(a4)
    800020f8:	ef10                	sd	a2,24(a4)
    800020fa:	02078793          	addi	a5,a5,32
    800020fe:	02070713          	addi	a4,a4,32
    80002102:	fed792e3          	bne	a5,a3,800020e6 <fork+0x54>
  np->trapframe->a0 = 0;
    80002106:	0709b783          	ld	a5,112(s3)
    8000210a:	0607b823          	sd	zero,112(a5)
    8000210e:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    80002112:	16800a13          	li	s4,360
    80002116:	a03d                	j	80002144 <fork+0xb2>
    freeproc(np);
    80002118:	854e                	mv	a0,s3
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	d26080e7          	jalr	-730(ra) # 80001e40 <freeproc>
    release(&np->lock);
    80002122:	854e                	mv	a0,s3
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	b74080e7          	jalr	-1164(ra) # 80000c98 <release>
    return -1;
    8000212c:	5a7d                	li	s4,-1
    8000212e:	a859                	j	800021c4 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80002130:	00002097          	auipc	ra,0x2
    80002134:	678080e7          	jalr	1656(ra) # 800047a8 <filedup>
    80002138:	009987b3          	add	a5,s3,s1
    8000213c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000213e:	04a1                	addi	s1,s1,8
    80002140:	01448763          	beq	s1,s4,8000214e <fork+0xbc>
    if(p->ofile[i])
    80002144:	009907b3          	add	a5,s2,s1
    80002148:	6388                	ld	a0,0(a5)
    8000214a:	f17d                	bnez	a0,80002130 <fork+0x9e>
    8000214c:	bfcd                	j	8000213e <fork+0xac>
  np->cwd = idup(p->cwd);
    8000214e:	16893503          	ld	a0,360(s2)
    80002152:	00001097          	auipc	ra,0x1
    80002156:	7cc080e7          	jalr	1996(ra) # 8000391e <idup>
    8000215a:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000215e:	4641                	li	a2,16
    80002160:	17090593          	addi	a1,s2,368
    80002164:	17098513          	addi	a0,s3,368
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	cca080e7          	jalr	-822(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002170:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002174:	854e                	mv	a0,s3
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000217e:	0000f497          	auipc	s1,0xf
    80002182:	55a48493          	addi	s1,s1,1370 # 800116d8 <wait_lock>
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
  np->parent = p;
    80002190:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000219e:	854e                	mv	a0,s3
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	a44080e7          	jalr	-1468(ra) # 80000be4 <acquire>
  np->last_runnable_time = ticks;
    800021a8:	00007797          	auipc	a5,0x7
    800021ac:	ea87a783          	lw	a5,-344(a5) # 80009050 <ticks>
    800021b0:	02f9ae23          	sw	a5,60(s3)
  np->state = RUNNABLE;
    800021b4:	478d                	li	a5,3
    800021b6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021ba:	854e                	mv	a0,s3
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	adc080e7          	jalr	-1316(ra) # 80000c98 <release>
}
    800021c4:	8552                	mv	a0,s4
    800021c6:	70a2                	ld	ra,40(sp)
    800021c8:	7402                	ld	s0,32(sp)
    800021ca:	64e2                	ld	s1,24(sp)
    800021cc:	6942                	ld	s2,16(sp)
    800021ce:	69a2                	ld	s3,8(sp)
    800021d0:	6a02                	ld	s4,0(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret
    return -1;
    800021d6:	5a7d                	li	s4,-1
    800021d8:	b7f5                	j	800021c4 <fork+0x132>

00000000800021da <sched>:
{
    800021da:	7179                	addi	sp,sp,-48
    800021dc:	f406                	sd	ra,40(sp)
    800021de:	f022                	sd	s0,32(sp)
    800021e0:	ec26                	sd	s1,24(sp)
    800021e2:	e84a                	sd	s2,16(sp)
    800021e4:	e44e                	sd	s3,8(sp)
    800021e6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	aa6080e7          	jalr	-1370(ra) # 80001c8e <myproc>
    800021f0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	978080e7          	jalr	-1672(ra) # 80000b6a <holding>
    800021fa:	c53d                	beqz	a0,80002268 <sched+0x8e>
    800021fc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021fe:	2781                	sext.w	a5,a5
    80002200:	079e                	slli	a5,a5,0x7
    80002202:	0000f717          	auipc	a4,0xf
    80002206:	0be70713          	addi	a4,a4,190 # 800112c0 <cpus>
    8000220a:	97ba                	add	a5,a5,a4
    8000220c:	5fb8                	lw	a4,120(a5)
    8000220e:	4785                	li	a5,1
    80002210:	06f71463          	bne	a4,a5,80002278 <sched+0x9e>
  if(p->state == RUNNING)
    80002214:	4c98                	lw	a4,24(s1)
    80002216:	4791                	li	a5,4
    80002218:	06f70863          	beq	a4,a5,80002288 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000221c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002220:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002222:	ebbd                	bnez	a5,80002298 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002224:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002226:	0000f917          	auipc	s2,0xf
    8000222a:	09a90913          	addi	s2,s2,154 # 800112c0 <cpus>
    8000222e:	2781                	sext.w	a5,a5
    80002230:	079e                	slli	a5,a5,0x7
    80002232:	97ca                	add	a5,a5,s2
    80002234:	07c7a983          	lw	s3,124(a5)
    80002238:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000223a:	2581                	sext.w	a1,a1
    8000223c:	059e                	slli	a1,a1,0x7
    8000223e:	05a1                	addi	a1,a1,8
    80002240:	95ca                	add	a1,a1,s2
    80002242:	07848513          	addi	a0,s1,120
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	650080e7          	jalr	1616(ra) # 80002896 <swtch>
    8000224e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002250:	2781                	sext.w	a5,a5
    80002252:	079e                	slli	a5,a5,0x7
    80002254:	993e                	add	s2,s2,a5
    80002256:	07392e23          	sw	s3,124(s2)
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6145                	addi	sp,sp,48
    80002266:	8082                	ret
    panic("sched p->lock");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	05050513          	addi	a0,a0,80 # 800082b8 <digits+0x278>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>
    panic("sched locks");
    80002278:	00006517          	auipc	a0,0x6
    8000227c:	05050513          	addi	a0,a0,80 # 800082c8 <digits+0x288>
    80002280:	ffffe097          	auipc	ra,0xffffe
    80002284:	2be080e7          	jalr	702(ra) # 8000053e <panic>
    panic("sched running");
    80002288:	00006517          	auipc	a0,0x6
    8000228c:	05050513          	addi	a0,a0,80 # 800082d8 <digits+0x298>
    80002290:	ffffe097          	auipc	ra,0xffffe
    80002294:	2ae080e7          	jalr	686(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002298:	00006517          	auipc	a0,0x6
    8000229c:	05050513          	addi	a0,a0,80 # 800082e8 <digits+0x2a8>
    800022a0:	ffffe097          	auipc	ra,0xffffe
    800022a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>

00000000800022a8 <yield>:
{
    800022a8:	1101                	addi	sp,sp,-32
    800022aa:	ec06                	sd	ra,24(sp)
    800022ac:	e822                	sd	s0,16(sp)
    800022ae:	e426                	sd	s1,8(sp)
    800022b0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	9dc080e7          	jalr	-1572(ra) # 80001c8e <myproc>
    800022ba:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	928080e7          	jalr	-1752(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022c4:	478d                	li	a5,3
    800022c6:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800022c8:	00007797          	auipc	a5,0x7
    800022cc:	d887a783          	lw	a5,-632(a5) # 80009050 <ticks>
    800022d0:	dcdc                	sw	a5,60(s1)
  sched();
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	f08080e7          	jalr	-248(ra) # 800021da <sched>
  release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9bc080e7          	jalr	-1604(ra) # 80000c98 <release>
}
    800022e4:	60e2                	ld	ra,24(sp)
    800022e6:	6442                	ld	s0,16(sp)
    800022e8:	64a2                	ld	s1,8(sp)
    800022ea:	6105                	addi	sp,sp,32
    800022ec:	8082                	ret

00000000800022ee <pause_sys>:
{
    800022ee:	1141                	addi	sp,sp,-16
    800022f0:	e406                	sd	ra,8(sp)
    800022f2:	e022                	sd	s0,0(sp)
    800022f4:	0800                	addi	s0,sp,16
  finish =  ticks + secs*10;
    800022f6:	0025179b          	slliw	a5,a0,0x2
    800022fa:	9fa9                	addw	a5,a5,a0
    800022fc:	0017979b          	slliw	a5,a5,0x1
    80002300:	00007517          	auipc	a0,0x7
    80002304:	d5052503          	lw	a0,-688(a0) # 80009050 <ticks>
    80002308:	9fa9                	addw	a5,a5,a0
    8000230a:	00007717          	auipc	a4,0x7
    8000230e:	d2f72d23          	sw	a5,-710(a4) # 80009044 <finish>
  yield();
    80002312:	00000097          	auipc	ra,0x0
    80002316:	f96080e7          	jalr	-106(ra) # 800022a8 <yield>
}
    8000231a:	4501                	li	a0,0
    8000231c:	60a2                	ld	ra,8(sp)
    8000231e:	6402                	ld	s0,0(sp)
    80002320:	0141                	addi	sp,sp,16
    80002322:	8082                	ret

0000000080002324 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002324:	7179                	addi	sp,sp,-48
    80002326:	f406                	sd	ra,40(sp)
    80002328:	f022                	sd	s0,32(sp)
    8000232a:	ec26                	sd	s1,24(sp)
    8000232c:	e84a                	sd	s2,16(sp)
    8000232e:	e44e                	sd	s3,8(sp)
    80002330:	e052                	sd	s4,0(sp)
    80002332:	1800                	addi	s0,sp,48
    80002334:	89aa                	mv	s3,a0
    80002336:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	956080e7          	jalr	-1706(ra) # 80001c8e <myproc>
    80002340:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
  release(lk);
    8000234a:	854a                	mv	a0,s2
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002354:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002358:	4789                	li	a5,2
    8000235a:	cc9c                	sw	a5,24(s1)
  int sleep_start = ticks;
    8000235c:	00007997          	auipc	s3,0x7
    80002360:	cf498993          	addi	s3,s3,-780 # 80009050 <ticks>
    80002364:	0009aa03          	lw	s4,0(s3)
  sched();
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	e72080e7          	jalr	-398(ra) # 800021da <sched>
  p->sleeping_time = ticks - sleep_start;
    80002370:	0009a783          	lw	a5,0(s3)
    80002374:	414787bb          	subw	a5,a5,s4
    80002378:	c0bc                	sw	a5,64(s1)
  // Tidy up.
  p->chan = 0;
    8000237a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
  acquire(lk);
    80002388:	854a                	mv	a0,s2
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	85a080e7          	jalr	-1958(ra) # 80000be4 <acquire>
}
    80002392:	70a2                	ld	ra,40(sp)
    80002394:	7402                	ld	s0,32(sp)
    80002396:	64e2                	ld	s1,24(sp)
    80002398:	6942                	ld	s2,16(sp)
    8000239a:	69a2                	ld	s3,8(sp)
    8000239c:	6a02                	ld	s4,0(sp)
    8000239e:	6145                	addi	sp,sp,48
    800023a0:	8082                	ret

00000000800023a2 <wait>:
{
    800023a2:	715d                	addi	sp,sp,-80
    800023a4:	e486                	sd	ra,72(sp)
    800023a6:	e0a2                	sd	s0,64(sp)
    800023a8:	fc26                	sd	s1,56(sp)
    800023aa:	f84a                	sd	s2,48(sp)
    800023ac:	f44e                	sd	s3,40(sp)
    800023ae:	f052                	sd	s4,32(sp)
    800023b0:	ec56                	sd	s5,24(sp)
    800023b2:	e85a                	sd	s6,16(sp)
    800023b4:	e45e                	sd	s7,8(sp)
    800023b6:	e062                	sd	s8,0(sp)
    800023b8:	0880                	addi	s0,sp,80
    800023ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	8d2080e7          	jalr	-1838(ra) # 80001c8e <myproc>
    800023c4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023c6:	0000f517          	auipc	a0,0xf
    800023ca:	31250513          	addi	a0,a0,786 # 800116d8 <wait_lock>
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
    havekids = 0;
    800023d6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023d8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023da:	00015997          	auipc	s3,0x15
    800023de:	31698993          	addi	s3,s3,790 # 800176f0 <tickslock>
        havekids = 1;
    800023e2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e4:	0000fc17          	auipc	s8,0xf
    800023e8:	2f4c0c13          	addi	s8,s8,756 # 800116d8 <wait_lock>
    havekids = 0;
    800023ec:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	30248493          	addi	s1,s1,770 # 800116f0 <proc>
    800023f6:	a0bd                	j	80002464 <wait+0xc2>
          pid = np->pid;
    800023f8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023fc:	000b0e63          	beqz	s6,80002418 <wait+0x76>
    80002400:	4691                	li	a3,4
    80002402:	02c48613          	addi	a2,s1,44
    80002406:	85da                	mv	a1,s6
    80002408:	06893503          	ld	a0,104(s2)
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	266080e7          	jalr	614(ra) # 80001672 <copyout>
    80002414:	02054563          	bltz	a0,8000243e <wait+0x9c>
          freeproc(np);
    80002418:	8526                	mv	a0,s1
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	a26080e7          	jalr	-1498(ra) # 80001e40 <freeproc>
          release(&np->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
          release(&wait_lock);
    8000242c:	0000f517          	auipc	a0,0xf
    80002430:	2ac50513          	addi	a0,a0,684 # 800116d8 <wait_lock>
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	864080e7          	jalr	-1948(ra) # 80000c98 <release>
          return pid;
    8000243c:	a09d                	j	800024a2 <wait+0x100>
            release(&np->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
            release(&wait_lock);
    80002448:	0000f517          	auipc	a0,0xf
    8000244c:	29050513          	addi	a0,a0,656 # 800116d8 <wait_lock>
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	848080e7          	jalr	-1976(ra) # 80000c98 <release>
            return -1;
    80002458:	59fd                	li	s3,-1
    8000245a:	a0a1                	j	800024a2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000245c:	18048493          	addi	s1,s1,384
    80002460:	03348463          	beq	s1,s3,80002488 <wait+0xe6>
      if(np->parent == p){
    80002464:	68bc                	ld	a5,80(s1)
    80002466:	ff279be3          	bne	a5,s2,8000245c <wait+0xba>
        acquire(&np->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002474:	4c9c                	lw	a5,24(s1)
    80002476:	f94781e3          	beq	a5,s4,800023f8 <wait+0x56>
        release(&np->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
        havekids = 1;
    80002484:	8756                	mv	a4,s5
    80002486:	bfd9                	j	8000245c <wait+0xba>
    if(!havekids || p->killed){
    80002488:	c701                	beqz	a4,80002490 <wait+0xee>
    8000248a:	02892783          	lw	a5,40(s2)
    8000248e:	c79d                	beqz	a5,800024bc <wait+0x11a>
      release(&wait_lock);
    80002490:	0000f517          	auipc	a0,0xf
    80002494:	24850513          	addi	a0,a0,584 # 800116d8 <wait_lock>
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
      return -1;
    800024a0:	59fd                	li	s3,-1
}
    800024a2:	854e                	mv	a0,s3
    800024a4:	60a6                	ld	ra,72(sp)
    800024a6:	6406                	ld	s0,64(sp)
    800024a8:	74e2                	ld	s1,56(sp)
    800024aa:	7942                	ld	s2,48(sp)
    800024ac:	79a2                	ld	s3,40(sp)
    800024ae:	7a02                	ld	s4,32(sp)
    800024b0:	6ae2                	ld	s5,24(sp)
    800024b2:	6b42                	ld	s6,16(sp)
    800024b4:	6ba2                	ld	s7,8(sp)
    800024b6:	6c02                	ld	s8,0(sp)
    800024b8:	6161                	addi	sp,sp,80
    800024ba:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024bc:	85e2                	mv	a1,s8
    800024be:	854a                	mv	a0,s2
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	e64080e7          	jalr	-412(ra) # 80002324 <sleep>
    havekids = 0;
    800024c8:	b715                	j	800023ec <wait+0x4a>

00000000800024ca <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024ca:	7139                	addi	sp,sp,-64
    800024cc:	fc06                	sd	ra,56(sp)
    800024ce:	f822                	sd	s0,48(sp)
    800024d0:	f426                	sd	s1,40(sp)
    800024d2:	f04a                	sd	s2,32(sp)
    800024d4:	ec4e                	sd	s3,24(sp)
    800024d6:	e852                	sd	s4,16(sp)
    800024d8:	e456                	sd	s5,8(sp)
    800024da:	e05a                	sd	s6,0(sp)
    800024dc:	0080                	addi	s0,sp,64
    800024de:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024e0:	0000f497          	auipc	s1,0xf
    800024e4:	21048493          	addi	s1,s1,528 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024e8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024ea:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800024ec:	00007a97          	auipc	s5,0x7
    800024f0:	b64a8a93          	addi	s5,s5,-1180 # 80009050 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024f4:	00015917          	auipc	s2,0x15
    800024f8:	1fc90913          	addi	s2,s2,508 # 800176f0 <tickslock>
    800024fc:	a839                	j	8000251a <wakeup+0x50>
        p->state = RUNNABLE;
    800024fe:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002502:	000aa783          	lw	a5,0(s5)
    80002506:	dcdc                	sw	a5,60(s1)

      }
      release(&p->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	78e080e7          	jalr	1934(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002512:	18048493          	addi	s1,s1,384
    80002516:	03248463          	beq	s1,s2,8000253e <wakeup+0x74>
    if(p != myproc()){
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	774080e7          	jalr	1908(ra) # 80001c8e <myproc>
    80002522:	fea488e3          	beq	s1,a0,80002512 <wakeup+0x48>
      acquire(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002530:	4c9c                	lw	a5,24(s1)
    80002532:	fd379be3          	bne	a5,s3,80002508 <wakeup+0x3e>
    80002536:	709c                	ld	a5,32(s1)
    80002538:	fd4798e3          	bne	a5,s4,80002508 <wakeup+0x3e>
    8000253c:	b7c9                	j	800024fe <wakeup+0x34>
    }
  }
}
    8000253e:	70e2                	ld	ra,56(sp)
    80002540:	7442                	ld	s0,48(sp)
    80002542:	74a2                	ld	s1,40(sp)
    80002544:	7902                	ld	s2,32(sp)
    80002546:	69e2                	ld	s3,24(sp)
    80002548:	6a42                	ld	s4,16(sp)
    8000254a:	6aa2                	ld	s5,8(sp)
    8000254c:	6b02                	ld	s6,0(sp)
    8000254e:	6121                	addi	sp,sp,64
    80002550:	8082                	ret

0000000080002552 <reparent>:
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	e052                	sd	s4,0(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002564:	0000f497          	auipc	s1,0xf
    80002568:	18c48493          	addi	s1,s1,396 # 800116f0 <proc>
      pp->parent = initproc;
    8000256c:	00007a17          	auipc	s4,0x7
    80002570:	adca0a13          	addi	s4,s4,-1316 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002574:	00015997          	auipc	s3,0x15
    80002578:	17c98993          	addi	s3,s3,380 # 800176f0 <tickslock>
    8000257c:	a029                	j	80002586 <reparent+0x34>
    8000257e:	18048493          	addi	s1,s1,384
    80002582:	01348d63          	beq	s1,s3,8000259c <reparent+0x4a>
    if(pp->parent == p){
    80002586:	68bc                	ld	a5,80(s1)
    80002588:	ff279be3          	bne	a5,s2,8000257e <reparent+0x2c>
      pp->parent = initproc;
    8000258c:	000a3503          	ld	a0,0(s4)
    80002590:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002592:	00000097          	auipc	ra,0x0
    80002596:	f38080e7          	jalr	-200(ra) # 800024ca <wakeup>
    8000259a:	b7d5                	j	8000257e <reparent+0x2c>
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6a02                	ld	s4,0(sp)
    800025a8:	6145                	addi	sp,sp,48
    800025aa:	8082                	ret

00000000800025ac <exit>:
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	6d0080e7          	jalr	1744(ra) # 80001c8e <myproc>
    800025c6:	892a                	mv	s2,a0
  if(p == initproc)
    800025c8:	00007797          	auipc	a5,0x7
    800025cc:	a807b783          	ld	a5,-1408(a5) # 80009048 <initproc>
    800025d0:	0e850493          	addi	s1,a0,232
    800025d4:	16850993          	addi	s3,a0,360
    800025d8:	02a79363          	bne	a5,a0,800025fe <exit+0x52>
    panic("init exiting");
    800025dc:	00006517          	auipc	a0,0x6
    800025e0:	d2450513          	addi	a0,a0,-732 # 80008300 <digits+0x2c0>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
      fileclose(f);
    800025ec:	00002097          	auipc	ra,0x2
    800025f0:	20e080e7          	jalr	526(ra) # 800047fa <fileclose>
      p->ofile[fd] = 0;
    800025f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025f8:	04a1                	addi	s1,s1,8
    800025fa:	01348563          	beq	s1,s3,80002604 <exit+0x58>
    if(p->ofile[fd]){
    800025fe:	6088                	ld	a0,0(s1)
    80002600:	f575                	bnez	a0,800025ec <exit+0x40>
    80002602:	bfdd                	j	800025f8 <exit+0x4c>
  begin_op();
    80002604:	00002097          	auipc	ra,0x2
    80002608:	d2a080e7          	jalr	-726(ra) # 8000432e <begin_op>
  iput(p->cwd);
    8000260c:	16893503          	ld	a0,360(s2)
    80002610:	00001097          	auipc	ra,0x1
    80002614:	506080e7          	jalr	1286(ra) # 80003b16 <iput>
  end_op();
    80002618:	00002097          	auipc	ra,0x2
    8000261c:	d96080e7          	jalr	-618(ra) # 800043ae <end_op>
  p->cwd = 0;
    80002620:	16093423          	sd	zero,360(s2)
  acquire(&wait_lock);
    80002624:	0000f517          	auipc	a0,0xf
    80002628:	0b450513          	addi	a0,a0,180 # 800116d8 <wait_lock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/exited+1;
    80002634:	00007797          	auipc	a5,0x7
    80002638:	a007a783          	lw	a5,-1536(a5) # 80009034 <exited>
    8000263c:	00007697          	auipc	a3,0x7
    80002640:	a0468693          	addi	a3,a3,-1532 # 80009040 <sleeping_processes_mean>
    80002644:	4298                	lw	a4,0(a3)
    80002646:	02f7073b          	mulw	a4,a4,a5
    8000264a:	04092603          	lw	a2,64(s2)
    8000264e:	9f31                	addw	a4,a4,a2
    80002650:	02f7473b          	divw	a4,a4,a5
    80002654:	2705                	addiw	a4,a4,1
    80002656:	c298                	sw	a4,0(a3)
  running_processes_mean = ((running_processes_mean*exited) + p->running_time)/exited+1;
    80002658:	04892603          	lw	a2,72(s2)
    8000265c:	00007697          	auipc	a3,0x7
    80002660:	9e068693          	addi	a3,a3,-1568 # 8000903c <running_processes_mean>
    80002664:	4298                	lw	a4,0(a3)
    80002666:	02f7073b          	mulw	a4,a4,a5
    8000266a:	9f31                	addw	a4,a4,a2
    8000266c:	02f7473b          	divw	a4,a4,a5
    80002670:	2705                	addiw	a4,a4,1
    80002672:	c298                	sw	a4,0(a3)
  runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/exited+1;
    80002674:	00007697          	auipc	a3,0x7
    80002678:	9c468693          	addi	a3,a3,-1596 # 80009038 <runnable_processes_mean>
    8000267c:	4298                	lw	a4,0(a3)
    8000267e:	02f7073b          	mulw	a4,a4,a5
    80002682:	04492583          	lw	a1,68(s2)
    80002686:	9f2d                	addw	a4,a4,a1
    80002688:	02f7473b          	divw	a4,a4,a5
    8000268c:	2705                	addiw	a4,a4,1
    8000268e:	c298                	sw	a4,0(a3)
  if((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)){
    80002690:	03092703          	lw	a4,48(s2)
    80002694:	0000f697          	auipc	a3,0xf
    80002698:	08c6a683          	lw	a3,140(a3) # 80011720 <proc+0x30>
    8000269c:	04e68263          	beq	a3,a4,800026e0 <exit+0x134>
    800026a0:	0000f697          	auipc	a3,0xf
    800026a4:	2006a683          	lw	a3,512(a3) # 800118a0 <proc+0x1b0>
    800026a8:	02e68c63          	beq	a3,a4,800026e0 <exit+0x134>
    program_time = program_time + p->running_time;
    800026ac:	00007697          	auipc	a3,0x7
    800026b0:	98068693          	addi	a3,a3,-1664 # 8000902c <program_time>
    800026b4:	4298                	lw	a4,0(a3)
    800026b6:	9e39                	addw	a2,a2,a4
    800026b8:	c290                	sw	a2,0(a3)
    cpu_utilization = (100*program_time)/(ticks-start_time);
    800026ba:	06400713          	li	a4,100
    800026be:	02c7073b          	mulw	a4,a4,a2
    800026c2:	00007697          	auipc	a3,0x7
    800026c6:	98e6a683          	lw	a3,-1650(a3) # 80009050 <ticks>
    800026ca:	00007617          	auipc	a2,0x7
    800026ce:	96662603          	lw	a2,-1690(a2) # 80009030 <start_time>
    800026d2:	9e91                	subw	a3,a3,a2
    800026d4:	02d7573b          	divuw	a4,a4,a3
    800026d8:	00007697          	auipc	a3,0x7
    800026dc:	94e6a823          	sw	a4,-1712(a3) # 80009028 <cpu_utilization>
  exited = exited + 1;
    800026e0:	2785                	addiw	a5,a5,1
    800026e2:	00007717          	auipc	a4,0x7
    800026e6:	94f72923          	sw	a5,-1710(a4) # 80009034 <exited>
  reparent(p);
    800026ea:	854a                	mv	a0,s2
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	e66080e7          	jalr	-410(ra) # 80002552 <reparent>
  wakeup(p->parent);
    800026f4:	05093503          	ld	a0,80(s2)
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	dd2080e7          	jalr	-558(ra) # 800024ca <wakeup>
  acquire(&p->lock);
    80002700:	854a                	mv	a0,s2
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000270a:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000270e:	4795                	li	a5,5
    80002710:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002714:	0000f517          	auipc	a0,0xf
    80002718:	fc450513          	addi	a0,a0,-60 # 800116d8 <wait_lock>
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	57c080e7          	jalr	1404(ra) # 80000c98 <release>
  sched();
    80002724:	00000097          	auipc	ra,0x0
    80002728:	ab6080e7          	jalr	-1354(ra) # 800021da <sched>
  panic("zombie exit");
    8000272c:	00006517          	auipc	a0,0x6
    80002730:	be450513          	addi	a0,a0,-1052 # 80008310 <digits+0x2d0>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>

000000008000273c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000273c:	7179                	addi	sp,sp,-48
    8000273e:	f406                	sd	ra,40(sp)
    80002740:	f022                	sd	s0,32(sp)
    80002742:	ec26                	sd	s1,24(sp)
    80002744:	e84a                	sd	s2,16(sp)
    80002746:	e44e                	sd	s3,8(sp)
    80002748:	e052                	sd	s4,0(sp)
    8000274a:	1800                	addi	s0,sp,48
    8000274c:	84aa                	mv	s1,a0
    8000274e:	892e                	mv	s2,a1
    80002750:	89b2                	mv	s3,a2
    80002752:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	53a080e7          	jalr	1338(ra) # 80001c8e <myproc>
  if(user_dst){
    8000275c:	c08d                	beqz	s1,8000277e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000275e:	86d2                	mv	a3,s4
    80002760:	864e                	mv	a2,s3
    80002762:	85ca                	mv	a1,s2
    80002764:	7528                	ld	a0,104(a0)
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	f0c080e7          	jalr	-244(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000276e:	70a2                	ld	ra,40(sp)
    80002770:	7402                	ld	s0,32(sp)
    80002772:	64e2                	ld	s1,24(sp)
    80002774:	6942                	ld	s2,16(sp)
    80002776:	69a2                	ld	s3,8(sp)
    80002778:	6a02                	ld	s4,0(sp)
    8000277a:	6145                	addi	sp,sp,48
    8000277c:	8082                	ret
    memmove((char *)dst, src, len);
    8000277e:	000a061b          	sext.w	a2,s4
    80002782:	85ce                	mv	a1,s3
    80002784:	854a                	mv	a0,s2
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	5ba080e7          	jalr	1466(ra) # 80000d40 <memmove>
    return 0;
    8000278e:	8526                	mv	a0,s1
    80002790:	bff9                	j	8000276e <either_copyout+0x32>

0000000080002792 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002792:	7179                	addi	sp,sp,-48
    80002794:	f406                	sd	ra,40(sp)
    80002796:	f022                	sd	s0,32(sp)
    80002798:	ec26                	sd	s1,24(sp)
    8000279a:	e84a                	sd	s2,16(sp)
    8000279c:	e44e                	sd	s3,8(sp)
    8000279e:	e052                	sd	s4,0(sp)
    800027a0:	1800                	addi	s0,sp,48
    800027a2:	892a                	mv	s2,a0
    800027a4:	84ae                	mv	s1,a1
    800027a6:	89b2                	mv	s3,a2
    800027a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	4e4080e7          	jalr	1252(ra) # 80001c8e <myproc>
  if(user_src){
    800027b2:	c08d                	beqz	s1,800027d4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027b4:	86d2                	mv	a3,s4
    800027b6:	864e                	mv	a2,s3
    800027b8:	85ca                	mv	a1,s2
    800027ba:	7528                	ld	a0,104(a0)
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	f42080e7          	jalr	-190(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027c4:	70a2                	ld	ra,40(sp)
    800027c6:	7402                	ld	s0,32(sp)
    800027c8:	64e2                	ld	s1,24(sp)
    800027ca:	6942                	ld	s2,16(sp)
    800027cc:	69a2                	ld	s3,8(sp)
    800027ce:	6a02                	ld	s4,0(sp)
    800027d0:	6145                	addi	sp,sp,48
    800027d2:	8082                	ret
    memmove(dst, (char*)src, len);
    800027d4:	000a061b          	sext.w	a2,s4
    800027d8:	85ce                	mv	a1,s3
    800027da:	854a                	mv	a0,s2
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	564080e7          	jalr	1380(ra) # 80000d40 <memmove>
    return 0;
    800027e4:	8526                	mv	a0,s1
    800027e6:	bff9                	j	800027c4 <either_copyin+0x32>

00000000800027e8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027e8:	715d                	addi	sp,sp,-80
    800027ea:	e486                	sd	ra,72(sp)
    800027ec:	e0a2                	sd	s0,64(sp)
    800027ee:	fc26                	sd	s1,56(sp)
    800027f0:	f84a                	sd	s2,48(sp)
    800027f2:	f44e                	sd	s3,40(sp)
    800027f4:	f052                	sd	s4,32(sp)
    800027f6:	ec56                	sd	s5,24(sp)
    800027f8:	e85a                	sd	s6,16(sp)
    800027fa:	e45e                	sd	s7,8(sp)
    800027fc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	a0a50513          	addi	a0,a0,-1526 # 80008208 <digits+0x1c8>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	d82080e7          	jalr	-638(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000280e:	0000f497          	auipc	s1,0xf
    80002812:	05248493          	addi	s1,s1,82 # 80011860 <proc+0x170>
    80002816:	00015917          	auipc	s2,0x15
    8000281a:	04a90913          	addi	s2,s2,74 # 80017860 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002820:	00006997          	auipc	s3,0x6
    80002824:	b0098993          	addi	s3,s3,-1280 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    80002828:	00006a97          	auipc	s5,0x6
    8000282c:	b00a8a93          	addi	s5,s5,-1280 # 80008328 <digits+0x2e8>
    printf("\n");
    80002830:	00006a17          	auipc	s4,0x6
    80002834:	9d8a0a13          	addi	s4,s4,-1576 # 80008208 <digits+0x1c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002838:	00006b97          	auipc	s7,0x6
    8000283c:	b28b8b93          	addi	s7,s7,-1240 # 80008360 <states.1745>
    80002840:	a00d                	j	80002862 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002842:	ec06a583          	lw	a1,-320(a3)
    80002846:	8556                	mv	a0,s5
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d40080e7          	jalr	-704(ra) # 80000588 <printf>
    printf("\n");
    80002850:	8552                	mv	a0,s4
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	d36080e7          	jalr	-714(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000285a:	18048493          	addi	s1,s1,384
    8000285e:	03248163          	beq	s1,s2,80002880 <procdump+0x98>
    if(p->state == UNUSED)
    80002862:	86a6                	mv	a3,s1
    80002864:	ea84a783          	lw	a5,-344(s1)
    80002868:	dbed                	beqz	a5,8000285a <procdump+0x72>
      state = "???";
    8000286a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286c:	fcfb6be3          	bltu	s6,a5,80002842 <procdump+0x5a>
    80002870:	1782                	slli	a5,a5,0x20
    80002872:	9381                	srli	a5,a5,0x20
    80002874:	078e                	slli	a5,a5,0x3
    80002876:	97de                	add	a5,a5,s7
    80002878:	6390                	ld	a2,0(a5)
    8000287a:	f661                	bnez	a2,80002842 <procdump+0x5a>
      state = "???";
    8000287c:	864e                	mv	a2,s3
    8000287e:	b7d1                	j	80002842 <procdump+0x5a>
  }
}
    80002880:	60a6                	ld	ra,72(sp)
    80002882:	6406                	ld	s0,64(sp)
    80002884:	74e2                	ld	s1,56(sp)
    80002886:	7942                	ld	s2,48(sp)
    80002888:	79a2                	ld	s3,40(sp)
    8000288a:	7a02                	ld	s4,32(sp)
    8000288c:	6ae2                	ld	s5,24(sp)
    8000288e:	6b42                	ld	s6,16(sp)
    80002890:	6ba2                	ld	s7,8(sp)
    80002892:	6161                	addi	sp,sp,80
    80002894:	8082                	ret

0000000080002896 <swtch>:
    80002896:	00153023          	sd	ra,0(a0)
    8000289a:	00253423          	sd	sp,8(a0)
    8000289e:	e900                	sd	s0,16(a0)
    800028a0:	ed04                	sd	s1,24(a0)
    800028a2:	03253023          	sd	s2,32(a0)
    800028a6:	03353423          	sd	s3,40(a0)
    800028aa:	03453823          	sd	s4,48(a0)
    800028ae:	03553c23          	sd	s5,56(a0)
    800028b2:	05653023          	sd	s6,64(a0)
    800028b6:	05753423          	sd	s7,72(a0)
    800028ba:	05853823          	sd	s8,80(a0)
    800028be:	05953c23          	sd	s9,88(a0)
    800028c2:	07a53023          	sd	s10,96(a0)
    800028c6:	07b53423          	sd	s11,104(a0)
    800028ca:	0005b083          	ld	ra,0(a1)
    800028ce:	0085b103          	ld	sp,8(a1)
    800028d2:	6980                	ld	s0,16(a1)
    800028d4:	6d84                	ld	s1,24(a1)
    800028d6:	0205b903          	ld	s2,32(a1)
    800028da:	0285b983          	ld	s3,40(a1)
    800028de:	0305ba03          	ld	s4,48(a1)
    800028e2:	0385ba83          	ld	s5,56(a1)
    800028e6:	0405bb03          	ld	s6,64(a1)
    800028ea:	0485bb83          	ld	s7,72(a1)
    800028ee:	0505bc03          	ld	s8,80(a1)
    800028f2:	0585bc83          	ld	s9,88(a1)
    800028f6:	0605bd03          	ld	s10,96(a1)
    800028fa:	0685bd83          	ld	s11,104(a1)
    800028fe:	8082                	ret

0000000080002900 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002900:	1141                	addi	sp,sp,-16
    80002902:	e406                	sd	ra,8(sp)
    80002904:	e022                	sd	s0,0(sp)
    80002906:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002908:	00006597          	auipc	a1,0x6
    8000290c:	a8858593          	addi	a1,a1,-1400 # 80008390 <states.1745+0x30>
    80002910:	00015517          	auipc	a0,0x15
    80002914:	de050513          	addi	a0,a0,-544 # 800176f0 <tickslock>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
}
    80002920:	60a2                	ld	ra,8(sp)
    80002922:	6402                	ld	s0,0(sp)
    80002924:	0141                	addi	sp,sp,16
    80002926:	8082                	ret

0000000080002928 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002928:	1141                	addi	sp,sp,-16
    8000292a:	e422                	sd	s0,8(sp)
    8000292c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000292e:	00003797          	auipc	a5,0x3
    80002932:	4e278793          	addi	a5,a5,1250 # 80005e10 <kernelvec>
    80002936:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000293a:	6422                	ld	s0,8(sp)
    8000293c:	0141                	addi	sp,sp,16
    8000293e:	8082                	ret

0000000080002940 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002940:	1141                	addi	sp,sp,-16
    80002942:	e406                	sd	ra,8(sp)
    80002944:	e022                	sd	s0,0(sp)
    80002946:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	346080e7          	jalr	838(ra) # 80001c8e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002950:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002954:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002956:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000295a:	00004617          	auipc	a2,0x4
    8000295e:	6a660613          	addi	a2,a2,1702 # 80007000 <_trampoline>
    80002962:	00004697          	auipc	a3,0x4
    80002966:	69e68693          	addi	a3,a3,1694 # 80007000 <_trampoline>
    8000296a:	8e91                	sub	a3,a3,a2
    8000296c:	040007b7          	lui	a5,0x4000
    80002970:	17fd                	addi	a5,a5,-1
    80002972:	07b2                	slli	a5,a5,0xc
    80002974:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002976:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000297a:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000297c:	180026f3          	csrr	a3,satp
    80002980:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002982:	7938                	ld	a4,112(a0)
    80002984:	6d34                	ld	a3,88(a0)
    80002986:	6585                	lui	a1,0x1
    80002988:	96ae                	add	a3,a3,a1
    8000298a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000298c:	7938                	ld	a4,112(a0)
    8000298e:	00000697          	auipc	a3,0x0
    80002992:	13868693          	addi	a3,a3,312 # 80002ac6 <usertrap>
    80002996:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002998:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000299a:	8692                	mv	a3,tp
    8000299c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029a2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029a6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029aa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029ae:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b0:	6f18                	ld	a4,24(a4)
    800029b2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029b6:	752c                	ld	a1,104(a0)
    800029b8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029ba:	00004717          	auipc	a4,0x4
    800029be:	6d670713          	addi	a4,a4,1750 # 80007090 <userret>
    800029c2:	8f11                	sub	a4,a4,a2
    800029c4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029c6:	577d                	li	a4,-1
    800029c8:	177e                	slli	a4,a4,0x3f
    800029ca:	8dd9                	or	a1,a1,a4
    800029cc:	02000537          	lui	a0,0x2000
    800029d0:	157d                	addi	a0,a0,-1
    800029d2:	0536                	slli	a0,a0,0xd
    800029d4:	9782                	jalr	a5
}
    800029d6:	60a2                	ld	ra,8(sp)
    800029d8:	6402                	ld	s0,0(sp)
    800029da:	0141                	addi	sp,sp,16
    800029dc:	8082                	ret

00000000800029de <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029e8:	00015497          	auipc	s1,0x15
    800029ec:	d0848493          	addi	s1,s1,-760 # 800176f0 <tickslock>
    800029f0:	8526                	mv	a0,s1
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
  ticks++;
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	65650513          	addi	a0,a0,1622 # 80009050 <ticks>
    80002a02:	411c                	lw	a5,0(a0)
    80002a04:	2785                	addiw	a5,a5,1
    80002a06:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	ac2080e7          	jalr	-1342(ra) # 800024ca <wakeup>
  release(&tickslock);
    80002a10:	8526                	mv	a0,s1
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6105                	addi	sp,sp,32
    80002a22:	8082                	ret

0000000080002a24 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a24:	1101                	addi	sp,sp,-32
    80002a26:	ec06                	sd	ra,24(sp)
    80002a28:	e822                	sd	s0,16(sp)
    80002a2a:	e426                	sd	s1,8(sp)
    80002a2c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a32:	00074d63          	bltz	a4,80002a4c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a36:	57fd                	li	a5,-1
    80002a38:	17fe                	slli	a5,a5,0x3f
    80002a3a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a3c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a3e:	06f70363          	beq	a4,a5,80002aa4 <devintr+0x80>
  }
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
     (scause & 0xff) == 9){
    80002a4c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a50:	46a5                	li	a3,9
    80002a52:	fed792e3          	bne	a5,a3,80002a36 <devintr+0x12>
    int irq = plic_claim();
    80002a56:	00003097          	auipc	ra,0x3
    80002a5a:	4c2080e7          	jalr	1218(ra) # 80005f18 <plic_claim>
    80002a5e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a60:	47a9                	li	a5,10
    80002a62:	02f50763          	beq	a0,a5,80002a90 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a66:	4785                	li	a5,1
    80002a68:	02f50963          	beq	a0,a5,80002a9a <devintr+0x76>
    return 1;
    80002a6c:	4505                	li	a0,1
    } else if(irq){
    80002a6e:	d8f1                	beqz	s1,80002a42 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a70:	85a6                	mv	a1,s1
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	92650513          	addi	a0,a0,-1754 # 80008398 <states.1745+0x38>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	b0e080e7          	jalr	-1266(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a82:	8526                	mv	a0,s1
    80002a84:	00003097          	auipc	ra,0x3
    80002a88:	4b8080e7          	jalr	1208(ra) # 80005f3c <plic_complete>
    return 1;
    80002a8c:	4505                	li	a0,1
    80002a8e:	bf55                	j	80002a42 <devintr+0x1e>
      uartintr();
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	f18080e7          	jalr	-232(ra) # 800009a8 <uartintr>
    80002a98:	b7ed                	j	80002a82 <devintr+0x5e>
      virtio_disk_intr();
    80002a9a:	00004097          	auipc	ra,0x4
    80002a9e:	982080e7          	jalr	-1662(ra) # 8000641c <virtio_disk_intr>
    80002aa2:	b7c5                	j	80002a82 <devintr+0x5e>
    if(cpuid() == 0){
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	1be080e7          	jalr	446(ra) # 80001c62 <cpuid>
    80002aac:	c901                	beqz	a0,80002abc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002aae:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ab2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ab4:	14479073          	csrw	sip,a5
    return 2;
    80002ab8:	4509                	li	a0,2
    80002aba:	b761                	j	80002a42 <devintr+0x1e>
      clockintr();
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	f22080e7          	jalr	-222(ra) # 800029de <clockintr>
    80002ac4:	b7ed                	j	80002aae <devintr+0x8a>

0000000080002ac6 <usertrap>:
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	e04a                	sd	s2,0(sp)
    80002ad0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ad6:	1007f793          	andi	a5,a5,256
    80002ada:	e3ad                	bnez	a5,80002b3c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002adc:	00003797          	auipc	a5,0x3
    80002ae0:	33478793          	addi	a5,a5,820 # 80005e10 <kernelvec>
    80002ae4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	1a6080e7          	jalr	422(ra) # 80001c8e <myproc>
    80002af0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002af2:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af4:	14102773          	csrr	a4,sepc
    80002af8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002afe:	47a1                	li	a5,8
    80002b00:	04f71c63          	bne	a4,a5,80002b58 <usertrap+0x92>
    if(p->killed)
    80002b04:	551c                	lw	a5,40(a0)
    80002b06:	e3b9                	bnez	a5,80002b4c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b08:	78b8                	ld	a4,112(s1)
    80002b0a:	6f1c                	ld	a5,24(a4)
    80002b0c:	0791                	addi	a5,a5,4
    80002b0e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b18:	10079073          	csrw	sstatus,a5
    syscall();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	2e0080e7          	jalr	736(ra) # 80002dfc <syscall>
  if(p->killed)
    80002b24:	549c                	lw	a5,40(s1)
    80002b26:	ebc1                	bnez	a5,80002bb6 <usertrap+0xf0>
  usertrapret();
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	e18080e7          	jalr	-488(ra) # 80002940 <usertrapret>
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6902                	ld	s2,0(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	87c50513          	addi	a0,a0,-1924 # 800083b8 <states.1745+0x58>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
      exit(-1);
    80002b4c:	557d                	li	a0,-1
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	a5e080e7          	jalr	-1442(ra) # 800025ac <exit>
    80002b56:	bf4d                	j	80002b08 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	ecc080e7          	jalr	-308(ra) # 80002a24 <devintr>
    80002b60:	892a                	mv	s2,a0
    80002b62:	c501                	beqz	a0,80002b6a <usertrap+0xa4>
  if(p->killed)
    80002b64:	549c                	lw	a5,40(s1)
    80002b66:	c3a1                	beqz	a5,80002ba6 <usertrap+0xe0>
    80002b68:	a815                	j	80002b9c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b6e:	5890                	lw	a2,48(s1)
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	86850513          	addi	a0,a0,-1944 # 800083d8 <states.1745+0x78>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a10080e7          	jalr	-1520(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b84:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b88:	00006517          	auipc	a0,0x6
    80002b8c:	88050513          	addi	a0,a0,-1920 # 80008408 <states.1745+0xa8>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
    p->killed = 1;
    80002b98:	4785                	li	a5,1
    80002b9a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b9c:	557d                	li	a0,-1
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	a0e080e7          	jalr	-1522(ra) # 800025ac <exit>
  if(which_dev == 2)
    80002ba6:	4789                	li	a5,2
    80002ba8:	f8f910e3          	bne	s2,a5,80002b28 <usertrap+0x62>
    yield();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	6fc080e7          	jalr	1788(ra) # 800022a8 <yield>
    80002bb4:	bf95                	j	80002b28 <usertrap+0x62>
  int which_dev = 0;
    80002bb6:	4901                	li	s2,0
    80002bb8:	b7d5                	j	80002b9c <usertrap+0xd6>

0000000080002bba <kerneltrap>:
{
    80002bba:	7179                	addi	sp,sp,-48
    80002bbc:	f406                	sd	ra,40(sp)
    80002bbe:	f022                	sd	s0,32(sp)
    80002bc0:	ec26                	sd	s1,24(sp)
    80002bc2:	e84a                	sd	s2,16(sp)
    80002bc4:	e44e                	sd	s3,8(sp)
    80002bc6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bcc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bd4:	1004f793          	andi	a5,s1,256
    80002bd8:	cb85                	beqz	a5,80002c08 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bda:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bde:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be0:	ef85                	bnez	a5,80002c18 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	e42080e7          	jalr	-446(ra) # 80002a24 <devintr>
    80002bea:	cd1d                	beqz	a0,80002c28 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bec:	4789                	li	a5,2
    80002bee:	06f50a63          	beq	a0,a5,80002c62 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf6:	10049073          	csrw	sstatus,s1
}
    80002bfa:	70a2                	ld	ra,40(sp)
    80002bfc:	7402                	ld	s0,32(sp)
    80002bfe:	64e2                	ld	s1,24(sp)
    80002c00:	6942                	ld	s2,16(sp)
    80002c02:	69a2                	ld	s3,8(sp)
    80002c04:	6145                	addi	sp,sp,48
    80002c06:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	82050513          	addi	a0,a0,-2016 # 80008428 <states.1745+0xc8>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c18:	00006517          	auipc	a0,0x6
    80002c1c:	83850513          	addi	a0,a0,-1992 # 80008450 <states.1745+0xf0>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c28:	85ce                	mv	a1,s3
    80002c2a:	00006517          	auipc	a0,0x6
    80002c2e:	84650513          	addi	a0,a0,-1978 # 80008470 <states.1745+0x110>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	956080e7          	jalr	-1706(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c3e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c42:	00006517          	auipc	a0,0x6
    80002c46:	83e50513          	addi	a0,a0,-1986 # 80008480 <states.1745+0x120>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	93e080e7          	jalr	-1730(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c52:	00006517          	auipc	a0,0x6
    80002c56:	84650513          	addi	a0,a0,-1978 # 80008498 <states.1745+0x138>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	02c080e7          	jalr	44(ra) # 80001c8e <myproc>
    80002c6a:	d541                	beqz	a0,80002bf2 <kerneltrap+0x38>
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	022080e7          	jalr	34(ra) # 80001c8e <myproc>
    80002c74:	4d18                	lw	a4,24(a0)
    80002c76:	4791                	li	a5,4
    80002c78:	f6f71de3          	bne	a4,a5,80002bf2 <kerneltrap+0x38>
    yield();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	62c080e7          	jalr	1580(ra) # 800022a8 <yield>
    80002c84:	b7bd                	j	80002bf2 <kerneltrap+0x38>

0000000080002c86 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	e426                	sd	s1,8(sp)
    80002c8e:	1000                	addi	s0,sp,32
    80002c90:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	ffc080e7          	jalr	-4(ra) # 80001c8e <myproc>
  switch (n) {
    80002c9a:	4795                	li	a5,5
    80002c9c:	0497e163          	bltu	a5,s1,80002cde <argraw+0x58>
    80002ca0:	048a                	slli	s1,s1,0x2
    80002ca2:	00006717          	auipc	a4,0x6
    80002ca6:	82e70713          	addi	a4,a4,-2002 # 800084d0 <states.1745+0x170>
    80002caa:	94ba                	add	s1,s1,a4
    80002cac:	409c                	lw	a5,0(s1)
    80002cae:	97ba                	add	a5,a5,a4
    80002cb0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cb2:	793c                	ld	a5,112(a0)
    80002cb4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cb6:	60e2                	ld	ra,24(sp)
    80002cb8:	6442                	ld	s0,16(sp)
    80002cba:	64a2                	ld	s1,8(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret
    return p->trapframe->a1;
    80002cc0:	793c                	ld	a5,112(a0)
    80002cc2:	7fa8                	ld	a0,120(a5)
    80002cc4:	bfcd                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a2;
    80002cc6:	793c                	ld	a5,112(a0)
    80002cc8:	63c8                	ld	a0,128(a5)
    80002cca:	b7f5                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a3;
    80002ccc:	793c                	ld	a5,112(a0)
    80002cce:	67c8                	ld	a0,136(a5)
    80002cd0:	b7dd                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a4;
    80002cd2:	793c                	ld	a5,112(a0)
    80002cd4:	6bc8                	ld	a0,144(a5)
    80002cd6:	b7c5                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a5;
    80002cd8:	793c                	ld	a5,112(a0)
    80002cda:	6fc8                	ld	a0,152(a5)
    80002cdc:	bfe9                	j	80002cb6 <argraw+0x30>
  panic("argraw");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	7ca50513          	addi	a0,a0,1994 # 800084a8 <states.1745+0x148>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>

0000000080002cee <fetchaddr>:
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	e04a                	sd	s2,0(sp)
    80002cf8:	1000                	addi	s0,sp,32
    80002cfa:	84aa                	mv	s1,a0
    80002cfc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	f90080e7          	jalr	-112(ra) # 80001c8e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d06:	713c                	ld	a5,96(a0)
    80002d08:	02f4f863          	bgeu	s1,a5,80002d38 <fetchaddr+0x4a>
    80002d0c:	00848713          	addi	a4,s1,8
    80002d10:	02e7e663          	bltu	a5,a4,80002d3c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d14:	46a1                	li	a3,8
    80002d16:	8626                	mv	a2,s1
    80002d18:	85ca                	mv	a1,s2
    80002d1a:	7528                	ld	a0,104(a0)
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	9e2080e7          	jalr	-1566(ra) # 800016fe <copyin>
    80002d24:	00a03533          	snez	a0,a0
    80002d28:	40a00533          	neg	a0,a0
}
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6902                	ld	s2,0(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret
    return -1;
    80002d38:	557d                	li	a0,-1
    80002d3a:	bfcd                	j	80002d2c <fetchaddr+0x3e>
    80002d3c:	557d                	li	a0,-1
    80002d3e:	b7fd                	j	80002d2c <fetchaddr+0x3e>

0000000080002d40 <fetchstr>:
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	e84a                	sd	s2,16(sp)
    80002d4a:	e44e                	sd	s3,8(sp)
    80002d4c:	1800                	addi	s0,sp,48
    80002d4e:	892a                	mv	s2,a0
    80002d50:	84ae                	mv	s1,a1
    80002d52:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	f3a080e7          	jalr	-198(ra) # 80001c8e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d5c:	86ce                	mv	a3,s3
    80002d5e:	864a                	mv	a2,s2
    80002d60:	85a6                	mv	a1,s1
    80002d62:	7528                	ld	a0,104(a0)
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	a26080e7          	jalr	-1498(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d6c:	00054763          	bltz	a0,80002d7a <fetchstr+0x3a>
  return strlen(buf);
    80002d70:	8526                	mv	a0,s1
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	0f2080e7          	jalr	242(ra) # 80000e64 <strlen>
}
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6942                	ld	s2,16(sp)
    80002d82:	69a2                	ld	s3,8(sp)
    80002d84:	6145                	addi	sp,sp,48
    80002d86:	8082                	ret

0000000080002d88 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	1000                	addi	s0,sp,32
    80002d92:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	ef2080e7          	jalr	-270(ra) # 80002c86 <argraw>
    80002d9c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d9e:	4501                	li	a0,0
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	e426                	sd	s1,8(sp)
    80002db2:	1000                	addi	s0,sp,32
    80002db4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	ed0080e7          	jalr	-304(ra) # 80002c86 <argraw>
    80002dbe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc0:	4501                	li	a0,0
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	e04a                	sd	s2,0(sp)
    80002dd6:	1000                	addi	s0,sp,32
    80002dd8:	84ae                	mv	s1,a1
    80002dda:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	eaa080e7          	jalr	-342(ra) # 80002c86 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002de4:	864a                	mv	a2,s2
    80002de6:	85a6                	mv	a1,s1
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	f58080e7          	jalr	-168(ra) # 80002d40 <fetchstr>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6902                	ld	s2,0(sp)
    80002df8:	6105                	addi	sp,sp,32
    80002dfa:	8082                	ret

0000000080002dfc <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	e426                	sd	s1,8(sp)
    80002e04:	e04a                	sd	s2,0(sp)
    80002e06:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	e86080e7          	jalr	-378(ra) # 80001c8e <myproc>
    80002e10:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e12:	07053903          	ld	s2,112(a0)
    80002e16:	0a893783          	ld	a5,168(s2)
    80002e1a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e1e:	37fd                	addiw	a5,a5,-1
    80002e20:	475d                	li	a4,23
    80002e22:	00f76f63          	bltu	a4,a5,80002e40 <syscall+0x44>
    80002e26:	00369713          	slli	a4,a3,0x3
    80002e2a:	00005797          	auipc	a5,0x5
    80002e2e:	6be78793          	addi	a5,a5,1726 # 800084e8 <syscalls>
    80002e32:	97ba                	add	a5,a5,a4
    80002e34:	639c                	ld	a5,0(a5)
    80002e36:	c789                	beqz	a5,80002e40 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e38:	9782                	jalr	a5
    80002e3a:	06a93823          	sd	a0,112(s2)
    80002e3e:	a839                	j	80002e5c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e40:	17048613          	addi	a2,s1,368
    80002e44:	588c                	lw	a1,48(s1)
    80002e46:	00005517          	auipc	a0,0x5
    80002e4a:	66a50513          	addi	a0,a0,1642 # 800084b0 <states.1745+0x150>
    80002e4e:	ffffd097          	auipc	ra,0xffffd
    80002e52:	73a080e7          	jalr	1850(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e56:	78bc                	ld	a5,112(s1)
    80002e58:	577d                	li	a4,-1
    80002e5a:	fbb8                	sd	a4,112(a5)
  }
}
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	64a2                	ld	s1,8(sp)
    80002e62:	6902                	ld	s2,0(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e70:	fec40593          	addi	a1,s0,-20
    80002e74:	4501                	li	a0,0
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	f12080e7          	jalr	-238(ra) # 80002d88 <argint>
    return -1;
    80002e7e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e80:	00054963          	bltz	a0,80002e92 <sys_exit+0x2a>
  exit(n);
    80002e84:	fec42503          	lw	a0,-20(s0)
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	724080e7          	jalr	1828(ra) # 800025ac <exit>
  return 0;  // not reached
    80002e90:	4781                	li	a5,0
}
    80002e92:	853e                	mv	a0,a5
    80002e94:	60e2                	ld	ra,24(sp)
    80002e96:	6442                	ld	s0,16(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e9c:	1141                	addi	sp,sp,-16
    80002e9e:	e406                	sd	ra,8(sp)
    80002ea0:	e022                	sd	s0,0(sp)
    80002ea2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	dea080e7          	jalr	-534(ra) # 80001c8e <myproc>
}
    80002eac:	5908                	lw	a0,48(a0)
    80002eae:	60a2                	ld	ra,8(sp)
    80002eb0:	6402                	ld	s0,0(sp)
    80002eb2:	0141                	addi	sp,sp,16
    80002eb4:	8082                	ret

0000000080002eb6 <sys_fork>:

uint64
sys_fork(void)
{
    80002eb6:	1141                	addi	sp,sp,-16
    80002eb8:	e406                	sd	ra,8(sp)
    80002eba:	e022                	sd	s0,0(sp)
    80002ebc:	0800                	addi	s0,sp,16
  return fork();
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	1d4080e7          	jalr	468(ra) # 80002092 <fork>
}
    80002ec6:	60a2                	ld	ra,8(sp)
    80002ec8:	6402                	ld	s0,0(sp)
    80002eca:	0141                	addi	sp,sp,16
    80002ecc:	8082                	ret

0000000080002ece <sys_wait>:

uint64
sys_wait(void)
{
    80002ece:	1101                	addi	sp,sp,-32
    80002ed0:	ec06                	sd	ra,24(sp)
    80002ed2:	e822                	sd	s0,16(sp)
    80002ed4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ed6:	fe840593          	addi	a1,s0,-24
    80002eda:	4501                	li	a0,0
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	ece080e7          	jalr	-306(ra) # 80002daa <argaddr>
    80002ee4:	87aa                	mv	a5,a0
    return -1;
    80002ee6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ee8:	0007c863          	bltz	a5,80002ef8 <sys_wait+0x2a>
  return wait(p);
    80002eec:	fe843503          	ld	a0,-24(s0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	4b2080e7          	jalr	1202(ra) # 800023a2 <wait>
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	6105                	addi	sp,sp,32
    80002efe:	8082                	ret

0000000080002f00 <sys_print_stats>:

void
sys_print_stats(void)
{
    80002f00:	1141                	addi	sp,sp,-16
    80002f02:	e406                	sd	ra,8(sp)
    80002f04:	e022                	sd	s0,0(sp)
    80002f06:	0800                	addi	s0,sp,16
  return print_stats();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	adc080e7          	jalr	-1316(ra) # 800019e4 <print_stats>
}
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	addi	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f18:	7179                	addi	sp,sp,-48
    80002f1a:	f406                	sd	ra,40(sp)
    80002f1c:	f022                	sd	s0,32(sp)
    80002f1e:	ec26                	sd	s1,24(sp)
    80002f20:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f22:	fdc40593          	addi	a1,s0,-36
    80002f26:	4501                	li	a0,0
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	e60080e7          	jalr	-416(ra) # 80002d88 <argint>
    80002f30:	87aa                	mv	a5,a0
    return -1;
    80002f32:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f34:	0207c063          	bltz	a5,80002f54 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	d56080e7          	jalr	-682(ra) # 80001c8e <myproc>
    80002f40:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80002f42:	fdc42503          	lw	a0,-36(s0)
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	0d8080e7          	jalr	216(ra) # 8000201e <growproc>
    80002f4e:	00054863          	bltz	a0,80002f5e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f52:	8526                	mv	a0,s1
}
    80002f54:	70a2                	ld	ra,40(sp)
    80002f56:	7402                	ld	s0,32(sp)
    80002f58:	64e2                	ld	s1,24(sp)
    80002f5a:	6145                	addi	sp,sp,48
    80002f5c:	8082                	ret
    return -1;
    80002f5e:	557d                	li	a0,-1
    80002f60:	bfd5                	j	80002f54 <sys_sbrk+0x3c>

0000000080002f62 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f62:	7139                	addi	sp,sp,-64
    80002f64:	fc06                	sd	ra,56(sp)
    80002f66:	f822                	sd	s0,48(sp)
    80002f68:	f426                	sd	s1,40(sp)
    80002f6a:	f04a                	sd	s2,32(sp)
    80002f6c:	ec4e                	sd	s3,24(sp)
    80002f6e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f70:	fcc40593          	addi	a1,s0,-52
    80002f74:	4501                	li	a0,0
    80002f76:	00000097          	auipc	ra,0x0
    80002f7a:	e12080e7          	jalr	-494(ra) # 80002d88 <argint>
    return -1;
    80002f7e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f80:	06054563          	bltz	a0,80002fea <sys_sleep+0x88>
  acquire(&tickslock);
    80002f84:	00014517          	auipc	a0,0x14
    80002f88:	76c50513          	addi	a0,a0,1900 # 800176f0 <tickslock>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	c58080e7          	jalr	-936(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f94:	00006917          	auipc	s2,0x6
    80002f98:	0bc92903          	lw	s2,188(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002f9c:	fcc42783          	lw	a5,-52(s0)
    80002fa0:	cf85                	beqz	a5,80002fd8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fa2:	00014997          	auipc	s3,0x14
    80002fa6:	74e98993          	addi	s3,s3,1870 # 800176f0 <tickslock>
    80002faa:	00006497          	auipc	s1,0x6
    80002fae:	0a648493          	addi	s1,s1,166 # 80009050 <ticks>
    if(myproc()->killed){
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	cdc080e7          	jalr	-804(ra) # 80001c8e <myproc>
    80002fba:	551c                	lw	a5,40(a0)
    80002fbc:	ef9d                	bnez	a5,80002ffa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fbe:	85ce                	mv	a1,s3
    80002fc0:	8526                	mv	a0,s1
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	362080e7          	jalr	866(ra) # 80002324 <sleep>
  while(ticks - ticks0 < n){
    80002fca:	409c                	lw	a5,0(s1)
    80002fcc:	412787bb          	subw	a5,a5,s2
    80002fd0:	fcc42703          	lw	a4,-52(s0)
    80002fd4:	fce7efe3          	bltu	a5,a4,80002fb2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	71850513          	addi	a0,a0,1816 # 800176f0 <tickslock>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	cb8080e7          	jalr	-840(ra) # 80000c98 <release>
  return 0;
    80002fe8:	4781                	li	a5,0
}
    80002fea:	853e                	mv	a0,a5
    80002fec:	70e2                	ld	ra,56(sp)
    80002fee:	7442                	ld	s0,48(sp)
    80002ff0:	74a2                	ld	s1,40(sp)
    80002ff2:	7902                	ld	s2,32(sp)
    80002ff4:	69e2                	ld	s3,24(sp)
    80002ff6:	6121                	addi	sp,sp,64
    80002ff8:	8082                	ret
      release(&tickslock);
    80002ffa:	00014517          	auipc	a0,0x14
    80002ffe:	6f650513          	addi	a0,a0,1782 # 800176f0 <tickslock>
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	c96080e7          	jalr	-874(ra) # 80000c98 <release>
      return -1;
    8000300a:	57fd                	li	a5,-1
    8000300c:	bff9                	j	80002fea <sys_sleep+0x88>

000000008000300e <sys_kill>:

uint64
sys_kill(void)
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003016:	fec40593          	addi	a1,s0,-20
    8000301a:	4501                	li	a0,0
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	d6c080e7          	jalr	-660(ra) # 80002d88 <argint>
    80003024:	87aa                	mv	a5,a0
    return -1;
    80003026:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003028:	0007c863          	bltz	a5,80003038 <sys_kill+0x2a>
  return kill(pid);
    8000302c:	fec42503          	lw	a0,-20(s0)
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	8a4080e7          	jalr	-1884(ra) # 800018d4 <kill>
}
    80003038:	60e2                	ld	ra,24(sp)
    8000303a:	6442                	ld	s0,16(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <sys_kill_sys>:

uint64
sys_kill_sys(void)
{
    80003040:	1141                	addi	sp,sp,-16
    80003042:	e406                	sd	ra,8(sp)
    80003044:	e022                	sd	s0,0(sp)
    80003046:	0800                	addi	s0,sp,16
  return kill_sys();
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	908080e7          	jalr	-1784(ra) # 80001950 <kill_sys>
}
    80003050:	60a2                	ld	ra,8(sp)
    80003052:	6402                	ld	s0,0(sp)
    80003054:	0141                	addi	sp,sp,16
    80003056:	8082                	ret

0000000080003058 <sys_pause_sys>:


uint64
sys_pause_sys(void)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80003060:	fec40593          	addi	a1,s0,-20
    80003064:	4501                	li	a0,0
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	d22080e7          	jalr	-734(ra) # 80002d88 <argint>
    8000306e:	87aa                	mv	a5,a0
    return -1;
    80003070:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80003072:	0007c863          	bltz	a5,80003082 <sys_pause_sys+0x2a>
  return pause_sys(time);
    80003076:	fec42503          	lw	a0,-20(s0)
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	274080e7          	jalr	628(ra) # 800022ee <pause_sys>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003094:	00014517          	auipc	a0,0x14
    80003098:	65c50513          	addi	a0,a0,1628 # 800176f0 <tickslock>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b48080e7          	jalr	-1208(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030a4:	00006497          	auipc	s1,0x6
    800030a8:	fac4a483          	lw	s1,-84(s1) # 80009050 <ticks>
  release(&tickslock);
    800030ac:	00014517          	auipc	a0,0x14
    800030b0:	64450513          	addi	a0,a0,1604 # 800176f0 <tickslock>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	be4080e7          	jalr	-1052(ra) # 80000c98 <release>
  return xticks;
}
    800030bc:	02049513          	slli	a0,s1,0x20
    800030c0:	9101                	srli	a0,a0,0x20
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6105                	addi	sp,sp,32
    800030ca:	8082                	ret

00000000800030cc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030cc:	7179                	addi	sp,sp,-48
    800030ce:	f406                	sd	ra,40(sp)
    800030d0:	f022                	sd	s0,32(sp)
    800030d2:	ec26                	sd	s1,24(sp)
    800030d4:	e84a                	sd	s2,16(sp)
    800030d6:	e44e                	sd	s3,8(sp)
    800030d8:	e052                	sd	s4,0(sp)
    800030da:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030dc:	00005597          	auipc	a1,0x5
    800030e0:	4d458593          	addi	a1,a1,1236 # 800085b0 <syscalls+0xc8>
    800030e4:	00014517          	auipc	a0,0x14
    800030e8:	62450513          	addi	a0,a0,1572 # 80017708 <bcache>
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	a68080e7          	jalr	-1432(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	61478793          	addi	a5,a5,1556 # 8001f708 <bcache+0x8000>
    800030fc:	0001d717          	auipc	a4,0x1d
    80003100:	87470713          	addi	a4,a4,-1932 # 8001f970 <bcache+0x8268>
    80003104:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003108:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000310c:	00014497          	auipc	s1,0x14
    80003110:	61448493          	addi	s1,s1,1556 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    80003114:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003116:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003118:	00005a17          	auipc	s4,0x5
    8000311c:	4a0a0a13          	addi	s4,s4,1184 # 800085b8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003120:	2b893783          	ld	a5,696(s2)
    80003124:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003126:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000312a:	85d2                	mv	a1,s4
    8000312c:	01048513          	addi	a0,s1,16
    80003130:	00001097          	auipc	ra,0x1
    80003134:	4bc080e7          	jalr	1212(ra) # 800045ec <initsleeplock>
    bcache.head.next->prev = b;
    80003138:	2b893783          	ld	a5,696(s2)
    8000313c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000313e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003142:	45848493          	addi	s1,s1,1112
    80003146:	fd349de3          	bne	s1,s3,80003120 <binit+0x54>
  }
}
    8000314a:	70a2                	ld	ra,40(sp)
    8000314c:	7402                	ld	s0,32(sp)
    8000314e:	64e2                	ld	s1,24(sp)
    80003150:	6942                	ld	s2,16(sp)
    80003152:	69a2                	ld	s3,8(sp)
    80003154:	6a02                	ld	s4,0(sp)
    80003156:	6145                	addi	sp,sp,48
    80003158:	8082                	ret

000000008000315a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	89aa                	mv	s3,a0
    8000316a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	59c50513          	addi	a0,a0,1436 # 80017708 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	a70080e7          	jalr	-1424(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000317c:	0001d497          	auipc	s1,0x1d
    80003180:	8444b483          	ld	s1,-1980(s1) # 8001f9c0 <bcache+0x82b8>
    80003184:	0001c797          	auipc	a5,0x1c
    80003188:	7ec78793          	addi	a5,a5,2028 # 8001f970 <bcache+0x8268>
    8000318c:	02f48f63          	beq	s1,a5,800031ca <bread+0x70>
    80003190:	873e                	mv	a4,a5
    80003192:	a021                	j	8000319a <bread+0x40>
    80003194:	68a4                	ld	s1,80(s1)
    80003196:	02e48a63          	beq	s1,a4,800031ca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000319a:	449c                	lw	a5,8(s1)
    8000319c:	ff379ce3          	bne	a5,s3,80003194 <bread+0x3a>
    800031a0:	44dc                	lw	a5,12(s1)
    800031a2:	ff2799e3          	bne	a5,s2,80003194 <bread+0x3a>
      b->refcnt++;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	55c50513          	addi	a0,a0,1372 # 80017708 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031bc:	01048513          	addi	a0,s1,16
    800031c0:	00001097          	auipc	ra,0x1
    800031c4:	466080e7          	jalr	1126(ra) # 80004626 <acquiresleep>
      return b;
    800031c8:	a8b9                	j	80003226 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ca:	0001c497          	auipc	s1,0x1c
    800031ce:	7ee4b483          	ld	s1,2030(s1) # 8001f9b8 <bcache+0x82b0>
    800031d2:	0001c797          	auipc	a5,0x1c
    800031d6:	79e78793          	addi	a5,a5,1950 # 8001f970 <bcache+0x8268>
    800031da:	00f48863          	beq	s1,a5,800031ea <bread+0x90>
    800031de:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031e0:	40bc                	lw	a5,64(s1)
    800031e2:	cf81                	beqz	a5,800031fa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e4:	64a4                	ld	s1,72(s1)
    800031e6:	fee49de3          	bne	s1,a4,800031e0 <bread+0x86>
  panic("bget: no buffers");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	3d650513          	addi	a0,a0,982 # 800085c0 <syscalls+0xd8>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>
      b->dev = dev;
    800031fa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031fe:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003202:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003206:	4785                	li	a5,1
    80003208:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000320a:	00014517          	auipc	a0,0x14
    8000320e:	4fe50513          	addi	a0,a0,1278 # 80017708 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000321a:	01048513          	addi	a0,s1,16
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	408080e7          	jalr	1032(ra) # 80004626 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003226:	409c                	lw	a5,0(s1)
    80003228:	cb89                	beqz	a5,8000323a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000322a:	8526                	mv	a0,s1
    8000322c:	70a2                	ld	ra,40(sp)
    8000322e:	7402                	ld	s0,32(sp)
    80003230:	64e2                	ld	s1,24(sp)
    80003232:	6942                	ld	s2,16(sp)
    80003234:	69a2                	ld	s3,8(sp)
    80003236:	6145                	addi	sp,sp,48
    80003238:	8082                	ret
    virtio_disk_rw(b, 0);
    8000323a:	4581                	li	a1,0
    8000323c:	8526                	mv	a0,s1
    8000323e:	00003097          	auipc	ra,0x3
    80003242:	f08080e7          	jalr	-248(ra) # 80006146 <virtio_disk_rw>
    b->valid = 1;
    80003246:	4785                	li	a5,1
    80003248:	c09c                	sw	a5,0(s1)
  return b;
    8000324a:	b7c5                	j	8000322a <bread+0xd0>

000000008000324c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003258:	0541                	addi	a0,a0,16
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	466080e7          	jalr	1126(ra) # 800046c0 <holdingsleep>
    80003262:	cd01                	beqz	a0,8000327a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003264:	4585                	li	a1,1
    80003266:	8526                	mv	a0,s1
    80003268:	00003097          	auipc	ra,0x3
    8000326c:	ede080e7          	jalr	-290(ra) # 80006146 <virtio_disk_rw>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret
    panic("bwrite");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	35e50513          	addi	a0,a0,862 # 800085d8 <syscalls+0xf0>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2bc080e7          	jalr	700(ra) # 8000053e <panic>

000000008000328a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	e04a                	sd	s2,0(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003298:	01050913          	addi	s2,a0,16
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	422080e7          	jalr	1058(ra) # 800046c0 <holdingsleep>
    800032a6:	c92d                	beqz	a0,80003318 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032a8:	854a                	mv	a0,s2
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	3d2080e7          	jalr	978(ra) # 8000467c <releasesleep>

  acquire(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	45650513          	addi	a0,a0,1110 # 80017708 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032c2:	40bc                	lw	a5,64(s1)
    800032c4:	37fd                	addiw	a5,a5,-1
    800032c6:	0007871b          	sext.w	a4,a5
    800032ca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032cc:	eb05                	bnez	a4,800032fc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ce:	68bc                	ld	a5,80(s1)
    800032d0:	64b8                	ld	a4,72(s1)
    800032d2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032d4:	64bc                	ld	a5,72(s1)
    800032d6:	68b8                	ld	a4,80(s1)
    800032d8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032da:	0001c797          	auipc	a5,0x1c
    800032de:	42e78793          	addi	a5,a5,1070 # 8001f708 <bcache+0x8000>
    800032e2:	2b87b703          	ld	a4,696(a5)
    800032e6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032e8:	0001c717          	auipc	a4,0x1c
    800032ec:	68870713          	addi	a4,a4,1672 # 8001f970 <bcache+0x8268>
    800032f0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032f2:	2b87b703          	ld	a4,696(a5)
    800032f6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032f8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	40c50513          	addi	a0,a0,1036 # 80017708 <bcache>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
}
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	64a2                	ld	s1,8(sp)
    80003312:	6902                	ld	s2,0(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret
    panic("brelse");
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	2c850513          	addi	a0,a0,712 # 800085e0 <syscalls+0xf8>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	21e080e7          	jalr	542(ra) # 8000053e <panic>

0000000080003328 <bpin>:

void
bpin(struct buf *b) {
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	e426                	sd	s1,8(sp)
    80003330:	1000                	addi	s0,sp,32
    80003332:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003334:	00014517          	auipc	a0,0x14
    80003338:	3d450513          	addi	a0,a0,980 # 80017708 <bcache>
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003344:	40bc                	lw	a5,64(s1)
    80003346:	2785                	addiw	a5,a5,1
    80003348:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000334a:	00014517          	auipc	a0,0x14
    8000334e:	3be50513          	addi	a0,a0,958 # 80017708 <bcache>
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	946080e7          	jalr	-1722(ra) # 80000c98 <release>
}
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	64a2                	ld	s1,8(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret

0000000080003364 <bunpin>:

void
bunpin(struct buf *b) {
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	e426                	sd	s1,8(sp)
    8000336c:	1000                	addi	s0,sp,32
    8000336e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003370:	00014517          	auipc	a0,0x14
    80003374:	39850513          	addi	a0,a0,920 # 80017708 <bcache>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003380:	40bc                	lw	a5,64(s1)
    80003382:	37fd                	addiw	a5,a5,-1
    80003384:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	38250513          	addi	a0,a0,898 # 80017708 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033ae:	00d5d59b          	srliw	a1,a1,0xd
    800033b2:	0001d797          	auipc	a5,0x1d
    800033b6:	a327a783          	lw	a5,-1486(a5) # 8001fde4 <sb+0x1c>
    800033ba:	9dbd                	addw	a1,a1,a5
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	d9e080e7          	jalr	-610(ra) # 8000315a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033c4:	0074f713          	andi	a4,s1,7
    800033c8:	4785                	li	a5,1
    800033ca:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ce:	14ce                	slli	s1,s1,0x33
    800033d0:	90d9                	srli	s1,s1,0x36
    800033d2:	00950733          	add	a4,a0,s1
    800033d6:	05874703          	lbu	a4,88(a4)
    800033da:	00e7f6b3          	and	a3,a5,a4
    800033de:	c69d                	beqz	a3,8000340c <bfree+0x6c>
    800033e0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033e2:	94aa                	add	s1,s1,a0
    800033e4:	fff7c793          	not	a5,a5
    800033e8:	8ff9                	and	a5,a5,a4
    800033ea:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	118080e7          	jalr	280(ra) # 80004506 <log_write>
  brelse(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	e92080e7          	jalr	-366(ra) # 8000328a <brelse>
}
    80003400:	60e2                	ld	ra,24(sp)
    80003402:	6442                	ld	s0,16(sp)
    80003404:	64a2                	ld	s1,8(sp)
    80003406:	6902                	ld	s2,0(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret
    panic("freeing free block");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	1dc50513          	addi	a0,a0,476 # 800085e8 <syscalls+0x100>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	12a080e7          	jalr	298(ra) # 8000053e <panic>

000000008000341c <balloc>:
{
    8000341c:	711d                	addi	sp,sp,-96
    8000341e:	ec86                	sd	ra,88(sp)
    80003420:	e8a2                	sd	s0,80(sp)
    80003422:	e4a6                	sd	s1,72(sp)
    80003424:	e0ca                	sd	s2,64(sp)
    80003426:	fc4e                	sd	s3,56(sp)
    80003428:	f852                	sd	s4,48(sp)
    8000342a:	f456                	sd	s5,40(sp)
    8000342c:	f05a                	sd	s6,32(sp)
    8000342e:	ec5e                	sd	s7,24(sp)
    80003430:	e862                	sd	s8,16(sp)
    80003432:	e466                	sd	s9,8(sp)
    80003434:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003436:	0001d797          	auipc	a5,0x1d
    8000343a:	9967a783          	lw	a5,-1642(a5) # 8001fdcc <sb+0x4>
    8000343e:	cbd1                	beqz	a5,800034d2 <balloc+0xb6>
    80003440:	8baa                	mv	s7,a0
    80003442:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003444:	0001db17          	auipc	s6,0x1d
    80003448:	984b0b13          	addi	s6,s6,-1660 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000344e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003450:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003452:	6c89                	lui	s9,0x2
    80003454:	a831                	j	80003470 <balloc+0x54>
    brelse(bp);
    80003456:	854a                	mv	a0,s2
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e32080e7          	jalr	-462(ra) # 8000328a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003460:	015c87bb          	addw	a5,s9,s5
    80003464:	00078a9b          	sext.w	s5,a5
    80003468:	004b2703          	lw	a4,4(s6)
    8000346c:	06eaf363          	bgeu	s5,a4,800034d2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003470:	41fad79b          	sraiw	a5,s5,0x1f
    80003474:	0137d79b          	srliw	a5,a5,0x13
    80003478:	015787bb          	addw	a5,a5,s5
    8000347c:	40d7d79b          	sraiw	a5,a5,0xd
    80003480:	01cb2583          	lw	a1,28(s6)
    80003484:	9dbd                	addw	a1,a1,a5
    80003486:	855e                	mv	a0,s7
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	cd2080e7          	jalr	-814(ra) # 8000315a <bread>
    80003490:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003492:	004b2503          	lw	a0,4(s6)
    80003496:	000a849b          	sext.w	s1,s5
    8000349a:	8662                	mv	a2,s8
    8000349c:	faa4fde3          	bgeu	s1,a0,80003456 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034a0:	41f6579b          	sraiw	a5,a2,0x1f
    800034a4:	01d7d69b          	srliw	a3,a5,0x1d
    800034a8:	00c6873b          	addw	a4,a3,a2
    800034ac:	00777793          	andi	a5,a4,7
    800034b0:	9f95                	subw	a5,a5,a3
    800034b2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034b6:	4037571b          	sraiw	a4,a4,0x3
    800034ba:	00e906b3          	add	a3,s2,a4
    800034be:	0586c683          	lbu	a3,88(a3)
    800034c2:	00d7f5b3          	and	a1,a5,a3
    800034c6:	cd91                	beqz	a1,800034e2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	2605                	addiw	a2,a2,1
    800034ca:	2485                	addiw	s1,s1,1
    800034cc:	fd4618e3          	bne	a2,s4,8000349c <balloc+0x80>
    800034d0:	b759                	j	80003456 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	12e50513          	addi	a0,a0,302 # 80008600 <syscalls+0x118>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	064080e7          	jalr	100(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034e2:	974a                	add	a4,a4,s2
    800034e4:	8fd5                	or	a5,a5,a3
    800034e6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	01a080e7          	jalr	26(ra) # 80004506 <log_write>
        brelse(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	d94080e7          	jalr	-620(ra) # 8000328a <brelse>
  bp = bread(dev, bno);
    800034fe:	85a6                	mv	a1,s1
    80003500:	855e                	mv	a0,s7
    80003502:	00000097          	auipc	ra,0x0
    80003506:	c58080e7          	jalr	-936(ra) # 8000315a <bread>
    8000350a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000350c:	40000613          	li	a2,1024
    80003510:	4581                	li	a1,0
    80003512:	05850513          	addi	a0,a0,88
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	7ca080e7          	jalr	1994(ra) # 80000ce0 <memset>
  log_write(bp);
    8000351e:	854a                	mv	a0,s2
    80003520:	00001097          	auipc	ra,0x1
    80003524:	fe6080e7          	jalr	-26(ra) # 80004506 <log_write>
  brelse(bp);
    80003528:	854a                	mv	a0,s2
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	d60080e7          	jalr	-672(ra) # 8000328a <brelse>
}
    80003532:	8526                	mv	a0,s1
    80003534:	60e6                	ld	ra,88(sp)
    80003536:	6446                	ld	s0,80(sp)
    80003538:	64a6                	ld	s1,72(sp)
    8000353a:	6906                	ld	s2,64(sp)
    8000353c:	79e2                	ld	s3,56(sp)
    8000353e:	7a42                	ld	s4,48(sp)
    80003540:	7aa2                	ld	s5,40(sp)
    80003542:	7b02                	ld	s6,32(sp)
    80003544:	6be2                	ld	s7,24(sp)
    80003546:	6c42                	ld	s8,16(sp)
    80003548:	6ca2                	ld	s9,8(sp)
    8000354a:	6125                	addi	sp,sp,96
    8000354c:	8082                	ret

000000008000354e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000354e:	7179                	addi	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	e052                	sd	s4,0(sp)
    8000355c:	1800                	addi	s0,sp,48
    8000355e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003560:	47ad                	li	a5,11
    80003562:	04b7fe63          	bgeu	a5,a1,800035be <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003566:	ff45849b          	addiw	s1,a1,-12
    8000356a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000356e:	0ff00793          	li	a5,255
    80003572:	0ae7e363          	bltu	a5,a4,80003618 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003576:	08052583          	lw	a1,128(a0)
    8000357a:	c5ad                	beqz	a1,800035e4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000357c:	00092503          	lw	a0,0(s2)
    80003580:	00000097          	auipc	ra,0x0
    80003584:	bda080e7          	jalr	-1062(ra) # 8000315a <bread>
    80003588:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000358a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000358e:	02049593          	slli	a1,s1,0x20
    80003592:	9181                	srli	a1,a1,0x20
    80003594:	058a                	slli	a1,a1,0x2
    80003596:	00b784b3          	add	s1,a5,a1
    8000359a:	0004a983          	lw	s3,0(s1)
    8000359e:	04098d63          	beqz	s3,800035f8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035a2:	8552                	mv	a0,s4
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	ce6080e7          	jalr	-794(ra) # 8000328a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ac:	854e                	mv	a0,s3
    800035ae:	70a2                	ld	ra,40(sp)
    800035b0:	7402                	ld	s0,32(sp)
    800035b2:	64e2                	ld	s1,24(sp)
    800035b4:	6942                	ld	s2,16(sp)
    800035b6:	69a2                	ld	s3,8(sp)
    800035b8:	6a02                	ld	s4,0(sp)
    800035ba:	6145                	addi	sp,sp,48
    800035bc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035be:	02059493          	slli	s1,a1,0x20
    800035c2:	9081                	srli	s1,s1,0x20
    800035c4:	048a                	slli	s1,s1,0x2
    800035c6:	94aa                	add	s1,s1,a0
    800035c8:	0504a983          	lw	s3,80(s1)
    800035cc:	fe0990e3          	bnez	s3,800035ac <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035d0:	4108                	lw	a0,0(a0)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e4a080e7          	jalr	-438(ra) # 8000341c <balloc>
    800035da:	0005099b          	sext.w	s3,a0
    800035de:	0534a823          	sw	s3,80(s1)
    800035e2:	b7e9                	j	800035ac <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035e4:	4108                	lw	a0,0(a0)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	e36080e7          	jalr	-458(ra) # 8000341c <balloc>
    800035ee:	0005059b          	sext.w	a1,a0
    800035f2:	08b92023          	sw	a1,128(s2)
    800035f6:	b759                	j	8000357c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035f8:	00092503          	lw	a0,0(s2)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e20080e7          	jalr	-480(ra) # 8000341c <balloc>
    80003604:	0005099b          	sext.w	s3,a0
    80003608:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000360c:	8552                	mv	a0,s4
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	ef8080e7          	jalr	-264(ra) # 80004506 <log_write>
    80003616:	b771                	j	800035a2 <bmap+0x54>
  panic("bmap: out of range");
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	00050513          	mv	a0,a0
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>

0000000080003628 <iget>:
{
    80003628:	7179                	addi	sp,sp,-48
    8000362a:	f406                	sd	ra,40(sp)
    8000362c:	f022                	sd	s0,32(sp)
    8000362e:	ec26                	sd	s1,24(sp)
    80003630:	e84a                	sd	s2,16(sp)
    80003632:	e44e                	sd	s3,8(sp)
    80003634:	e052                	sd	s4,0(sp)
    80003636:	1800                	addi	s0,sp,48
    80003638:	89aa                	mv	s3,a0
    8000363a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000363c:	0001c517          	auipc	a0,0x1c
    80003640:	7ac50513          	addi	a0,a0,1964 # 8001fde8 <itable>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  empty = 0;
    8000364c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000364e:	0001c497          	auipc	s1,0x1c
    80003652:	7b248493          	addi	s1,s1,1970 # 8001fe00 <itable+0x18>
    80003656:	0001e697          	auipc	a3,0x1e
    8000365a:	23a68693          	addi	a3,a3,570 # 80021890 <log>
    8000365e:	a039                	j	8000366c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003660:	02090b63          	beqz	s2,80003696 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003664:	08848493          	addi	s1,s1,136
    80003668:	02d48a63          	beq	s1,a3,8000369c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000366c:	449c                	lw	a5,8(s1)
    8000366e:	fef059e3          	blez	a5,80003660 <iget+0x38>
    80003672:	4098                	lw	a4,0(s1)
    80003674:	ff3716e3          	bne	a4,s3,80003660 <iget+0x38>
    80003678:	40d8                	lw	a4,4(s1)
    8000367a:	ff4713e3          	bne	a4,s4,80003660 <iget+0x38>
      ip->ref++;
    8000367e:	2785                	addiw	a5,a5,1
    80003680:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003682:	0001c517          	auipc	a0,0x1c
    80003686:	76650513          	addi	a0,a0,1894 # 8001fde8 <itable>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	60e080e7          	jalr	1550(ra) # 80000c98 <release>
      return ip;
    80003692:	8926                	mv	s2,s1
    80003694:	a03d                	j	800036c2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003696:	f7f9                	bnez	a5,80003664 <iget+0x3c>
    80003698:	8926                	mv	s2,s1
    8000369a:	b7e9                	j	80003664 <iget+0x3c>
  if(empty == 0)
    8000369c:	02090c63          	beqz	s2,800036d4 <iget+0xac>
  ip->dev = dev;
    800036a0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036a4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036a8:	4785                	li	a5,1
    800036aa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036ae:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036b2:	0001c517          	auipc	a0,0x1c
    800036b6:	73650513          	addi	a0,a0,1846 # 8001fde8 <itable>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5de080e7          	jalr	1502(ra) # 80000c98 <release>
}
    800036c2:	854a                	mv	a0,s2
    800036c4:	70a2                	ld	ra,40(sp)
    800036c6:	7402                	ld	s0,32(sp)
    800036c8:	64e2                	ld	s1,24(sp)
    800036ca:	6942                	ld	s2,16(sp)
    800036cc:	69a2                	ld	s3,8(sp)
    800036ce:	6a02                	ld	s4,0(sp)
    800036d0:	6145                	addi	sp,sp,48
    800036d2:	8082                	ret
    panic("iget: no inodes");
    800036d4:	00005517          	auipc	a0,0x5
    800036d8:	f5c50513          	addi	a0,a0,-164 # 80008630 <syscalls+0x148>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	e62080e7          	jalr	-414(ra) # 8000053e <panic>

00000000800036e4 <fsinit>:
fsinit(int dev) {
    800036e4:	7179                	addi	sp,sp,-48
    800036e6:	f406                	sd	ra,40(sp)
    800036e8:	f022                	sd	s0,32(sp)
    800036ea:	ec26                	sd	s1,24(sp)
    800036ec:	e84a                	sd	s2,16(sp)
    800036ee:	e44e                	sd	s3,8(sp)
    800036f0:	1800                	addi	s0,sp,48
    800036f2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036f4:	4585                	li	a1,1
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	a64080e7          	jalr	-1436(ra) # 8000315a <bread>
    800036fe:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003700:	0001c997          	auipc	s3,0x1c
    80003704:	6c898993          	addi	s3,s3,1736 # 8001fdc8 <sb>
    80003708:	02000613          	li	a2,32
    8000370c:	05850593          	addi	a1,a0,88
    80003710:	854e                	mv	a0,s3
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	62e080e7          	jalr	1582(ra) # 80000d40 <memmove>
  brelse(bp);
    8000371a:	8526                	mv	a0,s1
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	b6e080e7          	jalr	-1170(ra) # 8000328a <brelse>
  if(sb.magic != FSMAGIC)
    80003724:	0009a703          	lw	a4,0(s3)
    80003728:	102037b7          	lui	a5,0x10203
    8000372c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003730:	02f71263          	bne	a4,a5,80003754 <fsinit+0x70>
  initlog(dev, &sb);
    80003734:	0001c597          	auipc	a1,0x1c
    80003738:	69458593          	addi	a1,a1,1684 # 8001fdc8 <sb>
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	b4c080e7          	jalr	-1204(ra) # 8000428a <initlog>
}
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6145                	addi	sp,sp,48
    80003752:	8082                	ret
    panic("invalid file system");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	eec50513          	addi	a0,a0,-276 # 80008640 <syscalls+0x158>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>

0000000080003764 <iinit>:
{
    80003764:	7179                	addi	sp,sp,-48
    80003766:	f406                	sd	ra,40(sp)
    80003768:	f022                	sd	s0,32(sp)
    8000376a:	ec26                	sd	s1,24(sp)
    8000376c:	e84a                	sd	s2,16(sp)
    8000376e:	e44e                	sd	s3,8(sp)
    80003770:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003772:	00005597          	auipc	a1,0x5
    80003776:	ee658593          	addi	a1,a1,-282 # 80008658 <syscalls+0x170>
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	66e50513          	addi	a0,a0,1646 # 8001fde8 <itable>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	3d2080e7          	jalr	978(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000378a:	0001c497          	auipc	s1,0x1c
    8000378e:	68648493          	addi	s1,s1,1670 # 8001fe10 <itable+0x28>
    80003792:	0001e997          	auipc	s3,0x1e
    80003796:	10e98993          	addi	s3,s3,270 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000379a:	00005917          	auipc	s2,0x5
    8000379e:	ec690913          	addi	s2,s2,-314 # 80008660 <syscalls+0x178>
    800037a2:	85ca                	mv	a1,s2
    800037a4:	8526                	mv	a0,s1
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	e46080e7          	jalr	-442(ra) # 800045ec <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037ae:	08848493          	addi	s1,s1,136
    800037b2:	ff3498e3          	bne	s1,s3,800037a2 <iinit+0x3e>
}
    800037b6:	70a2                	ld	ra,40(sp)
    800037b8:	7402                	ld	s0,32(sp)
    800037ba:	64e2                	ld	s1,24(sp)
    800037bc:	6942                	ld	s2,16(sp)
    800037be:	69a2                	ld	s3,8(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret

00000000800037c4 <ialloc>:
{
    800037c4:	715d                	addi	sp,sp,-80
    800037c6:	e486                	sd	ra,72(sp)
    800037c8:	e0a2                	sd	s0,64(sp)
    800037ca:	fc26                	sd	s1,56(sp)
    800037cc:	f84a                	sd	s2,48(sp)
    800037ce:	f44e                	sd	s3,40(sp)
    800037d0:	f052                	sd	s4,32(sp)
    800037d2:	ec56                	sd	s5,24(sp)
    800037d4:	e85a                	sd	s6,16(sp)
    800037d6:	e45e                	sd	s7,8(sp)
    800037d8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037da:	0001c717          	auipc	a4,0x1c
    800037de:	5fa72703          	lw	a4,1530(a4) # 8001fdd4 <sb+0xc>
    800037e2:	4785                	li	a5,1
    800037e4:	04e7fa63          	bgeu	a5,a4,80003838 <ialloc+0x74>
    800037e8:	8aaa                	mv	s5,a0
    800037ea:	8bae                	mv	s7,a1
    800037ec:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037ee:	0001ca17          	auipc	s4,0x1c
    800037f2:	5daa0a13          	addi	s4,s4,1498 # 8001fdc8 <sb>
    800037f6:	00048b1b          	sext.w	s6,s1
    800037fa:	0044d593          	srli	a1,s1,0x4
    800037fe:	018a2783          	lw	a5,24(s4)
    80003802:	9dbd                	addw	a1,a1,a5
    80003804:	8556                	mv	a0,s5
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	954080e7          	jalr	-1708(ra) # 8000315a <bread>
    8000380e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003810:	05850993          	addi	s3,a0,88
    80003814:	00f4f793          	andi	a5,s1,15
    80003818:	079a                	slli	a5,a5,0x6
    8000381a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000381c:	00099783          	lh	a5,0(s3)
    80003820:	c785                	beqz	a5,80003848 <ialloc+0x84>
    brelse(bp);
    80003822:	00000097          	auipc	ra,0x0
    80003826:	a68080e7          	jalr	-1432(ra) # 8000328a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000382a:	0485                	addi	s1,s1,1
    8000382c:	00ca2703          	lw	a4,12(s4)
    80003830:	0004879b          	sext.w	a5,s1
    80003834:	fce7e1e3          	bltu	a5,a4,800037f6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	e3050513          	addi	a0,a0,-464 # 80008668 <syscalls+0x180>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cfe080e7          	jalr	-770(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003848:	04000613          	li	a2,64
    8000384c:	4581                	li	a1,0
    8000384e:	854e                	mv	a0,s3
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	490080e7          	jalr	1168(ra) # 80000ce0 <memset>
      dip->type = type;
    80003858:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	ca8080e7          	jalr	-856(ra) # 80004506 <log_write>
      brelse(bp);
    80003866:	854a                	mv	a0,s2
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	a22080e7          	jalr	-1502(ra) # 8000328a <brelse>
      return iget(dev, inum);
    80003870:	85da                	mv	a1,s6
    80003872:	8556                	mv	a0,s5
    80003874:	00000097          	auipc	ra,0x0
    80003878:	db4080e7          	jalr	-588(ra) # 80003628 <iget>
}
    8000387c:	60a6                	ld	ra,72(sp)
    8000387e:	6406                	ld	s0,64(sp)
    80003880:	74e2                	ld	s1,56(sp)
    80003882:	7942                	ld	s2,48(sp)
    80003884:	79a2                	ld	s3,40(sp)
    80003886:	7a02                	ld	s4,32(sp)
    80003888:	6ae2                	ld	s5,24(sp)
    8000388a:	6b42                	ld	s6,16(sp)
    8000388c:	6ba2                	ld	s7,8(sp)
    8000388e:	6161                	addi	sp,sp,80
    80003890:	8082                	ret

0000000080003892 <iupdate>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	e04a                	sd	s2,0(sp)
    8000389c:	1000                	addi	s0,sp,32
    8000389e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a0:	415c                	lw	a5,4(a0)
    800038a2:	0047d79b          	srliw	a5,a5,0x4
    800038a6:	0001c597          	auipc	a1,0x1c
    800038aa:	53a5a583          	lw	a1,1338(a1) # 8001fde0 <sb+0x18>
    800038ae:	9dbd                	addw	a1,a1,a5
    800038b0:	4108                	lw	a0,0(a0)
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	8a8080e7          	jalr	-1880(ra) # 8000315a <bread>
    800038ba:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038bc:	05850793          	addi	a5,a0,88
    800038c0:	40c8                	lw	a0,4(s1)
    800038c2:	893d                	andi	a0,a0,15
    800038c4:	051a                	slli	a0,a0,0x6
    800038c6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038c8:	04449703          	lh	a4,68(s1)
    800038cc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038d0:	04649703          	lh	a4,70(s1)
    800038d4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038d8:	04849703          	lh	a4,72(s1)
    800038dc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038e0:	04a49703          	lh	a4,74(s1)
    800038e4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038e8:	44f8                	lw	a4,76(s1)
    800038ea:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ec:	03400613          	li	a2,52
    800038f0:	05048593          	addi	a1,s1,80
    800038f4:	0531                	addi	a0,a0,12
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	44a080e7          	jalr	1098(ra) # 80000d40 <memmove>
  log_write(bp);
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	c06080e7          	jalr	-1018(ra) # 80004506 <log_write>
  brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	980080e7          	jalr	-1664(ra) # 8000328a <brelse>
}
    80003912:	60e2                	ld	ra,24(sp)
    80003914:	6442                	ld	s0,16(sp)
    80003916:	64a2                	ld	s1,8(sp)
    80003918:	6902                	ld	s2,0(sp)
    8000391a:	6105                	addi	sp,sp,32
    8000391c:	8082                	ret

000000008000391e <idup>:
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	e426                	sd	s1,8(sp)
    80003926:	1000                	addi	s0,sp,32
    80003928:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	4be50513          	addi	a0,a0,1214 # 8001fde8 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	2b2080e7          	jalr	690(ra) # 80000be4 <acquire>
  ip->ref++;
    8000393a:	449c                	lw	a5,8(s1)
    8000393c:	2785                	addiw	a5,a5,1
    8000393e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	4a850513          	addi	a0,a0,1192 # 8001fde8 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	350080e7          	jalr	848(ra) # 80000c98 <release>
}
    80003950:	8526                	mv	a0,s1
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6105                	addi	sp,sp,32
    8000395a:	8082                	ret

000000008000395c <ilock>:
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	e04a                	sd	s2,0(sp)
    80003966:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003968:	c115                	beqz	a0,8000398c <ilock+0x30>
    8000396a:	84aa                	mv	s1,a0
    8000396c:	451c                	lw	a5,8(a0)
    8000396e:	00f05f63          	blez	a5,8000398c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003972:	0541                	addi	a0,a0,16
    80003974:	00001097          	auipc	ra,0x1
    80003978:	cb2080e7          	jalr	-846(ra) # 80004626 <acquiresleep>
  if(ip->valid == 0){
    8000397c:	40bc                	lw	a5,64(s1)
    8000397e:	cf99                	beqz	a5,8000399c <ilock+0x40>
}
    80003980:	60e2                	ld	ra,24(sp)
    80003982:	6442                	ld	s0,16(sp)
    80003984:	64a2                	ld	s1,8(sp)
    80003986:	6902                	ld	s2,0(sp)
    80003988:	6105                	addi	sp,sp,32
    8000398a:	8082                	ret
    panic("ilock");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	cf450513          	addi	a0,a0,-780 # 80008680 <syscalls+0x198>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	baa080e7          	jalr	-1110(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000399c:	40dc                	lw	a5,4(s1)
    8000399e:	0047d79b          	srliw	a5,a5,0x4
    800039a2:	0001c597          	auipc	a1,0x1c
    800039a6:	43e5a583          	lw	a1,1086(a1) # 8001fde0 <sb+0x18>
    800039aa:	9dbd                	addw	a1,a1,a5
    800039ac:	4088                	lw	a0,0(s1)
    800039ae:	fffff097          	auipc	ra,0xfffff
    800039b2:	7ac080e7          	jalr	1964(ra) # 8000315a <bread>
    800039b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b8:	05850593          	addi	a1,a0,88
    800039bc:	40dc                	lw	a5,4(s1)
    800039be:	8bbd                	andi	a5,a5,15
    800039c0:	079a                	slli	a5,a5,0x6
    800039c2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039c4:	00059783          	lh	a5,0(a1)
    800039c8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039cc:	00259783          	lh	a5,2(a1)
    800039d0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039d4:	00459783          	lh	a5,4(a1)
    800039d8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039dc:	00659783          	lh	a5,6(a1)
    800039e0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039e4:	459c                	lw	a5,8(a1)
    800039e6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039e8:	03400613          	li	a2,52
    800039ec:	05b1                	addi	a1,a1,12
    800039ee:	05048513          	addi	a0,s1,80
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	34e080e7          	jalr	846(ra) # 80000d40 <memmove>
    brelse(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	88e080e7          	jalr	-1906(ra) # 8000328a <brelse>
    ip->valid = 1;
    80003a04:	4785                	li	a5,1
    80003a06:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a08:	04449783          	lh	a5,68(s1)
    80003a0c:	fbb5                	bnez	a5,80003980 <ilock+0x24>
      panic("ilock: no type");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	c7a50513          	addi	a0,a0,-902 # 80008688 <syscalls+0x1a0>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080003a1e <iunlock>:
{
    80003a1e:	1101                	addi	sp,sp,-32
    80003a20:	ec06                	sd	ra,24(sp)
    80003a22:	e822                	sd	s0,16(sp)
    80003a24:	e426                	sd	s1,8(sp)
    80003a26:	e04a                	sd	s2,0(sp)
    80003a28:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a2a:	c905                	beqz	a0,80003a5a <iunlock+0x3c>
    80003a2c:	84aa                	mv	s1,a0
    80003a2e:	01050913          	addi	s2,a0,16
    80003a32:	854a                	mv	a0,s2
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	c8c080e7          	jalr	-884(ra) # 800046c0 <holdingsleep>
    80003a3c:	cd19                	beqz	a0,80003a5a <iunlock+0x3c>
    80003a3e:	449c                	lw	a5,8(s1)
    80003a40:	00f05d63          	blez	a5,80003a5a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a44:	854a                	mv	a0,s2
    80003a46:	00001097          	auipc	ra,0x1
    80003a4a:	c36080e7          	jalr	-970(ra) # 8000467c <releasesleep>
}
    80003a4e:	60e2                	ld	ra,24(sp)
    80003a50:	6442                	ld	s0,16(sp)
    80003a52:	64a2                	ld	s1,8(sp)
    80003a54:	6902                	ld	s2,0(sp)
    80003a56:	6105                	addi	sp,sp,32
    80003a58:	8082                	ret
    panic("iunlock");
    80003a5a:	00005517          	auipc	a0,0x5
    80003a5e:	c3e50513          	addi	a0,a0,-962 # 80008698 <syscalls+0x1b0>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	adc080e7          	jalr	-1316(ra) # 8000053e <panic>

0000000080003a6a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a6a:	7179                	addi	sp,sp,-48
    80003a6c:	f406                	sd	ra,40(sp)
    80003a6e:	f022                	sd	s0,32(sp)
    80003a70:	ec26                	sd	s1,24(sp)
    80003a72:	e84a                	sd	s2,16(sp)
    80003a74:	e44e                	sd	s3,8(sp)
    80003a76:	e052                	sd	s4,0(sp)
    80003a78:	1800                	addi	s0,sp,48
    80003a7a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a7c:	05050493          	addi	s1,a0,80
    80003a80:	08050913          	addi	s2,a0,128
    80003a84:	a021                	j	80003a8c <itrunc+0x22>
    80003a86:	0491                	addi	s1,s1,4
    80003a88:	01248d63          	beq	s1,s2,80003aa2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a8c:	408c                	lw	a1,0(s1)
    80003a8e:	dde5                	beqz	a1,80003a86 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a90:	0009a503          	lw	a0,0(s3)
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	90c080e7          	jalr	-1780(ra) # 800033a0 <bfree>
      ip->addrs[i] = 0;
    80003a9c:	0004a023          	sw	zero,0(s1)
    80003aa0:	b7dd                	j	80003a86 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aa2:	0809a583          	lw	a1,128(s3)
    80003aa6:	e185                	bnez	a1,80003ac6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aa8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aac:	854e                	mv	a0,s3
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	de4080e7          	jalr	-540(ra) # 80003892 <iupdate>
}
    80003ab6:	70a2                	ld	ra,40(sp)
    80003ab8:	7402                	ld	s0,32(sp)
    80003aba:	64e2                	ld	s1,24(sp)
    80003abc:	6942                	ld	s2,16(sp)
    80003abe:	69a2                	ld	s3,8(sp)
    80003ac0:	6a02                	ld	s4,0(sp)
    80003ac2:	6145                	addi	sp,sp,48
    80003ac4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ac6:	0009a503          	lw	a0,0(s3)
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	690080e7          	jalr	1680(ra) # 8000315a <bread>
    80003ad2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ad4:	05850493          	addi	s1,a0,88
    80003ad8:	45850913          	addi	s2,a0,1112
    80003adc:	a811                	j	80003af0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ade:	0009a503          	lw	a0,0(s3)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	8be080e7          	jalr	-1858(ra) # 800033a0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003aea:	0491                	addi	s1,s1,4
    80003aec:	01248563          	beq	s1,s2,80003af6 <itrunc+0x8c>
      if(a[j])
    80003af0:	408c                	lw	a1,0(s1)
    80003af2:	dde5                	beqz	a1,80003aea <itrunc+0x80>
    80003af4:	b7ed                	j	80003ade <itrunc+0x74>
    brelse(bp);
    80003af6:	8552                	mv	a0,s4
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	792080e7          	jalr	1938(ra) # 8000328a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b00:	0809a583          	lw	a1,128(s3)
    80003b04:	0009a503          	lw	a0,0(s3)
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	898080e7          	jalr	-1896(ra) # 800033a0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b10:	0809a023          	sw	zero,128(s3)
    80003b14:	bf51                	j	80003aa8 <itrunc+0x3e>

0000000080003b16 <iput>:
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	e04a                	sd	s2,0(sp)
    80003b20:	1000                	addi	s0,sp,32
    80003b22:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b24:	0001c517          	auipc	a0,0x1c
    80003b28:	2c450513          	addi	a0,a0,708 # 8001fde8 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	0b8080e7          	jalr	184(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b34:	4498                	lw	a4,8(s1)
    80003b36:	4785                	li	a5,1
    80003b38:	02f70363          	beq	a4,a5,80003b5e <iput+0x48>
  ip->ref--;
    80003b3c:	449c                	lw	a5,8(s1)
    80003b3e:	37fd                	addiw	a5,a5,-1
    80003b40:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	2a650513          	addi	a0,a0,678 # 8001fde8 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
}
    80003b52:	60e2                	ld	ra,24(sp)
    80003b54:	6442                	ld	s0,16(sp)
    80003b56:	64a2                	ld	s1,8(sp)
    80003b58:	6902                	ld	s2,0(sp)
    80003b5a:	6105                	addi	sp,sp,32
    80003b5c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b5e:	40bc                	lw	a5,64(s1)
    80003b60:	dff1                	beqz	a5,80003b3c <iput+0x26>
    80003b62:	04a49783          	lh	a5,74(s1)
    80003b66:	fbf9                	bnez	a5,80003b3c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b68:	01048913          	addi	s2,s1,16
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	00001097          	auipc	ra,0x1
    80003b72:	ab8080e7          	jalr	-1352(ra) # 80004626 <acquiresleep>
    release(&itable.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	27250513          	addi	a0,a0,626 # 8001fde8 <itable>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	11a080e7          	jalr	282(ra) # 80000c98 <release>
    itrunc(ip);
    80003b86:	8526                	mv	a0,s1
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	ee2080e7          	jalr	-286(ra) # 80003a6a <itrunc>
    ip->type = 0;
    80003b90:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	cfc080e7          	jalr	-772(ra) # 80003892 <iupdate>
    ip->valid = 0;
    80003b9e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	ad8080e7          	jalr	-1320(ra) # 8000467c <releasesleep>
    acquire(&itable.lock);
    80003bac:	0001c517          	auipc	a0,0x1c
    80003bb0:	23c50513          	addi	a0,a0,572 # 8001fde8 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	030080e7          	jalr	48(ra) # 80000be4 <acquire>
    80003bbc:	b741                	j	80003b3c <iput+0x26>

0000000080003bbe <iunlockput>:
{
    80003bbe:	1101                	addi	sp,sp,-32
    80003bc0:	ec06                	sd	ra,24(sp)
    80003bc2:	e822                	sd	s0,16(sp)
    80003bc4:	e426                	sd	s1,8(sp)
    80003bc6:	1000                	addi	s0,sp,32
    80003bc8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	e54080e7          	jalr	-428(ra) # 80003a1e <iunlock>
  iput(ip);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	f42080e7          	jalr	-190(ra) # 80003b16 <iput>
}
    80003bdc:	60e2                	ld	ra,24(sp)
    80003bde:	6442                	ld	s0,16(sp)
    80003be0:	64a2                	ld	s1,8(sp)
    80003be2:	6105                	addi	sp,sp,32
    80003be4:	8082                	ret

0000000080003be6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003be6:	1141                	addi	sp,sp,-16
    80003be8:	e422                	sd	s0,8(sp)
    80003bea:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bec:	411c                	lw	a5,0(a0)
    80003bee:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bf0:	415c                	lw	a5,4(a0)
    80003bf2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bf4:	04451783          	lh	a5,68(a0)
    80003bf8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bfc:	04a51783          	lh	a5,74(a0)
    80003c00:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c04:	04c56783          	lwu	a5,76(a0)
    80003c08:	e99c                	sd	a5,16(a1)
}
    80003c0a:	6422                	ld	s0,8(sp)
    80003c0c:	0141                	addi	sp,sp,16
    80003c0e:	8082                	ret

0000000080003c10 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c10:	457c                	lw	a5,76(a0)
    80003c12:	0ed7e963          	bltu	a5,a3,80003d04 <readi+0xf4>
{
    80003c16:	7159                	addi	sp,sp,-112
    80003c18:	f486                	sd	ra,104(sp)
    80003c1a:	f0a2                	sd	s0,96(sp)
    80003c1c:	eca6                	sd	s1,88(sp)
    80003c1e:	e8ca                	sd	s2,80(sp)
    80003c20:	e4ce                	sd	s3,72(sp)
    80003c22:	e0d2                	sd	s4,64(sp)
    80003c24:	fc56                	sd	s5,56(sp)
    80003c26:	f85a                	sd	s6,48(sp)
    80003c28:	f45e                	sd	s7,40(sp)
    80003c2a:	f062                	sd	s8,32(sp)
    80003c2c:	ec66                	sd	s9,24(sp)
    80003c2e:	e86a                	sd	s10,16(sp)
    80003c30:	e46e                	sd	s11,8(sp)
    80003c32:	1880                	addi	s0,sp,112
    80003c34:	8baa                	mv	s7,a0
    80003c36:	8c2e                	mv	s8,a1
    80003c38:	8ab2                	mv	s5,a2
    80003c3a:	84b6                	mv	s1,a3
    80003c3c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c3e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c40:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c42:	0ad76063          	bltu	a4,a3,80003ce2 <readi+0xd2>
  if(off + n > ip->size)
    80003c46:	00e7f463          	bgeu	a5,a4,80003c4e <readi+0x3e>
    n = ip->size - off;
    80003c4a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c4e:	0a0b0963          	beqz	s6,80003d00 <readi+0xf0>
    80003c52:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c54:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c58:	5cfd                	li	s9,-1
    80003c5a:	a82d                	j	80003c94 <readi+0x84>
    80003c5c:	020a1d93          	slli	s11,s4,0x20
    80003c60:	020ddd93          	srli	s11,s11,0x20
    80003c64:	05890613          	addi	a2,s2,88
    80003c68:	86ee                	mv	a3,s11
    80003c6a:	963a                	add	a2,a2,a4
    80003c6c:	85d6                	mv	a1,s5
    80003c6e:	8562                	mv	a0,s8
    80003c70:	fffff097          	auipc	ra,0xfffff
    80003c74:	acc080e7          	jalr	-1332(ra) # 8000273c <either_copyout>
    80003c78:	05950d63          	beq	a0,s9,80003cd2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	60c080e7          	jalr	1548(ra) # 8000328a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c86:	013a09bb          	addw	s3,s4,s3
    80003c8a:	009a04bb          	addw	s1,s4,s1
    80003c8e:	9aee                	add	s5,s5,s11
    80003c90:	0569f763          	bgeu	s3,s6,80003cde <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c94:	000ba903          	lw	s2,0(s7)
    80003c98:	00a4d59b          	srliw	a1,s1,0xa
    80003c9c:	855e                	mv	a0,s7
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	8b0080e7          	jalr	-1872(ra) # 8000354e <bmap>
    80003ca6:	0005059b          	sext.w	a1,a0
    80003caa:	854a                	mv	a0,s2
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	4ae080e7          	jalr	1198(ra) # 8000315a <bread>
    80003cb4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb6:	3ff4f713          	andi	a4,s1,1023
    80003cba:	40ed07bb          	subw	a5,s10,a4
    80003cbe:	413b06bb          	subw	a3,s6,s3
    80003cc2:	8a3e                	mv	s4,a5
    80003cc4:	2781                	sext.w	a5,a5
    80003cc6:	0006861b          	sext.w	a2,a3
    80003cca:	f8f679e3          	bgeu	a2,a5,80003c5c <readi+0x4c>
    80003cce:	8a36                	mv	s4,a3
    80003cd0:	b771                	j	80003c5c <readi+0x4c>
      brelse(bp);
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	5b6080e7          	jalr	1462(ra) # 8000328a <brelse>
      tot = -1;
    80003cdc:	59fd                	li	s3,-1
  }
  return tot;
    80003cde:	0009851b          	sext.w	a0,s3
}
    80003ce2:	70a6                	ld	ra,104(sp)
    80003ce4:	7406                	ld	s0,96(sp)
    80003ce6:	64e6                	ld	s1,88(sp)
    80003ce8:	6946                	ld	s2,80(sp)
    80003cea:	69a6                	ld	s3,72(sp)
    80003cec:	6a06                	ld	s4,64(sp)
    80003cee:	7ae2                	ld	s5,56(sp)
    80003cf0:	7b42                	ld	s6,48(sp)
    80003cf2:	7ba2                	ld	s7,40(sp)
    80003cf4:	7c02                	ld	s8,32(sp)
    80003cf6:	6ce2                	ld	s9,24(sp)
    80003cf8:	6d42                	ld	s10,16(sp)
    80003cfa:	6da2                	ld	s11,8(sp)
    80003cfc:	6165                	addi	sp,sp,112
    80003cfe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d00:	89da                	mv	s3,s6
    80003d02:	bff1                	j	80003cde <readi+0xce>
    return 0;
    80003d04:	4501                	li	a0,0
}
    80003d06:	8082                	ret

0000000080003d08 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d08:	457c                	lw	a5,76(a0)
    80003d0a:	10d7e863          	bltu	a5,a3,80003e1a <writei+0x112>
{
    80003d0e:	7159                	addi	sp,sp,-112
    80003d10:	f486                	sd	ra,104(sp)
    80003d12:	f0a2                	sd	s0,96(sp)
    80003d14:	eca6                	sd	s1,88(sp)
    80003d16:	e8ca                	sd	s2,80(sp)
    80003d18:	e4ce                	sd	s3,72(sp)
    80003d1a:	e0d2                	sd	s4,64(sp)
    80003d1c:	fc56                	sd	s5,56(sp)
    80003d1e:	f85a                	sd	s6,48(sp)
    80003d20:	f45e                	sd	s7,40(sp)
    80003d22:	f062                	sd	s8,32(sp)
    80003d24:	ec66                	sd	s9,24(sp)
    80003d26:	e86a                	sd	s10,16(sp)
    80003d28:	e46e                	sd	s11,8(sp)
    80003d2a:	1880                	addi	s0,sp,112
    80003d2c:	8b2a                	mv	s6,a0
    80003d2e:	8c2e                	mv	s8,a1
    80003d30:	8ab2                	mv	s5,a2
    80003d32:	8936                	mv	s2,a3
    80003d34:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d36:	00e687bb          	addw	a5,a3,a4
    80003d3a:	0ed7e263          	bltu	a5,a3,80003e1e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d3e:	00043737          	lui	a4,0x43
    80003d42:	0ef76063          	bltu	a4,a5,80003e22 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d46:	0c0b8863          	beqz	s7,80003e16 <writei+0x10e>
    80003d4a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d50:	5cfd                	li	s9,-1
    80003d52:	a091                	j	80003d96 <writei+0x8e>
    80003d54:	02099d93          	slli	s11,s3,0x20
    80003d58:	020ddd93          	srli	s11,s11,0x20
    80003d5c:	05848513          	addi	a0,s1,88
    80003d60:	86ee                	mv	a3,s11
    80003d62:	8656                	mv	a2,s5
    80003d64:	85e2                	mv	a1,s8
    80003d66:	953a                	add	a0,a0,a4
    80003d68:	fffff097          	auipc	ra,0xfffff
    80003d6c:	a2a080e7          	jalr	-1494(ra) # 80002792 <either_copyin>
    80003d70:	07950263          	beq	a0,s9,80003dd4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d74:	8526                	mv	a0,s1
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	790080e7          	jalr	1936(ra) # 80004506 <log_write>
    brelse(bp);
    80003d7e:	8526                	mv	a0,s1
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	50a080e7          	jalr	1290(ra) # 8000328a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d88:	01498a3b          	addw	s4,s3,s4
    80003d8c:	0129893b          	addw	s2,s3,s2
    80003d90:	9aee                	add	s5,s5,s11
    80003d92:	057a7663          	bgeu	s4,s7,80003dde <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d96:	000b2483          	lw	s1,0(s6)
    80003d9a:	00a9559b          	srliw	a1,s2,0xa
    80003d9e:	855a                	mv	a0,s6
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	7ae080e7          	jalr	1966(ra) # 8000354e <bmap>
    80003da8:	0005059b          	sext.w	a1,a0
    80003dac:	8526                	mv	a0,s1
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	3ac080e7          	jalr	940(ra) # 8000315a <bread>
    80003db6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db8:	3ff97713          	andi	a4,s2,1023
    80003dbc:	40ed07bb          	subw	a5,s10,a4
    80003dc0:	414b86bb          	subw	a3,s7,s4
    80003dc4:	89be                	mv	s3,a5
    80003dc6:	2781                	sext.w	a5,a5
    80003dc8:	0006861b          	sext.w	a2,a3
    80003dcc:	f8f674e3          	bgeu	a2,a5,80003d54 <writei+0x4c>
    80003dd0:	89b6                	mv	s3,a3
    80003dd2:	b749                	j	80003d54 <writei+0x4c>
      brelse(bp);
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	4b4080e7          	jalr	1204(ra) # 8000328a <brelse>
  }

  if(off > ip->size)
    80003dde:	04cb2783          	lw	a5,76(s6)
    80003de2:	0127f463          	bgeu	a5,s2,80003dea <writei+0xe2>
    ip->size = off;
    80003de6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dea:	855a                	mv	a0,s6
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	aa6080e7          	jalr	-1370(ra) # 80003892 <iupdate>

  return tot;
    80003df4:	000a051b          	sext.w	a0,s4
}
    80003df8:	70a6                	ld	ra,104(sp)
    80003dfa:	7406                	ld	s0,96(sp)
    80003dfc:	64e6                	ld	s1,88(sp)
    80003dfe:	6946                	ld	s2,80(sp)
    80003e00:	69a6                	ld	s3,72(sp)
    80003e02:	6a06                	ld	s4,64(sp)
    80003e04:	7ae2                	ld	s5,56(sp)
    80003e06:	7b42                	ld	s6,48(sp)
    80003e08:	7ba2                	ld	s7,40(sp)
    80003e0a:	7c02                	ld	s8,32(sp)
    80003e0c:	6ce2                	ld	s9,24(sp)
    80003e0e:	6d42                	ld	s10,16(sp)
    80003e10:	6da2                	ld	s11,8(sp)
    80003e12:	6165                	addi	sp,sp,112
    80003e14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e16:	8a5e                	mv	s4,s7
    80003e18:	bfc9                	j	80003dea <writei+0xe2>
    return -1;
    80003e1a:	557d                	li	a0,-1
}
    80003e1c:	8082                	ret
    return -1;
    80003e1e:	557d                	li	a0,-1
    80003e20:	bfe1                	j	80003df8 <writei+0xf0>
    return -1;
    80003e22:	557d                	li	a0,-1
    80003e24:	bfd1                	j	80003df8 <writei+0xf0>

0000000080003e26 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e26:	1141                	addi	sp,sp,-16
    80003e28:	e406                	sd	ra,8(sp)
    80003e2a:	e022                	sd	s0,0(sp)
    80003e2c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e2e:	4639                	li	a2,14
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	f88080e7          	jalr	-120(ra) # 80000db8 <strncmp>
}
    80003e38:	60a2                	ld	ra,8(sp)
    80003e3a:	6402                	ld	s0,0(sp)
    80003e3c:	0141                	addi	sp,sp,16
    80003e3e:	8082                	ret

0000000080003e40 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e40:	7139                	addi	sp,sp,-64
    80003e42:	fc06                	sd	ra,56(sp)
    80003e44:	f822                	sd	s0,48(sp)
    80003e46:	f426                	sd	s1,40(sp)
    80003e48:	f04a                	sd	s2,32(sp)
    80003e4a:	ec4e                	sd	s3,24(sp)
    80003e4c:	e852                	sd	s4,16(sp)
    80003e4e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e50:	04451703          	lh	a4,68(a0)
    80003e54:	4785                	li	a5,1
    80003e56:	00f71a63          	bne	a4,a5,80003e6a <dirlookup+0x2a>
    80003e5a:	892a                	mv	s2,a0
    80003e5c:	89ae                	mv	s3,a1
    80003e5e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	457c                	lw	a5,76(a0)
    80003e62:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e64:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e66:	e79d                	bnez	a5,80003e94 <dirlookup+0x54>
    80003e68:	a8a5                	j	80003ee0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e6a:	00005517          	auipc	a0,0x5
    80003e6e:	83650513          	addi	a0,a0,-1994 # 800086a0 <syscalls+0x1b8>
    80003e72:	ffffc097          	auipc	ra,0xffffc
    80003e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	83e50513          	addi	a0,a0,-1986 # 800086b8 <syscalls+0x1d0>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6bc080e7          	jalr	1724(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8a:	24c1                	addiw	s1,s1,16
    80003e8c:	04c92783          	lw	a5,76(s2)
    80003e90:	04f4f763          	bgeu	s1,a5,80003ede <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e94:	4741                	li	a4,16
    80003e96:	86a6                	mv	a3,s1
    80003e98:	fc040613          	addi	a2,s0,-64
    80003e9c:	4581                	li	a1,0
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	d70080e7          	jalr	-656(ra) # 80003c10 <readi>
    80003ea8:	47c1                	li	a5,16
    80003eaa:	fcf518e3          	bne	a0,a5,80003e7a <dirlookup+0x3a>
    if(de.inum == 0)
    80003eae:	fc045783          	lhu	a5,-64(s0)
    80003eb2:	dfe1                	beqz	a5,80003e8a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eb4:	fc240593          	addi	a1,s0,-62
    80003eb8:	854e                	mv	a0,s3
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	f6c080e7          	jalr	-148(ra) # 80003e26 <namecmp>
    80003ec2:	f561                	bnez	a0,80003e8a <dirlookup+0x4a>
      if(poff)
    80003ec4:	000a0463          	beqz	s4,80003ecc <dirlookup+0x8c>
        *poff = off;
    80003ec8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ecc:	fc045583          	lhu	a1,-64(s0)
    80003ed0:	00092503          	lw	a0,0(s2)
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	754080e7          	jalr	1876(ra) # 80003628 <iget>
    80003edc:	a011                	j	80003ee0 <dirlookup+0xa0>
  return 0;
    80003ede:	4501                	li	a0,0
}
    80003ee0:	70e2                	ld	ra,56(sp)
    80003ee2:	7442                	ld	s0,48(sp)
    80003ee4:	74a2                	ld	s1,40(sp)
    80003ee6:	7902                	ld	s2,32(sp)
    80003ee8:	69e2                	ld	s3,24(sp)
    80003eea:	6a42                	ld	s4,16(sp)
    80003eec:	6121                	addi	sp,sp,64
    80003eee:	8082                	ret

0000000080003ef0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ef0:	711d                	addi	sp,sp,-96
    80003ef2:	ec86                	sd	ra,88(sp)
    80003ef4:	e8a2                	sd	s0,80(sp)
    80003ef6:	e4a6                	sd	s1,72(sp)
    80003ef8:	e0ca                	sd	s2,64(sp)
    80003efa:	fc4e                	sd	s3,56(sp)
    80003efc:	f852                	sd	s4,48(sp)
    80003efe:	f456                	sd	s5,40(sp)
    80003f00:	f05a                	sd	s6,32(sp)
    80003f02:	ec5e                	sd	s7,24(sp)
    80003f04:	e862                	sd	s8,16(sp)
    80003f06:	e466                	sd	s9,8(sp)
    80003f08:	1080                	addi	s0,sp,96
    80003f0a:	84aa                	mv	s1,a0
    80003f0c:	8b2e                	mv	s6,a1
    80003f0e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f10:	00054703          	lbu	a4,0(a0)
    80003f14:	02f00793          	li	a5,47
    80003f18:	02f70363          	beq	a4,a5,80003f3e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f1c:	ffffe097          	auipc	ra,0xffffe
    80003f20:	d72080e7          	jalr	-654(ra) # 80001c8e <myproc>
    80003f24:	16853503          	ld	a0,360(a0)
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	9f6080e7          	jalr	-1546(ra) # 8000391e <idup>
    80003f30:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f32:	02f00913          	li	s2,47
  len = path - s;
    80003f36:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f38:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f3a:	4c05                	li	s8,1
    80003f3c:	a865                	j	80003ff4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f3e:	4585                	li	a1,1
    80003f40:	4505                	li	a0,1
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	6e6080e7          	jalr	1766(ra) # 80003628 <iget>
    80003f4a:	89aa                	mv	s3,a0
    80003f4c:	b7dd                	j	80003f32 <namex+0x42>
      iunlockput(ip);
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	c6e080e7          	jalr	-914(ra) # 80003bbe <iunlockput>
      return 0;
    80003f58:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	60e6                	ld	ra,88(sp)
    80003f5e:	6446                	ld	s0,80(sp)
    80003f60:	64a6                	ld	s1,72(sp)
    80003f62:	6906                	ld	s2,64(sp)
    80003f64:	79e2                	ld	s3,56(sp)
    80003f66:	7a42                	ld	s4,48(sp)
    80003f68:	7aa2                	ld	s5,40(sp)
    80003f6a:	7b02                	ld	s6,32(sp)
    80003f6c:	6be2                	ld	s7,24(sp)
    80003f6e:	6c42                	ld	s8,16(sp)
    80003f70:	6ca2                	ld	s9,8(sp)
    80003f72:	6125                	addi	sp,sp,96
    80003f74:	8082                	ret
      iunlock(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	aa6080e7          	jalr	-1370(ra) # 80003a1e <iunlock>
      return ip;
    80003f80:	bfe9                	j	80003f5a <namex+0x6a>
      iunlockput(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	c3a080e7          	jalr	-966(ra) # 80003bbe <iunlockput>
      return 0;
    80003f8c:	89d2                	mv	s3,s4
    80003f8e:	b7f1                	j	80003f5a <namex+0x6a>
  len = path - s;
    80003f90:	40b48633          	sub	a2,s1,a1
    80003f94:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f98:	094cd463          	bge	s9,s4,80004020 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f9c:	4639                	li	a2,14
    80003f9e:	8556                	mv	a0,s5
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	da0080e7          	jalr	-608(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fa8:	0004c783          	lbu	a5,0(s1)
    80003fac:	01279763          	bne	a5,s2,80003fba <namex+0xca>
    path++;
    80003fb0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb2:	0004c783          	lbu	a5,0(s1)
    80003fb6:	ff278de3          	beq	a5,s2,80003fb0 <namex+0xc0>
    ilock(ip);
    80003fba:	854e                	mv	a0,s3
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	9a0080e7          	jalr	-1632(ra) # 8000395c <ilock>
    if(ip->type != T_DIR){
    80003fc4:	04499783          	lh	a5,68(s3)
    80003fc8:	f98793e3          	bne	a5,s8,80003f4e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fcc:	000b0563          	beqz	s6,80003fd6 <namex+0xe6>
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	d3cd                	beqz	a5,80003f76 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fd6:	865e                	mv	a2,s7
    80003fd8:	85d6                	mv	a1,s5
    80003fda:	854e                	mv	a0,s3
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	e64080e7          	jalr	-412(ra) # 80003e40 <dirlookup>
    80003fe4:	8a2a                	mv	s4,a0
    80003fe6:	dd51                	beqz	a0,80003f82 <namex+0x92>
    iunlockput(ip);
    80003fe8:	854e                	mv	a0,s3
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	bd4080e7          	jalr	-1068(ra) # 80003bbe <iunlockput>
    ip = next;
    80003ff2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ff4:	0004c783          	lbu	a5,0(s1)
    80003ff8:	05279763          	bne	a5,s2,80004046 <namex+0x156>
    path++;
    80003ffc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ffe:	0004c783          	lbu	a5,0(s1)
    80004002:	ff278de3          	beq	a5,s2,80003ffc <namex+0x10c>
  if(*path == 0)
    80004006:	c79d                	beqz	a5,80004034 <namex+0x144>
    path++;
    80004008:	85a6                	mv	a1,s1
  len = path - s;
    8000400a:	8a5e                	mv	s4,s7
    8000400c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000400e:	01278963          	beq	a5,s2,80004020 <namex+0x130>
    80004012:	dfbd                	beqz	a5,80003f90 <namex+0xa0>
    path++;
    80004014:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004016:	0004c783          	lbu	a5,0(s1)
    8000401a:	ff279ce3          	bne	a5,s2,80004012 <namex+0x122>
    8000401e:	bf8d                	j	80003f90 <namex+0xa0>
    memmove(name, s, len);
    80004020:	2601                	sext.w	a2,a2
    80004022:	8556                	mv	a0,s5
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	d1c080e7          	jalr	-740(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000402c:	9a56                	add	s4,s4,s5
    8000402e:	000a0023          	sb	zero,0(s4)
    80004032:	bf9d                	j	80003fa8 <namex+0xb8>
  if(nameiparent){
    80004034:	f20b03e3          	beqz	s6,80003f5a <namex+0x6a>
    iput(ip);
    80004038:	854e                	mv	a0,s3
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	adc080e7          	jalr	-1316(ra) # 80003b16 <iput>
    return 0;
    80004042:	4981                	li	s3,0
    80004044:	bf19                	j	80003f5a <namex+0x6a>
  if(*path == 0)
    80004046:	d7fd                	beqz	a5,80004034 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004048:	0004c783          	lbu	a5,0(s1)
    8000404c:	85a6                	mv	a1,s1
    8000404e:	b7d1                	j	80004012 <namex+0x122>

0000000080004050 <dirlink>:
{
    80004050:	7139                	addi	sp,sp,-64
    80004052:	fc06                	sd	ra,56(sp)
    80004054:	f822                	sd	s0,48(sp)
    80004056:	f426                	sd	s1,40(sp)
    80004058:	f04a                	sd	s2,32(sp)
    8000405a:	ec4e                	sd	s3,24(sp)
    8000405c:	e852                	sd	s4,16(sp)
    8000405e:	0080                	addi	s0,sp,64
    80004060:	892a                	mv	s2,a0
    80004062:	8a2e                	mv	s4,a1
    80004064:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004066:	4601                	li	a2,0
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	dd8080e7          	jalr	-552(ra) # 80003e40 <dirlookup>
    80004070:	e93d                	bnez	a0,800040e6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004072:	04c92483          	lw	s1,76(s2)
    80004076:	c49d                	beqz	s1,800040a4 <dirlink+0x54>
    80004078:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000407a:	4741                	li	a4,16
    8000407c:	86a6                	mv	a3,s1
    8000407e:	fc040613          	addi	a2,s0,-64
    80004082:	4581                	li	a1,0
    80004084:	854a                	mv	a0,s2
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	b8a080e7          	jalr	-1142(ra) # 80003c10 <readi>
    8000408e:	47c1                	li	a5,16
    80004090:	06f51163          	bne	a0,a5,800040f2 <dirlink+0xa2>
    if(de.inum == 0)
    80004094:	fc045783          	lhu	a5,-64(s0)
    80004098:	c791                	beqz	a5,800040a4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409a:	24c1                	addiw	s1,s1,16
    8000409c:	04c92783          	lw	a5,76(s2)
    800040a0:	fcf4ede3          	bltu	s1,a5,8000407a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040a4:	4639                	li	a2,14
    800040a6:	85d2                	mv	a1,s4
    800040a8:	fc240513          	addi	a0,s0,-62
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	d48080e7          	jalr	-696(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040b4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b8:	4741                	li	a4,16
    800040ba:	86a6                	mv	a3,s1
    800040bc:	fc040613          	addi	a2,s0,-64
    800040c0:	4581                	li	a1,0
    800040c2:	854a                	mv	a0,s2
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	c44080e7          	jalr	-956(ra) # 80003d08 <writei>
    800040cc:	872a                	mv	a4,a0
    800040ce:	47c1                	li	a5,16
  return 0;
    800040d0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d2:	02f71863          	bne	a4,a5,80004102 <dirlink+0xb2>
}
    800040d6:	70e2                	ld	ra,56(sp)
    800040d8:	7442                	ld	s0,48(sp)
    800040da:	74a2                	ld	s1,40(sp)
    800040dc:	7902                	ld	s2,32(sp)
    800040de:	69e2                	ld	s3,24(sp)
    800040e0:	6a42                	ld	s4,16(sp)
    800040e2:	6121                	addi	sp,sp,64
    800040e4:	8082                	ret
    iput(ip);
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	a30080e7          	jalr	-1488(ra) # 80003b16 <iput>
    return -1;
    800040ee:	557d                	li	a0,-1
    800040f0:	b7dd                	j	800040d6 <dirlink+0x86>
      panic("dirlink read");
    800040f2:	00004517          	auipc	a0,0x4
    800040f6:	5d650513          	addi	a0,a0,1494 # 800086c8 <syscalls+0x1e0>
    800040fa:	ffffc097          	auipc	ra,0xffffc
    800040fe:	444080e7          	jalr	1092(ra) # 8000053e <panic>
    panic("dirlink");
    80004102:	00004517          	auipc	a0,0x4
    80004106:	6d650513          	addi	a0,a0,1750 # 800087d8 <syscalls+0x2f0>
    8000410a:	ffffc097          	auipc	ra,0xffffc
    8000410e:	434080e7          	jalr	1076(ra) # 8000053e <panic>

0000000080004112 <namei>:

struct inode*
namei(char *path)
{
    80004112:	1101                	addi	sp,sp,-32
    80004114:	ec06                	sd	ra,24(sp)
    80004116:	e822                	sd	s0,16(sp)
    80004118:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000411a:	fe040613          	addi	a2,s0,-32
    8000411e:	4581                	li	a1,0
    80004120:	00000097          	auipc	ra,0x0
    80004124:	dd0080e7          	jalr	-560(ra) # 80003ef0 <namex>
}
    80004128:	60e2                	ld	ra,24(sp)
    8000412a:	6442                	ld	s0,16(sp)
    8000412c:	6105                	addi	sp,sp,32
    8000412e:	8082                	ret

0000000080004130 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004130:	1141                	addi	sp,sp,-16
    80004132:	e406                	sd	ra,8(sp)
    80004134:	e022                	sd	s0,0(sp)
    80004136:	0800                	addi	s0,sp,16
    80004138:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000413a:	4585                	li	a1,1
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	db4080e7          	jalr	-588(ra) # 80003ef0 <namex>
}
    80004144:	60a2                	ld	ra,8(sp)
    80004146:	6402                	ld	s0,0(sp)
    80004148:	0141                	addi	sp,sp,16
    8000414a:	8082                	ret

000000008000414c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000414c:	1101                	addi	sp,sp,-32
    8000414e:	ec06                	sd	ra,24(sp)
    80004150:	e822                	sd	s0,16(sp)
    80004152:	e426                	sd	s1,8(sp)
    80004154:	e04a                	sd	s2,0(sp)
    80004156:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004158:	0001d917          	auipc	s2,0x1d
    8000415c:	73890913          	addi	s2,s2,1848 # 80021890 <log>
    80004160:	01892583          	lw	a1,24(s2)
    80004164:	02892503          	lw	a0,40(s2)
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	ff2080e7          	jalr	-14(ra) # 8000315a <bread>
    80004170:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004172:	02c92683          	lw	a3,44(s2)
    80004176:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004178:	02d05763          	blez	a3,800041a6 <write_head+0x5a>
    8000417c:	0001d797          	auipc	a5,0x1d
    80004180:	74478793          	addi	a5,a5,1860 # 800218c0 <log+0x30>
    80004184:	05c50713          	addi	a4,a0,92
    80004188:	36fd                	addiw	a3,a3,-1
    8000418a:	1682                	slli	a3,a3,0x20
    8000418c:	9281                	srli	a3,a3,0x20
    8000418e:	068a                	slli	a3,a3,0x2
    80004190:	0001d617          	auipc	a2,0x1d
    80004194:	73460613          	addi	a2,a2,1844 # 800218c4 <log+0x34>
    80004198:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000419a:	4390                	lw	a2,0(a5)
    8000419c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000419e:	0791                	addi	a5,a5,4
    800041a0:	0711                	addi	a4,a4,4
    800041a2:	fed79ce3          	bne	a5,a3,8000419a <write_head+0x4e>
  }
  bwrite(buf);
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	0a4080e7          	jalr	164(ra) # 8000324c <bwrite>
  brelse(buf);
    800041b0:	8526                	mv	a0,s1
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	0d8080e7          	jalr	216(ra) # 8000328a <brelse>
}
    800041ba:	60e2                	ld	ra,24(sp)
    800041bc:	6442                	ld	s0,16(sp)
    800041be:	64a2                	ld	s1,8(sp)
    800041c0:	6902                	ld	s2,0(sp)
    800041c2:	6105                	addi	sp,sp,32
    800041c4:	8082                	ret

00000000800041c6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c6:	0001d797          	auipc	a5,0x1d
    800041ca:	6f67a783          	lw	a5,1782(a5) # 800218bc <log+0x2c>
    800041ce:	0af05d63          	blez	a5,80004288 <install_trans+0xc2>
{
    800041d2:	7139                	addi	sp,sp,-64
    800041d4:	fc06                	sd	ra,56(sp)
    800041d6:	f822                	sd	s0,48(sp)
    800041d8:	f426                	sd	s1,40(sp)
    800041da:	f04a                	sd	s2,32(sp)
    800041dc:	ec4e                	sd	s3,24(sp)
    800041de:	e852                	sd	s4,16(sp)
    800041e0:	e456                	sd	s5,8(sp)
    800041e2:	e05a                	sd	s6,0(sp)
    800041e4:	0080                	addi	s0,sp,64
    800041e6:	8b2a                	mv	s6,a0
    800041e8:	0001da97          	auipc	s5,0x1d
    800041ec:	6d8a8a93          	addi	s5,s5,1752 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f2:	0001d997          	auipc	s3,0x1d
    800041f6:	69e98993          	addi	s3,s3,1694 # 80021890 <log>
    800041fa:	a035                	j	80004226 <install_trans+0x60>
      bunpin(dbuf);
    800041fc:	8526                	mv	a0,s1
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	166080e7          	jalr	358(ra) # 80003364 <bunpin>
    brelse(lbuf);
    80004206:	854a                	mv	a0,s2
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	082080e7          	jalr	130(ra) # 8000328a <brelse>
    brelse(dbuf);
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	078080e7          	jalr	120(ra) # 8000328a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421a:	2a05                	addiw	s4,s4,1
    8000421c:	0a91                	addi	s5,s5,4
    8000421e:	02c9a783          	lw	a5,44(s3)
    80004222:	04fa5963          	bge	s4,a5,80004274 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004226:	0189a583          	lw	a1,24(s3)
    8000422a:	014585bb          	addw	a1,a1,s4
    8000422e:	2585                	addiw	a1,a1,1
    80004230:	0289a503          	lw	a0,40(s3)
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	f26080e7          	jalr	-218(ra) # 8000315a <bread>
    8000423c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000423e:	000aa583          	lw	a1,0(s5)
    80004242:	0289a503          	lw	a0,40(s3)
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	f14080e7          	jalr	-236(ra) # 8000315a <bread>
    8000424e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004250:	40000613          	li	a2,1024
    80004254:	05890593          	addi	a1,s2,88
    80004258:	05850513          	addi	a0,a0,88
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	ae4080e7          	jalr	-1308(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	fe6080e7          	jalr	-26(ra) # 8000324c <bwrite>
    if(recovering == 0)
    8000426e:	f80b1ce3          	bnez	s6,80004206 <install_trans+0x40>
    80004272:	b769                	j	800041fc <install_trans+0x36>
}
    80004274:	70e2                	ld	ra,56(sp)
    80004276:	7442                	ld	s0,48(sp)
    80004278:	74a2                	ld	s1,40(sp)
    8000427a:	7902                	ld	s2,32(sp)
    8000427c:	69e2                	ld	s3,24(sp)
    8000427e:	6a42                	ld	s4,16(sp)
    80004280:	6aa2                	ld	s5,8(sp)
    80004282:	6b02                	ld	s6,0(sp)
    80004284:	6121                	addi	sp,sp,64
    80004286:	8082                	ret
    80004288:	8082                	ret

000000008000428a <initlog>:
{
    8000428a:	7179                	addi	sp,sp,-48
    8000428c:	f406                	sd	ra,40(sp)
    8000428e:	f022                	sd	s0,32(sp)
    80004290:	ec26                	sd	s1,24(sp)
    80004292:	e84a                	sd	s2,16(sp)
    80004294:	e44e                	sd	s3,8(sp)
    80004296:	1800                	addi	s0,sp,48
    80004298:	892a                	mv	s2,a0
    8000429a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000429c:	0001d497          	auipc	s1,0x1d
    800042a0:	5f448493          	addi	s1,s1,1524 # 80021890 <log>
    800042a4:	00004597          	auipc	a1,0x4
    800042a8:	43458593          	addi	a1,a1,1076 # 800086d8 <syscalls+0x1f0>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	8a6080e7          	jalr	-1882(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042b6:	0149a583          	lw	a1,20(s3)
    800042ba:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042bc:	0109a783          	lw	a5,16(s3)
    800042c0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042c2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042c6:	854a                	mv	a0,s2
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	e92080e7          	jalr	-366(ra) # 8000315a <bread>
  log.lh.n = lh->n;
    800042d0:	4d3c                	lw	a5,88(a0)
    800042d2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042d4:	02f05563          	blez	a5,800042fe <initlog+0x74>
    800042d8:	05c50713          	addi	a4,a0,92
    800042dc:	0001d697          	auipc	a3,0x1d
    800042e0:	5e468693          	addi	a3,a3,1508 # 800218c0 <log+0x30>
    800042e4:	37fd                	addiw	a5,a5,-1
    800042e6:	1782                	slli	a5,a5,0x20
    800042e8:	9381                	srli	a5,a5,0x20
    800042ea:	078a                	slli	a5,a5,0x2
    800042ec:	06050613          	addi	a2,a0,96
    800042f0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042f2:	4310                	lw	a2,0(a4)
    800042f4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042f6:	0711                	addi	a4,a4,4
    800042f8:	0691                	addi	a3,a3,4
    800042fa:	fef71ce3          	bne	a4,a5,800042f2 <initlog+0x68>
  brelse(buf);
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	f8c080e7          	jalr	-116(ra) # 8000328a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004306:	4505                	li	a0,1
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	ebe080e7          	jalr	-322(ra) # 800041c6 <install_trans>
  log.lh.n = 0;
    80004310:	0001d797          	auipc	a5,0x1d
    80004314:	5a07a623          	sw	zero,1452(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	e34080e7          	jalr	-460(ra) # 8000414c <write_head>
}
    80004320:	70a2                	ld	ra,40(sp)
    80004322:	7402                	ld	s0,32(sp)
    80004324:	64e2                	ld	s1,24(sp)
    80004326:	6942                	ld	s2,16(sp)
    80004328:	69a2                	ld	s3,8(sp)
    8000432a:	6145                	addi	sp,sp,48
    8000432c:	8082                	ret

000000008000432e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000432e:	1101                	addi	sp,sp,-32
    80004330:	ec06                	sd	ra,24(sp)
    80004332:	e822                	sd	s0,16(sp)
    80004334:	e426                	sd	s1,8(sp)
    80004336:	e04a                	sd	s2,0(sp)
    80004338:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000433a:	0001d517          	auipc	a0,0x1d
    8000433e:	55650513          	addi	a0,a0,1366 # 80021890 <log>
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000434a:	0001d497          	auipc	s1,0x1d
    8000434e:	54648493          	addi	s1,s1,1350 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004352:	4979                	li	s2,30
    80004354:	a039                	j	80004362 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004356:	85a6                	mv	a1,s1
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffe097          	auipc	ra,0xffffe
    8000435e:	fca080e7          	jalr	-54(ra) # 80002324 <sleep>
    if(log.committing){
    80004362:	50dc                	lw	a5,36(s1)
    80004364:	fbed                	bnez	a5,80004356 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004366:	509c                	lw	a5,32(s1)
    80004368:	0017871b          	addiw	a4,a5,1
    8000436c:	0007069b          	sext.w	a3,a4
    80004370:	0027179b          	slliw	a5,a4,0x2
    80004374:	9fb9                	addw	a5,a5,a4
    80004376:	0017979b          	slliw	a5,a5,0x1
    8000437a:	54d8                	lw	a4,44(s1)
    8000437c:	9fb9                	addw	a5,a5,a4
    8000437e:	00f95963          	bge	s2,a5,80004390 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004382:	85a6                	mv	a1,s1
    80004384:	8526                	mv	a0,s1
    80004386:	ffffe097          	auipc	ra,0xffffe
    8000438a:	f9e080e7          	jalr	-98(ra) # 80002324 <sleep>
    8000438e:	bfd1                	j	80004362 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004390:	0001d517          	auipc	a0,0x1d
    80004394:	50050513          	addi	a0,a0,1280 # 80021890 <log>
    80004398:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043a2:	60e2                	ld	ra,24(sp)
    800043a4:	6442                	ld	s0,16(sp)
    800043a6:	64a2                	ld	s1,8(sp)
    800043a8:	6902                	ld	s2,0(sp)
    800043aa:	6105                	addi	sp,sp,32
    800043ac:	8082                	ret

00000000800043ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043ae:	7139                	addi	sp,sp,-64
    800043b0:	fc06                	sd	ra,56(sp)
    800043b2:	f822                	sd	s0,48(sp)
    800043b4:	f426                	sd	s1,40(sp)
    800043b6:	f04a                	sd	s2,32(sp)
    800043b8:	ec4e                	sd	s3,24(sp)
    800043ba:	e852                	sd	s4,16(sp)
    800043bc:	e456                	sd	s5,8(sp)
    800043be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043c0:	0001d497          	auipc	s1,0x1d
    800043c4:	4d048493          	addi	s1,s1,1232 # 80021890 <log>
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043d2:	509c                	lw	a5,32(s1)
    800043d4:	37fd                	addiw	a5,a5,-1
    800043d6:	0007891b          	sext.w	s2,a5
    800043da:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043dc:	50dc                	lw	a5,36(s1)
    800043de:	efb9                	bnez	a5,8000443c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043e0:	06091663          	bnez	s2,8000444c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043e4:	0001d497          	auipc	s1,0x1d
    800043e8:	4ac48493          	addi	s1,s1,1196 # 80021890 <log>
    800043ec:	4785                	li	a5,1
    800043ee:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043fa:	54dc                	lw	a5,44(s1)
    800043fc:	06f04763          	bgtz	a5,8000446a <end_op+0xbc>
    acquire(&log.lock);
    80004400:	0001d497          	auipc	s1,0x1d
    80004404:	49048493          	addi	s1,s1,1168 # 80021890 <log>
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	7da080e7          	jalr	2010(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004412:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004416:	8526                	mv	a0,s1
    80004418:	ffffe097          	auipc	ra,0xffffe
    8000441c:	0b2080e7          	jalr	178(ra) # 800024ca <wakeup>
    release(&log.lock);
    80004420:	8526                	mv	a0,s1
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000442a:	70e2                	ld	ra,56(sp)
    8000442c:	7442                	ld	s0,48(sp)
    8000442e:	74a2                	ld	s1,40(sp)
    80004430:	7902                	ld	s2,32(sp)
    80004432:	69e2                	ld	s3,24(sp)
    80004434:	6a42                	ld	s4,16(sp)
    80004436:	6aa2                	ld	s5,8(sp)
    80004438:	6121                	addi	sp,sp,64
    8000443a:	8082                	ret
    panic("log.committing");
    8000443c:	00004517          	auipc	a0,0x4
    80004440:	2a450513          	addi	a0,a0,676 # 800086e0 <syscalls+0x1f8>
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	0fa080e7          	jalr	250(ra) # 8000053e <panic>
    wakeup(&log);
    8000444c:	0001d497          	auipc	s1,0x1d
    80004450:	44448493          	addi	s1,s1,1092 # 80021890 <log>
    80004454:	8526                	mv	a0,s1
    80004456:	ffffe097          	auipc	ra,0xffffe
    8000445a:	074080e7          	jalr	116(ra) # 800024ca <wakeup>
  release(&log.lock);
    8000445e:	8526                	mv	a0,s1
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
  if(do_commit){
    80004468:	b7c9                	j	8000442a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000446a:	0001da97          	auipc	s5,0x1d
    8000446e:	456a8a93          	addi	s5,s5,1110 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004472:	0001da17          	auipc	s4,0x1d
    80004476:	41ea0a13          	addi	s4,s4,1054 # 80021890 <log>
    8000447a:	018a2583          	lw	a1,24(s4)
    8000447e:	012585bb          	addw	a1,a1,s2
    80004482:	2585                	addiw	a1,a1,1
    80004484:	028a2503          	lw	a0,40(s4)
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	cd2080e7          	jalr	-814(ra) # 8000315a <bread>
    80004490:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004492:	000aa583          	lw	a1,0(s5)
    80004496:	028a2503          	lw	a0,40(s4)
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	cc0080e7          	jalr	-832(ra) # 8000315a <bread>
    800044a2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044a4:	40000613          	li	a2,1024
    800044a8:	05850593          	addi	a1,a0,88
    800044ac:	05848513          	addi	a0,s1,88
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	890080e7          	jalr	-1904(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044b8:	8526                	mv	a0,s1
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	d92080e7          	jalr	-622(ra) # 8000324c <bwrite>
    brelse(from);
    800044c2:	854e                	mv	a0,s3
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	dc6080e7          	jalr	-570(ra) # 8000328a <brelse>
    brelse(to);
    800044cc:	8526                	mv	a0,s1
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	dbc080e7          	jalr	-580(ra) # 8000328a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d6:	2905                	addiw	s2,s2,1
    800044d8:	0a91                	addi	s5,s5,4
    800044da:	02ca2783          	lw	a5,44(s4)
    800044de:	f8f94ee3          	blt	s2,a5,8000447a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	c6a080e7          	jalr	-918(ra) # 8000414c <write_head>
    install_trans(0); // Now install writes to home locations
    800044ea:	4501                	li	a0,0
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	cda080e7          	jalr	-806(ra) # 800041c6 <install_trans>
    log.lh.n = 0;
    800044f4:	0001d797          	auipc	a5,0x1d
    800044f8:	3c07a423          	sw	zero,968(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	c50080e7          	jalr	-944(ra) # 8000414c <write_head>
    80004504:	bdf5                	j	80004400 <end_op+0x52>

0000000080004506 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004506:	1101                	addi	sp,sp,-32
    80004508:	ec06                	sd	ra,24(sp)
    8000450a:	e822                	sd	s0,16(sp)
    8000450c:	e426                	sd	s1,8(sp)
    8000450e:	e04a                	sd	s2,0(sp)
    80004510:	1000                	addi	s0,sp,32
    80004512:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004514:	0001d917          	auipc	s2,0x1d
    80004518:	37c90913          	addi	s2,s2,892 # 80021890 <log>
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6c6080e7          	jalr	1734(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004526:	02c92603          	lw	a2,44(s2)
    8000452a:	47f5                	li	a5,29
    8000452c:	06c7c563          	blt	a5,a2,80004596 <log_write+0x90>
    80004530:	0001d797          	auipc	a5,0x1d
    80004534:	37c7a783          	lw	a5,892(a5) # 800218ac <log+0x1c>
    80004538:	37fd                	addiw	a5,a5,-1
    8000453a:	04f65e63          	bge	a2,a5,80004596 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000453e:	0001d797          	auipc	a5,0x1d
    80004542:	3727a783          	lw	a5,882(a5) # 800218b0 <log+0x20>
    80004546:	06f05063          	blez	a5,800045a6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000454a:	4781                	li	a5,0
    8000454c:	06c05563          	blez	a2,800045b6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004550:	44cc                	lw	a1,12(s1)
    80004552:	0001d717          	auipc	a4,0x1d
    80004556:	36e70713          	addi	a4,a4,878 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000455a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000455c:	4314                	lw	a3,0(a4)
    8000455e:	04b68c63          	beq	a3,a1,800045b6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004562:	2785                	addiw	a5,a5,1
    80004564:	0711                	addi	a4,a4,4
    80004566:	fef61be3          	bne	a2,a5,8000455c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000456a:	0621                	addi	a2,a2,8
    8000456c:	060a                	slli	a2,a2,0x2
    8000456e:	0001d797          	auipc	a5,0x1d
    80004572:	32278793          	addi	a5,a5,802 # 80021890 <log>
    80004576:	963e                	add	a2,a2,a5
    80004578:	44dc                	lw	a5,12(s1)
    8000457a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000457c:	8526                	mv	a0,s1
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	daa080e7          	jalr	-598(ra) # 80003328 <bpin>
    log.lh.n++;
    80004586:	0001d717          	auipc	a4,0x1d
    8000458a:	30a70713          	addi	a4,a4,778 # 80021890 <log>
    8000458e:	575c                	lw	a5,44(a4)
    80004590:	2785                	addiw	a5,a5,1
    80004592:	d75c                	sw	a5,44(a4)
    80004594:	a835                	j	800045d0 <log_write+0xca>
    panic("too big a transaction");
    80004596:	00004517          	auipc	a0,0x4
    8000459a:	15a50513          	addi	a0,a0,346 # 800086f0 <syscalls+0x208>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	fa0080e7          	jalr	-96(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045a6:	00004517          	auipc	a0,0x4
    800045aa:	16250513          	addi	a0,a0,354 # 80008708 <syscalls+0x220>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045b6:	00878713          	addi	a4,a5,8
    800045ba:	00271693          	slli	a3,a4,0x2
    800045be:	0001d717          	auipc	a4,0x1d
    800045c2:	2d270713          	addi	a4,a4,722 # 80021890 <log>
    800045c6:	9736                	add	a4,a4,a3
    800045c8:	44d4                	lw	a3,12(s1)
    800045ca:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045cc:	faf608e3          	beq	a2,a5,8000457c <log_write+0x76>
  }
  release(&log.lock);
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	2c050513          	addi	a0,a0,704 # 80021890 <log>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6c0080e7          	jalr	1728(ra) # 80000c98 <release>
}
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6902                	ld	s2,0(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	e426                	sd	s1,8(sp)
    800045f4:	e04a                	sd	s2,0(sp)
    800045f6:	1000                	addi	s0,sp,32
    800045f8:	84aa                	mv	s1,a0
    800045fa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045fc:	00004597          	auipc	a1,0x4
    80004600:	12c58593          	addi	a1,a1,300 # 80008728 <syscalls+0x240>
    80004604:	0521                	addi	a0,a0,8
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	54e080e7          	jalr	1358(ra) # 80000b54 <initlock>
  lk->name = name;
    8000460e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004612:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004616:	0204a423          	sw	zero,40(s1)
}
    8000461a:	60e2                	ld	ra,24(sp)
    8000461c:	6442                	ld	s0,16(sp)
    8000461e:	64a2                	ld	s1,8(sp)
    80004620:	6902                	ld	s2,0(sp)
    80004622:	6105                	addi	sp,sp,32
    80004624:	8082                	ret

0000000080004626 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004626:	1101                	addi	sp,sp,-32
    80004628:	ec06                	sd	ra,24(sp)
    8000462a:	e822                	sd	s0,16(sp)
    8000462c:	e426                	sd	s1,8(sp)
    8000462e:	e04a                	sd	s2,0(sp)
    80004630:	1000                	addi	s0,sp,32
    80004632:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004634:	00850913          	addi	s2,a0,8
    80004638:	854a                	mv	a0,s2
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	5aa080e7          	jalr	1450(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004642:	409c                	lw	a5,0(s1)
    80004644:	cb89                	beqz	a5,80004656 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004646:	85ca                	mv	a1,s2
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffe097          	auipc	ra,0xffffe
    8000464e:	cda080e7          	jalr	-806(ra) # 80002324 <sleep>
  while (lk->locked) {
    80004652:	409c                	lw	a5,0(s1)
    80004654:	fbed                	bnez	a5,80004646 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004656:	4785                	li	a5,1
    80004658:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000465a:	ffffd097          	auipc	ra,0xffffd
    8000465e:	634080e7          	jalr	1588(ra) # 80001c8e <myproc>
    80004662:	591c                	lw	a5,48(a0)
    80004664:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
}
    80004670:	60e2                	ld	ra,24(sp)
    80004672:	6442                	ld	s0,16(sp)
    80004674:	64a2                	ld	s1,8(sp)
    80004676:	6902                	ld	s2,0(sp)
    80004678:	6105                	addi	sp,sp,32
    8000467a:	8082                	ret

000000008000467c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000467c:	1101                	addi	sp,sp,-32
    8000467e:	ec06                	sd	ra,24(sp)
    80004680:	e822                	sd	s0,16(sp)
    80004682:	e426                	sd	s1,8(sp)
    80004684:	e04a                	sd	s2,0(sp)
    80004686:	1000                	addi	s0,sp,32
    80004688:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000468a:	00850913          	addi	s2,a0,8
    8000468e:	854a                	mv	a0,s2
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004698:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000469c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046a0:	8526                	mv	a0,s1
    800046a2:	ffffe097          	auipc	ra,0xffffe
    800046a6:	e28080e7          	jalr	-472(ra) # 800024ca <wakeup>
  release(&lk->lk);
    800046aa:	854a                	mv	a0,s2
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	5ec080e7          	jalr	1516(ra) # 80000c98 <release>
}
    800046b4:	60e2                	ld	ra,24(sp)
    800046b6:	6442                	ld	s0,16(sp)
    800046b8:	64a2                	ld	s1,8(sp)
    800046ba:	6902                	ld	s2,0(sp)
    800046bc:	6105                	addi	sp,sp,32
    800046be:	8082                	ret

00000000800046c0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046c0:	7179                	addi	sp,sp,-48
    800046c2:	f406                	sd	ra,40(sp)
    800046c4:	f022                	sd	s0,32(sp)
    800046c6:	ec26                	sd	s1,24(sp)
    800046c8:	e84a                	sd	s2,16(sp)
    800046ca:	e44e                	sd	s3,8(sp)
    800046cc:	1800                	addi	s0,sp,48
    800046ce:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046d0:	00850913          	addi	s2,a0,8
    800046d4:	854a                	mv	a0,s2
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	50e080e7          	jalr	1294(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046de:	409c                	lw	a5,0(s1)
    800046e0:	ef99                	bnez	a5,800046fe <holdingsleep+0x3e>
    800046e2:	4481                	li	s1,0
  release(&lk->lk);
    800046e4:	854a                	mv	a0,s2
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
  return r;
}
    800046ee:	8526                	mv	a0,s1
    800046f0:	70a2                	ld	ra,40(sp)
    800046f2:	7402                	ld	s0,32(sp)
    800046f4:	64e2                	ld	s1,24(sp)
    800046f6:	6942                	ld	s2,16(sp)
    800046f8:	69a2                	ld	s3,8(sp)
    800046fa:	6145                	addi	sp,sp,48
    800046fc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fe:	0284a983          	lw	s3,40(s1)
    80004702:	ffffd097          	auipc	ra,0xffffd
    80004706:	58c080e7          	jalr	1420(ra) # 80001c8e <myproc>
    8000470a:	5904                	lw	s1,48(a0)
    8000470c:	413484b3          	sub	s1,s1,s3
    80004710:	0014b493          	seqz	s1,s1
    80004714:	bfc1                	j	800046e4 <holdingsleep+0x24>

0000000080004716 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004716:	1141                	addi	sp,sp,-16
    80004718:	e406                	sd	ra,8(sp)
    8000471a:	e022                	sd	s0,0(sp)
    8000471c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000471e:	00004597          	auipc	a1,0x4
    80004722:	01a58593          	addi	a1,a1,26 # 80008738 <syscalls+0x250>
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	2b250513          	addi	a0,a0,690 # 800219d8 <ftable>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	426080e7          	jalr	1062(ra) # 80000b54 <initlock>
}
    80004736:	60a2                	ld	ra,8(sp)
    80004738:	6402                	ld	s0,0(sp)
    8000473a:	0141                	addi	sp,sp,16
    8000473c:	8082                	ret

000000008000473e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004748:	0001d517          	auipc	a0,0x1d
    8000474c:	29050513          	addi	a0,a0,656 # 800219d8 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	494080e7          	jalr	1172(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004758:	0001d497          	auipc	s1,0x1d
    8000475c:	29848493          	addi	s1,s1,664 # 800219f0 <ftable+0x18>
    80004760:	0001e717          	auipc	a4,0x1e
    80004764:	23070713          	addi	a4,a4,560 # 80022990 <ftable+0xfb8>
    if(f->ref == 0){
    80004768:	40dc                	lw	a5,4(s1)
    8000476a:	cf99                	beqz	a5,80004788 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476c:	02848493          	addi	s1,s1,40
    80004770:	fee49ce3          	bne	s1,a4,80004768 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004774:	0001d517          	auipc	a0,0x1d
    80004778:	26450513          	addi	a0,a0,612 # 800219d8 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	51c080e7          	jalr	1308(ra) # 80000c98 <release>
  return 0;
    80004784:	4481                	li	s1,0
    80004786:	a819                	j	8000479c <filealloc+0x5e>
      f->ref = 1;
    80004788:	4785                	li	a5,1
    8000478a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000478c:	0001d517          	auipc	a0,0x1d
    80004790:	24c50513          	addi	a0,a0,588 # 800219d8 <ftable>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
}
    8000479c:	8526                	mv	a0,s1
    8000479e:	60e2                	ld	ra,24(sp)
    800047a0:	6442                	ld	s0,16(sp)
    800047a2:	64a2                	ld	s1,8(sp)
    800047a4:	6105                	addi	sp,sp,32
    800047a6:	8082                	ret

00000000800047a8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047a8:	1101                	addi	sp,sp,-32
    800047aa:	ec06                	sd	ra,24(sp)
    800047ac:	e822                	sd	s0,16(sp)
    800047ae:	e426                	sd	s1,8(sp)
    800047b0:	1000                	addi	s0,sp,32
    800047b2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047b4:	0001d517          	auipc	a0,0x1d
    800047b8:	22450513          	addi	a0,a0,548 # 800219d8 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047c4:	40dc                	lw	a5,4(s1)
    800047c6:	02f05263          	blez	a5,800047ea <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ca:	2785                	addiw	a5,a5,1
    800047cc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ce:	0001d517          	auipc	a0,0x1d
    800047d2:	20a50513          	addi	a0,a0,522 # 800219d8 <ftable>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
  return f;
}
    800047de:	8526                	mv	a0,s1
    800047e0:	60e2                	ld	ra,24(sp)
    800047e2:	6442                	ld	s0,16(sp)
    800047e4:	64a2                	ld	s1,8(sp)
    800047e6:	6105                	addi	sp,sp,32
    800047e8:	8082                	ret
    panic("filedup");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	f5650513          	addi	a0,a0,-170 # 80008740 <syscalls+0x258>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d4c080e7          	jalr	-692(ra) # 8000053e <panic>

00000000800047fa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047fa:	7139                	addi	sp,sp,-64
    800047fc:	fc06                	sd	ra,56(sp)
    800047fe:	f822                	sd	s0,48(sp)
    80004800:	f426                	sd	s1,40(sp)
    80004802:	f04a                	sd	s2,32(sp)
    80004804:	ec4e                	sd	s3,24(sp)
    80004806:	e852                	sd	s4,16(sp)
    80004808:	e456                	sd	s5,8(sp)
    8000480a:	0080                	addi	s0,sp,64
    8000480c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000480e:	0001d517          	auipc	a0,0x1d
    80004812:	1ca50513          	addi	a0,a0,458 # 800219d8 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	3ce080e7          	jalr	974(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000481e:	40dc                	lw	a5,4(s1)
    80004820:	06f05163          	blez	a5,80004882 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004824:	37fd                	addiw	a5,a5,-1
    80004826:	0007871b          	sext.w	a4,a5
    8000482a:	c0dc                	sw	a5,4(s1)
    8000482c:	06e04363          	bgtz	a4,80004892 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004830:	0004a903          	lw	s2,0(s1)
    80004834:	0094ca83          	lbu	s5,9(s1)
    80004838:	0104ba03          	ld	s4,16(s1)
    8000483c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004840:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004844:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004848:	0001d517          	auipc	a0,0x1d
    8000484c:	19050513          	addi	a0,a0,400 # 800219d8 <ftable>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	448080e7          	jalr	1096(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004858:	4785                	li	a5,1
    8000485a:	04f90d63          	beq	s2,a5,800048b4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000485e:	3979                	addiw	s2,s2,-2
    80004860:	4785                	li	a5,1
    80004862:	0527e063          	bltu	a5,s2,800048a2 <fileclose+0xa8>
    begin_op();
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	ac8080e7          	jalr	-1336(ra) # 8000432e <begin_op>
    iput(ff.ip);
    8000486e:	854e                	mv	a0,s3
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	2a6080e7          	jalr	678(ra) # 80003b16 <iput>
    end_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	b36080e7          	jalr	-1226(ra) # 800043ae <end_op>
    80004880:	a00d                	j	800048a2 <fileclose+0xa8>
    panic("fileclose");
    80004882:	00004517          	auipc	a0,0x4
    80004886:	ec650513          	addi	a0,a0,-314 # 80008748 <syscalls+0x260>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004892:	0001d517          	auipc	a0,0x1d
    80004896:	14650513          	addi	a0,a0,326 # 800219d8 <ftable>
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	3fe080e7          	jalr	1022(ra) # 80000c98 <release>
  }
}
    800048a2:	70e2                	ld	ra,56(sp)
    800048a4:	7442                	ld	s0,48(sp)
    800048a6:	74a2                	ld	s1,40(sp)
    800048a8:	7902                	ld	s2,32(sp)
    800048aa:	69e2                	ld	s3,24(sp)
    800048ac:	6a42                	ld	s4,16(sp)
    800048ae:	6aa2                	ld	s5,8(sp)
    800048b0:	6121                	addi	sp,sp,64
    800048b2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048b4:	85d6                	mv	a1,s5
    800048b6:	8552                	mv	a0,s4
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	34c080e7          	jalr	844(ra) # 80004c04 <pipeclose>
    800048c0:	b7cd                	j	800048a2 <fileclose+0xa8>

00000000800048c2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048c2:	715d                	addi	sp,sp,-80
    800048c4:	e486                	sd	ra,72(sp)
    800048c6:	e0a2                	sd	s0,64(sp)
    800048c8:	fc26                	sd	s1,56(sp)
    800048ca:	f84a                	sd	s2,48(sp)
    800048cc:	f44e                	sd	s3,40(sp)
    800048ce:	0880                	addi	s0,sp,80
    800048d0:	84aa                	mv	s1,a0
    800048d2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048d4:	ffffd097          	auipc	ra,0xffffd
    800048d8:	3ba080e7          	jalr	954(ra) # 80001c8e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048dc:	409c                	lw	a5,0(s1)
    800048de:	37f9                	addiw	a5,a5,-2
    800048e0:	4705                	li	a4,1
    800048e2:	04f76763          	bltu	a4,a5,80004930 <filestat+0x6e>
    800048e6:	892a                	mv	s2,a0
    ilock(f->ip);
    800048e8:	6c88                	ld	a0,24(s1)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	072080e7          	jalr	114(ra) # 8000395c <ilock>
    stati(f->ip, &st);
    800048f2:	fb840593          	addi	a1,s0,-72
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	2ee080e7          	jalr	750(ra) # 80003be6 <stati>
    iunlock(f->ip);
    80004900:	6c88                	ld	a0,24(s1)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	11c080e7          	jalr	284(ra) # 80003a1e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000490a:	46e1                	li	a3,24
    8000490c:	fb840613          	addi	a2,s0,-72
    80004910:	85ce                	mv	a1,s3
    80004912:	06893503          	ld	a0,104(s2)
    80004916:	ffffd097          	auipc	ra,0xffffd
    8000491a:	d5c080e7          	jalr	-676(ra) # 80001672 <copyout>
    8000491e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004922:	60a6                	ld	ra,72(sp)
    80004924:	6406                	ld	s0,64(sp)
    80004926:	74e2                	ld	s1,56(sp)
    80004928:	7942                	ld	s2,48(sp)
    8000492a:	79a2                	ld	s3,40(sp)
    8000492c:	6161                	addi	sp,sp,80
    8000492e:	8082                	ret
  return -1;
    80004930:	557d                	li	a0,-1
    80004932:	bfc5                	j	80004922 <filestat+0x60>

0000000080004934 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004934:	7179                	addi	sp,sp,-48
    80004936:	f406                	sd	ra,40(sp)
    80004938:	f022                	sd	s0,32(sp)
    8000493a:	ec26                	sd	s1,24(sp)
    8000493c:	e84a                	sd	s2,16(sp)
    8000493e:	e44e                	sd	s3,8(sp)
    80004940:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004942:	00854783          	lbu	a5,8(a0)
    80004946:	c3d5                	beqz	a5,800049ea <fileread+0xb6>
    80004948:	84aa                	mv	s1,a0
    8000494a:	89ae                	mv	s3,a1
    8000494c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000494e:	411c                	lw	a5,0(a0)
    80004950:	4705                	li	a4,1
    80004952:	04e78963          	beq	a5,a4,800049a4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004956:	470d                	li	a4,3
    80004958:	04e78d63          	beq	a5,a4,800049b2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495c:	4709                	li	a4,2
    8000495e:	06e79e63          	bne	a5,a4,800049da <fileread+0xa6>
    ilock(f->ip);
    80004962:	6d08                	ld	a0,24(a0)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	ff8080e7          	jalr	-8(ra) # 8000395c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000496c:	874a                	mv	a4,s2
    8000496e:	5094                	lw	a3,32(s1)
    80004970:	864e                	mv	a2,s3
    80004972:	4585                	li	a1,1
    80004974:	6c88                	ld	a0,24(s1)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	29a080e7          	jalr	666(ra) # 80003c10 <readi>
    8000497e:	892a                	mv	s2,a0
    80004980:	00a05563          	blez	a0,8000498a <fileread+0x56>
      f->off += r;
    80004984:	509c                	lw	a5,32(s1)
    80004986:	9fa9                	addw	a5,a5,a0
    80004988:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000498a:	6c88                	ld	a0,24(s1)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	092080e7          	jalr	146(ra) # 80003a1e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004994:	854a                	mv	a0,s2
    80004996:	70a2                	ld	ra,40(sp)
    80004998:	7402                	ld	s0,32(sp)
    8000499a:	64e2                	ld	s1,24(sp)
    8000499c:	6942                	ld	s2,16(sp)
    8000499e:	69a2                	ld	s3,8(sp)
    800049a0:	6145                	addi	sp,sp,48
    800049a2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049a4:	6908                	ld	a0,16(a0)
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	3c8080e7          	jalr	968(ra) # 80004d6e <piperead>
    800049ae:	892a                	mv	s2,a0
    800049b0:	b7d5                	j	80004994 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049b2:	02451783          	lh	a5,36(a0)
    800049b6:	03079693          	slli	a3,a5,0x30
    800049ba:	92c1                	srli	a3,a3,0x30
    800049bc:	4725                	li	a4,9
    800049be:	02d76863          	bltu	a4,a3,800049ee <fileread+0xba>
    800049c2:	0792                	slli	a5,a5,0x4
    800049c4:	0001d717          	auipc	a4,0x1d
    800049c8:	f7470713          	addi	a4,a4,-140 # 80021938 <devsw>
    800049cc:	97ba                	add	a5,a5,a4
    800049ce:	639c                	ld	a5,0(a5)
    800049d0:	c38d                	beqz	a5,800049f2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049d2:	4505                	li	a0,1
    800049d4:	9782                	jalr	a5
    800049d6:	892a                	mv	s2,a0
    800049d8:	bf75                	j	80004994 <fileread+0x60>
    panic("fileread");
    800049da:	00004517          	auipc	a0,0x4
    800049de:	d7e50513          	addi	a0,a0,-642 # 80008758 <syscalls+0x270>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	b5c080e7          	jalr	-1188(ra) # 8000053e <panic>
    return -1;
    800049ea:	597d                	li	s2,-1
    800049ec:	b765                	j	80004994 <fileread+0x60>
      return -1;
    800049ee:	597d                	li	s2,-1
    800049f0:	b755                	j	80004994 <fileread+0x60>
    800049f2:	597d                	li	s2,-1
    800049f4:	b745                	j	80004994 <fileread+0x60>

00000000800049f6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049f6:	715d                	addi	sp,sp,-80
    800049f8:	e486                	sd	ra,72(sp)
    800049fa:	e0a2                	sd	s0,64(sp)
    800049fc:	fc26                	sd	s1,56(sp)
    800049fe:	f84a                	sd	s2,48(sp)
    80004a00:	f44e                	sd	s3,40(sp)
    80004a02:	f052                	sd	s4,32(sp)
    80004a04:	ec56                	sd	s5,24(sp)
    80004a06:	e85a                	sd	s6,16(sp)
    80004a08:	e45e                	sd	s7,8(sp)
    80004a0a:	e062                	sd	s8,0(sp)
    80004a0c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a0e:	00954783          	lbu	a5,9(a0)
    80004a12:	10078663          	beqz	a5,80004b1e <filewrite+0x128>
    80004a16:	892a                	mv	s2,a0
    80004a18:	8aae                	mv	s5,a1
    80004a1a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a1c:	411c                	lw	a5,0(a0)
    80004a1e:	4705                	li	a4,1
    80004a20:	02e78263          	beq	a5,a4,80004a44 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a24:	470d                	li	a4,3
    80004a26:	02e78663          	beq	a5,a4,80004a52 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a2a:	4709                	li	a4,2
    80004a2c:	0ee79163          	bne	a5,a4,80004b0e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a30:	0ac05d63          	blez	a2,80004aea <filewrite+0xf4>
    int i = 0;
    80004a34:	4981                	li	s3,0
    80004a36:	6b05                	lui	s6,0x1
    80004a38:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a3c:	6b85                	lui	s7,0x1
    80004a3e:	c00b8b9b          	addiw	s7,s7,-1024
    80004a42:	a861                	j	80004ada <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a44:	6908                	ld	a0,16(a0)
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	22e080e7          	jalr	558(ra) # 80004c74 <pipewrite>
    80004a4e:	8a2a                	mv	s4,a0
    80004a50:	a045                	j	80004af0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a52:	02451783          	lh	a5,36(a0)
    80004a56:	03079693          	slli	a3,a5,0x30
    80004a5a:	92c1                	srli	a3,a3,0x30
    80004a5c:	4725                	li	a4,9
    80004a5e:	0cd76263          	bltu	a4,a3,80004b22 <filewrite+0x12c>
    80004a62:	0792                	slli	a5,a5,0x4
    80004a64:	0001d717          	auipc	a4,0x1d
    80004a68:	ed470713          	addi	a4,a4,-300 # 80021938 <devsw>
    80004a6c:	97ba                	add	a5,a5,a4
    80004a6e:	679c                	ld	a5,8(a5)
    80004a70:	cbdd                	beqz	a5,80004b26 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a72:	4505                	li	a0,1
    80004a74:	9782                	jalr	a5
    80004a76:	8a2a                	mv	s4,a0
    80004a78:	a8a5                	j	80004af0 <filewrite+0xfa>
    80004a7a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	8b0080e7          	jalr	-1872(ra) # 8000432e <begin_op>
      ilock(f->ip);
    80004a86:	01893503          	ld	a0,24(s2)
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	ed2080e7          	jalr	-302(ra) # 8000395c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a92:	8762                	mv	a4,s8
    80004a94:	02092683          	lw	a3,32(s2)
    80004a98:	01598633          	add	a2,s3,s5
    80004a9c:	4585                	li	a1,1
    80004a9e:	01893503          	ld	a0,24(s2)
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	266080e7          	jalr	614(ra) # 80003d08 <writei>
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	00a05763          	blez	a0,80004aba <filewrite+0xc4>
        f->off += r;
    80004ab0:	02092783          	lw	a5,32(s2)
    80004ab4:	9fa9                	addw	a5,a5,a0
    80004ab6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004aba:	01893503          	ld	a0,24(s2)
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	f60080e7          	jalr	-160(ra) # 80003a1e <iunlock>
      end_op();
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	8e8080e7          	jalr	-1816(ra) # 800043ae <end_op>

      if(r != n1){
    80004ace:	009c1f63          	bne	s8,s1,80004aec <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ad2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ad6:	0149db63          	bge	s3,s4,80004aec <filewrite+0xf6>
      int n1 = n - i;
    80004ada:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ade:	84be                	mv	s1,a5
    80004ae0:	2781                	sext.w	a5,a5
    80004ae2:	f8fb5ce3          	bge	s6,a5,80004a7a <filewrite+0x84>
    80004ae6:	84de                	mv	s1,s7
    80004ae8:	bf49                	j	80004a7a <filewrite+0x84>
    int i = 0;
    80004aea:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004aec:	013a1f63          	bne	s4,s3,80004b0a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004af0:	8552                	mv	a0,s4
    80004af2:	60a6                	ld	ra,72(sp)
    80004af4:	6406                	ld	s0,64(sp)
    80004af6:	74e2                	ld	s1,56(sp)
    80004af8:	7942                	ld	s2,48(sp)
    80004afa:	79a2                	ld	s3,40(sp)
    80004afc:	7a02                	ld	s4,32(sp)
    80004afe:	6ae2                	ld	s5,24(sp)
    80004b00:	6b42                	ld	s6,16(sp)
    80004b02:	6ba2                	ld	s7,8(sp)
    80004b04:	6c02                	ld	s8,0(sp)
    80004b06:	6161                	addi	sp,sp,80
    80004b08:	8082                	ret
    ret = (i == n ? n : -1);
    80004b0a:	5a7d                	li	s4,-1
    80004b0c:	b7d5                	j	80004af0 <filewrite+0xfa>
    panic("filewrite");
    80004b0e:	00004517          	auipc	a0,0x4
    80004b12:	c5a50513          	addi	a0,a0,-934 # 80008768 <syscalls+0x280>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
    return -1;
    80004b1e:	5a7d                	li	s4,-1
    80004b20:	bfc1                	j	80004af0 <filewrite+0xfa>
      return -1;
    80004b22:	5a7d                	li	s4,-1
    80004b24:	b7f1                	j	80004af0 <filewrite+0xfa>
    80004b26:	5a7d                	li	s4,-1
    80004b28:	b7e1                	j	80004af0 <filewrite+0xfa>

0000000080004b2a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b2a:	7179                	addi	sp,sp,-48
    80004b2c:	f406                	sd	ra,40(sp)
    80004b2e:	f022                	sd	s0,32(sp)
    80004b30:	ec26                	sd	s1,24(sp)
    80004b32:	e84a                	sd	s2,16(sp)
    80004b34:	e44e                	sd	s3,8(sp)
    80004b36:	e052                	sd	s4,0(sp)
    80004b38:	1800                	addi	s0,sp,48
    80004b3a:	84aa                	mv	s1,a0
    80004b3c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b3e:	0005b023          	sd	zero,0(a1)
    80004b42:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	bf8080e7          	jalr	-1032(ra) # 8000473e <filealloc>
    80004b4e:	e088                	sd	a0,0(s1)
    80004b50:	c551                	beqz	a0,80004bdc <pipealloc+0xb2>
    80004b52:	00000097          	auipc	ra,0x0
    80004b56:	bec080e7          	jalr	-1044(ra) # 8000473e <filealloc>
    80004b5a:	00aa3023          	sd	a0,0(s4)
    80004b5e:	c92d                	beqz	a0,80004bd0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	f94080e7          	jalr	-108(ra) # 80000af4 <kalloc>
    80004b68:	892a                	mv	s2,a0
    80004b6a:	c125                	beqz	a0,80004bca <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b6c:	4985                	li	s3,1
    80004b6e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b72:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b76:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b7a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b7e:	00004597          	auipc	a1,0x4
    80004b82:	bfa58593          	addi	a1,a1,-1030 # 80008778 <syscalls+0x290>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	fce080e7          	jalr	-50(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b8e:	609c                	ld	a5,0(s1)
    80004b90:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b94:	609c                	ld	a5,0(s1)
    80004b96:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b9a:	609c                	ld	a5,0(s1)
    80004b9c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ba0:	609c                	ld	a5,0(s1)
    80004ba2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ba6:	000a3783          	ld	a5,0(s4)
    80004baa:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bae:	000a3783          	ld	a5,0(s4)
    80004bb2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bb6:	000a3783          	ld	a5,0(s4)
    80004bba:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bbe:	000a3783          	ld	a5,0(s4)
    80004bc2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bc6:	4501                	li	a0,0
    80004bc8:	a025                	j	80004bf0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bca:	6088                	ld	a0,0(s1)
    80004bcc:	e501                	bnez	a0,80004bd4 <pipealloc+0xaa>
    80004bce:	a039                	j	80004bdc <pipealloc+0xb2>
    80004bd0:	6088                	ld	a0,0(s1)
    80004bd2:	c51d                	beqz	a0,80004c00 <pipealloc+0xd6>
    fileclose(*f0);
    80004bd4:	00000097          	auipc	ra,0x0
    80004bd8:	c26080e7          	jalr	-986(ra) # 800047fa <fileclose>
  if(*f1)
    80004bdc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004be0:	557d                	li	a0,-1
  if(*f1)
    80004be2:	c799                	beqz	a5,80004bf0 <pipealloc+0xc6>
    fileclose(*f1);
    80004be4:	853e                	mv	a0,a5
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	c14080e7          	jalr	-1004(ra) # 800047fa <fileclose>
  return -1;
    80004bee:	557d                	li	a0,-1
}
    80004bf0:	70a2                	ld	ra,40(sp)
    80004bf2:	7402                	ld	s0,32(sp)
    80004bf4:	64e2                	ld	s1,24(sp)
    80004bf6:	6942                	ld	s2,16(sp)
    80004bf8:	69a2                	ld	s3,8(sp)
    80004bfa:	6a02                	ld	s4,0(sp)
    80004bfc:	6145                	addi	sp,sp,48
    80004bfe:	8082                	ret
  return -1;
    80004c00:	557d                	li	a0,-1
    80004c02:	b7fd                	j	80004bf0 <pipealloc+0xc6>

0000000080004c04 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c04:	1101                	addi	sp,sp,-32
    80004c06:	ec06                	sd	ra,24(sp)
    80004c08:	e822                	sd	s0,16(sp)
    80004c0a:	e426                	sd	s1,8(sp)
    80004c0c:	e04a                	sd	s2,0(sp)
    80004c0e:	1000                	addi	s0,sp,32
    80004c10:	84aa                	mv	s1,a0
    80004c12:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	fd0080e7          	jalr	-48(ra) # 80000be4 <acquire>
  if(writable){
    80004c1c:	02090d63          	beqz	s2,80004c56 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c20:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c24:	21848513          	addi	a0,s1,536
    80004c28:	ffffe097          	auipc	ra,0xffffe
    80004c2c:	8a2080e7          	jalr	-1886(ra) # 800024ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c30:	2204b783          	ld	a5,544(s1)
    80004c34:	eb95                	bnez	a5,80004c68 <pipeclose+0x64>
    release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	060080e7          	jalr	96(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c40:	8526                	mv	a0,s1
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	db6080e7          	jalr	-586(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c4a:	60e2                	ld	ra,24(sp)
    80004c4c:	6442                	ld	s0,16(sp)
    80004c4e:	64a2                	ld	s1,8(sp)
    80004c50:	6902                	ld	s2,0(sp)
    80004c52:	6105                	addi	sp,sp,32
    80004c54:	8082                	ret
    pi->readopen = 0;
    80004c56:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c5a:	21c48513          	addi	a0,s1,540
    80004c5e:	ffffe097          	auipc	ra,0xffffe
    80004c62:	86c080e7          	jalr	-1940(ra) # 800024ca <wakeup>
    80004c66:	b7e9                	j	80004c30 <pipeclose+0x2c>
    release(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	02e080e7          	jalr	46(ra) # 80000c98 <release>
}
    80004c72:	bfe1                	j	80004c4a <pipeclose+0x46>

0000000080004c74 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c74:	7159                	addi	sp,sp,-112
    80004c76:	f486                	sd	ra,104(sp)
    80004c78:	f0a2                	sd	s0,96(sp)
    80004c7a:	eca6                	sd	s1,88(sp)
    80004c7c:	e8ca                	sd	s2,80(sp)
    80004c7e:	e4ce                	sd	s3,72(sp)
    80004c80:	e0d2                	sd	s4,64(sp)
    80004c82:	fc56                	sd	s5,56(sp)
    80004c84:	f85a                	sd	s6,48(sp)
    80004c86:	f45e                	sd	s7,40(sp)
    80004c88:	f062                	sd	s8,32(sp)
    80004c8a:	ec66                	sd	s9,24(sp)
    80004c8c:	1880                	addi	s0,sp,112
    80004c8e:	84aa                	mv	s1,a0
    80004c90:	8aae                	mv	s5,a1
    80004c92:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	ffa080e7          	jalr	-6(ra) # 80001c8e <myproc>
    80004c9c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f44080e7          	jalr	-188(ra) # 80000be4 <acquire>
  while(i < n){
    80004ca8:	0d405163          	blez	s4,80004d6a <pipewrite+0xf6>
    80004cac:	8ba6                	mv	s7,s1
  int i = 0;
    80004cae:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cb2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cb6:	21c48c13          	addi	s8,s1,540
    80004cba:	a08d                	j	80004d1c <pipewrite+0xa8>
      release(&pi->lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
      return -1;
    80004cc6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cc8:	854a                	mv	a0,s2
    80004cca:	70a6                	ld	ra,104(sp)
    80004ccc:	7406                	ld	s0,96(sp)
    80004cce:	64e6                	ld	s1,88(sp)
    80004cd0:	6946                	ld	s2,80(sp)
    80004cd2:	69a6                	ld	s3,72(sp)
    80004cd4:	6a06                	ld	s4,64(sp)
    80004cd6:	7ae2                	ld	s5,56(sp)
    80004cd8:	7b42                	ld	s6,48(sp)
    80004cda:	7ba2                	ld	s7,40(sp)
    80004cdc:	7c02                	ld	s8,32(sp)
    80004cde:	6ce2                	ld	s9,24(sp)
    80004ce0:	6165                	addi	sp,sp,112
    80004ce2:	8082                	ret
      wakeup(&pi->nread);
    80004ce4:	8566                	mv	a0,s9
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	7e4080e7          	jalr	2020(ra) # 800024ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cee:	85de                	mv	a1,s7
    80004cf0:	8562                	mv	a0,s8
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	632080e7          	jalr	1586(ra) # 80002324 <sleep>
    80004cfa:	a839                	j	80004d18 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cfc:	21c4a783          	lw	a5,540(s1)
    80004d00:	0017871b          	addiw	a4,a5,1
    80004d04:	20e4ae23          	sw	a4,540(s1)
    80004d08:	1ff7f793          	andi	a5,a5,511
    80004d0c:	97a6                	add	a5,a5,s1
    80004d0e:	f9f44703          	lbu	a4,-97(s0)
    80004d12:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d16:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d18:	03495d63          	bge	s2,s4,80004d52 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d1c:	2204a783          	lw	a5,544(s1)
    80004d20:	dfd1                	beqz	a5,80004cbc <pipewrite+0x48>
    80004d22:	0289a783          	lw	a5,40(s3)
    80004d26:	fbd9                	bnez	a5,80004cbc <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d28:	2184a783          	lw	a5,536(s1)
    80004d2c:	21c4a703          	lw	a4,540(s1)
    80004d30:	2007879b          	addiw	a5,a5,512
    80004d34:	faf708e3          	beq	a4,a5,80004ce4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d38:	4685                	li	a3,1
    80004d3a:	01590633          	add	a2,s2,s5
    80004d3e:	f9f40593          	addi	a1,s0,-97
    80004d42:	0689b503          	ld	a0,104(s3)
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	9b8080e7          	jalr	-1608(ra) # 800016fe <copyin>
    80004d4e:	fb6517e3          	bne	a0,s6,80004cfc <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d52:	21848513          	addi	a0,s1,536
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	774080e7          	jalr	1908(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
  return i;
    80004d68:	b785                	j	80004cc8 <pipewrite+0x54>
  int i = 0;
    80004d6a:	4901                	li	s2,0
    80004d6c:	b7dd                	j	80004d52 <pipewrite+0xde>

0000000080004d6e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d6e:	715d                	addi	sp,sp,-80
    80004d70:	e486                	sd	ra,72(sp)
    80004d72:	e0a2                	sd	s0,64(sp)
    80004d74:	fc26                	sd	s1,56(sp)
    80004d76:	f84a                	sd	s2,48(sp)
    80004d78:	f44e                	sd	s3,40(sp)
    80004d7a:	f052                	sd	s4,32(sp)
    80004d7c:	ec56                	sd	s5,24(sp)
    80004d7e:	e85a                	sd	s6,16(sp)
    80004d80:	0880                	addi	s0,sp,80
    80004d82:	84aa                	mv	s1,a0
    80004d84:	892e                	mv	s2,a1
    80004d86:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	f06080e7          	jalr	-250(ra) # 80001c8e <myproc>
    80004d90:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d92:	8b26                	mv	s6,s1
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	e4e080e7          	jalr	-434(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9e:	2184a703          	lw	a4,536(s1)
    80004da2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004da6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004daa:	02f71463          	bne	a4,a5,80004dd2 <piperead+0x64>
    80004dae:	2244a783          	lw	a5,548(s1)
    80004db2:	c385                	beqz	a5,80004dd2 <piperead+0x64>
    if(pr->killed){
    80004db4:	028a2783          	lw	a5,40(s4)
    80004db8:	ebc1                	bnez	a5,80004e48 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dba:	85da                	mv	a1,s6
    80004dbc:	854e                	mv	a0,s3
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	566080e7          	jalr	1382(ra) # 80002324 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc6:	2184a703          	lw	a4,536(s1)
    80004dca:	21c4a783          	lw	a5,540(s1)
    80004dce:	fef700e3          	beq	a4,a5,80004dae <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd2:	09505263          	blez	s5,80004e56 <piperead+0xe8>
    80004dd6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dda:	2184a783          	lw	a5,536(s1)
    80004dde:	21c4a703          	lw	a4,540(s1)
    80004de2:	02f70d63          	beq	a4,a5,80004e1c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004de6:	0017871b          	addiw	a4,a5,1
    80004dea:	20e4ac23          	sw	a4,536(s1)
    80004dee:	1ff7f793          	andi	a5,a5,511
    80004df2:	97a6                	add	a5,a5,s1
    80004df4:	0187c783          	lbu	a5,24(a5)
    80004df8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dfc:	4685                	li	a3,1
    80004dfe:	fbf40613          	addi	a2,s0,-65
    80004e02:	85ca                	mv	a1,s2
    80004e04:	068a3503          	ld	a0,104(s4)
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	86a080e7          	jalr	-1942(ra) # 80001672 <copyout>
    80004e10:	01650663          	beq	a0,s6,80004e1c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e14:	2985                	addiw	s3,s3,1
    80004e16:	0905                	addi	s2,s2,1
    80004e18:	fd3a91e3          	bne	s5,s3,80004dda <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e1c:	21c48513          	addi	a0,s1,540
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	6aa080e7          	jalr	1706(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	e6e080e7          	jalr	-402(ra) # 80000c98 <release>
  return i;
}
    80004e32:	854e                	mv	a0,s3
    80004e34:	60a6                	ld	ra,72(sp)
    80004e36:	6406                	ld	s0,64(sp)
    80004e38:	74e2                	ld	s1,56(sp)
    80004e3a:	7942                	ld	s2,48(sp)
    80004e3c:	79a2                	ld	s3,40(sp)
    80004e3e:	7a02                	ld	s4,32(sp)
    80004e40:	6ae2                	ld	s5,24(sp)
    80004e42:	6b42                	ld	s6,16(sp)
    80004e44:	6161                	addi	sp,sp,80
    80004e46:	8082                	ret
      release(&pi->lock);
    80004e48:	8526                	mv	a0,s1
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	e4e080e7          	jalr	-434(ra) # 80000c98 <release>
      return -1;
    80004e52:	59fd                	li	s3,-1
    80004e54:	bff9                	j	80004e32 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e56:	4981                	li	s3,0
    80004e58:	b7d1                	j	80004e1c <piperead+0xae>

0000000080004e5a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e5a:	df010113          	addi	sp,sp,-528
    80004e5e:	20113423          	sd	ra,520(sp)
    80004e62:	20813023          	sd	s0,512(sp)
    80004e66:	ffa6                	sd	s1,504(sp)
    80004e68:	fbca                	sd	s2,496(sp)
    80004e6a:	f7ce                	sd	s3,488(sp)
    80004e6c:	f3d2                	sd	s4,480(sp)
    80004e6e:	efd6                	sd	s5,472(sp)
    80004e70:	ebda                	sd	s6,464(sp)
    80004e72:	e7de                	sd	s7,456(sp)
    80004e74:	e3e2                	sd	s8,448(sp)
    80004e76:	ff66                	sd	s9,440(sp)
    80004e78:	fb6a                	sd	s10,432(sp)
    80004e7a:	f76e                	sd	s11,424(sp)
    80004e7c:	0c00                	addi	s0,sp,528
    80004e7e:	84aa                	mv	s1,a0
    80004e80:	dea43c23          	sd	a0,-520(s0)
    80004e84:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	e06080e7          	jalr	-506(ra) # 80001c8e <myproc>
    80004e90:	892a                	mv	s2,a0

  begin_op();
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	49c080e7          	jalr	1180(ra) # 8000432e <begin_op>

  if((ip = namei(path)) == 0){
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	276080e7          	jalr	630(ra) # 80004112 <namei>
    80004ea4:	c92d                	beqz	a0,80004f16 <exec+0xbc>
    80004ea6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	ab4080e7          	jalr	-1356(ra) # 8000395c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eb0:	04000713          	li	a4,64
    80004eb4:	4681                	li	a3,0
    80004eb6:	e5040613          	addi	a2,s0,-432
    80004eba:	4581                	li	a1,0
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	d52080e7          	jalr	-686(ra) # 80003c10 <readi>
    80004ec6:	04000793          	li	a5,64
    80004eca:	00f51a63          	bne	a0,a5,80004ede <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ece:	e5042703          	lw	a4,-432(s0)
    80004ed2:	464c47b7          	lui	a5,0x464c4
    80004ed6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eda:	04f70463          	beq	a4,a5,80004f22 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	cde080e7          	jalr	-802(ra) # 80003bbe <iunlockput>
    end_op();
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	4c6080e7          	jalr	1222(ra) # 800043ae <end_op>
  }
  return -1;
    80004ef0:	557d                	li	a0,-1
}
    80004ef2:	20813083          	ld	ra,520(sp)
    80004ef6:	20013403          	ld	s0,512(sp)
    80004efa:	74fe                	ld	s1,504(sp)
    80004efc:	795e                	ld	s2,496(sp)
    80004efe:	79be                	ld	s3,488(sp)
    80004f00:	7a1e                	ld	s4,480(sp)
    80004f02:	6afe                	ld	s5,472(sp)
    80004f04:	6b5e                	ld	s6,464(sp)
    80004f06:	6bbe                	ld	s7,456(sp)
    80004f08:	6c1e                	ld	s8,448(sp)
    80004f0a:	7cfa                	ld	s9,440(sp)
    80004f0c:	7d5a                	ld	s10,432(sp)
    80004f0e:	7dba                	ld	s11,424(sp)
    80004f10:	21010113          	addi	sp,sp,528
    80004f14:	8082                	ret
    end_op();
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	498080e7          	jalr	1176(ra) # 800043ae <end_op>
    return -1;
    80004f1e:	557d                	li	a0,-1
    80004f20:	bfc9                	j	80004ef2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f22:	854a                	mv	a0,s2
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	e2e080e7          	jalr	-466(ra) # 80001d52 <proc_pagetable>
    80004f2c:	8baa                	mv	s7,a0
    80004f2e:	d945                	beqz	a0,80004ede <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f30:	e7042983          	lw	s3,-400(s0)
    80004f34:	e8845783          	lhu	a5,-376(s0)
    80004f38:	c7ad                	beqz	a5,80004fa2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f3a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f3c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f3e:	6c85                	lui	s9,0x1
    80004f40:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f44:	def43823          	sd	a5,-528(s0)
    80004f48:	a42d                	j	80005172 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f4a:	00004517          	auipc	a0,0x4
    80004f4e:	83650513          	addi	a0,a0,-1994 # 80008780 <syscalls+0x298>
    80004f52:	ffffb097          	auipc	ra,0xffffb
    80004f56:	5ec080e7          	jalr	1516(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f5a:	8756                	mv	a4,s5
    80004f5c:	012d86bb          	addw	a3,s11,s2
    80004f60:	4581                	li	a1,0
    80004f62:	8526                	mv	a0,s1
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	cac080e7          	jalr	-852(ra) # 80003c10 <readi>
    80004f6c:	2501                	sext.w	a0,a0
    80004f6e:	1aaa9963          	bne	s5,a0,80005120 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f72:	6785                	lui	a5,0x1
    80004f74:	0127893b          	addw	s2,a5,s2
    80004f78:	77fd                	lui	a5,0xfffff
    80004f7a:	01478a3b          	addw	s4,a5,s4
    80004f7e:	1f897163          	bgeu	s2,s8,80005160 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f82:	02091593          	slli	a1,s2,0x20
    80004f86:	9181                	srli	a1,a1,0x20
    80004f88:	95ea                	add	a1,a1,s10
    80004f8a:	855e                	mv	a0,s7
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	0e2080e7          	jalr	226(ra) # 8000106e <walkaddr>
    80004f94:	862a                	mv	a2,a0
    if(pa == 0)
    80004f96:	d955                	beqz	a0,80004f4a <exec+0xf0>
      n = PGSIZE;
    80004f98:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f9a:	fd9a70e3          	bgeu	s4,s9,80004f5a <exec+0x100>
      n = sz - i;
    80004f9e:	8ad2                	mv	s5,s4
    80004fa0:	bf6d                	j	80004f5a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fa2:	4901                	li	s2,0
  iunlockput(ip);
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	c18080e7          	jalr	-1000(ra) # 80003bbe <iunlockput>
  end_op();
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	400080e7          	jalr	1024(ra) # 800043ae <end_op>
  p = myproc();
    80004fb6:	ffffd097          	auipc	ra,0xffffd
    80004fba:	cd8080e7          	jalr	-808(ra) # 80001c8e <myproc>
    80004fbe:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fc0:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004fc4:	6785                	lui	a5,0x1
    80004fc6:	17fd                	addi	a5,a5,-1
    80004fc8:	993e                	add	s2,s2,a5
    80004fca:	757d                	lui	a0,0xfffff
    80004fcc:	00a977b3          	and	a5,s2,a0
    80004fd0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fd4:	6609                	lui	a2,0x2
    80004fd6:	963e                	add	a2,a2,a5
    80004fd8:	85be                	mv	a1,a5
    80004fda:	855e                	mv	a0,s7
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	446080e7          	jalr	1094(ra) # 80001422 <uvmalloc>
    80004fe4:	8b2a                	mv	s6,a0
  ip = 0;
    80004fe6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fe8:	12050c63          	beqz	a0,80005120 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fec:	75f9                	lui	a1,0xffffe
    80004fee:	95aa                	add	a1,a1,a0
    80004ff0:	855e                	mv	a0,s7
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	64e080e7          	jalr	1614(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ffa:	7c7d                	lui	s8,0xfffff
    80004ffc:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ffe:	e0043783          	ld	a5,-512(s0)
    80005002:	6388                	ld	a0,0(a5)
    80005004:	c535                	beqz	a0,80005070 <exec+0x216>
    80005006:	e9040993          	addi	s3,s0,-368
    8000500a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000500e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	e54080e7          	jalr	-428(ra) # 80000e64 <strlen>
    80005018:	2505                	addiw	a0,a0,1
    8000501a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000501e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005022:	13896363          	bltu	s2,s8,80005148 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005026:	e0043d83          	ld	s11,-512(s0)
    8000502a:	000dba03          	ld	s4,0(s11)
    8000502e:	8552                	mv	a0,s4
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	e34080e7          	jalr	-460(ra) # 80000e64 <strlen>
    80005038:	0015069b          	addiw	a3,a0,1
    8000503c:	8652                	mv	a2,s4
    8000503e:	85ca                	mv	a1,s2
    80005040:	855e                	mv	a0,s7
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	630080e7          	jalr	1584(ra) # 80001672 <copyout>
    8000504a:	10054363          	bltz	a0,80005150 <exec+0x2f6>
    ustack[argc] = sp;
    8000504e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005052:	0485                	addi	s1,s1,1
    80005054:	008d8793          	addi	a5,s11,8
    80005058:	e0f43023          	sd	a5,-512(s0)
    8000505c:	008db503          	ld	a0,8(s11)
    80005060:	c911                	beqz	a0,80005074 <exec+0x21a>
    if(argc >= MAXARG)
    80005062:	09a1                	addi	s3,s3,8
    80005064:	fb3c96e3          	bne	s9,s3,80005010 <exec+0x1b6>
  sz = sz1;
    80005068:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000506c:	4481                	li	s1,0
    8000506e:	a84d                	j	80005120 <exec+0x2c6>
  sp = sz;
    80005070:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005072:	4481                	li	s1,0
  ustack[argc] = 0;
    80005074:	00349793          	slli	a5,s1,0x3
    80005078:	f9040713          	addi	a4,s0,-112
    8000507c:	97ba                	add	a5,a5,a4
    8000507e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005082:	00148693          	addi	a3,s1,1
    80005086:	068e                	slli	a3,a3,0x3
    80005088:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000508c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005090:	01897663          	bgeu	s2,s8,8000509c <exec+0x242>
  sz = sz1;
    80005094:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005098:	4481                	li	s1,0
    8000509a:	a059                	j	80005120 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000509c:	e9040613          	addi	a2,s0,-368
    800050a0:	85ca                	mv	a1,s2
    800050a2:	855e                	mv	a0,s7
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	5ce080e7          	jalr	1486(ra) # 80001672 <copyout>
    800050ac:	0a054663          	bltz	a0,80005158 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050b0:	070ab783          	ld	a5,112(s5)
    800050b4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b8:	df843783          	ld	a5,-520(s0)
    800050bc:	0007c703          	lbu	a4,0(a5)
    800050c0:	cf11                	beqz	a4,800050dc <exec+0x282>
    800050c2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c4:	02f00693          	li	a3,47
    800050c8:	a039                	j	800050d6 <exec+0x27c>
      last = s+1;
    800050ca:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050ce:	0785                	addi	a5,a5,1
    800050d0:	fff7c703          	lbu	a4,-1(a5)
    800050d4:	c701                	beqz	a4,800050dc <exec+0x282>
    if(*s == '/')
    800050d6:	fed71ce3          	bne	a4,a3,800050ce <exec+0x274>
    800050da:	bfc5                	j	800050ca <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050dc:	4641                	li	a2,16
    800050de:	df843583          	ld	a1,-520(s0)
    800050e2:	170a8513          	addi	a0,s5,368
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	d4c080e7          	jalr	-692(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050ee:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    800050f2:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    800050f6:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050fa:	070ab783          	ld	a5,112(s5)
    800050fe:	e6843703          	ld	a4,-408(s0)
    80005102:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005104:	070ab783          	ld	a5,112(s5)
    80005108:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000510c:	85ea                	mv	a1,s10
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	ce0080e7          	jalr	-800(ra) # 80001dee <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005116:	0004851b          	sext.w	a0,s1
    8000511a:	bbe1                	j	80004ef2 <exec+0x98>
    8000511c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005120:	e0843583          	ld	a1,-504(s0)
    80005124:	855e                	mv	a0,s7
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	cc8080e7          	jalr	-824(ra) # 80001dee <proc_freepagetable>
  if(ip){
    8000512e:	da0498e3          	bnez	s1,80004ede <exec+0x84>
  return -1;
    80005132:	557d                	li	a0,-1
    80005134:	bb7d                	j	80004ef2 <exec+0x98>
    80005136:	e1243423          	sd	s2,-504(s0)
    8000513a:	b7dd                	j	80005120 <exec+0x2c6>
    8000513c:	e1243423          	sd	s2,-504(s0)
    80005140:	b7c5                	j	80005120 <exec+0x2c6>
    80005142:	e1243423          	sd	s2,-504(s0)
    80005146:	bfe9                	j	80005120 <exec+0x2c6>
  sz = sz1;
    80005148:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000514c:	4481                	li	s1,0
    8000514e:	bfc9                	j	80005120 <exec+0x2c6>
  sz = sz1;
    80005150:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005154:	4481                	li	s1,0
    80005156:	b7e9                	j	80005120 <exec+0x2c6>
  sz = sz1;
    80005158:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515c:	4481                	li	s1,0
    8000515e:	b7c9                	j	80005120 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005160:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005164:	2b05                	addiw	s6,s6,1
    80005166:	0389899b          	addiw	s3,s3,56
    8000516a:	e8845783          	lhu	a5,-376(s0)
    8000516e:	e2fb5be3          	bge	s6,a5,80004fa4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005172:	2981                	sext.w	s3,s3
    80005174:	03800713          	li	a4,56
    80005178:	86ce                	mv	a3,s3
    8000517a:	e1840613          	addi	a2,s0,-488
    8000517e:	4581                	li	a1,0
    80005180:	8526                	mv	a0,s1
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	a8e080e7          	jalr	-1394(ra) # 80003c10 <readi>
    8000518a:	03800793          	li	a5,56
    8000518e:	f8f517e3          	bne	a0,a5,8000511c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005192:	e1842783          	lw	a5,-488(s0)
    80005196:	4705                	li	a4,1
    80005198:	fce796e3          	bne	a5,a4,80005164 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000519c:	e4043603          	ld	a2,-448(s0)
    800051a0:	e3843783          	ld	a5,-456(s0)
    800051a4:	f8f669e3          	bltu	a2,a5,80005136 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051a8:	e2843783          	ld	a5,-472(s0)
    800051ac:	963e                	add	a2,a2,a5
    800051ae:	f8f667e3          	bltu	a2,a5,8000513c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b2:	85ca                	mv	a1,s2
    800051b4:	855e                	mv	a0,s7
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	26c080e7          	jalr	620(ra) # 80001422 <uvmalloc>
    800051be:	e0a43423          	sd	a0,-504(s0)
    800051c2:	d141                	beqz	a0,80005142 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051c4:	e2843d03          	ld	s10,-472(s0)
    800051c8:	df043783          	ld	a5,-528(s0)
    800051cc:	00fd77b3          	and	a5,s10,a5
    800051d0:	fba1                	bnez	a5,80005120 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051d2:	e2042d83          	lw	s11,-480(s0)
    800051d6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051da:	f80c03e3          	beqz	s8,80005160 <exec+0x306>
    800051de:	8a62                	mv	s4,s8
    800051e0:	4901                	li	s2,0
    800051e2:	b345                	j	80004f82 <exec+0x128>

00000000800051e4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051e4:	7179                	addi	sp,sp,-48
    800051e6:	f406                	sd	ra,40(sp)
    800051e8:	f022                	sd	s0,32(sp)
    800051ea:	ec26                	sd	s1,24(sp)
    800051ec:	e84a                	sd	s2,16(sp)
    800051ee:	1800                	addi	s0,sp,48
    800051f0:	892e                	mv	s2,a1
    800051f2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051f4:	fdc40593          	addi	a1,s0,-36
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	b90080e7          	jalr	-1136(ra) # 80002d88 <argint>
    80005200:	04054063          	bltz	a0,80005240 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005204:	fdc42703          	lw	a4,-36(s0)
    80005208:	47bd                	li	a5,15
    8000520a:	02e7ed63          	bltu	a5,a4,80005244 <argfd+0x60>
    8000520e:	ffffd097          	auipc	ra,0xffffd
    80005212:	a80080e7          	jalr	-1408(ra) # 80001c8e <myproc>
    80005216:	fdc42703          	lw	a4,-36(s0)
    8000521a:	01c70793          	addi	a5,a4,28
    8000521e:	078e                	slli	a5,a5,0x3
    80005220:	953e                	add	a0,a0,a5
    80005222:	651c                	ld	a5,8(a0)
    80005224:	c395                	beqz	a5,80005248 <argfd+0x64>
    return -1;
  if(pfd)
    80005226:	00090463          	beqz	s2,8000522e <argfd+0x4a>
    *pfd = fd;
    8000522a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000522e:	4501                	li	a0,0
  if(pf)
    80005230:	c091                	beqz	s1,80005234 <argfd+0x50>
    *pf = f;
    80005232:	e09c                	sd	a5,0(s1)
}
    80005234:	70a2                	ld	ra,40(sp)
    80005236:	7402                	ld	s0,32(sp)
    80005238:	64e2                	ld	s1,24(sp)
    8000523a:	6942                	ld	s2,16(sp)
    8000523c:	6145                	addi	sp,sp,48
    8000523e:	8082                	ret
    return -1;
    80005240:	557d                	li	a0,-1
    80005242:	bfcd                	j	80005234 <argfd+0x50>
    return -1;
    80005244:	557d                	li	a0,-1
    80005246:	b7fd                	j	80005234 <argfd+0x50>
    80005248:	557d                	li	a0,-1
    8000524a:	b7ed                	j	80005234 <argfd+0x50>

000000008000524c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000524c:	1101                	addi	sp,sp,-32
    8000524e:	ec06                	sd	ra,24(sp)
    80005250:	e822                	sd	s0,16(sp)
    80005252:	e426                	sd	s1,8(sp)
    80005254:	1000                	addi	s0,sp,32
    80005256:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005258:	ffffd097          	auipc	ra,0xffffd
    8000525c:	a36080e7          	jalr	-1482(ra) # 80001c8e <myproc>
    80005260:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005262:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    80005266:	4501                	li	a0,0
    80005268:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000526a:	6398                	ld	a4,0(a5)
    8000526c:	cb19                	beqz	a4,80005282 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000526e:	2505                	addiw	a0,a0,1
    80005270:	07a1                	addi	a5,a5,8
    80005272:	fed51ce3          	bne	a0,a3,8000526a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005276:	557d                	li	a0,-1
}
    80005278:	60e2                	ld	ra,24(sp)
    8000527a:	6442                	ld	s0,16(sp)
    8000527c:	64a2                	ld	s1,8(sp)
    8000527e:	6105                	addi	sp,sp,32
    80005280:	8082                	ret
      p->ofile[fd] = f;
    80005282:	01c50793          	addi	a5,a0,28
    80005286:	078e                	slli	a5,a5,0x3
    80005288:	963e                	add	a2,a2,a5
    8000528a:	e604                	sd	s1,8(a2)
      return fd;
    8000528c:	b7f5                	j	80005278 <fdalloc+0x2c>

000000008000528e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000528e:	715d                	addi	sp,sp,-80
    80005290:	e486                	sd	ra,72(sp)
    80005292:	e0a2                	sd	s0,64(sp)
    80005294:	fc26                	sd	s1,56(sp)
    80005296:	f84a                	sd	s2,48(sp)
    80005298:	f44e                	sd	s3,40(sp)
    8000529a:	f052                	sd	s4,32(sp)
    8000529c:	ec56                	sd	s5,24(sp)
    8000529e:	0880                	addi	s0,sp,80
    800052a0:	89ae                	mv	s3,a1
    800052a2:	8ab2                	mv	s5,a2
    800052a4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052a6:	fb040593          	addi	a1,s0,-80
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	e86080e7          	jalr	-378(ra) # 80004130 <nameiparent>
    800052b2:	892a                	mv	s2,a0
    800052b4:	12050f63          	beqz	a0,800053f2 <create+0x164>
    return 0;

  ilock(dp);
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	6a4080e7          	jalr	1700(ra) # 8000395c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052c0:	4601                	li	a2,0
    800052c2:	fb040593          	addi	a1,s0,-80
    800052c6:	854a                	mv	a0,s2
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	b78080e7          	jalr	-1160(ra) # 80003e40 <dirlookup>
    800052d0:	84aa                	mv	s1,a0
    800052d2:	c921                	beqz	a0,80005322 <create+0x94>
    iunlockput(dp);
    800052d4:	854a                	mv	a0,s2
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	8e8080e7          	jalr	-1816(ra) # 80003bbe <iunlockput>
    ilock(ip);
    800052de:	8526                	mv	a0,s1
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	67c080e7          	jalr	1660(ra) # 8000395c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052e8:	2981                	sext.w	s3,s3
    800052ea:	4789                	li	a5,2
    800052ec:	02f99463          	bne	s3,a5,80005314 <create+0x86>
    800052f0:	0444d783          	lhu	a5,68(s1)
    800052f4:	37f9                	addiw	a5,a5,-2
    800052f6:	17c2                	slli	a5,a5,0x30
    800052f8:	93c1                	srli	a5,a5,0x30
    800052fa:	4705                	li	a4,1
    800052fc:	00f76c63          	bltu	a4,a5,80005314 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005300:	8526                	mv	a0,s1
    80005302:	60a6                	ld	ra,72(sp)
    80005304:	6406                	ld	s0,64(sp)
    80005306:	74e2                	ld	s1,56(sp)
    80005308:	7942                	ld	s2,48(sp)
    8000530a:	79a2                	ld	s3,40(sp)
    8000530c:	7a02                	ld	s4,32(sp)
    8000530e:	6ae2                	ld	s5,24(sp)
    80005310:	6161                	addi	sp,sp,80
    80005312:	8082                	ret
    iunlockput(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	8a8080e7          	jalr	-1880(ra) # 80003bbe <iunlockput>
    return 0;
    8000531e:	4481                	li	s1,0
    80005320:	b7c5                	j	80005300 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005322:	85ce                	mv	a1,s3
    80005324:	00092503          	lw	a0,0(s2)
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	49c080e7          	jalr	1180(ra) # 800037c4 <ialloc>
    80005330:	84aa                	mv	s1,a0
    80005332:	c529                	beqz	a0,8000537c <create+0xee>
  ilock(ip);
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	628080e7          	jalr	1576(ra) # 8000395c <ilock>
  ip->major = major;
    8000533c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005340:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005344:	4785                	li	a5,1
    80005346:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	546080e7          	jalr	1350(ra) # 80003892 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005354:	2981                	sext.w	s3,s3
    80005356:	4785                	li	a5,1
    80005358:	02f98a63          	beq	s3,a5,8000538c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000535c:	40d0                	lw	a2,4(s1)
    8000535e:	fb040593          	addi	a1,s0,-80
    80005362:	854a                	mv	a0,s2
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	cec080e7          	jalr	-788(ra) # 80004050 <dirlink>
    8000536c:	06054b63          	bltz	a0,800053e2 <create+0x154>
  iunlockput(dp);
    80005370:	854a                	mv	a0,s2
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	84c080e7          	jalr	-1972(ra) # 80003bbe <iunlockput>
  return ip;
    8000537a:	b759                	j	80005300 <create+0x72>
    panic("create: ialloc");
    8000537c:	00003517          	auipc	a0,0x3
    80005380:	42450513          	addi	a0,a0,1060 # 800087a0 <syscalls+0x2b8>
    80005384:	ffffb097          	auipc	ra,0xffffb
    80005388:	1ba080e7          	jalr	442(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000538c:	04a95783          	lhu	a5,74(s2)
    80005390:	2785                	addiw	a5,a5,1
    80005392:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005396:	854a                	mv	a0,s2
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	4fa080e7          	jalr	1274(ra) # 80003892 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053a0:	40d0                	lw	a2,4(s1)
    800053a2:	00003597          	auipc	a1,0x3
    800053a6:	40e58593          	addi	a1,a1,1038 # 800087b0 <syscalls+0x2c8>
    800053aa:	8526                	mv	a0,s1
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	ca4080e7          	jalr	-860(ra) # 80004050 <dirlink>
    800053b4:	00054f63          	bltz	a0,800053d2 <create+0x144>
    800053b8:	00492603          	lw	a2,4(s2)
    800053bc:	00003597          	auipc	a1,0x3
    800053c0:	3fc58593          	addi	a1,a1,1020 # 800087b8 <syscalls+0x2d0>
    800053c4:	8526                	mv	a0,s1
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	c8a080e7          	jalr	-886(ra) # 80004050 <dirlink>
    800053ce:	f80557e3          	bgez	a0,8000535c <create+0xce>
      panic("create dots");
    800053d2:	00003517          	auipc	a0,0x3
    800053d6:	3ee50513          	addi	a0,a0,1006 # 800087c0 <syscalls+0x2d8>
    800053da:	ffffb097          	auipc	ra,0xffffb
    800053de:	164080e7          	jalr	356(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053e2:	00003517          	auipc	a0,0x3
    800053e6:	3ee50513          	addi	a0,a0,1006 # 800087d0 <syscalls+0x2e8>
    800053ea:	ffffb097          	auipc	ra,0xffffb
    800053ee:	154080e7          	jalr	340(ra) # 8000053e <panic>
    return 0;
    800053f2:	84aa                	mv	s1,a0
    800053f4:	b731                	j	80005300 <create+0x72>

00000000800053f6 <sys_dup>:
{
    800053f6:	7179                	addi	sp,sp,-48
    800053f8:	f406                	sd	ra,40(sp)
    800053fa:	f022                	sd	s0,32(sp)
    800053fc:	ec26                	sd	s1,24(sp)
    800053fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005400:	fd840613          	addi	a2,s0,-40
    80005404:	4581                	li	a1,0
    80005406:	4501                	li	a0,0
    80005408:	00000097          	auipc	ra,0x0
    8000540c:	ddc080e7          	jalr	-548(ra) # 800051e4 <argfd>
    return -1;
    80005410:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005412:	02054363          	bltz	a0,80005438 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005416:	fd843503          	ld	a0,-40(s0)
    8000541a:	00000097          	auipc	ra,0x0
    8000541e:	e32080e7          	jalr	-462(ra) # 8000524c <fdalloc>
    80005422:	84aa                	mv	s1,a0
    return -1;
    80005424:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005426:	00054963          	bltz	a0,80005438 <sys_dup+0x42>
  filedup(f);
    8000542a:	fd843503          	ld	a0,-40(s0)
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	37a080e7          	jalr	890(ra) # 800047a8 <filedup>
  return fd;
    80005436:	87a6                	mv	a5,s1
}
    80005438:	853e                	mv	a0,a5
    8000543a:	70a2                	ld	ra,40(sp)
    8000543c:	7402                	ld	s0,32(sp)
    8000543e:	64e2                	ld	s1,24(sp)
    80005440:	6145                	addi	sp,sp,48
    80005442:	8082                	ret

0000000080005444 <sys_read>:
{
    80005444:	7179                	addi	sp,sp,-48
    80005446:	f406                	sd	ra,40(sp)
    80005448:	f022                	sd	s0,32(sp)
    8000544a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	fe840613          	addi	a2,s0,-24
    80005450:	4581                	li	a1,0
    80005452:	4501                	li	a0,0
    80005454:	00000097          	auipc	ra,0x0
    80005458:	d90080e7          	jalr	-624(ra) # 800051e4 <argfd>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545e:	04054163          	bltz	a0,800054a0 <sys_read+0x5c>
    80005462:	fe440593          	addi	a1,s0,-28
    80005466:	4509                	li	a0,2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	920080e7          	jalr	-1760(ra) # 80002d88 <argint>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005472:	02054763          	bltz	a0,800054a0 <sys_read+0x5c>
    80005476:	fd840593          	addi	a1,s0,-40
    8000547a:	4505                	li	a0,1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	92e080e7          	jalr	-1746(ra) # 80002daa <argaddr>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005486:	00054d63          	bltz	a0,800054a0 <sys_read+0x5c>
  return fileread(f, p, n);
    8000548a:	fe442603          	lw	a2,-28(s0)
    8000548e:	fd843583          	ld	a1,-40(s0)
    80005492:	fe843503          	ld	a0,-24(s0)
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	49e080e7          	jalr	1182(ra) # 80004934 <fileread>
    8000549e:	87aa                	mv	a5,a0
}
    800054a0:	853e                	mv	a0,a5
    800054a2:	70a2                	ld	ra,40(sp)
    800054a4:	7402                	ld	s0,32(sp)
    800054a6:	6145                	addi	sp,sp,48
    800054a8:	8082                	ret

00000000800054aa <sys_write>:
{
    800054aa:	7179                	addi	sp,sp,-48
    800054ac:	f406                	sd	ra,40(sp)
    800054ae:	f022                	sd	s0,32(sp)
    800054b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	fe840613          	addi	a2,s0,-24
    800054b6:	4581                	li	a1,0
    800054b8:	4501                	li	a0,0
    800054ba:	00000097          	auipc	ra,0x0
    800054be:	d2a080e7          	jalr	-726(ra) # 800051e4 <argfd>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c4:	04054163          	bltz	a0,80005506 <sys_write+0x5c>
    800054c8:	fe440593          	addi	a1,s0,-28
    800054cc:	4509                	li	a0,2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	8ba080e7          	jalr	-1862(ra) # 80002d88 <argint>
    return -1;
    800054d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d8:	02054763          	bltz	a0,80005506 <sys_write+0x5c>
    800054dc:	fd840593          	addi	a1,s0,-40
    800054e0:	4505                	li	a0,1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	8c8080e7          	jalr	-1848(ra) # 80002daa <argaddr>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ec:	00054d63          	bltz	a0,80005506 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054f0:	fe442603          	lw	a2,-28(s0)
    800054f4:	fd843583          	ld	a1,-40(s0)
    800054f8:	fe843503          	ld	a0,-24(s0)
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	4fa080e7          	jalr	1274(ra) # 800049f6 <filewrite>
    80005504:	87aa                	mv	a5,a0
}
    80005506:	853e                	mv	a0,a5
    80005508:	70a2                	ld	ra,40(sp)
    8000550a:	7402                	ld	s0,32(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret

0000000080005510 <sys_close>:
{
    80005510:	1101                	addi	sp,sp,-32
    80005512:	ec06                	sd	ra,24(sp)
    80005514:	e822                	sd	s0,16(sp)
    80005516:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005518:	fe040613          	addi	a2,s0,-32
    8000551c:	fec40593          	addi	a1,s0,-20
    80005520:	4501                	li	a0,0
    80005522:	00000097          	auipc	ra,0x0
    80005526:	cc2080e7          	jalr	-830(ra) # 800051e4 <argfd>
    return -1;
    8000552a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000552c:	02054463          	bltz	a0,80005554 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005530:	ffffc097          	auipc	ra,0xffffc
    80005534:	75e080e7          	jalr	1886(ra) # 80001c8e <myproc>
    80005538:	fec42783          	lw	a5,-20(s0)
    8000553c:	07f1                	addi	a5,a5,28
    8000553e:	078e                	slli	a5,a5,0x3
    80005540:	97aa                	add	a5,a5,a0
    80005542:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005546:	fe043503          	ld	a0,-32(s0)
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	2b0080e7          	jalr	688(ra) # 800047fa <fileclose>
  return 0;
    80005552:	4781                	li	a5,0
}
    80005554:	853e                	mv	a0,a5
    80005556:	60e2                	ld	ra,24(sp)
    80005558:	6442                	ld	s0,16(sp)
    8000555a:	6105                	addi	sp,sp,32
    8000555c:	8082                	ret

000000008000555e <sys_fstat>:
{
    8000555e:	1101                	addi	sp,sp,-32
    80005560:	ec06                	sd	ra,24(sp)
    80005562:	e822                	sd	s0,16(sp)
    80005564:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005566:	fe840613          	addi	a2,s0,-24
    8000556a:	4581                	li	a1,0
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	c76080e7          	jalr	-906(ra) # 800051e4 <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005578:	02054563          	bltz	a0,800055a2 <sys_fstat+0x44>
    8000557c:	fe040593          	addi	a1,s0,-32
    80005580:	4505                	li	a0,1
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	828080e7          	jalr	-2008(ra) # 80002daa <argaddr>
    return -1;
    8000558a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000558c:	00054b63          	bltz	a0,800055a2 <sys_fstat+0x44>
  return filestat(f, st);
    80005590:	fe043583          	ld	a1,-32(s0)
    80005594:	fe843503          	ld	a0,-24(s0)
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	32a080e7          	jalr	810(ra) # 800048c2 <filestat>
    800055a0:	87aa                	mv	a5,a0
}
    800055a2:	853e                	mv	a0,a5
    800055a4:	60e2                	ld	ra,24(sp)
    800055a6:	6442                	ld	s0,16(sp)
    800055a8:	6105                	addi	sp,sp,32
    800055aa:	8082                	ret

00000000800055ac <sys_link>:
{
    800055ac:	7169                	addi	sp,sp,-304
    800055ae:	f606                	sd	ra,296(sp)
    800055b0:	f222                	sd	s0,288(sp)
    800055b2:	ee26                	sd	s1,280(sp)
    800055b4:	ea4a                	sd	s2,272(sp)
    800055b6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b8:	08000613          	li	a2,128
    800055bc:	ed040593          	addi	a1,s0,-304
    800055c0:	4501                	li	a0,0
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	80a080e7          	jalr	-2038(ra) # 80002dcc <argstr>
    return -1;
    800055ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055cc:	10054e63          	bltz	a0,800056e8 <sys_link+0x13c>
    800055d0:	08000613          	li	a2,128
    800055d4:	f5040593          	addi	a1,s0,-176
    800055d8:	4505                	li	a0,1
    800055da:	ffffd097          	auipc	ra,0xffffd
    800055de:	7f2080e7          	jalr	2034(ra) # 80002dcc <argstr>
    return -1;
    800055e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e4:	10054263          	bltz	a0,800056e8 <sys_link+0x13c>
  begin_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	d46080e7          	jalr	-698(ra) # 8000432e <begin_op>
  if((ip = namei(old)) == 0){
    800055f0:	ed040513          	addi	a0,s0,-304
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	b1e080e7          	jalr	-1250(ra) # 80004112 <namei>
    800055fc:	84aa                	mv	s1,a0
    800055fe:	c551                	beqz	a0,8000568a <sys_link+0xde>
  ilock(ip);
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	35c080e7          	jalr	860(ra) # 8000395c <ilock>
  if(ip->type == T_DIR){
    80005608:	04449703          	lh	a4,68(s1)
    8000560c:	4785                	li	a5,1
    8000560e:	08f70463          	beq	a4,a5,80005696 <sys_link+0xea>
  ip->nlink++;
    80005612:	04a4d783          	lhu	a5,74(s1)
    80005616:	2785                	addiw	a5,a5,1
    80005618:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	274080e7          	jalr	628(ra) # 80003892 <iupdate>
  iunlock(ip);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	3f6080e7          	jalr	1014(ra) # 80003a1e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005630:	fd040593          	addi	a1,s0,-48
    80005634:	f5040513          	addi	a0,s0,-176
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	af8080e7          	jalr	-1288(ra) # 80004130 <nameiparent>
    80005640:	892a                	mv	s2,a0
    80005642:	c935                	beqz	a0,800056b6 <sys_link+0x10a>
  ilock(dp);
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	318080e7          	jalr	792(ra) # 8000395c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000564c:	00092703          	lw	a4,0(s2)
    80005650:	409c                	lw	a5,0(s1)
    80005652:	04f71d63          	bne	a4,a5,800056ac <sys_link+0x100>
    80005656:	40d0                	lw	a2,4(s1)
    80005658:	fd040593          	addi	a1,s0,-48
    8000565c:	854a                	mv	a0,s2
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	9f2080e7          	jalr	-1550(ra) # 80004050 <dirlink>
    80005666:	04054363          	bltz	a0,800056ac <sys_link+0x100>
  iunlockput(dp);
    8000566a:	854a                	mv	a0,s2
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	552080e7          	jalr	1362(ra) # 80003bbe <iunlockput>
  iput(ip);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	4a0080e7          	jalr	1184(ra) # 80003b16 <iput>
  end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	d30080e7          	jalr	-720(ra) # 800043ae <end_op>
  return 0;
    80005686:	4781                	li	a5,0
    80005688:	a085                	j	800056e8 <sys_link+0x13c>
    end_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	d24080e7          	jalr	-732(ra) # 800043ae <end_op>
    return -1;
    80005692:	57fd                	li	a5,-1
    80005694:	a891                	j	800056e8 <sys_link+0x13c>
    iunlockput(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	526080e7          	jalr	1318(ra) # 80003bbe <iunlockput>
    end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	d0e080e7          	jalr	-754(ra) # 800043ae <end_op>
    return -1;
    800056a8:	57fd                	li	a5,-1
    800056aa:	a83d                	j	800056e8 <sys_link+0x13c>
    iunlockput(dp);
    800056ac:	854a                	mv	a0,s2
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	510080e7          	jalr	1296(ra) # 80003bbe <iunlockput>
  ilock(ip);
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	2a4080e7          	jalr	676(ra) # 8000395c <ilock>
  ip->nlink--;
    800056c0:	04a4d783          	lhu	a5,74(s1)
    800056c4:	37fd                	addiw	a5,a5,-1
    800056c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	1c6080e7          	jalr	454(ra) # 80003892 <iupdate>
  iunlockput(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	4e8080e7          	jalr	1256(ra) # 80003bbe <iunlockput>
  end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	cd0080e7          	jalr	-816(ra) # 800043ae <end_op>
  return -1;
    800056e6:	57fd                	li	a5,-1
}
    800056e8:	853e                	mv	a0,a5
    800056ea:	70b2                	ld	ra,296(sp)
    800056ec:	7412                	ld	s0,288(sp)
    800056ee:	64f2                	ld	s1,280(sp)
    800056f0:	6952                	ld	s2,272(sp)
    800056f2:	6155                	addi	sp,sp,304
    800056f4:	8082                	ret

00000000800056f6 <sys_unlink>:
{
    800056f6:	7151                	addi	sp,sp,-240
    800056f8:	f586                	sd	ra,232(sp)
    800056fa:	f1a2                	sd	s0,224(sp)
    800056fc:	eda6                	sd	s1,216(sp)
    800056fe:	e9ca                	sd	s2,208(sp)
    80005700:	e5ce                	sd	s3,200(sp)
    80005702:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005704:	08000613          	li	a2,128
    80005708:	f3040593          	addi	a1,s0,-208
    8000570c:	4501                	li	a0,0
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	6be080e7          	jalr	1726(ra) # 80002dcc <argstr>
    80005716:	18054163          	bltz	a0,80005898 <sys_unlink+0x1a2>
  begin_op();
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	c14080e7          	jalr	-1004(ra) # 8000432e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005722:	fb040593          	addi	a1,s0,-80
    80005726:	f3040513          	addi	a0,s0,-208
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	a06080e7          	jalr	-1530(ra) # 80004130 <nameiparent>
    80005732:	84aa                	mv	s1,a0
    80005734:	c979                	beqz	a0,8000580a <sys_unlink+0x114>
  ilock(dp);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	226080e7          	jalr	550(ra) # 8000395c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000573e:	00003597          	auipc	a1,0x3
    80005742:	07258593          	addi	a1,a1,114 # 800087b0 <syscalls+0x2c8>
    80005746:	fb040513          	addi	a0,s0,-80
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	6dc080e7          	jalr	1756(ra) # 80003e26 <namecmp>
    80005752:	14050a63          	beqz	a0,800058a6 <sys_unlink+0x1b0>
    80005756:	00003597          	auipc	a1,0x3
    8000575a:	06258593          	addi	a1,a1,98 # 800087b8 <syscalls+0x2d0>
    8000575e:	fb040513          	addi	a0,s0,-80
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	6c4080e7          	jalr	1732(ra) # 80003e26 <namecmp>
    8000576a:	12050e63          	beqz	a0,800058a6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000576e:	f2c40613          	addi	a2,s0,-212
    80005772:	fb040593          	addi	a1,s0,-80
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	6c8080e7          	jalr	1736(ra) # 80003e40 <dirlookup>
    80005780:	892a                	mv	s2,a0
    80005782:	12050263          	beqz	a0,800058a6 <sys_unlink+0x1b0>
  ilock(ip);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	1d6080e7          	jalr	470(ra) # 8000395c <ilock>
  if(ip->nlink < 1)
    8000578e:	04a91783          	lh	a5,74(s2)
    80005792:	08f05263          	blez	a5,80005816 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005796:	04491703          	lh	a4,68(s2)
    8000579a:	4785                	li	a5,1
    8000579c:	08f70563          	beq	a4,a5,80005826 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057a0:	4641                	li	a2,16
    800057a2:	4581                	li	a1,0
    800057a4:	fc040513          	addi	a0,s0,-64
    800057a8:	ffffb097          	auipc	ra,0xffffb
    800057ac:	538080e7          	jalr	1336(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b0:	4741                	li	a4,16
    800057b2:	f2c42683          	lw	a3,-212(s0)
    800057b6:	fc040613          	addi	a2,s0,-64
    800057ba:	4581                	li	a1,0
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	54a080e7          	jalr	1354(ra) # 80003d08 <writei>
    800057c6:	47c1                	li	a5,16
    800057c8:	0af51563          	bne	a0,a5,80005872 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057cc:	04491703          	lh	a4,68(s2)
    800057d0:	4785                	li	a5,1
    800057d2:	0af70863          	beq	a4,a5,80005882 <sys_unlink+0x18c>
  iunlockput(dp);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	3e6080e7          	jalr	998(ra) # 80003bbe <iunlockput>
  ip->nlink--;
    800057e0:	04a95783          	lhu	a5,74(s2)
    800057e4:	37fd                	addiw	a5,a5,-1
    800057e6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	0a6080e7          	jalr	166(ra) # 80003892 <iupdate>
  iunlockput(ip);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	3c8080e7          	jalr	968(ra) # 80003bbe <iunlockput>
  end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	bb0080e7          	jalr	-1104(ra) # 800043ae <end_op>
  return 0;
    80005806:	4501                	li	a0,0
    80005808:	a84d                	j	800058ba <sys_unlink+0x1c4>
    end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	ba4080e7          	jalr	-1116(ra) # 800043ae <end_op>
    return -1;
    80005812:	557d                	li	a0,-1
    80005814:	a05d                	j	800058ba <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005816:	00003517          	auipc	a0,0x3
    8000581a:	fca50513          	addi	a0,a0,-54 # 800087e0 <syscalls+0x2f8>
    8000581e:	ffffb097          	auipc	ra,0xffffb
    80005822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005826:	04c92703          	lw	a4,76(s2)
    8000582a:	02000793          	li	a5,32
    8000582e:	f6e7f9e3          	bgeu	a5,a4,800057a0 <sys_unlink+0xaa>
    80005832:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005836:	4741                	li	a4,16
    80005838:	86ce                	mv	a3,s3
    8000583a:	f1840613          	addi	a2,s0,-232
    8000583e:	4581                	li	a1,0
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	3ce080e7          	jalr	974(ra) # 80003c10 <readi>
    8000584a:	47c1                	li	a5,16
    8000584c:	00f51b63          	bne	a0,a5,80005862 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005850:	f1845783          	lhu	a5,-232(s0)
    80005854:	e7a1                	bnez	a5,8000589c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005856:	29c1                	addiw	s3,s3,16
    80005858:	04c92783          	lw	a5,76(s2)
    8000585c:	fcf9ede3          	bltu	s3,a5,80005836 <sys_unlink+0x140>
    80005860:	b781                	j	800057a0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005862:	00003517          	auipc	a0,0x3
    80005866:	f9650513          	addi	a0,a0,-106 # 800087f8 <syscalls+0x310>
    8000586a:	ffffb097          	auipc	ra,0xffffb
    8000586e:	cd4080e7          	jalr	-812(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005872:	00003517          	auipc	a0,0x3
    80005876:	f9e50513          	addi	a0,a0,-98 # 80008810 <syscalls+0x328>
    8000587a:	ffffb097          	auipc	ra,0xffffb
    8000587e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>
    dp->nlink--;
    80005882:	04a4d783          	lhu	a5,74(s1)
    80005886:	37fd                	addiw	a5,a5,-1
    80005888:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	004080e7          	jalr	4(ra) # 80003892 <iupdate>
    80005896:	b781                	j	800057d6 <sys_unlink+0xe0>
    return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	a005                	j	800058ba <sys_unlink+0x1c4>
    iunlockput(ip);
    8000589c:	854a                	mv	a0,s2
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	320080e7          	jalr	800(ra) # 80003bbe <iunlockput>
  iunlockput(dp);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	316080e7          	jalr	790(ra) # 80003bbe <iunlockput>
  end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	afe080e7          	jalr	-1282(ra) # 800043ae <end_op>
  return -1;
    800058b8:	557d                	li	a0,-1
}
    800058ba:	70ae                	ld	ra,232(sp)
    800058bc:	740e                	ld	s0,224(sp)
    800058be:	64ee                	ld	s1,216(sp)
    800058c0:	694e                	ld	s2,208(sp)
    800058c2:	69ae                	ld	s3,200(sp)
    800058c4:	616d                	addi	sp,sp,240
    800058c6:	8082                	ret

00000000800058c8 <sys_open>:

uint64
sys_open(void)
{
    800058c8:	7131                	addi	sp,sp,-192
    800058ca:	fd06                	sd	ra,184(sp)
    800058cc:	f922                	sd	s0,176(sp)
    800058ce:	f526                	sd	s1,168(sp)
    800058d0:	f14a                	sd	s2,160(sp)
    800058d2:	ed4e                	sd	s3,152(sp)
    800058d4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058d6:	08000613          	li	a2,128
    800058da:	f5040593          	addi	a1,s0,-176
    800058de:	4501                	li	a0,0
    800058e0:	ffffd097          	auipc	ra,0xffffd
    800058e4:	4ec080e7          	jalr	1260(ra) # 80002dcc <argstr>
    return -1;
    800058e8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ea:	0c054163          	bltz	a0,800059ac <sys_open+0xe4>
    800058ee:	f4c40593          	addi	a1,s0,-180
    800058f2:	4505                	li	a0,1
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	494080e7          	jalr	1172(ra) # 80002d88 <argint>
    800058fc:	0a054863          	bltz	a0,800059ac <sys_open+0xe4>

  begin_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	a2e080e7          	jalr	-1490(ra) # 8000432e <begin_op>

  if(omode & O_CREATE){
    80005908:	f4c42783          	lw	a5,-180(s0)
    8000590c:	2007f793          	andi	a5,a5,512
    80005910:	cbdd                	beqz	a5,800059c6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005912:	4681                	li	a3,0
    80005914:	4601                	li	a2,0
    80005916:	4589                	li	a1,2
    80005918:	f5040513          	addi	a0,s0,-176
    8000591c:	00000097          	auipc	ra,0x0
    80005920:	972080e7          	jalr	-1678(ra) # 8000528e <create>
    80005924:	892a                	mv	s2,a0
    if(ip == 0){
    80005926:	c959                	beqz	a0,800059bc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005928:	04491703          	lh	a4,68(s2)
    8000592c:	478d                	li	a5,3
    8000592e:	00f71763          	bne	a4,a5,8000593c <sys_open+0x74>
    80005932:	04695703          	lhu	a4,70(s2)
    80005936:	47a5                	li	a5,9
    80005938:	0ce7ec63          	bltu	a5,a4,80005a10 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	e02080e7          	jalr	-510(ra) # 8000473e <filealloc>
    80005944:	89aa                	mv	s3,a0
    80005946:	10050263          	beqz	a0,80005a4a <sys_open+0x182>
    8000594a:	00000097          	auipc	ra,0x0
    8000594e:	902080e7          	jalr	-1790(ra) # 8000524c <fdalloc>
    80005952:	84aa                	mv	s1,a0
    80005954:	0e054663          	bltz	a0,80005a40 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005958:	04491703          	lh	a4,68(s2)
    8000595c:	478d                	li	a5,3
    8000595e:	0cf70463          	beq	a4,a5,80005a26 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005962:	4789                	li	a5,2
    80005964:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005968:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000596c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005970:	f4c42783          	lw	a5,-180(s0)
    80005974:	0017c713          	xori	a4,a5,1
    80005978:	8b05                	andi	a4,a4,1
    8000597a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000597e:	0037f713          	andi	a4,a5,3
    80005982:	00e03733          	snez	a4,a4
    80005986:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000598a:	4007f793          	andi	a5,a5,1024
    8000598e:	c791                	beqz	a5,8000599a <sys_open+0xd2>
    80005990:	04491703          	lh	a4,68(s2)
    80005994:	4789                	li	a5,2
    80005996:	08f70f63          	beq	a4,a5,80005a34 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	082080e7          	jalr	130(ra) # 80003a1e <iunlock>
  end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	a0a080e7          	jalr	-1526(ra) # 800043ae <end_op>

  return fd;
}
    800059ac:	8526                	mv	a0,s1
    800059ae:	70ea                	ld	ra,184(sp)
    800059b0:	744a                	ld	s0,176(sp)
    800059b2:	74aa                	ld	s1,168(sp)
    800059b4:	790a                	ld	s2,160(sp)
    800059b6:	69ea                	ld	s3,152(sp)
    800059b8:	6129                	addi	sp,sp,192
    800059ba:	8082                	ret
      end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	9f2080e7          	jalr	-1550(ra) # 800043ae <end_op>
      return -1;
    800059c4:	b7e5                	j	800059ac <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059c6:	f5040513          	addi	a0,s0,-176
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	748080e7          	jalr	1864(ra) # 80004112 <namei>
    800059d2:	892a                	mv	s2,a0
    800059d4:	c905                	beqz	a0,80005a04 <sys_open+0x13c>
    ilock(ip);
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	f86080e7          	jalr	-122(ra) # 8000395c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059de:	04491703          	lh	a4,68(s2)
    800059e2:	4785                	li	a5,1
    800059e4:	f4f712e3          	bne	a4,a5,80005928 <sys_open+0x60>
    800059e8:	f4c42783          	lw	a5,-180(s0)
    800059ec:	dba1                	beqz	a5,8000593c <sys_open+0x74>
      iunlockput(ip);
    800059ee:	854a                	mv	a0,s2
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	1ce080e7          	jalr	462(ra) # 80003bbe <iunlockput>
      end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	9b6080e7          	jalr	-1610(ra) # 800043ae <end_op>
      return -1;
    80005a00:	54fd                	li	s1,-1
    80005a02:	b76d                	j	800059ac <sys_open+0xe4>
      end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	9aa080e7          	jalr	-1622(ra) # 800043ae <end_op>
      return -1;
    80005a0c:	54fd                	li	s1,-1
    80005a0e:	bf79                	j	800059ac <sys_open+0xe4>
    iunlockput(ip);
    80005a10:	854a                	mv	a0,s2
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	1ac080e7          	jalr	428(ra) # 80003bbe <iunlockput>
    end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	994080e7          	jalr	-1644(ra) # 800043ae <end_op>
    return -1;
    80005a22:	54fd                	li	s1,-1
    80005a24:	b761                	j	800059ac <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a26:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a2a:	04691783          	lh	a5,70(s2)
    80005a2e:	02f99223          	sh	a5,36(s3)
    80005a32:	bf2d                	j	8000596c <sys_open+0xa4>
    itrunc(ip);
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	034080e7          	jalr	52(ra) # 80003a6a <itrunc>
    80005a3e:	bfb1                	j	8000599a <sys_open+0xd2>
      fileclose(f);
    80005a40:	854e                	mv	a0,s3
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	db8080e7          	jalr	-584(ra) # 800047fa <fileclose>
    iunlockput(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	172080e7          	jalr	370(ra) # 80003bbe <iunlockput>
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	95a080e7          	jalr	-1702(ra) # 800043ae <end_op>
    return -1;
    80005a5c:	54fd                	li	s1,-1
    80005a5e:	b7b9                	j	800059ac <sys_open+0xe4>

0000000080005a60 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a60:	7175                	addi	sp,sp,-144
    80005a62:	e506                	sd	ra,136(sp)
    80005a64:	e122                	sd	s0,128(sp)
    80005a66:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	8c6080e7          	jalr	-1850(ra) # 8000432e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f7040593          	addi	a1,s0,-144
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	352080e7          	jalr	850(ra) # 80002dcc <argstr>
    80005a82:	02054963          	bltz	a0,80005ab4 <sys_mkdir+0x54>
    80005a86:	4681                	li	a3,0
    80005a88:	4601                	li	a2,0
    80005a8a:	4585                	li	a1,1
    80005a8c:	f7040513          	addi	a0,s0,-144
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	7fe080e7          	jalr	2046(ra) # 8000528e <create>
    80005a98:	cd11                	beqz	a0,80005ab4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	124080e7          	jalr	292(ra) # 80003bbe <iunlockput>
  end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	90c080e7          	jalr	-1780(ra) # 800043ae <end_op>
  return 0;
    80005aaa:	4501                	li	a0,0
}
    80005aac:	60aa                	ld	ra,136(sp)
    80005aae:	640a                	ld	s0,128(sp)
    80005ab0:	6149                	addi	sp,sp,144
    80005ab2:	8082                	ret
    end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	8fa080e7          	jalr	-1798(ra) # 800043ae <end_op>
    return -1;
    80005abc:	557d                	li	a0,-1
    80005abe:	b7fd                	j	80005aac <sys_mkdir+0x4c>

0000000080005ac0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac0:	7135                	addi	sp,sp,-160
    80005ac2:	ed06                	sd	ra,152(sp)
    80005ac4:	e922                	sd	s0,144(sp)
    80005ac6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	866080e7          	jalr	-1946(ra) # 8000432e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad0:	08000613          	li	a2,128
    80005ad4:	f7040593          	addi	a1,s0,-144
    80005ad8:	4501                	li	a0,0
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	2f2080e7          	jalr	754(ra) # 80002dcc <argstr>
    80005ae2:	04054a63          	bltz	a0,80005b36 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ae6:	f6c40593          	addi	a1,s0,-148
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	29c080e7          	jalr	668(ra) # 80002d88 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005af4:	04054163          	bltz	a0,80005b36 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005af8:	f6840593          	addi	a1,s0,-152
    80005afc:	4509                	li	a0,2
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	28a080e7          	jalr	650(ra) # 80002d88 <argint>
     argint(1, &major) < 0 ||
    80005b06:	02054863          	bltz	a0,80005b36 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b0a:	f6841683          	lh	a3,-152(s0)
    80005b0e:	f6c41603          	lh	a2,-148(s0)
    80005b12:	458d                	li	a1,3
    80005b14:	f7040513          	addi	a0,s0,-144
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	776080e7          	jalr	1910(ra) # 8000528e <create>
     argint(2, &minor) < 0 ||
    80005b20:	c919                	beqz	a0,80005b36 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	09c080e7          	jalr	156(ra) # 80003bbe <iunlockput>
  end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	884080e7          	jalr	-1916(ra) # 800043ae <end_op>
  return 0;
    80005b32:	4501                	li	a0,0
    80005b34:	a031                	j	80005b40 <sys_mknod+0x80>
    end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	878080e7          	jalr	-1928(ra) # 800043ae <end_op>
    return -1;
    80005b3e:	557d                	li	a0,-1
}
    80005b40:	60ea                	ld	ra,152(sp)
    80005b42:	644a                	ld	s0,144(sp)
    80005b44:	610d                	addi	sp,sp,160
    80005b46:	8082                	ret

0000000080005b48 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b48:	7135                	addi	sp,sp,-160
    80005b4a:	ed06                	sd	ra,152(sp)
    80005b4c:	e922                	sd	s0,144(sp)
    80005b4e:	e526                	sd	s1,136(sp)
    80005b50:	e14a                	sd	s2,128(sp)
    80005b52:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	13a080e7          	jalr	314(ra) # 80001c8e <myproc>
    80005b5c:	892a                	mv	s2,a0
  
  begin_op();
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	7d0080e7          	jalr	2000(ra) # 8000432e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b66:	08000613          	li	a2,128
    80005b6a:	f6040593          	addi	a1,s0,-160
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	25c080e7          	jalr	604(ra) # 80002dcc <argstr>
    80005b78:	04054b63          	bltz	a0,80005bce <sys_chdir+0x86>
    80005b7c:	f6040513          	addi	a0,s0,-160
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	592080e7          	jalr	1426(ra) # 80004112 <namei>
    80005b88:	84aa                	mv	s1,a0
    80005b8a:	c131                	beqz	a0,80005bce <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	dd0080e7          	jalr	-560(ra) # 8000395c <ilock>
  if(ip->type != T_DIR){
    80005b94:	04449703          	lh	a4,68(s1)
    80005b98:	4785                	li	a5,1
    80005b9a:	04f71063          	bne	a4,a5,80005bda <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	e7e080e7          	jalr	-386(ra) # 80003a1e <iunlock>
  iput(p->cwd);
    80005ba8:	16893503          	ld	a0,360(s2)
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	f6a080e7          	jalr	-150(ra) # 80003b16 <iput>
  end_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	7fa080e7          	jalr	2042(ra) # 800043ae <end_op>
  p->cwd = ip;
    80005bbc:	16993423          	sd	s1,360(s2)
  return 0;
    80005bc0:	4501                	li	a0,0
}
    80005bc2:	60ea                	ld	ra,152(sp)
    80005bc4:	644a                	ld	s0,144(sp)
    80005bc6:	64aa                	ld	s1,136(sp)
    80005bc8:	690a                	ld	s2,128(sp)
    80005bca:	610d                	addi	sp,sp,160
    80005bcc:	8082                	ret
    end_op();
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	7e0080e7          	jalr	2016(ra) # 800043ae <end_op>
    return -1;
    80005bd6:	557d                	li	a0,-1
    80005bd8:	b7ed                	j	80005bc2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	fe2080e7          	jalr	-30(ra) # 80003bbe <iunlockput>
    end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7ca080e7          	jalr	1994(ra) # 800043ae <end_op>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	bfd1                	j	80005bc2 <sys_chdir+0x7a>

0000000080005bf0 <sys_exec>:

uint64
sys_exec(void)
{
    80005bf0:	7145                	addi	sp,sp,-464
    80005bf2:	e786                	sd	ra,456(sp)
    80005bf4:	e3a2                	sd	s0,448(sp)
    80005bf6:	ff26                	sd	s1,440(sp)
    80005bf8:	fb4a                	sd	s2,432(sp)
    80005bfa:	f74e                	sd	s3,424(sp)
    80005bfc:	f352                	sd	s4,416(sp)
    80005bfe:	ef56                	sd	s5,408(sp)
    80005c00:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c02:	08000613          	li	a2,128
    80005c06:	f4040593          	addi	a1,s0,-192
    80005c0a:	4501                	li	a0,0
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	1c0080e7          	jalr	448(ra) # 80002dcc <argstr>
    return -1;
    80005c14:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c16:	0c054a63          	bltz	a0,80005cea <sys_exec+0xfa>
    80005c1a:	e3840593          	addi	a1,s0,-456
    80005c1e:	4505                	li	a0,1
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	18a080e7          	jalr	394(ra) # 80002daa <argaddr>
    80005c28:	0c054163          	bltz	a0,80005cea <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c2c:	10000613          	li	a2,256
    80005c30:	4581                	li	a1,0
    80005c32:	e4040513          	addi	a0,s0,-448
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	0aa080e7          	jalr	170(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c3e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c42:	89a6                	mv	s3,s1
    80005c44:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c46:	02000a13          	li	s4,32
    80005c4a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c4e:	00391513          	slli	a0,s2,0x3
    80005c52:	e3040593          	addi	a1,s0,-464
    80005c56:	e3843783          	ld	a5,-456(s0)
    80005c5a:	953e                	add	a0,a0,a5
    80005c5c:	ffffd097          	auipc	ra,0xffffd
    80005c60:	092080e7          	jalr	146(ra) # 80002cee <fetchaddr>
    80005c64:	02054a63          	bltz	a0,80005c98 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c68:	e3043783          	ld	a5,-464(s0)
    80005c6c:	c3b9                	beqz	a5,80005cb2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c6e:	ffffb097          	auipc	ra,0xffffb
    80005c72:	e86080e7          	jalr	-378(ra) # 80000af4 <kalloc>
    80005c76:	85aa                	mv	a1,a0
    80005c78:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c7c:	cd11                	beqz	a0,80005c98 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c7e:	6605                	lui	a2,0x1
    80005c80:	e3043503          	ld	a0,-464(s0)
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	0bc080e7          	jalr	188(ra) # 80002d40 <fetchstr>
    80005c8c:	00054663          	bltz	a0,80005c98 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c90:	0905                	addi	s2,s2,1
    80005c92:	09a1                	addi	s3,s3,8
    80005c94:	fb491be3          	bne	s2,s4,80005c4a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c98:	10048913          	addi	s2,s1,256
    80005c9c:	6088                	ld	a0,0(s1)
    80005c9e:	c529                	beqz	a0,80005ce8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ca0:	ffffb097          	auipc	ra,0xffffb
    80005ca4:	d58080e7          	jalr	-680(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca8:	04a1                	addi	s1,s1,8
    80005caa:	ff2499e3          	bne	s1,s2,80005c9c <sys_exec+0xac>
  return -1;
    80005cae:	597d                	li	s2,-1
    80005cb0:	a82d                	j	80005cea <sys_exec+0xfa>
      argv[i] = 0;
    80005cb2:	0a8e                	slli	s5,s5,0x3
    80005cb4:	fc040793          	addi	a5,s0,-64
    80005cb8:	9abe                	add	s5,s5,a5
    80005cba:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cbe:	e4040593          	addi	a1,s0,-448
    80005cc2:	f4040513          	addi	a0,s0,-192
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	194080e7          	jalr	404(ra) # 80004e5a <exec>
    80005cce:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd0:	10048993          	addi	s3,s1,256
    80005cd4:	6088                	ld	a0,0(s1)
    80005cd6:	c911                	beqz	a0,80005cea <sys_exec+0xfa>
    kfree(argv[i]);
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	d20080e7          	jalr	-736(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce0:	04a1                	addi	s1,s1,8
    80005ce2:	ff3499e3          	bne	s1,s3,80005cd4 <sys_exec+0xe4>
    80005ce6:	a011                	j	80005cea <sys_exec+0xfa>
  return -1;
    80005ce8:	597d                	li	s2,-1
}
    80005cea:	854a                	mv	a0,s2
    80005cec:	60be                	ld	ra,456(sp)
    80005cee:	641e                	ld	s0,448(sp)
    80005cf0:	74fa                	ld	s1,440(sp)
    80005cf2:	795a                	ld	s2,432(sp)
    80005cf4:	79ba                	ld	s3,424(sp)
    80005cf6:	7a1a                	ld	s4,416(sp)
    80005cf8:	6afa                	ld	s5,408(sp)
    80005cfa:	6179                	addi	sp,sp,464
    80005cfc:	8082                	ret

0000000080005cfe <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cfe:	7139                	addi	sp,sp,-64
    80005d00:	fc06                	sd	ra,56(sp)
    80005d02:	f822                	sd	s0,48(sp)
    80005d04:	f426                	sd	s1,40(sp)
    80005d06:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	f86080e7          	jalr	-122(ra) # 80001c8e <myproc>
    80005d10:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d12:	fd840593          	addi	a1,s0,-40
    80005d16:	4501                	li	a0,0
    80005d18:	ffffd097          	auipc	ra,0xffffd
    80005d1c:	092080e7          	jalr	146(ra) # 80002daa <argaddr>
    return -1;
    80005d20:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d22:	0e054063          	bltz	a0,80005e02 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d26:	fc840593          	addi	a1,s0,-56
    80005d2a:	fd040513          	addi	a0,s0,-48
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	dfc080e7          	jalr	-516(ra) # 80004b2a <pipealloc>
    return -1;
    80005d36:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d38:	0c054563          	bltz	a0,80005e02 <sys_pipe+0x104>
  fd0 = -1;
    80005d3c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d40:	fd043503          	ld	a0,-48(s0)
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	508080e7          	jalr	1288(ra) # 8000524c <fdalloc>
    80005d4c:	fca42223          	sw	a0,-60(s0)
    80005d50:	08054c63          	bltz	a0,80005de8 <sys_pipe+0xea>
    80005d54:	fc843503          	ld	a0,-56(s0)
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	4f4080e7          	jalr	1268(ra) # 8000524c <fdalloc>
    80005d60:	fca42023          	sw	a0,-64(s0)
    80005d64:	06054863          	bltz	a0,80005dd4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d68:	4691                	li	a3,4
    80005d6a:	fc440613          	addi	a2,s0,-60
    80005d6e:	fd843583          	ld	a1,-40(s0)
    80005d72:	74a8                	ld	a0,104(s1)
    80005d74:	ffffc097          	auipc	ra,0xffffc
    80005d78:	8fe080e7          	jalr	-1794(ra) # 80001672 <copyout>
    80005d7c:	02054063          	bltz	a0,80005d9c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d80:	4691                	li	a3,4
    80005d82:	fc040613          	addi	a2,s0,-64
    80005d86:	fd843583          	ld	a1,-40(s0)
    80005d8a:	0591                	addi	a1,a1,4
    80005d8c:	74a8                	ld	a0,104(s1)
    80005d8e:	ffffc097          	auipc	ra,0xffffc
    80005d92:	8e4080e7          	jalr	-1820(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d96:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d98:	06055563          	bgez	a0,80005e02 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d9c:	fc442783          	lw	a5,-60(s0)
    80005da0:	07f1                	addi	a5,a5,28
    80005da2:	078e                	slli	a5,a5,0x3
    80005da4:	97a6                	add	a5,a5,s1
    80005da6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005daa:	fc042503          	lw	a0,-64(s0)
    80005dae:	0571                	addi	a0,a0,28
    80005db0:	050e                	slli	a0,a0,0x3
    80005db2:	9526                	add	a0,a0,s1
    80005db4:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005db8:	fd043503          	ld	a0,-48(s0)
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	a3e080e7          	jalr	-1474(ra) # 800047fa <fileclose>
    fileclose(wf);
    80005dc4:	fc843503          	ld	a0,-56(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	a32080e7          	jalr	-1486(ra) # 800047fa <fileclose>
    return -1;
    80005dd0:	57fd                	li	a5,-1
    80005dd2:	a805                	j	80005e02 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dd4:	fc442783          	lw	a5,-60(s0)
    80005dd8:	0007c863          	bltz	a5,80005de8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ddc:	01c78513          	addi	a0,a5,28
    80005de0:	050e                	slli	a0,a0,0x3
    80005de2:	9526                	add	a0,a0,s1
    80005de4:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005de8:	fd043503          	ld	a0,-48(s0)
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	a0e080e7          	jalr	-1522(ra) # 800047fa <fileclose>
    fileclose(wf);
    80005df4:	fc843503          	ld	a0,-56(s0)
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	a02080e7          	jalr	-1534(ra) # 800047fa <fileclose>
    return -1;
    80005e00:	57fd                	li	a5,-1
}
    80005e02:	853e                	mv	a0,a5
    80005e04:	70e2                	ld	ra,56(sp)
    80005e06:	7442                	ld	s0,48(sp)
    80005e08:	74a2                	ld	s1,40(sp)
    80005e0a:	6121                	addi	sp,sp,64
    80005e0c:	8082                	ret
	...

0000000080005e10 <kernelvec>:
    80005e10:	7111                	addi	sp,sp,-256
    80005e12:	e006                	sd	ra,0(sp)
    80005e14:	e40a                	sd	sp,8(sp)
    80005e16:	e80e                	sd	gp,16(sp)
    80005e18:	ec12                	sd	tp,24(sp)
    80005e1a:	f016                	sd	t0,32(sp)
    80005e1c:	f41a                	sd	t1,40(sp)
    80005e1e:	f81e                	sd	t2,48(sp)
    80005e20:	fc22                	sd	s0,56(sp)
    80005e22:	e0a6                	sd	s1,64(sp)
    80005e24:	e4aa                	sd	a0,72(sp)
    80005e26:	e8ae                	sd	a1,80(sp)
    80005e28:	ecb2                	sd	a2,88(sp)
    80005e2a:	f0b6                	sd	a3,96(sp)
    80005e2c:	f4ba                	sd	a4,104(sp)
    80005e2e:	f8be                	sd	a5,112(sp)
    80005e30:	fcc2                	sd	a6,120(sp)
    80005e32:	e146                	sd	a7,128(sp)
    80005e34:	e54a                	sd	s2,136(sp)
    80005e36:	e94e                	sd	s3,144(sp)
    80005e38:	ed52                	sd	s4,152(sp)
    80005e3a:	f156                	sd	s5,160(sp)
    80005e3c:	f55a                	sd	s6,168(sp)
    80005e3e:	f95e                	sd	s7,176(sp)
    80005e40:	fd62                	sd	s8,184(sp)
    80005e42:	e1e6                	sd	s9,192(sp)
    80005e44:	e5ea                	sd	s10,200(sp)
    80005e46:	e9ee                	sd	s11,208(sp)
    80005e48:	edf2                	sd	t3,216(sp)
    80005e4a:	f1f6                	sd	t4,224(sp)
    80005e4c:	f5fa                	sd	t5,232(sp)
    80005e4e:	f9fe                	sd	t6,240(sp)
    80005e50:	d6bfc0ef          	jal	ra,80002bba <kerneltrap>
    80005e54:	6082                	ld	ra,0(sp)
    80005e56:	6122                	ld	sp,8(sp)
    80005e58:	61c2                	ld	gp,16(sp)
    80005e5a:	7282                	ld	t0,32(sp)
    80005e5c:	7322                	ld	t1,40(sp)
    80005e5e:	73c2                	ld	t2,48(sp)
    80005e60:	7462                	ld	s0,56(sp)
    80005e62:	6486                	ld	s1,64(sp)
    80005e64:	6526                	ld	a0,72(sp)
    80005e66:	65c6                	ld	a1,80(sp)
    80005e68:	6666                	ld	a2,88(sp)
    80005e6a:	7686                	ld	a3,96(sp)
    80005e6c:	7726                	ld	a4,104(sp)
    80005e6e:	77c6                	ld	a5,112(sp)
    80005e70:	7866                	ld	a6,120(sp)
    80005e72:	688a                	ld	a7,128(sp)
    80005e74:	692a                	ld	s2,136(sp)
    80005e76:	69ca                	ld	s3,144(sp)
    80005e78:	6a6a                	ld	s4,152(sp)
    80005e7a:	7a8a                	ld	s5,160(sp)
    80005e7c:	7b2a                	ld	s6,168(sp)
    80005e7e:	7bca                	ld	s7,176(sp)
    80005e80:	7c6a                	ld	s8,184(sp)
    80005e82:	6c8e                	ld	s9,192(sp)
    80005e84:	6d2e                	ld	s10,200(sp)
    80005e86:	6dce                	ld	s11,208(sp)
    80005e88:	6e6e                	ld	t3,216(sp)
    80005e8a:	7e8e                	ld	t4,224(sp)
    80005e8c:	7f2e                	ld	t5,232(sp)
    80005e8e:	7fce                	ld	t6,240(sp)
    80005e90:	6111                	addi	sp,sp,256
    80005e92:	10200073          	sret
    80005e96:	00000013          	nop
    80005e9a:	00000013          	nop
    80005e9e:	0001                	nop

0000000080005ea0 <timervec>:
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	e10c                	sd	a1,0(a0)
    80005ea6:	e510                	sd	a2,8(a0)
    80005ea8:	e914                	sd	a3,16(a0)
    80005eaa:	6d0c                	ld	a1,24(a0)
    80005eac:	7110                	ld	a2,32(a0)
    80005eae:	6194                	ld	a3,0(a1)
    80005eb0:	96b2                	add	a3,a3,a2
    80005eb2:	e194                	sd	a3,0(a1)
    80005eb4:	4589                	li	a1,2
    80005eb6:	14459073          	csrw	sip,a1
    80005eba:	6914                	ld	a3,16(a0)
    80005ebc:	6510                	ld	a2,8(a0)
    80005ebe:	610c                	ld	a1,0(a0)
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	30200073          	mret
	...

0000000080005eca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eca:	1141                	addi	sp,sp,-16
    80005ecc:	e422                	sd	s0,8(sp)
    80005ece:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ed0:	0c0007b7          	lui	a5,0xc000
    80005ed4:	4705                	li	a4,1
    80005ed6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ed8:	c3d8                	sw	a4,4(a5)
}
    80005eda:	6422                	ld	s0,8(sp)
    80005edc:	0141                	addi	sp,sp,16
    80005ede:	8082                	ret

0000000080005ee0 <plicinithart>:

void
plicinithart(void)
{
    80005ee0:	1141                	addi	sp,sp,-16
    80005ee2:	e406                	sd	ra,8(sp)
    80005ee4:	e022                	sd	s0,0(sp)
    80005ee6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	d7a080e7          	jalr	-646(ra) # 80001c62 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ef0:	0085171b          	slliw	a4,a0,0x8
    80005ef4:	0c0027b7          	lui	a5,0xc002
    80005ef8:	97ba                	add	a5,a5,a4
    80005efa:	40200713          	li	a4,1026
    80005efe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f02:	00d5151b          	slliw	a0,a0,0xd
    80005f06:	0c2017b7          	lui	a5,0xc201
    80005f0a:	953e                	add	a0,a0,a5
    80005f0c:	00052023          	sw	zero,0(a0)
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret

0000000080005f18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f18:	1141                	addi	sp,sp,-16
    80005f1a:	e406                	sd	ra,8(sp)
    80005f1c:	e022                	sd	s0,0(sp)
    80005f1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	d42080e7          	jalr	-702(ra) # 80001c62 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f28:	00d5179b          	slliw	a5,a0,0xd
    80005f2c:	0c201537          	lui	a0,0xc201
    80005f30:	953e                	add	a0,a0,a5
  return irq;
}
    80005f32:	4148                	lw	a0,4(a0)
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	addi	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f3c:	1101                	addi	sp,sp,-32
    80005f3e:	ec06                	sd	ra,24(sp)
    80005f40:	e822                	sd	s0,16(sp)
    80005f42:	e426                	sd	s1,8(sp)
    80005f44:	1000                	addi	s0,sp,32
    80005f46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	d1a080e7          	jalr	-742(ra) # 80001c62 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f50:	00d5151b          	slliw	a0,a0,0xd
    80005f54:	0c2017b7          	lui	a5,0xc201
    80005f58:	97aa                	add	a5,a5,a0
    80005f5a:	c3c4                	sw	s1,4(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret

0000000080005f66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f66:	1141                	addi	sp,sp,-16
    80005f68:	e406                	sd	ra,8(sp)
    80005f6a:	e022                	sd	s0,0(sp)
    80005f6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f6e:	479d                	li	a5,7
    80005f70:	06a7c963          	blt	a5,a0,80005fe2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f74:	0001d797          	auipc	a5,0x1d
    80005f78:	08c78793          	addi	a5,a5,140 # 80023000 <disk>
    80005f7c:	00a78733          	add	a4,a5,a0
    80005f80:	6789                	lui	a5,0x2
    80005f82:	97ba                	add	a5,a5,a4
    80005f84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f88:	e7ad                	bnez	a5,80005ff2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f8a:	00451793          	slli	a5,a0,0x4
    80005f8e:	0001f717          	auipc	a4,0x1f
    80005f92:	07270713          	addi	a4,a4,114 # 80025000 <disk+0x2000>
    80005f96:	6314                	ld	a3,0(a4)
    80005f98:	96be                	add	a3,a3,a5
    80005f9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f9e:	6314                	ld	a3,0(a4)
    80005fa0:	96be                	add	a3,a3,a5
    80005fa2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fa6:	6314                	ld	a3,0(a4)
    80005fa8:	96be                	add	a3,a3,a5
    80005faa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fae:	6318                	ld	a4,0(a4)
    80005fb0:	97ba                	add	a5,a5,a4
    80005fb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fb6:	0001d797          	auipc	a5,0x1d
    80005fba:	04a78793          	addi	a5,a5,74 # 80023000 <disk>
    80005fbe:	97aa                	add	a5,a5,a0
    80005fc0:	6509                	lui	a0,0x2
    80005fc2:	953e                	add	a0,a0,a5
    80005fc4:	4785                	li	a5,1
    80005fc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fca:	0001f517          	auipc	a0,0x1f
    80005fce:	04e50513          	addi	a0,a0,78 # 80025018 <disk+0x2018>
    80005fd2:	ffffc097          	auipc	ra,0xffffc
    80005fd6:	4f8080e7          	jalr	1272(ra) # 800024ca <wakeup>
}
    80005fda:	60a2                	ld	ra,8(sp)
    80005fdc:	6402                	ld	s0,0(sp)
    80005fde:	0141                	addi	sp,sp,16
    80005fe0:	8082                	ret
    panic("free_desc 1");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	83e50513          	addi	a0,a0,-1986 # 80008820 <syscalls+0x338>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	83e50513          	addi	a0,a0,-1986 # 80008830 <syscalls+0x348>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>

0000000080006002 <virtio_disk_init>:
{
    80006002:	1101                	addi	sp,sp,-32
    80006004:	ec06                	sd	ra,24(sp)
    80006006:	e822                	sd	s0,16(sp)
    80006008:	e426                	sd	s1,8(sp)
    8000600a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000600c:	00003597          	auipc	a1,0x3
    80006010:	83458593          	addi	a1,a1,-1996 # 80008840 <syscalls+0x358>
    80006014:	0001f517          	auipc	a0,0x1f
    80006018:	11450513          	addi	a0,a0,276 # 80025128 <disk+0x2128>
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	b38080e7          	jalr	-1224(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006024:	100017b7          	lui	a5,0x10001
    80006028:	4398                	lw	a4,0(a5)
    8000602a:	2701                	sext.w	a4,a4
    8000602c:	747277b7          	lui	a5,0x74727
    80006030:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006034:	0ef71163          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	43dc                	lw	a5,4(a5)
    8000603e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006040:	4705                	li	a4,1
    80006042:	0ce79a63          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006046:	100017b7          	lui	a5,0x10001
    8000604a:	479c                	lw	a5,8(a5)
    8000604c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000604e:	4709                	li	a4,2
    80006050:	0ce79363          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	47d8                	lw	a4,12(a5)
    8000605a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605c:	554d47b7          	lui	a5,0x554d4
    80006060:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006064:	0af71963          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	4705                	li	a4,1
    8000606e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006070:	470d                	li	a4,3
    80006072:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006074:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006076:	c7ffe737          	lui	a4,0xc7ffe
    8000607a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000607e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006080:	2701                	sext.w	a4,a4
    80006082:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006084:	472d                	li	a4,11
    80006086:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	473d                	li	a4,15
    8000608a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000608c:	6705                	lui	a4,0x1
    8000608e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006090:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006094:	5bdc                	lw	a5,52(a5)
    80006096:	2781                	sext.w	a5,a5
  if(max == 0)
    80006098:	c7d9                	beqz	a5,80006126 <virtio_disk_init+0x124>
  if(max < NUM)
    8000609a:	471d                	li	a4,7
    8000609c:	08f77d63          	bgeu	a4,a5,80006136 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060a0:	100014b7          	lui	s1,0x10001
    800060a4:	47a1                	li	a5,8
    800060a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060a8:	6609                	lui	a2,0x2
    800060aa:	4581                	li	a1,0
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	c2c080e7          	jalr	-980(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060bc:	0001d717          	auipc	a4,0x1d
    800060c0:	f4470713          	addi	a4,a4,-188 # 80023000 <disk>
    800060c4:	00c75793          	srli	a5,a4,0xc
    800060c8:	2781                	sext.w	a5,a5
    800060ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060cc:	0001f797          	auipc	a5,0x1f
    800060d0:	f3478793          	addi	a5,a5,-204 # 80025000 <disk+0x2000>
    800060d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060d6:	0001d717          	auipc	a4,0x1d
    800060da:	faa70713          	addi	a4,a4,-86 # 80023080 <disk+0x80>
    800060de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060e0:	0001e717          	auipc	a4,0x1e
    800060e4:	f2070713          	addi	a4,a4,-224 # 80024000 <disk+0x1000>
    800060e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ea:	4705                	li	a4,1
    800060ec:	00e78c23          	sb	a4,24(a5)
    800060f0:	00e78ca3          	sb	a4,25(a5)
    800060f4:	00e78d23          	sb	a4,26(a5)
    800060f8:	00e78da3          	sb	a4,27(a5)
    800060fc:	00e78e23          	sb	a4,28(a5)
    80006100:	00e78ea3          	sb	a4,29(a5)
    80006104:	00e78f23          	sb	a4,30(a5)
    80006108:	00e78fa3          	sb	a4,31(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret
    panic("could not find virtio disk");
    80006116:	00002517          	auipc	a0,0x2
    8000611a:	73a50513          	addi	a0,a0,1850 # 80008850 <syscalls+0x368>
    8000611e:	ffffa097          	auipc	ra,0xffffa
    80006122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	74a50513          	addi	a0,a0,1866 # 80008870 <syscalls+0x388>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	75a50513          	addi	a0,a0,1882 # 80008890 <syscalls+0x3a8>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>

0000000080006146 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006146:	7159                	addi	sp,sp,-112
    80006148:	f486                	sd	ra,104(sp)
    8000614a:	f0a2                	sd	s0,96(sp)
    8000614c:	eca6                	sd	s1,88(sp)
    8000614e:	e8ca                	sd	s2,80(sp)
    80006150:	e4ce                	sd	s3,72(sp)
    80006152:	e0d2                	sd	s4,64(sp)
    80006154:	fc56                	sd	s5,56(sp)
    80006156:	f85a                	sd	s6,48(sp)
    80006158:	f45e                	sd	s7,40(sp)
    8000615a:	f062                	sd	s8,32(sp)
    8000615c:	ec66                	sd	s9,24(sp)
    8000615e:	e86a                	sd	s10,16(sp)
    80006160:	1880                	addi	s0,sp,112
    80006162:	892a                	mv	s2,a0
    80006164:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006166:	00c52c83          	lw	s9,12(a0)
    8000616a:	001c9c9b          	slliw	s9,s9,0x1
    8000616e:	1c82                	slli	s9,s9,0x20
    80006170:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006174:	0001f517          	auipc	a0,0x1f
    80006178:	fb450513          	addi	a0,a0,-76 # 80025128 <disk+0x2128>
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006184:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006186:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006188:	0001db97          	auipc	s7,0x1d
    8000618c:	e78b8b93          	addi	s7,s7,-392 # 80023000 <disk>
    80006190:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006192:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006194:	8a4e                	mv	s4,s3
    80006196:	a051                	j	8000621a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006198:	00fb86b3          	add	a3,s7,a5
    8000619c:	96da                	add	a3,a3,s6
    8000619e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061a4:	0207c563          	bltz	a5,800061ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061a8:	2485                	addiw	s1,s1,1
    800061aa:	0711                	addi	a4,a4,4
    800061ac:	25548063          	beq	s1,s5,800063ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061b2:	0001f697          	auipc	a3,0x1f
    800061b6:	e6668693          	addi	a3,a3,-410 # 80025018 <disk+0x2018>
    800061ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061bc:	0006c583          	lbu	a1,0(a3)
    800061c0:	fde1                	bnez	a1,80006198 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061c2:	2785                	addiw	a5,a5,1
    800061c4:	0685                	addi	a3,a3,1
    800061c6:	ff879be3          	bne	a5,s8,800061bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ca:	57fd                	li	a5,-1
    800061cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ce:	02905a63          	blez	s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061d2:	f9042503          	lw	a0,-112(s0)
    800061d6:	00000097          	auipc	ra,0x0
    800061da:	d90080e7          	jalr	-624(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061de:	4785                	li	a5,1
    800061e0:	0297d163          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061e4:	f9442503          	lw	a0,-108(s0)
    800061e8:	00000097          	auipc	ra,0x0
    800061ec:	d7e080e7          	jalr	-642(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061f0:	4789                	li	a5,2
    800061f2:	0097d863          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f6:	f9842503          	lw	a0,-104(s0)
    800061fa:	00000097          	auipc	ra,0x0
    800061fe:	d6c080e7          	jalr	-660(ra) # 80005f66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006202:	0001f597          	auipc	a1,0x1f
    80006206:	f2658593          	addi	a1,a1,-218 # 80025128 <disk+0x2128>
    8000620a:	0001f517          	auipc	a0,0x1f
    8000620e:	e0e50513          	addi	a0,a0,-498 # 80025018 <disk+0x2018>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	112080e7          	jalr	274(ra) # 80002324 <sleep>
  for(int i = 0; i < 3; i++){
    8000621a:	f9040713          	addi	a4,s0,-112
    8000621e:	84ce                	mv	s1,s3
    80006220:	bf41                	j	800061b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006222:	20058713          	addi	a4,a1,512
    80006226:	00471693          	slli	a3,a4,0x4
    8000622a:	0001d717          	auipc	a4,0x1d
    8000622e:	dd670713          	addi	a4,a4,-554 # 80023000 <disk>
    80006232:	9736                	add	a4,a4,a3
    80006234:	4685                	li	a3,1
    80006236:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000623a:	20058713          	addi	a4,a1,512
    8000623e:	00471693          	slli	a3,a4,0x4
    80006242:	0001d717          	auipc	a4,0x1d
    80006246:	dbe70713          	addi	a4,a4,-578 # 80023000 <disk>
    8000624a:	9736                	add	a4,a4,a3
    8000624c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006250:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006254:	7679                	lui	a2,0xffffe
    80006256:	963e                	add	a2,a2,a5
    80006258:	0001f697          	auipc	a3,0x1f
    8000625c:	da868693          	addi	a3,a3,-600 # 80025000 <disk+0x2000>
    80006260:	6298                	ld	a4,0(a3)
    80006262:	9732                	add	a4,a4,a2
    80006264:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006266:	6298                	ld	a4,0(a3)
    80006268:	9732                	add	a4,a4,a2
    8000626a:	4541                	li	a0,16
    8000626c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000626e:	6298                	ld	a4,0(a3)
    80006270:	9732                	add	a4,a4,a2
    80006272:	4505                	li	a0,1
    80006274:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006278:	f9442703          	lw	a4,-108(s0)
    8000627c:	6288                	ld	a0,0(a3)
    8000627e:	962a                	add	a2,a2,a0
    80006280:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	6290                	ld	a2,0(a3)
    80006288:	963a                	add	a2,a2,a4
    8000628a:	05890513          	addi	a0,s2,88
    8000628e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006290:	6294                	ld	a3,0(a3)
    80006292:	96ba                	add	a3,a3,a4
    80006294:	40000613          	li	a2,1024
    80006298:	c690                	sw	a2,8(a3)
  if(write)
    8000629a:	140d0063          	beqz	s10,800063da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000629e:	0001f697          	auipc	a3,0x1f
    800062a2:	d626b683          	ld	a3,-670(a3) # 80025000 <disk+0x2000>
    800062a6:	96ba                	add	a3,a3,a4
    800062a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ac:	0001d817          	auipc	a6,0x1d
    800062b0:	d5480813          	addi	a6,a6,-684 # 80023000 <disk>
    800062b4:	0001f517          	auipc	a0,0x1f
    800062b8:	d4c50513          	addi	a0,a0,-692 # 80025000 <disk+0x2000>
    800062bc:	6114                	ld	a3,0(a0)
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	00c6d603          	lhu	a2,12(a3)
    800062c4:	00166613          	ori	a2,a2,1
    800062c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062cc:	f9842683          	lw	a3,-104(s0)
    800062d0:	6110                	ld	a2,0(a0)
    800062d2:	9732                	add	a4,a4,a2
    800062d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d8:	20058613          	addi	a2,a1,512
    800062dc:	0612                	slli	a2,a2,0x4
    800062de:	9642                	add	a2,a2,a6
    800062e0:	577d                	li	a4,-1
    800062e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e6:	00469713          	slli	a4,a3,0x4
    800062ea:	6114                	ld	a3,0(a0)
    800062ec:	96ba                	add	a3,a3,a4
    800062ee:	03078793          	addi	a5,a5,48
    800062f2:	97c2                	add	a5,a5,a6
    800062f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062f6:	611c                	ld	a5,0(a0)
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	4685                	li	a3,1
    800062fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062fe:	611c                	ld	a5,0(a0)
    80006300:	97ba                	add	a5,a5,a4
    80006302:	4809                	li	a6,2
    80006304:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006308:	611c                	ld	a5,0(a0)
    8000630a:	973e                	add	a4,a4,a5
    8000630c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006310:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006314:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006318:	6518                	ld	a4,8(a0)
    8000631a:	00275783          	lhu	a5,2(a4)
    8000631e:	8b9d                	andi	a5,a5,7
    80006320:	0786                	slli	a5,a5,0x1
    80006322:	97ba                	add	a5,a5,a4
    80006324:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006328:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000632c:	6518                	ld	a4,8(a0)
    8000632e:	00275783          	lhu	a5,2(a4)
    80006332:	2785                	addiw	a5,a5,1
    80006334:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006338:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006344:	00492703          	lw	a4,4(s2)
    80006348:	4785                	li	a5,1
    8000634a:	02f71163          	bne	a4,a5,8000636c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000634e:	0001f997          	auipc	s3,0x1f
    80006352:	dda98993          	addi	s3,s3,-550 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006356:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006358:	85ce                	mv	a1,s3
    8000635a:	854a                	mv	a0,s2
    8000635c:	ffffc097          	auipc	ra,0xffffc
    80006360:	fc8080e7          	jalr	-56(ra) # 80002324 <sleep>
  while(b->disk == 1) {
    80006364:	00492783          	lw	a5,4(s2)
    80006368:	fe9788e3          	beq	a5,s1,80006358 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000636c:	f9042903          	lw	s2,-112(s0)
    80006370:	20090793          	addi	a5,s2,512
    80006374:	00479713          	slli	a4,a5,0x4
    80006378:	0001d797          	auipc	a5,0x1d
    8000637c:	c8878793          	addi	a5,a5,-888 # 80023000 <disk>
    80006380:	97ba                	add	a5,a5,a4
    80006382:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006386:	0001f997          	auipc	s3,0x1f
    8000638a:	c7a98993          	addi	s3,s3,-902 # 80025000 <disk+0x2000>
    8000638e:	00491713          	slli	a4,s2,0x4
    80006392:	0009b783          	ld	a5,0(s3)
    80006396:	97ba                	add	a5,a5,a4
    80006398:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000639c:	854a                	mv	a0,s2
    8000639e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063a2:	00000097          	auipc	ra,0x0
    800063a6:	bc4080e7          	jalr	-1084(ra) # 80005f66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063aa:	8885                	andi	s1,s1,1
    800063ac:	f0ed                	bnez	s1,8000638e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ae:	0001f517          	auipc	a0,0x1f
    800063b2:	d7a50513          	addi	a0,a0,-646 # 80025128 <disk+0x2128>
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
}
    800063be:	70a6                	ld	ra,104(sp)
    800063c0:	7406                	ld	s0,96(sp)
    800063c2:	64e6                	ld	s1,88(sp)
    800063c4:	6946                	ld	s2,80(sp)
    800063c6:	69a6                	ld	s3,72(sp)
    800063c8:	6a06                	ld	s4,64(sp)
    800063ca:	7ae2                	ld	s5,56(sp)
    800063cc:	7b42                	ld	s6,48(sp)
    800063ce:	7ba2                	ld	s7,40(sp)
    800063d0:	7c02                	ld	s8,32(sp)
    800063d2:	6ce2                	ld	s9,24(sp)
    800063d4:	6d42                	ld	s10,16(sp)
    800063d6:	6165                	addi	sp,sp,112
    800063d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063da:	0001f697          	auipc	a3,0x1f
    800063de:	c266b683          	ld	a3,-986(a3) # 80025000 <disk+0x2000>
    800063e2:	96ba                	add	a3,a3,a4
    800063e4:	4609                	li	a2,2
    800063e6:	00c69623          	sh	a2,12(a3)
    800063ea:	b5c9                	j	800062ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063ec:	f9042583          	lw	a1,-112(s0)
    800063f0:	20058793          	addi	a5,a1,512
    800063f4:	0792                	slli	a5,a5,0x4
    800063f6:	0001d517          	auipc	a0,0x1d
    800063fa:	cb250513          	addi	a0,a0,-846 # 800230a8 <disk+0xa8>
    800063fe:	953e                	add	a0,a0,a5
  if(write)
    80006400:	e20d11e3          	bnez	s10,80006222 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006404:	20058713          	addi	a4,a1,512
    80006408:	00471693          	slli	a3,a4,0x4
    8000640c:	0001d717          	auipc	a4,0x1d
    80006410:	bf470713          	addi	a4,a4,-1036 # 80023000 <disk>
    80006414:	9736                	add	a4,a4,a3
    80006416:	0a072423          	sw	zero,168(a4)
    8000641a:	b505                	j	8000623a <virtio_disk_rw+0xf4>

000000008000641c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	e04a                	sd	s2,0(sp)
    80006426:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006428:	0001f517          	auipc	a0,0x1f
    8000642c:	d0050513          	addi	a0,a0,-768 # 80025128 <disk+0x2128>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006438:	10001737          	lui	a4,0x10001
    8000643c:	533c                	lw	a5,96(a4)
    8000643e:	8b8d                	andi	a5,a5,3
    80006440:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006442:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006446:	0001f797          	auipc	a5,0x1f
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80025000 <disk+0x2000>
    8000644e:	6b94                	ld	a3,16(a5)
    80006450:	0207d703          	lhu	a4,32(a5)
    80006454:	0026d783          	lhu	a5,2(a3)
    80006458:	06f70163          	beq	a4,a5,800064ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000645c:	0001d917          	auipc	s2,0x1d
    80006460:	ba490913          	addi	s2,s2,-1116 # 80023000 <disk>
    80006464:	0001f497          	auipc	s1,0x1f
    80006468:	b9c48493          	addi	s1,s1,-1124 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000646c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006470:	6898                	ld	a4,16(s1)
    80006472:	0204d783          	lhu	a5,32(s1)
    80006476:	8b9d                	andi	a5,a5,7
    80006478:	078e                	slli	a5,a5,0x3
    8000647a:	97ba                	add	a5,a5,a4
    8000647c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000647e:	20078713          	addi	a4,a5,512
    80006482:	0712                	slli	a4,a4,0x4
    80006484:	974a                	add	a4,a4,s2
    80006486:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000648a:	e731                	bnez	a4,800064d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000648c:	20078793          	addi	a5,a5,512
    80006490:	0792                	slli	a5,a5,0x4
    80006492:	97ca                	add	a5,a5,s2
    80006494:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006496:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000649a:	ffffc097          	auipc	ra,0xffffc
    8000649e:	030080e7          	jalr	48(ra) # 800024ca <wakeup>

    disk.used_idx += 1;
    800064a2:	0204d783          	lhu	a5,32(s1)
    800064a6:	2785                	addiw	a5,a5,1
    800064a8:	17c2                	slli	a5,a5,0x30
    800064aa:	93c1                	srli	a5,a5,0x30
    800064ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b0:	6898                	ld	a4,16(s1)
    800064b2:	00275703          	lhu	a4,2(a4)
    800064b6:	faf71be3          	bne	a4,a5,8000646c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ba:	0001f517          	auipc	a0,0x1f
    800064be:	c6e50513          	addi	a0,a0,-914 # 80025128 <disk+0x2128>
    800064c2:	ffffa097          	auipc	ra,0xffffa
    800064c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
}
    800064ca:	60e2                	ld	ra,24(sp)
    800064cc:	6442                	ld	s0,16(sp)
    800064ce:	64a2                	ld	s1,8(sp)
    800064d0:	6902                	ld	s2,0(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret
      panic("virtio_disk_intr status");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	3da50513          	addi	a0,a0,986 # 800088b0 <syscalls+0x3c8>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
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
