# P2P Connect - Laravel Backend API

A comprehensive Laravel backend for the P2P Connect messaging and social media application.

## Features

### 🔐 Authentication & User Management
- JWT-based authentication
- User registration and login
- Profile management
- User search and discovery

### 💬 Messaging System
- Real-time messaging with WebSockets
- Chat rooms and direct messages
- Message history and persistence
- File and media sharing

### 📱 Social Features
- Posts and newsfeed
- Like and comment system
- User following/followers
- Real-time notifications

### 🚀 Production Ready
- Redis caching
- Queue system for background jobs
- File storage with S3 support
- Comprehensive API documentation
- Rate limiting and security

## Installation

1. **Prerequisites**
   ```bash
   composer install
   php artisan key:generate
   php artisan migrate
   php artisan db:seed
   ```

2. **Environment Setup**
   ```bash
   cp .env.example .env
   # Configure database, Redis, and other services
   ```

3. **Start Services**
   ```bash
   php artisan serve
   php artisan websockets:serve
   php artisan queue:work
   ```

## API Documentation

- **Base URL**: `http://localhost:8000/api`
- **Authentication**: Bearer Token (JWT)
- **Documentation**: Available at `/api/documentation`

## Architecture

- **Laravel 10** - PHP framework
- **MySQL** - Primary database
- **Redis** - Caching and sessions
- **WebSockets** - Real-time communication
- **JWT** - Authentication
- **S3** - File storage
