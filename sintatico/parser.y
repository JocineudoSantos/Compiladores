{
/* ========================================================================== */
/* INCLUDES DO SISTEMA                                                        */
/* ========================================================================== */

// Bibliotecas padrão C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstring>   // strcmp, strdup
#include <cstdlib>   // strdup no GCC/Clang

// Bibliotecas padrão C++
#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <fstream>

using namespace std;

/* ========================================================================== */
/* DEFINIÇÕES DE CORES PARA TERMINAL                                          */
/* ========================================================================== */

#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_RESET   "\x1b[0m"

/* ESTRUTURAS DE DADOS PRINCIPAIS */

// Informações de Enumeração
struct EnumInformacoes {
    string nome;
    vector<string> literals;  // Valores do Enum
};

// Informações de Relação Interna (dentro de classes)
struct RelacoesInternas {
    string nome;
    string estereotipo;
    string sourceCardinality;
    string targetCardinality;
    string targetClass;
};

// Informações de Relação Geral
struct RelationInfomacoes {
    string estereotipo;
    string tipo; 
    string detalhes; 
};

// Informações de Classe
struct ClassesInformacoes {
    string nome;
    string estereotipo;
    vector<string> parents;
    vector<string> attributes;
    vector<RelacoesInternas> internalRelations;
};

// Informações de Conjunto de Generalização
struct GensetInfo {
    string nome;
    string general;
    vector<string> specifics;
};

// Informações de Pacote (container principal)
struct PacoteInformacoes {
    string nome;
    vector<ClassesInformacoes> classes;
    vector<GensetInfo> gensets;
    vector<EnumInformacoes> enums;
    vector<RelationInfomacoes> externalRelations;
};

// Informações de Tipo de Dado
struct DatatypeInformacoes {
    string nome;
    string baseType; 
};

// Informações de Erro para Relatório
struct Erro {
    int line;
    int col;
    string message;
    string suggestion;
};

/* ========================================================================== */
/* VARIÁVEIS GLOBAIS - CONTROLE DE EXECUÇÃO                                   */
/* ========================================================================== */    

// Ponteiros de contexto atual
PacoteInformacoes* pacoteAtual = nullptr;    // Pacote sendo processado
ClassesInformacoes* currentClass = nullptr;     // Classe sendo processada

// Sistema de arquivos e relatórios
ofstream reportFile;                   // Arquivo de relatório de saída
extern FILE *tokenFile;                // Arquivo de tokens (externo)
extern std::string currentFileName;    // Nome do arquivo atual

/* ========================================================================== */
/* VARIÁVEIS GLOBAIS - ANÁLISE LÉXICA                                         */
/* ========================================================================== */

// Estado do analisador léxico
char typeStr[50];                      // Tipo do token atual
char lexeme[100];                      // Lexema do token atual  
int lineNumber;                        // Número da linha atual
int columnNumber;                      // Número da coluna atual

/* ========================================================================== */
/* VARIÁVEIS GLOBAIS - REPOSITÓRIOS DE DADOS                                  */
/* ========================================================================== */

// Estruturas principais de armazenamento
vector<PacoteInformacoes> pacotes;           // Todos os pacotes processados
vector<RelationInfomacoes> externalRelations; // Relações externas identificadas
vector<DatatypeInformacoes> datatypes;        // Tipos de dados definidos
vector<EnumInformacoes> enums;                // Enumerações mapeadas

// Buffers temporários para construção
vector<string> tempSpecifics;          // Lista temporária de específicos
vector<string> tempEnumLiterals;       // Lista temporária de literais enum

// Sistema de registro de erros
vector<Erro> errorLog;            // Log central de erros

/* ========================================================================== */
/* VARIÁVEIS GLOBAIS - TABELAS DE SÍMBOLOS                                    */
/* ========================================================================== */

// Mapas para reconhecimento de tokens
unordered_map<string, int> mapRelationestereotipos;  // Estereótipos de relação
unordered_map<string, int> mapDatatypes;            // Tipos de dados nativos
unordered_map<string, int> mapReservedWords;        // Palavras reservadas
unordered_map<string, int> mapClassestereotipos;     // Estereótipos de classe

/* ========================================================================== */
/* PROTÓTIPOS DE FUNÇÕES                                                      */
/* ========================================================================== */

// Funções do analisador sintático (Bison)
int yylex(void);                       // Analisador léxico
void yyerror(const char *s);           // Tratamento de erros sintáticos

// Funções do sistema
void init_maps();                      // Inicializa tabelas de símbolos
void printSynthesisReport();           // Gera relatório de síntese
void printErrorReport();               // Gera relatório de erros
%}
%define parse.error verbose
%union {
    char *sval;
}

/* ========================================================================== */
/* TOKENS                                                                     */
/* ========================================================================== */

/* Tokens sem valor */
%token HAS SPECIALIZES OF WHERE FUNCTIONAL_COMPLEXES PACKAGE SPECIFICS GENERAL COMPLETE DISJOINT GENSET IMPORT
%token DATATYPE RELATION ENUM

/* Tokens COM valor */
%token <sval> REL_STEREO NUM NATIVE_TYPE MATERIAL ID CLASS_STEREO CARDINALITY

/* Símbolos especiais - POR type */
%token LBRACE RBRACE LBRACKET RBRACKET COLON DOT COMMA     /* Chaves e colchetes */
%token ARROW_ASSOC ARROW_AGG ARROW_COMP ARROW_AGG_EXISTENTIAL  /* Setas */

/* types de não-terminais */
%type <sval> cardinalidade_opt opt_rel_stereo operador_relacao tipo_referencia opt_material pacote_cabecalho corpo_relacao_externa

/* Precedências */
%nonassoc EMPTY_CARD
%nonassoc CARDINALITY
%left ARROW_ASSOC ARROW_AGG ARROW_COMP

%%

programa:
    lista_imports lista_pacotes
    ;

lista_imports:
    /* vazio */
    | lista_imports IMPORT ID
    | lista_imports error ID { yyerrok; } /* Ponto de recuperação por elemento */
    ;

lista_pacotes:
    pacote
    | lista_pacotes pacote
    ;
    
pacote:
    pacote_cabecalho
    {
        PacoteInformacoes
        novoPacote;
        novoPacote.nome = string($1);
        pacotes.push_back(novoPacote);
        pacoteAtual = &pacotes.back();
    }
    opt_brace_block
    {
        pacoteAtual = nullptr;
    }
    ;

opt_brace_block:
    LBRACE conteudo_pacote RBRACE
    | conteudo_pacote
    ;

conteudo_pacote:
    | conteudo_pacote declaracao
    | conteudo_pacote error { yyerrok; } /* Ponto de recuperação por elemento */
    ;

pacote_cabecalho:
    PACKAGE ID { $$ = $2; }
    | PACKAGE error { yyerrok; } /* Ponto de recuperação por elemento */
    {
        yyerrok; 
        $$ = NULL; 
    }
    ;

declaracao:
    classe_decl
    | datatype_decl
    | enum_decl
    | genset_decl
    | relacao_esterna_decl
    | class_subkind_decl
    ;

classe_decl:

datatype_decl:

enum_decl:

genset_decl:

relacao_esterna_decl:

class_subkind_decl:
