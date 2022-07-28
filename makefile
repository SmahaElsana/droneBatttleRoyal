all: exec

exec: ass3.o drone.o printer.o scheduler.o target.o
	gcc -m32 -Wall -g -o ass3 ass3.o drone.o printer.o scheduler.o target.o 

ass3.o: ass3.s
	nasm -g -f elf ass3.s -o  ass3.o
drone.o: drone.s
	nasm -g -f elf -o drone.o drone.s
printer.o: printer.s
	nasm -g -f elf -o printer.o printer.s
scheduler.o: scheduler.s
	nasm -g -f elf -o scheduler.o scheduler.s
target.o: target.s
	nasm -g -f elf target.s -o target.o

.PHONY: clean
clean:
	rm -rf *.o ass3
# nasm -f elf -o try.o try.s && gcc -m32 -g -o try try.o && ./try
# make clean all && ./ass3 5 8 10 30 15019
