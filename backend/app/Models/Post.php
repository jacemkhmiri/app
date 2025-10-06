<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Post extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'content',
        'media',
        'tags',
        'visibility',
        'likes_count',
        'comments_count',
        'shares_count',
        'is_pinned',
        'published_at',
    ];

    protected $casts = [
        'media' => 'array',
        'tags' => 'array',
        'is_pinned' => 'boolean',
        'published_at' => 'datetime',
    ];

    protected $appends = ['is_liked'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function likes()
    {
        return $this->morphMany(Like::class, 'likeable');
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function getIsLikedAttribute()
    {
        if (auth()->check()) {
            return $this->likes()->where('user_id', auth()->id())->exists();
        }
        return false;
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
            ];
        })->toArray();
    }

    public function scopePublished($query)
    {
        return $query->whereNotNull('published_at')
                    ->where('published_at', '<=', now());
    }

    public function scopePublic($query)
    {
        return $query->where('visibility', 'public');
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where(function ($q) use ($userId) {
            $q->where('user_id', $userId)
              ->orWhereHas('user.followers', function ($followQuery) use ($userId) {
                  $followQuery->where('follower_id', $userId);
              });
        });
    }
}
