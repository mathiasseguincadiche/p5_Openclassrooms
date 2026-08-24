# Préparer la soutenance — P5 OpenClassrooms

## Rôle de ce document

Ce fichier prépare **l'organisation de l'oral**. Le conducteur de démonstration officiel est :

[`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md)

Il ne faut pas maintenir deux scénarios de soutenance concurrents. Le handbook contient l'architecture, les explications, les commandes, les preuves navigateur, les questions probables et les plans de repli.

![Architecture globale du P5](schemas/vue-ensemble.svg)

## Ce que l'évaluateur doit comprendre

À la fin de la présentation, le jury doit pouvoir résumer le projet ainsi :

```text
Exercice 1
Terraform crée l'infrastructure AWS
        ↓
Ansible configure l'EC2
        ↓
NGINX sert Angular
        ↓
application visible

Exercice 2
access.log réel
        ↓
OpenSearch
        ↓
3 visualisations + dashboard

Exercice 3
HAProxy
        ↓
2 backends
        ↓
round-robin
        ↓
panne contrôlée
        ↓
service maintenu et backend réintégré
```

## Préparation recommandée

Avant l'oral :

1. reconstruire et valider les trois exercices ;
2. conserver AWS actif ;
3. préparer les URLs Angular, OpenSearch Dashboards et HAProxy ;
4. ouvrir le handbook ;
5. garder les trois schémas d'exercice disponibles ;
6. vérifier les captures de secours ;
7. fermer toute fenêtre contenant un secret ou une donnée sensible.

## Les trois règles de présentation

### 1. Expliquer avant de taper

Avant une commande importante, annoncer :

```text
ce que je veux prouver
→ ce que la commande va vérifier
→ ce que je m'attends à observer
```

### 2. Montrer le résultat réel

```text
Terraform / Ansible / scripts = preuve technique
Navigateur                   = résultat concret
```

Une application web doit être montrée comme une application web. Un dashboard doit être montré comme un dashboard. Un load balancer doit être démontré par le comportement des backends.

### 3. Montrer peu de code, mais le bon code

Ne pas faire défiler des centaines de lignes. Montrer uniquement la source qui répond à la question :

| Question | Source utile |
| --- | --- |
| que crée Terraform ? | `terraform/exercice-1/main.tf` |
| quel type d'EC2 ? | `terraform/exercice-1/variables.tf` |
| que configure Ansible ? | `ansible/playbooks/deploy.yml` |
| comment le dashboard est-il versionné ? | `terraform/exercice-2/opensearch/dashboards/p5-dashboard.json` |
| comment HAProxy répartit-il ? | `terraform/exercice-3/haproxy.cfg.tpl` |

## Checklist juste avant l'oral

- [ ] `main` est à jour ;
- [ ] aucun changement local inattendu ;
- [ ] Ex. 1 est convergé ;
- [ ] Ansible affiche `changed=0` au second passage ;
- [ ] Angular est visible ;
- [ ] le vrai `access.log` existe ;
- [ ] OpenSearch contient les données ;
- [ ] les trois visualisations sont lisibles ;
- [ ] les deux backends HAProxy répondent ;
- [ ] le failover `2 → 1 → 2` a déjà été validé ;
- [ ] les captures de secours sont disponibles ;
- [ ] `cleanup` n'a pas été lancé.

## Pendant l'oral

Ouvrir et suivre :

[`RUNBOOK_SOUTENANCE.md`](RUNBOOK_SOUTENANCE.md)

Le fil conducteur est :

```text
architecture globale
→ exercice 1
→ exercice 2
→ exercice 3
→ dépendances entre exercices
→ conclusion
```

## Après l'oral

Une fois les preuves conservées :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```
