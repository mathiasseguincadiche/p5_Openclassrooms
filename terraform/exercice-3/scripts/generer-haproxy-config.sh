#!/bin/bash
# =============================================================================
# SCRIPT : Générer la configuration HAProxy pour nginxdemos/hello
# Projet P5 OpenClassrooms - Exercice 3
# =============================================================================

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que 2 arguments sont fournis
if [ "$#" -ne 2 ]; then
    echo -e "${YELLOW}Usage: $0 <NGINX_HELLO_1_IP> <NGINX_HELLO_2_IP>${NC}"
    echo "Exemple : $0 10.0.1.123 10.0.2.45"
    exit 1
fi

# IPs des instances nginxdemos/hello
NGINX_HELLO_1_IP=$1
NGINX_HELLO_2_IP=$2

echo -e "${GREEN}Génération de la configuration HAProxy...${NC}"
echo "  - Backend 1 : $NGINX_HELLO_1_IP:80"
echo "  - Backend 2 : $NGINX_HELLO_2_IP:80"

# Générer le fichier haproxy.cfg
cat > haproxy.cfg <<EOF
# =============================================================================
# Configuration HAProxy pour nginxdemos/hello
# Projet P5 OpenClassrooms - Exercice 3
# Généré automatiquement par : $0 $NGINX_HELLO_1_IP $NGINX_HELLO_2_IP
# =============================================================================

global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# ===========================================================================
# Frontend : Écoute sur le port 80
# ===========================================================================
frontend http-in
    bind *:80
    default_backend nginx_hello_servers

# ===========================================================================
# Backend : Répartition entre les 2 instances nginxdemos/hello
# Algorithme : Round Robin (1 requête par serveur à tour de rôle)
# ===========================================================================
backend nginx_hello_servers
    balance roundrobin
    server nginx-hello-1 ${NGINX_HELLO_1_IP}:80 check
    server nginx-hello-2 ${NGINX_HELLO_2_IP}:80 check

# ===========================================================================
# Statistiques HAProxy (port 8404)
# URL : http://<IP_HAPROXY>:8404/stats
# ===========================================================================
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
    stats show-legends
EOF

echo -e "${GREEN}✅ Configuration HAProxy générée dans haproxy.cfg${NC}"
echo ""
echo "Prochaine étape :"
echo "  1. Copier haproxy.cfg sur la VM HAProxy :"
echo "     scp -i p5-key.pem haproxy.cfg ubuntu@<IP_HAPROXY>:/tmp/"
echo "  2. Déployer la configuration :"
echo "     sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg"
echo "  3. Tester la configuration :"
echo "     sudo haproxy -c -f /etc/haproxy/haproxy.cfg"
echo "  4. Redémarrer HAProxy :"
echo "     sudo systemctl restart haproxy"
