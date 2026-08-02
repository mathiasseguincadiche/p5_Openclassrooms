#!/bin/bash
# =============================================================================
# SCRIPT : Génération de la configuration HAProxy
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# 
# Ce script génère un fichier haproxy.cfg avec les IPs des serveurs NGINX.
# Usage : ./generer-haproxy-config.sh <NGINX_1_PRIVATE_IP> <NGINX_2_PRIVATE_IP>
# =============================================================================

# Vérifier que 2 arguments sont fournis
if [ $# -ne 2 ]; then
    echo "Usage: $0 <NGINX_1_PRIVATE_IP> <NGINX_2_PRIVATE_IP>"
    exit 1
fi

NGINX_1_IP=$1
NGINX_2_IP=$2

# Générer le fichier haproxy.cfg
cat > haproxy.cfg <<EOF
# =============================================================================
# Configuration HAProxy pour le Projet P5 OpenClassrooms
# Généré automatiquement par : $0
# Date : $(date)
# =============================================================================

# Configuration globale
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

# Configuration par défaut
defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Frontend : Écoute sur le port 80
frontend http-in
    bind *:80
    default_backend ngx_servers

# Backend : Répartition de charge entre les serveurs NGINX
backend ngx_servers
    balance roundrobin
    server ngx1 ${NGINX_1_IP}:80 check
    server ngx2 ${NGINX_2_IP}:80 check

# Interface de statistiques (port 8404)
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
EOF

echo "✅ Configuration HAProxy générée dans haproxy.cfg"
echo "   - NGINX-1 : ${NGINX_1_IP}:80"
echo "   - NGINX-2 : ${NGINX_2_IP}:80"
echo "   - Algorithme : roundrobin"
echo "   - Statistiques : http://<HAPROXY_IP>:8404/stats"
