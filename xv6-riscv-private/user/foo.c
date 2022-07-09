#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "stddef.h"

int main(int argc, char *argv[]) {
	printf("Parent created (pid:%d)\n", (int) getpid());
	int i;
	for (i = 0; i < 5; i++) {
		int child = fork();
		if (child < 0) {
			// fork failed
			fprintf(1, "fork failed\n");
			exit(1);
		} else if (child == 0) {
			// child (new process)
			printf("Child (pid:%d) created\n", (int) getpid());
			int j;
			int k = 0;
			for (j = 0; j < 100000000; j++) {
				k = k+ j - j + 1; //random calculation
			}
		} else {
			// parent goes down this path (main)
//			wait(NULL);
			printf("hello, I am parent with (pid:%d)\n", (int) getpid());
		}		
	}
	exit(0);
}
