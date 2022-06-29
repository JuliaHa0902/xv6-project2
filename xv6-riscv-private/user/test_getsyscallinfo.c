#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main (void) {
	fprintf (1, "The number of syscall is %d\n", getsyscallinfo());
	exit(0);
}
