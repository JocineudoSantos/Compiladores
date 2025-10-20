# Compiladores
Projeto de um analisador léxico para a linguagem Tonto.

# Preparação do ambiente:
Instalar depedências
sudo apt update
sudo apt install git
sudo apt install build-essential
sudo apt install g++ gdb
sudo apt install make cmake
sudo apt install flex

# Extenções necessárias no vscode:
Yash
C/C++
CMake

# Comandos necessários:
// Para criar o lex.yy.cc
flex lexer.l 

//C omando para compilar e criar o arquivo executavel
g++ -o tonto_lexer lex.yy.cc main.cpp

// Para executar e criar os dois arquivos, os com tokens estará em um .tok, e a contagem em um .txt
./tonto_lexer "example".tonto
