%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ast.h"
#include "printer.h"

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

%token SKIP VAR DO OD ASSIGN PRINT OR EQUAL ADD AND XOR NOT TRUE FALSE IF FI PROC_BEGIN PROC_END PROC_ENDED COND_BEGIN COND_END
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
		{ program_vars = add_program_vars($2, program_vars); }
	| prog_vars prog_vars {}

//proc    : PROC_BEGIN stmt PROC_END { proc* tmp = program_procs; program_procs = make_proc($2); program_procs->next = tmp; }
//     | proc proc {}

proc_whole :
	proc_begin proc proc_end {}

proc_begin :
	PROC_BEGIN
		{
			debug("proc", "begin", "");
			if(is_in_a_proc) {
				yyerror("already in a process !\n");
				exit(1);
			}
			proc_t* tmp = program_procs;
			program_procs = make_proc(/*$1*/);
			program_procs->next = tmp;
			is_in_a_proc = 1;
		}

proc :
	vars stmt
		{ debug("proc", "procing a...", ""); program_procs->statement = $2; }
	| stmt
		{ debug("proc", "procing b...", ""); program_procs->statement = $1; }

proc_end :
	PROC_END
		{
			debug("proc", "end", "");
			if(!is_in_a_proc) {
				yyerror("not in a process !\n");
				exit(1);
			}
			is_in_a_proc = 0;
		}

vars :
	VAR declist ';'
		{
			debug("vars", "", "");
			var_t* tmp = program_procs->var;
			if(program_procs->var == NULL) debug("vars", "ppVar NULL", "");
			program_procs->var = $2;
			if(program_procs->var == NULL) debug("vars", "ppVar STILL NULL", "");
			program_procs->var->next = tmp; // i forgot the next lol
		}
	 | vars vars {}

declist :
	IDENT
		{ $$ = make_ident($1); }
	| declist ',' IDENT
		{ ($$ = make_ident($3))->next = $1; }
	//| declist ';' 'var' IDENT { ($$ = make_ident($4))->next = $1; }

stmt :
	assign
	| stmt ';' stmt	
		{ $$ = make_stmt(';',NULL,NULL,$1,$3,NULL); }
	| PRINT varlist
		{ $$ = make_stmt(S_PRINT,NULL,NULL,NULL,NULL,$2); }
	| IF cond FI
		{ $$ = make_stmt(S_IF, NULL, NULL, $2, NULL, NULL); }
	| DO cond OD
		{ $$ = make_stmt(S_DO, NULL, NULL, $2, NULL, NULL); }
	| SKIP
		{ $$ = make_stmt(S_SKIP, NULL, NULL, NULL, NULL, NULL); }

cond :
	COND_BEGIN expr COND_END stmt
		{ $$ = make_stmt(S_COND, NULL, $2, $4, NULL, NULL); }
	| cond cond
		{ $$ = make_stmt(S_COND, NULL, NULL, $1, $2, NULL); }

assign :
	IDENT ASSIGN expr
		{ $$ = make_stmt(S_ASSIGN,find_ident($1, program_procs, program_vars),$3,NULL,NULL, NULL); }

varlist :
	IDENT
		{ $$ = make_varlist($1, program_procs, program_vars); }
	| varlist ',' IDENT
		{ ($$ = make_varlist($3, program_procs, program_vars))->next = $1; }

expr :
	CST
		{ $$ = make_expr(E_CST,(void*)(long)$1,NULL,NULL); }
	| IDENT
		{ $$ = make_expr(E_OTHER,find_ident($1, program_procs, program_vars),NULL,NULL); }
	| expr XOR expr
		{ $$ = make_expr(E_XOR,NULL,$1,$3); }
	| expr OR expr
		{ $$ = make_expr(E_OR,NULL,$1,$3); }
	| expr EQUAL expr
		{ $$ = make_expr(E_EQUAL,NULL,$1,$3); }
	| expr ADD expr
		{ $$ = make_expr(E_ADD,NULL,$1,$3); }
	| expr AND expr
		{ $$ = make_expr(E_AND,NULL,$1,$3); }
	| NOT expr
		{ $$ = make_expr(E_NOT,NULL,$2,NULL); }
	| TRUE
		{ $$ = make_expr(E_TRUE,NULL,NULL,NULL); }
	| FALSE
		{ $$ = make_expr(E_FALSE,NULL,NULL,NULL); }
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
		case E_TRUE:  debug("eval", "TRUE", ""); return 1;
		case E_FALSE: debug("eval", "FALSE", ""); return 0;
		case E_XOR:   debug("eval", "XOR", ""); return eval(e->left) ^ eval(e->right);
		case E_OR:    debug("eval", "OR", ""); return eval(e->left) || eval(e->right);
		case E_EQUAL: debug("eval", "EQUAL", ""); return eval(e->left) == eval(e->right);
		case E_ADD:   debug("eval", "ADD", ""); return eval(e->left) + eval(e->right);
		case E_AND:   debug("eval", "AND", ""); return eval(e->left) && eval(e->right);
		case E_NOT:   debug("eval", "NOT", ""); return !eval(e->left);
		case E_OTHER: debug("eval", "ZERO", ""); if(e->var == NULL) debug("evel", "other", "e->var is NULL"); return e->var->value;
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
	switch(s->type)
    {
        case S_ASSIGN:
			debug("execute_step", "start", "ASSIGN");
            s->var->value = eval(s->expr);
            break;
        case ';':
			debug("execute_step", "start", ";");
            execute_step(s->left);
			execute_step(s->right);
            /*s->left = s->right;
			s->right = NULL;*/
            break;
        case S_PRINT:
			debug("execute_step", "start", "PRINT");
            print_vars(s->list);
            break;
    }
}

void execute (stmt_t *s)
{
	switch(s->type)
	{
		case S_ASSIGN:
			s->var->value = eval(s->expr);
			break;
		case ';':
			execute(s->left);
			execute(s->right);
			break;
		case S_PRINT: 
			print_vars(s->list);
			break;
		case S_PROC_ENDED:
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
	if(p->statement == NULL) debug("is proc needing", "p->statement", "NULL");
	if(p->statement != NULL && p->statement->type == PROC_ENDED) debug("is proc needing", "p->statement->type", "PROC_ENDED");
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
	short print_ast_flag = 0;
	short execute_flag = 1;
	char *input_file = NULL;

	// Parse command line options
	for (int i = 1 ; i < argc ; i ++) {
		// printf ("%d / %d -> %s\n", i, argc - 1, argv[i]);
		if (!strcmp(argv[i], "-p"))
			print_ast_flag = 1;
		else if (!strcmp(argv[i], "-no-exec"))
			execute_flag = 0;
		else if (!strcmp(argv[i], "-f") && i + 1 < argc)
			input_file = argv[++i];
		else
			input_file = argv[i];
	}

	// Managing input file
	if (input_file == NULL) {
		yyerror("No input file specified.");
		exit(1);
	}
	yyin = fopen(input_file,"r");

	// Debug information
	printf("Program execution for:\n\tfile: %s\n", input_file);
	if(print_ast_flag) printf("\t%15s: \033[32menabled\033[0m\n", "ast printing");
		else printf("\t%15s: \033[33mdisabled\033[0m\n", "ast printing");
	if(execute_flag) printf("\t%15s: \033[32menabled\033[0m\n", "ast execution");
		else printf("\t%15s: \033[33mdisabled\033[0m\n", "ast execution");

	if (!yyparse()) {// The parsing was successfull
		if (print_ast_flag) print_ast(program_procs);
		// execution enabled ?
		if(execute_flag) {
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
	} else
		yyerror("The parser failed.\n\n");

	return EXIT_SUCCESS;
}
