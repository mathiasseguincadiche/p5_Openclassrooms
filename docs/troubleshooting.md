# Troubleshooting — diagnostic du projet P5

Ce guide regroupe les problèmes les plus probables du parcours réel. L'objectif
est de diagnostiquer sans supprimer un état Terraform, sans contourner un
garde-fou et sans recréer des ressources au hasard.

## Réflexe de base

Commencer par les journaux du centre de commande :

```bash
bash scripts/commands/p5.sh logs
```

Chaque étape possède son propre fichier sous :

```text
logs/<UTC>/
```

Si un message indique :

```text
[ KO ] ... voir .../XX-etape.log
```

analyser d'abord ce fichier précis.

Pour un diagnostic partageable :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Ne jamais supprimer un `terraform.tfstate` comme méthode de dépannage.

## 1. `p5.sh` demande une reconnexion après le bootstrap

C'est normal sur une VM neuve. Le bootstrap peut ajouter l'utilisateur au groupe
Docker et installer NVM.

Déconnectez-vous, reconnectez-vous puis relancez exactement :

```bash
bash scripts/commands/p5.sh all
```

Le mode reprise réévalue l'environnement.

## 2. Le socle DevOps reste incomplet

Contrôlez :

```bash
bash scripts/commands/p5.sh status
```

Puis, si nécessaire :

```bash
node --version
docker info
terraform version
ansible-playbook --version
aws --version
```

Ne lancez pas Docker avec `sudo` uniquement pour masquer un problème de groupe.

## 3. Mauvais compte AWS ou session expirée

Symptômes :

- identité AWS illisible ;
- compte différent de `P5_EXPECTED_ACCOUNT_ID` ;
- `GO AWS` refusé.

Relancez :

```bash
bash scripts/commands/p5.sh prepare
```

`configure-lab.sh` peut relancer une session SSO si le profil l'utilise.

Diagnostic manuel :

```bash
aws --profile p5-lab sts get-caller-identity
aws configure get region --profile p5-lab
```

Ne modifiez jamais l'identifiant attendu uniquement pour faire correspondre un
mauvais compte actif.

## 4. L'adresse `/32` n'est plus valide

La connexion publique a changé.

La voie recommandée est :

```bash
bash scripts/commands/p5.sh prepare
```

Le script redétecte l'IPv4 publique et resynchronise les tfvars.

En manuel :

```bash
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Ne modifiez pas les trois `terraform.tfvars` séparément.

## 5. `terraform.tfvars` désynchronisés

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

La source de vérité reste `environment/aws-readiness.env`.

## 6. Collision de ressources P5

Ne faites pas :

- suppression du `terraform.tfstate` ;
- suppression immédiate dans la console AWS ;
- changement des tags pour contourner le contrôle.

Vérifiez les états :

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-2 state list
terraform -chdir=terraform/exercice-3 state list
```

Si les états correspondent à des ressources déjà gérées, relancez :

```bash
bash scripts/commands/p5.sh all
```

Le centre de commande active son mode reprise.

## 7. Quota EC2 insuffisant

Vérifiez le quota EC2 Standard de la région. Les exercices 1 et 3 peuvent
coexister et nécessiter plusieurs instances.

Ne réduisez pas arbitrairement `P5_REQUIRED_STANDARD_VCPUS` pour obtenir un faux
`GO AWS`.

## 8. Le budget AWS est absent

Relancez :

```bash
bash scripts/commands/p5.sh prepare
```

Ou manuellement :

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply
```

## 9. Terraform ne trouve pas l'AMI Ubuntu

Commencez par :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

La configuration normale utilise l'AMI Canonical Ubuntu 24.04 LTS sélectionnée
par filtres. Une AMI personnalisée ne doit être configurée que si elle est
réellement nécessaire.

## 10. Ansible ne joint pas l'EC2

Consultez d'abord le log `wait-ssh-ex1` ou `ansible-ping` de la session `p5.sh`.

Puis :

```bash
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
cat ansible/inventories/hosts_aws
ls -l ~/.ssh/p5-key
```

La clé privée doit être en mode restrictif :

```bash
chmod 600 ~/.ssh/p5-key
```

Test direct :

```bash
ssh -i ~/.ssh/p5-key ubuntu@ADRESSE_EC2
```

Puis :

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
```

Vérifiez également le `/32` du groupe de sécurité.

## 11. Le playbook Ansible échoue

Consultez le log `ansible-deploy` produit par `p5.sh`.

Sur l'EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx --no-pager -n 100
```

Le mode `--check --diff` n'est pas un prérequis fiable avant le tout premier
déploiement, car la validation `nginx -t` dépend de NGINX installé. Utilisez-le
plutôt après installation pour une vérification complémentaire.

## 12. L'idempotence Ansible échoue

`p5.sh ex1` rejoue le playbook et exige :

```text
changed=0
unreachable=0
failed=0
```

Si le log `ansible-idempotence` montre `changed>0`, identifiez la tâche qui
modifie encore la cible à chaque exécution. Une tâche réellement stable ne doit
pas produire de changement inutile au second passage.

## 13. L'artefact Angular n'est plus synchronisé

```bash
./scripts/commands/prepare-angular-artifact.sh
./scripts/commands/validate.sh
```

Le script ne remplace l'artefact Ansible qu'après un build Angular réussi.

## 14. Angular répond mais le fallback SPA échoue

```bash
./scripts/commands/verify-angular-deployment.sh
```

Tests manuels :

```bash
curl -i http://ADRESSE_EC2/
curl -i http://ADRESSE_EC2/parcours-p5
```

La configuration NGINX doit conserver un fallback du type :

```text
try_files $uri $uri/ /index.html;
```

## 15. Aucun log NGINX réel n'est disponible

Relancez l'exercice 1 :

```bash
bash scripts/commands/p5.sh ex1
```

Ou manuellement :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 96
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

Le fichier attendu est :

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

## 16. OpenSearch n'est pas accessible

Consultez le log Terraform ou d'import de `p5.sh ex2`.

Puis :

```bash
terraform -chdir=terraform/exercice-2 output
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Causes fréquentes :

- domaine encore en cours de création ;
- IP publique différente du `/32` autorisé ;
- endpoint incorrect ;
- accès HTTP au lieu de HTTPS ;
- session AWS expirée.

## 17. Les données OpenSearch ne passent pas la vérification

`p5.sh ex2` importe d'abord le jeu reproductible, puis le log réel lorsqu'il
existe.

En manuel :

```bash
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log \
  --apply
./scripts/commands/verify-opensearch-data.sh
```

La vérification exige notamment :

- 64 documents minimum ;
- 3 méthodes HTTP ;
- 4 tranches de 12 h ;
- 5 chemins distincts.

Le jeu versionné assure la distribution temporelle ; le log réel prouve le bout
en bout.

## 18. Le dashboard OpenSearch ne montre pas les trois graphiques

Vérifiez d'abord :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Puis contrôlez le data view `nginx-access-*` avec `@timestamp`.

Les trois vues sont :

1. Terms sur `http_method` ;
2. Date histogram `12h` + Sum sur `bytes_sent` ;
3. Date histogram `12h` + Terms taille 5 sur `url_path`.

Cette partie reste volontairement manuelle. `--yes` ne valide pas le checkpoint.

## 19. L'exercice 3 ne trouve pas le VPC

L'exercice 1 doit encore exister.

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

Ne détruisez jamais l'exercice 1 avant l'exercice 3.

## 20. HAProxy ne montre qu'un backend

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 12
```

Sur chaque backend :

```bash
sudo docker ps
sudo docker logs nginx-hello
curl http://localhost/
```

Sur HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

Les health checks utilisent `inter 3s`, `fall 3`, `rise 2`.

## 21. Le test de panne HAProxy échoue

Prévisualisez d'abord :

```bash
./scripts/commands/test-haproxy-failover.sh
```

Puis :

```bash
./scripts/commands/test-haproxy-failover.sh --apply
```

Vérifiez la clé SSH, l'utilisateur `ubuntu`, le `/32` et les outputs Terraform.
Le `trap` tente de redémarrer le backend en cas d'interruption après son arrêt.

## 22. `p5.sh all` a été interrompu

Ne nettoyez pas les états et ne recommencez pas manuellement au hasard.

Relancez :

```bash
bash scripts/commands/p5.sh all
```

Terraform réévalue les états existants et les contrôles fonctionnels sont
rejoués.

## 23. `p5.sh finalize` échoue

Consultez le log `livrables-strict`.

Les causes habituelles sont :

- capture réelle manquante ;
- placeholder encore présent ;
- section obligatoire absente ;
- signature sensible détectée.

Complétez uniquement les preuves réelles puis relancez :

```bash
bash scripts/commands/p5.sh finalize
```

## 24. `check-aws-cleanup.sh` indique un nettoyage incomplet

C'est normal si un exercice existe encore. L'audit est global.

Le verdict final n'est attendu qu'après :

```text
Exercice 3 détruit
Exercice 2 détruit
Exercice 1 détruit
```

Commande recommandée :

```bash
bash scripts/commands/p5.sh cleanup
```

## 25. Un état Terraform manque pendant la destruction

Ne concluez pas que les ressources ont disparu.

```bash
./scripts/commands/check-aws-cleanup.sh
```

Inspectez ensuite AWS avec prudence. La récupération d'un état perdu est une
opération distincte d'un simple nettoyage.

## 26. La CI échoue

Validation locale :

```bash
bash scripts/commands/p5.sh status --full-validation
bash scripts/tests/test-p5-orchestrator.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

La CI protège notamment :

- les trois guides d'exercice ;
- les six SVG ;
- le véritable projet Angular ;
- Terraform et Ansible ;
- les scripts critiques ;
- le centre de commande P5 ;
- la preuve d'idempotence ;
- le flux réel OpenSearch ;
- le checkpoint humain ;
- les liens Markdown ;
- l'absence de fichiers sensibles suivis.

## 27. La CI est verte mais le vrai AWS échoue

C'est possible. La CI teste le dépôt et les intégrations locales sans utiliser
vos credentials AWS réels.

Le premier `p5.sh all` sur la VM reste le test d'intégration AWS final. En cas
d'échec, envoyez le **log de l'étape indiquée** plutôt que de relancer plusieurs
commandes au hasard.
