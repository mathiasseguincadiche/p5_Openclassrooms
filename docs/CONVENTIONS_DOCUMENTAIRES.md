# Conventions documentaires du P5

## Objectif

Ce document fixe les règles de rédaction et de maintenance de la documentation du P5.

Le but n'est pas d'imposer un style artificiel. Il s'agit de garantir qu'une personne qui découvre le projet puisse :

- comprendre le rôle de chaque document ;
- distinguer explication, procédure et référence ;
- exécuter une commande dans le bon contexte ;
- savoir ce qu'elle doit observer ensuite ;
- reconnaître les actions risquées ou facturables ;
- retrouver la source de vérité lorsque le code évolue.

La matrice associée se trouve dans [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md).

---

## 1. Une fonction claire par type de document

### README racine — orienter

Le README racine doit permettre de comprendre rapidement :

- ce qu'est le projet ;
- son périmètre ;
- les trois exercices ;
- l'environnement d'exécution ;
- le premier parcours sûr ;
- où trouver le bon document ensuite.

Il ne doit pas absorber tous les détails techniques.

### Portail `docs/README.md` — naviguer

Le portail documentaire doit répondre à :

> « Quel document dois-je lire pour mon besoin actuel ? »

Il organise la documentation par intention et évite de recopier les procédures.

### Guide pédagogique — comprendre

Un guide pédagogique répond principalement à :

```text
Qu'est-ce que c'est ?
Pourquoi l'utilise-t-on ici ?
Comment les composants s'articulent-ils ?
Comment reconnaître un résultat correct ?
```

Il peut contenir des commandes, mais elles servent d'illustration et non de simple recette.

### Documentation technique — expliquer le système

Elle décrit :

- architecture ;
- responsabilités ;
- flux réseau et données ;
- choix techniques ;
- dépendances ;
- configuration ;
- sécurité ;
- sources de vérité.

### Runbook — agir

Un runbook répond principalement à :

```text
Dans quelle situation suis-je ?
Quelles sont les préconditions ?
Quelle action dois-je exécuter ?
Que dois-je observer ?
Quand dois-je m'arrêter ?
Comment reprendre si l'étape échoue ?
```

Il doit être exploitable sous pression sans demander de reconstruire mentalement l'architecture entière.

### Troubleshooting — diagnostiquer

Un document de dépannage doit suivre :

```text
symptôme
→ couche probable
→ diagnostic
→ cause possible
→ correction
→ vérification
```

Il ne doit pas commencer par une action destructive.

### Référence CLI — décrire une interface

`CENTRE_DE_COMMANDE.md` documente les commandes réellement supportées par `p5.sh` : rôle, mutation, risques et cas d'usage.

Il ne doit jamais inventer une commande future ou historique.

### Livrable — prouver

Un livrable doit montrer un résultat réellement observé. Une intention, un fichier de configuration ou une CI verte ne doit pas être présenté comme équivalent à une preuve AWS réelle lorsque la consigne exige une exécution.

---

## 2. Source de vérité avant prose

Lorsqu'une information technique peut être lue directement dans le code ou la configuration, la documentation doit s'aligner sur cette source.

Exemples :

| Information | Source à lire avant rédaction |
| --- | --- |
| version Node/Terraform/Ansible | `environment/versions.env` |
| commandes `p5.sh` | `scripts/commands/p5.sh` |
| AMI EC2 | modules Terraform concernés |
| ports et Security Groups | Terraform |
| comportement Ansible | `ansible/playbooks/deploy.yml` |
| scripts npm | `application/angular/package.json` |
| mapping OpenSearch | `index-template.json` |
| round-robin/health checks | `haproxy.cfg.tpl` |
| ordre de nettoyage | scripts de destruction + dépendances Terraform |

Ne pas recopier une version ou une commande depuis une ancienne documentation sans vérifier la source technique actuelle.

---

## 3. Toujours préciser le contexte d'une commande

Une commande doit être précédée d'un contexte lorsque celui-ci n'est pas évident.

Bon exemple :

```text
Dans la distribution WSL2 `Ubuntu` :
```

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
```

Autre exemple :

```text
Depuis PowerShell, pour rouvrir la distribution :
```

```powershell
wsl.exe -d Ubuntu
```

Éviter une suite de commandes qui mélange PowerShell, WSL2, EC2 distante et console AWS sans transition explicite.

---

## 4. Expliquer la commande, pas seulement la montrer

Pour une commande importante, la documentation doit fournir au minimum :

1. **intention** — pourquoi l'exécuter ;
2. **contexte** — où elle s'exécute ;
3. **commande** ;
4. **résultat attendu** ;
5. **point d'arrêt** si le résultat diffère.

Exemple de structure :

```markdown
### Vérifier le lab avant Terraform

Pourquoi : confirmer que les prérequis sont cohérents sans déployer.

Commande :
...

Résultat attendu :
GO TERRAFORM

Ne pas poursuivre si : ...
```

---

## 5. Distinguer information, action et avertissement

### Information

Explique un fait ou un concept.

### Action

Demande explicitement à l'opérateur d'exécuter quelque chose.

### Avertissement

Signale un risque **avant** la commande concernée :

- création/modification AWS ;
- destruction ;
- coût ;
- exposition réseau ;
- perte potentielle d'un state ;
- publication d'une information sensible.

Un avertissement placé après une commande destructive arrive trop tard.

---

## 6. Ne jamais inventer une valeur runtime

Les valeurs telles que :

- IP publiques ;
- DNS EC2 ;
- endpoint OpenSearch ;
- ARN ;
- identifiant de compte ;
- nom de ressource réellement créée ;

ne doivent pas être inventées dans une procédure présentée comme exécution réelle.

Utiliser :

- les outputs Terraform ;
- AWS CLI ;
- les fichiers de configuration locaux ;
- les sorties des scripts de contrôle.

Pour les exemples, utiliser uniquement des valeurs manifestement documentaires, par exemple les plages réservées comme `203.0.113.10/32` lorsqu'elles correspondent aux fichiers `.example`.

---

## 7. Distinguer les environnements qui portent le même OS

Le P5 contient plusieurs machines Linux. La documentation doit toujours préciser laquelle est concernée.

```text
Ubuntu 26.04 / resolute
→ plan de contrôle local sous WSL2

Ubuntu 24.04 / noble
→ AMI EC2 par défaut des exercices 1 et 3
```

Éviter les phrases ambiguës comme :

```text
« Sur Ubuntu, lancer... »
```

Préférer :

```text
« Dans la distribution WSL2 Ubuntu... »
```

ou :

```text
« Sur l'EC2 p5-web... »
```

---

## 8. Pédagogie : introduire avant d'abréger

À la première apparition d'un concept destiné aux débutants :

```text
Virtual Private Cloud (VPC)
Security Group (SG)
Infrastructure as Code (IaC)
```

Puis l'abréviation peut être réutilisée.

Le [`GLOSSAIRE.md`](GLOSSAIRE.md) sert de référence lorsque l'explication détaillée alourdirait un runbook.

---

## 9. Pédagogie : expliquer « pourquoi » lorsqu'un choix surprend

Certaines décisions méritent une phrase de justification :

- pourquoi le checkout reste sur le filesystem Linux WSL2 ;
- pourquoi le state est conservé ;
- pourquoi `plan` est lu avant `apply` ;
- pourquoi Terraform et Ansible ont des responsabilités séparées ;
- pourquoi un sample OpenSearch existe en plus du log réel ;
- pourquoi le dashboard reste un checkpoint humain ;
- pourquoi l'exercice 3 est détruit avant l'exercice 1.

La documentation ne doit pas faire mémoriser une règle arbitraire lorsqu'elle peut en expliquer la raison.

---

## 10. Résultats attendus : utiliser des critères observables

Préférer :

```text
changed=0
unreachable=0
failed=0
```

à :

```text
« Ansible doit bien fonctionner. »
```

Préférer :

```text
HTTP 200 sur `/`
```

à :

```text
« le site doit être OK »
```

Un critère de succès doit pouvoir être constaté.

---

## 11. Ne pas masquer les limites de l'automatisation

La documentation doit indiquer clairement lorsqu'une étape reste humaine.

Exemple du P5 :

- l'import et les agrégations OpenSearch sont vérifiables automatiquement ;
- la création et la lecture des visualisations dans OpenSearch Dashboards restent une validation humaine.

Le mode `--yes` ne doit pas être décrit comme capable de valider une preuve pédagogique à la place de l'opérateur.

---

## 12. CI, code et preuve réelle : trois niveaux différents

Toujours préserver cette distinction :

```text
CODE
= décrit ce qui doit être fait

CI
= vérifie le dépôt dans son environnement de test

PREUVE RUNTIME
= montre ce qui a réellement été observé pendant l'exécution
```

Ne pas conclure :

```text
CI verte → ressources AWS nécessairement déployées
```

---

## 13. Procédures destructives

Toute procédure destructive doit contenir :

- ce qui sera détruit ;
- les préconditions ;
- les dépendances ;
- l'ordre ;
- la confirmation attendue ;
- le verdict de fin ;
- la procédure si le verdict n'est pas obtenu.

Pour le P5 :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

et :

```text
NETTOYAGE AWS COMPLET
```

---

## 14. Sécurité documentaire

Ne jamais versionner ni insérer dans un exemple réel :

- credential AWS ;
- clé SSH privée ;
- vrai `terraform.tfvars` ;
- `terraform.tfstate` ;
- secret/token ;
- information personnelle inutile ;
- preuve runtime brute non relue lorsqu'elle contient des identifiants sensibles.

Les captures et logs destinés aux livrables doivent être relus et anonymisés lorsque nécessaire.

---

## 15. Liens et navigation

Privilégier les liens relatifs entre fichiers du dépôt :

```markdown
[Architecture](architecture-et-flux.md)
```

plutôt qu'une URL GitHub figée vers la branche `main` pour un document interne.

Avantages :

- navigation correcte dans une branche ou une pull request ;
- moins de liens cassés après fork ;
- lecture locale possible.

Les liens externes restent adaptés pour les dépôts séparés ou les sources officielles.

---

## 16. Schémas

Le dépôt utilise des schémas SVG versionnés sous :

```text
docs/schemas/
```

Les documents Markdown ne doivent pas introduire de blocs Mermaid : l'audit de non-régression interdit ce format dans le contrat actuel.

Pour un flux simple, un diagramme texte peut être utilisé :

```text
Terraform
   ↓
EC2
   ↓
Ansible
   ↓
NGINX
```

Pour un schéma de référence durable, utiliser un SVG conforme aux conventions de [`schemas/README.md`](schemas/README.md).

---

## 17. Nommage et titres

Un titre doit annoncer l'intention du document ou de la section.

Préférer :

```text
Exercice 3 — HAProxy : démontrer la continuité de service
```

à :

```text
Partie 3
```

Les noms techniques réels (`p5.sh`, `terraform.tfstate`, `OpenSearch Dashboards`) doivent conserver leur graphie exacte.

---

## 18. Ton et lisibilité

La documentation doit être :

- précise sans jargon inutile ;
- pédagogique sans être infantilisante ;
- directe dans les procédures ;
- explicative dans les guides ;
- cohérente dans le vocabulaire ;
- découpée en sections courtes lorsque la tâche est opérationnelle.

Une phrase courte et vérifiable vaut mieux qu'une affirmation générale difficile à contrôler.

---

## 19. Structure recommandée d'un guide d'exercice

```text
1. objectif pédagogique
2. ce qui doit être démontré
3. architecture / fichiers à connaître
4. concepts nécessaires
5. préparation
6. exécution
7. vérifications
8. preuves attendues
9. erreurs fréquentes
10. Definition of Done
11. étape suivante
```

Les guides existants peuvent adapter cette structure si le contenu l'exige.

---

## 20. Structure recommandée d'un runbook

```text
1. objectif et périmètre
2. quand l'utiliser
3. préconditions
4. risque / type de mutation
5. étapes numérotées
   - pourquoi
   - commande
   - résultat attendu
   - point d'arrêt
6. Definition of Done
7. récupération / rollback si pertinent
8. prochaine action
```

Le catalogue est disponible dans [`runbooks/README.md`](runbooks/README.md).

---

## 21. Mise à jour documentaire lors d'un changement de code

Avant de terminer une évolution qui modifie le comportement public :

- consulter [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md) ;
- mettre à jour les documents directement touchés ;
- rechercher les anciennes formulations ;
- vérifier les commandes et chemins ;
- vérifier les résultats attendus ;
- vérifier les schémas ;
- exécuter l'audit de non-régression ;
- vérifier la CI de la pull request.

Commandes :

```bash
python3 scripts/tools/audit_non_regression.py
bash scripts/commands/validate.sh
```

## 22. Définition d'une documentation terminée

Une documentation peut être considérée comme prête lorsque :

- [ ] son public et sa fonction sont clairs ;
- [ ] chaque commande est exacte ;
- [ ] son contexte d'exécution est explicite ;
- [ ] les versions et ressources correspondent au code ;
- [ ] les résultats attendus sont observables ;
- [ ] les risques sont annoncés avant les mutations ;
- [ ] les concepts nécessaires sont expliqués ou liés au glossaire ;
- [ ] les liens internes sont cohérents ;
- [ ] aucune information sensible n'est publiée ;
- [ ] aucun bloc Mermaid n'est présent ;
- [ ] l'audit de non-régression est satisfait ;
- [ ] les workflows GitHub Actions concernés passent.

## Références

- [Matrice de traçabilité](MATRICE_TRACABILITE.md)
- [Glossaire](GLOSSAIRE.md)
- [Portail documentaire](README.md)
- [Audit de non-régression](04-audit-non-regression.md)
