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

map<string, pair<vector<string>, vector<string>>>
verificar_semantica_por_pacote(const Sintese& sintese)
{

    map<string, pair<vector<string>, vector<string>>> relatorios;

    map<string, const Classe*> classesGlobais;

    for (const auto& [nomePacote, pacote] : sintese.pacotes) {
        for (const auto& [nomeClasse, classe] : pacote.classes) {
            classesGlobais[nomeClasse] = &classe;
        }
    }

    // PARA CADA PACOTE
    for (const auto& [nomePacote, pacote] : sintese.pacotes) {

        vector<string> padroes_identificados;
        vector<string> erros;

        const auto& classes = pacote.classes;
        const auto& gensets = pacote.generalizacoes;
        const auto& relacoes_externas = pacote.relacoes_externas;



        // 1. SUBKIND PATTERN
        map<string, vector<string>> subkindsPorGeneral;

        for (const auto& [nomeClasse, classe] : classes) {
            if (classe.estereotipo != "subkind") continue;

            for (const auto& pai : classe.parents) {
            subkindsPorGeneral[pai].push_back(nomeClasse);
            }
        }

        // Validação dos subkinds
        for (const auto& [nomeClasse, classe] : classes) {

        if (classe.estereotipo != "subkind") continue;

        // 1. Deve especializar alguém
        if (classe.parents.empty()) {
            erros.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                + "[Subkind Pattern] '" + nomeClasse +
                "' deve especializar um Kind ou Subkind."
            );
            continue;
        }

        // 2. Pai deve ser Kind ou Subkind
        bool paiRigido = false;

        for (const auto& pai : classe.parents) {
            auto itPai = classesGlobais.find(pai);
            if (itPai != classesGlobais.end()) {
                const string& estPai = itPai->second->estereotipo;
                if (estPai == "kind" || estPai == "subkind") {
                    paiRigido = true;
                }
            }
        }

        if (!paiRigido) {
            erros.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                "[Subkind Pattern] '" + nomeClasse +
                "' deve herdar de um Kind ou outro Subkind."
            );
            continue;
        }

        // 3. Verifica se o general possui múltiplos subkinds
        bool generalTemMultiplosSubkinds = false;
        for (const auto& pai : classe.parents) {
            if (subkindsPorGeneral[pai].size() >= 2) {
                generalTemMultiplosSubkinds = true;
            }
        }

        // 4. Se houver múltiplos subkinds → genset é obrigatório
        if (generalTemMultiplosSubkinds) {
            bool participaDeGenset = false;

            for (const auto& g : gensets) {
                if (contem(g.specifics, nomeClasse)) {
                    participaDeGenset = true;
                    break;
                }
            }

            if (!participaDeGenset) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Subkind Pattern] '" + nomeClasse +
                    "' especializa um general com múltiplos subkinds e deve participar de um genset."
                );
                continue;
            }

            // OK com genset
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                + "[OK] Subkind Pattern (" + nomeClasse + ")"
            );

        } else {
            // 5. Filho único → genset dispensado
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                + "[OK] Subkind Pattern (" + nomeClasse +
                ") — aceito por ser subkind único (genset dispensado)"
            );
        }
        }

        // 2. ROLE PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

            if (classe.estereotipo != "role") continue;

            // 1. Deve especializar um Kind
            if (classe.parents.empty()) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Role Pattern] '" + nomeClasse +
                    "' deve especializar um Kind."
                );
                continue;
            }

            // 2. Participar de genset é OPCIONAL → não gera erro
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                + "[OK] Role Pattern (" + nomeClasse + ")"
            );
        }

        // 3. PHASE PATTERN
        bool existePhaseNoPacote = false;
        for (const auto& [_, c] : classes) {
            if (c.estereotipo == "phase") {
                existePhaseNoPacote = true;
                break;
            }
        }

        if (existePhaseNoPacote) {

            for (const auto& g : gensets) {

                // Classe geral deve existir
                auto itGeneral = classes.find(g.general);
                if (itGeneral == classes.end()) {
                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Classe geral '" + g.general +
                        "' do genset '" + g.nome + "' não existe."
                    );
                    continue;
                }

                // Classe geral deve ser kind
                if (itGeneral->second.estereotipo != "kind" &&
                itGeneral->second.estereotipo != "phase") {

                erros.push_back(
                    "[Linha " + to_string(g.linha) + "] "
                    + "[Phase Pattern] Classe geral '" + g.general +
                    "' deve ser estereotipada como kind ou phase."
                );
                continue;
               }

                // Genset deve ser disjoint
                if (!contem(g.modifiers, "disjoint")) {
                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Genset '" + g.nome +
                        "' deve ser marcado como disjoint."
                    );
                    continue;
                }

                bool erro = false;

                // Específicas devem ser phase e especializar o general
                for (const auto& spec : g.specifics) {

                    auto itSpec = classes.find(spec);
                    if (itSpec == classes.end()) {
                        erros.push_back(
                            "[Linha " + to_string(g.linha) + "] "
                            + "[Phase Pattern] Classe '" + spec +
                            "' do genset '" + g.nome + "' não existe."
                        );
                        erro = true;
                        continue;
                    }

                    if (itSpec->second.estereotipo != "phase") {
                        erros.push_back(
                            "[Linha " + to_string(g.linha) + "] "
                            + "[Phase Pattern] Classe '" + spec +
                            "' deve ser estereotipada como phase."
                        );
                        erro = true;
                    }

                    if (!contem(itSpec->second.parents, g.general)) {
                        erros.push_back(
                            "[Linha " + to_string(g.linha) + "] "
                            + "[Phase Pattern] Phase '" + spec +
                            "' deve especializar diretamente '" + g.general + "'."
                        );
                        erro = true;
                    }
                }

                if (erro) continue;

                // COMPLETE: se declarado errado → erro
                if (contem(g.modifiers, "complete") && g.specifics.size() < 2) {
                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Genset '" + g.nome +
                        "' marcado como complete deve possuir ao menos duas phases."
                    );
                    continue;
                }

                // OK
                padroes_identificados.push_back(
                    "[Linha " + to_string(g.linha) + "] "
                    + "[OK] Phase Pattern (" + g.nome + ")"
                );
            }
        }

        // 4. RELATOR PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

        if (classe.estereotipo != "relator") continue;

        int mediacoesValidas = 0;

        for (const auto& rel : classe.relacoes_internas) {

            auto it = classesGlobais.find(rel.target);
            if (it == classesGlobais.end()) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Relator Pattern] O relator '" + nomeClasse +
                    "' media uma classe inexistente: '" + rel.target + "'."
                );
                continue;
            }

            const string& est = it->second->estereotipo;

            if (est == "role") {
                mediacoesValidas++;
            } else {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Relator Pattern] O relator '" + nomeClasse +
                    "' media '" + rel.target +
                    "' com estereótipo inválido ('" + est +
                    "'). Esperado: role, kind ou subkind."
                );
            }
        }

        if (mediacoesValidas < 2) {
            erros.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                "[Relator Pattern] O relator '" + nomeClasse +
                "' deve possuir pelo menos 2 mediações (@mediation) válidas."
            );
        } else {
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                "[OK] Relator Pattern (" + nomeClasse + ")"
            );
        }
        }
        
        // 5. MODE PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

            if (classe.estereotipo != "mode") continue;

            bool temCharacterization = false;
            bool temExternalDependence = false;

            for (const auto& rel : classe.relacoes_internas) {
                for (auto s : rel.stereotypes) {
                    s = limpaStereo(s);
                    if (s == "characterization") temCharacterization = true;
                    if (s == "externalDependence") temExternalDependence = true;
                }
            }

            if (!temCharacterization) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Mode Pattern] '" + nomeClasse +
                    "' deve possuir uma relação @characterization."
                );
            }

            if (!temExternalDependence) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Mode Pattern] '" + nomeClasse +
                    "' deve possuir uma relação @externalDependence."
                );
            }

            if (temCharacterization && temExternalDependence) {
                padroes_identificados.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[OK] Mode Pattern (" + nomeClasse + ")"
                );
            }
        }

        // 6. ROLE MIXIN PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

            if (classe.estereotipo != "roleMixin") continue;

            const Genset* gensetEncontrado = nullptr;

            for (const auto& g : gensets) {
                if (g.general == nomeClasse) {
                    gensetEncontrado = &g;
                    break;
                }
            }

            if (!gensetEncontrado) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] '" + nomeClasse +
                    "' deve ser a classe geral de um genset disjoint e complete."
                );
                continue;
            }

            bool isDisjoint = contem(gensetEncontrado->modifiers, "disjoint");
            bool isComplete = contem(gensetEncontrado->modifiers, "complete");

            if (!isDisjoint || !isComplete) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] Genset '" + gensetEncontrado->nome +
                    "' deve ser marcado como disjoint e complete."
                );
                continue;
            }

            bool todasSaoRoles = true;
            for (const auto& spec : gensetEncontrado->specifics) {
                auto itSpec = classes.find(spec);
                if (itSpec == classes.end() ||
                    itSpec->second.estereotipo != "role") {

                    erros.push_back(
                        "[Linha " + to_string(classe.linha) + "] "
                        + "[RoleMixin Pattern] A classe '" + spec +
                        "' deve ser estereotipada como role."
                    );
                    todasSaoRoles = false;
                }
            }

            if (todasSaoRoles) {
                padroes_identificados.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[OK] RoleMixin Pattern (" + nomeClasse + ")"
                );
            }
        }

        // SALVAR RELATÓRIO DO PACOTE
        relatorios[nomePacote] = { padroes_identificados, erros };
    }

    return relatorios;
}

