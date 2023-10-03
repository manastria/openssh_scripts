#!/bin/bash
# Fichier gen_ca.sh

set -e  # Arrêter le script en cas d'erreur
set -u  # Arrêter le script si une variable non définie est utilisée

# Gestionnaire d'erreurs
handle_error() {
  echo -e "\033[31mUne erreur s'est produite lors de la génération du certificat. Opération interrompue.\033[0m" 1>&2
  echo -e "\033[31mErreur : $1\033[0m" 1>&2
  exit 1
}

# Aide pour l'utilisation du script
usage() {
  echo "Ce script génère une clé privée et un certificat auto-signé pour une autorité de certification (CA)."
  echo "Les paramètres du certificat peuvent être définis dans le fichier de configuration 'cert_config.cfg'."
  echo ""
  echo "Usage: $0 <nom_du_fichier_certificat>"
  echo ""
  echo "Arguments :"
  echo "  <nom_du_fichier_certificat>  Nom du fichier de sortie pour la clé privée et le certificat."
  echo ""
  echo "Exemple :"
  echo "  $0 MonCertificat"
  exit 1
}

# Vérifie si un argument a été fourni pour le nom du fichier de certificat
if [ "$#" -ne 1 ]; then
    usage
fi

# S'assurer qu'OpenSSL est installé
if ! command -v openssl &> /dev/null; then
  echo "Erreur: OpenSSL n'est pas installé."
  exit 1
fi

# Charger le fichier de configuration s'il existe et est lisible
CONFIG_FILE="./cert_config.cfg"
if [ -f "$CONFIG_FILE" ]; then
  if [ -r "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    echo "Erreur: Le fichier de configuration n'est pas lisible."
    exit 1
  fi
else
  echo "Attention: Le fichier de configuration n'existe pas."
fi

# Nom du fichier pour la clé privée et le certificat
CERT_NAME="$1"

# Paramètres du certificat (ces valeurs écraseront les valeurs du fichier de configuration s'il y en a)
COUNTRY="${COUNTRY:-FR}"
STATE="${STATE:-Ile-de-France}"
LOCALITY="${LOCALITY:-Paris}"
ORGANIZATION="${ORGANIZATION:-MonOrganisation}"
ORG_UNIT="${ORG_UNIT:-IT}"
EMAIL="${EMAIL:-admin@example.com}"
DAYS="${DAYS:-3650}"

# Génération de la clé privée de la CA
PRIVATE_KEY="${CERT_NAME}_ca_key.pem"
openssl genpkey -algorithm RSA -out "$PRIVATE_KEY" || handle_error "La génération de la clé privée a échoué."

# Sécurisez la clé privée
chmod 600 "$PRIVATE_KEY"

# Vérifiez si openssl.cnf est lisible
if [ ! -r "./openssl.cnf" ]; then
  echo "Erreur: Le fichier openssl.cnf n'est pas lisible."
  exit 1
fi

# Génération du certificat auto-signé de la CA
openssl req -new -x509 -days "$DAYS" \
    -key "$PRIVATE_KEY" \
    -out "${CERT_NAME}_ca_cert.pem" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=RootCA/emailAddress=$EMAIL" \
    -config ./openssl.cnf \
    -extensions ca_extensions || handle_error "La génération du certificat a échoué."

# Vérification du certificat
openssl verify -CAfile "${CERT_NAME}_ca_cert.pem" "${CERT_NAME}_ca_cert.pem" || handle_error "La vérification du certificat a échoué."


echo "Certificat et clé de l'autorité de certification générés avec succès."