# 📁 Templates Kubernetes

**Bienvenue dans la section des templates Kubernetes !**
Ici, vous trouverez des **fichiers de configuration prêts à l'emploi** pour Kubernetes, **commentés et expliqués** pour déployer vos applications sur un cluster.

---

## 📌 Table des Matières

1. [Déploiement (Deployment)](#-déploiement-deployment)
2. [Service](#-service)
3. [Ingress](#-ingress)
4. [ConfigMap](#-configmap)
5. [Secret](#-secret)
6. [Bonnes Pratiques](#-bonnes-pratiques)

---

## 📄 Déploiement (Deployment)

**Fichier** : [`deployment.yaml`](deployment.yaml)

**Description** : Template pour **déployer une application** sur Kubernetes avec un `Deployment`. Un `Deployment` permet de :

- Définir le **nombre de réplicas** (pods) à maintenir.
- Effectuer des **rolling updates** (mises à jour sans temps d'arrêt).
- **Revenir en arrière** (rollback) en cas d'erreur.

**Cas d'Usage** :

- Déploiement d'une application conteneurisée.
- Mise à l'échelle d'une application.
- Gestion des mises à jour.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/kubernetes/deployment.yaml ./deployment.yaml

# 2. Personnalisez le fichier (ex: changez le nom de l'image, le nombre de réplicas)

# 3. Appliquez le déploiement
kubectl apply -f deployment.yaml

# 4. Vérifiez le déploiement
kubectl get deployments
kubectl get pods
```

---

## 📄 Service

**Fichier** : [`service.yaml`](service.yaml)

**Description** : Template pour **exposer une application** avec un `Service`. Un `Service` permet de :

- **Exposer** une application en interne ou en externe.
- **Équilibrer la charge** entre plusieurs pods.
- **Stabiliser** les adresses IP et les ports.

**Cas d'Usage** :

- Exposer une application en interne (ClusterIP).
- Exposer une application sur un port du nœud (NodePort).
- Exposer une application via un load balancer (LoadBalancer).

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/kubernetes/service.yaml ./service.yaml

# 2. Personnalisez le fichier (ex: changez le type de service, le port)

# 3. Appliquez le service
kubectl apply -f service.yaml

# 4. Vérifiez le service
kubectl get services
```

---

## 📄 Ingress

**Fichier** : [`ingress.yaml`](ingress.yaml)

**Description** : Template pour **configurer un Ingress** pour accéder à votre application via HTTP/HTTPS. Un `Ingress` permet de :

- **Router le trafic** vers différents services en fonction du chemin ou du nom d'hôte.
- **Configurer des règles HTTP/HTTPS**.
- **Terminer le TLS/SSL** (avec des certificats).

**Cas d'Usage** :

- Exposer plusieurs applications sous le même domaine.
- Router le trafic en fonction du chemin (ex: `/app`, `/api`).
- Configurer des certificats TLS/SSL.

**Exemple d'utilisation** :

```bash
# 1. Installez un Ingress Controller (ex: NGINX Ingress Controller)
#    Pour Minikube : minikube addons enable ingress
#    Pour Kind : helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.type=NodePort

# 2. Copiez le template dans votre projet
cp TEMPLATES/kubernetes/ingress.yaml ./ingress.yaml

# 3. Personnalisez le fichier (ex: changez le nom d'hôte, le chemin)

# 4. Appliquez l'Ingress
kubectl apply -f ingress.yaml

# 5. Vérifiez l'Ingress
kubectl get ingress
```

---

## 📄 ConfigMap

**Fichier** : [`configmap.yaml`](configmap.yaml)

**Description** : Template pour **stocker des configurations non sensibles** avec un `ConfigMap`. Un `ConfigMap` permet de :

- Stocker des **variables d'environnement**.
- Stocker des **fichiers de configuration**.
- **Séparer la configuration du code**.

**Cas d'Usage** :

- Configuration d'une application (ex: variables d'environnement).
- Fichiers de configuration (ex: `nginx.conf`, `application.properties`).

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/kubernetes/configmap.yaml ./configmap.yaml

# 2. Personnalisez le fichier (ex: ajoutez vos variables ou fichiers)

# 3. Appliquez le ConfigMap
kubectl apply -f configmap.yaml

# 4. Utilisez le ConfigMap dans un déploiement
#    envFrom:
#    - configMapRef:
#        name: mon-configmap
```

---

## 📄 Secret

**Fichier** : [`secret.yaml`](secret.yaml)

**Description** : Template pour **stocker des données sensibles** avec un `Secret`. Un `Secret` permet de :

- Stocker des **mots de passe**.
- Stocker des **clés API**.
- Stocker des **certificats TLS/SSL**.

**Cas d'Usage** :

- Mots de passe de base de données.
- Clés API pour des services externes.
- Certificats TLS/SSL.

**Exemple d'utilisation** :

```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/kubernetes/secret.yaml ./secret.yaml

# 2. Personnalisez le fichier (ex: ajoutez vos secrets encodés en base64)
#    Pour encoder une valeur : echo -n "valeur" | base64

# 3. Appliquez le Secret
kubectl apply -f secret.yaml

# 4. Utilisez le Secret dans un déploiement
#    env:
#    - name: DB_PASSWORD
#      valueFrom:
#        secretKeyRef:
#          name: mon-secret
#          key: db_password
```

---

## 🌟 Bonnes Pratiques

### 1. Utilisez des Manifestes Déclaratifs

- Définissez l'**état souhaité** de votre application dans des fichiers YAML.
- Évitez d'utiliser `kubectl create` ou `kubectl run` en production.

### 2. Gérez les Configurations avec ConfigMaps et Secrets

- **Ne hardcodez pas** les configurations dans les manifests.
- Utilisez des **ConfigMaps** pour les configurations non sensibles.
- Utilisez des **Secrets** pour les données sensibles.

### 3. Utilisez des Liveness et Readiness Probes

- **Liveness Probe** : Vérifie si le conteneur est **en vie** (redémarre si échec).
- **Readiness Probe** : Vérifie si le conteneur est **prêt à recevoir du trafic**.

Exemple :

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

### 4. Limitez les Ressources

- Définissez des **limites de CPU et mémoire** pour éviter qu'un conteneur ne consomme toutes les ressources.

Exemple :

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### 5. Utilisez des Namespaces

- **Isolez** les applications dans des **namespaces** (ex: `dev`, `staging`, `prod`).

Exemple :

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```bash
kubectl create -f namespace.yaml
kubectl apply -f deployment.yaml -n dev
```

### 6. Surveillez Votre Cluster

- Utilisez des outils comme **Prometheus + Grafana** pour surveiller votre cluster.
- Configurez des **alertes** pour les problèmes (CPU, mémoire, etc.).

### 7. Utilisez Helm pour les Applications Complexes

- **Helm** est un gestionnaire de paquets pour Kubernetes.
- Il permet de **déployer des applications complexes** avec des valeurs personnalisables.

Exemple :

```bash
# Installer Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Installer un chart Helm
helm install mon-app bitnami/nginx
```

### 8. Documentez vos Manifests

- Ajoutez des **commentaires** dans vos fichiers YAML pour expliquer chaque ressource.
- Utilisez des **labels** pour identifier vos ressources.

Exemple :

```yaml
metadata:
  name: mon-app
  labels:
    app: mon-app
    environment: production
    version: v1.0.0
```

---

## 📚 Ressources

- [Documentation Kubernetes](https://kubernetes.io/docs/home/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [Kubectl Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm](https://helm.sh/)
- [Kustomize](https://kustomize.io/)

---

**Bonne utilisation des templates Kubernetes !** 🚀
