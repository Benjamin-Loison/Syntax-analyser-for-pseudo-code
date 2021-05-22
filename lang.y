%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ast.h"

int yylex();


/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var_t *program_vars;
proc_t *program_procs;
int is_in_a_proc = 0;

%}

// %error-verbose is deprecated
%define parse.error verbose

/****************************************************************************/

/* types used by terminals and non-terminals */

%union {
	char *i;
	var_t *v;
	varlist_t *l;
	expr_t *e;
	stmt_t *s;
	int n;
}

%type <v> declist
%type <l> varlist
%type <e> expr
%type <s> stmt assign cond

%token VAR DO OD ASSIGN PRINT OR EQUAL ADD AND XOR NOT TRUE FALSE IF FI PROC_BEGIN PROC_END PROC_ENDED COND_BEGIN COND_END
%token <i> IDENT
%token <n> CST

%left ';'

%left EQUAL
%left OR XOR
%left AND
%left ADD
%right NOT

%%
prog :
	proc_whole {}
	| prog_vars proc_whole  {}

prog_vars :
	VAR declist ';'
		{ add_program_vars($2); }
	| prog_vars prog_vars {}

//proc    : PROC_BEGIN stmt PROC_END { proc* tmp = program_procs; program_procs = make_proc($2); program_procs->next = tmp; }
//     | proc proc {}

proc_whole :
	proc_begin proc proc_end {}

proc_begin :
	PROC_BEGIN
		{
			debug("proc_begin...\n");
			if(is_in_a_proc) {
				yyerror("already in a process !\n");
				exit(1);
			}
			proc* tmp = program_procs;
			program_procs = make_proc(/*$1*/);
			program_procs->next = tmp;
			is_in_a_proc = 1;
		}

proc :
	vars stmt
		{ debug("procing a...\n"); program_procs->statement = $2; }
	| stmt
		{ debug("procing b...\n"); program_procs->statement = $1; }

proc_end :
	PROC_END
		{
			debug("proc_end...\n");
			if(!is_in_a_proc) {
				yyerror("not in a process !\n");
				exit(1);
			}
			is_in_a_proc = 0;
		}

vars :
	VAR declist ';'
		{
			debug("vars...\n");
			var* tmp = program_procs->var;
			if(program_procs->var == NULL) debug("ppVar NULL\n");
			program_procs->var = $2;
			if(program_procs->var == NULL) debug("ppVar STILL NULL\n");
			program_procs->var->next = tmp; // i forgot the next lol
		}
	 | vars vars {}

declist :
	IDENT
		{ $$ = make_ident($1, program_vars, program_procs); }
	| declist ',' IDENT
		{ ($$ = make_ident($3, program_vars, program_procs))->next = $1; }
	//| declist ';' 'var' IDENT { ($$ = make_ident($4))->next = $1; }

stmt :
	assign
	| stmt ';' stmt	
		{ $$ = make_stmt(';',NULL,NULL,$1,$3,NULL, NULL); }
	| PRINT varlist
		{ $$ = make_stmt(PRINT,NULL,NULL,NULL,NULL,$2, NULL); }
	| IF cond FI
		{ $$ = make_stmt(IF, NULL, NULL, $2, NULL, NULL); }
	| DO cond OD
		{ $$ = make_stmt(DO, NULL, NULL, $2, NULL, NULL); }

cond :
	COND_BEGIN expr COND_END stmt
		{ $$ = make_stmt(COND, NULL, $2, $4, NULL, NULL, NULL); }
	| cond cond
		{ $$ = make_stmt(COND, NULL, NULL, $1, $2, NULL); }

assign :
	IDENT ASSIGN expr
		{ $$ = make_stmt(ASSIGN,find_ident($1, program_vars, program_procs),$3,NULL,NULL,NULL, NULL); }

varlist :
	IDENT
		{ $$ = make_varlist($1, program_vars, program_procs); }
	| varlist ',' IDENT
		{ ($$ = make_varlist($3, program_vars, program_procs))->next = $1; }

expr :
	CST
		{ $$ = make_expr($1,NULL,NULL,NULL); }
	| IDENT
		{ $$ = make_expr(0,find_ident($1, program_vars, program_procs),NULL,NULL); }
	| expr XOR expr
		{ $$ = make_expr(XOR,NULL,$1,$3); }
	| expr OR expr
		{ $$ = make_expr(OR,NULL,$1,$3); }
	| expr EQUAL expr
		{ $$ = make_expr(EQUAL,NULL,$1,$3); }
	| expr ADD expr
		{ $$ = make_expr(ADD,NULL,$1,$3); }
	| expr AND expr
		{ $$ = make_expr(AND,NULL,$1,$3); }
	| NOT expr
		{ $$ = make_expr(NOT,NULL,$2,NULL); }
	| TRUE
		{ $$ = make_expr(TRUE,NULL,NULL,NULL); }
	| FALSE
		{ $$ = make_expr(FALSE,NULL,NULL,NULL); }
	| '(' expr ')'
		{ $$ = $2; }

%%

#include "langlex.c"

/****************************************************************************/
/* programme interpreter      :                                             */

int eval (expr_t *e)
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

void print_vars (varlist_t *l)
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

// il faut pas éxécuter processus 1 puis 2 car sinon ça risque de s'interbloquer donc faut faire un peu de 1 puis un peu de 2 et ainsi de suite
void execute_step(stmt_t *s)
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
        case PRINT:
			debug("PRINT\n");
            print_vars(s->list);
            puts("");
            break;
    }
}

void execute (stmt_t *s)
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
		case PRINT: 
			print_vars(s->list);
			puts("");
			break;
		case PROC_ENDED:
			break;
	}
}

int is_a_proc_needing_execute(proc_t *p)
{
	printf("is_a_proc_needing_execute a\n");
	if (!p) return 0;
	printf("is_a_proc_needing_execute b\n");
	//stmt *s = p->statement;
	//printf("is_a_proc_needing_execute c\n");
	if(p->statement == NULL) debug("p->statement is NULL\n");
	if(p->statement != NULL && p->statement->type == PROC_ENDED) debug("p->statement->type == PROC_ENDED\n");
	return (p->statement != NULL && p->statement->type != PROC_ENDED) || is_a_proc_needing_execute(p->next);
}

unsigned int proc_size_aux(proc_t *p, unsigned int acc)
{
	if (!p) return acc;
	return proc_size_aux(p->next, acc + 1);
}

unsigned int get_proc_size(proc_t *p)
{
	return proc_size_aux(p, 0);
}

proc_t* get_proc(proc_t *p, unsigned int proc_id)
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
			proc_t* p = get_proc(program_procs, r);
			printf("I got the proc I need to see me through\n");
			execute_step(p->statement);
		}
		//execute(program_stmts);
	}
}
