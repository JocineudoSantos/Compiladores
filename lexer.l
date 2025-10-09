%option noyywrap c++
%option case-insensitive

%{
#include <iostream>
#include <string>
using namespace std;

static const char* CLASS[] = {
    "event","situation","process","category","mixin",
    "phaseMixin","roleMixin","historicalRoleMixin","kind","collective",
    "quantity","quality","mode","intrisicMode","extrinsicMode","subkind",
    "phase","role","historicalRole"
};

static const char* RELATION[] = {
"material","derivation","comparative","mediation",
"characterization", "externalDependence", "componentOf", "memberOf",
"subCollectionOf", "subQualityOf", "instantiation", "termination",
"participational", "participation", "historicalDependence", "creation",
"manifestation", "bringsAbout", "triggers", "composition", "aggregation",
"inherence", "value", "formal", "constitution"
};

static const char* SPECIALSYMBOLS[] = {
    "{","}","(“",")","[","]","..","<>--","--<>","*","@",":"
};

int line_number = 1;
int column_number = 1;

void update_position(const char* yytext) {
    for (const char* p = yytext; *p; ++p) {
        if (*p == '\n') {
            line_number++;
            column_number = 1;
        } else {
            column_number++;
        }
    }
}

bool is_special_symbol(const char* text) {
    for (const char* sym : SPECIALSYMBOLS) {
        if (strcmp(text, sym) == 0) {
            return true;
        }
    }
    return false;
}

bool is_classs(const char* text) {
    for (const char* cls : CLASS) {
        if (strcasecmp(text, cls) == 0) {
            return true;
        }
    }
    return false;
}

bool is_relation(const char* text) {
    for (const char* rel : RELATION) {
        if (strcasecmp(text, rel) == 0) {
            return true;
        }
    }
    return false;
}

%}

DIGIT [0-9]
ID [a-zA-Z_][a-zA-Z0-9_]*
STRING \"(\\.|[^\"])*\"
COMMENT "//".*|"/\*"(.\n|[^*])*\*+"/"


%%
{ID} {
    update_position(yytext);
    if (is_classs(yytext)) {
        cout << "CLASS(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else if (is_relation(yytext)) {
        cout << "RELATION(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else {
        cout << "ID(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    }
} 
%%

int yywrap() { return 1; }

