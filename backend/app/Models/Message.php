<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Message extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'chat_id',
        'user_id',
        'content',
        'type',
        'media',
        'reply_to',
        'reactions',
        'is_edited',
        'edited_at',
        'is_deleted',
        'deleted_at',
    ];

    protected $casts = [
        'media' => 'array',
        'reactions' => 'array',
        'is_edited' => 'boolean',
        'is_deleted' => 'boolean',
        'edited_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $appends = ['media_urls'];

    public function chat()
    {
        return $this->belongsTo(Chat::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function replyTo()
    {
        return $this->belongsTo(Message::class, 'reply_to');
    }

    public function replies()
    {
        return $this->hasMany(Message::class, 'reply_to');
    }

    public function likes()
    {
        return $this->morphMany(Like::class, 'likeable');
    }

    public function getMediaUrlsAttribute()
    {
        if (!$this->media) {
            return [];
        }

        return collect($this->media)->map(function ($media) {
            return [
                'url' => asset('storage/' . $media['path']),
                'type' => $media['type'],
                'size' => $media['size'] ?? null,
                'name' => $media['name'] ?? null,
            ];
        })->toArray();
    }

    public function getIsLikedAttribute()
    {
        if (auth()->check()) {
            return $this->likes()->where('user_id', auth()->id())->exists();
        }
        return false;
    }

    public function scopeForChat($query, $chatId)
    {
        return $query->where('chat_id', $chatId);
    }

    public function scopeNotDeleted($query)
    {
        return $query->where('is_deleted', false);
    }

    public function markAsRead($userId)
    {
        $this->chat->participants()
                  ->where('user_id', $userId)
                  ->update(['last_read_at' => now()]);
    }
}
