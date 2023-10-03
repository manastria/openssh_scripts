#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 fichier.pem"
  exit 1
fi

file="$1"

if [ -f "$file" ]; then
  # Vérifie si le fichier contient une clé privée
  if openssl rsa -inform PEM -in "$file" -noout -text > /dev/null 2>&1; then
    echo "Contenu du fichier $file : Clé privée"
    openssl rsa -inform PEM -in "$file" -noout -text
  # Vérifie si le fichier contient un certificat X.509
  elif openssl x509 -inform PEM -in "$file" -noout -text > /dev/null 2>&1; then
    echo "Contenu du fichier $file : Certificat X.509"
    openssl x509 -inform PEM -in "$file" -noout -text
  # Vérifie si le fichier contient un CSR (Certificate Signing Request)
  elif openssl req -inform PEM -in "$file" -noout -text > /dev/null 2>&1; then
    echo "Contenu du fichier $file : Certificate Signing Request (CSR)"
    openssl req -inform PEM -in "$file" -noout -text
  else
    echo "Le fichier $file ne semble pas être un fichier PEM valide."
  fi
else
  echo "Le fichier $file n'existe pas."
  exit 1
fi
