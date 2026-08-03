#!/bin/bash
# Script de nettoyage

echo "Nettoyage des fichiers temporaires..."
rm -rf terraform/.terraform
rm -f terraform/*.tfstate
rm -f terraform/*.tfstate.*
rm -f .env

echo "✅ Nettoyage terminé"
