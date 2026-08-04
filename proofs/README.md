# Preuves d'exécution du P5

Les scripts du dépôt enregistrent leurs résultats techniques sous
`proofs/runtime/`. Ce dossier est volontairement ignoré par Git, car il peut
contenir des adresses publiques, des endpoints, des dates ou d'autres données
propres au lab.

```text
proofs/
├── README.md
└── runtime/                 # créé localement, non versionné
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## Exercice 1

```bash
./scripts/commands/verify-angular-deployment.sh
./scripts/commands/generate-nginx-traffic.sh
```

Conserver :

- le résumé HTTP ;
- les en-têtes NGINX ;
- une capture navigateur de l'application Angular ;
- le récapitulatif de la seconde exécution Ansible.

## Exercice 2

```bash
./scripts/commands/collect-nginx-access-log.sh
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/verify-opensearch-data.sh
```

Conserver :

- la validation des logs réels ou de l'échantillon ;
- les réponses du template, du Bulk et des agrégations ;
- les quatre captures demandées dans OpenSearch Dashboards.

## Exercice 3

```bash
./scripts/commands/test-haproxy-roundrobin.sh
./scripts/commands/test-haproxy-failover.sh
./scripts/commands/test-haproxy-failover.sh --apply
```

La première exécution du test de bascule est une simulation. L'option `--apply`
arrête réellement le conteneur d'un backend, vérifie la continuité du service,
le redémarre et confirme sa réintégration.

## Avant la remise

1. relire chaque log et masquer les données inutiles ;
2. reporter les éléments pertinents dans les trois gabarits de `docs/livrables/` ;
3. remplacer toutes les zones « preuve à insérer » ;
4. exécuter le contrôle strict des livrables ;
5. détruire les ressources AWS et lancer l'audit de nettoyage.

Les fichiers runtime ne doivent jamais être publiés automatiquement. Seules les
preuves relues et anonymisées rejoignent les livrables finaux.
