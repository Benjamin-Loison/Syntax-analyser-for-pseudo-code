%option noyywrap

DIG	[0-9]

%%

"var"	{ printf("Scan: var\n"); return VAR; }
"while"	{ printf("Scan while\n");  return WHILE; }
"do"	{ printf("Sacn do\n"); return DO; }
"od"	{ printf("Scan od\n"); return OD; }
"print"	{ printf("Scan print\n"); return PRINT; }
"true"	{ printf("Scan true\n"); return TRUE; }
"false"	{ printf("Scan false\n"); return FALSE; }
"if"	{ printf("Scan if\n"); return IF; }
"::"	{ printf("Scan ::\n"); return CASE; }
"->"	{ printf("Scan ->\n"); return TO; }
"fi"	{ printf("Scan fi\n"); return FI; }

":="	{ printf("Scan :=\n"); return ASSIGN; }
"^"	{ printf("Scan '^'\n"); return XOR; }
"||"	{ printf("Scan ||\n"); return OR; }
"=="	{ printf("Scan ==\n"); return EQUAL; }
"+"   { printf("Scan +\n"); return ADD; }
"&&"	{ printf("Scan &&\n");  return AND; }
"!"	{ return NOT; }

[a-z_][a-z0-9_]* { yylval.i = strdup(yytext); return IDENT; }
[0-9]* { yylval.i = atoi(yytext); return CST; }

[	 \n]   { /* ignore */ }
"//"[^\n]*$ ; // https://stackoverflow.com/a/23235232

.	{ return *yytext; }

%%
