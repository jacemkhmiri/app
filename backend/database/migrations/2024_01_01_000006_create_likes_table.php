<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('likes', function (Blueprint $table) {
            $table->id();
            $table->morphs('likeable'); // Can like posts, comments, messages
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type')->default('like'); // like, love, laugh, etc.
            $table->timestamps();
            
            $table->unique(['likeable_type', 'likeable_id', 'user_id']);
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('likes');
    }
};
