%option noyywrap c++

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
    "{","}","(“",")","[","]","..","<>--","--<>","*","@",":","--"
};

int line_number = 1;
int column_number = 0;

void update_position(const char* yytext) {
    column_number++;
    for (const char* p = yytext; *p; ++p) {
        if (*p == '\n') {
            line_number++;
            column_number = 1;
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

UPPER  [A-Z]
LOWER  [a-z]
LETTER [a-zA-Z]
NUMBER [0-9]
UNDERLINE "_"

ID [a-zA-Z_][a-zA-Z0-9_]*
CLASS_NAME    {UPPER}({LETTER}|{NUMBER}|{UNDERLINE})*
DATATYPE_NAME {LETTER}+"DataType"
RELATION_NAME {LOWER}({LETTER}|{NUMBER}|{UNDERLINE})*
INSTANCE_NAME {LETTER}({LETTER}|{NUMBER}|{UNDERLINE})*{NUMBER}+


%%

{DATATYPE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: DATATYPE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
}

{INSTANCE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type INSTANCE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
}

{RELATION_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: RELATION_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
}

{CLASS_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: CLASS_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
}


{ID} {
    update_position(yytext);
    cout << "{ \n" << " type: ID\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
}

[ \t\r]+ {
    update_position(yytext);
}

\n {
    update_position(yytext);
}

. {
    update_position(yytext);
    cout << "{ \n" << " type: UNKNOWN\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
}




%%

int yywrap() { return 1; }

