#include "printer.h"

int indentation = 0;

void pprint(const char* loc, const char* msg)
{
	// Set up the lines color (no need to \e[0m as the message follows)
	printf("\e[38;5;8m");

	// Indent the text 
	for(int i = 0 ; i < indentation ; i ++) printf(" |");
	
	// Print the message (emphase on the location)
	printf("\e[38;5;202m%s\e[0m: %s\n", loc, msg);
}

void printer_vars(var_t *variable)
{
	char buffer[1024];

	// If there is no variable, abort.
	if(!variable) return;

	// Print the variable at hand
	sprintf(buffer, "%s (%d)", variable->name, variable->value);
	pprint("Variable", buffer);

	// Print the next variable as well.
	printer_vars(variable->next);
}


void printer_expression (expr_t *expr)
{
	// If there is no expression, abort.
	if(!expr) return;

	// There is an expression, wheck the expression type.
	switch(expr->type) {
		case E_OTHER:
			pprint("Variable (expr)", "");
			indentation ++;
			printer_vars(expr->var);
			indentation --;
			break;
		case E_XOR:
			pprint("XOR operator", "(2 expressions below)");
			indentation ++;
			printer_expression(expr->left);
			printer_expression(expr->right);
			indentation --;
			break;
		case E_OR:
			pprint("OR (||) operator", "(2 expressions below)");
			indentation ++;
			printer_expression(expr->left);
			printer_expression(expr->right);
			indentation --;
			break;
		case E_EQUAL:
			pprint("EQUAL (==) operator", "(2 expressions below)");
			indentation ++;
			printer_expression(expr->left);
			printer_expression(expr->right);
			indentation --;
			break;
		case E_ADD:
			pprint("ADD (+) operator", "(2 expressions below)");
			indentation ++;
			printer_expression(expr->left);
			printer_expression(expr->right);
			indentation --;
			break;
		case E_AND:
			pprint("AND (&&) operator", "(2 expressions below)");
			indentation ++;
			printer_expression(expr->left);
			printer_expression(expr->right);
			indentation --;
			break;
		case E_NOT:
			pprint("NOT (!) operator", "(see expression below)");
			indentation ++;
			printer_expression(expr->left);
			indentation --;
			break;
		case E_TRUE:
			pprint("TRUE", "This is a hell of an expression");
			break;
		case E_FALSE:
			pprint("FALSE", "This is a hell of an expression");
			break;
		case E_CST:
			char buffer[1024];
			sprintf(buffer, "value: %d", (int)(long)expr->var);
			pprint("CST", buffer);
			break;
		default:
			pprint("_", "This is not a correct expression.");
			break;
	}
}


void printer_statement(stmt_t *stmt)
{
	// If there is no statement, abort.
	if(!stmt) return;

	// Check the statement type
	switch(stmt->type) {
		case S_SKIP:
			pprint("Statement", "skip: Nothing to do.");
			break;
		case S_COND:
			if(stmt->expr && stmt->expr) {
				// :: expr -> left
				pprint("Condition", ":: expr -> statement");
				indentation ++;
				printer_expression(stmt->expr);
				printer_statement(stmt->left);
				indentation --;
			}
			else if (stmt->left && stmt->right) {
				printer_statement(stmt->left);
				printer_statement(stmt->right);
			}
			break;
		case S_ASSIGN:
			// var <- expr
			pprint("Assignment", "variable <- expression:");
			indentation ++;
			printer_vars(stmt->var);
			printer_expression(stmt->expr);
			indentation --;
			break;
		case S_PRINT:
			// Print varlist
			varlist_t *l = stmt->list;
			while(l) {
				printer_vars (l->var);
				l = l->next;
			}
			break;
		case S_IF:
			pprint("IF statement", "see below.");
			indentation++;
			printer_statement(stmt->left);
			indentation--;
			break;
		case S_DO:
			pprint("DO statement", "see below.");
			indentation++;
			printer_statement(stmt->left);
			indentation--;
			break;
		case S_PROC_ENDED:
			pprint("Proc", "End of the proc.");
			break;
	}
}

void printer_proc(proc_t *proc)
{
	// If threr is no proc (invalid pointer), abort.
	if(!proc) return;

	// Action according to the proc type.
	pprint("Proc", proc->name);
	indentation ++;
	printer_vars(proc->var);
	printer_statement(proc->statement);
	indentation --;

	// Print the next proc available
	printer_proc(proc->next);
}

void print_ast(proc_t *ast)
{
	if(!ast) {
		debug("printer_ast", "the AST is empty", "");
		return;
	}

	printf("Printing the AST:\n");
	// Global variables:
	// TODO!

	// Proint the first proc (the function will take care of the next procs as
	// well):
	printer_proc(ast);
}
