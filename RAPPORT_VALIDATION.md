# 🔍 Rapport de validation du dépôt P5

**Projet** : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
**Date de la dernière passe locale** : 3 août 2026
**Portée** : dépôt complet

---

## 📋 Introduction

Ce rapport décrit les contrôles reproductibles du dépôt. Il ne certifie pas un déploiement AWS : aucune ressource cloud payante n'a été créée pendant la passe de correction.

---

## ✅ 1. Bash

- Tous les fichiers `*.sh` sont analysés avec `bash -n`.
- ShellCheck est exécuté avec un seuil bloquant `error` dans la CI.
- Les chemins sont calculés depuis la racine du dépôt afin d'éviter les dépendances au répertoire courant.

## ✅ 2. Terraform

- Les modules racines sont `terraform/exercice-1`, `terraform/exercice-2`, `terraform/exercice-3` et `TEMPLATES/terraform`.
- La CI exécute `terraform fmt -check`, `terraform init -backend=false` et `terraform validate` dans chaque module.
- Les fichiers d'état, plans et valeurs locales `*.tfvars` sont ignorés par Git.

## ✅ 3. YAML, Ansible et NGINX

- Yamllint vérifie tous les fichiers YAML avec `.yamllint.yml`.
- Le playbook principal cible le groupe `webservers` et passe un contrôle de syntaxe Ansible.
- La configuration NGINX ne contient qu'un bloc `location /` et passe `nginx -t` dans la CI.

## ✅ 4. Docker et Kubernetes

- Hadolint vérifie les Dockerfiles avec les diagnostics de niveau erreur comme seuil bloquant.
- Docker Compose exige que `DB_PASSWORD` soit fourni par l'environnement.
- Les exemples Kubernetes ne contiennent plus de mots de passe ou tokens encodés en dur.

## ✅ 5. Documentation

- Markdownlint contrôle les fichiers Markdown tout en préservant les emojis, les grandes sections et la navigation visuelle existante.
- Le contrôle de liens CI fonctionne hors ligne pour valider les chemins et ancres internes sans rendre le dépôt dépendant de sites externes.
- Les livrables sont des gabarits explicites : les captures AWS réelles restent à fournir par l'étudiant.

## ⚠️️ 6. Points d'attention et recommandations

1. Exécuter `terraform plan` avec les vraies variables avant tout déploiement.
2. Évaluer les coûts AWS, notamment ceux d'OpenSearch, avant `terraform apply`.
3. Ne jamais commiter `terraform.tfstate`, `terraform.tfvars`, l'inventaire réel ou `scripts/haproxy.cfg`.
4. Remplacer les zones « preuve à insérer » uniquement par des sorties et captures réelles.

## 🧪 7. Commande de validation locale

```bash
./scripts/validate.sh
```

La source de vérité automatisée reste le workflow `.github/workflows/ci.yml`.

## 🎯 8. Conclusion

Le dépôt est structuré pour échouer immédiatement lorsqu'un contrôle important ne passe pas. La validation d'un déploiement réel reste volontairement séparée afin de ne ni engager de coûts AWS ni fabriquer de preuves.
