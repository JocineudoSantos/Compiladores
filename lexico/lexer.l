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

// Função para ser chamada da main após a análise
void finalize_lexer(const string& filename) {
    write_report(filename);
}

int yywrap() { 
    return 1; 
}