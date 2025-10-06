<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Chat extends Model
{
    use HasFactory;

    protected $fillable = [
        'type',
        'name',
        'description',
        'avatar',
        'created_by',
        'settings',
        'last_message_at',
    ];

    protected $casts = [
        'settings' => 'array',
        'last_message_at' => 'datetime',
    ];

    public function participants()
    {
        return $this->belongsToMany(User::class, 'chat_participants')
                    ->withPivot(['role', 'joined_at', 'last_read_at', 'settings'])
                    ->withTimestamps();
    }

    public function messages()
    {
        return $this->hasMany(Message::class)->latest();
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function getLastMessageAttribute()
    {
        return $this->messages()->first();
    }

    public function getUnreadCountAttribute()
    {
        if (!auth()->check()) {
            return 0;
        }

        $participant = $this->participants()
                           ->where('user_id', auth()->id())
                           ->first();

        if (!$participant || !$participant->pivot->last_read_at) {
            return $this->messages()->count();
        }

        return $this->messages()
                   ->where('created_at', '>', $participant->pivot->last_read_at)
                   ->count();
    }

    public function isParticipant($userId)
    {
        return $this->participants()->where('user_id', $userId)->exists();
    }

    public function getOtherParticipantAttribute()
    {
        if ($this->type !== 'private') {
            return null;
        }

        return $this->participants()
                   ->where('user_id', '!=', auth()->id())
                   ->first();
    }

    public function updateLastMessage()
    {
        $lastMessage = $this->messages()->first();
        if ($lastMessage) {
            $this->update(['last_message_at' => $lastMessage->created_at]);
        }
    }
}
