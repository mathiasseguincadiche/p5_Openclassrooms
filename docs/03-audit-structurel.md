# 03 — Audit structurel du dépôt

> Document de gouvernance. Il ne fait pas partie du parcours d'exécution du lab.

## Objectif

Cet audit décrit la **structure qui doit rester vraie aujourd'hui** pour que le dépôt demeure lisible, pédagogique et conforme aux trois exercices P5.

Il ne raconte pas l'historique des refontes. Le lecteur opérationnel doit pouvoir ignorer ce document et suivre directement le portail `docs/README.md`.

## 1. Trois exercices uniquement

La documentation évaluée doit exposer exactement :

```text
Exercice 1 — Terraform + Ansible
Exercice 2 — OpenSearch / dashboard
Exercice 3 — HAProxy / disponibilité
```

Les cours ou ressources pédagogiques OpenClassrooms ne doivent pas devenir artificiellement des exercices supplémentaires.

## 2. Un seul parcours d'implémentation

Le dépôt maintient le choix :

```text
AWS pour les trois exercices
```

Les variantes locales proposées par OpenClassrooms sont expliquées comme contexte, mais elles ne constituent pas une seconde architecture à maintenir.

## 3. Frontière plateforme / projet

La documentation doit conserver cette séparation :

```text
Ubuntu-desktops-custom
= HOST Ubuntu + KVM/libvirt + VM ubuntu-devops

p5_Openclassrooms
= runtime P5 dans ubuntu-devops + exercices AWS + preuves
```

Le dépôt P5 ne doit pas réimplémenter le provisioning, le réseau, le stockage, le démarrage, l'arrêt ou la sauvegarde de la VM.

En revanche, la **préparation d'environnement du P5 reste dans ce dépôt** : elle peut installer ou réaligner les dépendances strictement nécessaires au projet dans le guest Ubuntu Server 26.04.

## 4. Structure technique

```text
application/
  └── Angular source

ansible/
  ├── playbook
  ├── configuration NGINX
  └── artefact Angular

environment/
  ├── versions.env
  ├── aws-readiness.env.example
  └── vm-devops/README.md

terraform/
  ├── exercice-1
  ├── exercice-2
  └── exercice-3

scripts/
  ├── commands
  ├── lib
  ├── tests
  └── tools

docs/
  └── documentation officielle
```

Cette séparation doit rester compréhensible sans avoir besoin de connaître l'historique du dépôt.

## 5. Responsabilités

| Élément | Responsabilité |
| --- | --- |
| `Ubuntu-desktops-custom` | HOST, KVM/libvirt et cycle de vie de `ubuntu-devops` |
| bootstrap P5 | dépendances P5 dans la VM uniquement |
| Terraform ex. 1 | réseau et EC2 Angular |
| Ansible | NGINX + Angular sur l'EC2 |
| Terraform ex. 2 | Amazon OpenSearch |
| outils OpenSearch | conversion, import, vérification |
| Terraform ex. 3 | HAProxy + deux backends |
| scripts de tests HAProxy | round-robin et failover |
| `p5.sh` | orchestration et convergence du P5 |
| runtime | logs, preuves, confirmations et validation d'outputs |
| CI | qualité du dépôt et contrat d'intégration de la VM |

## 6. Dépendances autorisées

Deux dépendances sont intentionnelles :

```text
Exercice 1 → Exercice 2 : access.log NGINX réel
Exercice 1 → Exercice 3 : VPC + subnets
```

La seconde impose l'ordre de destruction :

```text
3 → 2 → 1
```

La dépendance vers `Ubuntu-desktops-custom` est uniquement une **dépendance de plateforme** : le P5 vérifie le contrat amont mais ne copie pas son implémentation.

## 7. Documentation officielle

Le chemin normal est :

```text
README racine
   ↓
docs/README.md
   ↓
cadre / architecture / parcours
   ↓
runbook
   ↓
guides des exercices
   ↓
preuves / livrables / nettoyage
```

Les documents de gouvernance (`02`, `03`, `04`, `suivi/`) ne doivent pas interrompre le parcours opérationnel.

## 8. Schémas

Le dépôt conserve six schémas SVG spécialisés :

```text
docs/schemas/vue-ensemble.svg
docs/schemas/etape-0.svg
docs/schemas/exercice-1.svg
docs/schemas/exercice-2.svg
docs/schemas/exercice-3.svg
docs/schemas/finalisation/finalisation.svg
```

Ils doivent rester :

- légers ;
- accessibles ;
- autonomes ;
- lisibles dans GitHub ;
- sans dépendance externe ;
- sans Mermaid.

Les schémas d'environnement doivent représenter `ubuntu-devops` comme runtime P5 sans transformer KVM/libvirt en composant du projet évalué.

## 9. Données runtime hors Git

Ne doivent pas être versionnés :

```text
environment/aws-readiness.env
terraform.tfvars réels
terraform.tfstate
inventaire Ansible réel
clés privées
logs runtime
preuves brutes runtime
```

Les fichiers exemples restent versionnés afin de documenter le contrat.

## 10. Source Angular

Le dépôt contient une application Angular réelle sous :

```text
application/angular/
```

L'artefact déployé par Ansible doit rester synchronisé avec le build de cette application.

La CI protège cette relation.

## 11. Architecture de sécurité minimale

L'audit doit continuer à protéger :

- `allowed_account_ids` ;
- SSH `/32` ;
- IMDSv2 ;
- volumes EC2 chiffrés ;
- OpenSearch chiffré et HTTPS ;
- secrets hors Git ;
- confirmation forte de destruction ;
- refus d'exécuter le runtime P5 hors de la VM attendue ;
- absence de logique KVM/libvirt dans les scripts P5.

## 12. Architecture de preuve

La présence du code ne vaut pas preuve runtime.

Le dépôt doit conserver :

```text
logs
+ preuves par étape
+ manifest
+ diagnostics
+ livrables
```

sans automatiser les preuves qui doivent rester humaines, notamment les visualisations OpenSearch.

## 13. Critère de qualité

Une évolution est structurellement acceptable si elle :

1. rend le parcours plus clair ou plus sûr ;
2. conserve les trois capacités pédagogiques ;
3. ne duplique pas une responsabilité existante ;
4. respecte la frontière `Ubuntu-desktops-custom` / P5 ;
5. ne casse pas les dépendances AWS ;
6. ne réduit pas la capacité de produire les preuves ;
7. passe l'audit de non-régression.

Commande :

```bash
python3 scripts/tools/audit_non_regression.py
```
