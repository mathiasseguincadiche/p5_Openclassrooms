#!/bin/bash
# Script de validation du projet

echo "=========================================="
echo "  Validation p5_Openclassrooms"
echo "=========================================="

ERRORS=0

# Valider YAML
echo "Validation des fichiers YAML..."
if command -v yamllint >/dev/null 2>&1; then
    yamllint ansible/playbooks/*.yml || ERRORS=$((ERRORS + 1))
else
    echo "yamllint non installé - installation recommandée"
fi

# Valider Terraform
echo "Validation des fichiers Terraform..."
cd terraform
terraform validate || ERRORS=$((ERRORS + 1))
terraform fmt -check || ERRORS=$((ERRORS + 1))
cd ..

# Valider la syntaxe des scripts
echo "Validation des scripts..."
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        bash -n "$script" || ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "✅ Tous les tests ont réussi!"
    exit 0
else
    echo "❌ $ERRORS erreur(s) trouvée(s)"
    exit 1
fi
