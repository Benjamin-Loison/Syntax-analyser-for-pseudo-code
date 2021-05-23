CC		= gcc
CFLAGS	=
SRC		= $(wildcard *.c) lang.c
OBJ	= $(SRC:.c=.o)
EXEC	= lang

.PHONY: all clean mrproper

all: $(EXEC)

langlex.c: langlex.l
	lex  -t langlex.l > langlex.c

lang.c: lang.y langlex.c
	yacc lang.y
	mv -f y.tab.c lang.c

clean:
	rm langlex.c lang.c *.o

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

$(EXEC): $(OBJ)
	yacc  lang.y
	mv -f y.tab.c lang.c
	cc $(OBJ) -o lang

mrproper: clean
	rm lang
