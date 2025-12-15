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

            // Ignora classes que não são subkind
            if (classe.estereotipo != "subkind") continue;

            // Deve especializar pelo menos uma classe
            if (classe.parents.empty()) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Subkind Pattern] '" + nomeClasse +
                    "' deve especializar um Kind ou Subkind."
                );
                continue;
            }

            // Verifica se herda de Kind ou Subkind
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

            // Erro se o pai não for Kind ou Subkind
            if (!paiRigido) {
                erros.push_back(
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

            // Exige genset se houver múltiplos subkinds
            if (generalTemMultiplosSubkinds) {
                bool participaDeGenset = false;

                // Verifica participação em algum genset
                for (const auto& g : gensets) {
                    if (contem(g.specifics, nomeClasse)) {
                        participaDeGenset = true;
                        break;
                    }
                }

                // Erro se não participar de genset
                if (!participaDeGenset) {
                    erros.push_back(
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
                // Subkind único não exige genset
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

            // 2. Participar de genset é OPCIONAL, não gera erro
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                + "[OK] Role Pattern (" + nomeClasse + ")"
            );
        }

        // 3. PHASE PATTERN
        bool existePhaseNoPacote = false;

        // Verifica se existe alguma phase no pacote
        for (const auto& [_, c] : classes) {
            if (c.estereotipo == "phase") {
                existePhaseNoPacote = true;
                break;
            }
        }

        if (existePhaseNoPacote) {

            // Percorre todos os gensets
            for (const auto& g : gensets) {

                // Verifica se a classe geral existe
                auto itGeneral = classes.find(g.general);
                if (itGeneral == classes.end()) {
                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Classe geral '" + g.general +
                        "' do genset '" + g.nome + "' não existe."
                    );
                    continue;
                }

                // Verifica se a classe geral é kind ou phase
                if (itGeneral->second.estereotipo != "kind" &&
                    itGeneral->second.estereotipo != "phase") {

                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Classe geral '" + g.general +
                        "' deve ser estereotipada como kind ou phase."
                    );
                    continue;
                }

                // Verifica se o genset é disjoint
                if (!contem(g.modifiers, "disjoint")) {
                    erros.push_back(
                        "[Linha " + to_string(g.linha) + "] "
                        + "[Phase Pattern] Genset '" + g.nome +
                        "' deve ser marcado como disjoint."
                    );
                    continue;
                }

                bool erro = false;

                // Valida as classes específicas do genset
                for (const auto& spec : g.specifics) {

                    // Verifica se a classe específica existe
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

                    // Verifica se a específica é phase
                    if (itSpec->second.estereotipo != "phase") {
                        erros.push_back(
                            "[Linha " + to_string(g.linha) + "] "
                            + "[Phase Pattern] Classe '" + spec +
                            "' deve ser estereotipada como phase."
                        );
                        erro = true;
                    }

                    // Verifica se a phase especializa a classe geral
                    if (!contem(itSpec->second.parents, g.general)) {
                        erros.push_back(
                            "[Linha " + to_string(g.linha) + "] "
                            + "[Phase Pattern] Phase '" + spec +
                            "' deve especializar diretamente '" + g.general + "'."
                        );
                        erro = true;
                    }
                }

                // Interrompe se houve erro nas específicas
                if (erro) continue;

                // Verifica cardinalidade mínima para genset complete
                if (contem(g.modifiers, "complete") && g.specifics.size() < 2) {
                    erros.push_back(
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

        // Ignora classes que não são relator
        if (classe.estereotipo != "relator") continue;

        // Contador de mediações válidas
        int mediacoesValidas = 0;

        // Percorre as relações internas do relator
        for (const auto& rel : classe.relacoes_internas) {

            // Verifica se a classe mediada existe
            auto it = classesGlobais.find(rel.target);
            if (it == classesGlobais.end()) {
                // Erro se a classe mediada não existir
                erros.push_back(
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
                // Erro de estereótipo inválido
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    "[Relator Pattern] O relator '" + nomeClasse +
                    "' media '" + rel.target +
                    "' com estereótipo inválido ('" + est +
                    "'). Esperado: role, kind ou subkind."
                );
            }
        }

        // Verifica se o relator possui pelo menos duas mediações válidas
        if (mediacoesValidas < 2) {
            erros.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                "[Relator Pattern] O relator '" + nomeClasse +
                "' deve possuir pelo menos 2 mediações (@mediation) válidas."
            );
        } else {
            // Relator identificado corretamente
            padroes_identificados.push_back(
                "[Linha " + to_string(classe.linha) + "] "
                "[OK] Relator Pattern (" + nomeClasse + ")"
            );
        }
        }
        
        // 5. MODE PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

            // Ignora classes que não são mode
            if (classe.estereotipo != "mode") continue;

            // Flags para verificar relações obrigatórias
            bool temCharacterization = false;
            bool temExternalDependence = false;

            // Percorre as relações internas da classe
            for (const auto& rel : classe.relacoes_internas) {
                // Percorre os estereótipos da relação
                for (auto s : rel.stereotypes) {
                    s = limpaStereo(s); // Normaliza o estereótipo
                    if (s == "characterization") temCharacterization = true;
                    if (s == "externalDependence") temExternalDependence = true;
                }
            }

            // Erro se não houver characterization
            if (!temCharacterization) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Mode Pattern] '" + nomeClasse +
                    "' deve possuir uma relação @characterization."
                );
            }

            // Erro se não houver externalDependence
            if (!temExternalDependence) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[Mode Pattern] '" + nomeClasse +
                    "' deve possuir uma relação @externalDependence."
                );
            }

            // Mode identificado corretamente
            if (temCharacterization && temExternalDependence) {
                padroes_identificados.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[OK] Mode Pattern (" + nomeClasse + ")"
                );
            }
        }

        // 6. ROLE MIXIN PATTERN
        for (const auto& [nomeClasse, classe] : classes) {

            // Ignora classes que não são roleMixin
            if (classe.estereotipo != "roleMixin") continue;

            // Ponteiro para o genset associado
            const Genset* gensetEncontrado = nullptr;

            // Procura um genset onde a classe seja geral
            for (const auto& g : gensets) {
                if (g.general == nomeClasse) {
                    gensetEncontrado = &g;
                    break;
                }
            }

            // Erro se não houver genset associado
            if (!gensetEncontrado) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] '" + nomeClasse +
                    "' deve ser a classe geral de um genset disjoint e complete."
                );
                continue;
            }

            // Verifica se o genset é disjoint
            bool isDisjoint = contem(gensetEncontrado->modifiers, "disjoint");
            // Verifica se o genset é complete
            bool isComplete = contem(gensetEncontrado->modifiers, "complete");

            // Erro se o genset não for disjoint e complete
            if (!isDisjoint || !isComplete) {
                erros.push_back(
                    "[Linha " + to_string(classe.linha) + "] "
                    + "[RoleMixin Pattern] Genset '" + gensetEncontrado->nome +
                    "' deve ser marcado como disjoint e complete."
                );
                continue;
            }

            // Flag para verificar se todos os específicos são roles
            bool todasSaoRoles = true;

            // Verifica os específicos do genset
            for (const auto& spec : gensetEncontrado->specifics) {
                auto itSpec = classes.find(spec);
                if (itSpec == classes.end() ||
                    itSpec->second.estereotipo != "role") {

                    // Erro se a específica não for role
                    erros.push_back(
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
        relatorios[nomePacote] = { padroes_identificados, erros };
    }

    return relatorios;
}

