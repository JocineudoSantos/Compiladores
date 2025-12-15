%option noyywrap c++

%{
#include <iostream>
#include <string>
#include <fstream>
#include <unordered_set>
using namespace std;

static const char* METAATTRIBUTES[] = {
    "ordered","const","derived","subsets","redefines"
};

static const char* TYPES[] = {
    "number","string","boolean","date","time","datetime"
};

static const char* RESERVEDWORDS[] = {
    "genset","disjoint","complete","general","specifics",
    "where","package","import","functional-complexes","specializes"
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
    "inherence","value","formal","constitution","of"
};

static const char* SPECIALSYMBOLS[] = {
    "{","}","(",")","[","]","..","<>--","--<>","*","@",":","--"
};

// Conjuntos para armazenar ocorrências únicas
unordered_set<string> classes;
unordered_set<string> relations;
unordered_set<string> reserved_words;
unordered_set<string> class_stereotypes;
unordered_set<string> relation_stereotypes;
unordered_set<string> metaattributes;
unordered_set<string> types;

int line_number = 1;
int column_number = 1;

// Atualiza a posição baseada no token e retorna a coluna inicial
int update_position(const char* yytext) {
    int start_column = column_number; // coluna onde o token começa

    for (const char* p = yytext; *p; ++p) {
        if (*p == '\n') {
            line_number++;
            column_number = 1;
        } else {
            column_number++;
        }
    }

    return start_column; // retorna a coluna inicial do token
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
CLASS_NAME     {UPPER}({LETTER}|{DIGIT}|{UNDERLINE}|"-")*
DATATYPE_NAME  {LETTER}*+{DATATYPE}
RELATION_NAME  {LOWER}({LETTER}|{DIGIT}|{UNDERLINE}|"-")*
INSTANCE_NAME  {LETTER}({LETTER}|{DIGIT}|{UNDERLINE})*{DIGIT}+
CARDINALITY    "["{DIGIT}+"]"

%%
{CARDINALITY} {
    int token_column = update_position(yytext);
    cout << "CARDINALITY " << yytext << " " << line_number << " " << token_column  << "\n";
}
{DATATYPE_NAME} {
    int token_column = update_position(yytext);
    cout << "DATATYPE_NAME " << yytext << " " << line_number << " " << token_column << "\n";
}

{RELATION_NAME} {
    int token_column = update_position(yytext);
    if(is_relation(yytext)) {
        cout << "RELATION_STEREOTYPE " << yytext << " " << line_number << " " << token_column << "\n";
        relation_stereotypes.insert(yytext);
    } else if (is_reservedword(yytext)) {
        cout << "RESERVED_WORD " << yytext << " " << line_number << " " << token_column << "\n";
        reserved_words.insert(yytext);
    } else if (is_metaattribute(yytext)) {
        cout << "METAATTRIBUTE " << yytext << " " << line_number << " " << token_column << "\n";
    } else if (is_type(yytext)) {
        cout << "TYPE " << yytext << " " << line_number << " " << token_column << "\n";
    } else if(is_classs(yytext)) {
        cout  << "CLASS_STEREOTYPE " << yytext << " " << line_number << " " << token_column << "\n";
        class_stereotypes.insert(yytext);
    } else {
        cout << "RELATION_NAME " << yytext << " " << line_number << " " << token_column << "\n";
        relations.insert(yytext);
    }
}

{INSTANCE_NAME} {
    int token_column = update_position(yytext);
    cout << "INSTANCE_NAME " << yytext << " " << line_number << " " << token_column << "\n";
}

{CLASS_NAME} {
    int token_column = update_position(yytext);
    cout << "CLASS_NAME " << yytext << " " << line_number << " " << token_column << "\n";
    classes.insert(yytext);
}

{NUMBER} {
    int token_column = update_position(yytext);
    cout << "NUMBER " << yytext << " " << line_number << " " << token_column << "\n"; 
}

{STRING} {
    int token_column = update_position(yytext);
    cout << "STRING " << yytext << " " << line_number << " " << token_column << "\n";
}

"{"|"}"|"("|")"|"["|"]"|".."|"<>--"|"--<>"|"*"|"@"|":"|"--"|"," {
    int token_column = update_position(yytext);
    cout << "SPECIAL_SYMBOL " << yytext << " " << line_number << " " << token_column << "\n";  
}
"//".* { 
    // Ignora comentários de linha
    update_position(yytext); // se você quiser atualizar posição
}

{ID} {
    int token_column = update_position(yytext);
    cout << "INDENTIFIER " << yytext << " " << line_number << " " << token_column << "\n";
}

[ \t\r]+ {
    update_position(yytext);
    // Ignora espaços em branco
}

\n {
    update_position(yytext);
}

. {
    int token_column = update_position(yytext);
    cout << "UNKNOWN " << yytext << " " << line_number << " " << token_column << "\n";
}

%%

int yywrap() { 
    return 1; 
}