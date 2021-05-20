%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "structure.h"

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
/* programme interpreter	  :											 */

int eval (expr *e)
{
	switch (e->type)
	{
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
		case PRINT: 
			print_vars(s->list);
			puts("");
			break;
	}
}

/****************************************************************************/

int main (int argc, char **argv)
{
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if (!yyparse()) execute(program_stmts);
}
