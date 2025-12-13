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
    const vector<string>& erros,
    const string& caminho_saida
) {
    ofstream out(caminho_saida);

    out << "=============================================\n";
    out << "        RELATÓRIO DE ANÁLISE SEMÂNTICA\n";
    out << "=============================================\n\n";

    // ================= PADRÕES =================
    out << "[PADRÕES IDENTIFICADOS]\n";
    if (padroes.empty()) {
        out << "- Nenhum padrão identificado.\n";
    } else {
        for (const auto& p : padroes)
            out << "- " << p << "\n";
    }

    out << "\n";

    // ================= ERROS / AVISOS =================
    out << "[ERROS / AVISOS]\n";
    if (erros.empty()) {
        out << "- Nenhum erro ou aviso encontrado.\n";
    } else {
        for (const auto& e : erros)
            out << "- " << e << "\n";
    }

    out << "\n";
    out.close();
}

Sintese ler_relatorio(const string& caminho) {

    Sintese s;
    ifstream file(caminho);
    string line, secao;

    Genset genset;
    bool lendoGenset = false;

    while (getline(file, line)) {

        line = trim(line);
        if (line.empty()) continue;

        // detectar seção
        if (line[0] == '[') {
            secao = line;
            continue;
        }

       if (secao == "[CLASSES]" && line[0] == '-') {

            size_t p1 = line.find('(');
            size_t p2 = line.find(')');

            string nome = trim(line.substr(2, p1 - 2));
            string inside = line.substr(p1 + 1, p2 - p1 - 1);

            string stereo = inside.substr(inside.find('=') + 1);
            s.classes[nome].estereotipo = stereo;

            // -------- ler parents --------
            if (line.find("parents:") != string::npos) {
            size_t p = line.find("parents:");
            string rest = line.substr(p + 8);

            stringstream ss(rest);
            string parent;
            while (getline(ss, parent, ',')) {
                s.classes[nome].parents.push_back(trim(parent));
            }
            }

        }


        // ================= RELAÇÕES INTERNAS =================
        else if (secao == "[RELAÇÕES INTERNAS]" && line[0] == '-') {

            size_t sPos = line.find("source:");
            size_t ster = line.find("(@");
            size_t arrow = line.find("-->");

            if (sPos == string::npos || arrow == string::npos) continue;

            string source = trim(line.substr(sPos + 7, ster - (sPos + 7)));
            string target = trim(line.substr(arrow + 3));

            string stereo = "";
            if (ster != string::npos) {
                stereo = line.substr(
                    ster + 2,
                    line.find(")") - (ster + 2)
                );
            }

            s.classes[source].relacoes_internas.push_back(
                {{stereo}, target}
            );
        }

        // ================= GENSETS =================
        else if (secao == "[GENSETS]") {

            if (line[0] == '-') {
                if (lendoGenset)
                    s.generalizacoes.push_back(genset);

                genset = Genset{};
                genset.nome = trim(line.substr(2));
                lendoGenset = true;
            }
            else if (line.find("general") != string::npos) {
                genset.general =
                    trim(line.substr(line.find(':') + 1));
            }
            else if (line.find("specifics") != string::npos) {
                stringstream ss(
                    line.substr(line.find(':') + 1)
                );
                string x;
                while (getline(ss, x, ','))
                    genset.specifics.push_back(trim(x));
            }
            else if (line.find("modifiers") != string::npos) {
                stringstream ss(
                    line.substr(line.find(':') + 1)
                );
                string x;
                while (getline(ss, x, ','))
                    genset.modifiers.push_back(trim(x));
            }
        }
    }

    if (lendoGenset)
        s.generalizacoes.push_back(genset);

    return s;
}

int main() {

    Sintese sintese = ler_relatorio("testes/teste2_Syntax_analysis.txt");

    auto [padroes, erros] = verificar_semantica(sintese);

   gerar_relatorio_semantico(
        sintese,
        padroes,
        erros,
        "output/relatorio_semantico.txt"
    );

    cout << "Relatório semântico gerado com sucesso.\n";


    return 0;
}


