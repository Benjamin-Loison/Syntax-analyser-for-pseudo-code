%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppprint.h"

int tab = 0;

int yylex();

void indentation()
{
	for (int i = 0 ; i < tab ; i ++)
		printf ("\t");
	tab ++;
}
void desindentation()
{
	tab --;
}

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}

/***************************************************************************/
/* Data structures for storing a programme.								*/

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

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *program_vars;
stmt *program_stmts;

/****************************************************************************/
/* Functions for settting up data structures at parse time.				 */

var* make_ident (char *s)
{
	printf("[make_indent] '%s'\n", s);
	var *v = malloc(sizeof(var));
	v->name = s;
	v->value = 0;	// make variable null initially
	v->next = NULL;
	return v;
}

var* find_ident (char *s)
{
	printf("[find_indent] '%s'\n", s);
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

varlist* make_varlist (char *s)
{
	printf("[make_varlist] '%s'\n", s);
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
		{ $$ = make_stmt(ASSIGN,find_ident($1),$3,NULL,NULL,NULL); }

varlist	:
	  IDENT			{ $$ = make_varlist($1); }
	| varlist ',' IDENT	{ ($$ = make_varlist($3))->next = $1; }

expr	:
	  CST { $$ = make_expr($1,NULL,NULL,NULL); }
	| IDENT		{ $$ = make_expr(0,find_ident($1),NULL,NULL); }
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
/*  pp_print section														*/

// TODO!

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
