#include "structure.h"

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

var* find_ident (char *s, var *program_vars)
{
	printf("[find_indent] '%s'\n", s);
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { printf("undeclared variable\n\n"); exit(1); }
	return v;
}

varlist* make_varlist (char *s, var *program_vars)
{
	printf("[make_varlist] '%s'\n", s);
	var *v = find_ident(s, program_vars);
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

