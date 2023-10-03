#!/bin/bash
# Fichier gen_csr.sh

# Aide pour l'utilisation du script
usage() {
  echo "Ce script génère une demande de signature de certificat (CSR) et la clé privée associée."
  echo "Les paramètres du certificat peuvent être définis dans le fichier de configuration 'cert_config.cfg'."
  echo ""
  echo "Usage: $0 <common_name> [san]"
  echo ""
  echo "Arguments :"
  echo "  <common_name>          Le nom du domaine pour le certificat."
  echo "  [san]                  Les Subject Alternative Names (optionnel)."
  echo ""
  echo "Exemple :"
  echo "  $0 www.example.com \"DNS:example.com,IP:192.168.0.1\""
  exit 1
}

# Vérifie si le premier argument a été fourni
if [ "$#" -lt 1 ]; then
    usage
fi

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

# Le nom commun (CN) est le nom de domaine du certificat donc du serveur
COMMON_NAME="$1"

# Si SAN est fourni en tant qu'argument, utilisez-le. Sinon, utilisez COMMON_NAME.
# Exemple de syntaxe : SAN="${SAN:-DNS:$COMMON_NAME,DNS:example.com,IP:192.168.0.1}"
if [ "$#" -ge 2 ]; then
    SAN="$2"
else
    SAN="DNS:$COMMON_NAME"
fi

# Paramètres pour le CSR (ces valeurs écraseront les valeurs du fichier de configuration s'il y en a)
COUNTRY="${COUNTRY:-FR}"
STATE="${STATE:-Ile-de-France}"
LOCALITY="${LOCALITY:-Paris}"
ORGANIZATION="${ORGANIZATION:-MonOrganisation}"
ORG_UNIT="${ORG_UNIT:-IT}"
EMAIL="${EMAIL:-admin@example.com}"

# Création du fichier de configuration temporaire pour openssl
cat > ${COMMON_NAME}_openssl.cnf <<EOL
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
countryName_default = $COUNTRY
countryName = Country

stateOrProvinceName_default = $STATE
stateOrProvinceName = State

localityName_default = $LOCALITY
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
openssl genpkey -algorithm RSA -out "${COMMON_NAME}_key.pem"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la génération de la clé privée."
    exit 1
fi

# Génération du CSR
openssl req -new \
    -key "${COMMON_NAME}_key.pem" \
    -out "${COMMON_NAME}.csr" \
    -config "${COMMON_NAME}_openssl.cnf" \
    -batch
if [ $? -ne 0 ]; then
    echo "Erreur lors de la génération du CSR."
    exit 1
fi

# Nettoyage du fichier de configuration temporaire
rm ${COMMON_NAME}_openssl.cnf
if [ $? -ne 0 ]; then
    echo "Erreur lors de la suppression du fichier de configuration temporaire."
    exit 1
fi

echo "CSR et clé privée générées avec succès."

