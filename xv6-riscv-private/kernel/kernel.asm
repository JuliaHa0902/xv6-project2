
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	bfe78793          	addi	a5,a5,-1026 # 80005c60 <timervec>
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
    8000012e:	336080e7          	jalr	822(ra) # 80002460 <either_copyin>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e96080e7          	jalr	-362(ra) # 80002066 <sleep>
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
    80000210:	1fe080e7          	jalr	510(ra) # 8000240a <either_copyout>
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
    800002f0:	1ca080e7          	jalr	458(ra) # 800024b6 <procdump>
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
    80000444:	db2080e7          	jalr	-590(ra) # 800021f2 <wakeup>
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
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
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
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
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
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
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
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
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
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
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
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
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
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
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
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
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
    80000892:	964080e7          	jalr	-1692(ra) # 800021f2 <wakeup>
    
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
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	74c080e7          	jalr	1868(ra) # 80002066 <sleep>
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
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
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
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
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
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
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
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
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
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
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
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
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
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
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
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
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
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
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
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
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
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	838080e7          	jalr	-1992(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	de0080e7          	jalr	-544(ra) # 80005ca0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fec080e7          	jalr	-20(ra) # 80001eb4 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
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
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	798080e7          	jalr	1944(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	7b8080e7          	jalr	1976(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d4a080e7          	jalr	-694(ra) # 80005c8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d58080e7          	jalr	-680(ra) # 80005ca0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f1c080e7          	jalr	-228(ra) # 80002e6c <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	5aa080e7          	jalr	1450(ra) # 80003502 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	55c080e7          	jalr	1372(ra) # 800044bc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e58080e7          	jalr	-424(ra) # 80005dc0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d0a080e7          	jalr	-758(ra) # 80001c7a <userinit>
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
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
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
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
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
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
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
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
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
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
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
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
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
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
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
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
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
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
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

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	c7ca0a13          	addi	s4,s4,-900 # 800174d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	17848493          	addi	s1,s1,376
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016997          	auipc	s3,0x16
    80001924:	bb098993          	addi	s3,s3,-1104 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	17848493          	addi	s1,s1,376
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	eba7a783          	lw	a5,-326(a5) # 800088a0 <first.2>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	d18080e7          	jalr	-744(ra) # 80002708 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ea07a023          	sw	zero,-352(a5) # 800088a0 <first.2>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	a78080e7          	jalr	-1416(ra) # 80003482 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e7278793          	addi	a5,a5,-398 # 800088a4 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00016917          	auipc	s2,0x16
    80001bb8:	91c90913          	addi	s2,s2,-1764 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	17848493          	addi	s1,s1,376
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a8b9                	j	80001c3c <allocproc+0x9c>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  p->in_queue = HIGH;
    80001bee:	1604a823          	sw	zero,368(s1)
  p->hticks = 0;
    80001bf2:	1604a423          	sw	zero,360(s1)
  p->lticks = 0;
    80001bf6:	1604a623          	sw	zero,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	ee6080e7          	jalr	-282(ra) # 80000ae0 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	eca8                	sd	a0,88(s1)
    80001c06:	c131                	beqz	a0,80001c4a <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e50080e7          	jalr	-432(ra) # 80001a5a <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c16:	c531                	beqz	a0,80001c62 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06048513          	addi	a0,s1,96
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0aa080e7          	jalr	170(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	da478793          	addi	a5,a5,-604 # 800019ce <forkret>
    80001c32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	60bc                	ld	a5,64(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f4bc                	sd	a5,104(s1)
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    freeproc(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	efc080e7          	jalr	-260(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	02e080e7          	jalr	46(ra) # 80000c84 <release>
    return 0;
    80001c5e:	84ca                	mv	s1,s2
    80001c60:	bff1                	j	80001c3c <allocproc+0x9c>
    freeproc(p);
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	ee4080e7          	jalr	-284(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	016080e7          	jalr	22(ra) # 80000c84 <release>
    return 0;
    80001c76:	84ca                	mv	s1,s2
    80001c78:	b7d1                	j	80001c3c <allocproc+0x9c>

0000000080001c7a <userinit>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	f1c080e7          	jalr	-228(ra) # 80001ba0 <allocproc>
    80001c8c:	84aa                	mv	s1,a0
  initproc = p;
    80001c8e:	00007797          	auipc	a5,0x7
    80001c92:	38a7bd23          	sd	a0,922(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c96:	03400613          	li	a2,52
    80001c9a:	00007597          	auipc	a1,0x7
    80001c9e:	c1658593          	addi	a1,a1,-1002 # 800088b0 <initcode>
    80001ca2:	6928                	ld	a0,80(a0)
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	6a8080e7          	jalr	1704(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cac:	6785                	lui	a5,0x1
    80001cae:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb0:	6cb8                	ld	a4,88(s1)
    80001cb2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb6:	6cb8                	ld	a4,88(s1)
    80001cb8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cba:	4641                	li	a2,16
    80001cbc:	00006597          	auipc	a1,0x6
    80001cc0:	54458593          	addi	a1,a1,1348 # 80008200 <digits+0x1c0>
    80001cc4:	15848513          	addi	a0,s1,344
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	14e080e7          	jalr	334(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cd0:	00006517          	auipc	a0,0x6
    80001cd4:	54050513          	addi	a0,a0,1344 # 80008210 <digits+0x1d0>
    80001cd8:	00002097          	auipc	ra,0x2
    80001cdc:	1e0080e7          	jalr	480(ra) # 80003eb8 <namei>
    80001ce0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce4:	478d                	li	a5,3
    80001ce6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	f9a080e7          	jalr	-102(ra) # 80000c84 <release>
}
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6105                	addi	sp,sp,32
    80001cfa:	8082                	ret

0000000080001cfc <growproc>:
{
    80001cfc:	1101                	addi	sp,sp,-32
    80001cfe:	ec06                	sd	ra,24(sp)
    80001d00:	e822                	sd	s0,16(sp)
    80001d02:	e426                	sd	s1,8(sp)
    80001d04:	e04a                	sd	s2,0(sp)
    80001d06:	1000                	addi	s0,sp,32
    80001d08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	c8c080e7          	jalr	-884(ra) # 80001996 <myproc>
    80001d12:	892a                	mv	s2,a0
  sz = p->sz;
    80001d14:	652c                	ld	a1,72(a0)
    80001d16:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d1a:	00904f63          	bgtz	s1,80001d38 <growproc+0x3c>
  } else if(n < 0){
    80001d1e:	0204cd63          	bltz	s1,80001d58 <growproc+0x5c>
  p->sz = sz;
    80001d22:	1782                	slli	a5,a5,0x20
    80001d24:	9381                	srli	a5,a5,0x20
    80001d26:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d38:	00f4863b          	addw	a2,s1,a5
    80001d3c:	1602                	slli	a2,a2,0x20
    80001d3e:	9201                	srli	a2,a2,0x20
    80001d40:	1582                	slli	a1,a1,0x20
    80001d42:	9181                	srli	a1,a1,0x20
    80001d44:	6928                	ld	a0,80(a0)
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	6c0080e7          	jalr	1728(ra) # 80001406 <uvmalloc>
    80001d4e:	0005079b          	sext.w	a5,a0
    80001d52:	fbe1                	bnez	a5,80001d22 <growproc+0x26>
      return -1;
    80001d54:	557d                	li	a0,-1
    80001d56:	bfd9                	j	80001d2c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d58:	00f4863b          	addw	a2,s1,a5
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	658080e7          	jalr	1624(ra) # 800013be <uvmdealloc>
    80001d6e:	0005079b          	sext.w	a5,a0
    80001d72:	bf45                	j	80001d22 <growproc+0x26>

0000000080001d74 <fork>:
{
    80001d74:	7139                	addi	sp,sp,-64
    80001d76:	fc06                	sd	ra,56(sp)
    80001d78:	f822                	sd	s0,48(sp)
    80001d7a:	f426                	sd	s1,40(sp)
    80001d7c:	f04a                	sd	s2,32(sp)
    80001d7e:	ec4e                	sd	s3,24(sp)
    80001d80:	e852                	sd	s4,16(sp)
    80001d82:	e456                	sd	s5,8(sp)
    80001d84:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	c10080e7          	jalr	-1008(ra) # 80001996 <myproc>
    80001d8e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	e10080e7          	jalr	-496(ra) # 80001ba0 <allocproc>
    80001d98:	10050c63          	beqz	a0,80001eb0 <fork+0x13c>
    80001d9c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d9e:	048ab603          	ld	a2,72(s5)
    80001da2:	692c                	ld	a1,80(a0)
    80001da4:	050ab503          	ld	a0,80(s5)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	7ae080e7          	jalr	1966(ra) # 80001556 <uvmcopy>
    80001db0:	04054863          	bltz	a0,80001e00 <fork+0x8c>
  np->sz = p->sz;
    80001db4:	048ab783          	ld	a5,72(s5)
    80001db8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbc:	058ab683          	ld	a3,88(s5)
    80001dc0:	87b6                	mv	a5,a3
    80001dc2:	058a3703          	ld	a4,88(s4)
    80001dc6:	12068693          	addi	a3,a3,288
    80001dca:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dce:	6788                	ld	a0,8(a5)
    80001dd0:	6b8c                	ld	a1,16(a5)
    80001dd2:	6f90                	ld	a2,24(a5)
    80001dd4:	01073023          	sd	a6,0(a4)
    80001dd8:	e708                	sd	a0,8(a4)
    80001dda:	eb0c                	sd	a1,16(a4)
    80001ddc:	ef10                	sd	a2,24(a4)
    80001dde:	02078793          	addi	a5,a5,32
    80001de2:	02070713          	addi	a4,a4,32
    80001de6:	fed792e3          	bne	a5,a3,80001dca <fork+0x56>
  np->trapframe->a0 = 0;
    80001dea:	058a3783          	ld	a5,88(s4)
    80001dee:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001df2:	0d0a8493          	addi	s1,s5,208
    80001df6:	0d0a0913          	addi	s2,s4,208
    80001dfa:	150a8993          	addi	s3,s5,336
    80001dfe:	a00d                	j	80001e20 <fork+0xac>
    freeproc(np);
    80001e00:	8552                	mv	a0,s4
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	d46080e7          	jalr	-698(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001e0a:	8552                	mv	a0,s4
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	e78080e7          	jalr	-392(ra) # 80000c84 <release>
    return -1;
    80001e14:	597d                	li	s2,-1
    80001e16:	a059                	j	80001e9c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e18:	04a1                	addi	s1,s1,8
    80001e1a:	0921                	addi	s2,s2,8
    80001e1c:	01348b63          	beq	s1,s3,80001e32 <fork+0xbe>
    if(p->ofile[i])
    80001e20:	6088                	ld	a0,0(s1)
    80001e22:	d97d                	beqz	a0,80001e18 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	72a080e7          	jalr	1834(ra) # 8000454e <filedup>
    80001e2c:	00a93023          	sd	a0,0(s2)
    80001e30:	b7e5                	j	80001e18 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e32:	150ab503          	ld	a0,336(s5)
    80001e36:	00002097          	auipc	ra,0x2
    80001e3a:	888080e7          	jalr	-1912(ra) # 800036be <idup>
    80001e3e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e42:	4641                	li	a2,16
    80001e44:	158a8593          	addi	a1,s5,344
    80001e48:	158a0513          	addi	a0,s4,344
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	fca080e7          	jalr	-54(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e54:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e58:	8552                	mv	a0,s4
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e2a080e7          	jalr	-470(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e62:	0000f497          	auipc	s1,0xf
    80001e66:	45648493          	addi	s1,s1,1110 # 800112b8 <wait_lock>
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	d64080e7          	jalr	-668(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e74:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e0a080e7          	jalr	-502(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	d4c080e7          	jalr	-692(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e8c:	478d                	li	a5,3
    80001e8e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	df0080e7          	jalr	-528(ra) # 80000c84 <release>
}
    80001e9c:	854a                	mv	a0,s2
    80001e9e:	70e2                	ld	ra,56(sp)
    80001ea0:	7442                	ld	s0,48(sp)
    80001ea2:	74a2                	ld	s1,40(sp)
    80001ea4:	7902                	ld	s2,32(sp)
    80001ea6:	69e2                	ld	s3,24(sp)
    80001ea8:	6a42                	ld	s4,16(sp)
    80001eaa:	6aa2                	ld	s5,8(sp)
    80001eac:	6121                	addi	sp,sp,64
    80001eae:	8082                	ret
    return -1;
    80001eb0:	597d                	li	s2,-1
    80001eb2:	b7ed                	j	80001e9c <fork+0x128>

0000000080001eb4 <scheduler>:
{
    80001eb4:	7139                	addi	sp,sp,-64
    80001eb6:	fc06                	sd	ra,56(sp)
    80001eb8:	f822                	sd	s0,48(sp)
    80001eba:	f426                	sd	s1,40(sp)
    80001ebc:	f04a                	sd	s2,32(sp)
    80001ebe:	ec4e                	sd	s3,24(sp)
    80001ec0:	e852                	sd	s4,16(sp)
    80001ec2:	e456                	sd	s5,8(sp)
    80001ec4:	e05a                	sd	s6,0(sp)
    80001ec6:	0080                	addi	s0,sp,64
    80001ec8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eca:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ecc:	00779a93          	slli	s5,a5,0x7
    80001ed0:	0000f717          	auipc	a4,0xf
    80001ed4:	3d070713          	addi	a4,a4,976 # 800112a0 <pid_lock>
    80001ed8:	9756                	add	a4,a4,s5
    80001eda:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	3fa70713          	addi	a4,a4,1018 # 800112d8 <cpus+0x8>
    80001ee6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eea:	4b11                	li	s6,4
        c->proc = p;
    80001eec:	079e                	slli	a5,a5,0x7
    80001eee:	0000fa17          	auipc	s4,0xf
    80001ef2:	3b2a0a13          	addi	s4,s4,946 # 800112a0 <pid_lock>
    80001ef6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef8:	00015917          	auipc	s2,0x15
    80001efc:	5d890913          	addi	s2,s2,1496 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f04:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f08:	10079073          	csrw	sstatus,a5
    80001f0c:	0000f497          	auipc	s1,0xf
    80001f10:	7c448493          	addi	s1,s1,1988 # 800116d0 <proc>
    80001f14:	a811                	j	80001f28 <scheduler+0x74>
      release(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d6c080e7          	jalr	-660(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f20:	17848493          	addi	s1,s1,376
    80001f24:	fd248ee3          	beq	s1,s2,80001f00 <scheduler+0x4c>
      acquire(&p->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	ca6080e7          	jalr	-858(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f32:	4c9c                	lw	a5,24(s1)
    80001f34:	ff3791e3          	bne	a5,s3,80001f16 <scheduler+0x62>
        p->state = RUNNING;
    80001f38:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f3c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f40:	06048593          	addi	a1,s1,96
    80001f44:	8556                	mv	a0,s5
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	718080e7          	jalr	1816(ra) # 8000265e <swtch>
        c->proc = 0;
    80001f4e:	020a3823          	sd	zero,48(s4)
    80001f52:	b7d1                	j	80001f16 <scheduler+0x62>

0000000080001f54 <sched>:
{
    80001f54:	7179                	addi	sp,sp,-48
    80001f56:	f406                	sd	ra,40(sp)
    80001f58:	f022                	sd	s0,32(sp)
    80001f5a:	ec26                	sd	s1,24(sp)
    80001f5c:	e84a                	sd	s2,16(sp)
    80001f5e:	e44e                	sd	s3,8(sp)
    80001f60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	a34080e7          	jalr	-1484(ra) # 80001996 <myproc>
    80001f6a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	bea080e7          	jalr	-1046(ra) # 80000b56 <holding>
    80001f74:	c93d                	beqz	a0,80001fea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f76:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f78:	2781                	sext.w	a5,a5
    80001f7a:	079e                	slli	a5,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	32470713          	addi	a4,a4,804 # 800112a0 <pid_lock>
    80001f84:	97ba                	add	a5,a5,a4
    80001f86:	0a87a703          	lw	a4,168(a5)
    80001f8a:	4785                	li	a5,1
    80001f8c:	06f71763          	bne	a4,a5,80001ffa <sched+0xa6>
  if(p->state == RUNNING)
    80001f90:	4c98                	lw	a4,24(s1)
    80001f92:	4791                	li	a5,4
    80001f94:	06f70b63          	beq	a4,a5,8000200a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f9e:	efb5                	bnez	a5,8000201a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa2:	0000f917          	auipc	s2,0xf
    80001fa6:	2fe90913          	addi	s2,s2,766 # 800112a0 <pid_lock>
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	97ca                	add	a5,a5,s2
    80001fb0:	0ac7a983          	lw	s3,172(a5)
    80001fb4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f597          	auipc	a1,0xf
    80001fbe:	31e58593          	addi	a1,a1,798 # 800112d8 <cpus+0x8>
    80001fc2:	95be                	add	a1,a1,a5
    80001fc4:	06048513          	addi	a0,s1,96
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	696080e7          	jalr	1686(ra) # 8000265e <swtch>
    80001fd0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	993e                	add	s2,s2,a5
    80001fd8:	0b392623          	sw	s3,172(s2)
}
    80001fdc:	70a2                	ld	ra,40(sp)
    80001fde:	7402                	ld	s0,32(sp)
    80001fe0:	64e2                	ld	s1,24(sp)
    80001fe2:	6942                	ld	s2,16(sp)
    80001fe4:	69a2                	ld	s3,8(sp)
    80001fe6:	6145                	addi	sp,sp,48
    80001fe8:	8082                	ret
    panic("sched p->lock");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	22e50513          	addi	a0,a0,558 # 80008218 <digits+0x1d8>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	548080e7          	jalr	1352(ra) # 8000053a <panic>
    panic("sched locks");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	22e50513          	addi	a0,a0,558 # 80008228 <digits+0x1e8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	538080e7          	jalr	1336(ra) # 8000053a <panic>
    panic("sched running");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	22e50513          	addi	a0,a0,558 # 80008238 <digits+0x1f8>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	528080e7          	jalr	1320(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	22e50513          	addi	a0,a0,558 # 80008248 <digits+0x208>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	518080e7          	jalr	1304(ra) # 8000053a <panic>

000000008000202a <yield>:
{
    8000202a:	1101                	addi	sp,sp,-32
    8000202c:	ec06                	sd	ra,24(sp)
    8000202e:	e822                	sd	s0,16(sp)
    80002030:	e426                	sd	s1,8(sp)
    80002032:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	962080e7          	jalr	-1694(ra) # 80001996 <myproc>
    8000203c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	b92080e7          	jalr	-1134(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002046:	478d                	li	a5,3
    80002048:	cc9c                	sw	a5,24(s1)
  sched();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	f0a080e7          	jalr	-246(ra) # 80001f54 <sched>
  release(&p->lock);
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c30080e7          	jalr	-976(ra) # 80000c84 <release>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6105                	addi	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002066:	7179                	addi	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	1800                	addi	s0,sp,48
    80002074:	89aa                	mv	s3,a0
    80002076:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	91e080e7          	jalr	-1762(ra) # 80001996 <myproc>
    80002080:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	b4e080e7          	jalr	-1202(ra) # 80000bd0 <acquire>
  release(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	bf8080e7          	jalr	-1032(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002094:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002098:	4789                	li	a5,2
    8000209a:	cc9c                	sw	a5,24(s1)

  sched();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	eb8080e7          	jalr	-328(ra) # 80001f54 <sched>

  // Tidy up.
  p->chan = 0;
    800020a4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bda080e7          	jalr	-1062(ra) # 80000c84 <release>
  acquire(lk);
    800020b2:	854a                	mv	a0,s2
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	b1c080e7          	jalr	-1252(ra) # 80000bd0 <acquire>
}
    800020bc:	70a2                	ld	ra,40(sp)
    800020be:	7402                	ld	s0,32(sp)
    800020c0:	64e2                	ld	s1,24(sp)
    800020c2:	6942                	ld	s2,16(sp)
    800020c4:	69a2                	ld	s3,8(sp)
    800020c6:	6145                	addi	sp,sp,48
    800020c8:	8082                	ret

00000000800020ca <wait>:
{
    800020ca:	715d                	addi	sp,sp,-80
    800020cc:	e486                	sd	ra,72(sp)
    800020ce:	e0a2                	sd	s0,64(sp)
    800020d0:	fc26                	sd	s1,56(sp)
    800020d2:	f84a                	sd	s2,48(sp)
    800020d4:	f44e                	sd	s3,40(sp)
    800020d6:	f052                	sd	s4,32(sp)
    800020d8:	ec56                	sd	s5,24(sp)
    800020da:	e85a                	sd	s6,16(sp)
    800020dc:	e45e                	sd	s7,8(sp)
    800020de:	e062                	sd	s8,0(sp)
    800020e0:	0880                	addi	s0,sp,80
    800020e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	8b2080e7          	jalr	-1870(ra) # 80001996 <myproc>
    800020ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020ee:	0000f517          	auipc	a0,0xf
    800020f2:	1ca50513          	addi	a0,a0,458 # 800112b8 <wait_lock>
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	ada080e7          	jalr	-1318(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020fe:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002100:	4a15                	li	s4,5
        havekids = 1;
    80002102:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002104:	00015997          	auipc	s3,0x15
    80002108:	3cc98993          	addi	s3,s3,972 # 800174d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000210c:	0000fc17          	auipc	s8,0xf
    80002110:	1acc0c13          	addi	s8,s8,428 # 800112b8 <wait_lock>
    havekids = 0;
    80002114:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002116:	0000f497          	auipc	s1,0xf
    8000211a:	5ba48493          	addi	s1,s1,1466 # 800116d0 <proc>
    8000211e:	a0bd                	j	8000218c <wait+0xc2>
          pid = np->pid;
    80002120:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002124:	000b0e63          	beqz	s6,80002140 <wait+0x76>
    80002128:	4691                	li	a3,4
    8000212a:	02c48613          	addi	a2,s1,44
    8000212e:	85da                	mv	a1,s6
    80002130:	05093503          	ld	a0,80(s2)
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	526080e7          	jalr	1318(ra) # 8000165a <copyout>
    8000213c:	02054563          	bltz	a0,80002166 <wait+0x9c>
          freeproc(np);
    80002140:	8526                	mv	a0,s1
    80002142:	00000097          	auipc	ra,0x0
    80002146:	a06080e7          	jalr	-1530(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b38080e7          	jalr	-1224(ra) # 80000c84 <release>
          release(&wait_lock);
    80002154:	0000f517          	auipc	a0,0xf
    80002158:	16450513          	addi	a0,a0,356 # 800112b8 <wait_lock>
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
          return pid;
    80002164:	a09d                	j	800021ca <wait+0x100>
            release(&np->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
            release(&wait_lock);
    80002170:	0000f517          	auipc	a0,0xf
    80002174:	14850513          	addi	a0,a0,328 # 800112b8 <wait_lock>
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b0c080e7          	jalr	-1268(ra) # 80000c84 <release>
            return -1;
    80002180:	59fd                	li	s3,-1
    80002182:	a0a1                	j	800021ca <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002184:	17848493          	addi	s1,s1,376
    80002188:	03348463          	beq	s1,s3,800021b0 <wait+0xe6>
      if(np->parent == p){
    8000218c:	7c9c                	ld	a5,56(s1)
    8000218e:	ff279be3          	bne	a5,s2,80002184 <wait+0xba>
        acquire(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	a3c080e7          	jalr	-1476(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    8000219c:	4c9c                	lw	a5,24(s1)
    8000219e:	f94781e3          	beq	a5,s4,80002120 <wait+0x56>
        release(&np->lock);
    800021a2:	8526                	mv	a0,s1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	ae0080e7          	jalr	-1312(ra) # 80000c84 <release>
        havekids = 1;
    800021ac:	8756                	mv	a4,s5
    800021ae:	bfd9                	j	80002184 <wait+0xba>
    if(!havekids || p->killed){
    800021b0:	c701                	beqz	a4,800021b8 <wait+0xee>
    800021b2:	02892783          	lw	a5,40(s2)
    800021b6:	c79d                	beqz	a5,800021e4 <wait+0x11a>
      release(&wait_lock);
    800021b8:	0000f517          	auipc	a0,0xf
    800021bc:	10050513          	addi	a0,a0,256 # 800112b8 <wait_lock>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ac4080e7          	jalr	-1340(ra) # 80000c84 <release>
      return -1;
    800021c8:	59fd                	li	s3,-1
}
    800021ca:	854e                	mv	a0,s3
    800021cc:	60a6                	ld	ra,72(sp)
    800021ce:	6406                	ld	s0,64(sp)
    800021d0:	74e2                	ld	s1,56(sp)
    800021d2:	7942                	ld	s2,48(sp)
    800021d4:	79a2                	ld	s3,40(sp)
    800021d6:	7a02                	ld	s4,32(sp)
    800021d8:	6ae2                	ld	s5,24(sp)
    800021da:	6b42                	ld	s6,16(sp)
    800021dc:	6ba2                	ld	s7,8(sp)
    800021de:	6c02                	ld	s8,0(sp)
    800021e0:	6161                	addi	sp,sp,80
    800021e2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021e4:	85e2                	mv	a1,s8
    800021e6:	854a                	mv	a0,s2
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e7e080e7          	jalr	-386(ra) # 80002066 <sleep>
    havekids = 0;
    800021f0:	b715                	j	80002114 <wait+0x4a>

00000000800021f2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021f2:	7139                	addi	sp,sp,-64
    800021f4:	fc06                	sd	ra,56(sp)
    800021f6:	f822                	sd	s0,48(sp)
    800021f8:	f426                	sd	s1,40(sp)
    800021fa:	f04a                	sd	s2,32(sp)
    800021fc:	ec4e                	sd	s3,24(sp)
    800021fe:	e852                	sd	s4,16(sp)
    80002200:	e456                	sd	s5,8(sp)
    80002202:	0080                	addi	s0,sp,64
    80002204:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	0000f497          	auipc	s1,0xf
    8000220a:	4ca48493          	addi	s1,s1,1226 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000220e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002210:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002212:	00015917          	auipc	s2,0x15
    80002216:	2be90913          	addi	s2,s2,702 # 800174d0 <tickslock>
    8000221a:	a811                	j	8000222e <wakeup+0x3c>
      }
      release(&p->lock);
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a66080e7          	jalr	-1434(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002226:	17848493          	addi	s1,s1,376
    8000222a:	03248663          	beq	s1,s2,80002256 <wakeup+0x64>
    if(p != myproc()){
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	768080e7          	jalr	1896(ra) # 80001996 <myproc>
    80002236:	fea488e3          	beq	s1,a0,80002226 <wakeup+0x34>
      acquire(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	994080e7          	jalr	-1644(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002244:	4c9c                	lw	a5,24(s1)
    80002246:	fd379be3          	bne	a5,s3,8000221c <wakeup+0x2a>
    8000224a:	709c                	ld	a5,32(s1)
    8000224c:	fd4798e3          	bne	a5,s4,8000221c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002250:	0154ac23          	sw	s5,24(s1)
    80002254:	b7e1                	j	8000221c <wakeup+0x2a>
    }
  }
}
    80002256:	70e2                	ld	ra,56(sp)
    80002258:	7442                	ld	s0,48(sp)
    8000225a:	74a2                	ld	s1,40(sp)
    8000225c:	7902                	ld	s2,32(sp)
    8000225e:	69e2                	ld	s3,24(sp)
    80002260:	6a42                	ld	s4,16(sp)
    80002262:	6aa2                	ld	s5,8(sp)
    80002264:	6121                	addi	sp,sp,64
    80002266:	8082                	ret

0000000080002268 <reparent>:
{
    80002268:	7179                	addi	sp,sp,-48
    8000226a:	f406                	sd	ra,40(sp)
    8000226c:	f022                	sd	s0,32(sp)
    8000226e:	ec26                	sd	s1,24(sp)
    80002270:	e84a                	sd	s2,16(sp)
    80002272:	e44e                	sd	s3,8(sp)
    80002274:	e052                	sd	s4,0(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	0000f497          	auipc	s1,0xf
    8000227e:	45648493          	addi	s1,s1,1110 # 800116d0 <proc>
      pp->parent = initproc;
    80002282:	00007a17          	auipc	s4,0x7
    80002286:	da6a0a13          	addi	s4,s4,-602 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000228a:	00015997          	auipc	s3,0x15
    8000228e:	24698993          	addi	s3,s3,582 # 800174d0 <tickslock>
    80002292:	a029                	j	8000229c <reparent+0x34>
    80002294:	17848493          	addi	s1,s1,376
    80002298:	01348d63          	beq	s1,s3,800022b2 <reparent+0x4a>
    if(pp->parent == p){
    8000229c:	7c9c                	ld	a5,56(s1)
    8000229e:	ff279be3          	bne	a5,s2,80002294 <reparent+0x2c>
      pp->parent = initproc;
    800022a2:	000a3503          	ld	a0,0(s4)
    800022a6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	f4a080e7          	jalr	-182(ra) # 800021f2 <wakeup>
    800022b0:	b7d5                	j	80002294 <reparent+0x2c>
}
    800022b2:	70a2                	ld	ra,40(sp)
    800022b4:	7402                	ld	s0,32(sp)
    800022b6:	64e2                	ld	s1,24(sp)
    800022b8:	6942                	ld	s2,16(sp)
    800022ba:	69a2                	ld	s3,8(sp)
    800022bc:	6a02                	ld	s4,0(sp)
    800022be:	6145                	addi	sp,sp,48
    800022c0:	8082                	ret

00000000800022c2 <exit>:
{
    800022c2:	7179                	addi	sp,sp,-48
    800022c4:	f406                	sd	ra,40(sp)
    800022c6:	f022                	sd	s0,32(sp)
    800022c8:	ec26                	sd	s1,24(sp)
    800022ca:	e84a                	sd	s2,16(sp)
    800022cc:	e44e                	sd	s3,8(sp)
    800022ce:	e052                	sd	s4,0(sp)
    800022d0:	1800                	addi	s0,sp,48
    800022d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	6c2080e7          	jalr	1730(ra) # 80001996 <myproc>
    800022dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022de:	00007797          	auipc	a5,0x7
    800022e2:	d4a7b783          	ld	a5,-694(a5) # 80009028 <initproc>
    800022e6:	0d050493          	addi	s1,a0,208
    800022ea:	15050913          	addi	s2,a0,336
    800022ee:	02a79363          	bne	a5,a0,80002314 <exit+0x52>
    panic("init exiting");
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	f6e50513          	addi	a0,a0,-146 # 80008260 <digits+0x220>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	240080e7          	jalr	576(ra) # 8000053a <panic>
      fileclose(f);
    80002302:	00002097          	auipc	ra,0x2
    80002306:	29e080e7          	jalr	670(ra) # 800045a0 <fileclose>
      p->ofile[fd] = 0;
    8000230a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000230e:	04a1                	addi	s1,s1,8
    80002310:	01248563          	beq	s1,s2,8000231a <exit+0x58>
    if(p->ofile[fd]){
    80002314:	6088                	ld	a0,0(s1)
    80002316:	f575                	bnez	a0,80002302 <exit+0x40>
    80002318:	bfdd                	j	8000230e <exit+0x4c>
  begin_op();
    8000231a:	00002097          	auipc	ra,0x2
    8000231e:	dbe080e7          	jalr	-578(ra) # 800040d8 <begin_op>
  iput(p->cwd);
    80002322:	1509b503          	ld	a0,336(s3)
    80002326:	00001097          	auipc	ra,0x1
    8000232a:	590080e7          	jalr	1424(ra) # 800038b6 <iput>
  end_op();
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	e28080e7          	jalr	-472(ra) # 80004156 <end_op>
  p->cwd = 0;
    80002336:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000233a:	0000f497          	auipc	s1,0xf
    8000233e:	f7e48493          	addi	s1,s1,-130 # 800112b8 <wait_lock>
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	88c080e7          	jalr	-1908(ra) # 80000bd0 <acquire>
  reparent(p);
    8000234c:	854e                	mv	a0,s3
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	f1a080e7          	jalr	-230(ra) # 80002268 <reparent>
  wakeup(p->parent);
    80002356:	0389b503          	ld	a0,56(s3)
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	e98080e7          	jalr	-360(ra) # 800021f2 <wakeup>
  acquire(&p->lock);
    80002362:	854e                	mv	a0,s3
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	86c080e7          	jalr	-1940(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000236c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002370:	4795                	li	a5,5
    80002372:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	90c080e7          	jalr	-1780(ra) # 80000c84 <release>
  sched();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	bd4080e7          	jalr	-1068(ra) # 80001f54 <sched>
  panic("zombie exit");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	ee850513          	addi	a0,a0,-280 # 80008270 <digits+0x230>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1aa080e7          	jalr	426(ra) # 8000053a <panic>

0000000080002398 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002398:	7179                	addi	sp,sp,-48
    8000239a:	f406                	sd	ra,40(sp)
    8000239c:	f022                	sd	s0,32(sp)
    8000239e:	ec26                	sd	s1,24(sp)
    800023a0:	e84a                	sd	s2,16(sp)
    800023a2:	e44e                	sd	s3,8(sp)
    800023a4:	1800                	addi	s0,sp,48
    800023a6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023a8:	0000f497          	auipc	s1,0xf
    800023ac:	32848493          	addi	s1,s1,808 # 800116d0 <proc>
    800023b0:	00015997          	auipc	s3,0x15
    800023b4:	12098993          	addi	s3,s3,288 # 800174d0 <tickslock>
    acquire(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	816080e7          	jalr	-2026(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023c2:	589c                	lw	a5,48(s1)
    800023c4:	01278d63          	beq	a5,s2,800023de <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8ba080e7          	jalr	-1862(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d2:	17848493          	addi	s1,s1,376
    800023d6:	ff3491e3          	bne	s1,s3,800023b8 <kill+0x20>
  }
  return -1;
    800023da:	557d                	li	a0,-1
    800023dc:	a829                	j	800023f6 <kill+0x5e>
      p->killed = 1;
    800023de:	4785                	li	a5,1
    800023e0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023e2:	4c98                	lw	a4,24(s1)
    800023e4:	4789                	li	a5,2
    800023e6:	00f70f63          	beq	a4,a5,80002404 <kill+0x6c>
      release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	898080e7          	jalr	-1896(ra) # 80000c84 <release>
      return 0;
    800023f4:	4501                	li	a0,0
}
    800023f6:	70a2                	ld	ra,40(sp)
    800023f8:	7402                	ld	s0,32(sp)
    800023fa:	64e2                	ld	s1,24(sp)
    800023fc:	6942                	ld	s2,16(sp)
    800023fe:	69a2                	ld	s3,8(sp)
    80002400:	6145                	addi	sp,sp,48
    80002402:	8082                	ret
        p->state = RUNNABLE;
    80002404:	478d                	li	a5,3
    80002406:	cc9c                	sw	a5,24(s1)
    80002408:	b7cd                	j	800023ea <kill+0x52>

000000008000240a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	e052                	sd	s4,0(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	84aa                	mv	s1,a0
    8000241c:	892e                	mv	s2,a1
    8000241e:	89b2                	mv	s3,a2
    80002420:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	574080e7          	jalr	1396(ra) # 80001996 <myproc>
  if(user_dst){
    8000242a:	c08d                	beqz	s1,8000244c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000242c:	86d2                	mv	a3,s4
    8000242e:	864e                	mv	a2,s3
    80002430:	85ca                	mv	a1,s2
    80002432:	6928                	ld	a0,80(a0)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	226080e7          	jalr	550(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000243c:	70a2                	ld	ra,40(sp)
    8000243e:	7402                	ld	s0,32(sp)
    80002440:	64e2                	ld	s1,24(sp)
    80002442:	6942                	ld	s2,16(sp)
    80002444:	69a2                	ld	s3,8(sp)
    80002446:	6a02                	ld	s4,0(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret
    memmove((char *)dst, src, len);
    8000244c:	000a061b          	sext.w	a2,s4
    80002450:	85ce                	mv	a1,s3
    80002452:	854a                	mv	a0,s2
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	8d4080e7          	jalr	-1836(ra) # 80000d28 <memmove>
    return 0;
    8000245c:	8526                	mv	a0,s1
    8000245e:	bff9                	j	8000243c <either_copyout+0x32>

0000000080002460 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	892a                	mv	s2,a0
    80002472:	84ae                	mv	s1,a1
    80002474:	89b2                	mv	s3,a2
    80002476:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	51e080e7          	jalr	1310(ra) # 80001996 <myproc>
  if(user_src){
    80002480:	c08d                	beqz	s1,800024a2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002482:	86d2                	mv	a3,s4
    80002484:	864e                	mv	a2,s3
    80002486:	85ca                	mv	a1,s2
    80002488:	6928                	ld	a0,80(a0)
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	25c080e7          	jalr	604(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
    memmove(dst, (char*)src, len);
    800024a2:	000a061b          	sext.w	a2,s4
    800024a6:	85ce                	mv	a1,s3
    800024a8:	854a                	mv	a0,s2
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	87e080e7          	jalr	-1922(ra) # 80000d28 <memmove>
    return 0;
    800024b2:	8526                	mv	a0,s1
    800024b4:	bff9                	j	80002492 <either_copyin+0x32>

00000000800024b6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024b6:	715d                	addi	sp,sp,-80
    800024b8:	e486                	sd	ra,72(sp)
    800024ba:	e0a2                	sd	s0,64(sp)
    800024bc:	fc26                	sd	s1,56(sp)
    800024be:	f84a                	sd	s2,48(sp)
    800024c0:	f44e                	sd	s3,40(sp)
    800024c2:	f052                	sd	s4,32(sp)
    800024c4:	ec56                	sd	s5,24(sp)
    800024c6:	e85a                	sd	s6,16(sp)
    800024c8:	e45e                	sd	s7,8(sp)
    800024ca:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024cc:	00006517          	auipc	a0,0x6
    800024d0:	bfc50513          	addi	a0,a0,-1028 # 800080c8 <digits+0x88>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	0b0080e7          	jalr	176(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024dc:	0000f497          	auipc	s1,0xf
    800024e0:	34c48493          	addi	s1,s1,844 # 80011828 <proc+0x158>
    800024e4:	00015917          	auipc	s2,0x15
    800024e8:	14490913          	addi	s2,s2,324 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024ec:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024ee:	00006997          	auipc	s3,0x6
    800024f2:	d9298993          	addi	s3,s3,-622 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024f6:	00006a97          	auipc	s5,0x6
    800024fa:	d92a8a93          	addi	s5,s5,-622 # 80008288 <digits+0x248>
    printf("\n");
    800024fe:	00006a17          	auipc	s4,0x6
    80002502:	bcaa0a13          	addi	s4,s4,-1078 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002506:	00006b97          	auipc	s7,0x6
    8000250a:	e22b8b93          	addi	s7,s7,-478 # 80008328 <states.1>
    8000250e:	a00d                	j	80002530 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002510:	ed86a583          	lw	a1,-296(a3)
    80002514:	8556                	mv	a0,s5
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	06e080e7          	jalr	110(ra) # 80000584 <printf>
    printf("\n");
    8000251e:	8552                	mv	a0,s4
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	064080e7          	jalr	100(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002528:	17848493          	addi	s1,s1,376
    8000252c:	03248263          	beq	s1,s2,80002550 <procdump+0x9a>
    if(p->state == UNUSED)
    80002530:	86a6                	mv	a3,s1
    80002532:	ec04a783          	lw	a5,-320(s1)
    80002536:	dbed                	beqz	a5,80002528 <procdump+0x72>
      state = "???";
    80002538:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253a:	fcfb6be3          	bltu	s6,a5,80002510 <procdump+0x5a>
    8000253e:	02079713          	slli	a4,a5,0x20
    80002542:	01d75793          	srli	a5,a4,0x1d
    80002546:	97de                	add	a5,a5,s7
    80002548:	6390                	ld	a2,0(a5)
    8000254a:	f279                	bnez	a2,80002510 <procdump+0x5a>
      state = "???";
    8000254c:	864e                	mv	a2,s3
    8000254e:	b7c9                	j	80002510 <procdump+0x5a>
  }
}
    80002550:	60a6                	ld	ra,72(sp)
    80002552:	6406                	ld	s0,64(sp)
    80002554:	74e2                	ld	s1,56(sp)
    80002556:	7942                	ld	s2,48(sp)
    80002558:	79a2                	ld	s3,40(sp)
    8000255a:	7a02                	ld	s4,32(sp)
    8000255c:	6ae2                	ld	s5,24(sp)
    8000255e:	6b42                	ld	s6,16(sp)
    80002560:	6ba2                	ld	s7,8(sp)
    80002562:	6161                	addi	sp,sp,80
    80002564:	8082                	ret

0000000080002566 <cps>:

int
cps (void)
{
    80002566:	715d                	addi	sp,sp,-80
    80002568:	e486                	sd	ra,72(sp)
    8000256a:	e0a2                	sd	s0,64(sp)
    8000256c:	fc26                	sd	s1,56(sp)
    8000256e:	f84a                	sd	s2,48(sp)
    80002570:	f44e                	sd	s3,40(sp)
    80002572:	f052                	sd	s4,32(sp)
    80002574:	ec56                	sd	s5,24(sp)
    80002576:	e85a                	sd	s6,16(sp)
    80002578:	e45e                	sd	s7,8(sp)
    8000257a:	e062                	sd	s8,0(sp)
    8000257c:	0880                	addi	s0,sp,80
	struct proc *p;
	static const char *queue[] = { "HIGH","LOW" };
	acquire (&proc->lock);
    8000257e:	0000f517          	auipc	a0,0xf
    80002582:	15250513          	addi	a0,a0,338 # 800116d0 <proc>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	64a080e7          	jalr	1610(ra) # 80000bd0 <acquire>
	printf ("name \t pid \t state \t queue\n");
    8000258e:	00006517          	auipc	a0,0x6
    80002592:	d0a50513          	addi	a0,a0,-758 # 80008298 <digits+0x258>
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	fee080e7          	jalr	-18(ra) # 80000584 <printf>
	for (p = proc; p < &proc[NPROC]; p++) {
    8000259e:	0000f497          	auipc	s1,0xf
    800025a2:	28a48493          	addi	s1,s1,650 # 80011828 <proc+0x158>
    800025a6:	00015997          	auipc	s3,0x15
    800025aa:	08298993          	addi	s3,s3,130 # 80017628 <bcache+0x140>
		if (p->state == SLEEPING)
    800025ae:	4909                	li	s2,2
			printf ("%s \t %d \t SLEEPING \t %s\n", p->name, p->pid, queue [p->in_queue]);
		else if (p->state == RUNNING)
    800025b0:	4a11                	li	s4,4
			printf ("%s \t %d \t RUNNING \t %s\n", p->name, p->pid, queue [p->in_queue]);
		else if (p->state == RUNNABLE)
    800025b2:	4a8d                	li	s5,3
			printf ("%s \t %d \t SLEEPING \t %s\n", p->name, p->pid, queue [p->in_queue]);
    800025b4:	00006b17          	auipc	s6,0x6
    800025b8:	d74b0b13          	addi	s6,s6,-652 # 80008328 <states.1>
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	cfcb8b93          	addi	s7,s7,-772 # 800082b8 <digits+0x278>
			printf ("%s \t %d \t RUNNING \t %s\n", p->name, p->pid, queue [p->in_queue]);
    800025c4:	00006c17          	auipc	s8,0x6
    800025c8:	d14c0c13          	addi	s8,s8,-748 # 800082d8 <digits+0x298>
    800025cc:	a00d                	j	800025ee <cps+0x88>
			printf ("%s \t %d \t SLEEPING \t %s\n", p->name, p->pid, queue [p->in_queue]);
    800025ce:	0184e783          	lwu	a5,24(s1)
    800025d2:	078e                	slli	a5,a5,0x3
    800025d4:	97da                	add	a5,a5,s6
    800025d6:	7b94                	ld	a3,48(a5)
    800025d8:	ed84a603          	lw	a2,-296(s1)
    800025dc:	855e                	mv	a0,s7
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	fa6080e7          	jalr	-90(ra) # 80000584 <printf>
	for (p = proc; p < &proc[NPROC]; p++) {
    800025e6:	17848493          	addi	s1,s1,376
    800025ea:	05348563          	beq	s1,s3,80002634 <cps+0xce>
		if (p->state == SLEEPING)
    800025ee:	85a6                	mv	a1,s1
    800025f0:	ec04a783          	lw	a5,-320(s1)
    800025f4:	fd278de3          	beq	a5,s2,800025ce <cps+0x68>
		else if (p->state == RUNNING)
    800025f8:	03478163          	beq	a5,s4,8000261a <cps+0xb4>
		else if (p->state == RUNNABLE)
    800025fc:	ff5795e3          	bne	a5,s5,800025e6 <cps+0x80>
			printf ("%s \t %d \t SLEEPING \t %s\n", p->name, p->pid, queue [p->in_queue]);
    80002600:	0184e783          	lwu	a5,24(s1)
    80002604:	078e                	slli	a5,a5,0x3
    80002606:	97da                	add	a5,a5,s6
    80002608:	7b94                	ld	a3,48(a5)
    8000260a:	ed84a603          	lw	a2,-296(s1)
    8000260e:	855e                	mv	a0,s7
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	f74080e7          	jalr	-140(ra) # 80000584 <printf>
    80002618:	b7f9                	j	800025e6 <cps+0x80>
			printf ("%s \t %d \t RUNNING \t %s\n", p->name, p->pid, queue [p->in_queue]);
    8000261a:	0184e783          	lwu	a5,24(s1)
    8000261e:	078e                	slli	a5,a5,0x3
    80002620:	97da                	add	a5,a5,s6
    80002622:	7b94                	ld	a3,48(a5)
    80002624:	ed84a603          	lw	a2,-296(s1)
    80002628:	8562                	mv	a0,s8
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	f5a080e7          	jalr	-166(ra) # 80000584 <printf>
    80002632:	bf55                	j	800025e6 <cps+0x80>
	}
	release(&proc->lock);
    80002634:	0000f517          	auipc	a0,0xf
    80002638:	09c50513          	addi	a0,a0,156 # 800116d0 <proc>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	648080e7          	jalr	1608(ra) # 80000c84 <release>
	return 22;
}
    80002644:	4559                	li	a0,22
    80002646:	60a6                	ld	ra,72(sp)
    80002648:	6406                	ld	s0,64(sp)
    8000264a:	74e2                	ld	s1,56(sp)
    8000264c:	7942                	ld	s2,48(sp)
    8000264e:	79a2                	ld	s3,40(sp)
    80002650:	7a02                	ld	s4,32(sp)
    80002652:	6ae2                	ld	s5,24(sp)
    80002654:	6b42                	ld	s6,16(sp)
    80002656:	6ba2                	ld	s7,8(sp)
    80002658:	6c02                	ld	s8,0(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00006597          	auipc	a1,0x6
    800026d4:	c9858593          	addi	a1,a1,-872 # 80008368 <queue.0+0x10>
    800026d8:	00015517          	auipc	a0,0x15
    800026dc:	df850513          	addi	a0,a0,-520 # 800174d0 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	460080e7          	jalr	1120(ra) # 80000b40 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	4da78793          	addi	a5,a5,1242 # 80005bd0 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	addi	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	addi	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	286080e7          	jalr	646(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002722:	00005697          	auipc	a3,0x5
    80002726:	8de68693          	addi	a3,a3,-1826 # 80007000 <_trampoline>
    8000272a:	00005717          	auipc	a4,0x5
    8000272e:	8d670713          	addi	a4,a4,-1834 # 80007000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	slli	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13860613          	addi	a2,a2,312 # 8000288e <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	692c                	ld	a1,80(a0)
    80002780:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002782:	00005717          	auipc	a4,0x5
    80002786:	90e70713          	addi	a4,a4,-1778 # 80007090 <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	slli	a4,a4,0x3f
    80002792:	8dd9                	or	a1,a1,a4
    80002794:	02000537          	lui	a0,0x2000
    80002798:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000279a:	0536                	slli	a0,a0,0xd
    8000279c:	9782                	jalr	a5
}
    8000279e:	60a2                	ld	ra,8(sp)
    800027a0:	6402                	ld	s0,0(sp)
    800027a2:	0141                	addi	sp,sp,16
    800027a4:	8082                	ret

00000000800027a6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a6:	1101                	addi	sp,sp,-32
    800027a8:	ec06                	sd	ra,24(sp)
    800027aa:	e822                	sd	s0,16(sp)
    800027ac:	e426                	sd	s1,8(sp)
    800027ae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b0:	00015497          	auipc	s1,0x15
    800027b4:	d2048493          	addi	s1,s1,-736 # 800174d0 <tickslock>
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	416080e7          	jalr	1046(ra) # 80000bd0 <acquire>
  ticks++;
    800027c2:	00007517          	auipc	a0,0x7
    800027c6:	86e50513          	addi	a0,a0,-1938 # 80009030 <ticks>
    800027ca:	411c                	lw	a5,0(a0)
    800027cc:	2785                	addiw	a5,a5,1
    800027ce:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	a22080e7          	jalr	-1502(ra) # 800021f2 <wakeup>
  release(&tickslock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4aa080e7          	jalr	1194(ra) # 80000c84 <release>
}
    800027e2:	60e2                	ld	ra,24(sp)
    800027e4:	6442                	ld	s0,16(sp)
    800027e6:	64a2                	ld	s1,8(sp)
    800027e8:	6105                	addi	sp,sp,32
    800027ea:	8082                	ret

00000000800027ec <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ec:	1101                	addi	sp,sp,-32
    800027ee:	ec06                	sd	ra,24(sp)
    800027f0:	e822                	sd	s0,16(sp)
    800027f2:	e426                	sd	s1,8(sp)
    800027f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fa:	00074d63          	bltz	a4,80002814 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fe:	57fd                	li	a5,-1
    80002800:	17fe                	slli	a5,a5,0x3f
    80002802:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002804:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002806:	06f70363          	beq	a4,a5,8000286c <devintr+0x80>
  }
}
    8000280a:	60e2                	ld	ra,24(sp)
    8000280c:	6442                	ld	s0,16(sp)
    8000280e:	64a2                	ld	s1,8(sp)
    80002810:	6105                	addi	sp,sp,32
    80002812:	8082                	ret
     (scause & 0xff) == 9){
    80002814:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002818:	46a5                	li	a3,9
    8000281a:	fed792e3          	bne	a5,a3,800027fe <devintr+0x12>
    int irq = plic_claim();
    8000281e:	00003097          	auipc	ra,0x3
    80002822:	4ba080e7          	jalr	1210(ra) # 80005cd8 <plic_claim>
    80002826:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002828:	47a9                	li	a5,10
    8000282a:	02f50763          	beq	a0,a5,80002858 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282e:	4785                	li	a5,1
    80002830:	02f50963          	beq	a0,a5,80002862 <devintr+0x76>
    return 1;
    80002834:	4505                	li	a0,1
    } else if(irq){
    80002836:	d8f1                	beqz	s1,8000280a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002838:	85a6                	mv	a1,s1
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	b3650513          	addi	a0,a0,-1226 # 80008370 <queue.0+0x18>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	d42080e7          	jalr	-702(ra) # 80000584 <printf>
      plic_complete(irq);
    8000284a:	8526                	mv	a0,s1
    8000284c:	00003097          	auipc	ra,0x3
    80002850:	4b0080e7          	jalr	1200(ra) # 80005cfc <plic_complete>
    return 1;
    80002854:	4505                	li	a0,1
    80002856:	bf55                	j	8000280a <devintr+0x1e>
      uartintr();
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	13a080e7          	jalr	314(ra) # 80000992 <uartintr>
    80002860:	b7ed                	j	8000284a <devintr+0x5e>
      virtio_disk_intr();
    80002862:	00004097          	auipc	ra,0x4
    80002866:	926080e7          	jalr	-1754(ra) # 80006188 <virtio_disk_intr>
    8000286a:	b7c5                	j	8000284a <devintr+0x5e>
    if(cpuid() == 0){
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	0fe080e7          	jalr	254(ra) # 8000196a <cpuid>
    80002874:	c901                	beqz	a0,80002884 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002876:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287c:	14479073          	csrw	sip,a5
    return 2;
    80002880:	4509                	li	a0,2
    80002882:	b761                	j	8000280a <devintr+0x1e>
      clockintr();
    80002884:	00000097          	auipc	ra,0x0
    80002888:	f22080e7          	jalr	-222(ra) # 800027a6 <clockintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x8a>

000000008000288e <usertrap>:
{
    8000288e:	1101                	addi	sp,sp,-32
    80002890:	ec06                	sd	ra,24(sp)
    80002892:	e822                	sd	s0,16(sp)
    80002894:	e426                	sd	s1,8(sp)
    80002896:	e04a                	sd	s2,0(sp)
    80002898:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289e:	1007f793          	andi	a5,a5,256
    800028a2:	e3ad                	bnez	a5,80002904 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00003797          	auipc	a5,0x3
    800028a8:	32c78793          	addi	a5,a5,812 # 80005bd0 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	0e6080e7          	jalr	230(ra) # 80001996 <myproc>
    800028b8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028bc:	14102773          	csrr	a4,sepc
    800028c0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c6:	47a1                	li	a5,8
    800028c8:	04f71c63          	bne	a4,a5,80002920 <usertrap+0x92>
    if(p->killed)
    800028cc:	551c                	lw	a5,40(a0)
    800028ce:	e3b9                	bnez	a5,80002914 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028d0:	6cb8                	ld	a4,88(s1)
    800028d2:	6f1c                	ld	a5,24(a4)
    800028d4:	0791                	addi	a5,a5,4
    800028d6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028dc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e0:	10079073          	csrw	sstatus,a5
    syscall();
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	2e0080e7          	jalr	736(ra) # 80002bc4 <syscall>
  if(p->killed)
    800028ec:	549c                	lw	a5,40(s1)
    800028ee:	ebc1                	bnez	a5,8000297e <usertrap+0xf0>
  usertrapret();
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	e18080e7          	jalr	-488(ra) # 80002708 <usertrapret>
}
    800028f8:	60e2                	ld	ra,24(sp)
    800028fa:	6442                	ld	s0,16(sp)
    800028fc:	64a2                	ld	s1,8(sp)
    800028fe:	6902                	ld	s2,0(sp)
    80002900:	6105                	addi	sp,sp,32
    80002902:	8082                	ret
    panic("usertrap: not from user mode");
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a8c50513          	addi	a0,a0,-1396 # 80008390 <queue.0+0x38>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c2e080e7          	jalr	-978(ra) # 8000053a <panic>
      exit(-1);
    80002914:	557d                	li	a0,-1
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	9ac080e7          	jalr	-1620(ra) # 800022c2 <exit>
    8000291e:	bf4d                	j	800028d0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002920:	00000097          	auipc	ra,0x0
    80002924:	ecc080e7          	jalr	-308(ra) # 800027ec <devintr>
    80002928:	892a                	mv	s2,a0
    8000292a:	c501                	beqz	a0,80002932 <usertrap+0xa4>
  if(p->killed)
    8000292c:	549c                	lw	a5,40(s1)
    8000292e:	c3a1                	beqz	a5,8000296e <usertrap+0xe0>
    80002930:	a815                	j	80002964 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002932:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002936:	5890                	lw	a2,48(s1)
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	a7850513          	addi	a0,a0,-1416 # 800083b0 <queue.0+0x58>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c44080e7          	jalr	-956(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002948:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000294c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002950:	00006517          	auipc	a0,0x6
    80002954:	a9050513          	addi	a0,a0,-1392 # 800083e0 <queue.0+0x88>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	c2c080e7          	jalr	-980(ra) # 80000584 <printf>
    p->killed = 1;
    80002960:	4785                	li	a5,1
    80002962:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002964:	557d                	li	a0,-1
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	95c080e7          	jalr	-1700(ra) # 800022c2 <exit>
  if(which_dev == 2)
    8000296e:	4789                	li	a5,2
    80002970:	f8f910e3          	bne	s2,a5,800028f0 <usertrap+0x62>
    yield();
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	6b6080e7          	jalr	1718(ra) # 8000202a <yield>
    8000297c:	bf95                	j	800028f0 <usertrap+0x62>
  int which_dev = 0;
    8000297e:	4901                	li	s2,0
    80002980:	b7d5                	j	80002964 <usertrap+0xd6>

0000000080002982 <kerneltrap>:
{
    80002982:	7179                	addi	sp,sp,-48
    80002984:	f406                	sd	ra,40(sp)
    80002986:	f022                	sd	s0,32(sp)
    80002988:	ec26                	sd	s1,24(sp)
    8000298a:	e84a                	sd	s2,16(sp)
    8000298c:	e44e                	sd	s3,8(sp)
    8000298e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000299c:	1004f793          	andi	a5,s1,256
    800029a0:	cb85                	beqz	a5,800029d0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029a8:	ef85                	bnez	a5,800029e0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	e42080e7          	jalr	-446(ra) # 800027ec <devintr>
    800029b2:	cd1d                	beqz	a0,800029f0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b4:	4789                	li	a5,2
    800029b6:	06f50a63          	beq	a0,a5,80002a2a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029be:	10049073          	csrw	sstatus,s1
}
    800029c2:	70a2                	ld	ra,40(sp)
    800029c4:	7402                	ld	s0,32(sp)
    800029c6:	64e2                	ld	s1,24(sp)
    800029c8:	6942                	ld	s2,16(sp)
    800029ca:	69a2                	ld	s3,8(sp)
    800029cc:	6145                	addi	sp,sp,48
    800029ce:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	a3050513          	addi	a0,a0,-1488 # 80008400 <queue.0+0xa8>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	b62080e7          	jalr	-1182(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	a4850513          	addi	a0,a0,-1464 # 80008428 <queue.0+0xd0>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	b52080e7          	jalr	-1198(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    800029f0:	85ce                	mv	a1,s3
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	a5650513          	addi	a0,a0,-1450 # 80008448 <queue.0+0xf0>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b8a080e7          	jalr	-1142(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a06:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	a4e50513          	addi	a0,a0,-1458 # 80008458 <queue.0+0x100>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b72080e7          	jalr	-1166(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	a5650513          	addi	a0,a0,-1450 # 80008470 <queue.0+0x118>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b18080e7          	jalr	-1256(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	f6c080e7          	jalr	-148(ra) # 80001996 <myproc>
    80002a32:	d541                	beqz	a0,800029ba <kerneltrap+0x38>
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	f62080e7          	jalr	-158(ra) # 80001996 <myproc>
    80002a3c:	4d18                	lw	a4,24(a0)
    80002a3e:	4791                	li	a5,4
    80002a40:	f6f71de3          	bne	a4,a5,800029ba <kerneltrap+0x38>
    yield();
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	5e6080e7          	jalr	1510(ra) # 8000202a <yield>
    80002a4c:	b7bd                	j	800029ba <kerneltrap+0x38>

0000000080002a4e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a4e:	1101                	addi	sp,sp,-32
    80002a50:	ec06                	sd	ra,24(sp)
    80002a52:	e822                	sd	s0,16(sp)
    80002a54:	e426                	sd	s1,8(sp)
    80002a56:	1000                	addi	s0,sp,32
    80002a58:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	f3c080e7          	jalr	-196(ra) # 80001996 <myproc>
  switch (n) {
    80002a62:	4795                	li	a5,5
    80002a64:	0497e163          	bltu	a5,s1,80002aa6 <argraw+0x58>
    80002a68:	048a                	slli	s1,s1,0x2
    80002a6a:	00006717          	auipc	a4,0x6
    80002a6e:	a3e70713          	addi	a4,a4,-1474 # 800084a8 <queue.0+0x150>
    80002a72:	94ba                	add	s1,s1,a4
    80002a74:	409c                	lw	a5,0(s1)
    80002a76:	97ba                	add	a5,a5,a4
    80002a78:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7a:	6d3c                	ld	a5,88(a0)
    80002a7c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a7e:	60e2                	ld	ra,24(sp)
    80002a80:	6442                	ld	s0,16(sp)
    80002a82:	64a2                	ld	s1,8(sp)
    80002a84:	6105                	addi	sp,sp,32
    80002a86:	8082                	ret
    return p->trapframe->a1;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	7fa8                	ld	a0,120(a5)
    80002a8c:	bfcd                	j	80002a7e <argraw+0x30>
    return p->trapframe->a2;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	63c8                	ld	a0,128(a5)
    80002a92:	b7f5                	j	80002a7e <argraw+0x30>
    return p->trapframe->a3;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	67c8                	ld	a0,136(a5)
    80002a98:	b7dd                	j	80002a7e <argraw+0x30>
    return p->trapframe->a4;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	6bc8                	ld	a0,144(a5)
    80002a9e:	b7c5                	j	80002a7e <argraw+0x30>
    return p->trapframe->a5;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	6fc8                	ld	a0,152(a5)
    80002aa4:	bfe9                	j	80002a7e <argraw+0x30>
  panic("argraw");
    80002aa6:	00006517          	auipc	a0,0x6
    80002aaa:	9da50513          	addi	a0,a0,-1574 # 80008480 <queue.0+0x128>
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	a8c080e7          	jalr	-1396(ra) # 8000053a <panic>

0000000080002ab6 <fetchaddr>:
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	e426                	sd	s1,8(sp)
    80002abe:	e04a                	sd	s2,0(sp)
    80002ac0:	1000                	addi	s0,sp,32
    80002ac2:	84aa                	mv	s1,a0
    80002ac4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	ed0080e7          	jalr	-304(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ace:	653c                	ld	a5,72(a0)
    80002ad0:	02f4f863          	bgeu	s1,a5,80002b00 <fetchaddr+0x4a>
    80002ad4:	00848713          	addi	a4,s1,8
    80002ad8:	02e7e663          	bltu	a5,a4,80002b04 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002adc:	46a1                	li	a3,8
    80002ade:	8626                	mv	a2,s1
    80002ae0:	85ca                	mv	a1,s2
    80002ae2:	6928                	ld	a0,80(a0)
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	c02080e7          	jalr	-1022(ra) # 800016e6 <copyin>
    80002aec:	00a03533          	snez	a0,a0
    80002af0:	40a00533          	neg	a0,a0
}
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6902                	ld	s2,0(sp)
    80002afc:	6105                	addi	sp,sp,32
    80002afe:	8082                	ret
    return -1;
    80002b00:	557d                	li	a0,-1
    80002b02:	bfcd                	j	80002af4 <fetchaddr+0x3e>
    80002b04:	557d                	li	a0,-1
    80002b06:	b7fd                	j	80002af4 <fetchaddr+0x3e>

0000000080002b08 <fetchstr>:
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	e44e                	sd	s3,8(sp)
    80002b14:	1800                	addi	s0,sp,48
    80002b16:	892a                	mv	s2,a0
    80002b18:	84ae                	mv	s1,a1
    80002b1a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	e7a080e7          	jalr	-390(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b24:	86ce                	mv	a3,s3
    80002b26:	864a                	mv	a2,s2
    80002b28:	85a6                	mv	a1,s1
    80002b2a:	6928                	ld	a0,80(a0)
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	c48080e7          	jalr	-952(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002b34:	00054763          	bltz	a0,80002b42 <fetchstr+0x3a>
  return strlen(buf);
    80002b38:	8526                	mv	a0,s1
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	30e080e7          	jalr	782(ra) # 80000e48 <strlen>
}
    80002b42:	70a2                	ld	ra,40(sp)
    80002b44:	7402                	ld	s0,32(sp)
    80002b46:	64e2                	ld	s1,24(sp)
    80002b48:	6942                	ld	s2,16(sp)
    80002b4a:	69a2                	ld	s3,8(sp)
    80002b4c:	6145                	addi	sp,sp,48
    80002b4e:	8082                	ret

0000000080002b50 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	1000                	addi	s0,sp,32
    80002b5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	ef2080e7          	jalr	-270(ra) # 80002a4e <argraw>
    80002b64:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b66:	4501                	li	a0,0
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	64a2                	ld	s1,8(sp)
    80002b6e:	6105                	addi	sp,sp,32
    80002b70:	8082                	ret

0000000080002b72 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	1000                	addi	s0,sp,32
    80002b7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	ed0080e7          	jalr	-304(ra) # 80002a4e <argraw>
    80002b86:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b88:	4501                	li	a0,0
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret

0000000080002b94 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b94:	1101                	addi	sp,sp,-32
    80002b96:	ec06                	sd	ra,24(sp)
    80002b98:	e822                	sd	s0,16(sp)
    80002b9a:	e426                	sd	s1,8(sp)
    80002b9c:	e04a                	sd	s2,0(sp)
    80002b9e:	1000                	addi	s0,sp,32
    80002ba0:	84ae                	mv	s1,a1
    80002ba2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	eaa080e7          	jalr	-342(ra) # 80002a4e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bac:	864a                	mv	a2,s2
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	f58080e7          	jalr	-168(ra) # 80002b08 <fetchstr>
}
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6902                	ld	s2,0(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret

0000000080002bc4 <syscall>:
[SYS_cps] sys_cps,
};

void
syscall(void)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	dc6080e7          	jalr	-570(ra) # 80001996 <myproc>
    80002bd8:	84aa                	mv	s1,a0
  count_syscall++;
    80002bda:	00006717          	auipc	a4,0x6
    80002bde:	45e70713          	addi	a4,a4,1118 # 80009038 <count_syscall>
    80002be2:	631c                	ld	a5,0(a4)
    80002be4:	0785                	addi	a5,a5,1
    80002be6:	e31c                	sd	a5,0(a4)

  num = p->trapframe->a7;
    80002be8:	05853903          	ld	s2,88(a0)
    80002bec:	0a893783          	ld	a5,168(s2)
    80002bf0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bf4:	37fd                	addiw	a5,a5,-1
    80002bf6:	4759                	li	a4,22
    80002bf8:	00f76f63          	bltu	a4,a5,80002c16 <syscall+0x52>
    80002bfc:	00369713          	slli	a4,a3,0x3
    80002c00:	00006797          	auipc	a5,0x6
    80002c04:	8c078793          	addi	a5,a5,-1856 # 800084c0 <syscalls>
    80002c08:	97ba                	add	a5,a5,a4
    80002c0a:	639c                	ld	a5,0(a5)
    80002c0c:	c789                	beqz	a5,80002c16 <syscall+0x52>
    p->trapframe->a0 = syscalls[num]();
    80002c0e:	9782                	jalr	a5
    80002c10:	06a93823          	sd	a0,112(s2)
    80002c14:	a839                	j	80002c32 <syscall+0x6e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c16:	15848613          	addi	a2,s1,344
    80002c1a:	588c                	lw	a1,48(s1)
    80002c1c:	00006517          	auipc	a0,0x6
    80002c20:	86c50513          	addi	a0,a0,-1940 # 80008488 <queue.0+0x130>
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	960080e7          	jalr	-1696(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c2c:	6cbc                	ld	a5,88(s1)
    80002c2e:	577d                	li	a4,-1
    80002c30:	fbb8                	sd	a4,112(a5)
  }
}
    80002c32:	60e2                	ld	ra,24(sp)
    80002c34:	6442                	ld	s0,16(sp)
    80002c36:	64a2                	ld	s1,8(sp)
    80002c38:	6902                	ld	s2,0(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret

0000000080002c3e <sys_exit>:

uint64 count_syscall = 0;

uint64
sys_exit(void)
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c46:	fec40593          	addi	a1,s0,-20
    80002c4a:	4501                	li	a0,0
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	f04080e7          	jalr	-252(ra) # 80002b50 <argint>
    return -1;
    80002c54:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c56:	00054963          	bltz	a0,80002c68 <sys_exit+0x2a>
  exit(n);
    80002c5a:	fec42503          	lw	a0,-20(s0)
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	664080e7          	jalr	1636(ra) # 800022c2 <exit>
  return 0;  // not reached
    80002c66:	4781                	li	a5,0
}
    80002c68:	853e                	mv	a0,a5
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c72:	1141                	addi	sp,sp,-16
    80002c74:	e406                	sd	ra,8(sp)
    80002c76:	e022                	sd	s0,0(sp)
    80002c78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d1c080e7          	jalr	-740(ra) # 80001996 <myproc>
}
    80002c82:	5908                	lw	a0,48(a0)
    80002c84:	60a2                	ld	ra,8(sp)
    80002c86:	6402                	ld	s0,0(sp)
    80002c88:	0141                	addi	sp,sp,16
    80002c8a:	8082                	ret

0000000080002c8c <sys_fork>:

uint64
sys_fork(void)
{
    80002c8c:	1141                	addi	sp,sp,-16
    80002c8e:	e406                	sd	ra,8(sp)
    80002c90:	e022                	sd	s0,0(sp)
    80002c92:	0800                	addi	s0,sp,16
  return fork();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	0e0080e7          	jalr	224(ra) # 80001d74 <fork>
}
    80002c9c:	60a2                	ld	ra,8(sp)
    80002c9e:	6402                	ld	s0,0(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret

0000000080002ca4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cac:	fe840593          	addi	a1,s0,-24
    80002cb0:	4501                	li	a0,0
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	ec0080e7          	jalr	-320(ra) # 80002b72 <argaddr>
    80002cba:	87aa                	mv	a5,a0
    return -1;
    80002cbc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cbe:	0007c863          	bltz	a5,80002cce <sys_wait+0x2a>
  return wait(p);
    80002cc2:	fe843503          	ld	a0,-24(s0)
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	404080e7          	jalr	1028(ra) # 800020ca <wait>
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret

0000000080002cd6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd6:	7179                	addi	sp,sp,-48
    80002cd8:	f406                	sd	ra,40(sp)
    80002cda:	f022                	sd	s0,32(sp)
    80002cdc:	ec26                	sd	s1,24(sp)
    80002cde:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ce0:	fdc40593          	addi	a1,s0,-36
    80002ce4:	4501                	li	a0,0
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	e6a080e7          	jalr	-406(ra) # 80002b50 <argint>
    80002cee:	87aa                	mv	a5,a0
    return -1;
    80002cf0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cf2:	0207c063          	bltz	a5,80002d12 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	ca0080e7          	jalr	-864(ra) # 80001996 <myproc>
    80002cfe:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d00:	fdc42503          	lw	a0,-36(s0)
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	ff8080e7          	jalr	-8(ra) # 80001cfc <growproc>
    80002d0c:	00054863          	bltz	a0,80002d1c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d10:	8526                	mv	a0,s1
}
    80002d12:	70a2                	ld	ra,40(sp)
    80002d14:	7402                	ld	s0,32(sp)
    80002d16:	64e2                	ld	s1,24(sp)
    80002d18:	6145                	addi	sp,sp,48
    80002d1a:	8082                	ret
    return -1;
    80002d1c:	557d                	li	a0,-1
    80002d1e:	bfd5                	j	80002d12 <sys_sbrk+0x3c>

0000000080002d20 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d20:	7139                	addi	sp,sp,-64
    80002d22:	fc06                	sd	ra,56(sp)
    80002d24:	f822                	sd	s0,48(sp)
    80002d26:	f426                	sd	s1,40(sp)
    80002d28:	f04a                	sd	s2,32(sp)
    80002d2a:	ec4e                	sd	s3,24(sp)
    80002d2c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d2e:	fcc40593          	addi	a1,s0,-52
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	e1c080e7          	jalr	-484(ra) # 80002b50 <argint>
    return -1;
    80002d3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d3e:	06054563          	bltz	a0,80002da8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d42:	00014517          	auipc	a0,0x14
    80002d46:	78e50513          	addi	a0,a0,1934 # 800174d0 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	e86080e7          	jalr	-378(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002d52:	00006917          	auipc	s2,0x6
    80002d56:	2de92903          	lw	s2,734(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d5a:	fcc42783          	lw	a5,-52(s0)
    80002d5e:	cf85                	beqz	a5,80002d96 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d60:	00014997          	auipc	s3,0x14
    80002d64:	77098993          	addi	s3,s3,1904 # 800174d0 <tickslock>
    80002d68:	00006497          	auipc	s1,0x6
    80002d6c:	2c848493          	addi	s1,s1,712 # 80009030 <ticks>
    if(myproc()->killed){
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	c26080e7          	jalr	-986(ra) # 80001996 <myproc>
    80002d78:	551c                	lw	a5,40(a0)
    80002d7a:	ef9d                	bnez	a5,80002db8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d7c:	85ce                	mv	a1,s3
    80002d7e:	8526                	mv	a0,s1
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	2e6080e7          	jalr	742(ra) # 80002066 <sleep>
  while(ticks - ticks0 < n){
    80002d88:	409c                	lw	a5,0(s1)
    80002d8a:	412787bb          	subw	a5,a5,s2
    80002d8e:	fcc42703          	lw	a4,-52(s0)
    80002d92:	fce7efe3          	bltu	a5,a4,80002d70 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d96:	00014517          	auipc	a0,0x14
    80002d9a:	73a50513          	addi	a0,a0,1850 # 800174d0 <tickslock>
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	ee6080e7          	jalr	-282(ra) # 80000c84 <release>
  return 0;
    80002da6:	4781                	li	a5,0
}
    80002da8:	853e                	mv	a0,a5
    80002daa:	70e2                	ld	ra,56(sp)
    80002dac:	7442                	ld	s0,48(sp)
    80002dae:	74a2                	ld	s1,40(sp)
    80002db0:	7902                	ld	s2,32(sp)
    80002db2:	69e2                	ld	s3,24(sp)
    80002db4:	6121                	addi	sp,sp,64
    80002db6:	8082                	ret
      release(&tickslock);
    80002db8:	00014517          	auipc	a0,0x14
    80002dbc:	71850513          	addi	a0,a0,1816 # 800174d0 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	ec4080e7          	jalr	-316(ra) # 80000c84 <release>
      return -1;
    80002dc8:	57fd                	li	a5,-1
    80002dca:	bff9                	j	80002da8 <sys_sleep+0x88>

0000000080002dcc <sys_kill>:

uint64
sys_kill(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dd4:	fec40593          	addi	a1,s0,-20
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	d76080e7          	jalr	-650(ra) # 80002b50 <argint>
    80002de2:	87aa                	mv	a5,a0
    return -1;
    80002de4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002de6:	0007c863          	bltz	a5,80002df6 <sys_kill+0x2a>
  return kill(pid);
    80002dea:	fec42503          	lw	a0,-20(s0)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	5aa080e7          	jalr	1450(ra) # 80002398 <kill>
}
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	6c850513          	addi	a0,a0,1736 # 800174d0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	dc0080e7          	jalr	-576(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002e18:	00006497          	auipc	s1,0x6
    80002e1c:	2184a483          	lw	s1,536(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e20:	00014517          	auipc	a0,0x14
    80002e24:	6b050513          	addi	a0,a0,1712 # 800174d0 <tickslock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e5c080e7          	jalr	-420(ra) # 80000c84 <release>
  return xticks;
}
    80002e30:	02049513          	slli	a0,s1,0x20
    80002e34:	9101                	srli	a0,a0,0x20
    80002e36:	60e2                	ld	ra,24(sp)
    80002e38:	6442                	ld	s0,16(sp)
    80002e3a:	64a2                	ld	s1,8(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret

0000000080002e40 <sys_getsyscallinfo>:

uint64
sys_getsyscallinfo(void)
{
    80002e40:	1141                	addi	sp,sp,-16
    80002e42:	e422                	sd	s0,8(sp)
    80002e44:	0800                	addi	s0,sp,16
   return count_syscall;
}
    80002e46:	00006517          	auipc	a0,0x6
    80002e4a:	1f253503          	ld	a0,498(a0) # 80009038 <count_syscall>
    80002e4e:	6422                	ld	s0,8(sp)
    80002e50:	0141                	addi	sp,sp,16
    80002e52:	8082                	ret

0000000080002e54 <sys_cps>:

uint64
sys_cps(void)
{
    80002e54:	1141                	addi	sp,sp,-16
    80002e56:	e406                	sd	ra,8(sp)
    80002e58:	e022                	sd	s0,0(sp)
    80002e5a:	0800                	addi	s0,sp,16
	return cps();
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	70a080e7          	jalr	1802(ra) # 80002566 <cps>
}
    80002e64:	60a2                	ld	ra,8(sp)
    80002e66:	6402                	ld	s0,0(sp)
    80002e68:	0141                	addi	sp,sp,16
    80002e6a:	8082                	ret

0000000080002e6c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e6c:	7179                	addi	sp,sp,-48
    80002e6e:	f406                	sd	ra,40(sp)
    80002e70:	f022                	sd	s0,32(sp)
    80002e72:	ec26                	sd	s1,24(sp)
    80002e74:	e84a                	sd	s2,16(sp)
    80002e76:	e44e                	sd	s3,8(sp)
    80002e78:	e052                	sd	s4,0(sp)
    80002e7a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e7c:	00005597          	auipc	a1,0x5
    80002e80:	70458593          	addi	a1,a1,1796 # 80008580 <syscalls+0xc0>
    80002e84:	00014517          	auipc	a0,0x14
    80002e88:	66450513          	addi	a0,a0,1636 # 800174e8 <bcache>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	cb4080e7          	jalr	-844(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e94:	0001c797          	auipc	a5,0x1c
    80002e98:	65478793          	addi	a5,a5,1620 # 8001f4e8 <bcache+0x8000>
    80002e9c:	0001d717          	auipc	a4,0x1d
    80002ea0:	8b470713          	addi	a4,a4,-1868 # 8001f750 <bcache+0x8268>
    80002ea4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ea8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eac:	00014497          	auipc	s1,0x14
    80002eb0:	65448493          	addi	s1,s1,1620 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eb6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eb8:	00005a17          	auipc	s4,0x5
    80002ebc:	6d0a0a13          	addi	s4,s4,1744 # 80008588 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ec0:	2b893783          	ld	a5,696(s2)
    80002ec4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ec6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eca:	85d2                	mv	a1,s4
    80002ecc:	01048513          	addi	a0,s1,16
    80002ed0:	00001097          	auipc	ra,0x1
    80002ed4:	4c2080e7          	jalr	1218(ra) # 80004392 <initsleeplock>
    bcache.head.next->prev = b;
    80002ed8:	2b893783          	ld	a5,696(s2)
    80002edc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ede:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee2:	45848493          	addi	s1,s1,1112
    80002ee6:	fd349de3          	bne	s1,s3,80002ec0 <binit+0x54>
  }
}
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6a02                	ld	s4,0(sp)
    80002ef6:	6145                	addi	sp,sp,48
    80002ef8:	8082                	ret

0000000080002efa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002efa:	7179                	addi	sp,sp,-48
    80002efc:	f406                	sd	ra,40(sp)
    80002efe:	f022                	sd	s0,32(sp)
    80002f00:	ec26                	sd	s1,24(sp)
    80002f02:	e84a                	sd	s2,16(sp)
    80002f04:	e44e                	sd	s3,8(sp)
    80002f06:	1800                	addi	s0,sp,48
    80002f08:	892a                	mv	s2,a0
    80002f0a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	5dc50513          	addi	a0,a0,1500 # 800174e8 <bcache>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	cbc080e7          	jalr	-836(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f1c:	0001d497          	auipc	s1,0x1d
    80002f20:	8844b483          	ld	s1,-1916(s1) # 8001f7a0 <bcache+0x82b8>
    80002f24:	0001d797          	auipc	a5,0x1d
    80002f28:	82c78793          	addi	a5,a5,-2004 # 8001f750 <bcache+0x8268>
    80002f2c:	02f48f63          	beq	s1,a5,80002f6a <bread+0x70>
    80002f30:	873e                	mv	a4,a5
    80002f32:	a021                	j	80002f3a <bread+0x40>
    80002f34:	68a4                	ld	s1,80(s1)
    80002f36:	02e48a63          	beq	s1,a4,80002f6a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f3a:	449c                	lw	a5,8(s1)
    80002f3c:	ff279ce3          	bne	a5,s2,80002f34 <bread+0x3a>
    80002f40:	44dc                	lw	a5,12(s1)
    80002f42:	ff3799e3          	bne	a5,s3,80002f34 <bread+0x3a>
      b->refcnt++;
    80002f46:	40bc                	lw	a5,64(s1)
    80002f48:	2785                	addiw	a5,a5,1
    80002f4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	59c50513          	addi	a0,a0,1436 # 800174e8 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d30080e7          	jalr	-720(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f5c:	01048513          	addi	a0,s1,16
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	46c080e7          	jalr	1132(ra) # 800043cc <acquiresleep>
      return b;
    80002f68:	a8b9                	j	80002fc6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6a:	0001d497          	auipc	s1,0x1d
    80002f6e:	82e4b483          	ld	s1,-2002(s1) # 8001f798 <bcache+0x82b0>
    80002f72:	0001c797          	auipc	a5,0x1c
    80002f76:	7de78793          	addi	a5,a5,2014 # 8001f750 <bcache+0x8268>
    80002f7a:	00f48863          	beq	s1,a5,80002f8a <bread+0x90>
    80002f7e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f80:	40bc                	lw	a5,64(s1)
    80002f82:	cf81                	beqz	a5,80002f9a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f84:	64a4                	ld	s1,72(s1)
    80002f86:	fee49de3          	bne	s1,a4,80002f80 <bread+0x86>
  panic("bget: no buffers");
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	60650513          	addi	a0,a0,1542 # 80008590 <syscalls+0xd0>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5a8080e7          	jalr	1448(ra) # 8000053a <panic>
      b->dev = dev;
    80002f9a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f9e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fa2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fa6:	4785                	li	a5,1
    80002fa8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	53e50513          	addi	a0,a0,1342 # 800174e8 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	cd2080e7          	jalr	-814(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002fba:	01048513          	addi	a0,s1,16
    80002fbe:	00001097          	auipc	ra,0x1
    80002fc2:	40e080e7          	jalr	1038(ra) # 800043cc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fc6:	409c                	lw	a5,0(s1)
    80002fc8:	cb89                	beqz	a5,80002fda <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fca:	8526                	mv	a0,s1
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6942                	ld	s2,16(sp)
    80002fd4:	69a2                	ld	s3,8(sp)
    80002fd6:	6145                	addi	sp,sp,48
    80002fd8:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fda:	4581                	li	a1,0
    80002fdc:	8526                	mv	a0,s1
    80002fde:	00003097          	auipc	ra,0x3
    80002fe2:	f24080e7          	jalr	-220(ra) # 80005f02 <virtio_disk_rw>
    b->valid = 1;
    80002fe6:	4785                	li	a5,1
    80002fe8:	c09c                	sw	a5,0(s1)
  return b;
    80002fea:	b7c5                	j	80002fca <bread+0xd0>

0000000080002fec <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	1000                	addi	s0,sp,32
    80002ff6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ff8:	0541                	addi	a0,a0,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	46c080e7          	jalr	1132(ra) # 80004466 <holdingsleep>
    80003002:	cd01                	beqz	a0,8000301a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003004:	4585                	li	a1,1
    80003006:	8526                	mv	a0,s1
    80003008:	00003097          	auipc	ra,0x3
    8000300c:	efa080e7          	jalr	-262(ra) # 80005f02 <virtio_disk_rw>
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret
    panic("bwrite");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	58e50513          	addi	a0,a0,1422 # 800085a8 <syscalls+0xe8>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	518080e7          	jalr	1304(ra) # 8000053a <panic>

000000008000302a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	e04a                	sd	s2,0(sp)
    80003034:	1000                	addi	s0,sp,32
    80003036:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003038:	01050913          	addi	s2,a0,16
    8000303c:	854a                	mv	a0,s2
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	428080e7          	jalr	1064(ra) # 80004466 <holdingsleep>
    80003046:	c92d                	beqz	a0,800030b8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003048:	854a                	mv	a0,s2
    8000304a:	00001097          	auipc	ra,0x1
    8000304e:	3d8080e7          	jalr	984(ra) # 80004422 <releasesleep>

  acquire(&bcache.lock);
    80003052:	00014517          	auipc	a0,0x14
    80003056:	49650513          	addi	a0,a0,1174 # 800174e8 <bcache>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	b76080e7          	jalr	-1162(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	37fd                	addiw	a5,a5,-1
    80003066:	0007871b          	sext.w	a4,a5
    8000306a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000306c:	eb05                	bnez	a4,8000309c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000306e:	68bc                	ld	a5,80(s1)
    80003070:	64b8                	ld	a4,72(s1)
    80003072:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003074:	64bc                	ld	a5,72(s1)
    80003076:	68b8                	ld	a4,80(s1)
    80003078:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000307a:	0001c797          	auipc	a5,0x1c
    8000307e:	46e78793          	addi	a5,a5,1134 # 8001f4e8 <bcache+0x8000>
    80003082:	2b87b703          	ld	a4,696(a5)
    80003086:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003088:	0001c717          	auipc	a4,0x1c
    8000308c:	6c870713          	addi	a4,a4,1736 # 8001f750 <bcache+0x8268>
    80003090:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003092:	2b87b703          	ld	a4,696(a5)
    80003096:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003098:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000309c:	00014517          	auipc	a0,0x14
    800030a0:	44c50513          	addi	a0,a0,1100 # 800174e8 <bcache>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	be0080e7          	jalr	-1056(ra) # 80000c84 <release>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6902                	ld	s2,0(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret
    panic("brelse");
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	4f850513          	addi	a0,a0,1272 # 800085b0 <syscalls+0xf0>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	47a080e7          	jalr	1146(ra) # 8000053a <panic>

00000000800030c8 <bpin>:

void
bpin(struct buf *b) {
    800030c8:	1101                	addi	sp,sp,-32
    800030ca:	ec06                	sd	ra,24(sp)
    800030cc:	e822                	sd	s0,16(sp)
    800030ce:	e426                	sd	s1,8(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	41450513          	addi	a0,a0,1044 # 800174e8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	af4080e7          	jalr	-1292(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800030e4:	40bc                	lw	a5,64(s1)
    800030e6:	2785                	addiw	a5,a5,1
    800030e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	3fe50513          	addi	a0,a0,1022 # 800174e8 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	b92080e7          	jalr	-1134(ra) # 80000c84 <release>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	64a2                	ld	s1,8(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret

0000000080003104 <bunpin>:

void
bunpin(struct buf *b) {
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	1000                	addi	s0,sp,32
    8000310e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	3d850513          	addi	a0,a0,984 # 800174e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	ab8080e7          	jalr	-1352(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003120:	40bc                	lw	a5,64(s1)
    80003122:	37fd                	addiw	a5,a5,-1
    80003124:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	3c250513          	addi	a0,a0,962 # 800174e8 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	b56080e7          	jalr	-1194(ra) # 80000c84 <release>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	e04a                	sd	s2,0(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000314e:	00d5d59b          	srliw	a1,a1,0xd
    80003152:	0001d797          	auipc	a5,0x1d
    80003156:	a727a783          	lw	a5,-1422(a5) # 8001fbc4 <sb+0x1c>
    8000315a:	9dbd                	addw	a1,a1,a5
    8000315c:	00000097          	auipc	ra,0x0
    80003160:	d9e080e7          	jalr	-610(ra) # 80002efa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003164:	0074f713          	andi	a4,s1,7
    80003168:	4785                	li	a5,1
    8000316a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000316e:	14ce                	slli	s1,s1,0x33
    80003170:	90d9                	srli	s1,s1,0x36
    80003172:	00950733          	add	a4,a0,s1
    80003176:	05874703          	lbu	a4,88(a4)
    8000317a:	00e7f6b3          	and	a3,a5,a4
    8000317e:	c69d                	beqz	a3,800031ac <bfree+0x6c>
    80003180:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003182:	94aa                	add	s1,s1,a0
    80003184:	fff7c793          	not	a5,a5
    80003188:	8f7d                	and	a4,a4,a5
    8000318a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	120080e7          	jalr	288(ra) # 800042ae <log_write>
  brelse(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	e92080e7          	jalr	-366(ra) # 8000302a <brelse>
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6902                	ld	s2,0(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret
    panic("freeing free block");
    800031ac:	00005517          	auipc	a0,0x5
    800031b0:	40c50513          	addi	a0,a0,1036 # 800085b8 <syscalls+0xf8>
    800031b4:	ffffd097          	auipc	ra,0xffffd
    800031b8:	386080e7          	jalr	902(ra) # 8000053a <panic>

00000000800031bc <balloc>:
{
    800031bc:	711d                	addi	sp,sp,-96
    800031be:	ec86                	sd	ra,88(sp)
    800031c0:	e8a2                	sd	s0,80(sp)
    800031c2:	e4a6                	sd	s1,72(sp)
    800031c4:	e0ca                	sd	s2,64(sp)
    800031c6:	fc4e                	sd	s3,56(sp)
    800031c8:	f852                	sd	s4,48(sp)
    800031ca:	f456                	sd	s5,40(sp)
    800031cc:	f05a                	sd	s6,32(sp)
    800031ce:	ec5e                	sd	s7,24(sp)
    800031d0:	e862                	sd	s8,16(sp)
    800031d2:	e466                	sd	s9,8(sp)
    800031d4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031d6:	0001d797          	auipc	a5,0x1d
    800031da:	9d67a783          	lw	a5,-1578(a5) # 8001fbac <sb+0x4>
    800031de:	cbc1                	beqz	a5,8000326e <balloc+0xb2>
    800031e0:	8baa                	mv	s7,a0
    800031e2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e4:	0001db17          	auipc	s6,0x1d
    800031e8:	9c4b0b13          	addi	s6,s6,-1596 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031ee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f2:	6c89                	lui	s9,0x2
    800031f4:	a831                	j	80003210 <balloc+0x54>
    brelse(bp);
    800031f6:	854a                	mv	a0,s2
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	e32080e7          	jalr	-462(ra) # 8000302a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003200:	015c87bb          	addw	a5,s9,s5
    80003204:	00078a9b          	sext.w	s5,a5
    80003208:	004b2703          	lw	a4,4(s6)
    8000320c:	06eaf163          	bgeu	s5,a4,8000326e <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003210:	41fad79b          	sraiw	a5,s5,0x1f
    80003214:	0137d79b          	srliw	a5,a5,0x13
    80003218:	015787bb          	addw	a5,a5,s5
    8000321c:	40d7d79b          	sraiw	a5,a5,0xd
    80003220:	01cb2583          	lw	a1,28(s6)
    80003224:	9dbd                	addw	a1,a1,a5
    80003226:	855e                	mv	a0,s7
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	cd2080e7          	jalr	-814(ra) # 80002efa <bread>
    80003230:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003232:	004b2503          	lw	a0,4(s6)
    80003236:	000a849b          	sext.w	s1,s5
    8000323a:	8762                	mv	a4,s8
    8000323c:	faa4fde3          	bgeu	s1,a0,800031f6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003240:	00777693          	andi	a3,a4,7
    80003244:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003248:	41f7579b          	sraiw	a5,a4,0x1f
    8000324c:	01d7d79b          	srliw	a5,a5,0x1d
    80003250:	9fb9                	addw	a5,a5,a4
    80003252:	4037d79b          	sraiw	a5,a5,0x3
    80003256:	00f90633          	add	a2,s2,a5
    8000325a:	05864603          	lbu	a2,88(a2)
    8000325e:	00c6f5b3          	and	a1,a3,a2
    80003262:	cd91                	beqz	a1,8000327e <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003264:	2705                	addiw	a4,a4,1
    80003266:	2485                	addiw	s1,s1,1
    80003268:	fd471ae3          	bne	a4,s4,8000323c <balloc+0x80>
    8000326c:	b769                	j	800031f6 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	36250513          	addi	a0,a0,866 # 800085d0 <syscalls+0x110>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2c4080e7          	jalr	708(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000327e:	97ca                	add	a5,a5,s2
    80003280:	8e55                	or	a2,a2,a3
    80003282:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	026080e7          	jalr	38(ra) # 800042ae <log_write>
        brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	d98080e7          	jalr	-616(ra) # 8000302a <brelse>
  bp = bread(dev, bno);
    8000329a:	85a6                	mv	a1,s1
    8000329c:	855e                	mv	a0,s7
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	c5c080e7          	jalr	-932(ra) # 80002efa <bread>
    800032a6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a8:	40000613          	li	a2,1024
    800032ac:	4581                	li	a1,0
    800032ae:	05850513          	addi	a0,a0,88
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	a1a080e7          	jalr	-1510(ra) # 80000ccc <memset>
  log_write(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	ff2080e7          	jalr	-14(ra) # 800042ae <log_write>
  brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	d64080e7          	jalr	-668(ra) # 8000302a <brelse>
}
    800032ce:	8526                	mv	a0,s1
    800032d0:	60e6                	ld	ra,88(sp)
    800032d2:	6446                	ld	s0,80(sp)
    800032d4:	64a6                	ld	s1,72(sp)
    800032d6:	6906                	ld	s2,64(sp)
    800032d8:	79e2                	ld	s3,56(sp)
    800032da:	7a42                	ld	s4,48(sp)
    800032dc:	7aa2                	ld	s5,40(sp)
    800032de:	7b02                	ld	s6,32(sp)
    800032e0:	6be2                	ld	s7,24(sp)
    800032e2:	6c42                	ld	s8,16(sp)
    800032e4:	6ca2                	ld	s9,8(sp)
    800032e6:	6125                	addi	sp,sp,96
    800032e8:	8082                	ret

00000000800032ea <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032ea:	7179                	addi	sp,sp,-48
    800032ec:	f406                	sd	ra,40(sp)
    800032ee:	f022                	sd	s0,32(sp)
    800032f0:	ec26                	sd	s1,24(sp)
    800032f2:	e84a                	sd	s2,16(sp)
    800032f4:	e44e                	sd	s3,8(sp)
    800032f6:	e052                	sd	s4,0(sp)
    800032f8:	1800                	addi	s0,sp,48
    800032fa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032fc:	47ad                	li	a5,11
    800032fe:	04b7fe63          	bgeu	a5,a1,8000335a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003302:	ff45849b          	addiw	s1,a1,-12
    80003306:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000330a:	0ff00793          	li	a5,255
    8000330e:	0ae7e463          	bltu	a5,a4,800033b6 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003312:	08052583          	lw	a1,128(a0)
    80003316:	c5b5                	beqz	a1,80003382 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003318:	00092503          	lw	a0,0(s2)
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	bde080e7          	jalr	-1058(ra) # 80002efa <bread>
    80003324:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003326:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000332a:	02049713          	slli	a4,s1,0x20
    8000332e:	01e75593          	srli	a1,a4,0x1e
    80003332:	00b784b3          	add	s1,a5,a1
    80003336:	0004a983          	lw	s3,0(s1)
    8000333a:	04098e63          	beqz	s3,80003396 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000333e:	8552                	mv	a0,s4
    80003340:	00000097          	auipc	ra,0x0
    80003344:	cea080e7          	jalr	-790(ra) # 8000302a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003348:	854e                	mv	a0,s3
    8000334a:	70a2                	ld	ra,40(sp)
    8000334c:	7402                	ld	s0,32(sp)
    8000334e:	64e2                	ld	s1,24(sp)
    80003350:	6942                	ld	s2,16(sp)
    80003352:	69a2                	ld	s3,8(sp)
    80003354:	6a02                	ld	s4,0(sp)
    80003356:	6145                	addi	sp,sp,48
    80003358:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000335a:	02059793          	slli	a5,a1,0x20
    8000335e:	01e7d593          	srli	a1,a5,0x1e
    80003362:	00b504b3          	add	s1,a0,a1
    80003366:	0504a983          	lw	s3,80(s1)
    8000336a:	fc099fe3          	bnez	s3,80003348 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000336e:	4108                	lw	a0,0(a0)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e4c080e7          	jalr	-436(ra) # 800031bc <balloc>
    80003378:	0005099b          	sext.w	s3,a0
    8000337c:	0534a823          	sw	s3,80(s1)
    80003380:	b7e1                	j	80003348 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003382:	4108                	lw	a0,0(a0)
    80003384:	00000097          	auipc	ra,0x0
    80003388:	e38080e7          	jalr	-456(ra) # 800031bc <balloc>
    8000338c:	0005059b          	sext.w	a1,a0
    80003390:	08b92023          	sw	a1,128(s2)
    80003394:	b751                	j	80003318 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003396:	00092503          	lw	a0,0(s2)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e22080e7          	jalr	-478(ra) # 800031bc <balloc>
    800033a2:	0005099b          	sext.w	s3,a0
    800033a6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033aa:	8552                	mv	a0,s4
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	f02080e7          	jalr	-254(ra) # 800042ae <log_write>
    800033b4:	b769                	j	8000333e <bmap+0x54>
  panic("bmap: out of range");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	23250513          	addi	a0,a0,562 # 800085e8 <syscalls+0x128>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	17c080e7          	jalr	380(ra) # 8000053a <panic>

00000000800033c6 <iget>:
{
    800033c6:	7179                	addi	sp,sp,-48
    800033c8:	f406                	sd	ra,40(sp)
    800033ca:	f022                	sd	s0,32(sp)
    800033cc:	ec26                	sd	s1,24(sp)
    800033ce:	e84a                	sd	s2,16(sp)
    800033d0:	e44e                	sd	s3,8(sp)
    800033d2:	e052                	sd	s4,0(sp)
    800033d4:	1800                	addi	s0,sp,48
    800033d6:	89aa                	mv	s3,a0
    800033d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033da:	0001c517          	auipc	a0,0x1c
    800033de:	7ee50513          	addi	a0,a0,2030 # 8001fbc8 <itable>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	7ee080e7          	jalr	2030(ra) # 80000bd0 <acquire>
  empty = 0;
    800033ea:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ec:	0001c497          	auipc	s1,0x1c
    800033f0:	7f448493          	addi	s1,s1,2036 # 8001fbe0 <itable+0x18>
    800033f4:	0001e697          	auipc	a3,0x1e
    800033f8:	27c68693          	addi	a3,a3,636 # 80021670 <log>
    800033fc:	a039                	j	8000340a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033fe:	02090b63          	beqz	s2,80003434 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003402:	08848493          	addi	s1,s1,136
    80003406:	02d48a63          	beq	s1,a3,8000343a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000340a:	449c                	lw	a5,8(s1)
    8000340c:	fef059e3          	blez	a5,800033fe <iget+0x38>
    80003410:	4098                	lw	a4,0(s1)
    80003412:	ff3716e3          	bne	a4,s3,800033fe <iget+0x38>
    80003416:	40d8                	lw	a4,4(s1)
    80003418:	ff4713e3          	bne	a4,s4,800033fe <iget+0x38>
      ip->ref++;
    8000341c:	2785                	addiw	a5,a5,1
    8000341e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003420:	0001c517          	auipc	a0,0x1c
    80003424:	7a850513          	addi	a0,a0,1960 # 8001fbc8 <itable>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	85c080e7          	jalr	-1956(ra) # 80000c84 <release>
      return ip;
    80003430:	8926                	mv	s2,s1
    80003432:	a03d                	j	80003460 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003434:	f7f9                	bnez	a5,80003402 <iget+0x3c>
    80003436:	8926                	mv	s2,s1
    80003438:	b7e9                	j	80003402 <iget+0x3c>
  if(empty == 0)
    8000343a:	02090c63          	beqz	s2,80003472 <iget+0xac>
  ip->dev = dev;
    8000343e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003442:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003446:	4785                	li	a5,1
    80003448:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000344c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003450:	0001c517          	auipc	a0,0x1c
    80003454:	77850513          	addi	a0,a0,1912 # 8001fbc8 <itable>
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	82c080e7          	jalr	-2004(ra) # 80000c84 <release>
}
    80003460:	854a                	mv	a0,s2
    80003462:	70a2                	ld	ra,40(sp)
    80003464:	7402                	ld	s0,32(sp)
    80003466:	64e2                	ld	s1,24(sp)
    80003468:	6942                	ld	s2,16(sp)
    8000346a:	69a2                	ld	s3,8(sp)
    8000346c:	6a02                	ld	s4,0(sp)
    8000346e:	6145                	addi	sp,sp,48
    80003470:	8082                	ret
    panic("iget: no inodes");
    80003472:	00005517          	auipc	a0,0x5
    80003476:	18e50513          	addi	a0,a0,398 # 80008600 <syscalls+0x140>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	0c0080e7          	jalr	192(ra) # 8000053a <panic>

0000000080003482 <fsinit>:
fsinit(int dev) {
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	1800                	addi	s0,sp,48
    80003490:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003492:	4585                	li	a1,1
    80003494:	00000097          	auipc	ra,0x0
    80003498:	a66080e7          	jalr	-1434(ra) # 80002efa <bread>
    8000349c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000349e:	0001c997          	auipc	s3,0x1c
    800034a2:	70a98993          	addi	s3,s3,1802 # 8001fba8 <sb>
    800034a6:	02000613          	li	a2,32
    800034aa:	05850593          	addi	a1,a0,88
    800034ae:	854e                	mv	a0,s3
    800034b0:	ffffe097          	auipc	ra,0xffffe
    800034b4:	878080e7          	jalr	-1928(ra) # 80000d28 <memmove>
  brelse(bp);
    800034b8:	8526                	mv	a0,s1
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	b70080e7          	jalr	-1168(ra) # 8000302a <brelse>
  if(sb.magic != FSMAGIC)
    800034c2:	0009a703          	lw	a4,0(s3)
    800034c6:	102037b7          	lui	a5,0x10203
    800034ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034ce:	02f71263          	bne	a4,a5,800034f2 <fsinit+0x70>
  initlog(dev, &sb);
    800034d2:	0001c597          	auipc	a1,0x1c
    800034d6:	6d658593          	addi	a1,a1,1750 # 8001fba8 <sb>
    800034da:	854a                	mv	a0,s2
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	b56080e7          	jalr	-1194(ra) # 80004032 <initlog>
}
    800034e4:	70a2                	ld	ra,40(sp)
    800034e6:	7402                	ld	s0,32(sp)
    800034e8:	64e2                	ld	s1,24(sp)
    800034ea:	6942                	ld	s2,16(sp)
    800034ec:	69a2                	ld	s3,8(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    panic("invalid file system");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	11e50513          	addi	a0,a0,286 # 80008610 <syscalls+0x150>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	040080e7          	jalr	64(ra) # 8000053a <panic>

0000000080003502 <iinit>:
{
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003510:	00005597          	auipc	a1,0x5
    80003514:	11858593          	addi	a1,a1,280 # 80008628 <syscalls+0x168>
    80003518:	0001c517          	auipc	a0,0x1c
    8000351c:	6b050513          	addi	a0,a0,1712 # 8001fbc8 <itable>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	620080e7          	jalr	1568(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003528:	0001c497          	auipc	s1,0x1c
    8000352c:	6c848493          	addi	s1,s1,1736 # 8001fbf0 <itable+0x28>
    80003530:	0001e997          	auipc	s3,0x1e
    80003534:	15098993          	addi	s3,s3,336 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003538:	00005917          	auipc	s2,0x5
    8000353c:	0f890913          	addi	s2,s2,248 # 80008630 <syscalls+0x170>
    80003540:	85ca                	mv	a1,s2
    80003542:	8526                	mv	a0,s1
    80003544:	00001097          	auipc	ra,0x1
    80003548:	e4e080e7          	jalr	-434(ra) # 80004392 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000354c:	08848493          	addi	s1,s1,136
    80003550:	ff3498e3          	bne	s1,s3,80003540 <iinit+0x3e>
}
    80003554:	70a2                	ld	ra,40(sp)
    80003556:	7402                	ld	s0,32(sp)
    80003558:	64e2                	ld	s1,24(sp)
    8000355a:	6942                	ld	s2,16(sp)
    8000355c:	69a2                	ld	s3,8(sp)
    8000355e:	6145                	addi	sp,sp,48
    80003560:	8082                	ret

0000000080003562 <ialloc>:
{
    80003562:	715d                	addi	sp,sp,-80
    80003564:	e486                	sd	ra,72(sp)
    80003566:	e0a2                	sd	s0,64(sp)
    80003568:	fc26                	sd	s1,56(sp)
    8000356a:	f84a                	sd	s2,48(sp)
    8000356c:	f44e                	sd	s3,40(sp)
    8000356e:	f052                	sd	s4,32(sp)
    80003570:	ec56                	sd	s5,24(sp)
    80003572:	e85a                	sd	s6,16(sp)
    80003574:	e45e                	sd	s7,8(sp)
    80003576:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003578:	0001c717          	auipc	a4,0x1c
    8000357c:	63c72703          	lw	a4,1596(a4) # 8001fbb4 <sb+0xc>
    80003580:	4785                	li	a5,1
    80003582:	04e7fa63          	bgeu	a5,a4,800035d6 <ialloc+0x74>
    80003586:	8aaa                	mv	s5,a0
    80003588:	8bae                	mv	s7,a1
    8000358a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000358c:	0001ca17          	auipc	s4,0x1c
    80003590:	61ca0a13          	addi	s4,s4,1564 # 8001fba8 <sb>
    80003594:	00048b1b          	sext.w	s6,s1
    80003598:	0044d593          	srli	a1,s1,0x4
    8000359c:	018a2783          	lw	a5,24(s4)
    800035a0:	9dbd                	addw	a1,a1,a5
    800035a2:	8556                	mv	a0,s5
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	956080e7          	jalr	-1706(ra) # 80002efa <bread>
    800035ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ae:	05850993          	addi	s3,a0,88
    800035b2:	00f4f793          	andi	a5,s1,15
    800035b6:	079a                	slli	a5,a5,0x6
    800035b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ba:	00099783          	lh	a5,0(s3)
    800035be:	c785                	beqz	a5,800035e6 <ialloc+0x84>
    brelse(bp);
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	a6a080e7          	jalr	-1430(ra) # 8000302a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c8:	0485                	addi	s1,s1,1
    800035ca:	00ca2703          	lw	a4,12(s4)
    800035ce:	0004879b          	sext.w	a5,s1
    800035d2:	fce7e1e3          	bltu	a5,a4,80003594 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	06250513          	addi	a0,a0,98 # 80008638 <syscalls+0x178>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f5c080e7          	jalr	-164(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800035e6:	04000613          	li	a2,64
    800035ea:	4581                	li	a1,0
    800035ec:	854e                	mv	a0,s3
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	6de080e7          	jalr	1758(ra) # 80000ccc <memset>
      dip->type = type;
    800035f6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035fa:	854a                	mv	a0,s2
    800035fc:	00001097          	auipc	ra,0x1
    80003600:	cb2080e7          	jalr	-846(ra) # 800042ae <log_write>
      brelse(bp);
    80003604:	854a                	mv	a0,s2
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	a24080e7          	jalr	-1500(ra) # 8000302a <brelse>
      return iget(dev, inum);
    8000360e:	85da                	mv	a1,s6
    80003610:	8556                	mv	a0,s5
    80003612:	00000097          	auipc	ra,0x0
    80003616:	db4080e7          	jalr	-588(ra) # 800033c6 <iget>
}
    8000361a:	60a6                	ld	ra,72(sp)
    8000361c:	6406                	ld	s0,64(sp)
    8000361e:	74e2                	ld	s1,56(sp)
    80003620:	7942                	ld	s2,48(sp)
    80003622:	79a2                	ld	s3,40(sp)
    80003624:	7a02                	ld	s4,32(sp)
    80003626:	6ae2                	ld	s5,24(sp)
    80003628:	6b42                	ld	s6,16(sp)
    8000362a:	6ba2                	ld	s7,8(sp)
    8000362c:	6161                	addi	sp,sp,80
    8000362e:	8082                	ret

0000000080003630 <iupdate>:
{
    80003630:	1101                	addi	sp,sp,-32
    80003632:	ec06                	sd	ra,24(sp)
    80003634:	e822                	sd	s0,16(sp)
    80003636:	e426                	sd	s1,8(sp)
    80003638:	e04a                	sd	s2,0(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000363e:	415c                	lw	a5,4(a0)
    80003640:	0047d79b          	srliw	a5,a5,0x4
    80003644:	0001c597          	auipc	a1,0x1c
    80003648:	57c5a583          	lw	a1,1404(a1) # 8001fbc0 <sb+0x18>
    8000364c:	9dbd                	addw	a1,a1,a5
    8000364e:	4108                	lw	a0,0(a0)
    80003650:	00000097          	auipc	ra,0x0
    80003654:	8aa080e7          	jalr	-1878(ra) # 80002efa <bread>
    80003658:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000365a:	05850793          	addi	a5,a0,88
    8000365e:	40d8                	lw	a4,4(s1)
    80003660:	8b3d                	andi	a4,a4,15
    80003662:	071a                	slli	a4,a4,0x6
    80003664:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003666:	04449703          	lh	a4,68(s1)
    8000366a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000366e:	04649703          	lh	a4,70(s1)
    80003672:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003676:	04849703          	lh	a4,72(s1)
    8000367a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000367e:	04a49703          	lh	a4,74(s1)
    80003682:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003686:	44f8                	lw	a4,76(s1)
    80003688:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000368a:	03400613          	li	a2,52
    8000368e:	05048593          	addi	a1,s1,80
    80003692:	00c78513          	addi	a0,a5,12
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	692080e7          	jalr	1682(ra) # 80000d28 <memmove>
  log_write(bp);
    8000369e:	854a                	mv	a0,s2
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	c0e080e7          	jalr	-1010(ra) # 800042ae <log_write>
  brelse(bp);
    800036a8:	854a                	mv	a0,s2
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	980080e7          	jalr	-1664(ra) # 8000302a <brelse>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret

00000000800036be <idup>:
{
    800036be:	1101                	addi	sp,sp,-32
    800036c0:	ec06                	sd	ra,24(sp)
    800036c2:	e822                	sd	s0,16(sp)
    800036c4:	e426                	sd	s1,8(sp)
    800036c6:	1000                	addi	s0,sp,32
    800036c8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036ca:	0001c517          	auipc	a0,0x1c
    800036ce:	4fe50513          	addi	a0,a0,1278 # 8001fbc8 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	4fe080e7          	jalr	1278(ra) # 80000bd0 <acquire>
  ip->ref++;
    800036da:	449c                	lw	a5,8(s1)
    800036dc:	2785                	addiw	a5,a5,1
    800036de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036e0:	0001c517          	auipc	a0,0x1c
    800036e4:	4e850513          	addi	a0,a0,1256 # 8001fbc8 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	59c080e7          	jalr	1436(ra) # 80000c84 <release>
}
    800036f0:	8526                	mv	a0,s1
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6105                	addi	sp,sp,32
    800036fa:	8082                	ret

00000000800036fc <ilock>:
{
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	e04a                	sd	s2,0(sp)
    80003706:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003708:	c115                	beqz	a0,8000372c <ilock+0x30>
    8000370a:	84aa                	mv	s1,a0
    8000370c:	451c                	lw	a5,8(a0)
    8000370e:	00f05f63          	blez	a5,8000372c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003712:	0541                	addi	a0,a0,16
    80003714:	00001097          	auipc	ra,0x1
    80003718:	cb8080e7          	jalr	-840(ra) # 800043cc <acquiresleep>
  if(ip->valid == 0){
    8000371c:	40bc                	lw	a5,64(s1)
    8000371e:	cf99                	beqz	a5,8000373c <ilock+0x40>
}
    80003720:	60e2                	ld	ra,24(sp)
    80003722:	6442                	ld	s0,16(sp)
    80003724:	64a2                	ld	s1,8(sp)
    80003726:	6902                	ld	s2,0(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret
    panic("ilock");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	f2450513          	addi	a0,a0,-220 # 80008650 <syscalls+0x190>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e06080e7          	jalr	-506(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000373c:	40dc                	lw	a5,4(s1)
    8000373e:	0047d79b          	srliw	a5,a5,0x4
    80003742:	0001c597          	auipc	a1,0x1c
    80003746:	47e5a583          	lw	a1,1150(a1) # 8001fbc0 <sb+0x18>
    8000374a:	9dbd                	addw	a1,a1,a5
    8000374c:	4088                	lw	a0,0(s1)
    8000374e:	fffff097          	auipc	ra,0xfffff
    80003752:	7ac080e7          	jalr	1964(ra) # 80002efa <bread>
    80003756:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003758:	05850593          	addi	a1,a0,88
    8000375c:	40dc                	lw	a5,4(s1)
    8000375e:	8bbd                	andi	a5,a5,15
    80003760:	079a                	slli	a5,a5,0x6
    80003762:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003764:	00059783          	lh	a5,0(a1)
    80003768:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000376c:	00259783          	lh	a5,2(a1)
    80003770:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003774:	00459783          	lh	a5,4(a1)
    80003778:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000377c:	00659783          	lh	a5,6(a1)
    80003780:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003784:	459c                	lw	a5,8(a1)
    80003786:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003788:	03400613          	li	a2,52
    8000378c:	05b1                	addi	a1,a1,12
    8000378e:	05048513          	addi	a0,s1,80
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	596080e7          	jalr	1430(ra) # 80000d28 <memmove>
    brelse(bp);
    8000379a:	854a                	mv	a0,s2
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	88e080e7          	jalr	-1906(ra) # 8000302a <brelse>
    ip->valid = 1;
    800037a4:	4785                	li	a5,1
    800037a6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037a8:	04449783          	lh	a5,68(s1)
    800037ac:	fbb5                	bnez	a5,80003720 <ilock+0x24>
      panic("ilock: no type");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	eaa50513          	addi	a0,a0,-342 # 80008658 <syscalls+0x198>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d84080e7          	jalr	-636(ra) # 8000053a <panic>

00000000800037be <iunlock>:
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037ca:	c905                	beqz	a0,800037fa <iunlock+0x3c>
    800037cc:	84aa                	mv	s1,a0
    800037ce:	01050913          	addi	s2,a0,16
    800037d2:	854a                	mv	a0,s2
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	c92080e7          	jalr	-878(ra) # 80004466 <holdingsleep>
    800037dc:	cd19                	beqz	a0,800037fa <iunlock+0x3c>
    800037de:	449c                	lw	a5,8(s1)
    800037e0:	00f05d63          	blez	a5,800037fa <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	c3c080e7          	jalr	-964(ra) # 80004422 <releasesleep>
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6902                	ld	s2,0(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret
    panic("iunlock");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	e6e50513          	addi	a0,a0,-402 # 80008668 <syscalls+0x1a8>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d38080e7          	jalr	-712(ra) # 8000053a <panic>

000000008000380a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000380a:	7179                	addi	sp,sp,-48
    8000380c:	f406                	sd	ra,40(sp)
    8000380e:	f022                	sd	s0,32(sp)
    80003810:	ec26                	sd	s1,24(sp)
    80003812:	e84a                	sd	s2,16(sp)
    80003814:	e44e                	sd	s3,8(sp)
    80003816:	e052                	sd	s4,0(sp)
    80003818:	1800                	addi	s0,sp,48
    8000381a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000381c:	05050493          	addi	s1,a0,80
    80003820:	08050913          	addi	s2,a0,128
    80003824:	a021                	j	8000382c <itrunc+0x22>
    80003826:	0491                	addi	s1,s1,4
    80003828:	01248d63          	beq	s1,s2,80003842 <itrunc+0x38>
    if(ip->addrs[i]){
    8000382c:	408c                	lw	a1,0(s1)
    8000382e:	dde5                	beqz	a1,80003826 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003830:	0009a503          	lw	a0,0(s3)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	90c080e7          	jalr	-1780(ra) # 80003140 <bfree>
      ip->addrs[i] = 0;
    8000383c:	0004a023          	sw	zero,0(s1)
    80003840:	b7dd                	j	80003826 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003842:	0809a583          	lw	a1,128(s3)
    80003846:	e185                	bnez	a1,80003866 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003848:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000384c:	854e                	mv	a0,s3
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	de2080e7          	jalr	-542(ra) # 80003630 <iupdate>
}
    80003856:	70a2                	ld	ra,40(sp)
    80003858:	7402                	ld	s0,32(sp)
    8000385a:	64e2                	ld	s1,24(sp)
    8000385c:	6942                	ld	s2,16(sp)
    8000385e:	69a2                	ld	s3,8(sp)
    80003860:	6a02                	ld	s4,0(sp)
    80003862:	6145                	addi	sp,sp,48
    80003864:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003866:	0009a503          	lw	a0,0(s3)
    8000386a:	fffff097          	auipc	ra,0xfffff
    8000386e:	690080e7          	jalr	1680(ra) # 80002efa <bread>
    80003872:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003874:	05850493          	addi	s1,a0,88
    80003878:	45850913          	addi	s2,a0,1112
    8000387c:	a021                	j	80003884 <itrunc+0x7a>
    8000387e:	0491                	addi	s1,s1,4
    80003880:	01248b63          	beq	s1,s2,80003896 <itrunc+0x8c>
      if(a[j])
    80003884:	408c                	lw	a1,0(s1)
    80003886:	dde5                	beqz	a1,8000387e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003888:	0009a503          	lw	a0,0(s3)
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	8b4080e7          	jalr	-1868(ra) # 80003140 <bfree>
    80003894:	b7ed                	j	8000387e <itrunc+0x74>
    brelse(bp);
    80003896:	8552                	mv	a0,s4
    80003898:	fffff097          	auipc	ra,0xfffff
    8000389c:	792080e7          	jalr	1938(ra) # 8000302a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038a0:	0809a583          	lw	a1,128(s3)
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	898080e7          	jalr	-1896(ra) # 80003140 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038b0:	0809a023          	sw	zero,128(s3)
    800038b4:	bf51                	j	80003848 <itrunc+0x3e>

00000000800038b6 <iput>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038c4:	0001c517          	auipc	a0,0x1c
    800038c8:	30450513          	addi	a0,a0,772 # 8001fbc8 <itable>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	304080e7          	jalr	772(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038d4:	4498                	lw	a4,8(s1)
    800038d6:	4785                	li	a5,1
    800038d8:	02f70363          	beq	a4,a5,800038fe <iput+0x48>
  ip->ref--;
    800038dc:	449c                	lw	a5,8(s1)
    800038de:	37fd                	addiw	a5,a5,-1
    800038e0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e2:	0001c517          	auipc	a0,0x1c
    800038e6:	2e650513          	addi	a0,a0,742 # 8001fbc8 <itable>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	39a080e7          	jalr	922(ra) # 80000c84 <release>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6902                	ld	s2,0(sp)
    800038fa:	6105                	addi	sp,sp,32
    800038fc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fe:	40bc                	lw	a5,64(s1)
    80003900:	dff1                	beqz	a5,800038dc <iput+0x26>
    80003902:	04a49783          	lh	a5,74(s1)
    80003906:	fbf9                	bnez	a5,800038dc <iput+0x26>
    acquiresleep(&ip->lock);
    80003908:	01048913          	addi	s2,s1,16
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	abe080e7          	jalr	-1346(ra) # 800043cc <acquiresleep>
    release(&itable.lock);
    80003916:	0001c517          	auipc	a0,0x1c
    8000391a:	2b250513          	addi	a0,a0,690 # 8001fbc8 <itable>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	366080e7          	jalr	870(ra) # 80000c84 <release>
    itrunc(ip);
    80003926:	8526                	mv	a0,s1
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	ee2080e7          	jalr	-286(ra) # 8000380a <itrunc>
    ip->type = 0;
    80003930:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003934:	8526                	mv	a0,s1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	cfa080e7          	jalr	-774(ra) # 80003630 <iupdate>
    ip->valid = 0;
    8000393e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003942:	854a                	mv	a0,s2
    80003944:	00001097          	auipc	ra,0x1
    80003948:	ade080e7          	jalr	-1314(ra) # 80004422 <releasesleep>
    acquire(&itable.lock);
    8000394c:	0001c517          	auipc	a0,0x1c
    80003950:	27c50513          	addi	a0,a0,636 # 8001fbc8 <itable>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	27c080e7          	jalr	636(ra) # 80000bd0 <acquire>
    8000395c:	b741                	j	800038dc <iput+0x26>

000000008000395e <iunlockput>:
{
    8000395e:	1101                	addi	sp,sp,-32
    80003960:	ec06                	sd	ra,24(sp)
    80003962:	e822                	sd	s0,16(sp)
    80003964:	e426                	sd	s1,8(sp)
    80003966:	1000                	addi	s0,sp,32
    80003968:	84aa                	mv	s1,a0
  iunlock(ip);
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	e54080e7          	jalr	-428(ra) # 800037be <iunlock>
  iput(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	f42080e7          	jalr	-190(ra) # 800038b6 <iput>
}
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret

0000000080003986 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003986:	1141                	addi	sp,sp,-16
    80003988:	e422                	sd	s0,8(sp)
    8000398a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000398c:	411c                	lw	a5,0(a0)
    8000398e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003990:	415c                	lw	a5,4(a0)
    80003992:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003994:	04451783          	lh	a5,68(a0)
    80003998:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000399c:	04a51783          	lh	a5,74(a0)
    800039a0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039a4:	04c56783          	lwu	a5,76(a0)
    800039a8:	e99c                	sd	a5,16(a1)
}
    800039aa:	6422                	ld	s0,8(sp)
    800039ac:	0141                	addi	sp,sp,16
    800039ae:	8082                	ret

00000000800039b0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039b0:	457c                	lw	a5,76(a0)
    800039b2:	0ed7e963          	bltu	a5,a3,80003aa4 <readi+0xf4>
{
    800039b6:	7159                	addi	sp,sp,-112
    800039b8:	f486                	sd	ra,104(sp)
    800039ba:	f0a2                	sd	s0,96(sp)
    800039bc:	eca6                	sd	s1,88(sp)
    800039be:	e8ca                	sd	s2,80(sp)
    800039c0:	e4ce                	sd	s3,72(sp)
    800039c2:	e0d2                	sd	s4,64(sp)
    800039c4:	fc56                	sd	s5,56(sp)
    800039c6:	f85a                	sd	s6,48(sp)
    800039c8:	f45e                	sd	s7,40(sp)
    800039ca:	f062                	sd	s8,32(sp)
    800039cc:	ec66                	sd	s9,24(sp)
    800039ce:	e86a                	sd	s10,16(sp)
    800039d0:	e46e                	sd	s11,8(sp)
    800039d2:	1880                	addi	s0,sp,112
    800039d4:	8baa                	mv	s7,a0
    800039d6:	8c2e                	mv	s8,a1
    800039d8:	8ab2                	mv	s5,a2
    800039da:	84b6                	mv	s1,a3
    800039dc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039de:	9f35                	addw	a4,a4,a3
    return 0;
    800039e0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039e2:	0ad76063          	bltu	a4,a3,80003a82 <readi+0xd2>
  if(off + n > ip->size)
    800039e6:	00e7f463          	bgeu	a5,a4,800039ee <readi+0x3e>
    n = ip->size - off;
    800039ea:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ee:	0a0b0963          	beqz	s6,80003aa0 <readi+0xf0>
    800039f2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039f8:	5cfd                	li	s9,-1
    800039fa:	a82d                	j	80003a34 <readi+0x84>
    800039fc:	020a1d93          	slli	s11,s4,0x20
    80003a00:	020ddd93          	srli	s11,s11,0x20
    80003a04:	05890613          	addi	a2,s2,88
    80003a08:	86ee                	mv	a3,s11
    80003a0a:	963a                	add	a2,a2,a4
    80003a0c:	85d6                	mv	a1,s5
    80003a0e:	8562                	mv	a0,s8
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	9fa080e7          	jalr	-1542(ra) # 8000240a <either_copyout>
    80003a18:	05950d63          	beq	a0,s9,80003a72 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	fffff097          	auipc	ra,0xfffff
    80003a22:	60c080e7          	jalr	1548(ra) # 8000302a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a26:	013a09bb          	addw	s3,s4,s3
    80003a2a:	009a04bb          	addw	s1,s4,s1
    80003a2e:	9aee                	add	s5,s5,s11
    80003a30:	0569f763          	bgeu	s3,s6,80003a7e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a34:	000ba903          	lw	s2,0(s7)
    80003a38:	00a4d59b          	srliw	a1,s1,0xa
    80003a3c:	855e                	mv	a0,s7
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	8ac080e7          	jalr	-1876(ra) # 800032ea <bmap>
    80003a46:	0005059b          	sext.w	a1,a0
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	4ae080e7          	jalr	1198(ra) # 80002efa <bread>
    80003a54:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a56:	3ff4f713          	andi	a4,s1,1023
    80003a5a:	40ed07bb          	subw	a5,s10,a4
    80003a5e:	413b06bb          	subw	a3,s6,s3
    80003a62:	8a3e                	mv	s4,a5
    80003a64:	2781                	sext.w	a5,a5
    80003a66:	0006861b          	sext.w	a2,a3
    80003a6a:	f8f679e3          	bgeu	a2,a5,800039fc <readi+0x4c>
    80003a6e:	8a36                	mv	s4,a3
    80003a70:	b771                	j	800039fc <readi+0x4c>
      brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	fffff097          	auipc	ra,0xfffff
    80003a78:	5b6080e7          	jalr	1462(ra) # 8000302a <brelse>
      tot = -1;
    80003a7c:	59fd                	li	s3,-1
  }
  return tot;
    80003a7e:	0009851b          	sext.w	a0,s3
}
    80003a82:	70a6                	ld	ra,104(sp)
    80003a84:	7406                	ld	s0,96(sp)
    80003a86:	64e6                	ld	s1,88(sp)
    80003a88:	6946                	ld	s2,80(sp)
    80003a8a:	69a6                	ld	s3,72(sp)
    80003a8c:	6a06                	ld	s4,64(sp)
    80003a8e:	7ae2                	ld	s5,56(sp)
    80003a90:	7b42                	ld	s6,48(sp)
    80003a92:	7ba2                	ld	s7,40(sp)
    80003a94:	7c02                	ld	s8,32(sp)
    80003a96:	6ce2                	ld	s9,24(sp)
    80003a98:	6d42                	ld	s10,16(sp)
    80003a9a:	6da2                	ld	s11,8(sp)
    80003a9c:	6165                	addi	sp,sp,112
    80003a9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa0:	89da                	mv	s3,s6
    80003aa2:	bff1                	j	80003a7e <readi+0xce>
    return 0;
    80003aa4:	4501                	li	a0,0
}
    80003aa6:	8082                	ret

0000000080003aa8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aa8:	457c                	lw	a5,76(a0)
    80003aaa:	10d7e863          	bltu	a5,a3,80003bba <writei+0x112>
{
    80003aae:	7159                	addi	sp,sp,-112
    80003ab0:	f486                	sd	ra,104(sp)
    80003ab2:	f0a2                	sd	s0,96(sp)
    80003ab4:	eca6                	sd	s1,88(sp)
    80003ab6:	e8ca                	sd	s2,80(sp)
    80003ab8:	e4ce                	sd	s3,72(sp)
    80003aba:	e0d2                	sd	s4,64(sp)
    80003abc:	fc56                	sd	s5,56(sp)
    80003abe:	f85a                	sd	s6,48(sp)
    80003ac0:	f45e                	sd	s7,40(sp)
    80003ac2:	f062                	sd	s8,32(sp)
    80003ac4:	ec66                	sd	s9,24(sp)
    80003ac6:	e86a                	sd	s10,16(sp)
    80003ac8:	e46e                	sd	s11,8(sp)
    80003aca:	1880                	addi	s0,sp,112
    80003acc:	8b2a                	mv	s6,a0
    80003ace:	8c2e                	mv	s8,a1
    80003ad0:	8ab2                	mv	s5,a2
    80003ad2:	8936                	mv	s2,a3
    80003ad4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ad6:	00e687bb          	addw	a5,a3,a4
    80003ada:	0ed7e263          	bltu	a5,a3,80003bbe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ade:	00043737          	lui	a4,0x43
    80003ae2:	0ef76063          	bltu	a4,a5,80003bc2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae6:	0c0b8863          	beqz	s7,80003bb6 <writei+0x10e>
    80003aea:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aec:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003af0:	5cfd                	li	s9,-1
    80003af2:	a091                	j	80003b36 <writei+0x8e>
    80003af4:	02099d93          	slli	s11,s3,0x20
    80003af8:	020ddd93          	srli	s11,s11,0x20
    80003afc:	05848513          	addi	a0,s1,88
    80003b00:	86ee                	mv	a3,s11
    80003b02:	8656                	mv	a2,s5
    80003b04:	85e2                	mv	a1,s8
    80003b06:	953a                	add	a0,a0,a4
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	958080e7          	jalr	-1704(ra) # 80002460 <either_copyin>
    80003b10:	07950263          	beq	a0,s9,80003b74 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b14:	8526                	mv	a0,s1
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	798080e7          	jalr	1944(ra) # 800042ae <log_write>
    brelse(bp);
    80003b1e:	8526                	mv	a0,s1
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	50a080e7          	jalr	1290(ra) # 8000302a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b28:	01498a3b          	addw	s4,s3,s4
    80003b2c:	0129893b          	addw	s2,s3,s2
    80003b30:	9aee                	add	s5,s5,s11
    80003b32:	057a7663          	bgeu	s4,s7,80003b7e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b36:	000b2483          	lw	s1,0(s6)
    80003b3a:	00a9559b          	srliw	a1,s2,0xa
    80003b3e:	855a                	mv	a0,s6
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	7aa080e7          	jalr	1962(ra) # 800032ea <bmap>
    80003b48:	0005059b          	sext.w	a1,a0
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	3ac080e7          	jalr	940(ra) # 80002efa <bread>
    80003b56:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b58:	3ff97713          	andi	a4,s2,1023
    80003b5c:	40ed07bb          	subw	a5,s10,a4
    80003b60:	414b86bb          	subw	a3,s7,s4
    80003b64:	89be                	mv	s3,a5
    80003b66:	2781                	sext.w	a5,a5
    80003b68:	0006861b          	sext.w	a2,a3
    80003b6c:	f8f674e3          	bgeu	a2,a5,80003af4 <writei+0x4c>
    80003b70:	89b6                	mv	s3,a3
    80003b72:	b749                	j	80003af4 <writei+0x4c>
      brelse(bp);
    80003b74:	8526                	mv	a0,s1
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	4b4080e7          	jalr	1204(ra) # 8000302a <brelse>
  }

  if(off > ip->size)
    80003b7e:	04cb2783          	lw	a5,76(s6)
    80003b82:	0127f463          	bgeu	a5,s2,80003b8a <writei+0xe2>
    ip->size = off;
    80003b86:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b8a:	855a                	mv	a0,s6
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	aa4080e7          	jalr	-1372(ra) # 80003630 <iupdate>

  return tot;
    80003b94:	000a051b          	sext.w	a0,s4
}
    80003b98:	70a6                	ld	ra,104(sp)
    80003b9a:	7406                	ld	s0,96(sp)
    80003b9c:	64e6                	ld	s1,88(sp)
    80003b9e:	6946                	ld	s2,80(sp)
    80003ba0:	69a6                	ld	s3,72(sp)
    80003ba2:	6a06                	ld	s4,64(sp)
    80003ba4:	7ae2                	ld	s5,56(sp)
    80003ba6:	7b42                	ld	s6,48(sp)
    80003ba8:	7ba2                	ld	s7,40(sp)
    80003baa:	7c02                	ld	s8,32(sp)
    80003bac:	6ce2                	ld	s9,24(sp)
    80003bae:	6d42                	ld	s10,16(sp)
    80003bb0:	6da2                	ld	s11,8(sp)
    80003bb2:	6165                	addi	sp,sp,112
    80003bb4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb6:	8a5e                	mv	s4,s7
    80003bb8:	bfc9                	j	80003b8a <writei+0xe2>
    return -1;
    80003bba:	557d                	li	a0,-1
}
    80003bbc:	8082                	ret
    return -1;
    80003bbe:	557d                	li	a0,-1
    80003bc0:	bfe1                	j	80003b98 <writei+0xf0>
    return -1;
    80003bc2:	557d                	li	a0,-1
    80003bc4:	bfd1                	j	80003b98 <writei+0xf0>

0000000080003bc6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bc6:	1141                	addi	sp,sp,-16
    80003bc8:	e406                	sd	ra,8(sp)
    80003bca:	e022                	sd	s0,0(sp)
    80003bcc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bce:	4639                	li	a2,14
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	1cc080e7          	jalr	460(ra) # 80000d9c <strncmp>
}
    80003bd8:	60a2                	ld	ra,8(sp)
    80003bda:	6402                	ld	s0,0(sp)
    80003bdc:	0141                	addi	sp,sp,16
    80003bde:	8082                	ret

0000000080003be0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003be0:	7139                	addi	sp,sp,-64
    80003be2:	fc06                	sd	ra,56(sp)
    80003be4:	f822                	sd	s0,48(sp)
    80003be6:	f426                	sd	s1,40(sp)
    80003be8:	f04a                	sd	s2,32(sp)
    80003bea:	ec4e                	sd	s3,24(sp)
    80003bec:	e852                	sd	s4,16(sp)
    80003bee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bf0:	04451703          	lh	a4,68(a0)
    80003bf4:	4785                	li	a5,1
    80003bf6:	00f71a63          	bne	a4,a5,80003c0a <dirlookup+0x2a>
    80003bfa:	892a                	mv	s2,a0
    80003bfc:	89ae                	mv	s3,a1
    80003bfe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c04:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c06:	e79d                	bnez	a5,80003c34 <dirlookup+0x54>
    80003c08:	a8a5                	j	80003c80 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	a6650513          	addi	a0,a0,-1434 # 80008670 <syscalls+0x1b0>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	928080e7          	jalr	-1752(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	a6e50513          	addi	a0,a0,-1426 # 80008688 <syscalls+0x1c8>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	918080e7          	jalr	-1768(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2a:	24c1                	addiw	s1,s1,16
    80003c2c:	04c92783          	lw	a5,76(s2)
    80003c30:	04f4f763          	bgeu	s1,a5,80003c7e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c34:	4741                	li	a4,16
    80003c36:	86a6                	mv	a3,s1
    80003c38:	fc040613          	addi	a2,s0,-64
    80003c3c:	4581                	li	a1,0
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	d70080e7          	jalr	-656(ra) # 800039b0 <readi>
    80003c48:	47c1                	li	a5,16
    80003c4a:	fcf518e3          	bne	a0,a5,80003c1a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c4e:	fc045783          	lhu	a5,-64(s0)
    80003c52:	dfe1                	beqz	a5,80003c2a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c54:	fc240593          	addi	a1,s0,-62
    80003c58:	854e                	mv	a0,s3
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	f6c080e7          	jalr	-148(ra) # 80003bc6 <namecmp>
    80003c62:	f561                	bnez	a0,80003c2a <dirlookup+0x4a>
      if(poff)
    80003c64:	000a0463          	beqz	s4,80003c6c <dirlookup+0x8c>
        *poff = off;
    80003c68:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c6c:	fc045583          	lhu	a1,-64(s0)
    80003c70:	00092503          	lw	a0,0(s2)
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	752080e7          	jalr	1874(ra) # 800033c6 <iget>
    80003c7c:	a011                	j	80003c80 <dirlookup+0xa0>
  return 0;
    80003c7e:	4501                	li	a0,0
}
    80003c80:	70e2                	ld	ra,56(sp)
    80003c82:	7442                	ld	s0,48(sp)
    80003c84:	74a2                	ld	s1,40(sp)
    80003c86:	7902                	ld	s2,32(sp)
    80003c88:	69e2                	ld	s3,24(sp)
    80003c8a:	6a42                	ld	s4,16(sp)
    80003c8c:	6121                	addi	sp,sp,64
    80003c8e:	8082                	ret

0000000080003c90 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c90:	711d                	addi	sp,sp,-96
    80003c92:	ec86                	sd	ra,88(sp)
    80003c94:	e8a2                	sd	s0,80(sp)
    80003c96:	e4a6                	sd	s1,72(sp)
    80003c98:	e0ca                	sd	s2,64(sp)
    80003c9a:	fc4e                	sd	s3,56(sp)
    80003c9c:	f852                	sd	s4,48(sp)
    80003c9e:	f456                	sd	s5,40(sp)
    80003ca0:	f05a                	sd	s6,32(sp)
    80003ca2:	ec5e                	sd	s7,24(sp)
    80003ca4:	e862                	sd	s8,16(sp)
    80003ca6:	e466                	sd	s9,8(sp)
    80003ca8:	e06a                	sd	s10,0(sp)
    80003caa:	1080                	addi	s0,sp,96
    80003cac:	84aa                	mv	s1,a0
    80003cae:	8b2e                	mv	s6,a1
    80003cb0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cb2:	00054703          	lbu	a4,0(a0)
    80003cb6:	02f00793          	li	a5,47
    80003cba:	02f70363          	beq	a4,a5,80003ce0 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cbe:	ffffe097          	auipc	ra,0xffffe
    80003cc2:	cd8080e7          	jalr	-808(ra) # 80001996 <myproc>
    80003cc6:	15053503          	ld	a0,336(a0)
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	9f4080e7          	jalr	-1548(ra) # 800036be <idup>
    80003cd2:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cd4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cd8:	4cb5                	li	s9,13
  len = path - s;
    80003cda:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cdc:	4c05                	li	s8,1
    80003cde:	a87d                	j	80003d9c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003ce0:	4585                	li	a1,1
    80003ce2:	4505                	li	a0,1
    80003ce4:	fffff097          	auipc	ra,0xfffff
    80003ce8:	6e2080e7          	jalr	1762(ra) # 800033c6 <iget>
    80003cec:	8a2a                	mv	s4,a0
    80003cee:	b7dd                	j	80003cd4 <namex+0x44>
      iunlockput(ip);
    80003cf0:	8552                	mv	a0,s4
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	c6c080e7          	jalr	-916(ra) # 8000395e <iunlockput>
      return 0;
    80003cfa:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cfc:	8552                	mv	a0,s4
    80003cfe:	60e6                	ld	ra,88(sp)
    80003d00:	6446                	ld	s0,80(sp)
    80003d02:	64a6                	ld	s1,72(sp)
    80003d04:	6906                	ld	s2,64(sp)
    80003d06:	79e2                	ld	s3,56(sp)
    80003d08:	7a42                	ld	s4,48(sp)
    80003d0a:	7aa2                	ld	s5,40(sp)
    80003d0c:	7b02                	ld	s6,32(sp)
    80003d0e:	6be2                	ld	s7,24(sp)
    80003d10:	6c42                	ld	s8,16(sp)
    80003d12:	6ca2                	ld	s9,8(sp)
    80003d14:	6d02                	ld	s10,0(sp)
    80003d16:	6125                	addi	sp,sp,96
    80003d18:	8082                	ret
      iunlock(ip);
    80003d1a:	8552                	mv	a0,s4
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	aa2080e7          	jalr	-1374(ra) # 800037be <iunlock>
      return ip;
    80003d24:	bfe1                	j	80003cfc <namex+0x6c>
      iunlockput(ip);
    80003d26:	8552                	mv	a0,s4
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	c36080e7          	jalr	-970(ra) # 8000395e <iunlockput>
      return 0;
    80003d30:	8a4e                	mv	s4,s3
    80003d32:	b7e9                	j	80003cfc <namex+0x6c>
  len = path - s;
    80003d34:	40998633          	sub	a2,s3,s1
    80003d38:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d3c:	09acd863          	bge	s9,s10,80003dcc <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d40:	4639                	li	a2,14
    80003d42:	85a6                	mv	a1,s1
    80003d44:	8556                	mv	a0,s5
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	fe2080e7          	jalr	-30(ra) # 80000d28 <memmove>
    80003d4e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	01279763          	bne	a5,s2,80003d62 <namex+0xd2>
    path++;
    80003d58:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d5a:	0004c783          	lbu	a5,0(s1)
    80003d5e:	ff278de3          	beq	a5,s2,80003d58 <namex+0xc8>
    ilock(ip);
    80003d62:	8552                	mv	a0,s4
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	998080e7          	jalr	-1640(ra) # 800036fc <ilock>
    if(ip->type != T_DIR){
    80003d6c:	044a1783          	lh	a5,68(s4)
    80003d70:	f98790e3          	bne	a5,s8,80003cf0 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d74:	000b0563          	beqz	s6,80003d7e <namex+0xee>
    80003d78:	0004c783          	lbu	a5,0(s1)
    80003d7c:	dfd9                	beqz	a5,80003d1a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d7e:	865e                	mv	a2,s7
    80003d80:	85d6                	mv	a1,s5
    80003d82:	8552                	mv	a0,s4
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	e5c080e7          	jalr	-420(ra) # 80003be0 <dirlookup>
    80003d8c:	89aa                	mv	s3,a0
    80003d8e:	dd41                	beqz	a0,80003d26 <namex+0x96>
    iunlockput(ip);
    80003d90:	8552                	mv	a0,s4
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	bcc080e7          	jalr	-1076(ra) # 8000395e <iunlockput>
    ip = next;
    80003d9a:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d9c:	0004c783          	lbu	a5,0(s1)
    80003da0:	01279763          	bne	a5,s2,80003dae <namex+0x11e>
    path++;
    80003da4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da6:	0004c783          	lbu	a5,0(s1)
    80003daa:	ff278de3          	beq	a5,s2,80003da4 <namex+0x114>
  if(*path == 0)
    80003dae:	cb9d                	beqz	a5,80003de4 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003db0:	0004c783          	lbu	a5,0(s1)
    80003db4:	89a6                	mv	s3,s1
  len = path - s;
    80003db6:	8d5e                	mv	s10,s7
    80003db8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dba:	01278963          	beq	a5,s2,80003dcc <namex+0x13c>
    80003dbe:	dbbd                	beqz	a5,80003d34 <namex+0xa4>
    path++;
    80003dc0:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dc2:	0009c783          	lbu	a5,0(s3)
    80003dc6:	ff279ce3          	bne	a5,s2,80003dbe <namex+0x12e>
    80003dca:	b7ad                	j	80003d34 <namex+0xa4>
    memmove(name, s, len);
    80003dcc:	2601                	sext.w	a2,a2
    80003dce:	85a6                	mv	a1,s1
    80003dd0:	8556                	mv	a0,s5
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	f56080e7          	jalr	-170(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003dda:	9d56                	add	s10,s10,s5
    80003ddc:	000d0023          	sb	zero,0(s10)
    80003de0:	84ce                	mv	s1,s3
    80003de2:	b7bd                	j	80003d50 <namex+0xc0>
  if(nameiparent){
    80003de4:	f00b0ce3          	beqz	s6,80003cfc <namex+0x6c>
    iput(ip);
    80003de8:	8552                	mv	a0,s4
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	acc080e7          	jalr	-1332(ra) # 800038b6 <iput>
    return 0;
    80003df2:	4a01                	li	s4,0
    80003df4:	b721                	j	80003cfc <namex+0x6c>

0000000080003df6 <dirlink>:
{
    80003df6:	7139                	addi	sp,sp,-64
    80003df8:	fc06                	sd	ra,56(sp)
    80003dfa:	f822                	sd	s0,48(sp)
    80003dfc:	f426                	sd	s1,40(sp)
    80003dfe:	f04a                	sd	s2,32(sp)
    80003e00:	ec4e                	sd	s3,24(sp)
    80003e02:	e852                	sd	s4,16(sp)
    80003e04:	0080                	addi	s0,sp,64
    80003e06:	892a                	mv	s2,a0
    80003e08:	8a2e                	mv	s4,a1
    80003e0a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e0c:	4601                	li	a2,0
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	dd2080e7          	jalr	-558(ra) # 80003be0 <dirlookup>
    80003e16:	e93d                	bnez	a0,80003e8c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e18:	04c92483          	lw	s1,76(s2)
    80003e1c:	c49d                	beqz	s1,80003e4a <dirlink+0x54>
    80003e1e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e20:	4741                	li	a4,16
    80003e22:	86a6                	mv	a3,s1
    80003e24:	fc040613          	addi	a2,s0,-64
    80003e28:	4581                	li	a1,0
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	b84080e7          	jalr	-1148(ra) # 800039b0 <readi>
    80003e34:	47c1                	li	a5,16
    80003e36:	06f51163          	bne	a0,a5,80003e98 <dirlink+0xa2>
    if(de.inum == 0)
    80003e3a:	fc045783          	lhu	a5,-64(s0)
    80003e3e:	c791                	beqz	a5,80003e4a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e40:	24c1                	addiw	s1,s1,16
    80003e42:	04c92783          	lw	a5,76(s2)
    80003e46:	fcf4ede3          	bltu	s1,a5,80003e20 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e4a:	4639                	li	a2,14
    80003e4c:	85d2                	mv	a1,s4
    80003e4e:	fc240513          	addi	a0,s0,-62
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	f86080e7          	jalr	-122(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003e5a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5e:	4741                	li	a4,16
    80003e60:	86a6                	mv	a3,s1
    80003e62:	fc040613          	addi	a2,s0,-64
    80003e66:	4581                	li	a1,0
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	c3e080e7          	jalr	-962(ra) # 80003aa8 <writei>
    80003e72:	872a                	mv	a4,a0
    80003e74:	47c1                	li	a5,16
  return 0;
    80003e76:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e78:	02f71863          	bne	a4,a5,80003ea8 <dirlink+0xb2>
}
    80003e7c:	70e2                	ld	ra,56(sp)
    80003e7e:	7442                	ld	s0,48(sp)
    80003e80:	74a2                	ld	s1,40(sp)
    80003e82:	7902                	ld	s2,32(sp)
    80003e84:	69e2                	ld	s3,24(sp)
    80003e86:	6a42                	ld	s4,16(sp)
    80003e88:	6121                	addi	sp,sp,64
    80003e8a:	8082                	ret
    iput(ip);
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	a2a080e7          	jalr	-1494(ra) # 800038b6 <iput>
    return -1;
    80003e94:	557d                	li	a0,-1
    80003e96:	b7dd                	j	80003e7c <dirlink+0x86>
      panic("dirlink read");
    80003e98:	00005517          	auipc	a0,0x5
    80003e9c:	80050513          	addi	a0,a0,-2048 # 80008698 <syscalls+0x1d8>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	69a080e7          	jalr	1690(ra) # 8000053a <panic>
    panic("dirlink");
    80003ea8:	00005517          	auipc	a0,0x5
    80003eac:	90050513          	addi	a0,a0,-1792 # 800087a8 <syscalls+0x2e8>
    80003eb0:	ffffc097          	auipc	ra,0xffffc
    80003eb4:	68a080e7          	jalr	1674(ra) # 8000053a <panic>

0000000080003eb8 <namei>:

struct inode*
namei(char *path)
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ec0:	fe040613          	addi	a2,s0,-32
    80003ec4:	4581                	li	a1,0
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	dca080e7          	jalr	-566(ra) # 80003c90 <namex>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed6:	1141                	addi	sp,sp,-16
    80003ed8:	e406                	sd	ra,8(sp)
    80003eda:	e022                	sd	s0,0(sp)
    80003edc:	0800                	addi	s0,sp,16
    80003ede:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ee0:	4585                	li	a1,1
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	dae080e7          	jalr	-594(ra) # 80003c90 <namex>
}
    80003eea:	60a2                	ld	ra,8(sp)
    80003eec:	6402                	ld	s0,0(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ef2:	1101                	addi	sp,sp,-32
    80003ef4:	ec06                	sd	ra,24(sp)
    80003ef6:	e822                	sd	s0,16(sp)
    80003ef8:	e426                	sd	s1,8(sp)
    80003efa:	e04a                	sd	s2,0(sp)
    80003efc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003efe:	0001d917          	auipc	s2,0x1d
    80003f02:	77290913          	addi	s2,s2,1906 # 80021670 <log>
    80003f06:	01892583          	lw	a1,24(s2)
    80003f0a:	02892503          	lw	a0,40(s2)
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	fec080e7          	jalr	-20(ra) # 80002efa <bread>
    80003f16:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f18:	02c92683          	lw	a3,44(s2)
    80003f1c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f1e:	02d05863          	blez	a3,80003f4e <write_head+0x5c>
    80003f22:	0001d797          	auipc	a5,0x1d
    80003f26:	77e78793          	addi	a5,a5,1918 # 800216a0 <log+0x30>
    80003f2a:	05c50713          	addi	a4,a0,92
    80003f2e:	36fd                	addiw	a3,a3,-1
    80003f30:	02069613          	slli	a2,a3,0x20
    80003f34:	01e65693          	srli	a3,a2,0x1e
    80003f38:	0001d617          	auipc	a2,0x1d
    80003f3c:	76c60613          	addi	a2,a2,1900 # 800216a4 <log+0x34>
    80003f40:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f42:	4390                	lw	a2,0(a5)
    80003f44:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f46:	0791                	addi	a5,a5,4
    80003f48:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f4a:	fed79ce3          	bne	a5,a3,80003f42 <write_head+0x50>
  }
  bwrite(buf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	09c080e7          	jalr	156(ra) # 80002fec <bwrite>
  brelse(buf);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	0d0080e7          	jalr	208(ra) # 8000302a <brelse>
}
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	64a2                	ld	s1,8(sp)
    80003f68:	6902                	ld	s2,0(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret

0000000080003f6e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f6e:	0001d797          	auipc	a5,0x1d
    80003f72:	72e7a783          	lw	a5,1838(a5) # 8002169c <log+0x2c>
    80003f76:	0af05d63          	blez	a5,80004030 <install_trans+0xc2>
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	e456                	sd	s5,8(sp)
    80003f8a:	e05a                	sd	s6,0(sp)
    80003f8c:	0080                	addi	s0,sp,64
    80003f8e:	8b2a                	mv	s6,a0
    80003f90:	0001da97          	auipc	s5,0x1d
    80003f94:	710a8a93          	addi	s5,s5,1808 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f98:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f9a:	0001d997          	auipc	s3,0x1d
    80003f9e:	6d698993          	addi	s3,s3,1750 # 80021670 <log>
    80003fa2:	a00d                	j	80003fc4 <install_trans+0x56>
    brelse(lbuf);
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	084080e7          	jalr	132(ra) # 8000302a <brelse>
    brelse(dbuf);
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	07a080e7          	jalr	122(ra) # 8000302a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb8:	2a05                	addiw	s4,s4,1
    80003fba:	0a91                	addi	s5,s5,4
    80003fbc:	02c9a783          	lw	a5,44(s3)
    80003fc0:	04fa5e63          	bge	s4,a5,8000401c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc4:	0189a583          	lw	a1,24(s3)
    80003fc8:	014585bb          	addw	a1,a1,s4
    80003fcc:	2585                	addiw	a1,a1,1
    80003fce:	0289a503          	lw	a0,40(s3)
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	f28080e7          	jalr	-216(ra) # 80002efa <bread>
    80003fda:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fdc:	000aa583          	lw	a1,0(s5)
    80003fe0:	0289a503          	lw	a0,40(s3)
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	f16080e7          	jalr	-234(ra) # 80002efa <bread>
    80003fec:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fee:	40000613          	li	a2,1024
    80003ff2:	05890593          	addi	a1,s2,88
    80003ff6:	05850513          	addi	a0,a0,88
    80003ffa:	ffffd097          	auipc	ra,0xffffd
    80003ffe:	d2e080e7          	jalr	-722(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004002:	8526                	mv	a0,s1
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	fe8080e7          	jalr	-24(ra) # 80002fec <bwrite>
    if(recovering == 0)
    8000400c:	f80b1ce3          	bnez	s6,80003fa4 <install_trans+0x36>
      bunpin(dbuf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	0f2080e7          	jalr	242(ra) # 80003104 <bunpin>
    8000401a:	b769                	j	80003fa4 <install_trans+0x36>
}
    8000401c:	70e2                	ld	ra,56(sp)
    8000401e:	7442                	ld	s0,48(sp)
    80004020:	74a2                	ld	s1,40(sp)
    80004022:	7902                	ld	s2,32(sp)
    80004024:	69e2                	ld	s3,24(sp)
    80004026:	6a42                	ld	s4,16(sp)
    80004028:	6aa2                	ld	s5,8(sp)
    8000402a:	6b02                	ld	s6,0(sp)
    8000402c:	6121                	addi	sp,sp,64
    8000402e:	8082                	ret
    80004030:	8082                	ret

0000000080004032 <initlog>:
{
    80004032:	7179                	addi	sp,sp,-48
    80004034:	f406                	sd	ra,40(sp)
    80004036:	f022                	sd	s0,32(sp)
    80004038:	ec26                	sd	s1,24(sp)
    8000403a:	e84a                	sd	s2,16(sp)
    8000403c:	e44e                	sd	s3,8(sp)
    8000403e:	1800                	addi	s0,sp,48
    80004040:	892a                	mv	s2,a0
    80004042:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004044:	0001d497          	auipc	s1,0x1d
    80004048:	62c48493          	addi	s1,s1,1580 # 80021670 <log>
    8000404c:	00004597          	auipc	a1,0x4
    80004050:	65c58593          	addi	a1,a1,1628 # 800086a8 <syscalls+0x1e8>
    80004054:	8526                	mv	a0,s1
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	aea080e7          	jalr	-1302(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000405e:	0149a583          	lw	a1,20(s3)
    80004062:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004064:	0109a783          	lw	a5,16(s3)
    80004068:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000406a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000406e:	854a                	mv	a0,s2
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	e8a080e7          	jalr	-374(ra) # 80002efa <bread>
  log.lh.n = lh->n;
    80004078:	4d34                	lw	a3,88(a0)
    8000407a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000407c:	02d05663          	blez	a3,800040a8 <initlog+0x76>
    80004080:	05c50793          	addi	a5,a0,92
    80004084:	0001d717          	auipc	a4,0x1d
    80004088:	61c70713          	addi	a4,a4,1564 # 800216a0 <log+0x30>
    8000408c:	36fd                	addiw	a3,a3,-1
    8000408e:	02069613          	slli	a2,a3,0x20
    80004092:	01e65693          	srli	a3,a2,0x1e
    80004096:	06050613          	addi	a2,a0,96
    8000409a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000409c:	4390                	lw	a2,0(a5)
    8000409e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	0791                	addi	a5,a5,4
    800040a2:	0711                	addi	a4,a4,4
    800040a4:	fed79ce3          	bne	a5,a3,8000409c <initlog+0x6a>
  brelse(buf);
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	f82080e7          	jalr	-126(ra) # 8000302a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040b0:	4505                	li	a0,1
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	ebc080e7          	jalr	-324(ra) # 80003f6e <install_trans>
  log.lh.n = 0;
    800040ba:	0001d797          	auipc	a5,0x1d
    800040be:	5e07a123          	sw	zero,1506(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	e30080e7          	jalr	-464(ra) # 80003ef2 <write_head>
}
    800040ca:	70a2                	ld	ra,40(sp)
    800040cc:	7402                	ld	s0,32(sp)
    800040ce:	64e2                	ld	s1,24(sp)
    800040d0:	6942                	ld	s2,16(sp)
    800040d2:	69a2                	ld	s3,8(sp)
    800040d4:	6145                	addi	sp,sp,48
    800040d6:	8082                	ret

00000000800040d8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040d8:	1101                	addi	sp,sp,-32
    800040da:	ec06                	sd	ra,24(sp)
    800040dc:	e822                	sd	s0,16(sp)
    800040de:	e426                	sd	s1,8(sp)
    800040e0:	e04a                	sd	s2,0(sp)
    800040e2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040e4:	0001d517          	auipc	a0,0x1d
    800040e8:	58c50513          	addi	a0,a0,1420 # 80021670 <log>
    800040ec:	ffffd097          	auipc	ra,0xffffd
    800040f0:	ae4080e7          	jalr	-1308(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800040f4:	0001d497          	auipc	s1,0x1d
    800040f8:	57c48493          	addi	s1,s1,1404 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040fc:	4979                	li	s2,30
    800040fe:	a039                	j	8000410c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004100:	85a6                	mv	a1,s1
    80004102:	8526                	mv	a0,s1
    80004104:	ffffe097          	auipc	ra,0xffffe
    80004108:	f62080e7          	jalr	-158(ra) # 80002066 <sleep>
    if(log.committing){
    8000410c:	50dc                	lw	a5,36(s1)
    8000410e:	fbed                	bnez	a5,80004100 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004110:	5098                	lw	a4,32(s1)
    80004112:	2705                	addiw	a4,a4,1
    80004114:	0007069b          	sext.w	a3,a4
    80004118:	0027179b          	slliw	a5,a4,0x2
    8000411c:	9fb9                	addw	a5,a5,a4
    8000411e:	0017979b          	slliw	a5,a5,0x1
    80004122:	54d8                	lw	a4,44(s1)
    80004124:	9fb9                	addw	a5,a5,a4
    80004126:	00f95963          	bge	s2,a5,80004138 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000412a:	85a6                	mv	a1,s1
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffe097          	auipc	ra,0xffffe
    80004132:	f38080e7          	jalr	-200(ra) # 80002066 <sleep>
    80004136:	bfd9                	j	8000410c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004138:	0001d517          	auipc	a0,0x1d
    8000413c:	53850513          	addi	a0,a0,1336 # 80021670 <log>
    80004140:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	b42080e7          	jalr	-1214(ra) # 80000c84 <release>
      break;
    }
  }
}
    8000414a:	60e2                	ld	ra,24(sp)
    8000414c:	6442                	ld	s0,16(sp)
    8000414e:	64a2                	ld	s1,8(sp)
    80004150:	6902                	ld	s2,0(sp)
    80004152:	6105                	addi	sp,sp,32
    80004154:	8082                	ret

0000000080004156 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004156:	7139                	addi	sp,sp,-64
    80004158:	fc06                	sd	ra,56(sp)
    8000415a:	f822                	sd	s0,48(sp)
    8000415c:	f426                	sd	s1,40(sp)
    8000415e:	f04a                	sd	s2,32(sp)
    80004160:	ec4e                	sd	s3,24(sp)
    80004162:	e852                	sd	s4,16(sp)
    80004164:	e456                	sd	s5,8(sp)
    80004166:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004168:	0001d497          	auipc	s1,0x1d
    8000416c:	50848493          	addi	s1,s1,1288 # 80021670 <log>
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	a5e080e7          	jalr	-1442(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000417a:	509c                	lw	a5,32(s1)
    8000417c:	37fd                	addiw	a5,a5,-1
    8000417e:	0007891b          	sext.w	s2,a5
    80004182:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004184:	50dc                	lw	a5,36(s1)
    80004186:	e7b9                	bnez	a5,800041d4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004188:	04091e63          	bnez	s2,800041e4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	4e448493          	addi	s1,s1,1252 # 80021670 <log>
    80004194:	4785                	li	a5,1
    80004196:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	aea080e7          	jalr	-1302(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041a2:	54dc                	lw	a5,44(s1)
    800041a4:	06f04763          	bgtz	a5,80004212 <end_op+0xbc>
    acquire(&log.lock);
    800041a8:	0001d497          	auipc	s1,0x1d
    800041ac:	4c848493          	addi	s1,s1,1224 # 80021670 <log>
    800041b0:	8526                	mv	a0,s1
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	a1e080e7          	jalr	-1506(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800041ba:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041be:	8526                	mv	a0,s1
    800041c0:	ffffe097          	auipc	ra,0xffffe
    800041c4:	032080e7          	jalr	50(ra) # 800021f2 <wakeup>
    release(&log.lock);
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	aba080e7          	jalr	-1350(ra) # 80000c84 <release>
}
    800041d2:	a03d                	j	80004200 <end_op+0xaa>
    panic("log.committing");
    800041d4:	00004517          	auipc	a0,0x4
    800041d8:	4dc50513          	addi	a0,a0,1244 # 800086b0 <syscalls+0x1f0>
    800041dc:	ffffc097          	auipc	ra,0xffffc
    800041e0:	35e080e7          	jalr	862(ra) # 8000053a <panic>
    wakeup(&log);
    800041e4:	0001d497          	auipc	s1,0x1d
    800041e8:	48c48493          	addi	s1,s1,1164 # 80021670 <log>
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffe097          	auipc	ra,0xffffe
    800041f2:	004080e7          	jalr	4(ra) # 800021f2 <wakeup>
  release(&log.lock);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	a8c080e7          	jalr	-1396(ra) # 80000c84 <release>
}
    80004200:	70e2                	ld	ra,56(sp)
    80004202:	7442                	ld	s0,48(sp)
    80004204:	74a2                	ld	s1,40(sp)
    80004206:	7902                	ld	s2,32(sp)
    80004208:	69e2                	ld	s3,24(sp)
    8000420a:	6a42                	ld	s4,16(sp)
    8000420c:	6aa2                	ld	s5,8(sp)
    8000420e:	6121                	addi	sp,sp,64
    80004210:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004212:	0001da97          	auipc	s5,0x1d
    80004216:	48ea8a93          	addi	s5,s5,1166 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000421a:	0001da17          	auipc	s4,0x1d
    8000421e:	456a0a13          	addi	s4,s4,1110 # 80021670 <log>
    80004222:	018a2583          	lw	a1,24(s4)
    80004226:	012585bb          	addw	a1,a1,s2
    8000422a:	2585                	addiw	a1,a1,1
    8000422c:	028a2503          	lw	a0,40(s4)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	cca080e7          	jalr	-822(ra) # 80002efa <bread>
    80004238:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000423a:	000aa583          	lw	a1,0(s5)
    8000423e:	028a2503          	lw	a0,40(s4)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	cb8080e7          	jalr	-840(ra) # 80002efa <bread>
    8000424a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000424c:	40000613          	li	a2,1024
    80004250:	05850593          	addi	a1,a0,88
    80004254:	05848513          	addi	a0,s1,88
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	ad0080e7          	jalr	-1328(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004260:	8526                	mv	a0,s1
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	d8a080e7          	jalr	-630(ra) # 80002fec <bwrite>
    brelse(from);
    8000426a:	854e                	mv	a0,s3
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	dbe080e7          	jalr	-578(ra) # 8000302a <brelse>
    brelse(to);
    80004274:	8526                	mv	a0,s1
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	db4080e7          	jalr	-588(ra) # 8000302a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427e:	2905                	addiw	s2,s2,1
    80004280:	0a91                	addi	s5,s5,4
    80004282:	02ca2783          	lw	a5,44(s4)
    80004286:	f8f94ee3          	blt	s2,a5,80004222 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	c68080e7          	jalr	-920(ra) # 80003ef2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004292:	4501                	li	a0,0
    80004294:	00000097          	auipc	ra,0x0
    80004298:	cda080e7          	jalr	-806(ra) # 80003f6e <install_trans>
    log.lh.n = 0;
    8000429c:	0001d797          	auipc	a5,0x1d
    800042a0:	4007a023          	sw	zero,1024(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	c4e080e7          	jalr	-946(ra) # 80003ef2 <write_head>
    800042ac:	bdf5                	j	800041a8 <end_op+0x52>

00000000800042ae <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ae:	1101                	addi	sp,sp,-32
    800042b0:	ec06                	sd	ra,24(sp)
    800042b2:	e822                	sd	s0,16(sp)
    800042b4:	e426                	sd	s1,8(sp)
    800042b6:	e04a                	sd	s2,0(sp)
    800042b8:	1000                	addi	s0,sp,32
    800042ba:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042bc:	0001d917          	auipc	s2,0x1d
    800042c0:	3b490913          	addi	s2,s2,948 # 80021670 <log>
    800042c4:	854a                	mv	a0,s2
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	90a080e7          	jalr	-1782(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042ce:	02c92603          	lw	a2,44(s2)
    800042d2:	47f5                	li	a5,29
    800042d4:	06c7c563          	blt	a5,a2,8000433e <log_write+0x90>
    800042d8:	0001d797          	auipc	a5,0x1d
    800042dc:	3b47a783          	lw	a5,948(a5) # 8002168c <log+0x1c>
    800042e0:	37fd                	addiw	a5,a5,-1
    800042e2:	04f65e63          	bge	a2,a5,8000433e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e6:	0001d797          	auipc	a5,0x1d
    800042ea:	3aa7a783          	lw	a5,938(a5) # 80021690 <log+0x20>
    800042ee:	06f05063          	blez	a5,8000434e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042f2:	4781                	li	a5,0
    800042f4:	06c05563          	blez	a2,8000435e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f8:	44cc                	lw	a1,12(s1)
    800042fa:	0001d717          	auipc	a4,0x1d
    800042fe:	3a670713          	addi	a4,a4,934 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004302:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004304:	4314                	lw	a3,0(a4)
    80004306:	04b68c63          	beq	a3,a1,8000435e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000430a:	2785                	addiw	a5,a5,1
    8000430c:	0711                	addi	a4,a4,4
    8000430e:	fef61be3          	bne	a2,a5,80004304 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004312:	0621                	addi	a2,a2,8
    80004314:	060a                	slli	a2,a2,0x2
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	35a78793          	addi	a5,a5,858 # 80021670 <log>
    8000431e:	97b2                	add	a5,a5,a2
    80004320:	44d8                	lw	a4,12(s1)
    80004322:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	da2080e7          	jalr	-606(ra) # 800030c8 <bpin>
    log.lh.n++;
    8000432e:	0001d717          	auipc	a4,0x1d
    80004332:	34270713          	addi	a4,a4,834 # 80021670 <log>
    80004336:	575c                	lw	a5,44(a4)
    80004338:	2785                	addiw	a5,a5,1
    8000433a:	d75c                	sw	a5,44(a4)
    8000433c:	a82d                	j	80004376 <log_write+0xc8>
    panic("too big a transaction");
    8000433e:	00004517          	auipc	a0,0x4
    80004342:	38250513          	addi	a0,a0,898 # 800086c0 <syscalls+0x200>
    80004346:	ffffc097          	auipc	ra,0xffffc
    8000434a:	1f4080e7          	jalr	500(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000434e:	00004517          	auipc	a0,0x4
    80004352:	38a50513          	addi	a0,a0,906 # 800086d8 <syscalls+0x218>
    80004356:	ffffc097          	auipc	ra,0xffffc
    8000435a:	1e4080e7          	jalr	484(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000435e:	00878693          	addi	a3,a5,8
    80004362:	068a                	slli	a3,a3,0x2
    80004364:	0001d717          	auipc	a4,0x1d
    80004368:	30c70713          	addi	a4,a4,780 # 80021670 <log>
    8000436c:	9736                	add	a4,a4,a3
    8000436e:	44d4                	lw	a3,12(s1)
    80004370:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004372:	faf609e3          	beq	a2,a5,80004324 <log_write+0x76>
  }
  release(&log.lock);
    80004376:	0001d517          	auipc	a0,0x1d
    8000437a:	2fa50513          	addi	a0,a0,762 # 80021670 <log>
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	906080e7          	jalr	-1786(ra) # 80000c84 <release>
}
    80004386:	60e2                	ld	ra,24(sp)
    80004388:	6442                	ld	s0,16(sp)
    8000438a:	64a2                	ld	s1,8(sp)
    8000438c:	6902                	ld	s2,0(sp)
    8000438e:	6105                	addi	sp,sp,32
    80004390:	8082                	ret

0000000080004392 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004392:	1101                	addi	sp,sp,-32
    80004394:	ec06                	sd	ra,24(sp)
    80004396:	e822                	sd	s0,16(sp)
    80004398:	e426                	sd	s1,8(sp)
    8000439a:	e04a                	sd	s2,0(sp)
    8000439c:	1000                	addi	s0,sp,32
    8000439e:	84aa                	mv	s1,a0
    800043a0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043a2:	00004597          	auipc	a1,0x4
    800043a6:	35658593          	addi	a1,a1,854 # 800086f8 <syscalls+0x238>
    800043aa:	0521                	addi	a0,a0,8
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	794080e7          	jalr	1940(ra) # 80000b40 <initlock>
  lk->name = name;
    800043b4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043bc:	0204a423          	sw	zero,40(s1)
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6902                	ld	s2,0(sp)
    800043c8:	6105                	addi	sp,sp,32
    800043ca:	8082                	ret

00000000800043cc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	e04a                	sd	s2,0(sp)
    800043d6:	1000                	addi	s0,sp,32
    800043d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043da:	00850913          	addi	s2,a0,8
    800043de:	854a                	mv	a0,s2
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	7f0080e7          	jalr	2032(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800043e8:	409c                	lw	a5,0(s1)
    800043ea:	cb89                	beqz	a5,800043fc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043ec:	85ca                	mv	a1,s2
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffe097          	auipc	ra,0xffffe
    800043f4:	c76080e7          	jalr	-906(ra) # 80002066 <sleep>
  while (lk->locked) {
    800043f8:	409c                	lw	a5,0(s1)
    800043fa:	fbed                	bnez	a5,800043ec <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043fc:	4785                	li	a5,1
    800043fe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	596080e7          	jalr	1430(ra) # 80001996 <myproc>
    80004408:	591c                	lw	a5,48(a0)
    8000440a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000440c:	854a                	mv	a0,s2
    8000440e:	ffffd097          	auipc	ra,0xffffd
    80004412:	876080e7          	jalr	-1930(ra) # 80000c84 <release>
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6902                	ld	s2,0(sp)
    8000441e:	6105                	addi	sp,sp,32
    80004420:	8082                	ret

0000000080004422 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004422:	1101                	addi	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	e04a                	sd	s2,0(sp)
    8000442c:	1000                	addi	s0,sp,32
    8000442e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004430:	00850913          	addi	s2,a0,8
    80004434:	854a                	mv	a0,s2
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	79a080e7          	jalr	1946(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000443e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004442:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004446:	8526                	mv	a0,s1
    80004448:	ffffe097          	auipc	ra,0xffffe
    8000444c:	daa080e7          	jalr	-598(ra) # 800021f2 <wakeup>
  release(&lk->lk);
    80004450:	854a                	mv	a0,s2
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	832080e7          	jalr	-1998(ra) # 80000c84 <release>
}
    8000445a:	60e2                	ld	ra,24(sp)
    8000445c:	6442                	ld	s0,16(sp)
    8000445e:	64a2                	ld	s1,8(sp)
    80004460:	6902                	ld	s2,0(sp)
    80004462:	6105                	addi	sp,sp,32
    80004464:	8082                	ret

0000000080004466 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004466:	7179                	addi	sp,sp,-48
    80004468:	f406                	sd	ra,40(sp)
    8000446a:	f022                	sd	s0,32(sp)
    8000446c:	ec26                	sd	s1,24(sp)
    8000446e:	e84a                	sd	s2,16(sp)
    80004470:	e44e                	sd	s3,8(sp)
    80004472:	1800                	addi	s0,sp,48
    80004474:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	754080e7          	jalr	1876(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004484:	409c                	lw	a5,0(s1)
    80004486:	ef99                	bnez	a5,800044a4 <holdingsleep+0x3e>
    80004488:	4481                	li	s1,0
  release(&lk->lk);
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	7f8080e7          	jalr	2040(ra) # 80000c84 <release>
  return r;
}
    80004494:	8526                	mv	a0,s1
    80004496:	70a2                	ld	ra,40(sp)
    80004498:	7402                	ld	s0,32(sp)
    8000449a:	64e2                	ld	s1,24(sp)
    8000449c:	6942                	ld	s2,16(sp)
    8000449e:	69a2                	ld	s3,8(sp)
    800044a0:	6145                	addi	sp,sp,48
    800044a2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a4:	0284a983          	lw	s3,40(s1)
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	4ee080e7          	jalr	1262(ra) # 80001996 <myproc>
    800044b0:	5904                	lw	s1,48(a0)
    800044b2:	413484b3          	sub	s1,s1,s3
    800044b6:	0014b493          	seqz	s1,s1
    800044ba:	bfc1                	j	8000448a <holdingsleep+0x24>

00000000800044bc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044bc:	1141                	addi	sp,sp,-16
    800044be:	e406                	sd	ra,8(sp)
    800044c0:	e022                	sd	s0,0(sp)
    800044c2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044c4:	00004597          	auipc	a1,0x4
    800044c8:	24458593          	addi	a1,a1,580 # 80008708 <syscalls+0x248>
    800044cc:	0001d517          	auipc	a0,0x1d
    800044d0:	2ec50513          	addi	a0,a0,748 # 800217b8 <ftable>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	66c080e7          	jalr	1644(ra) # 80000b40 <initlock>
}
    800044dc:	60a2                	ld	ra,8(sp)
    800044de:	6402                	ld	s0,0(sp)
    800044e0:	0141                	addi	sp,sp,16
    800044e2:	8082                	ret

00000000800044e4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ee:	0001d517          	auipc	a0,0x1d
    800044f2:	2ca50513          	addi	a0,a0,714 # 800217b8 <ftable>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6da080e7          	jalr	1754(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044fe:	0001d497          	auipc	s1,0x1d
    80004502:	2d248493          	addi	s1,s1,722 # 800217d0 <ftable+0x18>
    80004506:	0001e717          	auipc	a4,0x1e
    8000450a:	26a70713          	addi	a4,a4,618 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    8000450e:	40dc                	lw	a5,4(s1)
    80004510:	cf99                	beqz	a5,8000452e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004512:	02848493          	addi	s1,s1,40
    80004516:	fee49ce3          	bne	s1,a4,8000450e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000451a:	0001d517          	auipc	a0,0x1d
    8000451e:	29e50513          	addi	a0,a0,670 # 800217b8 <ftable>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	762080e7          	jalr	1890(ra) # 80000c84 <release>
  return 0;
    8000452a:	4481                	li	s1,0
    8000452c:	a819                	j	80004542 <filealloc+0x5e>
      f->ref = 1;
    8000452e:	4785                	li	a5,1
    80004530:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	28650513          	addi	a0,a0,646 # 800217b8 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	74a080e7          	jalr	1866(ra) # 80000c84 <release>
}
    80004542:	8526                	mv	a0,s1
    80004544:	60e2                	ld	ra,24(sp)
    80004546:	6442                	ld	s0,16(sp)
    80004548:	64a2                	ld	s1,8(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	1000                	addi	s0,sp,32
    80004558:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	25e50513          	addi	a0,a0,606 # 800217b8 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	66e080e7          	jalr	1646(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000456a:	40dc                	lw	a5,4(s1)
    8000456c:	02f05263          	blez	a5,80004590 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004570:	2785                	addiw	a5,a5,1
    80004572:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004574:	0001d517          	auipc	a0,0x1d
    80004578:	24450513          	addi	a0,a0,580 # 800217b8 <ftable>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	708080e7          	jalr	1800(ra) # 80000c84 <release>
  return f;
}
    80004584:	8526                	mv	a0,s1
    80004586:	60e2                	ld	ra,24(sp)
    80004588:	6442                	ld	s0,16(sp)
    8000458a:	64a2                	ld	s1,8(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret
    panic("filedup");
    80004590:	00004517          	auipc	a0,0x4
    80004594:	18050513          	addi	a0,a0,384 # 80008710 <syscalls+0x250>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	fa2080e7          	jalr	-94(ra) # 8000053a <panic>

00000000800045a0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045a0:	7139                	addi	sp,sp,-64
    800045a2:	fc06                	sd	ra,56(sp)
    800045a4:	f822                	sd	s0,48(sp)
    800045a6:	f426                	sd	s1,40(sp)
    800045a8:	f04a                	sd	s2,32(sp)
    800045aa:	ec4e                	sd	s3,24(sp)
    800045ac:	e852                	sd	s4,16(sp)
    800045ae:	e456                	sd	s5,8(sp)
    800045b0:	0080                	addi	s0,sp,64
    800045b2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	20450513          	addi	a0,a0,516 # 800217b8 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	614080e7          	jalr	1556(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800045c4:	40dc                	lw	a5,4(s1)
    800045c6:	06f05163          	blez	a5,80004628 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ca:	37fd                	addiw	a5,a5,-1
    800045cc:	0007871b          	sext.w	a4,a5
    800045d0:	c0dc                	sw	a5,4(s1)
    800045d2:	06e04363          	bgtz	a4,80004638 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d6:	0004a903          	lw	s2,0(s1)
    800045da:	0094ca83          	lbu	s5,9(s1)
    800045de:	0104ba03          	ld	s4,16(s1)
    800045e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	1ca50513          	addi	a0,a0,458 # 800217b8 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	68e080e7          	jalr	1678(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800045fe:	4785                	li	a5,1
    80004600:	04f90d63          	beq	s2,a5,8000465a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004604:	3979                	addiw	s2,s2,-2
    80004606:	4785                	li	a5,1
    80004608:	0527e063          	bltu	a5,s2,80004648 <fileclose+0xa8>
    begin_op();
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	acc080e7          	jalr	-1332(ra) # 800040d8 <begin_op>
    iput(ff.ip);
    80004614:	854e                	mv	a0,s3
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	2a0080e7          	jalr	672(ra) # 800038b6 <iput>
    end_op();
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	b38080e7          	jalr	-1224(ra) # 80004156 <end_op>
    80004626:	a00d                	j	80004648 <fileclose+0xa8>
    panic("fileclose");
    80004628:	00004517          	auipc	a0,0x4
    8000462c:	0f050513          	addi	a0,a0,240 # 80008718 <syscalls+0x258>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	f0a080e7          	jalr	-246(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004638:	0001d517          	auipc	a0,0x1d
    8000463c:	18050513          	addi	a0,a0,384 # 800217b8 <ftable>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	644080e7          	jalr	1604(ra) # 80000c84 <release>
  }
}
    80004648:	70e2                	ld	ra,56(sp)
    8000464a:	7442                	ld	s0,48(sp)
    8000464c:	74a2                	ld	s1,40(sp)
    8000464e:	7902                	ld	s2,32(sp)
    80004650:	69e2                	ld	s3,24(sp)
    80004652:	6a42                	ld	s4,16(sp)
    80004654:	6aa2                	ld	s5,8(sp)
    80004656:	6121                	addi	sp,sp,64
    80004658:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000465a:	85d6                	mv	a1,s5
    8000465c:	8552                	mv	a0,s4
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	34c080e7          	jalr	844(ra) # 800049aa <pipeclose>
    80004666:	b7cd                	j	80004648 <fileclose+0xa8>

0000000080004668 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004668:	715d                	addi	sp,sp,-80
    8000466a:	e486                	sd	ra,72(sp)
    8000466c:	e0a2                	sd	s0,64(sp)
    8000466e:	fc26                	sd	s1,56(sp)
    80004670:	f84a                	sd	s2,48(sp)
    80004672:	f44e                	sd	s3,40(sp)
    80004674:	0880                	addi	s0,sp,80
    80004676:	84aa                	mv	s1,a0
    80004678:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000467a:	ffffd097          	auipc	ra,0xffffd
    8000467e:	31c080e7          	jalr	796(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004682:	409c                	lw	a5,0(s1)
    80004684:	37f9                	addiw	a5,a5,-2
    80004686:	4705                	li	a4,1
    80004688:	04f76763          	bltu	a4,a5,800046d6 <filestat+0x6e>
    8000468c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000468e:	6c88                	ld	a0,24(s1)
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	06c080e7          	jalr	108(ra) # 800036fc <ilock>
    stati(f->ip, &st);
    80004698:	fb840593          	addi	a1,s0,-72
    8000469c:	6c88                	ld	a0,24(s1)
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	2e8080e7          	jalr	744(ra) # 80003986 <stati>
    iunlock(f->ip);
    800046a6:	6c88                	ld	a0,24(s1)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	116080e7          	jalr	278(ra) # 800037be <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046b0:	46e1                	li	a3,24
    800046b2:	fb840613          	addi	a2,s0,-72
    800046b6:	85ce                	mv	a1,s3
    800046b8:	05093503          	ld	a0,80(s2)
    800046bc:	ffffd097          	auipc	ra,0xffffd
    800046c0:	f9e080e7          	jalr	-98(ra) # 8000165a <copyout>
    800046c4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c8:	60a6                	ld	ra,72(sp)
    800046ca:	6406                	ld	s0,64(sp)
    800046cc:	74e2                	ld	s1,56(sp)
    800046ce:	7942                	ld	s2,48(sp)
    800046d0:	79a2                	ld	s3,40(sp)
    800046d2:	6161                	addi	sp,sp,80
    800046d4:	8082                	ret
  return -1;
    800046d6:	557d                	li	a0,-1
    800046d8:	bfc5                	j	800046c8 <filestat+0x60>

00000000800046da <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046da:	7179                	addi	sp,sp,-48
    800046dc:	f406                	sd	ra,40(sp)
    800046de:	f022                	sd	s0,32(sp)
    800046e0:	ec26                	sd	s1,24(sp)
    800046e2:	e84a                	sd	s2,16(sp)
    800046e4:	e44e                	sd	s3,8(sp)
    800046e6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e8:	00854783          	lbu	a5,8(a0)
    800046ec:	c3d5                	beqz	a5,80004790 <fileread+0xb6>
    800046ee:	84aa                	mv	s1,a0
    800046f0:	89ae                	mv	s3,a1
    800046f2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046f4:	411c                	lw	a5,0(a0)
    800046f6:	4705                	li	a4,1
    800046f8:	04e78963          	beq	a5,a4,8000474a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046fc:	470d                	li	a4,3
    800046fe:	04e78d63          	beq	a5,a4,80004758 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004702:	4709                	li	a4,2
    80004704:	06e79e63          	bne	a5,a4,80004780 <fileread+0xa6>
    ilock(f->ip);
    80004708:	6d08                	ld	a0,24(a0)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	ff2080e7          	jalr	-14(ra) # 800036fc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004712:	874a                	mv	a4,s2
    80004714:	5094                	lw	a3,32(s1)
    80004716:	864e                	mv	a2,s3
    80004718:	4585                	li	a1,1
    8000471a:	6c88                	ld	a0,24(s1)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	294080e7          	jalr	660(ra) # 800039b0 <readi>
    80004724:	892a                	mv	s2,a0
    80004726:	00a05563          	blez	a0,80004730 <fileread+0x56>
      f->off += r;
    8000472a:	509c                	lw	a5,32(s1)
    8000472c:	9fa9                	addw	a5,a5,a0
    8000472e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	08c080e7          	jalr	140(ra) # 800037be <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000473a:	854a                	mv	a0,s2
    8000473c:	70a2                	ld	ra,40(sp)
    8000473e:	7402                	ld	s0,32(sp)
    80004740:	64e2                	ld	s1,24(sp)
    80004742:	6942                	ld	s2,16(sp)
    80004744:	69a2                	ld	s3,8(sp)
    80004746:	6145                	addi	sp,sp,48
    80004748:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000474a:	6908                	ld	a0,16(a0)
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	3c0080e7          	jalr	960(ra) # 80004b0c <piperead>
    80004754:	892a                	mv	s2,a0
    80004756:	b7d5                	j	8000473a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004758:	02451783          	lh	a5,36(a0)
    8000475c:	03079693          	slli	a3,a5,0x30
    80004760:	92c1                	srli	a3,a3,0x30
    80004762:	4725                	li	a4,9
    80004764:	02d76863          	bltu	a4,a3,80004794 <fileread+0xba>
    80004768:	0792                	slli	a5,a5,0x4
    8000476a:	0001d717          	auipc	a4,0x1d
    8000476e:	fae70713          	addi	a4,a4,-82 # 80021718 <devsw>
    80004772:	97ba                	add	a5,a5,a4
    80004774:	639c                	ld	a5,0(a5)
    80004776:	c38d                	beqz	a5,80004798 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004778:	4505                	li	a0,1
    8000477a:	9782                	jalr	a5
    8000477c:	892a                	mv	s2,a0
    8000477e:	bf75                	j	8000473a <fileread+0x60>
    panic("fileread");
    80004780:	00004517          	auipc	a0,0x4
    80004784:	fa850513          	addi	a0,a0,-88 # 80008728 <syscalls+0x268>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	db2080e7          	jalr	-590(ra) # 8000053a <panic>
    return -1;
    80004790:	597d                	li	s2,-1
    80004792:	b765                	j	8000473a <fileread+0x60>
      return -1;
    80004794:	597d                	li	s2,-1
    80004796:	b755                	j	8000473a <fileread+0x60>
    80004798:	597d                	li	s2,-1
    8000479a:	b745                	j	8000473a <fileread+0x60>

000000008000479c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000479c:	715d                	addi	sp,sp,-80
    8000479e:	e486                	sd	ra,72(sp)
    800047a0:	e0a2                	sd	s0,64(sp)
    800047a2:	fc26                	sd	s1,56(sp)
    800047a4:	f84a                	sd	s2,48(sp)
    800047a6:	f44e                	sd	s3,40(sp)
    800047a8:	f052                	sd	s4,32(sp)
    800047aa:	ec56                	sd	s5,24(sp)
    800047ac:	e85a                	sd	s6,16(sp)
    800047ae:	e45e                	sd	s7,8(sp)
    800047b0:	e062                	sd	s8,0(sp)
    800047b2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047b4:	00954783          	lbu	a5,9(a0)
    800047b8:	10078663          	beqz	a5,800048c4 <filewrite+0x128>
    800047bc:	892a                	mv	s2,a0
    800047be:	8b2e                	mv	s6,a1
    800047c0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c2:	411c                	lw	a5,0(a0)
    800047c4:	4705                	li	a4,1
    800047c6:	02e78263          	beq	a5,a4,800047ea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ca:	470d                	li	a4,3
    800047cc:	02e78663          	beq	a5,a4,800047f8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d0:	4709                	li	a4,2
    800047d2:	0ee79163          	bne	a5,a4,800048b4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047d6:	0ac05d63          	blez	a2,80004890 <filewrite+0xf4>
    int i = 0;
    800047da:	4981                	li	s3,0
    800047dc:	6b85                	lui	s7,0x1
    800047de:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047e2:	6c05                	lui	s8,0x1
    800047e4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047e8:	a861                	j	80004880 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047ea:	6908                	ld	a0,16(a0)
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	22e080e7          	jalr	558(ra) # 80004a1a <pipewrite>
    800047f4:	8a2a                	mv	s4,a0
    800047f6:	a045                	j	80004896 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047f8:	02451783          	lh	a5,36(a0)
    800047fc:	03079693          	slli	a3,a5,0x30
    80004800:	92c1                	srli	a3,a3,0x30
    80004802:	4725                	li	a4,9
    80004804:	0cd76263          	bltu	a4,a3,800048c8 <filewrite+0x12c>
    80004808:	0792                	slli	a5,a5,0x4
    8000480a:	0001d717          	auipc	a4,0x1d
    8000480e:	f0e70713          	addi	a4,a4,-242 # 80021718 <devsw>
    80004812:	97ba                	add	a5,a5,a4
    80004814:	679c                	ld	a5,8(a5)
    80004816:	cbdd                	beqz	a5,800048cc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004818:	4505                	li	a0,1
    8000481a:	9782                	jalr	a5
    8000481c:	8a2a                	mv	s4,a0
    8000481e:	a8a5                	j	80004896 <filewrite+0xfa>
    80004820:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004824:	00000097          	auipc	ra,0x0
    80004828:	8b4080e7          	jalr	-1868(ra) # 800040d8 <begin_op>
      ilock(f->ip);
    8000482c:	01893503          	ld	a0,24(s2)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	ecc080e7          	jalr	-308(ra) # 800036fc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004838:	8756                	mv	a4,s5
    8000483a:	02092683          	lw	a3,32(s2)
    8000483e:	01698633          	add	a2,s3,s6
    80004842:	4585                	li	a1,1
    80004844:	01893503          	ld	a0,24(s2)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	260080e7          	jalr	608(ra) # 80003aa8 <writei>
    80004850:	84aa                	mv	s1,a0
    80004852:	00a05763          	blez	a0,80004860 <filewrite+0xc4>
        f->off += r;
    80004856:	02092783          	lw	a5,32(s2)
    8000485a:	9fa9                	addw	a5,a5,a0
    8000485c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004860:	01893503          	ld	a0,24(s2)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	f5a080e7          	jalr	-166(ra) # 800037be <iunlock>
      end_op();
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	8ea080e7          	jalr	-1814(ra) # 80004156 <end_op>

      if(r != n1){
    80004874:	009a9f63          	bne	s5,s1,80004892 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004878:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000487c:	0149db63          	bge	s3,s4,80004892 <filewrite+0xf6>
      int n1 = n - i;
    80004880:	413a04bb          	subw	s1,s4,s3
    80004884:	0004879b          	sext.w	a5,s1
    80004888:	f8fbdce3          	bge	s7,a5,80004820 <filewrite+0x84>
    8000488c:	84e2                	mv	s1,s8
    8000488e:	bf49                	j	80004820 <filewrite+0x84>
    int i = 0;
    80004890:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004892:	013a1f63          	bne	s4,s3,800048b0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004896:	8552                	mv	a0,s4
    80004898:	60a6                	ld	ra,72(sp)
    8000489a:	6406                	ld	s0,64(sp)
    8000489c:	74e2                	ld	s1,56(sp)
    8000489e:	7942                	ld	s2,48(sp)
    800048a0:	79a2                	ld	s3,40(sp)
    800048a2:	7a02                	ld	s4,32(sp)
    800048a4:	6ae2                	ld	s5,24(sp)
    800048a6:	6b42                	ld	s6,16(sp)
    800048a8:	6ba2                	ld	s7,8(sp)
    800048aa:	6c02                	ld	s8,0(sp)
    800048ac:	6161                	addi	sp,sp,80
    800048ae:	8082                	ret
    ret = (i == n ? n : -1);
    800048b0:	5a7d                	li	s4,-1
    800048b2:	b7d5                	j	80004896 <filewrite+0xfa>
    panic("filewrite");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	e8450513          	addi	a0,a0,-380 # 80008738 <syscalls+0x278>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c7e080e7          	jalr	-898(ra) # 8000053a <panic>
    return -1;
    800048c4:	5a7d                	li	s4,-1
    800048c6:	bfc1                	j	80004896 <filewrite+0xfa>
      return -1;
    800048c8:	5a7d                	li	s4,-1
    800048ca:	b7f1                	j	80004896 <filewrite+0xfa>
    800048cc:	5a7d                	li	s4,-1
    800048ce:	b7e1                	j	80004896 <filewrite+0xfa>

00000000800048d0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d0:	7179                	addi	sp,sp,-48
    800048d2:	f406                	sd	ra,40(sp)
    800048d4:	f022                	sd	s0,32(sp)
    800048d6:	ec26                	sd	s1,24(sp)
    800048d8:	e84a                	sd	s2,16(sp)
    800048da:	e44e                	sd	s3,8(sp)
    800048dc:	e052                	sd	s4,0(sp)
    800048de:	1800                	addi	s0,sp,48
    800048e0:	84aa                	mv	s1,a0
    800048e2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048e4:	0005b023          	sd	zero,0(a1)
    800048e8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	bf8080e7          	jalr	-1032(ra) # 800044e4 <filealloc>
    800048f4:	e088                	sd	a0,0(s1)
    800048f6:	c551                	beqz	a0,80004982 <pipealloc+0xb2>
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	bec080e7          	jalr	-1044(ra) # 800044e4 <filealloc>
    80004900:	00aa3023          	sd	a0,0(s4)
    80004904:	c92d                	beqz	a0,80004976 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	1da080e7          	jalr	474(ra) # 80000ae0 <kalloc>
    8000490e:	892a                	mv	s2,a0
    80004910:	c125                	beqz	a0,80004970 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004912:	4985                	li	s3,1
    80004914:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004918:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000491c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004920:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004924:	00004597          	auipc	a1,0x4
    80004928:	e2458593          	addi	a1,a1,-476 # 80008748 <syscalls+0x288>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000494c:	000a3783          	ld	a5,0(s4)
    80004950:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004954:	000a3783          	ld	a5,0(s4)
    80004958:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000495c:	000a3783          	ld	a5,0(s4)
    80004960:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004964:	000a3783          	ld	a5,0(s4)
    80004968:	0127b823          	sd	s2,16(a5)
  return 0;
    8000496c:	4501                	li	a0,0
    8000496e:	a025                	j	80004996 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004970:	6088                	ld	a0,0(s1)
    80004972:	e501                	bnez	a0,8000497a <pipealloc+0xaa>
    80004974:	a039                	j	80004982 <pipealloc+0xb2>
    80004976:	6088                	ld	a0,0(s1)
    80004978:	c51d                	beqz	a0,800049a6 <pipealloc+0xd6>
    fileclose(*f0);
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	c26080e7          	jalr	-986(ra) # 800045a0 <fileclose>
  if(*f1)
    80004982:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004986:	557d                	li	a0,-1
  if(*f1)
    80004988:	c799                	beqz	a5,80004996 <pipealloc+0xc6>
    fileclose(*f1);
    8000498a:	853e                	mv	a0,a5
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	c14080e7          	jalr	-1004(ra) # 800045a0 <fileclose>
  return -1;
    80004994:	557d                	li	a0,-1
}
    80004996:	70a2                	ld	ra,40(sp)
    80004998:	7402                	ld	s0,32(sp)
    8000499a:	64e2                	ld	s1,24(sp)
    8000499c:	6942                	ld	s2,16(sp)
    8000499e:	69a2                	ld	s3,8(sp)
    800049a0:	6a02                	ld	s4,0(sp)
    800049a2:	6145                	addi	sp,sp,48
    800049a4:	8082                	ret
  return -1;
    800049a6:	557d                	li	a0,-1
    800049a8:	b7fd                	j	80004996 <pipealloc+0xc6>

00000000800049aa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	e04a                	sd	s2,0(sp)
    800049b4:	1000                	addi	s0,sp,32
    800049b6:	84aa                	mv	s1,a0
    800049b8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	216080e7          	jalr	534(ra) # 80000bd0 <acquire>
  if(writable){
    800049c2:	02090d63          	beqz	s2,800049fc <pipeclose+0x52>
    pi->writeopen = 0;
    800049c6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ca:	21848513          	addi	a0,s1,536
    800049ce:	ffffe097          	auipc	ra,0xffffe
    800049d2:	824080e7          	jalr	-2012(ra) # 800021f2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d6:	2204b783          	ld	a5,544(s1)
    800049da:	eb95                	bnez	a5,80004a0e <pipeclose+0x64>
    release(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>
    kfree((char*)pi);
    800049e6:	8526                	mv	a0,s1
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	ffa080e7          	jalr	-6(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800049f0:	60e2                	ld	ra,24(sp)
    800049f2:	6442                	ld	s0,16(sp)
    800049f4:	64a2                	ld	s1,8(sp)
    800049f6:	6902                	ld	s2,0(sp)
    800049f8:	6105                	addi	sp,sp,32
    800049fa:	8082                	ret
    pi->readopen = 0;
    800049fc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a00:	21c48513          	addi	a0,s1,540
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	7ee080e7          	jalr	2030(ra) # 800021f2 <wakeup>
    80004a0c:	b7e9                	j	800049d6 <pipeclose+0x2c>
    release(&pi->lock);
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	274080e7          	jalr	628(ra) # 80000c84 <release>
}
    80004a18:	bfe1                	j	800049f0 <pipeclose+0x46>

0000000080004a1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a1a:	711d                	addi	sp,sp,-96
    80004a1c:	ec86                	sd	ra,88(sp)
    80004a1e:	e8a2                	sd	s0,80(sp)
    80004a20:	e4a6                	sd	s1,72(sp)
    80004a22:	e0ca                	sd	s2,64(sp)
    80004a24:	fc4e                	sd	s3,56(sp)
    80004a26:	f852                	sd	s4,48(sp)
    80004a28:	f456                	sd	s5,40(sp)
    80004a2a:	f05a                	sd	s6,32(sp)
    80004a2c:	ec5e                	sd	s7,24(sp)
    80004a2e:	e862                	sd	s8,16(sp)
    80004a30:	1080                	addi	s0,sp,96
    80004a32:	84aa                	mv	s1,a0
    80004a34:	8aae                	mv	s5,a1
    80004a36:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a38:	ffffd097          	auipc	ra,0xffffd
    80004a3c:	f5e080e7          	jalr	-162(ra) # 80001996 <myproc>
    80004a40:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a42:	8526                	mv	a0,s1
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	18c080e7          	jalr	396(ra) # 80000bd0 <acquire>
  while(i < n){
    80004a4c:	0b405363          	blez	s4,80004af2 <pipewrite+0xd8>
  int i = 0;
    80004a50:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a52:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a54:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a58:	21c48b93          	addi	s7,s1,540
    80004a5c:	a089                	j	80004a9e <pipewrite+0x84>
      release(&pi->lock);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	224080e7          	jalr	548(ra) # 80000c84 <release>
      return -1;
    80004a68:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	60e6                	ld	ra,88(sp)
    80004a6e:	6446                	ld	s0,80(sp)
    80004a70:	64a6                	ld	s1,72(sp)
    80004a72:	6906                	ld	s2,64(sp)
    80004a74:	79e2                	ld	s3,56(sp)
    80004a76:	7a42                	ld	s4,48(sp)
    80004a78:	7aa2                	ld	s5,40(sp)
    80004a7a:	7b02                	ld	s6,32(sp)
    80004a7c:	6be2                	ld	s7,24(sp)
    80004a7e:	6c42                	ld	s8,16(sp)
    80004a80:	6125                	addi	sp,sp,96
    80004a82:	8082                	ret
      wakeup(&pi->nread);
    80004a84:	8562                	mv	a0,s8
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	76c080e7          	jalr	1900(ra) # 800021f2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a8e:	85a6                	mv	a1,s1
    80004a90:	855e                	mv	a0,s7
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	5d4080e7          	jalr	1492(ra) # 80002066 <sleep>
  while(i < n){
    80004a9a:	05495d63          	bge	s2,s4,80004af4 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a9e:	2204a783          	lw	a5,544(s1)
    80004aa2:	dfd5                	beqz	a5,80004a5e <pipewrite+0x44>
    80004aa4:	0289a783          	lw	a5,40(s3)
    80004aa8:	fbdd                	bnez	a5,80004a5e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004aaa:	2184a783          	lw	a5,536(s1)
    80004aae:	21c4a703          	lw	a4,540(s1)
    80004ab2:	2007879b          	addiw	a5,a5,512
    80004ab6:	fcf707e3          	beq	a4,a5,80004a84 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aba:	4685                	li	a3,1
    80004abc:	01590633          	add	a2,s2,s5
    80004ac0:	faf40593          	addi	a1,s0,-81
    80004ac4:	0509b503          	ld	a0,80(s3)
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	c1e080e7          	jalr	-994(ra) # 800016e6 <copyin>
    80004ad0:	03650263          	beq	a0,s6,80004af4 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ad4:	21c4a783          	lw	a5,540(s1)
    80004ad8:	0017871b          	addiw	a4,a5,1
    80004adc:	20e4ae23          	sw	a4,540(s1)
    80004ae0:	1ff7f793          	andi	a5,a5,511
    80004ae4:	97a6                	add	a5,a5,s1
    80004ae6:	faf44703          	lbu	a4,-81(s0)
    80004aea:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aee:	2905                	addiw	s2,s2,1
    80004af0:	b76d                	j	80004a9a <pipewrite+0x80>
  int i = 0;
    80004af2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004af4:	21848513          	addi	a0,s1,536
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	6fa080e7          	jalr	1786(ra) # 800021f2 <wakeup>
  release(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	182080e7          	jalr	386(ra) # 80000c84 <release>
  return i;
    80004b0a:	b785                	j	80004a6a <pipewrite+0x50>

0000000080004b0c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b0c:	715d                	addi	sp,sp,-80
    80004b0e:	e486                	sd	ra,72(sp)
    80004b10:	e0a2                	sd	s0,64(sp)
    80004b12:	fc26                	sd	s1,56(sp)
    80004b14:	f84a                	sd	s2,48(sp)
    80004b16:	f44e                	sd	s3,40(sp)
    80004b18:	f052                	sd	s4,32(sp)
    80004b1a:	ec56                	sd	s5,24(sp)
    80004b1c:	e85a                	sd	s6,16(sp)
    80004b1e:	0880                	addi	s0,sp,80
    80004b20:	84aa                	mv	s1,a0
    80004b22:	892e                	mv	s2,a1
    80004b24:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	e70080e7          	jalr	-400(ra) # 80001996 <myproc>
    80004b2e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	09e080e7          	jalr	158(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3a:	2184a703          	lw	a4,536(s1)
    80004b3e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b42:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b46:	02f71463          	bne	a4,a5,80004b6e <piperead+0x62>
    80004b4a:	2244a783          	lw	a5,548(s1)
    80004b4e:	c385                	beqz	a5,80004b6e <piperead+0x62>
    if(pr->killed){
    80004b50:	028a2783          	lw	a5,40(s4)
    80004b54:	ebc9                	bnez	a5,80004be6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b56:	85a6                	mv	a1,s1
    80004b58:	854e                	mv	a0,s3
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	50c080e7          	jalr	1292(ra) # 80002066 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b62:	2184a703          	lw	a4,536(s1)
    80004b66:	21c4a783          	lw	a5,540(s1)
    80004b6a:	fef700e3          	beq	a4,a5,80004b4a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b70:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b72:	05505463          	blez	s5,80004bba <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b76:	2184a783          	lw	a5,536(s1)
    80004b7a:	21c4a703          	lw	a4,540(s1)
    80004b7e:	02f70e63          	beq	a4,a5,80004bba <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b82:	0017871b          	addiw	a4,a5,1
    80004b86:	20e4ac23          	sw	a4,536(s1)
    80004b8a:	1ff7f793          	andi	a5,a5,511
    80004b8e:	97a6                	add	a5,a5,s1
    80004b90:	0187c783          	lbu	a5,24(a5)
    80004b94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b98:	4685                	li	a3,1
    80004b9a:	fbf40613          	addi	a2,s0,-65
    80004b9e:	85ca                	mv	a1,s2
    80004ba0:	050a3503          	ld	a0,80(s4)
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	ab6080e7          	jalr	-1354(ra) # 8000165a <copyout>
    80004bac:	01650763          	beq	a0,s6,80004bba <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb0:	2985                	addiw	s3,s3,1
    80004bb2:	0905                	addi	s2,s2,1
    80004bb4:	fd3a91e3          	bne	s5,s3,80004b76 <piperead+0x6a>
    80004bb8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bba:	21c48513          	addi	a0,s1,540
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	634080e7          	jalr	1588(ra) # 800021f2 <wakeup>
  release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0bc080e7          	jalr	188(ra) # 80000c84 <release>
  return i;
}
    80004bd0:	854e                	mv	a0,s3
    80004bd2:	60a6                	ld	ra,72(sp)
    80004bd4:	6406                	ld	s0,64(sp)
    80004bd6:	74e2                	ld	s1,56(sp)
    80004bd8:	7942                	ld	s2,48(sp)
    80004bda:	79a2                	ld	s3,40(sp)
    80004bdc:	7a02                	ld	s4,32(sp)
    80004bde:	6ae2                	ld	s5,24(sp)
    80004be0:	6b42                	ld	s6,16(sp)
    80004be2:	6161                	addi	sp,sp,80
    80004be4:	8082                	ret
      release(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	09c080e7          	jalr	156(ra) # 80000c84 <release>
      return -1;
    80004bf0:	59fd                	li	s3,-1
    80004bf2:	bff9                	j	80004bd0 <piperead+0xc4>

0000000080004bf4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bf4:	de010113          	addi	sp,sp,-544
    80004bf8:	20113c23          	sd	ra,536(sp)
    80004bfc:	20813823          	sd	s0,528(sp)
    80004c00:	20913423          	sd	s1,520(sp)
    80004c04:	21213023          	sd	s2,512(sp)
    80004c08:	ffce                	sd	s3,504(sp)
    80004c0a:	fbd2                	sd	s4,496(sp)
    80004c0c:	f7d6                	sd	s5,488(sp)
    80004c0e:	f3da                	sd	s6,480(sp)
    80004c10:	efde                	sd	s7,472(sp)
    80004c12:	ebe2                	sd	s8,464(sp)
    80004c14:	e7e6                	sd	s9,456(sp)
    80004c16:	e3ea                	sd	s10,448(sp)
    80004c18:	ff6e                	sd	s11,440(sp)
    80004c1a:	1400                	addi	s0,sp,544
    80004c1c:	892a                	mv	s2,a0
    80004c1e:	dea43423          	sd	a0,-536(s0)
    80004c22:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	d70080e7          	jalr	-656(ra) # 80001996 <myproc>
    80004c2e:	84aa                	mv	s1,a0

  begin_op();
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	4a8080e7          	jalr	1192(ra) # 800040d8 <begin_op>

  if((ip = namei(path)) == 0){
    80004c38:	854a                	mv	a0,s2
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	27e080e7          	jalr	638(ra) # 80003eb8 <namei>
    80004c42:	c93d                	beqz	a0,80004cb8 <exec+0xc4>
    80004c44:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	ab6080e7          	jalr	-1354(ra) # 800036fc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c4e:	04000713          	li	a4,64
    80004c52:	4681                	li	a3,0
    80004c54:	e5040613          	addi	a2,s0,-432
    80004c58:	4581                	li	a1,0
    80004c5a:	8556                	mv	a0,s5
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	d54080e7          	jalr	-684(ra) # 800039b0 <readi>
    80004c64:	04000793          	li	a5,64
    80004c68:	00f51a63          	bne	a0,a5,80004c7c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c6c:	e5042703          	lw	a4,-432(s0)
    80004c70:	464c47b7          	lui	a5,0x464c4
    80004c74:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c78:	04f70663          	beq	a4,a5,80004cc4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c7c:	8556                	mv	a0,s5
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	ce0080e7          	jalr	-800(ra) # 8000395e <iunlockput>
    end_op();
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	4d0080e7          	jalr	1232(ra) # 80004156 <end_op>
  }
  return -1;
    80004c8e:	557d                	li	a0,-1
}
    80004c90:	21813083          	ld	ra,536(sp)
    80004c94:	21013403          	ld	s0,528(sp)
    80004c98:	20813483          	ld	s1,520(sp)
    80004c9c:	20013903          	ld	s2,512(sp)
    80004ca0:	79fe                	ld	s3,504(sp)
    80004ca2:	7a5e                	ld	s4,496(sp)
    80004ca4:	7abe                	ld	s5,488(sp)
    80004ca6:	7b1e                	ld	s6,480(sp)
    80004ca8:	6bfe                	ld	s7,472(sp)
    80004caa:	6c5e                	ld	s8,464(sp)
    80004cac:	6cbe                	ld	s9,456(sp)
    80004cae:	6d1e                	ld	s10,448(sp)
    80004cb0:	7dfa                	ld	s11,440(sp)
    80004cb2:	22010113          	addi	sp,sp,544
    80004cb6:	8082                	ret
    end_op();
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	49e080e7          	jalr	1182(ra) # 80004156 <end_op>
    return -1;
    80004cc0:	557d                	li	a0,-1
    80004cc2:	b7f9                	j	80004c90 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	d94080e7          	jalr	-620(ra) # 80001a5a <proc_pagetable>
    80004cce:	8b2a                	mv	s6,a0
    80004cd0:	d555                	beqz	a0,80004c7c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd2:	e7042783          	lw	a5,-400(s0)
    80004cd6:	e8845703          	lhu	a4,-376(s0)
    80004cda:	c735                	beqz	a4,80004d46 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cdc:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cde:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004ce2:	6a05                	lui	s4,0x1
    80004ce4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ce8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004cec:	6d85                	lui	s11,0x1
    80004cee:	7d7d                	lui	s10,0xfffff
    80004cf0:	ac1d                	j	80004f26 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cf2:	00004517          	auipc	a0,0x4
    80004cf6:	a5e50513          	addi	a0,a0,-1442 # 80008750 <syscalls+0x290>
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	840080e7          	jalr	-1984(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d02:	874a                	mv	a4,s2
    80004d04:	009c86bb          	addw	a3,s9,s1
    80004d08:	4581                	li	a1,0
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	ca4080e7          	jalr	-860(ra) # 800039b0 <readi>
    80004d14:	2501                	sext.w	a0,a0
    80004d16:	1aa91863          	bne	s2,a0,80004ec6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d1a:	009d84bb          	addw	s1,s11,s1
    80004d1e:	013d09bb          	addw	s3,s10,s3
    80004d22:	1f74f263          	bgeu	s1,s7,80004f06 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d26:	02049593          	slli	a1,s1,0x20
    80004d2a:	9181                	srli	a1,a1,0x20
    80004d2c:	95e2                	add	a1,a1,s8
    80004d2e:	855a                	mv	a0,s6
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	322080e7          	jalr	802(ra) # 80001052 <walkaddr>
    80004d38:	862a                	mv	a2,a0
    if(pa == 0)
    80004d3a:	dd45                	beqz	a0,80004cf2 <exec+0xfe>
      n = PGSIZE;
    80004d3c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d3e:	fd49f2e3          	bgeu	s3,s4,80004d02 <exec+0x10e>
      n = sz - i;
    80004d42:	894e                	mv	s2,s3
    80004d44:	bf7d                	j	80004d02 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d46:	4481                	li	s1,0
  iunlockput(ip);
    80004d48:	8556                	mv	a0,s5
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	c14080e7          	jalr	-1004(ra) # 8000395e <iunlockput>
  end_op();
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	404080e7          	jalr	1028(ra) # 80004156 <end_op>
  p = myproc();
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	c3c080e7          	jalr	-964(ra) # 80001996 <myproc>
    80004d62:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d64:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d68:	6785                	lui	a5,0x1
    80004d6a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d6c:	97a6                	add	a5,a5,s1
    80004d6e:	777d                	lui	a4,0xfffff
    80004d70:	8ff9                	and	a5,a5,a4
    80004d72:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d76:	6609                	lui	a2,0x2
    80004d78:	963e                	add	a2,a2,a5
    80004d7a:	85be                	mv	a1,a5
    80004d7c:	855a                	mv	a0,s6
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	688080e7          	jalr	1672(ra) # 80001406 <uvmalloc>
    80004d86:	8c2a                	mv	s8,a0
  ip = 0;
    80004d88:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d8a:	12050e63          	beqz	a0,80004ec6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d8e:	75f9                	lui	a1,0xffffe
    80004d90:	95aa                	add	a1,a1,a0
    80004d92:	855a                	mv	a0,s6
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	894080e7          	jalr	-1900(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d9c:	7afd                	lui	s5,0xfffff
    80004d9e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004da0:	df043783          	ld	a5,-528(s0)
    80004da4:	6388                	ld	a0,0(a5)
    80004da6:	c925                	beqz	a0,80004e16 <exec+0x222>
    80004da8:	e9040993          	addi	s3,s0,-368
    80004dac:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004db0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004db2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	094080e7          	jalr	148(ra) # 80000e48 <strlen>
    80004dbc:	0015079b          	addiw	a5,a0,1
    80004dc0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dc4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dc8:	13596363          	bltu	s2,s5,80004eee <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dcc:	df043d83          	ld	s11,-528(s0)
    80004dd0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dd4:	8552                	mv	a0,s4
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	072080e7          	jalr	114(ra) # 80000e48 <strlen>
    80004dde:	0015069b          	addiw	a3,a0,1
    80004de2:	8652                	mv	a2,s4
    80004de4:	85ca                	mv	a1,s2
    80004de6:	855a                	mv	a0,s6
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	872080e7          	jalr	-1934(ra) # 8000165a <copyout>
    80004df0:	10054363          	bltz	a0,80004ef6 <exec+0x302>
    ustack[argc] = sp;
    80004df4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004df8:	0485                	addi	s1,s1,1
    80004dfa:	008d8793          	addi	a5,s11,8
    80004dfe:	def43823          	sd	a5,-528(s0)
    80004e02:	008db503          	ld	a0,8(s11)
    80004e06:	c911                	beqz	a0,80004e1a <exec+0x226>
    if(argc >= MAXARG)
    80004e08:	09a1                	addi	s3,s3,8
    80004e0a:	fb3c95e3          	bne	s9,s3,80004db4 <exec+0x1c0>
  sz = sz1;
    80004e0e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e12:	4a81                	li	s5,0
    80004e14:	a84d                	j	80004ec6 <exec+0x2d2>
  sp = sz;
    80004e16:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e18:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e1a:	00349793          	slli	a5,s1,0x3
    80004e1e:	f9078793          	addi	a5,a5,-112
    80004e22:	97a2                	add	a5,a5,s0
    80004e24:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e28:	00148693          	addi	a3,s1,1
    80004e2c:	068e                	slli	a3,a3,0x3
    80004e2e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e32:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e36:	01597663          	bgeu	s2,s5,80004e42 <exec+0x24e>
  sz = sz1;
    80004e3a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e3e:	4a81                	li	s5,0
    80004e40:	a059                	j	80004ec6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e42:	e9040613          	addi	a2,s0,-368
    80004e46:	85ca                	mv	a1,s2
    80004e48:	855a                	mv	a0,s6
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	810080e7          	jalr	-2032(ra) # 8000165a <copyout>
    80004e52:	0a054663          	bltz	a0,80004efe <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e56:	058bb783          	ld	a5,88(s7)
    80004e5a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e5e:	de843783          	ld	a5,-536(s0)
    80004e62:	0007c703          	lbu	a4,0(a5)
    80004e66:	cf11                	beqz	a4,80004e82 <exec+0x28e>
    80004e68:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e6a:	02f00693          	li	a3,47
    80004e6e:	a039                	j	80004e7c <exec+0x288>
      last = s+1;
    80004e70:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e74:	0785                	addi	a5,a5,1
    80004e76:	fff7c703          	lbu	a4,-1(a5)
    80004e7a:	c701                	beqz	a4,80004e82 <exec+0x28e>
    if(*s == '/')
    80004e7c:	fed71ce3          	bne	a4,a3,80004e74 <exec+0x280>
    80004e80:	bfc5                	j	80004e70 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e82:	4641                	li	a2,16
    80004e84:	de843583          	ld	a1,-536(s0)
    80004e88:	158b8513          	addi	a0,s7,344
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	f8a080e7          	jalr	-118(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e94:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e98:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e9c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ea0:	058bb783          	ld	a5,88(s7)
    80004ea4:	e6843703          	ld	a4,-408(s0)
    80004ea8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eaa:	058bb783          	ld	a5,88(s7)
    80004eae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eb2:	85ea                	mv	a1,s10
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	c42080e7          	jalr	-958(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ebc:	0004851b          	sext.w	a0,s1
    80004ec0:	bbc1                	j	80004c90 <exec+0x9c>
    80004ec2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ec6:	df843583          	ld	a1,-520(s0)
    80004eca:	855a                	mv	a0,s6
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	c2a080e7          	jalr	-982(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004ed4:	da0a94e3          	bnez	s5,80004c7c <exec+0x88>
  return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	bb5d                	j	80004c90 <exec+0x9c>
    80004edc:	de943c23          	sd	s1,-520(s0)
    80004ee0:	b7dd                	j	80004ec6 <exec+0x2d2>
    80004ee2:	de943c23          	sd	s1,-520(s0)
    80004ee6:	b7c5                	j	80004ec6 <exec+0x2d2>
    80004ee8:	de943c23          	sd	s1,-520(s0)
    80004eec:	bfe9                	j	80004ec6 <exec+0x2d2>
  sz = sz1;
    80004eee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef2:	4a81                	li	s5,0
    80004ef4:	bfc9                	j	80004ec6 <exec+0x2d2>
  sz = sz1;
    80004ef6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efa:	4a81                	li	s5,0
    80004efc:	b7e9                	j	80004ec6 <exec+0x2d2>
  sz = sz1;
    80004efe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f02:	4a81                	li	s5,0
    80004f04:	b7c9                	j	80004ec6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f06:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f0a:	e0843783          	ld	a5,-504(s0)
    80004f0e:	0017869b          	addiw	a3,a5,1
    80004f12:	e0d43423          	sd	a3,-504(s0)
    80004f16:	e0043783          	ld	a5,-512(s0)
    80004f1a:	0387879b          	addiw	a5,a5,56
    80004f1e:	e8845703          	lhu	a4,-376(s0)
    80004f22:	e2e6d3e3          	bge	a3,a4,80004d48 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f26:	2781                	sext.w	a5,a5
    80004f28:	e0f43023          	sd	a5,-512(s0)
    80004f2c:	03800713          	li	a4,56
    80004f30:	86be                	mv	a3,a5
    80004f32:	e1840613          	addi	a2,s0,-488
    80004f36:	4581                	li	a1,0
    80004f38:	8556                	mv	a0,s5
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	a76080e7          	jalr	-1418(ra) # 800039b0 <readi>
    80004f42:	03800793          	li	a5,56
    80004f46:	f6f51ee3          	bne	a0,a5,80004ec2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f4a:	e1842783          	lw	a5,-488(s0)
    80004f4e:	4705                	li	a4,1
    80004f50:	fae79de3          	bne	a5,a4,80004f0a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f54:	e4043603          	ld	a2,-448(s0)
    80004f58:	e3843783          	ld	a5,-456(s0)
    80004f5c:	f8f660e3          	bltu	a2,a5,80004edc <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f60:	e2843783          	ld	a5,-472(s0)
    80004f64:	963e                	add	a2,a2,a5
    80004f66:	f6f66ee3          	bltu	a2,a5,80004ee2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f6a:	85a6                	mv	a1,s1
    80004f6c:	855a                	mv	a0,s6
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	498080e7          	jalr	1176(ra) # 80001406 <uvmalloc>
    80004f76:	dea43c23          	sd	a0,-520(s0)
    80004f7a:	d53d                	beqz	a0,80004ee8 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004f7c:	e2843c03          	ld	s8,-472(s0)
    80004f80:	de043783          	ld	a5,-544(s0)
    80004f84:	00fc77b3          	and	a5,s8,a5
    80004f88:	ff9d                	bnez	a5,80004ec6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f8a:	e2042c83          	lw	s9,-480(s0)
    80004f8e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f92:	f60b8ae3          	beqz	s7,80004f06 <exec+0x312>
    80004f96:	89de                	mv	s3,s7
    80004f98:	4481                	li	s1,0
    80004f9a:	b371                	j	80004d26 <exec+0x132>

0000000080004f9c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f9c:	7179                	addi	sp,sp,-48
    80004f9e:	f406                	sd	ra,40(sp)
    80004fa0:	f022                	sd	s0,32(sp)
    80004fa2:	ec26                	sd	s1,24(sp)
    80004fa4:	e84a                	sd	s2,16(sp)
    80004fa6:	1800                	addi	s0,sp,48
    80004fa8:	892e                	mv	s2,a1
    80004faa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fac:	fdc40593          	addi	a1,s0,-36
    80004fb0:	ffffe097          	auipc	ra,0xffffe
    80004fb4:	ba0080e7          	jalr	-1120(ra) # 80002b50 <argint>
    80004fb8:	04054063          	bltz	a0,80004ff8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fbc:	fdc42703          	lw	a4,-36(s0)
    80004fc0:	47bd                	li	a5,15
    80004fc2:	02e7ed63          	bltu	a5,a4,80004ffc <argfd+0x60>
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	9d0080e7          	jalr	-1584(ra) # 80001996 <myproc>
    80004fce:	fdc42703          	lw	a4,-36(s0)
    80004fd2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fd6:	078e                	slli	a5,a5,0x3
    80004fd8:	953e                	add	a0,a0,a5
    80004fda:	611c                	ld	a5,0(a0)
    80004fdc:	c395                	beqz	a5,80005000 <argfd+0x64>
    return -1;
  if(pfd)
    80004fde:	00090463          	beqz	s2,80004fe6 <argfd+0x4a>
    *pfd = fd;
    80004fe2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fe6:	4501                	li	a0,0
  if(pf)
    80004fe8:	c091                	beqz	s1,80004fec <argfd+0x50>
    *pf = f;
    80004fea:	e09c                	sd	a5,0(s1)
}
    80004fec:	70a2                	ld	ra,40(sp)
    80004fee:	7402                	ld	s0,32(sp)
    80004ff0:	64e2                	ld	s1,24(sp)
    80004ff2:	6942                	ld	s2,16(sp)
    80004ff4:	6145                	addi	sp,sp,48
    80004ff6:	8082                	ret
    return -1;
    80004ff8:	557d                	li	a0,-1
    80004ffa:	bfcd                	j	80004fec <argfd+0x50>
    return -1;
    80004ffc:	557d                	li	a0,-1
    80004ffe:	b7fd                	j	80004fec <argfd+0x50>
    80005000:	557d                	li	a0,-1
    80005002:	b7ed                	j	80004fec <argfd+0x50>

0000000080005004 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005004:	1101                	addi	sp,sp,-32
    80005006:	ec06                	sd	ra,24(sp)
    80005008:	e822                	sd	s0,16(sp)
    8000500a:	e426                	sd	s1,8(sp)
    8000500c:	1000                	addi	s0,sp,32
    8000500e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	986080e7          	jalr	-1658(ra) # 80001996 <myproc>
    80005018:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000501a:	0d050793          	addi	a5,a0,208
    8000501e:	4501                	li	a0,0
    80005020:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005022:	6398                	ld	a4,0(a5)
    80005024:	cb19                	beqz	a4,8000503a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005026:	2505                	addiw	a0,a0,1
    80005028:	07a1                	addi	a5,a5,8
    8000502a:	fed51ce3          	bne	a0,a3,80005022 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000502e:	557d                	li	a0,-1
}
    80005030:	60e2                	ld	ra,24(sp)
    80005032:	6442                	ld	s0,16(sp)
    80005034:	64a2                	ld	s1,8(sp)
    80005036:	6105                	addi	sp,sp,32
    80005038:	8082                	ret
      p->ofile[fd] = f;
    8000503a:	01a50793          	addi	a5,a0,26
    8000503e:	078e                	slli	a5,a5,0x3
    80005040:	963e                	add	a2,a2,a5
    80005042:	e204                	sd	s1,0(a2)
      return fd;
    80005044:	b7f5                	j	80005030 <fdalloc+0x2c>

0000000080005046 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005046:	715d                	addi	sp,sp,-80
    80005048:	e486                	sd	ra,72(sp)
    8000504a:	e0a2                	sd	s0,64(sp)
    8000504c:	fc26                	sd	s1,56(sp)
    8000504e:	f84a                	sd	s2,48(sp)
    80005050:	f44e                	sd	s3,40(sp)
    80005052:	f052                	sd	s4,32(sp)
    80005054:	ec56                	sd	s5,24(sp)
    80005056:	0880                	addi	s0,sp,80
    80005058:	89ae                	mv	s3,a1
    8000505a:	8ab2                	mv	s5,a2
    8000505c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000505e:	fb040593          	addi	a1,s0,-80
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	e74080e7          	jalr	-396(ra) # 80003ed6 <nameiparent>
    8000506a:	892a                	mv	s2,a0
    8000506c:	12050e63          	beqz	a0,800051a8 <create+0x162>
    return 0;

  ilock(dp);
    80005070:	ffffe097          	auipc	ra,0xffffe
    80005074:	68c080e7          	jalr	1676(ra) # 800036fc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005078:	4601                	li	a2,0
    8000507a:	fb040593          	addi	a1,s0,-80
    8000507e:	854a                	mv	a0,s2
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	b60080e7          	jalr	-1184(ra) # 80003be0 <dirlookup>
    80005088:	84aa                	mv	s1,a0
    8000508a:	c921                	beqz	a0,800050da <create+0x94>
    iunlockput(dp);
    8000508c:	854a                	mv	a0,s2
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	8d0080e7          	jalr	-1840(ra) # 8000395e <iunlockput>
    ilock(ip);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	664080e7          	jalr	1636(ra) # 800036fc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050a0:	2981                	sext.w	s3,s3
    800050a2:	4789                	li	a5,2
    800050a4:	02f99463          	bne	s3,a5,800050cc <create+0x86>
    800050a8:	0444d783          	lhu	a5,68(s1)
    800050ac:	37f9                	addiw	a5,a5,-2
    800050ae:	17c2                	slli	a5,a5,0x30
    800050b0:	93c1                	srli	a5,a5,0x30
    800050b2:	4705                	li	a4,1
    800050b4:	00f76c63          	bltu	a4,a5,800050cc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050b8:	8526                	mv	a0,s1
    800050ba:	60a6                	ld	ra,72(sp)
    800050bc:	6406                	ld	s0,64(sp)
    800050be:	74e2                	ld	s1,56(sp)
    800050c0:	7942                	ld	s2,48(sp)
    800050c2:	79a2                	ld	s3,40(sp)
    800050c4:	7a02                	ld	s4,32(sp)
    800050c6:	6ae2                	ld	s5,24(sp)
    800050c8:	6161                	addi	sp,sp,80
    800050ca:	8082                	ret
    iunlockput(ip);
    800050cc:	8526                	mv	a0,s1
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	890080e7          	jalr	-1904(ra) # 8000395e <iunlockput>
    return 0;
    800050d6:	4481                	li	s1,0
    800050d8:	b7c5                	j	800050b8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050da:	85ce                	mv	a1,s3
    800050dc:	00092503          	lw	a0,0(s2)
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	482080e7          	jalr	1154(ra) # 80003562 <ialloc>
    800050e8:	84aa                	mv	s1,a0
    800050ea:	c521                	beqz	a0,80005132 <create+0xec>
  ilock(ip);
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	610080e7          	jalr	1552(ra) # 800036fc <ilock>
  ip->major = major;
    800050f4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050f8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050fc:	4a05                	li	s4,1
    800050fe:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005102:	8526                	mv	a0,s1
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	52c080e7          	jalr	1324(ra) # 80003630 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000510c:	2981                	sext.w	s3,s3
    8000510e:	03498a63          	beq	s3,s4,80005142 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005112:	40d0                	lw	a2,4(s1)
    80005114:	fb040593          	addi	a1,s0,-80
    80005118:	854a                	mv	a0,s2
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	cdc080e7          	jalr	-804(ra) # 80003df6 <dirlink>
    80005122:	06054b63          	bltz	a0,80005198 <create+0x152>
  iunlockput(dp);
    80005126:	854a                	mv	a0,s2
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	836080e7          	jalr	-1994(ra) # 8000395e <iunlockput>
  return ip;
    80005130:	b761                	j	800050b8 <create+0x72>
    panic("create: ialloc");
    80005132:	00003517          	auipc	a0,0x3
    80005136:	63e50513          	addi	a0,a0,1598 # 80008770 <syscalls+0x2b0>
    8000513a:	ffffb097          	auipc	ra,0xffffb
    8000513e:	400080e7          	jalr	1024(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005142:	04a95783          	lhu	a5,74(s2)
    80005146:	2785                	addiw	a5,a5,1
    80005148:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000514c:	854a                	mv	a0,s2
    8000514e:	ffffe097          	auipc	ra,0xffffe
    80005152:	4e2080e7          	jalr	1250(ra) # 80003630 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005156:	40d0                	lw	a2,4(s1)
    80005158:	00003597          	auipc	a1,0x3
    8000515c:	62858593          	addi	a1,a1,1576 # 80008780 <syscalls+0x2c0>
    80005160:	8526                	mv	a0,s1
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	c94080e7          	jalr	-876(ra) # 80003df6 <dirlink>
    8000516a:	00054f63          	bltz	a0,80005188 <create+0x142>
    8000516e:	00492603          	lw	a2,4(s2)
    80005172:	00003597          	auipc	a1,0x3
    80005176:	61658593          	addi	a1,a1,1558 # 80008788 <syscalls+0x2c8>
    8000517a:	8526                	mv	a0,s1
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	c7a080e7          	jalr	-902(ra) # 80003df6 <dirlink>
    80005184:	f80557e3          	bgez	a0,80005112 <create+0xcc>
      panic("create dots");
    80005188:	00003517          	auipc	a0,0x3
    8000518c:	60850513          	addi	a0,a0,1544 # 80008790 <syscalls+0x2d0>
    80005190:	ffffb097          	auipc	ra,0xffffb
    80005194:	3aa080e7          	jalr	938(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005198:	00003517          	auipc	a0,0x3
    8000519c:	60850513          	addi	a0,a0,1544 # 800087a0 <syscalls+0x2e0>
    800051a0:	ffffb097          	auipc	ra,0xffffb
    800051a4:	39a080e7          	jalr	922(ra) # 8000053a <panic>
    return 0;
    800051a8:	84aa                	mv	s1,a0
    800051aa:	b739                	j	800050b8 <create+0x72>

00000000800051ac <sys_dup>:
{
    800051ac:	7179                	addi	sp,sp,-48
    800051ae:	f406                	sd	ra,40(sp)
    800051b0:	f022                	sd	s0,32(sp)
    800051b2:	ec26                	sd	s1,24(sp)
    800051b4:	e84a                	sd	s2,16(sp)
    800051b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051b8:	fd840613          	addi	a2,s0,-40
    800051bc:	4581                	li	a1,0
    800051be:	4501                	li	a0,0
    800051c0:	00000097          	auipc	ra,0x0
    800051c4:	ddc080e7          	jalr	-548(ra) # 80004f9c <argfd>
    return -1;
    800051c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ca:	02054363          	bltz	a0,800051f0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051ce:	fd843903          	ld	s2,-40(s0)
    800051d2:	854a                	mv	a0,s2
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	e30080e7          	jalr	-464(ra) # 80005004 <fdalloc>
    800051dc:	84aa                	mv	s1,a0
    return -1;
    800051de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051e0:	00054863          	bltz	a0,800051f0 <sys_dup+0x44>
  filedup(f);
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	368080e7          	jalr	872(ra) # 8000454e <filedup>
  return fd;
    800051ee:	87a6                	mv	a5,s1
}
    800051f0:	853e                	mv	a0,a5
    800051f2:	70a2                	ld	ra,40(sp)
    800051f4:	7402                	ld	s0,32(sp)
    800051f6:	64e2                	ld	s1,24(sp)
    800051f8:	6942                	ld	s2,16(sp)
    800051fa:	6145                	addi	sp,sp,48
    800051fc:	8082                	ret

00000000800051fe <sys_read>:
{
    800051fe:	7179                	addi	sp,sp,-48
    80005200:	f406                	sd	ra,40(sp)
    80005202:	f022                	sd	s0,32(sp)
    80005204:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005206:	fe840613          	addi	a2,s0,-24
    8000520a:	4581                	li	a1,0
    8000520c:	4501                	li	a0,0
    8000520e:	00000097          	auipc	ra,0x0
    80005212:	d8e080e7          	jalr	-626(ra) # 80004f9c <argfd>
    return -1;
    80005216:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005218:	04054163          	bltz	a0,8000525a <sys_read+0x5c>
    8000521c:	fe440593          	addi	a1,s0,-28
    80005220:	4509                	li	a0,2
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	92e080e7          	jalr	-1746(ra) # 80002b50 <argint>
    return -1;
    8000522a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522c:	02054763          	bltz	a0,8000525a <sys_read+0x5c>
    80005230:	fd840593          	addi	a1,s0,-40
    80005234:	4505                	li	a0,1
    80005236:	ffffe097          	auipc	ra,0xffffe
    8000523a:	93c080e7          	jalr	-1732(ra) # 80002b72 <argaddr>
    return -1;
    8000523e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005240:	00054d63          	bltz	a0,8000525a <sys_read+0x5c>
  return fileread(f, p, n);
    80005244:	fe442603          	lw	a2,-28(s0)
    80005248:	fd843583          	ld	a1,-40(s0)
    8000524c:	fe843503          	ld	a0,-24(s0)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	48a080e7          	jalr	1162(ra) # 800046da <fileread>
    80005258:	87aa                	mv	a5,a0
}
    8000525a:	853e                	mv	a0,a5
    8000525c:	70a2                	ld	ra,40(sp)
    8000525e:	7402                	ld	s0,32(sp)
    80005260:	6145                	addi	sp,sp,48
    80005262:	8082                	ret

0000000080005264 <sys_write>:
{
    80005264:	7179                	addi	sp,sp,-48
    80005266:	f406                	sd	ra,40(sp)
    80005268:	f022                	sd	s0,32(sp)
    8000526a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	fe840613          	addi	a2,s0,-24
    80005270:	4581                	li	a1,0
    80005272:	4501                	li	a0,0
    80005274:	00000097          	auipc	ra,0x0
    80005278:	d28080e7          	jalr	-728(ra) # 80004f9c <argfd>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	04054163          	bltz	a0,800052c0 <sys_write+0x5c>
    80005282:	fe440593          	addi	a1,s0,-28
    80005286:	4509                	li	a0,2
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	8c8080e7          	jalr	-1848(ra) # 80002b50 <argint>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	02054763          	bltz	a0,800052c0 <sys_write+0x5c>
    80005296:	fd840593          	addi	a1,s0,-40
    8000529a:	4505                	li	a0,1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	8d6080e7          	jalr	-1834(ra) # 80002b72 <argaddr>
    return -1;
    800052a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	00054d63          	bltz	a0,800052c0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052aa:	fe442603          	lw	a2,-28(s0)
    800052ae:	fd843583          	ld	a1,-40(s0)
    800052b2:	fe843503          	ld	a0,-24(s0)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	4e6080e7          	jalr	1254(ra) # 8000479c <filewrite>
    800052be:	87aa                	mv	a5,a0
}
    800052c0:	853e                	mv	a0,a5
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	6145                	addi	sp,sp,48
    800052c8:	8082                	ret

00000000800052ca <sys_close>:
{
    800052ca:	1101                	addi	sp,sp,-32
    800052cc:	ec06                	sd	ra,24(sp)
    800052ce:	e822                	sd	s0,16(sp)
    800052d0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052d2:	fe040613          	addi	a2,s0,-32
    800052d6:	fec40593          	addi	a1,s0,-20
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	cc0080e7          	jalr	-832(ra) # 80004f9c <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052e6:	02054463          	bltz	a0,8000530e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	6ac080e7          	jalr	1708(ra) # 80001996 <myproc>
    800052f2:	fec42783          	lw	a5,-20(s0)
    800052f6:	07e9                	addi	a5,a5,26
    800052f8:	078e                	slli	a5,a5,0x3
    800052fa:	953e                	add	a0,a0,a5
    800052fc:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005300:	fe043503          	ld	a0,-32(s0)
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	29c080e7          	jalr	668(ra) # 800045a0 <fileclose>
  return 0;
    8000530c:	4781                	li	a5,0
}
    8000530e:	853e                	mv	a0,a5
    80005310:	60e2                	ld	ra,24(sp)
    80005312:	6442                	ld	s0,16(sp)
    80005314:	6105                	addi	sp,sp,32
    80005316:	8082                	ret

0000000080005318 <sys_fstat>:
{
    80005318:	1101                	addi	sp,sp,-32
    8000531a:	ec06                	sd	ra,24(sp)
    8000531c:	e822                	sd	s0,16(sp)
    8000531e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005320:	fe840613          	addi	a2,s0,-24
    80005324:	4581                	li	a1,0
    80005326:	4501                	li	a0,0
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	c74080e7          	jalr	-908(ra) # 80004f9c <argfd>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005332:	02054563          	bltz	a0,8000535c <sys_fstat+0x44>
    80005336:	fe040593          	addi	a1,s0,-32
    8000533a:	4505                	li	a0,1
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	836080e7          	jalr	-1994(ra) # 80002b72 <argaddr>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005346:	00054b63          	bltz	a0,8000535c <sys_fstat+0x44>
  return filestat(f, st);
    8000534a:	fe043583          	ld	a1,-32(s0)
    8000534e:	fe843503          	ld	a0,-24(s0)
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	316080e7          	jalr	790(ra) # 80004668 <filestat>
    8000535a:	87aa                	mv	a5,a0
}
    8000535c:	853e                	mv	a0,a5
    8000535e:	60e2                	ld	ra,24(sp)
    80005360:	6442                	ld	s0,16(sp)
    80005362:	6105                	addi	sp,sp,32
    80005364:	8082                	ret

0000000080005366 <sys_link>:
{
    80005366:	7169                	addi	sp,sp,-304
    80005368:	f606                	sd	ra,296(sp)
    8000536a:	f222                	sd	s0,288(sp)
    8000536c:	ee26                	sd	s1,280(sp)
    8000536e:	ea4a                	sd	s2,272(sp)
    80005370:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005372:	08000613          	li	a2,128
    80005376:	ed040593          	addi	a1,s0,-304
    8000537a:	4501                	li	a0,0
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	818080e7          	jalr	-2024(ra) # 80002b94 <argstr>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005386:	10054e63          	bltz	a0,800054a2 <sys_link+0x13c>
    8000538a:	08000613          	li	a2,128
    8000538e:	f5040593          	addi	a1,s0,-176
    80005392:	4505                	li	a0,1
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	800080e7          	jalr	-2048(ra) # 80002b94 <argstr>
    return -1;
    8000539c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000539e:	10054263          	bltz	a0,800054a2 <sys_link+0x13c>
  begin_op();
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	d36080e7          	jalr	-714(ra) # 800040d8 <begin_op>
  if((ip = namei(old)) == 0){
    800053aa:	ed040513          	addi	a0,s0,-304
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	b0a080e7          	jalr	-1270(ra) # 80003eb8 <namei>
    800053b6:	84aa                	mv	s1,a0
    800053b8:	c551                	beqz	a0,80005444 <sys_link+0xde>
  ilock(ip);
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	342080e7          	jalr	834(ra) # 800036fc <ilock>
  if(ip->type == T_DIR){
    800053c2:	04449703          	lh	a4,68(s1)
    800053c6:	4785                	li	a5,1
    800053c8:	08f70463          	beq	a4,a5,80005450 <sys_link+0xea>
  ip->nlink++;
    800053cc:	04a4d783          	lhu	a5,74(s1)
    800053d0:	2785                	addiw	a5,a5,1
    800053d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053d6:	8526                	mv	a0,s1
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	258080e7          	jalr	600(ra) # 80003630 <iupdate>
  iunlock(ip);
    800053e0:	8526                	mv	a0,s1
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	3dc080e7          	jalr	988(ra) # 800037be <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ea:	fd040593          	addi	a1,s0,-48
    800053ee:	f5040513          	addi	a0,s0,-176
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	ae4080e7          	jalr	-1308(ra) # 80003ed6 <nameiparent>
    800053fa:	892a                	mv	s2,a0
    800053fc:	c935                	beqz	a0,80005470 <sys_link+0x10a>
  ilock(dp);
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	2fe080e7          	jalr	766(ra) # 800036fc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005406:	00092703          	lw	a4,0(s2)
    8000540a:	409c                	lw	a5,0(s1)
    8000540c:	04f71d63          	bne	a4,a5,80005466 <sys_link+0x100>
    80005410:	40d0                	lw	a2,4(s1)
    80005412:	fd040593          	addi	a1,s0,-48
    80005416:	854a                	mv	a0,s2
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	9de080e7          	jalr	-1570(ra) # 80003df6 <dirlink>
    80005420:	04054363          	bltz	a0,80005466 <sys_link+0x100>
  iunlockput(dp);
    80005424:	854a                	mv	a0,s2
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	538080e7          	jalr	1336(ra) # 8000395e <iunlockput>
  iput(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	486080e7          	jalr	1158(ra) # 800038b6 <iput>
  end_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	d1e080e7          	jalr	-738(ra) # 80004156 <end_op>
  return 0;
    80005440:	4781                	li	a5,0
    80005442:	a085                	j	800054a2 <sys_link+0x13c>
    end_op();
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	d12080e7          	jalr	-750(ra) # 80004156 <end_op>
    return -1;
    8000544c:	57fd                	li	a5,-1
    8000544e:	a891                	j	800054a2 <sys_link+0x13c>
    iunlockput(ip);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	50c080e7          	jalr	1292(ra) # 8000395e <iunlockput>
    end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	cfc080e7          	jalr	-772(ra) # 80004156 <end_op>
    return -1;
    80005462:	57fd                	li	a5,-1
    80005464:	a83d                	j	800054a2 <sys_link+0x13c>
    iunlockput(dp);
    80005466:	854a                	mv	a0,s2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	4f6080e7          	jalr	1270(ra) # 8000395e <iunlockput>
  ilock(ip);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	28a080e7          	jalr	650(ra) # 800036fc <ilock>
  ip->nlink--;
    8000547a:	04a4d783          	lhu	a5,74(s1)
    8000547e:	37fd                	addiw	a5,a5,-1
    80005480:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	1aa080e7          	jalr	426(ra) # 80003630 <iupdate>
  iunlockput(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	4ce080e7          	jalr	1230(ra) # 8000395e <iunlockput>
  end_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	cbe080e7          	jalr	-834(ra) # 80004156 <end_op>
  return -1;
    800054a0:	57fd                	li	a5,-1
}
    800054a2:	853e                	mv	a0,a5
    800054a4:	70b2                	ld	ra,296(sp)
    800054a6:	7412                	ld	s0,288(sp)
    800054a8:	64f2                	ld	s1,280(sp)
    800054aa:	6952                	ld	s2,272(sp)
    800054ac:	6155                	addi	sp,sp,304
    800054ae:	8082                	ret

00000000800054b0 <sys_unlink>:
{
    800054b0:	7151                	addi	sp,sp,-240
    800054b2:	f586                	sd	ra,232(sp)
    800054b4:	f1a2                	sd	s0,224(sp)
    800054b6:	eda6                	sd	s1,216(sp)
    800054b8:	e9ca                	sd	s2,208(sp)
    800054ba:	e5ce                	sd	s3,200(sp)
    800054bc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054be:	08000613          	li	a2,128
    800054c2:	f3040593          	addi	a1,s0,-208
    800054c6:	4501                	li	a0,0
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	6cc080e7          	jalr	1740(ra) # 80002b94 <argstr>
    800054d0:	18054163          	bltz	a0,80005652 <sys_unlink+0x1a2>
  begin_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	c04080e7          	jalr	-1020(ra) # 800040d8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054dc:	fb040593          	addi	a1,s0,-80
    800054e0:	f3040513          	addi	a0,s0,-208
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	9f2080e7          	jalr	-1550(ra) # 80003ed6 <nameiparent>
    800054ec:	84aa                	mv	s1,a0
    800054ee:	c979                	beqz	a0,800055c4 <sys_unlink+0x114>
  ilock(dp);
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	20c080e7          	jalr	524(ra) # 800036fc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054f8:	00003597          	auipc	a1,0x3
    800054fc:	28858593          	addi	a1,a1,648 # 80008780 <syscalls+0x2c0>
    80005500:	fb040513          	addi	a0,s0,-80
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	6c2080e7          	jalr	1730(ra) # 80003bc6 <namecmp>
    8000550c:	14050a63          	beqz	a0,80005660 <sys_unlink+0x1b0>
    80005510:	00003597          	auipc	a1,0x3
    80005514:	27858593          	addi	a1,a1,632 # 80008788 <syscalls+0x2c8>
    80005518:	fb040513          	addi	a0,s0,-80
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	6aa080e7          	jalr	1706(ra) # 80003bc6 <namecmp>
    80005524:	12050e63          	beqz	a0,80005660 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005528:	f2c40613          	addi	a2,s0,-212
    8000552c:	fb040593          	addi	a1,s0,-80
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	6ae080e7          	jalr	1710(ra) # 80003be0 <dirlookup>
    8000553a:	892a                	mv	s2,a0
    8000553c:	12050263          	beqz	a0,80005660 <sys_unlink+0x1b0>
  ilock(ip);
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	1bc080e7          	jalr	444(ra) # 800036fc <ilock>
  if(ip->nlink < 1)
    80005548:	04a91783          	lh	a5,74(s2)
    8000554c:	08f05263          	blez	a5,800055d0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005550:	04491703          	lh	a4,68(s2)
    80005554:	4785                	li	a5,1
    80005556:	08f70563          	beq	a4,a5,800055e0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000555a:	4641                	li	a2,16
    8000555c:	4581                	li	a1,0
    8000555e:	fc040513          	addi	a0,s0,-64
    80005562:	ffffb097          	auipc	ra,0xffffb
    80005566:	76a080e7          	jalr	1898(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000556a:	4741                	li	a4,16
    8000556c:	f2c42683          	lw	a3,-212(s0)
    80005570:	fc040613          	addi	a2,s0,-64
    80005574:	4581                	li	a1,0
    80005576:	8526                	mv	a0,s1
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	530080e7          	jalr	1328(ra) # 80003aa8 <writei>
    80005580:	47c1                	li	a5,16
    80005582:	0af51563          	bne	a0,a5,8000562c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005586:	04491703          	lh	a4,68(s2)
    8000558a:	4785                	li	a5,1
    8000558c:	0af70863          	beq	a4,a5,8000563c <sys_unlink+0x18c>
  iunlockput(dp);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	3cc080e7          	jalr	972(ra) # 8000395e <iunlockput>
  ip->nlink--;
    8000559a:	04a95783          	lhu	a5,74(s2)
    8000559e:	37fd                	addiw	a5,a5,-1
    800055a0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055a4:	854a                	mv	a0,s2
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	08a080e7          	jalr	138(ra) # 80003630 <iupdate>
  iunlockput(ip);
    800055ae:	854a                	mv	a0,s2
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	3ae080e7          	jalr	942(ra) # 8000395e <iunlockput>
  end_op();
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	b9e080e7          	jalr	-1122(ra) # 80004156 <end_op>
  return 0;
    800055c0:	4501                	li	a0,0
    800055c2:	a84d                	j	80005674 <sys_unlink+0x1c4>
    end_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	b92080e7          	jalr	-1134(ra) # 80004156 <end_op>
    return -1;
    800055cc:	557d                	li	a0,-1
    800055ce:	a05d                	j	80005674 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055d0:	00003517          	auipc	a0,0x3
    800055d4:	1e050513          	addi	a0,a0,480 # 800087b0 <syscalls+0x2f0>
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e0:	04c92703          	lw	a4,76(s2)
    800055e4:	02000793          	li	a5,32
    800055e8:	f6e7f9e3          	bgeu	a5,a4,8000555a <sys_unlink+0xaa>
    800055ec:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f0:	4741                	li	a4,16
    800055f2:	86ce                	mv	a3,s3
    800055f4:	f1840613          	addi	a2,s0,-232
    800055f8:	4581                	li	a1,0
    800055fa:	854a                	mv	a0,s2
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	3b4080e7          	jalr	948(ra) # 800039b0 <readi>
    80005604:	47c1                	li	a5,16
    80005606:	00f51b63          	bne	a0,a5,8000561c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000560a:	f1845783          	lhu	a5,-232(s0)
    8000560e:	e7a1                	bnez	a5,80005656 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005610:	29c1                	addiw	s3,s3,16
    80005612:	04c92783          	lw	a5,76(s2)
    80005616:	fcf9ede3          	bltu	s3,a5,800055f0 <sys_unlink+0x140>
    8000561a:	b781                	j	8000555a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000561c:	00003517          	auipc	a0,0x3
    80005620:	1ac50513          	addi	a0,a0,428 # 800087c8 <syscalls+0x308>
    80005624:	ffffb097          	auipc	ra,0xffffb
    80005628:	f16080e7          	jalr	-234(ra) # 8000053a <panic>
    panic("unlink: writei");
    8000562c:	00003517          	auipc	a0,0x3
    80005630:	1b450513          	addi	a0,a0,436 # 800087e0 <syscalls+0x320>
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	f06080e7          	jalr	-250(ra) # 8000053a <panic>
    dp->nlink--;
    8000563c:	04a4d783          	lhu	a5,74(s1)
    80005640:	37fd                	addiw	a5,a5,-1
    80005642:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	fe8080e7          	jalr	-24(ra) # 80003630 <iupdate>
    80005650:	b781                	j	80005590 <sys_unlink+0xe0>
    return -1;
    80005652:	557d                	li	a0,-1
    80005654:	a005                	j	80005674 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	306080e7          	jalr	774(ra) # 8000395e <iunlockput>
  iunlockput(dp);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	2fc080e7          	jalr	764(ra) # 8000395e <iunlockput>
  end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	aec080e7          	jalr	-1300(ra) # 80004156 <end_op>
  return -1;
    80005672:	557d                	li	a0,-1
}
    80005674:	70ae                	ld	ra,232(sp)
    80005676:	740e                	ld	s0,224(sp)
    80005678:	64ee                	ld	s1,216(sp)
    8000567a:	694e                	ld	s2,208(sp)
    8000567c:	69ae                	ld	s3,200(sp)
    8000567e:	616d                	addi	sp,sp,240
    80005680:	8082                	ret

0000000080005682 <sys_open>:

uint64
sys_open(void)
{
    80005682:	7131                	addi	sp,sp,-192
    80005684:	fd06                	sd	ra,184(sp)
    80005686:	f922                	sd	s0,176(sp)
    80005688:	f526                	sd	s1,168(sp)
    8000568a:	f14a                	sd	s2,160(sp)
    8000568c:	ed4e                	sd	s3,152(sp)
    8000568e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005690:	08000613          	li	a2,128
    80005694:	f5040593          	addi	a1,s0,-176
    80005698:	4501                	li	a0,0
    8000569a:	ffffd097          	auipc	ra,0xffffd
    8000569e:	4fa080e7          	jalr	1274(ra) # 80002b94 <argstr>
    return -1;
    800056a2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056a4:	0c054163          	bltz	a0,80005766 <sys_open+0xe4>
    800056a8:	f4c40593          	addi	a1,s0,-180
    800056ac:	4505                	li	a0,1
    800056ae:	ffffd097          	auipc	ra,0xffffd
    800056b2:	4a2080e7          	jalr	1186(ra) # 80002b50 <argint>
    800056b6:	0a054863          	bltz	a0,80005766 <sys_open+0xe4>

  begin_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	a1e080e7          	jalr	-1506(ra) # 800040d8 <begin_op>

  if(omode & O_CREATE){
    800056c2:	f4c42783          	lw	a5,-180(s0)
    800056c6:	2007f793          	andi	a5,a5,512
    800056ca:	cbdd                	beqz	a5,80005780 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056cc:	4681                	li	a3,0
    800056ce:	4601                	li	a2,0
    800056d0:	4589                	li	a1,2
    800056d2:	f5040513          	addi	a0,s0,-176
    800056d6:	00000097          	auipc	ra,0x0
    800056da:	970080e7          	jalr	-1680(ra) # 80005046 <create>
    800056de:	892a                	mv	s2,a0
    if(ip == 0){
    800056e0:	c959                	beqz	a0,80005776 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056e2:	04491703          	lh	a4,68(s2)
    800056e6:	478d                	li	a5,3
    800056e8:	00f71763          	bne	a4,a5,800056f6 <sys_open+0x74>
    800056ec:	04695703          	lhu	a4,70(s2)
    800056f0:	47a5                	li	a5,9
    800056f2:	0ce7ec63          	bltu	a5,a4,800057ca <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	dee080e7          	jalr	-530(ra) # 800044e4 <filealloc>
    800056fe:	89aa                	mv	s3,a0
    80005700:	10050263          	beqz	a0,80005804 <sys_open+0x182>
    80005704:	00000097          	auipc	ra,0x0
    80005708:	900080e7          	jalr	-1792(ra) # 80005004 <fdalloc>
    8000570c:	84aa                	mv	s1,a0
    8000570e:	0e054663          	bltz	a0,800057fa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005712:	04491703          	lh	a4,68(s2)
    80005716:	478d                	li	a5,3
    80005718:	0cf70463          	beq	a4,a5,800057e0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000571c:	4789                	li	a5,2
    8000571e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005722:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005726:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000572a:	f4c42783          	lw	a5,-180(s0)
    8000572e:	0017c713          	xori	a4,a5,1
    80005732:	8b05                	andi	a4,a4,1
    80005734:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005738:	0037f713          	andi	a4,a5,3
    8000573c:	00e03733          	snez	a4,a4
    80005740:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005744:	4007f793          	andi	a5,a5,1024
    80005748:	c791                	beqz	a5,80005754 <sys_open+0xd2>
    8000574a:	04491703          	lh	a4,68(s2)
    8000574e:	4789                	li	a5,2
    80005750:	08f70f63          	beq	a4,a5,800057ee <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	068080e7          	jalr	104(ra) # 800037be <iunlock>
  end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	9f8080e7          	jalr	-1544(ra) # 80004156 <end_op>

  return fd;
}
    80005766:	8526                	mv	a0,s1
    80005768:	70ea                	ld	ra,184(sp)
    8000576a:	744a                	ld	s0,176(sp)
    8000576c:	74aa                	ld	s1,168(sp)
    8000576e:	790a                	ld	s2,160(sp)
    80005770:	69ea                	ld	s3,152(sp)
    80005772:	6129                	addi	sp,sp,192
    80005774:	8082                	ret
      end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	9e0080e7          	jalr	-1568(ra) # 80004156 <end_op>
      return -1;
    8000577e:	b7e5                	j	80005766 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005780:	f5040513          	addi	a0,s0,-176
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	734080e7          	jalr	1844(ra) # 80003eb8 <namei>
    8000578c:	892a                	mv	s2,a0
    8000578e:	c905                	beqz	a0,800057be <sys_open+0x13c>
    ilock(ip);
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	f6c080e7          	jalr	-148(ra) # 800036fc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005798:	04491703          	lh	a4,68(s2)
    8000579c:	4785                	li	a5,1
    8000579e:	f4f712e3          	bne	a4,a5,800056e2 <sys_open+0x60>
    800057a2:	f4c42783          	lw	a5,-180(s0)
    800057a6:	dba1                	beqz	a5,800056f6 <sys_open+0x74>
      iunlockput(ip);
    800057a8:	854a                	mv	a0,s2
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	1b4080e7          	jalr	436(ra) # 8000395e <iunlockput>
      end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	9a4080e7          	jalr	-1628(ra) # 80004156 <end_op>
      return -1;
    800057ba:	54fd                	li	s1,-1
    800057bc:	b76d                	j	80005766 <sys_open+0xe4>
      end_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	998080e7          	jalr	-1640(ra) # 80004156 <end_op>
      return -1;
    800057c6:	54fd                	li	s1,-1
    800057c8:	bf79                	j	80005766 <sys_open+0xe4>
    iunlockput(ip);
    800057ca:	854a                	mv	a0,s2
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	192080e7          	jalr	402(ra) # 8000395e <iunlockput>
    end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	982080e7          	jalr	-1662(ra) # 80004156 <end_op>
    return -1;
    800057dc:	54fd                	li	s1,-1
    800057de:	b761                	j	80005766 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057e0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057e4:	04691783          	lh	a5,70(s2)
    800057e8:	02f99223          	sh	a5,36(s3)
    800057ec:	bf2d                	j	80005726 <sys_open+0xa4>
    itrunc(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	01a080e7          	jalr	26(ra) # 8000380a <itrunc>
    800057f8:	bfb1                	j	80005754 <sys_open+0xd2>
      fileclose(f);
    800057fa:	854e                	mv	a0,s3
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	da4080e7          	jalr	-604(ra) # 800045a0 <fileclose>
    iunlockput(ip);
    80005804:	854a                	mv	a0,s2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	158080e7          	jalr	344(ra) # 8000395e <iunlockput>
    end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	948080e7          	jalr	-1720(ra) # 80004156 <end_op>
    return -1;
    80005816:	54fd                	li	s1,-1
    80005818:	b7b9                	j	80005766 <sys_open+0xe4>

000000008000581a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000581a:	7175                	addi	sp,sp,-144
    8000581c:	e506                	sd	ra,136(sp)
    8000581e:	e122                	sd	s0,128(sp)
    80005820:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	8b6080e7          	jalr	-1866(ra) # 800040d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000582a:	08000613          	li	a2,128
    8000582e:	f7040593          	addi	a1,s0,-144
    80005832:	4501                	li	a0,0
    80005834:	ffffd097          	auipc	ra,0xffffd
    80005838:	360080e7          	jalr	864(ra) # 80002b94 <argstr>
    8000583c:	02054963          	bltz	a0,8000586e <sys_mkdir+0x54>
    80005840:	4681                	li	a3,0
    80005842:	4601                	li	a2,0
    80005844:	4585                	li	a1,1
    80005846:	f7040513          	addi	a0,s0,-144
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	7fc080e7          	jalr	2044(ra) # 80005046 <create>
    80005852:	cd11                	beqz	a0,8000586e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	10a080e7          	jalr	266(ra) # 8000395e <iunlockput>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	8fa080e7          	jalr	-1798(ra) # 80004156 <end_op>
  return 0;
    80005864:	4501                	li	a0,0
}
    80005866:	60aa                	ld	ra,136(sp)
    80005868:	640a                	ld	s0,128(sp)
    8000586a:	6149                	addi	sp,sp,144
    8000586c:	8082                	ret
    end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	8e8080e7          	jalr	-1816(ra) # 80004156 <end_op>
    return -1;
    80005876:	557d                	li	a0,-1
    80005878:	b7fd                	j	80005866 <sys_mkdir+0x4c>

000000008000587a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000587a:	7135                	addi	sp,sp,-160
    8000587c:	ed06                	sd	ra,152(sp)
    8000587e:	e922                	sd	s0,144(sp)
    80005880:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	856080e7          	jalr	-1962(ra) # 800040d8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000588a:	08000613          	li	a2,128
    8000588e:	f7040593          	addi	a1,s0,-144
    80005892:	4501                	li	a0,0
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	300080e7          	jalr	768(ra) # 80002b94 <argstr>
    8000589c:	04054a63          	bltz	a0,800058f0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058a0:	f6c40593          	addi	a1,s0,-148
    800058a4:	4505                	li	a0,1
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	2aa080e7          	jalr	682(ra) # 80002b50 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ae:	04054163          	bltz	a0,800058f0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058b2:	f6840593          	addi	a1,s0,-152
    800058b6:	4509                	li	a0,2
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	298080e7          	jalr	664(ra) # 80002b50 <argint>
     argint(1, &major) < 0 ||
    800058c0:	02054863          	bltz	a0,800058f0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058c4:	f6841683          	lh	a3,-152(s0)
    800058c8:	f6c41603          	lh	a2,-148(s0)
    800058cc:	458d                	li	a1,3
    800058ce:	f7040513          	addi	a0,s0,-144
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	774080e7          	jalr	1908(ra) # 80005046 <create>
     argint(2, &minor) < 0 ||
    800058da:	c919                	beqz	a0,800058f0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	082080e7          	jalr	130(ra) # 8000395e <iunlockput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	872080e7          	jalr	-1934(ra) # 80004156 <end_op>
  return 0;
    800058ec:	4501                	li	a0,0
    800058ee:	a031                	j	800058fa <sys_mknod+0x80>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	866080e7          	jalr	-1946(ra) # 80004156 <end_op>
    return -1;
    800058f8:	557d                	li	a0,-1
}
    800058fa:	60ea                	ld	ra,152(sp)
    800058fc:	644a                	ld	s0,144(sp)
    800058fe:	610d                	addi	sp,sp,160
    80005900:	8082                	ret

0000000080005902 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005902:	7135                	addi	sp,sp,-160
    80005904:	ed06                	sd	ra,152(sp)
    80005906:	e922                	sd	s0,144(sp)
    80005908:	e526                	sd	s1,136(sp)
    8000590a:	e14a                	sd	s2,128(sp)
    8000590c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000590e:	ffffc097          	auipc	ra,0xffffc
    80005912:	088080e7          	jalr	136(ra) # 80001996 <myproc>
    80005916:	892a                	mv	s2,a0
  
  begin_op();
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	7c0080e7          	jalr	1984(ra) # 800040d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005920:	08000613          	li	a2,128
    80005924:	f6040593          	addi	a1,s0,-160
    80005928:	4501                	li	a0,0
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	26a080e7          	jalr	618(ra) # 80002b94 <argstr>
    80005932:	04054b63          	bltz	a0,80005988 <sys_chdir+0x86>
    80005936:	f6040513          	addi	a0,s0,-160
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	57e080e7          	jalr	1406(ra) # 80003eb8 <namei>
    80005942:	84aa                	mv	s1,a0
    80005944:	c131                	beqz	a0,80005988 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	db6080e7          	jalr	-586(ra) # 800036fc <ilock>
  if(ip->type != T_DIR){
    8000594e:	04449703          	lh	a4,68(s1)
    80005952:	4785                	li	a5,1
    80005954:	04f71063          	bne	a4,a5,80005994 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	e64080e7          	jalr	-412(ra) # 800037be <iunlock>
  iput(p->cwd);
    80005962:	15093503          	ld	a0,336(s2)
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	f50080e7          	jalr	-176(ra) # 800038b6 <iput>
  end_op();
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	7e8080e7          	jalr	2024(ra) # 80004156 <end_op>
  p->cwd = ip;
    80005976:	14993823          	sd	s1,336(s2)
  return 0;
    8000597a:	4501                	li	a0,0
}
    8000597c:	60ea                	ld	ra,152(sp)
    8000597e:	644a                	ld	s0,144(sp)
    80005980:	64aa                	ld	s1,136(sp)
    80005982:	690a                	ld	s2,128(sp)
    80005984:	610d                	addi	sp,sp,160
    80005986:	8082                	ret
    end_op();
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	7ce080e7          	jalr	1998(ra) # 80004156 <end_op>
    return -1;
    80005990:	557d                	li	a0,-1
    80005992:	b7ed                	j	8000597c <sys_chdir+0x7a>
    iunlockput(ip);
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	fc8080e7          	jalr	-56(ra) # 8000395e <iunlockput>
    end_op();
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	7b8080e7          	jalr	1976(ra) # 80004156 <end_op>
    return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	bfd1                	j	8000597c <sys_chdir+0x7a>

00000000800059aa <sys_exec>:

uint64
sys_exec(void)
{
    800059aa:	7145                	addi	sp,sp,-464
    800059ac:	e786                	sd	ra,456(sp)
    800059ae:	e3a2                	sd	s0,448(sp)
    800059b0:	ff26                	sd	s1,440(sp)
    800059b2:	fb4a                	sd	s2,432(sp)
    800059b4:	f74e                	sd	s3,424(sp)
    800059b6:	f352                	sd	s4,416(sp)
    800059b8:	ef56                	sd	s5,408(sp)
    800059ba:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059bc:	08000613          	li	a2,128
    800059c0:	f4040593          	addi	a1,s0,-192
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	1ce080e7          	jalr	462(ra) # 80002b94 <argstr>
    return -1;
    800059ce:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059d0:	0c054b63          	bltz	a0,80005aa6 <sys_exec+0xfc>
    800059d4:	e3840593          	addi	a1,s0,-456
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	198080e7          	jalr	408(ra) # 80002b72 <argaddr>
    800059e2:	0c054263          	bltz	a0,80005aa6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059e6:	10000613          	li	a2,256
    800059ea:	4581                	li	a1,0
    800059ec:	e4040513          	addi	a0,s0,-448
    800059f0:	ffffb097          	auipc	ra,0xffffb
    800059f4:	2dc080e7          	jalr	732(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059f8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059fc:	89a6                	mv	s3,s1
    800059fe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a00:	02000a13          	li	s4,32
    80005a04:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a08:	00391513          	slli	a0,s2,0x3
    80005a0c:	e3040593          	addi	a1,s0,-464
    80005a10:	e3843783          	ld	a5,-456(s0)
    80005a14:	953e                	add	a0,a0,a5
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	0a0080e7          	jalr	160(ra) # 80002ab6 <fetchaddr>
    80005a1e:	02054a63          	bltz	a0,80005a52 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a22:	e3043783          	ld	a5,-464(s0)
    80005a26:	c3b9                	beqz	a5,80005a6c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	0b8080e7          	jalr	184(ra) # 80000ae0 <kalloc>
    80005a30:	85aa                	mv	a1,a0
    80005a32:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a36:	cd11                	beqz	a0,80005a52 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a38:	6605                	lui	a2,0x1
    80005a3a:	e3043503          	ld	a0,-464(s0)
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	0ca080e7          	jalr	202(ra) # 80002b08 <fetchstr>
    80005a46:	00054663          	bltz	a0,80005a52 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a4a:	0905                	addi	s2,s2,1
    80005a4c:	09a1                	addi	s3,s3,8
    80005a4e:	fb491be3          	bne	s2,s4,80005a04 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a52:	f4040913          	addi	s2,s0,-192
    80005a56:	6088                	ld	a0,0(s1)
    80005a58:	c531                	beqz	a0,80005aa4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	f88080e7          	jalr	-120(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a62:	04a1                	addi	s1,s1,8
    80005a64:	ff2499e3          	bne	s1,s2,80005a56 <sys_exec+0xac>
  return -1;
    80005a68:	597d                	li	s2,-1
    80005a6a:	a835                	j	80005aa6 <sys_exec+0xfc>
      argv[i] = 0;
    80005a6c:	0a8e                	slli	s5,s5,0x3
    80005a6e:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a72:	00878ab3          	add	s5,a5,s0
    80005a76:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a7a:	e4040593          	addi	a1,s0,-448
    80005a7e:	f4040513          	addi	a0,s0,-192
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	172080e7          	jalr	370(ra) # 80004bf4 <exec>
    80005a8a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a8c:	f4040993          	addi	s3,s0,-192
    80005a90:	6088                	ld	a0,0(s1)
    80005a92:	c911                	beqz	a0,80005aa6 <sys_exec+0xfc>
    kfree(argv[i]);
    80005a94:	ffffb097          	auipc	ra,0xffffb
    80005a98:	f4e080e7          	jalr	-178(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a9c:	04a1                	addi	s1,s1,8
    80005a9e:	ff3499e3          	bne	s1,s3,80005a90 <sys_exec+0xe6>
    80005aa2:	a011                	j	80005aa6 <sys_exec+0xfc>
  return -1;
    80005aa4:	597d                	li	s2,-1
}
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	60be                	ld	ra,456(sp)
    80005aaa:	641e                	ld	s0,448(sp)
    80005aac:	74fa                	ld	s1,440(sp)
    80005aae:	795a                	ld	s2,432(sp)
    80005ab0:	79ba                	ld	s3,424(sp)
    80005ab2:	7a1a                	ld	s4,416(sp)
    80005ab4:	6afa                	ld	s5,408(sp)
    80005ab6:	6179                	addi	sp,sp,464
    80005ab8:	8082                	ret

0000000080005aba <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aba:	7139                	addi	sp,sp,-64
    80005abc:	fc06                	sd	ra,56(sp)
    80005abe:	f822                	sd	s0,48(sp)
    80005ac0:	f426                	sd	s1,40(sp)
    80005ac2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ac4:	ffffc097          	auipc	ra,0xffffc
    80005ac8:	ed2080e7          	jalr	-302(ra) # 80001996 <myproc>
    80005acc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ace:	fd840593          	addi	a1,s0,-40
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	09e080e7          	jalr	158(ra) # 80002b72 <argaddr>
    return -1;
    80005adc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ade:	0e054063          	bltz	a0,80005bbe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ae2:	fc840593          	addi	a1,s0,-56
    80005ae6:	fd040513          	addi	a0,s0,-48
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	de6080e7          	jalr	-538(ra) # 800048d0 <pipealloc>
    return -1;
    80005af2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005af4:	0c054563          	bltz	a0,80005bbe <sys_pipe+0x104>
  fd0 = -1;
    80005af8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005afc:	fd043503          	ld	a0,-48(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	504080e7          	jalr	1284(ra) # 80005004 <fdalloc>
    80005b08:	fca42223          	sw	a0,-60(s0)
    80005b0c:	08054c63          	bltz	a0,80005ba4 <sys_pipe+0xea>
    80005b10:	fc843503          	ld	a0,-56(s0)
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	4f0080e7          	jalr	1264(ra) # 80005004 <fdalloc>
    80005b1c:	fca42023          	sw	a0,-64(s0)
    80005b20:	06054963          	bltz	a0,80005b92 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b24:	4691                	li	a3,4
    80005b26:	fc440613          	addi	a2,s0,-60
    80005b2a:	fd843583          	ld	a1,-40(s0)
    80005b2e:	68a8                	ld	a0,80(s1)
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	b2a080e7          	jalr	-1238(ra) # 8000165a <copyout>
    80005b38:	02054063          	bltz	a0,80005b58 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b3c:	4691                	li	a3,4
    80005b3e:	fc040613          	addi	a2,s0,-64
    80005b42:	fd843583          	ld	a1,-40(s0)
    80005b46:	0591                	addi	a1,a1,4
    80005b48:	68a8                	ld	a0,80(s1)
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	b10080e7          	jalr	-1264(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b52:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b54:	06055563          	bgez	a0,80005bbe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b58:	fc442783          	lw	a5,-60(s0)
    80005b5c:	07e9                	addi	a5,a5,26
    80005b5e:	078e                	slli	a5,a5,0x3
    80005b60:	97a6                	add	a5,a5,s1
    80005b62:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b66:	fc042783          	lw	a5,-64(s0)
    80005b6a:	07e9                	addi	a5,a5,26
    80005b6c:	078e                	slli	a5,a5,0x3
    80005b6e:	00f48533          	add	a0,s1,a5
    80005b72:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b76:	fd043503          	ld	a0,-48(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	a26080e7          	jalr	-1498(ra) # 800045a0 <fileclose>
    fileclose(wf);
    80005b82:	fc843503          	ld	a0,-56(s0)
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	a1a080e7          	jalr	-1510(ra) # 800045a0 <fileclose>
    return -1;
    80005b8e:	57fd                	li	a5,-1
    80005b90:	a03d                	j	80005bbe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b92:	fc442783          	lw	a5,-60(s0)
    80005b96:	0007c763          	bltz	a5,80005ba4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b9a:	07e9                	addi	a5,a5,26
    80005b9c:	078e                	slli	a5,a5,0x3
    80005b9e:	97a6                	add	a5,a5,s1
    80005ba0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ba4:	fd043503          	ld	a0,-48(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	9f8080e7          	jalr	-1544(ra) # 800045a0 <fileclose>
    fileclose(wf);
    80005bb0:	fc843503          	ld	a0,-56(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	9ec080e7          	jalr	-1556(ra) # 800045a0 <fileclose>
    return -1;
    80005bbc:	57fd                	li	a5,-1
}
    80005bbe:	853e                	mv	a0,a5
    80005bc0:	70e2                	ld	ra,56(sp)
    80005bc2:	7442                	ld	s0,48(sp)
    80005bc4:	74a2                	ld	s1,40(sp)
    80005bc6:	6121                	addi	sp,sp,64
    80005bc8:	8082                	ret
    80005bca:	0000                	unimp
    80005bcc:	0000                	unimp
	...

0000000080005bd0 <kernelvec>:
    80005bd0:	7111                	addi	sp,sp,-256
    80005bd2:	e006                	sd	ra,0(sp)
    80005bd4:	e40a                	sd	sp,8(sp)
    80005bd6:	e80e                	sd	gp,16(sp)
    80005bd8:	ec12                	sd	tp,24(sp)
    80005bda:	f016                	sd	t0,32(sp)
    80005bdc:	f41a                	sd	t1,40(sp)
    80005bde:	f81e                	sd	t2,48(sp)
    80005be0:	fc22                	sd	s0,56(sp)
    80005be2:	e0a6                	sd	s1,64(sp)
    80005be4:	e4aa                	sd	a0,72(sp)
    80005be6:	e8ae                	sd	a1,80(sp)
    80005be8:	ecb2                	sd	a2,88(sp)
    80005bea:	f0b6                	sd	a3,96(sp)
    80005bec:	f4ba                	sd	a4,104(sp)
    80005bee:	f8be                	sd	a5,112(sp)
    80005bf0:	fcc2                	sd	a6,120(sp)
    80005bf2:	e146                	sd	a7,128(sp)
    80005bf4:	e54a                	sd	s2,136(sp)
    80005bf6:	e94e                	sd	s3,144(sp)
    80005bf8:	ed52                	sd	s4,152(sp)
    80005bfa:	f156                	sd	s5,160(sp)
    80005bfc:	f55a                	sd	s6,168(sp)
    80005bfe:	f95e                	sd	s7,176(sp)
    80005c00:	fd62                	sd	s8,184(sp)
    80005c02:	e1e6                	sd	s9,192(sp)
    80005c04:	e5ea                	sd	s10,200(sp)
    80005c06:	e9ee                	sd	s11,208(sp)
    80005c08:	edf2                	sd	t3,216(sp)
    80005c0a:	f1f6                	sd	t4,224(sp)
    80005c0c:	f5fa                	sd	t5,232(sp)
    80005c0e:	f9fe                	sd	t6,240(sp)
    80005c10:	d73fc0ef          	jal	ra,80002982 <kerneltrap>
    80005c14:	6082                	ld	ra,0(sp)
    80005c16:	6122                	ld	sp,8(sp)
    80005c18:	61c2                	ld	gp,16(sp)
    80005c1a:	7282                	ld	t0,32(sp)
    80005c1c:	7322                	ld	t1,40(sp)
    80005c1e:	73c2                	ld	t2,48(sp)
    80005c20:	7462                	ld	s0,56(sp)
    80005c22:	6486                	ld	s1,64(sp)
    80005c24:	6526                	ld	a0,72(sp)
    80005c26:	65c6                	ld	a1,80(sp)
    80005c28:	6666                	ld	a2,88(sp)
    80005c2a:	7686                	ld	a3,96(sp)
    80005c2c:	7726                	ld	a4,104(sp)
    80005c2e:	77c6                	ld	a5,112(sp)
    80005c30:	7866                	ld	a6,120(sp)
    80005c32:	688a                	ld	a7,128(sp)
    80005c34:	692a                	ld	s2,136(sp)
    80005c36:	69ca                	ld	s3,144(sp)
    80005c38:	6a6a                	ld	s4,152(sp)
    80005c3a:	7a8a                	ld	s5,160(sp)
    80005c3c:	7b2a                	ld	s6,168(sp)
    80005c3e:	7bca                	ld	s7,176(sp)
    80005c40:	7c6a                	ld	s8,184(sp)
    80005c42:	6c8e                	ld	s9,192(sp)
    80005c44:	6d2e                	ld	s10,200(sp)
    80005c46:	6dce                	ld	s11,208(sp)
    80005c48:	6e6e                	ld	t3,216(sp)
    80005c4a:	7e8e                	ld	t4,224(sp)
    80005c4c:	7f2e                	ld	t5,232(sp)
    80005c4e:	7fce                	ld	t6,240(sp)
    80005c50:	6111                	addi	sp,sp,256
    80005c52:	10200073          	sret
    80005c56:	00000013          	nop
    80005c5a:	00000013          	nop
    80005c5e:	0001                	nop

0000000080005c60 <timervec>:
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	e10c                	sd	a1,0(a0)
    80005c66:	e510                	sd	a2,8(a0)
    80005c68:	e914                	sd	a3,16(a0)
    80005c6a:	6d0c                	ld	a1,24(a0)
    80005c6c:	7110                	ld	a2,32(a0)
    80005c6e:	6194                	ld	a3,0(a1)
    80005c70:	96b2                	add	a3,a3,a2
    80005c72:	e194                	sd	a3,0(a1)
    80005c74:	4589                	li	a1,2
    80005c76:	14459073          	csrw	sip,a1
    80005c7a:	6914                	ld	a3,16(a0)
    80005c7c:	6510                	ld	a2,8(a0)
    80005c7e:	610c                	ld	a1,0(a0)
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	30200073          	mret
	...

0000000080005c8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c8a:	1141                	addi	sp,sp,-16
    80005c8c:	e422                	sd	s0,8(sp)
    80005c8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c90:	0c0007b7          	lui	a5,0xc000
    80005c94:	4705                	li	a4,1
    80005c96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c98:	c3d8                	sw	a4,4(a5)
}
    80005c9a:	6422                	ld	s0,8(sp)
    80005c9c:	0141                	addi	sp,sp,16
    80005c9e:	8082                	ret

0000000080005ca0 <plicinithart>:

void
plicinithart(void)
{
    80005ca0:	1141                	addi	sp,sp,-16
    80005ca2:	e406                	sd	ra,8(sp)
    80005ca4:	e022                	sd	s0,0(sp)
    80005ca6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	cc2080e7          	jalr	-830(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cb0:	0085171b          	slliw	a4,a0,0x8
    80005cb4:	0c0027b7          	lui	a5,0xc002
    80005cb8:	97ba                	add	a5,a5,a4
    80005cba:	40200713          	li	a4,1026
    80005cbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cc2:	00d5151b          	slliw	a0,a0,0xd
    80005cc6:	0c2017b7          	lui	a5,0xc201
    80005cca:	97aa                	add	a5,a5,a0
    80005ccc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005cd0:	60a2                	ld	ra,8(sp)
    80005cd2:	6402                	ld	s0,0(sp)
    80005cd4:	0141                	addi	sp,sp,16
    80005cd6:	8082                	ret

0000000080005cd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cd8:	1141                	addi	sp,sp,-16
    80005cda:	e406                	sd	ra,8(sp)
    80005cdc:	e022                	sd	s0,0(sp)
    80005cde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce0:	ffffc097          	auipc	ra,0xffffc
    80005ce4:	c8a080e7          	jalr	-886(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ce8:	00d5151b          	slliw	a0,a0,0xd
    80005cec:	0c2017b7          	lui	a5,0xc201
    80005cf0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cf2:	43c8                	lw	a0,4(a5)
    80005cf4:	60a2                	ld	ra,8(sp)
    80005cf6:	6402                	ld	s0,0(sp)
    80005cf8:	0141                	addi	sp,sp,16
    80005cfa:	8082                	ret

0000000080005cfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cfc:	1101                	addi	sp,sp,-32
    80005cfe:	ec06                	sd	ra,24(sp)
    80005d00:	e822                	sd	s0,16(sp)
    80005d02:	e426                	sd	s1,8(sp)
    80005d04:	1000                	addi	s0,sp,32
    80005d06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	c62080e7          	jalr	-926(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d10:	00d5151b          	slliw	a0,a0,0xd
    80005d14:	0c2017b7          	lui	a5,0xc201
    80005d18:	97aa                	add	a5,a5,a0
    80005d1a:	c3c4                	sw	s1,4(a5)
}
    80005d1c:	60e2                	ld	ra,24(sp)
    80005d1e:	6442                	ld	s0,16(sp)
    80005d20:	64a2                	ld	s1,8(sp)
    80005d22:	6105                	addi	sp,sp,32
    80005d24:	8082                	ret

0000000080005d26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d26:	1141                	addi	sp,sp,-16
    80005d28:	e406                	sd	ra,8(sp)
    80005d2a:	e022                	sd	s0,0(sp)
    80005d2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d2e:	479d                	li	a5,7
    80005d30:	06a7c863          	blt	a5,a0,80005da0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005d34:	0001d717          	auipc	a4,0x1d
    80005d38:	2cc70713          	addi	a4,a4,716 # 80023000 <disk>
    80005d3c:	972a                	add	a4,a4,a0
    80005d3e:	6789                	lui	a5,0x2
    80005d40:	97ba                	add	a5,a5,a4
    80005d42:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d46:	e7ad                	bnez	a5,80005db0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d48:	00451793          	slli	a5,a0,0x4
    80005d4c:	0001f717          	auipc	a4,0x1f
    80005d50:	2b470713          	addi	a4,a4,692 # 80025000 <disk+0x2000>
    80005d54:	6314                	ld	a3,0(a4)
    80005d56:	96be                	add	a3,a3,a5
    80005d58:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d5c:	6314                	ld	a3,0(a4)
    80005d5e:	96be                	add	a3,a3,a5
    80005d60:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d64:	6314                	ld	a3,0(a4)
    80005d66:	96be                	add	a3,a3,a5
    80005d68:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d6c:	6318                	ld	a4,0(a4)
    80005d6e:	97ba                	add	a5,a5,a4
    80005d70:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d74:	0001d717          	auipc	a4,0x1d
    80005d78:	28c70713          	addi	a4,a4,652 # 80023000 <disk>
    80005d7c:	972a                	add	a4,a4,a0
    80005d7e:	6789                	lui	a5,0x2
    80005d80:	97ba                	add	a5,a5,a4
    80005d82:	4705                	li	a4,1
    80005d84:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d88:	0001f517          	auipc	a0,0x1f
    80005d8c:	29050513          	addi	a0,a0,656 # 80025018 <disk+0x2018>
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	462080e7          	jalr	1122(ra) # 800021f2 <wakeup>
}
    80005d98:	60a2                	ld	ra,8(sp)
    80005d9a:	6402                	ld	s0,0(sp)
    80005d9c:	0141                	addi	sp,sp,16
    80005d9e:	8082                	ret
    panic("free_desc 1");
    80005da0:	00003517          	auipc	a0,0x3
    80005da4:	a5050513          	addi	a0,a0,-1456 # 800087f0 <syscalls+0x330>
    80005da8:	ffffa097          	auipc	ra,0xffffa
    80005dac:	792080e7          	jalr	1938(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005db0:	00003517          	auipc	a0,0x3
    80005db4:	a5050513          	addi	a0,a0,-1456 # 80008800 <syscalls+0x340>
    80005db8:	ffffa097          	auipc	ra,0xffffa
    80005dbc:	782080e7          	jalr	1922(ra) # 8000053a <panic>

0000000080005dc0 <virtio_disk_init>:
{
    80005dc0:	1101                	addi	sp,sp,-32
    80005dc2:	ec06                	sd	ra,24(sp)
    80005dc4:	e822                	sd	s0,16(sp)
    80005dc6:	e426                	sd	s1,8(sp)
    80005dc8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dca:	00003597          	auipc	a1,0x3
    80005dce:	a4658593          	addi	a1,a1,-1466 # 80008810 <syscalls+0x350>
    80005dd2:	0001f517          	auipc	a0,0x1f
    80005dd6:	35650513          	addi	a0,a0,854 # 80025128 <disk+0x2128>
    80005dda:	ffffb097          	auipc	ra,0xffffb
    80005dde:	d66080e7          	jalr	-666(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005de2:	100017b7          	lui	a5,0x10001
    80005de6:	4398                	lw	a4,0(a5)
    80005de8:	2701                	sext.w	a4,a4
    80005dea:	747277b7          	lui	a5,0x74727
    80005dee:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005df2:	0ef71063          	bne	a4,a5,80005ed2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005df6:	100017b7          	lui	a5,0x10001
    80005dfa:	43dc                	lw	a5,4(a5)
    80005dfc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dfe:	4705                	li	a4,1
    80005e00:	0ce79963          	bne	a5,a4,80005ed2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	479c                	lw	a5,8(a5)
    80005e0a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e0c:	4709                	li	a4,2
    80005e0e:	0ce79263          	bne	a5,a4,80005ed2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e12:	100017b7          	lui	a5,0x10001
    80005e16:	47d8                	lw	a4,12(a5)
    80005e18:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e1a:	554d47b7          	lui	a5,0x554d4
    80005e1e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e22:	0af71863          	bne	a4,a5,80005ed2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e26:	100017b7          	lui	a5,0x10001
    80005e2a:	4705                	li	a4,1
    80005e2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e2e:	470d                	li	a4,3
    80005e30:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e32:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e34:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e38:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e3c:	8f75                	and	a4,a4,a3
    80005e3e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e40:	472d                	li	a4,11
    80005e42:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e44:	473d                	li	a4,15
    80005e46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e48:	6705                	lui	a4,0x1
    80005e4a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e4c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e50:	5bdc                	lw	a5,52(a5)
    80005e52:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e54:	c7d9                	beqz	a5,80005ee2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e56:	471d                	li	a4,7
    80005e58:	08f77d63          	bgeu	a4,a5,80005ef2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e5c:	100014b7          	lui	s1,0x10001
    80005e60:	47a1                	li	a5,8
    80005e62:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e64:	6609                	lui	a2,0x2
    80005e66:	4581                	li	a1,0
    80005e68:	0001d517          	auipc	a0,0x1d
    80005e6c:	19850513          	addi	a0,a0,408 # 80023000 <disk>
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	e5c080e7          	jalr	-420(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e78:	0001d717          	auipc	a4,0x1d
    80005e7c:	18870713          	addi	a4,a4,392 # 80023000 <disk>
    80005e80:	00c75793          	srli	a5,a4,0xc
    80005e84:	2781                	sext.w	a5,a5
    80005e86:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e88:	0001f797          	auipc	a5,0x1f
    80005e8c:	17878793          	addi	a5,a5,376 # 80025000 <disk+0x2000>
    80005e90:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e92:	0001d717          	auipc	a4,0x1d
    80005e96:	1ee70713          	addi	a4,a4,494 # 80023080 <disk+0x80>
    80005e9a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e9c:	0001e717          	auipc	a4,0x1e
    80005ea0:	16470713          	addi	a4,a4,356 # 80024000 <disk+0x1000>
    80005ea4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ea6:	4705                	li	a4,1
    80005ea8:	00e78c23          	sb	a4,24(a5)
    80005eac:	00e78ca3          	sb	a4,25(a5)
    80005eb0:	00e78d23          	sb	a4,26(a5)
    80005eb4:	00e78da3          	sb	a4,27(a5)
    80005eb8:	00e78e23          	sb	a4,28(a5)
    80005ebc:	00e78ea3          	sb	a4,29(a5)
    80005ec0:	00e78f23          	sb	a4,30(a5)
    80005ec4:	00e78fa3          	sb	a4,31(a5)
}
    80005ec8:	60e2                	ld	ra,24(sp)
    80005eca:	6442                	ld	s0,16(sp)
    80005ecc:	64a2                	ld	s1,8(sp)
    80005ece:	6105                	addi	sp,sp,32
    80005ed0:	8082                	ret
    panic("could not find virtio disk");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	94e50513          	addi	a0,a0,-1714 # 80008820 <syscalls+0x360>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	660080e7          	jalr	1632(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	95e50513          	addi	a0,a0,-1698 # 80008840 <syscalls+0x380>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	650080e7          	jalr	1616(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	96e50513          	addi	a0,a0,-1682 # 80008860 <syscalls+0x3a0>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	640080e7          	jalr	1600(ra) # 8000053a <panic>

0000000080005f02 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f02:	7119                	addi	sp,sp,-128
    80005f04:	fc86                	sd	ra,120(sp)
    80005f06:	f8a2                	sd	s0,112(sp)
    80005f08:	f4a6                	sd	s1,104(sp)
    80005f0a:	f0ca                	sd	s2,96(sp)
    80005f0c:	ecce                	sd	s3,88(sp)
    80005f0e:	e8d2                	sd	s4,80(sp)
    80005f10:	e4d6                	sd	s5,72(sp)
    80005f12:	e0da                	sd	s6,64(sp)
    80005f14:	fc5e                	sd	s7,56(sp)
    80005f16:	f862                	sd	s8,48(sp)
    80005f18:	f466                	sd	s9,40(sp)
    80005f1a:	f06a                	sd	s10,32(sp)
    80005f1c:	ec6e                	sd	s11,24(sp)
    80005f1e:	0100                	addi	s0,sp,128
    80005f20:	8aaa                	mv	s5,a0
    80005f22:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f24:	00c52c83          	lw	s9,12(a0)
    80005f28:	001c9c9b          	slliw	s9,s9,0x1
    80005f2c:	1c82                	slli	s9,s9,0x20
    80005f2e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f32:	0001f517          	auipc	a0,0x1f
    80005f36:	1f650513          	addi	a0,a0,502 # 80025128 <disk+0x2128>
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	c96080e7          	jalr	-874(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005f42:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f44:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f46:	0001dc17          	auipc	s8,0x1d
    80005f4a:	0bac0c13          	addi	s8,s8,186 # 80023000 <disk>
    80005f4e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f50:	4b0d                	li	s6,3
    80005f52:	a0ad                	j	80005fbc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f54:	00fc0733          	add	a4,s8,a5
    80005f58:	975e                	add	a4,a4,s7
    80005f5a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f5e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f60:	0207c563          	bltz	a5,80005f8a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f64:	2905                	addiw	s2,s2,1
    80005f66:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f68:	19690c63          	beq	s2,s6,80006100 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f6c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f6e:	0001f717          	auipc	a4,0x1f
    80005f72:	0aa70713          	addi	a4,a4,170 # 80025018 <disk+0x2018>
    80005f76:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f78:	00074683          	lbu	a3,0(a4)
    80005f7c:	fee1                	bnez	a3,80005f54 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f7e:	2785                	addiw	a5,a5,1
    80005f80:	0705                	addi	a4,a4,1
    80005f82:	fe979be3          	bne	a5,s1,80005f78 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f86:	57fd                	li	a5,-1
    80005f88:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f8a:	01205d63          	blez	s2,80005fa4 <virtio_disk_rw+0xa2>
    80005f8e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f90:	000a2503          	lw	a0,0(s4)
    80005f94:	00000097          	auipc	ra,0x0
    80005f98:	d92080e7          	jalr	-622(ra) # 80005d26 <free_desc>
      for(int j = 0; j < i; j++)
    80005f9c:	2d85                	addiw	s11,s11,1
    80005f9e:	0a11                	addi	s4,s4,4
    80005fa0:	ff2d98e3          	bne	s11,s2,80005f90 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fa4:	0001f597          	auipc	a1,0x1f
    80005fa8:	18458593          	addi	a1,a1,388 # 80025128 <disk+0x2128>
    80005fac:	0001f517          	auipc	a0,0x1f
    80005fb0:	06c50513          	addi	a0,a0,108 # 80025018 <disk+0x2018>
    80005fb4:	ffffc097          	auipc	ra,0xffffc
    80005fb8:	0b2080e7          	jalr	178(ra) # 80002066 <sleep>
  for(int i = 0; i < 3; i++){
    80005fbc:	f8040a13          	addi	s4,s0,-128
{
    80005fc0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fc2:	894e                	mv	s2,s3
    80005fc4:	b765                	j	80005f6c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fc6:	0001f697          	auipc	a3,0x1f
    80005fca:	03a6b683          	ld	a3,58(a3) # 80025000 <disk+0x2000>
    80005fce:	96ba                	add	a3,a3,a4
    80005fd0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fd4:	0001d817          	auipc	a6,0x1d
    80005fd8:	02c80813          	addi	a6,a6,44 # 80023000 <disk>
    80005fdc:	0001f697          	auipc	a3,0x1f
    80005fe0:	02468693          	addi	a3,a3,36 # 80025000 <disk+0x2000>
    80005fe4:	6290                	ld	a2,0(a3)
    80005fe6:	963a                	add	a2,a2,a4
    80005fe8:	00c65583          	lhu	a1,12(a2)
    80005fec:	0015e593          	ori	a1,a1,1
    80005ff0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005ff4:	f8842603          	lw	a2,-120(s0)
    80005ff8:	628c                	ld	a1,0(a3)
    80005ffa:	972e                	add	a4,a4,a1
    80005ffc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006000:	20050593          	addi	a1,a0,512
    80006004:	0592                	slli	a1,a1,0x4
    80006006:	95c2                	add	a1,a1,a6
    80006008:	577d                	li	a4,-1
    8000600a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000600e:	00461713          	slli	a4,a2,0x4
    80006012:	6290                	ld	a2,0(a3)
    80006014:	963a                	add	a2,a2,a4
    80006016:	03078793          	addi	a5,a5,48
    8000601a:	97c2                	add	a5,a5,a6
    8000601c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000601e:	629c                	ld	a5,0(a3)
    80006020:	97ba                	add	a5,a5,a4
    80006022:	4605                	li	a2,1
    80006024:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006026:	629c                	ld	a5,0(a3)
    80006028:	97ba                	add	a5,a5,a4
    8000602a:	4809                	li	a6,2
    8000602c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006030:	629c                	ld	a5,0(a3)
    80006032:	97ba                	add	a5,a5,a4
    80006034:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006038:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000603c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006040:	6698                	ld	a4,8(a3)
    80006042:	00275783          	lhu	a5,2(a4)
    80006046:	8b9d                	andi	a5,a5,7
    80006048:	0786                	slli	a5,a5,0x1
    8000604a:	973e                	add	a4,a4,a5
    8000604c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006050:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006054:	6698                	ld	a4,8(a3)
    80006056:	00275783          	lhu	a5,2(a4)
    8000605a:	2785                	addiw	a5,a5,1
    8000605c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006060:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006064:	100017b7          	lui	a5,0x10001
    80006068:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000606c:	004aa783          	lw	a5,4(s5)
    80006070:	02c79163          	bne	a5,a2,80006092 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006074:	0001f917          	auipc	s2,0x1f
    80006078:	0b490913          	addi	s2,s2,180 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000607c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000607e:	85ca                	mv	a1,s2
    80006080:	8556                	mv	a0,s5
    80006082:	ffffc097          	auipc	ra,0xffffc
    80006086:	fe4080e7          	jalr	-28(ra) # 80002066 <sleep>
  while(b->disk == 1) {
    8000608a:	004aa783          	lw	a5,4(s5)
    8000608e:	fe9788e3          	beq	a5,s1,8000607e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006092:	f8042903          	lw	s2,-128(s0)
    80006096:	20090713          	addi	a4,s2,512
    8000609a:	0712                	slli	a4,a4,0x4
    8000609c:	0001d797          	auipc	a5,0x1d
    800060a0:	f6478793          	addi	a5,a5,-156 # 80023000 <disk>
    800060a4:	97ba                	add	a5,a5,a4
    800060a6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060aa:	0001f997          	auipc	s3,0x1f
    800060ae:	f5698993          	addi	s3,s3,-170 # 80025000 <disk+0x2000>
    800060b2:	00491713          	slli	a4,s2,0x4
    800060b6:	0009b783          	ld	a5,0(s3)
    800060ba:	97ba                	add	a5,a5,a4
    800060bc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060c0:	854a                	mv	a0,s2
    800060c2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	c60080e7          	jalr	-928(ra) # 80005d26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ce:	8885                	andi	s1,s1,1
    800060d0:	f0ed                	bnez	s1,800060b2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060d2:	0001f517          	auipc	a0,0x1f
    800060d6:	05650513          	addi	a0,a0,86 # 80025128 <disk+0x2128>
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	baa080e7          	jalr	-1110(ra) # 80000c84 <release>
}
    800060e2:	70e6                	ld	ra,120(sp)
    800060e4:	7446                	ld	s0,112(sp)
    800060e6:	74a6                	ld	s1,104(sp)
    800060e8:	7906                	ld	s2,96(sp)
    800060ea:	69e6                	ld	s3,88(sp)
    800060ec:	6a46                	ld	s4,80(sp)
    800060ee:	6aa6                	ld	s5,72(sp)
    800060f0:	6b06                	ld	s6,64(sp)
    800060f2:	7be2                	ld	s7,56(sp)
    800060f4:	7c42                	ld	s8,48(sp)
    800060f6:	7ca2                	ld	s9,40(sp)
    800060f8:	7d02                	ld	s10,32(sp)
    800060fa:	6de2                	ld	s11,24(sp)
    800060fc:	6109                	addi	sp,sp,128
    800060fe:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006100:	f8042503          	lw	a0,-128(s0)
    80006104:	20050793          	addi	a5,a0,512
    80006108:	0792                	slli	a5,a5,0x4
  if(write)
    8000610a:	0001d817          	auipc	a6,0x1d
    8000610e:	ef680813          	addi	a6,a6,-266 # 80023000 <disk>
    80006112:	00f80733          	add	a4,a6,a5
    80006116:	01a036b3          	snez	a3,s10
    8000611a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000611e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006122:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006126:	7679                	lui	a2,0xffffe
    80006128:	963e                	add	a2,a2,a5
    8000612a:	0001f697          	auipc	a3,0x1f
    8000612e:	ed668693          	addi	a3,a3,-298 # 80025000 <disk+0x2000>
    80006132:	6298                	ld	a4,0(a3)
    80006134:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006136:	0a878593          	addi	a1,a5,168
    8000613a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000613c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000613e:	6298                	ld	a4,0(a3)
    80006140:	9732                	add	a4,a4,a2
    80006142:	45c1                	li	a1,16
    80006144:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006146:	6298                	ld	a4,0(a3)
    80006148:	9732                	add	a4,a4,a2
    8000614a:	4585                	li	a1,1
    8000614c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006150:	f8442703          	lw	a4,-124(s0)
    80006154:	628c                	ld	a1,0(a3)
    80006156:	962e                	add	a2,a2,a1
    80006158:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000615c:	0712                	slli	a4,a4,0x4
    8000615e:	6290                	ld	a2,0(a3)
    80006160:	963a                	add	a2,a2,a4
    80006162:	058a8593          	addi	a1,s5,88
    80006166:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006168:	6294                	ld	a3,0(a3)
    8000616a:	96ba                	add	a3,a3,a4
    8000616c:	40000613          	li	a2,1024
    80006170:	c690                	sw	a2,8(a3)
  if(write)
    80006172:	e40d1ae3          	bnez	s10,80005fc6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006176:	0001f697          	auipc	a3,0x1f
    8000617a:	e8a6b683          	ld	a3,-374(a3) # 80025000 <disk+0x2000>
    8000617e:	96ba                	add	a3,a3,a4
    80006180:	4609                	li	a2,2
    80006182:	00c69623          	sh	a2,12(a3)
    80006186:	b5b9                	j	80005fd4 <virtio_disk_rw+0xd2>

0000000080006188 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006188:	1101                	addi	sp,sp,-32
    8000618a:	ec06                	sd	ra,24(sp)
    8000618c:	e822                	sd	s0,16(sp)
    8000618e:	e426                	sd	s1,8(sp)
    80006190:	e04a                	sd	s2,0(sp)
    80006192:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006194:	0001f517          	auipc	a0,0x1f
    80006198:	f9450513          	addi	a0,a0,-108 # 80025128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	a34080e7          	jalr	-1484(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061a4:	10001737          	lui	a4,0x10001
    800061a8:	533c                	lw	a5,96(a4)
    800061aa:	8b8d                	andi	a5,a5,3
    800061ac:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061ae:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061b2:	0001f797          	auipc	a5,0x1f
    800061b6:	e4e78793          	addi	a5,a5,-434 # 80025000 <disk+0x2000>
    800061ba:	6b94                	ld	a3,16(a5)
    800061bc:	0207d703          	lhu	a4,32(a5)
    800061c0:	0026d783          	lhu	a5,2(a3)
    800061c4:	06f70163          	beq	a4,a5,80006226 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061c8:	0001d917          	auipc	s2,0x1d
    800061cc:	e3890913          	addi	s2,s2,-456 # 80023000 <disk>
    800061d0:	0001f497          	auipc	s1,0x1f
    800061d4:	e3048493          	addi	s1,s1,-464 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061d8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061dc:	6898                	ld	a4,16(s1)
    800061de:	0204d783          	lhu	a5,32(s1)
    800061e2:	8b9d                	andi	a5,a5,7
    800061e4:	078e                	slli	a5,a5,0x3
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061ea:	20078713          	addi	a4,a5,512
    800061ee:	0712                	slli	a4,a4,0x4
    800061f0:	974a                	add	a4,a4,s2
    800061f2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061f6:	e731                	bnez	a4,80006242 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061f8:	20078793          	addi	a5,a5,512
    800061fc:	0792                	slli	a5,a5,0x4
    800061fe:	97ca                	add	a5,a5,s2
    80006200:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006202:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	fec080e7          	jalr	-20(ra) # 800021f2 <wakeup>

    disk.used_idx += 1;
    8000620e:	0204d783          	lhu	a5,32(s1)
    80006212:	2785                	addiw	a5,a5,1
    80006214:	17c2                	slli	a5,a5,0x30
    80006216:	93c1                	srli	a5,a5,0x30
    80006218:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000621c:	6898                	ld	a4,16(s1)
    8000621e:	00275703          	lhu	a4,2(a4)
    80006222:	faf71be3          	bne	a4,a5,800061d8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006226:	0001f517          	auipc	a0,0x1f
    8000622a:	f0250513          	addi	a0,a0,-254 # 80025128 <disk+0x2128>
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>
}
    80006236:	60e2                	ld	ra,24(sp)
    80006238:	6442                	ld	s0,16(sp)
    8000623a:	64a2                	ld	s1,8(sp)
    8000623c:	6902                	ld	s2,0(sp)
    8000623e:	6105                	addi	sp,sp,32
    80006240:	8082                	ret
      panic("virtio_disk_intr status");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	63e50513          	addi	a0,a0,1598 # 80008880 <syscalls+0x3c0>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f0080e7          	jalr	752(ra) # 8000053a <panic>
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
