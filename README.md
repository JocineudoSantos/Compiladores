# Analisador Sintático para Textual Ontology Language (TONTO)

## UNIVERSIDADE FEDERAL RURAL DO SEMI-ÁRIDO (UFERSA)
**Centro de Ciências Exatas e Naturais (CCEN)**  
**Departamento de Computação**  
**Disciplina:** Compiladores  
**Professor:** Patrício de Alencar Silva

## CRIADORES

- [@Jocineudo Santos](https://www.github.com/JocineudoSantos)
- [@Thais Aquino](https://github.com/ThaisAquin0)

---

## ESTRUTURA DO PROJETO
```bash
Compiladores/
│
├── lexico/ # Pasta que contem o analisado léxico da linguagem tonto.
│ ├── lexer.l # Arquivo principal do analisador léxico (Flex)
│ ├── main.cpp # Arquivo principal que executa o analisador
│ ├── CMakeLists.txt # Configuração de build (opcional)
│ └──  README.md # Documentação do projeto léxico
│ 
├── sintatico/ # Pasta que contem o analisador sintatico da linguagem tonto.
│ ├── parser.y # Arquivo principal do analisador sintatico.
│ ├── main.cpp # Arquivo principal que executa o analisador
│ ├── CMakeLists.txt # Configuração de build
│ ├── output/testes/ # Pasta com as saidas do analisador
│ ├── testes/ # Pasta com a saida do analisador lexico
│ └── teste.tonto # Um teste incluso da biblioteca do professor
│
└──  README.md # Documentação do projeto sintatico
```

## Projeto
**Objetivo:**  
Projetar um analisador sintático para verificação da estrutura de declaração de operadores da linguagem TONTO (Textual Ontology Language).

## Contextualização
Na primeira unidade da disciplina de Compiladores, a análise léxica consiste na identificação dos tipos de lexemas que compõem uma linguagem de máquina, seja procedural ou declarativa. Linguagens de definição de ontologias são declarativas: apenas informam o que as coisas são, sem conter métodos ou funções.

- **OWL (Web Ontology Language):** Baseada em XML, usada para definição de ontologias interpretáveis por agentes inteligentes.  
- **OntoUML:** Gráfica e apropriada para interpretação humana; inclui estereótipos para modelagem filosófica.  
- **TONTO (Textual Ontology Language):** Versão textual e declarativa de OntoUML; foco do estudo de caso da disciplina.  

Na análise léxica, foi criado um subconjunto da linguagem Tonto com regras específicas para lexemas de classes, relações, instâncias e outros elementos. Na análise sintática, o objetivo é guiar o ontologista a escrever estruturas corretas segundo regras de escopo e ordem.

## Descrição do Problema
O analisador sintático deve verificar a corretude da especificação textual de uma ontologia em TONTO, considerando:

1. **Declaração de Pacotes:** Define visões da ontologia. Ex.: cada modelo deve começar com a declaração de um pacote.  
2. **Declaração de Classes:** Classes são declaradas com estereótipos OntoUML (kind, subkind, role, phase, etc.) e podem ter atributos próprios.  
3. **Declaração de Tipos de Dados:** TONTO possui seis tipos nativos: `number`, `string`, `boolean`, `date`, `time` e `datetime`. É possível derivar tipos complexos.  
4. **Declaração de Classes Enumeradas:** Classes com conjunto finito de instâncias (e.g., dias da semana, cores dos olhos).  
5. **Generalizações (Generalization sets):** Estruturas hierárquicas de conceitos com suporte a disjunção e completude.  
6. **Declarações de Relações:** Podem ser internas ou externas às classes, com cardinalidade e símbolos específicos.

## Requisitos
- Uso de **BISON** para análise ascendente, em **C++** ou **Python**.  
- Testes disponíveis em: [https://github.com/patricioalencar/Compiladores_UFERSA](https://github.com/patricioalencar/Compiladores_UFERSA).  
- Repositório deve conter documentação adequada.  
- Saída da análise sintática deve incluir:  
  1. **Tabela de Síntese:** Resumo de construtos (pacotes, classes, relações, tipos, etc.)  
  2. **Relatório de Erros:** Com sugestões de tratamento.  
- **Vídeo explicativo de 5 minutos** é obrigatório.

## Referências
1. Coutinho, M. L. (2024). *Leveraging LLMs in text-based ontology-driven conceptual modeling*. [https://www.utwente.nl/en/eemcs/fois2024/resources/papers/coutinholeveraging-llms-in-text-based-ontology-driven-conceptual-modeling.pdf](https://www.utwente.nl/en/eemcs/fois2024/resources/papers/coutinholeveraging-llms-in-text-based-ontology-driven-conceptual-modeling.pdf)  
2. Coutinho, M. L., Almeida, J. P. A., Sales, T. P., & Guizzardi, G. (2024). *A Textual Syntax and Toolset for Well-Founded Ontologies*. FOIS 2024, 208-222.  
3. Lenke, M. *Tonto: A Textual Syntax for OntoUML*. [https://matheuslenke.github.io/tonto-docs/](https://matheuslenke.github.io/tonto-docs/)
   
##PREPARACAO DO AMBIENTE:
```bash
sudo apt update
sudo apt upgrade 
sudo apt install git
sudo apt install build-essential
sudo apt install g++ gdb
sudo apt install make cmake
sudo apt install flex
```
## EXTENÇÕES NECESSÁRIAS NO VSCODE:
```bash
Yash
C/C++
CMake
```

## COMANDOS NECESSÁRIOS:
```bash
Antes de tudo precisamos que o arquivo teste passe pelo lexico, como nao alteramos
o lexico para suportar mais de uma arquivo por vez, terá de fazer um por vez.


flex -o lexico/lex.yy.cc lexico/lexer.l 
g++ -o lexico/tonto_lexer lexico/lex.yy.cc lexico/main.cpp

Caso coloque o teste na pasta de testes
./lexico/tonto_lexer lexico/testes"example".tonto

Apos isso sera gerado dois arquivos, um permancerá no lexico
e o outro ira pro sintatico.

No sintatico basta seguir essas instrucoes:
Makefile foi configurado, entao basta dar
make

Caso nao funcione utilize esses comandos:
bison -d parser.y

Comando para compilar e criar o arquivo
g++ parser.tab.c main.cpp -std=c++17 -o parser

E por fim, faça o ./parser no diretorio que recebeu o arquivo de tokens do lexico
É essencial que esteja em uma pasta, assim foi configurado o sintatico.
./parser "./diretorio"

Diferente do lexico, ele ira pegar a pasta e era executar todos
(util para as linguagens com mais de 1 arquivo com o CarRental por exemplo).
Apos isso o arquivo de sair ira para o output/

```

