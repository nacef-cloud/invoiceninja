#!/bin/sh
# Fix nginx directory permissions
# The parent directory must be accessible by www-data
chmod 755 /var/lib/nginx

# Create and fix temp directories
mkdir -p /var/lib/nginx/tmp/client_body \
         /var/lib/nginx/tmp/proxy \
         /var/lib/nginx/tmp/fastcgi \
         /var/lib/nginx/tmp/uwsgi \
         /var/lib/nginx/tmp/scgi
chown -R www-data:www-data /var/lib/nginx/tmp
chmod -R 755 /var/lib/nginx/tmp
