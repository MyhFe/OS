
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
    80000068:	e4c78793          	addi	a5,a5,-436 # 80005eb0 <timervec>
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
    80000130:	66a080e7          	jalr	1642(ra) # 80002796 <either_copyin>
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
    80000214:	530080e7          	jalr	1328(ra) # 80002740 <either_copyout>
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
    800002f6:	4fa080e7          	jalr	1274(ra) # 800027ec <procdump>
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
    80000ed8:	a58080e7          	jalr	-1448(ra) # 8000292c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	014080e7          	jalr	20(ra) # 80005ef0 <plicinithart>
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
    80000f50:	9b8080e7          	jalr	-1608(ra) # 80002904 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9d8080e7          	jalr	-1576(ra) # 8000292c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f7e080e7          	jalr	-130(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f8c080e7          	jalr	-116(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	164080e7          	jalr	356(ra) # 800030d0 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	7f4080e7          	jalr	2036(ra) # 80003768 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	79e080e7          	jalr	1950(ra) # 8000471a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	08e080e7          	jalr	142(ra) # 80006012 <virtio_disk_init>
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
    80001b72:	d2c080e7          	jalr	-724(ra) # 8000289a <swtch>
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
    80001cec:	c5c080e7          	jalr	-932(ra) # 80002944 <usertrapret>
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
    80001d06:	9e6080e7          	jalr	-1562(ra) # 800036e8 <fsinit>
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
    80001ff4:	126080e7          	jalr	294(ra) # 80004116 <namei>
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
    80002134:	67c080e7          	jalr	1660(ra) # 800047ac <filedup>
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
    80002156:	7d0080e7          	jalr	2000(ra) # 80003922 <idup>
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
    8000224a:	654080e7          	jalr	1620(ra) # 8000289a <swtch>
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

00000000800022ee <pause_system>:
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
    800025c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800025c8:	00007797          	auipc	a5,0x7
    800025cc:	a807b783          	ld	a5,-1408(a5) # 80009048 <initproc>
    800025d0:	0e850493          	addi	s1,a0,232
    800025d4:	16850913          	addi	s2,a0,360
    800025d8:	02a79363          	bne	a5,a0,800025fe <exit+0x52>
    panic("init exiting");
    800025dc:	00006517          	auipc	a0,0x6
    800025e0:	d2450513          	addi	a0,a0,-732 # 80008300 <digits+0x2c0>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
      fileclose(f);
    800025ec:	00002097          	auipc	ra,0x2
    800025f0:	212080e7          	jalr	530(ra) # 800047fe <fileclose>
      p->ofile[fd] = 0;
    800025f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025f8:	04a1                	addi	s1,s1,8
    800025fa:	01248563          	beq	s1,s2,80002604 <exit+0x58>
    if(p->ofile[fd]){
    800025fe:	6088                	ld	a0,0(s1)
    80002600:	f575                	bnez	a0,800025ec <exit+0x40>
    80002602:	bfdd                	j	800025f8 <exit+0x4c>
  begin_op();
    80002604:	00002097          	auipc	ra,0x2
    80002608:	d2e080e7          	jalr	-722(ra) # 80004332 <begin_op>
  iput(p->cwd);
    8000260c:	1689b503          	ld	a0,360(s3)
    80002610:	00001097          	auipc	ra,0x1
    80002614:	50a080e7          	jalr	1290(ra) # 80003b1a <iput>
  end_op();
    80002618:	00002097          	auipc	ra,0x2
    8000261c:	d9a080e7          	jalr	-614(ra) # 800043b2 <end_op>
  p->cwd = 0;
    80002620:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    80002624:	0000f517          	auipc	a0,0xf
    80002628:	0b450513          	addi	a0,a0,180 # 800116d8 <wait_lock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  if((p->pid!=proc[0].pid) && (p->pid!=proc[1].pid)){
    80002634:	0309a783          	lw	a5,48(s3)
    80002638:	0000f717          	auipc	a4,0xf
    8000263c:	0e872703          	lw	a4,232(a4) # 80011720 <proc+0x30>
    80002640:	0af70063          	beq	a4,a5,800026e0 <exit+0x134>
    80002644:	0000f717          	auipc	a4,0xf
    80002648:	25c72703          	lw	a4,604(a4) # 800118a0 <proc+0x1b0>
    8000264c:	08f70a63          	beq	a4,a5,800026e0 <exit+0x134>
    program_time = program_time + p->running_time;
    80002650:	0489a503          	lw	a0,72(s3)
    80002654:	00007717          	auipc	a4,0x7
    80002658:	9d870713          	addi	a4,a4,-1576 # 8000902c <program_time>
    8000265c:	431c                	lw	a5,0(a4)
    8000265e:	00a786bb          	addw	a3,a5,a0
    80002662:	c314                	sw	a3,0(a4)
    cpu_utilization = (100*program_time)/(ticks-start_time);
    80002664:	06400793          	li	a5,100
    80002668:	02d787bb          	mulw	a5,a5,a3
    8000266c:	00007697          	auipc	a3,0x7
    80002670:	9e46a683          	lw	a3,-1564(a3) # 80009050 <ticks>
    80002674:	00007717          	auipc	a4,0x7
    80002678:	9bc72703          	lw	a4,-1604(a4) # 80009030 <start_time>
    8000267c:	9e99                	subw	a3,a3,a4
    8000267e:	02d7d7bb          	divuw	a5,a5,a3
    80002682:	00007717          	auipc	a4,0x7
    80002686:	9af72323          	sw	a5,-1626(a4) # 80009028 <cpu_utilization>
    sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/(exited+1);
    8000268a:	00007617          	auipc	a2,0x7
    8000268e:	9aa62603          	lw	a2,-1622(a2) # 80009034 <exited>
    80002692:	0016059b          	addiw	a1,a2,1
    80002696:	00007797          	auipc	a5,0x7
    8000269a:	9aa78793          	addi	a5,a5,-1622 # 80009040 <sleeping_processes_mean>
    8000269e:	4394                	lw	a3,0(a5)
    800026a0:	02c686bb          	mulw	a3,a3,a2
    800026a4:	0409a703          	lw	a4,64(s3)
    800026a8:	9eb9                	addw	a3,a3,a4
    800026aa:	02b6c6bb          	divw	a3,a3,a1
    800026ae:	c394                	sw	a3,0(a5)
    running_processes_mean = ((running_processes_mean*exited) + p->running_time)/(exited+1);
    800026b0:	00007797          	auipc	a5,0x7
    800026b4:	98c78793          	addi	a5,a5,-1652 # 8000903c <running_processes_mean>
    800026b8:	4398                	lw	a4,0(a5)
    800026ba:	02c7073b          	mulw	a4,a4,a2
    800026be:	9f29                	addw	a4,a4,a0
    800026c0:	02b7473b          	divw	a4,a4,a1
    800026c4:	c398                	sw	a4,0(a5)
    runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/(exited+1);
    800026c6:	00007717          	auipc	a4,0x7
    800026ca:	97270713          	addi	a4,a4,-1678 # 80009038 <runnable_processes_mean>
    800026ce:	431c                	lw	a5,0(a4)
    800026d0:	02c787bb          	mulw	a5,a5,a2
    800026d4:	0449a683          	lw	a3,68(s3)
    800026d8:	9fb5                	addw	a5,a5,a3
    800026da:	02b7c7bb          	divw	a5,a5,a1
    800026de:	c31c                	sw	a5,0(a4)
  exited = exited + 1;
    800026e0:	00007717          	auipc	a4,0x7
    800026e4:	95470713          	addi	a4,a4,-1708 # 80009034 <exited>
    800026e8:	431c                	lw	a5,0(a4)
    800026ea:	2785                	addiw	a5,a5,1
    800026ec:	c31c                	sw	a5,0(a4)
  reparent(p);
    800026ee:	854e                	mv	a0,s3
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	e62080e7          	jalr	-414(ra) # 80002552 <reparent>
  wakeup(p->parent);
    800026f8:	0509b503          	ld	a0,80(s3)
    800026fc:	00000097          	auipc	ra,0x0
    80002700:	dce080e7          	jalr	-562(ra) # 800024ca <wakeup>
  acquire(&p->lock);
    80002704:	854e                	mv	a0,s3
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	4de080e7          	jalr	1246(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000270e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002712:	4795                	li	a5,5
    80002714:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002718:	0000f517          	auipc	a0,0xf
    8000271c:	fc050513          	addi	a0,a0,-64 # 800116d8 <wait_lock>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	578080e7          	jalr	1400(ra) # 80000c98 <release>
  sched();
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	ab2080e7          	jalr	-1358(ra) # 800021da <sched>
  panic("zombie exit");
    80002730:	00006517          	auipc	a0,0x6
    80002734:	be050513          	addi	a0,a0,-1056 # 80008310 <digits+0x2d0>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e06080e7          	jalr	-506(ra) # 8000053e <panic>

0000000080002740 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002740:	7179                	addi	sp,sp,-48
    80002742:	f406                	sd	ra,40(sp)
    80002744:	f022                	sd	s0,32(sp)
    80002746:	ec26                	sd	s1,24(sp)
    80002748:	e84a                	sd	s2,16(sp)
    8000274a:	e44e                	sd	s3,8(sp)
    8000274c:	e052                	sd	s4,0(sp)
    8000274e:	1800                	addi	s0,sp,48
    80002750:	84aa                	mv	s1,a0
    80002752:	892e                	mv	s2,a1
    80002754:	89b2                	mv	s3,a2
    80002756:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	536080e7          	jalr	1334(ra) # 80001c8e <myproc>
  if(user_dst){
    80002760:	c08d                	beqz	s1,80002782 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002762:	86d2                	mv	a3,s4
    80002764:	864e                	mv	a2,s3
    80002766:	85ca                	mv	a1,s2
    80002768:	7528                	ld	a0,104(a0)
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	f08080e7          	jalr	-248(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6a02                	ld	s4,0(sp)
    8000277e:	6145                	addi	sp,sp,48
    80002780:	8082                	ret
    memmove((char *)dst, src, len);
    80002782:	000a061b          	sext.w	a2,s4
    80002786:	85ce                	mv	a1,s3
    80002788:	854a                	mv	a0,s2
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	5b6080e7          	jalr	1462(ra) # 80000d40 <memmove>
    return 0;
    80002792:	8526                	mv	a0,s1
    80002794:	bff9                	j	80002772 <either_copyout+0x32>

0000000080002796 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002796:	7179                	addi	sp,sp,-48
    80002798:	f406                	sd	ra,40(sp)
    8000279a:	f022                	sd	s0,32(sp)
    8000279c:	ec26                	sd	s1,24(sp)
    8000279e:	e84a                	sd	s2,16(sp)
    800027a0:	e44e                	sd	s3,8(sp)
    800027a2:	e052                	sd	s4,0(sp)
    800027a4:	1800                	addi	s0,sp,48
    800027a6:	892a                	mv	s2,a0
    800027a8:	84ae                	mv	s1,a1
    800027aa:	89b2                	mv	s3,a2
    800027ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	4e0080e7          	jalr	1248(ra) # 80001c8e <myproc>
  if(user_src){
    800027b6:	c08d                	beqz	s1,800027d8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027b8:	86d2                	mv	a3,s4
    800027ba:	864e                	mv	a2,s3
    800027bc:	85ca                	mv	a1,s2
    800027be:	7528                	ld	a0,104(a0)
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	f3e080e7          	jalr	-194(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027c8:	70a2                	ld	ra,40(sp)
    800027ca:	7402                	ld	s0,32(sp)
    800027cc:	64e2                	ld	s1,24(sp)
    800027ce:	6942                	ld	s2,16(sp)
    800027d0:	69a2                	ld	s3,8(sp)
    800027d2:	6a02                	ld	s4,0(sp)
    800027d4:	6145                	addi	sp,sp,48
    800027d6:	8082                	ret
    memmove(dst, (char*)src, len);
    800027d8:	000a061b          	sext.w	a2,s4
    800027dc:	85ce                	mv	a1,s3
    800027de:	854a                	mv	a0,s2
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	560080e7          	jalr	1376(ra) # 80000d40 <memmove>
    return 0;
    800027e8:	8526                	mv	a0,s1
    800027ea:	bff9                	j	800027c8 <either_copyin+0x32>

00000000800027ec <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027ec:	715d                	addi	sp,sp,-80
    800027ee:	e486                	sd	ra,72(sp)
    800027f0:	e0a2                	sd	s0,64(sp)
    800027f2:	fc26                	sd	s1,56(sp)
    800027f4:	f84a                	sd	s2,48(sp)
    800027f6:	f44e                	sd	s3,40(sp)
    800027f8:	f052                	sd	s4,32(sp)
    800027fa:	ec56                	sd	s5,24(sp)
    800027fc:	e85a                	sd	s6,16(sp)
    800027fe:	e45e                	sd	s7,8(sp)
    80002800:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002802:	00006517          	auipc	a0,0x6
    80002806:	a0650513          	addi	a0,a0,-1530 # 80008208 <digits+0x1c8>
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	d7e080e7          	jalr	-642(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002812:	0000f497          	auipc	s1,0xf
    80002816:	04e48493          	addi	s1,s1,78 # 80011860 <proc+0x170>
    8000281a:	00015917          	auipc	s2,0x15
    8000281e:	04690913          	addi	s2,s2,70 # 80017860 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002822:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002824:	00006997          	auipc	s3,0x6
    80002828:	afc98993          	addi	s3,s3,-1284 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    8000282c:	00006a97          	auipc	s5,0x6
    80002830:	afca8a93          	addi	s5,s5,-1284 # 80008328 <digits+0x2e8>
    printf("\n");
    80002834:	00006a17          	auipc	s4,0x6
    80002838:	9d4a0a13          	addi	s4,s4,-1580 # 80008208 <digits+0x1c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283c:	00006b97          	auipc	s7,0x6
    80002840:	b24b8b93          	addi	s7,s7,-1244 # 80008360 <states.1745>
    80002844:	a00d                	j	80002866 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002846:	ec06a583          	lw	a1,-320(a3)
    8000284a:	8556                	mv	a0,s5
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d3c080e7          	jalr	-708(ra) # 80000588 <printf>
    printf("\n");
    80002854:	8552                	mv	a0,s4
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	d32080e7          	jalr	-718(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000285e:	18048493          	addi	s1,s1,384
    80002862:	03248163          	beq	s1,s2,80002884 <procdump+0x98>
    if(p->state == UNUSED)
    80002866:	86a6                	mv	a3,s1
    80002868:	ea84a783          	lw	a5,-344(s1)
    8000286c:	dbed                	beqz	a5,8000285e <procdump+0x72>
      state = "???";
    8000286e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002870:	fcfb6be3          	bltu	s6,a5,80002846 <procdump+0x5a>
    80002874:	1782                	slli	a5,a5,0x20
    80002876:	9381                	srli	a5,a5,0x20
    80002878:	078e                	slli	a5,a5,0x3
    8000287a:	97de                	add	a5,a5,s7
    8000287c:	6390                	ld	a2,0(a5)
    8000287e:	f661                	bnez	a2,80002846 <procdump+0x5a>
      state = "???";
    80002880:	864e                	mv	a2,s3
    80002882:	b7d1                	j	80002846 <procdump+0x5a>
  }
}
    80002884:	60a6                	ld	ra,72(sp)
    80002886:	6406                	ld	s0,64(sp)
    80002888:	74e2                	ld	s1,56(sp)
    8000288a:	7942                	ld	s2,48(sp)
    8000288c:	79a2                	ld	s3,40(sp)
    8000288e:	7a02                	ld	s4,32(sp)
    80002890:	6ae2                	ld	s5,24(sp)
    80002892:	6b42                	ld	s6,16(sp)
    80002894:	6ba2                	ld	s7,8(sp)
    80002896:	6161                	addi	sp,sp,80
    80002898:	8082                	ret

000000008000289a <swtch>:
    8000289a:	00153023          	sd	ra,0(a0)
    8000289e:	00253423          	sd	sp,8(a0)
    800028a2:	e900                	sd	s0,16(a0)
    800028a4:	ed04                	sd	s1,24(a0)
    800028a6:	03253023          	sd	s2,32(a0)
    800028aa:	03353423          	sd	s3,40(a0)
    800028ae:	03453823          	sd	s4,48(a0)
    800028b2:	03553c23          	sd	s5,56(a0)
    800028b6:	05653023          	sd	s6,64(a0)
    800028ba:	05753423          	sd	s7,72(a0)
    800028be:	05853823          	sd	s8,80(a0)
    800028c2:	05953c23          	sd	s9,88(a0)
    800028c6:	07a53023          	sd	s10,96(a0)
    800028ca:	07b53423          	sd	s11,104(a0)
    800028ce:	0005b083          	ld	ra,0(a1)
    800028d2:	0085b103          	ld	sp,8(a1)
    800028d6:	6980                	ld	s0,16(a1)
    800028d8:	6d84                	ld	s1,24(a1)
    800028da:	0205b903          	ld	s2,32(a1)
    800028de:	0285b983          	ld	s3,40(a1)
    800028e2:	0305ba03          	ld	s4,48(a1)
    800028e6:	0385ba83          	ld	s5,56(a1)
    800028ea:	0405bb03          	ld	s6,64(a1)
    800028ee:	0485bb83          	ld	s7,72(a1)
    800028f2:	0505bc03          	ld	s8,80(a1)
    800028f6:	0585bc83          	ld	s9,88(a1)
    800028fa:	0605bd03          	ld	s10,96(a1)
    800028fe:	0685bd83          	ld	s11,104(a1)
    80002902:	8082                	ret

0000000080002904 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002904:	1141                	addi	sp,sp,-16
    80002906:	e406                	sd	ra,8(sp)
    80002908:	e022                	sd	s0,0(sp)
    8000290a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000290c:	00006597          	auipc	a1,0x6
    80002910:	a8458593          	addi	a1,a1,-1404 # 80008390 <states.1745+0x30>
    80002914:	00015517          	auipc	a0,0x15
    80002918:	ddc50513          	addi	a0,a0,-548 # 800176f0 <tickslock>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	238080e7          	jalr	568(ra) # 80000b54 <initlock>
}
    80002924:	60a2                	ld	ra,8(sp)
    80002926:	6402                	ld	s0,0(sp)
    80002928:	0141                	addi	sp,sp,16
    8000292a:	8082                	ret

000000008000292c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000292c:	1141                	addi	sp,sp,-16
    8000292e:	e422                	sd	s0,8(sp)
    80002930:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002932:	00003797          	auipc	a5,0x3
    80002936:	4ee78793          	addi	a5,a5,1262 # 80005e20 <kernelvec>
    8000293a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000293e:	6422                	ld	s0,8(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret

0000000080002944 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002944:	1141                	addi	sp,sp,-16
    80002946:	e406                	sd	ra,8(sp)
    80002948:	e022                	sd	s0,0(sp)
    8000294a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	342080e7          	jalr	834(ra) # 80001c8e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002958:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000295e:	00004617          	auipc	a2,0x4
    80002962:	6a260613          	addi	a2,a2,1698 # 80007000 <_trampoline>
    80002966:	00004697          	auipc	a3,0x4
    8000296a:	69a68693          	addi	a3,a3,1690 # 80007000 <_trampoline>
    8000296e:	8e91                	sub	a3,a3,a2
    80002970:	040007b7          	lui	a5,0x4000
    80002974:	17fd                	addi	a5,a5,-1
    80002976:	07b2                	slli	a5,a5,0xc
    80002978:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000297e:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002980:	180026f3          	csrr	a3,satp
    80002984:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002986:	7938                	ld	a4,112(a0)
    80002988:	6d34                	ld	a3,88(a0)
    8000298a:	6585                	lui	a1,0x1
    8000298c:	96ae                	add	a3,a3,a1
    8000298e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002990:	7938                	ld	a4,112(a0)
    80002992:	00000697          	auipc	a3,0x0
    80002996:	13868693          	addi	a3,a3,312 # 80002aca <usertrap>
    8000299a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000299c:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000299e:	8692                	mv	a3,tp
    800029a0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029a6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029aa:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ae:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b2:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b4:	6f18                	ld	a4,24(a4)
    800029b6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ba:	752c                	ld	a1,104(a0)
    800029bc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029be:	00004717          	auipc	a4,0x4
    800029c2:	6d270713          	addi	a4,a4,1746 # 80007090 <userret>
    800029c6:	8f11                	sub	a4,a4,a2
    800029c8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ca:	577d                	li	a4,-1
    800029cc:	177e                	slli	a4,a4,0x3f
    800029ce:	8dd9                	or	a1,a1,a4
    800029d0:	02000537          	lui	a0,0x2000
    800029d4:	157d                	addi	a0,a0,-1
    800029d6:	0536                	slli	a0,a0,0xd
    800029d8:	9782                	jalr	a5
}
    800029da:	60a2                	ld	ra,8(sp)
    800029dc:	6402                	ld	s0,0(sp)
    800029de:	0141                	addi	sp,sp,16
    800029e0:	8082                	ret

00000000800029e2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e2:	1101                	addi	sp,sp,-32
    800029e4:	ec06                	sd	ra,24(sp)
    800029e6:	e822                	sd	s0,16(sp)
    800029e8:	e426                	sd	s1,8(sp)
    800029ea:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ec:	00015497          	auipc	s1,0x15
    800029f0:	d0448493          	addi	s1,s1,-764 # 800176f0 <tickslock>
    800029f4:	8526                	mv	a0,s1
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	1ee080e7          	jalr	494(ra) # 80000be4 <acquire>
  ticks++;
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	65250513          	addi	a0,a0,1618 # 80009050 <ticks>
    80002a06:	411c                	lw	a5,0(a0)
    80002a08:	2785                	addiw	a5,a5,1
    80002a0a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	abe080e7          	jalr	-1346(ra) # 800024ca <wakeup>
  release(&tickslock);
    80002a14:	8526                	mv	a0,s1
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
}
    80002a1e:	60e2                	ld	ra,24(sp)
    80002a20:	6442                	ld	s0,16(sp)
    80002a22:	64a2                	ld	s1,8(sp)
    80002a24:	6105                	addi	sp,sp,32
    80002a26:	8082                	ret

0000000080002a28 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a28:	1101                	addi	sp,sp,-32
    80002a2a:	ec06                	sd	ra,24(sp)
    80002a2c:	e822                	sd	s0,16(sp)
    80002a2e:	e426                	sd	s1,8(sp)
    80002a30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a32:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a36:	00074d63          	bltz	a4,80002a50 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a3a:	57fd                	li	a5,-1
    80002a3c:	17fe                	slli	a5,a5,0x3f
    80002a3e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a40:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a42:	06f70363          	beq	a4,a5,80002aa8 <devintr+0x80>
  }
}
    80002a46:	60e2                	ld	ra,24(sp)
    80002a48:	6442                	ld	s0,16(sp)
    80002a4a:	64a2                	ld	s1,8(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret
     (scause & 0xff) == 9){
    80002a50:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a54:	46a5                	li	a3,9
    80002a56:	fed792e3          	bne	a5,a3,80002a3a <devintr+0x12>
    int irq = plic_claim();
    80002a5a:	00003097          	auipc	ra,0x3
    80002a5e:	4ce080e7          	jalr	1230(ra) # 80005f28 <plic_claim>
    80002a62:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a64:	47a9                	li	a5,10
    80002a66:	02f50763          	beq	a0,a5,80002a94 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a6a:	4785                	li	a5,1
    80002a6c:	02f50963          	beq	a0,a5,80002a9e <devintr+0x76>
    return 1;
    80002a70:	4505                	li	a0,1
    } else if(irq){
    80002a72:	d8f1                	beqz	s1,80002a46 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a74:	85a6                	mv	a1,s1
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	92250513          	addi	a0,a0,-1758 # 80008398 <states.1745+0x38>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b0a080e7          	jalr	-1270(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a86:	8526                	mv	a0,s1
    80002a88:	00003097          	auipc	ra,0x3
    80002a8c:	4c4080e7          	jalr	1220(ra) # 80005f4c <plic_complete>
    return 1;
    80002a90:	4505                	li	a0,1
    80002a92:	bf55                	j	80002a46 <devintr+0x1e>
      uartintr();
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	f14080e7          	jalr	-236(ra) # 800009a8 <uartintr>
    80002a9c:	b7ed                	j	80002a86 <devintr+0x5e>
      virtio_disk_intr();
    80002a9e:	00004097          	auipc	ra,0x4
    80002aa2:	98e080e7          	jalr	-1650(ra) # 8000642c <virtio_disk_intr>
    80002aa6:	b7c5                	j	80002a86 <devintr+0x5e>
    if(cpuid() == 0){
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	1ba080e7          	jalr	442(ra) # 80001c62 <cpuid>
    80002ab0:	c901                	beqz	a0,80002ac0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ab6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ab8:	14479073          	csrw	sip,a5
    return 2;
    80002abc:	4509                	li	a0,2
    80002abe:	b761                	j	80002a46 <devintr+0x1e>
      clockintr();
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	f22080e7          	jalr	-222(ra) # 800029e2 <clockintr>
    80002ac8:	b7ed                	j	80002ab2 <devintr+0x8a>

0000000080002aca <usertrap>:
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	e04a                	sd	s2,0(sp)
    80002ad4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ada:	1007f793          	andi	a5,a5,256
    80002ade:	e3ad                	bnez	a5,80002b40 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae0:	00003797          	auipc	a5,0x3
    80002ae4:	34078793          	addi	a5,a5,832 # 80005e20 <kernelvec>
    80002ae8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	1a2080e7          	jalr	418(ra) # 80001c8e <myproc>
    80002af4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002af6:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af8:	14102773          	csrr	a4,sepc
    80002afc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afe:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b02:	47a1                	li	a5,8
    80002b04:	04f71c63          	bne	a4,a5,80002b5c <usertrap+0x92>
    if(p->killed)
    80002b08:	551c                	lw	a5,40(a0)
    80002b0a:	e3b9                	bnez	a5,80002b50 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b0c:	78b8                	ld	a4,112(s1)
    80002b0e:	6f1c                	ld	a5,24(a4)
    80002b10:	0791                	addi	a5,a5,4
    80002b12:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	2e0080e7          	jalr	736(ra) # 80002e00 <syscall>
  if(p->killed)
    80002b28:	549c                	lw	a5,40(s1)
    80002b2a:	ebc1                	bnez	a5,80002bba <usertrap+0xf0>
  usertrapret();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	e18080e7          	jalr	-488(ra) # 80002944 <usertrapret>
}
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6902                	ld	s2,0(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret
    panic("usertrap: not from user mode");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	87850513          	addi	a0,a0,-1928 # 800083b8 <states.1745+0x58>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
      exit(-1);
    80002b50:	557d                	li	a0,-1
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	a5a080e7          	jalr	-1446(ra) # 800025ac <exit>
    80002b5a:	bf4d                	j	80002b0c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	ecc080e7          	jalr	-308(ra) # 80002a28 <devintr>
    80002b64:	892a                	mv	s2,a0
    80002b66:	c501                	beqz	a0,80002b6e <usertrap+0xa4>
  if(p->killed)
    80002b68:	549c                	lw	a5,40(s1)
    80002b6a:	c3a1                	beqz	a5,80002baa <usertrap+0xe0>
    80002b6c:	a815                	j	80002ba0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b72:	5890                	lw	a2,48(s1)
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	86450513          	addi	a0,a0,-1948 # 800083d8 <states.1745+0x78>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	a0c080e7          	jalr	-1524(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b84:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b88:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b8c:	00006517          	auipc	a0,0x6
    80002b90:	87c50513          	addi	a0,a0,-1924 # 80008408 <states.1745+0xa8>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f4080e7          	jalr	-1548(ra) # 80000588 <printf>
    p->killed = 1;
    80002b9c:	4785                	li	a5,1
    80002b9e:	d49c                	sw	a5,40(s1)
    exit(-1); 
    80002ba0:	557d                	li	a0,-1
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	a0a080e7          	jalr	-1526(ra) # 800025ac <exit>
  if(which_dev == 2)
    80002baa:	4789                	li	a5,2
    80002bac:	f8f910e3          	bne	s2,a5,80002b2c <usertrap+0x62>
    yield();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	6f8080e7          	jalr	1784(ra) # 800022a8 <yield>
    80002bb8:	bf95                	j	80002b2c <usertrap+0x62>
  int which_dev = 0;
    80002bba:	4901                	li	s2,0
    80002bbc:	b7d5                	j	80002ba0 <usertrap+0xd6>

0000000080002bbe <kerneltrap>:
{
    80002bbe:	7179                	addi	sp,sp,-48
    80002bc0:	f406                	sd	ra,40(sp)
    80002bc2:	f022                	sd	s0,32(sp)
    80002bc4:	ec26                	sd	s1,24(sp)
    80002bc6:	e84a                	sd	s2,16(sp)
    80002bc8:	e44e                	sd	s3,8(sp)
    80002bca:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bcc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bd8:	1004f793          	andi	a5,s1,256
    80002bdc:	cb85                	beqz	a5,80002c0c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be4:	ef85                	bnez	a5,80002c1c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	e42080e7          	jalr	-446(ra) # 80002a28 <devintr>
    80002bee:	cd1d                	beqz	a0,80002c2c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf0:	4789                	li	a5,2
    80002bf2:	06f50a63          	beq	a0,a5,80002c66 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bfa:	10049073          	csrw	sstatus,s1
}
    80002bfe:	70a2                	ld	ra,40(sp)
    80002c00:	7402                	ld	s0,32(sp)
    80002c02:	64e2                	ld	s1,24(sp)
    80002c04:	6942                	ld	s2,16(sp)
    80002c06:	69a2                	ld	s3,8(sp)
    80002c08:	6145                	addi	sp,sp,48
    80002c0a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	81c50513          	addi	a0,a0,-2020 # 80008428 <states.1745+0xc8>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	92a080e7          	jalr	-1750(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c1c:	00006517          	auipc	a0,0x6
    80002c20:	83450513          	addi	a0,a0,-1996 # 80008450 <states.1745+0xf0>
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	91a080e7          	jalr	-1766(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c2c:	85ce                	mv	a1,s3
    80002c2e:	00006517          	auipc	a0,0x6
    80002c32:	84250513          	addi	a0,a0,-1982 # 80008470 <states.1745+0x110>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	952080e7          	jalr	-1710(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c42:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c46:	00006517          	auipc	a0,0x6
    80002c4a:	83a50513          	addi	a0,a0,-1990 # 80008480 <states.1745+0x120>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	93a080e7          	jalr	-1734(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c56:	00006517          	auipc	a0,0x6
    80002c5a:	84250513          	addi	a0,a0,-1982 # 80008498 <states.1745+0x138>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	8e0080e7          	jalr	-1824(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	028080e7          	jalr	40(ra) # 80001c8e <myproc>
    80002c6e:	d541                	beqz	a0,80002bf6 <kerneltrap+0x38>
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	01e080e7          	jalr	30(ra) # 80001c8e <myproc>
    80002c78:	4d18                	lw	a4,24(a0)
    80002c7a:	4791                	li	a5,4
    80002c7c:	f6f71de3          	bne	a4,a5,80002bf6 <kerneltrap+0x38>
    yield();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	628080e7          	jalr	1576(ra) # 800022a8 <yield>
    80002c88:	b7bd                	j	80002bf6 <kerneltrap+0x38>

0000000080002c8a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	1000                	addi	s0,sp,32
    80002c94:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	ff8080e7          	jalr	-8(ra) # 80001c8e <myproc>
  switch (n) {
    80002c9e:	4795                	li	a5,5
    80002ca0:	0497e163          	bltu	a5,s1,80002ce2 <argraw+0x58>
    80002ca4:	048a                	slli	s1,s1,0x2
    80002ca6:	00006717          	auipc	a4,0x6
    80002caa:	82a70713          	addi	a4,a4,-2006 # 800084d0 <states.1745+0x170>
    80002cae:	94ba                	add	s1,s1,a4
    80002cb0:	409c                	lw	a5,0(s1)
    80002cb2:	97ba                	add	a5,a5,a4
    80002cb4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cb6:	793c                	ld	a5,112(a0)
    80002cb8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	64a2                	ld	s1,8(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
    return p->trapframe->a1;
    80002cc4:	793c                	ld	a5,112(a0)
    80002cc6:	7fa8                	ld	a0,120(a5)
    80002cc8:	bfcd                	j	80002cba <argraw+0x30>
    return p->trapframe->a2;
    80002cca:	793c                	ld	a5,112(a0)
    80002ccc:	63c8                	ld	a0,128(a5)
    80002cce:	b7f5                	j	80002cba <argraw+0x30>
    return p->trapframe->a3;
    80002cd0:	793c                	ld	a5,112(a0)
    80002cd2:	67c8                	ld	a0,136(a5)
    80002cd4:	b7dd                	j	80002cba <argraw+0x30>
    return p->trapframe->a4;
    80002cd6:	793c                	ld	a5,112(a0)
    80002cd8:	6bc8                	ld	a0,144(a5)
    80002cda:	b7c5                	j	80002cba <argraw+0x30>
    return p->trapframe->a5;
    80002cdc:	793c                	ld	a5,112(a0)
    80002cde:	6fc8                	ld	a0,152(a5)
    80002ce0:	bfe9                	j	80002cba <argraw+0x30>
  panic("argraw");
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	7c650513          	addi	a0,a0,1990 # 800084a8 <states.1745+0x148>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080002cf2 <fetchaddr>:
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	e04a                	sd	s2,0(sp)
    80002cfc:	1000                	addi	s0,sp,32
    80002cfe:	84aa                	mv	s1,a0
    80002d00:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	f8c080e7          	jalr	-116(ra) # 80001c8e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d0a:	713c                	ld	a5,96(a0)
    80002d0c:	02f4f863          	bgeu	s1,a5,80002d3c <fetchaddr+0x4a>
    80002d10:	00848713          	addi	a4,s1,8
    80002d14:	02e7e663          	bltu	a5,a4,80002d40 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d18:	46a1                	li	a3,8
    80002d1a:	8626                	mv	a2,s1
    80002d1c:	85ca                	mv	a1,s2
    80002d1e:	7528                	ld	a0,104(a0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	9de080e7          	jalr	-1570(ra) # 800016fe <copyin>
    80002d28:	00a03533          	snez	a0,a0
    80002d2c:	40a00533          	neg	a0,a0
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6902                	ld	s2,0(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret
    return -1;
    80002d3c:	557d                	li	a0,-1
    80002d3e:	bfcd                	j	80002d30 <fetchaddr+0x3e>
    80002d40:	557d                	li	a0,-1
    80002d42:	b7fd                	j	80002d30 <fetchaddr+0x3e>

0000000080002d44 <fetchstr>:
{
    80002d44:	7179                	addi	sp,sp,-48
    80002d46:	f406                	sd	ra,40(sp)
    80002d48:	f022                	sd	s0,32(sp)
    80002d4a:	ec26                	sd	s1,24(sp)
    80002d4c:	e84a                	sd	s2,16(sp)
    80002d4e:	e44e                	sd	s3,8(sp)
    80002d50:	1800                	addi	s0,sp,48
    80002d52:	892a                	mv	s2,a0
    80002d54:	84ae                	mv	s1,a1
    80002d56:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	f36080e7          	jalr	-202(ra) # 80001c8e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d60:	86ce                	mv	a3,s3
    80002d62:	864a                	mv	a2,s2
    80002d64:	85a6                	mv	a1,s1
    80002d66:	7528                	ld	a0,104(a0)
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	a22080e7          	jalr	-1502(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d70:	00054763          	bltz	a0,80002d7e <fetchstr+0x3a>
  return strlen(buf);
    80002d74:	8526                	mv	a0,s1
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	0ee080e7          	jalr	238(ra) # 80000e64 <strlen>
}
    80002d7e:	70a2                	ld	ra,40(sp)
    80002d80:	7402                	ld	s0,32(sp)
    80002d82:	64e2                	ld	s1,24(sp)
    80002d84:	6942                	ld	s2,16(sp)
    80002d86:	69a2                	ld	s3,8(sp)
    80002d88:	6145                	addi	sp,sp,48
    80002d8a:	8082                	ret

0000000080002d8c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d8c:	1101                	addi	sp,sp,-32
    80002d8e:	ec06                	sd	ra,24(sp)
    80002d90:	e822                	sd	s0,16(sp)
    80002d92:	e426                	sd	s1,8(sp)
    80002d94:	1000                	addi	s0,sp,32
    80002d96:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	ef2080e7          	jalr	-270(ra) # 80002c8a <argraw>
    80002da0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002da2:	4501                	li	a0,0
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	64a2                	ld	s1,8(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	ed0080e7          	jalr	-304(ra) # 80002c8a <argraw>
    80002dc2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc4:	4501                	li	a0,0
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	e426                	sd	s1,8(sp)
    80002dd8:	e04a                	sd	s2,0(sp)
    80002dda:	1000                	addi	s0,sp,32
    80002ddc:	84ae                	mv	s1,a1
    80002dde:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	eaa080e7          	jalr	-342(ra) # 80002c8a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002de8:	864a                	mv	a2,s2
    80002dea:	85a6                	mv	a1,s1
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	f58080e7          	jalr	-168(ra) # 80002d44 <fetchstr>
}
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	64a2                	ld	s1,8(sp)
    80002dfa:	6902                	ld	s2,0(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	e426                	sd	s1,8(sp)
    80002e08:	e04a                	sd	s2,0(sp)
    80002e0a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	e82080e7          	jalr	-382(ra) # 80001c8e <myproc>
    80002e14:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e16:	07053903          	ld	s2,112(a0)
    80002e1a:	0a893783          	ld	a5,168(s2)
    80002e1e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e22:	37fd                	addiw	a5,a5,-1
    80002e24:	475d                	li	a4,23
    80002e26:	00f76f63          	bltu	a4,a5,80002e44 <syscall+0x44>
    80002e2a:	00369713          	slli	a4,a3,0x3
    80002e2e:	00005797          	auipc	a5,0x5
    80002e32:	6ba78793          	addi	a5,a5,1722 # 800084e8 <syscalls>
    80002e36:	97ba                	add	a5,a5,a4
    80002e38:	639c                	ld	a5,0(a5)
    80002e3a:	c789                	beqz	a5,80002e44 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e3c:	9782                	jalr	a5
    80002e3e:	06a93823          	sd	a0,112(s2)
    80002e42:	a839                	j	80002e60 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e44:	17048613          	addi	a2,s1,368
    80002e48:	588c                	lw	a1,48(s1)
    80002e4a:	00005517          	auipc	a0,0x5
    80002e4e:	66650513          	addi	a0,a0,1638 # 800084b0 <states.1745+0x150>
    80002e52:	ffffd097          	auipc	ra,0xffffd
    80002e56:	736080e7          	jalr	1846(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e5a:	78bc                	ld	a5,112(s1)
    80002e5c:	577d                	li	a4,-1
    80002e5e:	fbb8                	sd	a4,112(a5)
  }
}
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	64a2                	ld	s1,8(sp)
    80002e66:	6902                	ld	s2,0(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e74:	fec40593          	addi	a1,s0,-20
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	f12080e7          	jalr	-238(ra) # 80002d8c <argint>
    return -1;
    80002e82:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e84:	00054963          	bltz	a0,80002e96 <sys_exit+0x2a>
  exit(n);
    80002e88:	fec42503          	lw	a0,-20(s0)
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	720080e7          	jalr	1824(ra) # 800025ac <exit>
  return 0;  // not reached
    80002e94:	4781                	li	a5,0
}
    80002e96:	853e                	mv	a0,a5
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	6105                	addi	sp,sp,32
    80002e9e:	8082                	ret

0000000080002ea0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea0:	1141                	addi	sp,sp,-16
    80002ea2:	e406                	sd	ra,8(sp)
    80002ea4:	e022                	sd	s0,0(sp)
    80002ea6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	de6080e7          	jalr	-538(ra) # 80001c8e <myproc>
}
    80002eb0:	5908                	lw	a0,48(a0)
    80002eb2:	60a2                	ld	ra,8(sp)
    80002eb4:	6402                	ld	s0,0(sp)
    80002eb6:	0141                	addi	sp,sp,16
    80002eb8:	8082                	ret

0000000080002eba <sys_fork>:

uint64
sys_fork(void)
{
    80002eba:	1141                	addi	sp,sp,-16
    80002ebc:	e406                	sd	ra,8(sp)
    80002ebe:	e022                	sd	s0,0(sp)
    80002ec0:	0800                	addi	s0,sp,16
  return fork();
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	1d0080e7          	jalr	464(ra) # 80002092 <fork>
}
    80002eca:	60a2                	ld	ra,8(sp)
    80002ecc:	6402                	ld	s0,0(sp)
    80002ece:	0141                	addi	sp,sp,16
    80002ed0:	8082                	ret

0000000080002ed2 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002eda:	fe840593          	addi	a1,s0,-24
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	ece080e7          	jalr	-306(ra) # 80002dae <argaddr>
    80002ee8:	87aa                	mv	a5,a0
    return -1;
    80002eea:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002eec:	0007c863          	bltz	a5,80002efc <sys_wait+0x2a>
  return wait(p);
    80002ef0:	fe843503          	ld	a0,-24(s0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	4ae080e7          	jalr	1198(ra) # 800023a2 <wait>
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_print_stats>:

void
sys_print_stats(void)
{
    80002f04:	1141                	addi	sp,sp,-16
    80002f06:	e406                	sd	ra,8(sp)
    80002f08:	e022                	sd	s0,0(sp)
    80002f0a:	0800                	addi	s0,sp,16
  return print_stats();
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	ad8080e7          	jalr	-1320(ra) # 800019e4 <print_stats>
}
    80002f14:	60a2                	ld	ra,8(sp)
    80002f16:	6402                	ld	s0,0(sp)
    80002f18:	0141                	addi	sp,sp,16
    80002f1a:	8082                	ret

0000000080002f1c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f1c:	7179                	addi	sp,sp,-48
    80002f1e:	f406                	sd	ra,40(sp)
    80002f20:	f022                	sd	s0,32(sp)
    80002f22:	ec26                	sd	s1,24(sp)
    80002f24:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f26:	fdc40593          	addi	a1,s0,-36
    80002f2a:	4501                	li	a0,0
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	e60080e7          	jalr	-416(ra) # 80002d8c <argint>
    80002f34:	87aa                	mv	a5,a0
    return -1;
    80002f36:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f38:	0207c063          	bltz	a5,80002f58 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	d52080e7          	jalr	-686(ra) # 80001c8e <myproc>
    80002f44:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80002f46:	fdc42503          	lw	a0,-36(s0)
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	0d4080e7          	jalr	212(ra) # 8000201e <growproc>
    80002f52:	00054863          	bltz	a0,80002f62 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f56:	8526                	mv	a0,s1
}
    80002f58:	70a2                	ld	ra,40(sp)
    80002f5a:	7402                	ld	s0,32(sp)
    80002f5c:	64e2                	ld	s1,24(sp)
    80002f5e:	6145                	addi	sp,sp,48
    80002f60:	8082                	ret
    return -1;
    80002f62:	557d                	li	a0,-1
    80002f64:	bfd5                	j	80002f58 <sys_sbrk+0x3c>

0000000080002f66 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f66:	7139                	addi	sp,sp,-64
    80002f68:	fc06                	sd	ra,56(sp)
    80002f6a:	f822                	sd	s0,48(sp)
    80002f6c:	f426                	sd	s1,40(sp)
    80002f6e:	f04a                	sd	s2,32(sp)
    80002f70:	ec4e                	sd	s3,24(sp)
    80002f72:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f74:	fcc40593          	addi	a1,s0,-52
    80002f78:	4501                	li	a0,0
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	e12080e7          	jalr	-494(ra) # 80002d8c <argint>
    return -1;
    80002f82:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f84:	06054563          	bltz	a0,80002fee <sys_sleep+0x88>
  acquire(&tickslock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	76850513          	addi	a0,a0,1896 # 800176f0 <tickslock>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	c54080e7          	jalr	-940(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f98:	00006917          	auipc	s2,0x6
    80002f9c:	0b892903          	lw	s2,184(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002fa0:	fcc42783          	lw	a5,-52(s0)
    80002fa4:	cf85                	beqz	a5,80002fdc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fa6:	00014997          	auipc	s3,0x14
    80002faa:	74a98993          	addi	s3,s3,1866 # 800176f0 <tickslock>
    80002fae:	00006497          	auipc	s1,0x6
    80002fb2:	0a248493          	addi	s1,s1,162 # 80009050 <ticks>
    if(myproc()->killed){
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	cd8080e7          	jalr	-808(ra) # 80001c8e <myproc>
    80002fbe:	551c                	lw	a5,40(a0)
    80002fc0:	ef9d                	bnez	a5,80002ffe <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fc2:	85ce                	mv	a1,s3
    80002fc4:	8526                	mv	a0,s1
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	35e080e7          	jalr	862(ra) # 80002324 <sleep>
  while(ticks - ticks0 < n){
    80002fce:	409c                	lw	a5,0(s1)
    80002fd0:	412787bb          	subw	a5,a5,s2
    80002fd4:	fcc42703          	lw	a4,-52(s0)
    80002fd8:	fce7efe3          	bltu	a5,a4,80002fb6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fdc:	00014517          	auipc	a0,0x14
    80002fe0:	71450513          	addi	a0,a0,1812 # 800176f0 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	cb4080e7          	jalr	-844(ra) # 80000c98 <release>
  return 0;
    80002fec:	4781                	li	a5,0
}
    80002fee:	853e                	mv	a0,a5
    80002ff0:	70e2                	ld	ra,56(sp)
    80002ff2:	7442                	ld	s0,48(sp)
    80002ff4:	74a2                	ld	s1,40(sp)
    80002ff6:	7902                	ld	s2,32(sp)
    80002ff8:	69e2                	ld	s3,24(sp)
    80002ffa:	6121                	addi	sp,sp,64
    80002ffc:	8082                	ret
      release(&tickslock);
    80002ffe:	00014517          	auipc	a0,0x14
    80003002:	6f250513          	addi	a0,a0,1778 # 800176f0 <tickslock>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	c92080e7          	jalr	-878(ra) # 80000c98 <release>
      return -1;
    8000300e:	57fd                	li	a5,-1
    80003010:	bff9                	j	80002fee <sys_sleep+0x88>

0000000080003012 <sys_kill>:

uint64
sys_kill(void)
{
    80003012:	1101                	addi	sp,sp,-32
    80003014:	ec06                	sd	ra,24(sp)
    80003016:	e822                	sd	s0,16(sp)
    80003018:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000301a:	fec40593          	addi	a1,s0,-20
    8000301e:	4501                	li	a0,0
    80003020:	00000097          	auipc	ra,0x0
    80003024:	d6c080e7          	jalr	-660(ra) # 80002d8c <argint>
    80003028:	87aa                	mv	a5,a0
    return -1;
    8000302a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000302c:	0007c863          	bltz	a5,8000303c <sys_kill+0x2a>
  return kill(pid);
    80003030:	fec42503          	lw	a0,-20(s0)
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	8a0080e7          	jalr	-1888(ra) # 800018d4 <kill>
}
    8000303c:	60e2                	ld	ra,24(sp)
    8000303e:	6442                	ld	s0,16(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret

0000000080003044 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003044:	1141                	addi	sp,sp,-16
    80003046:	e406                	sd	ra,8(sp)
    80003048:	e022                	sd	s0,0(sp)
    8000304a:	0800                	addi	s0,sp,16
  return kill_system();
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	904080e7          	jalr	-1788(ra) # 80001950 <kill_system>
}
    80003054:	60a2                	ld	ra,8(sp)
    80003056:	6402                	ld	s0,0(sp)
    80003058:	0141                	addi	sp,sp,16
    8000305a:	8082                	ret

000000008000305c <sys_pause_system>:


uint64
sys_pause_system(void)
{
    8000305c:	1101                	addi	sp,sp,-32
    8000305e:	ec06                	sd	ra,24(sp)
    80003060:	e822                	sd	s0,16(sp)
    80003062:	1000                	addi	s0,sp,32
  int time;

  if(argint(0, &time) < 0)
    80003064:	fec40593          	addi	a1,s0,-20
    80003068:	4501                	li	a0,0
    8000306a:	00000097          	auipc	ra,0x0
    8000306e:	d22080e7          	jalr	-734(ra) # 80002d8c <argint>
    80003072:	87aa                	mv	a5,a0
    return -1;
    80003074:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80003076:	0007c863          	bltz	a5,80003086 <sys_pause_system+0x2a>
  return pause_system(time);
    8000307a:	fec42503          	lw	a0,-20(s0)
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	270080e7          	jalr	624(ra) # 800022ee <pause_system>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret

000000008000308e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	e426                	sd	s1,8(sp)
    80003096:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003098:	00014517          	auipc	a0,0x14
    8000309c:	65850513          	addi	a0,a0,1624 # 800176f0 <tickslock>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030a8:	00006497          	auipc	s1,0x6
    800030ac:	fa84a483          	lw	s1,-88(s1) # 80009050 <ticks>
  release(&tickslock);
    800030b0:	00014517          	auipc	a0,0x14
    800030b4:	64050513          	addi	a0,a0,1600 # 800176f0 <tickslock>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
  return xticks;
}
    800030c0:	02049513          	slli	a0,s1,0x20
    800030c4:	9101                	srli	a0,a0,0x20
    800030c6:	60e2                	ld	ra,24(sp)
    800030c8:	6442                	ld	s0,16(sp)
    800030ca:	64a2                	ld	s1,8(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret

00000000800030d0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030d0:	7179                	addi	sp,sp,-48
    800030d2:	f406                	sd	ra,40(sp)
    800030d4:	f022                	sd	s0,32(sp)
    800030d6:	ec26                	sd	s1,24(sp)
    800030d8:	e84a                	sd	s2,16(sp)
    800030da:	e44e                	sd	s3,8(sp)
    800030dc:	e052                	sd	s4,0(sp)
    800030de:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030e0:	00005597          	auipc	a1,0x5
    800030e4:	4d058593          	addi	a1,a1,1232 # 800085b0 <syscalls+0xc8>
    800030e8:	00014517          	auipc	a0,0x14
    800030ec:	62050513          	addi	a0,a0,1568 # 80017708 <bcache>
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	a64080e7          	jalr	-1436(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030f8:	0001c797          	auipc	a5,0x1c
    800030fc:	61078793          	addi	a5,a5,1552 # 8001f708 <bcache+0x8000>
    80003100:	0001d717          	auipc	a4,0x1d
    80003104:	87070713          	addi	a4,a4,-1936 # 8001f970 <bcache+0x8268>
    80003108:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000310c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003110:	00014497          	auipc	s1,0x14
    80003114:	61048493          	addi	s1,s1,1552 # 80017720 <bcache+0x18>
    b->next = bcache.head.next;
    80003118:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000311a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000311c:	00005a17          	auipc	s4,0x5
    80003120:	49ca0a13          	addi	s4,s4,1180 # 800085b8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003124:	2b893783          	ld	a5,696(s2)
    80003128:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000312a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000312e:	85d2                	mv	a1,s4
    80003130:	01048513          	addi	a0,s1,16
    80003134:	00001097          	auipc	ra,0x1
    80003138:	4bc080e7          	jalr	1212(ra) # 800045f0 <initsleeplock>
    bcache.head.next->prev = b;
    8000313c:	2b893783          	ld	a5,696(s2)
    80003140:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003142:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003146:	45848493          	addi	s1,s1,1112
    8000314a:	fd349de3          	bne	s1,s3,80003124 <binit+0x54>
  }
}
    8000314e:	70a2                	ld	ra,40(sp)
    80003150:	7402                	ld	s0,32(sp)
    80003152:	64e2                	ld	s1,24(sp)
    80003154:	6942                	ld	s2,16(sp)
    80003156:	69a2                	ld	s3,8(sp)
    80003158:	6a02                	ld	s4,0(sp)
    8000315a:	6145                	addi	sp,sp,48
    8000315c:	8082                	ret

000000008000315e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000315e:	7179                	addi	sp,sp,-48
    80003160:	f406                	sd	ra,40(sp)
    80003162:	f022                	sd	s0,32(sp)
    80003164:	ec26                	sd	s1,24(sp)
    80003166:	e84a                	sd	s2,16(sp)
    80003168:	e44e                	sd	s3,8(sp)
    8000316a:	1800                	addi	s0,sp,48
    8000316c:	89aa                	mv	s3,a0
    8000316e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003170:	00014517          	auipc	a0,0x14
    80003174:	59850513          	addi	a0,a0,1432 # 80017708 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003180:	0001d497          	auipc	s1,0x1d
    80003184:	8404b483          	ld	s1,-1984(s1) # 8001f9c0 <bcache+0x82b8>
    80003188:	0001c797          	auipc	a5,0x1c
    8000318c:	7e878793          	addi	a5,a5,2024 # 8001f970 <bcache+0x8268>
    80003190:	02f48f63          	beq	s1,a5,800031ce <bread+0x70>
    80003194:	873e                	mv	a4,a5
    80003196:	a021                	j	8000319e <bread+0x40>
    80003198:	68a4                	ld	s1,80(s1)
    8000319a:	02e48a63          	beq	s1,a4,800031ce <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000319e:	449c                	lw	a5,8(s1)
    800031a0:	ff379ce3          	bne	a5,s3,80003198 <bread+0x3a>
    800031a4:	44dc                	lw	a5,12(s1)
    800031a6:	ff2799e3          	bne	a5,s2,80003198 <bread+0x3a>
      b->refcnt++;
    800031aa:	40bc                	lw	a5,64(s1)
    800031ac:	2785                	addiw	a5,a5,1
    800031ae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b0:	00014517          	auipc	a0,0x14
    800031b4:	55850513          	addi	a0,a0,1368 # 80017708 <bcache>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	ae0080e7          	jalr	-1312(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031c0:	01048513          	addi	a0,s1,16
    800031c4:	00001097          	auipc	ra,0x1
    800031c8:	466080e7          	jalr	1126(ra) # 8000462a <acquiresleep>
      return b;
    800031cc:	a8b9                	j	8000322a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ce:	0001c497          	auipc	s1,0x1c
    800031d2:	7ea4b483          	ld	s1,2026(s1) # 8001f9b8 <bcache+0x82b0>
    800031d6:	0001c797          	auipc	a5,0x1c
    800031da:	79a78793          	addi	a5,a5,1946 # 8001f970 <bcache+0x8268>
    800031de:	00f48863          	beq	s1,a5,800031ee <bread+0x90>
    800031e2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031e4:	40bc                	lw	a5,64(s1)
    800031e6:	cf81                	beqz	a5,800031fe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e8:	64a4                	ld	s1,72(s1)
    800031ea:	fee49de3          	bne	s1,a4,800031e4 <bread+0x86>
  panic("bget: no buffers");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	3d250513          	addi	a0,a0,978 # 800085c0 <syscalls+0xd8>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	348080e7          	jalr	840(ra) # 8000053e <panic>
      b->dev = dev;
    800031fe:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003202:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003206:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000320a:	4785                	li	a5,1
    8000320c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000320e:	00014517          	auipc	a0,0x14
    80003212:	4fa50513          	addi	a0,a0,1274 # 80017708 <bcache>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000321e:	01048513          	addi	a0,s1,16
    80003222:	00001097          	auipc	ra,0x1
    80003226:	408080e7          	jalr	1032(ra) # 8000462a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000322a:	409c                	lw	a5,0(s1)
    8000322c:	cb89                	beqz	a5,8000323e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000322e:	8526                	mv	a0,s1
    80003230:	70a2                	ld	ra,40(sp)
    80003232:	7402                	ld	s0,32(sp)
    80003234:	64e2                	ld	s1,24(sp)
    80003236:	6942                	ld	s2,16(sp)
    80003238:	69a2                	ld	s3,8(sp)
    8000323a:	6145                	addi	sp,sp,48
    8000323c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000323e:	4581                	li	a1,0
    80003240:	8526                	mv	a0,s1
    80003242:	00003097          	auipc	ra,0x3
    80003246:	f14080e7          	jalr	-236(ra) # 80006156 <virtio_disk_rw>
    b->valid = 1;
    8000324a:	4785                	li	a5,1
    8000324c:	c09c                	sw	a5,0(s1)
  return b;
    8000324e:	b7c5                	j	8000322e <bread+0xd0>

0000000080003250 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	1000                	addi	s0,sp,32
    8000325a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000325c:	0541                	addi	a0,a0,16
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	466080e7          	jalr	1126(ra) # 800046c4 <holdingsleep>
    80003266:	cd01                	beqz	a0,8000327e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003268:	4585                	li	a1,1
    8000326a:	8526                	mv	a0,s1
    8000326c:	00003097          	auipc	ra,0x3
    80003270:	eea080e7          	jalr	-278(ra) # 80006156 <virtio_disk_rw>
}
    80003274:	60e2                	ld	ra,24(sp)
    80003276:	6442                	ld	s0,16(sp)
    80003278:	64a2                	ld	s1,8(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret
    panic("bwrite");
    8000327e:	00005517          	auipc	a0,0x5
    80003282:	35a50513          	addi	a0,a0,858 # 800085d8 <syscalls+0xf0>
    80003286:	ffffd097          	auipc	ra,0xffffd
    8000328a:	2b8080e7          	jalr	696(ra) # 8000053e <panic>

000000008000328e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	e04a                	sd	s2,0(sp)
    80003298:	1000                	addi	s0,sp,32
    8000329a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000329c:	01050913          	addi	s2,a0,16
    800032a0:	854a                	mv	a0,s2
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	422080e7          	jalr	1058(ra) # 800046c4 <holdingsleep>
    800032aa:	c92d                	beqz	a0,8000331c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ac:	854a                	mv	a0,s2
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	3d2080e7          	jalr	978(ra) # 80004680 <releasesleep>

  acquire(&bcache.lock);
    800032b6:	00014517          	auipc	a0,0x14
    800032ba:	45250513          	addi	a0,a0,1106 # 80017708 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032c6:	40bc                	lw	a5,64(s1)
    800032c8:	37fd                	addiw	a5,a5,-1
    800032ca:	0007871b          	sext.w	a4,a5
    800032ce:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032d0:	eb05                	bnez	a4,80003300 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032d2:	68bc                	ld	a5,80(s1)
    800032d4:	64b8                	ld	a4,72(s1)
    800032d6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032d8:	64bc                	ld	a5,72(s1)
    800032da:	68b8                	ld	a4,80(s1)
    800032dc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032de:	0001c797          	auipc	a5,0x1c
    800032e2:	42a78793          	addi	a5,a5,1066 # 8001f708 <bcache+0x8000>
    800032e6:	2b87b703          	ld	a4,696(a5)
    800032ea:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032ec:	0001c717          	auipc	a4,0x1c
    800032f0:	68470713          	addi	a4,a4,1668 # 8001f970 <bcache+0x8268>
    800032f4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032f6:	2b87b703          	ld	a4,696(a5)
    800032fa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032fc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003300:	00014517          	auipc	a0,0x14
    80003304:	40850513          	addi	a0,a0,1032 # 80017708 <bcache>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	990080e7          	jalr	-1648(ra) # 80000c98 <release>
}
    80003310:	60e2                	ld	ra,24(sp)
    80003312:	6442                	ld	s0,16(sp)
    80003314:	64a2                	ld	s1,8(sp)
    80003316:	6902                	ld	s2,0(sp)
    80003318:	6105                	addi	sp,sp,32
    8000331a:	8082                	ret
    panic("brelse");
    8000331c:	00005517          	auipc	a0,0x5
    80003320:	2c450513          	addi	a0,a0,708 # 800085e0 <syscalls+0xf8>
    80003324:	ffffd097          	auipc	ra,0xffffd
    80003328:	21a080e7          	jalr	538(ra) # 8000053e <panic>

000000008000332c <bpin>:

void
bpin(struct buf *b) {
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	e426                	sd	s1,8(sp)
    80003334:	1000                	addi	s0,sp,32
    80003336:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003338:	00014517          	auipc	a0,0x14
    8000333c:	3d050513          	addi	a0,a0,976 # 80017708 <bcache>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	8a4080e7          	jalr	-1884(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003348:	40bc                	lw	a5,64(s1)
    8000334a:	2785                	addiw	a5,a5,1
    8000334c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	3ba50513          	addi	a0,a0,954 # 80017708 <bcache>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6105                	addi	sp,sp,32
    80003366:	8082                	ret

0000000080003368 <bunpin>:

void
bunpin(struct buf *b) {
    80003368:	1101                	addi	sp,sp,-32
    8000336a:	ec06                	sd	ra,24(sp)
    8000336c:	e822                	sd	s0,16(sp)
    8000336e:	e426                	sd	s1,8(sp)
    80003370:	1000                	addi	s0,sp,32
    80003372:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003374:	00014517          	auipc	a0,0x14
    80003378:	39450513          	addi	a0,a0,916 # 80017708 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003384:	40bc                	lw	a5,64(s1)
    80003386:	37fd                	addiw	a5,a5,-1
    80003388:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000338a:	00014517          	auipc	a0,0x14
    8000338e:	37e50513          	addi	a0,a0,894 # 80017708 <bcache>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	906080e7          	jalr	-1786(ra) # 80000c98 <release>
}
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6105                	addi	sp,sp,32
    800033a2:	8082                	ret

00000000800033a4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033a4:	1101                	addi	sp,sp,-32
    800033a6:	ec06                	sd	ra,24(sp)
    800033a8:	e822                	sd	s0,16(sp)
    800033aa:	e426                	sd	s1,8(sp)
    800033ac:	e04a                	sd	s2,0(sp)
    800033ae:	1000                	addi	s0,sp,32
    800033b0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033b2:	00d5d59b          	srliw	a1,a1,0xd
    800033b6:	0001d797          	auipc	a5,0x1d
    800033ba:	a2e7a783          	lw	a5,-1490(a5) # 8001fde4 <sb+0x1c>
    800033be:	9dbd                	addw	a1,a1,a5
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	d9e080e7          	jalr	-610(ra) # 8000315e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033c8:	0074f713          	andi	a4,s1,7
    800033cc:	4785                	li	a5,1
    800033ce:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033d2:	14ce                	slli	s1,s1,0x33
    800033d4:	90d9                	srli	s1,s1,0x36
    800033d6:	00950733          	add	a4,a0,s1
    800033da:	05874703          	lbu	a4,88(a4)
    800033de:	00e7f6b3          	and	a3,a5,a4
    800033e2:	c69d                	beqz	a3,80003410 <bfree+0x6c>
    800033e4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033e6:	94aa                	add	s1,s1,a0
    800033e8:	fff7c793          	not	a5,a5
    800033ec:	8ff9                	and	a5,a5,a4
    800033ee:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	118080e7          	jalr	280(ra) # 8000450a <log_write>
  brelse(bp);
    800033fa:	854a                	mv	a0,s2
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	e92080e7          	jalr	-366(ra) # 8000328e <brelse>
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	64a2                	ld	s1,8(sp)
    8000340a:	6902                	ld	s2,0(sp)
    8000340c:	6105                	addi	sp,sp,32
    8000340e:	8082                	ret
    panic("freeing free block");
    80003410:	00005517          	auipc	a0,0x5
    80003414:	1d850513          	addi	a0,a0,472 # 800085e8 <syscalls+0x100>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	126080e7          	jalr	294(ra) # 8000053e <panic>

0000000080003420 <balloc>:
{
    80003420:	711d                	addi	sp,sp,-96
    80003422:	ec86                	sd	ra,88(sp)
    80003424:	e8a2                	sd	s0,80(sp)
    80003426:	e4a6                	sd	s1,72(sp)
    80003428:	e0ca                	sd	s2,64(sp)
    8000342a:	fc4e                	sd	s3,56(sp)
    8000342c:	f852                	sd	s4,48(sp)
    8000342e:	f456                	sd	s5,40(sp)
    80003430:	f05a                	sd	s6,32(sp)
    80003432:	ec5e                	sd	s7,24(sp)
    80003434:	e862                	sd	s8,16(sp)
    80003436:	e466                	sd	s9,8(sp)
    80003438:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000343a:	0001d797          	auipc	a5,0x1d
    8000343e:	9927a783          	lw	a5,-1646(a5) # 8001fdcc <sb+0x4>
    80003442:	cbd1                	beqz	a5,800034d6 <balloc+0xb6>
    80003444:	8baa                	mv	s7,a0
    80003446:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003448:	0001db17          	auipc	s6,0x1d
    8000344c:	980b0b13          	addi	s6,s6,-1664 # 8001fdc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003450:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003452:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003454:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003456:	6c89                	lui	s9,0x2
    80003458:	a831                	j	80003474 <balloc+0x54>
    brelse(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e32080e7          	jalr	-462(ra) # 8000328e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003464:	015c87bb          	addw	a5,s9,s5
    80003468:	00078a9b          	sext.w	s5,a5
    8000346c:	004b2703          	lw	a4,4(s6)
    80003470:	06eaf363          	bgeu	s5,a4,800034d6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003474:	41fad79b          	sraiw	a5,s5,0x1f
    80003478:	0137d79b          	srliw	a5,a5,0x13
    8000347c:	015787bb          	addw	a5,a5,s5
    80003480:	40d7d79b          	sraiw	a5,a5,0xd
    80003484:	01cb2583          	lw	a1,28(s6)
    80003488:	9dbd                	addw	a1,a1,a5
    8000348a:	855e                	mv	a0,s7
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	cd2080e7          	jalr	-814(ra) # 8000315e <bread>
    80003494:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003496:	004b2503          	lw	a0,4(s6)
    8000349a:	000a849b          	sext.w	s1,s5
    8000349e:	8662                	mv	a2,s8
    800034a0:	faa4fde3          	bgeu	s1,a0,8000345a <balloc+0x3a>
      m = 1 << (bi % 8);
    800034a4:	41f6579b          	sraiw	a5,a2,0x1f
    800034a8:	01d7d69b          	srliw	a3,a5,0x1d
    800034ac:	00c6873b          	addw	a4,a3,a2
    800034b0:	00777793          	andi	a5,a4,7
    800034b4:	9f95                	subw	a5,a5,a3
    800034b6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034ba:	4037571b          	sraiw	a4,a4,0x3
    800034be:	00e906b3          	add	a3,s2,a4
    800034c2:	0586c683          	lbu	a3,88(a3)
    800034c6:	00d7f5b3          	and	a1,a5,a3
    800034ca:	cd91                	beqz	a1,800034e6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034cc:	2605                	addiw	a2,a2,1
    800034ce:	2485                	addiw	s1,s1,1
    800034d0:	fd4618e3          	bne	a2,s4,800034a0 <balloc+0x80>
    800034d4:	b759                	j	8000345a <balloc+0x3a>
  panic("balloc: out of blocks");
    800034d6:	00005517          	auipc	a0,0x5
    800034da:	12a50513          	addi	a0,a0,298 # 80008600 <syscalls+0x118>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034e6:	974a                	add	a4,a4,s2
    800034e8:	8fd5                	or	a5,a5,a3
    800034ea:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034ee:	854a                	mv	a0,s2
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	01a080e7          	jalr	26(ra) # 8000450a <log_write>
        brelse(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	d94080e7          	jalr	-620(ra) # 8000328e <brelse>
  bp = bread(dev, bno);
    80003502:	85a6                	mv	a1,s1
    80003504:	855e                	mv	a0,s7
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	c58080e7          	jalr	-936(ra) # 8000315e <bread>
    8000350e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003510:	40000613          	li	a2,1024
    80003514:	4581                	li	a1,0
    80003516:	05850513          	addi	a0,a0,88
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	7c6080e7          	jalr	1990(ra) # 80000ce0 <memset>
  log_write(bp);
    80003522:	854a                	mv	a0,s2
    80003524:	00001097          	auipc	ra,0x1
    80003528:	fe6080e7          	jalr	-26(ra) # 8000450a <log_write>
  brelse(bp);
    8000352c:	854a                	mv	a0,s2
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	d60080e7          	jalr	-672(ra) # 8000328e <brelse>
}
    80003536:	8526                	mv	a0,s1
    80003538:	60e6                	ld	ra,88(sp)
    8000353a:	6446                	ld	s0,80(sp)
    8000353c:	64a6                	ld	s1,72(sp)
    8000353e:	6906                	ld	s2,64(sp)
    80003540:	79e2                	ld	s3,56(sp)
    80003542:	7a42                	ld	s4,48(sp)
    80003544:	7aa2                	ld	s5,40(sp)
    80003546:	7b02                	ld	s6,32(sp)
    80003548:	6be2                	ld	s7,24(sp)
    8000354a:	6c42                	ld	s8,16(sp)
    8000354c:	6ca2                	ld	s9,8(sp)
    8000354e:	6125                	addi	sp,sp,96
    80003550:	8082                	ret

0000000080003552 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003552:	7179                	addi	sp,sp,-48
    80003554:	f406                	sd	ra,40(sp)
    80003556:	f022                	sd	s0,32(sp)
    80003558:	ec26                	sd	s1,24(sp)
    8000355a:	e84a                	sd	s2,16(sp)
    8000355c:	e44e                	sd	s3,8(sp)
    8000355e:	e052                	sd	s4,0(sp)
    80003560:	1800                	addi	s0,sp,48
    80003562:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003564:	47ad                	li	a5,11
    80003566:	04b7fe63          	bgeu	a5,a1,800035c2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000356a:	ff45849b          	addiw	s1,a1,-12
    8000356e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003572:	0ff00793          	li	a5,255
    80003576:	0ae7e363          	bltu	a5,a4,8000361c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000357a:	08052583          	lw	a1,128(a0)
    8000357e:	c5ad                	beqz	a1,800035e8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003580:	00092503          	lw	a0,0(s2)
    80003584:	00000097          	auipc	ra,0x0
    80003588:	bda080e7          	jalr	-1062(ra) # 8000315e <bread>
    8000358c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000358e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003592:	02049593          	slli	a1,s1,0x20
    80003596:	9181                	srli	a1,a1,0x20
    80003598:	058a                	slli	a1,a1,0x2
    8000359a:	00b784b3          	add	s1,a5,a1
    8000359e:	0004a983          	lw	s3,0(s1)
    800035a2:	04098d63          	beqz	s3,800035fc <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035a6:	8552                	mv	a0,s4
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	ce6080e7          	jalr	-794(ra) # 8000328e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035b0:	854e                	mv	a0,s3
    800035b2:	70a2                	ld	ra,40(sp)
    800035b4:	7402                	ld	s0,32(sp)
    800035b6:	64e2                	ld	s1,24(sp)
    800035b8:	6942                	ld	s2,16(sp)
    800035ba:	69a2                	ld	s3,8(sp)
    800035bc:	6a02                	ld	s4,0(sp)
    800035be:	6145                	addi	sp,sp,48
    800035c0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035c2:	02059493          	slli	s1,a1,0x20
    800035c6:	9081                	srli	s1,s1,0x20
    800035c8:	048a                	slli	s1,s1,0x2
    800035ca:	94aa                	add	s1,s1,a0
    800035cc:	0504a983          	lw	s3,80(s1)
    800035d0:	fe0990e3          	bnez	s3,800035b0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035d4:	4108                	lw	a0,0(a0)
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	e4a080e7          	jalr	-438(ra) # 80003420 <balloc>
    800035de:	0005099b          	sext.w	s3,a0
    800035e2:	0534a823          	sw	s3,80(s1)
    800035e6:	b7e9                	j	800035b0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035e8:	4108                	lw	a0,0(a0)
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	e36080e7          	jalr	-458(ra) # 80003420 <balloc>
    800035f2:	0005059b          	sext.w	a1,a0
    800035f6:	08b92023          	sw	a1,128(s2)
    800035fa:	b759                	j	80003580 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035fc:	00092503          	lw	a0,0(s2)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e20080e7          	jalr	-480(ra) # 80003420 <balloc>
    80003608:	0005099b          	sext.w	s3,a0
    8000360c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003610:	8552                	mv	a0,s4
    80003612:	00001097          	auipc	ra,0x1
    80003616:	ef8080e7          	jalr	-264(ra) # 8000450a <log_write>
    8000361a:	b771                	j	800035a6 <bmap+0x54>
  panic("bmap: out of range");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	ffc50513          	addi	a0,a0,-4 # 80008618 <syscalls+0x130>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>

000000008000362c <iget>:
{
    8000362c:	7179                	addi	sp,sp,-48
    8000362e:	f406                	sd	ra,40(sp)
    80003630:	f022                	sd	s0,32(sp)
    80003632:	ec26                	sd	s1,24(sp)
    80003634:	e84a                	sd	s2,16(sp)
    80003636:	e44e                	sd	s3,8(sp)
    80003638:	e052                	sd	s4,0(sp)
    8000363a:	1800                	addi	s0,sp,48
    8000363c:	89aa                	mv	s3,a0
    8000363e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003640:	0001c517          	auipc	a0,0x1c
    80003644:	7a850513          	addi	a0,a0,1960 # 8001fde8 <itable>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	59c080e7          	jalr	1436(ra) # 80000be4 <acquire>
  empty = 0;
    80003650:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003652:	0001c497          	auipc	s1,0x1c
    80003656:	7ae48493          	addi	s1,s1,1966 # 8001fe00 <itable+0x18>
    8000365a:	0001e697          	auipc	a3,0x1e
    8000365e:	23668693          	addi	a3,a3,566 # 80021890 <log>
    80003662:	a039                	j	80003670 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003664:	02090b63          	beqz	s2,8000369a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003668:	08848493          	addi	s1,s1,136
    8000366c:	02d48a63          	beq	s1,a3,800036a0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003670:	449c                	lw	a5,8(s1)
    80003672:	fef059e3          	blez	a5,80003664 <iget+0x38>
    80003676:	4098                	lw	a4,0(s1)
    80003678:	ff3716e3          	bne	a4,s3,80003664 <iget+0x38>
    8000367c:	40d8                	lw	a4,4(s1)
    8000367e:	ff4713e3          	bne	a4,s4,80003664 <iget+0x38>
      ip->ref++;
    80003682:	2785                	addiw	a5,a5,1
    80003684:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003686:	0001c517          	auipc	a0,0x1c
    8000368a:	76250513          	addi	a0,a0,1890 # 8001fde8 <itable>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
      return ip;
    80003696:	8926                	mv	s2,s1
    80003698:	a03d                	j	800036c6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000369a:	f7f9                	bnez	a5,80003668 <iget+0x3c>
    8000369c:	8926                	mv	s2,s1
    8000369e:	b7e9                	j	80003668 <iget+0x3c>
  if(empty == 0)
    800036a0:	02090c63          	beqz	s2,800036d8 <iget+0xac>
  ip->dev = dev;
    800036a4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036a8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036ac:	4785                	li	a5,1
    800036ae:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036b2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036b6:	0001c517          	auipc	a0,0x1c
    800036ba:	73250513          	addi	a0,a0,1842 # 8001fde8 <itable>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
}
    800036c6:	854a                	mv	a0,s2
    800036c8:	70a2                	ld	ra,40(sp)
    800036ca:	7402                	ld	s0,32(sp)
    800036cc:	64e2                	ld	s1,24(sp)
    800036ce:	6942                	ld	s2,16(sp)
    800036d0:	69a2                	ld	s3,8(sp)
    800036d2:	6a02                	ld	s4,0(sp)
    800036d4:	6145                	addi	sp,sp,48
    800036d6:	8082                	ret
    panic("iget: no inodes");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	f5850513          	addi	a0,a0,-168 # 80008630 <syscalls+0x148>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e5e080e7          	jalr	-418(ra) # 8000053e <panic>

00000000800036e8 <fsinit>:
fsinit(int dev) {
    800036e8:	7179                	addi	sp,sp,-48
    800036ea:	f406                	sd	ra,40(sp)
    800036ec:	f022                	sd	s0,32(sp)
    800036ee:	ec26                	sd	s1,24(sp)
    800036f0:	e84a                	sd	s2,16(sp)
    800036f2:	e44e                	sd	s3,8(sp)
    800036f4:	1800                	addi	s0,sp,48
    800036f6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036f8:	4585                	li	a1,1
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	a64080e7          	jalr	-1436(ra) # 8000315e <bread>
    80003702:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003704:	0001c997          	auipc	s3,0x1c
    80003708:	6c498993          	addi	s3,s3,1732 # 8001fdc8 <sb>
    8000370c:	02000613          	li	a2,32
    80003710:	05850593          	addi	a1,a0,88
    80003714:	854e                	mv	a0,s3
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	62a080e7          	jalr	1578(ra) # 80000d40 <memmove>
  brelse(bp);
    8000371e:	8526                	mv	a0,s1
    80003720:	00000097          	auipc	ra,0x0
    80003724:	b6e080e7          	jalr	-1170(ra) # 8000328e <brelse>
  if(sb.magic != FSMAGIC)
    80003728:	0009a703          	lw	a4,0(s3)
    8000372c:	102037b7          	lui	a5,0x10203
    80003730:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003734:	02f71263          	bne	a4,a5,80003758 <fsinit+0x70>
  initlog(dev, &sb);
    80003738:	0001c597          	auipc	a1,0x1c
    8000373c:	69058593          	addi	a1,a1,1680 # 8001fdc8 <sb>
    80003740:	854a                	mv	a0,s2
    80003742:	00001097          	auipc	ra,0x1
    80003746:	b4c080e7          	jalr	-1204(ra) # 8000428e <initlog>
}
    8000374a:	70a2                	ld	ra,40(sp)
    8000374c:	7402                	ld	s0,32(sp)
    8000374e:	64e2                	ld	s1,24(sp)
    80003750:	6942                	ld	s2,16(sp)
    80003752:	69a2                	ld	s3,8(sp)
    80003754:	6145                	addi	sp,sp,48
    80003756:	8082                	ret
    panic("invalid file system");
    80003758:	00005517          	auipc	a0,0x5
    8000375c:	ee850513          	addi	a0,a0,-280 # 80008640 <syscalls+0x158>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	dde080e7          	jalr	-546(ra) # 8000053e <panic>

0000000080003768 <iinit>:
{
    80003768:	7179                	addi	sp,sp,-48
    8000376a:	f406                	sd	ra,40(sp)
    8000376c:	f022                	sd	s0,32(sp)
    8000376e:	ec26                	sd	s1,24(sp)
    80003770:	e84a                	sd	s2,16(sp)
    80003772:	e44e                	sd	s3,8(sp)
    80003774:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003776:	00005597          	auipc	a1,0x5
    8000377a:	ee258593          	addi	a1,a1,-286 # 80008658 <syscalls+0x170>
    8000377e:	0001c517          	auipc	a0,0x1c
    80003782:	66a50513          	addi	a0,a0,1642 # 8001fde8 <itable>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	3ce080e7          	jalr	974(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000378e:	0001c497          	auipc	s1,0x1c
    80003792:	68248493          	addi	s1,s1,1666 # 8001fe10 <itable+0x28>
    80003796:	0001e997          	auipc	s3,0x1e
    8000379a:	10a98993          	addi	s3,s3,266 # 800218a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000379e:	00005917          	auipc	s2,0x5
    800037a2:	ec290913          	addi	s2,s2,-318 # 80008660 <syscalls+0x178>
    800037a6:	85ca                	mv	a1,s2
    800037a8:	8526                	mv	a0,s1
    800037aa:	00001097          	auipc	ra,0x1
    800037ae:	e46080e7          	jalr	-442(ra) # 800045f0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037b2:	08848493          	addi	s1,s1,136
    800037b6:	ff3498e3          	bne	s1,s3,800037a6 <iinit+0x3e>
}
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6145                	addi	sp,sp,48
    800037c6:	8082                	ret

00000000800037c8 <ialloc>:
{
    800037c8:	715d                	addi	sp,sp,-80
    800037ca:	e486                	sd	ra,72(sp)
    800037cc:	e0a2                	sd	s0,64(sp)
    800037ce:	fc26                	sd	s1,56(sp)
    800037d0:	f84a                	sd	s2,48(sp)
    800037d2:	f44e                	sd	s3,40(sp)
    800037d4:	f052                	sd	s4,32(sp)
    800037d6:	ec56                	sd	s5,24(sp)
    800037d8:	e85a                	sd	s6,16(sp)
    800037da:	e45e                	sd	s7,8(sp)
    800037dc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037de:	0001c717          	auipc	a4,0x1c
    800037e2:	5f672703          	lw	a4,1526(a4) # 8001fdd4 <sb+0xc>
    800037e6:	4785                	li	a5,1
    800037e8:	04e7fa63          	bgeu	a5,a4,8000383c <ialloc+0x74>
    800037ec:	8aaa                	mv	s5,a0
    800037ee:	8bae                	mv	s7,a1
    800037f0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037f2:	0001ca17          	auipc	s4,0x1c
    800037f6:	5d6a0a13          	addi	s4,s4,1494 # 8001fdc8 <sb>
    800037fa:	00048b1b          	sext.w	s6,s1
    800037fe:	0044d593          	srli	a1,s1,0x4
    80003802:	018a2783          	lw	a5,24(s4)
    80003806:	9dbd                	addw	a1,a1,a5
    80003808:	8556                	mv	a0,s5
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	954080e7          	jalr	-1708(ra) # 8000315e <bread>
    80003812:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003814:	05850993          	addi	s3,a0,88
    80003818:	00f4f793          	andi	a5,s1,15
    8000381c:	079a                	slli	a5,a5,0x6
    8000381e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003820:	00099783          	lh	a5,0(s3)
    80003824:	c785                	beqz	a5,8000384c <ialloc+0x84>
    brelse(bp);
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	a68080e7          	jalr	-1432(ra) # 8000328e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000382e:	0485                	addi	s1,s1,1
    80003830:	00ca2703          	lw	a4,12(s4)
    80003834:	0004879b          	sext.w	a5,s1
    80003838:	fce7e1e3          	bltu	a5,a4,800037fa <ialloc+0x32>
  panic("ialloc: no inodes");
    8000383c:	00005517          	auipc	a0,0x5
    80003840:	e2c50513          	addi	a0,a0,-468 # 80008668 <syscalls+0x180>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	cfa080e7          	jalr	-774(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000384c:	04000613          	li	a2,64
    80003850:	4581                	li	a1,0
    80003852:	854e                	mv	a0,s3
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	48c080e7          	jalr	1164(ra) # 80000ce0 <memset>
      dip->type = type;
    8000385c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003860:	854a                	mv	a0,s2
    80003862:	00001097          	auipc	ra,0x1
    80003866:	ca8080e7          	jalr	-856(ra) # 8000450a <log_write>
      brelse(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	a22080e7          	jalr	-1502(ra) # 8000328e <brelse>
      return iget(dev, inum);
    80003874:	85da                	mv	a1,s6
    80003876:	8556                	mv	a0,s5
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	db4080e7          	jalr	-588(ra) # 8000362c <iget>
}
    80003880:	60a6                	ld	ra,72(sp)
    80003882:	6406                	ld	s0,64(sp)
    80003884:	74e2                	ld	s1,56(sp)
    80003886:	7942                	ld	s2,48(sp)
    80003888:	79a2                	ld	s3,40(sp)
    8000388a:	7a02                	ld	s4,32(sp)
    8000388c:	6ae2                	ld	s5,24(sp)
    8000388e:	6b42                	ld	s6,16(sp)
    80003890:	6ba2                	ld	s7,8(sp)
    80003892:	6161                	addi	sp,sp,80
    80003894:	8082                	ret

0000000080003896 <iupdate>:
{
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	e04a                	sd	s2,0(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a4:	415c                	lw	a5,4(a0)
    800038a6:	0047d79b          	srliw	a5,a5,0x4
    800038aa:	0001c597          	auipc	a1,0x1c
    800038ae:	5365a583          	lw	a1,1334(a1) # 8001fde0 <sb+0x18>
    800038b2:	9dbd                	addw	a1,a1,a5
    800038b4:	4108                	lw	a0,0(a0)
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	8a8080e7          	jalr	-1880(ra) # 8000315e <bread>
    800038be:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c0:	05850793          	addi	a5,a0,88
    800038c4:	40c8                	lw	a0,4(s1)
    800038c6:	893d                	andi	a0,a0,15
    800038c8:	051a                	slli	a0,a0,0x6
    800038ca:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038cc:	04449703          	lh	a4,68(s1)
    800038d0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038d4:	04649703          	lh	a4,70(s1)
    800038d8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038dc:	04849703          	lh	a4,72(s1)
    800038e0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038e4:	04a49703          	lh	a4,74(s1)
    800038e8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038ec:	44f8                	lw	a4,76(s1)
    800038ee:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038f0:	03400613          	li	a2,52
    800038f4:	05048593          	addi	a1,s1,80
    800038f8:	0531                	addi	a0,a0,12
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	446080e7          	jalr	1094(ra) # 80000d40 <memmove>
  log_write(bp);
    80003902:	854a                	mv	a0,s2
    80003904:	00001097          	auipc	ra,0x1
    80003908:	c06080e7          	jalr	-1018(ra) # 8000450a <log_write>
  brelse(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	980080e7          	jalr	-1664(ra) # 8000328e <brelse>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6902                	ld	s2,0(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret

0000000080003922 <idup>:
{
    80003922:	1101                	addi	sp,sp,-32
    80003924:	ec06                	sd	ra,24(sp)
    80003926:	e822                	sd	s0,16(sp)
    80003928:	e426                	sd	s1,8(sp)
    8000392a:	1000                	addi	s0,sp,32
    8000392c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000392e:	0001c517          	auipc	a0,0x1c
    80003932:	4ba50513          	addi	a0,a0,1210 # 8001fde8 <itable>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	2ae080e7          	jalr	686(ra) # 80000be4 <acquire>
  ip->ref++;
    8000393e:	449c                	lw	a5,8(s1)
    80003940:	2785                	addiw	a5,a5,1
    80003942:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003944:	0001c517          	auipc	a0,0x1c
    80003948:	4a450513          	addi	a0,a0,1188 # 8001fde8 <itable>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	34c080e7          	jalr	844(ra) # 80000c98 <release>
}
    80003954:	8526                	mv	a0,s1
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret

0000000080003960 <ilock>:
{
    80003960:	1101                	addi	sp,sp,-32
    80003962:	ec06                	sd	ra,24(sp)
    80003964:	e822                	sd	s0,16(sp)
    80003966:	e426                	sd	s1,8(sp)
    80003968:	e04a                	sd	s2,0(sp)
    8000396a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000396c:	c115                	beqz	a0,80003990 <ilock+0x30>
    8000396e:	84aa                	mv	s1,a0
    80003970:	451c                	lw	a5,8(a0)
    80003972:	00f05f63          	blez	a5,80003990 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003976:	0541                	addi	a0,a0,16
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	cb2080e7          	jalr	-846(ra) # 8000462a <acquiresleep>
  if(ip->valid == 0){
    80003980:	40bc                	lw	a5,64(s1)
    80003982:	cf99                	beqz	a5,800039a0 <ilock+0x40>
}
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6902                	ld	s2,0(sp)
    8000398c:	6105                	addi	sp,sp,32
    8000398e:	8082                	ret
    panic("ilock");
    80003990:	00005517          	auipc	a0,0x5
    80003994:	cf050513          	addi	a0,a0,-784 # 80008680 <syscalls+0x198>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039a0:	40dc                	lw	a5,4(s1)
    800039a2:	0047d79b          	srliw	a5,a5,0x4
    800039a6:	0001c597          	auipc	a1,0x1c
    800039aa:	43a5a583          	lw	a1,1082(a1) # 8001fde0 <sb+0x18>
    800039ae:	9dbd                	addw	a1,a1,a5
    800039b0:	4088                	lw	a0,0(s1)
    800039b2:	fffff097          	auipc	ra,0xfffff
    800039b6:	7ac080e7          	jalr	1964(ra) # 8000315e <bread>
    800039ba:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039bc:	05850593          	addi	a1,a0,88
    800039c0:	40dc                	lw	a5,4(s1)
    800039c2:	8bbd                	andi	a5,a5,15
    800039c4:	079a                	slli	a5,a5,0x6
    800039c6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039c8:	00059783          	lh	a5,0(a1)
    800039cc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039d0:	00259783          	lh	a5,2(a1)
    800039d4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039d8:	00459783          	lh	a5,4(a1)
    800039dc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039e0:	00659783          	lh	a5,6(a1)
    800039e4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039e8:	459c                	lw	a5,8(a1)
    800039ea:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039ec:	03400613          	li	a2,52
    800039f0:	05b1                	addi	a1,a1,12
    800039f2:	05048513          	addi	a0,s1,80
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	34a080e7          	jalr	842(ra) # 80000d40 <memmove>
    brelse(bp);
    800039fe:	854a                	mv	a0,s2
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	88e080e7          	jalr	-1906(ra) # 8000328e <brelse>
    ip->valid = 1;
    80003a08:	4785                	li	a5,1
    80003a0a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a0c:	04449783          	lh	a5,68(s1)
    80003a10:	fbb5                	bnez	a5,80003984 <ilock+0x24>
      panic("ilock: no type");
    80003a12:	00005517          	auipc	a0,0x5
    80003a16:	c7650513          	addi	a0,a0,-906 # 80008688 <syscalls+0x1a0>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>

0000000080003a22 <iunlock>:
{
    80003a22:	1101                	addi	sp,sp,-32
    80003a24:	ec06                	sd	ra,24(sp)
    80003a26:	e822                	sd	s0,16(sp)
    80003a28:	e426                	sd	s1,8(sp)
    80003a2a:	e04a                	sd	s2,0(sp)
    80003a2c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a2e:	c905                	beqz	a0,80003a5e <iunlock+0x3c>
    80003a30:	84aa                	mv	s1,a0
    80003a32:	01050913          	addi	s2,a0,16
    80003a36:	854a                	mv	a0,s2
    80003a38:	00001097          	auipc	ra,0x1
    80003a3c:	c8c080e7          	jalr	-884(ra) # 800046c4 <holdingsleep>
    80003a40:	cd19                	beqz	a0,80003a5e <iunlock+0x3c>
    80003a42:	449c                	lw	a5,8(s1)
    80003a44:	00f05d63          	blez	a5,80003a5e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a48:	854a                	mv	a0,s2
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	c36080e7          	jalr	-970(ra) # 80004680 <releasesleep>
}
    80003a52:	60e2                	ld	ra,24(sp)
    80003a54:	6442                	ld	s0,16(sp)
    80003a56:	64a2                	ld	s1,8(sp)
    80003a58:	6902                	ld	s2,0(sp)
    80003a5a:	6105                	addi	sp,sp,32
    80003a5c:	8082                	ret
    panic("iunlock");
    80003a5e:	00005517          	auipc	a0,0x5
    80003a62:	c3a50513          	addi	a0,a0,-966 # 80008698 <syscalls+0x1b0>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080003a6e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a6e:	7179                	addi	sp,sp,-48
    80003a70:	f406                	sd	ra,40(sp)
    80003a72:	f022                	sd	s0,32(sp)
    80003a74:	ec26                	sd	s1,24(sp)
    80003a76:	e84a                	sd	s2,16(sp)
    80003a78:	e44e                	sd	s3,8(sp)
    80003a7a:	e052                	sd	s4,0(sp)
    80003a7c:	1800                	addi	s0,sp,48
    80003a7e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a80:	05050493          	addi	s1,a0,80
    80003a84:	08050913          	addi	s2,a0,128
    80003a88:	a021                	j	80003a90 <itrunc+0x22>
    80003a8a:	0491                	addi	s1,s1,4
    80003a8c:	01248d63          	beq	s1,s2,80003aa6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a90:	408c                	lw	a1,0(s1)
    80003a92:	dde5                	beqz	a1,80003a8a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a94:	0009a503          	lw	a0,0(s3)
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	90c080e7          	jalr	-1780(ra) # 800033a4 <bfree>
      ip->addrs[i] = 0;
    80003aa0:	0004a023          	sw	zero,0(s1)
    80003aa4:	b7dd                	j	80003a8a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aa6:	0809a583          	lw	a1,128(s3)
    80003aaa:	e185                	bnez	a1,80003aca <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aac:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ab0:	854e                	mv	a0,s3
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	de4080e7          	jalr	-540(ra) # 80003896 <iupdate>
}
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6a02                	ld	s4,0(sp)
    80003ac6:	6145                	addi	sp,sp,48
    80003ac8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aca:	0009a503          	lw	a0,0(s3)
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	690080e7          	jalr	1680(ra) # 8000315e <bread>
    80003ad6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ad8:	05850493          	addi	s1,a0,88
    80003adc:	45850913          	addi	s2,a0,1112
    80003ae0:	a811                	j	80003af4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ae2:	0009a503          	lw	a0,0(s3)
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	8be080e7          	jalr	-1858(ra) # 800033a4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003aee:	0491                	addi	s1,s1,4
    80003af0:	01248563          	beq	s1,s2,80003afa <itrunc+0x8c>
      if(a[j])
    80003af4:	408c                	lw	a1,0(s1)
    80003af6:	dde5                	beqz	a1,80003aee <itrunc+0x80>
    80003af8:	b7ed                	j	80003ae2 <itrunc+0x74>
    brelse(bp);
    80003afa:	8552                	mv	a0,s4
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	792080e7          	jalr	1938(ra) # 8000328e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b04:	0809a583          	lw	a1,128(s3)
    80003b08:	0009a503          	lw	a0,0(s3)
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	898080e7          	jalr	-1896(ra) # 800033a4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b14:	0809a023          	sw	zero,128(s3)
    80003b18:	bf51                	j	80003aac <itrunc+0x3e>

0000000080003b1a <iput>:
{
    80003b1a:	1101                	addi	sp,sp,-32
    80003b1c:	ec06                	sd	ra,24(sp)
    80003b1e:	e822                	sd	s0,16(sp)
    80003b20:	e426                	sd	s1,8(sp)
    80003b22:	e04a                	sd	s2,0(sp)
    80003b24:	1000                	addi	s0,sp,32
    80003b26:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b28:	0001c517          	auipc	a0,0x1c
    80003b2c:	2c050513          	addi	a0,a0,704 # 8001fde8 <itable>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	0b4080e7          	jalr	180(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b38:	4498                	lw	a4,8(s1)
    80003b3a:	4785                	li	a5,1
    80003b3c:	02f70363          	beq	a4,a5,80003b62 <iput+0x48>
  ip->ref--;
    80003b40:	449c                	lw	a5,8(s1)
    80003b42:	37fd                	addiw	a5,a5,-1
    80003b44:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b46:	0001c517          	auipc	a0,0x1c
    80003b4a:	2a250513          	addi	a0,a0,674 # 8001fde8 <itable>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
}
    80003b56:	60e2                	ld	ra,24(sp)
    80003b58:	6442                	ld	s0,16(sp)
    80003b5a:	64a2                	ld	s1,8(sp)
    80003b5c:	6902                	ld	s2,0(sp)
    80003b5e:	6105                	addi	sp,sp,32
    80003b60:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b62:	40bc                	lw	a5,64(s1)
    80003b64:	dff1                	beqz	a5,80003b40 <iput+0x26>
    80003b66:	04a49783          	lh	a5,74(s1)
    80003b6a:	fbf9                	bnez	a5,80003b40 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b6c:	01048913          	addi	s2,s1,16
    80003b70:	854a                	mv	a0,s2
    80003b72:	00001097          	auipc	ra,0x1
    80003b76:	ab8080e7          	jalr	-1352(ra) # 8000462a <acquiresleep>
    release(&itable.lock);
    80003b7a:	0001c517          	auipc	a0,0x1c
    80003b7e:	26e50513          	addi	a0,a0,622 # 8001fde8 <itable>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	116080e7          	jalr	278(ra) # 80000c98 <release>
    itrunc(ip);
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	ee2080e7          	jalr	-286(ra) # 80003a6e <itrunc>
    ip->type = 0;
    80003b94:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b98:	8526                	mv	a0,s1
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	cfc080e7          	jalr	-772(ra) # 80003896 <iupdate>
    ip->valid = 0;
    80003ba2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	00001097          	auipc	ra,0x1
    80003bac:	ad8080e7          	jalr	-1320(ra) # 80004680 <releasesleep>
    acquire(&itable.lock);
    80003bb0:	0001c517          	auipc	a0,0x1c
    80003bb4:	23850513          	addi	a0,a0,568 # 8001fde8 <itable>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	02c080e7          	jalr	44(ra) # 80000be4 <acquire>
    80003bc0:	b741                	j	80003b40 <iput+0x26>

0000000080003bc2 <iunlockput>:
{
    80003bc2:	1101                	addi	sp,sp,-32
    80003bc4:	ec06                	sd	ra,24(sp)
    80003bc6:	e822                	sd	s0,16(sp)
    80003bc8:	e426                	sd	s1,8(sp)
    80003bca:	1000                	addi	s0,sp,32
    80003bcc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	e54080e7          	jalr	-428(ra) # 80003a22 <iunlock>
  iput(ip);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	f42080e7          	jalr	-190(ra) # 80003b1a <iput>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6105                	addi	sp,sp,32
    80003be8:	8082                	ret

0000000080003bea <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bea:	1141                	addi	sp,sp,-16
    80003bec:	e422                	sd	s0,8(sp)
    80003bee:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bf0:	411c                	lw	a5,0(a0)
    80003bf2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bf4:	415c                	lw	a5,4(a0)
    80003bf6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bf8:	04451783          	lh	a5,68(a0)
    80003bfc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c00:	04a51783          	lh	a5,74(a0)
    80003c04:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c08:	04c56783          	lwu	a5,76(a0)
    80003c0c:	e99c                	sd	a5,16(a1)
}
    80003c0e:	6422                	ld	s0,8(sp)
    80003c10:	0141                	addi	sp,sp,16
    80003c12:	8082                	ret

0000000080003c14 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c14:	457c                	lw	a5,76(a0)
    80003c16:	0ed7e963          	bltu	a5,a3,80003d08 <readi+0xf4>
{
    80003c1a:	7159                	addi	sp,sp,-112
    80003c1c:	f486                	sd	ra,104(sp)
    80003c1e:	f0a2                	sd	s0,96(sp)
    80003c20:	eca6                	sd	s1,88(sp)
    80003c22:	e8ca                	sd	s2,80(sp)
    80003c24:	e4ce                	sd	s3,72(sp)
    80003c26:	e0d2                	sd	s4,64(sp)
    80003c28:	fc56                	sd	s5,56(sp)
    80003c2a:	f85a                	sd	s6,48(sp)
    80003c2c:	f45e                	sd	s7,40(sp)
    80003c2e:	f062                	sd	s8,32(sp)
    80003c30:	ec66                	sd	s9,24(sp)
    80003c32:	e86a                	sd	s10,16(sp)
    80003c34:	e46e                	sd	s11,8(sp)
    80003c36:	1880                	addi	s0,sp,112
    80003c38:	8baa                	mv	s7,a0
    80003c3a:	8c2e                	mv	s8,a1
    80003c3c:	8ab2                	mv	s5,a2
    80003c3e:	84b6                	mv	s1,a3
    80003c40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c42:	9f35                	addw	a4,a4,a3
    return 0;
    80003c44:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c46:	0ad76063          	bltu	a4,a3,80003ce6 <readi+0xd2>
  if(off + n > ip->size)
    80003c4a:	00e7f463          	bgeu	a5,a4,80003c52 <readi+0x3e>
    n = ip->size - off;
    80003c4e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c52:	0a0b0963          	beqz	s6,80003d04 <readi+0xf0>
    80003c56:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c58:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c5c:	5cfd                	li	s9,-1
    80003c5e:	a82d                	j	80003c98 <readi+0x84>
    80003c60:	020a1d93          	slli	s11,s4,0x20
    80003c64:	020ddd93          	srli	s11,s11,0x20
    80003c68:	05890613          	addi	a2,s2,88
    80003c6c:	86ee                	mv	a3,s11
    80003c6e:	963a                	add	a2,a2,a4
    80003c70:	85d6                	mv	a1,s5
    80003c72:	8562                	mv	a0,s8
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	acc080e7          	jalr	-1332(ra) # 80002740 <either_copyout>
    80003c7c:	05950d63          	beq	a0,s9,80003cd6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c80:	854a                	mv	a0,s2
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	60c080e7          	jalr	1548(ra) # 8000328e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c8a:	013a09bb          	addw	s3,s4,s3
    80003c8e:	009a04bb          	addw	s1,s4,s1
    80003c92:	9aee                	add	s5,s5,s11
    80003c94:	0569f763          	bgeu	s3,s6,80003ce2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c98:	000ba903          	lw	s2,0(s7)
    80003c9c:	00a4d59b          	srliw	a1,s1,0xa
    80003ca0:	855e                	mv	a0,s7
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	8b0080e7          	jalr	-1872(ra) # 80003552 <bmap>
    80003caa:	0005059b          	sext.w	a1,a0
    80003cae:	854a                	mv	a0,s2
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	4ae080e7          	jalr	1198(ra) # 8000315e <bread>
    80003cb8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cba:	3ff4f713          	andi	a4,s1,1023
    80003cbe:	40ed07bb          	subw	a5,s10,a4
    80003cc2:	413b06bb          	subw	a3,s6,s3
    80003cc6:	8a3e                	mv	s4,a5
    80003cc8:	2781                	sext.w	a5,a5
    80003cca:	0006861b          	sext.w	a2,a3
    80003cce:	f8f679e3          	bgeu	a2,a5,80003c60 <readi+0x4c>
    80003cd2:	8a36                	mv	s4,a3
    80003cd4:	b771                	j	80003c60 <readi+0x4c>
      brelse(bp);
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	5b6080e7          	jalr	1462(ra) # 8000328e <brelse>
      tot = -1;
    80003ce0:	59fd                	li	s3,-1
  }
  return tot;
    80003ce2:	0009851b          	sext.w	a0,s3
}
    80003ce6:	70a6                	ld	ra,104(sp)
    80003ce8:	7406                	ld	s0,96(sp)
    80003cea:	64e6                	ld	s1,88(sp)
    80003cec:	6946                	ld	s2,80(sp)
    80003cee:	69a6                	ld	s3,72(sp)
    80003cf0:	6a06                	ld	s4,64(sp)
    80003cf2:	7ae2                	ld	s5,56(sp)
    80003cf4:	7b42                	ld	s6,48(sp)
    80003cf6:	7ba2                	ld	s7,40(sp)
    80003cf8:	7c02                	ld	s8,32(sp)
    80003cfa:	6ce2                	ld	s9,24(sp)
    80003cfc:	6d42                	ld	s10,16(sp)
    80003cfe:	6da2                	ld	s11,8(sp)
    80003d00:	6165                	addi	sp,sp,112
    80003d02:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d04:	89da                	mv	s3,s6
    80003d06:	bff1                	j	80003ce2 <readi+0xce>
    return 0;
    80003d08:	4501                	li	a0,0
}
    80003d0a:	8082                	ret

0000000080003d0c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d0c:	457c                	lw	a5,76(a0)
    80003d0e:	10d7e863          	bltu	a5,a3,80003e1e <writei+0x112>
{
    80003d12:	7159                	addi	sp,sp,-112
    80003d14:	f486                	sd	ra,104(sp)
    80003d16:	f0a2                	sd	s0,96(sp)
    80003d18:	eca6                	sd	s1,88(sp)
    80003d1a:	e8ca                	sd	s2,80(sp)
    80003d1c:	e4ce                	sd	s3,72(sp)
    80003d1e:	e0d2                	sd	s4,64(sp)
    80003d20:	fc56                	sd	s5,56(sp)
    80003d22:	f85a                	sd	s6,48(sp)
    80003d24:	f45e                	sd	s7,40(sp)
    80003d26:	f062                	sd	s8,32(sp)
    80003d28:	ec66                	sd	s9,24(sp)
    80003d2a:	e86a                	sd	s10,16(sp)
    80003d2c:	e46e                	sd	s11,8(sp)
    80003d2e:	1880                	addi	s0,sp,112
    80003d30:	8b2a                	mv	s6,a0
    80003d32:	8c2e                	mv	s8,a1
    80003d34:	8ab2                	mv	s5,a2
    80003d36:	8936                	mv	s2,a3
    80003d38:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d3a:	00e687bb          	addw	a5,a3,a4
    80003d3e:	0ed7e263          	bltu	a5,a3,80003e22 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d42:	00043737          	lui	a4,0x43
    80003d46:	0ef76063          	bltu	a4,a5,80003e26 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d4a:	0c0b8863          	beqz	s7,80003e1a <writei+0x10e>
    80003d4e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d50:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d54:	5cfd                	li	s9,-1
    80003d56:	a091                	j	80003d9a <writei+0x8e>
    80003d58:	02099d93          	slli	s11,s3,0x20
    80003d5c:	020ddd93          	srli	s11,s11,0x20
    80003d60:	05848513          	addi	a0,s1,88
    80003d64:	86ee                	mv	a3,s11
    80003d66:	8656                	mv	a2,s5
    80003d68:	85e2                	mv	a1,s8
    80003d6a:	953a                	add	a0,a0,a4
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	a2a080e7          	jalr	-1494(ra) # 80002796 <either_copyin>
    80003d74:	07950263          	beq	a0,s9,80003dd8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d78:	8526                	mv	a0,s1
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	790080e7          	jalr	1936(ra) # 8000450a <log_write>
    brelse(bp);
    80003d82:	8526                	mv	a0,s1
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	50a080e7          	jalr	1290(ra) # 8000328e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d8c:	01498a3b          	addw	s4,s3,s4
    80003d90:	0129893b          	addw	s2,s3,s2
    80003d94:	9aee                	add	s5,s5,s11
    80003d96:	057a7663          	bgeu	s4,s7,80003de2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d9a:	000b2483          	lw	s1,0(s6)
    80003d9e:	00a9559b          	srliw	a1,s2,0xa
    80003da2:	855a                	mv	a0,s6
    80003da4:	fffff097          	auipc	ra,0xfffff
    80003da8:	7ae080e7          	jalr	1966(ra) # 80003552 <bmap>
    80003dac:	0005059b          	sext.w	a1,a0
    80003db0:	8526                	mv	a0,s1
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	3ac080e7          	jalr	940(ra) # 8000315e <bread>
    80003dba:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dbc:	3ff97713          	andi	a4,s2,1023
    80003dc0:	40ed07bb          	subw	a5,s10,a4
    80003dc4:	414b86bb          	subw	a3,s7,s4
    80003dc8:	89be                	mv	s3,a5
    80003dca:	2781                	sext.w	a5,a5
    80003dcc:	0006861b          	sext.w	a2,a3
    80003dd0:	f8f674e3          	bgeu	a2,a5,80003d58 <writei+0x4c>
    80003dd4:	89b6                	mv	s3,a3
    80003dd6:	b749                	j	80003d58 <writei+0x4c>
      brelse(bp);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	4b4080e7          	jalr	1204(ra) # 8000328e <brelse>
  }

  if(off > ip->size)
    80003de2:	04cb2783          	lw	a5,76(s6)
    80003de6:	0127f463          	bgeu	a5,s2,80003dee <writei+0xe2>
    ip->size = off;
    80003dea:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dee:	855a                	mv	a0,s6
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	aa6080e7          	jalr	-1370(ra) # 80003896 <iupdate>

  return tot;
    80003df8:	000a051b          	sext.w	a0,s4
}
    80003dfc:	70a6                	ld	ra,104(sp)
    80003dfe:	7406                	ld	s0,96(sp)
    80003e00:	64e6                	ld	s1,88(sp)
    80003e02:	6946                	ld	s2,80(sp)
    80003e04:	69a6                	ld	s3,72(sp)
    80003e06:	6a06                	ld	s4,64(sp)
    80003e08:	7ae2                	ld	s5,56(sp)
    80003e0a:	7b42                	ld	s6,48(sp)
    80003e0c:	7ba2                	ld	s7,40(sp)
    80003e0e:	7c02                	ld	s8,32(sp)
    80003e10:	6ce2                	ld	s9,24(sp)
    80003e12:	6d42                	ld	s10,16(sp)
    80003e14:	6da2                	ld	s11,8(sp)
    80003e16:	6165                	addi	sp,sp,112
    80003e18:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e1a:	8a5e                	mv	s4,s7
    80003e1c:	bfc9                	j	80003dee <writei+0xe2>
    return -1;
    80003e1e:	557d                	li	a0,-1
}
    80003e20:	8082                	ret
    return -1;
    80003e22:	557d                	li	a0,-1
    80003e24:	bfe1                	j	80003dfc <writei+0xf0>
    return -1;
    80003e26:	557d                	li	a0,-1
    80003e28:	bfd1                	j	80003dfc <writei+0xf0>

0000000080003e2a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e2a:	1141                	addi	sp,sp,-16
    80003e2c:	e406                	sd	ra,8(sp)
    80003e2e:	e022                	sd	s0,0(sp)
    80003e30:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e32:	4639                	li	a2,14
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	f84080e7          	jalr	-124(ra) # 80000db8 <strncmp>
}
    80003e3c:	60a2                	ld	ra,8(sp)
    80003e3e:	6402                	ld	s0,0(sp)
    80003e40:	0141                	addi	sp,sp,16
    80003e42:	8082                	ret

0000000080003e44 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e44:	7139                	addi	sp,sp,-64
    80003e46:	fc06                	sd	ra,56(sp)
    80003e48:	f822                	sd	s0,48(sp)
    80003e4a:	f426                	sd	s1,40(sp)
    80003e4c:	f04a                	sd	s2,32(sp)
    80003e4e:	ec4e                	sd	s3,24(sp)
    80003e50:	e852                	sd	s4,16(sp)
    80003e52:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e54:	04451703          	lh	a4,68(a0)
    80003e58:	4785                	li	a5,1
    80003e5a:	00f71a63          	bne	a4,a5,80003e6e <dirlookup+0x2a>
    80003e5e:	892a                	mv	s2,a0
    80003e60:	89ae                	mv	s3,a1
    80003e62:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e64:	457c                	lw	a5,76(a0)
    80003e66:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e68:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6a:	e79d                	bnez	a5,80003e98 <dirlookup+0x54>
    80003e6c:	a8a5                	j	80003ee4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e6e:	00005517          	auipc	a0,0x5
    80003e72:	83250513          	addi	a0,a0,-1998 # 800086a0 <syscalls+0x1b8>
    80003e76:	ffffc097          	auipc	ra,0xffffc
    80003e7a:	6c8080e7          	jalr	1736(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e7e:	00005517          	auipc	a0,0x5
    80003e82:	83a50513          	addi	a0,a0,-1990 # 800086b8 <syscalls+0x1d0>
    80003e86:	ffffc097          	auipc	ra,0xffffc
    80003e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8e:	24c1                	addiw	s1,s1,16
    80003e90:	04c92783          	lw	a5,76(s2)
    80003e94:	04f4f763          	bgeu	s1,a5,80003ee2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e98:	4741                	li	a4,16
    80003e9a:	86a6                	mv	a3,s1
    80003e9c:	fc040613          	addi	a2,s0,-64
    80003ea0:	4581                	li	a1,0
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	d70080e7          	jalr	-656(ra) # 80003c14 <readi>
    80003eac:	47c1                	li	a5,16
    80003eae:	fcf518e3          	bne	a0,a5,80003e7e <dirlookup+0x3a>
    if(de.inum == 0)
    80003eb2:	fc045783          	lhu	a5,-64(s0)
    80003eb6:	dfe1                	beqz	a5,80003e8e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eb8:	fc240593          	addi	a1,s0,-62
    80003ebc:	854e                	mv	a0,s3
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	f6c080e7          	jalr	-148(ra) # 80003e2a <namecmp>
    80003ec6:	f561                	bnez	a0,80003e8e <dirlookup+0x4a>
      if(poff)
    80003ec8:	000a0463          	beqz	s4,80003ed0 <dirlookup+0x8c>
        *poff = off;
    80003ecc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed0:	fc045583          	lhu	a1,-64(s0)
    80003ed4:	00092503          	lw	a0,0(s2)
    80003ed8:	fffff097          	auipc	ra,0xfffff
    80003edc:	754080e7          	jalr	1876(ra) # 8000362c <iget>
    80003ee0:	a011                	j	80003ee4 <dirlookup+0xa0>
  return 0;
    80003ee2:	4501                	li	a0,0
}
    80003ee4:	70e2                	ld	ra,56(sp)
    80003ee6:	7442                	ld	s0,48(sp)
    80003ee8:	74a2                	ld	s1,40(sp)
    80003eea:	7902                	ld	s2,32(sp)
    80003eec:	69e2                	ld	s3,24(sp)
    80003eee:	6a42                	ld	s4,16(sp)
    80003ef0:	6121                	addi	sp,sp,64
    80003ef2:	8082                	ret

0000000080003ef4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ef4:	711d                	addi	sp,sp,-96
    80003ef6:	ec86                	sd	ra,88(sp)
    80003ef8:	e8a2                	sd	s0,80(sp)
    80003efa:	e4a6                	sd	s1,72(sp)
    80003efc:	e0ca                	sd	s2,64(sp)
    80003efe:	fc4e                	sd	s3,56(sp)
    80003f00:	f852                	sd	s4,48(sp)
    80003f02:	f456                	sd	s5,40(sp)
    80003f04:	f05a                	sd	s6,32(sp)
    80003f06:	ec5e                	sd	s7,24(sp)
    80003f08:	e862                	sd	s8,16(sp)
    80003f0a:	e466                	sd	s9,8(sp)
    80003f0c:	1080                	addi	s0,sp,96
    80003f0e:	84aa                	mv	s1,a0
    80003f10:	8b2e                	mv	s6,a1
    80003f12:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f14:	00054703          	lbu	a4,0(a0)
    80003f18:	02f00793          	li	a5,47
    80003f1c:	02f70363          	beq	a4,a5,80003f42 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f20:	ffffe097          	auipc	ra,0xffffe
    80003f24:	d6e080e7          	jalr	-658(ra) # 80001c8e <myproc>
    80003f28:	16853503          	ld	a0,360(a0)
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	9f6080e7          	jalr	-1546(ra) # 80003922 <idup>
    80003f34:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f36:	02f00913          	li	s2,47
  len = path - s;
    80003f3a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f3c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f3e:	4c05                	li	s8,1
    80003f40:	a865                	j	80003ff8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f42:	4585                	li	a1,1
    80003f44:	4505                	li	a0,1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	6e6080e7          	jalr	1766(ra) # 8000362c <iget>
    80003f4e:	89aa                	mv	s3,a0
    80003f50:	b7dd                	j	80003f36 <namex+0x42>
      iunlockput(ip);
    80003f52:	854e                	mv	a0,s3
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	c6e080e7          	jalr	-914(ra) # 80003bc2 <iunlockput>
      return 0;
    80003f5c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f5e:	854e                	mv	a0,s3
    80003f60:	60e6                	ld	ra,88(sp)
    80003f62:	6446                	ld	s0,80(sp)
    80003f64:	64a6                	ld	s1,72(sp)
    80003f66:	6906                	ld	s2,64(sp)
    80003f68:	79e2                	ld	s3,56(sp)
    80003f6a:	7a42                	ld	s4,48(sp)
    80003f6c:	7aa2                	ld	s5,40(sp)
    80003f6e:	7b02                	ld	s6,32(sp)
    80003f70:	6be2                	ld	s7,24(sp)
    80003f72:	6c42                	ld	s8,16(sp)
    80003f74:	6ca2                	ld	s9,8(sp)
    80003f76:	6125                	addi	sp,sp,96
    80003f78:	8082                	ret
      iunlock(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	aa6080e7          	jalr	-1370(ra) # 80003a22 <iunlock>
      return ip;
    80003f84:	bfe9                	j	80003f5e <namex+0x6a>
      iunlockput(ip);
    80003f86:	854e                	mv	a0,s3
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	c3a080e7          	jalr	-966(ra) # 80003bc2 <iunlockput>
      return 0;
    80003f90:	89d2                	mv	s3,s4
    80003f92:	b7f1                	j	80003f5e <namex+0x6a>
  len = path - s;
    80003f94:	40b48633          	sub	a2,s1,a1
    80003f98:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f9c:	094cd463          	bge	s9,s4,80004024 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fa0:	4639                	li	a2,14
    80003fa2:	8556                	mv	a0,s5
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	d9c080e7          	jalr	-612(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	01279763          	bne	a5,s2,80003fbe <namex+0xca>
    path++;
    80003fb4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb6:	0004c783          	lbu	a5,0(s1)
    80003fba:	ff278de3          	beq	a5,s2,80003fb4 <namex+0xc0>
    ilock(ip);
    80003fbe:	854e                	mv	a0,s3
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	9a0080e7          	jalr	-1632(ra) # 80003960 <ilock>
    if(ip->type != T_DIR){
    80003fc8:	04499783          	lh	a5,68(s3)
    80003fcc:	f98793e3          	bne	a5,s8,80003f52 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fd0:	000b0563          	beqz	s6,80003fda <namex+0xe6>
    80003fd4:	0004c783          	lbu	a5,0(s1)
    80003fd8:	d3cd                	beqz	a5,80003f7a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fda:	865e                	mv	a2,s7
    80003fdc:	85d6                	mv	a1,s5
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	e64080e7          	jalr	-412(ra) # 80003e44 <dirlookup>
    80003fe8:	8a2a                	mv	s4,a0
    80003fea:	dd51                	beqz	a0,80003f86 <namex+0x92>
    iunlockput(ip);
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	bd4080e7          	jalr	-1068(ra) # 80003bc2 <iunlockput>
    ip = next;
    80003ff6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ff8:	0004c783          	lbu	a5,0(s1)
    80003ffc:	05279763          	bne	a5,s2,8000404a <namex+0x156>
    path++;
    80004000:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004002:	0004c783          	lbu	a5,0(s1)
    80004006:	ff278de3          	beq	a5,s2,80004000 <namex+0x10c>
  if(*path == 0)
    8000400a:	c79d                	beqz	a5,80004038 <namex+0x144>
    path++;
    8000400c:	85a6                	mv	a1,s1
  len = path - s;
    8000400e:	8a5e                	mv	s4,s7
    80004010:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004012:	01278963          	beq	a5,s2,80004024 <namex+0x130>
    80004016:	dfbd                	beqz	a5,80003f94 <namex+0xa0>
    path++;
    80004018:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	ff279ce3          	bne	a5,s2,80004016 <namex+0x122>
    80004022:	bf8d                	j	80003f94 <namex+0xa0>
    memmove(name, s, len);
    80004024:	2601                	sext.w	a2,a2
    80004026:	8556                	mv	a0,s5
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	d18080e7          	jalr	-744(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004030:	9a56                	add	s4,s4,s5
    80004032:	000a0023          	sb	zero,0(s4)
    80004036:	bf9d                	j	80003fac <namex+0xb8>
  if(nameiparent){
    80004038:	f20b03e3          	beqz	s6,80003f5e <namex+0x6a>
    iput(ip);
    8000403c:	854e                	mv	a0,s3
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	adc080e7          	jalr	-1316(ra) # 80003b1a <iput>
    return 0;
    80004046:	4981                	li	s3,0
    80004048:	bf19                	j	80003f5e <namex+0x6a>
  if(*path == 0)
    8000404a:	d7fd                	beqz	a5,80004038 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000404c:	0004c783          	lbu	a5,0(s1)
    80004050:	85a6                	mv	a1,s1
    80004052:	b7d1                	j	80004016 <namex+0x122>

0000000080004054 <dirlink>:
{
    80004054:	7139                	addi	sp,sp,-64
    80004056:	fc06                	sd	ra,56(sp)
    80004058:	f822                	sd	s0,48(sp)
    8000405a:	f426                	sd	s1,40(sp)
    8000405c:	f04a                	sd	s2,32(sp)
    8000405e:	ec4e                	sd	s3,24(sp)
    80004060:	e852                	sd	s4,16(sp)
    80004062:	0080                	addi	s0,sp,64
    80004064:	892a                	mv	s2,a0
    80004066:	8a2e                	mv	s4,a1
    80004068:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000406a:	4601                	li	a2,0
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	dd8080e7          	jalr	-552(ra) # 80003e44 <dirlookup>
    80004074:	e93d                	bnez	a0,800040ea <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004076:	04c92483          	lw	s1,76(s2)
    8000407a:	c49d                	beqz	s1,800040a8 <dirlink+0x54>
    8000407c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000407e:	4741                	li	a4,16
    80004080:	86a6                	mv	a3,s1
    80004082:	fc040613          	addi	a2,s0,-64
    80004086:	4581                	li	a1,0
    80004088:	854a                	mv	a0,s2
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	b8a080e7          	jalr	-1142(ra) # 80003c14 <readi>
    80004092:	47c1                	li	a5,16
    80004094:	06f51163          	bne	a0,a5,800040f6 <dirlink+0xa2>
    if(de.inum == 0)
    80004098:	fc045783          	lhu	a5,-64(s0)
    8000409c:	c791                	beqz	a5,800040a8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409e:	24c1                	addiw	s1,s1,16
    800040a0:	04c92783          	lw	a5,76(s2)
    800040a4:	fcf4ede3          	bltu	s1,a5,8000407e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040a8:	4639                	li	a2,14
    800040aa:	85d2                	mv	a1,s4
    800040ac:	fc240513          	addi	a0,s0,-62
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	d44080e7          	jalr	-700(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040b8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040bc:	4741                	li	a4,16
    800040be:	86a6                	mv	a3,s1
    800040c0:	fc040613          	addi	a2,s0,-64
    800040c4:	4581                	li	a1,0
    800040c6:	854a                	mv	a0,s2
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	c44080e7          	jalr	-956(ra) # 80003d0c <writei>
    800040d0:	872a                	mv	a4,a0
    800040d2:	47c1                	li	a5,16
  return 0;
    800040d4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d6:	02f71863          	bne	a4,a5,80004106 <dirlink+0xb2>
}
    800040da:	70e2                	ld	ra,56(sp)
    800040dc:	7442                	ld	s0,48(sp)
    800040de:	74a2                	ld	s1,40(sp)
    800040e0:	7902                	ld	s2,32(sp)
    800040e2:	69e2                	ld	s3,24(sp)
    800040e4:	6a42                	ld	s4,16(sp)
    800040e6:	6121                	addi	sp,sp,64
    800040e8:	8082                	ret
    iput(ip);
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	a30080e7          	jalr	-1488(ra) # 80003b1a <iput>
    return -1;
    800040f2:	557d                	li	a0,-1
    800040f4:	b7dd                	j	800040da <dirlink+0x86>
      panic("dirlink read");
    800040f6:	00004517          	auipc	a0,0x4
    800040fa:	5d250513          	addi	a0,a0,1490 # 800086c8 <syscalls+0x1e0>
    800040fe:	ffffc097          	auipc	ra,0xffffc
    80004102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("dirlink");
    80004106:	00004517          	auipc	a0,0x4
    8000410a:	6d250513          	addi	a0,a0,1746 # 800087d8 <syscalls+0x2f0>
    8000410e:	ffffc097          	auipc	ra,0xffffc
    80004112:	430080e7          	jalr	1072(ra) # 8000053e <panic>

0000000080004116 <namei>:

struct inode*
namei(char *path)
{
    80004116:	1101                	addi	sp,sp,-32
    80004118:	ec06                	sd	ra,24(sp)
    8000411a:	e822                	sd	s0,16(sp)
    8000411c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000411e:	fe040613          	addi	a2,s0,-32
    80004122:	4581                	li	a1,0
    80004124:	00000097          	auipc	ra,0x0
    80004128:	dd0080e7          	jalr	-560(ra) # 80003ef4 <namex>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	6105                	addi	sp,sp,32
    80004132:	8082                	ret

0000000080004134 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004134:	1141                	addi	sp,sp,-16
    80004136:	e406                	sd	ra,8(sp)
    80004138:	e022                	sd	s0,0(sp)
    8000413a:	0800                	addi	s0,sp,16
    8000413c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000413e:	4585                	li	a1,1
    80004140:	00000097          	auipc	ra,0x0
    80004144:	db4080e7          	jalr	-588(ra) # 80003ef4 <namex>
}
    80004148:	60a2                	ld	ra,8(sp)
    8000414a:	6402                	ld	s0,0(sp)
    8000414c:	0141                	addi	sp,sp,16
    8000414e:	8082                	ret

0000000080004150 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004150:	1101                	addi	sp,sp,-32
    80004152:	ec06                	sd	ra,24(sp)
    80004154:	e822                	sd	s0,16(sp)
    80004156:	e426                	sd	s1,8(sp)
    80004158:	e04a                	sd	s2,0(sp)
    8000415a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000415c:	0001d917          	auipc	s2,0x1d
    80004160:	73490913          	addi	s2,s2,1844 # 80021890 <log>
    80004164:	01892583          	lw	a1,24(s2)
    80004168:	02892503          	lw	a0,40(s2)
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	ff2080e7          	jalr	-14(ra) # 8000315e <bread>
    80004174:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004176:	02c92683          	lw	a3,44(s2)
    8000417a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000417c:	02d05763          	blez	a3,800041aa <write_head+0x5a>
    80004180:	0001d797          	auipc	a5,0x1d
    80004184:	74078793          	addi	a5,a5,1856 # 800218c0 <log+0x30>
    80004188:	05c50713          	addi	a4,a0,92
    8000418c:	36fd                	addiw	a3,a3,-1
    8000418e:	1682                	slli	a3,a3,0x20
    80004190:	9281                	srli	a3,a3,0x20
    80004192:	068a                	slli	a3,a3,0x2
    80004194:	0001d617          	auipc	a2,0x1d
    80004198:	73060613          	addi	a2,a2,1840 # 800218c4 <log+0x34>
    8000419c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000419e:	4390                	lw	a2,0(a5)
    800041a0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041a2:	0791                	addi	a5,a5,4
    800041a4:	0711                	addi	a4,a4,4
    800041a6:	fed79ce3          	bne	a5,a3,8000419e <write_head+0x4e>
  }
  bwrite(buf);
    800041aa:	8526                	mv	a0,s1
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	0a4080e7          	jalr	164(ra) # 80003250 <bwrite>
  brelse(buf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	0d8080e7          	jalr	216(ra) # 8000328e <brelse>
}
    800041be:	60e2                	ld	ra,24(sp)
    800041c0:	6442                	ld	s0,16(sp)
    800041c2:	64a2                	ld	s1,8(sp)
    800041c4:	6902                	ld	s2,0(sp)
    800041c6:	6105                	addi	sp,sp,32
    800041c8:	8082                	ret

00000000800041ca <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ca:	0001d797          	auipc	a5,0x1d
    800041ce:	6f27a783          	lw	a5,1778(a5) # 800218bc <log+0x2c>
    800041d2:	0af05d63          	blez	a5,8000428c <install_trans+0xc2>
{
    800041d6:	7139                	addi	sp,sp,-64
    800041d8:	fc06                	sd	ra,56(sp)
    800041da:	f822                	sd	s0,48(sp)
    800041dc:	f426                	sd	s1,40(sp)
    800041de:	f04a                	sd	s2,32(sp)
    800041e0:	ec4e                	sd	s3,24(sp)
    800041e2:	e852                	sd	s4,16(sp)
    800041e4:	e456                	sd	s5,8(sp)
    800041e6:	e05a                	sd	s6,0(sp)
    800041e8:	0080                	addi	s0,sp,64
    800041ea:	8b2a                	mv	s6,a0
    800041ec:	0001da97          	auipc	s5,0x1d
    800041f0:	6d4a8a93          	addi	s5,s5,1748 # 800218c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f6:	0001d997          	auipc	s3,0x1d
    800041fa:	69a98993          	addi	s3,s3,1690 # 80021890 <log>
    800041fe:	a035                	j	8000422a <install_trans+0x60>
      bunpin(dbuf);
    80004200:	8526                	mv	a0,s1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	166080e7          	jalr	358(ra) # 80003368 <bunpin>
    brelse(lbuf);
    8000420a:	854a                	mv	a0,s2
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	082080e7          	jalr	130(ra) # 8000328e <brelse>
    brelse(dbuf);
    80004214:	8526                	mv	a0,s1
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	078080e7          	jalr	120(ra) # 8000328e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421e:	2a05                	addiw	s4,s4,1
    80004220:	0a91                	addi	s5,s5,4
    80004222:	02c9a783          	lw	a5,44(s3)
    80004226:	04fa5963          	bge	s4,a5,80004278 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000422a:	0189a583          	lw	a1,24(s3)
    8000422e:	014585bb          	addw	a1,a1,s4
    80004232:	2585                	addiw	a1,a1,1
    80004234:	0289a503          	lw	a0,40(s3)
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	f26080e7          	jalr	-218(ra) # 8000315e <bread>
    80004240:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004242:	000aa583          	lw	a1,0(s5)
    80004246:	0289a503          	lw	a0,40(s3)
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	f14080e7          	jalr	-236(ra) # 8000315e <bread>
    80004252:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004254:	40000613          	li	a2,1024
    80004258:	05890593          	addi	a1,s2,88
    8000425c:	05850513          	addi	a0,a0,88
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	ae0080e7          	jalr	-1312(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	fe6080e7          	jalr	-26(ra) # 80003250 <bwrite>
    if(recovering == 0)
    80004272:	f80b1ce3          	bnez	s6,8000420a <install_trans+0x40>
    80004276:	b769                	j	80004200 <install_trans+0x36>
}
    80004278:	70e2                	ld	ra,56(sp)
    8000427a:	7442                	ld	s0,48(sp)
    8000427c:	74a2                	ld	s1,40(sp)
    8000427e:	7902                	ld	s2,32(sp)
    80004280:	69e2                	ld	s3,24(sp)
    80004282:	6a42                	ld	s4,16(sp)
    80004284:	6aa2                	ld	s5,8(sp)
    80004286:	6b02                	ld	s6,0(sp)
    80004288:	6121                	addi	sp,sp,64
    8000428a:	8082                	ret
    8000428c:	8082                	ret

000000008000428e <initlog>:
{
    8000428e:	7179                	addi	sp,sp,-48
    80004290:	f406                	sd	ra,40(sp)
    80004292:	f022                	sd	s0,32(sp)
    80004294:	ec26                	sd	s1,24(sp)
    80004296:	e84a                	sd	s2,16(sp)
    80004298:	e44e                	sd	s3,8(sp)
    8000429a:	1800                	addi	s0,sp,48
    8000429c:	892a                	mv	s2,a0
    8000429e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042a0:	0001d497          	auipc	s1,0x1d
    800042a4:	5f048493          	addi	s1,s1,1520 # 80021890 <log>
    800042a8:	00004597          	auipc	a1,0x4
    800042ac:	43058593          	addi	a1,a1,1072 # 800086d8 <syscalls+0x1f0>
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	8a2080e7          	jalr	-1886(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042ba:	0149a583          	lw	a1,20(s3)
    800042be:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042c0:	0109a783          	lw	a5,16(s3)
    800042c4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042c6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ca:	854a                	mv	a0,s2
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	e92080e7          	jalr	-366(ra) # 8000315e <bread>
  log.lh.n = lh->n;
    800042d4:	4d3c                	lw	a5,88(a0)
    800042d6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042d8:	02f05563          	blez	a5,80004302 <initlog+0x74>
    800042dc:	05c50713          	addi	a4,a0,92
    800042e0:	0001d697          	auipc	a3,0x1d
    800042e4:	5e068693          	addi	a3,a3,1504 # 800218c0 <log+0x30>
    800042e8:	37fd                	addiw	a5,a5,-1
    800042ea:	1782                	slli	a5,a5,0x20
    800042ec:	9381                	srli	a5,a5,0x20
    800042ee:	078a                	slli	a5,a5,0x2
    800042f0:	06050613          	addi	a2,a0,96
    800042f4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042f6:	4310                	lw	a2,0(a4)
    800042f8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	0711                	addi	a4,a4,4
    800042fc:	0691                	addi	a3,a3,4
    800042fe:	fef71ce3          	bne	a4,a5,800042f6 <initlog+0x68>
  brelse(buf);
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	f8c080e7          	jalr	-116(ra) # 8000328e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000430a:	4505                	li	a0,1
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	ebe080e7          	jalr	-322(ra) # 800041ca <install_trans>
  log.lh.n = 0;
    80004314:	0001d797          	auipc	a5,0x1d
    80004318:	5a07a423          	sw	zero,1448(a5) # 800218bc <log+0x2c>
  write_head(); // clear the log
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	e34080e7          	jalr	-460(ra) # 80004150 <write_head>
}
    80004324:	70a2                	ld	ra,40(sp)
    80004326:	7402                	ld	s0,32(sp)
    80004328:	64e2                	ld	s1,24(sp)
    8000432a:	6942                	ld	s2,16(sp)
    8000432c:	69a2                	ld	s3,8(sp)
    8000432e:	6145                	addi	sp,sp,48
    80004330:	8082                	ret

0000000080004332 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004332:	1101                	addi	sp,sp,-32
    80004334:	ec06                	sd	ra,24(sp)
    80004336:	e822                	sd	s0,16(sp)
    80004338:	e426                	sd	s1,8(sp)
    8000433a:	e04a                	sd	s2,0(sp)
    8000433c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000433e:	0001d517          	auipc	a0,0x1d
    80004342:	55250513          	addi	a0,a0,1362 # 80021890 <log>
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	89e080e7          	jalr	-1890(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000434e:	0001d497          	auipc	s1,0x1d
    80004352:	54248493          	addi	s1,s1,1346 # 80021890 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004356:	4979                	li	s2,30
    80004358:	a039                	j	80004366 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000435a:	85a6                	mv	a1,s1
    8000435c:	8526                	mv	a0,s1
    8000435e:	ffffe097          	auipc	ra,0xffffe
    80004362:	fc6080e7          	jalr	-58(ra) # 80002324 <sleep>
    if(log.committing){
    80004366:	50dc                	lw	a5,36(s1)
    80004368:	fbed                	bnez	a5,8000435a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436a:	509c                	lw	a5,32(s1)
    8000436c:	0017871b          	addiw	a4,a5,1
    80004370:	0007069b          	sext.w	a3,a4
    80004374:	0027179b          	slliw	a5,a4,0x2
    80004378:	9fb9                	addw	a5,a5,a4
    8000437a:	0017979b          	slliw	a5,a5,0x1
    8000437e:	54d8                	lw	a4,44(s1)
    80004380:	9fb9                	addw	a5,a5,a4
    80004382:	00f95963          	bge	s2,a5,80004394 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004386:	85a6                	mv	a1,s1
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffe097          	auipc	ra,0xffffe
    8000438e:	f9a080e7          	jalr	-102(ra) # 80002324 <sleep>
    80004392:	bfd1                	j	80004366 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004394:	0001d517          	auipc	a0,0x1d
    80004398:	4fc50513          	addi	a0,a0,1276 # 80021890 <log>
    8000439c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043a6:	60e2                	ld	ra,24(sp)
    800043a8:	6442                	ld	s0,16(sp)
    800043aa:	64a2                	ld	s1,8(sp)
    800043ac:	6902                	ld	s2,0(sp)
    800043ae:	6105                	addi	sp,sp,32
    800043b0:	8082                	ret

00000000800043b2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043b2:	7139                	addi	sp,sp,-64
    800043b4:	fc06                	sd	ra,56(sp)
    800043b6:	f822                	sd	s0,48(sp)
    800043b8:	f426                	sd	s1,40(sp)
    800043ba:	f04a                	sd	s2,32(sp)
    800043bc:	ec4e                	sd	s3,24(sp)
    800043be:	e852                	sd	s4,16(sp)
    800043c0:	e456                	sd	s5,8(sp)
    800043c2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043c4:	0001d497          	auipc	s1,0x1d
    800043c8:	4cc48493          	addi	s1,s1,1228 # 80021890 <log>
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043d6:	509c                	lw	a5,32(s1)
    800043d8:	37fd                	addiw	a5,a5,-1
    800043da:	0007891b          	sext.w	s2,a5
    800043de:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043e0:	50dc                	lw	a5,36(s1)
    800043e2:	efb9                	bnez	a5,80004440 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043e4:	06091663          	bnez	s2,80004450 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043e8:	0001d497          	auipc	s1,0x1d
    800043ec:	4a848493          	addi	s1,s1,1192 # 80021890 <log>
    800043f0:	4785                	li	a5,1
    800043f2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043f4:	8526                	mv	a0,s1
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	8a2080e7          	jalr	-1886(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043fe:	54dc                	lw	a5,44(s1)
    80004400:	06f04763          	bgtz	a5,8000446e <end_op+0xbc>
    acquire(&log.lock);
    80004404:	0001d497          	auipc	s1,0x1d
    80004408:	48c48493          	addi	s1,s1,1164 # 80021890 <log>
    8000440c:	8526                	mv	a0,s1
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	7d6080e7          	jalr	2006(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004416:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000441a:	8526                	mv	a0,s1
    8000441c:	ffffe097          	auipc	ra,0xffffe
    80004420:	0ae080e7          	jalr	174(ra) # 800024ca <wakeup>
    release(&log.lock);
    80004424:	8526                	mv	a0,s1
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	872080e7          	jalr	-1934(ra) # 80000c98 <release>
}
    8000442e:	70e2                	ld	ra,56(sp)
    80004430:	7442                	ld	s0,48(sp)
    80004432:	74a2                	ld	s1,40(sp)
    80004434:	7902                	ld	s2,32(sp)
    80004436:	69e2                	ld	s3,24(sp)
    80004438:	6a42                	ld	s4,16(sp)
    8000443a:	6aa2                	ld	s5,8(sp)
    8000443c:	6121                	addi	sp,sp,64
    8000443e:	8082                	ret
    panic("log.committing");
    80004440:	00004517          	auipc	a0,0x4
    80004444:	2a050513          	addi	a0,a0,672 # 800086e0 <syscalls+0x1f8>
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	0f6080e7          	jalr	246(ra) # 8000053e <panic>
    wakeup(&log);
    80004450:	0001d497          	auipc	s1,0x1d
    80004454:	44048493          	addi	s1,s1,1088 # 80021890 <log>
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	070080e7          	jalr	112(ra) # 800024ca <wakeup>
  release(&log.lock);
    80004462:	8526                	mv	a0,s1
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	834080e7          	jalr	-1996(ra) # 80000c98 <release>
  if(do_commit){
    8000446c:	b7c9                	j	8000442e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000446e:	0001da97          	auipc	s5,0x1d
    80004472:	452a8a93          	addi	s5,s5,1106 # 800218c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004476:	0001da17          	auipc	s4,0x1d
    8000447a:	41aa0a13          	addi	s4,s4,1050 # 80021890 <log>
    8000447e:	018a2583          	lw	a1,24(s4)
    80004482:	012585bb          	addw	a1,a1,s2
    80004486:	2585                	addiw	a1,a1,1
    80004488:	028a2503          	lw	a0,40(s4)
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	cd2080e7          	jalr	-814(ra) # 8000315e <bread>
    80004494:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004496:	000aa583          	lw	a1,0(s5)
    8000449a:	028a2503          	lw	a0,40(s4)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	cc0080e7          	jalr	-832(ra) # 8000315e <bread>
    800044a6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044a8:	40000613          	li	a2,1024
    800044ac:	05850593          	addi	a1,a0,88
    800044b0:	05848513          	addi	a0,s1,88
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	88c080e7          	jalr	-1908(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044bc:	8526                	mv	a0,s1
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	d92080e7          	jalr	-622(ra) # 80003250 <bwrite>
    brelse(from);
    800044c6:	854e                	mv	a0,s3
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	dc6080e7          	jalr	-570(ra) # 8000328e <brelse>
    brelse(to);
    800044d0:	8526                	mv	a0,s1
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	dbc080e7          	jalr	-580(ra) # 8000328e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044da:	2905                	addiw	s2,s2,1
    800044dc:	0a91                	addi	s5,s5,4
    800044de:	02ca2783          	lw	a5,44(s4)
    800044e2:	f8f94ee3          	blt	s2,a5,8000447e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	c6a080e7          	jalr	-918(ra) # 80004150 <write_head>
    install_trans(0); // Now install writes to home locations
    800044ee:	4501                	li	a0,0
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	cda080e7          	jalr	-806(ra) # 800041ca <install_trans>
    log.lh.n = 0;
    800044f8:	0001d797          	auipc	a5,0x1d
    800044fc:	3c07a223          	sw	zero,964(a5) # 800218bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004500:	00000097          	auipc	ra,0x0
    80004504:	c50080e7          	jalr	-944(ra) # 80004150 <write_head>
    80004508:	bdf5                	j	80004404 <end_op+0x52>

000000008000450a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004518:	0001d917          	auipc	s2,0x1d
    8000451c:	37890913          	addi	s2,s2,888 # 80021890 <log>
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	6c2080e7          	jalr	1730(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000452a:	02c92603          	lw	a2,44(s2)
    8000452e:	47f5                	li	a5,29
    80004530:	06c7c563          	blt	a5,a2,8000459a <log_write+0x90>
    80004534:	0001d797          	auipc	a5,0x1d
    80004538:	3787a783          	lw	a5,888(a5) # 800218ac <log+0x1c>
    8000453c:	37fd                	addiw	a5,a5,-1
    8000453e:	04f65e63          	bge	a2,a5,8000459a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004542:	0001d797          	auipc	a5,0x1d
    80004546:	36e7a783          	lw	a5,878(a5) # 800218b0 <log+0x20>
    8000454a:	06f05063          	blez	a5,800045aa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000454e:	4781                	li	a5,0
    80004550:	06c05563          	blez	a2,800045ba <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004554:	44cc                	lw	a1,12(s1)
    80004556:	0001d717          	auipc	a4,0x1d
    8000455a:	36a70713          	addi	a4,a4,874 # 800218c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000455e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004560:	4314                	lw	a3,0(a4)
    80004562:	04b68c63          	beq	a3,a1,800045ba <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004566:	2785                	addiw	a5,a5,1
    80004568:	0711                	addi	a4,a4,4
    8000456a:	fef61be3          	bne	a2,a5,80004560 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000456e:	0621                	addi	a2,a2,8
    80004570:	060a                	slli	a2,a2,0x2
    80004572:	0001d797          	auipc	a5,0x1d
    80004576:	31e78793          	addi	a5,a5,798 # 80021890 <log>
    8000457a:	963e                	add	a2,a2,a5
    8000457c:	44dc                	lw	a5,12(s1)
    8000457e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004580:	8526                	mv	a0,s1
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	daa080e7          	jalr	-598(ra) # 8000332c <bpin>
    log.lh.n++;
    8000458a:	0001d717          	auipc	a4,0x1d
    8000458e:	30670713          	addi	a4,a4,774 # 80021890 <log>
    80004592:	575c                	lw	a5,44(a4)
    80004594:	2785                	addiw	a5,a5,1
    80004596:	d75c                	sw	a5,44(a4)
    80004598:	a835                	j	800045d4 <log_write+0xca>
    panic("too big a transaction");
    8000459a:	00004517          	auipc	a0,0x4
    8000459e:	15650513          	addi	a0,a0,342 # 800086f0 <syscalls+0x208>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045aa:	00004517          	auipc	a0,0x4
    800045ae:	15e50513          	addi	a0,a0,350 # 80008708 <syscalls+0x220>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	f8c080e7          	jalr	-116(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045ba:	00878713          	addi	a4,a5,8
    800045be:	00271693          	slli	a3,a4,0x2
    800045c2:	0001d717          	auipc	a4,0x1d
    800045c6:	2ce70713          	addi	a4,a4,718 # 80021890 <log>
    800045ca:	9736                	add	a4,a4,a3
    800045cc:	44d4                	lw	a3,12(s1)
    800045ce:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045d0:	faf608e3          	beq	a2,a5,80004580 <log_write+0x76>
  }
  release(&log.lock);
    800045d4:	0001d517          	auipc	a0,0x1d
    800045d8:	2bc50513          	addi	a0,a0,700 # 80021890 <log>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6bc080e7          	jalr	1724(ra) # 80000c98 <release>
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	64a2                	ld	s1,8(sp)
    800045ea:	6902                	ld	s2,0(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	e04a                	sd	s2,0(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
    800045fe:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004600:	00004597          	auipc	a1,0x4
    80004604:	12858593          	addi	a1,a1,296 # 80008728 <syscalls+0x240>
    80004608:	0521                	addi	a0,a0,8
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	54a080e7          	jalr	1354(ra) # 80000b54 <initlock>
  lk->name = name;
    80004612:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004616:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000461a:	0204a423          	sw	zero,40(s1)
}
    8000461e:	60e2                	ld	ra,24(sp)
    80004620:	6442                	ld	s0,16(sp)
    80004622:	64a2                	ld	s1,8(sp)
    80004624:	6902                	ld	s2,0(sp)
    80004626:	6105                	addi	sp,sp,32
    80004628:	8082                	ret

000000008000462a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000462a:	1101                	addi	sp,sp,-32
    8000462c:	ec06                	sd	ra,24(sp)
    8000462e:	e822                	sd	s0,16(sp)
    80004630:	e426                	sd	s1,8(sp)
    80004632:	e04a                	sd	s2,0(sp)
    80004634:	1000                	addi	s0,sp,32
    80004636:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004638:	00850913          	addi	s2,a0,8
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004646:	409c                	lw	a5,0(s1)
    80004648:	cb89                	beqz	a5,8000465a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000464a:	85ca                	mv	a1,s2
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffe097          	auipc	ra,0xffffe
    80004652:	cd6080e7          	jalr	-810(ra) # 80002324 <sleep>
  while (lk->locked) {
    80004656:	409c                	lw	a5,0(s1)
    80004658:	fbed                	bnez	a5,8000464a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000465a:	4785                	li	a5,1
    8000465c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000465e:	ffffd097          	auipc	ra,0xffffd
    80004662:	630080e7          	jalr	1584(ra) # 80001c8e <myproc>
    80004666:	591c                	lw	a5,48(a0)
    80004668:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	62c080e7          	jalr	1580(ra) # 80000c98 <release>
}
    80004674:	60e2                	ld	ra,24(sp)
    80004676:	6442                	ld	s0,16(sp)
    80004678:	64a2                	ld	s1,8(sp)
    8000467a:	6902                	ld	s2,0(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004680:	1101                	addi	sp,sp,-32
    80004682:	ec06                	sd	ra,24(sp)
    80004684:	e822                	sd	s0,16(sp)
    80004686:	e426                	sd	s1,8(sp)
    80004688:	e04a                	sd	s2,0(sp)
    8000468a:	1000                	addi	s0,sp,32
    8000468c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000468e:	00850913          	addi	s2,a0,8
    80004692:	854a                	mv	a0,s2
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	550080e7          	jalr	1360(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000469c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046a0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffe097          	auipc	ra,0xffffe
    800046aa:	e24080e7          	jalr	-476(ra) # 800024ca <wakeup>
  release(&lk->lk);
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
}
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6902                	ld	s2,0(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret

00000000800046c4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046c4:	7179                	addi	sp,sp,-48
    800046c6:	f406                	sd	ra,40(sp)
    800046c8:	f022                	sd	s0,32(sp)
    800046ca:	ec26                	sd	s1,24(sp)
    800046cc:	e84a                	sd	s2,16(sp)
    800046ce:	e44e                	sd	s3,8(sp)
    800046d0:	1800                	addi	s0,sp,48
    800046d2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046d4:	00850913          	addi	s2,a0,8
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	50a080e7          	jalr	1290(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046e2:	409c                	lw	a5,0(s1)
    800046e4:	ef99                	bnez	a5,80004702 <holdingsleep+0x3e>
    800046e6:	4481                	li	s1,0
  release(&lk->lk);
    800046e8:	854a                	mv	a0,s2
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5ae080e7          	jalr	1454(ra) # 80000c98 <release>
  return r;
}
    800046f2:	8526                	mv	a0,s1
    800046f4:	70a2                	ld	ra,40(sp)
    800046f6:	7402                	ld	s0,32(sp)
    800046f8:	64e2                	ld	s1,24(sp)
    800046fa:	6942                	ld	s2,16(sp)
    800046fc:	69a2                	ld	s3,8(sp)
    800046fe:	6145                	addi	sp,sp,48
    80004700:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004702:	0284a983          	lw	s3,40(s1)
    80004706:	ffffd097          	auipc	ra,0xffffd
    8000470a:	588080e7          	jalr	1416(ra) # 80001c8e <myproc>
    8000470e:	5904                	lw	s1,48(a0)
    80004710:	413484b3          	sub	s1,s1,s3
    80004714:	0014b493          	seqz	s1,s1
    80004718:	bfc1                	j	800046e8 <holdingsleep+0x24>

000000008000471a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000471a:	1141                	addi	sp,sp,-16
    8000471c:	e406                	sd	ra,8(sp)
    8000471e:	e022                	sd	s0,0(sp)
    80004720:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004722:	00004597          	auipc	a1,0x4
    80004726:	01658593          	addi	a1,a1,22 # 80008738 <syscalls+0x250>
    8000472a:	0001d517          	auipc	a0,0x1d
    8000472e:	2ae50513          	addi	a0,a0,686 # 800219d8 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	422080e7          	jalr	1058(ra) # 80000b54 <initlock>
}
    8000473a:	60a2                	ld	ra,8(sp)
    8000473c:	6402                	ld	s0,0(sp)
    8000473e:	0141                	addi	sp,sp,16
    80004740:	8082                	ret

0000000080004742 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004742:	1101                	addi	sp,sp,-32
    80004744:	ec06                	sd	ra,24(sp)
    80004746:	e822                	sd	s0,16(sp)
    80004748:	e426                	sd	s1,8(sp)
    8000474a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000474c:	0001d517          	auipc	a0,0x1d
    80004750:	28c50513          	addi	a0,a0,652 # 800219d8 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	490080e7          	jalr	1168(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000475c:	0001d497          	auipc	s1,0x1d
    80004760:	29448493          	addi	s1,s1,660 # 800219f0 <ftable+0x18>
    80004764:	0001e717          	auipc	a4,0x1e
    80004768:	22c70713          	addi	a4,a4,556 # 80022990 <ftable+0xfb8>
    if(f->ref == 0){
    8000476c:	40dc                	lw	a5,4(s1)
    8000476e:	cf99                	beqz	a5,8000478c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004770:	02848493          	addi	s1,s1,40
    80004774:	fee49ce3          	bne	s1,a4,8000476c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004778:	0001d517          	auipc	a0,0x1d
    8000477c:	26050513          	addi	a0,a0,608 # 800219d8 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	518080e7          	jalr	1304(ra) # 80000c98 <release>
  return 0;
    80004788:	4481                	li	s1,0
    8000478a:	a819                	j	800047a0 <filealloc+0x5e>
      f->ref = 1;
    8000478c:	4785                	li	a5,1
    8000478e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004790:	0001d517          	auipc	a0,0x1d
    80004794:	24850513          	addi	a0,a0,584 # 800219d8 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	500080e7          	jalr	1280(ra) # 80000c98 <release>
}
    800047a0:	8526                	mv	a0,s1
    800047a2:	60e2                	ld	ra,24(sp)
    800047a4:	6442                	ld	s0,16(sp)
    800047a6:	64a2                	ld	s1,8(sp)
    800047a8:	6105                	addi	sp,sp,32
    800047aa:	8082                	ret

00000000800047ac <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047ac:	1101                	addi	sp,sp,-32
    800047ae:	ec06                	sd	ra,24(sp)
    800047b0:	e822                	sd	s0,16(sp)
    800047b2:	e426                	sd	s1,8(sp)
    800047b4:	1000                	addi	s0,sp,32
    800047b6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047b8:	0001d517          	auipc	a0,0x1d
    800047bc:	22050513          	addi	a0,a0,544 # 800219d8 <ftable>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	424080e7          	jalr	1060(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047c8:	40dc                	lw	a5,4(s1)
    800047ca:	02f05263          	blez	a5,800047ee <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ce:	2785                	addiw	a5,a5,1
    800047d0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047d2:	0001d517          	auipc	a0,0x1d
    800047d6:	20650513          	addi	a0,a0,518 # 800219d8 <ftable>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	4be080e7          	jalr	1214(ra) # 80000c98 <release>
  return f;
}
    800047e2:	8526                	mv	a0,s1
    800047e4:	60e2                	ld	ra,24(sp)
    800047e6:	6442                	ld	s0,16(sp)
    800047e8:	64a2                	ld	s1,8(sp)
    800047ea:	6105                	addi	sp,sp,32
    800047ec:	8082                	ret
    panic("filedup");
    800047ee:	00004517          	auipc	a0,0x4
    800047f2:	f5250513          	addi	a0,a0,-174 # 80008740 <syscalls+0x258>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>

00000000800047fe <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047fe:	7139                	addi	sp,sp,-64
    80004800:	fc06                	sd	ra,56(sp)
    80004802:	f822                	sd	s0,48(sp)
    80004804:	f426                	sd	s1,40(sp)
    80004806:	f04a                	sd	s2,32(sp)
    80004808:	ec4e                	sd	s3,24(sp)
    8000480a:	e852                	sd	s4,16(sp)
    8000480c:	e456                	sd	s5,8(sp)
    8000480e:	0080                	addi	s0,sp,64
    80004810:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004812:	0001d517          	auipc	a0,0x1d
    80004816:	1c650513          	addi	a0,a0,454 # 800219d8 <ftable>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	3ca080e7          	jalr	970(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004822:	40dc                	lw	a5,4(s1)
    80004824:	06f05163          	blez	a5,80004886 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004828:	37fd                	addiw	a5,a5,-1
    8000482a:	0007871b          	sext.w	a4,a5
    8000482e:	c0dc                	sw	a5,4(s1)
    80004830:	06e04363          	bgtz	a4,80004896 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004834:	0004a903          	lw	s2,0(s1)
    80004838:	0094ca83          	lbu	s5,9(s1)
    8000483c:	0104ba03          	ld	s4,16(s1)
    80004840:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004844:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004848:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000484c:	0001d517          	auipc	a0,0x1d
    80004850:	18c50513          	addi	a0,a0,396 # 800219d8 <ftable>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	444080e7          	jalr	1092(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000485c:	4785                	li	a5,1
    8000485e:	04f90d63          	beq	s2,a5,800048b8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004862:	3979                	addiw	s2,s2,-2
    80004864:	4785                	li	a5,1
    80004866:	0527e063          	bltu	a5,s2,800048a6 <fileclose+0xa8>
    begin_op();
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	ac8080e7          	jalr	-1336(ra) # 80004332 <begin_op>
    iput(ff.ip);
    80004872:	854e                	mv	a0,s3
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	2a6080e7          	jalr	678(ra) # 80003b1a <iput>
    end_op();
    8000487c:	00000097          	auipc	ra,0x0
    80004880:	b36080e7          	jalr	-1226(ra) # 800043b2 <end_op>
    80004884:	a00d                	j	800048a6 <fileclose+0xa8>
    panic("fileclose");
    80004886:	00004517          	auipc	a0,0x4
    8000488a:	ec250513          	addi	a0,a0,-318 # 80008748 <syscalls+0x260>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	14250513          	addi	a0,a0,322 # 800219d8 <ftable>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
  }
}
    800048a6:	70e2                	ld	ra,56(sp)
    800048a8:	7442                	ld	s0,48(sp)
    800048aa:	74a2                	ld	s1,40(sp)
    800048ac:	7902                	ld	s2,32(sp)
    800048ae:	69e2                	ld	s3,24(sp)
    800048b0:	6a42                	ld	s4,16(sp)
    800048b2:	6aa2                	ld	s5,8(sp)
    800048b4:	6121                	addi	sp,sp,64
    800048b6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048b8:	85d6                	mv	a1,s5
    800048ba:	8552                	mv	a0,s4
    800048bc:	00000097          	auipc	ra,0x0
    800048c0:	34c080e7          	jalr	844(ra) # 80004c08 <pipeclose>
    800048c4:	b7cd                	j	800048a6 <fileclose+0xa8>

00000000800048c6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048c6:	715d                	addi	sp,sp,-80
    800048c8:	e486                	sd	ra,72(sp)
    800048ca:	e0a2                	sd	s0,64(sp)
    800048cc:	fc26                	sd	s1,56(sp)
    800048ce:	f84a                	sd	s2,48(sp)
    800048d0:	f44e                	sd	s3,40(sp)
    800048d2:	0880                	addi	s0,sp,80
    800048d4:	84aa                	mv	s1,a0
    800048d6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048d8:	ffffd097          	auipc	ra,0xffffd
    800048dc:	3b6080e7          	jalr	950(ra) # 80001c8e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048e0:	409c                	lw	a5,0(s1)
    800048e2:	37f9                	addiw	a5,a5,-2
    800048e4:	4705                	li	a4,1
    800048e6:	04f76763          	bltu	a4,a5,80004934 <filestat+0x6e>
    800048ea:	892a                	mv	s2,a0
    ilock(f->ip);
    800048ec:	6c88                	ld	a0,24(s1)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	072080e7          	jalr	114(ra) # 80003960 <ilock>
    stati(f->ip, &st);
    800048f6:	fb840593          	addi	a1,s0,-72
    800048fa:	6c88                	ld	a0,24(s1)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	2ee080e7          	jalr	750(ra) # 80003bea <stati>
    iunlock(f->ip);
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	11c080e7          	jalr	284(ra) # 80003a22 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000490e:	46e1                	li	a3,24
    80004910:	fb840613          	addi	a2,s0,-72
    80004914:	85ce                	mv	a1,s3
    80004916:	06893503          	ld	a0,104(s2)
    8000491a:	ffffd097          	auipc	ra,0xffffd
    8000491e:	d58080e7          	jalr	-680(ra) # 80001672 <copyout>
    80004922:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004926:	60a6                	ld	ra,72(sp)
    80004928:	6406                	ld	s0,64(sp)
    8000492a:	74e2                	ld	s1,56(sp)
    8000492c:	7942                	ld	s2,48(sp)
    8000492e:	79a2                	ld	s3,40(sp)
    80004930:	6161                	addi	sp,sp,80
    80004932:	8082                	ret
  return -1;
    80004934:	557d                	li	a0,-1
    80004936:	bfc5                	j	80004926 <filestat+0x60>

0000000080004938 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004938:	7179                	addi	sp,sp,-48
    8000493a:	f406                	sd	ra,40(sp)
    8000493c:	f022                	sd	s0,32(sp)
    8000493e:	ec26                	sd	s1,24(sp)
    80004940:	e84a                	sd	s2,16(sp)
    80004942:	e44e                	sd	s3,8(sp)
    80004944:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004946:	00854783          	lbu	a5,8(a0)
    8000494a:	c3d5                	beqz	a5,800049ee <fileread+0xb6>
    8000494c:	84aa                	mv	s1,a0
    8000494e:	89ae                	mv	s3,a1
    80004950:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004952:	411c                	lw	a5,0(a0)
    80004954:	4705                	li	a4,1
    80004956:	04e78963          	beq	a5,a4,800049a8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000495a:	470d                	li	a4,3
    8000495c:	04e78d63          	beq	a5,a4,800049b6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004960:	4709                	li	a4,2
    80004962:	06e79e63          	bne	a5,a4,800049de <fileread+0xa6>
    ilock(f->ip);
    80004966:	6d08                	ld	a0,24(a0)
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	ff8080e7          	jalr	-8(ra) # 80003960 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004970:	874a                	mv	a4,s2
    80004972:	5094                	lw	a3,32(s1)
    80004974:	864e                	mv	a2,s3
    80004976:	4585                	li	a1,1
    80004978:	6c88                	ld	a0,24(s1)
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	29a080e7          	jalr	666(ra) # 80003c14 <readi>
    80004982:	892a                	mv	s2,a0
    80004984:	00a05563          	blez	a0,8000498e <fileread+0x56>
      f->off += r;
    80004988:	509c                	lw	a5,32(s1)
    8000498a:	9fa9                	addw	a5,a5,a0
    8000498c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000498e:	6c88                	ld	a0,24(s1)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	092080e7          	jalr	146(ra) # 80003a22 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004998:	854a                	mv	a0,s2
    8000499a:	70a2                	ld	ra,40(sp)
    8000499c:	7402                	ld	s0,32(sp)
    8000499e:	64e2                	ld	s1,24(sp)
    800049a0:	6942                	ld	s2,16(sp)
    800049a2:	69a2                	ld	s3,8(sp)
    800049a4:	6145                	addi	sp,sp,48
    800049a6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049a8:	6908                	ld	a0,16(a0)
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	3c8080e7          	jalr	968(ra) # 80004d72 <piperead>
    800049b2:	892a                	mv	s2,a0
    800049b4:	b7d5                	j	80004998 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049b6:	02451783          	lh	a5,36(a0)
    800049ba:	03079693          	slli	a3,a5,0x30
    800049be:	92c1                	srli	a3,a3,0x30
    800049c0:	4725                	li	a4,9
    800049c2:	02d76863          	bltu	a4,a3,800049f2 <fileread+0xba>
    800049c6:	0792                	slli	a5,a5,0x4
    800049c8:	0001d717          	auipc	a4,0x1d
    800049cc:	f7070713          	addi	a4,a4,-144 # 80021938 <devsw>
    800049d0:	97ba                	add	a5,a5,a4
    800049d2:	639c                	ld	a5,0(a5)
    800049d4:	c38d                	beqz	a5,800049f6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049d6:	4505                	li	a0,1
    800049d8:	9782                	jalr	a5
    800049da:	892a                	mv	s2,a0
    800049dc:	bf75                	j	80004998 <fileread+0x60>
    panic("fileread");
    800049de:	00004517          	auipc	a0,0x4
    800049e2:	d7a50513          	addi	a0,a0,-646 # 80008758 <syscalls+0x270>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	b58080e7          	jalr	-1192(ra) # 8000053e <panic>
    return -1;
    800049ee:	597d                	li	s2,-1
    800049f0:	b765                	j	80004998 <fileread+0x60>
      return -1;
    800049f2:	597d                	li	s2,-1
    800049f4:	b755                	j	80004998 <fileread+0x60>
    800049f6:	597d                	li	s2,-1
    800049f8:	b745                	j	80004998 <fileread+0x60>

00000000800049fa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049fa:	715d                	addi	sp,sp,-80
    800049fc:	e486                	sd	ra,72(sp)
    800049fe:	e0a2                	sd	s0,64(sp)
    80004a00:	fc26                	sd	s1,56(sp)
    80004a02:	f84a                	sd	s2,48(sp)
    80004a04:	f44e                	sd	s3,40(sp)
    80004a06:	f052                	sd	s4,32(sp)
    80004a08:	ec56                	sd	s5,24(sp)
    80004a0a:	e85a                	sd	s6,16(sp)
    80004a0c:	e45e                	sd	s7,8(sp)
    80004a0e:	e062                	sd	s8,0(sp)
    80004a10:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a12:	00954783          	lbu	a5,9(a0)
    80004a16:	10078663          	beqz	a5,80004b22 <filewrite+0x128>
    80004a1a:	892a                	mv	s2,a0
    80004a1c:	8aae                	mv	s5,a1
    80004a1e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a20:	411c                	lw	a5,0(a0)
    80004a22:	4705                	li	a4,1
    80004a24:	02e78263          	beq	a5,a4,80004a48 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a28:	470d                	li	a4,3
    80004a2a:	02e78663          	beq	a5,a4,80004a56 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a2e:	4709                	li	a4,2
    80004a30:	0ee79163          	bne	a5,a4,80004b12 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a34:	0ac05d63          	blez	a2,80004aee <filewrite+0xf4>
    int i = 0;
    80004a38:	4981                	li	s3,0
    80004a3a:	6b05                	lui	s6,0x1
    80004a3c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a40:	6b85                	lui	s7,0x1
    80004a42:	c00b8b9b          	addiw	s7,s7,-1024
    80004a46:	a861                	j	80004ade <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a48:	6908                	ld	a0,16(a0)
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	22e080e7          	jalr	558(ra) # 80004c78 <pipewrite>
    80004a52:	8a2a                	mv	s4,a0
    80004a54:	a045                	j	80004af4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a56:	02451783          	lh	a5,36(a0)
    80004a5a:	03079693          	slli	a3,a5,0x30
    80004a5e:	92c1                	srli	a3,a3,0x30
    80004a60:	4725                	li	a4,9
    80004a62:	0cd76263          	bltu	a4,a3,80004b26 <filewrite+0x12c>
    80004a66:	0792                	slli	a5,a5,0x4
    80004a68:	0001d717          	auipc	a4,0x1d
    80004a6c:	ed070713          	addi	a4,a4,-304 # 80021938 <devsw>
    80004a70:	97ba                	add	a5,a5,a4
    80004a72:	679c                	ld	a5,8(a5)
    80004a74:	cbdd                	beqz	a5,80004b2a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a76:	4505                	li	a0,1
    80004a78:	9782                	jalr	a5
    80004a7a:	8a2a                	mv	s4,a0
    80004a7c:	a8a5                	j	80004af4 <filewrite+0xfa>
    80004a7e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a82:	00000097          	auipc	ra,0x0
    80004a86:	8b0080e7          	jalr	-1872(ra) # 80004332 <begin_op>
      ilock(f->ip);
    80004a8a:	01893503          	ld	a0,24(s2)
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	ed2080e7          	jalr	-302(ra) # 80003960 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a96:	8762                	mv	a4,s8
    80004a98:	02092683          	lw	a3,32(s2)
    80004a9c:	01598633          	add	a2,s3,s5
    80004aa0:	4585                	li	a1,1
    80004aa2:	01893503          	ld	a0,24(s2)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	266080e7          	jalr	614(ra) # 80003d0c <writei>
    80004aae:	84aa                	mv	s1,a0
    80004ab0:	00a05763          	blez	a0,80004abe <filewrite+0xc4>
        f->off += r;
    80004ab4:	02092783          	lw	a5,32(s2)
    80004ab8:	9fa9                	addw	a5,a5,a0
    80004aba:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004abe:	01893503          	ld	a0,24(s2)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	f60080e7          	jalr	-160(ra) # 80003a22 <iunlock>
      end_op();
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	8e8080e7          	jalr	-1816(ra) # 800043b2 <end_op>

      if(r != n1){
    80004ad2:	009c1f63          	bne	s8,s1,80004af0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ad6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ada:	0149db63          	bge	s3,s4,80004af0 <filewrite+0xf6>
      int n1 = n - i;
    80004ade:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ae2:	84be                	mv	s1,a5
    80004ae4:	2781                	sext.w	a5,a5
    80004ae6:	f8fb5ce3          	bge	s6,a5,80004a7e <filewrite+0x84>
    80004aea:	84de                	mv	s1,s7
    80004aec:	bf49                	j	80004a7e <filewrite+0x84>
    int i = 0;
    80004aee:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004af0:	013a1f63          	bne	s4,s3,80004b0e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004af4:	8552                	mv	a0,s4
    80004af6:	60a6                	ld	ra,72(sp)
    80004af8:	6406                	ld	s0,64(sp)
    80004afa:	74e2                	ld	s1,56(sp)
    80004afc:	7942                	ld	s2,48(sp)
    80004afe:	79a2                	ld	s3,40(sp)
    80004b00:	7a02                	ld	s4,32(sp)
    80004b02:	6ae2                	ld	s5,24(sp)
    80004b04:	6b42                	ld	s6,16(sp)
    80004b06:	6ba2                	ld	s7,8(sp)
    80004b08:	6c02                	ld	s8,0(sp)
    80004b0a:	6161                	addi	sp,sp,80
    80004b0c:	8082                	ret
    ret = (i == n ? n : -1);
    80004b0e:	5a7d                	li	s4,-1
    80004b10:	b7d5                	j	80004af4 <filewrite+0xfa>
    panic("filewrite");
    80004b12:	00004517          	auipc	a0,0x4
    80004b16:	c5650513          	addi	a0,a0,-938 # 80008768 <syscalls+0x280>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	a24080e7          	jalr	-1500(ra) # 8000053e <panic>
    return -1;
    80004b22:	5a7d                	li	s4,-1
    80004b24:	bfc1                	j	80004af4 <filewrite+0xfa>
      return -1;
    80004b26:	5a7d                	li	s4,-1
    80004b28:	b7f1                	j	80004af4 <filewrite+0xfa>
    80004b2a:	5a7d                	li	s4,-1
    80004b2c:	b7e1                	j	80004af4 <filewrite+0xfa>

0000000080004b2e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b2e:	7179                	addi	sp,sp,-48
    80004b30:	f406                	sd	ra,40(sp)
    80004b32:	f022                	sd	s0,32(sp)
    80004b34:	ec26                	sd	s1,24(sp)
    80004b36:	e84a                	sd	s2,16(sp)
    80004b38:	e44e                	sd	s3,8(sp)
    80004b3a:	e052                	sd	s4,0(sp)
    80004b3c:	1800                	addi	s0,sp,48
    80004b3e:	84aa                	mv	s1,a0
    80004b40:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b42:	0005b023          	sd	zero,0(a1)
    80004b46:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b4a:	00000097          	auipc	ra,0x0
    80004b4e:	bf8080e7          	jalr	-1032(ra) # 80004742 <filealloc>
    80004b52:	e088                	sd	a0,0(s1)
    80004b54:	c551                	beqz	a0,80004be0 <pipealloc+0xb2>
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	bec080e7          	jalr	-1044(ra) # 80004742 <filealloc>
    80004b5e:	00aa3023          	sd	a0,0(s4)
    80004b62:	c92d                	beqz	a0,80004bd4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	f90080e7          	jalr	-112(ra) # 80000af4 <kalloc>
    80004b6c:	892a                	mv	s2,a0
    80004b6e:	c125                	beqz	a0,80004bce <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b70:	4985                	li	s3,1
    80004b72:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b76:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b7a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b7e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b82:	00004597          	auipc	a1,0x4
    80004b86:	bf658593          	addi	a1,a1,-1034 # 80008778 <syscalls+0x290>
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	fca080e7          	jalr	-54(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b92:	609c                	ld	a5,0(s1)
    80004b94:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b98:	609c                	ld	a5,0(s1)
    80004b9a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b9e:	609c                	ld	a5,0(s1)
    80004ba0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ba4:	609c                	ld	a5,0(s1)
    80004ba6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004baa:	000a3783          	ld	a5,0(s4)
    80004bae:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bb2:	000a3783          	ld	a5,0(s4)
    80004bb6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bba:	000a3783          	ld	a5,0(s4)
    80004bbe:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bc2:	000a3783          	ld	a5,0(s4)
    80004bc6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bca:	4501                	li	a0,0
    80004bcc:	a025                	j	80004bf4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bce:	6088                	ld	a0,0(s1)
    80004bd0:	e501                	bnez	a0,80004bd8 <pipealloc+0xaa>
    80004bd2:	a039                	j	80004be0 <pipealloc+0xb2>
    80004bd4:	6088                	ld	a0,0(s1)
    80004bd6:	c51d                	beqz	a0,80004c04 <pipealloc+0xd6>
    fileclose(*f0);
    80004bd8:	00000097          	auipc	ra,0x0
    80004bdc:	c26080e7          	jalr	-986(ra) # 800047fe <fileclose>
  if(*f1)
    80004be0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004be4:	557d                	li	a0,-1
  if(*f1)
    80004be6:	c799                	beqz	a5,80004bf4 <pipealloc+0xc6>
    fileclose(*f1);
    80004be8:	853e                	mv	a0,a5
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	c14080e7          	jalr	-1004(ra) # 800047fe <fileclose>
  return -1;
    80004bf2:	557d                	li	a0,-1
}
    80004bf4:	70a2                	ld	ra,40(sp)
    80004bf6:	7402                	ld	s0,32(sp)
    80004bf8:	64e2                	ld	s1,24(sp)
    80004bfa:	6942                	ld	s2,16(sp)
    80004bfc:	69a2                	ld	s3,8(sp)
    80004bfe:	6a02                	ld	s4,0(sp)
    80004c00:	6145                	addi	sp,sp,48
    80004c02:	8082                	ret
  return -1;
    80004c04:	557d                	li	a0,-1
    80004c06:	b7fd                	j	80004bf4 <pipealloc+0xc6>

0000000080004c08 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c08:	1101                	addi	sp,sp,-32
    80004c0a:	ec06                	sd	ra,24(sp)
    80004c0c:	e822                	sd	s0,16(sp)
    80004c0e:	e426                	sd	s1,8(sp)
    80004c10:	e04a                	sd	s2,0(sp)
    80004c12:	1000                	addi	s0,sp,32
    80004c14:	84aa                	mv	s1,a0
    80004c16:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	fcc080e7          	jalr	-52(ra) # 80000be4 <acquire>
  if(writable){
    80004c20:	02090d63          	beqz	s2,80004c5a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c24:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c28:	21848513          	addi	a0,s1,536
    80004c2c:	ffffe097          	auipc	ra,0xffffe
    80004c30:	89e080e7          	jalr	-1890(ra) # 800024ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c34:	2204b783          	ld	a5,544(s1)
    80004c38:	eb95                	bnez	a5,80004c6c <pipeclose+0x64>
    release(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	05c080e7          	jalr	92(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	db2080e7          	jalr	-590(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c4e:	60e2                	ld	ra,24(sp)
    80004c50:	6442                	ld	s0,16(sp)
    80004c52:	64a2                	ld	s1,8(sp)
    80004c54:	6902                	ld	s2,0(sp)
    80004c56:	6105                	addi	sp,sp,32
    80004c58:	8082                	ret
    pi->readopen = 0;
    80004c5a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c5e:	21c48513          	addi	a0,s1,540
    80004c62:	ffffe097          	auipc	ra,0xffffe
    80004c66:	868080e7          	jalr	-1944(ra) # 800024ca <wakeup>
    80004c6a:	b7e9                	j	80004c34 <pipeclose+0x2c>
    release(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
}
    80004c76:	bfe1                	j	80004c4e <pipeclose+0x46>

0000000080004c78 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c78:	7159                	addi	sp,sp,-112
    80004c7a:	f486                	sd	ra,104(sp)
    80004c7c:	f0a2                	sd	s0,96(sp)
    80004c7e:	eca6                	sd	s1,88(sp)
    80004c80:	e8ca                	sd	s2,80(sp)
    80004c82:	e4ce                	sd	s3,72(sp)
    80004c84:	e0d2                	sd	s4,64(sp)
    80004c86:	fc56                	sd	s5,56(sp)
    80004c88:	f85a                	sd	s6,48(sp)
    80004c8a:	f45e                	sd	s7,40(sp)
    80004c8c:	f062                	sd	s8,32(sp)
    80004c8e:	ec66                	sd	s9,24(sp)
    80004c90:	1880                	addi	s0,sp,112
    80004c92:	84aa                	mv	s1,a0
    80004c94:	8aae                	mv	s5,a1
    80004c96:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	ff6080e7          	jalr	-10(ra) # 80001c8e <myproc>
    80004ca0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
  while(i < n){
    80004cac:	0d405163          	blez	s4,80004d6e <pipewrite+0xf6>
    80004cb0:	8ba6                	mv	s7,s1
  int i = 0;
    80004cb2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cb6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cba:	21c48c13          	addi	s8,s1,540
    80004cbe:	a08d                	j	80004d20 <pipewrite+0xa8>
      release(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
      return -1;
    80004cca:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ccc:	854a                	mv	a0,s2
    80004cce:	70a6                	ld	ra,104(sp)
    80004cd0:	7406                	ld	s0,96(sp)
    80004cd2:	64e6                	ld	s1,88(sp)
    80004cd4:	6946                	ld	s2,80(sp)
    80004cd6:	69a6                	ld	s3,72(sp)
    80004cd8:	6a06                	ld	s4,64(sp)
    80004cda:	7ae2                	ld	s5,56(sp)
    80004cdc:	7b42                	ld	s6,48(sp)
    80004cde:	7ba2                	ld	s7,40(sp)
    80004ce0:	7c02                	ld	s8,32(sp)
    80004ce2:	6ce2                	ld	s9,24(sp)
    80004ce4:	6165                	addi	sp,sp,112
    80004ce6:	8082                	ret
      wakeup(&pi->nread);
    80004ce8:	8566                	mv	a0,s9
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	7e0080e7          	jalr	2016(ra) # 800024ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cf2:	85de                	mv	a1,s7
    80004cf4:	8562                	mv	a0,s8
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	62e080e7          	jalr	1582(ra) # 80002324 <sleep>
    80004cfe:	a839                	j	80004d1c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d00:	21c4a783          	lw	a5,540(s1)
    80004d04:	0017871b          	addiw	a4,a5,1
    80004d08:	20e4ae23          	sw	a4,540(s1)
    80004d0c:	1ff7f793          	andi	a5,a5,511
    80004d10:	97a6                	add	a5,a5,s1
    80004d12:	f9f44703          	lbu	a4,-97(s0)
    80004d16:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d1a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d1c:	03495d63          	bge	s2,s4,80004d56 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d20:	2204a783          	lw	a5,544(s1)
    80004d24:	dfd1                	beqz	a5,80004cc0 <pipewrite+0x48>
    80004d26:	0289a783          	lw	a5,40(s3)
    80004d2a:	fbd9                	bnez	a5,80004cc0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d2c:	2184a783          	lw	a5,536(s1)
    80004d30:	21c4a703          	lw	a4,540(s1)
    80004d34:	2007879b          	addiw	a5,a5,512
    80004d38:	faf708e3          	beq	a4,a5,80004ce8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3c:	4685                	li	a3,1
    80004d3e:	01590633          	add	a2,s2,s5
    80004d42:	f9f40593          	addi	a1,s0,-97
    80004d46:	0689b503          	ld	a0,104(s3)
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	9b4080e7          	jalr	-1612(ra) # 800016fe <copyin>
    80004d52:	fb6517e3          	bne	a0,s6,80004d00 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d56:	21848513          	addi	a0,s1,536
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	770080e7          	jalr	1904(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f34080e7          	jalr	-204(ra) # 80000c98 <release>
  return i;
    80004d6c:	b785                	j	80004ccc <pipewrite+0x54>
  int i = 0;
    80004d6e:	4901                	li	s2,0
    80004d70:	b7dd                	j	80004d56 <pipewrite+0xde>

0000000080004d72 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d72:	715d                	addi	sp,sp,-80
    80004d74:	e486                	sd	ra,72(sp)
    80004d76:	e0a2                	sd	s0,64(sp)
    80004d78:	fc26                	sd	s1,56(sp)
    80004d7a:	f84a                	sd	s2,48(sp)
    80004d7c:	f44e                	sd	s3,40(sp)
    80004d7e:	f052                	sd	s4,32(sp)
    80004d80:	ec56                	sd	s5,24(sp)
    80004d82:	e85a                	sd	s6,16(sp)
    80004d84:	0880                	addi	s0,sp,80
    80004d86:	84aa                	mv	s1,a0
    80004d88:	892e                	mv	s2,a1
    80004d8a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	f02080e7          	jalr	-254(ra) # 80001c8e <myproc>
    80004d94:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d96:	8b26                	mv	s6,s1
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	e4a080e7          	jalr	-438(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	2184a703          	lw	a4,536(s1)
    80004da6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004daa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dae:	02f71463          	bne	a4,a5,80004dd6 <piperead+0x64>
    80004db2:	2244a783          	lw	a5,548(s1)
    80004db6:	c385                	beqz	a5,80004dd6 <piperead+0x64>
    if(pr->killed){
    80004db8:	028a2783          	lw	a5,40(s4)
    80004dbc:	ebc1                	bnez	a5,80004e4c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dbe:	85da                	mv	a1,s6
    80004dc0:	854e                	mv	a0,s3
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	562080e7          	jalr	1378(ra) # 80002324 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dca:	2184a703          	lw	a4,536(s1)
    80004dce:	21c4a783          	lw	a5,540(s1)
    80004dd2:	fef700e3          	beq	a4,a5,80004db2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd6:	09505263          	blez	s5,80004e5a <piperead+0xe8>
    80004dda:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ddc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dde:	2184a783          	lw	a5,536(s1)
    80004de2:	21c4a703          	lw	a4,540(s1)
    80004de6:	02f70d63          	beq	a4,a5,80004e20 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dea:	0017871b          	addiw	a4,a5,1
    80004dee:	20e4ac23          	sw	a4,536(s1)
    80004df2:	1ff7f793          	andi	a5,a5,511
    80004df6:	97a6                	add	a5,a5,s1
    80004df8:	0187c783          	lbu	a5,24(a5)
    80004dfc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e00:	4685                	li	a3,1
    80004e02:	fbf40613          	addi	a2,s0,-65
    80004e06:	85ca                	mv	a1,s2
    80004e08:	068a3503          	ld	a0,104(s4)
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	866080e7          	jalr	-1946(ra) # 80001672 <copyout>
    80004e14:	01650663          	beq	a0,s6,80004e20 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e18:	2985                	addiw	s3,s3,1
    80004e1a:	0905                	addi	s2,s2,1
    80004e1c:	fd3a91e3          	bne	s5,s3,80004dde <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e20:	21c48513          	addi	a0,s1,540
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	6a6080e7          	jalr	1702(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	e6a080e7          	jalr	-406(ra) # 80000c98 <release>
  return i;
}
    80004e36:	854e                	mv	a0,s3
    80004e38:	60a6                	ld	ra,72(sp)
    80004e3a:	6406                	ld	s0,64(sp)
    80004e3c:	74e2                	ld	s1,56(sp)
    80004e3e:	7942                	ld	s2,48(sp)
    80004e40:	79a2                	ld	s3,40(sp)
    80004e42:	7a02                	ld	s4,32(sp)
    80004e44:	6ae2                	ld	s5,24(sp)
    80004e46:	6b42                	ld	s6,16(sp)
    80004e48:	6161                	addi	sp,sp,80
    80004e4a:	8082                	ret
      release(&pi->lock);
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	e4a080e7          	jalr	-438(ra) # 80000c98 <release>
      return -1;
    80004e56:	59fd                	li	s3,-1
    80004e58:	bff9                	j	80004e36 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5a:	4981                	li	s3,0
    80004e5c:	b7d1                	j	80004e20 <piperead+0xae>

0000000080004e5e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e5e:	df010113          	addi	sp,sp,-528
    80004e62:	20113423          	sd	ra,520(sp)
    80004e66:	20813023          	sd	s0,512(sp)
    80004e6a:	ffa6                	sd	s1,504(sp)
    80004e6c:	fbca                	sd	s2,496(sp)
    80004e6e:	f7ce                	sd	s3,488(sp)
    80004e70:	f3d2                	sd	s4,480(sp)
    80004e72:	efd6                	sd	s5,472(sp)
    80004e74:	ebda                	sd	s6,464(sp)
    80004e76:	e7de                	sd	s7,456(sp)
    80004e78:	e3e2                	sd	s8,448(sp)
    80004e7a:	ff66                	sd	s9,440(sp)
    80004e7c:	fb6a                	sd	s10,432(sp)
    80004e7e:	f76e                	sd	s11,424(sp)
    80004e80:	0c00                	addi	s0,sp,528
    80004e82:	84aa                	mv	s1,a0
    80004e84:	dea43c23          	sd	a0,-520(s0)
    80004e88:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	e02080e7          	jalr	-510(ra) # 80001c8e <myproc>
    80004e94:	892a                	mv	s2,a0

  begin_op();
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	49c080e7          	jalr	1180(ra) # 80004332 <begin_op>

  if((ip = namei(path)) == 0){
    80004e9e:	8526                	mv	a0,s1
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	276080e7          	jalr	630(ra) # 80004116 <namei>
    80004ea8:	c92d                	beqz	a0,80004f1a <exec+0xbc>
    80004eaa:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	ab4080e7          	jalr	-1356(ra) # 80003960 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eb4:	04000713          	li	a4,64
    80004eb8:	4681                	li	a3,0
    80004eba:	e5040613          	addi	a2,s0,-432
    80004ebe:	4581                	li	a1,0
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	d52080e7          	jalr	-686(ra) # 80003c14 <readi>
    80004eca:	04000793          	li	a5,64
    80004ece:	00f51a63          	bne	a0,a5,80004ee2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ed2:	e5042703          	lw	a4,-432(s0)
    80004ed6:	464c47b7          	lui	a5,0x464c4
    80004eda:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ede:	04f70463          	beq	a4,a5,80004f26 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	cde080e7          	jalr	-802(ra) # 80003bc2 <iunlockput>
    end_op();
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	4c6080e7          	jalr	1222(ra) # 800043b2 <end_op>
  }
  return -1;
    80004ef4:	557d                	li	a0,-1
}
    80004ef6:	20813083          	ld	ra,520(sp)
    80004efa:	20013403          	ld	s0,512(sp)
    80004efe:	74fe                	ld	s1,504(sp)
    80004f00:	795e                	ld	s2,496(sp)
    80004f02:	79be                	ld	s3,488(sp)
    80004f04:	7a1e                	ld	s4,480(sp)
    80004f06:	6afe                	ld	s5,472(sp)
    80004f08:	6b5e                	ld	s6,464(sp)
    80004f0a:	6bbe                	ld	s7,456(sp)
    80004f0c:	6c1e                	ld	s8,448(sp)
    80004f0e:	7cfa                	ld	s9,440(sp)
    80004f10:	7d5a                	ld	s10,432(sp)
    80004f12:	7dba                	ld	s11,424(sp)
    80004f14:	21010113          	addi	sp,sp,528
    80004f18:	8082                	ret
    end_op();
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	498080e7          	jalr	1176(ra) # 800043b2 <end_op>
    return -1;
    80004f22:	557d                	li	a0,-1
    80004f24:	bfc9                	j	80004ef6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f26:	854a                	mv	a0,s2
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	e2a080e7          	jalr	-470(ra) # 80001d52 <proc_pagetable>
    80004f30:	8baa                	mv	s7,a0
    80004f32:	d945                	beqz	a0,80004ee2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f34:	e7042983          	lw	s3,-400(s0)
    80004f38:	e8845783          	lhu	a5,-376(s0)
    80004f3c:	c7ad                	beqz	a5,80004fa6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f3e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f40:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f42:	6c85                	lui	s9,0x1
    80004f44:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f48:	def43823          	sd	a5,-528(s0)
    80004f4c:	a42d                	j	80005176 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f4e:	00004517          	auipc	a0,0x4
    80004f52:	83250513          	addi	a0,a0,-1998 # 80008780 <syscalls+0x298>
    80004f56:	ffffb097          	auipc	ra,0xffffb
    80004f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f5e:	8756                	mv	a4,s5
    80004f60:	012d86bb          	addw	a3,s11,s2
    80004f64:	4581                	li	a1,0
    80004f66:	8526                	mv	a0,s1
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	cac080e7          	jalr	-852(ra) # 80003c14 <readi>
    80004f70:	2501                	sext.w	a0,a0
    80004f72:	1aaa9963          	bne	s5,a0,80005124 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f76:	6785                	lui	a5,0x1
    80004f78:	0127893b          	addw	s2,a5,s2
    80004f7c:	77fd                	lui	a5,0xfffff
    80004f7e:	01478a3b          	addw	s4,a5,s4
    80004f82:	1f897163          	bgeu	s2,s8,80005164 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f86:	02091593          	slli	a1,s2,0x20
    80004f8a:	9181                	srli	a1,a1,0x20
    80004f8c:	95ea                	add	a1,a1,s10
    80004f8e:	855e                	mv	a0,s7
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	0de080e7          	jalr	222(ra) # 8000106e <walkaddr>
    80004f98:	862a                	mv	a2,a0
    if(pa == 0)
    80004f9a:	d955                	beqz	a0,80004f4e <exec+0xf0>
      n = PGSIZE;
    80004f9c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f9e:	fd9a70e3          	bgeu	s4,s9,80004f5e <exec+0x100>
      n = sz - i;
    80004fa2:	8ad2                	mv	s5,s4
    80004fa4:	bf6d                	j	80004f5e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fa6:	4901                	li	s2,0
  iunlockput(ip);
    80004fa8:	8526                	mv	a0,s1
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	c18080e7          	jalr	-1000(ra) # 80003bc2 <iunlockput>
  end_op();
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	400080e7          	jalr	1024(ra) # 800043b2 <end_op>
  p = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	cd4080e7          	jalr	-812(ra) # 80001c8e <myproc>
    80004fc2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fc4:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004fc8:	6785                	lui	a5,0x1
    80004fca:	17fd                	addi	a5,a5,-1
    80004fcc:	993e                	add	s2,s2,a5
    80004fce:	757d                	lui	a0,0xfffff
    80004fd0:	00a977b3          	and	a5,s2,a0
    80004fd4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fd8:	6609                	lui	a2,0x2
    80004fda:	963e                	add	a2,a2,a5
    80004fdc:	85be                	mv	a1,a5
    80004fde:	855e                	mv	a0,s7
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	442080e7          	jalr	1090(ra) # 80001422 <uvmalloc>
    80004fe8:	8b2a                	mv	s6,a0
  ip = 0;
    80004fea:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fec:	12050c63          	beqz	a0,80005124 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ff0:	75f9                	lui	a1,0xffffe
    80004ff2:	95aa                	add	a1,a1,a0
    80004ff4:	855e                	mv	a0,s7
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	64a080e7          	jalr	1610(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ffe:	7c7d                	lui	s8,0xfffff
    80005000:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005002:	e0043783          	ld	a5,-512(s0)
    80005006:	6388                	ld	a0,0(a5)
    80005008:	c535                	beqz	a0,80005074 <exec+0x216>
    8000500a:	e9040993          	addi	s3,s0,-368
    8000500e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005012:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	e50080e7          	jalr	-432(ra) # 80000e64 <strlen>
    8000501c:	2505                	addiw	a0,a0,1
    8000501e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005022:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005026:	13896363          	bltu	s2,s8,8000514c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000502a:	e0043d83          	ld	s11,-512(s0)
    8000502e:	000dba03          	ld	s4,0(s11)
    80005032:	8552                	mv	a0,s4
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	e30080e7          	jalr	-464(ra) # 80000e64 <strlen>
    8000503c:	0015069b          	addiw	a3,a0,1
    80005040:	8652                	mv	a2,s4
    80005042:	85ca                	mv	a1,s2
    80005044:	855e                	mv	a0,s7
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	62c080e7          	jalr	1580(ra) # 80001672 <copyout>
    8000504e:	10054363          	bltz	a0,80005154 <exec+0x2f6>
    ustack[argc] = sp;
    80005052:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005056:	0485                	addi	s1,s1,1
    80005058:	008d8793          	addi	a5,s11,8
    8000505c:	e0f43023          	sd	a5,-512(s0)
    80005060:	008db503          	ld	a0,8(s11)
    80005064:	c911                	beqz	a0,80005078 <exec+0x21a>
    if(argc >= MAXARG)
    80005066:	09a1                	addi	s3,s3,8
    80005068:	fb3c96e3          	bne	s9,s3,80005014 <exec+0x1b6>
  sz = sz1;
    8000506c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005070:	4481                	li	s1,0
    80005072:	a84d                	j	80005124 <exec+0x2c6>
  sp = sz;
    80005074:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005076:	4481                	li	s1,0
  ustack[argc] = 0;
    80005078:	00349793          	slli	a5,s1,0x3
    8000507c:	f9040713          	addi	a4,s0,-112
    80005080:	97ba                	add	a5,a5,a4
    80005082:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005086:	00148693          	addi	a3,s1,1
    8000508a:	068e                	slli	a3,a3,0x3
    8000508c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005090:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005094:	01897663          	bgeu	s2,s8,800050a0 <exec+0x242>
  sz = sz1;
    80005098:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000509c:	4481                	li	s1,0
    8000509e:	a059                	j	80005124 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050a0:	e9040613          	addi	a2,s0,-368
    800050a4:	85ca                	mv	a1,s2
    800050a6:	855e                	mv	a0,s7
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	5ca080e7          	jalr	1482(ra) # 80001672 <copyout>
    800050b0:	0a054663          	bltz	a0,8000515c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050b4:	070ab783          	ld	a5,112(s5)
    800050b8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050bc:	df843783          	ld	a5,-520(s0)
    800050c0:	0007c703          	lbu	a4,0(a5)
    800050c4:	cf11                	beqz	a4,800050e0 <exec+0x282>
    800050c6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c8:	02f00693          	li	a3,47
    800050cc:	a039                	j	800050da <exec+0x27c>
      last = s+1;
    800050ce:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050d2:	0785                	addi	a5,a5,1
    800050d4:	fff7c703          	lbu	a4,-1(a5)
    800050d8:	c701                	beqz	a4,800050e0 <exec+0x282>
    if(*s == '/')
    800050da:	fed71ce3          	bne	a4,a3,800050d2 <exec+0x274>
    800050de:	bfc5                	j	800050ce <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050e0:	4641                	li	a2,16
    800050e2:	df843583          	ld	a1,-520(s0)
    800050e6:	170a8513          	addi	a0,s5,368
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	d48080e7          	jalr	-696(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050f2:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    800050f6:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    800050fa:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050fe:	070ab783          	ld	a5,112(s5)
    80005102:	e6843703          	ld	a4,-408(s0)
    80005106:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005108:	070ab783          	ld	a5,112(s5)
    8000510c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005110:	85ea                	mv	a1,s10
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	cdc080e7          	jalr	-804(ra) # 80001dee <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000511a:	0004851b          	sext.w	a0,s1
    8000511e:	bbe1                	j	80004ef6 <exec+0x98>
    80005120:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005124:	e0843583          	ld	a1,-504(s0)
    80005128:	855e                	mv	a0,s7
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	cc4080e7          	jalr	-828(ra) # 80001dee <proc_freepagetable>
  if(ip){
    80005132:	da0498e3          	bnez	s1,80004ee2 <exec+0x84>
  return -1;
    80005136:	557d                	li	a0,-1
    80005138:	bb7d                	j	80004ef6 <exec+0x98>
    8000513a:	e1243423          	sd	s2,-504(s0)
    8000513e:	b7dd                	j	80005124 <exec+0x2c6>
    80005140:	e1243423          	sd	s2,-504(s0)
    80005144:	b7c5                	j	80005124 <exec+0x2c6>
    80005146:	e1243423          	sd	s2,-504(s0)
    8000514a:	bfe9                	j	80005124 <exec+0x2c6>
  sz = sz1;
    8000514c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005150:	4481                	li	s1,0
    80005152:	bfc9                	j	80005124 <exec+0x2c6>
  sz = sz1;
    80005154:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005158:	4481                	li	s1,0
    8000515a:	b7e9                	j	80005124 <exec+0x2c6>
  sz = sz1;
    8000515c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005160:	4481                	li	s1,0
    80005162:	b7c9                	j	80005124 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005164:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005168:	2b05                	addiw	s6,s6,1
    8000516a:	0389899b          	addiw	s3,s3,56
    8000516e:	e8845783          	lhu	a5,-376(s0)
    80005172:	e2fb5be3          	bge	s6,a5,80004fa8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005176:	2981                	sext.w	s3,s3
    80005178:	03800713          	li	a4,56
    8000517c:	86ce                	mv	a3,s3
    8000517e:	e1840613          	addi	a2,s0,-488
    80005182:	4581                	li	a1,0
    80005184:	8526                	mv	a0,s1
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	a8e080e7          	jalr	-1394(ra) # 80003c14 <readi>
    8000518e:	03800793          	li	a5,56
    80005192:	f8f517e3          	bne	a0,a5,80005120 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005196:	e1842783          	lw	a5,-488(s0)
    8000519a:	4705                	li	a4,1
    8000519c:	fce796e3          	bne	a5,a4,80005168 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051a0:	e4043603          	ld	a2,-448(s0)
    800051a4:	e3843783          	ld	a5,-456(s0)
    800051a8:	f8f669e3          	bltu	a2,a5,8000513a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051ac:	e2843783          	ld	a5,-472(s0)
    800051b0:	963e                	add	a2,a2,a5
    800051b2:	f8f667e3          	bltu	a2,a5,80005140 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b6:	85ca                	mv	a1,s2
    800051b8:	855e                	mv	a0,s7
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	268080e7          	jalr	616(ra) # 80001422 <uvmalloc>
    800051c2:	e0a43423          	sd	a0,-504(s0)
    800051c6:	d141                	beqz	a0,80005146 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051c8:	e2843d03          	ld	s10,-472(s0)
    800051cc:	df043783          	ld	a5,-528(s0)
    800051d0:	00fd77b3          	and	a5,s10,a5
    800051d4:	fba1                	bnez	a5,80005124 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051d6:	e2042d83          	lw	s11,-480(s0)
    800051da:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051de:	f80c03e3          	beqz	s8,80005164 <exec+0x306>
    800051e2:	8a62                	mv	s4,s8
    800051e4:	4901                	li	s2,0
    800051e6:	b345                	j	80004f86 <exec+0x128>

00000000800051e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051e8:	7179                	addi	sp,sp,-48
    800051ea:	f406                	sd	ra,40(sp)
    800051ec:	f022                	sd	s0,32(sp)
    800051ee:	ec26                	sd	s1,24(sp)
    800051f0:	e84a                	sd	s2,16(sp)
    800051f2:	1800                	addi	s0,sp,48
    800051f4:	892e                	mv	s2,a1
    800051f6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051f8:	fdc40593          	addi	a1,s0,-36
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	b90080e7          	jalr	-1136(ra) # 80002d8c <argint>
    80005204:	04054063          	bltz	a0,80005244 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005208:	fdc42703          	lw	a4,-36(s0)
    8000520c:	47bd                	li	a5,15
    8000520e:	02e7ed63          	bltu	a5,a4,80005248 <argfd+0x60>
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	a7c080e7          	jalr	-1412(ra) # 80001c8e <myproc>
    8000521a:	fdc42703          	lw	a4,-36(s0)
    8000521e:	01c70793          	addi	a5,a4,28
    80005222:	078e                	slli	a5,a5,0x3
    80005224:	953e                	add	a0,a0,a5
    80005226:	651c                	ld	a5,8(a0)
    80005228:	c395                	beqz	a5,8000524c <argfd+0x64>
    return -1;
  if(pfd)
    8000522a:	00090463          	beqz	s2,80005232 <argfd+0x4a>
    *pfd = fd;
    8000522e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005232:	4501                	li	a0,0
  if(pf)
    80005234:	c091                	beqz	s1,80005238 <argfd+0x50>
    *pf = f;
    80005236:	e09c                	sd	a5,0(s1)
}
    80005238:	70a2                	ld	ra,40(sp)
    8000523a:	7402                	ld	s0,32(sp)
    8000523c:	64e2                	ld	s1,24(sp)
    8000523e:	6942                	ld	s2,16(sp)
    80005240:	6145                	addi	sp,sp,48
    80005242:	8082                	ret
    return -1;
    80005244:	557d                	li	a0,-1
    80005246:	bfcd                	j	80005238 <argfd+0x50>
    return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	b7fd                	j	80005238 <argfd+0x50>
    8000524c:	557d                	li	a0,-1
    8000524e:	b7ed                	j	80005238 <argfd+0x50>

0000000080005250 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005250:	1101                	addi	sp,sp,-32
    80005252:	ec06                	sd	ra,24(sp)
    80005254:	e822                	sd	s0,16(sp)
    80005256:	e426                	sd	s1,8(sp)
    80005258:	1000                	addi	s0,sp,32
    8000525a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000525c:	ffffd097          	auipc	ra,0xffffd
    80005260:	a32080e7          	jalr	-1486(ra) # 80001c8e <myproc>
    80005264:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005266:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    8000526a:	4501                	li	a0,0
    8000526c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000526e:	6398                	ld	a4,0(a5)
    80005270:	cb19                	beqz	a4,80005286 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005272:	2505                	addiw	a0,a0,1
    80005274:	07a1                	addi	a5,a5,8
    80005276:	fed51ce3          	bne	a0,a3,8000526e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000527a:	557d                	li	a0,-1
}
    8000527c:	60e2                	ld	ra,24(sp)
    8000527e:	6442                	ld	s0,16(sp)
    80005280:	64a2                	ld	s1,8(sp)
    80005282:	6105                	addi	sp,sp,32
    80005284:	8082                	ret
      p->ofile[fd] = f;
    80005286:	01c50793          	addi	a5,a0,28
    8000528a:	078e                	slli	a5,a5,0x3
    8000528c:	963e                	add	a2,a2,a5
    8000528e:	e604                	sd	s1,8(a2)
      return fd;
    80005290:	b7f5                	j	8000527c <fdalloc+0x2c>

0000000080005292 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005292:	715d                	addi	sp,sp,-80
    80005294:	e486                	sd	ra,72(sp)
    80005296:	e0a2                	sd	s0,64(sp)
    80005298:	fc26                	sd	s1,56(sp)
    8000529a:	f84a                	sd	s2,48(sp)
    8000529c:	f44e                	sd	s3,40(sp)
    8000529e:	f052                	sd	s4,32(sp)
    800052a0:	ec56                	sd	s5,24(sp)
    800052a2:	0880                	addi	s0,sp,80
    800052a4:	89ae                	mv	s3,a1
    800052a6:	8ab2                	mv	s5,a2
    800052a8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052aa:	fb040593          	addi	a1,s0,-80
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	e86080e7          	jalr	-378(ra) # 80004134 <nameiparent>
    800052b6:	892a                	mv	s2,a0
    800052b8:	12050f63          	beqz	a0,800053f6 <create+0x164>
    return 0;

  ilock(dp);
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	6a4080e7          	jalr	1700(ra) # 80003960 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052c4:	4601                	li	a2,0
    800052c6:	fb040593          	addi	a1,s0,-80
    800052ca:	854a                	mv	a0,s2
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	b78080e7          	jalr	-1160(ra) # 80003e44 <dirlookup>
    800052d4:	84aa                	mv	s1,a0
    800052d6:	c921                	beqz	a0,80005326 <create+0x94>
    iunlockput(dp);
    800052d8:	854a                	mv	a0,s2
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	8e8080e7          	jalr	-1816(ra) # 80003bc2 <iunlockput>
    ilock(ip);
    800052e2:	8526                	mv	a0,s1
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	67c080e7          	jalr	1660(ra) # 80003960 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052ec:	2981                	sext.w	s3,s3
    800052ee:	4789                	li	a5,2
    800052f0:	02f99463          	bne	s3,a5,80005318 <create+0x86>
    800052f4:	0444d783          	lhu	a5,68(s1)
    800052f8:	37f9                	addiw	a5,a5,-2
    800052fa:	17c2                	slli	a5,a5,0x30
    800052fc:	93c1                	srli	a5,a5,0x30
    800052fe:	4705                	li	a4,1
    80005300:	00f76c63          	bltu	a4,a5,80005318 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005304:	8526                	mv	a0,s1
    80005306:	60a6                	ld	ra,72(sp)
    80005308:	6406                	ld	s0,64(sp)
    8000530a:	74e2                	ld	s1,56(sp)
    8000530c:	7942                	ld	s2,48(sp)
    8000530e:	79a2                	ld	s3,40(sp)
    80005310:	7a02                	ld	s4,32(sp)
    80005312:	6ae2                	ld	s5,24(sp)
    80005314:	6161                	addi	sp,sp,80
    80005316:	8082                	ret
    iunlockput(ip);
    80005318:	8526                	mv	a0,s1
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	8a8080e7          	jalr	-1880(ra) # 80003bc2 <iunlockput>
    return 0;
    80005322:	4481                	li	s1,0
    80005324:	b7c5                	j	80005304 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005326:	85ce                	mv	a1,s3
    80005328:	00092503          	lw	a0,0(s2)
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	49c080e7          	jalr	1180(ra) # 800037c8 <ialloc>
    80005334:	84aa                	mv	s1,a0
    80005336:	c529                	beqz	a0,80005380 <create+0xee>
  ilock(ip);
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	628080e7          	jalr	1576(ra) # 80003960 <ilock>
  ip->major = major;
    80005340:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005344:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005348:	4785                	li	a5,1
    8000534a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000534e:	8526                	mv	a0,s1
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	546080e7          	jalr	1350(ra) # 80003896 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005358:	2981                	sext.w	s3,s3
    8000535a:	4785                	li	a5,1
    8000535c:	02f98a63          	beq	s3,a5,80005390 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005360:	40d0                	lw	a2,4(s1)
    80005362:	fb040593          	addi	a1,s0,-80
    80005366:	854a                	mv	a0,s2
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	cec080e7          	jalr	-788(ra) # 80004054 <dirlink>
    80005370:	06054b63          	bltz	a0,800053e6 <create+0x154>
  iunlockput(dp);
    80005374:	854a                	mv	a0,s2
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	84c080e7          	jalr	-1972(ra) # 80003bc2 <iunlockput>
  return ip;
    8000537e:	b759                	j	80005304 <create+0x72>
    panic("create: ialloc");
    80005380:	00003517          	auipc	a0,0x3
    80005384:	42050513          	addi	a0,a0,1056 # 800087a0 <syscalls+0x2b8>
    80005388:	ffffb097          	auipc	ra,0xffffb
    8000538c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005390:	04a95783          	lhu	a5,74(s2)
    80005394:	2785                	addiw	a5,a5,1
    80005396:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000539a:	854a                	mv	a0,s2
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	4fa080e7          	jalr	1274(ra) # 80003896 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053a4:	40d0                	lw	a2,4(s1)
    800053a6:	00003597          	auipc	a1,0x3
    800053aa:	40a58593          	addi	a1,a1,1034 # 800087b0 <syscalls+0x2c8>
    800053ae:	8526                	mv	a0,s1
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	ca4080e7          	jalr	-860(ra) # 80004054 <dirlink>
    800053b8:	00054f63          	bltz	a0,800053d6 <create+0x144>
    800053bc:	00492603          	lw	a2,4(s2)
    800053c0:	00003597          	auipc	a1,0x3
    800053c4:	3f858593          	addi	a1,a1,1016 # 800087b8 <syscalls+0x2d0>
    800053c8:	8526                	mv	a0,s1
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	c8a080e7          	jalr	-886(ra) # 80004054 <dirlink>
    800053d2:	f80557e3          	bgez	a0,80005360 <create+0xce>
      panic("create dots");
    800053d6:	00003517          	auipc	a0,0x3
    800053da:	3ea50513          	addi	a0,a0,1002 # 800087c0 <syscalls+0x2d8>
    800053de:	ffffb097          	auipc	ra,0xffffb
    800053e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053e6:	00003517          	auipc	a0,0x3
    800053ea:	3ea50513          	addi	a0,a0,1002 # 800087d0 <syscalls+0x2e8>
    800053ee:	ffffb097          	auipc	ra,0xffffb
    800053f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
    return 0;
    800053f6:	84aa                	mv	s1,a0
    800053f8:	b731                	j	80005304 <create+0x72>

00000000800053fa <sys_dup>:
{
    800053fa:	7179                	addi	sp,sp,-48
    800053fc:	f406                	sd	ra,40(sp)
    800053fe:	f022                	sd	s0,32(sp)
    80005400:	ec26                	sd	s1,24(sp)
    80005402:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005404:	fd840613          	addi	a2,s0,-40
    80005408:	4581                	li	a1,0
    8000540a:	4501                	li	a0,0
    8000540c:	00000097          	auipc	ra,0x0
    80005410:	ddc080e7          	jalr	-548(ra) # 800051e8 <argfd>
    return -1;
    80005414:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005416:	02054363          	bltz	a0,8000543c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000541a:	fd843503          	ld	a0,-40(s0)
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	e32080e7          	jalr	-462(ra) # 80005250 <fdalloc>
    80005426:	84aa                	mv	s1,a0
    return -1;
    80005428:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000542a:	00054963          	bltz	a0,8000543c <sys_dup+0x42>
  filedup(f);
    8000542e:	fd843503          	ld	a0,-40(s0)
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	37a080e7          	jalr	890(ra) # 800047ac <filedup>
  return fd;
    8000543a:	87a6                	mv	a5,s1
}
    8000543c:	853e                	mv	a0,a5
    8000543e:	70a2                	ld	ra,40(sp)
    80005440:	7402                	ld	s0,32(sp)
    80005442:	64e2                	ld	s1,24(sp)
    80005444:	6145                	addi	sp,sp,48
    80005446:	8082                	ret

0000000080005448 <sys_read>:
{
    80005448:	7179                	addi	sp,sp,-48
    8000544a:	f406                	sd	ra,40(sp)
    8000544c:	f022                	sd	s0,32(sp)
    8000544e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005450:	fe840613          	addi	a2,s0,-24
    80005454:	4581                	li	a1,0
    80005456:	4501                	li	a0,0
    80005458:	00000097          	auipc	ra,0x0
    8000545c:	d90080e7          	jalr	-624(ra) # 800051e8 <argfd>
    return -1;
    80005460:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005462:	04054163          	bltz	a0,800054a4 <sys_read+0x5c>
    80005466:	fe440593          	addi	a1,s0,-28
    8000546a:	4509                	li	a0,2
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	920080e7          	jalr	-1760(ra) # 80002d8c <argint>
    return -1;
    80005474:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005476:	02054763          	bltz	a0,800054a4 <sys_read+0x5c>
    8000547a:	fd840593          	addi	a1,s0,-40
    8000547e:	4505                	li	a0,1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	92e080e7          	jalr	-1746(ra) # 80002dae <argaddr>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548a:	00054d63          	bltz	a0,800054a4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000548e:	fe442603          	lw	a2,-28(s0)
    80005492:	fd843583          	ld	a1,-40(s0)
    80005496:	fe843503          	ld	a0,-24(s0)
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	49e080e7          	jalr	1182(ra) # 80004938 <fileread>
    800054a2:	87aa                	mv	a5,a0
}
    800054a4:	853e                	mv	a0,a5
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	6145                	addi	sp,sp,48
    800054ac:	8082                	ret

00000000800054ae <sys_write>:
{
    800054ae:	7179                	addi	sp,sp,-48
    800054b0:	f406                	sd	ra,40(sp)
    800054b2:	f022                	sd	s0,32(sp)
    800054b4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b6:	fe840613          	addi	a2,s0,-24
    800054ba:	4581                	li	a1,0
    800054bc:	4501                	li	a0,0
    800054be:	00000097          	auipc	ra,0x0
    800054c2:	d2a080e7          	jalr	-726(ra) # 800051e8 <argfd>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c8:	04054163          	bltz	a0,8000550a <sys_write+0x5c>
    800054cc:	fe440593          	addi	a1,s0,-28
    800054d0:	4509                	li	a0,2
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	8ba080e7          	jalr	-1862(ra) # 80002d8c <argint>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054dc:	02054763          	bltz	a0,8000550a <sys_write+0x5c>
    800054e0:	fd840593          	addi	a1,s0,-40
    800054e4:	4505                	li	a0,1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	8c8080e7          	jalr	-1848(ra) # 80002dae <argaddr>
    return -1;
    800054ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f0:	00054d63          	bltz	a0,8000550a <sys_write+0x5c>
  return filewrite(f, p, n);
    800054f4:	fe442603          	lw	a2,-28(s0)
    800054f8:	fd843583          	ld	a1,-40(s0)
    800054fc:	fe843503          	ld	a0,-24(s0)
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	4fa080e7          	jalr	1274(ra) # 800049fa <filewrite>
    80005508:	87aa                	mv	a5,a0
}
    8000550a:	853e                	mv	a0,a5
    8000550c:	70a2                	ld	ra,40(sp)
    8000550e:	7402                	ld	s0,32(sp)
    80005510:	6145                	addi	sp,sp,48
    80005512:	8082                	ret

0000000080005514 <sys_close>:
{
    80005514:	1101                	addi	sp,sp,-32
    80005516:	ec06                	sd	ra,24(sp)
    80005518:	e822                	sd	s0,16(sp)
    8000551a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000551c:	fe040613          	addi	a2,s0,-32
    80005520:	fec40593          	addi	a1,s0,-20
    80005524:	4501                	li	a0,0
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	cc2080e7          	jalr	-830(ra) # 800051e8 <argfd>
    return -1;
    8000552e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005530:	02054463          	bltz	a0,80005558 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	75a080e7          	jalr	1882(ra) # 80001c8e <myproc>
    8000553c:	fec42783          	lw	a5,-20(s0)
    80005540:	07f1                	addi	a5,a5,28
    80005542:	078e                	slli	a5,a5,0x3
    80005544:	97aa                	add	a5,a5,a0
    80005546:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000554a:	fe043503          	ld	a0,-32(s0)
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	2b0080e7          	jalr	688(ra) # 800047fe <fileclose>
  return 0;
    80005556:	4781                	li	a5,0
}
    80005558:	853e                	mv	a0,a5
    8000555a:	60e2                	ld	ra,24(sp)
    8000555c:	6442                	ld	s0,16(sp)
    8000555e:	6105                	addi	sp,sp,32
    80005560:	8082                	ret

0000000080005562 <sys_fstat>:
{
    80005562:	1101                	addi	sp,sp,-32
    80005564:	ec06                	sd	ra,24(sp)
    80005566:	e822                	sd	s0,16(sp)
    80005568:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000556a:	fe840613          	addi	a2,s0,-24
    8000556e:	4581                	li	a1,0
    80005570:	4501                	li	a0,0
    80005572:	00000097          	auipc	ra,0x0
    80005576:	c76080e7          	jalr	-906(ra) # 800051e8 <argfd>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000557c:	02054563          	bltz	a0,800055a6 <sys_fstat+0x44>
    80005580:	fe040593          	addi	a1,s0,-32
    80005584:	4505                	li	a0,1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	828080e7          	jalr	-2008(ra) # 80002dae <argaddr>
    return -1;
    8000558e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005590:	00054b63          	bltz	a0,800055a6 <sys_fstat+0x44>
  return filestat(f, st);
    80005594:	fe043583          	ld	a1,-32(s0)
    80005598:	fe843503          	ld	a0,-24(s0)
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	32a080e7          	jalr	810(ra) # 800048c6 <filestat>
    800055a4:	87aa                	mv	a5,a0
}
    800055a6:	853e                	mv	a0,a5
    800055a8:	60e2                	ld	ra,24(sp)
    800055aa:	6442                	ld	s0,16(sp)
    800055ac:	6105                	addi	sp,sp,32
    800055ae:	8082                	ret

00000000800055b0 <sys_link>:
{
    800055b0:	7169                	addi	sp,sp,-304
    800055b2:	f606                	sd	ra,296(sp)
    800055b4:	f222                	sd	s0,288(sp)
    800055b6:	ee26                	sd	s1,280(sp)
    800055b8:	ea4a                	sd	s2,272(sp)
    800055ba:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055bc:	08000613          	li	a2,128
    800055c0:	ed040593          	addi	a1,s0,-304
    800055c4:	4501                	li	a0,0
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	80a080e7          	jalr	-2038(ra) # 80002dd0 <argstr>
    return -1;
    800055ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d0:	10054e63          	bltz	a0,800056ec <sys_link+0x13c>
    800055d4:	08000613          	li	a2,128
    800055d8:	f5040593          	addi	a1,s0,-176
    800055dc:	4505                	li	a0,1
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	7f2080e7          	jalr	2034(ra) # 80002dd0 <argstr>
    return -1;
    800055e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e8:	10054263          	bltz	a0,800056ec <sys_link+0x13c>
  begin_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	d46080e7          	jalr	-698(ra) # 80004332 <begin_op>
  if((ip = namei(old)) == 0){
    800055f4:	ed040513          	addi	a0,s0,-304
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	b1e080e7          	jalr	-1250(ra) # 80004116 <namei>
    80005600:	84aa                	mv	s1,a0
    80005602:	c551                	beqz	a0,8000568e <sys_link+0xde>
  ilock(ip);
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	35c080e7          	jalr	860(ra) # 80003960 <ilock>
  if(ip->type == T_DIR){
    8000560c:	04449703          	lh	a4,68(s1)
    80005610:	4785                	li	a5,1
    80005612:	08f70463          	beq	a4,a5,8000569a <sys_link+0xea>
  ip->nlink++;
    80005616:	04a4d783          	lhu	a5,74(s1)
    8000561a:	2785                	addiw	a5,a5,1
    8000561c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	274080e7          	jalr	628(ra) # 80003896 <iupdate>
  iunlock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	3f6080e7          	jalr	1014(ra) # 80003a22 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005634:	fd040593          	addi	a1,s0,-48
    80005638:	f5040513          	addi	a0,s0,-176
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	af8080e7          	jalr	-1288(ra) # 80004134 <nameiparent>
    80005644:	892a                	mv	s2,a0
    80005646:	c935                	beqz	a0,800056ba <sys_link+0x10a>
  ilock(dp);
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	318080e7          	jalr	792(ra) # 80003960 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005650:	00092703          	lw	a4,0(s2)
    80005654:	409c                	lw	a5,0(s1)
    80005656:	04f71d63          	bne	a4,a5,800056b0 <sys_link+0x100>
    8000565a:	40d0                	lw	a2,4(s1)
    8000565c:	fd040593          	addi	a1,s0,-48
    80005660:	854a                	mv	a0,s2
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	9f2080e7          	jalr	-1550(ra) # 80004054 <dirlink>
    8000566a:	04054363          	bltz	a0,800056b0 <sys_link+0x100>
  iunlockput(dp);
    8000566e:	854a                	mv	a0,s2
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	552080e7          	jalr	1362(ra) # 80003bc2 <iunlockput>
  iput(ip);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	4a0080e7          	jalr	1184(ra) # 80003b1a <iput>
  end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	d30080e7          	jalr	-720(ra) # 800043b2 <end_op>
  return 0;
    8000568a:	4781                	li	a5,0
    8000568c:	a085                	j	800056ec <sys_link+0x13c>
    end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	d24080e7          	jalr	-732(ra) # 800043b2 <end_op>
    return -1;
    80005696:	57fd                	li	a5,-1
    80005698:	a891                	j	800056ec <sys_link+0x13c>
    iunlockput(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	526080e7          	jalr	1318(ra) # 80003bc2 <iunlockput>
    end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	d0e080e7          	jalr	-754(ra) # 800043b2 <end_op>
    return -1;
    800056ac:	57fd                	li	a5,-1
    800056ae:	a83d                	j	800056ec <sys_link+0x13c>
    iunlockput(dp);
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	510080e7          	jalr	1296(ra) # 80003bc2 <iunlockput>
  ilock(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	2a4080e7          	jalr	676(ra) # 80003960 <ilock>
  ip->nlink--;
    800056c4:	04a4d783          	lhu	a5,74(s1)
    800056c8:	37fd                	addiw	a5,a5,-1
    800056ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ce:	8526                	mv	a0,s1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	1c6080e7          	jalr	454(ra) # 80003896 <iupdate>
  iunlockput(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	4e8080e7          	jalr	1256(ra) # 80003bc2 <iunlockput>
  end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	cd0080e7          	jalr	-816(ra) # 800043b2 <end_op>
  return -1;
    800056ea:	57fd                	li	a5,-1
}
    800056ec:	853e                	mv	a0,a5
    800056ee:	70b2                	ld	ra,296(sp)
    800056f0:	7412                	ld	s0,288(sp)
    800056f2:	64f2                	ld	s1,280(sp)
    800056f4:	6952                	ld	s2,272(sp)
    800056f6:	6155                	addi	sp,sp,304
    800056f8:	8082                	ret

00000000800056fa <sys_unlink>:
{
    800056fa:	7151                	addi	sp,sp,-240
    800056fc:	f586                	sd	ra,232(sp)
    800056fe:	f1a2                	sd	s0,224(sp)
    80005700:	eda6                	sd	s1,216(sp)
    80005702:	e9ca                	sd	s2,208(sp)
    80005704:	e5ce                	sd	s3,200(sp)
    80005706:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005708:	08000613          	li	a2,128
    8000570c:	f3040593          	addi	a1,s0,-208
    80005710:	4501                	li	a0,0
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	6be080e7          	jalr	1726(ra) # 80002dd0 <argstr>
    8000571a:	18054163          	bltz	a0,8000589c <sys_unlink+0x1a2>
  begin_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	c14080e7          	jalr	-1004(ra) # 80004332 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005726:	fb040593          	addi	a1,s0,-80
    8000572a:	f3040513          	addi	a0,s0,-208
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	a06080e7          	jalr	-1530(ra) # 80004134 <nameiparent>
    80005736:	84aa                	mv	s1,a0
    80005738:	c979                	beqz	a0,8000580e <sys_unlink+0x114>
  ilock(dp);
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	226080e7          	jalr	550(ra) # 80003960 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005742:	00003597          	auipc	a1,0x3
    80005746:	06e58593          	addi	a1,a1,110 # 800087b0 <syscalls+0x2c8>
    8000574a:	fb040513          	addi	a0,s0,-80
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	6dc080e7          	jalr	1756(ra) # 80003e2a <namecmp>
    80005756:	14050a63          	beqz	a0,800058aa <sys_unlink+0x1b0>
    8000575a:	00003597          	auipc	a1,0x3
    8000575e:	05e58593          	addi	a1,a1,94 # 800087b8 <syscalls+0x2d0>
    80005762:	fb040513          	addi	a0,s0,-80
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	6c4080e7          	jalr	1732(ra) # 80003e2a <namecmp>
    8000576e:	12050e63          	beqz	a0,800058aa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005772:	f2c40613          	addi	a2,s0,-212
    80005776:	fb040593          	addi	a1,s0,-80
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	6c8080e7          	jalr	1736(ra) # 80003e44 <dirlookup>
    80005784:	892a                	mv	s2,a0
    80005786:	12050263          	beqz	a0,800058aa <sys_unlink+0x1b0>
  ilock(ip);
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	1d6080e7          	jalr	470(ra) # 80003960 <ilock>
  if(ip->nlink < 1)
    80005792:	04a91783          	lh	a5,74(s2)
    80005796:	08f05263          	blez	a5,8000581a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000579a:	04491703          	lh	a4,68(s2)
    8000579e:	4785                	li	a5,1
    800057a0:	08f70563          	beq	a4,a5,8000582a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057a4:	4641                	li	a2,16
    800057a6:	4581                	li	a1,0
    800057a8:	fc040513          	addi	a0,s0,-64
    800057ac:	ffffb097          	auipc	ra,0xffffb
    800057b0:	534080e7          	jalr	1332(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b4:	4741                	li	a4,16
    800057b6:	f2c42683          	lw	a3,-212(s0)
    800057ba:	fc040613          	addi	a2,s0,-64
    800057be:	4581                	li	a1,0
    800057c0:	8526                	mv	a0,s1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	54a080e7          	jalr	1354(ra) # 80003d0c <writei>
    800057ca:	47c1                	li	a5,16
    800057cc:	0af51563          	bne	a0,a5,80005876 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d0:	04491703          	lh	a4,68(s2)
    800057d4:	4785                	li	a5,1
    800057d6:	0af70863          	beq	a4,a5,80005886 <sys_unlink+0x18c>
  iunlockput(dp);
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	3e6080e7          	jalr	998(ra) # 80003bc2 <iunlockput>
  ip->nlink--;
    800057e4:	04a95783          	lhu	a5,74(s2)
    800057e8:	37fd                	addiw	a5,a5,-1
    800057ea:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	0a6080e7          	jalr	166(ra) # 80003896 <iupdate>
  iunlockput(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	3c8080e7          	jalr	968(ra) # 80003bc2 <iunlockput>
  end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	bb0080e7          	jalr	-1104(ra) # 800043b2 <end_op>
  return 0;
    8000580a:	4501                	li	a0,0
    8000580c:	a84d                	j	800058be <sys_unlink+0x1c4>
    end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	ba4080e7          	jalr	-1116(ra) # 800043b2 <end_op>
    return -1;
    80005816:	557d                	li	a0,-1
    80005818:	a05d                	j	800058be <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000581a:	00003517          	auipc	a0,0x3
    8000581e:	fc650513          	addi	a0,a0,-58 # 800087e0 <syscalls+0x2f8>
    80005822:	ffffb097          	auipc	ra,0xffffb
    80005826:	d1c080e7          	jalr	-740(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582a:	04c92703          	lw	a4,76(s2)
    8000582e:	02000793          	li	a5,32
    80005832:	f6e7f9e3          	bgeu	a5,a4,800057a4 <sys_unlink+0xaa>
    80005836:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583a:	4741                	li	a4,16
    8000583c:	86ce                	mv	a3,s3
    8000583e:	f1840613          	addi	a2,s0,-232
    80005842:	4581                	li	a1,0
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	3ce080e7          	jalr	974(ra) # 80003c14 <readi>
    8000584e:	47c1                	li	a5,16
    80005850:	00f51b63          	bne	a0,a5,80005866 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005854:	f1845783          	lhu	a5,-232(s0)
    80005858:	e7a1                	bnez	a5,800058a0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585a:	29c1                	addiw	s3,s3,16
    8000585c:	04c92783          	lw	a5,76(s2)
    80005860:	fcf9ede3          	bltu	s3,a5,8000583a <sys_unlink+0x140>
    80005864:	b781                	j	800057a4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005866:	00003517          	auipc	a0,0x3
    8000586a:	f9250513          	addi	a0,a0,-110 # 800087f8 <syscalls+0x310>
    8000586e:	ffffb097          	auipc	ra,0xffffb
    80005872:	cd0080e7          	jalr	-816(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005876:	00003517          	auipc	a0,0x3
    8000587a:	f9a50513          	addi	a0,a0,-102 # 80008810 <syscalls+0x328>
    8000587e:	ffffb097          	auipc	ra,0xffffb
    80005882:	cc0080e7          	jalr	-832(ra) # 8000053e <panic>
    dp->nlink--;
    80005886:	04a4d783          	lhu	a5,74(s1)
    8000588a:	37fd                	addiw	a5,a5,-1
    8000588c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	004080e7          	jalr	4(ra) # 80003896 <iupdate>
    8000589a:	b781                	j	800057da <sys_unlink+0xe0>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	a005                	j	800058be <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	320080e7          	jalr	800(ra) # 80003bc2 <iunlockput>
  iunlockput(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	316080e7          	jalr	790(ra) # 80003bc2 <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	afe080e7          	jalr	-1282(ra) # 800043b2 <end_op>
  return -1;
    800058bc:	557d                	li	a0,-1
}
    800058be:	70ae                	ld	ra,232(sp)
    800058c0:	740e                	ld	s0,224(sp)
    800058c2:	64ee                	ld	s1,216(sp)
    800058c4:	694e                	ld	s2,208(sp)
    800058c6:	69ae                	ld	s3,200(sp)
    800058c8:	616d                	addi	sp,sp,240
    800058ca:	8082                	ret

00000000800058cc <sys_open>:

uint64
sys_open(void)
{
    800058cc:	7131                	addi	sp,sp,-192
    800058ce:	fd06                	sd	ra,184(sp)
    800058d0:	f922                	sd	s0,176(sp)
    800058d2:	f526                	sd	s1,168(sp)
    800058d4:	f14a                	sd	s2,160(sp)
    800058d6:	ed4e                	sd	s3,152(sp)
    800058d8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058da:	08000613          	li	a2,128
    800058de:	f5040593          	addi	a1,s0,-176
    800058e2:	4501                	li	a0,0
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	4ec080e7          	jalr	1260(ra) # 80002dd0 <argstr>
    return -1;
    800058ec:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ee:	0c054163          	bltz	a0,800059b0 <sys_open+0xe4>
    800058f2:	f4c40593          	addi	a1,s0,-180
    800058f6:	4505                	li	a0,1
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	494080e7          	jalr	1172(ra) # 80002d8c <argint>
    80005900:	0a054863          	bltz	a0,800059b0 <sys_open+0xe4>

  begin_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	a2e080e7          	jalr	-1490(ra) # 80004332 <begin_op>

  if(omode & O_CREATE){
    8000590c:	f4c42783          	lw	a5,-180(s0)
    80005910:	2007f793          	andi	a5,a5,512
    80005914:	cbdd                	beqz	a5,800059ca <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005916:	4681                	li	a3,0
    80005918:	4601                	li	a2,0
    8000591a:	4589                	li	a1,2
    8000591c:	f5040513          	addi	a0,s0,-176
    80005920:	00000097          	auipc	ra,0x0
    80005924:	972080e7          	jalr	-1678(ra) # 80005292 <create>
    80005928:	892a                	mv	s2,a0
    if(ip == 0){
    8000592a:	c959                	beqz	a0,800059c0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000592c:	04491703          	lh	a4,68(s2)
    80005930:	478d                	li	a5,3
    80005932:	00f71763          	bne	a4,a5,80005940 <sys_open+0x74>
    80005936:	04695703          	lhu	a4,70(s2)
    8000593a:	47a5                	li	a5,9
    8000593c:	0ce7ec63          	bltu	a5,a4,80005a14 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	e02080e7          	jalr	-510(ra) # 80004742 <filealloc>
    80005948:	89aa                	mv	s3,a0
    8000594a:	10050263          	beqz	a0,80005a4e <sys_open+0x182>
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	902080e7          	jalr	-1790(ra) # 80005250 <fdalloc>
    80005956:	84aa                	mv	s1,a0
    80005958:	0e054663          	bltz	a0,80005a44 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000595c:	04491703          	lh	a4,68(s2)
    80005960:	478d                	li	a5,3
    80005962:	0cf70463          	beq	a4,a5,80005a2a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005966:	4789                	li	a5,2
    80005968:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000596c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005970:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005974:	f4c42783          	lw	a5,-180(s0)
    80005978:	0017c713          	xori	a4,a5,1
    8000597c:	8b05                	andi	a4,a4,1
    8000597e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005982:	0037f713          	andi	a4,a5,3
    80005986:	00e03733          	snez	a4,a4
    8000598a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000598e:	4007f793          	andi	a5,a5,1024
    80005992:	c791                	beqz	a5,8000599e <sys_open+0xd2>
    80005994:	04491703          	lh	a4,68(s2)
    80005998:	4789                	li	a5,2
    8000599a:	08f70f63          	beq	a4,a5,80005a38 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000599e:	854a                	mv	a0,s2
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	082080e7          	jalr	130(ra) # 80003a22 <iunlock>
  end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	a0a080e7          	jalr	-1526(ra) # 800043b2 <end_op>

  return fd;
}
    800059b0:	8526                	mv	a0,s1
    800059b2:	70ea                	ld	ra,184(sp)
    800059b4:	744a                	ld	s0,176(sp)
    800059b6:	74aa                	ld	s1,168(sp)
    800059b8:	790a                	ld	s2,160(sp)
    800059ba:	69ea                	ld	s3,152(sp)
    800059bc:	6129                	addi	sp,sp,192
    800059be:	8082                	ret
      end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	9f2080e7          	jalr	-1550(ra) # 800043b2 <end_op>
      return -1;
    800059c8:	b7e5                	j	800059b0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059ca:	f5040513          	addi	a0,s0,-176
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	748080e7          	jalr	1864(ra) # 80004116 <namei>
    800059d6:	892a                	mv	s2,a0
    800059d8:	c905                	beqz	a0,80005a08 <sys_open+0x13c>
    ilock(ip);
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	f86080e7          	jalr	-122(ra) # 80003960 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059e2:	04491703          	lh	a4,68(s2)
    800059e6:	4785                	li	a5,1
    800059e8:	f4f712e3          	bne	a4,a5,8000592c <sys_open+0x60>
    800059ec:	f4c42783          	lw	a5,-180(s0)
    800059f0:	dba1                	beqz	a5,80005940 <sys_open+0x74>
      iunlockput(ip);
    800059f2:	854a                	mv	a0,s2
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	1ce080e7          	jalr	462(ra) # 80003bc2 <iunlockput>
      end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	9b6080e7          	jalr	-1610(ra) # 800043b2 <end_op>
      return -1;
    80005a04:	54fd                	li	s1,-1
    80005a06:	b76d                	j	800059b0 <sys_open+0xe4>
      end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	9aa080e7          	jalr	-1622(ra) # 800043b2 <end_op>
      return -1;
    80005a10:	54fd                	li	s1,-1
    80005a12:	bf79                	j	800059b0 <sys_open+0xe4>
    iunlockput(ip);
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	1ac080e7          	jalr	428(ra) # 80003bc2 <iunlockput>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	994080e7          	jalr	-1644(ra) # 800043b2 <end_op>
    return -1;
    80005a26:	54fd                	li	s1,-1
    80005a28:	b761                	j	800059b0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a2a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a2e:	04691783          	lh	a5,70(s2)
    80005a32:	02f99223          	sh	a5,36(s3)
    80005a36:	bf2d                	j	80005970 <sys_open+0xa4>
    itrunc(ip);
    80005a38:	854a                	mv	a0,s2
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	034080e7          	jalr	52(ra) # 80003a6e <itrunc>
    80005a42:	bfb1                	j	8000599e <sys_open+0xd2>
      fileclose(f);
    80005a44:	854e                	mv	a0,s3
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	db8080e7          	jalr	-584(ra) # 800047fe <fileclose>
    iunlockput(ip);
    80005a4e:	854a                	mv	a0,s2
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	172080e7          	jalr	370(ra) # 80003bc2 <iunlockput>
    end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	95a080e7          	jalr	-1702(ra) # 800043b2 <end_op>
    return -1;
    80005a60:	54fd                	li	s1,-1
    80005a62:	b7b9                	j	800059b0 <sys_open+0xe4>

0000000080005a64 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a64:	7175                	addi	sp,sp,-144
    80005a66:	e506                	sd	ra,136(sp)
    80005a68:	e122                	sd	s0,128(sp)
    80005a6a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	8c6080e7          	jalr	-1850(ra) # 80004332 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a74:	08000613          	li	a2,128
    80005a78:	f7040593          	addi	a1,s0,-144
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	352080e7          	jalr	850(ra) # 80002dd0 <argstr>
    80005a86:	02054963          	bltz	a0,80005ab8 <sys_mkdir+0x54>
    80005a8a:	4681                	li	a3,0
    80005a8c:	4601                	li	a2,0
    80005a8e:	4585                	li	a1,1
    80005a90:	f7040513          	addi	a0,s0,-144
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	7fe080e7          	jalr	2046(ra) # 80005292 <create>
    80005a9c:	cd11                	beqz	a0,80005ab8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	124080e7          	jalr	292(ra) # 80003bc2 <iunlockput>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	90c080e7          	jalr	-1780(ra) # 800043b2 <end_op>
  return 0;
    80005aae:	4501                	li	a0,0
}
    80005ab0:	60aa                	ld	ra,136(sp)
    80005ab2:	640a                	ld	s0,128(sp)
    80005ab4:	6149                	addi	sp,sp,144
    80005ab6:	8082                	ret
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	8fa080e7          	jalr	-1798(ra) # 800043b2 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	b7fd                	j	80005ab0 <sys_mkdir+0x4c>

0000000080005ac4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac4:	7135                	addi	sp,sp,-160
    80005ac6:	ed06                	sd	ra,152(sp)
    80005ac8:	e922                	sd	s0,144(sp)
    80005aca:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	866080e7          	jalr	-1946(ra) # 80004332 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad4:	08000613          	li	a2,128
    80005ad8:	f7040593          	addi	a1,s0,-144
    80005adc:	4501                	li	a0,0
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	2f2080e7          	jalr	754(ra) # 80002dd0 <argstr>
    80005ae6:	04054a63          	bltz	a0,80005b3a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005aea:	f6c40593          	addi	a1,s0,-148
    80005aee:	4505                	li	a0,1
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	29c080e7          	jalr	668(ra) # 80002d8c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005af8:	04054163          	bltz	a0,80005b3a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005afc:	f6840593          	addi	a1,s0,-152
    80005b00:	4509                	li	a0,2
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	28a080e7          	jalr	650(ra) # 80002d8c <argint>
     argint(1, &major) < 0 ||
    80005b0a:	02054863          	bltz	a0,80005b3a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b0e:	f6841683          	lh	a3,-152(s0)
    80005b12:	f6c41603          	lh	a2,-148(s0)
    80005b16:	458d                	li	a1,3
    80005b18:	f7040513          	addi	a0,s0,-144
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	776080e7          	jalr	1910(ra) # 80005292 <create>
     argint(2, &minor) < 0 ||
    80005b24:	c919                	beqz	a0,80005b3a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	09c080e7          	jalr	156(ra) # 80003bc2 <iunlockput>
  end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	884080e7          	jalr	-1916(ra) # 800043b2 <end_op>
  return 0;
    80005b36:	4501                	li	a0,0
    80005b38:	a031                	j	80005b44 <sys_mknod+0x80>
    end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	878080e7          	jalr	-1928(ra) # 800043b2 <end_op>
    return -1;
    80005b42:	557d                	li	a0,-1
}
    80005b44:	60ea                	ld	ra,152(sp)
    80005b46:	644a                	ld	s0,144(sp)
    80005b48:	610d                	addi	sp,sp,160
    80005b4a:	8082                	ret

0000000080005b4c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b4c:	7135                	addi	sp,sp,-160
    80005b4e:	ed06                	sd	ra,152(sp)
    80005b50:	e922                	sd	s0,144(sp)
    80005b52:	e526                	sd	s1,136(sp)
    80005b54:	e14a                	sd	s2,128(sp)
    80005b56:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	136080e7          	jalr	310(ra) # 80001c8e <myproc>
    80005b60:	892a                	mv	s2,a0
  
  begin_op();
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	7d0080e7          	jalr	2000(ra) # 80004332 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b6a:	08000613          	li	a2,128
    80005b6e:	f6040593          	addi	a1,s0,-160
    80005b72:	4501                	li	a0,0
    80005b74:	ffffd097          	auipc	ra,0xffffd
    80005b78:	25c080e7          	jalr	604(ra) # 80002dd0 <argstr>
    80005b7c:	04054b63          	bltz	a0,80005bd2 <sys_chdir+0x86>
    80005b80:	f6040513          	addi	a0,s0,-160
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	592080e7          	jalr	1426(ra) # 80004116 <namei>
    80005b8c:	84aa                	mv	s1,a0
    80005b8e:	c131                	beqz	a0,80005bd2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	dd0080e7          	jalr	-560(ra) # 80003960 <ilock>
  if(ip->type != T_DIR){
    80005b98:	04449703          	lh	a4,68(s1)
    80005b9c:	4785                	li	a5,1
    80005b9e:	04f71063          	bne	a4,a5,80005bde <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ba2:	8526                	mv	a0,s1
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	e7e080e7          	jalr	-386(ra) # 80003a22 <iunlock>
  iput(p->cwd);
    80005bac:	16893503          	ld	a0,360(s2)
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	f6a080e7          	jalr	-150(ra) # 80003b1a <iput>
  end_op();
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	7fa080e7          	jalr	2042(ra) # 800043b2 <end_op>
  p->cwd = ip;
    80005bc0:	16993423          	sd	s1,360(s2)
  return 0;
    80005bc4:	4501                	li	a0,0
}
    80005bc6:	60ea                	ld	ra,152(sp)
    80005bc8:	644a                	ld	s0,144(sp)
    80005bca:	64aa                	ld	s1,136(sp)
    80005bcc:	690a                	ld	s2,128(sp)
    80005bce:	610d                	addi	sp,sp,160
    80005bd0:	8082                	ret
    end_op();
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	7e0080e7          	jalr	2016(ra) # 800043b2 <end_op>
    return -1;
    80005bda:	557d                	li	a0,-1
    80005bdc:	b7ed                	j	80005bc6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bde:	8526                	mv	a0,s1
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	fe2080e7          	jalr	-30(ra) # 80003bc2 <iunlockput>
    end_op();
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	7ca080e7          	jalr	1994(ra) # 800043b2 <end_op>
    return -1;
    80005bf0:	557d                	li	a0,-1
    80005bf2:	bfd1                	j	80005bc6 <sys_chdir+0x7a>

0000000080005bf4 <sys_exec>:

uint64
sys_exec(void)
{
    80005bf4:	7145                	addi	sp,sp,-464
    80005bf6:	e786                	sd	ra,456(sp)
    80005bf8:	e3a2                	sd	s0,448(sp)
    80005bfa:	ff26                	sd	s1,440(sp)
    80005bfc:	fb4a                	sd	s2,432(sp)
    80005bfe:	f74e                	sd	s3,424(sp)
    80005c00:	f352                	sd	s4,416(sp)
    80005c02:	ef56                	sd	s5,408(sp)
    80005c04:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c06:	08000613          	li	a2,128
    80005c0a:	f4040593          	addi	a1,s0,-192
    80005c0e:	4501                	li	a0,0
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	1c0080e7          	jalr	448(ra) # 80002dd0 <argstr>
    return -1;
    80005c18:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c1a:	0c054a63          	bltz	a0,80005cee <sys_exec+0xfa>
    80005c1e:	e3840593          	addi	a1,s0,-456
    80005c22:	4505                	li	a0,1
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	18a080e7          	jalr	394(ra) # 80002dae <argaddr>
    80005c2c:	0c054163          	bltz	a0,80005cee <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c30:	10000613          	li	a2,256
    80005c34:	4581                	li	a1,0
    80005c36:	e4040513          	addi	a0,s0,-448
    80005c3a:	ffffb097          	auipc	ra,0xffffb
    80005c3e:	0a6080e7          	jalr	166(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c42:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c46:	89a6                	mv	s3,s1
    80005c48:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c4a:	02000a13          	li	s4,32
    80005c4e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c52:	00391513          	slli	a0,s2,0x3
    80005c56:	e3040593          	addi	a1,s0,-464
    80005c5a:	e3843783          	ld	a5,-456(s0)
    80005c5e:	953e                	add	a0,a0,a5
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	092080e7          	jalr	146(ra) # 80002cf2 <fetchaddr>
    80005c68:	02054a63          	bltz	a0,80005c9c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c6c:	e3043783          	ld	a5,-464(s0)
    80005c70:	c3b9                	beqz	a5,80005cb6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c72:	ffffb097          	auipc	ra,0xffffb
    80005c76:	e82080e7          	jalr	-382(ra) # 80000af4 <kalloc>
    80005c7a:	85aa                	mv	a1,a0
    80005c7c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c80:	cd11                	beqz	a0,80005c9c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c82:	6605                	lui	a2,0x1
    80005c84:	e3043503          	ld	a0,-464(s0)
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	0bc080e7          	jalr	188(ra) # 80002d44 <fetchstr>
    80005c90:	00054663          	bltz	a0,80005c9c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c94:	0905                	addi	s2,s2,1
    80005c96:	09a1                	addi	s3,s3,8
    80005c98:	fb491be3          	bne	s2,s4,80005c4e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9c:	10048913          	addi	s2,s1,256
    80005ca0:	6088                	ld	a0,0(s1)
    80005ca2:	c529                	beqz	a0,80005cec <sys_exec+0xf8>
    kfree(argv[i]);
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	d54080e7          	jalr	-684(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	04a1                	addi	s1,s1,8
    80005cae:	ff2499e3          	bne	s1,s2,80005ca0 <sys_exec+0xac>
  return -1;
    80005cb2:	597d                	li	s2,-1
    80005cb4:	a82d                	j	80005cee <sys_exec+0xfa>
      argv[i] = 0;
    80005cb6:	0a8e                	slli	s5,s5,0x3
    80005cb8:	fc040793          	addi	a5,s0,-64
    80005cbc:	9abe                	add	s5,s5,a5
    80005cbe:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cc2:	e4040593          	addi	a1,s0,-448
    80005cc6:	f4040513          	addi	a0,s0,-192
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	194080e7          	jalr	404(ra) # 80004e5e <exec>
    80005cd2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd4:	10048993          	addi	s3,s1,256
    80005cd8:	6088                	ld	a0,0(s1)
    80005cda:	c911                	beqz	a0,80005cee <sys_exec+0xfa>
    kfree(argv[i]);
    80005cdc:	ffffb097          	auipc	ra,0xffffb
    80005ce0:	d1c080e7          	jalr	-740(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce4:	04a1                	addi	s1,s1,8
    80005ce6:	ff3499e3          	bne	s1,s3,80005cd8 <sys_exec+0xe4>
    80005cea:	a011                	j	80005cee <sys_exec+0xfa>
  return -1;
    80005cec:	597d                	li	s2,-1
}
    80005cee:	854a                	mv	a0,s2
    80005cf0:	60be                	ld	ra,456(sp)
    80005cf2:	641e                	ld	s0,448(sp)
    80005cf4:	74fa                	ld	s1,440(sp)
    80005cf6:	795a                	ld	s2,432(sp)
    80005cf8:	79ba                	ld	s3,424(sp)
    80005cfa:	7a1a                	ld	s4,416(sp)
    80005cfc:	6afa                	ld	s5,408(sp)
    80005cfe:	6179                	addi	sp,sp,464
    80005d00:	8082                	ret

0000000080005d02 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d02:	7139                	addi	sp,sp,-64
    80005d04:	fc06                	sd	ra,56(sp)
    80005d06:	f822                	sd	s0,48(sp)
    80005d08:	f426                	sd	s1,40(sp)
    80005d0a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d0c:	ffffc097          	auipc	ra,0xffffc
    80005d10:	f82080e7          	jalr	-126(ra) # 80001c8e <myproc>
    80005d14:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d16:	fd840593          	addi	a1,s0,-40
    80005d1a:	4501                	li	a0,0
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	092080e7          	jalr	146(ra) # 80002dae <argaddr>
    return -1;
    80005d24:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d26:	0e054063          	bltz	a0,80005e06 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d2a:	fc840593          	addi	a1,s0,-56
    80005d2e:	fd040513          	addi	a0,s0,-48
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	dfc080e7          	jalr	-516(ra) # 80004b2e <pipealloc>
    return -1;
    80005d3a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d3c:	0c054563          	bltz	a0,80005e06 <sys_pipe+0x104>
  fd0 = -1;
    80005d40:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d44:	fd043503          	ld	a0,-48(s0)
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	508080e7          	jalr	1288(ra) # 80005250 <fdalloc>
    80005d50:	fca42223          	sw	a0,-60(s0)
    80005d54:	08054c63          	bltz	a0,80005dec <sys_pipe+0xea>
    80005d58:	fc843503          	ld	a0,-56(s0)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	4f4080e7          	jalr	1268(ra) # 80005250 <fdalloc>
    80005d64:	fca42023          	sw	a0,-64(s0)
    80005d68:	06054863          	bltz	a0,80005dd8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d6c:	4691                	li	a3,4
    80005d6e:	fc440613          	addi	a2,s0,-60
    80005d72:	fd843583          	ld	a1,-40(s0)
    80005d76:	74a8                	ld	a0,104(s1)
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	8fa080e7          	jalr	-1798(ra) # 80001672 <copyout>
    80005d80:	02054063          	bltz	a0,80005da0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d84:	4691                	li	a3,4
    80005d86:	fc040613          	addi	a2,s0,-64
    80005d8a:	fd843583          	ld	a1,-40(s0)
    80005d8e:	0591                	addi	a1,a1,4
    80005d90:	74a8                	ld	a0,104(s1)
    80005d92:	ffffc097          	auipc	ra,0xffffc
    80005d96:	8e0080e7          	jalr	-1824(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d9a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9c:	06055563          	bgez	a0,80005e06 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005da0:	fc442783          	lw	a5,-60(s0)
    80005da4:	07f1                	addi	a5,a5,28
    80005da6:	078e                	slli	a5,a5,0x3
    80005da8:	97a6                	add	a5,a5,s1
    80005daa:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005dae:	fc042503          	lw	a0,-64(s0)
    80005db2:	0571                	addi	a0,a0,28
    80005db4:	050e                	slli	a0,a0,0x3
    80005db6:	9526                	add	a0,a0,s1
    80005db8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dbc:	fd043503          	ld	a0,-48(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	a3e080e7          	jalr	-1474(ra) # 800047fe <fileclose>
    fileclose(wf);
    80005dc8:	fc843503          	ld	a0,-56(s0)
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	a32080e7          	jalr	-1486(ra) # 800047fe <fileclose>
    return -1;
    80005dd4:	57fd                	li	a5,-1
    80005dd6:	a805                	j	80005e06 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dd8:	fc442783          	lw	a5,-60(s0)
    80005ddc:	0007c863          	bltz	a5,80005dec <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005de0:	01c78513          	addi	a0,a5,28
    80005de4:	050e                	slli	a0,a0,0x3
    80005de6:	9526                	add	a0,a0,s1
    80005de8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dec:	fd043503          	ld	a0,-48(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	a0e080e7          	jalr	-1522(ra) # 800047fe <fileclose>
    fileclose(wf);
    80005df8:	fc843503          	ld	a0,-56(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	a02080e7          	jalr	-1534(ra) # 800047fe <fileclose>
    return -1;
    80005e04:	57fd                	li	a5,-1
}
    80005e06:	853e                	mv	a0,a5
    80005e08:	70e2                	ld	ra,56(sp)
    80005e0a:	7442                	ld	s0,48(sp)
    80005e0c:	74a2                	ld	s1,40(sp)
    80005e0e:	6121                	addi	sp,sp,64
    80005e10:	8082                	ret
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	d5ffc0ef          	jal	ra,80002bbe <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	d6a080e7          	jalr	-662(ra) # 80001c62 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	d32080e7          	jalr	-718(ra) # 80001c62 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	d0a080e7          	jalr	-758(ra) # 80001c62 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	06a7c963          	blt	a5,a0,80005ff2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0001d797          	auipc	a5,0x1d
    80005f88:	07c78793          	addi	a5,a5,124 # 80023000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	e7ad                	bnez	a5,80006002 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451793          	slli	a5,a0,0x4
    80005f9e:	0001f717          	auipc	a4,0x1f
    80005fa2:	06270713          	addi	a4,a4,98 # 80025000 <disk+0x2000>
    80005fa6:	6314                	ld	a3,0(a4)
    80005fa8:	96be                	add	a3,a3,a5
    80005faa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fae:	6314                	ld	a3,0(a4)
    80005fb0:	96be                	add	a3,a3,a5
    80005fb2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fb6:	6314                	ld	a3,0(a4)
    80005fb8:	96be                	add	a3,a3,a5
    80005fba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fbe:	6318                	ld	a4,0(a4)
    80005fc0:	97ba                	add	a5,a5,a4
    80005fc2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fc6:	0001d797          	auipc	a5,0x1d
    80005fca:	03a78793          	addi	a5,a5,58 # 80023000 <disk>
    80005fce:	97aa                	add	a5,a5,a0
    80005fd0:	6509                	lui	a0,0x2
    80005fd2:	953e                	add	a0,a0,a5
    80005fd4:	4785                	li	a5,1
    80005fd6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fda:	0001f517          	auipc	a0,0x1f
    80005fde:	03e50513          	addi	a0,a0,62 # 80025018 <disk+0x2018>
    80005fe2:	ffffc097          	auipc	ra,0xffffc
    80005fe6:	4e8080e7          	jalr	1256(ra) # 800024ca <wakeup>
}
    80005fea:	60a2                	ld	ra,8(sp)
    80005fec:	6402                	ld	s0,0(sp)
    80005fee:	0141                	addi	sp,sp,16
    80005ff0:	8082                	ret
    panic("free_desc 1");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	82e50513          	addi	a0,a0,-2002 # 80008820 <syscalls+0x338>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	82e50513          	addi	a0,a0,-2002 # 80008830 <syscalls+0x348>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	534080e7          	jalr	1332(ra) # 8000053e <panic>

0000000080006012 <virtio_disk_init>:
{
    80006012:	1101                	addi	sp,sp,-32
    80006014:	ec06                	sd	ra,24(sp)
    80006016:	e822                	sd	s0,16(sp)
    80006018:	e426                	sd	s1,8(sp)
    8000601a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000601c:	00003597          	auipc	a1,0x3
    80006020:	82458593          	addi	a1,a1,-2012 # 80008840 <syscalls+0x358>
    80006024:	0001f517          	auipc	a0,0x1f
    80006028:	10450513          	addi	a0,a0,260 # 80025128 <disk+0x2128>
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	b28080e7          	jalr	-1240(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006034:	100017b7          	lui	a5,0x10001
    80006038:	4398                	lw	a4,0(a5)
    8000603a:	2701                	sext.w	a4,a4
    8000603c:	747277b7          	lui	a5,0x74727
    80006040:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006044:	0ef71163          	bne	a4,a5,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	43dc                	lw	a5,4(a5)
    8000604e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006050:	4705                	li	a4,1
    80006052:	0ce79a63          	bne	a5,a4,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006056:	100017b7          	lui	a5,0x10001
    8000605a:	479c                	lw	a5,8(a5)
    8000605c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000605e:	4709                	li	a4,2
    80006060:	0ce79363          	bne	a5,a4,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006064:	100017b7          	lui	a5,0x10001
    80006068:	47d8                	lw	a4,12(a5)
    8000606a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000606c:	554d47b7          	lui	a5,0x554d4
    80006070:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006074:	0af71963          	bne	a4,a5,80006126 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006078:	100017b7          	lui	a5,0x10001
    8000607c:	4705                	li	a4,1
    8000607e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006080:	470d                	li	a4,3
    80006082:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006084:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006086:	c7ffe737          	lui	a4,0xc7ffe
    8000608a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000608e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006090:	2701                	sext.w	a4,a4
    80006092:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006094:	472d                	li	a4,11
    80006096:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006098:	473d                	li	a4,15
    8000609a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000609c:	6705                	lui	a4,0x1
    8000609e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060a4:	5bdc                	lw	a5,52(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a8:	c7d9                	beqz	a5,80006136 <virtio_disk_init+0x124>
  if(max < NUM)
    800060aa:	471d                	li	a4,7
    800060ac:	08f77d63          	bgeu	a4,a5,80006146 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060b0:	100014b7          	lui	s1,0x10001
    800060b4:	47a1                	li	a5,8
    800060b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060b8:	6609                	lui	a2,0x2
    800060ba:	4581                	li	a1,0
    800060bc:	0001d517          	auipc	a0,0x1d
    800060c0:	f4450513          	addi	a0,a0,-188 # 80023000 <disk>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	c1c080e7          	jalr	-996(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060cc:	0001d717          	auipc	a4,0x1d
    800060d0:	f3470713          	addi	a4,a4,-204 # 80023000 <disk>
    800060d4:	00c75793          	srli	a5,a4,0xc
    800060d8:	2781                	sext.w	a5,a5
    800060da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060dc:	0001f797          	auipc	a5,0x1f
    800060e0:	f2478793          	addi	a5,a5,-220 # 80025000 <disk+0x2000>
    800060e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060e6:	0001d717          	auipc	a4,0x1d
    800060ea:	f9a70713          	addi	a4,a4,-102 # 80023080 <disk+0x80>
    800060ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060f0:	0001e717          	auipc	a4,0x1e
    800060f4:	f1070713          	addi	a4,a4,-240 # 80024000 <disk+0x1000>
    800060f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060fa:	4705                	li	a4,1
    800060fc:	00e78c23          	sb	a4,24(a5)
    80006100:	00e78ca3          	sb	a4,25(a5)
    80006104:	00e78d23          	sb	a4,26(a5)
    80006108:	00e78da3          	sb	a4,27(a5)
    8000610c:	00e78e23          	sb	a4,28(a5)
    80006110:	00e78ea3          	sb	a4,29(a5)
    80006114:	00e78f23          	sb	a4,30(a5)
    80006118:	00e78fa3          	sb	a4,31(a5)
}
    8000611c:	60e2                	ld	ra,24(sp)
    8000611e:	6442                	ld	s0,16(sp)
    80006120:	64a2                	ld	s1,8(sp)
    80006122:	6105                	addi	sp,sp,32
    80006124:	8082                	ret
    panic("could not find virtio disk");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	72a50513          	addi	a0,a0,1834 # 80008850 <syscalls+0x368>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	73a50513          	addi	a0,a0,1850 # 80008870 <syscalls+0x388>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	74a50513          	addi	a0,a0,1866 # 80008890 <syscalls+0x3a8>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>

0000000080006156 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006156:	7159                	addi	sp,sp,-112
    80006158:	f486                	sd	ra,104(sp)
    8000615a:	f0a2                	sd	s0,96(sp)
    8000615c:	eca6                	sd	s1,88(sp)
    8000615e:	e8ca                	sd	s2,80(sp)
    80006160:	e4ce                	sd	s3,72(sp)
    80006162:	e0d2                	sd	s4,64(sp)
    80006164:	fc56                	sd	s5,56(sp)
    80006166:	f85a                	sd	s6,48(sp)
    80006168:	f45e                	sd	s7,40(sp)
    8000616a:	f062                	sd	s8,32(sp)
    8000616c:	ec66                	sd	s9,24(sp)
    8000616e:	e86a                	sd	s10,16(sp)
    80006170:	1880                	addi	s0,sp,112
    80006172:	892a                	mv	s2,a0
    80006174:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006176:	00c52c83          	lw	s9,12(a0)
    8000617a:	001c9c9b          	slliw	s9,s9,0x1
    8000617e:	1c82                	slli	s9,s9,0x20
    80006180:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006184:	0001f517          	auipc	a0,0x1f
    80006188:	fa450513          	addi	a0,a0,-92 # 80025128 <disk+0x2128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	a58080e7          	jalr	-1448(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006194:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006196:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006198:	0001db97          	auipc	s7,0x1d
    8000619c:	e68b8b93          	addi	s7,s7,-408 # 80023000 <disk>
    800061a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061a4:	8a4e                	mv	s4,s3
    800061a6:	a051                	j	8000622a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061a8:	00fb86b3          	add	a3,s7,a5
    800061ac:	96da                	add	a3,a3,s6
    800061ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061b4:	0207c563          	bltz	a5,800061de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061b8:	2485                	addiw	s1,s1,1
    800061ba:	0711                	addi	a4,a4,4
    800061bc:	25548063          	beq	s1,s5,800063fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061c2:	0001f697          	auipc	a3,0x1f
    800061c6:	e5668693          	addi	a3,a3,-426 # 80025018 <disk+0x2018>
    800061ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061cc:	0006c583          	lbu	a1,0(a3)
    800061d0:	fde1                	bnez	a1,800061a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061d2:	2785                	addiw	a5,a5,1
    800061d4:	0685                	addi	a3,a3,1
    800061d6:	ff879be3          	bne	a5,s8,800061cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061da:	57fd                	li	a5,-1
    800061dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061de:	02905a63          	blez	s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061e2:	f9042503          	lw	a0,-112(s0)
    800061e6:	00000097          	auipc	ra,0x0
    800061ea:	d90080e7          	jalr	-624(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061ee:	4785                	li	a5,1
    800061f0:	0297d163          	bge	a5,s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f4:	f9442503          	lw	a0,-108(s0)
    800061f8:	00000097          	auipc	ra,0x0
    800061fc:	d7e080e7          	jalr	-642(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006200:	4789                	li	a5,2
    80006202:	0097d863          	bge	a5,s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006206:	f9842503          	lw	a0,-104(s0)
    8000620a:	00000097          	auipc	ra,0x0
    8000620e:	d6c080e7          	jalr	-660(ra) # 80005f76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006212:	0001f597          	auipc	a1,0x1f
    80006216:	f1658593          	addi	a1,a1,-234 # 80025128 <disk+0x2128>
    8000621a:	0001f517          	auipc	a0,0x1f
    8000621e:	dfe50513          	addi	a0,a0,-514 # 80025018 <disk+0x2018>
    80006222:	ffffc097          	auipc	ra,0xffffc
    80006226:	102080e7          	jalr	258(ra) # 80002324 <sleep>
  for(int i = 0; i < 3; i++){
    8000622a:	f9040713          	addi	a4,s0,-112
    8000622e:	84ce                	mv	s1,s3
    80006230:	bf41                	j	800061c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006232:	20058713          	addi	a4,a1,512
    80006236:	00471693          	slli	a3,a4,0x4
    8000623a:	0001d717          	auipc	a4,0x1d
    8000623e:	dc670713          	addi	a4,a4,-570 # 80023000 <disk>
    80006242:	9736                	add	a4,a4,a3
    80006244:	4685                	li	a3,1
    80006246:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000624a:	20058713          	addi	a4,a1,512
    8000624e:	00471693          	slli	a3,a4,0x4
    80006252:	0001d717          	auipc	a4,0x1d
    80006256:	dae70713          	addi	a4,a4,-594 # 80023000 <disk>
    8000625a:	9736                	add	a4,a4,a3
    8000625c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006260:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006264:	7679                	lui	a2,0xffffe
    80006266:	963e                	add	a2,a2,a5
    80006268:	0001f697          	auipc	a3,0x1f
    8000626c:	d9868693          	addi	a3,a3,-616 # 80025000 <disk+0x2000>
    80006270:	6298                	ld	a4,0(a3)
    80006272:	9732                	add	a4,a4,a2
    80006274:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006276:	6298                	ld	a4,0(a3)
    80006278:	9732                	add	a4,a4,a2
    8000627a:	4541                	li	a0,16
    8000627c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000627e:	6298                	ld	a4,0(a3)
    80006280:	9732                	add	a4,a4,a2
    80006282:	4505                	li	a0,1
    80006284:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006288:	f9442703          	lw	a4,-108(s0)
    8000628c:	6288                	ld	a0,0(a3)
    8000628e:	962a                	add	a2,a2,a0
    80006290:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006294:	0712                	slli	a4,a4,0x4
    80006296:	6290                	ld	a2,0(a3)
    80006298:	963a                	add	a2,a2,a4
    8000629a:	05890513          	addi	a0,s2,88
    8000629e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062a0:	6294                	ld	a3,0(a3)
    800062a2:	96ba                	add	a3,a3,a4
    800062a4:	40000613          	li	a2,1024
    800062a8:	c690                	sw	a2,8(a3)
  if(write)
    800062aa:	140d0063          	beqz	s10,800063ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ae:	0001f697          	auipc	a3,0x1f
    800062b2:	d526b683          	ld	a3,-686(a3) # 80025000 <disk+0x2000>
    800062b6:	96ba                	add	a3,a3,a4
    800062b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062bc:	0001d817          	auipc	a6,0x1d
    800062c0:	d4480813          	addi	a6,a6,-700 # 80023000 <disk>
    800062c4:	0001f517          	auipc	a0,0x1f
    800062c8:	d3c50513          	addi	a0,a0,-708 # 80025000 <disk+0x2000>
    800062cc:	6114                	ld	a3,0(a0)
    800062ce:	96ba                	add	a3,a3,a4
    800062d0:	00c6d603          	lhu	a2,12(a3)
    800062d4:	00166613          	ori	a2,a2,1
    800062d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062dc:	f9842683          	lw	a3,-104(s0)
    800062e0:	6110                	ld	a2,0(a0)
    800062e2:	9732                	add	a4,a4,a2
    800062e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062e8:	20058613          	addi	a2,a1,512
    800062ec:	0612                	slli	a2,a2,0x4
    800062ee:	9642                	add	a2,a2,a6
    800062f0:	577d                	li	a4,-1
    800062f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062f6:	00469713          	slli	a4,a3,0x4
    800062fa:	6114                	ld	a3,0(a0)
    800062fc:	96ba                	add	a3,a3,a4
    800062fe:	03078793          	addi	a5,a5,48
    80006302:	97c2                	add	a5,a5,a6
    80006304:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006306:	611c                	ld	a5,0(a0)
    80006308:	97ba                	add	a5,a5,a4
    8000630a:	4685                	li	a3,1
    8000630c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000630e:	611c                	ld	a5,0(a0)
    80006310:	97ba                	add	a5,a5,a4
    80006312:	4809                	li	a6,2
    80006314:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006318:	611c                	ld	a5,0(a0)
    8000631a:	973e                	add	a4,a4,a5
    8000631c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006320:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006324:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006328:	6518                	ld	a4,8(a0)
    8000632a:	00275783          	lhu	a5,2(a4)
    8000632e:	8b9d                	andi	a5,a5,7
    80006330:	0786                	slli	a5,a5,0x1
    80006332:	97ba                	add	a5,a5,a4
    80006334:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006338:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000633c:	6518                	ld	a4,8(a0)
    8000633e:	00275783          	lhu	a5,2(a4)
    80006342:	2785                	addiw	a5,a5,1
    80006344:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006348:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006354:	00492703          	lw	a4,4(s2)
    80006358:	4785                	li	a5,1
    8000635a:	02f71163          	bne	a4,a5,8000637c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000635e:	0001f997          	auipc	s3,0x1f
    80006362:	dca98993          	addi	s3,s3,-566 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006366:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006368:	85ce                	mv	a1,s3
    8000636a:	854a                	mv	a0,s2
    8000636c:	ffffc097          	auipc	ra,0xffffc
    80006370:	fb8080e7          	jalr	-72(ra) # 80002324 <sleep>
  while(b->disk == 1) {
    80006374:	00492783          	lw	a5,4(s2)
    80006378:	fe9788e3          	beq	a5,s1,80006368 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000637c:	f9042903          	lw	s2,-112(s0)
    80006380:	20090793          	addi	a5,s2,512
    80006384:	00479713          	slli	a4,a5,0x4
    80006388:	0001d797          	auipc	a5,0x1d
    8000638c:	c7878793          	addi	a5,a5,-904 # 80023000 <disk>
    80006390:	97ba                	add	a5,a5,a4
    80006392:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006396:	0001f997          	auipc	s3,0x1f
    8000639a:	c6a98993          	addi	s3,s3,-918 # 80025000 <disk+0x2000>
    8000639e:	00491713          	slli	a4,s2,0x4
    800063a2:	0009b783          	ld	a5,0(s3)
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063ac:	854a                	mv	a0,s2
    800063ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063b2:	00000097          	auipc	ra,0x0
    800063b6:	bc4080e7          	jalr	-1084(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ba:	8885                	andi	s1,s1,1
    800063bc:	f0ed                	bnez	s1,8000639e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063be:	0001f517          	auipc	a0,0x1f
    800063c2:	d6a50513          	addi	a0,a0,-662 # 80025128 <disk+0x2128>
    800063c6:	ffffb097          	auipc	ra,0xffffb
    800063ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
}
    800063ce:	70a6                	ld	ra,104(sp)
    800063d0:	7406                	ld	s0,96(sp)
    800063d2:	64e6                	ld	s1,88(sp)
    800063d4:	6946                	ld	s2,80(sp)
    800063d6:	69a6                	ld	s3,72(sp)
    800063d8:	6a06                	ld	s4,64(sp)
    800063da:	7ae2                	ld	s5,56(sp)
    800063dc:	7b42                	ld	s6,48(sp)
    800063de:	7ba2                	ld	s7,40(sp)
    800063e0:	7c02                	ld	s8,32(sp)
    800063e2:	6ce2                	ld	s9,24(sp)
    800063e4:	6d42                	ld	s10,16(sp)
    800063e6:	6165                	addi	sp,sp,112
    800063e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ea:	0001f697          	auipc	a3,0x1f
    800063ee:	c166b683          	ld	a3,-1002(a3) # 80025000 <disk+0x2000>
    800063f2:	96ba                	add	a3,a3,a4
    800063f4:	4609                	li	a2,2
    800063f6:	00c69623          	sh	a2,12(a3)
    800063fa:	b5c9                	j	800062bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063fc:	f9042583          	lw	a1,-112(s0)
    80006400:	20058793          	addi	a5,a1,512
    80006404:	0792                	slli	a5,a5,0x4
    80006406:	0001d517          	auipc	a0,0x1d
    8000640a:	ca250513          	addi	a0,a0,-862 # 800230a8 <disk+0xa8>
    8000640e:	953e                	add	a0,a0,a5
  if(write)
    80006410:	e20d11e3          	bnez	s10,80006232 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006414:	20058713          	addi	a4,a1,512
    80006418:	00471693          	slli	a3,a4,0x4
    8000641c:	0001d717          	auipc	a4,0x1d
    80006420:	be470713          	addi	a4,a4,-1052 # 80023000 <disk>
    80006424:	9736                	add	a4,a4,a3
    80006426:	0a072423          	sw	zero,168(a4)
    8000642a:	b505                	j	8000624a <virtio_disk_rw+0xf4>

000000008000642c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000642c:	1101                	addi	sp,sp,-32
    8000642e:	ec06                	sd	ra,24(sp)
    80006430:	e822                	sd	s0,16(sp)
    80006432:	e426                	sd	s1,8(sp)
    80006434:	e04a                	sd	s2,0(sp)
    80006436:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006438:	0001f517          	auipc	a0,0x1f
    8000643c:	cf050513          	addi	a0,a0,-784 # 80025128 <disk+0x2128>
    80006440:	ffffa097          	auipc	ra,0xffffa
    80006444:	7a4080e7          	jalr	1956(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006448:	10001737          	lui	a4,0x10001
    8000644c:	533c                	lw	a5,96(a4)
    8000644e:	8b8d                	andi	a5,a5,3
    80006450:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006452:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006456:	0001f797          	auipc	a5,0x1f
    8000645a:	baa78793          	addi	a5,a5,-1110 # 80025000 <disk+0x2000>
    8000645e:	6b94                	ld	a3,16(a5)
    80006460:	0207d703          	lhu	a4,32(a5)
    80006464:	0026d783          	lhu	a5,2(a3)
    80006468:	06f70163          	beq	a4,a5,800064ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000646c:	0001d917          	auipc	s2,0x1d
    80006470:	b9490913          	addi	s2,s2,-1132 # 80023000 <disk>
    80006474:	0001f497          	auipc	s1,0x1f
    80006478:	b8c48493          	addi	s1,s1,-1140 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000647c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006480:	6898                	ld	a4,16(s1)
    80006482:	0204d783          	lhu	a5,32(s1)
    80006486:	8b9d                	andi	a5,a5,7
    80006488:	078e                	slli	a5,a5,0x3
    8000648a:	97ba                	add	a5,a5,a4
    8000648c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000648e:	20078713          	addi	a4,a5,512
    80006492:	0712                	slli	a4,a4,0x4
    80006494:	974a                	add	a4,a4,s2
    80006496:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000649a:	e731                	bnez	a4,800064e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000649c:	20078793          	addi	a5,a5,512
    800064a0:	0792                	slli	a5,a5,0x4
    800064a2:	97ca                	add	a5,a5,s2
    800064a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064aa:	ffffc097          	auipc	ra,0xffffc
    800064ae:	020080e7          	jalr	32(ra) # 800024ca <wakeup>

    disk.used_idx += 1;
    800064b2:	0204d783          	lhu	a5,32(s1)
    800064b6:	2785                	addiw	a5,a5,1
    800064b8:	17c2                	slli	a5,a5,0x30
    800064ba:	93c1                	srli	a5,a5,0x30
    800064bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064c0:	6898                	ld	a4,16(s1)
    800064c2:	00275703          	lhu	a4,2(a4)
    800064c6:	faf71be3          	bne	a4,a5,8000647c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	c5e50513          	addi	a0,a0,-930 # 80025128 <disk+0x2128>
    800064d2:	ffffa097          	auipc	ra,0xffffa
    800064d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
}
    800064da:	60e2                	ld	ra,24(sp)
    800064dc:	6442                	ld	s0,16(sp)
    800064de:	64a2                	ld	s1,8(sp)
    800064e0:	6902                	ld	s2,0(sp)
    800064e2:	6105                	addi	sp,sp,32
    800064e4:	8082                	ret
      panic("virtio_disk_intr status");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	3ca50513          	addi	a0,a0,970 # 800088b0 <syscalls+0x3c8>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
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
