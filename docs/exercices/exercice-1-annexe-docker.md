# Annexe A : Exercice 1 en Mode Local (Docker)

> **Option alternative pour l'Exercice 1 (si vous ne voulez pas utiliser AWS).**
> **Conforme aux consignes OpenClassrooms (2 options : AWS ou Docker).**

---

## Objectif
Déployer **2 conteneurs Docker** avec NGINX + Angular en local.

---

## Prérequis
- Docker installé sur votre machine.
- Git installé.
- Node.js et npm installés (pour builder Angular).

---

## Étapes d'exécution (Mode Local)

### 1. Cloner l'application Angular
```bash
git clone https://github.com/OpenClassrooms-P5/oc-p5-angular-app.git angular-app
cd angular-app
npm install
npm run build -- --prod
```

### 2. Créer un Dockerfile pour NGINX + Angular
```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html
COPY nginx-angular.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 3. Créer le fichier `nginx-angular.conf`
```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        access_log off;
        expires max;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

### 4. Builder l'image Docker
```bash
docker build -t p5-angular-nginx .
```

### 5. Lancer 2 conteneurs
```bash
docker run -d --name nginx-angular-1 -p 8081:80 p5-angular-nginx
docker run -d --name nginx-angular-2 -p 8082:80 p5-angular-nginx
```

### 6. Tester l'accès
```bash
curl http://localhost:8081
curl http://localhost:8082
```

---

## Résumé (Mode Local)
✅ 2 conteneurs Docker avec NGINX + Angular déployés.
✅ Application accessible via `http://localhost:8081` et `http://localhost:8082`.

**→ Vous pouvez maintenant passer à l'Exercice 2 (OpenSearch + Kibana) en mode local ou AWS.**
