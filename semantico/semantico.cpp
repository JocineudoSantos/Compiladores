#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <algorithm>
#include "semantico.h"
using namespace std;

bool contem(const vector<string>& v, const string& s) {
    return find(v.begin(), v.end(), s) != v.end();
}

string limpaStereo(string s) {
    if (!s.empty() && s[0] == '@') return s.substr(1);
    return s;
}

pair<vector<string>, vector<string>> verificar_semantica(const Sintese& sintese) {

    vector<string> padroes_identificados;
    vector<string> erros;

    const auto& classes = sintese.classes;
    const auto& gensets = sintese.generalizacoes;
    const auto& relacoes_externas = sintese.relacoes_externas;

    // 1. SUBKIND PATTERN
    map<string, vector<string>> subkindsPorGeneral;

    for (const auto& [nomeClasse, classe] : classes) {
        if (classe.estereotipo != "subkind") continue;

        for (const auto& pai : classe.parents) {
            subkindsPorGeneral[pai].push_back(nomeClasse);
        }
    }

    // Validar cada subkind
    for (const auto& [nomeClasse, classe] : classes) {

    if (classe.estereotipo != "subkind") continue;

    // Deve especializar alguém
    if (classe.parents.empty()) {
        erros.push_back(
            "[Subkind Pattern] '" + nomeClasse +
            "' deve especializar um Kind ou Subkind."
        );
        continue;
    }

    // Pai deve ser kind ou subkind
    bool paiRigido = false;
    for (const auto& pai : classe.parents) {
        auto itPai = classes.find(pai);
        if (itPai != classes.end() &&
            (itPai->second.estereotipo == "kind" ||
             itPai->second.estereotipo == "subkind")) {
            paiRigido = true;
        }
    }

    if (!paiRigido) {
        erros.push_back(
            "[Subkind Pattern] '" + nomeClasse +
            "' deve herdar de um Kind ou outro Subkind."
        );
        continue;
    }

    // Verifica se o general tem múltiplos subkinds
    bool precisaDeGenset = false;
    for (const auto& pai : classe.parents) {
        if (subkindsPorGeneral[pai].size() >= 2) {
            precisaDeGenset = true;
        }
    }

    // Se precisa, verifica participação em genset
    if (precisaDeGenset) {
        bool participaDeGenset = false;
        for (const auto& g : gensets) {
            if (contem(g.specifics, nomeClasse)) {
                participaDeGenset = true;
                break;
            }
        }

        if (!participaDeGenset) {
            erros.push_back(
                "[Subkind Pattern] '" + nomeClasse +
                "' especializa um general com múltiplos subkinds e deve participar de um genset."
            );
            continue;
        }
    }

    // Padrão identificado
    padroes_identificados.push_back(
        "[OK] Subkind Pattern (" + nomeClasse + ")"
    );
    }   

    // 2. ROLE PATTERN
    for (const auto& [nomeClasse, classe] : classes) {

    // Só analisa roles
    if (classe.estereotipo != "role") continue;

    // Deve herdar de alguém
    if (classe.parents.empty()) {
        erros.push_back(
            "[Role Pattern] '" + nomeClasse +
            "' deve especializar uma classe."
        );
        continue;
    }

    // Pai deve ser Kind ou Role
    bool paiValido = false;
    for (const auto& pai : classe.parents) {
        auto itPai = classes.find(pai);
        if (itPai != classes.end() &&
            (itPai->second.estereotipo == "kind" ||
             itPai->second.estereotipo == "role")) {
            paiValido = true;
        }
    }

    if (!paiValido) {
        erros.push_back(
            "[Role Pattern] '" + nomeClasse +
            "' herda de uma classe inválida."
        );
        continue;
    }

    // Role DEVE participar de um genset
    bool participaDeGenset = false;
    for (const auto& g : gensets) {
        if (contem(g.specifics, nomeClasse)) {
            participaDeGenset = true;
            break;
        }
    }

    if (!participaDeGenset) {
        erros.push_back(
            "[Role Pattern] '" + nomeClasse +
            "' deve participar de um Genset."
        );
        continue;
    }

    // Padrão identificado
    padroes_identificados.push_back(
        "[OK] Role Pattern (" + nomeClasse + ")"
    );
    }

    // 3. PHASE PATTERN
    for (const auto& [nomeClasse, classe] : classes) {

    if (classe.estereotipo != "relator") continue;

    int mediacoesValidas = 0;

    for (const auto& rel : classe.relacoes_internas) {

        // REGRA: TODA relação interna de relator é mediação
        auto it = classes.find(rel.target);
        if (it == classes.end()) {
            erros.push_back(
                "[Relator Pattern] O relator '" + nomeClasse +
                "' media uma classe inexistente: '" + rel.target + "'."
            );
            continue;
        }

        if (it->second.estereotipo == "role") {
            mediacoesValidas++;
        } else {
            erros.push_back(
                "[Relator Pattern] O relator '" + nomeClasse +
                "' possui mediação inválida para '" + rel.target +
                "' (estereótipo='" + it->second.estereotipo +
                "'). Esperado: 'role'."
            );
        }
    }

    if (mediacoesValidas < 2) {
        erros.push_back(
            "[Relator Pattern] O relator '" + nomeClasse +
            "' deve possuir pelo menos 2 mediações (@mediation) válidas para roles."
        );
    } else {
        padroes_identificados.push_back(
            "[OK] Relator Pattern (" + nomeClasse + ")"
        );
    }
    }

    // 5. MODE PATTERN
    for (const auto& [nomeClasse, classe] : classes) {

    // Só analisa mode
    if (classe.estereotipo != "mode") continue;

    bool temCharacterization = false;
    bool temExternalDependence = false;

    // Verifica relações obrigatórias
    for (const auto& rel : classe.relacoes_internas) {
        for (auto s : rel.stereotypes) {
            s = limpaStereo(s);
            if (s == "characterization") temCharacterization = true;
            if (s == "externalDependence") temExternalDependence = true;
        }
    }

    // Erros obrigatórios
    if (!temCharacterization) {
        erros.push_back(
            "[Mode Pattern] '" + nomeClasse +
            "' deve possuir uma relação @characterization."
        );
    }

    if (!temExternalDependence) {
        erros.push_back(
            "[Mode Pattern] '" + nomeClasse +
            "' deve possuir uma relação @externalDependence."
        );
    }

    // Só é OK se tiver as duas
    if (temCharacterization && temExternalDependence) {
        padroes_identificados.push_back(
            "[OK] Mode Pattern (" + nomeClasse + ")"
        );
    }
   }

    // ROLE MIXIN PATTERN
    for (const auto& [nomeClasse, classe] : classes) {

    // Só analisa roleMixin
    if (classe.estereotipo != "roleMixin") continue;

    const Genset* gensetEncontrado = nullptr;

    // Procurar genset onde ele é o general
    for (const auto& g : gensets) {
        if (g.general == nomeClasse) {
            gensetEncontrado = &g;
            break;
        }
    }

    // Deve ser general de um genset
    if (!gensetEncontrado) {
        erros.push_back(
            "[RoleMixin Pattern] '" + nomeClasse +
            "' deve ser a classe geral de um genset disjoint e complete."
        );
        continue;
    }

    // Genset deve ser disjoint e complete
    bool isDisjoint  = contem(gensetEncontrado->modifiers, "disjoint");
    bool isComplete  = contem(gensetEncontrado->modifiers, "complete");

    if (!isDisjoint || !isComplete) {
        erros.push_back(
            "[RoleMixin Pattern] Genset '" + gensetEncontrado->nome +
            "' deve ser marcado como disjoint e complete."
        );
        continue;
    }

    // Todas as específicas devem ser role
    bool todasSaoRoles = true;
    for (const auto& spec : gensetEncontrado->specifics) {
        auto itSpec = classes.find(spec);
        if (itSpec == classes.end() ||
            itSpec->second.estereotipo != "role") {

            erros.push_back(
                "[RoleMixin Pattern] A classe '" + spec +
                "' deve ser estereotipada como role."
            );
            todasSaoRoles = false;
        }
    }

    if (!todasSaoRoles) continue;

    // Padrão identificado com sucesso
    padroes_identificados.push_back(
        "[OK] RoleMixin Pattern (" + nomeClasse + ")"
    );
    }

    return {padroes_identificados, erros};
}
