#!/bin/bash
# =============================================================================
# Script d'automatisation complète pour p5_Openclassrooms
# Ce script installe les dépendances, vérifie la structure et lance le projet
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction pour afficher un titre
print_title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Fonction pour afficher un succès
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher une erreur
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour afficher une info
print_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

# Fonction pour demander confirmation
confirm() {
    read -p "$1 (o/n) : " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Vérifier si on est root
if [ "$EUID" -eq 0 ]; then
    print_error "Ne pas exécuter en tant que root. Utilisez sudo si nécessaire pour les commandes d'installation."
    exit 1
fi

# Détecter la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    print_error "Impossible de détecter la distribution Linux."
    exit 1
fi

print_title "🚀 p5_Openclassrooms - Setup & Run Automatique"

# Étape 1: Installation des dépendances
print_title "Étape 1: Installation des dépendances"

if [ "$OS" = "fedora" ]; then
    print_info "Distribution détectée: Fedora $VERSION"
    
    # Mettre à jour le système
    print_info "Mise à jour du système..."
    sudo dnf update -y
    
    # Installer les dépendances de base
    print_info "Installation des dépendances de base..."
    sudo dnf install -y git curl wget unzip python3 python3-pip
    
    # Installer Terraform
    print_info "Installation de Terraform..."
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf install -y terraform
    
    # Installer Ansible
    print_info "Installation d'Ansible..."
    sudo dnf install -y ansible
    
    # Installer yamllint
    print_info "Installation de yamllint..."
    sudo dnf install -y yamllint
    
    print_success "Toutes les dépendances sont installées !"
    
elif [ "$OS" = "ubuntu" ]; then
    print_info "Distribution détectée: Ubuntu $VERSION"
    
    # Mettre à jour le système
    print_info "Mise à jour du système..."
    sudo apt update -y
    sudo apt upgrade -y
    
    # Installer les dépendances de base
    print_info "Installation des dépendances de base..."
    sudo apt install -y git curl wget unzip python3 python3-pip software-properties-common
    
    # Installer Terraform
    print_info "Installation de Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y terraform
    
    # Installer Ansible
    print_info "Installation d'Ansible..."
    sudo apt install -y ansible
    
    # Installer yamllint
    print_info "Installation de yamllint..."
    sudo apt install -y yamllint
    
    print_success "Toutes les dépendances sont installées !"
else
    print_error "Distribution non supportée: $OS. Ce script supporte Fedora et Ubuntu."
    exit 1
fi

# Vérifier les versions installées
print_title "Vérification des versions installées"
echo ""
terraform --version 2>/dev/null || print_error "Terraform n'est pas installé"
ansible --version 2>/dev/null | head -1 || print_error "Ansible n'est pas installé"
python3 --version 2>/dev/null || print_error "Python3 n'est pas installé"
yamllint --version 2>/dev/null || print_error "yamllint n'est pas installé"
echo ""

# Étape 2: Configuration AWS (optionnelle)
print_title "Étape 2: Configuration AWS (optionnelle)"

if confirm "Souhaitez-vous configurer AWS pour Terraform ?"; then
    print_info "Configuration des clés AWS..."
    
    if [ ! -d ~/.aws ]; then
        mkdir -p ~/.aws
    fi
    
    if [ ! -f ~/.aws/credentials ]; then
        read -p "Entrez votre AWS Access Key ID: " aws_access_key
        read -p "Entrez votre AWS Secret Access Key: " aws_secret_key
        
        cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $aws_access_key
aws_secret_access_key = $aws_secret_key
EOF
        chmod 600 ~/.aws/credentials
        print_success "Fichier ~/.aws/credentials créé"
    else
        print_info "Le fichier ~/.aws/credentials existe déjà. Utilisation de la configuration existante."
    fi
    
    if [ ! -f ~/.aws/config ]; then
        cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
        chmod 600 ~/.aws/config
        print_success "Fichier ~/.aws/config créé"
    else
        print_info "Le fichier ~/.aws/config existe déjà. Utilisation de la configuration existante."
    fi
else
    print_info "Configuration AWS ignorée. Vous devrez la configurer manuellement plus tard."
fi

# Étape 3: Clonage du dépôt (si ce n'est pas déjà fait)
print_title "Étape 3: Préparation du projet"

CURRENT_DIR=$(pwd)
PROJECT_DIR="$(dirname "$0")"

if [ "$CURRENT_DIR" != "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
fi

print_success "Dossier du projet: $(pwd)"

# Étape 4: Vérification de la structure
print_title "Étape 4: Vérification de la structure du projet"

echo "Vérification des dossiers..."
for dir in terraform ansible scripts docs; do
    if [ -d "$dir" ]; then
        print_success "Dossier $dir/ existe"
    else
        print_error "Dossier $dir/ MANQUANT"
        exit 1
    fi
done

echo ""
echo "Vérification des fichiers essentiels..."
for file in terraform/main.tf terraform/variables.tf terraform/outputs.tf ansible/playbooks/deploy.yml scripts/deploy.sh scripts/validate.sh scripts/clean.sh; do
    if [ -f "$file" ]; then
        print_success "Fichier $file existe"
    else
        print_error "Fichier $file MANQUANT"
        exit 1
    fi
done

# Étape 5: Validation du projet
print_title "Étape 5: Validation du projet"

print_info "Validation des scripts bash..."
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        if bash -n "$script"; then
            print_success "$script: syntaxe OK"
        else
            print_error "$script: erreur de syntaxe"
            exit 1
        fi
    fi
done

print_info "Validation YAML..."
if command -v yamllint >/dev/null 2>&1; then
    if yamllint ansible/playbooks/*.yml; then
        print_success "YAML: valide"
    else
        print_error "YAML: erreurs trouvées"
        exit 1
    fi
else
    print_info "yamllint non installé - validation YAML ignorée"
fi

print_info "Validation Terraform..."
cd terraform
if terraform validate; then
    print_success "Terraform: configuration valide"
else
    print_error "Terraform: erreurs de configuration"
    cd ..
    exit 1
fi

if terraform fmt -check; then
    print_success "Terraform: formatage correct"
else
    print_error "Terraform: problèmes de formatage"
    cd ..
    exit 1
fi
cd ..

print_success "✅ Toutes les validations ont réussi !"

# Étape 6: Options de déploiement
print_title "Étape 6: Options de déploiement"

echo ""
print_info "Que souhaitez-vous faire maintenant ?"
echo ""
echo "1) Lancer le déploiement complet (Terraform + Ansible)"
echo "2) Lancer uniquement la validation"
echo "3) Lancer uniquement le nettoyage"
echo "4) Quitter"
echo ""

read -p "Choisissez une option (1-4) : " option

case $option in
    1)
        print_title "Lancement du déploiement complet"
        if confirm "Êtes-vous sûr de vouloir lancer le déploiement ? (Cela peut créer des ressources AWS)"; then
            ./scripts/deploy.sh
        else
            print_info "Déploiement annulé"
        fi
        ;;
    2)
        print_title "Lancement de la validation"
        ./scripts/validate.sh
        ;;
    3)
        print_title "Lancement du nettoyage"
        if confirm "Êtes-vous sûr de vouloir nettoyer ?"; then
            ./scripts/clean.sh
        else
            print_info "Nettoyage annulé"
        fi
        ;;
    4)
        print_info "Au revoir !"
        exit 0
        ;;
    *)
        print_error "Option invalide"
        exit 1
        ;;
esac

print_title "✅ Setup & Run terminé !"
print_success "Votre projet p5_Openclassrooms est prêt à être utilisé."
print_info "Pour lancer manuellement :"
print_info "  - Déploiement: ./scripts/deploy.sh"
print_info "  - Validation: ./scripts/validate.sh"
print_info "  - Nettoyage: ./scripts/clean.sh"
