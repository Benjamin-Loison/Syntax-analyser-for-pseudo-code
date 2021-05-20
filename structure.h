#ifndef __H_STRUCTURE_
#define __H_STRUCTURE_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
/* Functions for settting up data structures at parse time.				 */

var* make_ident (char*);
var* find_ident (char*, var*);
varlist* make_varlist (char*, var*);
expr* make_expr (int, var*, expr*, expr*);
stmt* make_stmt (int, var*, expr*, stmt*, stmt*, varlist*);


#endif// __H_STRUCTURE_

