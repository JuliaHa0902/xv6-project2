#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void spin () {
	int j;
	int k = 0;
	for (j = 0; j < 100000000; j++) {
		k = k + j - j + 1; //random calculation
	}
}

int main (int argc, char *argv[]) {
	int ticket_list [] = {1, 2, 3};
	settickets (ticket_list[0]);
	cps();
	
	int i;
	for (i = 1; i < 3; i++) {
		int child = fork();
		if (child < 0) {
			// fork failed
			fprintf(1, "fork failed\n");
			exit(1);
		} else if (child == 0) {
			// child (new process)
			settickets (ticket_list[i]);
			cps();
			spin();
		} else {
			// parent goes down this path (main)
			spin();
		}		
	}
	exit(0);
}
