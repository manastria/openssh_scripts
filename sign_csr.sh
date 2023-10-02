#!/bin/bash
# File: sign_csr.sh

usage() {
    echo "Description :"
    echo "  Ce script permet de signer un Certificate Signing Request (CSR) avec une autorité de certification (CA) spécifiée."
    echo "  Si aucune CA n'est fournie, un certificat auto-signé sera généré."
    echo ""
    echo "Usage: $0 <nom_fichier_csr> [nom_fichier_ca]"
    echo "Arguments :"
    echo "  <nom_fichier_csr>       : Le nom du fichier CSR à signer."
    echo "  [nom_fichier_ca]        : (Optionnel) Le nom de la CA utilisée pour signer le CSR."
    echo "                            Si omis, un certificat auto-signé sera créé."
}

# Affichage de l'aide si aucun argument n'est fourni
if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

# Charger le fichier de configuration s'il existe
[ -f "./cert_config.cfg" ] && source "./cert_config.cfg"

# Nom du fichier CSR et éventuelle CA
CSR_NAME="$1"
CA_NAME="$2"

# Extraction du Common Name du CSR
COMMON_NAME=$(openssl req -in "${CSR_NAME}.csr" -noout -subject | sed -n 's/.*CN[[:space:]]*=[[:space:]]*\([a-zA-Z0-9\.\-]*\).*/\1/p')

# Afficher le Common Name du CSR
echo "Common Name : ${COMMON_NAME}"

# Vérifier que le Common Name du CSR est valide
if [ -z "$COMMON_NAME" ]; then
    echo "Erreur : Le Common Name du CSR ne peut pas être vide."
    exit 1
fi

# Si une CA est fournie
if [ ! -z "$CA_NAME" ]; then
    openssl x509 -req \
        -in "${CSR_NAME}.csr" \
        -CA "${CA_NAME}_ca_cert.pem" \
        -CAkey "${CA_NAME}_ca_key.pem" \
        -CAcreateserial \
        -out "${COMMON_NAME}_cert.pem"

    # Création de la chaîne de certificats
    cat "${COMMON_NAME}_cert.pem" "${CA_NAME}_ca_cert.pem" > "${COMMON_NAME}_chain.pem"

# Si aucune CA n'est fournie, création d'un certificat auto-signé
else
    openssl x509 -req \
        -in "${CSR_NAME}.csr" \
        -signkey "${CSR_NAME}_key.pem" \
        -out "${COMMON_NAME}_cert.pem"

    # Dans ce cas, la chaîne de certificat est simplement le certificat auto-signé
    cp "${COMMON_NAME}_cert.pem" "${COMMON_NAME}_chain.pem"
fi

# Export en format PKCS12
openssl pkcs12 -export \
    -inkey "${CSR_NAME}_key.pem" \
    -in "${COMMON_NAME}_cert.pem" \
    -certfile "${COMMON_NAME}_chain.pem" \
    -out "${COMMON_NAME}.p12" \
    -passout pass:

echo "Certificat généré avec succès."
