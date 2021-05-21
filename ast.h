#ifndef __AST_H_
#define __AST_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var	// a variable
{
	char *name;
	int value;
	struct var *next;
} var_t;

typedef struct varlist	// variable reference (used for print statement)
{
	struct var *var;
	struct varlist *next;
} varlist_t;

typedef struct expr	// boolean expression
{
	int type;	// TRUE, FALSE, OR, AND, NOT, 0 (variable)
	var_t *var;
	struct expr *left, *right;
} expr_t;

typedef struct stmt	// command
{
	int type;	// ASSIGN, ';', WHILE, PRINT
	var_t *var;
	expr_t *expr;
	struct stmt *left, *right;
	varlist_t *list;
} stmt_t;

typedef struct proc
{
	char* name;
	stmt_t *statement;
	var_t* var;
	struct proc *next;
} proc_t;



/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

void yyerror(const char*);
var_t* make_ident (char*, var_t*, proc_t*);
var_t* find_ident (char*, var_t*, proc_t*);
varlist_t* make_varlist (char*, var_t*, proc_t*);
expr_t* make_expr (int, var_t*, expr_t*, expr_t*);
stmt_t* make_stmt (int, var_t*, expr_t*, stmt_t*, stmt_t*, varlist_t*);
proc_t* make_proc (stmt_t*, var_t*, proc_t*);

#endif// __AST_H_
