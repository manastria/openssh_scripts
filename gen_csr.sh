#!/bin/bash
# Fichier gen_csr.sh

# Aide pour l'utilisation du script
usage() {
  echo "Ce script génère une demande de signature de certificat (CSR) et la clé privée associée."
  echo "Les paramètres du certificat peuvent être définis dans le fichier de configuration 'cert_config.cfg'."
  echo ""
  echo "Usage: $0 <nom_du_fichier_csr>"
  echo ""
  echo "Arguments :"
  echo "  <nom_du_fichier_csr>    Le nom du fichier CSR."
  echo ""
  echo "Exemple :"
  echo "  $0 my_csr"
  exit 1
}

# Vérifie si un argument a été fourni pour le nom du fichier CSR
if [ "$#" -ne 1 ]; then
    usage
fi

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

# Nom du fichier CSR
CSR_NAME="$1"

# Paramètres pour le CSR (ces valeurs écraseront les valeurs du fichier de configuration s'il y en a)
COUNTRY="${COUNTRY:-FR}"
STATE="${STATE:-Ile-de-France}"
LOCALITY="${LOCALITY:-Paris}"
ORGANIZATION="${ORGANIZATION:-MonOrganisation}"
ORG_UNIT="${ORG_UNIT:-IT}"
COMMON_NAME="${COMMON_NAME:-www.example.com}"
EMAIL="${EMAIL:-admin@example.com}"

# Définition des SAN (Subject Alternative Names)
SAN="${SAN:-DNS:$COMMON_NAME,DNS:example.com,IP:192.168.0.1}"

# Création du fichier de configuration temporaire pour openssl
cat > ${CSR_NAME}_openssl.cnf <<EOL
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
countryName_default = $COUNTRY
countryName = Country

stateOrProvinceName_default = $STATE
stateOrProvinceName = State

localityName_default = Paris
localityName = Locality

organizationName_default = $ORGANIZATION
organizationName = Organization

organizationalUnitName_default = $ORG_UNIT
organizationalUnitName = Organizational Unit

commonName_default = $COMMON_NAME
commonName = Common Name

emailAddress_default = $EMAIL
emailAddress = Email Address

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = $SAN
EOL

# Génération de la clé privée
openssl genpkey -algorithm RSA -out "${CSR_NAME}_key.pem"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la génération de la clé privée."
    exit 1
fi


# Génération du CSR
openssl req -new \
    -key "${CSR_NAME}_key.pem" \
    -out "${CSR_NAME}.csr" \
    -config "${CSR_NAME}_openssl.cnf" \
    -batch
if [ $? -ne 0 ]; then
    echo "Erreur lors de la génération du CSR."
    exit 1
fi

# Nettoyage du fichier de configuration temporaire
rm ${CSR_NAME}_openssl.cnf
if [ $? -ne 0 ]; then
    echo "Erreur lors de la suppression du fichier de configuration temporaire."
    exit 1
fi

echo "CSR et clé privée générées avec succès."
