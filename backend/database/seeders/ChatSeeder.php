<?php

namespace Database\Seeders;

use App\Models\Chat;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

class ChatSeeder extends Seeder
{
    public function run()
    {
        $alice = User::where('username', 'alice')->first();
        $bob = User::where('username', 'bob')->first();
        $charlie = User::where('username', 'charlie')->first();
        $diana = User::where('username', 'diana')->first();

        // Create private chat between Alice and Bob
        $chat1 = Chat::create([
            'type' => 'private',
            'created_by' => $alice->id,
            'last_message_at' => now()->subMinutes(30),
        ]);

        $chat1->participants()->attach([$alice->id, $bob->id], [
            'role' => 'member',
            'joined_at' => now()->subDays(1),
        ]);

        // Add some messages to chat1
        $messages1 = [
            [
                'chat_id' => $chat1->id,
                'user_id' => $alice->id,
                'content' => 'Hey Bob! How are you doing?',
                'created_at' => now()->subHour(),
            ],
            [
                'chat_id' => $chat1->id,
                'user_id' => $bob->id,
                'content' => 'Hi Alice! I\'m doing great, thanks for asking. How about you?',
                'created_at' => now()->subMinutes(45),
            ],
            [
                'chat_id' => $chat1->id,
                'user_id' => $alice->id,
                'content' => 'I\'m fantastic! Just working on this new P2P app. It\'s so exciting!',
                'created_at' => now()->subMinutes(30),
            ],
        ];

        foreach ($messages1 as $messageData) {
            Message::create($messageData);
        }

        // Create group chat
        $chat2 = Chat::create([
            'type' => 'group',
            'name' => 'P2P Connect Team',
            'description' => 'Discussion about the P2P Connect project',
            'created_by' => $alice->id,
            'last_message_at' => now()->subMinutes(15),
        ]);

        $chat2->participants()->attach([$alice->id, $charlie->id, $diana->id], [
            'role' => 'member',
            'joined_at' => now()->subDays(2),
        ]);

        // Make Alice admin
        $chat2->participants()->updateExistingPivot($alice->id, ['role' => 'admin']);

        // Add some messages to chat2
        $messages2 = [
            [
                'chat_id' => $chat2->id,
                'user_id' => $charlie->id,
                'content' => 'Diana, have you seen the new features in the app?',
                'created_at' => now()->subHours(2),
            ],
            [
                'chat_id' => $chat2->id,
                'user_id' => $diana->id,
                'content' => 'Yes! The messaging UI looks amazing. The bubbles are so clean!',
                'created_at' => now()->subHour(),
            ],
            [
                'chat_id' => $chat2->id,
                'user_id' => $alice->id,
                'content' => 'Thanks everyone! The team has been working really hard on this.',
                'created_at' => now()->subMinutes(15),
            ],
        ];

        foreach ($messages2 as $messageData) {
            Message::create($messageData);
        }
    }
}
