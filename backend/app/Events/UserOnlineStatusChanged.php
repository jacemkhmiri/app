<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserOnlineStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;

    public function __construct(User $user)
    {
        $this->user = $user;
    }

    public function broadcastOn()
    {
        return new Channel('user-status');
    }

    public function broadcastWith()
    {
        return [
            'user_id' => $this->user->id,
            'username' => $this->user->username,
            'is_online' => $this->user->is_online,
            'last_seen_at' => $this->user->last_seen_at?->toISOString(),
        ];
    }

    public function broadcastAs()
    {
        return 'user.status.changed';
    }
}
