#!/bin/bash

# Cores
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Separador
SEPARATOR="${MAGENTA}=============================================================${RESET}"

# Função para mostrar status com cor
status(){
  echo -e "\n${CYAN}[*] $1...${RESET}"
}

# Função para exibir erro e sair
erro(){
  echo -e "${RED}[ERRO] $1${RESET}"
  exit 1
}

# Banner
banner(){
  echo -e "${BLUE}
 █████╗ ██╗   ██╗████████╗ ██████╗
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗
███████║██║   ██║   ██║   ██║   ██║
██╔══██║██║   ██║   ██║   ██║   ██║
██║  ██║╚██████╔╝   ██║   ╚██████╔╝
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝

██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝
                                           ${RESET}"

  echo -e "${YELLOW}           Automated Recon Script v1.0${RESET}"
  echo -e "${BLUE}          by JoaoOliveira - github.com/JoaoOliveira-Dev${RESET}"
  echo -e "$SEPARATOR"
}

# Verifica se o domínio foi fornecido
if [ -z "$1" ]; then
  erro "Uso: $0 dominio.com [diretorio_de_saida]"
fi

DOMINIO=$1
OUTPUT_DIR=${2:-"output_$DOMINIO"}

# Cria diretório de saída se não existir
mkdir -p "$OUTPUT_DIR"

banner

echo -e "${GREEN}Iniciando automação de Recon para: ${YELLOW}$DOMINIO${RESET}"
echo -e "${GREEN}Diretório de saída: ${YELLOW}$OUTPUT_DIR${RESET}"
echo -e "$SEPARATOR"

status "Executando subfinder completo"
subfinder -d "$DOMINIO" -all -recursive > "$OUTPUT_DIR/subdomain.txt"

status "Verificando subdomínios vivos com httpx"
cat "$OUTPUT_DIR/subdomain.txt" | httpx -ports 80,443,8080,8000,8888,8443,4445 -threads 200 > "$OUTPUT_DIR/subdomains_alive.txt"

status "Raspando URLs com katana"
katana -u "$OUTPUT_DIR/subdomains_alive.txt" -d 5 -kf -jc -fx -ef woff,css,png,svg,jpg,woff2,jpeg,gif,svg -o "$OUTPUT_DIR/allurls.txt"

status "Filtrando arquivos sensíveis"
cat "$OUTPUT_DIR/allurls.txt" | grep -E "\.txt|\.log|\.cache|\.secret|\.db|\.backup|\.yml|\.json|\.gz|\.rar|\.zip|\.config" > "$OUTPUT_DIR/sensitive_files.txt"
echo -e "${GREEN}[✔] Arquivos sensíveis salvos em $OUTPUT_DIR/sensitive_files.txt${RESET}"

status "Coletando arquivos JavaScript"
cat "$OUTPUT_DIR/allurls.txt" | grep -E "\.js$" > "$OUTPUT_DIR/js.txt"
echo -e "${GREEN}[✔] Arquivos JavaScript salvos em $OUTPUT_DIR/js.txt${RESET}"

echo -e "$SEPARATOR"
echo -e "${GREEN}[✔] Finalizado com sucesso!${RESET}"
echo -e "${BLUE}Arquivos gerados em: ${YELLOW}$OUTPUT_DIR${RESET}"
ls -1 "$OUTPUT_DIR" | sed "s/^/  - /"
echo -e "$SEPARATOR"
