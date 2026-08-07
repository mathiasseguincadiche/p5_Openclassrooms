# Politique de sécurité

## Données interdites dans le dépôt

Aucun secret ou fichier d’exécution local ne doit être versionné, notamment :

- clés d’accès AWS, jetons de session ou identifiants GitHub ;
- clés privées SSH, certificats privés ou fichiers de credentials ;
- `environment/aws-readiness.env` ;
- `terraform.tfvars`, plans et états Terraform réels ;
- inventaire Ansible réel ;
- journaux, captures ou archives non relus contenant des données sensibles.

Le contrôle local suivant analyse les fichiers suivis par Git :

```bash
python3 scripts/tools/audit_secrets.py
```

Le workflow `CI - Secrets et hygiène` exécute le même contrôle sur chaque pull request et chaque push vers `main`.

## Signaler une fuite

Ne publiez jamais un secret dans une issue ou une pull request. En cas d’exposition :

1. révoquer ou faire tourner immédiatement le secret ;
2. vérifier les journaux d’utilisation du fournisseur concerné ;
3. supprimer le secret de l’état courant du dépôt ;
4. purger l’historique Git lorsque cela est nécessaire ;
5. signaler l’incident au propriétaire du dépôt par un canal privé.

La suppression d’un fichier dans un nouveau commit ne retire pas sa valeur de l’historique Git.
