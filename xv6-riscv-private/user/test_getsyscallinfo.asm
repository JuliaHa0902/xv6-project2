
user/_test_getsyscallinfo:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main (void) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
	fprintf (1, "The number of syscall is %d\n", getsyscallinfo());
   8:	00000097          	auipc	ra,0x0
   c:	332080e7          	jalr	818(ra) # 33a <getsyscallinfo>
  10:	862a                	mv	a2,a0
  12:	00000597          	auipc	a1,0x0
  16:	7b658593          	addi	a1,a1,1974 # 7c8 <malloc+0xec>
  1a:	4505                	li	a0,1
  1c:	00000097          	auipc	ra,0x0
  20:	5da080e7          	jalr	1498(ra) # 5f6 <fprintf>
	exit(0);
  24:	4501                	li	a0,0
  26:	00000097          	auipc	ra,0x0
  2a:	274080e7          	jalr	628(ra) # 29a <exit>

000000000000002e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  2e:	1141                	addi	sp,sp,-16
  30:	e422                	sd	s0,8(sp)
  32:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  34:	87aa                	mv	a5,a0
  36:	0585                	addi	a1,a1,1
  38:	0785                	addi	a5,a5,1
  3a:	fff5c703          	lbu	a4,-1(a1)
  3e:	fee78fa3          	sb	a4,-1(a5)
  42:	fb75                	bnez	a4,36 <strcpy+0x8>
    ;
  return os;
}
  44:	6422                	ld	s0,8(sp)
  46:	0141                	addi	sp,sp,16
  48:	8082                	ret

000000000000004a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  4a:	1141                	addi	sp,sp,-16
  4c:	e422                	sd	s0,8(sp)
  4e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  50:	00054783          	lbu	a5,0(a0)
  54:	cb91                	beqz	a5,68 <strcmp+0x1e>
  56:	0005c703          	lbu	a4,0(a1)
  5a:	00f71763          	bne	a4,a5,68 <strcmp+0x1e>
    p++, q++;
  5e:	0505                	addi	a0,a0,1
  60:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  62:	00054783          	lbu	a5,0(a0)
  66:	fbe5                	bnez	a5,56 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  68:	0005c503          	lbu	a0,0(a1)
}
  6c:	40a7853b          	subw	a0,a5,a0
  70:	6422                	ld	s0,8(sp)
  72:	0141                	addi	sp,sp,16
  74:	8082                	ret

0000000000000076 <strlen>:

uint
strlen(const char *s)
{
  76:	1141                	addi	sp,sp,-16
  78:	e422                	sd	s0,8(sp)
  7a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  7c:	00054783          	lbu	a5,0(a0)
  80:	cf91                	beqz	a5,9c <strlen+0x26>
  82:	0505                	addi	a0,a0,1
  84:	87aa                	mv	a5,a0
  86:	4685                	li	a3,1
  88:	9e89                	subw	a3,a3,a0
  8a:	00f6853b          	addw	a0,a3,a5
  8e:	0785                	addi	a5,a5,1
  90:	fff7c703          	lbu	a4,-1(a5)
  94:	fb7d                	bnez	a4,8a <strlen+0x14>
    ;
  return n;
}
  96:	6422                	ld	s0,8(sp)
  98:	0141                	addi	sp,sp,16
  9a:	8082                	ret
  for(n = 0; s[n]; n++)
  9c:	4501                	li	a0,0
  9e:	bfe5                	j	96 <strlen+0x20>

00000000000000a0 <memset>:

void*
memset(void *dst, int c, uint n)
{
  a0:	1141                	addi	sp,sp,-16
  a2:	e422                	sd	s0,8(sp)
  a4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  a6:	ca19                	beqz	a2,bc <memset+0x1c>
  a8:	87aa                	mv	a5,a0
  aa:	1602                	slli	a2,a2,0x20
  ac:	9201                	srli	a2,a2,0x20
  ae:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  b2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  b6:	0785                	addi	a5,a5,1
  b8:	fee79de3          	bne	a5,a4,b2 <memset+0x12>
  }
  return dst;
}
  bc:	6422                	ld	s0,8(sp)
  be:	0141                	addi	sp,sp,16
  c0:	8082                	ret

00000000000000c2 <strchr>:

char*
strchr(const char *s, char c)
{
  c2:	1141                	addi	sp,sp,-16
  c4:	e422                	sd	s0,8(sp)
  c6:	0800                	addi	s0,sp,16
  for(; *s; s++)
  c8:	00054783          	lbu	a5,0(a0)
  cc:	cb99                	beqz	a5,e2 <strchr+0x20>
    if(*s == c)
  ce:	00f58763          	beq	a1,a5,dc <strchr+0x1a>
  for(; *s; s++)
  d2:	0505                	addi	a0,a0,1
  d4:	00054783          	lbu	a5,0(a0)
  d8:	fbfd                	bnez	a5,ce <strchr+0xc>
      return (char*)s;
  return 0;
  da:	4501                	li	a0,0
}
  dc:	6422                	ld	s0,8(sp)
  de:	0141                	addi	sp,sp,16
  e0:	8082                	ret
  return 0;
  e2:	4501                	li	a0,0
  e4:	bfe5                	j	dc <strchr+0x1a>

00000000000000e6 <gets>:

char*
gets(char *buf, int max)
{
  e6:	711d                	addi	sp,sp,-96
  e8:	ec86                	sd	ra,88(sp)
  ea:	e8a2                	sd	s0,80(sp)
  ec:	e4a6                	sd	s1,72(sp)
  ee:	e0ca                	sd	s2,64(sp)
  f0:	fc4e                	sd	s3,56(sp)
  f2:	f852                	sd	s4,48(sp)
  f4:	f456                	sd	s5,40(sp)
  f6:	f05a                	sd	s6,32(sp)
  f8:	ec5e                	sd	s7,24(sp)
  fa:	1080                	addi	s0,sp,96
  fc:	8baa                	mv	s7,a0
  fe:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 100:	892a                	mv	s2,a0
 102:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 104:	4aa9                	li	s5,10
 106:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 108:	89a6                	mv	s3,s1
 10a:	2485                	addiw	s1,s1,1
 10c:	0344d863          	bge	s1,s4,13c <gets+0x56>
    cc = read(0, &c, 1);
 110:	4605                	li	a2,1
 112:	faf40593          	addi	a1,s0,-81
 116:	4501                	li	a0,0
 118:	00000097          	auipc	ra,0x0
 11c:	19a080e7          	jalr	410(ra) # 2b2 <read>
    if(cc < 1)
 120:	00a05e63          	blez	a0,13c <gets+0x56>
    buf[i++] = c;
 124:	faf44783          	lbu	a5,-81(s0)
 128:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 12c:	01578763          	beq	a5,s5,13a <gets+0x54>
 130:	0905                	addi	s2,s2,1
 132:	fd679be3          	bne	a5,s6,108 <gets+0x22>
  for(i=0; i+1 < max; ){
 136:	89a6                	mv	s3,s1
 138:	a011                	j	13c <gets+0x56>
 13a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 13c:	99de                	add	s3,s3,s7
 13e:	00098023          	sb	zero,0(s3)
  return buf;
}
 142:	855e                	mv	a0,s7
 144:	60e6                	ld	ra,88(sp)
 146:	6446                	ld	s0,80(sp)
 148:	64a6                	ld	s1,72(sp)
 14a:	6906                	ld	s2,64(sp)
 14c:	79e2                	ld	s3,56(sp)
 14e:	7a42                	ld	s4,48(sp)
 150:	7aa2                	ld	s5,40(sp)
 152:	7b02                	ld	s6,32(sp)
 154:	6be2                	ld	s7,24(sp)
 156:	6125                	addi	sp,sp,96
 158:	8082                	ret

000000000000015a <stat>:

int
stat(const char *n, struct stat *st)
{
 15a:	1101                	addi	sp,sp,-32
 15c:	ec06                	sd	ra,24(sp)
 15e:	e822                	sd	s0,16(sp)
 160:	e426                	sd	s1,8(sp)
 162:	e04a                	sd	s2,0(sp)
 164:	1000                	addi	s0,sp,32
 166:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 168:	4581                	li	a1,0
 16a:	00000097          	auipc	ra,0x0
 16e:	170080e7          	jalr	368(ra) # 2da <open>
  if(fd < 0)
 172:	02054563          	bltz	a0,19c <stat+0x42>
 176:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 178:	85ca                	mv	a1,s2
 17a:	00000097          	auipc	ra,0x0
 17e:	178080e7          	jalr	376(ra) # 2f2 <fstat>
 182:	892a                	mv	s2,a0
  close(fd);
 184:	8526                	mv	a0,s1
 186:	00000097          	auipc	ra,0x0
 18a:	13c080e7          	jalr	316(ra) # 2c2 <close>
  return r;
}
 18e:	854a                	mv	a0,s2
 190:	60e2                	ld	ra,24(sp)
 192:	6442                	ld	s0,16(sp)
 194:	64a2                	ld	s1,8(sp)
 196:	6902                	ld	s2,0(sp)
 198:	6105                	addi	sp,sp,32
 19a:	8082                	ret
    return -1;
 19c:	597d                	li	s2,-1
 19e:	bfc5                	j	18e <stat+0x34>

00000000000001a0 <atoi>:

int
atoi(const char *s)
{
 1a0:	1141                	addi	sp,sp,-16
 1a2:	e422                	sd	s0,8(sp)
 1a4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1a6:	00054683          	lbu	a3,0(a0)
 1aa:	fd06879b          	addiw	a5,a3,-48
 1ae:	0ff7f793          	zext.b	a5,a5
 1b2:	4625                	li	a2,9
 1b4:	02f66863          	bltu	a2,a5,1e4 <atoi+0x44>
 1b8:	872a                	mv	a4,a0
  n = 0;
 1ba:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1bc:	0705                	addi	a4,a4,1
 1be:	0025179b          	slliw	a5,a0,0x2
 1c2:	9fa9                	addw	a5,a5,a0
 1c4:	0017979b          	slliw	a5,a5,0x1
 1c8:	9fb5                	addw	a5,a5,a3
 1ca:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1ce:	00074683          	lbu	a3,0(a4)
 1d2:	fd06879b          	addiw	a5,a3,-48
 1d6:	0ff7f793          	zext.b	a5,a5
 1da:	fef671e3          	bgeu	a2,a5,1bc <atoi+0x1c>
  return n;
}
 1de:	6422                	ld	s0,8(sp)
 1e0:	0141                	addi	sp,sp,16
 1e2:	8082                	ret
  n = 0;
 1e4:	4501                	li	a0,0
 1e6:	bfe5                	j	1de <atoi+0x3e>

00000000000001e8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1e8:	1141                	addi	sp,sp,-16
 1ea:	e422                	sd	s0,8(sp)
 1ec:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1ee:	02b57463          	bgeu	a0,a1,216 <memmove+0x2e>
    while(n-- > 0)
 1f2:	00c05f63          	blez	a2,210 <memmove+0x28>
 1f6:	1602                	slli	a2,a2,0x20
 1f8:	9201                	srli	a2,a2,0x20
 1fa:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 1fe:	872a                	mv	a4,a0
      *dst++ = *src++;
 200:	0585                	addi	a1,a1,1
 202:	0705                	addi	a4,a4,1
 204:	fff5c683          	lbu	a3,-1(a1)
 208:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 20c:	fee79ae3          	bne	a5,a4,200 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 210:	6422                	ld	s0,8(sp)
 212:	0141                	addi	sp,sp,16
 214:	8082                	ret
    dst += n;
 216:	00c50733          	add	a4,a0,a2
    src += n;
 21a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 21c:	fec05ae3          	blez	a2,210 <memmove+0x28>
 220:	fff6079b          	addiw	a5,a2,-1
 224:	1782                	slli	a5,a5,0x20
 226:	9381                	srli	a5,a5,0x20
 228:	fff7c793          	not	a5,a5
 22c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 22e:	15fd                	addi	a1,a1,-1
 230:	177d                	addi	a4,a4,-1
 232:	0005c683          	lbu	a3,0(a1)
 236:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 23a:	fee79ae3          	bne	a5,a4,22e <memmove+0x46>
 23e:	bfc9                	j	210 <memmove+0x28>

0000000000000240 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 240:	1141                	addi	sp,sp,-16
 242:	e422                	sd	s0,8(sp)
 244:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 246:	ca05                	beqz	a2,276 <memcmp+0x36>
 248:	fff6069b          	addiw	a3,a2,-1
 24c:	1682                	slli	a3,a3,0x20
 24e:	9281                	srli	a3,a3,0x20
 250:	0685                	addi	a3,a3,1
 252:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 254:	00054783          	lbu	a5,0(a0)
 258:	0005c703          	lbu	a4,0(a1)
 25c:	00e79863          	bne	a5,a4,26c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 260:	0505                	addi	a0,a0,1
    p2++;
 262:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 264:	fed518e3          	bne	a0,a3,254 <memcmp+0x14>
  }
  return 0;
 268:	4501                	li	a0,0
 26a:	a019                	j	270 <memcmp+0x30>
      return *p1 - *p2;
 26c:	40e7853b          	subw	a0,a5,a4
}
 270:	6422                	ld	s0,8(sp)
 272:	0141                	addi	sp,sp,16
 274:	8082                	ret
  return 0;
 276:	4501                	li	a0,0
 278:	bfe5                	j	270 <memcmp+0x30>

000000000000027a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 27a:	1141                	addi	sp,sp,-16
 27c:	e406                	sd	ra,8(sp)
 27e:	e022                	sd	s0,0(sp)
 280:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 282:	00000097          	auipc	ra,0x0
 286:	f66080e7          	jalr	-154(ra) # 1e8 <memmove>
}
 28a:	60a2                	ld	ra,8(sp)
 28c:	6402                	ld	s0,0(sp)
 28e:	0141                	addi	sp,sp,16
 290:	8082                	ret

0000000000000292 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 292:	4885                	li	a7,1
 ecall
 294:	00000073          	ecall
 ret
 298:	8082                	ret

000000000000029a <exit>:
.global exit
exit:
 li a7, SYS_exit
 29a:	4889                	li	a7,2
 ecall
 29c:	00000073          	ecall
 ret
 2a0:	8082                	ret

00000000000002a2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2a2:	488d                	li	a7,3
 ecall
 2a4:	00000073          	ecall
 ret
 2a8:	8082                	ret

00000000000002aa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2aa:	4891                	li	a7,4
 ecall
 2ac:	00000073          	ecall
 ret
 2b0:	8082                	ret

00000000000002b2 <read>:
.global read
read:
 li a7, SYS_read
 2b2:	4895                	li	a7,5
 ecall
 2b4:	00000073          	ecall
 ret
 2b8:	8082                	ret

00000000000002ba <write>:
.global write
write:
 li a7, SYS_write
 2ba:	48c1                	li	a7,16
 ecall
 2bc:	00000073          	ecall
 ret
 2c0:	8082                	ret

00000000000002c2 <close>:
.global close
close:
 li a7, SYS_close
 2c2:	48d5                	li	a7,21
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <kill>:
.global kill
kill:
 li a7, SYS_kill
 2ca:	4899                	li	a7,6
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2d2:	489d                	li	a7,7
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <open>:
.global open
open:
 li a7, SYS_open
 2da:	48bd                	li	a7,15
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2e2:	48c5                	li	a7,17
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2ea:	48c9                	li	a7,18
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2f2:	48a1                	li	a7,8
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <link>:
.global link
link:
 li a7, SYS_link
 2fa:	48cd                	li	a7,19
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 302:	48d1                	li	a7,20
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 30a:	48a5                	li	a7,9
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <dup>:
.global dup
dup:
 li a7, SYS_dup
 312:	48a9                	li	a7,10
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 31a:	48ad                	li	a7,11
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 322:	48b1                	li	a7,12
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 32a:	48b5                	li	a7,13
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 332:	48b9                	li	a7,14
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <getsyscallinfo>:
.global getsyscallinfo
getsyscallinfo:
 li a7, SYS_getsyscallinfo
 33a:	48d9                	li	a7,22
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <cps>:
.global cps
cps:
 li a7, SYS_cps
 342:	48dd                	li	a7,23
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 34a:	1101                	addi	sp,sp,-32
 34c:	ec06                	sd	ra,24(sp)
 34e:	e822                	sd	s0,16(sp)
 350:	1000                	addi	s0,sp,32
 352:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 356:	4605                	li	a2,1
 358:	fef40593          	addi	a1,s0,-17
 35c:	00000097          	auipc	ra,0x0
 360:	f5e080e7          	jalr	-162(ra) # 2ba <write>
}
 364:	60e2                	ld	ra,24(sp)
 366:	6442                	ld	s0,16(sp)
 368:	6105                	addi	sp,sp,32
 36a:	8082                	ret

000000000000036c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 36c:	7139                	addi	sp,sp,-64
 36e:	fc06                	sd	ra,56(sp)
 370:	f822                	sd	s0,48(sp)
 372:	f426                	sd	s1,40(sp)
 374:	f04a                	sd	s2,32(sp)
 376:	ec4e                	sd	s3,24(sp)
 378:	0080                	addi	s0,sp,64
 37a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 37c:	c299                	beqz	a3,382 <printint+0x16>
 37e:	0805c963          	bltz	a1,410 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 382:	2581                	sext.w	a1,a1
  neg = 0;
 384:	4881                	li	a7,0
 386:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 38a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 38c:	2601                	sext.w	a2,a2
 38e:	00000517          	auipc	a0,0x0
 392:	4ba50513          	addi	a0,a0,1210 # 848 <digits>
 396:	883a                	mv	a6,a4
 398:	2705                	addiw	a4,a4,1
 39a:	02c5f7bb          	remuw	a5,a1,a2
 39e:	1782                	slli	a5,a5,0x20
 3a0:	9381                	srli	a5,a5,0x20
 3a2:	97aa                	add	a5,a5,a0
 3a4:	0007c783          	lbu	a5,0(a5)
 3a8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ac:	0005879b          	sext.w	a5,a1
 3b0:	02c5d5bb          	divuw	a1,a1,a2
 3b4:	0685                	addi	a3,a3,1
 3b6:	fec7f0e3          	bgeu	a5,a2,396 <printint+0x2a>
  if(neg)
 3ba:	00088c63          	beqz	a7,3d2 <printint+0x66>
    buf[i++] = '-';
 3be:	fd070793          	addi	a5,a4,-48
 3c2:	00878733          	add	a4,a5,s0
 3c6:	02d00793          	li	a5,45
 3ca:	fef70823          	sb	a5,-16(a4)
 3ce:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3d2:	02e05863          	blez	a4,402 <printint+0x96>
 3d6:	fc040793          	addi	a5,s0,-64
 3da:	00e78933          	add	s2,a5,a4
 3de:	fff78993          	addi	s3,a5,-1
 3e2:	99ba                	add	s3,s3,a4
 3e4:	377d                	addiw	a4,a4,-1
 3e6:	1702                	slli	a4,a4,0x20
 3e8:	9301                	srli	a4,a4,0x20
 3ea:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3ee:	fff94583          	lbu	a1,-1(s2)
 3f2:	8526                	mv	a0,s1
 3f4:	00000097          	auipc	ra,0x0
 3f8:	f56080e7          	jalr	-170(ra) # 34a <putc>
  while(--i >= 0)
 3fc:	197d                	addi	s2,s2,-1
 3fe:	ff3918e3          	bne	s2,s3,3ee <printint+0x82>
}
 402:	70e2                	ld	ra,56(sp)
 404:	7442                	ld	s0,48(sp)
 406:	74a2                	ld	s1,40(sp)
 408:	7902                	ld	s2,32(sp)
 40a:	69e2                	ld	s3,24(sp)
 40c:	6121                	addi	sp,sp,64
 40e:	8082                	ret
    x = -xx;
 410:	40b005bb          	negw	a1,a1
    neg = 1;
 414:	4885                	li	a7,1
    x = -xx;
 416:	bf85                	j	386 <printint+0x1a>

0000000000000418 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 418:	7119                	addi	sp,sp,-128
 41a:	fc86                	sd	ra,120(sp)
 41c:	f8a2                	sd	s0,112(sp)
 41e:	f4a6                	sd	s1,104(sp)
 420:	f0ca                	sd	s2,96(sp)
 422:	ecce                	sd	s3,88(sp)
 424:	e8d2                	sd	s4,80(sp)
 426:	e4d6                	sd	s5,72(sp)
 428:	e0da                	sd	s6,64(sp)
 42a:	fc5e                	sd	s7,56(sp)
 42c:	f862                	sd	s8,48(sp)
 42e:	f466                	sd	s9,40(sp)
 430:	f06a                	sd	s10,32(sp)
 432:	ec6e                	sd	s11,24(sp)
 434:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 436:	0005c903          	lbu	s2,0(a1)
 43a:	18090f63          	beqz	s2,5d8 <vprintf+0x1c0>
 43e:	8aaa                	mv	s5,a0
 440:	8b32                	mv	s6,a2
 442:	00158493          	addi	s1,a1,1
  state = 0;
 446:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 448:	02500a13          	li	s4,37
 44c:	4c55                	li	s8,21
 44e:	00000c97          	auipc	s9,0x0
 452:	3a2c8c93          	addi	s9,s9,930 # 7f0 <malloc+0x114>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 456:	02800d93          	li	s11,40
  putc(fd, 'x');
 45a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 45c:	00000b97          	auipc	s7,0x0
 460:	3ecb8b93          	addi	s7,s7,1004 # 848 <digits>
 464:	a839                	j	482 <vprintf+0x6a>
        putc(fd, c);
 466:	85ca                	mv	a1,s2
 468:	8556                	mv	a0,s5
 46a:	00000097          	auipc	ra,0x0
 46e:	ee0080e7          	jalr	-288(ra) # 34a <putc>
 472:	a019                	j	478 <vprintf+0x60>
    } else if(state == '%'){
 474:	01498d63          	beq	s3,s4,48e <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 478:	0485                	addi	s1,s1,1
 47a:	fff4c903          	lbu	s2,-1(s1)
 47e:	14090d63          	beqz	s2,5d8 <vprintf+0x1c0>
    if(state == 0){
 482:	fe0999e3          	bnez	s3,474 <vprintf+0x5c>
      if(c == '%'){
 486:	ff4910e3          	bne	s2,s4,466 <vprintf+0x4e>
        state = '%';
 48a:	89d2                	mv	s3,s4
 48c:	b7f5                	j	478 <vprintf+0x60>
      if(c == 'd'){
 48e:	11490c63          	beq	s2,s4,5a6 <vprintf+0x18e>
 492:	f9d9079b          	addiw	a5,s2,-99
 496:	0ff7f793          	zext.b	a5,a5
 49a:	10fc6e63          	bltu	s8,a5,5b6 <vprintf+0x19e>
 49e:	f9d9079b          	addiw	a5,s2,-99
 4a2:	0ff7f713          	zext.b	a4,a5
 4a6:	10ec6863          	bltu	s8,a4,5b6 <vprintf+0x19e>
 4aa:	00271793          	slli	a5,a4,0x2
 4ae:	97e6                	add	a5,a5,s9
 4b0:	439c                	lw	a5,0(a5)
 4b2:	97e6                	add	a5,a5,s9
 4b4:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4b6:	008b0913          	addi	s2,s6,8
 4ba:	4685                	li	a3,1
 4bc:	4629                	li	a2,10
 4be:	000b2583          	lw	a1,0(s6)
 4c2:	8556                	mv	a0,s5
 4c4:	00000097          	auipc	ra,0x0
 4c8:	ea8080e7          	jalr	-344(ra) # 36c <printint>
 4cc:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4ce:	4981                	li	s3,0
 4d0:	b765                	j	478 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4d2:	008b0913          	addi	s2,s6,8
 4d6:	4681                	li	a3,0
 4d8:	4629                	li	a2,10
 4da:	000b2583          	lw	a1,0(s6)
 4de:	8556                	mv	a0,s5
 4e0:	00000097          	auipc	ra,0x0
 4e4:	e8c080e7          	jalr	-372(ra) # 36c <printint>
 4e8:	8b4a                	mv	s6,s2
      state = 0;
 4ea:	4981                	li	s3,0
 4ec:	b771                	j	478 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4ee:	008b0913          	addi	s2,s6,8
 4f2:	4681                	li	a3,0
 4f4:	866a                	mv	a2,s10
 4f6:	000b2583          	lw	a1,0(s6)
 4fa:	8556                	mv	a0,s5
 4fc:	00000097          	auipc	ra,0x0
 500:	e70080e7          	jalr	-400(ra) # 36c <printint>
 504:	8b4a                	mv	s6,s2
      state = 0;
 506:	4981                	li	s3,0
 508:	bf85                	j	478 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 50a:	008b0793          	addi	a5,s6,8
 50e:	f8f43423          	sd	a5,-120(s0)
 512:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 516:	03000593          	li	a1,48
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	e2e080e7          	jalr	-466(ra) # 34a <putc>
  putc(fd, 'x');
 524:	07800593          	li	a1,120
 528:	8556                	mv	a0,s5
 52a:	00000097          	auipc	ra,0x0
 52e:	e20080e7          	jalr	-480(ra) # 34a <putc>
 532:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 534:	03c9d793          	srli	a5,s3,0x3c
 538:	97de                	add	a5,a5,s7
 53a:	0007c583          	lbu	a1,0(a5)
 53e:	8556                	mv	a0,s5
 540:	00000097          	auipc	ra,0x0
 544:	e0a080e7          	jalr	-502(ra) # 34a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 548:	0992                	slli	s3,s3,0x4
 54a:	397d                	addiw	s2,s2,-1
 54c:	fe0914e3          	bnez	s2,534 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 550:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 554:	4981                	li	s3,0
 556:	b70d                	j	478 <vprintf+0x60>
        s = va_arg(ap, char*);
 558:	008b0913          	addi	s2,s6,8
 55c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 560:	02098163          	beqz	s3,582 <vprintf+0x16a>
        while(*s != 0){
 564:	0009c583          	lbu	a1,0(s3)
 568:	c5ad                	beqz	a1,5d2 <vprintf+0x1ba>
          putc(fd, *s);
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	dde080e7          	jalr	-546(ra) # 34a <putc>
          s++;
 574:	0985                	addi	s3,s3,1
        while(*s != 0){
 576:	0009c583          	lbu	a1,0(s3)
 57a:	f9e5                	bnez	a1,56a <vprintf+0x152>
        s = va_arg(ap, char*);
 57c:	8b4a                	mv	s6,s2
      state = 0;
 57e:	4981                	li	s3,0
 580:	bde5                	j	478 <vprintf+0x60>
          s = "(null)";
 582:	00000997          	auipc	s3,0x0
 586:	26698993          	addi	s3,s3,614 # 7e8 <malloc+0x10c>
        while(*s != 0){
 58a:	85ee                	mv	a1,s11
 58c:	bff9                	j	56a <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 58e:	008b0913          	addi	s2,s6,8
 592:	000b4583          	lbu	a1,0(s6)
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	db2080e7          	jalr	-590(ra) # 34a <putc>
 5a0:	8b4a                	mv	s6,s2
      state = 0;
 5a2:	4981                	li	s3,0
 5a4:	bdd1                	j	478 <vprintf+0x60>
        putc(fd, c);
 5a6:	85d2                	mv	a1,s4
 5a8:	8556                	mv	a0,s5
 5aa:	00000097          	auipc	ra,0x0
 5ae:	da0080e7          	jalr	-608(ra) # 34a <putc>
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	b5d1                	j	478 <vprintf+0x60>
        putc(fd, '%');
 5b6:	85d2                	mv	a1,s4
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	d90080e7          	jalr	-624(ra) # 34a <putc>
        putc(fd, c);
 5c2:	85ca                	mv	a1,s2
 5c4:	8556                	mv	a0,s5
 5c6:	00000097          	auipc	ra,0x0
 5ca:	d84080e7          	jalr	-636(ra) # 34a <putc>
      state = 0;
 5ce:	4981                	li	s3,0
 5d0:	b565                	j	478 <vprintf+0x60>
        s = va_arg(ap, char*);
 5d2:	8b4a                	mv	s6,s2
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	b54d                	j	478 <vprintf+0x60>
    }
  }
}
 5d8:	70e6                	ld	ra,120(sp)
 5da:	7446                	ld	s0,112(sp)
 5dc:	74a6                	ld	s1,104(sp)
 5de:	7906                	ld	s2,96(sp)
 5e0:	69e6                	ld	s3,88(sp)
 5e2:	6a46                	ld	s4,80(sp)
 5e4:	6aa6                	ld	s5,72(sp)
 5e6:	6b06                	ld	s6,64(sp)
 5e8:	7be2                	ld	s7,56(sp)
 5ea:	7c42                	ld	s8,48(sp)
 5ec:	7ca2                	ld	s9,40(sp)
 5ee:	7d02                	ld	s10,32(sp)
 5f0:	6de2                	ld	s11,24(sp)
 5f2:	6109                	addi	sp,sp,128
 5f4:	8082                	ret

00000000000005f6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5f6:	715d                	addi	sp,sp,-80
 5f8:	ec06                	sd	ra,24(sp)
 5fa:	e822                	sd	s0,16(sp)
 5fc:	1000                	addi	s0,sp,32
 5fe:	e010                	sd	a2,0(s0)
 600:	e414                	sd	a3,8(s0)
 602:	e818                	sd	a4,16(s0)
 604:	ec1c                	sd	a5,24(s0)
 606:	03043023          	sd	a6,32(s0)
 60a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 60e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 612:	8622                	mv	a2,s0
 614:	00000097          	auipc	ra,0x0
 618:	e04080e7          	jalr	-508(ra) # 418 <vprintf>
}
 61c:	60e2                	ld	ra,24(sp)
 61e:	6442                	ld	s0,16(sp)
 620:	6161                	addi	sp,sp,80
 622:	8082                	ret

0000000000000624 <printf>:

void
printf(const char *fmt, ...)
{
 624:	711d                	addi	sp,sp,-96
 626:	ec06                	sd	ra,24(sp)
 628:	e822                	sd	s0,16(sp)
 62a:	1000                	addi	s0,sp,32
 62c:	e40c                	sd	a1,8(s0)
 62e:	e810                	sd	a2,16(s0)
 630:	ec14                	sd	a3,24(s0)
 632:	f018                	sd	a4,32(s0)
 634:	f41c                	sd	a5,40(s0)
 636:	03043823          	sd	a6,48(s0)
 63a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 63e:	00840613          	addi	a2,s0,8
 642:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 646:	85aa                	mv	a1,a0
 648:	4505                	li	a0,1
 64a:	00000097          	auipc	ra,0x0
 64e:	dce080e7          	jalr	-562(ra) # 418 <vprintf>
}
 652:	60e2                	ld	ra,24(sp)
 654:	6442                	ld	s0,16(sp)
 656:	6125                	addi	sp,sp,96
 658:	8082                	ret

000000000000065a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 65a:	1141                	addi	sp,sp,-16
 65c:	e422                	sd	s0,8(sp)
 65e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 660:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 664:	00000797          	auipc	a5,0x0
 668:	1fc7b783          	ld	a5,508(a5) # 860 <freep>
 66c:	a02d                	j	696 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 66e:	4618                	lw	a4,8(a2)
 670:	9f2d                	addw	a4,a4,a1
 672:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 676:	6398                	ld	a4,0(a5)
 678:	6310                	ld	a2,0(a4)
 67a:	a83d                	j	6b8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 67c:	ff852703          	lw	a4,-8(a0)
 680:	9f31                	addw	a4,a4,a2
 682:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 684:	ff053683          	ld	a3,-16(a0)
 688:	a091                	j	6cc <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68a:	6398                	ld	a4,0(a5)
 68c:	00e7e463          	bltu	a5,a4,694 <free+0x3a>
 690:	00e6ea63          	bltu	a3,a4,6a4 <free+0x4a>
{
 694:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 696:	fed7fae3          	bgeu	a5,a3,68a <free+0x30>
 69a:	6398                	ld	a4,0(a5)
 69c:	00e6e463          	bltu	a3,a4,6a4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a0:	fee7eae3          	bltu	a5,a4,694 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6a4:	ff852583          	lw	a1,-8(a0)
 6a8:	6390                	ld	a2,0(a5)
 6aa:	02059813          	slli	a6,a1,0x20
 6ae:	01c85713          	srli	a4,a6,0x1c
 6b2:	9736                	add	a4,a4,a3
 6b4:	fae60de3          	beq	a2,a4,66e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6b8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6bc:	4790                	lw	a2,8(a5)
 6be:	02061593          	slli	a1,a2,0x20
 6c2:	01c5d713          	srli	a4,a1,0x1c
 6c6:	973e                	add	a4,a4,a5
 6c8:	fae68ae3          	beq	a3,a4,67c <free+0x22>
    p->s.ptr = bp->s.ptr;
 6cc:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6ce:	00000717          	auipc	a4,0x0
 6d2:	18f73923          	sd	a5,402(a4) # 860 <freep>
}
 6d6:	6422                	ld	s0,8(sp)
 6d8:	0141                	addi	sp,sp,16
 6da:	8082                	ret

00000000000006dc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6dc:	7139                	addi	sp,sp,-64
 6de:	fc06                	sd	ra,56(sp)
 6e0:	f822                	sd	s0,48(sp)
 6e2:	f426                	sd	s1,40(sp)
 6e4:	f04a                	sd	s2,32(sp)
 6e6:	ec4e                	sd	s3,24(sp)
 6e8:	e852                	sd	s4,16(sp)
 6ea:	e456                	sd	s5,8(sp)
 6ec:	e05a                	sd	s6,0(sp)
 6ee:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f0:	02051493          	slli	s1,a0,0x20
 6f4:	9081                	srli	s1,s1,0x20
 6f6:	04bd                	addi	s1,s1,15
 6f8:	8091                	srli	s1,s1,0x4
 6fa:	0014899b          	addiw	s3,s1,1
 6fe:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 700:	00000517          	auipc	a0,0x0
 704:	16053503          	ld	a0,352(a0) # 860 <freep>
 708:	c515                	beqz	a0,734 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 70c:	4798                	lw	a4,8(a5)
 70e:	02977f63          	bgeu	a4,s1,74c <malloc+0x70>
 712:	8a4e                	mv	s4,s3
 714:	0009871b          	sext.w	a4,s3
 718:	6685                	lui	a3,0x1
 71a:	00d77363          	bgeu	a4,a3,720 <malloc+0x44>
 71e:	6a05                	lui	s4,0x1
 720:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 724:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 728:	00000917          	auipc	s2,0x0
 72c:	13890913          	addi	s2,s2,312 # 860 <freep>
  if(p == (char*)-1)
 730:	5afd                	li	s5,-1
 732:	a895                	j	7a6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 734:	00000797          	auipc	a5,0x0
 738:	13478793          	addi	a5,a5,308 # 868 <base>
 73c:	00000717          	auipc	a4,0x0
 740:	12f73223          	sd	a5,292(a4) # 860 <freep>
 744:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 746:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 74a:	b7e1                	j	712 <malloc+0x36>
      if(p->s.size == nunits)
 74c:	02e48c63          	beq	s1,a4,784 <malloc+0xa8>
        p->s.size -= nunits;
 750:	4137073b          	subw	a4,a4,s3
 754:	c798                	sw	a4,8(a5)
        p += p->s.size;
 756:	02071693          	slli	a3,a4,0x20
 75a:	01c6d713          	srli	a4,a3,0x1c
 75e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 760:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 764:	00000717          	auipc	a4,0x0
 768:	0ea73e23          	sd	a0,252(a4) # 860 <freep>
      return (void*)(p + 1);
 76c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 770:	70e2                	ld	ra,56(sp)
 772:	7442                	ld	s0,48(sp)
 774:	74a2                	ld	s1,40(sp)
 776:	7902                	ld	s2,32(sp)
 778:	69e2                	ld	s3,24(sp)
 77a:	6a42                	ld	s4,16(sp)
 77c:	6aa2                	ld	s5,8(sp)
 77e:	6b02                	ld	s6,0(sp)
 780:	6121                	addi	sp,sp,64
 782:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 784:	6398                	ld	a4,0(a5)
 786:	e118                	sd	a4,0(a0)
 788:	bff1                	j	764 <malloc+0x88>
  hp->s.size = nu;
 78a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 78e:	0541                	addi	a0,a0,16
 790:	00000097          	auipc	ra,0x0
 794:	eca080e7          	jalr	-310(ra) # 65a <free>
  return freep;
 798:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 79c:	d971                	beqz	a0,770 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 79e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a0:	4798                	lw	a4,8(a5)
 7a2:	fa9775e3          	bgeu	a4,s1,74c <malloc+0x70>
    if(p == freep)
 7a6:	00093703          	ld	a4,0(s2)
 7aa:	853e                	mv	a0,a5
 7ac:	fef719e3          	bne	a4,a5,79e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7b0:	8552                	mv	a0,s4
 7b2:	00000097          	auipc	ra,0x0
 7b6:	b70080e7          	jalr	-1168(ra) # 322 <sbrk>
  if(p == (char*)-1)
 7ba:	fd5518e3          	bne	a0,s5,78a <malloc+0xae>
        return 0;
 7be:	4501                	li	a0,0
 7c0:	bf45                	j	770 <malloc+0x94>
