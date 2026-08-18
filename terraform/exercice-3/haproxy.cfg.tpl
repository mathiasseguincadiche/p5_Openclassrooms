global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client 50s
    timeout server 50s

frontend http-in
    bind *:80
    default_backend hello-servers

backend hello-servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server hello-1 @@BACKEND_1@@:80 check inter 3s fall 3 rise 2
    server hello-2 @@BACKEND_2@@:80 check inter 3s fall 3 rise 2
