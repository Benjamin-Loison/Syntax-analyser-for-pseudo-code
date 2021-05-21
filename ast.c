#include "ast.h"

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}


var_t* make_ident (char *s, var_t *program_vars, proc_t *program_procs)
{
	var_t *v = malloc(sizeof(var_t));
	v->name = s;
	v->value = 0;	// make variable false initially
	v->next = NULL;
	return v;
}

var_t* find_ident (char *s, var_t *program_vars, proc_t *program_procs)
{
	var_t *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

varlist_t* make_varlist (char *s, var_t *program_vars, proc_t *program_procs)
{
	var_t *v = find_ident(s, program_vars, program_procs);
	varlist_t *l = malloc(sizeof(varlist_t));
	l->var = v;
	l->next = NULL;
	return l;
}

expr_t* make_expr (int type, var_t *var, expr_t *left, expr_t *right)
{
	expr_t *e = malloc(sizeof(expr_t));
	e->type = type;
	e->var = var;
	e->left = left;
	e->right = right;
	return e;
}

stmt_t* make_stmt (int type, var_t *var, expr_t *expr,
			stmt_t *left, stmt_t *right, varlist_t *list)
{
	stmt_t *s = malloc(sizeof(stmt_t));
	s->type = type;
	s->var = var;
	s->expr = expr;
	s->left = left;
	s->right = right;
	s->list = list;
	return s;
}

proc_t* make_proc (stmt_t *s, var_t *program_vars, proc_t *program_procs/*, int type*/) /// TODO: initialize with the argument
{
	proc_t* p = malloc(sizeof(proc_t));
	p->name = "testName";
	p->next = NULL;
	//stmt* ns = make_stmt (type/*PROC_ENDED*/, NULL, NULL, NULL, NULL, NULL);
	p->statement = s/*ns*//*s*/;
	p->var = NULL;
	p->next = NULL;
	return p;
}

