#include "ast.h"

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "!!! ERROR: %s\n", s);
}

void debug(const char* loc, const char* msg, const char *precision)
{
	if(!ast_debug) return;
	char long_dots[100];
	sprintf(long_dots, "%s ............................................................", msg);
	printf("[%20s]: %.41s (%s)\n", loc, long_dots, precision);
}

void clean_debug(const char* msg, const char *precision)
{
	/*if(!ast_debug) return;
	char long_dots[100];
	sprintf(long_dots, "%s ............................................................", msg);
	printf("%24s| %.39s (%s)\n", "", long_dots, precision);*/ return;
}

var_t* make_ident (char *s)
{
	debug("make_ident", "new variable", s);
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
	//clean_debug("variable_name", vTmp->name);
	var_t* v = vTmp; // otherwise might change original one
	while (v && strcmp(v->name, s)/* && printf("v (%s)", v->name)*/) v = v->next;
	if (!v) { if(violent) { yyerror("undeclared variable"); exit(1); } else return NULL; }
	return v;
}

var_t* find_global_ident (char *s, var_t* program_vars)
{
	clean_debug("looking gloablly", s);
	return find_ident_from_var (s, program_vars, 1);
}

var_t* find_local_ident (char *s, proc_t *program_procs)
{
	clean_debug("looking locally", s);
	proc_t* p = program_procs;
	var_t* v = p->var;
	if(v == NULL) clean_debug("no local variables found !", s);
	return find_ident_from_var (s, v, 0);
}

var_t* find_ident (char *s, proc_t* program_procs, var_t* program_vars)
{
	debug("find_ident", "looking", s); // si pas de "\n" ça n'affiche pas forcément u_u
	var_t* v = find_local_ident (s, program_procs);
	if(!v) {
		clean_debug("unfound locally, looking globally", s);
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

void print_global_variables (var_t *program_vars)
{
	print_variables (program_vars);
}

varlist_t* make_varlist (char *s, proc_t* program_procs, var_t* program_vars)
{
	var_t *v = find_ident(s, program_procs, program_vars);
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

proc_t* make_proc (char* name) /// TODO: initialize with the argument
{
	debug("make_proc", "New proc", name);
	proc_t* p = malloc(sizeof(proc_t));
	p->name = name;
	p->next = NULL;
	//stmt* ns = make_stmt (type/*PROC_ENDED*/, NULL, NULL, NULL, NULL, NULL);
	p->statement = NULL/*ns*//*s*/;
	p->var = NULL/*v*/;
	p->next = NULL;
	return p;
}

var_t* add_program_vars (var_t *v, var_t* program_vars)
{
	if(program_vars == NULL) {
		program_vars = v;
	} else {
		var_t *program_vars_tmp = program_vars;
		while(program_vars_tmp->next != NULL) program_vars_tmp = program_vars_tmp->next;
		program_vars_tmp->next = v;
	}
	return program_vars;
}
