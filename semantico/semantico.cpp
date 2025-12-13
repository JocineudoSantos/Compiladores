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

    // =========================================================================
    // 1. SUBKIND PATTERN
    // =========================================================================
    for (const auto& g : gensets) {
        auto it = classes.find(g.general);
        if (it == classes.end()) continue;

        if (it->second.estereotipo == "kind") {
            bool all_subkinds = true;

            for (const auto& spec : g.specifics) {
                auto itSpec = classes.find(spec);
                if (itSpec == classes.end()) continue;

                string stereo = itSpec->second.estereotipo;
                if (stereo != "subkind" && stereo != "kind") {
                    all_subkinds = false;
                }
            }

            if (all_subkinds && !g.specifics.empty()) {
                string nome = "Subkind Pattern (" + g.general + ")";
                if (contem(g.modifiers, "disjoint")) {
                    padroes_identificados.push_back("[OK] " + nome);
                } else {
                    erros.push_back(
                        "Erro no " + nome +
                        ": Genset '" + g.nome + "' deve ser disjoint. "
                        "-> Coerção: assumindo disjoint."
                    );
                    padroes_identificados.push_back("[COERGIDO] " + nome);
                }
            }
        }
    }

    // =========================================================================
    // 2. ROLE PATTERN
    // =========================================================================
    for (const auto& [nome, classe] : classes) {
    if (classe.estereotipo != "role") continue;

        for (const auto& parent : classe.parents) {
            auto it = classes.find(parent);
            if (it != classes.end() &&
                it->second.estereotipo == "kind") {

                padroes_identificados.push_back(
                    "[OK] Role Pattern (" + parent + " -> " + nome + ")"
                );
            }
        }
    }

    // =========================================================================
    // 3. PHASE PATTERN
    // =========================================================================
    for (const auto& g : gensets) {
        auto it = classes.find(g.general);
        if (it == classes.end()) continue;

        if (it->second.estereotipo == "kind") {
            bool all_phases = true;

            for (const auto& spec : g.specifics) {
                auto itSpec = classes.find(spec);
                if (itSpec == classes.end() ||
                    itSpec->second.estereotipo != "phase") {
                    all_phases = false;
                }
            }

            if (all_phases && !g.specifics.empty()) {
                string nome = "Phase Pattern (" + g.general + ")";
                if (contem(g.modifiers, "disjoint")) {
                    padroes_identificados.push_back("[OK] " + nome);
                } else {
                    erros.push_back(
                        "Erro no " + nome +
                        ": Genset '" + g.nome + "' deve ser disjoint. "
                        "-> Coerção aplicada."
                    );
                    padroes_identificados.push_back("[COERGIDO] " + nome);
                }
            }
        }
    }

    // =========================================================================
    // 4. RELATOR PATTERN
    // =========================================================================
    for (const auto& [nomeClasse, classe] : classes) {
        if (classe.estereotipo != "relator") continue;

        vector<string> roles;

        for (const auto& rel : classe.relacoes_internas) {
            for (auto s : rel.stereotypes) {
                if (limpaStereo(s) == "mediation") {
                    auto it = classes.find(rel.target);
                    if (it != classes.end() &&
                        it->second.estereotipo == "role") {
                        roles.push_back(rel.target);
                    } else {
                        erros.push_back(
                            "Erro no Relator Pattern '" + nomeClasse +
                            "': mediação inválida para '" + rel.target + "'. "
                            "-> Coerção aplicada."
                        );
                        roles.push_back(rel.target);
                    }
                }
            }
        }

        if (roles.size() >= 2) {
            bool has_material = false;

            for (const auto& relExt : relacoes_externas) {
                for (auto s : relExt.stereotypes) {
                    if (limpaStereo(s) == "material") {
                        if (contem(roles, relExt.source) &&
                            contem(roles, relExt.target)) {
                            has_material = true;
                        }
                    }
                }
            }

            string nome = "Relator Pattern (" + nomeClasse + ")";
            if (has_material) {
                padroes_identificados.push_back("[OK] " + nome);
            } else {
                padroes_identificados.push_back(
                    "[AVISO] " + nome +
                    ": relação material não encontrada."
                );
            }
        }
    }

    // =========================================================================
    // 5. MODE PATTERN
    // =========================================================================
    for (const auto& [nomeClasse, classe] : classes) {
        if (classe.estereotipo != "mode") continue;

        bool has_charac = false;
        bool has_ext_dep = false;

        for (const auto& rel : classe.relacoes_internas) {
            for (auto s : rel.stereotypes) {
                s = limpaStereo(s);
                if (s == "characterization") has_charac = true;
                if (s == "externalDependence") has_ext_dep = true;
            }
        }

        string nome = "Mode Pattern (" + nomeClasse + ")";
        if (has_charac && has_ext_dep) {
            padroes_identificados.push_back("[OK] " + nome);
        } else if (has_charac) {
            erros.push_back(
                "Padrão Mode '" + nomeClasse +
                "' incompleto. -> Coerção aplicada."
            );
            padroes_identificados.push_back("[PARCIAL] " + nome);
        }
    }

    // =========================================================================
    // 6. ROLE MIXIN PATTERN
    // =========================================================================
    for (const auto& [nomeClasse, classe] : classes) {
        if (classe.estereotipo != "roleMixin") continue;

        const Genset* genset_rm = nullptr;
        for (const auto& g : gensets) {
            if (g.general == nomeClasse) {
                genset_rm = &g;
                break;
            }
        }

        if (!genset_rm) continue;

        bool all_roles = true;
        for (const auto& spec : genset_rm->specifics) {
            auto it = classes.find(spec);
            if (it == classes.end() ||
                it->second.estereotipo != "role") {
                all_roles = false;
            }
        }

        if (all_roles) {
            string nome = "RoleMixin Pattern (" + nomeClasse + ")";
            if (contem(genset_rm->modifiers, "disjoint") &&
                contem(genset_rm->modifiers, "complete")) {
                padroes_identificados.push_back("[OK] " + nome);
            } else {
                erros.push_back(
                    "Erro no " + nome +
                    ": deve ser disjoint e complete. "
                    "-> Coerção aplicada."
                );
                padroes_identificados.push_back("[COERGIDO] " + nome);
            }
        }
    }

    return {padroes_identificados, erros};
}
