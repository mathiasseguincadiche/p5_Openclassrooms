#!/bin/bash
# =============================================================================
# SCRIPT : phase-4-livrables.sh
# DESCRIPTION : Phase 4 - Génération des livrables OpenClassrooms
# PROJET : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# Charger les utilitaires
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/checks.sh"
source "$(dirname "$0")/utils/prompts.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# =============================================================================
# VARIABLES GLOBALES
# =============================================================================

LIVRABLES_DIR="$PROJECT_DIR/dist/livrables"
DATE=$(date +%d%m%Y)
NOM="SEGUIN-CADICHE"
PRENOM="Mathias"

cd "$PROJECT_DIR" || exit 1

# Format conforme OpenClassrooms : NOM_Prenom_n°_nom_du_livrable_date
# Exemple : SEGUIN-CADICHE_Mathias_1_fichiers_terraform_02082026

# =============================================================================
# FONCTIONS
# =============================================================================

# Affiche l'aide
show_help() {
    echo ""
    title "AIDE : phase-4-livrables.sh"
    echo ""
    echo "Ce script génère les livrables au format OpenClassrooms."
    echo ""
    echo "Options :"
    echo "  --help, -h          Affiche cette aide"
    echo "  --auto, -a          Mode automatique (pas de confirmation)"
    echo "  --nom NOM          Spécifie le nom (défaut: $NOM)"
    echo "  --prenom PRENOM    Spécifie le prénom (défaut: $PRENOM)"
    echo ""
}

# Crée la structure des dossiers de livrables
create_livrables_structure() {
    step 1 "Création de la structure des livrables"

    info "Création des dossiers de livrables..."
    mkdir -p "$LIVRABLES_DIR/Exercice_1"
    mkdir -p "$LIVRABLES_DIR/Exercice_2"
    mkdir -p "$LIVRABLES_DIR/Exercice_3"

    success "Structure des livrables créée :"
    tree "$LIVRABLES_DIR" 2>/dev/null || find "$LIVRABLES_DIR" -type d | sed 's|[^/]*/|  |g'
}

# Copie les fichiers Terraform pour l'Exercice 1
copy_terraform_files() {
    step 2 "Copie des fichiers Terraform (Exercice 1)"

    TERRAFORM_SRC="$PROJECT_DIR/terraform/exercice-1"
    TERRAFORM_DST="$LIVRABLES_DIR/Exercice_1/${NOM}_${PRENOM}_1_fichiers_terraform_${DATE}"

    info "Copie des fichiers Terraform depuis $TERRAFORM_SRC..."
    mkdir -p "$TERRAFORM_DST"

    # Copier les fichiers Terraform
    for file in main.tf variables.tf outputs.tf terraform.tfvars.example; do
        if [ -f "$TERRAFORM_SRC/$file" ]; then
            cp "$TERRAFORM_SRC/$file" "$TERRAFORM_DST/"
            check "Fichier $file copié"
        else
            warning "Fichier $file introuvable dans $TERRAFORM_SRC"
        fi
    done

    success "Fichiers Terraform copiés vers $TERRAFORM_DST"
}

# Copie le playbook Ansible pour l'Exercice 1
copy_ansible_playbook() {
    step 3 "Copie du playbook Ansible (Exercice 1)"

    PLAYBOOK_SRC="$PROJECT_DIR/ansible/playbooks/deploy.yml"
    PLAYBOOK_DST="$LIVRABLES_DIR/Exercice_1/${NOM}_${PRENOM}_1_playbook_ansible_${DATE}.yml"

    info "Copie du playbook Ansible..."
    if [ -f "$PLAYBOOK_SRC" ]; then
        cp "$PLAYBOOK_SRC" "$PLAYBOOK_DST"
        success "Playbook Ansible copié vers $PLAYBOOK_DST"
    else
        error "Playbook Ansible introuvable : $PLAYBOOK_SRC"
        exit 1
    fi
}

# Copie les captures d'écran pour l'Exercice 2
copy_exercice_2_captures() {
    step 4 "Copie des captures d'écran (Exercice 2)"

    info "Recherche des captures d'écran..."

    # Vérifier si le dossier captures existe
    if [ -d "captures" ]; then
        info "Dossier 'captures' trouvé. Utilisation des captures automatiques."

        # Noms des fichiers de destination
        capture_names=(
            "${NOM}_${PRENOM}_2_dashboard_complet_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_donut_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_histogramme_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_histogramme_cumule_${DATE}.png"
        )

        # Noms des fichiers sources
        source_files=(
            "dashboard_complet_${DATE}.png"
            "diagramme_donut_${DATE}.png"
            "diagramme_histogramme_${DATE}.png"
            "diagramme_histogramme_cumule_${DATE}.png"
        )

        # Copier les captures depuis le dossier captures
        for i in {0..3}; do
            if [ -f "captures/${source_files[$i]}" ]; then
                cp "captures/${source_files[$i]}" "$LIVRABLES_DIR/Exercice_2/${capture_names[$i]}"
                check "Capture ${capture_names[$i]} copiée"
            else
                warning "Capture ${source_files[$i]} introuvable dans captures/"
            fi
        done

        success "Captures d'écran copiées depuis captures/ vers $LIVRABLES_DIR/Exercice_2/"
    else
        # Méthode originale : recherche dans le dossier courant
        info "Recherche des captures d'écran dans le dossier courant..."

        # Liste des fichiers PNG/JPG dans le dossier courant
        captures=$(find . -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | grep -E "(dashboard|diagramme|histogramme)" | head -4)

        if [ -z "$captures" ]; then
            warning "Aucune capture d'écran trouvée dans le dossier courant"
            info "Veuillez placer vos captures dans le dossier courant ou spécifier leur emplacement"

            # Proposer de générer les captures automatiquement
            if confirm "Voulez-vous essayer de générer les captures automatiquement ?"; then
                if [ -f "$(dirname "$0")/utils/capture-screenshots.sh" ]; then
                    info "Lancement du script de génération automatique des captures..."
                    bash "$(dirname "$0")/utils/capture-screenshots.sh" --auto

                    # Re-essayer la copie
                    copy_exercice_2_captures
                else
                    error "Le script capture-screenshots.sh n'existe pas"
                fi
            fi
            return 1
        fi

        # Noms des fichiers de destination
        capture_names=(
            "${NOM}_${PRENOM}_2_dashboard_complet_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_donut_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_histogramme_${DATE}.png"
            "${NOM}_${PRENOM}_2_diagramme_histogramme_cumule_${DATE}.png"
        )

        # Copier les captures
        i=0
        for capture in $captures; do
            if [ $i -lt 4 ]; then
                cp "$capture" "$LIVRABLES_DIR/Exercice_2/${capture_names[$i]}"
                check "Capture ${capture_names[$i]} copiée"
                i=$((i + 1))
            fi
        done

        success "Captures d'écran copiées vers $LIVRABLES_DIR/Exercice_2/"
    fi
}

# Copie le fichier haproxy.cfg pour l'Exercice 3
copy_haproxy_config() {
    step 5 "Copie du fichier haproxy.cfg (Exercice 3)"

    HAPROXY_SRC="$PROJECT_DIR/scripts/haproxy.cfg"
    HAPROXY_DST="$LIVRABLES_DIR/Exercice_3/${NOM}_${PRENOM}_3_haproxy_cfg_${DATE}.cfg"

    info "Copie du fichier haproxy.cfg..."
    if [ -f "$HAPROXY_SRC" ]; then
        sed -E 's/(stats auth [^:]+:).*/\1A_REMPLACER/' "$HAPROXY_SRC" > "$HAPROXY_DST"
        success "Fichier haproxy.cfg copié et mot de passe expurgé vers $HAPROXY_DST"
    else
        error "Fichier haproxy.cfg introuvable. Exécutez d'abord la Phase 3."
        exit 1
    fi
}

# Crée les fichiers de journal de session et décisions techniques
create_documentation_files() {
    step 6 "Création des fichiers de documentation"

    # Journal de session
    JOURNAL_FILE="$LIVRABLES_DIR/${NOM}_${PRENOM}_journal_session_${DATE}.md"
    info "Création du fichier de journal de session..."

    if [ ! -f "$JOURNAL_FILE" ]; then
        cat > "$JOURNAL_FILE" <<EOF
# Journal de session - Projet P5 OpenClassrooms
**Déployer et suivre l'infrastructure as code**

---

## 📅 Journal des actions

### 📌 [Date du jour]

| Heure | Action | Commande | Résultat |
|-------|--------|----------|----------|
|       |        |          |          |

---

### Exemple de structure à compléter :

### 📅 02/08/2026

| Heure      | Action                                      | Commande                          | Résultat                     |
|------------|---------------------------------------------|-----------------------------------|------------------------------|
| 10:00-11:00 | Configuration de l'environnement            | `./scripts/phase-0-preparation.sh` | À compléter                  |
| 11:00-12:00 | Validation locale                           | `./scripts/validate.sh` | À compléter                  |
| 14:00-18:00 | Exercice 1 : Terraform + Ansible + interface web | `./scripts/phase-1-terraform-ansible.sh` | À compléter          |

---

**Conseil** : Mettez à jour ce journal **après chaque session** pour ne rien oublier !
EOF
        check "Journal de session créé"
    else
        check "Journal de session déjà existant"
    fi

    # Décisions techniques
    DECISIONS_FILE="$LIVRABLES_DIR/${NOM}_${PRENOM}_decisions_techniques_${DATE}.md"
    info "Création du fichier de décisions techniques..."

    if [ ! -f "$DECISIONS_FILE" ]; then
        cat > "$DECISIONS_FILE" <<EOF
# Décisions techniques - Projet P5 OpenClassrooms

---

## 🏗️ Architecture

| Décision | Choix | Justification |
|----------|-------|---------------|
| Région AWS | us-east-1 | Région **obligatoire** pour le projet |
| Type d'instances (NGINX) | t2.micro | Suffisant et **gratuit** avec Free Tier |
| Type d'instances (OpenSearch) | t3.small.search | Taille du module pédagogique |
| Type d'instances (HAProxy) | t2.micro | Suffisant pour un load balancer de test |
| Algorithme HAProxy | roundrobin | **Équilibrage simple** et efficace |

---

## 🛠️ Outils

| Outil | Version | Justification |
|-------|---------|---------------|
| Terraform | v1.15+ | Version **stable et compatible** |
| Ansible | 2.15+ | Version **moderne** avec support complet |
| AWS CLI | 2.x.x | Version **récente** avec toutes les commandes |

---

## 📝 Décisions personnelles

| Décision | Choix | Justification | Alternatives envisagées |
|----------|-------|---------------|---------------------------|
| [À compléter] | [À compléter] | [À compléter] | [À compléter] |

---

**Conseil** : Documentez **toutes vos décisions techniques** ici pour justifier vos choix.
EOF
        check "Décisions techniques créées"
    else
        check "Décisions techniques déjà existantes"
    fi
}

# Crée le ZIP final
create_zip() {
    step 7 "Création du ZIP final"

    ZIP_FILE="P5_4091_Deployez_et_suivez_l_IaC_${NOM}_${PRENOM}.zip"

    info "Création du fichier ZIP : $ZIP_FILE"

    if command_exists zip; then
        if zip -r "$ZIP_FILE" "$LIVRABLES_DIR"; then
            success "Fichier ZIP créé : $ZIP_FILE"
            info "Taille du fichier : $(du -sh "$ZIP_FILE" 2>/dev/null)"
        else
            error "Échec de la création du ZIP"
            exit 1
        fi
    else
        error "zip n'est pas installé. Installez-le avec: sudo apt install -y zip"
        exit 1
    fi
}

# Affiche un résumé des livrables
show_summary() {
    step 8 "Résumé des livrables"

    echo ""
    title "RÉSUMÉ DES LIVRABLES"
    echo ""

    info "Dossier des livrables : $LIVRABLES_DIR/"
    echo ""

    # Lister les fichiers
    if [ -d "$LIVRABLES_DIR" ]; then
        info "Contenu du dossier :"
        find "$LIVRABLES_DIR" -type f | while read -r file; do
            size=$(du -h "$file" | cut -f1)
            echo "  ✅ $file ($size)"
        done
    fi

    echo ""
    info "Fichier ZIP : $ZIP_FILE"
    echo ""

    warning "⚠️ Vérifiez que tous les fichiers sont présents avant de livrer !"
    info "Format attendu :"
    info "  - Exercice_1 : fichiers Terraform + playbook Ansible"
    info "  - Exercice_2 : 4 captures d'écran"
    info "  - Exercice_3 : fichier haproxy.cfg"
    info "  - Journal de session et décisions techniques"
}

# =============================================================================
# PROGRAMME PRINCIPAL
# =============================================================================

# Gestion des options en ligne de commande
AUTO_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --auto|-a)
            AUTO_MODE=true
            BEGINNER_MODE=0
            shift
            ;;
        --nom)
            NOM="$2"
            shift 2
            ;;
        --prenom)
            PRENOM="$2"
            shift 2
            ;;
        *)
            error "Option inconnue : $1"
            show_help
            exit 1
            ;;
    esac
done

# Afficher l'en-tête
title "PHASE 4 : GÉNÉRATION DES LIVRABLES"
info "Durée estimée : 1h"
info "Objectif : Préparer les livrables conformes au format OpenClassrooms"
echo ""

# Mode automatique ou interactif
if [ "$AUTO_MODE" = true ]; then
    info "Mode automatique activé"
else
    info "Mode interactif activé (confirmation requise à chaque étape)"
    set_beginner_mode
fi

# Exécuter les étapes
create_livrables_structure
prompt_to_continue

copy_terraform_files
prompt_to_continue

copy_ansible_playbook
prompt_to_continue

copy_exercice_2_captures
prompt_to_continue

copy_haproxy_config
prompt_to_continue

create_documentation_files
prompt_to_continue

create_zip
prompt_to_continue

show_summary

echo ""
title "PHASE 4 TERMINÉE"
success "Livrables générés avec succès !"
info "Votre fichier ZIP est prêt à être livré : $ZIP_FILE"
info "Prochaine étape :"
info "  1. Vérifiez le contenu du ZIP"
info "  2. Livrez le fichier sur OpenClassrooms"
info "  3. Pensez à nettoyer vos ressources AWS (Phase 5)"
