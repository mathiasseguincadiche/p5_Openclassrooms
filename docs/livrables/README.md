# Livrables et preuves du P5

Ce dossier contient les **trois structures de livrables** correspondant aux trois
exercices du projet. Leur rôle est d’organiser les preuves réelles, pas de les
remplacer.

## Principe essentiel

```text
Code présent ≠ exercice exécuté
Gabarit présent ≠ preuve produite
Sortie runtime brute ≠ livrable publiable
```

Une preuve valide doit :

1. provenir du véritable lab ;
2. démontrer un résultat précis ;
3. rester lisible ;
4. être expliquée ;
5. ne contenir aucun secret ou détail sensible inutile.

## Les trois livrables

| Exercice | Ce qui doit être démontré | Gabarit |
| --- | --- | --- |
| 1 — Terraform + Ansible | infrastructure, déploiement NGINX/Angular, idempotence | [Livrable 1](SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| 2 — OpenSearch | données, Discover, 3 visualisations et dashboard | [Livrable 2](SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| 3 — HAProxy | config, round-robin, panne, continuité et reprise | [Livrable 3](SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |

## D’où viennent les preuves ?

Les scripts conservent leurs sorties techniques sous :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Ce dossier est ignoré par Git et **privé par défaut**.

La documentation complète du cycle de preuve se trouve dans
[Validation, preuves, publication et nettoyage](../validation-preuves-nettoyage.md).

## Exercice 1 — preuves minimales

### Terraform

- `terraform validate` réussi ;
- plan relu ;
- ressources attendues identifiables ;
- `apply` réussi ;
- EC2 active.

### Ansible

- ping de la cible ;
- première exécution du playbook ;
- seconde exécution démontrant l’idempotence ;
- aucune tâche en échec.

### Application

- application Angular réelle dans un navigateur ;
- NGINX valide ;
- bundle JavaScript chargé ;
- fallback SPA ;
- verdict :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

### Dépendance de nettoyage

Le réseau de l’exercice 1 est réutilisé par l’exercice 3. **La destruction de
l’exercice 1 n’est donc pas une étape à effectuer juste après le livrable 1.**

## Exercice 2 — preuves minimales

- domaine OpenSearch actif ;
- index `nginx-access-*` ;
- données visibles dans Discover ;
- mapping exploitable ;
- verdict :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Puis quatre captures :

1. donut des méthodes HTTP ;
2. somme des octets par tranches de 12 h ;
3. top 5 des URL par tranches de 12 h ;
4. dashboard complet.

OpenSearch peut être détruit après ces captures afin de limiter les coûts.

## Exercice 3 — preuves minimales

- trois EC2 actives ;
- `haproxy.cfg` lisible ;
- `haproxy -c` réussi ;
- deux backends en round-robin ;
- un backend pendant la panne ;
- service disponible pendant cette panne ;
- deux backends après la reprise ;
- verdict :

```text
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## État d’une preuve

| État | Exemple | Peut être publié ? |
| --- | --- | --- |
| Brut | log, endpoint, sortie CLI complète | non |
| Sélectionné | extrait utile | après relecture |
| Anonymisé | IP ou identifiant masqué si inutile | oui |
| Contextualisé | preuve + commande + explication | oui, état recommandé |

## Règles d’anonymisation

Ne jamais publier :

- clé AWS ;
- jeton de session ;
- clé privée SSH ;
- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- état Terraform ;
- inventaire Ansible réel ;
- en-tête d’autorisation ;
- archive ou journal runtime non relu.

Les IP, endpoints, ARNs et identifiants peuvent être masqués partiellement
lorsque leur valeur exacte n’est pas nécessaire pour comprendre la preuve.

## Une capture seule n’est pas suffisante

Pour chaque preuve importante, expliquer :

- **ce qui est exécuté** ;
- **ce que montre la sortie** ;
- **pourquoi le résultat valide l’exercice**.

Exemple de structure :

```text
Commande : test-haproxy-roundrobin.sh --requests 10
Résultat : deux valeurs distinctes de Server name sont observées.
Conclusion : HAProxy répartit bien les requêtes entre les deux backends.
```

## Contrôle avant exécution réelle

La CI utilise :

```bash
./scripts/commands/prepare-livrables.sh --structure-only
```

Ce mode vérifie :

- présence des trois fichiers ;
- sections obligatoires ;
- composants associés ;
- absence de signatures de secrets évidentes.

Il **n’exige pas encore les preuves réelles**.

## Contrôle strict avant remise

```bash
./scripts/commands/prepare-livrables.sh
```

Ce mode échoue si un marqueur de preuve reste présent, par exemple :

```text
Gabarit à compléter
Preuve à insérer
Capture réelle à insérer
À joindre
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Ordre de travail recommandé

Pour chaque exercice :

1. lire le guide ;
2. exécuter réellement ;
3. conserver les sorties techniques ;
4. capturer les éléments visuels demandés ;
5. sélectionner les preuves ;
6. anonymiser ;
7. compléter le livrable ;
8. relire comme un évaluateur.

Puis, une fois les trois exercices terminés :

1. lancer l’audit des secrets ;
2. exécuter le contrôle strict des livrables ;
3. détruire AWS dans l’ordre 3 → 2 → 1 ;
4. lancer l’audit global du nettoyage.

## Nettoyage et preuve finale

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

Ce verdict concerne **l’ensemble du projet**, pas un seul exercice.

## Canal de remise

Les formulations fournies par OpenClassrooms peuvent varier selon la version de
la plateforme (GitHub/GitLab, ZIP ou liens). La consigne visible au moment de la
remise et les indications du mentor restent prioritaires.

Le dépôt organise le contenu technique indépendamment du canal final choisi.

## Documents associés

- [Traçabilité consignes → code → preuves](../02-correspondance-consignes-depot.md)
- [Runbook complet](../01-parcours-debutant.md)
- [Validation et nettoyage](../validation-preuves-nettoyage.md)
- [Convention des preuves runtime](../../proofs/README.md)
- [Sécurité](../../SECURITY.md)
