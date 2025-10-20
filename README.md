# Compiladores
Projeto de um analisador léxico para a linguagem Tonto.

# Criadores

- [@Jocineudo Santos](https://www.github.com/JocineudoSantos)
- [@Thais Aquino](https://github.com/ThaisAquin0)

# Preparação do ambiente:
```bash
sudo apt update
sudo apt upgrade 
sudo apt install git
sudo apt install build-essential
sudo apt install g++ gdb
sudo apt install make cmake
sudo apt install flex
```
# Extenções necessárias no vscode:
```bash
Yash
C/C++
CMake
```

# Comandos necessários:
```bash
Para criar o lex.yy.cc
flex lexer.l 

Comando para compilar e criar o arquivo executavel
g++ -o tonto_lexer lex.yy.cc main.cpp

Para executar e criar os dois arquivos, os com tokens estará em um .tok, e a contagem em um .txt
./tonto_lexer "example".tonto
```