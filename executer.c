#include "executer.h"

int evalExpr(var_t* var, expr_t* expr)
{
	// TODO!
	return 0;
}

void execute_step(var_t* vars, stmt_t* stmt, stack_t** stack)
{
	if (!stmt) return;
	switch(stmt->type) {
		case S_SKIP:
		// Do nothing.
			break;
		case S_COND:
			///
			break;
		case S_ASSIGN:
			stmt->var->value = evalExpr(vars, stmt->expr);
			break;
		case S_PRINT:
			///
			break;
		case S_IF:
			///
			break;
		case S_DO:
			///
			break;
		case S_PROC_ENDED:
			exit(0);
			break;
		case S_JUXT:
			push(*stack, stmt->right);
			execute_step(vars, stmt->left, stack);
			break;
		default:
			printf("\n\n!!!ERROR: *********************************");
			break;
	}
}

void execute_proc (var_t* program_vars, proc_t* proc)
{
	stmt_t *stmt;
	stack_t *stack = malloc(sizeof(stack_t));
	push(stack, proc->statement);
	while(!isEmpty(stack)) {
		// Pop an element from the stack and update the stack.
		stmt = pop_stmt(stack);
		stack = stack->next;

		// The execution might add elements to the stack, hence the &stack.
		execute_step(program_vars, stmt, &stack);
	}
}

void execute_ast(var_t* vars, proc_t* proc)
{
	proc_t* current_proc = proc;
	int nb_procs = 0;
	// First of all, one must split the AST to get every procs on line.
	while(current_proc) {
		nb_procs ++;
		current_proc = current_proc->next;
	}

	pid_t* pids = malloc (nb_procs * sizeof(pid_t));
	current_proc = proc;
	int i = 0;
	while(current_proc) {
		i ++;
		if((pids[i] = fork())) {
			execute_proc(vars, current_proc);
		}
		current_proc = current_proc->next;
	}

	printf("Waiting for the procs to be complete:\n");
	for(i = 0 ; i < nb_procs ; i ++) {
		waitpid(pids[i], NULL, 0);
		printf("\tproc %d over\n", i);
	}
	printf("End of the execution.\n\n");
}
