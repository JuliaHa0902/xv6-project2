
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	e8e78793          	addi	a5,a5,-370 # 80005ef0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4d0080e7          	jalr	1232(ra) # 800025fa <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	880080e7          	jalr	-1920(ra) # 80001a40 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	030080e7          	jalr	48(ra) # 80002200 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	398080e7          	jalr	920(ra) # 800025a4 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	364080e7          	jalr	868(ra) # 80002650 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	f4c080e7          	jalr	-180(ra) # 8000238c <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bce58593          	addi	a1,a1,-1074 # 80008020 <etext+0x20>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	2a678793          	addi	a5,a5,678 # 80021718 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b9c60613          	addi	a2,a2,-1124 # 80008050 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	ada50513          	addi	a0,a0,-1318 # 80008028 <etext+0x28>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b7050513          	addi	a0,a0,-1168 # 800080d8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a6eb0b13          	addi	s6,s6,-1426 # 80008050 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a3250513          	addi	a0,a0,-1486 # 80008038 <etext+0x38>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	93048493          	addi	s1,s1,-1744 # 80008030 <etext+0x30>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8d258593          	addi	a1,a1,-1838 # 80008048 <etext+0x48>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	8a258593          	addi	a1,a1,-1886 # 80008068 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	afe080e7          	jalr	-1282(ra) # 8000238c <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	8e6080e7          	jalr	-1818(ra) # 80002200 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	62850513          	addi	a0,a0,1576 # 80008070 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5cc58593          	addi	a1,a1,1484 # 80008078 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	eba080e7          	jalr	-326(ra) # 80001a24 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	e88080e7          	jalr	-376(ra) # 80001a24 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	e7c080e7          	jalr	-388(ra) # 80001a24 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	e64080e7          	jalr	-412(ra) # 80001a24 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	e24080e7          	jalr	-476(ra) # 80001a24 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	46c50513          	addi	a0,a0,1132 # 80008080 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	df8080e7          	jalr	-520(ra) # 80001a24 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	42450513          	addi	a0,a0,1060 # 80008088 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	42c50513          	addi	a0,a0,1068 # 800080a0 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3ec50513          	addi	a0,a0,1004 # 800080a8 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b9a080e7          	jalr	-1126(ra) # 80001a14 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b7e080e7          	jalr	-1154(ra) # 80001a14 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	22850513          	addi	a0,a0,552 # 800080c8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	a88080e7          	jalr	-1400(ra) # 80002940 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	070080e7          	jalr	112(ra) # 80005f30 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	09a080e7          	jalr	154(ra) # 80001f62 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1f850513          	addi	a0,a0,504 # 800080d8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1c050513          	addi	a0,a0,448 # 800080b0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1d850513          	addi	a0,a0,472 # 800080d8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	a3c080e7          	jalr	-1476(ra) # 80001964 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	9e8080e7          	jalr	-1560(ra) # 80002918 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	a08080e7          	jalr	-1528(ra) # 80002940 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	fda080e7          	jalr	-38(ra) # 80005f1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	fe8080e7          	jalr	-24(ra) # 80005f30 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	1ae080e7          	jalr	430(ra) # 800030fe <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	83c080e7          	jalr	-1988(ra) # 80003794 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	7ee080e7          	jalr	2030(ra) # 8000474e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	0e8080e7          	jalr	232(ra) # 80006050 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	db8080e7          	jalr	-584(ra) # 80001d28 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	10e50513          	addi	a0,a0,270 # 800080e0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	ff050513          	addi	a0,a0,-16 # 800080e8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	ff050513          	addi	a0,a0,-16 # 800080f8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fb450513          	addi	a0,a0,-76 # 80008108 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	6aa080e7          	jalr	1706(ra) # 800018ce <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e7050513          	addi	a0,a0,-400 # 80008110 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e7850513          	addi	a0,a0,-392 # 80008128 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e7850513          	addi	a0,a0,-392 # 80008138 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e8050513          	addi	a0,a0,-384 # 80008150 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	dba50513          	addi	a0,a0,-582 # 80008168 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c9650513          	addi	a0,a0,-874 # 80008188 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bc850513          	addi	a0,a0,-1080 # 80008198 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bd850513          	addi	a0,a0,-1064 # 800081b8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b8e50513          	addi	a0,a0,-1138 # 800081d8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <rand>:

static uint32_t z1 = SEED, z2 = SEED, z3 = SEED, z4 = SEED;


double rand (void)
{
    80001824:	1141                	addi	sp,sp,-16
    80001826:	e422                	sd	s0,8(sp)
    80001828:	0800                	addi	s0,sp,16
   uint32_t b;
   b  = ((z1 << 6) ^ z1) >> 13;
    8000182a:	00007697          	auipc	a3,0x7
    8000182e:	0fa68693          	addi	a3,a3,250 # 80008924 <z1>
    80001832:	429c                	lw	a5,0(a3)
    80001834:	0067971b          	slliw	a4,a5,0x6
    80001838:	8f3d                	xor	a4,a4,a5
    8000183a:	00d7571b          	srliw	a4,a4,0xd
   z1 = ((z1 & 4294967294U) << 18) ^ b;
    8000183e:	0127961b          	slliw	a2,a5,0x12
    80001842:	fff807b7          	lui	a5,0xfff80
    80001846:	8e7d                	and	a2,a2,a5
    80001848:	8e39                	xor	a2,a2,a4
    8000184a:	2601                	sext.w	a2,a2
    8000184c:	c290                	sw	a2,0(a3)
   b  = ((z2 << 2) ^ z2) >> 27;
    8000184e:	00007717          	auipc	a4,0x7
    80001852:	0d270713          	addi	a4,a4,210 # 80008920 <z2>
    80001856:	431c                	lw	a5,0(a4)
    80001858:	0027969b          	slliw	a3,a5,0x2
    8000185c:	8fb5                	xor	a5,a5,a3
    8000185e:	01b7d79b          	srliw	a5,a5,0x1b
   z2 = ((z2 & 4294967288U) << 2) ^ b;
    80001862:	9a81                	andi	a3,a3,-32
    80001864:	8ebd                	xor	a3,a3,a5
    80001866:	2681                	sext.w	a3,a3
    80001868:	c314                	sw	a3,0(a4)
   b  = ((z3 << 13) ^ z3) >> 21;
    8000186a:	00007517          	auipc	a0,0x7
    8000186e:	0b250513          	addi	a0,a0,178 # 8000891c <z3>
    80001872:	411c                	lw	a5,0(a0)
    80001874:	00d7959b          	slliw	a1,a5,0xd
    80001878:	8dbd                	xor	a1,a1,a5
    8000187a:	0155d59b          	srliw	a1,a1,0x15
   z3 = ((z3 & 4294967280U) << 7) ^ b;
    8000187e:	0077971b          	slliw	a4,a5,0x7
    80001882:	80077713          	andi	a4,a4,-2048
    80001886:	8f2d                	xor	a4,a4,a1
    80001888:	2701                	sext.w	a4,a4
    8000188a:	c118                	sw	a4,0(a0)
   b  = ((z4 << 3) ^ z4) >> 12;
    8000188c:	00007517          	auipc	a0,0x7
    80001890:	08c50513          	addi	a0,a0,140 # 80008918 <z4>
    80001894:	411c                	lw	a5,0(a0)
    80001896:	0037959b          	slliw	a1,a5,0x3
    8000189a:	8dbd                	xor	a1,a1,a5
    8000189c:	00c5d59b          	srliw	a1,a1,0xc
   z4 = ((z4 & 4294967168U) << 13) ^ b;
    800018a0:	00d7979b          	slliw	a5,a5,0xd
    800018a4:	fff00837          	lui	a6,0xfff00
    800018a8:	0107f7b3          	and	a5,a5,a6
    800018ac:	8fad                	xor	a5,a5,a1
    800018ae:	2781                	sext.w	a5,a5
    800018b0:	c11c                	sw	a5,0(a0)
   return (z1 ^ z2 ^ z3 ^ z4) * 2.3283064365386963e-10;
    800018b2:	8e35                	xor	a2,a2,a3
    800018b4:	8e39                	xor	a2,a2,a4
    800018b6:	8e3d                	xor	a2,a2,a5
    800018b8:	d2160553          	fcvt.d.wu	fa0,a2
    800018bc:	00006797          	auipc	a5,0x6
    800018c0:	7447b787          	fld	fa5,1860(a5) # 80008000 <etext>
}
    800018c4:	12f57553          	fmul.d	fa0,fa0,fa5
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018ce:	7139                	addi	sp,sp,-64
    800018d0:	fc06                	sd	ra,56(sp)
    800018d2:	f822                	sd	s0,48(sp)
    800018d4:	f426                	sd	s1,40(sp)
    800018d6:	f04a                	sd	s2,32(sp)
    800018d8:	ec4e                	sd	s3,24(sp)
    800018da:	e852                	sd	s4,16(sp)
    800018dc:	e456                	sd	s5,8(sp)
    800018de:	e05a                	sd	s6,0(sp)
    800018e0:	0080                	addi	s0,sp,64
    800018e2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e4:	00010497          	auipc	s1,0x10
    800018e8:	dec48493          	addi	s1,s1,-532 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018ec:	8b26                	mv	s6,s1
    800018ee:	00006a97          	auipc	s5,0x6
    800018f2:	71aa8a93          	addi	s5,s5,1818 # 80008008 <etext+0x8>
    800018f6:	04000937          	lui	s2,0x4000
    800018fa:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018fc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00016a17          	auipc	s4,0x16
    80001902:	bd2a0a13          	addi	s4,s4,-1070 # 800174d0 <tickslock>
    char *pa = kalloc();
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	1da080e7          	jalr	474(ra) # 80000ae0 <kalloc>
    8000190e:	862a                	mv	a2,a0
    if(pa == 0)
    80001910:	c131                	beqz	a0,80001954 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001912:	416485b3          	sub	a1,s1,s6
    80001916:	858d                	srai	a1,a1,0x3
    80001918:	000ab783          	ld	a5,0(s5)
    8000191c:	02f585b3          	mul	a1,a1,a5
    80001920:	2585                	addiw	a1,a1,1
    80001922:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001926:	4719                	li	a4,6
    80001928:	6685                	lui	a3,0x1
    8000192a:	40b905b3          	sub	a1,s2,a1
    8000192e:	854e                	mv	a0,s3
    80001930:	00000097          	auipc	ra,0x0
    80001934:	804080e7          	jalr	-2044(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001938:	17848493          	addi	s1,s1,376
    8000193c:	fd4495e3          	bne	s1,s4,80001906 <proc_mapstacks+0x38>
  }
}
    80001940:	70e2                	ld	ra,56(sp)
    80001942:	7442                	ld	s0,48(sp)
    80001944:	74a2                	ld	s1,40(sp)
    80001946:	7902                	ld	s2,32(sp)
    80001948:	69e2                	ld	s3,24(sp)
    8000194a:	6a42                	ld	s4,16(sp)
    8000194c:	6aa2                	ld	s5,8(sp)
    8000194e:	6b02                	ld	s6,0(sp)
    80001950:	6121                	addi	sp,sp,64
    80001952:	8082                	ret
      panic("kalloc");
    80001954:	00007517          	auipc	a0,0x7
    80001958:	89450513          	addi	a0,a0,-1900 # 800081e8 <digits+0x198>
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	bde080e7          	jalr	-1058(ra) # 8000053a <panic>

0000000080001964 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001964:	7139                	addi	sp,sp,-64
    80001966:	fc06                	sd	ra,56(sp)
    80001968:	f822                	sd	s0,48(sp)
    8000196a:	f426                	sd	s1,40(sp)
    8000196c:	f04a                	sd	s2,32(sp)
    8000196e:	ec4e                	sd	s3,24(sp)
    80001970:	e852                	sd	s4,16(sp)
    80001972:	e456                	sd	s5,8(sp)
    80001974:	e05a                	sd	s6,0(sp)
    80001976:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001978:	00007597          	auipc	a1,0x7
    8000197c:	87858593          	addi	a1,a1,-1928 # 800081f0 <digits+0x1a0>
    80001980:	00010517          	auipc	a0,0x10
    80001984:	92050513          	addi	a0,a0,-1760 # 800112a0 <pid_lock>
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1b8080e7          	jalr	440(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	86858593          	addi	a1,a1,-1944 # 800081f8 <digits+0x1a8>
    80001998:	00010517          	auipc	a0,0x10
    8000199c:	92050513          	addi	a0,a0,-1760 # 800112b8 <wait_lock>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1a0080e7          	jalr	416(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a8:	00010497          	auipc	s1,0x10
    800019ac:	d2848493          	addi	s1,s1,-728 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800019b0:	00007b17          	auipc	s6,0x7
    800019b4:	858b0b13          	addi	s6,s6,-1960 # 80008208 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    800019b8:	8aa6                	mv	s5,s1
    800019ba:	00006a17          	auipc	s4,0x6
    800019be:	64ea0a13          	addi	s4,s4,1614 # 80008008 <etext+0x8>
    800019c2:	04000937          	lui	s2,0x4000
    800019c6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019c8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ca:	00016997          	auipc	s3,0x16
    800019ce:	b0698993          	addi	s3,s3,-1274 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    800019d2:	85da                	mv	a1,s6
    800019d4:	8526                	mv	a0,s1
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	16a080e7          	jalr	362(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019de:	415487b3          	sub	a5,s1,s5
    800019e2:	878d                	srai	a5,a5,0x3
    800019e4:	000a3703          	ld	a4,0(s4)
    800019e8:	02e787b3          	mul	a5,a5,a4
    800019ec:	2785                	addiw	a5,a5,1
    800019ee:	00d7979b          	slliw	a5,a5,0xd
    800019f2:	40f907b3          	sub	a5,s2,a5
    800019f6:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f8:	17848493          	addi	s1,s1,376
    800019fc:	fd349be3          	bne	s1,s3,800019d2 <procinit+0x6e>
  }
}
    80001a00:	70e2                	ld	ra,56(sp)
    80001a02:	7442                	ld	s0,48(sp)
    80001a04:	74a2                	ld	s1,40(sp)
    80001a06:	7902                	ld	s2,32(sp)
    80001a08:	69e2                	ld	s3,24(sp)
    80001a0a:	6a42                	ld	s4,16(sp)
    80001a0c:	6aa2                	ld	s5,8(sp)
    80001a0e:	6b02                	ld	s6,0(sp)
    80001a10:	6121                	addi	sp,sp,64
    80001a12:	8082                	ret

0000000080001a14 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e422                	sd	s0,8(sp)
    80001a18:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a1a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a1c:	2501                	sext.w	a0,a0
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a24:	1141                	addi	sp,sp,-16
    80001a26:	e422                	sd	s0,8(sp)
    80001a28:	0800                	addi	s0,sp,16
    80001a2a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a2c:	2781                	sext.w	a5,a5
    80001a2e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a30:	00010517          	auipc	a0,0x10
    80001a34:	8a050513          	addi	a0,a0,-1888 # 800112d0 <cpus>
    80001a38:	953e                	add	a0,a0,a5
    80001a3a:	6422                	ld	s0,8(sp)
    80001a3c:	0141                	addi	sp,sp,16
    80001a3e:	8082                	ret

0000000080001a40 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a40:	1101                	addi	sp,sp,-32
    80001a42:	ec06                	sd	ra,24(sp)
    80001a44:	e822                	sd	s0,16(sp)
    80001a46:	e426                	sd	s1,8(sp)
    80001a48:	1000                	addi	s0,sp,32
  push_off();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	13a080e7          	jalr	314(ra) # 80000b84 <push_off>
    80001a52:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a54:	2781                	sext.w	a5,a5
    80001a56:	079e                	slli	a5,a5,0x7
    80001a58:	00010717          	auipc	a4,0x10
    80001a5c:	84870713          	addi	a4,a4,-1976 # 800112a0 <pid_lock>
    80001a60:	97ba                	add	a5,a5,a4
    80001a62:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	1c0080e7          	jalr	448(ra) # 80000c24 <pop_off>
  return p;
}
    80001a6c:	8526                	mv	a0,s1
    80001a6e:	60e2                	ld	ra,24(sp)
    80001a70:	6442                	ld	s0,16(sp)
    80001a72:	64a2                	ld	s1,8(sp)
    80001a74:	6105                	addi	sp,sp,32
    80001a76:	8082                	ret

0000000080001a78 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a78:	1141                	addi	sp,sp,-16
    80001a7a:	e406                	sd	ra,8(sp)
    80001a7c:	e022                	sd	s0,0(sp)
    80001a7e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a80:	00000097          	auipc	ra,0x0
    80001a84:	fc0080e7          	jalr	-64(ra) # 80001a40 <myproc>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	1fc080e7          	jalr	508(ra) # 80000c84 <release>

  if (first) {
    80001a90:	00007797          	auipc	a5,0x7
    80001a94:	e807a783          	lw	a5,-384(a5) # 80008910 <first.2>
    80001a98:	eb89                	bnez	a5,80001aaa <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a9a:	00001097          	auipc	ra,0x1
    80001a9e:	ebe080e7          	jalr	-322(ra) # 80002958 <usertrapret>
}
    80001aa2:	60a2                	ld	ra,8(sp)
    80001aa4:	6402                	ld	s0,0(sp)
    80001aa6:	0141                	addi	sp,sp,16
    80001aa8:	8082                	ret
    first = 0;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	e607a323          	sw	zero,-410(a5) # 80008910 <first.2>
    fsinit(ROOTDEV);
    80001ab2:	4505                	li	a0,1
    80001ab4:	00002097          	auipc	ra,0x2
    80001ab8:	c60080e7          	jalr	-928(ra) # 80003714 <fsinit>
    80001abc:	bff9                	j	80001a9a <forkret+0x22>

0000000080001abe <allocpid>:
allocpid() {
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	e04a                	sd	s2,0(sp)
    80001ac8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aca:	0000f917          	auipc	s2,0xf
    80001ace:	7d690913          	addi	s2,s2,2006 # 800112a0 <pid_lock>
    80001ad2:	854a                	mv	a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	0fc080e7          	jalr	252(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001adc:	00007797          	auipc	a5,0x7
    80001ae0:	e3878793          	addi	a5,a5,-456 # 80008914 <nextpid>
    80001ae4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae6:	0014871b          	addiw	a4,s1,1
    80001aea:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aec:	854a                	mv	a0,s2
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	196080e7          	jalr	406(ra) # 80000c84 <release>
}
    80001af6:	8526                	mv	a0,s1
    80001af8:	60e2                	ld	ra,24(sp)
    80001afa:	6442                	ld	s0,16(sp)
    80001afc:	64a2                	ld	s1,8(sp)
    80001afe:	6902                	ld	s2,0(sp)
    80001b00:	6105                	addi	sp,sp,32
    80001b02:	8082                	ret

0000000080001b04 <proc_pagetable>:
{
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	addi	s0,sp,32
    80001b10:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	80c080e7          	jalr	-2036(ra) # 8000131e <uvmcreate>
    80001b1a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1c:	c121                	beqz	a0,80001b5c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b1e:	4729                	li	a4,10
    80001b20:	00005697          	auipc	a3,0x5
    80001b24:	4e068693          	addi	a3,a3,1248 # 80007000 <_trampoline>
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	040005b7          	lui	a1,0x4000
    80001b2e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b30:	05b2                	slli	a1,a1,0xc
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	562080e7          	jalr	1378(ra) # 80001094 <mappages>
    80001b3a:	02054863          	bltz	a0,80001b6a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b3e:	4719                	li	a4,6
    80001b40:	05893683          	ld	a3,88(s2)
    80001b44:	6605                	lui	a2,0x1
    80001b46:	020005b7          	lui	a1,0x2000
    80001b4a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b4c:	05b6                	slli	a1,a1,0xd
    80001b4e:	8526                	mv	a0,s1
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	544080e7          	jalr	1348(ra) # 80001094 <mappages>
    80001b58:	02054163          	bltz	a0,80001b7a <proc_pagetable+0x76>
}
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6a:	4581                	li	a1,0
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	9ae080e7          	jalr	-1618(ra) # 8000151c <uvmfree>
    return 0;
    80001b76:	4481                	li	s1,0
    80001b78:	b7d5                	j	80001b5c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	040005b7          	lui	a1,0x4000
    80001b82:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b84:	05b2                	slli	a1,a1,0xc
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	6d2080e7          	jalr	1746(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b90:	4581                	li	a1,0
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	988080e7          	jalr	-1656(ra) # 8000151c <uvmfree>
    return 0;
    80001b9c:	4481                	li	s1,0
    80001b9e:	bf7d                	j	80001b5c <proc_pagetable+0x58>

0000000080001ba0 <proc_freepagetable>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
    80001bac:	84aa                	mv	s1,a0
    80001bae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb0:	4681                	li	a3,0
    80001bb2:	4605                	li	a2,1
    80001bb4:	040005b7          	lui	a1,0x4000
    80001bb8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bba:	05b2                	slli	a1,a1,0xc
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	69e080e7          	jalr	1694(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	4605                	li	a2,1
    80001bc8:	020005b7          	lui	a1,0x2000
    80001bcc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bce:	05b6                	slli	a1,a1,0xd
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	688080e7          	jalr	1672(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001bda:	85ca                	mv	a1,s2
    80001bdc:	8526                	mv	a0,s1
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	93e080e7          	jalr	-1730(ra) # 8000151c <uvmfree>
}
    80001be6:	60e2                	ld	ra,24(sp)
    80001be8:	6442                	ld	s0,16(sp)
    80001bea:	64a2                	ld	s1,8(sp)
    80001bec:	6902                	ld	s2,0(sp)
    80001bee:	6105                	addi	sp,sp,32
    80001bf0:	8082                	ret

0000000080001bf2 <freeproc>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	1000                	addi	s0,sp,32
    80001bfc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bfe:	6d28                	ld	a0,88(a0)
    80001c00:	c509                	beqz	a0,80001c0a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	de0080e7          	jalr	-544(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001c0a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0e:	68a8                	ld	a0,80(s1)
    80001c10:	c511                	beqz	a0,80001c1c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c12:	64ac                	ld	a1,72(s1)
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	f8c080e7          	jalr	-116(ra) # 80001ba0 <proc_freepagetable>
  p->pagetable = 0;
    80001c1c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c20:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c24:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c28:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c2c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c30:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c34:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c38:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c3c:	0004ac23          	sw	zero,24(s1)
}
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <allocproc>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	e04a                	sd	s2,0(sp)
    80001c54:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c56:	00010497          	auipc	s1,0x10
    80001c5a:	a7a48493          	addi	s1,s1,-1414 # 800116d0 <proc>
    80001c5e:	00016917          	auipc	s2,0x16
    80001c62:	87290913          	addi	s2,s2,-1934 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	f68080e7          	jalr	-152(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001c70:	4c9c                	lw	a5,24(s1)
    80001c72:	cf81                	beqz	a5,80001c8a <allocproc+0x40>
      release(&p->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	00e080e7          	jalr	14(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c7e:	17848493          	addi	s1,s1,376
    80001c82:	ff2492e3          	bne	s1,s2,80001c66 <allocproc+0x1c>
  return 0;
    80001c86:	4481                	li	s1,0
    80001c88:	a08d                	j	80001cea <allocproc+0xa0>
  p->pid = allocpid();
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e34080e7          	jalr	-460(ra) # 80001abe <allocpid>
    80001c92:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c94:	4785                	li	a5,1
    80001c96:	cc9c                	sw	a5,24(s1)
  p->in_queue = HIGH;
    80001c98:	1604aa23          	sw	zero,372(s1)
  p->hticks = 0;
    80001c9c:	1604a423          	sw	zero,360(s1)
  p->lticks = 0;
    80001ca0:	1604a623          	sw	zero,364(s1)
  p->ticket = 0;
    80001ca4:	1604a823          	sw	zero,368(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	e38080e7          	jalr	-456(ra) # 80000ae0 <kalloc>
    80001cb0:	892a                	mv	s2,a0
    80001cb2:	eca8                	sd	a0,88(s1)
    80001cb4:	c131                	beqz	a0,80001cf8 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e4c080e7          	jalr	-436(ra) # 80001b04 <proc_pagetable>
    80001cc0:	892a                	mv	s2,a0
    80001cc2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc4:	c531                	beqz	a0,80001d10 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc6:	07000613          	li	a2,112
    80001cca:	4581                	li	a1,0
    80001ccc:	06048513          	addi	a0,s1,96
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	ffc080e7          	jalr	-4(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001cd8:	00000797          	auipc	a5,0x0
    80001cdc:	da078793          	addi	a5,a5,-608 # 80001a78 <forkret>
    80001ce0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce2:	60bc                	ld	a5,64(s1)
    80001ce4:	6705                	lui	a4,0x1
    80001ce6:	97ba                	add	a5,a5,a4
    80001ce8:	f4bc                	sd	a5,104(s1)
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    freeproc(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	ef8080e7          	jalr	-264(ra) # 80001bf2 <freeproc>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f80080e7          	jalr	-128(ra) # 80000c84 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	bff1                	j	80001cea <allocproc+0xa0>
    freeproc(p);
    80001d10:	8526                	mv	a0,s1
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	ee0080e7          	jalr	-288(ra) # 80001bf2 <freeproc>
    release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f68080e7          	jalr	-152(ra) # 80000c84 <release>
    return 0;
    80001d24:	84ca                	mv	s1,s2
    80001d26:	b7d1                	j	80001cea <allocproc+0xa0>

0000000080001d28 <userinit>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	f18080e7          	jalr	-232(ra) # 80001c4a <allocproc>
    80001d3a:	84aa                	mv	s1,a0
  initproc = p;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	2ea7b623          	sd	a0,748(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d44:	03400613          	li	a2,52
    80001d48:	00007597          	auipc	a1,0x7
    80001d4c:	be858593          	addi	a1,a1,-1048 # 80008930 <initcode>
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	5fa080e7          	jalr	1530(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001d5a:	6785                	lui	a5,0x1
    80001d5c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d5e:	6cb8                	ld	a4,88(s1)
    80001d60:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d64:	6cb8                	ld	a4,88(s1)
    80001d66:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d68:	4641                	li	a2,16
    80001d6a:	00006597          	auipc	a1,0x6
    80001d6e:	4a658593          	addi	a1,a1,1190 # 80008210 <digits+0x1c0>
    80001d72:	15848513          	addi	a0,s1,344
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	0a0080e7          	jalr	160(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d7e:	00006517          	auipc	a0,0x6
    80001d82:	4a250513          	addi	a0,a0,1186 # 80008220 <digits+0x1d0>
    80001d86:	00002097          	auipc	ra,0x2
    80001d8a:	3c4080e7          	jalr	964(ra) # 8000414a <namei>
    80001d8e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d92:	478d                	li	a5,3
    80001d94:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	eec080e7          	jalr	-276(ra) # 80000c84 <release>
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <growproc>:
{
    80001daa:	1101                	addi	sp,sp,-32
    80001dac:	ec06                	sd	ra,24(sp)
    80001dae:	e822                	sd	s0,16(sp)
    80001db0:	e426                	sd	s1,8(sp)
    80001db2:	e04a                	sd	s2,0(sp)
    80001db4:	1000                	addi	s0,sp,32
    80001db6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	c88080e7          	jalr	-888(ra) # 80001a40 <myproc>
    80001dc0:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc2:	652c                	ld	a1,72(a0)
    80001dc4:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001dc8:	00904f63          	bgtz	s1,80001de6 <growproc+0x3c>
  } else if(n < 0){
    80001dcc:	0204cd63          	bltz	s1,80001e06 <growproc+0x5c>
  p->sz = sz;
    80001dd0:	1782                	slli	a5,a5,0x20
    80001dd2:	9381                	srli	a5,a5,0x20
    80001dd4:	04f93423          	sd	a5,72(s2)
  return 0;
    80001dd8:	4501                	li	a0,0
}
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6902                	ld	s2,0(sp)
    80001de2:	6105                	addi	sp,sp,32
    80001de4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001de6:	00f4863b          	addw	a2,s1,a5
    80001dea:	1602                	slli	a2,a2,0x20
    80001dec:	9201                	srli	a2,a2,0x20
    80001dee:	1582                	slli	a1,a1,0x20
    80001df0:	9181                	srli	a1,a1,0x20
    80001df2:	6928                	ld	a0,80(a0)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	612080e7          	jalr	1554(ra) # 80001406 <uvmalloc>
    80001dfc:	0005079b          	sext.w	a5,a0
    80001e00:	fbe1                	bnez	a5,80001dd0 <growproc+0x26>
      return -1;
    80001e02:	557d                	li	a0,-1
    80001e04:	bfd9                	j	80001dda <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e06:	00f4863b          	addw	a2,s1,a5
    80001e0a:	1602                	slli	a2,a2,0x20
    80001e0c:	9201                	srli	a2,a2,0x20
    80001e0e:	1582                	slli	a1,a1,0x20
    80001e10:	9181                	srli	a1,a1,0x20
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	5aa080e7          	jalr	1450(ra) # 800013be <uvmdealloc>
    80001e1c:	0005079b          	sext.w	a5,a0
    80001e20:	bf45                	j	80001dd0 <growproc+0x26>

0000000080001e22 <fork>:
{
    80001e22:	7139                	addi	sp,sp,-64
    80001e24:	fc06                	sd	ra,56(sp)
    80001e26:	f822                	sd	s0,48(sp)
    80001e28:	f426                	sd	s1,40(sp)
    80001e2a:	f04a                	sd	s2,32(sp)
    80001e2c:	ec4e                	sd	s3,24(sp)
    80001e2e:	e852                	sd	s4,16(sp)
    80001e30:	e456                	sd	s5,8(sp)
    80001e32:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	c0c080e7          	jalr	-1012(ra) # 80001a40 <myproc>
    80001e3c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	e0c080e7          	jalr	-500(ra) # 80001c4a <allocproc>
    80001e46:	10050c63          	beqz	a0,80001f5e <fork+0x13c>
    80001e4a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e4c:	048ab603          	ld	a2,72(s5)
    80001e50:	692c                	ld	a1,80(a0)
    80001e52:	050ab503          	ld	a0,80(s5)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	700080e7          	jalr	1792(ra) # 80001556 <uvmcopy>
    80001e5e:	04054863          	bltz	a0,80001eae <fork+0x8c>
  np->sz = p->sz;
    80001e62:	048ab783          	ld	a5,72(s5)
    80001e66:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e6a:	058ab683          	ld	a3,88(s5)
    80001e6e:	87b6                	mv	a5,a3
    80001e70:	058a3703          	ld	a4,88(s4)
    80001e74:	12068693          	addi	a3,a3,288
    80001e78:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7c:	6788                	ld	a0,8(a5)
    80001e7e:	6b8c                	ld	a1,16(a5)
    80001e80:	6f90                	ld	a2,24(a5)
    80001e82:	01073023          	sd	a6,0(a4)
    80001e86:	e708                	sd	a0,8(a4)
    80001e88:	eb0c                	sd	a1,16(a4)
    80001e8a:	ef10                	sd	a2,24(a4)
    80001e8c:	02078793          	addi	a5,a5,32
    80001e90:	02070713          	addi	a4,a4,32
    80001e94:	fed792e3          	bne	a5,a3,80001e78 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e98:	058a3783          	ld	a5,88(s4)
    80001e9c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea0:	0d0a8493          	addi	s1,s5,208
    80001ea4:	0d0a0913          	addi	s2,s4,208
    80001ea8:	150a8993          	addi	s3,s5,336
    80001eac:	a00d                	j	80001ece <fork+0xac>
    freeproc(np);
    80001eae:	8552                	mv	a0,s4
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	d42080e7          	jalr	-702(ra) # 80001bf2 <freeproc>
    release(&np->lock);
    80001eb8:	8552                	mv	a0,s4
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dca080e7          	jalr	-566(ra) # 80000c84 <release>
    return -1;
    80001ec2:	597d                	li	s2,-1
    80001ec4:	a059                	j	80001f4a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001ec6:	04a1                	addi	s1,s1,8
    80001ec8:	0921                	addi	s2,s2,8
    80001eca:	01348b63          	beq	s1,s3,80001ee0 <fork+0xbe>
    if(p->ofile[i])
    80001ece:	6088                	ld	a0,0(s1)
    80001ed0:	d97d                	beqz	a0,80001ec6 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed2:	00003097          	auipc	ra,0x3
    80001ed6:	90e080e7          	jalr	-1778(ra) # 800047e0 <filedup>
    80001eda:	00a93023          	sd	a0,0(s2)
    80001ede:	b7e5                	j	80001ec6 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ee0:	150ab503          	ld	a0,336(s5)
    80001ee4:	00002097          	auipc	ra,0x2
    80001ee8:	a6c080e7          	jalr	-1428(ra) # 80003950 <idup>
    80001eec:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef0:	4641                	li	a2,16
    80001ef2:	158a8593          	addi	a1,s5,344
    80001ef6:	158a0513          	addi	a0,s4,344
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	f1c080e7          	jalr	-228(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f02:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f06:	8552                	mv	a0,s4
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7c080e7          	jalr	-644(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	3a848493          	addi	s1,s1,936 # 800112b8 <wait_lock>
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001f22:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d5c080e7          	jalr	-676(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001f30:	8552                	mv	a0,s4
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	c9e080e7          	jalr	-866(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001f3a:	478d                	li	a5,3
    80001f3c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f40:	8552                	mv	a0,s4
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d42080e7          	jalr	-702(ra) # 80000c84 <release>
}
    80001f4a:	854a                	mv	a0,s2
    80001f4c:	70e2                	ld	ra,56(sp)
    80001f4e:	7442                	ld	s0,48(sp)
    80001f50:	74a2                	ld	s1,40(sp)
    80001f52:	7902                	ld	s2,32(sp)
    80001f54:	69e2                	ld	s3,24(sp)
    80001f56:	6a42                	ld	s4,16(sp)
    80001f58:	6aa2                	ld	s5,8(sp)
    80001f5a:	6121                	addi	sp,sp,64
    80001f5c:	8082                	ret
    return -1;
    80001f5e:	597d                	li	s2,-1
    80001f60:	b7ed                	j	80001f4a <fork+0x128>

0000000080001f62 <scheduler>:
{
    80001f62:	7159                	addi	sp,sp,-112
    80001f64:	f486                	sd	ra,104(sp)
    80001f66:	f0a2                	sd	s0,96(sp)
    80001f68:	eca6                	sd	s1,88(sp)
    80001f6a:	e8ca                	sd	s2,80(sp)
    80001f6c:	e4ce                	sd	s3,72(sp)
    80001f6e:	e0d2                	sd	s4,64(sp)
    80001f70:	fc56                	sd	s5,56(sp)
    80001f72:	f85a                	sd	s6,48(sp)
    80001f74:	f45e                	sd	s7,40(sp)
    80001f76:	f062                	sd	s8,32(sp)
    80001f78:	ec66                	sd	s9,24(sp)
    80001f7a:	e86a                	sd	s10,16(sp)
    80001f7c:	e46e                	sd	s11,8(sp)
    80001f7e:	1880                	addi	s0,sp,112
    80001f80:	8792                	mv	a5,tp
  int id = r_tp();
    80001f82:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f84:	00779d13          	slli	s10,a5,0x7
    80001f88:	0000f717          	auipc	a4,0xf
    80001f8c:	31870713          	addi	a4,a4,792 # 800112a0 <pid_lock>
    80001f90:	976a                	add	a4,a4,s10
    80001f92:	02073823          	sd	zero,48(a4)
	        swtch(&c->context, &p->context);
    80001f96:	0000f717          	auipc	a4,0xf
    80001f9a:	34270713          	addi	a4,a4,834 # 800112d8 <cpus+0x8>
    80001f9e:	9d3a                	add	s10,s10,a4
	        c->proc = p;
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	0000fc17          	auipc	s8,0xf
    80001fa6:	2fec0c13          	addi	s8,s8,766 # 800112a0 <pid_lock>
    80001faa:	9c3e                	add	s8,s8,a5
	        total_tickets ++;
    80001fac:	00007b97          	auipc	s7,0x7
    80001fb0:	084b8b93          	addi	s7,s7,132 # 80009030 <total_tickets>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	00015a17          	auipc	s4,0x15
    80001fb8:	51ca0a13          	addi	s4,s4,1308 # 800174d0 <tickslock>
    80001fbc:	aa09                	j	800020ce <scheduler+0x16c>
		release(&p->lock);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cc4080e7          	jalr	-828(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc8:	17848493          	addi	s1,s1,376
    80001fcc:	05448a63          	beq	s1,s4,80002020 <scheduler+0xbe>
    	acquire(&p->lock);
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	bfe080e7          	jalr	-1026(ra) # 80000bd0 <acquire>
    	if ((p->state == RUNNABLE) && (p->in_queue == HIGH)) {
    80001fda:	4c9c                	lw	a5,24(s1)
    80001fdc:	ff3791e3          	bne	a5,s3,80001fbe <scheduler+0x5c>
    80001fe0:	1744a783          	lw	a5,372(s1)
    80001fe4:	ffe9                	bnez	a5,80001fbe <scheduler+0x5c>
	        p->state = RUNNING;
    80001fe6:	0194ac23          	sw	s9,24(s1)
	        p->hticks++;
    80001fea:	1684a783          	lw	a5,360(s1)
    80001fee:	2785                	addiw	a5,a5,1
    80001ff0:	16f4a423          	sw	a5,360(s1)
	        c->proc = p;
    80001ff4:	029c3823          	sd	s1,48(s8)
	        high_p_count++;
    80001ff8:	2a85                	addiw	s5,s5,1
	        swtch(&c->context, &p->context);
    80001ffa:	06048593          	addi	a1,s1,96
    80001ffe:	856a                	mv	a0,s10
    80002000:	00001097          	auipc	ra,0x1
    80002004:	8ae080e7          	jalr	-1874(ra) # 800028ae <swtch>
	        c->proc = 0;
    80002008:	020c3823          	sd	zero,48(s8)
	        p->in_queue = LOW;
    8000200c:	1764aa23          	sw	s6,372(s1)
	        p->ticket = 1;
    80002010:	1764a823          	sw	s6,368(s1)
	        total_tickets ++;
    80002014:	000ba783          	lw	a5,0(s7)
    80002018:	2785                	addiw	a5,a5,1
    8000201a:	00fba023          	sw	a5,0(s7)
    8000201e:	b745                	j	80001fbe <scheduler+0x5c>
	if (high_p_count == 0) {
    80002020:	0a0a9863          	bnez	s5,800020d0 <scheduler+0x16e>
		int winner = (rand() * total_tickets * 10)/10 + 1;
    80002024:	00000097          	auipc	ra,0x0
    80002028:	800080e7          	jalr	-2048(ra) # 80001824 <rand>
    8000202c:	000ba783          	lw	a5,0(s7)
    80002030:	d20787d3          	fcvt.d.w	fa5,a5
    80002034:	12a7f7d3          	fmul.d	fa5,fa5,fa0
    80002038:	00006797          	auipc	a5,0x6
    8000203c:	fd87b707          	fld	fa4,-40(a5) # 80008010 <etext+0x10>
    80002040:	12e7f7d3          	fmul.d	fa5,fa5,fa4
    80002044:	1ae7f7d3          	fdiv.d	fa5,fa5,fa4
    80002048:	00006797          	auipc	a5,0x6
    8000204c:	fd07b707          	fld	fa4,-48(a5) # 80008018 <etext+0x18>
    80002050:	02e7f7d3          	fadd.d	fa5,fa5,fa4
    80002054:	c20797d3          	fcvt.w.d	a5,fa5,rtz
    80002058:	0007899b          	sext.w	s3,a5
	    for(p = proc; p < &proc[NPROC]; p++) {
    8000205c:	0000f497          	auipc	s1,0xf
    80002060:	67448493          	addi	s1,s1,1652 # 800116d0 <proc>
			if ((p->state == RUNNABLE) && (p->in_queue == LOW) && (counter >= winner)) {
    80002064:	490d                	li	s2,3
    80002066:	4b05                	li	s6,1
	    	acquire(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b66080e7          	jalr	-1178(ra) # 80000bd0 <acquire>
	    	counter += p->ticket;
    80002072:	1704a783          	lw	a5,368(s1)
    80002076:	01578abb          	addw	s5,a5,s5
			if ((p->state == RUNNABLE) && (p->in_queue == LOW) && (counter >= winner)) {
    8000207a:	4c9c                	lw	a5,24(s1)
    8000207c:	01278c63          	beq	a5,s2,80002094 <scheduler+0x132>
			release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c02080e7          	jalr	-1022(ra) # 80000c84 <release>
	    for(p = proc; p < &proc[NPROC]; p++) {
    8000208a:	17848493          	addi	s1,s1,376
    8000208e:	fd449de3          	bne	s1,s4,80002068 <scheduler+0x106>
    80002092:	a835                	j	800020ce <scheduler+0x16c>
			if ((p->state == RUNNABLE) && (p->in_queue == LOW) && (counter >= winner)) {
    80002094:	1744a783          	lw	a5,372(s1)
    80002098:	ff6794e3          	bne	a5,s6,80002080 <scheduler+0x11e>
    8000209c:	ff3ac2e3          	blt	s5,s3,80002080 <scheduler+0x11e>
		        p->state = RUNNING;
    800020a0:	4791                	li	a5,4
    800020a2:	cc9c                	sw	a5,24(s1)
		        p->lticks++;
    800020a4:	16c4a783          	lw	a5,364(s1)
    800020a8:	2785                	addiw	a5,a5,1
    800020aa:	16f4a623          	sw	a5,364(s1)
		        c->proc = p;
    800020ae:	029c3823          	sd	s1,48(s8)
		        swtch(&c->context, &p->context);
    800020b2:	06048593          	addi	a1,s1,96
    800020b6:	856a                	mv	a0,s10
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	7f6080e7          	jalr	2038(ra) # 800028ae <swtch>
		        c->proc = 0;
    800020c0:	020c3823          	sd	zero,48(s8)
			release(&p->lock);
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bbe080e7          	jalr	-1090(ra) # 80000c84 <release>
    int high_p_count = 0;
    800020ce:	4d81                	li	s11,0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020d4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d8:	10079073          	csrw	sstatus,a5
    800020dc:	8aee                	mv	s5,s11
    for(p = proc; p < &proc[NPROC]; p++) {
    800020de:	0000f497          	auipc	s1,0xf
    800020e2:	5f248493          	addi	s1,s1,1522 # 800116d0 <proc>
    	if ((p->state == RUNNABLE) && (p->in_queue == HIGH)) {
    800020e6:	498d                	li	s3,3
	        p->state = RUNNING;
    800020e8:	4c91                	li	s9,4
	        p->in_queue = LOW;
    800020ea:	4b05                	li	s6,1
    800020ec:	b5d5                	j	80001fd0 <scheduler+0x6e>

00000000800020ee <sched>:
{
    800020ee:	7179                	addi	sp,sp,-48
    800020f0:	f406                	sd	ra,40(sp)
    800020f2:	f022                	sd	s0,32(sp)
    800020f4:	ec26                	sd	s1,24(sp)
    800020f6:	e84a                	sd	s2,16(sp)
    800020f8:	e44e                	sd	s3,8(sp)
    800020fa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	944080e7          	jalr	-1724(ra) # 80001a40 <myproc>
    80002104:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	a50080e7          	jalr	-1456(ra) # 80000b56 <holding>
    8000210e:	c93d                	beqz	a0,80002184 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002110:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002112:	2781                	sext.w	a5,a5
    80002114:	079e                	slli	a5,a5,0x7
    80002116:	0000f717          	auipc	a4,0xf
    8000211a:	18a70713          	addi	a4,a4,394 # 800112a0 <pid_lock>
    8000211e:	97ba                	add	a5,a5,a4
    80002120:	0a87a703          	lw	a4,168(a5)
    80002124:	4785                	li	a5,1
    80002126:	06f71763          	bne	a4,a5,80002194 <sched+0xa6>
  if(p->state == RUNNING)
    8000212a:	4c98                	lw	a4,24(s1)
    8000212c:	4791                	li	a5,4
    8000212e:	06f70b63          	beq	a4,a5,800021a4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002132:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002136:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002138:	efb5                	bnez	a5,800021b4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000213c:	0000f917          	auipc	s2,0xf
    80002140:	16490913          	addi	s2,s2,356 # 800112a0 <pid_lock>
    80002144:	2781                	sext.w	a5,a5
    80002146:	079e                	slli	a5,a5,0x7
    80002148:	97ca                	add	a5,a5,s2
    8000214a:	0ac7a983          	lw	s3,172(a5)
    8000214e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002150:	2781                	sext.w	a5,a5
    80002152:	079e                	slli	a5,a5,0x7
    80002154:	0000f597          	auipc	a1,0xf
    80002158:	18458593          	addi	a1,a1,388 # 800112d8 <cpus+0x8>
    8000215c:	95be                	add	a1,a1,a5
    8000215e:	06048513          	addi	a0,s1,96
    80002162:	00000097          	auipc	ra,0x0
    80002166:	74c080e7          	jalr	1868(ra) # 800028ae <swtch>
    8000216a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000216c:	2781                	sext.w	a5,a5
    8000216e:	079e                	slli	a5,a5,0x7
    80002170:	993e                	add	s2,s2,a5
    80002172:	0b392623          	sw	s3,172(s2)
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
    80002188:	0a450513          	addi	a0,a0,164 # 80008228 <digits+0x1d8>
    8000218c:	ffffe097          	auipc	ra,0xffffe
    80002190:	3ae080e7          	jalr	942(ra) # 8000053a <panic>
    panic("sched locks");
    80002194:	00006517          	auipc	a0,0x6
    80002198:	0a450513          	addi	a0,a0,164 # 80008238 <digits+0x1e8>
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	39e080e7          	jalr	926(ra) # 8000053a <panic>
    panic("sched running");
    800021a4:	00006517          	auipc	a0,0x6
    800021a8:	0a450513          	addi	a0,a0,164 # 80008248 <digits+0x1f8>
    800021ac:	ffffe097          	auipc	ra,0xffffe
    800021b0:	38e080e7          	jalr	910(ra) # 8000053a <panic>
    panic("sched interruptible");
    800021b4:	00006517          	auipc	a0,0x6
    800021b8:	0a450513          	addi	a0,a0,164 # 80008258 <digits+0x208>
    800021bc:	ffffe097          	auipc	ra,0xffffe
    800021c0:	37e080e7          	jalr	894(ra) # 8000053a <panic>

00000000800021c4 <yield>:
{
    800021c4:	1101                	addi	sp,sp,-32
    800021c6:	ec06                	sd	ra,24(sp)
    800021c8:	e822                	sd	s0,16(sp)
    800021ca:	e426                	sd	s1,8(sp)
    800021cc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	872080e7          	jalr	-1934(ra) # 80001a40 <myproc>
    800021d6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	9f8080e7          	jalr	-1544(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    800021e0:	478d                	li	a5,3
    800021e2:	cc9c                	sw	a5,24(s1)
  sched();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	f0a080e7          	jalr	-246(ra) # 800020ee <sched>
  release(&p->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	a96080e7          	jalr	-1386(ra) # 80000c84 <release>
}
    800021f6:	60e2                	ld	ra,24(sp)
    800021f8:	6442                	ld	s0,16(sp)
    800021fa:	64a2                	ld	s1,8(sp)
    800021fc:	6105                	addi	sp,sp,32
    800021fe:	8082                	ret

0000000080002200 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002200:	7179                	addi	sp,sp,-48
    80002202:	f406                	sd	ra,40(sp)
    80002204:	f022                	sd	s0,32(sp)
    80002206:	ec26                	sd	s1,24(sp)
    80002208:	e84a                	sd	s2,16(sp)
    8000220a:	e44e                	sd	s3,8(sp)
    8000220c:	1800                	addi	s0,sp,48
    8000220e:	89aa                	mv	s3,a0
    80002210:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002212:	00000097          	auipc	ra,0x0
    80002216:	82e080e7          	jalr	-2002(ra) # 80001a40 <myproc>
    8000221a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9b4080e7          	jalr	-1612(ra) # 80000bd0 <acquire>
  release(lk);
    80002224:	854a                	mv	a0,s2
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a5e080e7          	jalr	-1442(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000222e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002232:	4789                	li	a5,2
    80002234:	cc9c                	sw	a5,24(s1)

  sched();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	eb8080e7          	jalr	-328(ra) # 800020ee <sched>

  // Tidy up.
  p->chan = 0;
    8000223e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a40080e7          	jalr	-1472(ra) # 80000c84 <release>
  acquire(lk);
    8000224c:	854a                	mv	a0,s2
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	982080e7          	jalr	-1662(ra) # 80000bd0 <acquire>
}
    80002256:	70a2                	ld	ra,40(sp)
    80002258:	7402                	ld	s0,32(sp)
    8000225a:	64e2                	ld	s1,24(sp)
    8000225c:	6942                	ld	s2,16(sp)
    8000225e:	69a2                	ld	s3,8(sp)
    80002260:	6145                	addi	sp,sp,48
    80002262:	8082                	ret

0000000080002264 <wait>:
{
    80002264:	715d                	addi	sp,sp,-80
    80002266:	e486                	sd	ra,72(sp)
    80002268:	e0a2                	sd	s0,64(sp)
    8000226a:	fc26                	sd	s1,56(sp)
    8000226c:	f84a                	sd	s2,48(sp)
    8000226e:	f44e                	sd	s3,40(sp)
    80002270:	f052                	sd	s4,32(sp)
    80002272:	ec56                	sd	s5,24(sp)
    80002274:	e85a                	sd	s6,16(sp)
    80002276:	e45e                	sd	s7,8(sp)
    80002278:	e062                	sd	s8,0(sp)
    8000227a:	0880                	addi	s0,sp,80
    8000227c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	7c2080e7          	jalr	1986(ra) # 80001a40 <myproc>
    80002286:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002288:	0000f517          	auipc	a0,0xf
    8000228c:	03050513          	addi	a0,a0,48 # 800112b8 <wait_lock>
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	940080e7          	jalr	-1728(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002298:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000229a:	4a15                	li	s4,5
        havekids = 1;
    8000229c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000229e:	00015997          	auipc	s3,0x15
    800022a2:	23298993          	addi	s3,s3,562 # 800174d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022a6:	0000fc17          	auipc	s8,0xf
    800022aa:	012c0c13          	addi	s8,s8,18 # 800112b8 <wait_lock>
    havekids = 0;
    800022ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022b0:	0000f497          	auipc	s1,0xf
    800022b4:	42048493          	addi	s1,s1,1056 # 800116d0 <proc>
    800022b8:	a0bd                	j	80002326 <wait+0xc2>
          pid = np->pid;
    800022ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022be:	000b0e63          	beqz	s6,800022da <wait+0x76>
    800022c2:	4691                	li	a3,4
    800022c4:	02c48613          	addi	a2,s1,44
    800022c8:	85da                	mv	a1,s6
    800022ca:	05093503          	ld	a0,80(s2)
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	38c080e7          	jalr	908(ra) # 8000165a <copyout>
    800022d6:	02054563          	bltz	a0,80002300 <wait+0x9c>
          freeproc(np);
    800022da:	8526                	mv	a0,s1
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	916080e7          	jalr	-1770(ra) # 80001bf2 <freeproc>
          release(&np->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	99e080e7          	jalr	-1634(ra) # 80000c84 <release>
          release(&wait_lock);
    800022ee:	0000f517          	auipc	a0,0xf
    800022f2:	fca50513          	addi	a0,a0,-54 # 800112b8 <wait_lock>
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	98e080e7          	jalr	-1650(ra) # 80000c84 <release>
          return pid;
    800022fe:	a09d                	j	80002364 <wait+0x100>
            release(&np->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	982080e7          	jalr	-1662(ra) # 80000c84 <release>
            release(&wait_lock);
    8000230a:	0000f517          	auipc	a0,0xf
    8000230e:	fae50513          	addi	a0,a0,-82 # 800112b8 <wait_lock>
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	972080e7          	jalr	-1678(ra) # 80000c84 <release>
            return -1;
    8000231a:	59fd                	li	s3,-1
    8000231c:	a0a1                	j	80002364 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000231e:	17848493          	addi	s1,s1,376
    80002322:	03348463          	beq	s1,s3,8000234a <wait+0xe6>
      if(np->parent == p){
    80002326:	7c9c                	ld	a5,56(s1)
    80002328:	ff279be3          	bne	a5,s2,8000231e <wait+0xba>
        acquire(&np->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8a2080e7          	jalr	-1886(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002336:	4c9c                	lw	a5,24(s1)
    80002338:	f94781e3          	beq	a5,s4,800022ba <wait+0x56>
        release(&np->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	946080e7          	jalr	-1722(ra) # 80000c84 <release>
        havekids = 1;
    80002346:	8756                	mv	a4,s5
    80002348:	bfd9                	j	8000231e <wait+0xba>
    if(!havekids || p->killed){
    8000234a:	c701                	beqz	a4,80002352 <wait+0xee>
    8000234c:	02892783          	lw	a5,40(s2)
    80002350:	c79d                	beqz	a5,8000237e <wait+0x11a>
      release(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	f6650513          	addi	a0,a0,-154 # 800112b8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	92a080e7          	jalr	-1750(ra) # 80000c84 <release>
      return -1;
    80002362:	59fd                	li	s3,-1
}
    80002364:	854e                	mv	a0,s3
    80002366:	60a6                	ld	ra,72(sp)
    80002368:	6406                	ld	s0,64(sp)
    8000236a:	74e2                	ld	s1,56(sp)
    8000236c:	7942                	ld	s2,48(sp)
    8000236e:	79a2                	ld	s3,40(sp)
    80002370:	7a02                	ld	s4,32(sp)
    80002372:	6ae2                	ld	s5,24(sp)
    80002374:	6b42                	ld	s6,16(sp)
    80002376:	6ba2                	ld	s7,8(sp)
    80002378:	6c02                	ld	s8,0(sp)
    8000237a:	6161                	addi	sp,sp,80
    8000237c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237e:	85e2                	mv	a1,s8
    80002380:	854a                	mv	a0,s2
    80002382:	00000097          	auipc	ra,0x0
    80002386:	e7e080e7          	jalr	-386(ra) # 80002200 <sleep>
    havekids = 0;
    8000238a:	b715                	j	800022ae <wait+0x4a>

000000008000238c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000238c:	7139                	addi	sp,sp,-64
    8000238e:	fc06                	sd	ra,56(sp)
    80002390:	f822                	sd	s0,48(sp)
    80002392:	f426                	sd	s1,40(sp)
    80002394:	f04a                	sd	s2,32(sp)
    80002396:	ec4e                	sd	s3,24(sp)
    80002398:	e852                	sd	s4,16(sp)
    8000239a:	e456                	sd	s5,8(sp)
    8000239c:	0080                	addi	s0,sp,64
    8000239e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	33048493          	addi	s1,s1,816 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023a8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023aa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ac:	00015917          	auipc	s2,0x15
    800023b0:	12490913          	addi	s2,s2,292 # 800174d0 <tickslock>
    800023b4:	a811                	j	800023c8 <wakeup+0x3c>
      }
      release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8cc080e7          	jalr	-1844(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c0:	17848493          	addi	s1,s1,376
    800023c4:	03248663          	beq	s1,s2,800023f0 <wakeup+0x64>
    if(p != myproc()){
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	678080e7          	jalr	1656(ra) # 80001a40 <myproc>
    800023d0:	fea488e3          	beq	s1,a0,800023c0 <wakeup+0x34>
      acquire(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	7fa080e7          	jalr	2042(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4c9c                	lw	a5,24(s1)
    800023e0:	fd379be3          	bne	a5,s3,800023b6 <wakeup+0x2a>
    800023e4:	709c                	ld	a5,32(s1)
    800023e6:	fd4798e3          	bne	a5,s4,800023b6 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023ea:	0154ac23          	sw	s5,24(s1)
    800023ee:	b7e1                	j	800023b6 <wakeup+0x2a>
    }
  }
}
    800023f0:	70e2                	ld	ra,56(sp)
    800023f2:	7442                	ld	s0,48(sp)
    800023f4:	74a2                	ld	s1,40(sp)
    800023f6:	7902                	ld	s2,32(sp)
    800023f8:	69e2                	ld	s3,24(sp)
    800023fa:	6a42                	ld	s4,16(sp)
    800023fc:	6aa2                	ld	s5,8(sp)
    800023fe:	6121                	addi	sp,sp,64
    80002400:	8082                	ret

0000000080002402 <reparent>:
{
    80002402:	7179                	addi	sp,sp,-48
    80002404:	f406                	sd	ra,40(sp)
    80002406:	f022                	sd	s0,32(sp)
    80002408:	ec26                	sd	s1,24(sp)
    8000240a:	e84a                	sd	s2,16(sp)
    8000240c:	e44e                	sd	s3,8(sp)
    8000240e:	e052                	sd	s4,0(sp)
    80002410:	1800                	addi	s0,sp,48
    80002412:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002414:	0000f497          	auipc	s1,0xf
    80002418:	2bc48493          	addi	s1,s1,700 # 800116d0 <proc>
      pp->parent = initproc;
    8000241c:	00007a17          	auipc	s4,0x7
    80002420:	c0ca0a13          	addi	s4,s4,-1012 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002424:	00015997          	auipc	s3,0x15
    80002428:	0ac98993          	addi	s3,s3,172 # 800174d0 <tickslock>
    8000242c:	a029                	j	80002436 <reparent+0x34>
    8000242e:	17848493          	addi	s1,s1,376
    80002432:	01348d63          	beq	s1,s3,8000244c <reparent+0x4a>
    if(pp->parent == p){
    80002436:	7c9c                	ld	a5,56(s1)
    80002438:	ff279be3          	bne	a5,s2,8000242e <reparent+0x2c>
      pp->parent = initproc;
    8000243c:	000a3503          	ld	a0,0(s4)
    80002440:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002442:	00000097          	auipc	ra,0x0
    80002446:	f4a080e7          	jalr	-182(ra) # 8000238c <wakeup>
    8000244a:	b7d5                	j	8000242e <reparent+0x2c>
}
    8000244c:	70a2                	ld	ra,40(sp)
    8000244e:	7402                	ld	s0,32(sp)
    80002450:	64e2                	ld	s1,24(sp)
    80002452:	6942                	ld	s2,16(sp)
    80002454:	69a2                	ld	s3,8(sp)
    80002456:	6a02                	ld	s4,0(sp)
    80002458:	6145                	addi	sp,sp,48
    8000245a:	8082                	ret

000000008000245c <exit>:
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	5d2080e7          	jalr	1490(ra) # 80001a40 <myproc>
    80002476:	89aa                	mv	s3,a0
  if(p == initproc)
    80002478:	00007797          	auipc	a5,0x7
    8000247c:	bb07b783          	ld	a5,-1104(a5) # 80009028 <initproc>
    80002480:	0d050493          	addi	s1,a0,208
    80002484:	15050913          	addi	s2,a0,336
    80002488:	02a79363          	bne	a5,a0,800024ae <exit+0x52>
    panic("init exiting");
    8000248c:	00006517          	auipc	a0,0x6
    80002490:	de450513          	addi	a0,a0,-540 # 80008270 <digits+0x220>
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	0a6080e7          	jalr	166(ra) # 8000053a <panic>
      fileclose(f);
    8000249c:	00002097          	auipc	ra,0x2
    800024a0:	396080e7          	jalr	918(ra) # 80004832 <fileclose>
      p->ofile[fd] = 0;
    800024a4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024a8:	04a1                	addi	s1,s1,8
    800024aa:	01248563          	beq	s1,s2,800024b4 <exit+0x58>
    if(p->ofile[fd]){
    800024ae:	6088                	ld	a0,0(s1)
    800024b0:	f575                	bnez	a0,8000249c <exit+0x40>
    800024b2:	bfdd                	j	800024a8 <exit+0x4c>
  begin_op();
    800024b4:	00002097          	auipc	ra,0x2
    800024b8:	eb6080e7          	jalr	-330(ra) # 8000436a <begin_op>
  iput(p->cwd);
    800024bc:	1509b503          	ld	a0,336(s3)
    800024c0:	00001097          	auipc	ra,0x1
    800024c4:	688080e7          	jalr	1672(ra) # 80003b48 <iput>
  end_op();
    800024c8:	00002097          	auipc	ra,0x2
    800024cc:	f20080e7          	jalr	-224(ra) # 800043e8 <end_op>
  p->cwd = 0;
    800024d0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024d4:	0000f497          	auipc	s1,0xf
    800024d8:	de448493          	addi	s1,s1,-540 # 800112b8 <wait_lock>
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	6f2080e7          	jalr	1778(ra) # 80000bd0 <acquire>
  reparent(p);
    800024e6:	854e                	mv	a0,s3
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	f1a080e7          	jalr	-230(ra) # 80002402 <reparent>
  wakeup(p->parent);
    800024f0:	0389b503          	ld	a0,56(s3)
    800024f4:	00000097          	auipc	ra,0x0
    800024f8:	e98080e7          	jalr	-360(ra) # 8000238c <wakeup>
  acquire(&p->lock);
    800024fc:	854e                	mv	a0,s3
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	6d2080e7          	jalr	1746(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002506:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000250a:	4795                	li	a5,5
    8000250c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	772080e7          	jalr	1906(ra) # 80000c84 <release>
  sched();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	bd4080e7          	jalr	-1068(ra) # 800020ee <sched>
  panic("zombie exit");
    80002522:	00006517          	auipc	a0,0x6
    80002526:	d5e50513          	addi	a0,a0,-674 # 80008280 <digits+0x230>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	010080e7          	jalr	16(ra) # 8000053a <panic>

0000000080002532 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002532:	7179                	addi	sp,sp,-48
    80002534:	f406                	sd	ra,40(sp)
    80002536:	f022                	sd	s0,32(sp)
    80002538:	ec26                	sd	s1,24(sp)
    8000253a:	e84a                	sd	s2,16(sp)
    8000253c:	e44e                	sd	s3,8(sp)
    8000253e:	1800                	addi	s0,sp,48
    80002540:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002542:	0000f497          	auipc	s1,0xf
    80002546:	18e48493          	addi	s1,s1,398 # 800116d0 <proc>
    8000254a:	00015997          	auipc	s3,0x15
    8000254e:	f8698993          	addi	s3,s3,-122 # 800174d0 <tickslock>
    acquire(&p->lock);
    80002552:	8526                	mv	a0,s1
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	67c080e7          	jalr	1660(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    8000255c:	589c                	lw	a5,48(s1)
    8000255e:	01278d63          	beq	a5,s2,80002578 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	720080e7          	jalr	1824(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256c:	17848493          	addi	s1,s1,376
    80002570:	ff3491e3          	bne	s1,s3,80002552 <kill+0x20>
  }
  return -1;
    80002574:	557d                	li	a0,-1
    80002576:	a829                	j	80002590 <kill+0x5e>
      p->killed = 1;
    80002578:	4785                	li	a5,1
    8000257a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000257c:	4c98                	lw	a4,24(s1)
    8000257e:	4789                	li	a5,2
    80002580:	00f70f63          	beq	a4,a5,8000259e <kill+0x6c>
      release(&p->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	6fe080e7          	jalr	1790(ra) # 80000c84 <release>
      return 0;
    8000258e:	4501                	li	a0,0
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6145                	addi	sp,sp,48
    8000259c:	8082                	ret
        p->state = RUNNABLE;
    8000259e:	478d                	li	a5,3
    800025a0:	cc9c                	sw	a5,24(s1)
    800025a2:	b7cd                	j	80002584 <kill+0x52>

00000000800025a4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025a4:	7179                	addi	sp,sp,-48
    800025a6:	f406                	sd	ra,40(sp)
    800025a8:	f022                	sd	s0,32(sp)
    800025aa:	ec26                	sd	s1,24(sp)
    800025ac:	e84a                	sd	s2,16(sp)
    800025ae:	e44e                	sd	s3,8(sp)
    800025b0:	e052                	sd	s4,0(sp)
    800025b2:	1800                	addi	s0,sp,48
    800025b4:	84aa                	mv	s1,a0
    800025b6:	892e                	mv	s2,a1
    800025b8:	89b2                	mv	s3,a2
    800025ba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	484080e7          	jalr	1156(ra) # 80001a40 <myproc>
  if(user_dst){
    800025c4:	c08d                	beqz	s1,800025e6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025c6:	86d2                	mv	a3,s4
    800025c8:	864e                	mv	a2,s3
    800025ca:	85ca                	mv	a1,s2
    800025cc:	6928                	ld	a0,80(a0)
    800025ce:	fffff097          	auipc	ra,0xfffff
    800025d2:	08c080e7          	jalr	140(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6a02                	ld	s4,0(sp)
    800025e2:	6145                	addi	sp,sp,48
    800025e4:	8082                	ret
    memmove((char *)dst, src, len);
    800025e6:	000a061b          	sext.w	a2,s4
    800025ea:	85ce                	mv	a1,s3
    800025ec:	854a                	mv	a0,s2
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	73a080e7          	jalr	1850(ra) # 80000d28 <memmove>
    return 0;
    800025f6:	8526                	mv	a0,s1
    800025f8:	bff9                	j	800025d6 <either_copyout+0x32>

00000000800025fa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025fa:	7179                	addi	sp,sp,-48
    800025fc:	f406                	sd	ra,40(sp)
    800025fe:	f022                	sd	s0,32(sp)
    80002600:	ec26                	sd	s1,24(sp)
    80002602:	e84a                	sd	s2,16(sp)
    80002604:	e44e                	sd	s3,8(sp)
    80002606:	e052                	sd	s4,0(sp)
    80002608:	1800                	addi	s0,sp,48
    8000260a:	892a                	mv	s2,a0
    8000260c:	84ae                	mv	s1,a1
    8000260e:	89b2                	mv	s3,a2
    80002610:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	42e080e7          	jalr	1070(ra) # 80001a40 <myproc>
  if(user_src){
    8000261a:	c08d                	beqz	s1,8000263c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000261c:	86d2                	mv	a3,s4
    8000261e:	864e                	mv	a2,s3
    80002620:	85ca                	mv	a1,s2
    80002622:	6928                	ld	a0,80(a0)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	0c2080e7          	jalr	194(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000262c:	70a2                	ld	ra,40(sp)
    8000262e:	7402                	ld	s0,32(sp)
    80002630:	64e2                	ld	s1,24(sp)
    80002632:	6942                	ld	s2,16(sp)
    80002634:	69a2                	ld	s3,8(sp)
    80002636:	6a02                	ld	s4,0(sp)
    80002638:	6145                	addi	sp,sp,48
    8000263a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000263c:	000a061b          	sext.w	a2,s4
    80002640:	85ce                	mv	a1,s3
    80002642:	854a                	mv	a0,s2
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	6e4080e7          	jalr	1764(ra) # 80000d28 <memmove>
    return 0;
    8000264c:	8526                	mv	a0,s1
    8000264e:	bff9                	j	8000262c <either_copyin+0x32>

0000000080002650 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002650:	715d                	addi	sp,sp,-80
    80002652:	e486                	sd	ra,72(sp)
    80002654:	e0a2                	sd	s0,64(sp)
    80002656:	fc26                	sd	s1,56(sp)
    80002658:	f84a                	sd	s2,48(sp)
    8000265a:	f44e                	sd	s3,40(sp)
    8000265c:	f052                	sd	s4,32(sp)
    8000265e:	ec56                	sd	s5,24(sp)
    80002660:	e85a                	sd	s6,16(sp)
    80002662:	e45e                	sd	s7,8(sp)
    80002664:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002666:	00006517          	auipc	a0,0x6
    8000266a:	a7250513          	addi	a0,a0,-1422 # 800080d8 <digits+0x88>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	f16080e7          	jalr	-234(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002676:	0000f497          	auipc	s1,0xf
    8000267a:	1b248493          	addi	s1,s1,434 # 80011828 <proc+0x158>
    8000267e:	00015917          	auipc	s2,0x15
    80002682:	faa90913          	addi	s2,s2,-86 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002686:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002688:	00006997          	auipc	s3,0x6
    8000268c:	c0898993          	addi	s3,s3,-1016 # 80008290 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002690:	00006a97          	auipc	s5,0x6
    80002694:	c08a8a93          	addi	s5,s5,-1016 # 80008298 <digits+0x248>
    printf("\n");
    80002698:	00006a17          	auipc	s4,0x6
    8000269c:	a40a0a13          	addi	s4,s4,-1472 # 800080d8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a0:	00006b97          	auipc	s7,0x6
    800026a4:	cf8b8b93          	addi	s7,s7,-776 # 80008398 <states.1>
    800026a8:	a00d                	j	800026ca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026aa:	ed86a583          	lw	a1,-296(a3)
    800026ae:	8556                	mv	a0,s5
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	ed4080e7          	jalr	-300(ra) # 80000584 <printf>
    printf("\n");
    800026b8:	8552                	mv	a0,s4
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	eca080e7          	jalr	-310(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026c2:	17848493          	addi	s1,s1,376
    800026c6:	03248263          	beq	s1,s2,800026ea <procdump+0x9a>
    if(p->state == UNUSED)
    800026ca:	86a6                	mv	a3,s1
    800026cc:	ec04a783          	lw	a5,-320(s1)
    800026d0:	dbed                	beqz	a5,800026c2 <procdump+0x72>
      state = "???";
    800026d2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d4:	fcfb6be3          	bltu	s6,a5,800026aa <procdump+0x5a>
    800026d8:	02079713          	slli	a4,a5,0x20
    800026dc:	01d75793          	srli	a5,a4,0x1d
    800026e0:	97de                	add	a5,a5,s7
    800026e2:	6390                	ld	a2,0(a5)
    800026e4:	f279                	bnez	a2,800026aa <procdump+0x5a>
      state = "???";
    800026e6:	864e                	mv	a2,s3
    800026e8:	b7c9                	j	800026aa <procdump+0x5a>
  }
}
    800026ea:	60a6                	ld	ra,72(sp)
    800026ec:	6406                	ld	s0,64(sp)
    800026ee:	74e2                	ld	s1,56(sp)
    800026f0:	7942                	ld	s2,48(sp)
    800026f2:	79a2                	ld	s3,40(sp)
    800026f4:	7a02                	ld	s4,32(sp)
    800026f6:	6ae2                	ld	s5,24(sp)
    800026f8:	6b42                	ld	s6,16(sp)
    800026fa:	6ba2                	ld	s7,8(sp)
    800026fc:	6161                	addi	sp,sp,80
    800026fe:	8082                	ret

0000000080002700 <cps>:

int
cps (void)
{
    80002700:	711d                	addi	sp,sp,-96
    80002702:	ec86                	sd	ra,88(sp)
    80002704:	e8a2                	sd	s0,80(sp)
    80002706:	e4a6                	sd	s1,72(sp)
    80002708:	e0ca                	sd	s2,64(sp)
    8000270a:	fc4e                	sd	s3,56(sp)
    8000270c:	f852                	sd	s4,48(sp)
    8000270e:	f456                	sd	s5,40(sp)
    80002710:	f05a                	sd	s6,32(sp)
    80002712:	ec5e                	sd	s7,24(sp)
    80002714:	e862                	sd	s8,16(sp)
    80002716:	e466                	sd	s9,8(sp)
    80002718:	e06a                	sd	s10,0(sp)
    8000271a:	1080                	addi	s0,sp,96
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002720:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002724:	10079073          	csrw	sstatus,a5
	static const char *queue[] = { "HIGH","LOW" };
	
	//Enable interrupt
	intr_on();
	
	printf ("name \t pid \t state \t queue \t tickets \t high ticks \t low ticks\n");
    80002728:	00006517          	auipc	a0,0x6
    8000272c:	b8050513          	addi	a0,a0,-1152 # 800082a8 <digits+0x258>
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	e54080e7          	jalr	-428(ra) # 80000584 <printf>
	for (p = proc; p < &proc[NPROC]; p++) {
    80002738:	0000f497          	auipc	s1,0xf
    8000273c:	0f048493          	addi	s1,s1,240 # 80011828 <proc+0x158>
    80002740:	00015a17          	auipc	s4,0x15
    80002744:	ee8a0a13          	addi	s4,s4,-280 # 80017628 <bcache+0x140>
		acquire (&p->lock);
		if (p->state == SLEEPING)
    80002748:	4989                	li	s3,2
			printf ("%s \t %d \t SLEEPING \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
		else if (p->state == RUNNING)
    8000274a:	4a91                	li	s5,4
			printf ("%s \t %d \t RUNNING \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
		else if (p->state == RUNNABLE)
    8000274c:	4b0d                	li	s6,3
			printf ("%s \t %d \t RUNNABLE \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
    8000274e:	00006b97          	auipc	s7,0x6
    80002752:	c4ab8b93          	addi	s7,s7,-950 # 80008398 <states.1>
    80002756:	00006d17          	auipc	s10,0x6
    8000275a:	be2d0d13          	addi	s10,s10,-1054 # 80008338 <digits+0x2e8>
			printf ("%s \t %d \t RUNNING \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
    8000275e:	00006c97          	auipc	s9,0x6
    80002762:	bb2c8c93          	addi	s9,s9,-1102 # 80008310 <digits+0x2c0>
			printf ("%s \t %d \t SLEEPING \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
    80002766:	00006c17          	auipc	s8,0x6
    8000276a:	b82c0c13          	addi	s8,s8,-1150 # 800082e8 <digits+0x298>
    8000276e:	a815                	j	800027a2 <cps+0xa2>
    80002770:	01c4e683          	lwu	a3,28(s1)
    80002774:	068e                	slli	a3,a3,0x3
    80002776:	96de                	add	a3,a3,s7
    80002778:	0144a803          	lw	a6,20(s1)
    8000277c:	489c                	lw	a5,16(s1)
    8000277e:	4c98                	lw	a4,24(s1)
    80002780:	7a94                	ld	a3,48(a3)
    80002782:	ed84a603          	lw	a2,-296(s1)
    80002786:	8562                	mv	a0,s8
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	dfc080e7          	jalr	-516(ra) # 80000584 <printf>
		release(&p->lock);
    80002790:	854a                	mv	a0,s2
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	4f2080e7          	jalr	1266(ra) # 80000c84 <release>
	for (p = proc; p < &proc[NPROC]; p++) {
    8000279a:	17848493          	addi	s1,s1,376
    8000279e:	07448463          	beq	s1,s4,80002806 <cps+0x106>
		acquire (&p->lock);
    800027a2:	ea848913          	addi	s2,s1,-344
    800027a6:	854a                	mv	a0,s2
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	428080e7          	jalr	1064(ra) # 80000bd0 <acquire>
		if (p->state == SLEEPING)
    800027b0:	85a6                	mv	a1,s1
    800027b2:	ec04a783          	lw	a5,-320(s1)
    800027b6:	fb378de3          	beq	a5,s3,80002770 <cps+0x70>
		else if (p->state == RUNNING)
    800027ba:	03578563          	beq	a5,s5,800027e4 <cps+0xe4>
		else if (p->state == RUNNABLE)
    800027be:	fd6799e3          	bne	a5,s6,80002790 <cps+0x90>
			printf ("%s \t %d \t RUNNABLE \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
    800027c2:	01c4e683          	lwu	a3,28(s1)
    800027c6:	068e                	slli	a3,a3,0x3
    800027c8:	96de                	add	a3,a3,s7
    800027ca:	0144a803          	lw	a6,20(s1)
    800027ce:	489c                	lw	a5,16(s1)
    800027d0:	4c98                	lw	a4,24(s1)
    800027d2:	7a94                	ld	a3,48(a3)
    800027d4:	ed84a603          	lw	a2,-296(s1)
    800027d8:	856a                	mv	a0,s10
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	daa080e7          	jalr	-598(ra) # 80000584 <printf>
    800027e2:	b77d                	j	80002790 <cps+0x90>
			printf ("%s \t %d \t RUNNING \t %s \t %d \t %d \t %d\n", p->name, p->pid, queue [p->in_queue], p->ticket, p->hticks, p->lticks);
    800027e4:	01c4e683          	lwu	a3,28(s1)
    800027e8:	068e                	slli	a3,a3,0x3
    800027ea:	96de                	add	a3,a3,s7
    800027ec:	0144a803          	lw	a6,20(s1)
    800027f0:	489c                	lw	a5,16(s1)
    800027f2:	4c98                	lw	a4,24(s1)
    800027f4:	7a94                	ld	a3,48(a3)
    800027f6:	ed84a603          	lw	a2,-296(s1)
    800027fa:	8566                	mv	a0,s9
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d88080e7          	jalr	-632(ra) # 80000584 <printf>
    80002804:	b771                	j	80002790 <cps+0x90>
	}
	return 0;
}
    80002806:	4501                	li	a0,0
    80002808:	60e6                	ld	ra,88(sp)
    8000280a:	6446                	ld	s0,80(sp)
    8000280c:	64a6                	ld	s1,72(sp)
    8000280e:	6906                	ld	s2,64(sp)
    80002810:	79e2                	ld	s3,56(sp)
    80002812:	7a42                	ld	s4,48(sp)
    80002814:	7aa2                	ld	s5,40(sp)
    80002816:	7b02                	ld	s6,32(sp)
    80002818:	6be2                	ld	s7,24(sp)
    8000281a:	6c42                	ld	s8,16(sp)
    8000281c:	6ca2                	ld	s9,8(sp)
    8000281e:	6d02                	ld	s10,0(sp)
    80002820:	6125                	addi	sp,sp,96
    80002822:	8082                	ret

0000000080002824 <settickets>:

//set ticket for each processor to num
int 
settickets (int pid, int num) {
	struct proc *p;
	if (num < 0)
    80002824:	0805c363          	bltz	a1,800028aa <settickets+0x86>
settickets (int pid, int num) {
    80002828:	7179                	addi	sp,sp,-48
    8000282a:	f406                	sd	ra,40(sp)
    8000282c:	f022                	sd	s0,32(sp)
    8000282e:	ec26                	sd	s1,24(sp)
    80002830:	e84a                	sd	s2,16(sp)
    80002832:	e44e                	sd	s3,8(sp)
    80002834:	e052                	sd	s4,0(sp)
    80002836:	1800                	addi	s0,sp,48
    80002838:	892a                	mv	s2,a0
    8000283a:	8a2e                	mv	s4,a1
		return -1;
	bool is_set = false;
	for (p = proc; p < &proc[NPROC]; p++) {
    8000283c:	0000f497          	auipc	s1,0xf
    80002840:	e9448493          	addi	s1,s1,-364 # 800116d0 <proc>
    80002844:	00015997          	auipc	s3,0x15
    80002848:	c8c98993          	addi	s3,s3,-884 # 800174d0 <tickslock>
    8000284c:	a811                	j	80002860 <settickets+0x3c>
			total_tickets -= p->ticket;
			p->ticket = num;
			total_tickets += p->ticket;
			is_set = true;
		}
		release (&p->lock);
    8000284e:	8526                	mv	a0,s1
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	434080e7          	jalr	1076(ra) # 80000c84 <release>
	for (p = proc; p < &proc[NPROC]; p++) {
    80002858:	17848493          	addi	s1,s1,376
    8000285c:	05348563          	beq	s1,s3,800028a6 <settickets+0x82>
		acquire (&p->lock);
    80002860:	8526                	mv	a0,s1
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	36e080e7          	jalr	878(ra) # 80000bd0 <acquire>
		if (p->pid == pid) {
    8000286a:	589c                	lw	a5,48(s1)
    8000286c:	ff2791e3          	bne	a5,s2,8000284e <settickets+0x2a>
			total_tickets -= p->ticket;
    80002870:	00006717          	auipc	a4,0x6
    80002874:	7c070713          	addi	a4,a4,1984 # 80009030 <total_tickets>
    80002878:	431c                	lw	a5,0(a4)
    8000287a:	1704a683          	lw	a3,368(s1)
    8000287e:	9f95                	subw	a5,a5,a3
			p->ticket = num;
    80002880:	1744a823          	sw	s4,368(s1)
			total_tickets += p->ticket;
    80002884:	014787bb          	addw	a5,a5,s4
    80002888:	c31c                	sw	a5,0(a4)
		release (&p->lock);
    8000288a:	8526                	mv	a0,s1
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	3f8080e7          	jalr	1016(ra) # 80000c84 <release>
		if (is_set) break;
	}
	return 0;
    80002894:	4501                	li	a0,0
}
    80002896:	70a2                	ld	ra,40(sp)
    80002898:	7402                	ld	s0,32(sp)
    8000289a:	64e2                	ld	s1,24(sp)
    8000289c:	6942                	ld	s2,16(sp)
    8000289e:	69a2                	ld	s3,8(sp)
    800028a0:	6a02                	ld	s4,0(sp)
    800028a2:	6145                	addi	sp,sp,48
    800028a4:	8082                	ret
	return 0;
    800028a6:	4501                	li	a0,0
    800028a8:	b7fd                	j	80002896 <settickets+0x72>
		return -1;
    800028aa:	557d                	li	a0,-1
}
    800028ac:	8082                	ret

00000000800028ae <swtch>:
    800028ae:	00153023          	sd	ra,0(a0)
    800028b2:	00253423          	sd	sp,8(a0)
    800028b6:	e900                	sd	s0,16(a0)
    800028b8:	ed04                	sd	s1,24(a0)
    800028ba:	03253023          	sd	s2,32(a0)
    800028be:	03353423          	sd	s3,40(a0)
    800028c2:	03453823          	sd	s4,48(a0)
    800028c6:	03553c23          	sd	s5,56(a0)
    800028ca:	05653023          	sd	s6,64(a0)
    800028ce:	05753423          	sd	s7,72(a0)
    800028d2:	05853823          	sd	s8,80(a0)
    800028d6:	05953c23          	sd	s9,88(a0)
    800028da:	07a53023          	sd	s10,96(a0)
    800028de:	07b53423          	sd	s11,104(a0)
    800028e2:	0005b083          	ld	ra,0(a1)
    800028e6:	0085b103          	ld	sp,8(a1)
    800028ea:	6980                	ld	s0,16(a1)
    800028ec:	6d84                	ld	s1,24(a1)
    800028ee:	0205b903          	ld	s2,32(a1)
    800028f2:	0285b983          	ld	s3,40(a1)
    800028f6:	0305ba03          	ld	s4,48(a1)
    800028fa:	0385ba83          	ld	s5,56(a1)
    800028fe:	0405bb03          	ld	s6,64(a1)
    80002902:	0485bb83          	ld	s7,72(a1)
    80002906:	0505bc03          	ld	s8,80(a1)
    8000290a:	0585bc83          	ld	s9,88(a1)
    8000290e:	0605bd03          	ld	s10,96(a1)
    80002912:	0685bd83          	ld	s11,104(a1)
    80002916:	8082                	ret

0000000080002918 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002918:	1141                	addi	sp,sp,-16
    8000291a:	e406                	sd	ra,8(sp)
    8000291c:	e022                	sd	s0,0(sp)
    8000291e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002920:	00006597          	auipc	a1,0x6
    80002924:	ab858593          	addi	a1,a1,-1352 # 800083d8 <queue.0+0x10>
    80002928:	00015517          	auipc	a0,0x15
    8000292c:	ba850513          	addi	a0,a0,-1112 # 800174d0 <tickslock>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	210080e7          	jalr	528(ra) # 80000b40 <initlock>
}
    80002938:	60a2                	ld	ra,8(sp)
    8000293a:	6402                	ld	s0,0(sp)
    8000293c:	0141                	addi	sp,sp,16
    8000293e:	8082                	ret

0000000080002940 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002940:	1141                	addi	sp,sp,-16
    80002942:	e422                	sd	s0,8(sp)
    80002944:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002946:	00003797          	auipc	a5,0x3
    8000294a:	51a78793          	addi	a5,a5,1306 # 80005e60 <kernelvec>
    8000294e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002952:	6422                	ld	s0,8(sp)
    80002954:	0141                	addi	sp,sp,16
    80002956:	8082                	ret

0000000080002958 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002958:	1141                	addi	sp,sp,-16
    8000295a:	e406                	sd	ra,8(sp)
    8000295c:	e022                	sd	s0,0(sp)
    8000295e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	0e0080e7          	jalr	224(ra) # 80001a40 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002968:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000296c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002972:	00004697          	auipc	a3,0x4
    80002976:	68e68693          	addi	a3,a3,1678 # 80007000 <_trampoline>
    8000297a:	00004717          	auipc	a4,0x4
    8000297e:	68670713          	addi	a4,a4,1670 # 80007000 <_trampoline>
    80002982:	8f15                	sub	a4,a4,a3
    80002984:	040007b7          	lui	a5,0x4000
    80002988:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000298a:	07b2                	slli	a5,a5,0xc
    8000298c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298e:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002992:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002994:	18002673          	csrr	a2,satp
    80002998:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000299a:	6d30                	ld	a2,88(a0)
    8000299c:	6138                	ld	a4,64(a0)
    8000299e:	6585                	lui	a1,0x1
    800029a0:	972e                	add	a4,a4,a1
    800029a2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029a4:	6d38                	ld	a4,88(a0)
    800029a6:	00000617          	auipc	a2,0x0
    800029aa:	13860613          	addi	a2,a2,312 # 80002ade <usertrap>
    800029ae:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029b0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029b2:	8612                	mv	a2,tp
    800029b4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029ba:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029be:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029c6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c8:	6f18                	ld	a4,24(a4)
    800029ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ce:	692c                	ld	a1,80(a0)
    800029d0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029d2:	00004717          	auipc	a4,0x4
    800029d6:	6be70713          	addi	a4,a4,1726 # 80007090 <userret>
    800029da:	8f15                	sub	a4,a4,a3
    800029dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029de:	577d                	li	a4,-1
    800029e0:	177e                	slli	a4,a4,0x3f
    800029e2:	8dd9                	or	a1,a1,a4
    800029e4:	02000537          	lui	a0,0x2000
    800029e8:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800029ea:	0536                	slli	a0,a0,0xd
    800029ec:	9782                	jalr	a5
}
    800029ee:	60a2                	ld	ra,8(sp)
    800029f0:	6402                	ld	s0,0(sp)
    800029f2:	0141                	addi	sp,sp,16
    800029f4:	8082                	ret

00000000800029f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a00:	00015497          	auipc	s1,0x15
    80002a04:	ad048493          	addi	s1,s1,-1328 # 800174d0 <tickslock>
    80002a08:	8526                	mv	a0,s1
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	1c6080e7          	jalr	454(ra) # 80000bd0 <acquire>
  ticks++;
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	62250513          	addi	a0,a0,1570 # 80009034 <ticks>
    80002a1a:	411c                	lw	a5,0(a0)
    80002a1c:	2785                	addiw	a5,a5,1
    80002a1e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	96c080e7          	jalr	-1684(ra) # 8000238c <wakeup>
  release(&tickslock);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	25a080e7          	jalr	602(ra) # 80000c84 <release>
}
    80002a32:	60e2                	ld	ra,24(sp)
    80002a34:	6442                	ld	s0,16(sp)
    80002a36:	64a2                	ld	s1,8(sp)
    80002a38:	6105                	addi	sp,sp,32
    80002a3a:	8082                	ret

0000000080002a3c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a46:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a4a:	00074d63          	bltz	a4,80002a64 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a4e:	57fd                	li	a5,-1
    80002a50:	17fe                	slli	a5,a5,0x3f
    80002a52:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a54:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a56:	06f70363          	beq	a4,a5,80002abc <devintr+0x80>
  }
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6105                	addi	sp,sp,32
    80002a62:	8082                	ret
     (scause & 0xff) == 9){
    80002a64:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a68:	46a5                	li	a3,9
    80002a6a:	fed792e3          	bne	a5,a3,80002a4e <devintr+0x12>
    int irq = plic_claim();
    80002a6e:	00003097          	auipc	ra,0x3
    80002a72:	4fa080e7          	jalr	1274(ra) # 80005f68 <plic_claim>
    80002a76:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a78:	47a9                	li	a5,10
    80002a7a:	02f50763          	beq	a0,a5,80002aa8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a7e:	4785                	li	a5,1
    80002a80:	02f50963          	beq	a0,a5,80002ab2 <devintr+0x76>
    return 1;
    80002a84:	4505                	li	a0,1
    } else if(irq){
    80002a86:	d8f1                	beqz	s1,80002a5a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a88:	85a6                	mv	a1,s1
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	95650513          	addi	a0,a0,-1706 # 800083e0 <queue.0+0x18>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	af2080e7          	jalr	-1294(ra) # 80000584 <printf>
      plic_complete(irq);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	00003097          	auipc	ra,0x3
    80002aa0:	4f0080e7          	jalr	1264(ra) # 80005f8c <plic_complete>
    return 1;
    80002aa4:	4505                	li	a0,1
    80002aa6:	bf55                	j	80002a5a <devintr+0x1e>
      uartintr();
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	eea080e7          	jalr	-278(ra) # 80000992 <uartintr>
    80002ab0:	b7ed                	j	80002a9a <devintr+0x5e>
      virtio_disk_intr();
    80002ab2:	00004097          	auipc	ra,0x4
    80002ab6:	966080e7          	jalr	-1690(ra) # 80006418 <virtio_disk_intr>
    80002aba:	b7c5                	j	80002a9a <devintr+0x5e>
    if(cpuid() == 0){
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	f58080e7          	jalr	-168(ra) # 80001a14 <cpuid>
    80002ac4:	c901                	beqz	a0,80002ad4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ac6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002acc:	14479073          	csrw	sip,a5
    return 2;
    80002ad0:	4509                	li	a0,2
    80002ad2:	b761                	j	80002a5a <devintr+0x1e>
      clockintr();
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	f22080e7          	jalr	-222(ra) # 800029f6 <clockintr>
    80002adc:	b7ed                	j	80002ac6 <devintr+0x8a>

0000000080002ade <usertrap>:
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	e04a                	sd	s2,0(sp)
    80002ae8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aee:	1007f793          	andi	a5,a5,256
    80002af2:	e3ad                	bnez	a5,80002b54 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af4:	00003797          	auipc	a5,0x3
    80002af8:	36c78793          	addi	a5,a5,876 # 80005e60 <kernelvec>
    80002afc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	f40080e7          	jalr	-192(ra) # 80001a40 <myproc>
    80002b08:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b0a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0c:	14102773          	csrr	a4,sepc
    80002b10:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b12:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b16:	47a1                	li	a5,8
    80002b18:	04f71c63          	bne	a4,a5,80002b70 <usertrap+0x92>
    if(p->killed)
    80002b1c:	551c                	lw	a5,40(a0)
    80002b1e:	e3b9                	bnez	a5,80002b64 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b20:	6cb8                	ld	a4,88(s1)
    80002b22:	6f1c                	ld	a5,24(a4)
    80002b24:	0791                	addi	a5,a5,4
    80002b26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b30:	10079073          	csrw	sstatus,a5
    syscall();
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	2e0080e7          	jalr	736(ra) # 80002e14 <syscall>
  if(p->killed)
    80002b3c:	549c                	lw	a5,40(s1)
    80002b3e:	ebc1                	bnez	a5,80002bce <usertrap+0xf0>
  usertrapret();
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	e18080e7          	jalr	-488(ra) # 80002958 <usertrapret>
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6902                	ld	s2,0(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret
    panic("usertrap: not from user mode");
    80002b54:	00006517          	auipc	a0,0x6
    80002b58:	8ac50513          	addi	a0,a0,-1876 # 80008400 <queue.0+0x38>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	9de080e7          	jalr	-1570(ra) # 8000053a <panic>
      exit(-1);
    80002b64:	557d                	li	a0,-1
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	8f6080e7          	jalr	-1802(ra) # 8000245c <exit>
    80002b6e:	bf4d                	j	80002b20 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	ecc080e7          	jalr	-308(ra) # 80002a3c <devintr>
    80002b78:	892a                	mv	s2,a0
    80002b7a:	c501                	beqz	a0,80002b82 <usertrap+0xa4>
  if(p->killed)
    80002b7c:	549c                	lw	a5,40(s1)
    80002b7e:	c3a1                	beqz	a5,80002bbe <usertrap+0xe0>
    80002b80:	a815                	j	80002bb4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b86:	5890                	lw	a2,48(s1)
    80002b88:	00006517          	auipc	a0,0x6
    80002b8c:	89850513          	addi	a0,a0,-1896 # 80008420 <queue.0+0x58>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f4080e7          	jalr	-1548(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba0:	00006517          	auipc	a0,0x6
    80002ba4:	8b050513          	addi	a0,a0,-1872 # 80008450 <queue.0+0x88>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9dc080e7          	jalr	-1572(ra) # 80000584 <printf>
    p->killed = 1;
    80002bb0:	4785                	li	a5,1
    80002bb2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bb4:	557d                	li	a0,-1
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	8a6080e7          	jalr	-1882(ra) # 8000245c <exit>
  if(which_dev == 2)
    80002bbe:	4789                	li	a5,2
    80002bc0:	f8f910e3          	bne	s2,a5,80002b40 <usertrap+0x62>
    yield();
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	600080e7          	jalr	1536(ra) # 800021c4 <yield>
    80002bcc:	bf95                	j	80002b40 <usertrap+0x62>
  int which_dev = 0;
    80002bce:	4901                	li	s2,0
    80002bd0:	b7d5                	j	80002bb4 <usertrap+0xd6>

0000000080002bd2 <kerneltrap>:
{
    80002bd2:	7179                	addi	sp,sp,-48
    80002bd4:	f406                	sd	ra,40(sp)
    80002bd6:	f022                	sd	s0,32(sp)
    80002bd8:	ec26                	sd	s1,24(sp)
    80002bda:	e84a                	sd	s2,16(sp)
    80002bdc:	e44e                	sd	s3,8(sp)
    80002bde:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bec:	1004f793          	andi	a5,s1,256
    80002bf0:	cb85                	beqz	a5,80002c20 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bf6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bf8:	ef85                	bnez	a5,80002c30 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	e42080e7          	jalr	-446(ra) # 80002a3c <devintr>
    80002c02:	cd1d                	beqz	a0,80002c40 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c04:	4789                	li	a5,2
    80002c06:	06f50a63          	beq	a0,a5,80002c7a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c0a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0e:	10049073          	csrw	sstatus,s1
}
    80002c12:	70a2                	ld	ra,40(sp)
    80002c14:	7402                	ld	s0,32(sp)
    80002c16:	64e2                	ld	s1,24(sp)
    80002c18:	6942                	ld	s2,16(sp)
    80002c1a:	69a2                	ld	s3,8(sp)
    80002c1c:	6145                	addi	sp,sp,48
    80002c1e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c20:	00006517          	auipc	a0,0x6
    80002c24:	85050513          	addi	a0,a0,-1968 # 80008470 <queue.0+0xa8>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	912080e7          	jalr	-1774(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c30:	00006517          	auipc	a0,0x6
    80002c34:	86850513          	addi	a0,a0,-1944 # 80008498 <queue.0+0xd0>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	902080e7          	jalr	-1790(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002c40:	85ce                	mv	a1,s3
    80002c42:	00006517          	auipc	a0,0x6
    80002c46:	87650513          	addi	a0,a0,-1930 # 800084b8 <queue.0+0xf0>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	93a080e7          	jalr	-1734(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c56:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c5a:	00006517          	auipc	a0,0x6
    80002c5e:	86e50513          	addi	a0,a0,-1938 # 800084c8 <queue.0+0x100>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	922080e7          	jalr	-1758(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002c6a:	00006517          	auipc	a0,0x6
    80002c6e:	87650513          	addi	a0,a0,-1930 # 800084e0 <queue.0+0x118>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8c8080e7          	jalr	-1848(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	dc6080e7          	jalr	-570(ra) # 80001a40 <myproc>
    80002c82:	d541                	beqz	a0,80002c0a <kerneltrap+0x38>
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	dbc080e7          	jalr	-580(ra) # 80001a40 <myproc>
    80002c8c:	4d18                	lw	a4,24(a0)
    80002c8e:	4791                	li	a5,4
    80002c90:	f6f71de3          	bne	a4,a5,80002c0a <kerneltrap+0x38>
    yield();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	530080e7          	jalr	1328(ra) # 800021c4 <yield>
    80002c9c:	b7bd                	j	80002c0a <kerneltrap+0x38>

0000000080002c9e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	1000                	addi	s0,sp,32
    80002ca8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	d96080e7          	jalr	-618(ra) # 80001a40 <myproc>
  switch (n) {
    80002cb2:	4795                	li	a5,5
    80002cb4:	0497e163          	bltu	a5,s1,80002cf6 <argraw+0x58>
    80002cb8:	048a                	slli	s1,s1,0x2
    80002cba:	00006717          	auipc	a4,0x6
    80002cbe:	85e70713          	addi	a4,a4,-1954 # 80008518 <queue.0+0x150>
    80002cc2:	94ba                	add	s1,s1,a4
    80002cc4:	409c                	lw	a5,0(s1)
    80002cc6:	97ba                	add	a5,a5,a4
    80002cc8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cca:	6d3c                	ld	a5,88(a0)
    80002ccc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret
    return p->trapframe->a1;
    80002cd8:	6d3c                	ld	a5,88(a0)
    80002cda:	7fa8                	ld	a0,120(a5)
    80002cdc:	bfcd                	j	80002cce <argraw+0x30>
    return p->trapframe->a2;
    80002cde:	6d3c                	ld	a5,88(a0)
    80002ce0:	63c8                	ld	a0,128(a5)
    80002ce2:	b7f5                	j	80002cce <argraw+0x30>
    return p->trapframe->a3;
    80002ce4:	6d3c                	ld	a5,88(a0)
    80002ce6:	67c8                	ld	a0,136(a5)
    80002ce8:	b7dd                	j	80002cce <argraw+0x30>
    return p->trapframe->a4;
    80002cea:	6d3c                	ld	a5,88(a0)
    80002cec:	6bc8                	ld	a0,144(a5)
    80002cee:	b7c5                	j	80002cce <argraw+0x30>
    return p->trapframe->a5;
    80002cf0:	6d3c                	ld	a5,88(a0)
    80002cf2:	6fc8                	ld	a0,152(a5)
    80002cf4:	bfe9                	j	80002cce <argraw+0x30>
  panic("argraw");
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	7fa50513          	addi	a0,a0,2042 # 800084f0 <queue.0+0x128>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	83c080e7          	jalr	-1988(ra) # 8000053a <panic>

0000000080002d06 <fetchaddr>:
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	e426                	sd	s1,8(sp)
    80002d0e:	e04a                	sd	s2,0(sp)
    80002d10:	1000                	addi	s0,sp,32
    80002d12:	84aa                	mv	s1,a0
    80002d14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	d2a080e7          	jalr	-726(ra) # 80001a40 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d1e:	653c                	ld	a5,72(a0)
    80002d20:	02f4f863          	bgeu	s1,a5,80002d50 <fetchaddr+0x4a>
    80002d24:	00848713          	addi	a4,s1,8
    80002d28:	02e7e663          	bltu	a5,a4,80002d54 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d2c:	46a1                	li	a3,8
    80002d2e:	8626                	mv	a2,s1
    80002d30:	85ca                	mv	a1,s2
    80002d32:	6928                	ld	a0,80(a0)
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	9b2080e7          	jalr	-1614(ra) # 800016e6 <copyin>
    80002d3c:	00a03533          	snez	a0,a0
    80002d40:	40a00533          	neg	a0,a0
}
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	64a2                	ld	s1,8(sp)
    80002d4a:	6902                	ld	s2,0(sp)
    80002d4c:	6105                	addi	sp,sp,32
    80002d4e:	8082                	ret
    return -1;
    80002d50:	557d                	li	a0,-1
    80002d52:	bfcd                	j	80002d44 <fetchaddr+0x3e>
    80002d54:	557d                	li	a0,-1
    80002d56:	b7fd                	j	80002d44 <fetchaddr+0x3e>

0000000080002d58 <fetchstr>:
{
    80002d58:	7179                	addi	sp,sp,-48
    80002d5a:	f406                	sd	ra,40(sp)
    80002d5c:	f022                	sd	s0,32(sp)
    80002d5e:	ec26                	sd	s1,24(sp)
    80002d60:	e84a                	sd	s2,16(sp)
    80002d62:	e44e                	sd	s3,8(sp)
    80002d64:	1800                	addi	s0,sp,48
    80002d66:	892a                	mv	s2,a0
    80002d68:	84ae                	mv	s1,a1
    80002d6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	cd4080e7          	jalr	-812(ra) # 80001a40 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d74:	86ce                	mv	a3,s3
    80002d76:	864a                	mv	a2,s2
    80002d78:	85a6                	mv	a1,s1
    80002d7a:	6928                	ld	a0,80(a0)
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	9f8080e7          	jalr	-1544(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002d84:	00054763          	bltz	a0,80002d92 <fetchstr+0x3a>
  return strlen(buf);
    80002d88:	8526                	mv	a0,s1
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	0be080e7          	jalr	190(ra) # 80000e48 <strlen>
}
    80002d92:	70a2                	ld	ra,40(sp)
    80002d94:	7402                	ld	s0,32(sp)
    80002d96:	64e2                	ld	s1,24(sp)
    80002d98:	6942                	ld	s2,16(sp)
    80002d9a:	69a2                	ld	s3,8(sp)
    80002d9c:	6145                	addi	sp,sp,48
    80002d9e:	8082                	ret

0000000080002da0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	e426                	sd	s1,8(sp)
    80002da8:	1000                	addi	s0,sp,32
    80002daa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	ef2080e7          	jalr	-270(ra) # 80002c9e <argraw>
    80002db4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002db6:	4501                	li	a0,0
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6105                	addi	sp,sp,32
    80002dc0:	8082                	ret

0000000080002dc2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dc2:	1101                	addi	sp,sp,-32
    80002dc4:	ec06                	sd	ra,24(sp)
    80002dc6:	e822                	sd	s0,16(sp)
    80002dc8:	e426                	sd	s1,8(sp)
    80002dca:	1000                	addi	s0,sp,32
    80002dcc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	ed0080e7          	jalr	-304(ra) # 80002c9e <argraw>
    80002dd6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dd8:	4501                	li	a0,0
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret

0000000080002de4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	e04a                	sd	s2,0(sp)
    80002dee:	1000                	addi	s0,sp,32
    80002df0:	84ae                	mv	s1,a1
    80002df2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	eaa080e7          	jalr	-342(ra) # 80002c9e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dfc:	864a                	mv	a2,s2
    80002dfe:	85a6                	mv	a1,s1
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	f58080e7          	jalr	-168(ra) # 80002d58 <fetchstr>
}
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	64a2                	ld	s1,8(sp)
    80002e0e:	6902                	ld	s2,0(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <syscall>:
[SYS_settickets] sys_settickets,
};

void
syscall(void)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	e426                	sd	s1,8(sp)
    80002e1c:	e04a                	sd	s2,0(sp)
    80002e1e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	c20080e7          	jalr	-992(ra) # 80001a40 <myproc>
    80002e28:	84aa                	mv	s1,a0
  count_syscall++;
    80002e2a:	00006717          	auipc	a4,0x6
    80002e2e:	20e70713          	addi	a4,a4,526 # 80009038 <count_syscall>
    80002e32:	631c                	ld	a5,0(a4)
    80002e34:	0785                	addi	a5,a5,1
    80002e36:	e31c                	sd	a5,0(a4)

  num = p->trapframe->a7;
    80002e38:	05853903          	ld	s2,88(a0)
    80002e3c:	0a893783          	ld	a5,168(s2)
    80002e40:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e44:	37fd                	addiw	a5,a5,-1
    80002e46:	475d                	li	a4,23
    80002e48:	00f76f63          	bltu	a4,a5,80002e66 <syscall+0x52>
    80002e4c:	00369713          	slli	a4,a3,0x3
    80002e50:	00005797          	auipc	a5,0x5
    80002e54:	6e078793          	addi	a5,a5,1760 # 80008530 <syscalls>
    80002e58:	97ba                	add	a5,a5,a4
    80002e5a:	639c                	ld	a5,0(a5)
    80002e5c:	c789                	beqz	a5,80002e66 <syscall+0x52>
    p->trapframe->a0 = syscalls[num]();
    80002e5e:	9782                	jalr	a5
    80002e60:	06a93823          	sd	a0,112(s2)
    80002e64:	a839                	j	80002e82 <syscall+0x6e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e66:	15848613          	addi	a2,s1,344
    80002e6a:	588c                	lw	a1,48(s1)
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	68c50513          	addi	a0,a0,1676 # 800084f8 <queue.0+0x130>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	710080e7          	jalr	1808(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e7c:	6cbc                	ld	a5,88(s1)
    80002e7e:	577d                	li	a4,-1
    80002e80:	fbb8                	sd	a4,112(a5)
  }
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret

0000000080002e8e <sys_exit>:

uint64 count_syscall = 0;

uint64
sys_exit(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e96:	fec40593          	addi	a1,s0,-20
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	f04080e7          	jalr	-252(ra) # 80002da0 <argint>
    return -1;
    80002ea4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ea6:	00054963          	bltz	a0,80002eb8 <sys_exit+0x2a>
  exit(n);
    80002eaa:	fec42503          	lw	a0,-20(s0)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	5ae080e7          	jalr	1454(ra) # 8000245c <exit>
  return 0;  // not reached
    80002eb6:	4781                	li	a5,0
}
    80002eb8:	853e                	mv	a0,a5
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	6105                	addi	sp,sp,32
    80002ec0:	8082                	ret

0000000080002ec2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ec2:	1141                	addi	sp,sp,-16
    80002ec4:	e406                	sd	ra,8(sp)
    80002ec6:	e022                	sd	s0,0(sp)
    80002ec8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	b76080e7          	jalr	-1162(ra) # 80001a40 <myproc>
}
    80002ed2:	5908                	lw	a0,48(a0)
    80002ed4:	60a2                	ld	ra,8(sp)
    80002ed6:	6402                	ld	s0,0(sp)
    80002ed8:	0141                	addi	sp,sp,16
    80002eda:	8082                	ret

0000000080002edc <sys_fork>:

uint64
sys_fork(void)
{
    80002edc:	1141                	addi	sp,sp,-16
    80002ede:	e406                	sd	ra,8(sp)
    80002ee0:	e022                	sd	s0,0(sp)
    80002ee2:	0800                	addi	s0,sp,16
  return fork();
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	f3e080e7          	jalr	-194(ra) # 80001e22 <fork>
}
    80002eec:	60a2                	ld	ra,8(sp)
    80002eee:	6402                	ld	s0,0(sp)
    80002ef0:	0141                	addi	sp,sp,16
    80002ef2:	8082                	ret

0000000080002ef4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002efc:	fe840593          	addi	a1,s0,-24
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	ec0080e7          	jalr	-320(ra) # 80002dc2 <argaddr>
    80002f0a:	87aa                	mv	a5,a0
    return -1;
    80002f0c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f0e:	0007c863          	bltz	a5,80002f1e <sys_wait+0x2a>
  return wait(p);
    80002f12:	fe843503          	ld	a0,-24(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	34e080e7          	jalr	846(ra) # 80002264 <wait>
}
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f30:	fdc40593          	addi	a1,s0,-36
    80002f34:	4501                	li	a0,0
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	e6a080e7          	jalr	-406(ra) # 80002da0 <argint>
    80002f3e:	87aa                	mv	a5,a0
    return -1;
    80002f40:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f42:	0207c063          	bltz	a5,80002f62 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	afa080e7          	jalr	-1286(ra) # 80001a40 <myproc>
    80002f4e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f50:	fdc42503          	lw	a0,-36(s0)
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	e56080e7          	jalr	-426(ra) # 80001daa <growproc>
    80002f5c:	00054863          	bltz	a0,80002f6c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f60:	8526                	mv	a0,s1
}
    80002f62:	70a2                	ld	ra,40(sp)
    80002f64:	7402                	ld	s0,32(sp)
    80002f66:	64e2                	ld	s1,24(sp)
    80002f68:	6145                	addi	sp,sp,48
    80002f6a:	8082                	ret
    return -1;
    80002f6c:	557d                	li	a0,-1
    80002f6e:	bfd5                	j	80002f62 <sys_sbrk+0x3c>

0000000080002f70 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f70:	7139                	addi	sp,sp,-64
    80002f72:	fc06                	sd	ra,56(sp)
    80002f74:	f822                	sd	s0,48(sp)
    80002f76:	f426                	sd	s1,40(sp)
    80002f78:	f04a                	sd	s2,32(sp)
    80002f7a:	ec4e                	sd	s3,24(sp)
    80002f7c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f7e:	fcc40593          	addi	a1,s0,-52
    80002f82:	4501                	li	a0,0
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	e1c080e7          	jalr	-484(ra) # 80002da0 <argint>
    return -1;
    80002f8c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f8e:	06054563          	bltz	a0,80002ff8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f92:	00014517          	auipc	a0,0x14
    80002f96:	53e50513          	addi	a0,a0,1342 # 800174d0 <tickslock>
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	c36080e7          	jalr	-970(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002fa2:	00006917          	auipc	s2,0x6
    80002fa6:	09292903          	lw	s2,146(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80002faa:	fcc42783          	lw	a5,-52(s0)
    80002fae:	cf85                	beqz	a5,80002fe6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fb0:	00014997          	auipc	s3,0x14
    80002fb4:	52098993          	addi	s3,s3,1312 # 800174d0 <tickslock>
    80002fb8:	00006497          	auipc	s1,0x6
    80002fbc:	07c48493          	addi	s1,s1,124 # 80009034 <ticks>
    if(myproc()->killed){
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	a80080e7          	jalr	-1408(ra) # 80001a40 <myproc>
    80002fc8:	551c                	lw	a5,40(a0)
    80002fca:	ef9d                	bnez	a5,80003008 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fcc:	85ce                	mv	a1,s3
    80002fce:	8526                	mv	a0,s1
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	230080e7          	jalr	560(ra) # 80002200 <sleep>
  while(ticks - ticks0 < n){
    80002fd8:	409c                	lw	a5,0(s1)
    80002fda:	412787bb          	subw	a5,a5,s2
    80002fde:	fcc42703          	lw	a4,-52(s0)
    80002fe2:	fce7efe3          	bltu	a5,a4,80002fc0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	4ea50513          	addi	a0,a0,1258 # 800174d0 <tickslock>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	c96080e7          	jalr	-874(ra) # 80000c84 <release>
  return 0;
    80002ff6:	4781                	li	a5,0
}
    80002ff8:	853e                	mv	a0,a5
    80002ffa:	70e2                	ld	ra,56(sp)
    80002ffc:	7442                	ld	s0,48(sp)
    80002ffe:	74a2                	ld	s1,40(sp)
    80003000:	7902                	ld	s2,32(sp)
    80003002:	69e2                	ld	s3,24(sp)
    80003004:	6121                	addi	sp,sp,64
    80003006:	8082                	ret
      release(&tickslock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	4c850513          	addi	a0,a0,1224 # 800174d0 <tickslock>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	c74080e7          	jalr	-908(ra) # 80000c84 <release>
      return -1;
    80003018:	57fd                	li	a5,-1
    8000301a:	bff9                	j	80002ff8 <sys_sleep+0x88>

000000008000301c <sys_kill>:

uint64
sys_kill(void)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003024:	fec40593          	addi	a1,s0,-20
    80003028:	4501                	li	a0,0
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	d76080e7          	jalr	-650(ra) # 80002da0 <argint>
    80003032:	87aa                	mv	a5,a0
    return -1;
    80003034:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003036:	0007c863          	bltz	a5,80003046 <sys_kill+0x2a>
  return kill(pid);
    8000303a:	fec42503          	lw	a0,-20(s0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	4f4080e7          	jalr	1268(ra) # 80002532 <kill>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret

000000008000304e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	47850513          	addi	a0,a0,1144 # 800174d0 <tickslock>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	b70080e7          	jalr	-1168(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80003068:	00006497          	auipc	s1,0x6
    8000306c:	fcc4a483          	lw	s1,-52(s1) # 80009034 <ticks>
  release(&tickslock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	46050513          	addi	a0,a0,1120 # 800174d0 <tickslock>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	c0c080e7          	jalr	-1012(ra) # 80000c84 <release>
  return xticks;
}
    80003080:	02049513          	slli	a0,s1,0x20
    80003084:	9101                	srli	a0,a0,0x20
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <sys_getsyscallinfo>:

uint64
sys_getsyscallinfo(void)
{
    80003090:	1141                	addi	sp,sp,-16
    80003092:	e422                	sd	s0,8(sp)
    80003094:	0800                	addi	s0,sp,16
   return count_syscall;
}
    80003096:	00006517          	auipc	a0,0x6
    8000309a:	fa253503          	ld	a0,-94(a0) # 80009038 <count_syscall>
    8000309e:	6422                	ld	s0,8(sp)
    800030a0:	0141                	addi	sp,sp,16
    800030a2:	8082                	ret

00000000800030a4 <sys_cps>:

uint64
sys_cps(void)
{
    800030a4:	1141                	addi	sp,sp,-16
    800030a6:	e406                	sd	ra,8(sp)
    800030a8:	e022                	sd	s0,0(sp)
    800030aa:	0800                	addi	s0,sp,16
	return cps();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	654080e7          	jalr	1620(ra) # 80002700 <cps>
}
    800030b4:	60a2                	ld	ra,8(sp)
    800030b6:	6402                	ld	s0,0(sp)
    800030b8:	0141                	addi	sp,sp,16
    800030ba:	8082                	ret

00000000800030bc <sys_settickets>:

uint64
sys_settickets(void)
{
    800030bc:	7179                	addi	sp,sp,-48
    800030be:	f406                	sd	ra,40(sp)
    800030c0:	f022                	sd	s0,32(sp)
    800030c2:	ec26                	sd	s1,24(sp)
    800030c4:	1800                	addi	s0,sp,48
	int num;
	int pid = myproc()->pid;
    800030c6:	fffff097          	auipc	ra,0xfffff
    800030ca:	97a080e7          	jalr	-1670(ra) # 80001a40 <myproc>
    800030ce:	5904                	lw	s1,48(a0)
	if (argint (0, &num) < 0)
    800030d0:	fdc40593          	addi	a1,s0,-36
    800030d4:	4501                	li	a0,0
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	cca080e7          	jalr	-822(ra) # 80002da0 <argint>
    800030de:	87aa                	mv	a5,a0
		return -1;
    800030e0:	557d                	li	a0,-1
	if (argint (0, &num) < 0)
    800030e2:	0007c963          	bltz	a5,800030f4 <sys_settickets+0x38>
	return settickets (pid, num);
    800030e6:	fdc42583          	lw	a1,-36(s0)
    800030ea:	8526                	mv	a0,s1
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	738080e7          	jalr	1848(ra) # 80002824 <settickets>
}
    800030f4:	70a2                	ld	ra,40(sp)
    800030f6:	7402                	ld	s0,32(sp)
    800030f8:	64e2                	ld	s1,24(sp)
    800030fa:	6145                	addi	sp,sp,48
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
    80003112:	4ea58593          	addi	a1,a1,1258 # 800085f8 <syscalls+0xc8>
    80003116:	00014517          	auipc	a0,0x14
    8000311a:	3d250513          	addi	a0,a0,978 # 800174e8 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	a22080e7          	jalr	-1502(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003126:	0001c797          	auipc	a5,0x1c
    8000312a:	3c278793          	addi	a5,a5,962 # 8001f4e8 <bcache+0x8000>
    8000312e:	0001c717          	auipc	a4,0x1c
    80003132:	62270713          	addi	a4,a4,1570 # 8001f750 <bcache+0x8268>
    80003136:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000313a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000313e:	00014497          	auipc	s1,0x14
    80003142:	3c248493          	addi	s1,s1,962 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80003146:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003148:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000314a:	00005a17          	auipc	s4,0x5
    8000314e:	4b6a0a13          	addi	s4,s4,1206 # 80008600 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003152:	2b893783          	ld	a5,696(s2)
    80003156:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003158:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000315c:	85d2                	mv	a1,s4
    8000315e:	01048513          	addi	a0,s1,16
    80003162:	00001097          	auipc	ra,0x1
    80003166:	4c2080e7          	jalr	1218(ra) # 80004624 <initsleeplock>
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
    8000319a:	892a                	mv	s2,a0
    8000319c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000319e:	00014517          	auipc	a0,0x14
    800031a2:	34a50513          	addi	a0,a0,842 # 800174e8 <bcache>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	a2a080e7          	jalr	-1494(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ae:	0001c497          	auipc	s1,0x1c
    800031b2:	5f24b483          	ld	s1,1522(s1) # 8001f7a0 <bcache+0x82b8>
    800031b6:	0001c797          	auipc	a5,0x1c
    800031ba:	59a78793          	addi	a5,a5,1434 # 8001f750 <bcache+0x8268>
    800031be:	02f48f63          	beq	s1,a5,800031fc <bread+0x70>
    800031c2:	873e                	mv	a4,a5
    800031c4:	a021                	j	800031cc <bread+0x40>
    800031c6:	68a4                	ld	s1,80(s1)
    800031c8:	02e48a63          	beq	s1,a4,800031fc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031cc:	449c                	lw	a5,8(s1)
    800031ce:	ff279ce3          	bne	a5,s2,800031c6 <bread+0x3a>
    800031d2:	44dc                	lw	a5,12(s1)
    800031d4:	ff3799e3          	bne	a5,s3,800031c6 <bread+0x3a>
      b->refcnt++;
    800031d8:	40bc                	lw	a5,64(s1)
    800031da:	2785                	addiw	a5,a5,1
    800031dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	30a50513          	addi	a0,a0,778 # 800174e8 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	a9e080e7          	jalr	-1378(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800031ee:	01048513          	addi	a0,s1,16
    800031f2:	00001097          	auipc	ra,0x1
    800031f6:	46c080e7          	jalr	1132(ra) # 8000465e <acquiresleep>
      return b;
    800031fa:	a8b9                	j	80003258 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031fc:	0001c497          	auipc	s1,0x1c
    80003200:	59c4b483          	ld	s1,1436(s1) # 8001f798 <bcache+0x82b0>
    80003204:	0001c797          	auipc	a5,0x1c
    80003208:	54c78793          	addi	a5,a5,1356 # 8001f750 <bcache+0x8268>
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
    80003220:	3ec50513          	addi	a0,a0,1004 # 80008608 <syscalls+0xd8>
    80003224:	ffffd097          	auipc	ra,0xffffd
    80003228:	316080e7          	jalr	790(ra) # 8000053a <panic>
      b->dev = dev;
    8000322c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003230:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003234:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003238:	4785                	li	a5,1
    8000323a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000323c:	00014517          	auipc	a0,0x14
    80003240:	2ac50513          	addi	a0,a0,684 # 800174e8 <bcache>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	a40080e7          	jalr	-1472(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000324c:	01048513          	addi	a0,s1,16
    80003250:	00001097          	auipc	ra,0x1
    80003254:	40e080e7          	jalr	1038(ra) # 8000465e <acquiresleep>
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
    80003274:	f22080e7          	jalr	-222(ra) # 80006192 <virtio_disk_rw>
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
    80003290:	46c080e7          	jalr	1132(ra) # 800046f8 <holdingsleep>
    80003294:	cd01                	beqz	a0,800032ac <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003296:	4585                	li	a1,1
    80003298:	8526                	mv	a0,s1
    8000329a:	00003097          	auipc	ra,0x3
    8000329e:	ef8080e7          	jalr	-264(ra) # 80006192 <virtio_disk_rw>
}
    800032a2:	60e2                	ld	ra,24(sp)
    800032a4:	6442                	ld	s0,16(sp)
    800032a6:	64a2                	ld	s1,8(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret
    panic("bwrite");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	37450513          	addi	a0,a0,884 # 80008620 <syscalls+0xf0>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	286080e7          	jalr	646(ra) # 8000053a <panic>

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
    800032d4:	428080e7          	jalr	1064(ra) # 800046f8 <holdingsleep>
    800032d8:	c92d                	beqz	a0,8000334a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032da:	854a                	mv	a0,s2
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	3d8080e7          	jalr	984(ra) # 800046b4 <releasesleep>

  acquire(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	20450513          	addi	a0,a0,516 # 800174e8 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8e4080e7          	jalr	-1820(ra) # 80000bd0 <acquire>
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
    80003310:	1dc78793          	addi	a5,a5,476 # 8001f4e8 <bcache+0x8000>
    80003314:	2b87b703          	ld	a4,696(a5)
    80003318:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000331a:	0001c717          	auipc	a4,0x1c
    8000331e:	43670713          	addi	a4,a4,1078 # 8001f750 <bcache+0x8268>
    80003322:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003324:	2b87b703          	ld	a4,696(a5)
    80003328:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000332a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000332e:	00014517          	auipc	a0,0x14
    80003332:	1ba50513          	addi	a0,a0,442 # 800174e8 <bcache>
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	94e080e7          	jalr	-1714(ra) # 80000c84 <release>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6902                	ld	s2,0(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret
    panic("brelse");
    8000334a:	00005517          	auipc	a0,0x5
    8000334e:	2de50513          	addi	a0,a0,734 # 80008628 <syscalls+0xf8>
    80003352:	ffffd097          	auipc	ra,0xffffd
    80003356:	1e8080e7          	jalr	488(ra) # 8000053a <panic>

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
    8000336a:	18250513          	addi	a0,a0,386 # 800174e8 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	862080e7          	jalr	-1950(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003376:	40bc                	lw	a5,64(s1)
    80003378:	2785                	addiw	a5,a5,1
    8000337a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337c:	00014517          	auipc	a0,0x14
    80003380:	16c50513          	addi	a0,a0,364 # 800174e8 <bcache>
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	900080e7          	jalr	-1792(ra) # 80000c84 <release>
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
    800033a6:	14650513          	addi	a0,a0,326 # 800174e8 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	826080e7          	jalr	-2010(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800033b2:	40bc                	lw	a5,64(s1)
    800033b4:	37fd                	addiw	a5,a5,-1
    800033b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b8:	00014517          	auipc	a0,0x14
    800033bc:	13050513          	addi	a0,a0,304 # 800174e8 <bcache>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8c4080e7          	jalr	-1852(ra) # 80000c84 <release>
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
    800033e4:	0001c797          	auipc	a5,0x1c
    800033e8:	7e07a783          	lw	a5,2016(a5) # 8001fbc4 <sb+0x1c>
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
    8000341a:	8f7d                	and	a4,a4,a5
    8000341c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003420:	00001097          	auipc	ra,0x1
    80003424:	120080e7          	jalr	288(ra) # 80004540 <log_write>
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
    80003442:	1f250513          	addi	a0,a0,498 # 80008630 <syscalls+0x100>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	0f4080e7          	jalr	244(ra) # 8000053a <panic>

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
    80003468:	0001c797          	auipc	a5,0x1c
    8000346c:	7447a783          	lw	a5,1860(a5) # 8001fbac <sb+0x4>
    80003470:	cbc1                	beqz	a5,80003500 <balloc+0xb2>
    80003472:	8baa                	mv	s7,a0
    80003474:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003476:	0001cb17          	auipc	s6,0x1c
    8000347a:	732b0b13          	addi	s6,s6,1842 # 8001fba8 <sb>
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
    8000349e:	06eaf163          	bgeu	s5,a4,80003500 <balloc+0xb2>
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
    800034cc:	8762                	mv	a4,s8
    800034ce:	faa4fde3          	bgeu	s1,a0,80003488 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034d2:	00777693          	andi	a3,a4,7
    800034d6:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034da:	41f7579b          	sraiw	a5,a4,0x1f
    800034de:	01d7d79b          	srliw	a5,a5,0x1d
    800034e2:	9fb9                	addw	a5,a5,a4
    800034e4:	4037d79b          	sraiw	a5,a5,0x3
    800034e8:	00f90633          	add	a2,s2,a5
    800034ec:	05864603          	lbu	a2,88(a2)
    800034f0:	00c6f5b3          	and	a1,a3,a2
    800034f4:	cd91                	beqz	a1,80003510 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f6:	2705                	addiw	a4,a4,1
    800034f8:	2485                	addiw	s1,s1,1
    800034fa:	fd471ae3          	bne	a4,s4,800034ce <balloc+0x80>
    800034fe:	b769                	j	80003488 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003500:	00005517          	auipc	a0,0x5
    80003504:	14850513          	addi	a0,a0,328 # 80008648 <syscalls+0x118>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	032080e7          	jalr	50(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003510:	97ca                	add	a5,a5,s2
    80003512:	8e55                	or	a2,a2,a3
    80003514:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	026080e7          	jalr	38(ra) # 80004540 <log_write>
        brelse(bp);
    80003522:	854a                	mv	a0,s2
    80003524:	00000097          	auipc	ra,0x0
    80003528:	d98080e7          	jalr	-616(ra) # 800032bc <brelse>
  bp = bread(dev, bno);
    8000352c:	85a6                	mv	a1,s1
    8000352e:	855e                	mv	a0,s7
    80003530:	00000097          	auipc	ra,0x0
    80003534:	c5c080e7          	jalr	-932(ra) # 8000318c <bread>
    80003538:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000353a:	40000613          	li	a2,1024
    8000353e:	4581                	li	a1,0
    80003540:	05850513          	addi	a0,a0,88
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	788080e7          	jalr	1928(ra) # 80000ccc <memset>
  log_write(bp);
    8000354c:	854a                	mv	a0,s2
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	ff2080e7          	jalr	-14(ra) # 80004540 <log_write>
  brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	d64080e7          	jalr	-668(ra) # 800032bc <brelse>
}
    80003560:	8526                	mv	a0,s1
    80003562:	60e6                	ld	ra,88(sp)
    80003564:	6446                	ld	s0,80(sp)
    80003566:	64a6                	ld	s1,72(sp)
    80003568:	6906                	ld	s2,64(sp)
    8000356a:	79e2                	ld	s3,56(sp)
    8000356c:	7a42                	ld	s4,48(sp)
    8000356e:	7aa2                	ld	s5,40(sp)
    80003570:	7b02                	ld	s6,32(sp)
    80003572:	6be2                	ld	s7,24(sp)
    80003574:	6c42                	ld	s8,16(sp)
    80003576:	6ca2                	ld	s9,8(sp)
    80003578:	6125                	addi	sp,sp,96
    8000357a:	8082                	ret

000000008000357c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000357c:	7179                	addi	sp,sp,-48
    8000357e:	f406                	sd	ra,40(sp)
    80003580:	f022                	sd	s0,32(sp)
    80003582:	ec26                	sd	s1,24(sp)
    80003584:	e84a                	sd	s2,16(sp)
    80003586:	e44e                	sd	s3,8(sp)
    80003588:	e052                	sd	s4,0(sp)
    8000358a:	1800                	addi	s0,sp,48
    8000358c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000358e:	47ad                	li	a5,11
    80003590:	04b7fe63          	bgeu	a5,a1,800035ec <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003594:	ff45849b          	addiw	s1,a1,-12
    80003598:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000359c:	0ff00793          	li	a5,255
    800035a0:	0ae7e463          	bltu	a5,a4,80003648 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a4:	08052583          	lw	a1,128(a0)
    800035a8:	c5b5                	beqz	a1,80003614 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035aa:	00092503          	lw	a0,0(s2)
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	bde080e7          	jalr	-1058(ra) # 8000318c <bread>
    800035b6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035bc:	02049713          	slli	a4,s1,0x20
    800035c0:	01e75593          	srli	a1,a4,0x1e
    800035c4:	00b784b3          	add	s1,a5,a1
    800035c8:	0004a983          	lw	s3,0(s1)
    800035cc:	04098e63          	beqz	s3,80003628 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035d0:	8552                	mv	a0,s4
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	cea080e7          	jalr	-790(ra) # 800032bc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035da:	854e                	mv	a0,s3
    800035dc:	70a2                	ld	ra,40(sp)
    800035de:	7402                	ld	s0,32(sp)
    800035e0:	64e2                	ld	s1,24(sp)
    800035e2:	6942                	ld	s2,16(sp)
    800035e4:	69a2                	ld	s3,8(sp)
    800035e6:	6a02                	ld	s4,0(sp)
    800035e8:	6145                	addi	sp,sp,48
    800035ea:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035ec:	02059793          	slli	a5,a1,0x20
    800035f0:	01e7d593          	srli	a1,a5,0x1e
    800035f4:	00b504b3          	add	s1,a0,a1
    800035f8:	0504a983          	lw	s3,80(s1)
    800035fc:	fc099fe3          	bnez	s3,800035da <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003600:	4108                	lw	a0,0(a0)
    80003602:	00000097          	auipc	ra,0x0
    80003606:	e4c080e7          	jalr	-436(ra) # 8000344e <balloc>
    8000360a:	0005099b          	sext.w	s3,a0
    8000360e:	0534a823          	sw	s3,80(s1)
    80003612:	b7e1                	j	800035da <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003614:	4108                	lw	a0,0(a0)
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e38080e7          	jalr	-456(ra) # 8000344e <balloc>
    8000361e:	0005059b          	sext.w	a1,a0
    80003622:	08b92023          	sw	a1,128(s2)
    80003626:	b751                	j	800035aa <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003628:	00092503          	lw	a0,0(s2)
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	e22080e7          	jalr	-478(ra) # 8000344e <balloc>
    80003634:	0005099b          	sext.w	s3,a0
    80003638:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000363c:	8552                	mv	a0,s4
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	f02080e7          	jalr	-254(ra) # 80004540 <log_write>
    80003646:	b769                	j	800035d0 <bmap+0x54>
  panic("bmap: out of range");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	01850513          	addi	a0,a0,24 # 80008660 <syscalls+0x130>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	eea080e7          	jalr	-278(ra) # 8000053a <panic>

0000000080003658 <iget>:
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	e052                	sd	s4,0(sp)
    80003666:	1800                	addi	s0,sp,48
    80003668:	89aa                	mv	s3,a0
    8000366a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000366c:	0001c517          	auipc	a0,0x1c
    80003670:	55c50513          	addi	a0,a0,1372 # 8001fbc8 <itable>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	55c080e7          	jalr	1372(ra) # 80000bd0 <acquire>
  empty = 0;
    8000367c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000367e:	0001c497          	auipc	s1,0x1c
    80003682:	56248493          	addi	s1,s1,1378 # 8001fbe0 <itable+0x18>
    80003686:	0001e697          	auipc	a3,0x1e
    8000368a:	fea68693          	addi	a3,a3,-22 # 80021670 <log>
    8000368e:	a039                	j	8000369c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003690:	02090b63          	beqz	s2,800036c6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003694:	08848493          	addi	s1,s1,136
    80003698:	02d48a63          	beq	s1,a3,800036cc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000369c:	449c                	lw	a5,8(s1)
    8000369e:	fef059e3          	blez	a5,80003690 <iget+0x38>
    800036a2:	4098                	lw	a4,0(s1)
    800036a4:	ff3716e3          	bne	a4,s3,80003690 <iget+0x38>
    800036a8:	40d8                	lw	a4,4(s1)
    800036aa:	ff4713e3          	bne	a4,s4,80003690 <iget+0x38>
      ip->ref++;
    800036ae:	2785                	addiw	a5,a5,1
    800036b0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036b2:	0001c517          	auipc	a0,0x1c
    800036b6:	51650513          	addi	a0,a0,1302 # 8001fbc8 <itable>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5ca080e7          	jalr	1482(ra) # 80000c84 <release>
      return ip;
    800036c2:	8926                	mv	s2,s1
    800036c4:	a03d                	j	800036f2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c6:	f7f9                	bnez	a5,80003694 <iget+0x3c>
    800036c8:	8926                	mv	s2,s1
    800036ca:	b7e9                	j	80003694 <iget+0x3c>
  if(empty == 0)
    800036cc:	02090c63          	beqz	s2,80003704 <iget+0xac>
  ip->dev = dev;
    800036d0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d8:	4785                	li	a5,1
    800036da:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036de:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036e2:	0001c517          	auipc	a0,0x1c
    800036e6:	4e650513          	addi	a0,a0,1254 # 8001fbc8 <itable>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	59a080e7          	jalr	1434(ra) # 80000c84 <release>
}
    800036f2:	854a                	mv	a0,s2
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6a02                	ld	s4,0(sp)
    80003700:	6145                	addi	sp,sp,48
    80003702:	8082                	ret
    panic("iget: no inodes");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	f7450513          	addi	a0,a0,-140 # 80008678 <syscalls+0x148>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e2e080e7          	jalr	-466(ra) # 8000053a <panic>

0000000080003714 <fsinit>:
fsinit(int dev) {
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	1800                	addi	s0,sp,48
    80003722:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003724:	4585                	li	a1,1
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	a66080e7          	jalr	-1434(ra) # 8000318c <bread>
    8000372e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003730:	0001c997          	auipc	s3,0x1c
    80003734:	47898993          	addi	s3,s3,1144 # 8001fba8 <sb>
    80003738:	02000613          	li	a2,32
    8000373c:	05850593          	addi	a1,a0,88
    80003740:	854e                	mv	a0,s3
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	5e6080e7          	jalr	1510(ra) # 80000d28 <memmove>
  brelse(bp);
    8000374a:	8526                	mv	a0,s1
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	b70080e7          	jalr	-1168(ra) # 800032bc <brelse>
  if(sb.magic != FSMAGIC)
    80003754:	0009a703          	lw	a4,0(s3)
    80003758:	102037b7          	lui	a5,0x10203
    8000375c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003760:	02f71263          	bne	a4,a5,80003784 <fsinit+0x70>
  initlog(dev, &sb);
    80003764:	0001c597          	auipc	a1,0x1c
    80003768:	44458593          	addi	a1,a1,1092 # 8001fba8 <sb>
    8000376c:	854a                	mv	a0,s2
    8000376e:	00001097          	auipc	ra,0x1
    80003772:	b56080e7          	jalr	-1194(ra) # 800042c4 <initlog>
}
    80003776:	70a2                	ld	ra,40(sp)
    80003778:	7402                	ld	s0,32(sp)
    8000377a:	64e2                	ld	s1,24(sp)
    8000377c:	6942                	ld	s2,16(sp)
    8000377e:	69a2                	ld	s3,8(sp)
    80003780:	6145                	addi	sp,sp,48
    80003782:	8082                	ret
    panic("invalid file system");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	f0450513          	addi	a0,a0,-252 # 80008688 <syscalls+0x158>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	dae080e7          	jalr	-594(ra) # 8000053a <panic>

0000000080003794 <iinit>:
{
    80003794:	7179                	addi	sp,sp,-48
    80003796:	f406                	sd	ra,40(sp)
    80003798:	f022                	sd	s0,32(sp)
    8000379a:	ec26                	sd	s1,24(sp)
    8000379c:	e84a                	sd	s2,16(sp)
    8000379e:	e44e                	sd	s3,8(sp)
    800037a0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037a2:	00005597          	auipc	a1,0x5
    800037a6:	efe58593          	addi	a1,a1,-258 # 800086a0 <syscalls+0x170>
    800037aa:	0001c517          	auipc	a0,0x1c
    800037ae:	41e50513          	addi	a0,a0,1054 # 8001fbc8 <itable>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	38e080e7          	jalr	910(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ba:	0001c497          	auipc	s1,0x1c
    800037be:	43648493          	addi	s1,s1,1078 # 8001fbf0 <itable+0x28>
    800037c2:	0001e997          	auipc	s3,0x1e
    800037c6:	ebe98993          	addi	s3,s3,-322 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037ca:	00005917          	auipc	s2,0x5
    800037ce:	ede90913          	addi	s2,s2,-290 # 800086a8 <syscalls+0x178>
    800037d2:	85ca                	mv	a1,s2
    800037d4:	8526                	mv	a0,s1
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	e4e080e7          	jalr	-434(ra) # 80004624 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037de:	08848493          	addi	s1,s1,136
    800037e2:	ff3498e3          	bne	s1,s3,800037d2 <iinit+0x3e>
}
    800037e6:	70a2                	ld	ra,40(sp)
    800037e8:	7402                	ld	s0,32(sp)
    800037ea:	64e2                	ld	s1,24(sp)
    800037ec:	6942                	ld	s2,16(sp)
    800037ee:	69a2                	ld	s3,8(sp)
    800037f0:	6145                	addi	sp,sp,48
    800037f2:	8082                	ret

00000000800037f4 <ialloc>:
{
    800037f4:	715d                	addi	sp,sp,-80
    800037f6:	e486                	sd	ra,72(sp)
    800037f8:	e0a2                	sd	s0,64(sp)
    800037fa:	fc26                	sd	s1,56(sp)
    800037fc:	f84a                	sd	s2,48(sp)
    800037fe:	f44e                	sd	s3,40(sp)
    80003800:	f052                	sd	s4,32(sp)
    80003802:	ec56                	sd	s5,24(sp)
    80003804:	e85a                	sd	s6,16(sp)
    80003806:	e45e                	sd	s7,8(sp)
    80003808:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000380a:	0001c717          	auipc	a4,0x1c
    8000380e:	3aa72703          	lw	a4,938(a4) # 8001fbb4 <sb+0xc>
    80003812:	4785                	li	a5,1
    80003814:	04e7fa63          	bgeu	a5,a4,80003868 <ialloc+0x74>
    80003818:	8aaa                	mv	s5,a0
    8000381a:	8bae                	mv	s7,a1
    8000381c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000381e:	0001ca17          	auipc	s4,0x1c
    80003822:	38aa0a13          	addi	s4,s4,906 # 8001fba8 <sb>
    80003826:	00048b1b          	sext.w	s6,s1
    8000382a:	0044d593          	srli	a1,s1,0x4
    8000382e:	018a2783          	lw	a5,24(s4)
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	8556                	mv	a0,s5
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	956080e7          	jalr	-1706(ra) # 8000318c <bread>
    8000383e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003840:	05850993          	addi	s3,a0,88
    80003844:	00f4f793          	andi	a5,s1,15
    80003848:	079a                	slli	a5,a5,0x6
    8000384a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000384c:	00099783          	lh	a5,0(s3)
    80003850:	c785                	beqz	a5,80003878 <ialloc+0x84>
    brelse(bp);
    80003852:	00000097          	auipc	ra,0x0
    80003856:	a6a080e7          	jalr	-1430(ra) # 800032bc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000385a:	0485                	addi	s1,s1,1
    8000385c:	00ca2703          	lw	a4,12(s4)
    80003860:	0004879b          	sext.w	a5,s1
    80003864:	fce7e1e3          	bltu	a5,a4,80003826 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	e4850513          	addi	a0,a0,-440 # 800086b0 <syscalls+0x180>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cca080e7          	jalr	-822(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003878:	04000613          	li	a2,64
    8000387c:	4581                	li	a1,0
    8000387e:	854e                	mv	a0,s3
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	44c080e7          	jalr	1100(ra) # 80000ccc <memset>
      dip->type = type;
    80003888:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	cb2080e7          	jalr	-846(ra) # 80004540 <log_write>
      brelse(bp);
    80003896:	854a                	mv	a0,s2
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	a24080e7          	jalr	-1500(ra) # 800032bc <brelse>
      return iget(dev, inum);
    800038a0:	85da                	mv	a1,s6
    800038a2:	8556                	mv	a0,s5
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	db4080e7          	jalr	-588(ra) # 80003658 <iget>
}
    800038ac:	60a6                	ld	ra,72(sp)
    800038ae:	6406                	ld	s0,64(sp)
    800038b0:	74e2                	ld	s1,56(sp)
    800038b2:	7942                	ld	s2,48(sp)
    800038b4:	79a2                	ld	s3,40(sp)
    800038b6:	7a02                	ld	s4,32(sp)
    800038b8:	6ae2                	ld	s5,24(sp)
    800038ba:	6b42                	ld	s6,16(sp)
    800038bc:	6ba2                	ld	s7,8(sp)
    800038be:	6161                	addi	sp,sp,80
    800038c0:	8082                	ret

00000000800038c2 <iupdate>:
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	e04a                	sd	s2,0(sp)
    800038cc:	1000                	addi	s0,sp,32
    800038ce:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d0:	415c                	lw	a5,4(a0)
    800038d2:	0047d79b          	srliw	a5,a5,0x4
    800038d6:	0001c597          	auipc	a1,0x1c
    800038da:	2ea5a583          	lw	a1,746(a1) # 8001fbc0 <sb+0x18>
    800038de:	9dbd                	addw	a1,a1,a5
    800038e0:	4108                	lw	a0,0(a0)
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	8aa080e7          	jalr	-1878(ra) # 8000318c <bread>
    800038ea:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ec:	05850793          	addi	a5,a0,88
    800038f0:	40d8                	lw	a4,4(s1)
    800038f2:	8b3d                	andi	a4,a4,15
    800038f4:	071a                	slli	a4,a4,0x6
    800038f6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038f8:	04449703          	lh	a4,68(s1)
    800038fc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003900:	04649703          	lh	a4,70(s1)
    80003904:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003908:	04849703          	lh	a4,72(s1)
    8000390c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003910:	04a49703          	lh	a4,74(s1)
    80003914:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003918:	44f8                	lw	a4,76(s1)
    8000391a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000391c:	03400613          	li	a2,52
    80003920:	05048593          	addi	a1,s1,80
    80003924:	00c78513          	addi	a0,a5,12
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	400080e7          	jalr	1024(ra) # 80000d28 <memmove>
  log_write(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	00001097          	auipc	ra,0x1
    80003936:	c0e080e7          	jalr	-1010(ra) # 80004540 <log_write>
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
    80003960:	26c50513          	addi	a0,a0,620 # 8001fbc8 <itable>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	26c080e7          	jalr	620(ra) # 80000bd0 <acquire>
  ip->ref++;
    8000396c:	449c                	lw	a5,8(s1)
    8000396e:	2785                	addiw	a5,a5,1
    80003970:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003972:	0001c517          	auipc	a0,0x1c
    80003976:	25650513          	addi	a0,a0,598 # 8001fbc8 <itable>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	30a080e7          	jalr	778(ra) # 80000c84 <release>
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
    800039aa:	cb8080e7          	jalr	-840(ra) # 8000465e <acquiresleep>
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
    800039c2:	d0a50513          	addi	a0,a0,-758 # 800086c8 <syscalls+0x198>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	b74080e7          	jalr	-1164(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ce:	40dc                	lw	a5,4(s1)
    800039d0:	0047d79b          	srliw	a5,a5,0x4
    800039d4:	0001c597          	auipc	a1,0x1c
    800039d8:	1ec5a583          	lw	a1,492(a1) # 8001fbc0 <sb+0x18>
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
    80003a28:	304080e7          	jalr	772(ra) # 80000d28 <memmove>
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
    80003a44:	c9050513          	addi	a0,a0,-880 # 800086d0 <syscalls+0x1a0>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	af2080e7          	jalr	-1294(ra) # 8000053a <panic>

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
    80003a6a:	c92080e7          	jalr	-878(ra) # 800046f8 <holdingsleep>
    80003a6e:	cd19                	beqz	a0,80003a8c <iunlock+0x3c>
    80003a70:	449c                	lw	a5,8(s1)
    80003a72:	00f05d63          	blez	a5,80003a8c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	c3c080e7          	jalr	-964(ra) # 800046b4 <releasesleep>
}
    80003a80:	60e2                	ld	ra,24(sp)
    80003a82:	6442                	ld	s0,16(sp)
    80003a84:	64a2                	ld	s1,8(sp)
    80003a86:	6902                	ld	s2,0(sp)
    80003a88:	6105                	addi	sp,sp,32
    80003a8a:	8082                	ret
    panic("iunlock");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	c5450513          	addi	a0,a0,-940 # 800086e0 <syscalls+0x1b0>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	aa6080e7          	jalr	-1370(ra) # 8000053a <panic>

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
    80003ae4:	de2080e7          	jalr	-542(ra) # 800038c2 <iupdate>
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
    80003b0e:	a021                	j	80003b16 <itrunc+0x7a>
    80003b10:	0491                	addi	s1,s1,4
    80003b12:	01248b63          	beq	s1,s2,80003b28 <itrunc+0x8c>
      if(a[j])
    80003b16:	408c                	lw	a1,0(s1)
    80003b18:	dde5                	beqz	a1,80003b10 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b1a:	0009a503          	lw	a0,0(s3)
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	8b4080e7          	jalr	-1868(ra) # 800033d2 <bfree>
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
    80003b5a:	07250513          	addi	a0,a0,114 # 8001fbc8 <itable>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	072080e7          	jalr	114(ra) # 80000bd0 <acquire>
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
    80003b78:	05450513          	addi	a0,a0,84 # 8001fbc8 <itable>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	108080e7          	jalr	264(ra) # 80000c84 <release>
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
    80003ba4:	abe080e7          	jalr	-1346(ra) # 8000465e <acquiresleep>
    release(&itable.lock);
    80003ba8:	0001c517          	auipc	a0,0x1c
    80003bac:	02050513          	addi	a0,a0,32 # 8001fbc8 <itable>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	0d4080e7          	jalr	212(ra) # 80000c84 <release>
    itrunc(ip);
    80003bb8:	8526                	mv	a0,s1
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	ee2080e7          	jalr	-286(ra) # 80003a9c <itrunc>
    ip->type = 0;
    80003bc2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	cfa080e7          	jalr	-774(ra) # 800038c2 <iupdate>
    ip->valid = 0;
    80003bd0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	ade080e7          	jalr	-1314(ra) # 800046b4 <releasesleep>
    acquire(&itable.lock);
    80003bde:	0001c517          	auipc	a0,0x1c
    80003be2:	fea50513          	addi	a0,a0,-22 # 8001fbc8 <itable>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	fea080e7          	jalr	-22(ra) # 80000bd0 <acquire>
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
    80003ca6:	902080e7          	jalr	-1790(ra) # 800025a4 <either_copyout>
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
    80003cd4:	8ac080e7          	jalr	-1876(ra) # 8000357c <bmap>
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
    80003d9e:	860080e7          	jalr	-1952(ra) # 800025fa <either_copyin>
    80003da2:	07950263          	beq	a0,s9,80003e06 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003da6:	8526                	mv	a0,s1
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	798080e7          	jalr	1944(ra) # 80004540 <log_write>
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
    80003dd6:	7aa080e7          	jalr	1962(ra) # 8000357c <bmap>
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
    80003e22:	aa4080e7          	jalr	-1372(ra) # 800038c2 <iupdate>

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
    80003e66:	f3a080e7          	jalr	-198(ra) # 80000d9c <strncmp>
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
    80003e9c:	00005517          	auipc	a0,0x5
    80003ea0:	84c50513          	addi	a0,a0,-1972 # 800086e8 <syscalls+0x1b8>
    80003ea4:	ffffc097          	auipc	ra,0xffffc
    80003ea8:	696080e7          	jalr	1686(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003eac:	00005517          	auipc	a0,0x5
    80003eb0:	85450513          	addi	a0,a0,-1964 # 80008700 <syscalls+0x1d0>
    80003eb4:	ffffc097          	auipc	ra,0xffffc
    80003eb8:	686080e7          	jalr	1670(ra) # 8000053a <panic>
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
    80003f0a:	752080e7          	jalr	1874(ra) # 80003658 <iget>
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
    80003f3a:	e06a                	sd	s10,0(sp)
    80003f3c:	1080                	addi	s0,sp,96
    80003f3e:	84aa                	mv	s1,a0
    80003f40:	8b2e                	mv	s6,a1
    80003f42:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f44:	00054703          	lbu	a4,0(a0)
    80003f48:	02f00793          	li	a5,47
    80003f4c:	02f70363          	beq	a4,a5,80003f72 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f50:	ffffe097          	auipc	ra,0xffffe
    80003f54:	af0080e7          	jalr	-1296(ra) # 80001a40 <myproc>
    80003f58:	15053503          	ld	a0,336(a0)
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	9f4080e7          	jalr	-1548(ra) # 80003950 <idup>
    80003f64:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f66:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f6a:	4cb5                	li	s9,13
  len = path - s;
    80003f6c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f6e:	4c05                	li	s8,1
    80003f70:	a87d                	j	8000402e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f72:	4585                	li	a1,1
    80003f74:	4505                	li	a0,1
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	6e2080e7          	jalr	1762(ra) # 80003658 <iget>
    80003f7e:	8a2a                	mv	s4,a0
    80003f80:	b7dd                	j	80003f66 <namex+0x44>
      iunlockput(ip);
    80003f82:	8552                	mv	a0,s4
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	c6c080e7          	jalr	-916(ra) # 80003bf0 <iunlockput>
      return 0;
    80003f8c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f8e:	8552                	mv	a0,s4
    80003f90:	60e6                	ld	ra,88(sp)
    80003f92:	6446                	ld	s0,80(sp)
    80003f94:	64a6                	ld	s1,72(sp)
    80003f96:	6906                	ld	s2,64(sp)
    80003f98:	79e2                	ld	s3,56(sp)
    80003f9a:	7a42                	ld	s4,48(sp)
    80003f9c:	7aa2                	ld	s5,40(sp)
    80003f9e:	7b02                	ld	s6,32(sp)
    80003fa0:	6be2                	ld	s7,24(sp)
    80003fa2:	6c42                	ld	s8,16(sp)
    80003fa4:	6ca2                	ld	s9,8(sp)
    80003fa6:	6d02                	ld	s10,0(sp)
    80003fa8:	6125                	addi	sp,sp,96
    80003faa:	8082                	ret
      iunlock(ip);
    80003fac:	8552                	mv	a0,s4
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	aa2080e7          	jalr	-1374(ra) # 80003a50 <iunlock>
      return ip;
    80003fb6:	bfe1                	j	80003f8e <namex+0x6c>
      iunlockput(ip);
    80003fb8:	8552                	mv	a0,s4
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	c36080e7          	jalr	-970(ra) # 80003bf0 <iunlockput>
      return 0;
    80003fc2:	8a4e                	mv	s4,s3
    80003fc4:	b7e9                	j	80003f8e <namex+0x6c>
  len = path - s;
    80003fc6:	40998633          	sub	a2,s3,s1
    80003fca:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003fce:	09acd863          	bge	s9,s10,8000405e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003fd2:	4639                	li	a2,14
    80003fd4:	85a6                	mv	a1,s1
    80003fd6:	8556                	mv	a0,s5
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	d50080e7          	jalr	-688(ra) # 80000d28 <memmove>
    80003fe0:	84ce                	mv	s1,s3
  while(*path == '/')
    80003fe2:	0004c783          	lbu	a5,0(s1)
    80003fe6:	01279763          	bne	a5,s2,80003ff4 <namex+0xd2>
    path++;
    80003fea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	ff278de3          	beq	a5,s2,80003fea <namex+0xc8>
    ilock(ip);
    80003ff4:	8552                	mv	a0,s4
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	998080e7          	jalr	-1640(ra) # 8000398e <ilock>
    if(ip->type != T_DIR){
    80003ffe:	044a1783          	lh	a5,68(s4)
    80004002:	f98790e3          	bne	a5,s8,80003f82 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004006:	000b0563          	beqz	s6,80004010 <namex+0xee>
    8000400a:	0004c783          	lbu	a5,0(s1)
    8000400e:	dfd9                	beqz	a5,80003fac <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004010:	865e                	mv	a2,s7
    80004012:	85d6                	mv	a1,s5
    80004014:	8552                	mv	a0,s4
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	e5c080e7          	jalr	-420(ra) # 80003e72 <dirlookup>
    8000401e:	89aa                	mv	s3,a0
    80004020:	dd41                	beqz	a0,80003fb8 <namex+0x96>
    iunlockput(ip);
    80004022:	8552                	mv	a0,s4
    80004024:	00000097          	auipc	ra,0x0
    80004028:	bcc080e7          	jalr	-1076(ra) # 80003bf0 <iunlockput>
    ip = next;
    8000402c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000402e:	0004c783          	lbu	a5,0(s1)
    80004032:	01279763          	bne	a5,s2,80004040 <namex+0x11e>
    path++;
    80004036:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004038:	0004c783          	lbu	a5,0(s1)
    8000403c:	ff278de3          	beq	a5,s2,80004036 <namex+0x114>
  if(*path == 0)
    80004040:	cb9d                	beqz	a5,80004076 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	89a6                	mv	s3,s1
  len = path - s;
    80004048:	8d5e                	mv	s10,s7
    8000404a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000404c:	01278963          	beq	a5,s2,8000405e <namex+0x13c>
    80004050:	dbbd                	beqz	a5,80003fc6 <namex+0xa4>
    path++;
    80004052:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004054:	0009c783          	lbu	a5,0(s3)
    80004058:	ff279ce3          	bne	a5,s2,80004050 <namex+0x12e>
    8000405c:	b7ad                	j	80003fc6 <namex+0xa4>
    memmove(name, s, len);
    8000405e:	2601                	sext.w	a2,a2
    80004060:	85a6                	mv	a1,s1
    80004062:	8556                	mv	a0,s5
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	cc4080e7          	jalr	-828(ra) # 80000d28 <memmove>
    name[len] = 0;
    8000406c:	9d56                	add	s10,s10,s5
    8000406e:	000d0023          	sb	zero,0(s10)
    80004072:	84ce                	mv	s1,s3
    80004074:	b7bd                	j	80003fe2 <namex+0xc0>
  if(nameiparent){
    80004076:	f00b0ce3          	beqz	s6,80003f8e <namex+0x6c>
    iput(ip);
    8000407a:	8552                	mv	a0,s4
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	acc080e7          	jalr	-1332(ra) # 80003b48 <iput>
    return 0;
    80004084:	4a01                	li	s4,0
    80004086:	b721                	j	80003f8e <namex+0x6c>

0000000080004088 <dirlink>:
{
    80004088:	7139                	addi	sp,sp,-64
    8000408a:	fc06                	sd	ra,56(sp)
    8000408c:	f822                	sd	s0,48(sp)
    8000408e:	f426                	sd	s1,40(sp)
    80004090:	f04a                	sd	s2,32(sp)
    80004092:	ec4e                	sd	s3,24(sp)
    80004094:	e852                	sd	s4,16(sp)
    80004096:	0080                	addi	s0,sp,64
    80004098:	892a                	mv	s2,a0
    8000409a:	8a2e                	mv	s4,a1
    8000409c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000409e:	4601                	li	a2,0
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	dd2080e7          	jalr	-558(ra) # 80003e72 <dirlookup>
    800040a8:	e93d                	bnez	a0,8000411e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040aa:	04c92483          	lw	s1,76(s2)
    800040ae:	c49d                	beqz	s1,800040dc <dirlink+0x54>
    800040b0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b2:	4741                	li	a4,16
    800040b4:	86a6                	mv	a3,s1
    800040b6:	fc040613          	addi	a2,s0,-64
    800040ba:	4581                	li	a1,0
    800040bc:	854a                	mv	a0,s2
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	b84080e7          	jalr	-1148(ra) # 80003c42 <readi>
    800040c6:	47c1                	li	a5,16
    800040c8:	06f51163          	bne	a0,a5,8000412a <dirlink+0xa2>
    if(de.inum == 0)
    800040cc:	fc045783          	lhu	a5,-64(s0)
    800040d0:	c791                	beqz	a5,800040dc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d2:	24c1                	addiw	s1,s1,16
    800040d4:	04c92783          	lw	a5,76(s2)
    800040d8:	fcf4ede3          	bltu	s1,a5,800040b2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040dc:	4639                	li	a2,14
    800040de:	85d2                	mv	a1,s4
    800040e0:	fc240513          	addi	a0,s0,-62
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	cf4080e7          	jalr	-780(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    800040ec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f0:	4741                	li	a4,16
    800040f2:	86a6                	mv	a3,s1
    800040f4:	fc040613          	addi	a2,s0,-64
    800040f8:	4581                	li	a1,0
    800040fa:	854a                	mv	a0,s2
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	c3e080e7          	jalr	-962(ra) # 80003d3a <writei>
    80004104:	872a                	mv	a4,a0
    80004106:	47c1                	li	a5,16
  return 0;
    80004108:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410a:	02f71863          	bne	a4,a5,8000413a <dirlink+0xb2>
}
    8000410e:	70e2                	ld	ra,56(sp)
    80004110:	7442                	ld	s0,48(sp)
    80004112:	74a2                	ld	s1,40(sp)
    80004114:	7902                	ld	s2,32(sp)
    80004116:	69e2                	ld	s3,24(sp)
    80004118:	6a42                	ld	s4,16(sp)
    8000411a:	6121                	addi	sp,sp,64
    8000411c:	8082                	ret
    iput(ip);
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	a2a080e7          	jalr	-1494(ra) # 80003b48 <iput>
    return -1;
    80004126:	557d                	li	a0,-1
    80004128:	b7dd                	j	8000410e <dirlink+0x86>
      panic("dirlink read");
    8000412a:	00004517          	auipc	a0,0x4
    8000412e:	5e650513          	addi	a0,a0,1510 # 80008710 <syscalls+0x1e0>
    80004132:	ffffc097          	auipc	ra,0xffffc
    80004136:	408080e7          	jalr	1032(ra) # 8000053a <panic>
    panic("dirlink");
    8000413a:	00004517          	auipc	a0,0x4
    8000413e:	6e650513          	addi	a0,a0,1766 # 80008820 <syscalls+0x2f0>
    80004142:	ffffc097          	auipc	ra,0xffffc
    80004146:	3f8080e7          	jalr	1016(ra) # 8000053a <panic>

000000008000414a <namei>:

struct inode*
namei(char *path)
{
    8000414a:	1101                	addi	sp,sp,-32
    8000414c:	ec06                	sd	ra,24(sp)
    8000414e:	e822                	sd	s0,16(sp)
    80004150:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004152:	fe040613          	addi	a2,s0,-32
    80004156:	4581                	li	a1,0
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	dca080e7          	jalr	-566(ra) # 80003f22 <namex>
}
    80004160:	60e2                	ld	ra,24(sp)
    80004162:	6442                	ld	s0,16(sp)
    80004164:	6105                	addi	sp,sp,32
    80004166:	8082                	ret

0000000080004168 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004168:	1141                	addi	sp,sp,-16
    8000416a:	e406                	sd	ra,8(sp)
    8000416c:	e022                	sd	s0,0(sp)
    8000416e:	0800                	addi	s0,sp,16
    80004170:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004172:	4585                	li	a1,1
    80004174:	00000097          	auipc	ra,0x0
    80004178:	dae080e7          	jalr	-594(ra) # 80003f22 <namex>
}
    8000417c:	60a2                	ld	ra,8(sp)
    8000417e:	6402                	ld	s0,0(sp)
    80004180:	0141                	addi	sp,sp,16
    80004182:	8082                	ret

0000000080004184 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004184:	1101                	addi	sp,sp,-32
    80004186:	ec06                	sd	ra,24(sp)
    80004188:	e822                	sd	s0,16(sp)
    8000418a:	e426                	sd	s1,8(sp)
    8000418c:	e04a                	sd	s2,0(sp)
    8000418e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004190:	0001d917          	auipc	s2,0x1d
    80004194:	4e090913          	addi	s2,s2,1248 # 80021670 <log>
    80004198:	01892583          	lw	a1,24(s2)
    8000419c:	02892503          	lw	a0,40(s2)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	fec080e7          	jalr	-20(ra) # 8000318c <bread>
    800041a8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041aa:	02c92683          	lw	a3,44(s2)
    800041ae:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041b0:	02d05863          	blez	a3,800041e0 <write_head+0x5c>
    800041b4:	0001d797          	auipc	a5,0x1d
    800041b8:	4ec78793          	addi	a5,a5,1260 # 800216a0 <log+0x30>
    800041bc:	05c50713          	addi	a4,a0,92
    800041c0:	36fd                	addiw	a3,a3,-1
    800041c2:	02069613          	slli	a2,a3,0x20
    800041c6:	01e65693          	srli	a3,a2,0x1e
    800041ca:	0001d617          	auipc	a2,0x1d
    800041ce:	4da60613          	addi	a2,a2,1242 # 800216a4 <log+0x34>
    800041d2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041d4:	4390                	lw	a2,0(a5)
    800041d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	0791                	addi	a5,a5,4
    800041da:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800041dc:	fed79ce3          	bne	a5,a3,800041d4 <write_head+0x50>
  }
  bwrite(buf);
    800041e0:	8526                	mv	a0,s1
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	09c080e7          	jalr	156(ra) # 8000327e <bwrite>
  brelse(buf);
    800041ea:	8526                	mv	a0,s1
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	0d0080e7          	jalr	208(ra) # 800032bc <brelse>
}
    800041f4:	60e2                	ld	ra,24(sp)
    800041f6:	6442                	ld	s0,16(sp)
    800041f8:	64a2                	ld	s1,8(sp)
    800041fa:	6902                	ld	s2,0(sp)
    800041fc:	6105                	addi	sp,sp,32
    800041fe:	8082                	ret

0000000080004200 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004200:	0001d797          	auipc	a5,0x1d
    80004204:	49c7a783          	lw	a5,1180(a5) # 8002169c <log+0x2c>
    80004208:	0af05d63          	blez	a5,800042c2 <install_trans+0xc2>
{
    8000420c:	7139                	addi	sp,sp,-64
    8000420e:	fc06                	sd	ra,56(sp)
    80004210:	f822                	sd	s0,48(sp)
    80004212:	f426                	sd	s1,40(sp)
    80004214:	f04a                	sd	s2,32(sp)
    80004216:	ec4e                	sd	s3,24(sp)
    80004218:	e852                	sd	s4,16(sp)
    8000421a:	e456                	sd	s5,8(sp)
    8000421c:	e05a                	sd	s6,0(sp)
    8000421e:	0080                	addi	s0,sp,64
    80004220:	8b2a                	mv	s6,a0
    80004222:	0001da97          	auipc	s5,0x1d
    80004226:	47ea8a93          	addi	s5,s5,1150 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000422c:	0001d997          	auipc	s3,0x1d
    80004230:	44498993          	addi	s3,s3,1092 # 80021670 <log>
    80004234:	a00d                	j	80004256 <install_trans+0x56>
    brelse(lbuf);
    80004236:	854a                	mv	a0,s2
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	084080e7          	jalr	132(ra) # 800032bc <brelse>
    brelse(dbuf);
    80004240:	8526                	mv	a0,s1
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	07a080e7          	jalr	122(ra) # 800032bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	2a05                	addiw	s4,s4,1
    8000424c:	0a91                	addi	s5,s5,4
    8000424e:	02c9a783          	lw	a5,44(s3)
    80004252:	04fa5e63          	bge	s4,a5,800042ae <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004256:	0189a583          	lw	a1,24(s3)
    8000425a:	014585bb          	addw	a1,a1,s4
    8000425e:	2585                	addiw	a1,a1,1
    80004260:	0289a503          	lw	a0,40(s3)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	f28080e7          	jalr	-216(ra) # 8000318c <bread>
    8000426c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000426e:	000aa583          	lw	a1,0(s5)
    80004272:	0289a503          	lw	a0,40(s3)
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	f16080e7          	jalr	-234(ra) # 8000318c <bread>
    8000427e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004280:	40000613          	li	a2,1024
    80004284:	05890593          	addi	a1,s2,88
    80004288:	05850513          	addi	a0,a0,88
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	a9c080e7          	jalr	-1380(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	fe8080e7          	jalr	-24(ra) # 8000327e <bwrite>
    if(recovering == 0)
    8000429e:	f80b1ce3          	bnez	s6,80004236 <install_trans+0x36>
      bunpin(dbuf);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	0f2080e7          	jalr	242(ra) # 80003396 <bunpin>
    800042ac:	b769                	j	80004236 <install_trans+0x36>
}
    800042ae:	70e2                	ld	ra,56(sp)
    800042b0:	7442                	ld	s0,48(sp)
    800042b2:	74a2                	ld	s1,40(sp)
    800042b4:	7902                	ld	s2,32(sp)
    800042b6:	69e2                	ld	s3,24(sp)
    800042b8:	6a42                	ld	s4,16(sp)
    800042ba:	6aa2                	ld	s5,8(sp)
    800042bc:	6b02                	ld	s6,0(sp)
    800042be:	6121                	addi	sp,sp,64
    800042c0:	8082                	ret
    800042c2:	8082                	ret

00000000800042c4 <initlog>:
{
    800042c4:	7179                	addi	sp,sp,-48
    800042c6:	f406                	sd	ra,40(sp)
    800042c8:	f022                	sd	s0,32(sp)
    800042ca:	ec26                	sd	s1,24(sp)
    800042cc:	e84a                	sd	s2,16(sp)
    800042ce:	e44e                	sd	s3,8(sp)
    800042d0:	1800                	addi	s0,sp,48
    800042d2:	892a                	mv	s2,a0
    800042d4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042d6:	0001d497          	auipc	s1,0x1d
    800042da:	39a48493          	addi	s1,s1,922 # 80021670 <log>
    800042de:	00004597          	auipc	a1,0x4
    800042e2:	44258593          	addi	a1,a1,1090 # 80008720 <syscalls+0x1f0>
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	858080e7          	jalr	-1960(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800042f0:	0149a583          	lw	a1,20(s3)
    800042f4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042f6:	0109a783          	lw	a5,16(s3)
    800042fa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042fc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004300:	854a                	mv	a0,s2
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	e8a080e7          	jalr	-374(ra) # 8000318c <bread>
  log.lh.n = lh->n;
    8000430a:	4d34                	lw	a3,88(a0)
    8000430c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	02d05663          	blez	a3,8000433a <initlog+0x76>
    80004312:	05c50793          	addi	a5,a0,92
    80004316:	0001d717          	auipc	a4,0x1d
    8000431a:	38a70713          	addi	a4,a4,906 # 800216a0 <log+0x30>
    8000431e:	36fd                	addiw	a3,a3,-1
    80004320:	02069613          	slli	a2,a3,0x20
    80004324:	01e65693          	srli	a3,a2,0x1e
    80004328:	06050613          	addi	a2,a0,96
    8000432c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000432e:	4390                	lw	a2,0(a5)
    80004330:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004332:	0791                	addi	a5,a5,4
    80004334:	0711                	addi	a4,a4,4
    80004336:	fed79ce3          	bne	a5,a3,8000432e <initlog+0x6a>
  brelse(buf);
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	f82080e7          	jalr	-126(ra) # 800032bc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004342:	4505                	li	a0,1
    80004344:	00000097          	auipc	ra,0x0
    80004348:	ebc080e7          	jalr	-324(ra) # 80004200 <install_trans>
  log.lh.n = 0;
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	3407a823          	sw	zero,848(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    80004354:	00000097          	auipc	ra,0x0
    80004358:	e30080e7          	jalr	-464(ra) # 80004184 <write_head>
}
    8000435c:	70a2                	ld	ra,40(sp)
    8000435e:	7402                	ld	s0,32(sp)
    80004360:	64e2                	ld	s1,24(sp)
    80004362:	6942                	ld	s2,16(sp)
    80004364:	69a2                	ld	s3,8(sp)
    80004366:	6145                	addi	sp,sp,48
    80004368:	8082                	ret

000000008000436a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004376:	0001d517          	auipc	a0,0x1d
    8000437a:	2fa50513          	addi	a0,a0,762 # 80021670 <log>
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	852080e7          	jalr	-1966(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004386:	0001d497          	auipc	s1,0x1d
    8000438a:	2ea48493          	addi	s1,s1,746 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000438e:	4979                	li	s2,30
    80004390:	a039                	j	8000439e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004392:	85a6                	mv	a1,s1
    80004394:	8526                	mv	a0,s1
    80004396:	ffffe097          	auipc	ra,0xffffe
    8000439a:	e6a080e7          	jalr	-406(ra) # 80002200 <sleep>
    if(log.committing){
    8000439e:	50dc                	lw	a5,36(s1)
    800043a0:	fbed                	bnez	a5,80004392 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043a2:	5098                	lw	a4,32(s1)
    800043a4:	2705                	addiw	a4,a4,1
    800043a6:	0007069b          	sext.w	a3,a4
    800043aa:	0027179b          	slliw	a5,a4,0x2
    800043ae:	9fb9                	addw	a5,a5,a4
    800043b0:	0017979b          	slliw	a5,a5,0x1
    800043b4:	54d8                	lw	a4,44(s1)
    800043b6:	9fb9                	addw	a5,a5,a4
    800043b8:	00f95963          	bge	s2,a5,800043ca <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043bc:	85a6                	mv	a1,s1
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffe097          	auipc	ra,0xffffe
    800043c4:	e40080e7          	jalr	-448(ra) # 80002200 <sleep>
    800043c8:	bfd9                	j	8000439e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043ca:	0001d517          	auipc	a0,0x1d
    800043ce:	2a650513          	addi	a0,a0,678 # 80021670 <log>
    800043d2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	8b0080e7          	jalr	-1872(ra) # 80000c84 <release>
      break;
    }
  }
}
    800043dc:	60e2                	ld	ra,24(sp)
    800043de:	6442                	ld	s0,16(sp)
    800043e0:	64a2                	ld	s1,8(sp)
    800043e2:	6902                	ld	s2,0(sp)
    800043e4:	6105                	addi	sp,sp,32
    800043e6:	8082                	ret

00000000800043e8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043e8:	7139                	addi	sp,sp,-64
    800043ea:	fc06                	sd	ra,56(sp)
    800043ec:	f822                	sd	s0,48(sp)
    800043ee:	f426                	sd	s1,40(sp)
    800043f0:	f04a                	sd	s2,32(sp)
    800043f2:	ec4e                	sd	s3,24(sp)
    800043f4:	e852                	sd	s4,16(sp)
    800043f6:	e456                	sd	s5,8(sp)
    800043f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043fa:	0001d497          	auipc	s1,0x1d
    800043fe:	27648493          	addi	s1,s1,630 # 80021670 <log>
    80004402:	8526                	mv	a0,s1
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7cc080e7          	jalr	1996(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000440c:	509c                	lw	a5,32(s1)
    8000440e:	37fd                	addiw	a5,a5,-1
    80004410:	0007891b          	sext.w	s2,a5
    80004414:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004416:	50dc                	lw	a5,36(s1)
    80004418:	e7b9                	bnez	a5,80004466 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000441a:	04091e63          	bnez	s2,80004476 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000441e:	0001d497          	auipc	s1,0x1d
    80004422:	25248493          	addi	s1,s1,594 # 80021670 <log>
    80004426:	4785                	li	a5,1
    80004428:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	858080e7          	jalr	-1960(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004434:	54dc                	lw	a5,44(s1)
    80004436:	06f04763          	bgtz	a5,800044a4 <end_op+0xbc>
    acquire(&log.lock);
    8000443a:	0001d497          	auipc	s1,0x1d
    8000443e:	23648493          	addi	s1,s1,566 # 80021670 <log>
    80004442:	8526                	mv	a0,s1
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	78c080e7          	jalr	1932(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000444c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004450:	8526                	mv	a0,s1
    80004452:	ffffe097          	auipc	ra,0xffffe
    80004456:	f3a080e7          	jalr	-198(ra) # 8000238c <wakeup>
    release(&log.lock);
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	828080e7          	jalr	-2008(ra) # 80000c84 <release>
}
    80004464:	a03d                	j	80004492 <end_op+0xaa>
    panic("log.committing");
    80004466:	00004517          	auipc	a0,0x4
    8000446a:	2c250513          	addi	a0,a0,706 # 80008728 <syscalls+0x1f8>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	0cc080e7          	jalr	204(ra) # 8000053a <panic>
    wakeup(&log);
    80004476:	0001d497          	auipc	s1,0x1d
    8000447a:	1fa48493          	addi	s1,s1,506 # 80021670 <log>
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	f0c080e7          	jalr	-244(ra) # 8000238c <wakeup>
  release(&log.lock);
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	7fa080e7          	jalr	2042(ra) # 80000c84 <release>
}
    80004492:	70e2                	ld	ra,56(sp)
    80004494:	7442                	ld	s0,48(sp)
    80004496:	74a2                	ld	s1,40(sp)
    80004498:	7902                	ld	s2,32(sp)
    8000449a:	69e2                	ld	s3,24(sp)
    8000449c:	6a42                	ld	s4,16(sp)
    8000449e:	6aa2                	ld	s5,8(sp)
    800044a0:	6121                	addi	sp,sp,64
    800044a2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a4:	0001da97          	auipc	s5,0x1d
    800044a8:	1fca8a93          	addi	s5,s5,508 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044ac:	0001da17          	auipc	s4,0x1d
    800044b0:	1c4a0a13          	addi	s4,s4,452 # 80021670 <log>
    800044b4:	018a2583          	lw	a1,24(s4)
    800044b8:	012585bb          	addw	a1,a1,s2
    800044bc:	2585                	addiw	a1,a1,1
    800044be:	028a2503          	lw	a0,40(s4)
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	cca080e7          	jalr	-822(ra) # 8000318c <bread>
    800044ca:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044cc:	000aa583          	lw	a1,0(s5)
    800044d0:	028a2503          	lw	a0,40(s4)
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	cb8080e7          	jalr	-840(ra) # 8000318c <bread>
    800044dc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044de:	40000613          	li	a2,1024
    800044e2:	05850593          	addi	a1,a0,88
    800044e6:	05848513          	addi	a0,s1,88
    800044ea:	ffffd097          	auipc	ra,0xffffd
    800044ee:	83e080e7          	jalr	-1986(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	d8a080e7          	jalr	-630(ra) # 8000327e <bwrite>
    brelse(from);
    800044fc:	854e                	mv	a0,s3
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	dbe080e7          	jalr	-578(ra) # 800032bc <brelse>
    brelse(to);
    80004506:	8526                	mv	a0,s1
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	db4080e7          	jalr	-588(ra) # 800032bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004510:	2905                	addiw	s2,s2,1
    80004512:	0a91                	addi	s5,s5,4
    80004514:	02ca2783          	lw	a5,44(s4)
    80004518:	f8f94ee3          	blt	s2,a5,800044b4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	c68080e7          	jalr	-920(ra) # 80004184 <write_head>
    install_trans(0); // Now install writes to home locations
    80004524:	4501                	li	a0,0
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	cda080e7          	jalr	-806(ra) # 80004200 <install_trans>
    log.lh.n = 0;
    8000452e:	0001d797          	auipc	a5,0x1d
    80004532:	1607a723          	sw	zero,366(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	c4e080e7          	jalr	-946(ra) # 80004184 <write_head>
    8000453e:	bdf5                	j	8000443a <end_op+0x52>

0000000080004540 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004540:	1101                	addi	sp,sp,-32
    80004542:	ec06                	sd	ra,24(sp)
    80004544:	e822                	sd	s0,16(sp)
    80004546:	e426                	sd	s1,8(sp)
    80004548:	e04a                	sd	s2,0(sp)
    8000454a:	1000                	addi	s0,sp,32
    8000454c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000454e:	0001d917          	auipc	s2,0x1d
    80004552:	12290913          	addi	s2,s2,290 # 80021670 <log>
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	678080e7          	jalr	1656(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004560:	02c92603          	lw	a2,44(s2)
    80004564:	47f5                	li	a5,29
    80004566:	06c7c563          	blt	a5,a2,800045d0 <log_write+0x90>
    8000456a:	0001d797          	auipc	a5,0x1d
    8000456e:	1227a783          	lw	a5,290(a5) # 8002168c <log+0x1c>
    80004572:	37fd                	addiw	a5,a5,-1
    80004574:	04f65e63          	bge	a2,a5,800045d0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004578:	0001d797          	auipc	a5,0x1d
    8000457c:	1187a783          	lw	a5,280(a5) # 80021690 <log+0x20>
    80004580:	06f05063          	blez	a5,800045e0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004584:	4781                	li	a5,0
    80004586:	06c05563          	blez	a2,800045f0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000458a:	44cc                	lw	a1,12(s1)
    8000458c:	0001d717          	auipc	a4,0x1d
    80004590:	11470713          	addi	a4,a4,276 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004594:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004596:	4314                	lw	a3,0(a4)
    80004598:	04b68c63          	beq	a3,a1,800045f0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000459c:	2785                	addiw	a5,a5,1
    8000459e:	0711                	addi	a4,a4,4
    800045a0:	fef61be3          	bne	a2,a5,80004596 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045a4:	0621                	addi	a2,a2,8
    800045a6:	060a                	slli	a2,a2,0x2
    800045a8:	0001d797          	auipc	a5,0x1d
    800045ac:	0c878793          	addi	a5,a5,200 # 80021670 <log>
    800045b0:	97b2                	add	a5,a5,a2
    800045b2:	44d8                	lw	a4,12(s1)
    800045b4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045b6:	8526                	mv	a0,s1
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	da2080e7          	jalr	-606(ra) # 8000335a <bpin>
    log.lh.n++;
    800045c0:	0001d717          	auipc	a4,0x1d
    800045c4:	0b070713          	addi	a4,a4,176 # 80021670 <log>
    800045c8:	575c                	lw	a5,44(a4)
    800045ca:	2785                	addiw	a5,a5,1
    800045cc:	d75c                	sw	a5,44(a4)
    800045ce:	a82d                	j	80004608 <log_write+0xc8>
    panic("too big a transaction");
    800045d0:	00004517          	auipc	a0,0x4
    800045d4:	16850513          	addi	a0,a0,360 # 80008738 <syscalls+0x208>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	17050513          	addi	a0,a0,368 # 80008750 <syscalls+0x220>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    800045f0:	00878693          	addi	a3,a5,8
    800045f4:	068a                	slli	a3,a3,0x2
    800045f6:	0001d717          	auipc	a4,0x1d
    800045fa:	07a70713          	addi	a4,a4,122 # 80021670 <log>
    800045fe:	9736                	add	a4,a4,a3
    80004600:	44d4                	lw	a3,12(s1)
    80004602:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004604:	faf609e3          	beq	a2,a5,800045b6 <log_write+0x76>
  }
  release(&log.lock);
    80004608:	0001d517          	auipc	a0,0x1d
    8000460c:	06850513          	addi	a0,a0,104 # 80021670 <log>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	674080e7          	jalr	1652(ra) # 80000c84 <release>
}
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6902                	ld	s2,0(sp)
    80004620:	6105                	addi	sp,sp,32
    80004622:	8082                	ret

0000000080004624 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	e04a                	sd	s2,0(sp)
    8000462e:	1000                	addi	s0,sp,32
    80004630:	84aa                	mv	s1,a0
    80004632:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004634:	00004597          	auipc	a1,0x4
    80004638:	13c58593          	addi	a1,a1,316 # 80008770 <syscalls+0x240>
    8000463c:	0521                	addi	a0,a0,8
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	502080e7          	jalr	1282(ra) # 80000b40 <initlock>
  lk->name = name;
    80004646:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000464a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000464e:	0204a423          	sw	zero,40(s1)
}
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6902                	ld	s2,0(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret

000000008000465e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	e04a                	sd	s2,0(sp)
    80004668:	1000                	addi	s0,sp,32
    8000466a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000466c:	00850913          	addi	s2,a0,8
    80004670:	854a                	mv	a0,s2
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	55e080e7          	jalr	1374(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000467a:	409c                	lw	a5,0(s1)
    8000467c:	cb89                	beqz	a5,8000468e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000467e:	85ca                	mv	a1,s2
    80004680:	8526                	mv	a0,s1
    80004682:	ffffe097          	auipc	ra,0xffffe
    80004686:	b7e080e7          	jalr	-1154(ra) # 80002200 <sleep>
  while (lk->locked) {
    8000468a:	409c                	lw	a5,0(s1)
    8000468c:	fbed                	bnez	a5,8000467e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000468e:	4785                	li	a5,1
    80004690:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004692:	ffffd097          	auipc	ra,0xffffd
    80004696:	3ae080e7          	jalr	942(ra) # 80001a40 <myproc>
    8000469a:	591c                	lw	a5,48(a0)
    8000469c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000469e:	854a                	mv	a0,s2
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5e4080e7          	jalr	1508(ra) # 80000c84 <release>
}
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6902                	ld	s2,0(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	addi	s0,sp,32
    800046c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046c2:	00850913          	addi	s2,a0,8
    800046c6:	854a                	mv	a0,s2
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	508080e7          	jalr	1288(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800046d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046d4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046d8:	8526                	mv	a0,s1
    800046da:	ffffe097          	auipc	ra,0xffffe
    800046de:	cb2080e7          	jalr	-846(ra) # 8000238c <wakeup>
  release(&lk->lk);
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	5a0080e7          	jalr	1440(ra) # 80000c84 <release>
}
    800046ec:	60e2                	ld	ra,24(sp)
    800046ee:	6442                	ld	s0,16(sp)
    800046f0:	64a2                	ld	s1,8(sp)
    800046f2:	6902                	ld	s2,0(sp)
    800046f4:	6105                	addi	sp,sp,32
    800046f6:	8082                	ret

00000000800046f8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046f8:	7179                	addi	sp,sp,-48
    800046fa:	f406                	sd	ra,40(sp)
    800046fc:	f022                	sd	s0,32(sp)
    800046fe:	ec26                	sd	s1,24(sp)
    80004700:	e84a                	sd	s2,16(sp)
    80004702:	e44e                	sd	s3,8(sp)
    80004704:	1800                	addi	s0,sp,48
    80004706:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004708:	00850913          	addi	s2,a0,8
    8000470c:	854a                	mv	a0,s2
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	4c2080e7          	jalr	1218(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004716:	409c                	lw	a5,0(s1)
    80004718:	ef99                	bnez	a5,80004736 <holdingsleep+0x3e>
    8000471a:	4481                	li	s1,0
  release(&lk->lk);
    8000471c:	854a                	mv	a0,s2
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	566080e7          	jalr	1382(ra) # 80000c84 <release>
  return r;
}
    80004726:	8526                	mv	a0,s1
    80004728:	70a2                	ld	ra,40(sp)
    8000472a:	7402                	ld	s0,32(sp)
    8000472c:	64e2                	ld	s1,24(sp)
    8000472e:	6942                	ld	s2,16(sp)
    80004730:	69a2                	ld	s3,8(sp)
    80004732:	6145                	addi	sp,sp,48
    80004734:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004736:	0284a983          	lw	s3,40(s1)
    8000473a:	ffffd097          	auipc	ra,0xffffd
    8000473e:	306080e7          	jalr	774(ra) # 80001a40 <myproc>
    80004742:	5904                	lw	s1,48(a0)
    80004744:	413484b3          	sub	s1,s1,s3
    80004748:	0014b493          	seqz	s1,s1
    8000474c:	bfc1                	j	8000471c <holdingsleep+0x24>

000000008000474e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000474e:	1141                	addi	sp,sp,-16
    80004750:	e406                	sd	ra,8(sp)
    80004752:	e022                	sd	s0,0(sp)
    80004754:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004756:	00004597          	auipc	a1,0x4
    8000475a:	02a58593          	addi	a1,a1,42 # 80008780 <syscalls+0x250>
    8000475e:	0001d517          	auipc	a0,0x1d
    80004762:	05a50513          	addi	a0,a0,90 # 800217b8 <ftable>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	3da080e7          	jalr	986(ra) # 80000b40 <initlock>
}
    8000476e:	60a2                	ld	ra,8(sp)
    80004770:	6402                	ld	s0,0(sp)
    80004772:	0141                	addi	sp,sp,16
    80004774:	8082                	ret

0000000080004776 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004776:	1101                	addi	sp,sp,-32
    80004778:	ec06                	sd	ra,24(sp)
    8000477a:	e822                	sd	s0,16(sp)
    8000477c:	e426                	sd	s1,8(sp)
    8000477e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	03850513          	addi	a0,a0,56 # 800217b8 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	448080e7          	jalr	1096(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004790:	0001d497          	auipc	s1,0x1d
    80004794:	04048493          	addi	s1,s1,64 # 800217d0 <ftable+0x18>
    80004798:	0001e717          	auipc	a4,0x1e
    8000479c:	fd870713          	addi	a4,a4,-40 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800047a0:	40dc                	lw	a5,4(s1)
    800047a2:	cf99                	beqz	a5,800047c0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047a4:	02848493          	addi	s1,s1,40
    800047a8:	fee49ce3          	bne	s1,a4,800047a0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047ac:	0001d517          	auipc	a0,0x1d
    800047b0:	00c50513          	addi	a0,a0,12 # 800217b8 <ftable>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	4d0080e7          	jalr	1232(ra) # 80000c84 <release>
  return 0;
    800047bc:	4481                	li	s1,0
    800047be:	a819                	j	800047d4 <filealloc+0x5e>
      f->ref = 1;
    800047c0:	4785                	li	a5,1
    800047c2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047c4:	0001d517          	auipc	a0,0x1d
    800047c8:	ff450513          	addi	a0,a0,-12 # 800217b8 <ftable>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4b8080e7          	jalr	1208(ra) # 80000c84 <release>
}
    800047d4:	8526                	mv	a0,s1
    800047d6:	60e2                	ld	ra,24(sp)
    800047d8:	6442                	ld	s0,16(sp)
    800047da:	64a2                	ld	s1,8(sp)
    800047dc:	6105                	addi	sp,sp,32
    800047de:	8082                	ret

00000000800047e0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047e0:	1101                	addi	sp,sp,-32
    800047e2:	ec06                	sd	ra,24(sp)
    800047e4:	e822                	sd	s0,16(sp)
    800047e6:	e426                	sd	s1,8(sp)
    800047e8:	1000                	addi	s0,sp,32
    800047ea:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ec:	0001d517          	auipc	a0,0x1d
    800047f0:	fcc50513          	addi	a0,a0,-52 # 800217b8 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	3dc080e7          	jalr	988(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800047fc:	40dc                	lw	a5,4(s1)
    800047fe:	02f05263          	blez	a5,80004822 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004802:	2785                	addiw	a5,a5,1
    80004804:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	fb250513          	addi	a0,a0,-78 # 800217b8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	476080e7          	jalr	1142(ra) # 80000c84 <release>
  return f;
}
    80004816:	8526                	mv	a0,s1
    80004818:	60e2                	ld	ra,24(sp)
    8000481a:	6442                	ld	s0,16(sp)
    8000481c:	64a2                	ld	s1,8(sp)
    8000481e:	6105                	addi	sp,sp,32
    80004820:	8082                	ret
    panic("filedup");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	f6650513          	addi	a0,a0,-154 # 80008788 <syscalls+0x258>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d10080e7          	jalr	-752(ra) # 8000053a <panic>

0000000080004832 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004832:	7139                	addi	sp,sp,-64
    80004834:	fc06                	sd	ra,56(sp)
    80004836:	f822                	sd	s0,48(sp)
    80004838:	f426                	sd	s1,40(sp)
    8000483a:	f04a                	sd	s2,32(sp)
    8000483c:	ec4e                	sd	s3,24(sp)
    8000483e:	e852                	sd	s4,16(sp)
    80004840:	e456                	sd	s5,8(sp)
    80004842:	0080                	addi	s0,sp,64
    80004844:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004846:	0001d517          	auipc	a0,0x1d
    8000484a:	f7250513          	addi	a0,a0,-142 # 800217b8 <ftable>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	382080e7          	jalr	898(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004856:	40dc                	lw	a5,4(s1)
    80004858:	06f05163          	blez	a5,800048ba <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000485c:	37fd                	addiw	a5,a5,-1
    8000485e:	0007871b          	sext.w	a4,a5
    80004862:	c0dc                	sw	a5,4(s1)
    80004864:	06e04363          	bgtz	a4,800048ca <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004868:	0004a903          	lw	s2,0(s1)
    8000486c:	0094ca83          	lbu	s5,9(s1)
    80004870:	0104ba03          	ld	s4,16(s1)
    80004874:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004878:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000487c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004880:	0001d517          	auipc	a0,0x1d
    80004884:	f3850513          	addi	a0,a0,-200 # 800217b8 <ftable>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	3fc080e7          	jalr	1020(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004890:	4785                	li	a5,1
    80004892:	04f90d63          	beq	s2,a5,800048ec <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004896:	3979                	addiw	s2,s2,-2
    80004898:	4785                	li	a5,1
    8000489a:	0527e063          	bltu	a5,s2,800048da <fileclose+0xa8>
    begin_op();
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	acc080e7          	jalr	-1332(ra) # 8000436a <begin_op>
    iput(ff.ip);
    800048a6:	854e                	mv	a0,s3
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	2a0080e7          	jalr	672(ra) # 80003b48 <iput>
    end_op();
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	b38080e7          	jalr	-1224(ra) # 800043e8 <end_op>
    800048b8:	a00d                	j	800048da <fileclose+0xa8>
    panic("fileclose");
    800048ba:	00004517          	auipc	a0,0x4
    800048be:	ed650513          	addi	a0,a0,-298 # 80008790 <syscalls+0x260>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	c78080e7          	jalr	-904(ra) # 8000053a <panic>
    release(&ftable.lock);
    800048ca:	0001d517          	auipc	a0,0x1d
    800048ce:	eee50513          	addi	a0,a0,-274 # 800217b8 <ftable>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	3b2080e7          	jalr	946(ra) # 80000c84 <release>
  }
}
    800048da:	70e2                	ld	ra,56(sp)
    800048dc:	7442                	ld	s0,48(sp)
    800048de:	74a2                	ld	s1,40(sp)
    800048e0:	7902                	ld	s2,32(sp)
    800048e2:	69e2                	ld	s3,24(sp)
    800048e4:	6a42                	ld	s4,16(sp)
    800048e6:	6aa2                	ld	s5,8(sp)
    800048e8:	6121                	addi	sp,sp,64
    800048ea:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ec:	85d6                	mv	a1,s5
    800048ee:	8552                	mv	a0,s4
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	34c080e7          	jalr	844(ra) # 80004c3c <pipeclose>
    800048f8:	b7cd                	j	800048da <fileclose+0xa8>

00000000800048fa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048fa:	715d                	addi	sp,sp,-80
    800048fc:	e486                	sd	ra,72(sp)
    800048fe:	e0a2                	sd	s0,64(sp)
    80004900:	fc26                	sd	s1,56(sp)
    80004902:	f84a                	sd	s2,48(sp)
    80004904:	f44e                	sd	s3,40(sp)
    80004906:	0880                	addi	s0,sp,80
    80004908:	84aa                	mv	s1,a0
    8000490a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000490c:	ffffd097          	auipc	ra,0xffffd
    80004910:	134080e7          	jalr	308(ra) # 80001a40 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004914:	409c                	lw	a5,0(s1)
    80004916:	37f9                	addiw	a5,a5,-2
    80004918:	4705                	li	a4,1
    8000491a:	04f76763          	bltu	a4,a5,80004968 <filestat+0x6e>
    8000491e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004920:	6c88                	ld	a0,24(s1)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	06c080e7          	jalr	108(ra) # 8000398e <ilock>
    stati(f->ip, &st);
    8000492a:	fb840593          	addi	a1,s0,-72
    8000492e:	6c88                	ld	a0,24(s1)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	2e8080e7          	jalr	744(ra) # 80003c18 <stati>
    iunlock(f->ip);
    80004938:	6c88                	ld	a0,24(s1)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	116080e7          	jalr	278(ra) # 80003a50 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004942:	46e1                	li	a3,24
    80004944:	fb840613          	addi	a2,s0,-72
    80004948:	85ce                	mv	a1,s3
    8000494a:	05093503          	ld	a0,80(s2)
    8000494e:	ffffd097          	auipc	ra,0xffffd
    80004952:	d0c080e7          	jalr	-756(ra) # 8000165a <copyout>
    80004956:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000495a:	60a6                	ld	ra,72(sp)
    8000495c:	6406                	ld	s0,64(sp)
    8000495e:	74e2                	ld	s1,56(sp)
    80004960:	7942                	ld	s2,48(sp)
    80004962:	79a2                	ld	s3,40(sp)
    80004964:	6161                	addi	sp,sp,80
    80004966:	8082                	ret
  return -1;
    80004968:	557d                	li	a0,-1
    8000496a:	bfc5                	j	8000495a <filestat+0x60>

000000008000496c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000497a:	00854783          	lbu	a5,8(a0)
    8000497e:	c3d5                	beqz	a5,80004a22 <fileread+0xb6>
    80004980:	84aa                	mv	s1,a0
    80004982:	89ae                	mv	s3,a1
    80004984:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004986:	411c                	lw	a5,0(a0)
    80004988:	4705                	li	a4,1
    8000498a:	04e78963          	beq	a5,a4,800049dc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000498e:	470d                	li	a4,3
    80004990:	04e78d63          	beq	a5,a4,800049ea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004994:	4709                	li	a4,2
    80004996:	06e79e63          	bne	a5,a4,80004a12 <fileread+0xa6>
    ilock(f->ip);
    8000499a:	6d08                	ld	a0,24(a0)
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	ff2080e7          	jalr	-14(ra) # 8000398e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049a4:	874a                	mv	a4,s2
    800049a6:	5094                	lw	a3,32(s1)
    800049a8:	864e                	mv	a2,s3
    800049aa:	4585                	li	a1,1
    800049ac:	6c88                	ld	a0,24(s1)
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	294080e7          	jalr	660(ra) # 80003c42 <readi>
    800049b6:	892a                	mv	s2,a0
    800049b8:	00a05563          	blez	a0,800049c2 <fileread+0x56>
      f->off += r;
    800049bc:	509c                	lw	a5,32(s1)
    800049be:	9fa9                	addw	a5,a5,a0
    800049c0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049c2:	6c88                	ld	a0,24(s1)
    800049c4:	fffff097          	auipc	ra,0xfffff
    800049c8:	08c080e7          	jalr	140(ra) # 80003a50 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049cc:	854a                	mv	a0,s2
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6942                	ld	s2,16(sp)
    800049d6:	69a2                	ld	s3,8(sp)
    800049d8:	6145                	addi	sp,sp,48
    800049da:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049dc:	6908                	ld	a0,16(a0)
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	3c0080e7          	jalr	960(ra) # 80004d9e <piperead>
    800049e6:	892a                	mv	s2,a0
    800049e8:	b7d5                	j	800049cc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049ea:	02451783          	lh	a5,36(a0)
    800049ee:	03079693          	slli	a3,a5,0x30
    800049f2:	92c1                	srli	a3,a3,0x30
    800049f4:	4725                	li	a4,9
    800049f6:	02d76863          	bltu	a4,a3,80004a26 <fileread+0xba>
    800049fa:	0792                	slli	a5,a5,0x4
    800049fc:	0001d717          	auipc	a4,0x1d
    80004a00:	d1c70713          	addi	a4,a4,-740 # 80021718 <devsw>
    80004a04:	97ba                	add	a5,a5,a4
    80004a06:	639c                	ld	a5,0(a5)
    80004a08:	c38d                	beqz	a5,80004a2a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a0a:	4505                	li	a0,1
    80004a0c:	9782                	jalr	a5
    80004a0e:	892a                	mv	s2,a0
    80004a10:	bf75                	j	800049cc <fileread+0x60>
    panic("fileread");
    80004a12:	00004517          	auipc	a0,0x4
    80004a16:	d8e50513          	addi	a0,a0,-626 # 800087a0 <syscalls+0x270>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	b20080e7          	jalr	-1248(ra) # 8000053a <panic>
    return -1;
    80004a22:	597d                	li	s2,-1
    80004a24:	b765                	j	800049cc <fileread+0x60>
      return -1;
    80004a26:	597d                	li	s2,-1
    80004a28:	b755                	j	800049cc <fileread+0x60>
    80004a2a:	597d                	li	s2,-1
    80004a2c:	b745                	j	800049cc <fileread+0x60>

0000000080004a2e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a2e:	715d                	addi	sp,sp,-80
    80004a30:	e486                	sd	ra,72(sp)
    80004a32:	e0a2                	sd	s0,64(sp)
    80004a34:	fc26                	sd	s1,56(sp)
    80004a36:	f84a                	sd	s2,48(sp)
    80004a38:	f44e                	sd	s3,40(sp)
    80004a3a:	f052                	sd	s4,32(sp)
    80004a3c:	ec56                	sd	s5,24(sp)
    80004a3e:	e85a                	sd	s6,16(sp)
    80004a40:	e45e                	sd	s7,8(sp)
    80004a42:	e062                	sd	s8,0(sp)
    80004a44:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a46:	00954783          	lbu	a5,9(a0)
    80004a4a:	10078663          	beqz	a5,80004b56 <filewrite+0x128>
    80004a4e:	892a                	mv	s2,a0
    80004a50:	8b2e                	mv	s6,a1
    80004a52:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a54:	411c                	lw	a5,0(a0)
    80004a56:	4705                	li	a4,1
    80004a58:	02e78263          	beq	a5,a4,80004a7c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a5c:	470d                	li	a4,3
    80004a5e:	02e78663          	beq	a5,a4,80004a8a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a62:	4709                	li	a4,2
    80004a64:	0ee79163          	bne	a5,a4,80004b46 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a68:	0ac05d63          	blez	a2,80004b22 <filewrite+0xf4>
    int i = 0;
    80004a6c:	4981                	li	s3,0
    80004a6e:	6b85                	lui	s7,0x1
    80004a70:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a74:	6c05                	lui	s8,0x1
    80004a76:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a7a:	a861                	j	80004b12 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a7c:	6908                	ld	a0,16(a0)
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	22e080e7          	jalr	558(ra) # 80004cac <pipewrite>
    80004a86:	8a2a                	mv	s4,a0
    80004a88:	a045                	j	80004b28 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a8a:	02451783          	lh	a5,36(a0)
    80004a8e:	03079693          	slli	a3,a5,0x30
    80004a92:	92c1                	srli	a3,a3,0x30
    80004a94:	4725                	li	a4,9
    80004a96:	0cd76263          	bltu	a4,a3,80004b5a <filewrite+0x12c>
    80004a9a:	0792                	slli	a5,a5,0x4
    80004a9c:	0001d717          	auipc	a4,0x1d
    80004aa0:	c7c70713          	addi	a4,a4,-900 # 80021718 <devsw>
    80004aa4:	97ba                	add	a5,a5,a4
    80004aa6:	679c                	ld	a5,8(a5)
    80004aa8:	cbdd                	beqz	a5,80004b5e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004aaa:	4505                	li	a0,1
    80004aac:	9782                	jalr	a5
    80004aae:	8a2a                	mv	s4,a0
    80004ab0:	a8a5                	j	80004b28 <filewrite+0xfa>
    80004ab2:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	8b4080e7          	jalr	-1868(ra) # 8000436a <begin_op>
      ilock(f->ip);
    80004abe:	01893503          	ld	a0,24(s2)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	ecc080e7          	jalr	-308(ra) # 8000398e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aca:	8756                	mv	a4,s5
    80004acc:	02092683          	lw	a3,32(s2)
    80004ad0:	01698633          	add	a2,s3,s6
    80004ad4:	4585                	li	a1,1
    80004ad6:	01893503          	ld	a0,24(s2)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	260080e7          	jalr	608(ra) # 80003d3a <writei>
    80004ae2:	84aa                	mv	s1,a0
    80004ae4:	00a05763          	blez	a0,80004af2 <filewrite+0xc4>
        f->off += r;
    80004ae8:	02092783          	lw	a5,32(s2)
    80004aec:	9fa9                	addw	a5,a5,a0
    80004aee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004af2:	01893503          	ld	a0,24(s2)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	f5a080e7          	jalr	-166(ra) # 80003a50 <iunlock>
      end_op();
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	8ea080e7          	jalr	-1814(ra) # 800043e8 <end_op>

      if(r != n1){
    80004b06:	009a9f63          	bne	s5,s1,80004b24 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b0a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b0e:	0149db63          	bge	s3,s4,80004b24 <filewrite+0xf6>
      int n1 = n - i;
    80004b12:	413a04bb          	subw	s1,s4,s3
    80004b16:	0004879b          	sext.w	a5,s1
    80004b1a:	f8fbdce3          	bge	s7,a5,80004ab2 <filewrite+0x84>
    80004b1e:	84e2                	mv	s1,s8
    80004b20:	bf49                	j	80004ab2 <filewrite+0x84>
    int i = 0;
    80004b22:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b24:	013a1f63          	bne	s4,s3,80004b42 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b28:	8552                	mv	a0,s4
    80004b2a:	60a6                	ld	ra,72(sp)
    80004b2c:	6406                	ld	s0,64(sp)
    80004b2e:	74e2                	ld	s1,56(sp)
    80004b30:	7942                	ld	s2,48(sp)
    80004b32:	79a2                	ld	s3,40(sp)
    80004b34:	7a02                	ld	s4,32(sp)
    80004b36:	6ae2                	ld	s5,24(sp)
    80004b38:	6b42                	ld	s6,16(sp)
    80004b3a:	6ba2                	ld	s7,8(sp)
    80004b3c:	6c02                	ld	s8,0(sp)
    80004b3e:	6161                	addi	sp,sp,80
    80004b40:	8082                	ret
    ret = (i == n ? n : -1);
    80004b42:	5a7d                	li	s4,-1
    80004b44:	b7d5                	j	80004b28 <filewrite+0xfa>
    panic("filewrite");
    80004b46:	00004517          	auipc	a0,0x4
    80004b4a:	c6a50513          	addi	a0,a0,-918 # 800087b0 <syscalls+0x280>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	9ec080e7          	jalr	-1556(ra) # 8000053a <panic>
    return -1;
    80004b56:	5a7d                	li	s4,-1
    80004b58:	bfc1                	j	80004b28 <filewrite+0xfa>
      return -1;
    80004b5a:	5a7d                	li	s4,-1
    80004b5c:	b7f1                	j	80004b28 <filewrite+0xfa>
    80004b5e:	5a7d                	li	s4,-1
    80004b60:	b7e1                	j	80004b28 <filewrite+0xfa>

0000000080004b62 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b62:	7179                	addi	sp,sp,-48
    80004b64:	f406                	sd	ra,40(sp)
    80004b66:	f022                	sd	s0,32(sp)
    80004b68:	ec26                	sd	s1,24(sp)
    80004b6a:	e84a                	sd	s2,16(sp)
    80004b6c:	e44e                	sd	s3,8(sp)
    80004b6e:	e052                	sd	s4,0(sp)
    80004b70:	1800                	addi	s0,sp,48
    80004b72:	84aa                	mv	s1,a0
    80004b74:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b76:	0005b023          	sd	zero,0(a1)
    80004b7a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	bf8080e7          	jalr	-1032(ra) # 80004776 <filealloc>
    80004b86:	e088                	sd	a0,0(s1)
    80004b88:	c551                	beqz	a0,80004c14 <pipealloc+0xb2>
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	bec080e7          	jalr	-1044(ra) # 80004776 <filealloc>
    80004b92:	00aa3023          	sd	a0,0(s4)
    80004b96:	c92d                	beqz	a0,80004c08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	f48080e7          	jalr	-184(ra) # 80000ae0 <kalloc>
    80004ba0:	892a                	mv	s2,a0
    80004ba2:	c125                	beqz	a0,80004c02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ba4:	4985                	li	s3,1
    80004ba6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004baa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bb2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bb6:	00004597          	auipc	a1,0x4
    80004bba:	c0a58593          	addi	a1,a1,-1014 # 800087c0 <syscalls+0x290>
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	f82080e7          	jalr	-126(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004bc6:	609c                	ld	a5,0(s1)
    80004bc8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bcc:	609c                	ld	a5,0(s1)
    80004bce:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bd2:	609c                	ld	a5,0(s1)
    80004bd4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bd8:	609c                	ld	a5,0(s1)
    80004bda:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bde:	000a3783          	ld	a5,0(s4)
    80004be2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004be6:	000a3783          	ld	a5,0(s4)
    80004bea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bee:	000a3783          	ld	a5,0(s4)
    80004bf2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bf6:	000a3783          	ld	a5,0(s4)
    80004bfa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bfe:	4501                	li	a0,0
    80004c00:	a025                	j	80004c28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c02:	6088                	ld	a0,0(s1)
    80004c04:	e501                	bnez	a0,80004c0c <pipealloc+0xaa>
    80004c06:	a039                	j	80004c14 <pipealloc+0xb2>
    80004c08:	6088                	ld	a0,0(s1)
    80004c0a:	c51d                	beqz	a0,80004c38 <pipealloc+0xd6>
    fileclose(*f0);
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	c26080e7          	jalr	-986(ra) # 80004832 <fileclose>
  if(*f1)
    80004c14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c18:	557d                	li	a0,-1
  if(*f1)
    80004c1a:	c799                	beqz	a5,80004c28 <pipealloc+0xc6>
    fileclose(*f1);
    80004c1c:	853e                	mv	a0,a5
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	c14080e7          	jalr	-1004(ra) # 80004832 <fileclose>
  return -1;
    80004c26:	557d                	li	a0,-1
}
    80004c28:	70a2                	ld	ra,40(sp)
    80004c2a:	7402                	ld	s0,32(sp)
    80004c2c:	64e2                	ld	s1,24(sp)
    80004c2e:	6942                	ld	s2,16(sp)
    80004c30:	69a2                	ld	s3,8(sp)
    80004c32:	6a02                	ld	s4,0(sp)
    80004c34:	6145                	addi	sp,sp,48
    80004c36:	8082                	ret
  return -1;
    80004c38:	557d                	li	a0,-1
    80004c3a:	b7fd                	j	80004c28 <pipealloc+0xc6>

0000000080004c3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c3c:	1101                	addi	sp,sp,-32
    80004c3e:	ec06                	sd	ra,24(sp)
    80004c40:	e822                	sd	s0,16(sp)
    80004c42:	e426                	sd	s1,8(sp)
    80004c44:	e04a                	sd	s2,0(sp)
    80004c46:	1000                	addi	s0,sp,32
    80004c48:	84aa                	mv	s1,a0
    80004c4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	f84080e7          	jalr	-124(ra) # 80000bd0 <acquire>
  if(writable){
    80004c54:	02090d63          	beqz	s2,80004c8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c5c:	21848513          	addi	a0,s1,536
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	72c080e7          	jalr	1836(ra) # 8000238c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c68:	2204b783          	ld	a5,544(s1)
    80004c6c:	eb95                	bnez	a5,80004ca0 <pipeclose+0x64>
    release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	014080e7          	jalr	20(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	d68080e7          	jalr	-664(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6902                	ld	s2,0(sp)
    80004c8a:	6105                	addi	sp,sp,32
    80004c8c:	8082                	ret
    pi->readopen = 0;
    80004c8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c92:	21c48513          	addi	a0,s1,540
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	6f6080e7          	jalr	1782(ra) # 8000238c <wakeup>
    80004c9e:	b7e9                	j	80004c68 <pipeclose+0x2c>
    release(&pi->lock);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	fe2080e7          	jalr	-30(ra) # 80000c84 <release>
}
    80004caa:	bfe1                	j	80004c82 <pipeclose+0x46>

0000000080004cac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cac:	711d                	addi	sp,sp,-96
    80004cae:	ec86                	sd	ra,88(sp)
    80004cb0:	e8a2                	sd	s0,80(sp)
    80004cb2:	e4a6                	sd	s1,72(sp)
    80004cb4:	e0ca                	sd	s2,64(sp)
    80004cb6:	fc4e                	sd	s3,56(sp)
    80004cb8:	f852                	sd	s4,48(sp)
    80004cba:	f456                	sd	s5,40(sp)
    80004cbc:	f05a                	sd	s6,32(sp)
    80004cbe:	ec5e                	sd	s7,24(sp)
    80004cc0:	e862                	sd	s8,16(sp)
    80004cc2:	1080                	addi	s0,sp,96
    80004cc4:	84aa                	mv	s1,a0
    80004cc6:	8aae                	mv	s5,a1
    80004cc8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	d76080e7          	jalr	-650(ra) # 80001a40 <myproc>
    80004cd2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	efa080e7          	jalr	-262(ra) # 80000bd0 <acquire>
  while(i < n){
    80004cde:	0b405363          	blez	s4,80004d84 <pipewrite+0xd8>
  int i = 0;
    80004ce2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ce6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cea:	21c48b93          	addi	s7,s1,540
    80004cee:	a089                	j	80004d30 <pipewrite+0x84>
      release(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f92080e7          	jalr	-110(ra) # 80000c84 <release>
      return -1;
    80004cfa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cfc:	854a                	mv	a0,s2
    80004cfe:	60e6                	ld	ra,88(sp)
    80004d00:	6446                	ld	s0,80(sp)
    80004d02:	64a6                	ld	s1,72(sp)
    80004d04:	6906                	ld	s2,64(sp)
    80004d06:	79e2                	ld	s3,56(sp)
    80004d08:	7a42                	ld	s4,48(sp)
    80004d0a:	7aa2                	ld	s5,40(sp)
    80004d0c:	7b02                	ld	s6,32(sp)
    80004d0e:	6be2                	ld	s7,24(sp)
    80004d10:	6c42                	ld	s8,16(sp)
    80004d12:	6125                	addi	sp,sp,96
    80004d14:	8082                	ret
      wakeup(&pi->nread);
    80004d16:	8562                	mv	a0,s8
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	674080e7          	jalr	1652(ra) # 8000238c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d20:	85a6                	mv	a1,s1
    80004d22:	855e                	mv	a0,s7
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	4dc080e7          	jalr	1244(ra) # 80002200 <sleep>
  while(i < n){
    80004d2c:	05495d63          	bge	s2,s4,80004d86 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004d30:	2204a783          	lw	a5,544(s1)
    80004d34:	dfd5                	beqz	a5,80004cf0 <pipewrite+0x44>
    80004d36:	0289a783          	lw	a5,40(s3)
    80004d3a:	fbdd                	bnez	a5,80004cf0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d3c:	2184a783          	lw	a5,536(s1)
    80004d40:	21c4a703          	lw	a4,540(s1)
    80004d44:	2007879b          	addiw	a5,a5,512
    80004d48:	fcf707e3          	beq	a4,a5,80004d16 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d4c:	4685                	li	a3,1
    80004d4e:	01590633          	add	a2,s2,s5
    80004d52:	faf40593          	addi	a1,s0,-81
    80004d56:	0509b503          	ld	a0,80(s3)
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	98c080e7          	jalr	-1652(ra) # 800016e6 <copyin>
    80004d62:	03650263          	beq	a0,s6,80004d86 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d66:	21c4a783          	lw	a5,540(s1)
    80004d6a:	0017871b          	addiw	a4,a5,1
    80004d6e:	20e4ae23          	sw	a4,540(s1)
    80004d72:	1ff7f793          	andi	a5,a5,511
    80004d76:	97a6                	add	a5,a5,s1
    80004d78:	faf44703          	lbu	a4,-81(s0)
    80004d7c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d80:	2905                	addiw	s2,s2,1
    80004d82:	b76d                	j	80004d2c <pipewrite+0x80>
  int i = 0;
    80004d84:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d86:	21848513          	addi	a0,s1,536
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	602080e7          	jalr	1538(ra) # 8000238c <wakeup>
  release(&pi->lock);
    80004d92:	8526                	mv	a0,s1
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	ef0080e7          	jalr	-272(ra) # 80000c84 <release>
  return i;
    80004d9c:	b785                	j	80004cfc <pipewrite+0x50>

0000000080004d9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d9e:	715d                	addi	sp,sp,-80
    80004da0:	e486                	sd	ra,72(sp)
    80004da2:	e0a2                	sd	s0,64(sp)
    80004da4:	fc26                	sd	s1,56(sp)
    80004da6:	f84a                	sd	s2,48(sp)
    80004da8:	f44e                	sd	s3,40(sp)
    80004daa:	f052                	sd	s4,32(sp)
    80004dac:	ec56                	sd	s5,24(sp)
    80004dae:	e85a                	sd	s6,16(sp)
    80004db0:	0880                	addi	s0,sp,80
    80004db2:	84aa                	mv	s1,a0
    80004db4:	892e                	mv	s2,a1
    80004db6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	c88080e7          	jalr	-888(ra) # 80001a40 <myproc>
    80004dc0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	e0c080e7          	jalr	-500(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dcc:	2184a703          	lw	a4,536(s1)
    80004dd0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd8:	02f71463          	bne	a4,a5,80004e00 <piperead+0x62>
    80004ddc:	2244a783          	lw	a5,548(s1)
    80004de0:	c385                	beqz	a5,80004e00 <piperead+0x62>
    if(pr->killed){
    80004de2:	028a2783          	lw	a5,40(s4)
    80004de6:	ebc9                	bnez	a5,80004e78 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de8:	85a6                	mv	a1,s1
    80004dea:	854e                	mv	a0,s3
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	414080e7          	jalr	1044(ra) # 80002200 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df4:	2184a703          	lw	a4,536(s1)
    80004df8:	21c4a783          	lw	a5,540(s1)
    80004dfc:	fef700e3          	beq	a4,a5,80004ddc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e00:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e02:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e04:	05505463          	blez	s5,80004e4c <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004e08:	2184a783          	lw	a5,536(s1)
    80004e0c:	21c4a703          	lw	a4,540(s1)
    80004e10:	02f70e63          	beq	a4,a5,80004e4c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e14:	0017871b          	addiw	a4,a5,1
    80004e18:	20e4ac23          	sw	a4,536(s1)
    80004e1c:	1ff7f793          	andi	a5,a5,511
    80004e20:	97a6                	add	a5,a5,s1
    80004e22:	0187c783          	lbu	a5,24(a5)
    80004e26:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e2a:	4685                	li	a3,1
    80004e2c:	fbf40613          	addi	a2,s0,-65
    80004e30:	85ca                	mv	a1,s2
    80004e32:	050a3503          	ld	a0,80(s4)
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	824080e7          	jalr	-2012(ra) # 8000165a <copyout>
    80004e3e:	01650763          	beq	a0,s6,80004e4c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e42:	2985                	addiw	s3,s3,1
    80004e44:	0905                	addi	s2,s2,1
    80004e46:	fd3a91e3          	bne	s5,s3,80004e08 <piperead+0x6a>
    80004e4a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e4c:	21c48513          	addi	a0,s1,540
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	53c080e7          	jalr	1340(ra) # 8000238c <wakeup>
  release(&pi->lock);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	e2a080e7          	jalr	-470(ra) # 80000c84 <release>
  return i;
}
    80004e62:	854e                	mv	a0,s3
    80004e64:	60a6                	ld	ra,72(sp)
    80004e66:	6406                	ld	s0,64(sp)
    80004e68:	74e2                	ld	s1,56(sp)
    80004e6a:	7942                	ld	s2,48(sp)
    80004e6c:	79a2                	ld	s3,40(sp)
    80004e6e:	7a02                	ld	s4,32(sp)
    80004e70:	6ae2                	ld	s5,24(sp)
    80004e72:	6b42                	ld	s6,16(sp)
    80004e74:	6161                	addi	sp,sp,80
    80004e76:	8082                	ret
      release(&pi->lock);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	e0a080e7          	jalr	-502(ra) # 80000c84 <release>
      return -1;
    80004e82:	59fd                	li	s3,-1
    80004e84:	bff9                	j	80004e62 <piperead+0xc4>

0000000080004e86 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e86:	de010113          	addi	sp,sp,-544
    80004e8a:	20113c23          	sd	ra,536(sp)
    80004e8e:	20813823          	sd	s0,528(sp)
    80004e92:	20913423          	sd	s1,520(sp)
    80004e96:	21213023          	sd	s2,512(sp)
    80004e9a:	ffce                	sd	s3,504(sp)
    80004e9c:	fbd2                	sd	s4,496(sp)
    80004e9e:	f7d6                	sd	s5,488(sp)
    80004ea0:	f3da                	sd	s6,480(sp)
    80004ea2:	efde                	sd	s7,472(sp)
    80004ea4:	ebe2                	sd	s8,464(sp)
    80004ea6:	e7e6                	sd	s9,456(sp)
    80004ea8:	e3ea                	sd	s10,448(sp)
    80004eaa:	ff6e                	sd	s11,440(sp)
    80004eac:	1400                	addi	s0,sp,544
    80004eae:	892a                	mv	s2,a0
    80004eb0:	dea43423          	sd	a0,-536(s0)
    80004eb4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	b88080e7          	jalr	-1144(ra) # 80001a40 <myproc>
    80004ec0:	84aa                	mv	s1,a0

  begin_op();
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	4a8080e7          	jalr	1192(ra) # 8000436a <begin_op>

  if((ip = namei(path)) == 0){
    80004eca:	854a                	mv	a0,s2
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	27e080e7          	jalr	638(ra) # 8000414a <namei>
    80004ed4:	c93d                	beqz	a0,80004f4a <exec+0xc4>
    80004ed6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	ab6080e7          	jalr	-1354(ra) # 8000398e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ee0:	04000713          	li	a4,64
    80004ee4:	4681                	li	a3,0
    80004ee6:	e5040613          	addi	a2,s0,-432
    80004eea:	4581                	li	a1,0
    80004eec:	8556                	mv	a0,s5
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	d54080e7          	jalr	-684(ra) # 80003c42 <readi>
    80004ef6:	04000793          	li	a5,64
    80004efa:	00f51a63          	bne	a0,a5,80004f0e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004efe:	e5042703          	lw	a4,-432(s0)
    80004f02:	464c47b7          	lui	a5,0x464c4
    80004f06:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f0a:	04f70663          	beq	a4,a5,80004f56 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f0e:	8556                	mv	a0,s5
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	ce0080e7          	jalr	-800(ra) # 80003bf0 <iunlockput>
    end_op();
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	4d0080e7          	jalr	1232(ra) # 800043e8 <end_op>
  }
  return -1;
    80004f20:	557d                	li	a0,-1
}
    80004f22:	21813083          	ld	ra,536(sp)
    80004f26:	21013403          	ld	s0,528(sp)
    80004f2a:	20813483          	ld	s1,520(sp)
    80004f2e:	20013903          	ld	s2,512(sp)
    80004f32:	79fe                	ld	s3,504(sp)
    80004f34:	7a5e                	ld	s4,496(sp)
    80004f36:	7abe                	ld	s5,488(sp)
    80004f38:	7b1e                	ld	s6,480(sp)
    80004f3a:	6bfe                	ld	s7,472(sp)
    80004f3c:	6c5e                	ld	s8,464(sp)
    80004f3e:	6cbe                	ld	s9,456(sp)
    80004f40:	6d1e                	ld	s10,448(sp)
    80004f42:	7dfa                	ld	s11,440(sp)
    80004f44:	22010113          	addi	sp,sp,544
    80004f48:	8082                	ret
    end_op();
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	49e080e7          	jalr	1182(ra) # 800043e8 <end_op>
    return -1;
    80004f52:	557d                	li	a0,-1
    80004f54:	b7f9                	j	80004f22 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f56:	8526                	mv	a0,s1
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	bac080e7          	jalr	-1108(ra) # 80001b04 <proc_pagetable>
    80004f60:	8b2a                	mv	s6,a0
    80004f62:	d555                	beqz	a0,80004f0e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f64:	e7042783          	lw	a5,-400(s0)
    80004f68:	e8845703          	lhu	a4,-376(s0)
    80004f6c:	c735                	beqz	a4,80004fd8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f6e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f70:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004f74:	6a05                	lui	s4,0x1
    80004f76:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f7a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f7e:	6d85                	lui	s11,0x1
    80004f80:	7d7d                	lui	s10,0xfffff
    80004f82:	ac1d                	j	800051b8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f84:	00004517          	auipc	a0,0x4
    80004f88:	84450513          	addi	a0,a0,-1980 # 800087c8 <syscalls+0x298>
    80004f8c:	ffffb097          	auipc	ra,0xffffb
    80004f90:	5ae080e7          	jalr	1454(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f94:	874a                	mv	a4,s2
    80004f96:	009c86bb          	addw	a3,s9,s1
    80004f9a:	4581                	li	a1,0
    80004f9c:	8556                	mv	a0,s5
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	ca4080e7          	jalr	-860(ra) # 80003c42 <readi>
    80004fa6:	2501                	sext.w	a0,a0
    80004fa8:	1aa91863          	bne	s2,a0,80005158 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fac:	009d84bb          	addw	s1,s11,s1
    80004fb0:	013d09bb          	addw	s3,s10,s3
    80004fb4:	1f74f263          	bgeu	s1,s7,80005198 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fb8:	02049593          	slli	a1,s1,0x20
    80004fbc:	9181                	srli	a1,a1,0x20
    80004fbe:	95e2                	add	a1,a1,s8
    80004fc0:	855a                	mv	a0,s6
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	090080e7          	jalr	144(ra) # 80001052 <walkaddr>
    80004fca:	862a                	mv	a2,a0
    if(pa == 0)
    80004fcc:	dd45                	beqz	a0,80004f84 <exec+0xfe>
      n = PGSIZE;
    80004fce:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fd0:	fd49f2e3          	bgeu	s3,s4,80004f94 <exec+0x10e>
      n = sz - i;
    80004fd4:	894e                	mv	s2,s3
    80004fd6:	bf7d                	j	80004f94 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fd8:	4481                	li	s1,0
  iunlockput(ip);
    80004fda:	8556                	mv	a0,s5
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	c14080e7          	jalr	-1004(ra) # 80003bf0 <iunlockput>
  end_op();
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	404080e7          	jalr	1028(ra) # 800043e8 <end_op>
  p = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	a54080e7          	jalr	-1452(ra) # 80001a40 <myproc>
    80004ff4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ff6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ffa:	6785                	lui	a5,0x1
    80004ffc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004ffe:	97a6                	add	a5,a5,s1
    80005000:	777d                	lui	a4,0xfffff
    80005002:	8ff9                	and	a5,a5,a4
    80005004:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005008:	6609                	lui	a2,0x2
    8000500a:	963e                	add	a2,a2,a5
    8000500c:	85be                	mv	a1,a5
    8000500e:	855a                	mv	a0,s6
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	3f6080e7          	jalr	1014(ra) # 80001406 <uvmalloc>
    80005018:	8c2a                	mv	s8,a0
  ip = 0;
    8000501a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000501c:	12050e63          	beqz	a0,80005158 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005020:	75f9                	lui	a1,0xffffe
    80005022:	95aa                	add	a1,a1,a0
    80005024:	855a                	mv	a0,s6
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	602080e7          	jalr	1538(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    8000502e:	7afd                	lui	s5,0xfffff
    80005030:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005032:	df043783          	ld	a5,-528(s0)
    80005036:	6388                	ld	a0,0(a5)
    80005038:	c925                	beqz	a0,800050a8 <exec+0x222>
    8000503a:	e9040993          	addi	s3,s0,-368
    8000503e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005042:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005044:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	e02080e7          	jalr	-510(ra) # 80000e48 <strlen>
    8000504e:	0015079b          	addiw	a5,a0,1
    80005052:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005056:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000505a:	13596363          	bltu	s2,s5,80005180 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000505e:	df043d83          	ld	s11,-528(s0)
    80005062:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005066:	8552                	mv	a0,s4
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	de0080e7          	jalr	-544(ra) # 80000e48 <strlen>
    80005070:	0015069b          	addiw	a3,a0,1
    80005074:	8652                	mv	a2,s4
    80005076:	85ca                	mv	a1,s2
    80005078:	855a                	mv	a0,s6
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	5e0080e7          	jalr	1504(ra) # 8000165a <copyout>
    80005082:	10054363          	bltz	a0,80005188 <exec+0x302>
    ustack[argc] = sp;
    80005086:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000508a:	0485                	addi	s1,s1,1
    8000508c:	008d8793          	addi	a5,s11,8
    80005090:	def43823          	sd	a5,-528(s0)
    80005094:	008db503          	ld	a0,8(s11)
    80005098:	c911                	beqz	a0,800050ac <exec+0x226>
    if(argc >= MAXARG)
    8000509a:	09a1                	addi	s3,s3,8
    8000509c:	fb3c95e3          	bne	s9,s3,80005046 <exec+0x1c0>
  sz = sz1;
    800050a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050a4:	4a81                	li	s5,0
    800050a6:	a84d                	j	80005158 <exec+0x2d2>
  sp = sz;
    800050a8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800050ac:	00349793          	slli	a5,s1,0x3
    800050b0:	f9078793          	addi	a5,a5,-112
    800050b4:	97a2                	add	a5,a5,s0
    800050b6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800050ba:	00148693          	addi	a3,s1,1
    800050be:	068e                	slli	a3,a3,0x3
    800050c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050c8:	01597663          	bgeu	s2,s5,800050d4 <exec+0x24e>
  sz = sz1;
    800050cc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050d0:	4a81                	li	s5,0
    800050d2:	a059                	j	80005158 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050d4:	e9040613          	addi	a2,s0,-368
    800050d8:	85ca                	mv	a1,s2
    800050da:	855a                	mv	a0,s6
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	57e080e7          	jalr	1406(ra) # 8000165a <copyout>
    800050e4:	0a054663          	bltz	a0,80005190 <exec+0x30a>
  p->trapframe->a1 = sp;
    800050e8:	058bb783          	ld	a5,88(s7)
    800050ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050f0:	de843783          	ld	a5,-536(s0)
    800050f4:	0007c703          	lbu	a4,0(a5)
    800050f8:	cf11                	beqz	a4,80005114 <exec+0x28e>
    800050fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050fc:	02f00693          	li	a3,47
    80005100:	a039                	j	8000510e <exec+0x288>
      last = s+1;
    80005102:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005106:	0785                	addi	a5,a5,1
    80005108:	fff7c703          	lbu	a4,-1(a5)
    8000510c:	c701                	beqz	a4,80005114 <exec+0x28e>
    if(*s == '/')
    8000510e:	fed71ce3          	bne	a4,a3,80005106 <exec+0x280>
    80005112:	bfc5                	j	80005102 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005114:	4641                	li	a2,16
    80005116:	de843583          	ld	a1,-536(s0)
    8000511a:	158b8513          	addi	a0,s7,344
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	cf8080e7          	jalr	-776(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005126:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000512a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000512e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005132:	058bb783          	ld	a5,88(s7)
    80005136:	e6843703          	ld	a4,-408(s0)
    8000513a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000513c:	058bb783          	ld	a5,88(s7)
    80005140:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005144:	85ea                	mv	a1,s10
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	a5a080e7          	jalr	-1446(ra) # 80001ba0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000514e:	0004851b          	sext.w	a0,s1
    80005152:	bbc1                	j	80004f22 <exec+0x9c>
    80005154:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005158:	df843583          	ld	a1,-520(s0)
    8000515c:	855a                	mv	a0,s6
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	a42080e7          	jalr	-1470(ra) # 80001ba0 <proc_freepagetable>
  if(ip){
    80005166:	da0a94e3          	bnez	s5,80004f0e <exec+0x88>
  return -1;
    8000516a:	557d                	li	a0,-1
    8000516c:	bb5d                	j	80004f22 <exec+0x9c>
    8000516e:	de943c23          	sd	s1,-520(s0)
    80005172:	b7dd                	j	80005158 <exec+0x2d2>
    80005174:	de943c23          	sd	s1,-520(s0)
    80005178:	b7c5                	j	80005158 <exec+0x2d2>
    8000517a:	de943c23          	sd	s1,-520(s0)
    8000517e:	bfe9                	j	80005158 <exec+0x2d2>
  sz = sz1;
    80005180:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005184:	4a81                	li	s5,0
    80005186:	bfc9                	j	80005158 <exec+0x2d2>
  sz = sz1;
    80005188:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000518c:	4a81                	li	s5,0
    8000518e:	b7e9                	j	80005158 <exec+0x2d2>
  sz = sz1;
    80005190:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005194:	4a81                	li	s5,0
    80005196:	b7c9                	j	80005158 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005198:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000519c:	e0843783          	ld	a5,-504(s0)
    800051a0:	0017869b          	addiw	a3,a5,1
    800051a4:	e0d43423          	sd	a3,-504(s0)
    800051a8:	e0043783          	ld	a5,-512(s0)
    800051ac:	0387879b          	addiw	a5,a5,56
    800051b0:	e8845703          	lhu	a4,-376(s0)
    800051b4:	e2e6d3e3          	bge	a3,a4,80004fda <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051b8:	2781                	sext.w	a5,a5
    800051ba:	e0f43023          	sd	a5,-512(s0)
    800051be:	03800713          	li	a4,56
    800051c2:	86be                	mv	a3,a5
    800051c4:	e1840613          	addi	a2,s0,-488
    800051c8:	4581                	li	a1,0
    800051ca:	8556                	mv	a0,s5
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	a76080e7          	jalr	-1418(ra) # 80003c42 <readi>
    800051d4:	03800793          	li	a5,56
    800051d8:	f6f51ee3          	bne	a0,a5,80005154 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051dc:	e1842783          	lw	a5,-488(s0)
    800051e0:	4705                	li	a4,1
    800051e2:	fae79de3          	bne	a5,a4,8000519c <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051e6:	e4043603          	ld	a2,-448(s0)
    800051ea:	e3843783          	ld	a5,-456(s0)
    800051ee:	f8f660e3          	bltu	a2,a5,8000516e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051f2:	e2843783          	ld	a5,-472(s0)
    800051f6:	963e                	add	a2,a2,a5
    800051f8:	f6f66ee3          	bltu	a2,a5,80005174 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051fc:	85a6                	mv	a1,s1
    800051fe:	855a                	mv	a0,s6
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	206080e7          	jalr	518(ra) # 80001406 <uvmalloc>
    80005208:	dea43c23          	sd	a0,-520(s0)
    8000520c:	d53d                	beqz	a0,8000517a <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000520e:	e2843c03          	ld	s8,-472(s0)
    80005212:	de043783          	ld	a5,-544(s0)
    80005216:	00fc77b3          	and	a5,s8,a5
    8000521a:	ff9d                	bnez	a5,80005158 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000521c:	e2042c83          	lw	s9,-480(s0)
    80005220:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005224:	f60b8ae3          	beqz	s7,80005198 <exec+0x312>
    80005228:	89de                	mv	s3,s7
    8000522a:	4481                	li	s1,0
    8000522c:	b371                	j	80004fb8 <exec+0x132>

000000008000522e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000522e:	7179                	addi	sp,sp,-48
    80005230:	f406                	sd	ra,40(sp)
    80005232:	f022                	sd	s0,32(sp)
    80005234:	ec26                	sd	s1,24(sp)
    80005236:	e84a                	sd	s2,16(sp)
    80005238:	1800                	addi	s0,sp,48
    8000523a:	892e                	mv	s2,a1
    8000523c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000523e:	fdc40593          	addi	a1,s0,-36
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	b5e080e7          	jalr	-1186(ra) # 80002da0 <argint>
    8000524a:	04054063          	bltz	a0,8000528a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000524e:	fdc42703          	lw	a4,-36(s0)
    80005252:	47bd                	li	a5,15
    80005254:	02e7ed63          	bltu	a5,a4,8000528e <argfd+0x60>
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	7e8080e7          	jalr	2024(ra) # 80001a40 <myproc>
    80005260:	fdc42703          	lw	a4,-36(s0)
    80005264:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80005268:	078e                	slli	a5,a5,0x3
    8000526a:	953e                	add	a0,a0,a5
    8000526c:	611c                	ld	a5,0(a0)
    8000526e:	c395                	beqz	a5,80005292 <argfd+0x64>
    return -1;
  if(pfd)
    80005270:	00090463          	beqz	s2,80005278 <argfd+0x4a>
    *pfd = fd;
    80005274:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005278:	4501                	li	a0,0
  if(pf)
    8000527a:	c091                	beqz	s1,8000527e <argfd+0x50>
    *pf = f;
    8000527c:	e09c                	sd	a5,0(s1)
}
    8000527e:	70a2                	ld	ra,40(sp)
    80005280:	7402                	ld	s0,32(sp)
    80005282:	64e2                	ld	s1,24(sp)
    80005284:	6942                	ld	s2,16(sp)
    80005286:	6145                	addi	sp,sp,48
    80005288:	8082                	ret
    return -1;
    8000528a:	557d                	li	a0,-1
    8000528c:	bfcd                	j	8000527e <argfd+0x50>
    return -1;
    8000528e:	557d                	li	a0,-1
    80005290:	b7fd                	j	8000527e <argfd+0x50>
    80005292:	557d                	li	a0,-1
    80005294:	b7ed                	j	8000527e <argfd+0x50>

0000000080005296 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005296:	1101                	addi	sp,sp,-32
    80005298:	ec06                	sd	ra,24(sp)
    8000529a:	e822                	sd	s0,16(sp)
    8000529c:	e426                	sd	s1,8(sp)
    8000529e:	1000                	addi	s0,sp,32
    800052a0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	79e080e7          	jalr	1950(ra) # 80001a40 <myproc>
    800052aa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ac:	0d050793          	addi	a5,a0,208
    800052b0:	4501                	li	a0,0
    800052b2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052b4:	6398                	ld	a4,0(a5)
    800052b6:	cb19                	beqz	a4,800052cc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052b8:	2505                	addiw	a0,a0,1
    800052ba:	07a1                	addi	a5,a5,8
    800052bc:	fed51ce3          	bne	a0,a3,800052b4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052c0:	557d                	li	a0,-1
}
    800052c2:	60e2                	ld	ra,24(sp)
    800052c4:	6442                	ld	s0,16(sp)
    800052c6:	64a2                	ld	s1,8(sp)
    800052c8:	6105                	addi	sp,sp,32
    800052ca:	8082                	ret
      p->ofile[fd] = f;
    800052cc:	01a50793          	addi	a5,a0,26
    800052d0:	078e                	slli	a5,a5,0x3
    800052d2:	963e                	add	a2,a2,a5
    800052d4:	e204                	sd	s1,0(a2)
      return fd;
    800052d6:	b7f5                	j	800052c2 <fdalloc+0x2c>

00000000800052d8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052d8:	715d                	addi	sp,sp,-80
    800052da:	e486                	sd	ra,72(sp)
    800052dc:	e0a2                	sd	s0,64(sp)
    800052de:	fc26                	sd	s1,56(sp)
    800052e0:	f84a                	sd	s2,48(sp)
    800052e2:	f44e                	sd	s3,40(sp)
    800052e4:	f052                	sd	s4,32(sp)
    800052e6:	ec56                	sd	s5,24(sp)
    800052e8:	0880                	addi	s0,sp,80
    800052ea:	89ae                	mv	s3,a1
    800052ec:	8ab2                	mv	s5,a2
    800052ee:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052f0:	fb040593          	addi	a1,s0,-80
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	e74080e7          	jalr	-396(ra) # 80004168 <nameiparent>
    800052fc:	892a                	mv	s2,a0
    800052fe:	12050e63          	beqz	a0,8000543a <create+0x162>
    return 0;

  ilock(dp);
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	68c080e7          	jalr	1676(ra) # 8000398e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000530a:	4601                	li	a2,0
    8000530c:	fb040593          	addi	a1,s0,-80
    80005310:	854a                	mv	a0,s2
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	b60080e7          	jalr	-1184(ra) # 80003e72 <dirlookup>
    8000531a:	84aa                	mv	s1,a0
    8000531c:	c921                	beqz	a0,8000536c <create+0x94>
    iunlockput(dp);
    8000531e:	854a                	mv	a0,s2
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	8d0080e7          	jalr	-1840(ra) # 80003bf0 <iunlockput>
    ilock(ip);
    80005328:	8526                	mv	a0,s1
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	664080e7          	jalr	1636(ra) # 8000398e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005332:	2981                	sext.w	s3,s3
    80005334:	4789                	li	a5,2
    80005336:	02f99463          	bne	s3,a5,8000535e <create+0x86>
    8000533a:	0444d783          	lhu	a5,68(s1)
    8000533e:	37f9                	addiw	a5,a5,-2
    80005340:	17c2                	slli	a5,a5,0x30
    80005342:	93c1                	srli	a5,a5,0x30
    80005344:	4705                	li	a4,1
    80005346:	00f76c63          	bltu	a4,a5,8000535e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000534a:	8526                	mv	a0,s1
    8000534c:	60a6                	ld	ra,72(sp)
    8000534e:	6406                	ld	s0,64(sp)
    80005350:	74e2                	ld	s1,56(sp)
    80005352:	7942                	ld	s2,48(sp)
    80005354:	79a2                	ld	s3,40(sp)
    80005356:	7a02                	ld	s4,32(sp)
    80005358:	6ae2                	ld	s5,24(sp)
    8000535a:	6161                	addi	sp,sp,80
    8000535c:	8082                	ret
    iunlockput(ip);
    8000535e:	8526                	mv	a0,s1
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	890080e7          	jalr	-1904(ra) # 80003bf0 <iunlockput>
    return 0;
    80005368:	4481                	li	s1,0
    8000536a:	b7c5                	j	8000534a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000536c:	85ce                	mv	a1,s3
    8000536e:	00092503          	lw	a0,0(s2)
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	482080e7          	jalr	1154(ra) # 800037f4 <ialloc>
    8000537a:	84aa                	mv	s1,a0
    8000537c:	c521                	beqz	a0,800053c4 <create+0xec>
  ilock(ip);
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	610080e7          	jalr	1552(ra) # 8000398e <ilock>
  ip->major = major;
    80005386:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000538a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000538e:	4a05                	li	s4,1
    80005390:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	52c080e7          	jalr	1324(ra) # 800038c2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000539e:	2981                	sext.w	s3,s3
    800053a0:	03498a63          	beq	s3,s4,800053d4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053a4:	40d0                	lw	a2,4(s1)
    800053a6:	fb040593          	addi	a1,s0,-80
    800053aa:	854a                	mv	a0,s2
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	cdc080e7          	jalr	-804(ra) # 80004088 <dirlink>
    800053b4:	06054b63          	bltz	a0,8000542a <create+0x152>
  iunlockput(dp);
    800053b8:	854a                	mv	a0,s2
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	836080e7          	jalr	-1994(ra) # 80003bf0 <iunlockput>
  return ip;
    800053c2:	b761                	j	8000534a <create+0x72>
    panic("create: ialloc");
    800053c4:	00003517          	auipc	a0,0x3
    800053c8:	42450513          	addi	a0,a0,1060 # 800087e8 <syscalls+0x2b8>
    800053cc:	ffffb097          	auipc	ra,0xffffb
    800053d0:	16e080e7          	jalr	366(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    800053d4:	04a95783          	lhu	a5,74(s2)
    800053d8:	2785                	addiw	a5,a5,1
    800053da:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053de:	854a                	mv	a0,s2
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	4e2080e7          	jalr	1250(ra) # 800038c2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053e8:	40d0                	lw	a2,4(s1)
    800053ea:	00003597          	auipc	a1,0x3
    800053ee:	40e58593          	addi	a1,a1,1038 # 800087f8 <syscalls+0x2c8>
    800053f2:	8526                	mv	a0,s1
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	c94080e7          	jalr	-876(ra) # 80004088 <dirlink>
    800053fc:	00054f63          	bltz	a0,8000541a <create+0x142>
    80005400:	00492603          	lw	a2,4(s2)
    80005404:	00003597          	auipc	a1,0x3
    80005408:	3fc58593          	addi	a1,a1,1020 # 80008800 <syscalls+0x2d0>
    8000540c:	8526                	mv	a0,s1
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	c7a080e7          	jalr	-902(ra) # 80004088 <dirlink>
    80005416:	f80557e3          	bgez	a0,800053a4 <create+0xcc>
      panic("create dots");
    8000541a:	00003517          	auipc	a0,0x3
    8000541e:	3ee50513          	addi	a0,a0,1006 # 80008808 <syscalls+0x2d8>
    80005422:	ffffb097          	auipc	ra,0xffffb
    80005426:	118080e7          	jalr	280(ra) # 8000053a <panic>
    panic("create: dirlink");
    8000542a:	00003517          	auipc	a0,0x3
    8000542e:	3ee50513          	addi	a0,a0,1006 # 80008818 <syscalls+0x2e8>
    80005432:	ffffb097          	auipc	ra,0xffffb
    80005436:	108080e7          	jalr	264(ra) # 8000053a <panic>
    return 0;
    8000543a:	84aa                	mv	s1,a0
    8000543c:	b739                	j	8000534a <create+0x72>

000000008000543e <sys_dup>:
{
    8000543e:	7179                	addi	sp,sp,-48
    80005440:	f406                	sd	ra,40(sp)
    80005442:	f022                	sd	s0,32(sp)
    80005444:	ec26                	sd	s1,24(sp)
    80005446:	e84a                	sd	s2,16(sp)
    80005448:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000544a:	fd840613          	addi	a2,s0,-40
    8000544e:	4581                	li	a1,0
    80005450:	4501                	li	a0,0
    80005452:	00000097          	auipc	ra,0x0
    80005456:	ddc080e7          	jalr	-548(ra) # 8000522e <argfd>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000545c:	02054363          	bltz	a0,80005482 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005460:	fd843903          	ld	s2,-40(s0)
    80005464:	854a                	mv	a0,s2
    80005466:	00000097          	auipc	ra,0x0
    8000546a:	e30080e7          	jalr	-464(ra) # 80005296 <fdalloc>
    8000546e:	84aa                	mv	s1,a0
    return -1;
    80005470:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005472:	00054863          	bltz	a0,80005482 <sys_dup+0x44>
  filedup(f);
    80005476:	854a                	mv	a0,s2
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	368080e7          	jalr	872(ra) # 800047e0 <filedup>
  return fd;
    80005480:	87a6                	mv	a5,s1
}
    80005482:	853e                	mv	a0,a5
    80005484:	70a2                	ld	ra,40(sp)
    80005486:	7402                	ld	s0,32(sp)
    80005488:	64e2                	ld	s1,24(sp)
    8000548a:	6942                	ld	s2,16(sp)
    8000548c:	6145                	addi	sp,sp,48
    8000548e:	8082                	ret

0000000080005490 <sys_read>:
{
    80005490:	7179                	addi	sp,sp,-48
    80005492:	f406                	sd	ra,40(sp)
    80005494:	f022                	sd	s0,32(sp)
    80005496:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005498:	fe840613          	addi	a2,s0,-24
    8000549c:	4581                	li	a1,0
    8000549e:	4501                	li	a0,0
    800054a0:	00000097          	auipc	ra,0x0
    800054a4:	d8e080e7          	jalr	-626(ra) # 8000522e <argfd>
    return -1;
    800054a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054aa:	04054163          	bltz	a0,800054ec <sys_read+0x5c>
    800054ae:	fe440593          	addi	a1,s0,-28
    800054b2:	4509                	li	a0,2
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	8ec080e7          	jalr	-1812(ra) # 80002da0 <argint>
    return -1;
    800054bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054be:	02054763          	bltz	a0,800054ec <sys_read+0x5c>
    800054c2:	fd840593          	addi	a1,s0,-40
    800054c6:	4505                	li	a0,1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	8fa080e7          	jalr	-1798(ra) # 80002dc2 <argaddr>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d2:	00054d63          	bltz	a0,800054ec <sys_read+0x5c>
  return fileread(f, p, n);
    800054d6:	fe442603          	lw	a2,-28(s0)
    800054da:	fd843583          	ld	a1,-40(s0)
    800054de:	fe843503          	ld	a0,-24(s0)
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	48a080e7          	jalr	1162(ra) # 8000496c <fileread>
    800054ea:	87aa                	mv	a5,a0
}
    800054ec:	853e                	mv	a0,a5
    800054ee:	70a2                	ld	ra,40(sp)
    800054f0:	7402                	ld	s0,32(sp)
    800054f2:	6145                	addi	sp,sp,48
    800054f4:	8082                	ret

00000000800054f6 <sys_write>:
{
    800054f6:	7179                	addi	sp,sp,-48
    800054f8:	f406                	sd	ra,40(sp)
    800054fa:	f022                	sd	s0,32(sp)
    800054fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fe:	fe840613          	addi	a2,s0,-24
    80005502:	4581                	li	a1,0
    80005504:	4501                	li	a0,0
    80005506:	00000097          	auipc	ra,0x0
    8000550a:	d28080e7          	jalr	-728(ra) # 8000522e <argfd>
    return -1;
    8000550e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005510:	04054163          	bltz	a0,80005552 <sys_write+0x5c>
    80005514:	fe440593          	addi	a1,s0,-28
    80005518:	4509                	li	a0,2
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	886080e7          	jalr	-1914(ra) # 80002da0 <argint>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005524:	02054763          	bltz	a0,80005552 <sys_write+0x5c>
    80005528:	fd840593          	addi	a1,s0,-40
    8000552c:	4505                	li	a0,1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	894080e7          	jalr	-1900(ra) # 80002dc2 <argaddr>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005538:	00054d63          	bltz	a0,80005552 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000553c:	fe442603          	lw	a2,-28(s0)
    80005540:	fd843583          	ld	a1,-40(s0)
    80005544:	fe843503          	ld	a0,-24(s0)
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	4e6080e7          	jalr	1254(ra) # 80004a2e <filewrite>
    80005550:	87aa                	mv	a5,a0
}
    80005552:	853e                	mv	a0,a5
    80005554:	70a2                	ld	ra,40(sp)
    80005556:	7402                	ld	s0,32(sp)
    80005558:	6145                	addi	sp,sp,48
    8000555a:	8082                	ret

000000008000555c <sys_close>:
{
    8000555c:	1101                	addi	sp,sp,-32
    8000555e:	ec06                	sd	ra,24(sp)
    80005560:	e822                	sd	s0,16(sp)
    80005562:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005564:	fe040613          	addi	a2,s0,-32
    80005568:	fec40593          	addi	a1,s0,-20
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	cc0080e7          	jalr	-832(ra) # 8000522e <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005578:	02054463          	bltz	a0,800055a0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000557c:	ffffc097          	auipc	ra,0xffffc
    80005580:	4c4080e7          	jalr	1220(ra) # 80001a40 <myproc>
    80005584:	fec42783          	lw	a5,-20(s0)
    80005588:	07e9                	addi	a5,a5,26
    8000558a:	078e                	slli	a5,a5,0x3
    8000558c:	953e                	add	a0,a0,a5
    8000558e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005592:	fe043503          	ld	a0,-32(s0)
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	29c080e7          	jalr	668(ra) # 80004832 <fileclose>
  return 0;
    8000559e:	4781                	li	a5,0
}
    800055a0:	853e                	mv	a0,a5
    800055a2:	60e2                	ld	ra,24(sp)
    800055a4:	6442                	ld	s0,16(sp)
    800055a6:	6105                	addi	sp,sp,32
    800055a8:	8082                	ret

00000000800055aa <sys_fstat>:
{
    800055aa:	1101                	addi	sp,sp,-32
    800055ac:	ec06                	sd	ra,24(sp)
    800055ae:	e822                	sd	s0,16(sp)
    800055b0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055b2:	fe840613          	addi	a2,s0,-24
    800055b6:	4581                	li	a1,0
    800055b8:	4501                	li	a0,0
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	c74080e7          	jalr	-908(ra) # 8000522e <argfd>
    return -1;
    800055c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c4:	02054563          	bltz	a0,800055ee <sys_fstat+0x44>
    800055c8:	fe040593          	addi	a1,s0,-32
    800055cc:	4505                	li	a0,1
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	7f4080e7          	jalr	2036(ra) # 80002dc2 <argaddr>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d8:	00054b63          	bltz	a0,800055ee <sys_fstat+0x44>
  return filestat(f, st);
    800055dc:	fe043583          	ld	a1,-32(s0)
    800055e0:	fe843503          	ld	a0,-24(s0)
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	316080e7          	jalr	790(ra) # 800048fa <filestat>
    800055ec:	87aa                	mv	a5,a0
}
    800055ee:	853e                	mv	a0,a5
    800055f0:	60e2                	ld	ra,24(sp)
    800055f2:	6442                	ld	s0,16(sp)
    800055f4:	6105                	addi	sp,sp,32
    800055f6:	8082                	ret

00000000800055f8 <sys_link>:
{
    800055f8:	7169                	addi	sp,sp,-304
    800055fa:	f606                	sd	ra,296(sp)
    800055fc:	f222                	sd	s0,288(sp)
    800055fe:	ee26                	sd	s1,280(sp)
    80005600:	ea4a                	sd	s2,272(sp)
    80005602:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005604:	08000613          	li	a2,128
    80005608:	ed040593          	addi	a1,s0,-304
    8000560c:	4501                	li	a0,0
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	7d6080e7          	jalr	2006(ra) # 80002de4 <argstr>
    return -1;
    80005616:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005618:	10054e63          	bltz	a0,80005734 <sys_link+0x13c>
    8000561c:	08000613          	li	a2,128
    80005620:	f5040593          	addi	a1,s0,-176
    80005624:	4505                	li	a0,1
    80005626:	ffffd097          	auipc	ra,0xffffd
    8000562a:	7be080e7          	jalr	1982(ra) # 80002de4 <argstr>
    return -1;
    8000562e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005630:	10054263          	bltz	a0,80005734 <sys_link+0x13c>
  begin_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	d36080e7          	jalr	-714(ra) # 8000436a <begin_op>
  if((ip = namei(old)) == 0){
    8000563c:	ed040513          	addi	a0,s0,-304
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b0a080e7          	jalr	-1270(ra) # 8000414a <namei>
    80005648:	84aa                	mv	s1,a0
    8000564a:	c551                	beqz	a0,800056d6 <sys_link+0xde>
  ilock(ip);
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	342080e7          	jalr	834(ra) # 8000398e <ilock>
  if(ip->type == T_DIR){
    80005654:	04449703          	lh	a4,68(s1)
    80005658:	4785                	li	a5,1
    8000565a:	08f70463          	beq	a4,a5,800056e2 <sys_link+0xea>
  ip->nlink++;
    8000565e:	04a4d783          	lhu	a5,74(s1)
    80005662:	2785                	addiw	a5,a5,1
    80005664:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	258080e7          	jalr	600(ra) # 800038c2 <iupdate>
  iunlock(ip);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	3dc080e7          	jalr	988(ra) # 80003a50 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000567c:	fd040593          	addi	a1,s0,-48
    80005680:	f5040513          	addi	a0,s0,-176
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	ae4080e7          	jalr	-1308(ra) # 80004168 <nameiparent>
    8000568c:	892a                	mv	s2,a0
    8000568e:	c935                	beqz	a0,80005702 <sys_link+0x10a>
  ilock(dp);
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	2fe080e7          	jalr	766(ra) # 8000398e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005698:	00092703          	lw	a4,0(s2)
    8000569c:	409c                	lw	a5,0(s1)
    8000569e:	04f71d63          	bne	a4,a5,800056f8 <sys_link+0x100>
    800056a2:	40d0                	lw	a2,4(s1)
    800056a4:	fd040593          	addi	a1,s0,-48
    800056a8:	854a                	mv	a0,s2
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	9de080e7          	jalr	-1570(ra) # 80004088 <dirlink>
    800056b2:	04054363          	bltz	a0,800056f8 <sys_link+0x100>
  iunlockput(dp);
    800056b6:	854a                	mv	a0,s2
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	538080e7          	jalr	1336(ra) # 80003bf0 <iunlockput>
  iput(ip);
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	486080e7          	jalr	1158(ra) # 80003b48 <iput>
  end_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	d1e080e7          	jalr	-738(ra) # 800043e8 <end_op>
  return 0;
    800056d2:	4781                	li	a5,0
    800056d4:	a085                	j	80005734 <sys_link+0x13c>
    end_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	d12080e7          	jalr	-750(ra) # 800043e8 <end_op>
    return -1;
    800056de:	57fd                	li	a5,-1
    800056e0:	a891                	j	80005734 <sys_link+0x13c>
    iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	50c080e7          	jalr	1292(ra) # 80003bf0 <iunlockput>
    end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cfc080e7          	jalr	-772(ra) # 800043e8 <end_op>
    return -1;
    800056f4:	57fd                	li	a5,-1
    800056f6:	a83d                	j	80005734 <sys_link+0x13c>
    iunlockput(dp);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	4f6080e7          	jalr	1270(ra) # 80003bf0 <iunlockput>
  ilock(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	28a080e7          	jalr	650(ra) # 8000398e <ilock>
  ip->nlink--;
    8000570c:	04a4d783          	lhu	a5,74(s1)
    80005710:	37fd                	addiw	a5,a5,-1
    80005712:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	1aa080e7          	jalr	426(ra) # 800038c2 <iupdate>
  iunlockput(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	4ce080e7          	jalr	1230(ra) # 80003bf0 <iunlockput>
  end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	cbe080e7          	jalr	-834(ra) # 800043e8 <end_op>
  return -1;
    80005732:	57fd                	li	a5,-1
}
    80005734:	853e                	mv	a0,a5
    80005736:	70b2                	ld	ra,296(sp)
    80005738:	7412                	ld	s0,288(sp)
    8000573a:	64f2                	ld	s1,280(sp)
    8000573c:	6952                	ld	s2,272(sp)
    8000573e:	6155                	addi	sp,sp,304
    80005740:	8082                	ret

0000000080005742 <sys_unlink>:
{
    80005742:	7151                	addi	sp,sp,-240
    80005744:	f586                	sd	ra,232(sp)
    80005746:	f1a2                	sd	s0,224(sp)
    80005748:	eda6                	sd	s1,216(sp)
    8000574a:	e9ca                	sd	s2,208(sp)
    8000574c:	e5ce                	sd	s3,200(sp)
    8000574e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005750:	08000613          	li	a2,128
    80005754:	f3040593          	addi	a1,s0,-208
    80005758:	4501                	li	a0,0
    8000575a:	ffffd097          	auipc	ra,0xffffd
    8000575e:	68a080e7          	jalr	1674(ra) # 80002de4 <argstr>
    80005762:	18054163          	bltz	a0,800058e4 <sys_unlink+0x1a2>
  begin_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	c04080e7          	jalr	-1020(ra) # 8000436a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000576e:	fb040593          	addi	a1,s0,-80
    80005772:	f3040513          	addi	a0,s0,-208
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	9f2080e7          	jalr	-1550(ra) # 80004168 <nameiparent>
    8000577e:	84aa                	mv	s1,a0
    80005780:	c979                	beqz	a0,80005856 <sys_unlink+0x114>
  ilock(dp);
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	20c080e7          	jalr	524(ra) # 8000398e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000578a:	00003597          	auipc	a1,0x3
    8000578e:	06e58593          	addi	a1,a1,110 # 800087f8 <syscalls+0x2c8>
    80005792:	fb040513          	addi	a0,s0,-80
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	6c2080e7          	jalr	1730(ra) # 80003e58 <namecmp>
    8000579e:	14050a63          	beqz	a0,800058f2 <sys_unlink+0x1b0>
    800057a2:	00003597          	auipc	a1,0x3
    800057a6:	05e58593          	addi	a1,a1,94 # 80008800 <syscalls+0x2d0>
    800057aa:	fb040513          	addi	a0,s0,-80
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	6aa080e7          	jalr	1706(ra) # 80003e58 <namecmp>
    800057b6:	12050e63          	beqz	a0,800058f2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057ba:	f2c40613          	addi	a2,s0,-212
    800057be:	fb040593          	addi	a1,s0,-80
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	6ae080e7          	jalr	1710(ra) # 80003e72 <dirlookup>
    800057cc:	892a                	mv	s2,a0
    800057ce:	12050263          	beqz	a0,800058f2 <sys_unlink+0x1b0>
  ilock(ip);
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	1bc080e7          	jalr	444(ra) # 8000398e <ilock>
  if(ip->nlink < 1)
    800057da:	04a91783          	lh	a5,74(s2)
    800057de:	08f05263          	blez	a5,80005862 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057e2:	04491703          	lh	a4,68(s2)
    800057e6:	4785                	li	a5,1
    800057e8:	08f70563          	beq	a4,a5,80005872 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ec:	4641                	li	a2,16
    800057ee:	4581                	li	a1,0
    800057f0:	fc040513          	addi	a0,s0,-64
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	4d8080e7          	jalr	1240(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057fc:	4741                	li	a4,16
    800057fe:	f2c42683          	lw	a3,-212(s0)
    80005802:	fc040613          	addi	a2,s0,-64
    80005806:	4581                	li	a1,0
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	530080e7          	jalr	1328(ra) # 80003d3a <writei>
    80005812:	47c1                	li	a5,16
    80005814:	0af51563          	bne	a0,a5,800058be <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005818:	04491703          	lh	a4,68(s2)
    8000581c:	4785                	li	a5,1
    8000581e:	0af70863          	beq	a4,a5,800058ce <sys_unlink+0x18c>
  iunlockput(dp);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	3cc080e7          	jalr	972(ra) # 80003bf0 <iunlockput>
  ip->nlink--;
    8000582c:	04a95783          	lhu	a5,74(s2)
    80005830:	37fd                	addiw	a5,a5,-1
    80005832:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	08a080e7          	jalr	138(ra) # 800038c2 <iupdate>
  iunlockput(ip);
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	3ae080e7          	jalr	942(ra) # 80003bf0 <iunlockput>
  end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	b9e080e7          	jalr	-1122(ra) # 800043e8 <end_op>
  return 0;
    80005852:	4501                	li	a0,0
    80005854:	a84d                	j	80005906 <sys_unlink+0x1c4>
    end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	b92080e7          	jalr	-1134(ra) # 800043e8 <end_op>
    return -1;
    8000585e:	557d                	li	a0,-1
    80005860:	a05d                	j	80005906 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005862:	00003517          	auipc	a0,0x3
    80005866:	fc650513          	addi	a0,a0,-58 # 80008828 <syscalls+0x2f8>
    8000586a:	ffffb097          	auipc	ra,0xffffb
    8000586e:	cd0080e7          	jalr	-816(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005872:	04c92703          	lw	a4,76(s2)
    80005876:	02000793          	li	a5,32
    8000587a:	f6e7f9e3          	bgeu	a5,a4,800057ec <sys_unlink+0xaa>
    8000587e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005882:	4741                	li	a4,16
    80005884:	86ce                	mv	a3,s3
    80005886:	f1840613          	addi	a2,s0,-232
    8000588a:	4581                	li	a1,0
    8000588c:	854a                	mv	a0,s2
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	3b4080e7          	jalr	948(ra) # 80003c42 <readi>
    80005896:	47c1                	li	a5,16
    80005898:	00f51b63          	bne	a0,a5,800058ae <sys_unlink+0x16c>
    if(de.inum != 0)
    8000589c:	f1845783          	lhu	a5,-232(s0)
    800058a0:	e7a1                	bnez	a5,800058e8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058a2:	29c1                	addiw	s3,s3,16
    800058a4:	04c92783          	lw	a5,76(s2)
    800058a8:	fcf9ede3          	bltu	s3,a5,80005882 <sys_unlink+0x140>
    800058ac:	b781                	j	800057ec <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ae:	00003517          	auipc	a0,0x3
    800058b2:	f9250513          	addi	a0,a0,-110 # 80008840 <syscalls+0x310>
    800058b6:	ffffb097          	auipc	ra,0xffffb
    800058ba:	c84080e7          	jalr	-892(ra) # 8000053a <panic>
    panic("unlink: writei");
    800058be:	00003517          	auipc	a0,0x3
    800058c2:	f9a50513          	addi	a0,a0,-102 # 80008858 <syscalls+0x328>
    800058c6:	ffffb097          	auipc	ra,0xffffb
    800058ca:	c74080e7          	jalr	-908(ra) # 8000053a <panic>
    dp->nlink--;
    800058ce:	04a4d783          	lhu	a5,74(s1)
    800058d2:	37fd                	addiw	a5,a5,-1
    800058d4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	fe8080e7          	jalr	-24(ra) # 800038c2 <iupdate>
    800058e2:	b781                	j	80005822 <sys_unlink+0xe0>
    return -1;
    800058e4:	557d                	li	a0,-1
    800058e6:	a005                	j	80005906 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	306080e7          	jalr	774(ra) # 80003bf0 <iunlockput>
  iunlockput(dp);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	2fc080e7          	jalr	764(ra) # 80003bf0 <iunlockput>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	aec080e7          	jalr	-1300(ra) # 800043e8 <end_op>
  return -1;
    80005904:	557d                	li	a0,-1
}
    80005906:	70ae                	ld	ra,232(sp)
    80005908:	740e                	ld	s0,224(sp)
    8000590a:	64ee                	ld	s1,216(sp)
    8000590c:	694e                	ld	s2,208(sp)
    8000590e:	69ae                	ld	s3,200(sp)
    80005910:	616d                	addi	sp,sp,240
    80005912:	8082                	ret

0000000080005914 <sys_open>:

uint64
sys_open(void)
{
    80005914:	7131                	addi	sp,sp,-192
    80005916:	fd06                	sd	ra,184(sp)
    80005918:	f922                	sd	s0,176(sp)
    8000591a:	f526                	sd	s1,168(sp)
    8000591c:	f14a                	sd	s2,160(sp)
    8000591e:	ed4e                	sd	s3,152(sp)
    80005920:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005922:	08000613          	li	a2,128
    80005926:	f5040593          	addi	a1,s0,-176
    8000592a:	4501                	li	a0,0
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	4b8080e7          	jalr	1208(ra) # 80002de4 <argstr>
    return -1;
    80005934:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005936:	0c054163          	bltz	a0,800059f8 <sys_open+0xe4>
    8000593a:	f4c40593          	addi	a1,s0,-180
    8000593e:	4505                	li	a0,1
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	460080e7          	jalr	1120(ra) # 80002da0 <argint>
    80005948:	0a054863          	bltz	a0,800059f8 <sys_open+0xe4>

  begin_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	a1e080e7          	jalr	-1506(ra) # 8000436a <begin_op>

  if(omode & O_CREATE){
    80005954:	f4c42783          	lw	a5,-180(s0)
    80005958:	2007f793          	andi	a5,a5,512
    8000595c:	cbdd                	beqz	a5,80005a12 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000595e:	4681                	li	a3,0
    80005960:	4601                	li	a2,0
    80005962:	4589                	li	a1,2
    80005964:	f5040513          	addi	a0,s0,-176
    80005968:	00000097          	auipc	ra,0x0
    8000596c:	970080e7          	jalr	-1680(ra) # 800052d8 <create>
    80005970:	892a                	mv	s2,a0
    if(ip == 0){
    80005972:	c959                	beqz	a0,80005a08 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005974:	04491703          	lh	a4,68(s2)
    80005978:	478d                	li	a5,3
    8000597a:	00f71763          	bne	a4,a5,80005988 <sys_open+0x74>
    8000597e:	04695703          	lhu	a4,70(s2)
    80005982:	47a5                	li	a5,9
    80005984:	0ce7ec63          	bltu	a5,a4,80005a5c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	dee080e7          	jalr	-530(ra) # 80004776 <filealloc>
    80005990:	89aa                	mv	s3,a0
    80005992:	10050263          	beqz	a0,80005a96 <sys_open+0x182>
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	900080e7          	jalr	-1792(ra) # 80005296 <fdalloc>
    8000599e:	84aa                	mv	s1,a0
    800059a0:	0e054663          	bltz	a0,80005a8c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059a4:	04491703          	lh	a4,68(s2)
    800059a8:	478d                	li	a5,3
    800059aa:	0cf70463          	beq	a4,a5,80005a72 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ae:	4789                	li	a5,2
    800059b0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059b4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059b8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059bc:	f4c42783          	lw	a5,-180(s0)
    800059c0:	0017c713          	xori	a4,a5,1
    800059c4:	8b05                	andi	a4,a4,1
    800059c6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059ca:	0037f713          	andi	a4,a5,3
    800059ce:	00e03733          	snez	a4,a4
    800059d2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059d6:	4007f793          	andi	a5,a5,1024
    800059da:	c791                	beqz	a5,800059e6 <sys_open+0xd2>
    800059dc:	04491703          	lh	a4,68(s2)
    800059e0:	4789                	li	a5,2
    800059e2:	08f70f63          	beq	a4,a5,80005a80 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	068080e7          	jalr	104(ra) # 80003a50 <iunlock>
  end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	9f8080e7          	jalr	-1544(ra) # 800043e8 <end_op>

  return fd;
}
    800059f8:	8526                	mv	a0,s1
    800059fa:	70ea                	ld	ra,184(sp)
    800059fc:	744a                	ld	s0,176(sp)
    800059fe:	74aa                	ld	s1,168(sp)
    80005a00:	790a                	ld	s2,160(sp)
    80005a02:	69ea                	ld	s3,152(sp)
    80005a04:	6129                	addi	sp,sp,192
    80005a06:	8082                	ret
      end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	9e0080e7          	jalr	-1568(ra) # 800043e8 <end_op>
      return -1;
    80005a10:	b7e5                	j	800059f8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a12:	f5040513          	addi	a0,s0,-176
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	734080e7          	jalr	1844(ra) # 8000414a <namei>
    80005a1e:	892a                	mv	s2,a0
    80005a20:	c905                	beqz	a0,80005a50 <sys_open+0x13c>
    ilock(ip);
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	f6c080e7          	jalr	-148(ra) # 8000398e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a2a:	04491703          	lh	a4,68(s2)
    80005a2e:	4785                	li	a5,1
    80005a30:	f4f712e3          	bne	a4,a5,80005974 <sys_open+0x60>
    80005a34:	f4c42783          	lw	a5,-180(s0)
    80005a38:	dba1                	beqz	a5,80005988 <sys_open+0x74>
      iunlockput(ip);
    80005a3a:	854a                	mv	a0,s2
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	1b4080e7          	jalr	436(ra) # 80003bf0 <iunlockput>
      end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	9a4080e7          	jalr	-1628(ra) # 800043e8 <end_op>
      return -1;
    80005a4c:	54fd                	li	s1,-1
    80005a4e:	b76d                	j	800059f8 <sys_open+0xe4>
      end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	998080e7          	jalr	-1640(ra) # 800043e8 <end_op>
      return -1;
    80005a58:	54fd                	li	s1,-1
    80005a5a:	bf79                	j	800059f8 <sys_open+0xe4>
    iunlockput(ip);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	192080e7          	jalr	402(ra) # 80003bf0 <iunlockput>
    end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	982080e7          	jalr	-1662(ra) # 800043e8 <end_op>
    return -1;
    80005a6e:	54fd                	li	s1,-1
    80005a70:	b761                	j	800059f8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a72:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a76:	04691783          	lh	a5,70(s2)
    80005a7a:	02f99223          	sh	a5,36(s3)
    80005a7e:	bf2d                	j	800059b8 <sys_open+0xa4>
    itrunc(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	01a080e7          	jalr	26(ra) # 80003a9c <itrunc>
    80005a8a:	bfb1                	j	800059e6 <sys_open+0xd2>
      fileclose(f);
    80005a8c:	854e                	mv	a0,s3
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	da4080e7          	jalr	-604(ra) # 80004832 <fileclose>
    iunlockput(ip);
    80005a96:	854a                	mv	a0,s2
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	158080e7          	jalr	344(ra) # 80003bf0 <iunlockput>
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	948080e7          	jalr	-1720(ra) # 800043e8 <end_op>
    return -1;
    80005aa8:	54fd                	li	s1,-1
    80005aaa:	b7b9                	j	800059f8 <sys_open+0xe4>

0000000080005aac <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aac:	7175                	addi	sp,sp,-144
    80005aae:	e506                	sd	ra,136(sp)
    80005ab0:	e122                	sd	s0,128(sp)
    80005ab2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	8b6080e7          	jalr	-1866(ra) # 8000436a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005abc:	08000613          	li	a2,128
    80005ac0:	f7040593          	addi	a1,s0,-144
    80005ac4:	4501                	li	a0,0
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	31e080e7          	jalr	798(ra) # 80002de4 <argstr>
    80005ace:	02054963          	bltz	a0,80005b00 <sys_mkdir+0x54>
    80005ad2:	4681                	li	a3,0
    80005ad4:	4601                	li	a2,0
    80005ad6:	4585                	li	a1,1
    80005ad8:	f7040513          	addi	a0,s0,-144
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	7fc080e7          	jalr	2044(ra) # 800052d8 <create>
    80005ae4:	cd11                	beqz	a0,80005b00 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	10a080e7          	jalr	266(ra) # 80003bf0 <iunlockput>
  end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	8fa080e7          	jalr	-1798(ra) # 800043e8 <end_op>
  return 0;
    80005af6:	4501                	li	a0,0
}
    80005af8:	60aa                	ld	ra,136(sp)
    80005afa:	640a                	ld	s0,128(sp)
    80005afc:	6149                	addi	sp,sp,144
    80005afe:	8082                	ret
    end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	8e8080e7          	jalr	-1816(ra) # 800043e8 <end_op>
    return -1;
    80005b08:	557d                	li	a0,-1
    80005b0a:	b7fd                	j	80005af8 <sys_mkdir+0x4c>

0000000080005b0c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b0c:	7135                	addi	sp,sp,-160
    80005b0e:	ed06                	sd	ra,152(sp)
    80005b10:	e922                	sd	s0,144(sp)
    80005b12:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	856080e7          	jalr	-1962(ra) # 8000436a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b1c:	08000613          	li	a2,128
    80005b20:	f7040593          	addi	a1,s0,-144
    80005b24:	4501                	li	a0,0
    80005b26:	ffffd097          	auipc	ra,0xffffd
    80005b2a:	2be080e7          	jalr	702(ra) # 80002de4 <argstr>
    80005b2e:	04054a63          	bltz	a0,80005b82 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b32:	f6c40593          	addi	a1,s0,-148
    80005b36:	4505                	li	a0,1
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	268080e7          	jalr	616(ra) # 80002da0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b40:	04054163          	bltz	a0,80005b82 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b44:	f6840593          	addi	a1,s0,-152
    80005b48:	4509                	li	a0,2
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	256080e7          	jalr	598(ra) # 80002da0 <argint>
     argint(1, &major) < 0 ||
    80005b52:	02054863          	bltz	a0,80005b82 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b56:	f6841683          	lh	a3,-152(s0)
    80005b5a:	f6c41603          	lh	a2,-148(s0)
    80005b5e:	458d                	li	a1,3
    80005b60:	f7040513          	addi	a0,s0,-144
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	774080e7          	jalr	1908(ra) # 800052d8 <create>
     argint(2, &minor) < 0 ||
    80005b6c:	c919                	beqz	a0,80005b82 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	082080e7          	jalr	130(ra) # 80003bf0 <iunlockput>
  end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	872080e7          	jalr	-1934(ra) # 800043e8 <end_op>
  return 0;
    80005b7e:	4501                	li	a0,0
    80005b80:	a031                	j	80005b8c <sys_mknod+0x80>
    end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	866080e7          	jalr	-1946(ra) # 800043e8 <end_op>
    return -1;
    80005b8a:	557d                	li	a0,-1
}
    80005b8c:	60ea                	ld	ra,152(sp)
    80005b8e:	644a                	ld	s0,144(sp)
    80005b90:	610d                	addi	sp,sp,160
    80005b92:	8082                	ret

0000000080005b94 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b94:	7135                	addi	sp,sp,-160
    80005b96:	ed06                	sd	ra,152(sp)
    80005b98:	e922                	sd	s0,144(sp)
    80005b9a:	e526                	sd	s1,136(sp)
    80005b9c:	e14a                	sd	s2,128(sp)
    80005b9e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ba0:	ffffc097          	auipc	ra,0xffffc
    80005ba4:	ea0080e7          	jalr	-352(ra) # 80001a40 <myproc>
    80005ba8:	892a                	mv	s2,a0
  
  begin_op();
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	7c0080e7          	jalr	1984(ra) # 8000436a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bb2:	08000613          	li	a2,128
    80005bb6:	f6040593          	addi	a1,s0,-160
    80005bba:	4501                	li	a0,0
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	228080e7          	jalr	552(ra) # 80002de4 <argstr>
    80005bc4:	04054b63          	bltz	a0,80005c1a <sys_chdir+0x86>
    80005bc8:	f6040513          	addi	a0,s0,-160
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	57e080e7          	jalr	1406(ra) # 8000414a <namei>
    80005bd4:	84aa                	mv	s1,a0
    80005bd6:	c131                	beqz	a0,80005c1a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	db6080e7          	jalr	-586(ra) # 8000398e <ilock>
  if(ip->type != T_DIR){
    80005be0:	04449703          	lh	a4,68(s1)
    80005be4:	4785                	li	a5,1
    80005be6:	04f71063          	bne	a4,a5,80005c26 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	e64080e7          	jalr	-412(ra) # 80003a50 <iunlock>
  iput(p->cwd);
    80005bf4:	15093503          	ld	a0,336(s2)
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	f50080e7          	jalr	-176(ra) # 80003b48 <iput>
  end_op();
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	7e8080e7          	jalr	2024(ra) # 800043e8 <end_op>
  p->cwd = ip;
    80005c08:	14993823          	sd	s1,336(s2)
  return 0;
    80005c0c:	4501                	li	a0,0
}
    80005c0e:	60ea                	ld	ra,152(sp)
    80005c10:	644a                	ld	s0,144(sp)
    80005c12:	64aa                	ld	s1,136(sp)
    80005c14:	690a                	ld	s2,128(sp)
    80005c16:	610d                	addi	sp,sp,160
    80005c18:	8082                	ret
    end_op();
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	7ce080e7          	jalr	1998(ra) # 800043e8 <end_op>
    return -1;
    80005c22:	557d                	li	a0,-1
    80005c24:	b7ed                	j	80005c0e <sys_chdir+0x7a>
    iunlockput(ip);
    80005c26:	8526                	mv	a0,s1
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	fc8080e7          	jalr	-56(ra) # 80003bf0 <iunlockput>
    end_op();
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	7b8080e7          	jalr	1976(ra) # 800043e8 <end_op>
    return -1;
    80005c38:	557d                	li	a0,-1
    80005c3a:	bfd1                	j	80005c0e <sys_chdir+0x7a>

0000000080005c3c <sys_exec>:

uint64
sys_exec(void)
{
    80005c3c:	7145                	addi	sp,sp,-464
    80005c3e:	e786                	sd	ra,456(sp)
    80005c40:	e3a2                	sd	s0,448(sp)
    80005c42:	ff26                	sd	s1,440(sp)
    80005c44:	fb4a                	sd	s2,432(sp)
    80005c46:	f74e                	sd	s3,424(sp)
    80005c48:	f352                	sd	s4,416(sp)
    80005c4a:	ef56                	sd	s5,408(sp)
    80005c4c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c4e:	08000613          	li	a2,128
    80005c52:	f4040593          	addi	a1,s0,-192
    80005c56:	4501                	li	a0,0
    80005c58:	ffffd097          	auipc	ra,0xffffd
    80005c5c:	18c080e7          	jalr	396(ra) # 80002de4 <argstr>
    return -1;
    80005c60:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c62:	0c054b63          	bltz	a0,80005d38 <sys_exec+0xfc>
    80005c66:	e3840593          	addi	a1,s0,-456
    80005c6a:	4505                	li	a0,1
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	156080e7          	jalr	342(ra) # 80002dc2 <argaddr>
    80005c74:	0c054263          	bltz	a0,80005d38 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c78:	10000613          	li	a2,256
    80005c7c:	4581                	li	a1,0
    80005c7e:	e4040513          	addi	a0,s0,-448
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	04a080e7          	jalr	74(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c8a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c8e:	89a6                	mv	s3,s1
    80005c90:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c92:	02000a13          	li	s4,32
    80005c96:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c9a:	00391513          	slli	a0,s2,0x3
    80005c9e:	e3040593          	addi	a1,s0,-464
    80005ca2:	e3843783          	ld	a5,-456(s0)
    80005ca6:	953e                	add	a0,a0,a5
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	05e080e7          	jalr	94(ra) # 80002d06 <fetchaddr>
    80005cb0:	02054a63          	bltz	a0,80005ce4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cb4:	e3043783          	ld	a5,-464(s0)
    80005cb8:	c3b9                	beqz	a5,80005cfe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	e26080e7          	jalr	-474(ra) # 80000ae0 <kalloc>
    80005cc2:	85aa                	mv	a1,a0
    80005cc4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cc8:	cd11                	beqz	a0,80005ce4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cca:	6605                	lui	a2,0x1
    80005ccc:	e3043503          	ld	a0,-464(s0)
    80005cd0:	ffffd097          	auipc	ra,0xffffd
    80005cd4:	088080e7          	jalr	136(ra) # 80002d58 <fetchstr>
    80005cd8:	00054663          	bltz	a0,80005ce4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cdc:	0905                	addi	s2,s2,1
    80005cde:	09a1                	addi	s3,s3,8
    80005ce0:	fb491be3          	bne	s2,s4,80005c96 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce4:	f4040913          	addi	s2,s0,-192
    80005ce8:	6088                	ld	a0,0(s1)
    80005cea:	c531                	beqz	a0,80005d36 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	cf6080e7          	jalr	-778(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf4:	04a1                	addi	s1,s1,8
    80005cf6:	ff2499e3          	bne	s1,s2,80005ce8 <sys_exec+0xac>
  return -1;
    80005cfa:	597d                	li	s2,-1
    80005cfc:	a835                	j	80005d38 <sys_exec+0xfc>
      argv[i] = 0;
    80005cfe:	0a8e                	slli	s5,s5,0x3
    80005d00:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005d04:	00878ab3          	add	s5,a5,s0
    80005d08:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d0c:	e4040593          	addi	a1,s0,-448
    80005d10:	f4040513          	addi	a0,s0,-192
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	172080e7          	jalr	370(ra) # 80004e86 <exec>
    80005d1c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1e:	f4040993          	addi	s3,s0,-192
    80005d22:	6088                	ld	a0,0(s1)
    80005d24:	c911                	beqz	a0,80005d38 <sys_exec+0xfc>
    kfree(argv[i]);
    80005d26:	ffffb097          	auipc	ra,0xffffb
    80005d2a:	cbc080e7          	jalr	-836(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d2e:	04a1                	addi	s1,s1,8
    80005d30:	ff3499e3          	bne	s1,s3,80005d22 <sys_exec+0xe6>
    80005d34:	a011                	j	80005d38 <sys_exec+0xfc>
  return -1;
    80005d36:	597d                	li	s2,-1
}
    80005d38:	854a                	mv	a0,s2
    80005d3a:	60be                	ld	ra,456(sp)
    80005d3c:	641e                	ld	s0,448(sp)
    80005d3e:	74fa                	ld	s1,440(sp)
    80005d40:	795a                	ld	s2,432(sp)
    80005d42:	79ba                	ld	s3,424(sp)
    80005d44:	7a1a                	ld	s4,416(sp)
    80005d46:	6afa                	ld	s5,408(sp)
    80005d48:	6179                	addi	sp,sp,464
    80005d4a:	8082                	ret

0000000080005d4c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d4c:	7139                	addi	sp,sp,-64
    80005d4e:	fc06                	sd	ra,56(sp)
    80005d50:	f822                	sd	s0,48(sp)
    80005d52:	f426                	sd	s1,40(sp)
    80005d54:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d56:	ffffc097          	auipc	ra,0xffffc
    80005d5a:	cea080e7          	jalr	-790(ra) # 80001a40 <myproc>
    80005d5e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d60:	fd840593          	addi	a1,s0,-40
    80005d64:	4501                	li	a0,0
    80005d66:	ffffd097          	auipc	ra,0xffffd
    80005d6a:	05c080e7          	jalr	92(ra) # 80002dc2 <argaddr>
    return -1;
    80005d6e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d70:	0e054063          	bltz	a0,80005e50 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d74:	fc840593          	addi	a1,s0,-56
    80005d78:	fd040513          	addi	a0,s0,-48
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	de6080e7          	jalr	-538(ra) # 80004b62 <pipealloc>
    return -1;
    80005d84:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d86:	0c054563          	bltz	a0,80005e50 <sys_pipe+0x104>
  fd0 = -1;
    80005d8a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d8e:	fd043503          	ld	a0,-48(s0)
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	504080e7          	jalr	1284(ra) # 80005296 <fdalloc>
    80005d9a:	fca42223          	sw	a0,-60(s0)
    80005d9e:	08054c63          	bltz	a0,80005e36 <sys_pipe+0xea>
    80005da2:	fc843503          	ld	a0,-56(s0)
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	4f0080e7          	jalr	1264(ra) # 80005296 <fdalloc>
    80005dae:	fca42023          	sw	a0,-64(s0)
    80005db2:	06054963          	bltz	a0,80005e24 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005db6:	4691                	li	a3,4
    80005db8:	fc440613          	addi	a2,s0,-60
    80005dbc:	fd843583          	ld	a1,-40(s0)
    80005dc0:	68a8                	ld	a0,80(s1)
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	898080e7          	jalr	-1896(ra) # 8000165a <copyout>
    80005dca:	02054063          	bltz	a0,80005dea <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dce:	4691                	li	a3,4
    80005dd0:	fc040613          	addi	a2,s0,-64
    80005dd4:	fd843583          	ld	a1,-40(s0)
    80005dd8:	0591                	addi	a1,a1,4
    80005dda:	68a8                	ld	a0,80(s1)
    80005ddc:	ffffc097          	auipc	ra,0xffffc
    80005de0:	87e080e7          	jalr	-1922(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005de4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005de6:	06055563          	bgez	a0,80005e50 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dea:	fc442783          	lw	a5,-60(s0)
    80005dee:	07e9                	addi	a5,a5,26
    80005df0:	078e                	slli	a5,a5,0x3
    80005df2:	97a6                	add	a5,a5,s1
    80005df4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005df8:	fc042783          	lw	a5,-64(s0)
    80005dfc:	07e9                	addi	a5,a5,26
    80005dfe:	078e                	slli	a5,a5,0x3
    80005e00:	00f48533          	add	a0,s1,a5
    80005e04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e08:	fd043503          	ld	a0,-48(s0)
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	a26080e7          	jalr	-1498(ra) # 80004832 <fileclose>
    fileclose(wf);
    80005e14:	fc843503          	ld	a0,-56(s0)
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	a1a080e7          	jalr	-1510(ra) # 80004832 <fileclose>
    return -1;
    80005e20:	57fd                	li	a5,-1
    80005e22:	a03d                	j	80005e50 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e24:	fc442783          	lw	a5,-60(s0)
    80005e28:	0007c763          	bltz	a5,80005e36 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e2c:	07e9                	addi	a5,a5,26
    80005e2e:	078e                	slli	a5,a5,0x3
    80005e30:	97a6                	add	a5,a5,s1
    80005e32:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005e36:	fd043503          	ld	a0,-48(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	9f8080e7          	jalr	-1544(ra) # 80004832 <fileclose>
    fileclose(wf);
    80005e42:	fc843503          	ld	a0,-56(s0)
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	9ec080e7          	jalr	-1556(ra) # 80004832 <fileclose>
    return -1;
    80005e4e:	57fd                	li	a5,-1
}
    80005e50:	853e                	mv	a0,a5
    80005e52:	70e2                	ld	ra,56(sp)
    80005e54:	7442                	ld	s0,48(sp)
    80005e56:	74a2                	ld	s1,40(sp)
    80005e58:	6121                	addi	sp,sp,64
    80005e5a:	8082                	ret
    80005e5c:	0000                	unimp
	...

0000000080005e60 <kernelvec>:
    80005e60:	7111                	addi	sp,sp,-256
    80005e62:	e006                	sd	ra,0(sp)
    80005e64:	e40a                	sd	sp,8(sp)
    80005e66:	e80e                	sd	gp,16(sp)
    80005e68:	ec12                	sd	tp,24(sp)
    80005e6a:	f016                	sd	t0,32(sp)
    80005e6c:	f41a                	sd	t1,40(sp)
    80005e6e:	f81e                	sd	t2,48(sp)
    80005e70:	fc22                	sd	s0,56(sp)
    80005e72:	e0a6                	sd	s1,64(sp)
    80005e74:	e4aa                	sd	a0,72(sp)
    80005e76:	e8ae                	sd	a1,80(sp)
    80005e78:	ecb2                	sd	a2,88(sp)
    80005e7a:	f0b6                	sd	a3,96(sp)
    80005e7c:	f4ba                	sd	a4,104(sp)
    80005e7e:	f8be                	sd	a5,112(sp)
    80005e80:	fcc2                	sd	a6,120(sp)
    80005e82:	e146                	sd	a7,128(sp)
    80005e84:	e54a                	sd	s2,136(sp)
    80005e86:	e94e                	sd	s3,144(sp)
    80005e88:	ed52                	sd	s4,152(sp)
    80005e8a:	f156                	sd	s5,160(sp)
    80005e8c:	f55a                	sd	s6,168(sp)
    80005e8e:	f95e                	sd	s7,176(sp)
    80005e90:	fd62                	sd	s8,184(sp)
    80005e92:	e1e6                	sd	s9,192(sp)
    80005e94:	e5ea                	sd	s10,200(sp)
    80005e96:	e9ee                	sd	s11,208(sp)
    80005e98:	edf2                	sd	t3,216(sp)
    80005e9a:	f1f6                	sd	t4,224(sp)
    80005e9c:	f5fa                	sd	t5,232(sp)
    80005e9e:	f9fe                	sd	t6,240(sp)
    80005ea0:	d33fc0ef          	jal	ra,80002bd2 <kerneltrap>
    80005ea4:	6082                	ld	ra,0(sp)
    80005ea6:	6122                	ld	sp,8(sp)
    80005ea8:	61c2                	ld	gp,16(sp)
    80005eaa:	7282                	ld	t0,32(sp)
    80005eac:	7322                	ld	t1,40(sp)
    80005eae:	73c2                	ld	t2,48(sp)
    80005eb0:	7462                	ld	s0,56(sp)
    80005eb2:	6486                	ld	s1,64(sp)
    80005eb4:	6526                	ld	a0,72(sp)
    80005eb6:	65c6                	ld	a1,80(sp)
    80005eb8:	6666                	ld	a2,88(sp)
    80005eba:	7686                	ld	a3,96(sp)
    80005ebc:	7726                	ld	a4,104(sp)
    80005ebe:	77c6                	ld	a5,112(sp)
    80005ec0:	7866                	ld	a6,120(sp)
    80005ec2:	688a                	ld	a7,128(sp)
    80005ec4:	692a                	ld	s2,136(sp)
    80005ec6:	69ca                	ld	s3,144(sp)
    80005ec8:	6a6a                	ld	s4,152(sp)
    80005eca:	7a8a                	ld	s5,160(sp)
    80005ecc:	7b2a                	ld	s6,168(sp)
    80005ece:	7bca                	ld	s7,176(sp)
    80005ed0:	7c6a                	ld	s8,184(sp)
    80005ed2:	6c8e                	ld	s9,192(sp)
    80005ed4:	6d2e                	ld	s10,200(sp)
    80005ed6:	6dce                	ld	s11,208(sp)
    80005ed8:	6e6e                	ld	t3,216(sp)
    80005eda:	7e8e                	ld	t4,224(sp)
    80005edc:	7f2e                	ld	t5,232(sp)
    80005ede:	7fce                	ld	t6,240(sp)
    80005ee0:	6111                	addi	sp,sp,256
    80005ee2:	10200073          	sret
    80005ee6:	00000013          	nop
    80005eea:	00000013          	nop
    80005eee:	0001                	nop

0000000080005ef0 <timervec>:
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	e10c                	sd	a1,0(a0)
    80005ef6:	e510                	sd	a2,8(a0)
    80005ef8:	e914                	sd	a3,16(a0)
    80005efa:	6d0c                	ld	a1,24(a0)
    80005efc:	7110                	ld	a2,32(a0)
    80005efe:	6194                	ld	a3,0(a1)
    80005f00:	96b2                	add	a3,a3,a2
    80005f02:	e194                	sd	a3,0(a1)
    80005f04:	4589                	li	a1,2
    80005f06:	14459073          	csrw	sip,a1
    80005f0a:	6914                	ld	a3,16(a0)
    80005f0c:	6510                	ld	a2,8(a0)
    80005f0e:	610c                	ld	a1,0(a0)
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	30200073          	mret
	...

0000000080005f1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f1a:	1141                	addi	sp,sp,-16
    80005f1c:	e422                	sd	s0,8(sp)
    80005f1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f20:	0c0007b7          	lui	a5,0xc000
    80005f24:	4705                	li	a4,1
    80005f26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f28:	c3d8                	sw	a4,4(a5)
}
    80005f2a:	6422                	ld	s0,8(sp)
    80005f2c:	0141                	addi	sp,sp,16
    80005f2e:	8082                	ret

0000000080005f30 <plicinithart>:

void
plicinithart(void)
{
    80005f30:	1141                	addi	sp,sp,-16
    80005f32:	e406                	sd	ra,8(sp)
    80005f34:	e022                	sd	s0,0(sp)
    80005f36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	adc080e7          	jalr	-1316(ra) # 80001a14 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f40:	0085171b          	slliw	a4,a0,0x8
    80005f44:	0c0027b7          	lui	a5,0xc002
    80005f48:	97ba                	add	a5,a5,a4
    80005f4a:	40200713          	li	a4,1026
    80005f4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f52:	00d5151b          	slliw	a0,a0,0xd
    80005f56:	0c2017b7          	lui	a5,0xc201
    80005f5a:	97aa                	add	a5,a5,a0
    80005f5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret

0000000080005f68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f68:	1141                	addi	sp,sp,-16
    80005f6a:	e406                	sd	ra,8(sp)
    80005f6c:	e022                	sd	s0,0(sp)
    80005f6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f70:	ffffc097          	auipc	ra,0xffffc
    80005f74:	aa4080e7          	jalr	-1372(ra) # 80001a14 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f78:	00d5151b          	slliw	a0,a0,0xd
    80005f7c:	0c2017b7          	lui	a5,0xc201
    80005f80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f82:	43c8                	lw	a0,4(a5)
    80005f84:	60a2                	ld	ra,8(sp)
    80005f86:	6402                	ld	s0,0(sp)
    80005f88:	0141                	addi	sp,sp,16
    80005f8a:	8082                	ret

0000000080005f8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f8c:	1101                	addi	sp,sp,-32
    80005f8e:	ec06                	sd	ra,24(sp)
    80005f90:	e822                	sd	s0,16(sp)
    80005f92:	e426                	sd	s1,8(sp)
    80005f94:	1000                	addi	s0,sp,32
    80005f96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	a7c080e7          	jalr	-1412(ra) # 80001a14 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fa0:	00d5151b          	slliw	a0,a0,0xd
    80005fa4:	0c2017b7          	lui	a5,0xc201
    80005fa8:	97aa                	add	a5,a5,a0
    80005faa:	c3c4                	sw	s1,4(a5)
}
    80005fac:	60e2                	ld	ra,24(sp)
    80005fae:	6442                	ld	s0,16(sp)
    80005fb0:	64a2                	ld	s1,8(sp)
    80005fb2:	6105                	addi	sp,sp,32
    80005fb4:	8082                	ret

0000000080005fb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fb6:	1141                	addi	sp,sp,-16
    80005fb8:	e406                	sd	ra,8(sp)
    80005fba:	e022                	sd	s0,0(sp)
    80005fbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fbe:	479d                	li	a5,7
    80005fc0:	06a7c863          	blt	a5,a0,80006030 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005fc4:	0001d717          	auipc	a4,0x1d
    80005fc8:	03c70713          	addi	a4,a4,60 # 80023000 <disk>
    80005fcc:	972a                	add	a4,a4,a0
    80005fce:	6789                	lui	a5,0x2
    80005fd0:	97ba                	add	a5,a5,a4
    80005fd2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fd6:	e7ad                	bnez	a5,80006040 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fd8:	00451793          	slli	a5,a0,0x4
    80005fdc:	0001f717          	auipc	a4,0x1f
    80005fe0:	02470713          	addi	a4,a4,36 # 80025000 <disk+0x2000>
    80005fe4:	6314                	ld	a3,0(a4)
    80005fe6:	96be                	add	a3,a3,a5
    80005fe8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fec:	6314                	ld	a3,0(a4)
    80005fee:	96be                	add	a3,a3,a5
    80005ff0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ff4:	6314                	ld	a3,0(a4)
    80005ff6:	96be                	add	a3,a3,a5
    80005ff8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005ffc:	6318                	ld	a4,0(a4)
    80005ffe:	97ba                	add	a5,a5,a4
    80006000:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006004:	0001d717          	auipc	a4,0x1d
    80006008:	ffc70713          	addi	a4,a4,-4 # 80023000 <disk>
    8000600c:	972a                	add	a4,a4,a0
    8000600e:	6789                	lui	a5,0x2
    80006010:	97ba                	add	a5,a5,a4
    80006012:	4705                	li	a4,1
    80006014:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006018:	0001f517          	auipc	a0,0x1f
    8000601c:	00050513          	mv	a0,a0
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	36c080e7          	jalr	876(ra) # 8000238c <wakeup>
}
    80006028:	60a2                	ld	ra,8(sp)
    8000602a:	6402                	ld	s0,0(sp)
    8000602c:	0141                	addi	sp,sp,16
    8000602e:	8082                	ret
    panic("free_desc 1");
    80006030:	00003517          	auipc	a0,0x3
    80006034:	83850513          	addi	a0,a0,-1992 # 80008868 <syscalls+0x338>
    80006038:	ffffa097          	auipc	ra,0xffffa
    8000603c:	502080e7          	jalr	1282(ra) # 8000053a <panic>
    panic("free_desc 2");
    80006040:	00003517          	auipc	a0,0x3
    80006044:	83850513          	addi	a0,a0,-1992 # 80008878 <syscalls+0x348>
    80006048:	ffffa097          	auipc	ra,0xffffa
    8000604c:	4f2080e7          	jalr	1266(ra) # 8000053a <panic>

0000000080006050 <virtio_disk_init>:
{
    80006050:	1101                	addi	sp,sp,-32
    80006052:	ec06                	sd	ra,24(sp)
    80006054:	e822                	sd	s0,16(sp)
    80006056:	e426                	sd	s1,8(sp)
    80006058:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000605a:	00003597          	auipc	a1,0x3
    8000605e:	82e58593          	addi	a1,a1,-2002 # 80008888 <syscalls+0x358>
    80006062:	0001f517          	auipc	a0,0x1f
    80006066:	0c650513          	addi	a0,a0,198 # 80025128 <disk+0x2128>
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	ad6080e7          	jalr	-1322(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006072:	100017b7          	lui	a5,0x10001
    80006076:	4398                	lw	a4,0(a5)
    80006078:	2701                	sext.w	a4,a4
    8000607a:	747277b7          	lui	a5,0x74727
    8000607e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006082:	0ef71063          	bne	a4,a5,80006162 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006086:	100017b7          	lui	a5,0x10001
    8000608a:	43dc                	lw	a5,4(a5)
    8000608c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000608e:	4705                	li	a4,1
    80006090:	0ce79963          	bne	a5,a4,80006162 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006094:	100017b7          	lui	a5,0x10001
    80006098:	479c                	lw	a5,8(a5)
    8000609a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000609c:	4709                	li	a4,2
    8000609e:	0ce79263          	bne	a5,a4,80006162 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060a2:	100017b7          	lui	a5,0x10001
    800060a6:	47d8                	lw	a4,12(a5)
    800060a8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060aa:	554d47b7          	lui	a5,0x554d4
    800060ae:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060b2:	0af71863          	bne	a4,a5,80006162 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	100017b7          	lui	a5,0x10001
    800060ba:	4705                	li	a4,1
    800060bc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060be:	470d                	li	a4,3
    800060c0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060c2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060c4:	c7ffe6b7          	lui	a3,0xc7ffe
    800060c8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060cc:	8f75                	and	a4,a4,a3
    800060ce:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d0:	472d                	li	a4,11
    800060d2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d4:	473d                	li	a4,15
    800060d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060d8:	6705                	lui	a4,0x1
    800060da:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060dc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060e0:	5bdc                	lw	a5,52(a5)
    800060e2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060e4:	c7d9                	beqz	a5,80006172 <virtio_disk_init+0x122>
  if(max < NUM)
    800060e6:	471d                	li	a4,7
    800060e8:	08f77d63          	bgeu	a4,a5,80006182 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060ec:	100014b7          	lui	s1,0x10001
    800060f0:	47a1                	li	a5,8
    800060f2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060f4:	6609                	lui	a2,0x2
    800060f6:	4581                	li	a1,0
    800060f8:	0001d517          	auipc	a0,0x1d
    800060fc:	f0850513          	addi	a0,a0,-248 # 80023000 <disk>
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	bcc080e7          	jalr	-1076(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006108:	0001d717          	auipc	a4,0x1d
    8000610c:	ef870713          	addi	a4,a4,-264 # 80023000 <disk>
    80006110:	00c75793          	srli	a5,a4,0xc
    80006114:	2781                	sext.w	a5,a5
    80006116:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006118:	0001f797          	auipc	a5,0x1f
    8000611c:	ee878793          	addi	a5,a5,-280 # 80025000 <disk+0x2000>
    80006120:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006122:	0001d717          	auipc	a4,0x1d
    80006126:	f5e70713          	addi	a4,a4,-162 # 80023080 <disk+0x80>
    8000612a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000612c:	0001e717          	auipc	a4,0x1e
    80006130:	ed470713          	addi	a4,a4,-300 # 80024000 <disk+0x1000>
    80006134:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006136:	4705                	li	a4,1
    80006138:	00e78c23          	sb	a4,24(a5)
    8000613c:	00e78ca3          	sb	a4,25(a5)
    80006140:	00e78d23          	sb	a4,26(a5)
    80006144:	00e78da3          	sb	a4,27(a5)
    80006148:	00e78e23          	sb	a4,28(a5)
    8000614c:	00e78ea3          	sb	a4,29(a5)
    80006150:	00e78f23          	sb	a4,30(a5)
    80006154:	00e78fa3          	sb	a4,31(a5)
}
    80006158:	60e2                	ld	ra,24(sp)
    8000615a:	6442                	ld	s0,16(sp)
    8000615c:	64a2                	ld	s1,8(sp)
    8000615e:	6105                	addi	sp,sp,32
    80006160:	8082                	ret
    panic("could not find virtio disk");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	73650513          	addi	a0,a0,1846 # 80008898 <syscalls+0x368>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3d0080e7          	jalr	976(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006172:	00002517          	auipc	a0,0x2
    80006176:	74650513          	addi	a0,a0,1862 # 800088b8 <syscalls+0x388>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3c0080e7          	jalr	960(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006182:	00002517          	auipc	a0,0x2
    80006186:	75650513          	addi	a0,a0,1878 # 800088d8 <syscalls+0x3a8>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3b0080e7          	jalr	944(ra) # 8000053a <panic>

0000000080006192 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006192:	7119                	addi	sp,sp,-128
    80006194:	fc86                	sd	ra,120(sp)
    80006196:	f8a2                	sd	s0,112(sp)
    80006198:	f4a6                	sd	s1,104(sp)
    8000619a:	f0ca                	sd	s2,96(sp)
    8000619c:	ecce                	sd	s3,88(sp)
    8000619e:	e8d2                	sd	s4,80(sp)
    800061a0:	e4d6                	sd	s5,72(sp)
    800061a2:	e0da                	sd	s6,64(sp)
    800061a4:	fc5e                	sd	s7,56(sp)
    800061a6:	f862                	sd	s8,48(sp)
    800061a8:	f466                	sd	s9,40(sp)
    800061aa:	f06a                	sd	s10,32(sp)
    800061ac:	ec6e                	sd	s11,24(sp)
    800061ae:	0100                	addi	s0,sp,128
    800061b0:	8aaa                	mv	s5,a0
    800061b2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061b4:	00c52c83          	lw	s9,12(a0)
    800061b8:	001c9c9b          	slliw	s9,s9,0x1
    800061bc:	1c82                	slli	s9,s9,0x20
    800061be:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061c2:	0001f517          	auipc	a0,0x1f
    800061c6:	f6650513          	addi	a0,a0,-154 # 80025128 <disk+0x2128>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	a06080e7          	jalr	-1530(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    800061d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d6:	0001dc17          	auipc	s8,0x1d
    800061da:	e2ac0c13          	addi	s8,s8,-470 # 80023000 <disk>
    800061de:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061e0:	4b0d                	li	s6,3
    800061e2:	a0ad                	j	8000624c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061e4:	00fc0733          	add	a4,s8,a5
    800061e8:	975e                	add	a4,a4,s7
    800061ea:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061ee:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061f0:	0207c563          	bltz	a5,8000621a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061f4:	2905                	addiw	s2,s2,1
    800061f6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800061f8:	19690c63          	beq	s2,s6,80006390 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800061fc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061fe:	0001f717          	auipc	a4,0x1f
    80006202:	e1a70713          	addi	a4,a4,-486 # 80025018 <disk+0x2018>
    80006206:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006208:	00074683          	lbu	a3,0(a4)
    8000620c:	fee1                	bnez	a3,800061e4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000620e:	2785                	addiw	a5,a5,1
    80006210:	0705                	addi	a4,a4,1
    80006212:	fe979be3          	bne	a5,s1,80006208 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006216:	57fd                	li	a5,-1
    80006218:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000621a:	01205d63          	blez	s2,80006234 <virtio_disk_rw+0xa2>
    8000621e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006220:	000a2503          	lw	a0,0(s4)
    80006224:	00000097          	auipc	ra,0x0
    80006228:	d92080e7          	jalr	-622(ra) # 80005fb6 <free_desc>
      for(int j = 0; j < i; j++)
    8000622c:	2d85                	addiw	s11,s11,1
    8000622e:	0a11                	addi	s4,s4,4
    80006230:	ff2d98e3          	bne	s11,s2,80006220 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006234:	0001f597          	auipc	a1,0x1f
    80006238:	ef458593          	addi	a1,a1,-268 # 80025128 <disk+0x2128>
    8000623c:	0001f517          	auipc	a0,0x1f
    80006240:	ddc50513          	addi	a0,a0,-548 # 80025018 <disk+0x2018>
    80006244:	ffffc097          	auipc	ra,0xffffc
    80006248:	fbc080e7          	jalr	-68(ra) # 80002200 <sleep>
  for(int i = 0; i < 3; i++){
    8000624c:	f8040a13          	addi	s4,s0,-128
{
    80006250:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006252:	894e                	mv	s2,s3
    80006254:	b765                	j	800061fc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006256:	0001f697          	auipc	a3,0x1f
    8000625a:	daa6b683          	ld	a3,-598(a3) # 80025000 <disk+0x2000>
    8000625e:	96ba                	add	a3,a3,a4
    80006260:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006264:	0001d817          	auipc	a6,0x1d
    80006268:	d9c80813          	addi	a6,a6,-612 # 80023000 <disk>
    8000626c:	0001f697          	auipc	a3,0x1f
    80006270:	d9468693          	addi	a3,a3,-620 # 80025000 <disk+0x2000>
    80006274:	6290                	ld	a2,0(a3)
    80006276:	963a                	add	a2,a2,a4
    80006278:	00c65583          	lhu	a1,12(a2)
    8000627c:	0015e593          	ori	a1,a1,1
    80006280:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006284:	f8842603          	lw	a2,-120(s0)
    80006288:	628c                	ld	a1,0(a3)
    8000628a:	972e                	add	a4,a4,a1
    8000628c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006290:	20050593          	addi	a1,a0,512
    80006294:	0592                	slli	a1,a1,0x4
    80006296:	95c2                	add	a1,a1,a6
    80006298:	577d                	li	a4,-1
    8000629a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000629e:	00461713          	slli	a4,a2,0x4
    800062a2:	6290                	ld	a2,0(a3)
    800062a4:	963a                	add	a2,a2,a4
    800062a6:	03078793          	addi	a5,a5,48
    800062aa:	97c2                	add	a5,a5,a6
    800062ac:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800062ae:	629c                	ld	a5,0(a3)
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	4605                	li	a2,1
    800062b4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b6:	629c                	ld	a5,0(a3)
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	4809                	li	a6,2
    800062bc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062c0:	629c                	ld	a5,0(a3)
    800062c2:	97ba                	add	a5,a5,a4
    800062c4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062c8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062cc:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062d0:	6698                	ld	a4,8(a3)
    800062d2:	00275783          	lhu	a5,2(a4)
    800062d6:	8b9d                	andi	a5,a5,7
    800062d8:	0786                	slli	a5,a5,0x1
    800062da:	973e                	add	a4,a4,a5
    800062dc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800062e0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062e4:	6698                	ld	a4,8(a3)
    800062e6:	00275783          	lhu	a5,2(a4)
    800062ea:	2785                	addiw	a5,a5,1
    800062ec:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062f0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062f4:	100017b7          	lui	a5,0x10001
    800062f8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062fc:	004aa783          	lw	a5,4(s5)
    80006300:	02c79163          	bne	a5,a2,80006322 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006304:	0001f917          	auipc	s2,0x1f
    80006308:	e2490913          	addi	s2,s2,-476 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000630c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000630e:	85ca                	mv	a1,s2
    80006310:	8556                	mv	a0,s5
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	eee080e7          	jalr	-274(ra) # 80002200 <sleep>
  while(b->disk == 1) {
    8000631a:	004aa783          	lw	a5,4(s5)
    8000631e:	fe9788e3          	beq	a5,s1,8000630e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006322:	f8042903          	lw	s2,-128(s0)
    80006326:	20090713          	addi	a4,s2,512
    8000632a:	0712                	slli	a4,a4,0x4
    8000632c:	0001d797          	auipc	a5,0x1d
    80006330:	cd478793          	addi	a5,a5,-812 # 80023000 <disk>
    80006334:	97ba                	add	a5,a5,a4
    80006336:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000633a:	0001f997          	auipc	s3,0x1f
    8000633e:	cc698993          	addi	s3,s3,-826 # 80025000 <disk+0x2000>
    80006342:	00491713          	slli	a4,s2,0x4
    80006346:	0009b783          	ld	a5,0(s3)
    8000634a:	97ba                	add	a5,a5,a4
    8000634c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006350:	854a                	mv	a0,s2
    80006352:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006356:	00000097          	auipc	ra,0x0
    8000635a:	c60080e7          	jalr	-928(ra) # 80005fb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000635e:	8885                	andi	s1,s1,1
    80006360:	f0ed                	bnez	s1,80006342 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006362:	0001f517          	auipc	a0,0x1f
    80006366:	dc650513          	addi	a0,a0,-570 # 80025128 <disk+0x2128>
    8000636a:	ffffb097          	auipc	ra,0xffffb
    8000636e:	91a080e7          	jalr	-1766(ra) # 80000c84 <release>
}
    80006372:	70e6                	ld	ra,120(sp)
    80006374:	7446                	ld	s0,112(sp)
    80006376:	74a6                	ld	s1,104(sp)
    80006378:	7906                	ld	s2,96(sp)
    8000637a:	69e6                	ld	s3,88(sp)
    8000637c:	6a46                	ld	s4,80(sp)
    8000637e:	6aa6                	ld	s5,72(sp)
    80006380:	6b06                	ld	s6,64(sp)
    80006382:	7be2                	ld	s7,56(sp)
    80006384:	7c42                	ld	s8,48(sp)
    80006386:	7ca2                	ld	s9,40(sp)
    80006388:	7d02                	ld	s10,32(sp)
    8000638a:	6de2                	ld	s11,24(sp)
    8000638c:	6109                	addi	sp,sp,128
    8000638e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006390:	f8042503          	lw	a0,-128(s0)
    80006394:	20050793          	addi	a5,a0,512
    80006398:	0792                	slli	a5,a5,0x4
  if(write)
    8000639a:	0001d817          	auipc	a6,0x1d
    8000639e:	c6680813          	addi	a6,a6,-922 # 80023000 <disk>
    800063a2:	00f80733          	add	a4,a6,a5
    800063a6:	01a036b3          	snez	a3,s10
    800063aa:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800063ae:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063b2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063b6:	7679                	lui	a2,0xffffe
    800063b8:	963e                	add	a2,a2,a5
    800063ba:	0001f697          	auipc	a3,0x1f
    800063be:	c4668693          	addi	a3,a3,-954 # 80025000 <disk+0x2000>
    800063c2:	6298                	ld	a4,0(a3)
    800063c4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c6:	0a878593          	addi	a1,a5,168
    800063ca:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063cc:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063ce:	6298                	ld	a4,0(a3)
    800063d0:	9732                	add	a4,a4,a2
    800063d2:	45c1                	li	a1,16
    800063d4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063d6:	6298                	ld	a4,0(a3)
    800063d8:	9732                	add	a4,a4,a2
    800063da:	4585                	li	a1,1
    800063dc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063e0:	f8442703          	lw	a4,-124(s0)
    800063e4:	628c                	ld	a1,0(a3)
    800063e6:	962e                	add	a2,a2,a1
    800063e8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063ec:	0712                	slli	a4,a4,0x4
    800063ee:	6290                	ld	a2,0(a3)
    800063f0:	963a                	add	a2,a2,a4
    800063f2:	058a8593          	addi	a1,s5,88
    800063f6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800063f8:	6294                	ld	a3,0(a3)
    800063fa:	96ba                	add	a3,a3,a4
    800063fc:	40000613          	li	a2,1024
    80006400:	c690                	sw	a2,8(a3)
  if(write)
    80006402:	e40d1ae3          	bnez	s10,80006256 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006406:	0001f697          	auipc	a3,0x1f
    8000640a:	bfa6b683          	ld	a3,-1030(a3) # 80025000 <disk+0x2000>
    8000640e:	96ba                	add	a3,a3,a4
    80006410:	4609                	li	a2,2
    80006412:	00c69623          	sh	a2,12(a3)
    80006416:	b5b9                	j	80006264 <virtio_disk_rw+0xd2>

0000000080006418 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006418:	1101                	addi	sp,sp,-32
    8000641a:	ec06                	sd	ra,24(sp)
    8000641c:	e822                	sd	s0,16(sp)
    8000641e:	e426                	sd	s1,8(sp)
    80006420:	e04a                	sd	s2,0(sp)
    80006422:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006424:	0001f517          	auipc	a0,0x1f
    80006428:	d0450513          	addi	a0,a0,-764 # 80025128 <disk+0x2128>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	7a4080e7          	jalr	1956(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006434:	10001737          	lui	a4,0x10001
    80006438:	533c                	lw	a5,96(a4)
    8000643a:	8b8d                	andi	a5,a5,3
    8000643c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000643e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006442:	0001f797          	auipc	a5,0x1f
    80006446:	bbe78793          	addi	a5,a5,-1090 # 80025000 <disk+0x2000>
    8000644a:	6b94                	ld	a3,16(a5)
    8000644c:	0207d703          	lhu	a4,32(a5)
    80006450:	0026d783          	lhu	a5,2(a3)
    80006454:	06f70163          	beq	a4,a5,800064b6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006458:	0001d917          	auipc	s2,0x1d
    8000645c:	ba890913          	addi	s2,s2,-1112 # 80023000 <disk>
    80006460:	0001f497          	auipc	s1,0x1f
    80006464:	ba048493          	addi	s1,s1,-1120 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006468:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000646c:	6898                	ld	a4,16(s1)
    8000646e:	0204d783          	lhu	a5,32(s1)
    80006472:	8b9d                	andi	a5,a5,7
    80006474:	078e                	slli	a5,a5,0x3
    80006476:	97ba                	add	a5,a5,a4
    80006478:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000647a:	20078713          	addi	a4,a5,512
    8000647e:	0712                	slli	a4,a4,0x4
    80006480:	974a                	add	a4,a4,s2
    80006482:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006486:	e731                	bnez	a4,800064d2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006488:	20078793          	addi	a5,a5,512
    8000648c:	0792                	slli	a5,a5,0x4
    8000648e:	97ca                	add	a5,a5,s2
    80006490:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006492:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006496:	ffffc097          	auipc	ra,0xffffc
    8000649a:	ef6080e7          	jalr	-266(ra) # 8000238c <wakeup>

    disk.used_idx += 1;
    8000649e:	0204d783          	lhu	a5,32(s1)
    800064a2:	2785                	addiw	a5,a5,1
    800064a4:	17c2                	slli	a5,a5,0x30
    800064a6:	93c1                	srli	a5,a5,0x30
    800064a8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064ac:	6898                	ld	a4,16(s1)
    800064ae:	00275703          	lhu	a4,2(a4)
    800064b2:	faf71be3          	bne	a4,a5,80006468 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064b6:	0001f517          	auipc	a0,0x1f
    800064ba:	c7250513          	addi	a0,a0,-910 # 80025128 <disk+0x2128>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	7c6080e7          	jalr	1990(ra) # 80000c84 <release>
}
    800064c6:	60e2                	ld	ra,24(sp)
    800064c8:	6442                	ld	s0,16(sp)
    800064ca:	64a2                	ld	s1,8(sp)
    800064cc:	6902                	ld	s2,0(sp)
    800064ce:	6105                	addi	sp,sp,32
    800064d0:	8082                	ret
      panic("virtio_disk_intr status");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	42650513          	addi	a0,a0,1062 # 800088f8 <syscalls+0x3c8>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	060080e7          	jalr	96(ra) # 8000053a <panic>
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
