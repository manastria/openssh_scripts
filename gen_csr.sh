#!/bin/bash
# Fichier gen_csr.sh

# Utilisation de 'set -euo pipefail' pour un script bash plus sûr :
# -e : Arrête le script si une commande échoue
# -u : Arrête le script si une variable non définie est utilisée
# -o pipefail : Le script échoue si une commande dans un pipeline échoue (et pas seulement la dernière commande)
set -euo pipefail

display_message() {
  # $1 = message type (e.g., Error, Warning), $2 = message
  case "$1" in
    "Erreur")
      COLOR="\033[31m"  # Rouge
      ;;
    "Attention")
      COLOR="\033[33m"  # Jaune
      ;;
    *)
      COLOR="\033[0m"   # Par défaut (blanc)
      ;;
  esac
  
  echo -e "$COLOR$1: $2\033[0m" 1>&2
}

handle_error() {
  display_message "Erreur" "$1"
  exit 1
}

trap 'handle_error "Une erreur est survenue à la ligne $LINENO"' ERR

# Vérifier si OpenSSL est disponible
if ! command -v openssl &> /dev/null; then
    handle_error "OpenSSL n'est pas trouvé. Installez-le et réessayez."
fi

# Aide pour l'utilisation du script
usage() {
  echo "Ce script génère une demande de signature de certificat (CSR) et la clé privée associée."
  echo "Les paramètres du certificat peuvent être définis dans le fichier de configuration 'cert_config.cfg'."
  echo ""
  echo "Usage: $0 <common_name>"
  echo ""
  echo "Arguments :"
  echo "  <common_name>          Le nom du domaine pour le certificat."
  echo ""
  echo "Exemple :"
  echo "  $0 www.example.com"
  exit 1
}

# Vérifie si le premier argument a été fourni
[ "$#" -lt 1 ] && usage

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

# Le nom commun (CN) est le nom de domaine du certificat donc du serveur
COMMON_NAME="$1"

# Exemple de syntaxe : SAN="${SAN:-DNS:$COMMON_NAME,DNS:example.com,IP:192.168.0.1}"

# Paramètres pour le CSR (ces valeurs écraseront les valeurs du fichier de configuration s'il y en a)
COUNTRY="${COUNTRY:-FR}"
STATE="${STATE:-Ile-de-France}"
LOCALITY="${LOCALITY:-Paris}"
ORGANIZATION="${ORGANIZATION:-MonOrganisation}"
ORG_UNIT="${ORG_UNIT:-IT}"
EMAIL="${EMAIL:-admin@example.com}"


create_cnf_file() {
  # Crée un fichier de configuration pour la génération du certificat et CSR
  # Prend un nom commun (CN, ou le nom de domaine) en argument
  cat > "${1}_openssl.cnf" <<EOL
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
x509_extensions = v3_req
string_mask = MASK:0x2002
utf8 = yes
prompt = no

[req_distinguished_name]
0.C=${COUNTRY}
1.ST=${STATE}
2.L=${LOCALITY}
3.O=${ORGANIZATION}
4.OU=${ORG_UNIT}
5.CN=${1}
6.emailAddress=${EMAIL}

[v3_req]
nsComment=xca certificate
nsCertType=server
extendedKeyUsage=serverAuth
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, keyAgreement
subjectKeyIdentifier=hash
basicConstraints=critical,CA:FALSE
subjectAltName = @alt_names

[server_ext]
authorityKeyIdentifier = keyid,issuer
basicConstraints=critical,CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
nsCertType=server
nsComment=manastria certificate

[alt_names]
DNS.1   = ${1}
DNS.2   = www.${1}
EOL
}

generate_private_key() {
  # Génère une clé privée
  # Prend un nom commun (CN, ou le nom de domaine) en argument

  openssl genpkey -algorithm RSA -out "${1}_key.pem" || handle_error "La génération de la clé privée a échoué."
  chmod 600 "${1}_key.pem"
}

generate_csr() {
  # Génère une CSR (Certificate Signing Request)
  # Prend un nom commun (CN, ou le nom de domaine) en argument

  openssl req -new \
    -key "${1}_key.pem" \
    -out "${1}.csr" \
    -config "${1}_openssl.cnf" \
    -batch  || handle_error "La génération du CSR a échoué."
}

create_cnf_file "${COMMON_NAME}"
generate_private_key "${COMMON_NAME}"
generate_csr "${COMMON_NAME}"


# Vérification du CSR
openssl req -verify -in "${COMMON_NAME}.csr" -noout || handle_error "La vérification du CSR a échoué."


echo "CSR et clé privée générées avec succès."

