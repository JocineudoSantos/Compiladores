#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <dirent.h>
#include <filesystem>
#include <fstream>
#include <cstring>

using namespace std;
string currentFileName = ""; 
namespace fs = std::filesystem;
int yyparse(void);
FILE *tokenFile = nullptr;
extern void mapa();
extern void imprimirRelatorio(string dirName);
extern void imprimirErro();

struct ErrorInfo {
    int line;
    int col;
    string message;
    string suggestion;
};

void verificarECriarDiretorio(const fs::path &path);

extern vector<ErrorInfo> errorLog;
extern ofstream reportFile;

bool endsWith(const std::string &str, const std::string &suffix) {
    if (str.length() < suffix.length()) return false;
    return str.compare(str.length() - suffix.length(), suffix.length(), suffix) == 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <diretorio_com_tokens>\n", argv[0]);
        return 1;
    }

    const char *directoryPath = argv[1];
    DIR *dir = opendir(directoryPath);
    if (!dir) {
        perror("Erro ao abrir diretório");
        return 1;
    }

    struct dirent *entry;
    mapa();

    while((entry = readdir(dir)) != NULL) {

        string fileName = entry->d_name;

        if(fileName == "." || fileName == "..") continue;
        if(!endsWith(fileName, "tokens.txt")) continue;

        string fullPath;
        if(string(directoryPath).back() == '/')
            fullPath = string(directoryPath) + fileName;
        else
            fullPath = string(directoryPath) + '/' +  fileName;
        
        currentFileName = fullPath;

        printf("Abrindo o arquivo %s\n", fullPath.c_str());

        tokenFile = fopen(fullPath.c_str(), "r");
        if (!tokenFile) {
            perror(("Erro ao abrir arquivo: " + fullPath).c_str());
            continue;
        }

        yyparse();
        fclose(tokenFile);
        
    }

    fs::path directory = "output";
    
    if(directoryPath[strlen(directoryPath) - 1] == '/' || directoryPath[strlen(directoryPath) - 1] == '\\') {
        ((char*)directoryPath)[strlen(directoryPath) - 1] = '\0';
    }
    fs::path dirName = string(directoryPath).substr(string(directoryPath).find_last_of("/\\") + 1);

    verificarECriarDiretorio(directory);
    verificarECriarDiretorio("output/" / dirName);    

    if(errorLog.empty())
        imprimirRelatorio(dirName.string());
    else 
        imprimirErro();
    return 0;
}

void verificarECriarDiretorio(const fs::path &path) {
    try{
        if(!fs::exists(path)) {
            fs::create_directories(path);
        }
    }catch(const fs::filesystem_error &e) {
        fprintf(stderr, "Erro ao criar diretório: %s\n", e.what());
        exit(1);
    }

}
