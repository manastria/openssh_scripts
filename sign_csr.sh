#!/bin/bash
# File: sign_csr.sh

usage() {
    echo "Description :"
    echo "  Ce script permet de signer un Certificate Signing Request (CSR) avec une autorité de certification (CA) spécifiée."
    echo "  Si aucune CA n'est fournie, un certificat auto-signé sera généré."
    echo ""
    echo "Usage: $0 <common_name> [nom_fichier_ca]"
    echo "Arguments :"
    echo "  <common_name>       : Le nom du fichier CSR à signer."
    echo "  [nom_ca]            : (Optionnel) Le nom de la CA utilisée pour signer le CSR."
    echo "                        Si omis, un certificat auto-signé sera créé."
}

check_dependencies() {
    if ! command -v openssl &> /dev/null; then
        echo "Erreur : openssl n'est pas installé."
        exit 1
    fi
}

extract_common_name() {
    COMMON_NAME=$(openssl req -in "${CSR_NAME}.csr" -noout -subject | sed -n 's/.*CN *= *\([^ ,]*\).*/\1/p')
    echo "Common Name : ${COMMON_NAME}"
}

sign_with_ca() {
    openssl x509 -req \
        -in "${CSR_NAME}.csr" \
        -CA "${CA_NAME}_ca_cert.pem" \
        -CAkey "${CA_NAME}_ca_key.pem" \
        -CAcreateserial \
        -out "${COMMON_NAME}_cert.pem" \
        -days 365 -extfile ${COMMON_NAME}_openssl.cnf -extensions server_ext
    
    cat "${COMMON_NAME}_cert.pem" "${CA_NAME}_ca_cert.pem" > "${COMMON_NAME}_chain.pem"
}

create_self_signed() {
    openssl x509 -req \
        -in "${CSR_NAME}.csr" \
        -signkey "${CSR_NAME}_key.pem" \
        -out "${COMMON_NAME}_cert.pem"
    
    cp "${COMMON_NAME}_cert.pem" "${COMMON_NAME}_chain.pem"
}

export_pkcs12() {
    openssl pkcs12 -export \
        -inkey "${CSR_NAME}_key.pem" \
        -in "${COMMON_NAME}_cert.pem" \
        -certfile "${COMMON_NAME}_chain.pem" \
        -out "${COMMON_NAME}.p12" \
        -passout pass:
}

main() {
    if [[ "$#" -lt 1 ]]; then
        usage
        exit 1
    fi

    [ -f "./cert_config.cfg" ] && source "./cert_config.cfg"
    CSR_NAME="$1"
    CA_NAME="$2"

    check_dependencies
    extract_common_name

    if [[ -z "${COMMON_NAME}" ]]; then
        echo "Erreur : Le Common Name du CSR ne peut pas être vide."
        exit 1
    fi
    
    if [[ -n "${CA_NAME}" ]]; then
        sign_with_ca
    else
        create_self_signed
    fi
    
    export_pkcs12
    echo "Certificat généré avec succès."
}

main "$@"
