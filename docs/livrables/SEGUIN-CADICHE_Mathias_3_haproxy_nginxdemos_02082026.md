# SEGUIN-CADICHE_Mathias_3_HAProxy_nginxdemos

# Preuves Exercice 3 : Load Balancing avec HAProxy + nginxdemos/hello

> ⚠️️ **Gabarit de collecte** — remplacez les zones indiquées par des preuves issues de votre déploiement.
> Les anciennes IP et le mot de passe d'exemple ont été retirés pour éviter de présenter des données fictives ou sensibles comme réelles.

---

## 📋 Contexte

**Projet** : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
**Exercice** : 3 - HAProxy devant deux serveurs `nginxdemos/hello`
**Auteur** : SEGUIN-CADICHE Mathias

---

## 🎯 Objectifs

- ✅ Déployer deux serveurs `nginxdemos/hello`.
- ✅ Déployer HAProxy en mode `roundrobin`.
- ✅ Autoriser les backends HTTP uniquement depuis le groupe de sécurité HAProxy.
- ✅ Vérifier l'alternance et la tolérance à la panne.
- ✅ Protéger les statistiques HAProxy par un secret externe au dépôt.

---

## 🛠️ Outils utilisés

- **Terraform** 1.15.8.
- **Docker** et l'image `nginxdemos/hello:plain-text`.
- **HAProxy**.
- **AWS CLI v2**.

---

## 📁 Structure des fichiers

```text
terraform/exercice-3/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example

scripts/
└── generer-haproxy-config.sh
```

---

## ✅ 1. Préparation de l'environnement

```bash
cp terraform/exercice-3/terraform.tfvars.example terraform/exercice-3/terraform.tfvars
export HAPROXY_STATS_PASSWORD='UNE_PHRASE_SECRETE_D_AU_MOINS_16_CARACTERES'
export TF_VAR_haproxy_stats_password="$HAPROXY_STATS_PASSWORD"
```

Ne placez jamais ce mot de passe dans Git, dans une capture ou dans la commande transmise au livrable.

---

## ✅ 2. Déploiement Terraform

```bash
terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 validate
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 apply tfplan
terraform -chdir=terraform/exercice-3 output
```

**Preuves à insérer** : validation, résumé du plan, résumé de l'application et outputs réels.

---

## ⚙️️ 3. Configuration HAProxy

```bash
./scripts/tools/generer-haproxy-config.sh \
  "ADRESSE_PRIVEE_BACKEND_1" \
  "ADRESSE_PRIVEE_BACKEND_2" \
  scripts/haproxy.cfg
```

Le fichier généré est ignoré par Git, car il contient le secret des statistiques.

**Preuves à insérer** : résultat de `haproxy -c -f /etc/haproxy/haproxy.cfg` et état des deux backends, sans exposer le mot de passe.

---

## 🔄 4. Vérification du load balancing

```bash
for _ in {1..10}; do
  curl --fail --silent "http://ADRESSE_HAPROXY"
done
```

**Preuve à insérer** : alternance visible entre les deux noms de serveur.

---

## 🧯 5. Tolérance à la panne

1. Arrêter temporairement le conteneur du premier backend.
2. Répéter plusieurs requêtes via HAProxy.
3. Vérifier que le second backend traite toutes les requêtes.
4. Redémarrer le premier conteneur et confirmer son retour à l'état `UP`.

**Preuves à insérer** : état HAProxy avant, pendant et après le test.

---

## 📊 6. Statistiques HAProxy

L'URL est fournie par l'output `haproxy_stats_url` et n'est accessible que depuis `your_ip_cidr`.

**Preuve à insérer** : capture anonymisée de la page de statistiques montrant les deux backends.

---

## 🧹 7. Nettoyage

```bash
terraform -chdir=terraform/exercice-3 destroy
unset HAPROXY_STATS_PASSWORD TF_VAR_haproxy_stats_password
```

---

## 📌 Conclusion

Le livrable est prêt à être complété, mais il ne doit être remis qu'après insertion de preuves réelles et vérification qu'aucun secret n'y apparaît.
