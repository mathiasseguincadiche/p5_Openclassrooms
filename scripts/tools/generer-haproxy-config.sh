#!/bin/bash
# =============================================================================
# SCRIPT : Génération de la configuration HAProxy
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
#
# Ce script génère un fichier haproxy.cfg avec les IPs des serveurs nginxdemos/hello.
# Usage : HAPROXY_STATS_PASSWORD='...' ./generer-haproxy-config.sh <IP_1> <IP_2> [SORTIE]
# =============================================================================

# Vérifier les arguments et le secret requis
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: HAPROXY_STATS_PASSWORD='...' $0 <HELLO_1_PRIVATE_IP> <HELLO_2_PRIVATE_IP> [SORTIE]"
    exit 1
fi

if [ -z "${HAPROXY_STATS_PASSWORD:-}" ]; then
    echo "Erreur: définissez HAPROXY_STATS_PASSWORD sans l'écrire dans le dépôt."
    exit 1
fi

HELLO_1_IP=$1
HELLO_2_IP=$2
OUTPUT_FILE=${3:-haproxy.cfg}

# Générer le fichier haproxy.cfg
cat > "$OUTPUT_FILE" <<EOF
# =============================================================================
# Configuration HAProxy pour le Projet P5 OpenClassrooms
# Généré automatiquement par : $0
# Date : $(date)
# Serveurs backend : nginxdemos/hello (conforme aux consignes OpenClassrooms)
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
    default_backend hello_servers

# Backend : Répartition de charge entre les serveurs nginxdemos/hello
backend hello_servers
    balance roundrobin
    server hello-1 ${HELLO_1_IP}:80 check
    server hello-2 ${HELLO_2_IP}:80 check

# Interface de statistiques (port 8404)
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:${HAPROXY_STATS_PASSWORD}
EOF

echo "✅ Configuration HAProxy générée dans $OUTPUT_FILE"
echo "   - nginxdemos/hello 1 : ${HELLO_1_IP}:80"
echo "   - nginxdemos/hello 2 : ${HELLO_2_IP}:80"
echo "   - Algorithme : roundrobin"
echo "   - Statistiques : http://<HAPROXY_IP>:8404/stats"
echo ""
echo "⚠️  Pour tester la configuration :"
echo "   1. Copiez ce fichier vers /etc/haproxy/haproxy.cfg sur l'instance HAProxy"
echo "   2. Redémarrez HAProxy : sudo systemctl restart haproxy"
echo "   3. Testez avec : curl http://<HAPROXY_IP>"
echo "   4. Vérifiez les stats : http://<HAPROXY_IP>:8404/stats"
