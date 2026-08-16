# Convergence et réexécution

## Pourquoi ce document est important

Un lab DevOps ne doit pas devenir inutilisable parce que la session SSH a été fermée, la VM a redémarré, le HOST a redémarré ou une commande a échoué au milieu du parcours.

Le P5 est conçu pour être **repris à partir de l'état réel** dans la VM `ubuntu-devops`.

La plateforme et le projet ont deux cycles de vie distincts :

```text
Ubuntu-desktops-custom
→ HOST / KVM / ubuntu-devops

p5_Openclassrooms
→ runtime P5 / AWS / states / preuves
```

## Principe

```text
ne pas supposer
      ↓
inspecter
      ↓
relire le state et AWS
      ↓
recalculer le delta
      ↓
appliquer uniquement le nécessaire
      ↓
revérifier
```

## 1. Terraform et la convergence

Le mécanisme central est :

```bash
terraform plan -detailed-exitcode
```

Codes utiles :

```text
0 = aucun delta
2 = delta à appliquer
autre = erreur
```

`p5.sh` utilise cette distinction.

### État déjà conforme

Si Terraform retourne `0` :

```text
pas d'apply
lecture des outputs existants
suite du contrôle fonctionnel
```

### État différent

Si Terraform retourne `2` :

```text
afficher le plan
→ demander confirmation
→ appliquer le plan sauvegardé
→ relancer un plan
```

### Pourquoi rejouer les tests si Terraform n'a rien modifié ?

Parce qu'un plan vide prouve que **Terraform ne voit pas de changement d'infrastructure**. Il ne garantit pas qu'un service répond correctement.

Exemples :

- NGINX peut être arrêté ;
- un conteneur backend peut être arrêté ;
- le dashboard peut ne pas avoir été terminé ;
- un endpoint peut être inaccessible depuis la nouvelle IP publique.

Les tests fonctionnels gardent donc leur intérêt.

## 2. Ne jamais supprimer le state pour « débloquer »

Le fichier `terraform.tfstate` représente le lien entre la configuration et les ressources gérées.

Si des ressources AWS existent encore et que le state est supprimé, Terraform peut :

- ne plus savoir qu'il les gère ;
- proposer des doublons ;
- échouer sur des noms déjà utilisés ;
- compliquer le nettoyage ;
- laisser des coûts résiduels.

Règle :

```text
ressources AWS existantes + state valide
→ conserver le state
→ calculer le delta
```

## 3. Reprise après fermeture du terminal

Se reconnecter à `ubuntu-devops` selon le runbook de la plateforme, puis dans la VM :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
```

Ensuite choisir :

```bash
bash scripts/commands/p5.sh status
```

pour contrôler seulement, ou :

```bash
bash scripts/commands/p5.sh all
```

pour poursuivre le parcours complet de façon convergente.

## 4. Reprise après redémarrage du HOST ou de la VM

Le redémarrage du HOST ou de `ubuntu-devops` ne supprime pas les ressources AWS. Les states P5 restent sur le disque de la VM tant que son stockage est intact.

Procédure :

1. utiliser `Ubuntu-desktops-custom` pour vérifier/démarrer `ubuntu-devops` ;
2. se reconnecter en SSH ;
3. revenir dans le dépôt P5 ;
4. inspecter avant toute mutation.

Dans la VM :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status
```

Ne recréer ni clé SSH ni configuration AWS si le moteur confirme qu'elles existent et sont conformes.

Si la VM elle-même est en panne, le P5 ne doit pas essayer de réparer KVM/libvirt : corriger d'abord la plateforme amont.

## 5. Reprise après code retour 90 du bootstrap

Le code `90` signifie que le runtime P5 est installé mais qu'une **nouvelle session SSH** est nécessaire pour que l'appartenance au groupe Docker soit effective.

Procédure :

1. fermer la session SSH ;
2. se reconnecter à `ubuntu-devops` ;
3. revenir dans le dépôt ;
4. relancer exactement la même commande P5.

Ne pas réinstaller Docker pour ce cas.

## 6. Reprise de l'exercice 1

### Terraform a déjà créé l'EC2

Relancer :

```bash
bash scripts/commands/p5.sh ex1
```

Terraform doit recalculer le delta. Si le state et AWS sont cohérents, aucun nouvel apply n'est nécessaire.

Ansible et les tests sont ensuite rejoués pour vérifier l'état réel.

### Ansible a échoué après Terraform

Ne détruire pas l'EC2 uniquement parce que le playbook a échoué.

Procédure :

```bash
bash scripts/commands/p5.sh inspect
terraform -chdir=terraform/exercice-1 output
ansible all -i ansible/inventories/hosts_aws -m ping
```

Puis diagnostiquer la couche SSH/Ansible et relancer `ex1`.

## 7. Reprise de l'exercice 2

### Domaine OpenSearch déjà créé

Relancer :

```bash
bash scripts/commands/p5.sh ex2
```

Terraform doit conserver le domaine s'il est conforme.

Les données peuvent être réconciliées puis les agrégations revérifiées.

### Dashboard non terminé

Il n'est pas nécessaire de détruire/recréer OpenSearch. Reprendre directement le checkpoint OpenSearch Dashboards tant que le domaine et les données sont encore disponibles.

## 8. Reprise de l'exercice 3

### Infrastructure créée mais test de failover interrompu

Commencer par :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh ex3
```

Le test vérifie de nouveau le round-robin avant de proposer une panne réelle.

Si un backend a été laissé arrêté de manière inattendue, restaurer l'état fonctionnel avant de produire une nouvelle preuve de failover.

## 9. Changement d'IPv4 publique

C'est un cas courant après changement de réseau ou redémarrage de box.

Symptômes :

- SSH timeout ;
- OpenSearch Dashboards inaccessible ;
- infrastructure pourtant présente dans Terraform.

Ne pas recréer les ressources.

Relancer :

```bash
bash scripts/commands/p5.sh prepare
```

Le moteur doit mettre à jour l'IP `/32` de référence et synchroniser les `tfvars`.

Le prochain plan Terraform montrera uniquement le delta réseau nécessaire.

## 10. Changement de code Angular

Après modification des sources :

```bash
bash scripts/commands/p5.sh ex1
```

Le pipeline doit :

- reconstruire/vérifier l'artefact ;
- ne pas recréer l'infrastructure si elle n'a pas changé ;
- laisser Ansible copier uniquement les fichiers différents ;
- revérifier le second passage idempotent.

C'est un exemple typique de convergence multi-couches.

## 11. Modification Terraform volontaire

Après changement d'un `.tf` :

```bash
bash scripts/commands/p5.sh ex1
```

ou l'exercice concerné.

Toujours lire le plan.

Ne pas utiliser `--yes` pour masquer un plan que vous ne comprenez pas.

## 12. State présent mais ressources manquantes

Terraform doit détecter le drift lors du refresh/plan.

Ne pas modifier directement le state comme première action.

Procédure :

```bash
bash scripts/commands/p5.sh inspect
terraform -chdir=terraform/exercice-X state list
terraform -chdir=terraform/exercice-X plan
```

Puis comprendre pourquoi AWS et le state divergent.

## 13. Ressources AWS présentes mais state absent

C'est une situation plus délicate.

Ne pas lancer un nouvel apply immédiatement.

Il faut identifier :

- qui a créé les ressources ;
- si elles portent les tags P5 ;
- si un state sauvegardé existe ;
- si un import Terraform est nécessaire ;
- si une destruction manuelle est réellement justifiée.

Le runbook normal ne doit jamais conduire à cette situation.

## 14. Git et reprise

Avant `git pull` :

```bash
git status
```

Pour une mise à jour sans merge implicite :

```bash
git pull --ff-only
```

Ne pas écraser les fichiers locaux runtime pour « obtenir une branche propre » si cela supprime un state nécessaire.

Les states et `tfvars` sont ignorés par Git précisément parce que leur cycle de vie est différent du code versionné.

## 15. Reprise recommandée selon l'état

| État | Action |
| --- | --- |
| VM/HOST/KVM en panne | corriger via `Ubuntu-desktops-custom` |
| je ne sais pas où j'en suis dans P5 | `p5.sh inspect` |
| outils/config P5 seulement | `p5.sh prepare` |
| je veux vérifier sans muter | `p5.sh status` |
| ex. 1 incomplet | `p5.sh ex1` |
| ex. 2 incomplet | `p5.sh ex2` |
| ex. 3 incomplet | `p5.sh ex3` |
| plusieurs étapes à reprendre | `p5.sh all` |
| preuves à vérifier | `p5.sh diagnostics` |
| livrables à contrôler | `p5.sh finalize` |
| projet terminé | `p5.sh cleanup` |

## 16. Invariant de reprise

Une reprise correcte conserve ce principe :

```text
on ne détruit pas un état connu pour éviter de le comprendre
```

La stratégie du P5 est au contraire :

```text
observer → expliquer → converger → prouver
```

Et la frontière de plateforme reste :

```text
problème de VM/KVM → Ubuntu-desktops-custom
problème de runtime P5/AWS → p5_Openclassrooms
```
