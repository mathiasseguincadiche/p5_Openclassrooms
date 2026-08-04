# 📋 Cheatsheet Git

**Bienvenue dans le cheatsheet Git !**
Cette page regroupe les **commandes Git les plus utiles** pour les débutants et les utilisateurs avancés.

---

## 📌 Table des Matières

1. [Installation](#-installation)
2. [Configuration](#configuration)
3. [Commandes de Base](#-commandes-de-base)
4. [Branches](#-branches)
5. [Commits](#-commits)
6. [Dépôt Distant](#depot-distant)
7. [Collaboration](#-collaboration)
8. [Historique](#-historique)
9. [Annulation](#-annulation)
10. [Tags](#tags)
11. [Stash](#-stash)
12. [Rebase](#-rebase)
13. [Merge](#-merge)
14. [Dépannage](#depannage)

---

## 📥 Installation

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git
```

### macOS

```bash
brew install git
```

### Windows

1. Téléchargez [Git for Windows](https://gitforwindows.org/).
2. Installez Git avec les options par défaut.

### Vérifier l'installation

```bash
git --version
```

---

<a id="configuration"></a>

## ⚙️ Configuration

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git config --global user.name <name>` | Configurer le nom d'utilisateur | `git config --global user.name "John Doe"` |
| `git config --global user.email <email>` | Configurer l'email | `git config --global user.email "john@example.com"` |
| `git config --global core.editor <editor>` | Configurer l'éditeur | `git config --global core.editor "nano"` |
| `git config --global init.defaultBranch <branch>` | Configurer la branche par défaut | `git config --global init.defaultBranch main` |
| `git config --global color.ui true` | Activer les couleurs | `git config --global color.ui true` |
| `git config --list` | Lister toutes les configurations | `git config --list` |
| `git config <key>` | Afficher une configuration | `git config user.name` |

---

## 🚀 Commandes de Base

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git init` | Initialiser un dépôt Git | `git init` |
| `git status` | Afficher l'état du dépôt | `git status` |
| `git add <file>` | Ajouter un fichier à l'index | `git add README.md` |
| `git add .` | Ajouter tous les fichiers | `git add .` |
| `git add -A` | Ajouter tous les fichiers (y compris supprimés) | `git add -A` |
| `git add -p` | Ajouter interactivement | `git add -p` |
| `git diff` | Afficher les modifications non indexées | `git diff` |
| `git diff --staged` | Afficher les modifications indexées | `git diff --staged` |
| `git diff <commit>` | Afficher les modifications depuis un commit | `git diff HEAD~1` |
| `git diff <branch1> <branch2>` | Afficher les différences entre deux branches | `git diff main dev` |
| `git mv <old> <new>` | Renommer un fichier | `git mv old.txt new.txt` |
| `git rm <file>` | Supprimer un fichier | `git rm file.txt` |
| `git rm --cached <file>` | Supprimer un fichier de l'index (garder localement) | `git rm --cached file.txt` |
| `git clean -fd` | Supprimer les fichiers non suivis | `git clean -fd` |
| `git reset` | Réinitialiser l'index | `git reset` |
| `git reset --hard` | Réinitialiser l'index et le répertoire de travail | `git reset --hard` |

---

## 🌿 Branches

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git branch` | Lister les branches locales | `git branch` |
| `git branch -a` | Lister toutes les branches (locales + distantes) | `git branch -a` |
| `git branch -r` | Lister les branches distantes | `git branch -r` |
| `git branch <name>` | Créer une nouvelle branche | `git branch feature/login` |
| `git branch -d <name>` | Supprimer une branche locale | `git branch -d feature/login` |
| `git branch -D <name>` | Supprimer une branche locale (forcé) | `git branch -D feature/login` |
| `git checkout <branch>` | Changer de branche | `git checkout main` |
| `git checkout -b <branch>` | Créer et changer de branche | `git checkout -b feature/login` |
| `git switch <branch>` | Changer de branche (Git 2.23+) | `git switch main` |
| `git switch -c <branch>` | Créer et changer de branche (Git 2.23+) | `git switch -c feature/login` |
| `git push origin <branch>` | Pousser une branche vers le dépôt distant | `git push origin feature/login` |
| `git push origin -d <branch>` | Supprimer une branche distante | `git push origin -d feature/login` |
| `git fetch` | Récupérer les branches distantes | `git fetch` |
| `git pull` | Récupérer et fusionner les modifications distantes | `git pull` |
| `git pull origin <branch>` | Récupérer et fusionner une branche distante | `git pull origin main` |

---

## 📝 Commits

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git commit` | Commiter les modifications indexées | `git commit` |
| `git commit -m <message>` | Commiter avec un message | `git commit -m "fix: corrige le bug de connexion"` |
| `git commit -a -m <message>` | Commiter tous les fichiers modifiés | `git commit -a -m "fix: corrige le bug"` |
| `git commit --amend` | Modifier le dernier commit | `git commit --amend` |
| `git commit --amend -m <message>` | Modifier le message du dernier commit | `git commit --amend -m "nouveau message"` |
| `git commit -C <commit>` | Réutiliser le message d'un commit | `git commit -C HEAD~1` |
| `git show <commit>` | Afficher les détails d'un commit | `git show abc123` |
| `git show` | Afficher les détails du dernier commit | `git show` |
| `git log` | Afficher l'historique des commits | `git log` |
| `git log --oneline` | Afficher l'historique en une ligne | `git log --oneline` |
| `git log --graph` | Afficher l'historique sous forme de graphe | `git log --graph` |
| `git log --author=<name>` | Afficher les commits d'un auteur | `git log --author="John Doe"` |
| `git log --grep=<pattern>` | Afficher les commits avec un message correspondant | `git log --grep="fix:"` |
| `git log -p` | Afficher les modifications de chaque commit | `git log -p` |
| `git log --stat` | Afficher les statistiques des commits | `git log --stat` |

---

<a id="depot-distant"></a>

## ☁️ Dépôt Distant

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git remote` | Lister les dépôts distants | `git remote` |
| `git remote -v` | Lister les dépôts distants avec les URLs | `git remote -v` |
| `git remote add <name> <url>` | Ajouter un dépôt distant | `git remote add origin https://github.com/user/repo.git` |
| `git remote remove <name>` | Supprimer un dépôt distant | `git remote remove origin` |
| `git remote rename <old> <new>` | Renommer un dépôt distant | `git remote rename origin upstream` |
| `git remote set-url <name> <url>` | Modifier l'URL d'un dépôt distant | `git remote set-url origin https://github.com/user/repo.git` |
| `git push` | Pousser les modifications vers le dépôt distant | `git push` |
| `git push -u <remote> <branch>` | Pousser et définir la branche upstream | `git push -u origin main` |
| `git push --all` | Pousser toutes les branches | `git push --all` |
| `git push --tags` | Pousser tous les tags | `git push --tags` |
| `git pull` | Récupérer et fusionner les modifications distantes | `git pull` |
| `git fetch` | Récupérer les modifications distantes sans fusion | `git fetch` |
| `git clone <url>` | Cloner un dépôt | `git clone https://github.com/user/repo.git` |
| `git clone <url> <dir>` | Cloner un dépôt dans un dossier spécifique | `git clone https://github.com/user/repo.git mon-projet` |

---

## 🤝 Collaboration

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git fork` | Forker un dépôt (GitHub CLI) | `gh repo fork user/repo` |
| `git pull-request` | Créer une pull request (GitHub CLI) | `gh pr create` |
| `git merge <branch>` | Fusionner une branche | `git merge feature/login` |
| `git merge --no-ff <branch>` | Fusionner sans fast-forward | `git merge --no-ff feature/login` |
| `git merge --abort` | Annuler une fusion | `git merge --abort` |
| `git rebase <branch>` | Rebase une branche | `git rebase main` |
| `git rebase --abort` | Annuler un rebase | `git rebase --abort` |
| `git rebase --continue` | Continuer un rebase | `git rebase --continue` |
| `git cherry-pick <commit>` | Appliquer un commit sur la branche actuelle | `git cherry-pick abc123` |

---

## 📜 Historique

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git log` | Afficher l'historique des commits | `git log` |
| `git log --oneline` | Afficher l'historique en une ligne | `git log --oneline` |
| `git log --graph --oneline` | Afficher l'historique sous forme de graphe | `git log --graph --oneline` |
| `git log --author=<name>` | Afficher les commits d'un auteur | `git log --author="John Doe"` |
| `git log --since=<date>` | Afficher les commits depuis une date | `git log --since="2024-01-01"` |
| `git log --until=<date>` | Afficher les commits jusqu'à une date | `git log --until="2024-01-01"` |
| `git log --grep=<pattern>` | Afficher les commits avec un message correspondant | `git log --grep="fix:"` |
| `git log -p` | Afficher les modifications de chaque commit | `git log -p` |
| `git log --stat` | Afficher les statistiques des commits | `git log --stat` |
| `git log -- <file>` | Afficher l'historique d'un fichier | `git log -- README.md` |
| `git blame <file>` | Afficher qui a modifié chaque ligne d'un fichier | `git blame README.md` |
| `git shortlog` | Afficher un résumé des commits par auteur | `git shortlog` |

---

## ⏪ Annulation

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git revert <commit>` | Créer un commit qui annule un autre commit | `git revert abc123` |
| `git revert HEAD` | Annuler le dernier commit | `git revert HEAD` |
| `git reset --soft <commit>` | Réinitialiser l'index (garder les modifications) | `git reset --soft HEAD~1` |
| `git reset --mixed <commit>` | Réinitialiser l'index (par défaut) | `git reset HEAD~1` |
| `git reset --hard <commit>` | Réinitialiser l'index et le répertoire de travail | `git reset --hard HEAD~1` |
| `git reset --hard origin/<branch>` | Réinitialiser à l'état de la branche distante | `git reset --hard origin/main` |
| `git checkout -- <file>` | Annuler les modifications d'un fichier | `git checkout -- README.md` |
| `git clean -fd` | Supprimer les fichiers non suivis | `git clean -fd` |

---

<a id="tags"></a>

## 🏷️ Tags

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git tag` | Lister les tags | `git tag` |
| `git tag <name>` | Créer un tag léger | `git tag v1.0.0` |
| `git tag -a <name> -m <message>` | Créer un tag annoté | `git tag -a v1.0.0 -m "Version 1.0.0"` |
| `git tag -l <pattern>` | Lister les tags avec un motif | `git tag -l "v1.*"` |
| `git show <tag>` | Afficher les détails d'un tag | `git show v1.0.0` |
| `git push --tags` | Pousser tous les tags | `git push --tags` |
| `git push origin <tag>` | Pousser un tag spécifique | `git push origin v1.0.0` |
| `git tag -d <name>` | Supprimer un tag local | `git tag -d v1.0.0` |
| `git push origin -d <tag>` | Supprimer un tag distant | `git push origin -d v1.0.0` |

---

## 📦 Stash

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git stash` | Stasher les modifications | `git stash` |
| `git stash -u` | Stasher les modifications + fichiers non suivis | `git stash -u` |
| `git stash -a` | Stasher toutes les modifications | `git stash -a` |
| `git stash list` | Lister les stashes | `git stash list` |
| `git stash show` | Afficher le dernier stash | `git stash show` |
| `git stash show <stash>` | Afficher un stash spécifique | `git stash show stash@{0}` |
| `git stash pop` | Appliquer et supprimer le dernier stash | `git stash pop` |
| `git stash apply` | Appliquer le dernier stash (sans supprimer) | `git stash apply` |
| `git stash apply <stash>` | Appliquer un stash spécifique | `git stash apply stash@{0}` |
| `git stash drop` | Supprimer le dernier stash | `git stash drop` |
| `git stash drop <stash>` | Supprimer un stash spécifique | `git stash drop stash@{0}` |
| `git stash clear` | Supprimer tous les stashes | `git stash clear` |

---

## 🔄 Rebase

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git rebase <branch>` | Rebase la branche actuelle sur une autre branche | `git rebase main` |
| `git rebase -i <commit>` | Rebase interactif | `git rebase -i HEAD~3` |
| `git rebase --continue` | Continuer un rebase | `git rebase --continue` |
| `git rebase --abort` | Annuler un rebase | `git rebase --abort` |
| `git rebase --skip` | Ignorer un commit pendant un rebase | `git rebase --skip` |
| `git pull --rebase` | Récupérer et rebase les modifications distantes | `git pull --rebase` |

---

## 🔀 Merge

| Commande | Description | Exemple |
|----------|-------------|---------|
| `git merge <branch>` | Fusionner une branche | `git merge feature/login` |
| `git merge --no-ff <branch>` | Fusionner sans fast-forward | `git merge --no-ff feature/login` |
| `git merge --abort` | Annuler une fusion | `git merge --abort` |
| `git merge --continue` | Continuer une fusion | `git merge --continue` |
| `git merge -X<strategy-option> <branch>` | Fusionner avec une option de stratégie | `git merge -Xours feature/login` |
| `git mergetool` | Ouvrir l'outil de fusion | `git mergetool` |

---

<a id="depannage"></a>

## 🛠️ Dépannage

| Problème | Solution | Commande |
|----------|----------|----------|
| `fatal: not a git repository` | Le dossier n'est pas un dépôt Git | `git init` |
| `fatal: 'origin' does not appear to be a git repository` | Le dépôt distant n'existe pas | `git remote add origin <url>` |
| `fatal: refusing to merge unrelated histories` | Fusion de deux dépôts non liés | `git pull --allow-unrelated-histories` |
| `fatal: Authentication failed` | Problème d'authentification | Vérifiez vos clés SSH ou tokens |
| `fatal: remote origin already exists` | Le dépôt distant existe déjà | `git remote set-url origin <url>` |
| `error: pathspec 'branch' did not match any file(s)` | La branche n'existe pas | `git fetch` puis `git checkout <branch>` |
| `error: Your local changes would be overwritten` | Modifications locales non commitées | `git stash` ou `git commit` |
| `error: failed to push some refs` | Conflit avec le dépôt distant | `git pull` puis `git push` |

---

## 📚 Conventions de Commit

### Conventional Commits

Utilisez des messages de commit **structurés** pour faciliter la lecture de l'historique.

| Type | Description | Exemple |
|------|-------------|---------|
| `feat:` | Nouvelle fonctionnalité | `feat: ajoute un bouton de partage` |
| `fix:` | Correction de bug | `fix: corrige le bug de connexion` |
| `docs:` | Modification de la documentation | `docs: met à jour le README` |
| `style:` | Changements de style (indentation, etc.) | `style: corrige l'indentation` |
| `refactor:` | Refactorisation du code | `refactor: extrait une fonction` |
| `test:` | Ajout ou modification de tests | `test: ajoute des tests unitaires` |
| `chore:` | Tâches de maintenance | `chore: met à jour les dépendances` |
| `perf:` | Amélioration des performances | `perf: optimise la requête SQL` |
| `build:` | Modification du build | `build: met à jour Dockerfile` |
| `ci:` | Modification de la CI/CD | `ci: ajoute un workflow GitHub Actions` |

### Exemple de Message de Commit

```
feat: ajoute un endpoint /api/users

- Ajoute un nouveau endpoint pour lister les utilisateurs
- Utilise une base de données PostgreSQL
- Inclut des tests unitaires

Closes #123
```

---

## 📚 Ressources

- [Documentation Officielle Git](https://git-scm.com/doc)
- [Git Cheatsheet Officiel](https://github.github.com/training-kit/downloads/github-git-cheat-sheet.pdf)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Git Handbook](https://guides.github.com/introduction/git-handbook/)

---

**Bonne utilisation de Git !** 🚀
