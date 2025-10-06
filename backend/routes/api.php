<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
});

// Protected routes
Route::middleware('auth:api')->group(function () {
    
    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::get('me', [AuthController::class, 'me']);
        Route::put('profile', [AuthController::class, 'updateProfile']);
        Route::post('online-status', [AuthController::class, 'updateOnlineStatus']);
    });

    // User routes
    Route::prefix('users')->group(function () {
        Route::get('/', [UserController::class, 'index']);
        Route::get('online', [UserController::class, 'getOnlineUsers']);
        Route::get('suggested', [UserController::class, 'getSuggestedUsers']);
        Route::get('{user}', [UserController::class, 'show']);
        Route::post('{user}/follow', [UserController::class, 'follow']);
        Route::get('{user}/followers', [UserController::class, 'followers']);
        Route::get('{user}/following', [UserController::class, 'following']);
        Route::post('avatar', [UserController::class, 'uploadAvatar']);
    });

    // Post routes
    Route::prefix('posts')->group(function () {
        Route::get('/', [PostController::class, 'index']);
        Route::post('/', [PostController::class, 'store']);
        Route::get('{post}', [PostController::class, 'show']);
        Route::put('{post}', [PostController::class, 'update']);
        Route::delete('{post}', [PostController::class, 'destroy']);
        Route::post('{post}/like', [PostController::class, 'like']);
        Route::get('user/{user}', [PostController::class, 'getUserPosts']);
    });

    // Chat routes
    Route::prefix('chats')->group(function () {
        Route::get('/', [ChatController::class, 'index']);
        Route::post('/', [ChatController::class, 'store']);
        Route::get('{chat}', [ChatController::class, 'show']);
        Route::get('{chat}/messages', [ChatController::class, 'getMessages']);
        Route::post('{chat}/messages', [ChatController::class, 'sendMessage']);
        Route::post('{chat}/read', [ChatController::class, 'markAsRead']);
        Route::post('{chat}/participants', [ChatController::class, 'addParticipant']);
        Route::delete('{chat}/participants', [ChatController::class, 'removeParticipant']);
    });

});

// Health check
Route::get('health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now(),
        'version' => '1.0.0'
    ]);
});
