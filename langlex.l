%option noyywrap

DIG	[0-9]

%%

"var"	{ return VAR; }
"do"	{ return DO; }
"od"	{ return OD; }
"print"	{ return PRINT; }
"true"	{ return TRUE; }
"false"	{ return FALSE; }
"else"	{ return ELSE; }
"if"	{ return IF; }
"fi"	{ return FI; }
"::"	{ return COND_BEGIN; }
"->"	{ return COND_END; }
"skip"	{ return SKIP; }
"break"	{ return BREAK; }

":="	{ return ASSIGN; }
"^"		{ return XOR; }
"||"	{ return OR; }
"=="	{ return EQUAL; }
"+"		{ return ADD; }
"-"		{ return SUB; }
"*"		{ return MUL; }
"/"		{ return DIV; }
"%"		{ return MOD; }
"&&"	{ return AND; }
">"		{ return GNEQ; }
"!"		{ return NOT; }

"proc "[a-z][a-z0-9]* { yylval.i = yytext; return PROC_BEGIN; }
"end" { return PROC_END; }
[a-z_][a-z0-9_]* { yylval.i = strdup(yytext); return IDENT; }
[0-9]* { yylval.n = atoi(yytext); return CST; }


[	 \n]   { /* ignore */ }
"//"[^\n]*$ ; // https://stackoverflow.com/a/23235232
"reach"[^\n]*$ ;

.	{ return *yytext; }

%%

