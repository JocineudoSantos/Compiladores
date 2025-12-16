#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <algorithm>
#include "semantico.h"

using namespace std;

// verifica se o elemento esta no vetor, gensets, disjoints ou complete
bool contem(const vector<string>& v, const string& s) {
    return find(v.begin(), v.end(), s) != v.end();
}

// remove o @ do estereotipo
string limpaStereo(string s) {
    if (!s.empty() && s[0] == '@') return s.substr(1);
    return s;
}

map<string, pair<vector<string>, vector<string>>>
verificar_semantica_por_pacote(const Sintese& sintese)
{

    map<string, pair<vector<string>, vector<string>>> relatorios;

    // Mapa global de classes para fácil acesso
    map<string, const Classe*> classesGlobais;

    for (const auto& [nomePacote, pacote] : sintese.pacotes) {
        for (const auto& [nomeClasse, classe] : pacote.classes) {
            classesGlobais[nomeClasse] = &classe;
        }
    }

    // Para cada pacote, verifica os padrões semânticos
    for (const auto& [nomePacote, pacote] : sintese.pacotes) {

        vector<string> padroes_identificados;
        vector<string> sugestao;

        const auto& classes = pacote.classes;
        const auto& gensets = pacote.generalizacoes;
        const auto& relacoes_externas = pacote.relacoes_externas;

        // 1. SUBKIND PATTERN
        map<string, vector<string>> subkindsPorGeneral;

        // Agrupa subkinds por classe geral
        for (const auto& [nomeClasse, classe] : classes) {
            if (classe.estereotipo != "subkind") continue;

            // Registra cada subkind por seu pai
            for (const auto& pai : classe.parents) {
                subkindsPorGeneral[pai].push_back(nomeClasse);
            }
        }

        // Validação dos subkinds
        for (const auto& [nomeClasse, classe] : classes) {

            if (classe.estereotipo != "subkind") continue;

            // Deve especializar pelo menos uma classe
            if (classe.parents.empty()) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Subkind Pattern] '" + nomeClasse +
                    "' deve especializar um Kind ou Subkind."
                );
                continue;
            }

            bool paiRigido = false;
            
           // Verifica se herda de Kind ou Subkind
            for (const auto& pai : classe.parents) {
                auto itPai = classesGlobais.find(pai);
                if (itPai != classesGlobais.end()) {
                    const string& estPai = itPai->second->estereotipo;
                    if (estPai == "kind" || estPai == "subkind") {
                        paiRigido = true;
                    }
                }
            }

            // Sugestão de correção se o pai não for Kind ou Subkind
            if (!paiRigido) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Subkind Pattern] '" + nomeClasse +
                    "' deve herdar de um Kind ou outro Subkind."
                );
                continue;
            }

            // Verifica se o general possui múltiplos subkinds
            bool generalTemMultiplosSubkinds = false;
            for (const auto& pai : classe.parents) {
                if (subkindsPorGeneral[pai].size() >= 2) {
                    generalTemMultiplosSubkinds = true;
                }
            }

            if (generalTemMultiplosSubkinds) {
                bool participaDeGenset = false;

                // Verifica participação em algum genset
                for (const auto& g : gensets) {
                    if (contem(g.specifics, nomeClasse)) {
                        participaDeGenset = true;
                        break;
                    }
                }

                if (!participaDeGenset) {
                    sugestao.push_back(
                        "[Linha " + to_string(classe.linha) + "] "
                        + "[Subkind Pattern] '" + nomeClasse +
                        "' especializa um general com múltiplos subkinds e deve participar de um genset."
                    );
                    continue;
                }

                // Subkind válido com genset
                padroes_identificados.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[OK] Subkind Pattern (" + nomeClasse + ")"
                );

            } else {
                // Subkind único não exige genset, logo é válido
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

            // Sugestão de correção se a classe não especializar um Kind
            if (classe.parents.empty()) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Role Pattern] '" + nomeClasse +
                    "' deve especializar um Kind."
                );
                continue;
            }

            // Participar de genset é OPCIONAL, não gera sugestão
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

            // Percorre todos os gensets
            for (const auto& g : gensets) {

                auto itGeneral = classes.find(g.general);
                if (itGeneral == classes.end()) {
                    sugestao.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Classe geral '" + g.general +
                        "' do genset '" + g.nome + "' não existe."
                    );
                    continue;
                }
                // a classe geral deve ser kind ou phase
                if (itGeneral->second.estereotipo != "kind" &&
                    itGeneral->second.estereotipo != "phase") {

                    sugestao.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Classe geral '" + g.general +
                        "' deve ser estereotipada como kind ou phase."
                    );
                    continue;
                }
                // genset deve ser disjoint obrigatorio caso seja complete
                if (!contem(g.modifiers, "disjoint")) {
                    sugestao.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Genset '" + g.nome +
                        "' deve ser marcado como disjoint."
                    );
                    continue;
                }
                // deve possuir ao menos duas phases
                if (contem(g.modifiers, "complete") && g.specifics.size() < 2) {
                    sugestao.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Genset '" + g.nome +
                        "' marcado como complete deve possuir ao menos duas phases."
                    );
                    continue;
                }

                // Phase Pattern identificado corretamente
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

        // Percorre as relações internas do relator
        for (const auto& rel : classe.relacoes_internas) {

            auto it = classesGlobais.find(rel.target);
            if (it == classesGlobais.end()) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Relator Pattern] O relator '" + nomeClasse +
                    "' media uma classe inexistente: '" + rel.target + "'."
                );
                continue;
            }

            // Obtém o estereótipo da classe mediada
            const string& est = it->second->estereotipo;

            // Verifica se o estereótipo é válido para mediação
            if (est == "role") {
                mediacoesValidas++;
            } else {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Relator Pattern] O relator '" + nomeClasse +
                    "' media '" + rel.target +
                    "' com estereótipo inválido ('" + est +
                    "'). Esperado: role."
                    
                );
                continue;
            }
        }

        if (mediacoesValidas < 2) {
            sugestao.push_back(
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
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Mode Pattern] '" + nomeClasse +
                    "' deve possuir uma relação @characterization."
                );
            }

            if (!temExternalDependence) {
                sugestao.push_back(
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

            // Procura um genset onde a classe seja geral
            for (const auto& g : gensets) {
                if (g.general == nomeClasse) {
                    gensetEncontrado = &g;
                    break;
                }
            }

            if (!gensetEncontrado) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] '" + nomeClasse +
                    "' deve ser a classe geral de um genset disjoint e complete."
                );
                continue;
            }


            bool isDisjoint = contem(gensetEncontrado->modifiers, "disjoint");
            bool isComplete = contem(gensetEncontrado->modifiers, "complete");

            if (!isDisjoint || !isComplete) {
                sugestao.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] Genset '" + gensetEncontrado->nome +
                    "' deve ser marcado como disjoint e complete."
                );
                continue;
            }

            bool todasSaoRoles = true;

            // Verifica os específicos do genset
            for (const auto& spec : gensetEncontrado->specifics) {
                auto itSpec = classes.find(spec);
                if (itSpec == classes.end() ||
                    itSpec->second.estereotipo != "role") {
                    sugestao.push_back(
                        "[Linha " + to_string(classe.linha) + "] "
                        + "[RoleMixin Pattern] A classe '" + spec +
                        "' deve ser estereotipada como role."
                    );
                    todasSaoRoles = false;
                }
            }

            // RoleMixin identificado corretamente
            if (todasSaoRoles) {
                padroes_identificados.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[OK] RoleMixin Pattern (" + nomeClasse + ")"
                );
            }
        }

        // salva o relatório do pacote
        relatorios[nomePacote] = { padroes_identificados, sugestao };
    }

    return relatorios;
}

