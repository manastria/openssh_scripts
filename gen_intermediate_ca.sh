#!/bin/bash
# Fichier gen_intermediate_ca.sh

# Aide pour l'utilisation du script
usage() {
  echo "Ce script génère une clé privée et un certificat signé pour une autorité de certification (CA) intermédiaire."
  echo "Le certificat est signé par une CA racine spécifiée."
  echo "Les paramètres du certificat peuvent être définis dans le fichier de configuration 'cert_config.cfg'."
  echo ""
  echo "Usage: $0 <nom_fichier_ca_racine> <nom_fichier_ca_intermediaire>"
  echo ""
  echo "Arguments :"
  echo "  <nom_fichier_ca_racine>        Nom du fichier de la CA racine."
  echo "  <nom_fichier_ca_intermediaire> Nom du fichier de la CA intermédiaire."
  echo ""
  echo "Exemple :"
  echo "  $0 RootCA IntermediateCA"
  exit 1
}

# Vérifie si les deux arguments ont été fournis
if [ "$#" -ne 2 ]; then
    usage
fi

# Noms des fichiers
ROOT_CA_NAME="$1"
INTERMEDIATE_CA_NAME="$2"

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

# Paramètres du certificat (ces valeurs écraseront les valeurs du fichier de configuration s'il y en a)
COUNTRY="${COUNTRY:-FR}"
STATE="${STATE:-Ile-de-France}"
LOCALITY="${LOCALITY:-Paris}"
ORGANIZATION="${ORGANIZATION:-Mon Organisation}"
ORG_UNIT="${ORG_UNIT:-IT}"
EMAIL="${EMAIL:-admin@example.com}"
DAYS="${DAYS:-3650}"

# Génération de la clé privée de la CA intermédiaire
openssl genpkey -algorithm RSA -out "${INTERMEDIATE_CA_NAME}_key.pem"

# Génération du CSR pour la CA intermédiaire
openssl req -new \
    -key "${INTERMEDIATE_CA_NAME}_key.pem" \
    -out "${INTERMEDIATE_CA_NAME}.csr" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$INTERMEDIATE_CA_NAME/emailAddress=$EMAIL"

# Signature du certificat de la CA intermédiaire avec la CA racine
openssl x509 -req \
    -in "${INTERMEDIATE_CA_NAME}.csr" \
    -CA "${ROOT_CA_NAME}_ca_cert.pem" \
    -CAkey "${ROOT_CA_NAME}_ca_key.pem" \
    -CAcreateserial \
    -out "${INTERMEDIATE_CA_NAME}_cert.pem" \
    -days "$DAYS" \
    -extensions v3_ca

echo "CA intermédiaire signée avec succès."
