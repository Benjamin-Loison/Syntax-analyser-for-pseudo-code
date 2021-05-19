EXEC	= lang

.PHONY: all clean mrproper

all: $(EXEC)

$(EXEC): langlex.c lang.y
	yacc  lang.y
	mv -f y.tab.c lang.c
	cc    -c -o lang.o lang.c
	cc   lang.o   -o lang

langlex.c: langlex.l
	lex  -t langlex.l > langlex.c

clean:
	rm langlex.c lang.c lang.o

mrproper: clean
	rm lang
