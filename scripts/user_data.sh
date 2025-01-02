#!/bin/bash

# Log setup for troubleshooting
exec > >(tee /var/log/user_data.log | logger -t user_data) 2>&1

# Update the system
sudo yum update -y

# Install Nginx and PHP from Amazon Linux Extras
sudo amazon-linux-extras enable nginx1 php8.0
sudo yum install -y nginx php php-fpm php-mysqlnd curl unzip

# Configure Cache Directories
sudo mkdir -p /var/cache/nginx/proxy /var/cache/nginx/fastcgi
sudo chown nginx:nginx /var/cache/nginx/proxy /var/cache/nginx/fastcgi

# Configure Nginx
cat << 'EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    proxy_cache_path /var/cache/nginx/proxy levels=1:2 keys_zone=proxy_cache_zone:10m inactive=60m use_temp_path=off;
    fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=fastcgi_cache_zone:10m inactive=60m use_temp_path=off;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    sendfile        on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat << 'EOF' > /etc/nginx/conf.d/dev4.cloudcat.digital.conf
server {
    listen 80;
    server_name dev4.cloudcat.digital;

    root /var/www/html;
    index index.php index.html index.htm;

    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;

    access_log /var/log/nginx/dev4.access.log;
    error_log /var/log/nginx/dev4.error.log;

    set $no_cache 0;
    if ($request_uri ~* "/wp-admin/|/preview=true") {
        set $no_cache 1;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;

        fastcgi_cache fastcgi_cache_zone;
        fastcgi_cache_key $scheme$request_method$host$request_uri;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_valid 404 5m;
        add_header X-FastCGI-Cache $upstream_cache_status;

        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~* \.(?:ico|css|js|gif|jpe?g|png|svg|woff2?|eot|ttf|otf|html)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

# Create Basic Auth Password
sudo htpasswd -cb /etc/nginx/.htpasswd devUser devPurpose

# Start and enable services
sudo systemctl restart nginx php-fpm
sudo systemctl enable nginx php-fpm

# Download and Install WordPress
cd /var/www/html
sudo curl -O https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz --strip-components=1
sudo chown -R nginx:nginx /var/www/html
