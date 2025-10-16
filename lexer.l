%option noyywrap c++

%{
#include <iostream>
#include <string>
using namespace std;

static const char* METAATTRIBUTES[] = {
    "ordered","const","derived","subsets","redefines"
};

static const char* TYPES[] = {
    "number","string","boolean","date","time","datetime"
};

static const char* RESERVEDWORDS[] = {
    "genset","disjoint","complete","general","specifics",
    "where","package","import","functional-complexes"
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
int column_number = 1;

void update_position(const char* yytext) {
    for (const char* p = yytext; *p; ++p) {
        if (*p == '\n') {
            line_number++;
            column_number = 1;  // Nova linha → reinicia coluna
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
DIGIT    [0-9]
UNDERLINE "_"
STRING          \"([^\\\"]|\\.)*\"
DATATYPE "DataType"

ID [a-zA-Z_][a-zA-Z0-9_]*

NUMBER         {DIGIT}+(\.{DIGIT}+)?
CLASS_NAME     {UPPER}({LETTER}|{DIGIT}|{UNDERLINE})*
DATATYPE_NAME  {LETTER}*+{DATATYPE}
RELATION_NAME  {LOWER}({LETTER}|{DIGIT}|{UNDERLINE})*
INSTANCE_NAME  {LETTER}({LETTER}|{DIGIT}|{UNDERLINE})*{DIGIT}+


%%



{DATATYPE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: DATATYPE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras
}

{INSTANCE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type INSTANCE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras
}

{RELATION_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: RELATION_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras
}

{CLASS_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: CLASS_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras    
}

{NUMBER} {
    update_position(yytext);
    cout << "{ \n" << " type: NUMBER\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras    
}

{STRING} {
   update_position(yytext);
    cout << "{ \n" << " type: STRING\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras    
}

"{"|"}"|"(“"|")"|"["|"]"|".."|"<>--"|"--<>"|"*"|"@"|":"|"--" {
    update_position(yytext);
    cout << "{ \n" << " type: SPECIAL_SYMBOL\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;  // Conta como separador de palavras   
}
{ID} {
    update_position(yytext);

    if (is_reservedword(yytext)) {
        cout << "{ \n type: RESERVED_WORD\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if (is_metaattribute(yytext)) {
        cout << "{ \n type: META_ATTRIBUTE\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if (is_type(yytext)) {
        cout << "{ \n type: TYPE\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if (is_classs(yytext)) {
        cout << "{ \n type: CLASS_KEYWORD\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if (is_relation(yytext)) {
        cout << "{ \n type: RELATION_KEYWORD\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else {
        cout << "{ \n type: IDENTIFIER\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    }

    column_number++;  // Conta como separador de palavras
}

[ \t\r]+ {
    
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

