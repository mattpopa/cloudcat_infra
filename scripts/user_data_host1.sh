#!/bin/bash

# Log setup for troubleshooting
exec > >(tee /var/log/user_data.log | logger -t user_data) 2>&1

# Update the system
sudo yum update -y

# Install Nginx, PHP, and MariaDB from Amazon Linux Extras
sudo amazon-linux-extras enable nginx1 php8.2 mariadb10.5
sudo yum install -y nginx php php-fpm php-mysqlnd mariadb-server curl unzip \
php-gd php-mbstring php-intl php-dom php-pecl-imagick

# Update PHP-FPM to use the nginx user and group
sudo sed -i 's/^user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = apache/group = nginx/' /etc/php-fpm.d/www.conf

# Start and enable MariaDB service
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Generate a random root password
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
echo "db tmp pass $DB_ROOT_PASSWORD"

# Automate MariaDB secure installation
mysql -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;

-- Remove privileges on test database
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

# Create WordPress database and user
DB_NAME="dev"
DB_USER="dev_user"
DB_PASSWORD="dev_password"
DB_HOST="localhost"

mysql -u root -p"$DB_ROOT_PASSWORD" <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

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

cat << 'EOF' > /etc/nginx/conf.d/stefaniapana.design.conf
server {
    listen 80;
    server_name stefaniapana.design;

    root /var/www/html;
    index index.php index.html index.htm;

    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;

    access_log /var/log/nginx/stefaniapana.access.log;
    error_log /var/log/nginx/stefaniapana.error.log;

    set $no_cache 0;
    if ($request_uri ~* "/wp-admin/|/preview=true") {
        set $no_cache 1;
    }

    client_max_body_size 10M;

    location ^~ /wp-content/uploads/ {
        add_header Access-Control-Allow-Origin *;
        auth_basic off;  # Disable authentication for uploads
    }

    location / {
       allow 127.0.0.1;
        allow 10.0.0.0/8;
        deny all;
        try_files $uri $uri/ /index.php?$args;

        fastcgi_cache fastcgi_cache_zone;
        fastcgi_cache_key $scheme$request_method$host$request_uri;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_valid 404 5m;
        add_header X-FastCGI-Cache $upstream_cache_status;

        fastcgi_buffers 8 16k;
        fastcgi_buffer_size 32k;

        include fastcgi_params;
        fastcgi_param HTTPS $http_x_forwarded_proto;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~* \.(?:ico|css|js|gif|jpeg|jpg|png|svg|woff2?|eot|ttf|otf|html|webp)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

# Create Basic Auth Password
# sudo htpasswd -cb /etc/nginx/.htpasswd devUser devScope

# Start and enable services
sudo systemctl restart nginx php-fpm
sudo systemctl enable nginx php-fpm

# Download and Install WordPress
cd /var/www/html
sudo curl -O https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz --strip-components=1
sudo chown -R nginx:nginx /var/www/html

# Generate WordPress authentication salts
WP_SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Create wp-config.php using the default WordPress sample configuration
cat <<EOF > /var/www/html/wp-config.php
<?php
/** The base configuration for WordPress */

// ** Database settings ** //
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USER' );
define( 'DB_PASSWORD', '$DB_PASSWORD' );
define( 'DB_HOST', '$DB_HOST' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define( 'WP_HOME', 'https://stefaniapana.design' );
define( 'WP_SITEURL', 'https://stefaniapana.design' );
define('FORCE_SSL_ADMIN', true);

if (\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')
    \$_SERVER['HTTPS'] = 'on';

/**#@+ Authentication unique keys and salts. */
$WP_SALTS
/**#@-*/

\$table_prefix = 'dev_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

rm -f /var/www/html/wp-config-sample.php
sudo chown nginx:nginx /var/www/html/wp-config.php

echo "User data script completed successfully."
