#!/bin/bash

echo "🚀 Installing P2P Connect Laravel Backend..."

# Install Composer dependencies
echo "📦 Installing Composer dependencies..."
composer install

# Copy environment file
echo "⚙️ Setting up environment..."
cp env.example .env

# Generate application key
echo "🔑 Generating application key..."
php artisan key:generate

# Generate JWT secret
echo "🔐 Generating JWT secret..."
php artisan jwt:secret

# Run database migrations
echo "🗄️ Running database migrations..."
php artisan migrate

# Seed database with sample data
echo "🌱 Seeding database with sample data..."
php artisan db:seed

# Create storage link
echo "🔗 Creating storage link..."
php artisan storage:link

# Clear caches
echo "🧹 Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear

echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Configure your .env file with database credentials"
echo "2. Start the server: php artisan serve"
echo "3. Start WebSockets: php artisan websockets:serve"
echo "4. Start queue worker: php artisan queue:work"
echo ""
echo "🌐 API will be available at: http://localhost:8000/api"
echo "📚 API Documentation: http://localhost:8000/api/documentation"
