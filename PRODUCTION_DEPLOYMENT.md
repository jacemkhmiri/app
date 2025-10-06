# P2P Connect - Production Deployment Guide

## 🚀 Complete Production-Ready Setup

This guide covers deploying both the Flutter app and Laravel backend to production.

## 📋 Prerequisites

- **Server**: Ubuntu 20.04+ or CentOS 8+
- **PHP**: 8.1+
- **MySQL**: 8.0+
- **Redis**: 6.0+
- **Nginx**: 1.18+
- **Node.js**: 16+
- **Composer**: 2.0+
- **Flutter**: 3.0+

## 🗄️ Database Setup

### MySQL Configuration
```sql
CREATE DATABASE p2p_connect;
CREATE USER 'p2p_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON p2p_connect.* TO 'p2p_user'@'localhost';
FLUSH PRIVILEGES;
```

### Redis Configuration
```bash
# Install Redis
sudo apt update
sudo apt install redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf
# Set: requirepass your_redis_password
# Set: maxmemory 256mb
# Set: maxmemory-policy allkeys-lru

sudo systemctl restart redis-server
```

## 🔧 Backend Deployment (Laravel)

### 1. Server Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install PHP and extensions
sudo apt install php8.1-fpm php8.1-mysql php8.1-xml php8.1-gd php8.1-curl php8.1-zip php8.1-mbstring php8.1-bcmath php8.1-redis

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Deploy Laravel Backend
```bash
# Clone repository
git clone <your-repo> /var/www/p2p-connect
cd /var/www/p2p-connect/backend

# Install dependencies
composer install --optimize-autoloader --no-dev

# Set permissions
sudo chown -R www-data:www-data /var/www/p2p-connect
sudo chmod -R 755 /var/www/p2p-connect

# Configure environment
cp env.example .env
nano .env
```

### 3. Environment Configuration
```env
APP_NAME="P2P Connect"
APP_ENV=production
APP_KEY=base64:your_generated_key
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=p2p_connect
DB_USERNAME=p2p_user
DB_PASSWORD=secure_password

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=your_redis_password
REDIS_PORT=6379

BROADCAST_DRIVER=pusher
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

PUSHER_APP_ID=your_pusher_app_id
PUSHER_APP_KEY=your_pusher_app_key
PUSHER_APP_SECRET=your_pusher_app_secret
PUSHER_APP_CLUSTER=mt1

JWT_SECRET=your_jwt_secret_key
```

### 4. Laravel Setup
```bash
# Generate keys and run migrations
php artisan key:generate
php artisan jwt:secret
php artisan migrate --force
php artisan db:seed --force

# Create storage link
php artisan storage:link

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 5. Nginx Configuration
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;

    root /var/www/p2p-connect/backend/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### 6. Supervisor Configuration (Queue Workers)
```ini
[program:p2p-connect-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/p2p-connect/backend/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/p2p-connect/backend/storage/logs/worker.log
stopwaitsecs=3600
```

## 📱 Flutter App Deployment

### 1. Web Deployment
```bash
# Build for web
flutter build web --release

# Deploy to Nginx
sudo cp -r build/web/* /var/www/html/
```

### 2. Android APK
```bash
# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### 3. iOS Deployment
```bash
# Build for iOS
flutter build ios --release

# Archive and upload to App Store Connect
# Use Xcode for final deployment
```

## 🔐 Security Configuration

### 1. SSL Certificate
```bash
# Using Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 2. Firewall Setup
```bash
# Configure UFW
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 3. Database Security
```sql
-- Remove test databases
DROP DATABASE IF EXISTS test;

-- Secure MySQL
UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root';
FLUSH PRIVILEGES;
```

## 📊 Monitoring & Logging

### 1. Log Rotation
```bash
# Configure logrotate
sudo nano /etc/logrotate.d/p2p-connect

/var/www/p2p-connect/backend/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 www-data www-data
}
```

### 2. Performance Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor Laravel logs
tail -f /var/www/p2p-connect/backend/storage/logs/laravel.log
```

## 🚀 Production Commands

### Start Services
```bash
# Start all services
sudo systemctl start nginx
sudo systemctl start mysql
sudo systemctl start redis-server
sudo systemctl start php8.1-fpm
sudo supervisorctl start p2p-connect-worker:*

# Enable auto-start
sudo systemctl enable nginx mysql redis-server php8.1-fpm
```

### Maintenance Commands
```bash
# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Restart queue workers
sudo supervisorctl restart p2p-connect-worker:*

# Check queue status
php artisan queue:work --once
```

## 📈 Performance Optimization

### 1. PHP-FPM Optimization
```ini
; /etc/php/8.1/fpm/pool.d/www.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 1000
```

### 2. MySQL Optimization
```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 32M
query_cache_type = 1
```

### 3. Redis Optimization
```conf
# /etc/redis/redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

## 🔄 Backup Strategy

### 1. Database Backup
```bash
#!/bin/bash
# /usr/local/bin/backup-db.sh
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u p2p_user -p p2p_connect > /backups/db_$DATE.sql
find /backups -name "db_*.sql" -mtime +7 -delete
```

### 2. File Backup
```bash
#!/bin/bash
# /usr/local/bin/backup-files.sh
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /backups/files_$DATE.tar.gz /var/www/p2p-connect
find /backups -name "files_*.tar.gz" -mtime +7 -delete
```

### 3. Automated Backups
```bash
# Add to crontab
0 2 * * * /usr/local/bin/backup-db.sh
0 3 * * * /usr/local/bin/backup-files.sh
```

## ✅ Production Checklist

- [ ] SSL certificate installed and working
- [ ] Database secured and optimized
- [ ] Redis configured and running
- [ ] Queue workers running via Supervisor
- [ ] Log rotation configured
- [ ] Firewall configured
- [ ] Backup strategy implemented
- [ ] Monitoring tools installed
- [ ] Performance optimizations applied
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Error tracking configured

## 🆘 Troubleshooting

### Common Issues
1. **502 Bad Gateway**: Check PHP-FPM status
2. **Database Connection**: Verify credentials and permissions
3. **Queue Not Processing**: Check Supervisor configuration
4. **File Permissions**: Ensure www-data owns files
5. **Memory Issues**: Increase PHP memory limit

### Useful Commands
```bash
# Check service status
sudo systemctl status nginx mysql redis-server php8.1-fpm

# Check logs
sudo journalctl -u nginx -f
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/redis/redis-server.log

# Test API
curl -X GET https://your-domain.com/api/health
```

## 📞 Support

For production support and advanced configurations, refer to:
- Laravel Documentation
- Flutter Documentation
- Nginx Documentation
- MySQL Documentation
- Redis Documentation
