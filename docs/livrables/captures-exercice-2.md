# Captures Exercice 2 : Déploiement d'OpenSearch

---

## 📌 Contexte
**But** : Déployer un **cluster OpenSearch** dans AWS pour stocker et analyser des logs.
**Outils utilisés** : Terraform, AWS CLI.

---

## 🔹 1. Déploiement avec Terraform

### Plan Terraform
**Commande** : `terraform plan`

**Résultat** : [Copier-coller la sortie complète ici]

---

### Application Terraform
**Commande** : `terraform apply -auto-approve`

**Résultat** : [Copier-coller la sortie complète ici]

---

## 🔹 2. Vérification du cluster

**Commande** : `aws es describe-domain --domain-name p5-opensearch`

**Résultat** : [Copier-coller la sortie JSON ici]

---

## 🔹 3. Test du cluster

**Commande** : `curl -k -X GET "https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com" -H "Content-Type: application/json"`

**Résultat** : [Copier-coller la réponse JSON ici]

---

## ✅ Checklist de Vérification

- [ ] Terraform initialisé et plan vérifié
- [ ] Cluster OpenSearch déployé
- [ ] Domaine OpenSearch accessible
- [ ] API OpenSearch fonctionnelle
- [ ] Captures d'écran des étapes clés (à ajouter dans le dossier `captures/`) :
  - [ ] Sortie de `terraform plan`
  - [ ] Sortie de `terraform apply`
  - [ ] Console AWS montrant le cluster OpenSearch
  - [ ] Test de l'API OpenSearch via curl

---

**Conseil** : 
- Utilisez `curl -k` pour ignorer les erreurs de certificat SSL.
- Vérifiez que le cluster est dans l'état **"Active"** avant de continuer.
