# RUNBOOK P5 OpenClassrooms — Exécution guidée A → Z

> **But :** réaliser le P5 AWS rapidement avec `p5.sh`, comprendre ce qui se passe,
> conserver les preuves, diagnostiquer proprement les erreurs et terminer par le
> contrôle des livrables puis le nettoyage AWS.

---

## 1. Philosophie du dépôt

Le projet suit ce cycle :

```text
INSPECTER
   ↓
COMPARER état réel ↔ état attendu
   ↓
ÉCART ?
 ├─ NON → aucune mutation
 └─ OUI → corriger uniquement le delta
   ↓
VÉRIFIER
   ↓
JOURNALISER
```

Les éléments persistants ne sont donc pas recréés inutilement. En revanche, les
tests fonctionnels peuvent être rejoués pour prouver que le système fonctionne
encore au moment de la démonstration.

---

## 2. Architecture à retenir

```text
VM Ubuntu Server — poste DevOps
│
├─ AWS CLI
├─ Terraform
├─ Ansible
├─ Docker
├─ Node.js / Angular
└─ p5.sh
    │
    ▼
AWS
├─ Exercice 1 : VPC + subnets + EC2 → Ansible → NGINX → Angular
├─ Exercice 2 : Amazon OpenSearch ← logs NGINX
└─ Exercice 3 : HAProxy → Backend 1 + Backend 2
```

**Dépendance importante :** l’exercice 3 réutilise le réseau de l’exercice 1.
Ne détruis jamais l’exercice 1 avant d’avoir terminé l’exercice 3.

---

## 3. Commandes principales

```bash
# Observer sans modifier
bash scripts/commands/p5.sh inspect

# Préparer le lab
bash scripts/commands/p5.sh prepare

# Contrôler sans créer de ressources AWS
bash scripts/commands/p5.sh status

# Exécuter un exercice
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3

# Faire tout le projet
bash scripts/commands/p5.sh all

# Vérifier les livrables
bash scripts/commands/p5.sh finalize

# Voir les logs
bash scripts/commands/p5.sh logs

# Nettoyer AWS à la fin
bash scripts/commands/p5.sh cleanup
```

Pour la **première exécution réelle**, utilise `all` **sans `--yes`** afin de voir
les plans Terraform et les validations humaines.

---

# PHASE A — DÉMARRAGE

## 4. Mettre le dépôt à jour

```bash
cd ~/p5_Openclassrooms
git pull
git status
```

État idéal :

```text
On branch main
nothing to commit, working tree clean
```

Si tu pars d’un clone neuf :

```bash
cd ~
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

---

## 5. Inspecter avant de toucher quoi que ce soit

```bash
bash scripts/commands/p5.sh inspect
```

### Ce que `inspect` regarde

- Ubuntu et le socle DevOps ;
- Terraform ;
- Docker ;
- AWS CLI ;
- Ansible ;
- Node/NVM ;
- configuration AWS locale ;
- session AWS déjà active ;
- clés SSH ;
- `terraform.tfvars` ;
- états Terraform ;
- inventaire Ansible ;
- artefact Angular ;
- preuves et logs existants.

### Ce que `inspect` ne doit pas faire

- aucune installation ;
- aucune authentification interactive ;
- aucun `terraform apply` ;
- aucune création AWS ;
- aucune destruction.

### Si `inspect` échoue

```bash
bash scripts/commands/p5.sh logs
```

Envoie-moi :

1. la commande lancée ;
2. le premier message `[ KO ]` ou l’erreur ;
3. le nom de l’étape ;
4. le fichier `.log` complet correspondant.

---

# PHASE B — LANCEMENT COMPLET

## 6. Démarrer le projet

```bash
bash scripts/commands/p5.sh all
```

Le parcours est :

```text
prepare
  ↓
ex1
  ↓
ex2
  ↓
ex3
  ↓
diagnostics
```

Le mode `all` **ne détruit pas AWS**.

---

# PHASE C — PRÉPARATION VM + AWS

## 7. Convergence de la VM

Le script inspecte les outils avant installation.

### Si tout est conforme

```text
VM déjà convergée : aucune installation nécessaire.
```

### Si un outil manque

Le script propose de corriger uniquement l’écart.

### Si Docker demande une reconnexion

Tu peux voir :

```text
RECONNEXION REQUISE
```

Dans ce cas :

```bash
exit
```

Reconnecte-toi puis :

```bash
cd ~/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Ne relance pas manuellement une installation complète.

---

## 8. Authentification AWS

Le projet utilise des credentials temporaires et refuse l’usage quotidien de
l’identité AWS root.

### Session valide

Aucune action : elle est réutilisée.

### Session absente ou expirée

Le flux peut utiliser :

```bash
aws login --remote
```

La VM affiche l’autorisation à ouvrir dans ton navigateur. Tu saisis tes
identifiants **chez AWS**, pas dans les scripts du projet.

### Ne jamais partager

- mot de passe AWS ;
- Access Key ;
- Secret Access Key ;
- token de session ;
- code MFA ;
- cookies.

---

## 9. Configuration du lab

Le projet prépare :

```text
environment/aws-readiness.env
```

Ce fichier sert de source locale pour :

- profil AWS ;
- région ;
- compte ;
- IPv4 publique `/32` ;
- clé SSH ;
- OpenSearch ;
- budget.

Les trois `terraform.tfvars` sont ensuite synchronisés automatiquement.

Si tout est déjà correct, ils ne sont pas réécrits inutilement.

---

## 10. Budget AWS

Le script vérifie notamment :

- montant ;
- alerte réelle 50 % ;
- alerte réelle 80 % ;
- alerte prévisionnelle 100 % ;
- destinataire.

S’il est déjà conforme :

```text
Budget AWS déjà conforme
```

Sinon le delta est affiché avant correction.

---

## 11. Porte AWS Ready

Avant Terraform, l’objectif est :

```text
AWS PRÊT
GO AWS
GO TERRAFORM
```

Si tu obtiens :

```text
STOP AWS
```

ou un `[ KO ]`, **ne contourne pas le contrôle**.

Envoie le log de cette étape. Les causes possibles sont souvent IAM, quota,
session, IP publique, région ou disponibilité d’un service AWS.

---

# PHASE D — EXERCICE 1

## 12. Angular

Le script compare dépendances, sources et artefact.

Premier passage : un build peut être nécessaire.

Passage suivant sans changement :

```text
Artefact Angular déjà conforme
```

Le but est d’éviter `npm ci` et un rebuild inutiles.

---

## 13. Terraform Exercice 1

Le script exécute :

```text
terraform init
terraform plan -detailed-exitcode
```

Interprétation :

```text
0 → aucun delta → aucun apply
1 → erreur → arrêt
2 → delta réel → affichage → confirmation → apply
```

### Premier déploiement

Le plan doit correspondre au périmètre de l’exercice : VPC, sous-réseaux, EC2,
security groups, etc.

**Lis toujours le plan avant de confirmer.**

### Après l’apply

Un second plan est exécuté.

Résultat attendu :

```text
No changes.
```

Cela prouve que l’état AWS réel correspond maintenant à l’état Terraform attendu.

---

## 14. Inventaire Ansible

L’IP de l’EC2 vient de Terraform.

Le projet génère automatiquement :

```text
ansible/inventories/hosts_aws
```

Aucune IP ne doit normalement être recopiée à la main.

---

## 15. Attente SSH / cloud-init

Une EC2 neuve n’est pas immédiatement prête.

Tu peux voir :

```text
tentative 01/48
tentative 02/48
...
SSH prêt
```

Laisse le script attendre. Il vérifie notamment SSH, Python et `cloud-init`.

---

## 16. Ansible

Le script commence par un ping Ansible puis exécute le playbook.

Le playbook configure notamment :

```text
EC2
 ↓
NGINX
 ↓
Angular
```

---

## 17. Idempotence Ansible

Le playbook est exécuté une deuxième fois.

Résultat obligatoire :

```text
changed=0
unreachable=0
failed=0
```

**Pourquoi ?** Le premier passage configure. Le second prouve que la machine est
déjà conforme et qu’Ansible n’a plus besoin de la modifier.

Si `changed` reste supérieur à zéro, envoie le log de l’étape
`ansible-idempotence`.

---

## 18. Vérification Angular / NGINX

Le script vérifie ensuite l’application réelle par HTTP.

Le succès du playbook seul n’est pas considéré comme une preuve suffisante.

---

## 19. Génération de vrais logs

Le script génère **96 requêtes HTTP**, puis collecte :

```text
/var/log/nginx/access.log
```

dans :

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

Chaîne à comprendre :

```text
requêtes → NGINX → access.log → collecte → OpenSearch
```

### Exercice 1 terminé lorsque

- [ ] Terraform Ex1 est convergé ;
- [ ] post-plan vide ;
- [ ] Ansible ping OK ;
- [ ] déploiement OK ;
- [ ] second Ansible `changed=0` ;
- [ ] Angular accessible ;
- [ ] vrai access.log collecté.

---

# PHASE E — EXERCICE 2

## 20. Terraform OpenSearch

Même logique :

```text
init → plan → apply uniquement si delta → post-plan
```

Un plan vide ne doit jamais être appliqué.

---

## 21. Deux sources de données

### Jeu reproductible

```text
terraform/exercice-2/samples/nginx-access.log.sample
```

Il garantit une distribution temporelle suffisante pour les visualisations.

### Vrai log NGINX

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

Il prouve la chaîne réelle :

```text
NGINX réel → collecte → conversion → Amazon OpenSearch
```

---

## 22. Convergence OpenSearch

Le script compare :

- template distant ;
- template attendu ;
- IDs des documents déjà présents.

Si tout est déjà conforme :

```text
OPENSEARCH DÉJÀ CONFORME — AUCUNE MUTATION NÉCESSAIRE
```

Les agrégations sont néanmoins revérifiées.

---

## 23. Checkpoint manuel OpenSearch Dashboards

Le script affiche l’URL.

Tu dois vérifier/créer :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 des `url_path` par tranches de 12 h.

Puis :

- fais les captures ;
- vérifie qu’elles sont lisibles ;
- conserve-les pour les livrables ;
- confirme le checkpoint demandé par le script.

Même `--yes` ne doit pas contourner cette preuve humaine.

### Si OpenSearch échoue

Récupère les logs liés à :

```text
tf-ex2-plan
tf-ex2-apply
opensearch-sample-import
opensearch-real-import
opensearch-verify
```

Ne détruis pas le domaine pour « essayer ».

---

# PHASE F — EXERCICE 3

## 24. Architecture HAProxy

```text
             CLIENT
               |
               v
            HAProxy
           /       \
          v         v
     Backend 1   Backend 2
```

L’exercice 1 doit encore exister.

---

## 25. Terraform Exercice 3

Même contrat :

```text
plan vide → aucun apply
delta réel → confirmation → apply
erreur → arrêt
```

Le script attend ensuite que HAProxy réponde réellement en HTTP.

---

## 26. Round-robin

Le projet effectue **12 requêtes** et doit observer les deux backends.

Objectif :

```text
les deux serveurs participent au trafic
```

---

## 27. Panne et reprise

Le script prévisualise le scénario puis demande confirmation.

Scénario :

```text
Backend 1 OK + Backend 2 OK
          ↓
arrêt d’un backend
          ↓
service toujours disponible
          ↓
redémarrage
          ↓
réintégration du backend
```

Cette étape prouve la résilience actuelle du service.

### Exercice 3 terminé lorsque

- [ ] HAProxy accessible ;
- [ ] deux backends observés ;
- [ ] round-robin validé ;
- [ ] panne réelle contrôlée validée ;
- [ ] service resté disponible ;
- [ ] backend réintégré.

---

# PHASE G — FIN DE `all`

## 28. Résultat attendu

Après les trois exercices :

```text
DÉPLOIEMENT CONVERGÉ ET VÉRIFIÉ
```

Les ressources AWS restent actives.

**Ne lance pas encore `cleanup`.**

Utilise ce moment pour :

- captures ;
- contrôles ;
- démonstration ;
- préparation de soutenance.

---

# PHASE H — LOGS ET DIAGNOSTIC

## 29. Retrouver les logs

```bash
bash scripts/commands/p5.sh logs
```

Organisation :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Il existe donc un log global et un log complet par étape.

---

## 30. Procédure exacte si une étape casse

### 1 — Ne change rien au hasard

Conserve l’environnement tel quel.

### 2 — Repère la première vraie erreur

Cherche :

```text
[ KO ]
ERROR
FAILED
STOP
```

### 3 — Liste les logs

```bash
bash scripts/commands/p5.sh logs
```

### 4 — Envoie-moi

```text
Commande lancée :
bash scripts/commands/p5.sh all

Étape :
<nom de l’étape>

Erreur terminal :
<message>

Pièce jointe :
<log complet de cette étape>
```

### 5 — On corrige la cause

Selon le cas :

```text
bug dépôt/script
IAM / permissions
quota AWS
réseau
configuration
service temporairement indisponible
```

### 6 — Relance la même commande

```bash
bash scripts/commands/p5.sh all
```

L’orchestrateur doit recalculer l’état et reprendre par convergence.

---

## 31. Règle absolue Terraform

**Ne supprime jamais un `terraform.tfstate` pour débloquer le projet si les
ressources AWS existent encore.**

Ne fais pas :

```bash
rm terraform/exercice-*/terraform.tfstate
```

Cela pourrait orpheliner les ressources et provoquer des doublons.

---

# PHASE I — REPRISE APRÈS INTERRUPTION

## 32. Après perte SSH, reboot ou fermeture du terminal

```bash
cd ~/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Le comportement attendu lors d’une reprise est proche de :

```text
VM déjà convergée
session AWS réutilisée
budget déjà conforme
tfvars déjà synchronisés
Terraform Ex1 : aucun apply
artefact Angular déjà conforme
Ansible : changed=0
Terraform Ex2 : aucun apply
OpenSearch déjà conforme
Terraform Ex3 : aucun apply
```

Les tests fonctionnels sont ensuite rejoués.

---

# PHASE J — FINALISATION

## 33. Quand lancer `finalize`

Une fois les exercices validés et les captures sauvegardées :

```bash
bash scripts/commands/p5.sh finalize
```

Le script contrôle :

- diagnostics ;
- preuves ;
- structure ;
- livrables.

Résultat attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

### Si `finalize` échoue

Ne détruis rien.

Corrige uniquement l’élément signalé puis :

```bash
bash scripts/commands/p5.sh finalize
```

---

# PHASE K — CHECKLIST AVANT DE DÉTRUIRE AWS

- [ ] Angular démontrable ;
- [ ] idempotence Ansible `changed=0` ;
- [ ] vrai log NGINX conservé ;
- [ ] OpenSearch contient les données ;
- [ ] donut HTTP capturé ;
- [ ] `bytes_sent` / 12 h capturé ;
- [ ] top 5 `url_path` / 12 h capturé ;
- [ ] round-robin HAProxy validé ;
- [ ] panne backend validée ;
- [ ] reprise backend validée ;
- [ ] diagnostics conservés ;
- [ ] `p5.sh finalize` réussi ;
- [ ] toutes les captures sauvegardées.

---

# PHASE L — NETTOYAGE AWS

## 34. Destruction

Uniquement lorsque tu n’as plus besoin du lab :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

La destruction réelle nécessite la saisie :

```text
DETRUIRE
```

Les états Terraform déjà vides sont ignorés.

---

## 35. Audit final

Après la destruction, l’audit doit aboutir à :

```text
NETTOYAGE AWS COMPLET
```

Ne considère pas le projet fermé avant ce verdict.

---

# 36. Parcours express à garder sous les yeux

```bash
cd ~/p5_Openclassrooms
git pull

# 1. Observer
bash scripts/commands/p5.sh inspect

# 2. Faire le projet
bash scripts/commands/p5.sh all

# 3. Faire/conserver les captures manuelles demandées

# 4. Vérifier les livrables
bash scripts/commands/p5.sh finalize

# 5. Seulement à la fin
bash scripts/commands/p5.sh cleanup
```

En cas d’erreur :

```bash
bash scripts/commands/p5.sh logs
```

Puis envoie-moi **le log complet de l’étape en échec**.

---

# 37. Ce qu’il ne faut jamais faire

```text
❌ supprimer un terraform.tfstate
❌ contourner STOP AWS
❌ utiliser root pour le lab quotidien
❌ mettre des credentials AWS dans Git
❌ envoyer des secrets dans le chat
❌ modifier plusieurs composants à la fois pour “tester”
❌ détruire Ex1 avant Ex3
❌ nettoyer AWS avant les captures et finalize
```

---

# 38. Ce que tu dois savoir expliquer en soutenance

## Terraform

```text
état souhaité ↔ état AWS réel
```

Plan vide = aucune mutation nécessaire.

## Ansible

Le deuxième passage doit revenir :

```text
changed=0
```

C’est la preuve d’idempotence.

## OpenSearch

Le projet vérifie template, documents, mappings, agrégations et preuve visuelle.

## HAProxy

Le projet prouve :

```text
répartition de charge + continuité de service en cas de panne
```

## Orchestrateur

`p5.sh` :

```text
observe → compare → corrige le delta → vérifie → journalise
```

---

# 39. Formulation courte pour présenter l’automatisation

> Le projet est piloté par un orchestrateur Bash convergent. Il inspecte l’état
> réel avant les mutations. Terraform calcule les différences d’infrastructure,
> Ansible converge la configuration des serveurs et prouve son idempotence,
> OpenSearch exploite un jeu reproductible et de vrais logs NGINX, et HAProxy
> est validé par des tests de round-robin, de panne et de reprise. Chaque étape
> produit un log afin de rendre l’exécution reproductible et diagnosticable.

---

# 40. Sources de vérité du dépôt

```text
README.md
docs/01-parcours-debutant.md
docs/convergence-et-reexecution.md
docs/00-preparation-environnement.md
docs/00b-preparation-compte-aws.md
docs/exercices/01-terraform-ansible.md
docs/exercices/02-elk-opensearch.md
docs/exercices/03-haproxy.md
scripts/README.md
scripts/commands/p5.sh
```

---

## Règle finale

**En cas de problème : ne détruis rien, ne supprime aucun state, garde le log,
envoie-moi le log exact, on corrige la cause, puis tu relances la même commande.**
