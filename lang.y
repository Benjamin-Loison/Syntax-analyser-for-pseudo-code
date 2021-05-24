%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ast.h"
#include "printer.h"
#include "executer.h"

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

%token SKIP BREAK VAR DO OD ASSIGN PRINT OR EQUAL ADD SUB AND XOR NOT TRUE FALSE ELSE IF FI PROC_END PROC_ENDED COND_BEGIN COND_END GNEQ
%token <i> IDENT PROC_BEGIN
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
	| proc_whole proc_whole {}

proc_begin :
	PROC_BEGIN
		{
			char *proc_name = malloc(sizeof(char) * strlen($1));
			strcpy(proc_name, (char*)((long)($1) + 5));
			debug("proc", "begin", proc_name);
			if(is_in_a_proc) {
				yyerror("already in a process !\n");
				exit(1);
			}
			proc_t* tmp = program_procs;
			program_procs = make_proc(proc_name);
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
	| BREAK
		{ $$ = make_stmt(S_BREAK, NULL, NULL, NULL, NULL, NULL); }

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
	| expr SUB expr
		{ $$ = make_expr(E_SUB,NULL,$1,$3); }
	| expr AND expr
		{ $$ = make_expr(E_AND,NULL,$1,$3); }
	| expr GNEQ expr
		{ $$ = make_expr(E_GNEQ,NULL,$1,$3); }
	| NOT expr
		{ $$ = make_expr(E_NOT,NULL,$2,NULL); }
	| TRUE
		{ $$ = make_expr(E_TRUE,NULL,NULL,NULL); }
	| FALSE
		{ $$ = make_expr(E_FALSE,NULL,NULL,NULL); }
	| ELSE
		{ $$ = make_expr(E_ELSE,NULL,NULL,NULL); }
	| '(' expr ')'
		{ $$ = $2; }

%%

#include "langlex.c"

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
		if (print_ast_flag) print_ast(program_vars, program_procs);
		// execution enabled ?
		if(execute_flag) execute_ast(program_vars, program_procs);
	} else
		yyerror("The parser failed.\n\n");

	return EXIT_SUCCESS;
}
