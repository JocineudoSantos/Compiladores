#ifndef SEMANTICO_H
#define SEMANTICO_H

#include <string>
#include <vector>
#include <map>
#include <utility>
#include <algorithm>

using namespace std;

// ================= RELAÇÕES =================
struct RelacaoInterna {
    vector<string> stereotypes;
    string target;
};

struct RelacaoExterna {
    vector<string> stereotypes;
    string source;
    string target;
};

// ================= CLASSES =================
struct Classe {
    string estereotipo;
     vector<string> parents;      
    vector<RelacaoInterna> relacoes_internas;
};

// ================= GENSETS =================
struct Genset {
    string nome;
    string general;
    vector<string> specifics;
    vector<string> modifiers;
};

// ================= SÍNTESE =================
struct Sintese {
    map<string, Classe> classes;
    vector<Genset> generalizacoes;
    vector<RelacaoExterna> relacoes_externas;
};

// ================= SEMÂNTICO =================
pair<vector<string>, vector<string>> verificar_semantica(const Sintese& sintese);

// ================= FUNÇÕES UTILITÁRIAS =================
bool contem(const vector<string>& v, const string& s);
string limpaStereo(string s);

#endif
