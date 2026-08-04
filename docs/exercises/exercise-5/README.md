# 🐳 Exercice 5 : Orchestration avec Kubernetes

**Bienvenue dans l'Exercice 5 !**
Ici, vous allez apprendre à **déployer une application sur un cluster Kubernetes**. Cet exercice est conçu pour les **débutants en orchestration de conteneurs** et couvre les bases de Kubernetes : pods, deployments, services, ingress, et plus.

---

## 📌 Table des Matières

1. [🎯 Objectifs](#-objectifs)
2. [🛠️ Prérequis](#prerequis)
3. [📥 Préparation de l'Environnement](#-préparation-de-lenvironnement)
4. [📝 Étape 1 : Installer les Outils Kubernetes](#-étape-1--installer-les-outils-kubernetes)
5. [📝 Étape 2 : Créer un Cluster Kubernetes Local](#-étape-2--créer-un-cluster-kubernetes-local)
6. [📝 Étape 3 : Déployer une Application Simple](#-étape-3--déployer-une-application-simple)
7. [📝 Étape 4 : Utiliser des Services](#-étape-4--utiliser-des-services)
8. [📝 Étape 5 : Configurer un Ingress](#-étape-5--configurer-un-ingress)
9. [📝 Étape 6 : Utiliser des ConfigMaps et Secrets](#-étape-6--utiliser-des-configmaps-et-secrets)
10. [📝 Étape 7 : Mettre à l'Échelle une Application](#-étape-7--mettre-à-léchelle-une-application)
11. [✅ Vérification](#-vérification)
12. [🔍 Résolution des Problèmes](#-résolution-des-problèmes)
13. [📚 Pour Aller Plus Loin](#-pour-aller-plus-loin)

---

## 🎯 Objectifs

À la fin de cet exercice, vous serez capable de :
✅ **Comprendre** les concepts de base de Kubernetes (cluster, pods, deployments, services).
✅ **Installer** les outils Kubernetes (`kubectl`, Minikube/Kind).
✅ **Créer** un cluster Kubernetes local.
✅ **Déployer** une application sur Kubernetes.
✅ **Exposer** une application avec un Service.
✅ **Configurer** un Ingress pour accéder à l'application.
✅ **Utiliser** des ConfigMaps et Secrets pour gérer les configurations.
✅ **Mettre à l'échelle** une application.

---

<a id="prerequis"></a>

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

| Outil | Version | Vérification | Lien d'Installation |
|-------|---------|--------------|---------------------|
| **Docker** | 24.x | `docker --version` | [docker.com](https://www.docker.com/) |
| **kubectl** | 1.28.x | `kubectl version --client` | [kubernetes.io](https://kubernetes.io/) |
| **Minikube** | - | `minikube version` | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/) |
| **Kind** | - | `kind --version` | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/) |

> **⚠️ Important** :
>
> - **Minikube** et **Kind** sont des outils pour créer des **clusters Kubernetes locaux**.
> - Vous n'avez besoin que de **l'un des deux** (Minikube est plus simple pour les débutants).

---

## 📥 Préparation de l'Environnement

### 1. Cloner le Dépôt du Projet P5

Si ce n'est pas déjà fait, clonez le dépôt :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 2. Créer un Dossier pour l'Exercice

```bash
mkdir -p ~/p5-exercise-5 && cd ~/p5-exercise-5
```

---

## 📝 Étape 1 : Installer les Outils Kubernetes

### 1. Installer `kubectl`

`kubectl` est le **CLI officiel** pour interagir avec Kubernetes.

#### Sur Linux (Debian/Ubuntu)

```bash
# Télécharger kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Installer kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Vérifier l'installation
kubectl version --client
```

#### Sur macOS (avec Homebrew)

```bash
# Installer kubectl avec Homebrew
brew install kubectl

# Vérifier l'installation
kubectl version --client
```

#### Sur Windows (avec Chocolatey)

```powershell
# Installer kubectl avec Chocolatey
choco install kubernetes-cli

# Vérifier l'installation
kubectl version --client
```

### 2. Installer Minikube (Option 1)

Minikube est un outil pour créer un **cluster Kubernetes local** avec une seule machine virtuelle.

#### Sur Linux

```bash
# Télécharger Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Installer Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Vérifier l'installation
minikube version
```

#### Sur macOS (avec Homebrew)

```bash
# Installer Minikube avec Homebrew
brew install minikube

# Vérifier l'installation
minikube version
```

#### Sur Windows (avec Chocolatey)

```powershell
# Installer Minikube avec Chocolatey
choco install minikube

# Vérifier l'installation
minikube version
```

### 3. Installer Kind (Option 2)

Kind (Kubernetes IN Docker) est un outil pour créer un **cluster Kubernetes local** en utilisant des conteneurs Docker.

#### Sur Linux/macOS

```bash
# Télécharger Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-$(uname)-amd64

# Installer Kind
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Vérifier l'installation
kind --version
```

#### Sur Windows (avec Chocolatey)

```powershell
# Installer Kind avec Chocolatey
choco install kind

# Vérifier l'installation
kind --version
```

---

## 📝 Étape 2 : Créer un Cluster Kubernetes Local

### Option 1 : Avec Minikube

#### 1. Démarrer Minikube

```bash
# Démarrer Minikube avec Docker comme driver
minikube start --driver=docker
```

> **💡 Explication** :
>
> - `minikube start` : Démarre un cluster Kubernetes local.
> - `--driver=docker` : Utilise Docker comme **driver** (au lieu de VirtualBox).

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> 😄  minikube v1.30.1 on Ubuntu 22.04
> ✨  Automatically selected the docker driver
> 📌  Using Docker driver with root privileges
> 👍  Starting control plane node minikube in cluster minikube
> 🔥  Creating docker container (CPUs=2, Memory=2200MiB) ...
> 🐳  Preparing Kubernetes v1.28.2 on Docker 24.0.5 ...
>     ▪ Generating certificates and keys ...
>     ▪ Booting up control plane ...
>     ▪ Configuring RBAC ...
> ✅  minikube is up and running!
> ```

#### 2. Vérifier le Cluster

```bash
# Vérifier que le cluster est prêt
kubectl cluster-info

# Vérifier les nœuds
kubectl get nodes
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Kubernetes control plane is running at https://127.0.0.1:54437
> CoreDNS is running at https://127.0.0.1:54437/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
>
> To further debug and diagnose cluster problems, use 'kubectl describe' on the following objects:
> - control-plane node: minikube
>
> NAME       STATUS   ROLES           AGE   VERSION
> minikube   Ready    control-plane   1m    v1.28.2
> ```

#### 3. Accéder au Tableau de Bord Kubernetes

```bash
# Démarrer le tableau de bord Kubernetes
minikube dashboard
```

> **✅ Résultat attendu** : Un navigateur devrait s'ouvrir avec le **tableau de bord Kubernetes**.

---

### Option 2 : Avec Kind

#### 1. Créer un Cluster Kind

```bash
# Créer un cluster nommé "p5-cluster"
kind create cluster --name p5-cluster
```

> **💡 Explication** :
>
> - `kind create cluster` : Crée un cluster Kubernetes local.
> - `--name p5-cluster` : Donne un nom au cluster.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Creating cluster "p5-cluster" ...
> ✓ Ensuring node image (kindest/node:v1.28.0) 🖼️
> ✓ Preparing nodes 📦
> ✓ Writing configuration 📜
> ✓ Starting control-plane 🕹️
> ✓ Installing CNI 🔌
> ✓ Installing StorageClass 💾
> Set kubectl context to "kind-p5-cluster"
> You can now use your cluster with:
>
> kubectl cluster-info --context kind-p5-cluster
>
> Have a nice day! 👋
> ```

#### 2. Vérifier le Cluster

```bash
# Vérifier que le cluster est prêt
kubectl cluster-info

# Vérifier les nœuds
kubectl get nodes
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> Kubernetes control plane is running at https://127.0.0.1:54437
> CoreDNS is running at https://127.0.0.1:54437/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
>
> NAME                 STATUS   ROLES           AGE   VERSION
> p5-cluster-control-plane   Ready    control-plane   1m    v1.28.0
> ```

---

## 📝 Étape 3 : Déployer une Application Simple

Dans cette étape, nous allons déployer une **application Nginx** sur Kubernetes.

### 1. Créer un Fichier de Déploiement

Créez un fichier `nginx-deployment.yaml` :

```bash
nano nginx-deployment.yaml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Déploiement Kubernetes pour Nginx
# =============================================

apiVersion: apps/v1  # Version de l'API Kubernetes
kind: Deployment     # Type de ressource (Déploiement)
metadata:
  name: nginx-deployment  # Nom du déploiement
  labels:
    app: nginx         # Label pour identifier l'application

spec:
  # Nombre de réplicas (pods) à maintenir
  replicas: 3

  # Sélecteur pour trouver les pods gérés par ce déploiement
  selector:
    matchLabels:
      app: nginx

  # Template pour créer les pods
  template:
    metadata:
      labels:
        app: nginx  # Label pour identifier les pods
    spec:
      containers:
      - name: nginx  # Nom du conteneur
        image: nginx:1.25  # Image Docker à utiliser
        ports:
        - containerPort: 80  # Port exposé par le conteneur

# =============================================
# Explications :
# - apiVersion : Version de l'API Kubernetes (apps/v1 pour les déploiements).
# - kind : Type de ressource (Deployment, Pod, Service, etc.).
# - metadata : Métadonnées (nom, labels, etc.).
# - spec : Spécification du déploiement.
#   - replicas : Nombre de pods à maintenir.
#   - selector : Sélecteur pour trouver les pods gérés.
#   - template : Template pour créer les pods.
#     - spec : Spécification du pod.
#       - containers : Liste des conteneurs dans le pod.
#         - name : Nom du conteneur.
#         - image : Image Docker à utiliser.
#         - ports : Ports exposés par le conteneur.
# =============================================
```

> **💡 Explications des Concepts** :
>
> | Concept | Description | Exemple |
> |---------|-------------|---------|
> | **Pod** | Plus petite unité déployable dans Kubernetes (1 ou plusieurs conteneurs). | `pod-nginx-abc123` |
> | **Deployment** | Gère le déploiement et la mise à jour des pods. | `nginx-deployment` |
> | **Replica** | Copie d'un pod. | `replicas: 3` |
> | **Label** | Métadonnée pour identifier et sélectionner des ressources. | `app: nginx` |
> | **Selector** | Filtre pour sélectionner des pods en fonction de leurs labels. | `matchLabels: { app: nginx }` |

### 2. Appliquer le Déploiement

```bash
# Appliquer le fichier de déploiement
kubectl apply -f nginx-deployment.yaml
```

> **💡 Explication** :
>
> - `kubectl apply` : Applique une configuration Kubernetes.
> - `-f nginx-deployment.yaml` : Spécifie le fichier à appliquer.

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> deployment.apps/nginx-deployment created
> ```

### 3. Vérifier le Déploiement

```bash
# Lister les déploiements
kubectl get deployments

# Lister les pods
kubectl get pods

# Voir les détails du déploiement
kubectl describe deployment nginx-deployment
```

> **✅ Résultat attendu** :
>
> ```
> NAME               READY   UP-TO-DATE   AVAILABLE   AGE
> nginx-deployment   3/3     3            3           10s
>
> NAME                            READY   STATUS    RESTARTS   AGE
> nginx-deployment-5c6d48d8f-abc12   1/1     Running   0          10s
> nginx-deployment-5c6d48d8f-def45   1/1     Running   0          10s
> nginx-deployment-5c6d48d8f-ghi78   1/1     Running   0          10s
> ```

> **💡 Explications** :
>
> - `READY` : Nombre de pods prêts / nombre total de pods.
> - `STATUS` : État du pod (`Running`, `Pending`, `CrashLoopBackOff`, etc.).
> - `RESTARTS` : Nombre de redémarrages du pod.

### 4. Voir les Logs d'un Pod

```bash
# Récupérer le nom d'un pod
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')

# Voir les logs du pod
kubectl logs $POD_NAME
```

> **✅ Résultat attendu** : Vous devriez voir les logs de Nginx (peu de logs par défaut).

---

## 📝 Étape 4 : Utiliser des Services

Un **Service** permet d'**exposer** une application en interne ou en externe.

### 1. Créer un Service pour Nginx

Créez un fichier `nginx-service.yaml` :

```bash
nano nginx-service.yaml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Service Kubernetes pour Nginx
# =============================================

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  # Sélecteur pour trouver les pods à exposer
  selector:
    app: nginx

  # Ports à exposer
  ports:
    - protocol: TCP
      port: 80        # Port du service
      targetPort: 80 # Port du conteneur

  # Type de service (ClusterIP, NodePort, LoadBalancer)
  type: ClusterIP

# =============================================
# Explications :
# - kind : Service (pour exposer une application).
# - selector : Sélecteur pour trouver les pods à exposer.
# - ports : Liste des ports à exposer.
#   - protocol : Protocole (TCP, UDP).
#   - port : Port du service.
#   - targetPort : Port du conteneur.
# - type : Type de service.
#   - ClusterIP : Service interne (accessible uniquement dans le cluster).
#   - NodePort : Service accessible via un port sur chaque nœud.
#   - LoadBalancer : Service accessible via un load balancer externe (cloud).
# =============================================
```

### 2. Appliquer le Service

```bash
kubectl apply -f nginx-service.yaml
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> service/nginx-service created
> ```

### 3. Vérifier le Service

```bash
# Lister les services
kubectl get services

# Voir les détails du service
kubectl describe service nginx-service
```

> **✅ Résultat attendu** :
>
> ```
> NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
> nginx-service   ClusterIP   10.96.123.456   <none>        80/TCP    10s
> ```

### 4. Tester le Service en Interne

```bash
# Créer un pod temporaire pour tester le service
kubectl run curl-test --image=curlimages/curl -it --rm --restart=Never -- sh
```

> **✅ Résultat attendu** : Vous devriez être dans un shell dans le pod `curl-test`.

```bash
# Dans le pod, tester le service Nginx
curl http://nginx-service
```

> **✅ Résultat attendu** : Vous devriez voir la page HTML par défaut de Nginx.

> **⚠️ Pour quitter le pod** : Tapez `exit` ou `Ctrl + D`.

### 5. Exposer le Service en Externe (NodePort)

Modifiez le fichier `nginx-service.yaml` :

```bash
nano nginx-service.yaml
```

Remplacez `type: ClusterIP` par :

```yaml
  type: NodePort
```

Appliquez les changements :

```bash
kubectl apply -f nginx-service.yaml
```

### 6. Récupérer le Port NodePort

```bash
# Récupérer le port NodePort
NODE_PORT=$(kubectl get svc nginx-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"
```

> **✅ Résultat attendu** : Vous devriez voir un port entre **30000 et 32767** (ex: `30080`).

### 7. Accéder au Service via NodePort

#### Avec Minikube

```bash
# Récupérer l'IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Accéder au service via curl
curl http://$MINIKUBE_IP:$NODE_PORT
```

> **✅ Résultat attendu** : Vous devriez voir la page HTML par défaut de Nginx.

#### Avec Kind

```bash
# Récupérer l'IP d'un nœud Kind
KIND_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Kind IP: $KIND_IP"

# Accéder au service via curl
curl http://$KIND_IP:$NODE_PORT
```

> **✅ Résultat attendu** : Vous devriez voir la page HTML par défaut de Nginx.

---

## 📝 Étape 5 : Configurer un Ingress

Un **Ingress** permet de **gérer l'accès HTTP/HTTPS** à vos services Kubernetes. Il agit comme un **reverse proxy** et peut router le trafic vers différents services en fonction du **chemin** ou du **nom d'hôte**.

### 1. Installer un Ingress Controller

Kubernetes nécessite un **Ingress Controller** pour gérer les règles Ingress. Nous allons utiliser **NGINX Ingress Controller**.

#### Avec Minikube

```bash
# Activer l'addon Ingress dans Minikube
minikube addons enable ingress
```

#### Avec Kind

```bash
# Installer NGINX Ingress Controller avec Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.type=NodePort
```

> **⚠️ Si vous n'avez pas Helm** : Installez-le avec :
>
> ```bash
> curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
> ```

### 2. Vérifier que l'Ingress Controller est Installé

```bash
# Lister les pods dans le namespace ingress-nginx
kubectl get pods -n ingress-nginx
```

> **✅ Résultat attendu** : Vous devriez voir des pods en cours d'exécution :
>
> ```
> NAME                                        READY   STATUS    RESTARTS   AGE
> ingress-nginx-controller-abc123def456-abc12   1/1     Running   0          1m
> ```

### 3. Créer un Fichier Ingress

Créez un fichier `nginx-ingress.yaml` :

```bash
nano nginx-ingress.yaml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Ingress Kubernetes pour Nginx
# =============================================

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    # Annotation pour NGINX Ingress Controller
    nginx.ingress.kubernetes.io/rewrite-target: /

spec:
  # Règles de routage
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service  # Nom du service à exposer
            port:
              number: 80         # Port du service

# =============================================
# Explications :
# - kind : Ingress (pour gérer l'accès HTTP/HTTPS).
# - annotations : Configuration spécifique pour l'Ingress Controller.
# - rules : Liste des règles de routage.
#   - http : Règles pour le trafic HTTP.
#     - paths : Liste des chemins à router.
#       - path : Chemin URL (ex: /, /app, /api).
#       - pathType : Type de correspondance (Prefix, Exact).
#       - backend : Service backend vers lequel router le trafic.
#         - service : Nom du service.
#         - port : Port du service.
# =============================================
```

### 4. Appliquer l'Ingress

```bash
kubectl apply -f nginx-ingress.yaml
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> ingress.networking.k8s.io/nginx-ingress created
> ```

### 5. Récupérer l'IP de l'Ingress

```bash
# Récupérer l'IP de l'Ingress (peut prendre quelques minutes)
kubectl get ingress nginx-ingress -w
```

> **✅ Résultat attendu** : Après quelques minutes, vous devriez voir une **IP** ou un **nom d'hôte** :
>
> ```
> NAME            CLASS   HOSTS   ADDRESS          PORTS   AGE
> nginx-ingress   <none>  *       192.168.49.2    80      1m
> ```

### 6. Accéder à l'Application via l'Ingress

#### Avec Minikube

```bash
# Récupérer l'IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Accéder au service via curl
curl http://$MINIKUBE_IP
```

> **✅ Résultat attendu** : Vous devriez voir la page HTML par défaut de Nginx.

#### Avec Kind

```bash
# Récupérer l'IP d'un nœud Kind
KIND_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Kind IP: $KIND_IP"

# Accéder au service via curl
curl http://$KIND_IP
```

> **✅ Résultat attendu** : Vous devriez voir la page HTML par défaut de Nginx.

---

## 📝 Étape 6 : Utiliser des ConfigMaps et Secrets

Les **ConfigMaps** et **Secrets** permettent de **gérer les configurations** et les **données sensibles** (mots de passe, clés API, etc.) de manière sécurisée.

### 1. Créer un ConfigMap

Un **ConfigMap** permet de stocker des **données de configuration non sensibles** (ex: variables d'environnement, fichiers de configuration).

Créez un fichier `nginx-configmap.yaml` :

```bash
nano nginx-configmap.yaml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# ConfigMap pour Nginx
# =============================================

apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config

data:
  # Variables d'environnement
  NGINX_ENV: "production"
  NGINX_PORT: "80"

  # Fichier de configuration Nginx
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;

      location / {
        return 200 "Bienvenue sur Kubernetes avec ConfigMap !";
        add_header Content-Type text/plain;
      }
    }

# =============================================
# Explications :
# - kind : ConfigMap (pour stocker des configurations).
# - data : Données de configuration (clé: valeur).
#   - Les valeurs peuvent être des chaînes de caractères ou des fichiers.
#   - | : Permet de définir une valeur multi-lignes (YAML).
# =============================================
```

Appliquez le ConfigMap :

```bash
kubectl apply -f nginx-configmap.yaml
```

### 2. Créer un Secret

Un **Secret** permet de stocker des **données sensibles** (mots de passe, clés API, certificats, etc.).

Créez un fichier `nginx-secret.yaml` :

```bash
nano nginx-secret.yaml
```

Ajoutez le contenu suivant :

```yaml
# =============================================
# Secret pour Nginx
# =============================================

apiVersion: v1
kind: Secret
metadata:
  name: nginx-secrets

# Type de secret (Opaque = données génériques)
type: Opaque

# Valeur d'exemple à remplacer avant application
stringData:
  NGINX_PASSWORD: A_REMPLACER

# =============================================
# Explications :
# - kind : Secret (pour stocker des données sensibles).
# - type : Type de secret (Opaque, kubernetes.io/tls, etc.).
# - stringData : Valeur convertie en `data` par l'API Kubernetes.
# =============================================
```

> **⚠️ Important** :
>
> - Les **Secrets ne sont pas chiffrés par défaut** dans Kubernetes (ils sont encodés en base64).
> - Pour une **sécurité maximale**, utilisez des outils comme **HashiCorp Vault** ou **AWS Secrets Manager**.

Appliquez le Secret :

```bash
kubectl apply -f nginx-secret.yaml
```

### 3. Utiliser le ConfigMap et le Secret dans un Déploiement

Modifiez le fichier `nginx-deployment.yaml` :

```bash
nano nginx-deployment.yaml
```

Remplacez le contenu par :

```yaml
# =============================================
# Déploiement Kubernetes pour Nginx avec ConfigMap et Secret
# =============================================

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx

spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx

  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80

        # Utiliser le ConfigMap comme variables d'environnement
        envFrom:
        - configMapRef:
            name: nginx-config

        # Monter le ConfigMap comme fichier
        volumeMounts:
        - name: nginx-config-volume
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf

        # Monter le Secret comme variables d'environnement
        env:
        - name: NGINX_PASSWORD
          valueFrom:
            secretKeyRef:
              name: nginx-secrets
              key: NGINX_PASSWORD

      # Définir les volumes
      volumes:
      - name: nginx-config-volume
        configMap:
          name: nginx-config

# =============================================
# Explications :
# - envFrom : Charge toutes les clés d'un ConfigMap comme variables d'environnement.
# - volumeMounts : Monte un volume dans le conteneur.
#   - name : Nom du volume.
#   - mountPath : Chemin où monter le volume dans le conteneur.
#   - subPath : Fichier spécifique à monter (optionnel).
# - volumes : Liste des volumes à monter dans le pod.
#   - configMap : Monte un ConfigMap comme volume.
# - env : Définit des variables d'environnement.
#   - valueFrom : Charge une valeur depuis une source externe (ConfigMap, Secret).
#     - secretKeyRef : Charge une valeur depuis un Secret.
# =============================================
```

Appliquez les changements :

```bash
kubectl apply -f nginx-deployment.yaml
```

### 4. Vérifier que le ConfigMap et le Secret sont Utilisés

```bash
# Récupérer le nom d'un pod
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')

# Vérifier les variables d'environnement
kubectl exec $POD_NAME -- env

# Vérifier que le fichier de configuration a été monté
kubectl exec $POD_NAME -- cat /etc/nginx/conf.d/default.conf
```

> **✅ Résultat attendu** :
>
> - Les **variables d'environnement** devraient inclure `NGINX_ENV=production` et une valeur de secret injectée à l'exécution.
> - Le **fichier `/etc/nginx/conf.d/default.conf`** devrait contenir la configuration Nginx.

---

## 📝 Étape 7 : Mettre à l'Échelle une Application

Kubernetes permet de **mettre à l'échelle** une application de manière **simple et rapide**.

### 1. Mettre à l'Échelle avec `kubectl scale`

```bash
# Mettre à l'échelle le déploiement à 5 réplicas
kubectl scale deployment nginx-deployment --replicas=5
```

> **✅ Résultat attendu** : Vous devriez voir :
>
> ```
> deployment.apps/nginx-deployment scaled
> ```

### 2. Vérifier le Nombre de Pods

```bash
# Lister les pods
kubectl get pods
```

> **✅ Résultat attendu** : Vous devriez voir **5 pods** en cours d'exécution :
>
> ```
> NAME                            READY   STATUS    RESTARTS   AGE
> nginx-deployment-5c6d48d8f-abc12   1/1     Running   0          5m
> nginx-deployment-5c6d48d8f-def45   1/1     Running   0          5m
> nginx-deployment-5c6d48d8f-ghi78   1/1     Running   0          5m
> nginx-deployment-5c6d48d8f-jkl90   1/1     Running   0          10s
> nginx-deployment-5c6d48d8f-mno12   1/1     Running   0          10s
> ```

### 3. Mettre à l'Échelle avec `kubectl edit`

```bash
# Modifier le déploiement
kubectl edit deployment nginx-deployment
```

> **💡 Explication** :
>
> - `kubectl edit` : Ouvre le fichier de configuration dans un éditeur (par défaut : `vim`).
> - Modifiez `replicas: 5` à `replicas: 2` et sauvegardez.

> **✅ Résultat attendu** : Kubernetes devrait **réduire automatiquement** le nombre de pods à 2.

### 4. Vérifier le Rolling Update

Modifiez le fichier `nginx-deployment.yaml` pour utiliser une nouvelle image :

```bash
nano nginx-deployment.yaml
```

Remplacez `image: nginx:1.25` par :

```yaml
        image: nginx:1.26
```

Appliquez les changements :

```bash
kubectl apply -f nginx-deployment.yaml
```

> **💡 Explication** :
>
> - Kubernetes effectue un **rolling update** : il remplace progressivement les pods avec la nouvelle image **sans temps d'arrêt**.

### 5. Vérifier le Rolling Update

```bash
# Voir les détails du déploiement
kubectl describe deployment nginx-deployment

# Voir les images des pods
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'
```

> **✅ Résultat attendu** : Vous devriez voir que les pods sont **progressivement mis à jour** vers `nginx:1.26`.

### 6. Annuler un Rolling Update

Si quelque chose ne va pas, vous pouvez **annuler** le rolling update :

```bash
# Annuler le dernier rolling update
kubectl rollout undo deployment/nginx-deployment
```

> **✅ Résultat attendu** : Kubernetes devrait **revenir à la version précédente** (nginx:1.25).

---

## ✅ Vérification

Pour vérifier que vous avez **bien compris** cet exercice, répondez aux questions suivantes :

### 1. Qu'est-ce que Kubernetes ?

<details>
<summary>💡 Réponse</summary>
Kubernetes (ou **K8s**) est une **plateforme open-source** pour **orchestrer** des conteneurs. Elle permet de **déployer**, **scaler**, et **gérer** des applications conteneurisées de manière **automatisée**.
</details>

### 2. Qu'est-ce qu'un Pod ?

<details>
<summary>💡 Réponse</summary>
Un **Pod** est la **plus petite unité déployable** dans Kubernetes. Il peut contenir **un ou plusieurs conteneurs** qui partagent le même **espace de noms réseau** et le même **volume de stockage**.
</details>

### 3. Qu'est-ce qu'un Deployment ?

<details>
<summary>💡 Réponse</summary>
Un **Deployment** est une **ressource Kubernetes** qui gère le **déploiement** et la **mise à jour** des pods. Il permet de :
- Définir le **nombre de réplicas** (pods).
- Effectuer des **rolling updates** (mises à jour sans temps d'arrêt).
- **Revenir en arrière** (rollback) en cas d'erreur.
</details>

### 4. Qu'est-ce qu'un Service ?

<details>
<summary>💡 Réponse</summary>
Un **Service** est une **ressource Kubernetes** qui permet d'**exposer** une application en interne ou en externe. Il existe 3 types de services :
- **ClusterIP** : Service interne (accessible uniquement dans le cluster).
- **NodePort** : Service accessible via un **port sur chaque nœud**.
- **LoadBalancer** : Service accessible via un **load balancer externe** (cloud).
</details>

### 5. Qu'est-ce qu'un Ingress ?

<details>
<summary>💡 Réponse</summary>
Un **Ingress** est une **ressource Kubernetes** qui permet de **gérer l'accès HTTP/HTTPS** à vos services. Il agit comme un **reverse proxy** et peut router le trafic vers différents services en fonction du **chemin** ou du **nom d'hôte**.

> **⚠️ Important** : Un Ingress nécessite un **Ingress Controller** (ex: NGINX Ingress Controller) pour fonctionner.
</details>

### 6. Qu'est-ce qu'un ConfigMap ?

<details>
<summary>💡 Réponse</summary>
Un **ConfigMap** est une **ressource Kubernetes** qui permet de stocker des **données de configuration non sensibles** (ex: variables d'environnement, fichiers de configuration).

> **Exemples d'utilisation** :
>
> - Variables d'environnement (`envFrom`).
> - Fichiers de configuration (`volumeMounts`).
>
</details>

### 7. Qu'est-ce qu'un Secret ?

<details>
<summary>💡 Réponse</summary>
Un **Secret** est une **ressource Kubernetes** qui permet de stocker des **données sensibles** (mots de passe, clés API, certificats, etc.).

> **⚠️ Important** :
>
> - Les Secrets **ne sont pas chiffrés par défaut** (ils sont encodés en base64).
> - Pour une **sécurité maximale**, utilisez des outils comme **HashiCorp Vault** ou **AWS Secrets Manager**.
>
</details>

### 8. À quoi sert `kubectl apply` ?

<details>
<summary>💡 Réponse</summary>
`kubectl apply` permet d'**appliquer une configuration Kubernetes** définie dans un fichier YAML. Si la ressource n'existe pas, elle est **créée**. Si elle existe déjà, elle est **mise à jour**.
</details>

### 9. À quoi sert `kubectl get pods` ?

<details>
<summary>💡 Réponse</summary>
`kubectl get pods` permet de **lister les pods** dans le namespace actuel. Vous pouvez ajouter des options comme :
- `-n namespace` : Lister les pods dans un namespace spécifique.
- `-l label=value` : Filtrer les pods par label.
- `-o wide` : Afficher plus de détails (IP, nœud, etc.).
</details>

### 10. À quoi sert `kubectl scale` ?

<details>
<summary>💡 Réponse</summary>
`kubectl scale` permet de **mettre à l'échelle** un déploiement, un replica set, ou un stateful set en modifiant le **nombre de réplicas**.

> **Exemple** :
>
> ```bash
> kubectl scale deployment nginx-deployment --replicas=5
> ```
>
</details>

---

## 🔍 Résolution des Problèmes

Voici les **problèmes courants** et leurs solutions :

| **Problème** | **Cause Possible** | **Solution** |
|--------------|-------------------|--------------|
| `Error: minikube start: minikube is not running` | Minikube n'est pas démarré. | Démarrez Minikube avec `minikube start`. |
| `Error: kubectl: command not found` | `kubectl` n'est pas installé ou n'est pas dans le PATH. | Installez `kubectl` et vérifiez le PATH. |
| `Error: unable to connect to server` | Le cluster Kubernetes n'est pas configuré. | Vérifiez que Minikube/Kind est démarré et que `kubectl` est configuré. |
| `Error: ImagePullBackOff` | L'image Docker n'existe pas ou ne peut pas être téléchargée. | Vérifiez le nom de l'image et votre connexion Internet. |
| `Error: CrashLoopBackOff` | Le conteneur plante au démarrage. | Vérifiez les logs avec `kubectl logs <pod-name>`. |
| `Error: pending` | Le pod ne peut pas être planifié. | Vérifiez les ressources disponibles avec `kubectl describe node`. |
| `Error: no nodes available` | Aucun nœud n'est disponible. | Vérifiez que Minikube/Kind est démarré. |
| `Error: forbidden: User "system:serviceaccount:default:default" cannot get resource "pods"` | Problème de permissions RBAC. | Utilisez `kubectl` avec un utilisateur ayant les permissions nécessaires. |
| `Error: Ingress Controller not found` | L'Ingress Controller n'est pas installé. | Installez un Ingress Controller (ex: NGINX Ingress Controller). |

---

## 📚 Pour Aller Plus Loin

### Ressources Officielles

- [Documentation Kubernetes](https://kubernetes.io/docs/home/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [Kubectl Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Outils Complémentaires

- **Helm** : Gestionnaire de paquets pour Kubernetes. [helm.sh](https://helm.sh/)
- **Kustomize** : Outil pour personnaliser les manifests Kubernetes. [kustomize.io](https://kustomize.io/)
- **Lens** : IDE pour Kubernetes. [k8slens.dev](https://k8slens.dev/)

### Tutoriels

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Deploying an App](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/)
- [Scaling an App](https://kubernetes.io/docs/tutorials/kubernetes-basics/scale/)

### Livres

- [Kubernetes: Up and Running](https://www.oreilly.com/library/view/kubernetes-up/9781492046527/) (Kelsey Hightower, Brendan Burns, Joe Beda)
- [The Kubernetes Book](https://www.freecodecamp.org/news/the-kubernetes-book/) (Nigel Poulton)

### Prochains Exercices

- **[Exercice 4 : Infrastructure as Code avec Terraform](../exercise-4/README.md)** : Si vous ne l'avez pas encore fait.

---

## 🎉 Félicitations

Vous avez **terminé l'Exercice 5** ! 🎉
Vous savez maintenant :
✅ **Installer** les outils Kubernetes (`kubectl`, Minikube/Kind).
✅ **Créer** un cluster Kubernetes local.
✅ **Déployer** une application sur Kubernetes.
✅ **Exposer** une application avec un Service.
✅ **Configurer** un Ingress pour accéder à l'application.
✅ **Utiliser** des ConfigMaps et Secrets pour gérer les configurations.
✅ **Mettre à l'échelle** une application.

**Vous avez maintenant terminé tous les exercices du projet P5 !** 🚀
**Félicitations pour votre parcours DevOps !** 🎊
