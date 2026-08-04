# 📊 Captures Exercice 2 : OpenSearch + Dashboard

> ⚠️️ **Gabarit de collecte** — les captures et résultats doivent provenir d'un déploiement réel.
> Aucun visuel de substitution ni résultat AWS fictif n'est utilisé dans ce document.

---

## 📋 Contexte

**But** : déployer un domaine Amazon OpenSearch, charger des logs NGINX et produire un tableau de bord avec trois visualisations.
**Outils utilisés** : Terraform, AWS CLI, OpenSearch Dashboards.

---

## 🚀 1. Déploiement du domaine OpenSearch

### 🔎 1.1. Validation et plan Terraform

```bash
cp terraform/exercice-2/terraform.tfvars.example terraform/exercice-2/terraform.tfvars
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 validate
terraform -chdir=terraform/exercice-2 plan -out=tfplan
```

La variable `your_ip_cidr` doit contenir une adresse unique au format `/32`. Le module impose HTTPS, le chiffrement au repos et le chiffrement nœud à nœud.

**Preuves à insérer** : validation réussie et résumé du plan.

### ✅ 1.2. Application Terraform

```bash
terraform -chdir=terraform/exercice-2 apply tfplan
terraform -chdir=terraform/exercice-2 output
aws opensearch describe-domain --domain-name p5-opensearch
```

**Preuves à insérer** : résumé de l'application, état du domaine et endpoints anonymisés si nécessaire.

---

## 📥 2. Chargement des logs NGINX

Le fichier d'exemple se trouve dans `terraform/exercice-2/samples/nginx-access.log.sample`.

```bash
./scripts/phases/phase-2-opensearch-kibana.sh
```

**Preuves à insérer** :

1. Index `nginx-access-*` visible.
2. Nombre de documents chargés.
3. Extrait de Discover contenant les champs `client_ip`, `method`, `url`, `status` et `size`.

---

## 📈 3. Création du dashboard

Le dashboard attendu doit contenir :

- 🍩 une répartition des verbes HTTP ;
- 📊 une quantité de données par tranche de douze heures ;
- 📉 une évolution cumulée de la quantité de données.

**Preuves à insérer** : une capture lisible de chaque visualisation et une capture du dashboard complet.

---

## 🔐 4. Contrôles de sécurité

- L'endpoint répond uniquement en HTTPS.
- La stratégie d'accès limite les requêtes à `your_ip_cidr`.
- Aucun identifiant AWS, mot de passe ou token ne figure dans les captures.
- La configuration Terraform ne contient pas de règle `0.0.0.0/0` pour OpenSearch.

---

## 🧹 5. Nettoyage

```bash
terraform -chdir=terraform/exercice-2 destroy
```

**Preuve à insérer** : absence du domaine après destruction, vérifiée avec `aws opensearch list-domain-names`.

---

## 📌 Conclusion

Ce fichier constitue la trame du livrable. Il devient une preuve recevable uniquement une fois complété avec les captures réelles du compte AWS utilisé pour l'exercice.
