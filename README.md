# Analisador Semântico para Textual Ontology Language (TONTO)

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
│ ├── Example/ # Todos os exemplos do github do professor
│ └──  README.md # Documentação do projeto léxico
│ 
├── sintatico/ # Pasta que contem o analisador sintatico da linguagem tonto.
│ ├── parser.y # Arquivo principal do analisador sintatico.
│ ├── main.cpp # Arquivo principal que executa o analisador
│ ├── CMakeLists.txt # Configuração de build
│ ├── output/testes/ # Pasta com as saidas do analisador
│ ├── testes/ # Pasta com a saida do analisador lexico
│ ├── Example/ # Todos os exemplos do github do professor
│ └── teste.tonto # Um teste incluso da biblioteca do professor
│ └──  README.md # Documentação do projeto sintático
│
├── semantico # Pasta que contem o analisador semantico da linguagem tonto.
│ ├── semantico.cpp # Arquivo com o analisador semântico
│ ├── semantico.h # Arquivo com as definições
│ ├── main.cpp # Arquivo principal que executa o analisador
│ ├── Example/ # Todos os exemplos do github do professor
│ └── output/ # Saida do analisador semântico
│
└──  README.md # Documentação do projeto semântico
```

## Projeto
**Objetivo:**  
Projetar um analisador semântico para validação de padrões de projeto de ontologias (Ontology Design Patterns – ODPs) especificados na linguagem TONTO (Textual Ontology Language).

## Contextualização
No processo de compilação, a análise semântica é responsável por verificar se as construções da linguagem fazem sentido dentro de seu contexto, indo além da verificação estrutural realizada pelas análises léxica e sintática. Em linguagens declarativas, como as de definição de ontologias, a análise semântica é fundamental para garantir a coerência conceitual e lógica entre os elementos modelados.

Linguagens de ontologia descrevem o conhecimento de um domínio por meio de conceitos e relações, sem a definição de algoritmos. Nesse cenário, destacam-se:

- **OWL (Web Ontology Language):** Linguagem baseada em XML, amplamente utilizada para definição de ontologias interpretáveis por agentes inteligentes e sistemas de inferência.
- **OntoUML:** Linguagem gráfica voltada à modelagem conceitual, fundamentada em princípios ontológicos e filosóficos.
- **TONTO (Textual Ontology Language):** Linguagem textual e declarativa inspirada na OntoUML, utilizada como estudo de caso na disciplina de Compiladores.

Após a análise léxica, que identifica os lexemas da linguagem, e a análise sintática, que verifica a estrutura das declarações, a análise semântica tem como objetivo validar se os conceitos e relações definidos no código TONTO respeitam regras ontológicas mais profundas, especialmente aquelas associadas a padrões de projeto de ontologias.

## Descrição do Problema
O analisador semântico deve validar a especificação textual de uma ontologia escrita em TONTO, verificando a correta aplicação de padrões de projeto ontológicos (Ontology Design Patterns – ODPs), considerando:

1. **Subkind Pattern:** Verificação da especialização adequada de classes do tipo *kind*, garantindo herança semântica correta.
2. **Role Pattern:** Validação de papéis dependentes de contexto, assegurando a existência de entidades relacionais que os sustentem.
3. **Phase Pattern:** Análise de fases mutuamente exclusivas que representam estados temporais de um mesmo conceito.
4. **Relator Pattern:** Verificação da presença de entidades relacionais que conectam dois ou mais participantes.
5. **Mode Pattern:** Validação de modos que representam propriedades intrínsecas dependentes de uma entidade portadora.
6. **RoleMixin Pattern:** Análise de mixins aplicáveis a diferentes tipos de entidades que desempenham papéis semelhantes.

O analisador deve identificar padrões completos, detectar padrões incompletos ou incorretos e apontar inconsistências semânticas presentes na ontologia.

## Requisitos
- Implementação do analisador semântico em **C++** ou **Python**;
- Utilização dos testes disponibilizados em:  
  https://github.com/patricioalencar/Compiladores_UFERSA
- Repositório versionado no GitHub contendo documentação adequada;
- A saída da análise semântica deve incluir:
  1. **Padrões completos identificados** no código;
  2. **Padrões incompletos ou inválidos**, especialmente aqueles afetados por sobrecarregamento;
- Tratamento de erros semânticos utilizando **técnicas de coerção**, sempre que possível;
- Elaboração de um **vídeo explicativo com duração aproximada de 5 minutos** apresentando o funcionamento do analisador.

## Referências
1. Coutinho, M. L., Almeida, J. P. A., Sales, T. P., & Guizzardi, G. (2024). *A Textual Syntax and Toolset for Well-Founded Ontologies*. FOIS 2024, p. 208–222.
2. Lenke, M. *Tonto: A Textual Syntax for OntoUML*. Disponível em: https://matheuslenke.github.io/tonto-docs/
3. Ruy, F. B., Guizzardi, G., Falbo, R. A., Reginato, C. C., & Santos, V. A. (2017). *From reference ontologies to ontology patterns and back*. Data & Knowledge Engineering.

   
## PREPARACAO DO AMBIENTE:
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
Como existe a pasta example no semâmtico, basta compilar e executar um arquivo
g++ main.cpp semantico.cpp -o analisador

E utilizar em um arquivo, considerando que esteja na pasta compiladores/semantico
./analisador ./Example/"example"/"example"_Syntax_analysis.txt

O arquivo sera gerado na pasta output, lembrando que como nosso sintático junta os arquivos numa
análise completa, há apenas um arquivo na entrada do semântico (contendo todos os conteúdos dos arquivos de teste)
```



