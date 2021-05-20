%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "executer.h"
#include "printer.h"

int yylex();

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}


/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *program_vars;
stmt *program_stmts;


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
	int n;// À négocier avec le Bison
}

%type <v> declist
%type <l> varlist
%type <e> expr
%type <s> stmt assign

%token VAR ASSIGN PRINT OR EQUAL ADD AND XOR NOT
%token <i> IDENT
%token <n> CST

%left ';'

%right CONDITION
%right CONDITIONNAL_LIST

%left EQUAL
%left OR XOR
%left AND
%left ADD
%right NOT

%%

prog	: vars stmt	{ program_stmts = $2; }

vars	: VAR declist ';'	{ var* tmp = program_vars; program_vars = $2; program_vars->next = tmp; }

declist	:
	  IDENT			{ $$ = make_ident($1); }
	| declist ',' IDENT	{ ($$ = make_ident($3))->next = $1; }

stmt	:
	  assign
	| stmt ';' stmt	
		{ $$ = make_stmt(';',NULL,NULL,$1,$3,NULL); }
	| PRINT varlist
		{ $$ = make_stmt(PRINT,NULL,NULL,NULL,NULL,$2); }

assign	: IDENT ASSIGN expr
		{ $$ = make_stmt(ASSIGN,find_ident($1, program_vars),$3,NULL,NULL,NULL); }

varlist	:
	  IDENT			{ $$ = make_varlist($1, program_vars); }
	| varlist ',' IDENT	{ ($$ = make_varlist($3, program_vars))->next = $1; }

expr	:
	  CST { $$ = make_expr($1,NULL,NULL,NULL); }
	| IDENT		{ $$ = make_expr(0,find_ident($1, program_vars),NULL,NULL); }
	| expr XOR expr	{ $$ = make_expr(XOR,NULL,$1,$3); }
	| expr OR expr	{ $$ = make_expr(OR,NULL,$1,$3); }
	| expr EQUAL expr	{ $$ = make_expr(EQUAL,NULL,$1,$3); }
	| expr ADD expr	{ $$ = make_expr(ADD,NULL,$1,$3); }
	| expr AND expr	{ $$ = make_expr(AND,NULL,$1,$3); }
	| NOT expr	{ $$ = make_expr(NOT,NULL,$2,NULL); }
	| '(' expr ')'	{ $$ = $2; }

%%

#include "langlex.c"

/****************************************************************************/
/* main bloc                                                                */

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
		if (print_ast_flag) print_ast(program_stmts);
		if(execute_flag) execute_ast(program_stmts);
	} else
		yyerror("The parser failed.\n\n");
}
