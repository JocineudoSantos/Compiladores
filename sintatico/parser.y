%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <fstream>

using namespace std;

/* ========================================================================== */
/* ESTRUTURAS DE DADOS                                                        */
/* ========================================================================== */

struct EnumInformacoes {
    string name;
    vector<string> literals;
};

struct InternalRelationInformacoes {
    string stereotype;
    string name;
    string sourceCardinality;
    string targetCardinality;
    string targetClass;
};

struct RelationInformacoes {
    string stereotype;
    string type; 
    string details; 
};

struct ClassInfo {
    string name;
    string stereotype;
    vector<string> parents;
    vector<string> attributes;
    vector<InternalRelationInformacoes> internalRelations;
};

struct GensetInfo {
    string name;
    string general;
    vector<string> specifics;
};

struct PacoteInformacoes {
    string name;
    vector<ClassInfo> classes;
    vector<GensetInfo> gensets;
    vector<EnumInformacoes> enums;
    vector<RelationInformacoes> relacoesExternas;
};

struct DatatypeInformacoes {
    string name;
    string baseType; 
};

struct ErrorInfo {
    int line;
    int col;
    string mensagem;
    string sugestao;
};

// Ponteiros atuais
PacoteInformacoes* pacoteAtual = nullptr;
ClassInfo* classeAtual = nullptr;

// Funções auxiliares
int yylex(void);
void yyerror(const char *s);
void mapa();
void imprimirRelatorio();
void imprimirErro();


// Estruturas principais
vector<PacoteInformacoes> pacotes;
vector<RelationInformacoes> relacoesExternas;
vector<DatatypeInformacoes> Datatypes;
vector<EnumInformacoes> enums;

// Variáveis temporárias
vector<string> tempIdentifier;
vector<string> tempEnum;

// Log de erros
vector<ErrorInfo> errorLog;

// Mapas de consulta rápida
unordered_map<string, int> relationStereotypes;
unordered_map<string, int> reservedDatatypes;
unordered_map<string, int> reservedWords;
unordered_map<string, int> classStereotype;

// Variáveis de controle
char type[100], lexeme[100];
int lineNumber = 0, columnNumber = 0;

// Arquivos e fluxos de entrada/saída
ofstream relatorioFile;
extern FILE *tokenFile;
extern string currentFileName;

/* Funções auxiliares */
void adicionarAtributo(ClassInfo* classes, const string& nome, const string& tipo) {
    if(classes) classes->attributes.push_back(nome + " : " + tipo);
}
void adicionarParente(ClassInfo* classes, const string& pai) {
    if(classes) classes->parents.push_back(pai);
}
string joinOptional(char* s) {
    return s ? string(s) : "";
}

%}

%define parse.error verbose

%union {
    char *strval;
}

%token DISJOINT SPECIALIZES IMPORT COMPLETE FUNCTIONAL_COMPLEXES PACKAGE 
    WHERE GENSET OF SPECIFICS LBRACE RBRACE LBRACKET RBRACKET COLON DOT COMMA
    ARROW_COMPOSITION ARROW_ASSOCIATION ARROW_AGGREGATION
    ARROW_AGGREGATION_EXISTENTIAL RELATION ENUM DATATYPE GENERAL

%token <strval> HAS NATIVE_TYPE CLASS_STEREOTYPE MATERIAL RELATION_STEREOTYPE NUM ID CARDINALITY

%type <strval> operador_relacao optional_id pacote_cabecalho cardinalidade_optional
    optional_relacao_stereotype campo tipo_referencia optional_material
    corpo_relacao_externa

%nonassoc CARDINALITY EMPTY

%left ARROW_COMPOSITION ARROW_ASSOCIATION ARROW_AGGREGATION

%%

programa:
    lista_de_imports lista_de_pacotes
    ;

lista_de_imports:
    | lista_de_imports IMPORT ID
    | lista_de_imports error ID { yyerrok; yyclearin; } 
    ;

lista_de_pacotes:
      pacote
    | lista_de_pacotes pacote
    ;

pacote:
    pacote_cabecalho optional_brace_block
    {
        // pacoteAtual já foi atualizado antes do bloco
        pacoteAtual = nullptr; // reset após terminar
    }
    ;

pacote_cabecalho:
    PACKAGE ID
    {
        PacoteInformacoes novoPacote;
        novoPacote.name = std::string($2);
        pacotes.push_back(novoPacote);

        // Atualiza ponteiro antes de processar o bloco
        pacoteAtual = &pacotes.back();
        $$ = $2;
    }
    | PACKAGE error
    {
        yyerrok;
        PacoteInformacoes novoPacote;
        novoPacote.name = "[semnome_" + std::to_string(lineNumber) + "]";
        pacotes.push_back(novoPacote);
        pacoteAtual = &pacotes.back();
        $$ = nullptr;
    }
    ;

optional_brace_block:
      LBRACE conteudo_pacote RBRACE
    | conteudo_pacote
    ;

conteudo_pacote:
    | conteudo_pacote declaracao
    | conteudo_pacote error { yyerrok; }
    ;

declaracao:
      classe
    | enum
    | datatype
    | relacao_externa
    | genset
    | classe_subkind
    ;

// CLASSES
classe:
    cabecalho_classe optional_especializacao optional_relacoes_sintaxe_lista optional_corpo_classe
    ;

cabecalho_classe:
    CLASS_STEREOTYPE ID
    {
        if(pacoteAtual){
            pacoteAtual->classes.emplace_back();
            ClassInfo &classes = pacoteAtual->classes.back();
            classes.name = string($2);
            classes.stereotype = string($1);
            classeAtual = &classes;
        }
        free($1); free($2);
    }
    ;

optional_especializacao:
    | SPECIALIZES pai
    ;

pai:
    ID { adicionarParente(classeAtual, string($1)); free($1); }
    | pai COMMA ID { adicionarParente(classeAtual, string($3)); free($3); }
    ;

optional_relacoes_sintaxe_lista:
    | relacoes_lista
    ;

relacoes_lista:
      RELATION_STEREOTYPE ID
    | relacoes_lista COMMA ID
    ;

optional_corpo_classe:
    | LBRACE corpo_classe RBRACE
    ;

corpo_classe:
    | lista_membros
    ;

lista_membros:
      membro_classe
    | lista_membros membro_classe
    | lista_membros error { yyerrok; }
    ;

membro_classe:
      atributo
    | relacao_interna
    ;

atributo:
    ID COLON tipo_referencia cardinalidade_optional
    {
        adicionarAtributo(classeAtual, string($1), string($3));
        free($1); free($3);
    }
    ;

tipo_referencia:
      NATIVE_TYPE { $$ = $1; }
    | ID { $$ = $1; }
    ;

// ENUMS
enum:
    ENUM ID LBRACE lista_enum RBRACE
    {
        if(pacoteAtual){
            pacoteAtual->enums.push_back({string($2), tempEnum});
        }
        tempEnum.clear();
        free($2);
    }
    ;

lista_enum:
      ID { tempEnum.push_back(string($1)); free($1); }
    | lista_enum COMMA ID { tempEnum.push_back(string($3)); free($3); }
    ;

// DATATYPES
datatype:
      DATATYPE ID LBRACE lista_atributos RBRACE
    {
        Datatypes.push_back({string($2), "Complexo"});
        free($2);
    }
    | DATATYPE ID
    | DATATYPE NATIVE_TYPE
    ;

lista_atributos:
      atributo
    | lista_atributos atributo
    ;

// RELAÇÕES
relacao_interna:
      optional_relacao_stereotype operador_relacao ID operador_relacao cardinalidade_optional ID
    {
        if(classeAtual)
            classeAtual->internalRelations.push_back({joinOptional($1), string($3), "", joinOptional($5), string($6)});
        free($1); free($3); free($5); free($6);
    }
    | optional_relacao_stereotype CARDINALITY operador_relacao optional_id CARDINALITY ID
    {
        if(classeAtual)
            classeAtual->internalRelations.push_back({joinOptional($1), "", joinOptional($2), joinOptional($5), string($6)});
        free($1); free($2); free($5); free($6);
    }
    ;

optional_id:
    { $$ = nullptr; }
    | campo operador_relacao { $$ = $1; free($2); }
    ;

campo:
      ID { $$ = $1; }
    | HAS { $$ = $1; }
    | RELATION_STEREOTYPE { $$ = $1; }
    ;
    
relacao_externa:
      optional_material RELATION optional_relacao_stereotype corpo_relacao_externa
    {
        if(pacoteAtual)
            pacoteAtual->relacoesExternas.push_back({joinOptional($3), "Externa", string($4)});
        free($3); free($4);
    }
    ;

corpo_relacao_externa:
      ID cardinalidade_optional operador_relacao ID cardinalidade_optional
    {
        $$ = (char*) strdup((string($1) + " " + joinOptional($2) + " " + string($3) + " " + string($4) + " " + joinOptional($5)).c_str());
        free($1); free($2); free($3); free($4); free($5);
    }
    |
      ID cardinalidade_optional operador_relacao CARDINALITY ID
    {
        $$ = (char*) strdup((string($1) + " " + joinOptional($2) + " " + string($3) + " " + string($4) + " " + string($5)).c_str());
        free($1); free($2); free($3); free($4); free($5);
    }
    |
      ID cardinalidade_optional operador_relacao ID operador_relacao cardinalidade_optional ID
    {
        $$ = (char*) strdup((string($1) + " " + joinOptional($2) + " " + string($3) + " " + string($4) + " " + string($5) + " " + joinOptional($6) + " " + string($7)).c_str());
        free($1); free($2); free($3); free($4); free($5); free($6); free($7);
    }
    ;

operador_relacao:
      ARROW_AGGREGATION { $$ = (char*) "<>--"; }
    | ARROW_ASSOCIATION { $$ = (char*) "--"; }
    | ARROW_COMPOSITION { $$ = (char*) "<*>--"; }
    | ARROW_AGGREGATION_EXISTENTIAL { $$ = (char*) "<o>--"; }
    ;

optional_material:
      { $$ = nullptr; }
    | MATERIAL { $$ = $1; }
    ;

optional_relacao_stereotype:
      { $$ = nullptr; }
    | RELATION_STEREOTYPE { $$ = $1; }
    ;

cardinalidade_optional:
      { $$ = nullptr; } %prec EMPTY
    | LBRACKET NUM RBRACKET { $$ = $2; }
    | LBRACKET NUM ARROW_ASSOCIATION NUM RBRACKET { $$ = $2; }
    | LBRACKET NUM DOT DOT NUM RBRACKET { $$ = $2; }
    | CARDINALITY { $$ = $1; }
    ;

// GENSET
genset:
    meta_atributos GENSET ID WHERE GENERAL ID SPECIFICS lista_ids
    {
        if(pacoteAtual)
            pacoteAtual->gensets.push_back({string($3), string($6), tempIdentifier});
        tempIdentifier.clear();
        free($3); free($6);
    }
    | meta_atributos GENSET ID LBRACE GENERAL ID SPECIFICS lista_ids RBRACE
    {
        if(pacoteAtual)
            pacoteAtual->gensets.push_back({string($3), string($6), tempIdentifier});
        tempIdentifier.clear();
        free($3); free($6);
    }
    | GENERAL ID LBRACE meta_atributos SPECIFICS lista_ids RBRACE
    {
        if(pacoteAtual)
            pacoteAtual->gensets.push_back({"Unnamed_Genset", string($2), tempIdentifier});
        tempIdentifier.clear();
        free($2);
    }
    ;

meta_atributos:
    | meta_atributos DISJOINT
    | meta_atributos COMPLETE
    ;

lista_ids:
      ID { tempIdentifier.push_back(string($1)); free($1); }
    | lista_ids COMMA ID { tempIdentifier.push_back(string($3)); free($3); }
    ;

// SUBKIND
classe_subkind:
      cabecalho_classe OF FUNCTIONAL_COMPLEXES SPECIALIZES ID
    {
        adicionarParente(classeAtual, string($5));
        free($5);
    }
    |
      cabecalho_classe OF CLASS_STEREOTYPE SPECIALIZES ID
    ;

%%

// MAPA DAS PALAVRAS RESERVADAS E STEREOTYPES
void mapa() {
    reservedDatatypes = {
        {"number", NATIVE_TYPE}, {"string", NATIVE_TYPE}, {"boolean", NATIVE_TYPE},
        {"date", NATIVE_TYPE}, {"time", NATIVE_TYPE}, {"datetime", NATIVE_TYPE}
    };
    reservedWords = {
        {"package", PACKAGE}, {"import", IMPORT}, {"genset", GENSET},
        {"disjoint", DISJOINT}, {"complete", COMPLETE}, {"general", GENERAL},
        {"specifics", SPECIFICS}, {"where", WHERE},
        {"enum", ENUM}, {"datatype", DATATYPE}, {"relation", RELATION}, {"of", OF},
        {"specializes", SPECIALIZES}, {"functional-complexes", FUNCTIONAL_COMPLEXES},
        {"has", HAS}, {"material", MATERIAL},
    };
    classStereotype = {
        {"relator", CLASS_STEREOTYPE}, {"event", CLASS_STEREOTYPE}, {"situation", CLASS_STEREOTYPE},
        {"process", CLASS_STEREOTYPE}, {"category", CLASS_STEREOTYPE}, {"mixin", CLASS_STEREOTYPE},
        {"phaseMixin", CLASS_STEREOTYPE}, {"roleMixin", CLASS_STEREOTYPE},
        {"historialRoleMixin", CLASS_STEREOTYPE}, {"kind", CLASS_STEREOTYPE},
        {"collective", CLASS_STEREOTYPE}, {"quantity", CLASS_STEREOTYPE},
        {"quality", CLASS_STEREOTYPE}, {"mode", CLASS_STEREOTYPE},
        {"intrisicMode", CLASS_STEREOTYPE}, {"extrinsicMode", CLASS_STEREOTYPE},
        {"subkind", CLASS_STEREOTYPE}, {"phase", CLASS_STEREOTYPE}, {"role", CLASS_STEREOTYPE},
        {"historicalRole", CLASS_STEREOTYPE},{"intrinsic-modes", CLASS_STEREOTYPE}, 
        {"relators", CLASS_STEREOTYPE}
    };
    relationStereotypes = {
        {"derivation", RELATION_STEREOTYPE}, {"comparative", RELATION_STEREOTYPE},
        {"mediation", RELATION_STEREOTYPE}, {"characterization", RELATION_STEREOTYPE},
        {"externalDependence", RELATION_STEREOTYPE}, {"componentOf", RELATION_STEREOTYPE},
        {"memberOf", RELATION_STEREOTYPE}, {"subCollectionOf", RELATION_STEREOTYPE},
        {"subQualityOf", RELATION_STEREOTYPE}, {"instantiation", RELATION_STEREOTYPE},
        {"termination", RELATION_STEREOTYPE}, {"participational", RELATION_STEREOTYPE},
        {"participation", RELATION_STEREOTYPE}, {"historicalDependence", RELATION_STEREOTYPE},
        {"creation", RELATION_STEREOTYPE}, {"manifestation", RELATION_STEREOTYPE},
        {"bringsAbout", RELATION_STEREOTYPE}, {"triggers", RELATION_STEREOTYPE},
        {"composition", RELATION_STEREOTYPE}, {"aggregation", RELATION_STEREOTYPE},
        {"inherence", RELATION_STEREOTYPE}, {"value", RELATION_STEREOTYPE}, {"formal", RELATION_STEREOTYPE},
        {"constitution", RELATION_STEREOTYPE}, {"constitutedBy", RELATION_STEREOTYPE}
    };
}

int yylex(void) {
    char typeTmp[50], lexemeTmp[100];
    int lineTmp, colTmp;

    // Lê no formato: TYPE LEXEMA LINHA COLUNA
    if (fscanf(tokenFile, "%s %s %d %d", typeTmp, lexemeTmp, &lineTmp, &colTmp) != 4) {
        return 0; // EOF ou erro de leitura
    }

    // Atualiza variáveis globais
    strcpy(type, typeTmp);
    strcpy(lexeme, lexemeTmp);
    lineNumber = lineTmp;
    columnNumber = colTmp;

    std::string lex(lexeme);

    // Símbolos Especiais
    if (lex == "--") return ARROW_ASSOCIATION;
    if (lex == "<>--") return ARROW_AGGREGATION;
    if (lex == "<*>--") return ARROW_COMPOSITION;
    if (lex == "<o>--") return ARROW_AGGREGATION_EXISTENTIAL;
    if (lex == "{") return LBRACE;
    if (lex == "}") return RBRACE;
    if (lex == ":") return COLON;
    if (lex == ",") return COMMA;
    if (lex == ".") return DOT;
    if (lex == "[") return LBRACKET;
    if (lex == "]") return RBRACKET;

    // Cardinalidade no formato [X..Y]
    if (lex.length() > 1 && lex[0] == '[') {
        yylval.strval = strdup(lexeme);
        return CARDINALITY;
    }

    // Estereótipos de classe
    if (classStereotype.find(lex) != classStereotype.end()) {
        yylval.strval = strdup(lexeme);
        return CLASS_STEREOTYPE;
    }

    // Remove '@' para estereótipos de relação
    std::string cleanLex = lex;
    if (lex == "@") return yylex();
    if (lex[0] == '@') cleanLex = lex.substr(1);

    // Estereótipos de relação
    if (relationStereotypes.find(cleanLex) != relationStereotypes.end()) {
        yylval.strval = strdup(cleanLex.c_str());
        return RELATION_STEREOTYPE;
    }

    // Palavras reservadas
    if (reservedWords.find(lex) != reservedWords.end()) {
        return reservedWords[lex];
    }

    // Tipos nativos
    if (reservedDatatypes.find(lex) != reservedDatatypes.end()) {
        yylval.strval = strdup(lexeme);
        return NATIVE_TYPE;
    }

    // Número
    if (strcmp(type, "NUM") == 0) {
        yylval.strval = strdup(lexeme);
        return NUM;
    }

    // EOF
    if (strcmp(type, "EOF") == 0) return 0;

    // Identificador genérico
    yylval.strval = strdup(lexeme);
    return ID;
}

void yyerror(const char *s) {
    ErrorInfo erro;
    erro.line = lineNumber;
    erro.col = columnNumber;
    erro.mensagem = string(s);

    string currentToken = string(lexeme);
    if (currentToken == "}") {
        erro.sugestao = "Confira se há uma chave de abertura correspondente.";
    } else if (currentToken == "{") {
        erro.sugestao = "Confira se há uma chave de fechamento correspondente.";
    } else if (currentToken == "]") {
        erro.sugestao = "Confira se há um colchete de abertura correspondente.";
    } else if (currentToken == "[") {
        erro.sugestao = "Confira se há um colchete de fechamento correspondente.";
    } else if (currentToken == ":") {
        erro.sugestao = "Verifique se o ':' está sendo usado corretamente em declarações de atributos.";
    } else if (currentToken == ",") {
        erro.sugestao = "Verifique se a vírgula está separando corretamente os elementos.";
    } else if (currentToken == ".") {
        erro.sugestao = "Verifique o uso correto do ponto.";
    } else if (currentToken == "--" || currentToken == "<>--" || currentToken == "<*>--" || currentToken == "<o>--" || currentToken == "->"
    || currentToken == "-<>--") {
        erro.sugestao = "Operador de relação incorreto ou incompleto.";
    } else if (reservedWords.find(currentToken) != reservedWords.end()) {
        erro.sugestao = "Verifique o uso correto da palavra reservada '" + currentToken + "'.";
    } else {
        erro.sugestao = "Verifique a sintaxe próxima ao token '" + currentToken + "'.";
    }

    errorLog.push_back(erro);

    fprintf(stderr, "\n[ERRO] Arquivo: %s Linha: %d, Coluna: %d\n", currentFileName.c_str(), erro.line, erro.col);
    fprintf(stderr, "   -> Lexema encontrado: '%s'\n", currentToken.c_str());
    fprintf(stderr, "   -> Sugestão: %s\n", erro.sugestao.c_str());
}

void imprimirErro() {
    if (!errorLog.empty()) {

        cout << "\n A análise finalizou com " << errorLog.size(); 
        if(errorLog.size() > 1) cout << " erros." << endl;
         else cout << " erro." << endl;
    }

}

void imprimirRelatorio(string dirName) {

    string reportPath = "output/" + dirName + "/" + dirName + "_Syntax_analysis.txt";
    relatorioFile.open(reportPath);
    
    relatorioFile << "\n======================================================" << endl;
    relatorioFile << "               RELATÓRIO DE SÍNTESE" << endl;
    relatorioFile << "======================================================" << endl;

    // ===== Estatísticas Gerais =====
    relatorioFile << "\n[ESTATÍSTICAS GERAIS]" << endl;
    relatorioFile << "Pacotes: " << pacotes.size() << " (";
    for (size_t i = 0; i < pacotes.size(); ++i)
        relatorioFile << pacotes[i].name << (i < pacotes.size() - 1 ? ", " : "");
    relatorioFile << ")" << endl;

    int totalClasses = 0, totalRelationsInternas = 0, totalRelationsExternas = 0;
    int totalGensets = 0, totalEnums = 0, totalDatatypes = reservedDatatypes.size();

    for (const auto& p : pacotes) {
        totalClasses += p.classes.size();
        for (const auto& c : p.classes) totalRelationsInternas += c.internalRelations.size();
        totalRelationsExternas += p.relacoesExternas.size();
        totalGensets += p.gensets.size();
        totalEnums += p.enums.size();
    }

    relatorioFile << "Classes: " << totalClasses << endl;
    relatorioFile << "Relações Internas: " << totalRelationsInternas << endl;
    relatorioFile << "Relações Externas: " << totalRelationsExternas << endl;
    relatorioFile << "Gensets: " << totalGensets << endl;
    relatorioFile << "Enums: " << totalEnums << endl;
    relatorioFile << "Datatypes: " << totalDatatypes << endl;

    relatorioFile << "\n[DETALHAMENTO POR PACOTE]" << endl;

    for (const auto& pacote : pacotes) {
        relatorioFile << "\n" << pacote.name << endl;

        if (pacote.classes.empty() && pacote.enums.empty() && pacote.gensets.empty() && pacote.relacoesExternas.empty()) {
            relatorioFile << "(Pacote vazio)" << endl;
            continue;
        }

        // Classes em hierarquia
        for (size_t i = 0; i < pacote.classes.size(); ++i) {
            const auto& classes = pacote.classes[i];
            bool isLastClass = (i == pacote.classes.size() - 1);

            relatorioFile << (isLastClass ? "└─ " : "├─ ") << classes.name << " [" << classes.stereotype << "]";
            if (!classes.parents.empty()) {
                relatorioFile << " (Herda de: ";
                for (size_t j = 0; j < classes.parents.size(); ++j) {
                    relatorioFile << classes.parents[j] << (j < classes.parents.size() - 1 ? ", " : "");
                }
                relatorioFile << ")";
            }
            relatorioFile << endl;

            // Relações internas
            if (!classes.internalRelations.empty()) {
                relatorioFile << (isLastClass ? "   ├─ Internas:" : "   │─ Internas:") << endl;
                for (const auto& relacao : classes.internalRelations) {
                    relatorioFile << "   │  > ";
                    if(!relacao.stereotype.empty()) relatorioFile << "(@" << relacao.stereotype << ") ";
                    if(!relacao.sourceCardinality.empty()) relatorioFile << relacao.sourceCardinality << " ";
                    if(!relacao.name.empty()) relatorioFile << relacao.name << " ";
                    else relatorioFile << "-- ";
                    if(!relacao.targetCardinality.empty()) relatorioFile << relacao.targetCardinality << " ";
                    relatorioFile << "--> " << relacao.targetClass << endl;
                }
            }

            // Atributos
            if (!classes.attributes.empty()) {
                relatorioFile << (isLastClass ? "   ├─ Atributos: " : "   │─ Atributos: ");
                for (const auto& at : classes.attributes) relatorioFile << at << ", ";
                relatorioFile << endl;
            }
        }

        // Gensets
        if (!pacote.gensets.empty()) {
            relatorioFile << "   └─ Gensets:" << endl;
            for (const auto& gs : pacote.gensets) {
                relatorioFile << "       * " << gs.name << endl;
                relatorioFile << "         - General: " << gs.general << endl;
                relatorioFile << "         - Specifics: ";
                for (size_t i = 0; i < gs.specifics.size(); ++i) {
                    relatorioFile << gs.specifics[i] << (i < gs.specifics.size() - 1 ? ", " : "");
                }
                relatorioFile << endl;
            }
        }

        // Enums
        if (!pacote.enums.empty()) {
            relatorioFile << "   └─ Enums:" << endl;
            for (const auto& en : pacote.enums) {
                relatorioFile << "       * " << en.name << ": ";
                for (size_t i = 0; i < en.literals.size(); ++i) {
                    relatorioFile << en.literals[i] << (i < en.literals.size() - 1 ? ", " : "");
                }
                relatorioFile << endl;
            }
        }

        // Relações externas
        if (!pacote.relacoesExternas.empty()) {
            relatorioFile << "   └─ Relações Externas:" << endl;
            for (const auto& rel : pacote.relacoesExternas) {
                relatorioFile << "       * ";
                if (!rel.stereotype.empty()) relatorioFile << "(@" << rel.stereotype << ") ";
                relatorioFile << rel.details << endl;
            }
        }
    }

    relatorioFile.close();
}


