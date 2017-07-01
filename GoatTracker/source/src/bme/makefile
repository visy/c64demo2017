CFLAGS=-I/sw/include -D_GNU_SOURCE=1 -D_THREAD_SAFE
LIBS=/sw/lib/libSDLmain.a /sw/lib/libSDL.a -framework Cocoa -framework OpenGL -framework IOKit -framework Carbon -framework QuickTime

CFLAGS+=-O3 -Wall
CXXFLAGS=$(CFLAGS)


all: dat2inc datafile

datafile: datafile.c bme_end.c
	gcc $(CFLAGS) -o datafile datafile.c bme_end.c
	strip datafile

dat2inc: dat2inc.c
	gcc -o dat2inc dat2inc.c
	strip dat2inc

