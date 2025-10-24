### DISCIPLINA: Compiladores  
### PROFESSOR: Patrício de Alencar Silva  
### PROJETO: Analisador Léxico para Textual Ontology Language (TONTO)

## CRIADORES

- [@Jocineudo Santos](https://www.github.com/JocineudoSantos)
- [@Thais Aquino](https://github.com/ThaisAquin0)


---

## ESTRUTURA DO PROJETO
```bash
Compiladores/
├── lexer.l # Arquivo principal do analisador léxico (Flex)
├── main.cpp # Arquivo principal que executa o analisador
├── CMakeLists.txt # Configuração de build (opcional)
├── README.md # Documentação do projeto
└── teste.tonto # Um teste incluso da biblioteca do professor
```
___

## OBJETIVO
Projetar um analisador léxico para dar suporte à análise de corretude de uma ontologia especificada textualmente com a linguagem TONTO (Textual Ontology Language).


---

## CONTEXTUALIZAÇÃO

TONTO é o acrônimo para *Textual Ontology Language* (Linguagem de Ontologia Textual), sendo uma forma de especificar textualmente uma ontologia como artefato computacional.

Ontologias computacionais são grafos de conhecimento que conectam conceitos que possuem alguma relação de sentido, sendo normalmente especificadas em linguagens lógicas interpretáveis por máquina, como:
- **RDF (Resource Description Framework)** [1]
- **OWL (Web Ontology Language)** [2]

Essas ontologias são blocos fundamentais da Web 3.0 (Web Semântica), onde cada nó do grafo representa um recurso identificado por um **URI (Uniform Resource Identifier)**.
Quando recursos da Web (como vídeos, textos, imagens e códigos) são instanciados em uma ontologia, cria-se uma base de conhecimento dinâmica e extensível, capaz de ser interpretada por máquina para inferência de novas relações.

A Web 3.0 é a base das redes sociais, plataformas multimídia e comércio eletrônico.

---

## SOBRE A LINGUAGEM TONTO

Novas linguagens vêm sendo propostas para facilitar o entendimento e o uso de ontologias computacionais.  
Por exemplo:
- A linguagem **OntoUML**, proposta por Guizzardi et al. (2018) [3], que adiciona estereótipos lógicos e filosóficos aos modelos UML.
- O trabalho de Coutinho et al. (2024) [4], que propôs a **Textual Ontology Language (TONTO)** — uma forma textual e formalmente analisável de criar ontologias.

A TONTO permite:
- Criar módulos de ontologias (`.tonto`) no VSCode;
- Unir módulos com o **Tonto Package Manager** (`tonto.json`);
- Gerar formatos de saída como **JSON** e **gUFO** (serialização OWL compatível com Protégé);
- Importar arquivos externos em JSON e convertê-los em TONTO.

Mais informações estão disponíveis na monografia original de **Matheus Lenke** [5].

---

## DESCRIÇÃO DO PROBLEMA

Projetar um analisador léxico para a linguagem TONTO capaz de reconhecer os elementos principais da linguagem.  
O analisador deve identificar:

### Estereótipos de classe
`event`, `situation`, `process`, `category`, `mixin`, `phaseMixin`, `roleMixin`, `historicalRoleMixin`, `kind`, 
`collective`, `quantity`, `quality`, `mode`, `intrisicMode`, `extrinsicMode`, `subkind`, `phase`, `role`, `historicalRole`.

### Estereótipos de relações
`material`, `derivation`, `comparative`, `mediation`, `characterization`, `externalDependence`, `componentOf`, `memberOf`, 
`subCollectionOf`, `subQualityOf`, `instantiation`, `termination`, `participational`, `participation`, `historicalDependence`, 
`creation`, `manifestation`, `bringsAbout`, `triggers`, `composition`, `aggregation`, `inherence`, `value`, `formal`, `constitution`.

### Palavras reservadas
`genset`, `disjoint`, `complete`, `general`, `specifics`, `where`, `package`, `import`, `functional-complexes`.

### Símbolos especiais
`{`, `}`, `(`, `)`, `[`, `]`, `..`, `<>--`, `--<>`, `*`, `@`, `:`.

### Convenções
- **Classes:** iniciam com letra maiúscula, podem conter sublinhado, sem números.  
  Exemplo: `Person`, `Child`, `University`, `Second_Baptist_Church`.
- **Relações:** iniciam com letra minúscula, podem conter sublinhado, sem números.  
  Exemplo: `has`, `hasParent`, `is_part_of`.
- **Instâncias:** iniciam com letra, podem conter sublinhado e terminam com número inteiro.  
  Exemplo: `Planeta1`, `pizza03`, `pizza123`.

### Tipos de dados nativos
`number`, `string`, `boolean`, `date`, `time`, `datetime`.

### Novos tipos
Iniciam com letra, sem números, sem sublinhado e terminam com `DataType`.  
Exemplo: `CPFDataType`, `PhoneNumberDataType`.

### Meta-atributos
`ordered`, `const`, `derived`, `subsets`, `redefines`.

---

## REQUISITOS DO PROJETO

- Implementação automatizada com **LEX/FLEX ou PLY**.  
- Linguagens aceitas: **C++** ou **Python**.  
- Exemplos de teste: [Repositório do Professor](https://github.com/patricioalencar/Compiladores_UFERSA).  
- Saídas obrigatórias:
  1. **Visão analítica:** todos os tokens, com linha e coluna.
  2. **Tabela de síntese:** quantidades de classes, relações, palavras-chave, instâncias, palavras reservadas e meta-atributos.  
- **Tratamento de erros:** deve indicar a linha e sugerir correções (sem falhas não tratadas).  
- **Controle de versão:** atividade dos membros será verificada via GitHub.  
- **Apresentação obrigatória:** vídeo explicativo de 5 minutos.

---

## DIREÇÕES DE PESQUISA

- Estudar **LEX**, **FLEX** e **PLY**.  
- Elaborar **gramática da linguagem** e código principal para leitura e análise dos tokens.  
- Criar e testar **exemplos próprios** em TONTO.  
- Explorar a interoperabilidade entre:
  - **VSCode (extensão TONTO)**
  - **Visual Paradigm (plugin OntoUML)**
  - **Protégé (edição OWL/gUFO)**

---

## REFERÊNCIAS

1. W3C. (2025). *Resource Description Framework – Concepts and Abstract Data Model.*  
   Disponível em: [https://www.w3.org/TR/rdf12-concepts/](https://www.w3.org/TR/rdf12-concepts/)

2. W3C. (2012). *Web Ontology Language Conformance (Second Edition).*  
   Disponível em: [https://www.w3.org/TR/owl2-conformance/](https://www.w3.org/TR/owl2-conformance/)

3. Guizzardi, G. et al. (2018). *Endurant types in ontology-driven conceptual modeling: Towards OntoUML 2.0.*  
   *International Conference on Conceptual Modeling.* Springer.

4. Coutinho, M. L. et al. (2024). *A Textual Syntax and Toolset for Well-Founded Ontologies.*  
   *14th International Conference on Formal Ontology in Information Systems (FOIS 2024).* IOS Press.

5. Lenke, M. *Tonto: A Textual Syntax for OntoUML – A textual way for conceptual modeling.*  
   Disponível em: [https://matheuslenke.github.io/tonto-docs/](https://matheuslenke.github.io/tonto-docs/)

## PREPARAÇÃO DO AMBIENTE:
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
Para criar o lex.yy.cc
flex lexer.l 

Comando para compilar e criar o arquivo executavel
g++ -o tonto_lexer lex.yy.cc main.cpp

Para executar e criar os dois arquivos, os com tokens estará em um .tok, e a contagem em um .txt
./tonto_lexer "example".tonto
```
