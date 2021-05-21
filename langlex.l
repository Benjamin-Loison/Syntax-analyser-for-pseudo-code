%option noyywrap

DIG	[0-9]

%%

"var"	{ debug("var\n"); return VAR; }
"while"	{ debug("while\n"); return WHILE; }
"do"	{ debug("do\n"); return DO; }
"od"	{ debug("od\n"); return OD; }
"print"	{ debug("print\n"); return PRINT; }
"true"	{ debug("true\n"); return TRUE; }
"false"	{ debug("false\n"); return FALSE; }
"if"	{ debug("if\n"); return IF; }
"then"	{ debug("then\n"); return THEN; }
"else"	{ debug("else\n"); return ELSE; }
"fi"	{ debug("fi\n"); return FI; }

":="	{ debug(":=\n"); return ASSIGN; }
"^"	{ debug("^\n"); return XOR; }
"||"	{ debug("||\n"); return OR; }
"=="	{ debug("==\n"); return EQUAL; }
"+"   { debug("+\n"); return ADD; }
"&&"	{ debug("&&\n"); return AND; }
"!"	{ debug("!\n"); return NOT; }

"proc "[a-z][a-z0-9]* { debug("proc\n"); return PROC_BEGIN; }
"end" { debug("end\n"); return PROC_END; }
[a-z_][a-z0-9_]* { debug("ident\n"); yylval.i = strdup(yytext); return IDENT; }
[0-9]* { debug("cst\n"); yylval.i = atoi(yytext); return CST; }


[	 \n]   { /* ignore */ }
"//"[^\n]*$ ; // https://stackoverflow.com/a/23235232

.	{ return *yytext; }

%%

