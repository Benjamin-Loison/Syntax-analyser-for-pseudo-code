#ifndef __AST_H_
#define __AST_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>



/***************************************************************************/
/* Global variable for debugging purposes                                  */
static int ast_debug = 0;


/***************************************************************************/
/* Data structures for storing a programme.                                */

enum STMT { S_JUXT, S_SKIP, S_COND, S_ASSIGN, S_PRINT, S_IF, S_DO, S_PROC_ENDED };

enum EXPR { E_CST, E_OTHER, E_XOR, E_OR, E_EQUAL, E_ADD, E_AND, E_NOT, E_TRUE, E_FALSE };

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
	enum EXPR type;	// TRUE, FALSE, OR, AND, NOT, 0 (variable)
	var_t *var;
	struct expr *left, *right;
} expr_t;

typedef struct stmt	// command
{
	enum STMT type;	// ASSIGN, ';', WHILE, PRINT
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
/* Debugging and Error displaying functions                                 */

void yyerror(const char*);
void debug(const char*, const char*, const char*);



/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

// variable related fnctions
var_t* make_ident (char *s);
var_t* find_ident_from_var (char *s, var_t* vTmp, int violent);
var_t* find_global_ident (char *s, var_t*);
var_t* find_local_ident (char *s, proc_t *program_procs);
var_t* find_ident (char *s, proc_t* program_procs, var_t* program_vars);
void print_variables (var_t *v);
void print_local_variables (proc_t *program_procs);
void print_global_variables (var_t* program_vars);
varlist_t* make_varlist (char *, proc_t*, var_t*);
var_t* add_program_vars (var_t *v, var_t* program_vars);

// Expression related function(~~s~~)
expr_t* make_expr (int type, var_t *var, expr_t *left, expr_t *right);

// Statement related function(~~s~~)
stmt_t* make_stmt (int type, var_t *var, expr_t *expr,
			stmt_t *left, stmt_t *right, varlist_t *list);

// Proc related function(~~s~~)
proc_t* make_proc (char*); /// TODO: initialize with the argument


#endif// __AST_H_

