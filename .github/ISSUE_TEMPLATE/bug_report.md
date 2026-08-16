---
name: Bug Report
about: Signaler un bug dans la documentation ou l’implémentation du P5
title: "[BUG] "
labels: bug
assignees: ''

---

## 🐛 Description du bug

**Décrivez clairement le bug que vous avez rencontré.**

- **Où le bug se produit-il ?** (ex. : préparation dans `ubuntu-devops`, exercice 1, module Terraform, playbook Ansible, documentation)
- **Quelle est l'erreur exacte ?** (copiez-collez le message d'erreur après avoir retiré les secrets)
- **Quelles étapes reproduisent le bug ?**

---

## 🔍 Étapes pour reproduire

1. Dans la VM `ubuntu-devops`, allez dans...
2. Exécutez la commande...
3. Observez que...

---

## 📋 Informations complémentaires

- **Version de l'outil concerné** (ex. : Terraform, Ansible, AWS CLI, Node.js, Docker, HAProxy) :
- **Runtime P5** : Ubuntu Server 26.04 dans `ubuntu-devops`
- **Résultat de `hostname -s`** :
- **Résultat de `systemd-detect-virt`** :
- **Fichier concerné** (si applicable) :
- **Lien vers le fichier** (si applicable) :

Si le problème concerne le HOST Ubuntu, KVM/libvirt, le réseau virtuel ou le cycle de vie de `ubuntu-devops`, il relève du dépôt `mathiasseguincadiche/Ubuntu-desktops-custom` et non du P5.

---

## 💡 Solution proposée (optionnel)

Si vous avez une idée de la solution, décrivez-la ici.

---

## ⚠️ Sécurité

- [ ] Ce bug n'implique pas de problème de sécurité.
- [ ] Ce bug implique un problème de sécurité (merci de ne pas partager de détails sensibles).
- [ ] Les logs joints ne contiennent ni credential AWS, ni clé SSH privée, ni state/tfvars sensibles.

---

**Merci pour votre rapport.**
