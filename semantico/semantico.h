#ifndef SEMANTICO_H
#define SEMANTICO_H

#include <string>
#include <vector>
#include <map>
#include <utility>
#include <algorithm>

using namespace std;

// ESTRUTURAS DE DADOS
struct RelacaoInterna {
    vector<string> stereotypes;
    string target;
    int linha;
};

struct RelacaoExterna {
    vector<string> stereotypes;
    string source;
    string target;
    int linha;
};

struct Classe {
    string nome;
    string estereotipo;
    vector<string> parents; 
    vector<RelacaoInterna> relacoes_internas;
    int linha;
};

struct Genset {
    string nome;
    string general;
    vector<string> specifics;
    vector<string> modifiers;
    int linha;
};

struct SintesePacote {
    map<string, Classe> classes;
    vector<Genset> generalizacoes;
    vector<RelacaoExterna> relacoes_externas;
};

struct Sintese {
    map<string, SintesePacote> pacotes;
};

// FUNÇÕES UTILITÁRIAS 
map<string, pair<vector<string>, vector<string>>> verificar_semantica_por_pacote(const Sintese& sintese);
bool contem(const vector<string>& v, const string& s);
string limpaStereo(string s);

#endif
