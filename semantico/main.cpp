#include <iostream>
#include "semantico.h"
#include <sstream>
#include <fstream>

using namespace std;

static string trim(string s) {
    s.erase(0, s.find_first_not_of(" \t"));
    s.erase(s.find_last_not_of(" \t") + 1);
    return s;
}

void gerar_relatorio_semantico(
    const Sintese& sintese,
    const vector<string>& padroes,
    const vector<string>& incompletos,
    const string& caminho_saida
) {
    ofstream out(caminho_saida);

    out << "---------------------------------------------\n";
    out << "        RELATÓRIO DE ANÁLISE SEMÂNTICA\n";
    out << "---------------------------------------------\n\n";

    for (const auto& [nomePacote, _] : sintese.pacotes) {

        out << "---------------------------------------------\n";
        out << "PACOTE: " << nomePacote << "\n";
        out << "---------------------------------------------\n\n";

        out << "[PADRÕES COMPLETOS IDENTIFICADOS]\n";
        bool achouPadrao = false;

        for (const auto& p : padroes) {
            if (p.find("[" + nomePacote + "]") != string::npos) {

                string msg = p.substr(p.find("]") + 2);

                size_t posLinha = msg.find("(linha");
                if (posLinha != string::npos) {
                    string linha = msg.substr(posLinha);
                    msg = msg.substr(0, posLinha);
                    out << "- [" << linha.substr(1, linha.size() - 2) << "] "
                        << msg << "\n";
                } else {
                    out << "- " << msg << "\n";
                }

                achouPadrao = true;
            }
        }

        if (!achouPadrao) {
            out << "- Nenhum padrão identificado neste pacote.\n";
        }

        out << "\n";

        out << "[PADRÕES INCOMPLETOS IDENTIFICADOS]\n";
        bool achouProblema = false;

        for (const auto& e : incompletos) {
            if (e.find("[" + nomePacote + "]") != string::npos) {

                string msg = e.substr(e.find("]") + 2);

                size_t posLinha = msg.find("(linha");
                if (posLinha != string::npos) {
                    string linha = msg.substr(posLinha);
                    msg = msg.substr(0, posLinha);
                    out << "- [" << linha.substr(1, linha.size() - 2) << "] "
                        << msg << "\n";
                } else {
                    out << "- " << msg << "\n";
                }

                achouProblema = true;
            }
        }

        if (!achouProblema) {
            out << "- Nenhum problema encontrado neste pacote.\n";
        }

        out << "\n";
    }

    out.close();
}


Sintese ler_relatorio(const string& caminho) {

    Sintese sintese;

    ifstream file(caminho);
    if (!file.is_open()) return sintese;

    string line;
    string pacoteAtual;
    string secaoAtual;

    Genset genset;
    bool lendoGenset = false;
    int linhaAtual = 0;

    while (getline(file, line)) {

        linhaAtual++;     
        line = trim(line);
        if (line.empty()) continue;

        // PACOTE
        if (line.rfind("PACOTE:", 0) == 0) {
            pacoteAtual = trim(line.substr(7));
            sintese.pacotes[pacoteAtual];
            secaoAtual.clear();
            continue;
        }
        // SEÇÃO
        if (line[0] == '[') {
            secaoAtual = line;
            continue;
        }

        // CLASSES
        if (secaoAtual == "[CLASSES]" && line[0] == '-') {

            // - Nome (stereotype=kind) | parents: A, B
            size_t pNomeFim = line.find('(');
            string nomeClasse = trim(line.substr(2, pNomeFim - 2));

            size_t pStereoIni = line.find("stereotype=");
            size_t pStereoFim = line.find(')', pStereoIni);
            string estereotipo = line.substr(
                pStereoIni + 11,
                pStereoFim - (pStereoIni + 11)
            );

            Classe& c = sintese.pacotes[pacoteAtual].classes[nomeClasse];
            c.estereotipo = estereotipo;
            c.linha = linhaAtual; 

            size_t pParents = line.find("parents:");
            if (pParents != string::npos) {
                string lista = line.substr(pParents + 8);
                stringstream ss(lista);
                string pai;
                while (getline(ss, pai, ',')) {
                    c.parents.push_back(trim(pai));
                }
            }
        }

        // RELAÇÕES INTERNAS
        else if (secaoAtual == "[RELAÇÕES INTERNAS]" && line[0] == '-') {

            // - source: A --(@mediation)--> B
            size_t pSource = line.find("source:");
            size_t pArrow = line.find("-->");
            size_t pStereo = line.find("(@");

            if (pSource == string::npos || pArrow == string::npos) continue;

            string source = trim(line.substr(pSource + 7, pStereo - (pSource + 7)));
            string target = trim(line.substr(pArrow + 3));

            string stereo;
            if (pStereo != string::npos) {
                stereo = line.substr(
                    pStereo + 2,
                    line.find(")", pStereo) - (pStereo + 2)
                );
            }

            RelacaoInterna r;
            r.target = target;
            r.linha = linhaAtual; 

            if (!stereo.empty())
                r.stereotypes.push_back(stereo);

            sintese.pacotes[pacoteAtual]
                .classes[source]
                .relacoes_internas
                .push_back(r);
        }

        // GENSETS
        else if (secaoAtual == "[GENSETS]") {

            if (line[0] == '-') {
                if (lendoGenset) {
                    sintese.pacotes[pacoteAtual].generalizacoes.push_back(genset);
                }
                genset = Genset{};
                genset.nome = trim(line.substr(2));
                genset.linha = linhaAtual;
                lendoGenset = true;
            }
            else if (line.find("general") != string::npos) {
                genset.general = trim(line.substr(line.find(':') + 1));
            }
            else if (line.find("specifics") != string::npos) {
                stringstream ss(line.substr(line.find(':') + 1));
                string x;
                while (getline(ss, x, ','))
                    genset.specifics.push_back(trim(x));
            }
            else if (line.find("modifiers") != string::npos) {
                stringstream ss(line.substr(line.find(':') + 1));
                string x;
                while (getline(ss, x, ','))
                    genset.modifiers.push_back(trim(x));
            }
        }
    }

    if (lendoGenset && !pacoteAtual.empty()) {
        sintese.pacotes[pacoteAtual].generalizacoes.push_back(genset);
    }

    return sintese;
}

int main(int argc, char* argv[]) {

    if (argc < 2) {
        cerr << "Uso: ./analisador <arquivo_sintatico.txt>\n";
        return 1;
    }

    string caminhoEntrada = argv[1];
    string nomeArquivo = caminhoEntrada;

    size_t posBarra = nomeArquivo.find_last_of("/\\");
    if (posBarra != string::npos) {
        nomeArquivo = nomeArquivo.substr(posBarra + 1);
    }

    size_t posUnderscore = nomeArquivo.find('_');
    if (posUnderscore != string::npos) {
        nomeArquivo = nomeArquivo.substr(0, posUnderscore);
    }

    string caminhoSaida = "output/" + nomeArquivo + "_relatorio_semantico.txt";
    
    Sintese sintese = ler_relatorio(caminhoEntrada);

    auto resultados_por_pacote = verificar_semantica_por_pacote(sintese);

    vector<string> padroes;
    vector<string> incompletos;

    for (const auto& [nomePacote, resultado] : resultados_por_pacote) {

        for (const auto& p : resultado.first)
            padroes.push_back("[" + nomePacote + "] " + p);

        for (const auto& e : resultado.second)
            incompletos.push_back("[" + nomePacote + "] " + e);
    }

    gerar_relatorio_semantico(
        sintese,
        padroes,
        incompletos,
        caminhoSaida
    );

    cout << "Relatório semântico gerado com sucesso em:\n"
         << caminhoSaida << endl;

    return 0;
}



