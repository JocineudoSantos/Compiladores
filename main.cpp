#include <iostream>
#include <fstream>
#include "FlexLexer.h"
using namespace std;

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

    string saida = string(argv[1]) + ".tok";
    ofstream out(saida);
    if (!out) {
        std::cerr << "não foi possivel criar o arquivo" << std::endl;
        return 1;
    }

    streambuf* old_cin = cin.rdbuf(in.rdbuf());
    streambuf* old_cout = cout.rdbuf(out.rdbuf());

    yyFlexLexer lexer;
    lexer.yylex();

    std::cin.rdbuf(old_cin);
    std::cout.rdbuf(old_cout);

    return 0;
}