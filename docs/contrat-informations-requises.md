# Contrat des informations requises

Le projet P5 applique une règle stricte lorsqu'une information n'est pas disponible.

```text
DÉTECTER / LIRE LA SOURCE RÉELLE
            ↓
      valeur disponible ?
        ┌───────┴───────┐
       oui             non
        │               │
   VALIDER LE       CLASSER LA
     FORMAT          VALEUR
                        │
             ┌──────────┴──────────┐
             │                     │
      valeur opérateur       valeur authoritative
             │                     │
       EXPLIQUER +             NE PAS INVENTER
       DEMANDER              BLOQUER + EXPLIQUER
             │                     │
       VALIDER +               RÉTABLIR AWS /
       ENREGISTRER             TERRAFORM / SOURCE
```

## Pourquoi ce contrat existe

Un script ne doit jamais :

- supposer qu'une valeur d'exemple est réelle ;
- transformer une détection impossible en une fausse valeur ;
- afficher uniquement « invalide ou absent » sans expliquer quoi faire ;
- demander à l'opérateur d'inventer une valeur qui doit venir d'AWS ou Terraform ;
- continuer silencieusement avec une preuve incomplète.

## 1. Valeurs que l'opérateur peut fournir

Lorsqu'une valeur dépend réellement de l'opérateur et que la détection automatique
échoue, le terminal doit afficher :

1. **le nom de l'information** ;
2. **pourquoi elle est nécessaire** ;
3. **le format attendu** ;
4. **un exemple** ;
5. **comment la transmettre** dans le terminal ou via une option CLI ;
6. **une validation du format** avant utilisation.

Exemple attendu :

```text
P5  INFORMATION REQUISE — IPv4 publique actuelle

[INFO] Elle sert à limiter SSH et OpenSearch à votre connexion actuelle.
       Format attendu : IPv4 seule, sans /32
       Exemple        : 198.51.100.42
       Transmission   : saisissez-la ici ou utilisez --public-ip 198.51.100.42

IPv4 publique actuelle :
```

Le script ajoute ensuite `/32`, valide le CIDR et enregistre la valeur dans
`environment/aws-readiness.env`.

### Valeurs concernées

| Information | Détection normale | Fallback opérateur |
| --- | --- | --- |
| IPv4 publique | `checkip.amazonaws.com` | saisie IPv4 ou `--public-ip` |
| e-mail budget | configuration locale | saisie e-mail ou `--budget-email` |
| clé SSH existante | configuration/fichier | chemin ou `--ssh-key` |
| profil AWS existant | `aws configure list-profiles` | sélection/saisie du nom exact |
| URL Angular/NGINX de diagnostic | output Terraform | `--url` ou saisie manuelle |
| hôte NGINX de diagnostic | output Terraform | `--host` ou saisie manuelle |
| endpoint OpenSearch de diagnostic | output Terraform | `--endpoint` ou saisie manuelle |
| URL HAProxy de diagnostic | output Terraform | `--url` ou saisie manuelle |
| backend HAProxy de diagnostic | output Terraform | `--backend-host` ou saisie manuelle |

Les overrides manuels servent principalement au **diagnostic**. Le parcours normal
`p5.sh all` continue de privilégier les valeurs provenant de Terraform.

## 2. Valeurs qui ne doivent pas être inventées

Certaines informations sont des preuves de l'état réel. Une saisie manuelle ne
constituerait pas une preuve fiable.

### Compte et identité AWS

Le compte actif doit venir de :

```bash
aws sts get-caller-identity
```

Si STS ne répond pas, le projet ne demande pas « quel est votre Account ID ? ».
Il indique que l'identité n'est pas vérifiable et demande de rétablir la session.

### Credentials temporaires

La présence de `SessionToken` et `Expiration` doit être vérifiée par AWS CLI.
Elle ne peut pas être confirmée par une simple saisie utilisateur.

### Outputs Terraform d'infrastructure

Pour le parcours normal, les adresses et endpoints d'infrastructure doivent venir
de Terraform :

```text
web_public_ip
web_url
opensearch_endpoint
opensearch_dashboards_endpoint
haproxy_url
hello_1_public_ip
hello_2_public_ip
```

Si un output nécessaire à une étape orchestrée n'est pas disponible, le bon
comportement est :

```text
[INCONNU] sortie Terraform ...
[ACTION REQUISE] relancer l'exercice concerné / consulter le log tf-ex*-*
```

et non une valeur inventée.

### Nettoyage AWS

L'audit final doit vérifier le **compte actif réel** et interroger AWS. Si le
compte ou la session n'est pas vérifiable, le nettoyage n'est pas déclaré complet.

## 3. Observation et exécution ne se comportent pas de la même façon

### `inspect`, `status`, `--check`

Ces commandes sont non mutantes et non interactives par principe.

Si une information manque :

```text
INCONNU / KO bloquant
+ raison
+ action exacte pour la renseigner ou rétablir la source
```

Elles ne doivent pas ouvrir une collecte interactive.

### `prepare`, `all` et scripts de diagnostic interactifs

Ces commandes peuvent demander une valeur opérateur lorsqu'elle est réellement
nécessaire et impossible à détecter.

Le collecteur principal reste :

```bash
bash scripts/commands/p5.sh prepare
```

Le parcours complet l'exécute automatiquement :

```bash
bash scripts/commands/p5.sh all
```

## 4. Source de vérité locale

Les valeurs opérateur persistantes sont centralisées dans :

```text
environment/aws-readiness.env
```

Ce fichier :

- est ignoré par Git ;
- est protégé en mode `600` ;
- ne contient aucune clé AWS ;
- alimente les trois `terraform.tfvars` ;
- évite de redemander une valeur déjà connue et encore valide.

## 5. Réexécution

Une valeur déjà connue n'est pas redemandée sans raison.

Exemples :

- session AWS valide → réutilisée ;
- e-mail budget valide → conservé ;
- clé SSH présente → conservée ;
- tfvars cohérents → non réécrits ;
- output Terraform disponible → relu automatiquement.

En revanche, une valeur détectable qui a changé, comme l'IPv4 publique, est
réévaluée afin de refléter la réalité actuelle.

## 6. Contrat CI

Le test suivant protège ce comportement :

```bash
bash scripts/tests/test-operator-input-contract.sh
```

Il vérifie notamment :

- les fonctions communes `p5_unknown`, `p5_prompt_value` et
  `p5_authoritative_unknown` ;
- les validateurs e-mail, IPv4, CIDR et URL ;
- l'affichage `quoi / pourquoi / format / exemple / transmission` ;
- les fallbacks `configure-lab.sh` ;
- les overrides de diagnostic Angular, NGINX, OpenSearch et HAProxy ;
- la protection des outputs Terraform utilisés par l'inventaire Ansible ;
- la séparation entre observation non mutante et collecte interactive.

## Règle finale

> **Si le projet peut connaître une valeur : il la détecte et la vérifie.**
>
> **S'il ne peut pas connaître une valeur que l'opérateur est légitime à fournir :
> il explique exactement ce qu'il attend puis la demande et la valide.**
>
> **Si la valeur doit obligatoirement provenir d'AWS ou Terraform : il ne l'invente
> jamais ; il bloque et explique comment rétablir la source réelle.**
