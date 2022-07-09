#include "kernel/types.h"
#include "user/user.h"
#include "stddef.h"

int main(int argc, char** argv) {
	printf("Mother %d created\n", getpid());
	const int NCHILD = 2;
	const int ticket_list [] = {2, 4};

	for(int i = 0; i < NCHILD; i++) {
		const int pid = fork();
		if(pid < 0) {
			fprintf(1, "Fork fails!"); 
			exit(0);
		}
		if(pid == 0) {
			settickets(ticket_list[i]);
			printf("Child %d created with %d tickets\n", getpid(), ticket_list[i]);
			// Loop forever
			while(1);
			printf("Child %d exiting\n", getpid());
			exit(0);
		} else {
			printf ("Parent running\n");
		}
	}
	printf("Parent exiting\n");
	exit(0);
}
