#include "ast.h"

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}

void debug(char* s)
{
	printf(s);
}

var_t* make_ident (char *s)
{
	debug("make_ident...\n");
	var_t *v = malloc(sizeof(var_t));
	v->name = s;
	v->value = 0;	// make variable null initially
	v->next = NULL;
	return v;
}

var_t* find_ident_from_var (char *s, var_t* vTmp, int violent)
{
	//if(vTmp == NULL) { yyerror("vTmp NULL"); exit(1); }
	if(!vTmp) return NULL;
	debug("find_ident_from_var (%s)...\n", vTmp->name);
	var_t* v = vTmp; // otherwise might change original one
	while (v && strcmp(v->name, s)/* && printf("v (%s)", v->name)*/) v = v->next;
    if (!v) { if(violent) { yyerror("undeclared variable"); exit(1); } else return NULL; }
    return v;
}

var_t* find_global_ident (char *s, program_vars)
{
	debug("find_global_ident...\n");
    return find_ident_from_var (s, program_vars, 1);
}

var_t* find_local_ident (char *s, proc_t *program_procs)
{
	debug("find_local_ident a\n", s);
	proc_t* p = program_procs;
	debug("find_local_ident b\n");
	var_t* v = p->var;
	if(v == NULL) debug("no local variables found !\n");
	debug("find_local_ident c\n");
	return find_ident_from_var (s, v, 0);
}

var_t* find_ident (char *s, proc_t* program_procs, proc_t* program_vars)
{
	debug("find_ident (%s)...\n", s); // si pas de "\n" ça n'affiche pas forcément u_u
	var_t* v = find_local_ident (s, program_procs);
	if(!v) {
		debug("%s not found locally, looking globally...\n", s);
		v = find_global_ident (s, program_vars);
	}
	if(!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

void print_variables (var_t *v)
{
	if(!v) return;
	printf("%s %i\n", v->name, v->value);
	print_variables(v->next);
}

void print_local_variables (proc_t *program_procs)
{
	print_variables (program_procs->var);
}

void print_global_variables (proc_t *program_procs)
{
	print_variables (program_vars);
}

varlist_t* make_varlist (char *s)
{
	var_t *v = find_ident(s);
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

proc* make_proc (/*stmt *s*//*, int type*//*, var* v*/) /// TODO: initialize with the argument
{
	debug("make_proc\n");
	proc* p = malloc(sizeof(proc));
	p->name = "testName";
	p->next = NULL;
	//stmt* ns = make_stmt (type/*PROC_ENDED*/, NULL, NULL, NULL, NULL, NULL);
	p->statement = NULL/*ns*//*s*/;
	p->var = NULL/*v*/;
	p->next = NULL;
	return p;
}

void add_program_vars (var_t *v, var_t* program_vars)
{
	if(program_vars == NULL)
		program_vars = v;
	else
	{
		var *program_vars_tmp = program_vars;
		while(program_vars_tmp->next != NULL) program_vars_tmp = program_vars_tmp->next;
		program_vars_tmp->next = v;
	}
}
