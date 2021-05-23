#include "executer.h"

void execute_ast(var_t* vars, proc_t* proc)
{
	// First of all, convert the AST tree into a forest:
	// Each proc is a new tree of the forest, and the proc structure is
	// linearized. Each statement contains the information about the next
	// statement to be executed.
	// The proc structure must provide information about whata last statement
	// has been executed.
	//ast_to_et(proc);
}
