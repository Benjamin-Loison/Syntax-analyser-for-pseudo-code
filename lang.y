%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdbool.h>
#include "ast.h"

int yylex();


/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var_t *program_vars;
proc_t *program_procs;


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

prog : prog_vars proc  { }

prog_vars :
	VAR declist ';'
		{ var_t* tmp = program_vars; program_vars = $2; program_vars->next = tmp; }
	| prog_vars prog_vars {  }

proc :
	PROC_BEGIN stmt PROC_END
		{ proc_t* tmp = program_procs; program_procs = make_proc($2, program_vars, program_procs); program_procs->next = tmp; }
	| proc proc {  }

vars :
	VAR declist ';'
		{ var_t* tmp = program_procs->var; program_procs->var = $2; program_procs->var = tmp; }
	| vars vars {  }

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
		{ $$ = $2; }
	| DO cond OD
		{ $$ = make_stmt(DO, NULL, NULL, NULL, NULL, NULL, make_cond($2)) }

cond :
	COND_BEGIN expr COND_END stmt
		{ $$ = make_stmt(COND, NULL, $2, $4, NULL, NULL, NULL); }
	cond cond
		{ $$ = make_stmt(COND, NULL, NULL, $1, $2, NULL, NULL); }

assign :
	IDENT ASSIGN expr
		{ $$ = make_stmt(ASSIGN,find_ident($1, program_vars,
 program_procs),$3,NULL,NULL,NULL, NULL); }

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

void debug(char* s)
{
	//printf(s);
}

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

bool is_a_proc_needing_execute(proc_t *p)
{
	printf("is_a_proc_needing_execute a\n");
	if (!p) return false;
	printf("is_a_proc_needing_execute b\n");
	//stmt *s = p->statement;
	//printf("is_a_proc_needing_execute c\n");
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
