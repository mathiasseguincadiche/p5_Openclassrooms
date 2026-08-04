# 🚀 Automatisation Complète du Projet P5 OpenClassrooms

**Version 2.0** - Avec vérifications avancées, mode headless robuste et gestion d'erreur améliorée

Ce dossier contient des scripts pour **automatiser à 100%** le projet P5 "Déployez et suivez l'Infrastructure-as-Code grâce à Terraform, Ansible et un stack ELK".

## 📋 Tableau de Bord d'Automatisation

| Étape | Script | Automatisation | Intervention manuelle |
|-------|--------|----------------|----------------------|
| Phase 0 | `phase-0-preparation.sh` | ✅ 100% | ❌ Aucune |
| Phase 1 | `phase-1-terraform-ansible.sh` | ✅ 100% | ❌ Aucune |
| Phase 2 | `phase-2-opensearch-kibana.sh` | ✅ **98%** | ⚠️ Vérification visuelle du dashboard |
| Phase 3 | `phase-3-haproxy.sh` | ✅ 100% | ❌ Aucune |
| Phase 4 | `phase-4-livrables.sh` | ✅ **98%** | ⚠️ Vérification des captures |
| Phase 5 | `phase-5-nettoyage.sh` | ✅ 100% | ❌ Aucune |

**→ Objectif : 100% d'automatisation pour toutes les phases !**

---

## 🆕 Nouveautés de la Version 2.0

### ✨ Améliorations Majeures

1. **Vérifications Automatiques des Prérequis**
   - `kibana-api.sh` vérifie maintenant que les logs sont chargés avant de créer le dashboard
   - Attente automatique avec timeout configurable
   - Messages d'erreur clairs avec solutions

2. **Mode Headless Robuste**
   - `capture-screenshots.sh` supporte maintenant un mode `--headless` complet
   - Utilisation de Puppeteer pour les captures sans interface graphique
   - Installation automatique de Puppeteer si nécessaire
   - Gestion des erreurs améliorée

3. **Système de Health Checks**
   - Nouveau script `health-checks.sh` pour vérifier l'état de toutes les ressources
   - Vérification par phase ou globale
   - Mode rapide (`--quick`) pour les vérifications de base

4. **Validation Pré-Exécution**
   - `run-all.sh` valide maintenant les prérequis avant de commencer
   - Options `--validate` et `--health-check` pour une vérification complète
   - Mode `--force` pour ignorer les erreurs (à utiliser avec prudence)

5. **Gestion d'Erreur Améliorée**
   - Logging complet avec timestamps et niveaux de gravité
   - Fichiers de log dans `/tmp/p5_logs/`
   - Rapports d'erreur détaillés

---

## 📁 Nouveaux Scripts d'Automatisation

### 1. 🎨 `utils/kibana-api.sh v2.0` - Création Automatique du Dashboard Kibana

**Description** : Crée automatiquement le dashboard Kibana avec les 3 diagrammes obligatoires via l'API OpenSearch, avec vérifications avancées.

**Nouveautés v2.0** :

- ✅ Vérification automatique que l'index `nginx-access*` existe
- ✅ Vérification que l'index contient des données (> 0 documents)
- ✅ Vérification que tous les champs requis existent (`@timestamp`, `method`, `url`, `status`, `size`, `client_ip`)
- ✅ Attente automatique avec `--wait` (timeout: 300s par défaut)
- ✅ Gestion des dashboards existants (option `--force` pour écraser)
- ✅ Sauvegarde automatique des URLs dans `/tmp/`
- ✅ Logging complet avec `logging.sh`

**Utilisation** :

```bash
# Mode interactif
./scripts/utils/kibana-api.sh --url https://votre-opensearch-url/_dashboards

# Mode automatique
./scripts/utils/kibana-api.sh --url https://votre-opensearch-url/_dashboards --auto

# Mode automatique avec attente
./scripts/utils/kibana-api.sh --url https://... --auto --wait

# Forcer la recréation
./scripts/utils/kibana-api.sh --url https://... --auto --force
```

**Options** :

- `--url URL` : Spécifie l'URL de Kibana
- `--index-pattern PATTERN` : Spécifie l'index pattern (défaut: nginx-access*)
- `--dashboard-name NAME` : Spécifie le nom du dashboard (défaut: P5_NGINX_Logs_Dashboard)
- `--auto, -a` : Mode automatique (pas de confirmation)
- `--force, -f` : Force la création (écrase si existe)
- `--wait, -w` : Attend que les logs soient chargés (timeout: 300s)
- `--help, -h` : Affiche l'aide

**Exemple de sortie** :

```
✅ Index nginx-access* trouvé
✅ Index contient 150 documents
✅ Tous les champs requis sont présents
✅ Dashboard P5_NGINX_Logs_Dashboard créé
URL : https://.../app/dashboards#/view/abc123
```

---

### 2. 📸 `utils/capture-screenshots.sh v2.0` - Génération Automatique des Captures d'Écran

**Description** : Génère automatiquement les 4 captures d'écran pour l'Exercice 2, avec support headless complet.

**Nouveautés v2.0** :

- ✅ **Mode headless** avec Puppeteer pour les environnements sans GUI
- ✅ Installation automatique de Puppeteer et Node.js
- ✅ Vérification automatique que Kibana est accessible
- ✅ Vérification que le dashboard existe avant de prendre les captures
- ✅ Attente automatique avec `--wait`
- ✅ Gestion d'erreur améliorée avec logging
- ✅ Vérification des captures générées

**Utilisation** :

#### Mode GUI (avec interface graphique)

```bash
# Mode interactif
./scripts/utils/capture-screenshots.sh --url https://votre-kibana-url

# Mode automatique
./scripts/utils/capture-screenshots.sh --url https://votre-kibana-url --auto
```

#### Mode Headless (sans interface graphique)

```bash
# Installation des dépendances (une seule fois)
sudo apt install -y nodejs npm

# Exécution en mode headless
./scripts/utils/capture-screenshots.sh --url https://votre-kibana-url --headless --auto

# Avec attente
./scripts/utils/capture-screenshots.sh --url https://... --headless --auto --wait
```

**Options** :

- `--url URL` : Spécifie l'URL de Kibana
- `--nom NOM` : Spécifie le nom (défaut: SEGUIN-CADICHE)
- `--prenom PRENOM` : Spécifie le prénom (défaut: Mathias)
- `--auto, -a` : Mode automatique (pas de confirmation)
- `--headless` : Mode headless (sans interface graphique)
- `--wait, -w` : Attend que Kibana soit prêt
- `--help, -h` : Affiche l'aide

**Fichiers générés** :

- `{NOM}_{PRENOM}_2_dashboard_complet_{DATE}.png`
- `{NOM}_{PRENOM}_2_diagramme_donut_{DATE}.png`
- `{NOM}_{PRENOM}_2_diagramme_histogramme_{DATE}.png`
- `{NOM}_{PRENOM}_2_diagramme_histogramme_cumule_{DATE}.png`

**Prérequis pour le mode headless** :

- Node.js (v14+ recommandé)
- npm
- Puppeteer (installé automatiquement)
- Environnement avec accès internet pour télécharger Puppeteer

---

### 3. 🏥 `utils/health-checks.sh` - Système de Health Checks Global

**Description** : Vérifie l'état de santé de toutes les ressources du projet P5.

**Fonctionnalités** :

- ✅ Vérification des outils de base (Terraform, AWS CLI, Git, Ansible, curl, jq)
- ✅ Vérification des fichiers du projet (scripts, configurations)
- ✅ Vérification par phase (0 à 5)
- ✅ Vérification des ressources déployées (OpenSearch, Kibana, HAProxy)
- ✅ Vérification des logs chargés dans OpenSearch
- ✅ Vérification des captures d'écran générées
- ✅ Vérification des livrables
- ✅ Rapport détaillé avec statistiques

**Utilisation** :

```bash
# Vérifier tout
./scripts/utils/health-checks.sh

# Vérifier tout en mode automatique
./scripts/utils/health-checks.sh --auto

# Vérifier une phase spécifique
./scripts/utils/health-checks.sh --phase 2

# Mode rapide (vérifications de base seulement)
./scripts/utils/health-checks.sh --quick --auto

# Avec attente
./scripts/utils/health-checks.sh --wait --auto
```

**Options** :

- `--auto, -a` : Mode automatique (pas de confirmation)
- `--phase PHASE` : Vérifie seulement une phase spécifique (0-5)
- `--quick` : Mode rapide (vérifications de base seulement)
- `--wait, -w` : Attend que les ressources soient prêtes
- `--help, -h` : Affiche l'aide

**Exemple de sortie** :

```
=== RAPPORT DE SANTÉ DU PROJET P5 ===

✅ Phase 0 : Préparation - OK
✅ Phase 1 : Terraform+Ansible - OK
✅ Phase 2 : OpenSearch+Kibana - OK
✅ Phase 3 : HAProxy - OK
⚠️  Phase 4 : Livrables - Incomplet (captures manquantes)
✅ Phase 5 : Nettoyage - OK

Statistiques : 5/6 phases réussies
```

---

### 4. 🔄 `run-all.sh v2.0` - Script "One-Click" pour Tout le Projet

**Description** : Exécute automatiquement toutes les phases du projet de A à Z, avec validation pré-exécution.

**Nouveautés v2.0** :

- ✅ Validation automatique des prérequis avant exécution
- ✅ Intégration des health checks (`--health-check`)
- ✅ Mode `--validate` pour vérifier sans exécuter
- ✅ Mode `--force` pour ignorer les erreurs
- ✅ Attente automatique avec `--wait`
- ✅ Logging complet avec timestamps
- ✅ Rapports d'erreur détaillés

**Utilisation** :

```bash
# Exécuter tout le projet en mode interactif
./scripts/run-all.sh

# Exécuter tout le projet en mode automatique
./scripts/run-all.sh --auto

# Exécuter seulement les phases 2 à 4
./scripts/run-all.sh --from 2 --to 4

# Exécuter à partir de la phase 3
./scripts/run-all.sh --from 3 --auto

# Valider les prérequis sans exécuter
./scripts/run-all.sh --validate

# Exécuter les health checks puis le projet
./scripts/run-all.sh --health-check --auto

# Forcer l'exécution même si des erreurs sont détectées
./scripts/run-all.sh --auto --force

# Attendre que les ressources soient prêtes
./scripts/run-all.sh --auto --wait
```

**Options** :

- `--auto, -a` : Mode automatique (pas de confirmation)
- `--from PHASE` : Commence à partir de la phase spécifiée (0-5)
- `--to PHASE` : Termine à la phase spécifiée (0-5)
- `--validate, -v` : Valide les prérequis avant exécution
- `--health-check, -c` : Exécute les health checks avant de commencer
- `--force, -f` : Force l'exécution même si des erreurs sont détectées
- `--wait, -w` : Attend que les ressources soient prêtes
- `--help, -h` : Affiche l'aide

---

### 5. 📝 `utils/logging.sh` - Système de Logging

**Description** : Fournit des fonctions de logging pour suivre l'avancement du projet.

**Fonctionnalités** :

- Logging avec timestamp et niveaux (INFO, SUCCESS, WARNING, ERROR, DEBUG)
- Stockage des logs dans `/tmp/p5_logs/`
- Affichage des statistiques des logs
- Nettoyage automatique des anciens logs (> 7 jours)

**Utilisation** :

```bash
# Dans vos scripts, sourcez le fichier
source ./scripts/utils/logging.sh

# Puis utilisez les fonctions
init_logging
log_info "Début de l'exécution"
log_success "Phase terminée avec succès"
log_error "Une erreur est survenue"
log_warning "Attention, problème détecté"

# Afficher les logs
./scripts/utils/logging.sh --show

# Afficher les statistiques
./scripts/utils/logging.sh --stats

# Nettoyer les anciens logs
./scripts/utils/logging.sh --clean
```

---

## 🔧 Intégration avec les Scripts Existants

### Modifications apportées à `phase-2-opensearch-kibana.sh`

Le script a été mis à jour pour :

1. ✅ Proposer la création automatique du dashboard via `kibana-api.sh`
2. ✅ Conserver la possibilité de créer le dashboard manuellement
3. ✅ Afficher des instructions claires pour les deux méthodes
4. ✅ Sauvegarder automatiquement l'URL de Kibana dans `/tmp/kibana_url.txt`

**Nouveau flux** :

```
1. Le script demande si vous voulez utiliser l'API pour créer le dashboard
2. Si oui, il exécute automatiquement kibana-api.sh avec vérifications
3. Si non, il affiche les instructions manuelles
4. Dans les deux cas, l'URL est sauvegardée pour les autres scripts
```

### Modifications apportées à `phase-4-livrables.sh`

Le script a été mis à jour pour :

1. ✅ Rechercher d'abord les captures dans le dossier `captures/`
2. ✅ Si le dossier existe, utiliser les captures automatiques
3. ✅ Sinon, proposer de générer les captures avec `capture-screenshots.sh`
4. ✅ Conserver la méthode originale de recherche dans le dossier courant
5. ✅ Gérer les erreurs de manière plus robuste

**Nouveau flux** :

```
1. Le script vérifie si le dossier captures/ existe
2. Si oui, il copie les captures depuis ce dossier
3. Si non, il propose de générer les captures automatiquement
4. Sinon, il utilise la méthode originale
5. En cas d'erreur, il affiche des messages clairs
```

---

## 📊 Workflow Recommandé

### Pour un déploiement complet automatique (avec environnement graphique)

```bash
# 1. Préparer l'environnement
./scripts/phase-0-preparation.sh --auto

# 2. Déployer Terraform + Ansible
./scripts/phase-1-terraform-ansible.sh --auto

# 3. Déployer OpenSearch + Kibana + Dashboard
./scripts/phase-2-opensearch-kibana.sh --auto
# Le script proposera de créer le dashboard automatiquement

# 4. Déployer HAProxy
./scripts/phase-3-haproxy.sh --auto

# 5. Générer les captures d'écran (mode GUI)
./scripts/utils/capture-screenshots.sh --auto

# 6. Générer les livrables
./scripts/phase-4-livrables.sh --auto

# 7. Nettoyer (optionnel)
./scripts/phase-5-nettoyage.sh --auto
```

### Pour un déploiement complet en mode headless (sans GUI)

```bash
# 1. Installer les dépendances headless
sudo apt update && sudo apt install -y nodejs npm

# 2. Exécuter tout le projet
./scripts/run-all.sh --auto --wait

# 3. Générer les captures en mode headless
./scripts/utils/capture-screenshots.sh --headless --auto --wait

# 4. Générer les livrables
./scripts/phase-4-livrables.sh --auto
```

### Pour un déploiement avec validation complète

```bash
# 1. Vérifier l'état du projet
./scripts/utils/health-checks.sh --auto

# 2. Exécuter les health checks
./scripts/utils/health-checks.sh --phase 2 --auto

# 3. Exécuter le projet avec validation
./scripts/run-all.sh --validate --health-check --auto
```

### Ou en une seule commande (recommandé)

```bash
# Exécuter tout le projet avec validation et health checks
./scripts/run-all.sh --validate --health-check --auto --wait
```

---

## 🎯 Bonnes Pratiques

### Avant de commencer

1. **Vérifiez les prérequis** : `./scripts/run-all.sh --validate`
2. **Exécutez les health checks** : `./scripts/utils/health-checks.sh --auto`
3. **Installez les dépendances headless** si vous êtes en SSH : `sudo apt install -y nodejs npm`

### Pendant l'exécution

1. **Surveillez les logs** : `tail -f /tmp/p5_logs/p5_*.log`
2. **Utilisez le mode --wait** pour les vérifications automatiques
3. **Activez le mode --auto** pour une exécution sans intervention

### Après l'exécution

1. **Vérifiez le rapport final** dans le terminal
2. **Consultez le fichier de log** : `/tmp/p5_logs/p5_*.log`
3. **Exécutez les health checks** : `./scripts/utils/health-checks.sh`
4. **Nettoyez les ressources AWS** : `./scripts/phase-5-nettoyage.sh --auto`

---

## 🐛 Dépannage

### Problèmes courants et solutions

#### 1. **Kibana n'est pas accessible**

```bash
# Vérifiez le cluster OpenSearch
./scripts/utils/health-checks.sh --phase 2 --auto

# Solutions possibles :
# - Vérifiez que le cluster OpenSearch est actif
# - Vérifiez l'access policy
# - Vérifiez que votre IP publique est autorisée
# - Attendez 5-10 minutes après le déploiement
```

#### 2. **Les logs ne sont pas chargés dans OpenSearch**

```bash
# Vérifiez avec kibana-api.sh en mode wait
./scripts/utils/kibana-api.sh --url https://... --wait --auto

# Solutions possibles :
# - Exécutez : ./scripts/phase-2-opensearch-kibana.sh --auto
# - Vérifiez que le fichier nginx-access.log existe
# - Attendez que le script de chargement termine
```

#### 3. **Les visualisations ne sont pas créées**

```bash
# Vérifiez les champs dans l'index
./scripts/utils/kibana-api.sh --url https://... --auto

# Solutions possibles :
# - Vérifiez que l'index nginx-access* existe
# - Vérifiez que les logs ont été chargés
# - Vérifiez que jq est installé : sudo apt install -y jq
# - Vérifiez le format des logs (doit contenir : @timestamp, method, url, status, size, client_ip)
```

#### 4. **Les captures d'écran ne sont pas générées (mode GUI)**

```bash
# Vérifiez les outils de capture
./scripts/utils/capture-screenshots.sh --auto

# Solutions possibles :
# - Installez scrot : sudo apt install -y scrot
# - Installez ImageMagick : sudo apt install -y imagemagick
# - Ouvrez Kibana dans votre navigateur avant de lancer le script
# - Maximisez la fenêtre du navigateur
```

#### 5. **Les captures d'écran ne sont pas générées (mode headless)**

```bash
# Vérifiez les dépendances headless
./scripts/utils/capture-screenshots.sh --headless --auto

# Solutions possibles :
# - Installez Node.js : sudo apt install -y nodejs npm
# - Vérifiez que Kibana est accessible
# - Utilisez --wait pour attendre que Kibana soit prêt
# - Consultez /tmp/puppeteer_errors.log pour les erreurs détaillées
```

#### 6. **Le script run-all.sh s'arrête**

```bash
# Consultez le fichier de log
./scripts/utils/logging.sh --show

# Exécutez les health checks
./scripts/utils/health-checks.sh --auto

# Solutions possibles :
# - Corrigez les problèmes identifiés
# - Utilisez --force pour ignorer les erreurs (à utiliser avec prudence)
# - Reprenez à partir de la phase qui a échoué : ./scripts/run-all.sh --from X --auto
```

#### 7. **Problèmes de permissions**

```bash
# Donnez les permissions à tous les scripts
chmod +x scripts/*.sh scripts/utils/*.sh

# Exécutez avec bash explicitement
bash scripts/run-all.sh --auto
```

---

## 📚 Documentation Complémentaire

- [Guide OpenClassrooms](https://openclassrooms.com/fr/paths/518-devenez-devops)
- [Documentation Terraform](https://www.terraform.io/docs/)
- [Documentation Ansible](https://docs.ansible.com/)
- [Documentation OpenSearch](https://opensearch.org/docs/)
- [API OpenSearch Dashboards](https://opensearch.org/docs/latest/opensearch/rest-api/)
- [Puppeteer Documentation](https://pptr.dev/)

---

## 🔒 Sécurité

- ⚠️ **Ne partagez jamais vos clés AWS**
- 🔒 **Nettoyez toujours vos ressources après utilisation**
- 🛡️ **Utilisez des access policies restrictives**
- 📁 **Conservez vos logs dans un endroit sécurisé**
- 🚫 **Ne laissez pas les ressources AWS actives inutilisées**

---

## 📞 Support

Pour toute question ou problème :

1. Consultez les logs dans `/tmp/p5_logs/`
2. Vérifiez la documentation ci-dessus
3. Exécutez les health checks : `./scripts/utils/health-checks.sh --auto`
4. Ouvrez une issue sur le dépôt GitHub

---

## 🎉 Résumé des Améliorations

| Problème Initial | Solution Implémentée | Bénéfice |
|------------------|----------------------|----------|
| Vérification manuelle des logs | Vérification automatique dans kibana-api.sh | Gain de temps, moins d'erreurs |
| Environnement graphique requis | Mode headless avec Puppeteer | Fonctionne en SSH/serveur |
| Pas de validation pré-exécution | Health checks et validation | Détection précoce des problèmes |
| Gestion d'erreur basique | Logging complet avec niveaux | Dépannage facilité |
| Pas de suivi d'avancement | Système de logging intégré | Suivi complet du projet |

---

**Bon déploiement ! 🚀**

*"L'automatisation est la clé pour livrer rapidement et sans erreur."*
