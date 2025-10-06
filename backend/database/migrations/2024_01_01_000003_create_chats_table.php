<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('chats', function (Blueprint $table) {
            $table->id();
            $table->string('type')->default('private'); // private, group
            $table->string('name')->nullable(); // For group chats
            $table->string('description')->nullable(); // For group chats
            $table->string('avatar')->nullable(); // For group chats
            $table->foreignId('created_by')->constrained('users')->onDelete('cascade');
            $table->json('settings')->nullable();
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();
            
            $table->index(['type', 'last_message_at']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('chats');
    }
};
