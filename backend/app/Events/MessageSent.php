<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct(Message $message)
    {
        $this->message = $message->load(['user', 'replyTo.user']);
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->message->chat_id);
    }

    public function broadcastWith()
    {
        return [
            'id' => $this->message->id,
            'chat_id' => $this->message->chat_id,
            'user' => [
                'id' => $this->message->user->id,
                'username' => $this->message->user->username,
                'first_name' => $this->message->user->first_name,
                'last_name' => $this->message->user->last_name,
                'avatar_url' => $this->message->user->avatar_url,
            ],
            'content' => $this->message->content,
            'type' => $this->message->type,
            'media_urls' => $this->message->media_urls,
            'reply_to' => $this->message->reply_to ? [
                'id' => $this->message->replyTo->id,
                'content' => $this->message->replyTo->content,
                'user' => [
                    'username' => $this->message->replyTo->user->username,
                ]
            ] : null,
            'created_at' => $this->message->created_at->toISOString(),
        ];
    }

    public function broadcastAs()
    {
        return 'message.sent';
    }
}
