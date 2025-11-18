/* ============================================================
   parser.y — Arquivo inicial para analisador sintático (Bison)
   Integrado com Flex (lexer.l), usando C++
   ============================================================ */

%language "c++"
%define api.value.type {std::string}
%define api.pure full
%define api.token.constructor
%define api.lex { yylex() }

%code requires {
    #include <string>
    #include <iostream>
    using namespace std;

    // Flex fornece esta função
    extern int yylex();
    void yyerror(const char* msg);
}

%code {
    // para integração com o lexer
    extern int line_number;
    extern int column_number;

    // para o relatório final
    extern void finalize_lexer(const std::string& filename);
}

/* -------- Tokens do arquivo lexer -------- */
%token CLASS_NAME
%token RELATION_NAME
%token RELATION_STEREOTYPE
%token CLASS_STEREOTYPE
%token INSTANCE_NAME
%token RESERVED_WORD
%token METAATTRIBUTE
%token TYPE
%token STRING
%token NUMBER
%token DATATYPE_NAME
%token CARDINALITY
%token SPECIAL_SYMBOL
%token INDENTIFIER   /* sim, tem typo no seu lexer, deixei igual */

%token '{' '}' '(' ')' '[' ']' '*' '@' ':'


/* -------- Começo da gramática -------- */
%start program

%%

program:
      elements
    | /* vazio */
    ;

elements:
      elements element
    | element
    ;

element:
      CLASS_NAME
    | RELATION_NAME
    | INSTANCE_NAME
    | NUMBER
    | STRING
    | DATATYPE_NAME
    | CARDINALITY
    | METAATTRIBUTE
    | TYPE
    | RESERVED_WORD
    | CLASS_STEREOTYPE
    | RELATION_STEREOTYPE
    | INDENTIFIER
    | SPECIAL_SYMBOL
    | '{'
    | '}'
    | '('
    | ')'
    | '['
    | ']'
    | '*'
    | '@'
    | ':'
    ;

%%

/* -------- Funções auxiliares -------- */

void yyerror(const char* msg) {
    cerr << "[ERRO SINTÁTICO] " << msg
         << " na linha " << line_number
         << ", coluna " << column_number << endl;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        cerr << "Uso: ./parser <arquivo>" << endl;
        return 1;
    }

    /* Abrir arquivo de entrada */
    FILE* file = fopen(argv[1], "r");
    if (!file) {
        cerr << "Erro ao abrir arquivo: " << argv[1] << endl;
        return 1;
    }
    yyin = file;

    cout << "=== Iniciando análise sintática ===\n\n";

    int result = yyparse();

    cout << "\n=== Fim da análise sintática ===\n";

    fclose(file);

    /* Chama o relatório gerado pelo lexer */
    finalize_lexer(argv[1]);

    return result;
}
