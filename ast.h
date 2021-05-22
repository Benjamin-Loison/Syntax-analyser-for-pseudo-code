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
	cond_t *cond;
} stmt_t;

typedef struct proc
{
	char* name;
	stmt_t *statement;
	var_t* var;
	struct proc *next;
} proc_t;


/****************************************************************************/
/* Debugging and Error displaying functions                                 */


void yyerror(const char*);
void debug(char* s);



/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var_t* make_ident (char *s);
var_t* find_ident_from_var (char *s, var_t* vTmp, int violent);
var_t* find_global_ident (char *s, program_vars);
var_t* find_local_ident (char *s, proc_t *program_procs);
var_t* find_ident (char *s, proc_t* program_procs, proc_t* program_vars);
void print_variables (var_t *v);
void print_local_variables (proc_t *program_procs);
void print_global_variables (proc_t *program_procs);
varlist_t* make_varlist (char *s);
expr_t* make_expr (int type, var_t *var, expr_t *left, expr_t *right);
stmt_t* make_stmt (int type, var_t *var, expr_t *expr,
			stmt_t *left, stmt_t *right, varlist_t *list);
proc* make_proc (/*stmt *s*//*, int type*//*, var* v*/) /// TODO: initialize with the argument
void add_program_vars (var_t *v, var_t* program_vars);


#endif// __AST_H_
