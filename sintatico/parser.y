%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <string>
#include <iostream>
#include <unordered_map>

using namespace std;

// Estruturas de dados para armazenar os construtos
struct Attribute {
    string name;
    string type;
    bool isConst;
    bool isDerived;
    bool isOrdered;
};

struct Class {
    string stereotype;
    string name;
    vector<Attribute> attributes;
    string specializes;
};

struct Datatype {
    string name;
    vector<Attribute> attributes;
};

struct Enum {
    string name;
    vector<string> values;
};

struct GeneralizationSet {
    string name;
    string general;
    vector<string> specifics;
    bool disjoint;
    bool complete;
};

struct Relation {
    string stereotype;
    string from;
    string to;
    string fromCardinality;
    string toCardinality;
    string symbol;
    bool isInternal;
};

struct Package {
    string name;
    vector<Class> classes;
    vector<Datatype> datatypes;
    vector<Enum> enums;
    vector<GeneralizationSet> gensets;
    vector<Relation> relations;
};

// Variáveis globais
extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char* msg);

vector<Package> packages;
Package currentPackage;
vector<string> errors;

// Funções auxiliares
void startNewPackage(const char* name);
void addClass(const Class& cls);
void addDatatype(const Datatype& dt);
void addEnum(const Enum& en);
void addGeneralizationSet(const GeneralizationSet& genset);
void addRelation(const Relation& rel);
void generateSummaryReport();
void generateErrorReport();

%}

// Tokens baseados na sua lista léxica
%token PACKAGE IMPORT GENSET DISJOINT COMPLETE GENERAL SPECIFICS WHERE SPECIALIZES

// Metaatributos
%token ORDERED CONST DERIVED SUBSETS REDEFINES

// Tipos de dados
%token NUMBER STRING BOOLEAN DATE TIME DATETIME

// Estereótipos de classe
%token EVENT SITUATION PROCESS CATEGORY MIXIN PHASEMIXIN ROLEMIXIN HISTORICALROLEMIXIN
%token KIND COLLECTIVE QUANTITY QUALITY MODE INTRINSICMODE EXTRINSICMODE SUBKIND
%token PHASE ROLE HISTORICALROLE

// Estereótipos de relação
%token MATERIAL DERIVATION COMPARATIVE MEDIATION CHARACTERIZATION EXTERNALDEPENDENCE
%token COMPONENTOF MEMBEROF SUBCOLLECTIONOF SUBQUALITYOF INSTANTIATION TERMINATION
%token PARTICIPATIONAL PARTICIPATION HISTORICALDEPENDENCE CREATION MANIFESTATION
%token BRINGSABOUT TRIGGERS COMPOSITION AGGREGATION INHERENCE VALUE FORMAL CONSTITUTION

// Símbolos especiais
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET DOTDOT LESSGREATERDASH GREATERLESSDASH
%token STAR AT COLON DASHDASH

// Identificadores e literais
%token ID STRING_LITERAL NUMBER_LITERAL CARDINALITY

%start Program

%%

Program
    : Declarations
    ;

Declarations
    : Declarations Declaration
    | /* vazio */
    ;

Declaration
    : PackageDeclaration
    | ClassDeclaration
    | DatatypeDeclaration
    | EnumDeclaration
    | GeneralizationSetDeclaration
    | RelationDeclaration
    | ImportDeclaration
    ;

PackageDeclaration
    : PACKAGE ID { 
        startNewPackage($2);
        free($2);
      }
    ;

ImportDeclaration
    : IMPORT STRING_LITERAL {
        // Implementar lógica de importação se necessário
        free($2);
      }
    ;

ClassDeclaration
    : ClassStereotype ID LBRACE AttributeList RBRACE {
        Class cls;
        cls.stereotype = $1;
        cls.name = $2;
        cls.attributes = $4;
        addClass(cls);
        free($2);
      }
    | ClassStereotype ID SPECIALIZES ID {
        Class cls;
        cls.stereotype = $1;
        cls.name = $2;
        cls.specializes = $4;
        addClass(cls);
        free($2);
        free($4);
      }
    ;

ClassStereotype
    : KIND { $$ = "kind"; }
    | PHASE { $$ = "phase"; }
    | ROLE { $$ = "role"; }
    | SUBKIND { $$ = "subkind"; }
    | COLLECTIVE { $$ = "collective"; }
    | QUANTITY { $$ = "quantity"; }
    | CATEGORY { $$ = "category"; }
    | MIXIN { $$ = "mixin"; }
    | PHASEMIXIN { $$ = "phaseMixin"; }
    | ROLEMIXIN { $$ = "roleMixin"; }
    | HISTORICALROLE { $$ = "historicalRole"; }
    | EVENT { $$ = "event"; }
    | PROCESS { $$ = "process"; }
    | SITUATION { $$ = "situation"; }
    | QUALITY { $$ = "quality"; }
    | MODE { $$ = "mode"; }
    | INTRINSICMODE { $$ = "intrinsicMode"; }
    | EXTRINSICMODE { $$ = "extrinsicMode"; }
    ;

AttributeList
    : AttributeList Attribute
    | /* vazio */ { $$ = vector<Attribute>(); }
    ;

Attribute
    : ID COLON Type MetaAttributes {
        Attribute attr;
        attr.name = $1;
        attr.type = $3;
        attr.isConst = $4.isConst;
        attr.isDerived = $4.isDerived;
        attr.isOrdered = $4.isOrdered;
        $$ = attr;
        free($1);
      }
    ;

Type
    : STRING { $$ = "string"; }
    | NUMBER { $$ = "number"; }
    | BOOLEAN { $$ = "boolean"; }
    | DATE { $$ = "date"; }
    | TIME { $$ = "time"; }
    | DATETIME { $$ = "datetime"; }
    | ID { $$ = $1; }
    ;

MetaAttributes
    : LBRACE MetaAttributeList RBRACE { $$ = $2; }
    | /* vazio */ { 
        struct { bool isConst; bool isDerived; bool isOrdered; } attrs = {false, false, false};
        $$ = attrs;
      }
    ;

MetaAttributeList
    : MetaAttribute
    | MetaAttributeList COMMA MetaAttribute
    ;

MetaAttribute
    : CONST { 
        struct { bool isConst; bool isDerived; bool isOrdered; } attrs = {true, false, false};
        $$ = attrs;
      }
    | DERIVED { 
        struct { bool isConst; bool isDerived; bool isOrdered; } attrs = {false, true, false};
        $$ = attrs;
      }
    | ORDERED { 
        struct { bool isConst; bool isDerived; bool isOrdered; } attrs = {false, false, true};
        $$ = attrs;
      }
    ;

DatatypeDeclaration
    : DATATYPE ID LBRACE AttributeList RBRACE {
        Datatype dt;
        dt.name = $2;
        dt.attributes = $4;
        addDatatype(dt);
        free($2);
      }
    ;

EnumDeclaration
    : ENUM ID LBRACE EnumValues RBRACE {
        Enum en;
        en.name = $2;
        en.values = $4;
        addEnum(en);
        free($2);
      }
    ;

EnumValues
    : ID { 
        vector<string> values;
        values.push_back($1);
        $$ = values;
        free($1);
      }
    | EnumValues COMMA ID {
        $1.push_back($3);
        $$ = $1;
        free($3);
      }
    ;

GeneralizationSetDeclaration
    : DisjointComplete GENSET ID WHERE IDList SPECIALIZES ID {
        GeneralizationSet genset;
        genset.name = $3;
        genset.specifics = $5;
        genset.general = $7;
        genset.disjoint = $1.disjoint;
        genset.complete = $1.complete;
        addGeneralizationSet(genset);
        free($3);
        free($7);
      }
    | GENSET ID LBRACE GeneralSpecifies RBRACE {
        GeneralizationSet genset;
        genset.name = $2;
        genset.general = $4.general;
        genset.specifics = $4.specifics;
        genset.disjoint = false; // padrão
        genset.complete = false; // padrão
        addGeneralizationSet(genset);
        free($2);
      }
    ;

DisjointComplete
    : DISJOINT COMPLETE { 
        struct { bool disjoint; bool complete; } dc = {true, true};
        $$ = dc;
      }
    | DISJOINT { 
        struct { bool disjoint; bool complete; } dc = {true, false};
        $$ = dc;
      }
    | COMPLETE { 
        struct { bool disjoint; bool complete; } dc = {false, true};
        $$ = dc;
      }
    | /* vazio */ { 
        struct { bool disjoint; bool complete; } dc = {false, false};
        $$ = dc;
      }
    ;

IDList
    : ID {
        vector<string> ids;
        ids.push_back($1);
        $$ = ids;
        free($1);
      }
    | IDList COMMA ID {
        $1.push_back($3);
        $$ = $1;
        free($3);
      }
    ;

GeneralSpecifies
    : GENERAL ID SPECIFICS IDList {
        struct { string general; vector<string> specifics; } gs;
        gs.general = $2;
        gs.specifics = $4;
        $$ = gs;
        free($2);
      }
    ;

RelationDeclaration
    : ClassStereotype ID LBRACE InternalRelation RBRACE {
        Relation rel;
        rel.isInternal = true;
        rel.from = $2;
        rel.stereotype = $5.stereotype;
        rel.to = $5.to;
        rel.fromCardinality = $5.fromCardinality;
        rel.toCardinality = $5.toCardinality;
        rel.symbol = $5.symbol;
        addRelation(rel);
        free($2);
      }
    | ExternalRelation
    ;

InternalRelation
    : AT RelationStereotype LBRACKET CARDINALITY RBRACKET RelationSymbol LBRACKET CARDINALITY RBRACKET ID {
        struct { string stereotype; string to; string fromCardinality; string toCardinality; string symbol; } rel;
        rel.stereotype = $2;
        rel.to = $9;
        rel.fromCardinality = $4;
        rel.toCardinality = $7;
        rel.symbol = $6;
        $$ = rel;
        free($9);
      }
    ;

ExternalRelation
    : AT RelationStereotype RELATION ID LBRACKET CARDINALITY RBRACKET RelationSymbol LBRACKET CARDINALITY RBRACKET ID {
        Relation rel;
        rel.isInternal = false;
        rel.stereotype = $2;
        rel.from = $4;
        rel.to = $11;
        rel.fromCardinality = $6;
        rel.toCardinality = $9;
        rel.symbol = $8;
        addRelation(rel);
        free($4);
        free($11);
      }
    ;

RelationStereotype
    : COMPONENTOF { $$ = "componentOf"; }
    | MEDIATION { $$ = "mediation"; }
    | MATERIAL { $$ = "material"; }
    | CHARACTERIZATION { $$ = "characterization"; }
    | MEMBEROF { $$ = "memberOf"; }
    | AGGREGATION { $$ = "aggregation"; }
    | COMPOSITION { $$ = "composition"; }
    | DERIVATION { $$ = "derivation"; }
    | COMPARATIVE { $$ = "comparative"; }
    | EXTERNALDEPENDENCE { $$ = "externalDependence"; }
    | SUBCOLLECTIONOF { $$ = "subCollectionOf"; }
    | SUBQUALITYOF { $$ = "subQualityOf"; }
    | INSTANTIATION { $$ = "instantiation"; }
    | PARTICIPATION { $$ = "participation"; }
    | HISTORICALDEPENDENCE { $$ = "historicalDependence"; }
    | CREATION { $$ = "creation"; }
    | MANIFESTATION { $$ = "manifestation"; }
    | BRINGSABOUT { $$ = "bringsAbout"; }
    | TRIGGERS { $$ = "triggers"; }
    | INHERENCE { $$ = "inherence"; }
    | VALUE { $$ = "value"; }
    | FORMAL { $$ = "formal"; }
    | CONSTITUTION { $$ = "constitution"; }
    ;

RelationSymbol
    : LESSGREATERDASH { $$ = "<>--"; }
    | GREATERLESSDASH { $$ = "--<>"; }
    | DASHDASH { $$ = "--"; }
    ;

%%

void yyerror(const char* msg) {
    string errorMsg = "Linha " + to_string(yylineno) + ": " + msg;
    errors.push_back(errorMsg);
    cerr << "ERRO: " << errorMsg << endl;
}

void startNewPackage(const char* name) {
    if (!currentPackage.name.empty()) {
        packages.push_back(currentPackage);
    }
    currentPackage = Package();
    currentPackage.name = name;
    cout << "Pacote criado: " << name << endl;
}

void addClass(const Class& cls) {
    currentPackage.classes.push_back(cls);
    cout << "Classe adicionada: " << cls.stereotype << " " << cls.name;
    if (!cls.specializes.empty()) {
        cout << " especializa " << cls.specializes;
    }
    cout << endl;
}

void addDatatype(const Datatype& dt) {
    currentPackage.datatypes.push_back(dt);
    cout << "Tipo de dados adicionado: " << dt.name << endl;
}

void addEnum(const Enum& en) {
    currentPackage.enums.push_back(en);
    cout << "Enum adicionado: " << en.name << " com " << en.values.size() << " valores" << endl;
}

void addGeneralizationSet(const GeneralizationSet& genset) {
    currentPackage.gensets.push_back(genset);
    cout << "Conjunto de generalização adicionado: " << genset.name << endl;
}

void addRelation(const Relation& rel) {
    currentPackage.relations.push_back(rel);
    string type = rel.isInternal ? "Interna" : "Externa";
    cout << "Relação " << type << " adicionada: " << rel.stereotype << endl;
}

void generateSummaryReport() {
    cout << "\n=== RELATÓRIO DE SÍNTESE ===" << endl;
    
    for (const auto& pkg : packages) {
        cout << "\nPacote: " << pkg.name << endl;
        
        cout << "\nClasses (" << pkg.classes.size() << "):" << endl;
        for (const auto& cls : pkg.classes) {
            cout << "- " << cls.name << " (" << cls.stereotype << ")";
            if (!cls.specializes.empty()) {
                cout << " → especializa " << cls.specializes;
            }
            if (!cls.attributes.empty()) {
                cout << " [" << cls.attributes.size() << " atributos]";
            }
            cout << endl;
        }
        
        cout << "\nTipos de dados (" << pkg.datatypes.size() << "):" << endl;
        for (const auto& dt : pkg.datatypes) {
            cout << "- " << dt.name << " [" << dt.attributes.size() << " atributos]" << endl;
        }
        
        cout << "\nEnums (" << pkg.enums.size() << "):" << endl;
        for (const auto& en : pkg.enums) {
            cout << "- " << en.name << " [" << en.values.size() << " valores: ";
            for (size_t i = 0; i < en.values.size(); i++) {
                cout << en.values[i];
                if (i < en.values.size() - 1) cout << ", ";
            }
            cout << "]" << endl;
        }
        
        cout << "\nConjuntos de generalização (" << pkg.gensets.size() << "):" << endl;
        for (const auto& gs : pkg.gensets) {
            cout << "- " << gs.name;
            if (gs.disjoint) cout << " (disjoint)";
            if (gs.complete) cout << " (complete)";
            cout << " " << gs.general << " → [";
            for (size_t i = 0; i < gs.specifics.size(); i++) {
                cout << gs.specifics[i];
                if (i < gs.specifics.size() - 1) cout << ", ";
            }
            cout << "]" << endl;
        }
        
        cout << "\nRelações (" << pkg.relations.size() << "):" << endl;
        for (const auto& rel : pkg.relations) {
            cout << "- " << (rel.isInternal ? "Interna" : "Externa") << ": ";
            cout << rel.stereotype << " " << rel.from << " " << rel.fromCardinality;
            cout << " " << rel.symbol << " " << rel.toCardinality << " " << rel.to << endl;
        }
    }
}

void generateErrorReport() {
    cout << "\n=== RELATÓRIO DE ERROS ===" << endl;
    if (errors.empty()) {
        cout << "Nenhum erro encontrado!" << endl;
    } else {
        cout << "Foram encontrados " << errors.size() << " erros:" << endl;
        for (const auto& error : errors) {
            cout << "• " << error << endl;
        }
    }
}

int main() {
    cout << "Analisador Sintático Tonto - Iniciando análise..." << endl;
    
    int result = yyparse();
    
    // Adicionar o último pacote processado
    if (!currentPackage.name.empty()) {
        packages.push_back(currentPackage);
    }
    
    generateSummaryReport();
    generateErrorReport();
    
    return result;
}