#!/bin/sh
set -e

echo "========================================="
echo "InvoiceNinja Entrypoint Starting..."
echo "========================================="

# Wait for database to be ready
echo "Waiting for database connection..."
max_attempts=30
attempt=0
until php artisan db:show > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -gt $max_attempts ]; then
        echo "ERROR: Database connection timeout after $max_attempts attempts"
        exit 1
    fi
    echo "  Attempt $attempt/$max_attempts - waiting..."
    sleep 2
done

echo "✓ Database is ready!"

# Run migrations if requested (use for init container)
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    echo "Running database migrations..."
    php artisan migrate --force --no-interaction
    echo "✓ Migrations completed!"

    # Seed static data if needed
    echo "Checking static data..."
    TIMEZONE_COUNT=$(php artisan tinker --execute="echo App\Models\Timezone::count();" 2>/dev/null | tail -1)
    if [ "$TIMEZONE_COUNT" = "0" ]; then
        echo "Seeding static data..."
        php artisan db:seed --force
        echo "✓ Static data seeded!"
    else
        echo "✓ Static data already present"
    fi
fi

# Create storage symlink if not exists
if [ ! -L public/storage ]; then
    echo "Creating storage symlink..."
    php artisan storage:link
    echo "✓ Storage symlink created!"
fi

# Clear and optimize caches
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo "✓ Application optimized!"

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Ensure nginx directories have proper permissions
# Parent directory must be accessible by www-data
chmod 755 /var/lib/nginx
mkdir -p /var/lib/nginx/tmp/client_body \
         /var/lib/nginx/tmp/proxy \
         /var/lib/nginx/tmp/fastcgi \
         /var/lib/nginx/tmp/uwsgi \
         /var/lib/nginx/tmp/scgi
chown -R www-data:www-data /var/lib/nginx/tmp
chmod -R 755 /var/lib/nginx/tmp

echo "✓ Permissions set!"

echo "========================================="
echo "InvoiceNinja initialization complete!"
echo "========================================="

# Execute CMD
exec "$@"
