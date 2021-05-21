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
bool is_in_a_proc = false;

/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var* make_ident (char *s)
{
	debug("make_ident...\n");
	var *v = malloc(sizeof(var));
	v->name = s;
	v->value = 0;	// make variable false initially
	v->next = NULL;
	return v;
}

var* find_ident_from_var (char *s, var* vTmp, bool violent)
{
	//if(vTmp == NULL) { yyerror("vTmp NULL"); exit(1); }
	if(!vTmp) return NULL;
	debug("find_ident_from_var (%s)...\n", vTmp->name);
	var* v = vTmp; // otherwise might change original one
	while (v && strcmp(v->name, s)/* && printf("v (%s)", v->name)*/) v = v->next;
    if (!v) { if(violent) { yyerror("undeclared variable"); exit(1); } else return NULL; }
    return v;
}

var* find_global_ident (char *s)
{
	debug("find_global_ident...\n");
    return find_ident_from_var (s, program_vars, true);
}

var* find_local_ident (char *s)
{
	debug("find_local_ident a\n", s);
	proc* p = program_procs;
	debug("find_local_ident b\n");
	var* v = p->var;
	if(v == NULL) debug("no local variables found !\n");
	debug("find_local_ident c\n");
	return find_ident_from_var (s, v, false);
}

var* find_ident (char *s)
{
	debug("find_ident (%s)...\n", s); // si pas de "\n" ça n'affiche pas forcément u_u
	var* v = find_local_ident (s);
	if(v == NULL) { debug("%s not found locally, looking globally...\n", s); v = find_global_ident (s); }
	if(v == NULL) { yyerror("undeclared variable"); exit(1); }
	return v;
}

void print_variables (var *v)
{
	if(v != NULL) { printf("%s %i\n", v->name, v->value); print_variables(v->next); }
}

void print_local_variables ()
{
	print_variables (program_procs->var);
}

void print_global_variables ()
{
	print_variables (program_vars);
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

proc* make_proc (/*stmt *s*//*, int type*//*, var* v*/) /// TODO: initialize with the argument
{
	debug("make_proc\n");
	proc* p = malloc(sizeof(proc));
	p->name = "testName";
	p->next = NULL;
	//stmt* ns = make_stmt (type/*PROC_ENDED*/, NULL, NULL, NULL, NULL, NULL);
	p->statement = NULL/*ns*//*s*/;
	p->var = NULL/*v*/;
	p->next = NULL;
	return p;
}

void add_program_vars (var *v)
{
	if(program_vars == NULL)
		program_vars = v;
	else
	{
		var *program_vars_tmp = program_vars;
		while(program_vars_tmp->next != NULL) program_vars_tmp = program_vars_tmp->next;
		program_vars_tmp->next = v;
	}
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
%type <v> vars
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

prog	:  proc_whole { }

prog	: prog_vars proc_whole  { }

prog_vars	: VAR declist ';'   { /*program_vars = */add_program_vars($2); /*var* tmp = program_vars; program_vars = $2; program_vars->next = tmp;*/ }
     | prog_vars prog_vars {}

//proc    : PROC_BEGIN stmt PROC_END { proc* tmp = program_procs; program_procs = make_proc($2); program_procs->next = tmp; }
//     | proc proc {}

proc_whole	: proc_begin proc proc_end {}

proc_begin	: PROC_BEGIN { debug("proc_begin...\n"); if(is_in_a_proc) { yyerror("already in a process !\n"); exit(1); } proc* tmp = program_procs; program_procs = make_proc(/*$1*/); program_procs->next = tmp; is_in_a_proc = true; }

proc	: vars stmt { debug("procing a...\n"); program_procs->statement = $2; }

proc	: stmt { debug("procing b...\n"); program_procs->statement = $1; }

proc_end	: PROC_END { debug("proc_end...\n"); if(!is_in_a_proc) { yyerror("not in a process !\n"); exit(1);} is_in_a_proc = false; }

vars	: VAR declist ';'	{ debug("vars...\n"); var* tmp = program_procs->var; if(program_procs->var == NULL) debug("ppVar NULL\n"); program_procs->var = $2; if(program_procs->var == NULL) debug("ppVar STILL NULL\n"); program_procs->var->next = tmp; } // i forgot the next lol
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
		case TRUE: debug("TRUE\n"); return 1;
		case FALSE: debug("FALSE\n"); return 0;
		case XOR: debug("XOR\n"); return eval(e->left) ^ eval(e->right);
		case OR: debug("OR\n"); return eval(e->left) || eval(e->right);
		case EQUAL: debug("EQUAL\n"); return eval(e->left) == eval(e->right);
		case ADD: debug("ADD\n"); return eval(e->left) + eval(e->right);
		case AND: debug("AND\n"); return eval(e->left) && eval(e->right);
		case NOT: debug("NOT\n"); return !eval(e->left);
		case 0: debug("ZERO\n"); if(e->var == NULL) debug("e->var is NULL\n"); return e->var->value;
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
	printf(s);
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
			debug("WHILE a\n");
            //if (eval(s->expr)) execute_step(s->left);
			while (eval(s->expr))
			{
				debug("WHILE b\n");
				execute_step(s->left);
				debug("WHILE c\n");
			}
			//debug("yeah\n");
			//return; // this is so violent
			debug("WHILE d\n");
			s->type = PROC_ENDED;
			debug("WHILE e\n");
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
	if(p->statement == NULL) debug("p->statement is NULL\n");
	if(p->statement != NULL && p->statement->type == PROC_ENDED) debug("p->statement->type == PROC_ENDED\n");
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
