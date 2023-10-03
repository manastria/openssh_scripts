#!/bin/bash
# Fichier gen_ca.sh

set -e # Arrêter le script en cas d'erreur
set -u # Arrêter le script si une variable non définie est utilisée

handle_error() {
  echo -e "\033[31mErreur : $1\033[0m" 1>&2
  exit 1
}

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


verify_openssl_installed() {
  if ! command -v openssl &> /dev/null; then
    display_message "Erreur" "OpenSSL n'est pas installé."
    exit 1
  fi
}

verify_file_readable() {
  # $1 = file path
  if [ ! -r "$1" ]; then
    handle_error "Le fichier $1 n'est pas lisible."
  fi
}

load_config() {
  CONFIG_FILE="./cert_config.cfg"
  if [ -f "$CONFIG_FILE" ]; then
    verify_file_readable "$CONFIG_FILE"
    source "$CONFIG_FILE"
  else
    display_message "Attention" "Le fichier de configuration n'existe pas."
  fi
}

generate_private_key() {
  # $1 = key file path
  openssl genpkey -algorithm RSA -out "$1" || handle_error "La génération de la clé privée a échoué."
  chmod 600 "$1"
}

generate_self_signed_cert() {
  # $1 = key file path, $2 = cert file path
  openssl req -new -x509 -days "$DAYS" \
    -key "$1" \
    -out "$2" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=RootCA/emailAddress=$EMAIL" \
    -config ./openssl.cnf \
    -extensions ca_extensions || handle_error "La génération du certificat a échoué."
}

verify_cert() {
  # $1 = cert file path
  openssl verify -CAfile "$1" "$1" || handle_error "La vérification du certificat a échoué."
}

usage() {
  echo "Usage: $0 <nom_du_fichier_certificat>"
  # ... rest of the message
  exit 1
}

# Verifier si un argument est fourni
if [ "$#" -ne 1 ]; then
    usage
fi

CERT_NAME="$1"

verify_openssl_installed
load_config

PRIVATE_KEY="${CERT_NAME}_ca_key.pem"
CERT_FILE="${CERT_NAME}_ca_cert.pem"

generate_private_key "$PRIVATE_KEY"
generate_self_signed_cert "$PRIVATE_KEY" "$CERT_FILE"
verify_cert "$CERT_FILE"

echo "Certificat et clé de l'autorité de certification générés avec succès."
