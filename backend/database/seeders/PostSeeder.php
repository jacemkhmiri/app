<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostSeeder extends Seeder
{
    public function run()
    {
        $alice = User::where('username', 'alice')->first();
        $bob = User::where('username', 'bob')->first();
        $charlie = User::where('username', 'charlie')->first();
        $diana = User::where('username', 'diana')->first();

        $posts = [
            [
                'user_id' => $alice->id,
                'content' => 'Just finished building this amazing P2P messaging app! The decentralized approach is so much better than traditional social media. 🚀 #P2P #Decentralized #Tech',
                'likes_count' => 5,
                'published_at' => now()->subHours(2),
            ],
            [
                'user_id' => $bob->id,
                'content' => 'Privacy matters! Love how this app keeps everything peer-to-peer without any central servers. No data harvesting here! 🔒 #Privacy #Security',
                'likes_count' => 3,
                'published_at' => now()->subHours(4),
            ],
            [
                'user_id' => $charlie->id,
                'content' => 'The UI looks fantastic! Clean, modern design with smooth animations. Great work on the user experience! ✨ #UI #UX #Design',
                'likes_count' => 7,
                'published_at' => now()->subHours(6),
            ],
            [
                'user_id' => $diana->id,
                'content' => 'Real-time messaging without any middleman? Count me in! This is the future of communication. 🌟 #RealTime #Communication',
                'likes_count' => 4,
                'published_at' => now()->subDay(),
            ],
            [
                'user_id' => $alice->id,
                'content' => 'Working on some exciting new features for the app. Can\'t wait to share them with everyone! #Development #Features',
                'likes_count' => 2,
                'published_at' => now()->subHours(1),
            ],
        ];

        foreach ($posts as $postData) {
            Post::create($postData);
        }
    }
}
