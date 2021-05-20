EXEC	= lang

.PHONY: all clean mrproper debug

all: $(EXEC)

$(EXEC): langlex.c lang.y
	yacc  lang.y
	mv -f y.tab.c lang.c
	gcc -o lang structure.c lang.c

debug: langlex.c lang.y
	yacc  -Wcounterexamples lang.y
	mv -f y.tab.c lang.c
	cc -c -o structure.o structure.c
	cc -c -o lang.o lang.c
	cc lang.o structure.o -o lang

langlex.c: langlex.l
	lex  -t langlex.l > langlex.c

clean:
	rm langlex.c lang.c *.o

mrproper: clean
	rm lang
