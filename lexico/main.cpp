#include <iostream>
#include <fstream>
#include "FlexLexer.h"
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
    size_t pos = base.find_last_of("/\\");
    string filename = (pos == string::npos ? base : base.substr(pos + 1));

    // Força saída dentro da pasta do módulo
    string saida = "lexico/" + filename + ".tok";

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
