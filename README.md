# Compiladores
Comandos necessários

flex lexer.l 

Para criar o arquivo lex.yy.cc

Comando para compilar e criar o arquivo executavel

g++ -o tonto_lexer lex.yy.cc main.cpp

Executar para criar a tabela

./tonto_lexer teste.tonto
