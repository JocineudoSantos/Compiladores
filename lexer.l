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
    "inherence","value","formal","constitution"
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

void update_position(const char* yytext) {
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

// Função para escrever o relatório no arquivo - será chamada no final
void write_report(const string& filename) {
    string report_filename = filename + "_contagem.txt";
    ofstream file(report_filename);
    if (!file.is_open()) {
        cerr << "Erro ao criar arquivo de relatório!" << endl;
        return;
    }
    
    file << "=== RELATÓRIO DE CONTAGEM ÚNICA ===\n\n";
    
    file << "CLASSES: " << classes.size() << "\n";
    for (const auto& cls : classes) {
        file << "  - " << cls << "\n";
    }
    file << "\n";
    
    file << "RELAÇÕES: " << relations.size() << "\n";
    for (const auto& rel : relations) {
        file << "  - " << rel << "\n";
    }
    file << "\n";
    
    file << "PALAVRAS RESERVADAS: " << reserved_words.size() << "\n";
    for (const auto& word : reserved_words) {
        file << "  - " << word << "\n";
    }
    file << "\n";
    
    file << "CLASSES ESTEREÓTIPOS: " << class_stereotypes.size() << "\n";
    for (const auto& stereo : class_stereotypes) {
        file << "  - " << stereo << "\n";
    }
    file << "\n";
    
    file << "RELAÇÕES ESTEREÓTIPOS: " << relation_stereotypes.size() << "\n";
    for (const auto& rel_stereo : relation_stereotypes) {
        file << "  - " << rel_stereo << "\n";
    }
    file << "\n";

    int total = classes.size() + relations.size() + reserved_words.size() + 
                class_stereotypes.size() + relation_stereotypes.size() + 
                metaattributes.size() + types.size();
    
    file << "=== TOTAL GERAL: " << total << " elementos únicos ===\n";
    
    file.close();
    cout << "Relatório de contagem gerado em: " << report_filename << endl;
}

// Função para obter contagens (para uso externo se necessário)
extern "C" {
    void get_counts(int* class_count, int* relation_count, int* reserved_count, 
                   int* class_stereo_count, int* relation_stereo_count) {
        *class_count = classes.size();
        *relation_count = relations.size();
        *reserved_count = reserved_words.size();
        *class_stereo_count = class_stereotypes.size();
        *relation_stereo_count = relation_stereotypes.size();
    }
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
CARDINALITY    "["{DIGIT}+"]"

%%
{CARDINALITY} {
    update_position(yytext);
    cout << "{ \n" << " type: CARDINALITY\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;
}
{DATATYPE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: DATATYPE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;
}

{RELATION_NAME} {
    update_position(yytext);
    if(is_relation(yytext)) {
        cout << "{ \n" << " type: RELATION_STEREOTYPE\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
        relation_stereotypes.insert(yytext);
    } else if (is_reservedword(yytext)) {
        cout << "{ \n" << " type: RESERVEDWORD\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
        reserved_words.insert(yytext);
    } else if (is_metaattribute(yytext)) {
        cout << "{ \n" << " type: METAATTRIBUTE\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if (is_type(yytext)) {
        cout << "{ \n" << " type: TYPE\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    } else if(is_classs(yytext)) {
        cout << "{ \n" << " type: CLASS_STEREOTYPE\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
        class_stereotypes.insert(yytext);
    } else {
        cout << "{ \n" << " type: RELATION_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
        relations.insert(yytext);
    }
    column_number++;
}

{INSTANCE_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: INSTANCE_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;
}

{CLASS_NAME} {
    update_position(yytext);
    cout << "{ \n" << " type: CLASS_NAME\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    classes.insert(yytext);

    column_number++;    
}

{NUMBER} {
    update_position(yytext);
    cout << "{ \n" << " type: NUMBER\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;    
}

{STRING} {
   update_position(yytext);
    cout << "{ \n" << " type: STRING\n lexema: \"" << yytext << "\"\n linha:  " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;    
}

"{"|"}"|"("|")"|"["|"]"|".."|"<>--"|"--<>"|"*"|"@"|":"|"--" {
    update_position(yytext);
    cout << "{ \n" << " type: SPECIAL_SYMBOL\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;   
}

{ID} {
    update_position(yytext);
    cout << "{ \n type: INDENTIFIER\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
    column_number++;
}

[ \t\r]+ {
    // Ignora espaços em branco
}

\n {
    update_position(yytext);
}

. {
    update_position(yytext);
    cout << "{ \n" << " type: UNKNOWN\n lexema: \"" << yytext << "\"\n linha: " << line_number << "\n coluna: " << column_number << "\n}\n";
}

%%

// Função para ser chamada da main após a análise
void finalize_lexer(const string& filename) {
    write_report(filename);
}

int yywrap() { 
    return 1; 
}