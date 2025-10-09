%option noyywrap c++
%option case-insensitive

%{
#include <iostream>
#include <string>
using namespace std;

static const char* METAATTRIBUTES[] = {
    "ordered","const","derived","subsets","redefines"
};

static const char* TYPES[] = {
    "number", "string","boolean","date","time","datetime"
};

static const char* RESERVEDWORDS[] {
    "genset","disjoint","complete","general","specifics",
    "where","package"
};

static const char* CLASS[] = {
    "event","situation","process","category","mixin",
    "phaseMixin","roleMixin","historicalRoleMixin","kind","collective",
    "quantity","quality","mode","intrisicMode","extrinsicMode","subkind",
    "phase","role","historicalRole"
};

static const char* RELATION[] = {
    "material","derivation","comparative","mediation",
    "characterization","externalDependence","componentOf","memberOf",
    "subCollectionOf","subQualityOf","instantiation","termination",
    "participational","participation","historicalDependence", "creation",
    "manifestation","bringsAbout","triggers","composition","aggregation",
    "inherence","value","formal","constitution"
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

bool is_metaattribute(const char* text) {
    for (const char* attr : METAATTRIBUTES) {
        if (strcasecmp(text, attr) == 0) {
            return true;
        }
    }
    return false;
}

bool is_type(const char* text) {
    for (const char* type : TYPES) {
        if (strcasecmp(text, type) == 0) {
            return true;
        }
    }
    return false;
}

bool is_reservedword(const char* text) {
    for (const char* word : RESERVEDWORDS) {
        if (strcasecmp(text, word) == 0) {
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


bool is_special_symbol(const char* text) {
    for (const char* sym : SPECIALSYMBOLS) {
        if (strcmp(text, sym) == 0) {
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
    if (is_metaattribute(yytext)) {
        cout << "METAATTRIBUTE(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else if (is_type(yytext)) {
        cout << "TYPE(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else if (is_reservedword(yytext)) {
        cout << "RESERVEDWORD(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else if (is_classs(yytext)) {
        cout << "CLASS(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else if (is_relation(yytext)) {
        cout << "RELATION(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else {
        cout << "IDENTIFIER(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    }
} 
{DIGIT}+ {
    update_position(yytext);
    cout << "NUMBER(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
}
{STRING} {
    update_position(yytext);
    cout << "STRING(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
}
{COMMENT} {
    update_position(yytext); // IGNORA COMENTÁRIOS
}
[ \t\r]+ {
    update_position(yytext); // IGNORA ESPAÇOS EM BRANCO
}
\n {
    update_position(yytext);
}
. {
    update_position(yytext);
    if (is_special_symbol(yytext)) {
        cout << "SPECIAL(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    } else {
        cout << "UNKNOWN(" << yytext << ") at line " << line_number << ", column " << column_number - yyleng << endl;
    }
}
%%

int yywrap() { return 1; }

