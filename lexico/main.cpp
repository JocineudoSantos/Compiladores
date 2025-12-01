#include <iostream>
#include <fstream>
#include "FlexLexer.h"
#include <filesystem>
namespace fs = std::filesystem;
using namespace std;

void finalize_lexer(const string& filename);

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cerr << "Uso: " << argv[0] << " arquivo.tonto" << endl;
        return 1;
    }

    ifstream in(argv[1]);
    if (!in) {
        cerr << "Arquivo n abriu n pae" << endl;
        return 1;
    }

    // Extrai apenas o nome do arquivo e remove o caminho
    string base = argv[1];
    fs::path p(base);
    std::string nameWithoutExt = p.stem().string(); // retorna o nome sem a extensão
    // Força saída dentro da pasta do módulo
    string saida = "sintatico/testes/" + nameWithoutExt + "_tokens.txt";

    ofstream out(saida);
    if (!out) {
        cerr << "não foi possivel criar o arquivo" << endl;
        return 1;
    }

    streambuf* old_cin = cin.rdbuf(in.rdbuf());
    streambuf* old_cout = cout.rdbuf(out.rdbuf());

    yyFlexLexer lexer;
    lexer.yylex();

    cin.rdbuf(old_cin);
    cout.rdbuf(old_cout);

    finalize_lexer(argv[1]);

    return 0;
}
