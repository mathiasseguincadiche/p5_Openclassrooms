# Livrables et preuves du P5

OpenClassrooms demande trois ensembles de livrables correspondant aux trois
exercices officiels.

| Exercice | Éléments à remettre | Gabarit du dépôt |
| --- | --- | --- |
| 1 — Terraform et Ansible | Terraform, playbook, NGINX, application Angular et preuves HTTP | [Livrable 1](SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| 2 — OpenSearch | Index, Discover, trois visualisations et dashboard | [Livrable 2](SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| 3 — HAProxy | Configuration, round-robin, panne et réintégration | [Livrable 3](SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |

## Collecte technique

Les scripts écrivent leurs sorties dans un dossier local ignoré par Git :

```text
proofs/runtime/
├── exercice-1/  # HTTP, en-têtes, page Angular et trafic NGINX
├── exercice-2/  # logs, import Bulk, mapping et agrégations
└── exercice-3/  # round-robin, panne et reprise
```

Ces fichiers facilitent la rédaction, mais ils ne remplacent pas les captures
et explications demandées dans les livrables.

## Règles de preuve

- Une zone « preuve à insérer » n’est pas une preuve.
- Les captures et sorties doivent venir du véritable lab.
- Les IP peuvent être masquées partiellement si le résultat reste lisible.
- Aucun secret, clé, mot de passe, identifiant AWS, inventaire réel ou état
  Terraform ne doit apparaître.
- Le livrable 1 doit montrer le build Angular réellement servi par NGINX.
- Le livrable 2 doit contenir exactement le donut, les octets par 12 heures et
  le top 5 des requêtes par 12 heures, puis le dashboard complet.
- Le livrable 3 doit montrer les deux backends avant la panne, un seul pendant
  la panne, puis les deux après la reprise.
- Les commandes et conclusions doivent être expliquées ; une capture seule ne
  démontre pas la compréhension.

## Contrôles

Validation de la structure, utilisable avant le déploiement :

```bash
./scripts/commands/prepare-livrables.sh --structure-only
```

Validation finale stricte :

```bash
./scripts/commands/prepare-livrables.sh
```

Le contrôle final échoue tant que les trois gabarits contiennent des marqueurs
de preuve, une section obligatoire manque ou une clé potentielle est détectée.
Il ne peut toutefois pas juger la qualité visuelle d’une capture : une relecture
humaine reste obligatoire.

## Ordre conseillé

1. exécuter l’exercice ;
2. conserver les sorties sous `proofs/runtime/` ;
3. sélectionner les preuves utiles et anonymiser les données sensibles ;
4. compléter le gabarit correspondant ;
5. exécuter le contrôle strict ;
6. relire les trois documents comme un évaluateur ;
7. détruire les ressources et joindre la preuve de nettoyage.

## Nom et canal de remise

La page de bilan peut demander un ZIP et employer GitLab ou GitHub selon la
version de la consigne. Vérifiez le libellé visible sur la plateforme et
confirmez-le avec le mentor avant la remise finale.
