%option noyywrap

DIG	[0-9]

%%

"var"	{ return VAR; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"od"	{ return OD; }
"print"	{ return PRINT; }
"true"	{ return TRUE; }
"false"	{ return FALSE; }
"if"	{ return IF; }
"then"	{ return THEN; }
"else"	{ return ELSE; }
"fi"	{ return FI; }

":="	{ return ASSIGN; }
"^"	{ return XOR; }
"||"	{ return OR; }
"=="	{ return EQUAL; }
"&&"	{ return AND; }
"!"	{ return NOT; }

[a-z_][a-z0-9_]* { yylval.i = strdup(yytext); return IDENT; }

[	 \n]   { /* ignore */ }

.	{ return *yytext; }

%%
