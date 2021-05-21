%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdbool.h>

int yylex();

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}

/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var	// a variable
{
	char *name;
	int value;
	struct var *next;
} var;

typedef struct varlist	// variable reference (used for print statement)
{
	struct var *var;
	struct varlist *next;
} varlist;

typedef struct expr	// boolean expression
{
	int type;	// TRUE, FALSE, OR, AND, NOT, 0 (variable)
	var *var;
	struct expr *left, *right;
} expr;

typedef struct stmt	// command
{
	int type;	// ASSIGN, ';', WHILE, PRINT
	var *var;
	expr *expr;
	struct stmt *left, *right;
	varlist *list;
} stmt;

typedef struct proc
{
	char* name;
	stmt *statement;
	var* var;
	struct proc *next;
} proc;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *program_vars;
proc *program_procs;

/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var* make_ident (char *s)
{
	var *v = malloc(sizeof(var));
	v->name = s;
	v->value = 0;	// make variable false initially
	v->next = NULL;
	return v;
}

var* find_ident (char *s)
{
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

varlist* make_varlist (char *s)
{
	var *v = find_ident(s);
	varlist *l = malloc(sizeof(varlist));
	l->var = v;
	l->next = NULL;
	return l;
}

expr* make_expr (int type, var *var, expr *left, expr *right)
{
	expr *e = malloc(sizeof(expr));
	e->type = type;
	e->var = var;
	e->left = left;
	e->right = right;
	return e;
}

stmt* make_stmt (int type, var *var, expr *expr,
			stmt *left, stmt *right, varlist *list)
{
	stmt *s = malloc(sizeof(stmt));
	s->type = type;
	s->var = var;
	s->expr = expr;
	s->left = left;
	s->right = right;
	s->list = list;
	return s;
}

proc* make_proc (stmt *s/*, int type*/) /// TODO: initialize with the argument
{
	proc* p = malloc(sizeof(proc));
	p->name = "testName";
	p->next = NULL;
	//stmt* ns = make_stmt (type/*PROC_ENDED*/, NULL, NULL, NULL, NULL, NULL);
	p->statement = s/*ns*//*s*/;
	p->var = NULL;
	p->next = NULL;
	return p;
}


%}

// %error-verbose is deprecated
%define parse.error verbose

/****************************************************************************/

/* types used by terminals and non-terminals */

%union {
	char *i;
	var *v;
	varlist *l;
	expr *e;
	stmt *s;
}

%union {
		int n;
}

%type <v> declist
%type <l> varlist
%type <e> expr
%type <s> stmt assign

%token VAR WHILE DO OD ASSIGN PRINT OR EQUAL ADD AND XOR NOT TRUE FALSE IF FI ELSE THEN PROC_BEGIN PROC_END PROC_ENDED
%token <i> IDENT
%token <n> CST

%left ';'

%left EQUAL
%left OR XOR
%left AND
%left ADD
%right NOT

%%

prog	: prog_vars proc  { }

prog_vars	: VAR declist ';'   { var* tmp = program_vars; program_vars = $2; program_vars->next = tmp; }
     | prog_vars prog_vars {}

proc	: PROC_BEGIN stmt PROC_END { proc* tmp = program_procs; program_procs = make_proc($2); program_procs->next = tmp; }
	 | proc proc {}

vars	: VAR declist ';'	{ var* tmp = program_procs->var; program_procs->var = $2; program_procs->var = tmp; }
	 | vars vars {}

declist	: IDENT			{ $$ = make_ident($1); }
	| declist ',' IDENT	{ ($$ = make_ident($3))->next = $1; }
	//| declist ';' 'var' IDENT { ($$ = make_ident($4))->next = $1; }

stmt	: assign
	| stmt ';' stmt	
		{ $$ = make_stmt(';',NULL,NULL,$1,$3,NULL); }
	| WHILE expr DO stmt OD
		{ $$ = make_stmt(WHILE,NULL,$2,$4,NULL,NULL); }
	| IF expr THEN stmt FI
		{ $$ = make_stmt(IF,NULL,$2,$4,NULL,NULL); }
	| IF expr THEN stmt ELSE stmt FI
		{ $$ = make_stmt(IF,NULL,$2,$4,$6,NULL); }
	| PRINT varlist
		{ $$ = make_stmt(PRINT,NULL,NULL,NULL,NULL,$2); }

assign	: IDENT ASSIGN expr
		{ $$ = make_stmt(ASSIGN,find_ident($1),$3,NULL,NULL,NULL); }

varlist	: IDENT			{ $$ = make_varlist($1); }
	| varlist ',' IDENT	{ ($$ = make_varlist($3))->next = $1; }

expr	: CST { $$ = make_expr($1,NULL,NULL,NULL); }
	| IDENT		{ $$ = make_expr(0,find_ident($1),NULL,NULL); }
	| expr XOR expr	{ $$ = make_expr(XOR,NULL,$1,$3); }
	| expr OR expr	{ $$ = make_expr(OR,NULL,$1,$3); }
	| expr EQUAL expr	{ $$ = make_expr(EQUAL,NULL,$1,$3); }
	| expr ADD expr	{ $$ = make_expr(ADD,NULL,$1,$3); }
	| expr AND expr	{ $$ = make_expr(AND,NULL,$1,$3); }
	| NOT expr	{ $$ = make_expr(NOT,NULL,$2,NULL); }
	| TRUE		{ $$ = make_expr(TRUE,NULL,NULL,NULL); }
	| FALSE		{ $$ = make_expr(FALSE,NULL,NULL,NULL); }
	| '(' expr ')'	{ $$ = $2; }

%%

#include "langlex.c"

/****************************************************************************/
/* programme interpreter      :                                             */

int eval (expr *e)
{
	switch (e->type)
	{
		case TRUE: return 1;
		case FALSE: return 0;
		case XOR: return eval(e->left) ^ eval(e->right);
		case OR: return eval(e->left) || eval(e->right);
		case EQUAL: return eval(e->left) == eval(e->right);
		case ADD: return eval(e->left) + eval(e->right);
		case AND: return eval(e->left) && eval(e->right);
		case NOT: return !eval(e->left);
		case 0: return e->var->value;
	}
}

void print_vars (varlist *l)
{
	if (!l) return;
	print_vars(l->next);
	printf("%s = %i  ", l->var->name, l->var->value);
}

/*void execute_proc (proc *proc)
{
	if (!proc) return;
	print
}*/

void debug(char* s)
{
	//printf(s);
}

// il faut pas éxécuter processus 1 puis 2 car sinon ça risque de s'interbloquer donc faut faire un peu de 1 puis un peu de 2 et ainsi de suite
void execute_step(stmt *s)
{
	debug("doing: ");
	switch(s->type)
    {
        case ASSIGN:
			debug("ASSIGN\n");
            s->var->value = eval(s->expr);
            break;
        case ';':
			debug(";\n");
            execute_step(s->left);
			execute_step(s->right);
            /*s->left = s->right;
			s->right = NULL;*/
            break;
        case WHILE:
			debug("WHILE\n");
            //if (eval(s->expr)) execute_step(s->left);
			while (eval(s->expr)) execute_step(s->left);
			//debug("yeah\n");
			//return; // this is so violent
			s->type = PROC_ENDED;
            break;
        case IF:
			debug("IF\n");
            if(eval(s->expr)) execute_step (s->left);
            else if (s->right != NULL) execute_step(s->right);
            break;
        case PRINT:
			debug("PRINT\n");
            print_vars(s->list);
            puts("");
            break;
    }
}

void execute (stmt *s)
{
	switch(s->type)
	{
		case ASSIGN:
			s->var->value = eval(s->expr);
			break;
		case ';':
			execute(s->left);
			execute(s->right);
			break;
		case WHILE:
			while (eval(s->expr)) execute(s->left);
			break;
		case IF:
			if(eval(s->expr)) execute (s->left);
			else if (s->right != NULL) execute(s->right);
			break;
		case PRINT: 
			print_vars(s->list);
			puts("");
			break;
		case PROC_ENDED:
			break;
	}
}

bool is_a_proc_needing_execute(proc *p)
{
	printf("is_a_proc_needing_execute a\n");
	if (!p) return false;
	printf("is_a_proc_needing_execute b\n");
	//stmt *s = p->statement;
	//printf("is_a_proc_needing_execute c\n");
	return (p->statement != NULL && p->statement->type != PROC_ENDED) || is_a_proc_needing_execute(p->next);
}

unsigned int proc_size_aux(proc *p, unsigned int acc)
{
	if (!p) return acc;
	return proc_size_aux(p->next, acc + 1);
}

unsigned int get_proc_size(proc *p)
{
	return proc_size_aux(p, 0);
}

proc* get_proc(proc *p, unsigned int proc_id)
{
	return proc_id == 0 ? p : get_proc(p->next, proc_id--);
}

/****************************************************************************/

int main (int argc, char **argv)
{
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	printf("parsing...\n");
	if (!yyparse())
	{
		//if (!l) return;
		srand(time(NULL));
		printf("counting...\n");
		unsigned int proc_size = get_proc_size(program_procs);
		printf("proc_size: %i\n", proc_size);
		while(is_a_proc_needing_execute(program_procs))
		{
			printf("executing stuff...\n");
			int r = rand() % proc_size;
			printf("executing proc %i\n", r);
			proc* p = get_proc(program_procs, r);
			printf("I got the proc I need to see me through\n");
    		execute_step(p->statement);
		}
		//execute(program_stmts);
	}
}
