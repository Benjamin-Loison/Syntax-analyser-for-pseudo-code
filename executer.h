#ifndef __EXECUTER_H_
#define __EXECUTER_H_

#include "ast.h"
#include <unistd.h>
#include <sys/wait.h>

typedef struct stack {
	stmt_t* stmt;
	struct stack* next;
} stmt_stack_t;

// Stack mgmt
void push(stmt_stack_t*,stmt_t*);
stmt_t* pop_stmt(stmt_stack_t*);// Does not update the stack!


// Execution
void execute_ast(var_t*, proc_t*);
void execute_one_step(var_t*, var_t*, stmt_t*);
stmt_t* eval_cond(stmt_t*);// Takes the S_COND statement. NULL if no nondition Ok
int isEmpty(stmt_stack_t*);

#endif// __EXECUTER_H_

