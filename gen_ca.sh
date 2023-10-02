#!/bin/bash
# Fichier gen_ca.sh


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

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

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
openssl genpkey -algorithm RSA -out "${CERT_NAME}_ca_key.pem"

# Génération du certificat auto-signé de la CA
openssl req -new -x509 -days "$DAYS" \
    -key "${CERT_NAME}_ca_key.pem" \
    -out "${CERT_NAME}_ca_cert.pem" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=RootCA/emailAddress=$EMAIL"

echo "Certificat et clé de l'autorité de certification générés avec succès."
