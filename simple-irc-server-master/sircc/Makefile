CC	 	= gcc
LD	 	= gcc
CFLAGS	 	= -Wall -O2

LDFLAGS	 	= 
DEFS 	 	=
LIB		= -pthread

all:	sircc

sircc: sircc.c csapp.c
	$(CC) $(DEFS) $(CFLAGS) -c csapp.c	
	$(CC) $(DEFS) $(CFLAGS) -c sircc.c
	$(LD) -o $@ $(LDFLAGS) sircc.o csapp.o $(LIB)

clean:
	rm -f *.o sircc
