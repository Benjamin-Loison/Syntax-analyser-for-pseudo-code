#ifndef __EXECUTER_H_
#define __EXECUTER_H_

#include "ast.h"

typedef struct stack {
	stmt_t* stmt;
	struct stack* next;
} stack_t;

// Stack mgmt
void push(stack_t*,stmt_t*);
stmt_t* pop_stmt(stack_t*);// Does not update the stack!


// Execution
void execute_ast(var_t*, proc_t*);
void execute_one_step(var_t*, val_t*, stmt_t*);
stmt_t* eval_cond(stmt_t*);// Takes the S_COND statement. NULL if no nondition Ok

#endif// __EXECUTER_H_

