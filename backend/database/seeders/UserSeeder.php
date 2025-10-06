<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run()
    {
        // Create sample users
        $users = [
            [
                'username' => 'alice',
                'first_name' => 'Alice',
                'last_name' => 'Johnson',
                'email' => 'alice@example.com',
                'bio' => 'Tech enthusiast and developer',
                'is_online' => true,
                'last_seen_at' => now(),
            ],
            [
                'username' => 'bob',
                'first_name' => 'Bob',
                'last_name' => 'Smith',
                'email' => 'bob@example.com',
                'bio' => 'Designer and creative thinker',
                'is_online' => false,
                'last_seen_at' => now()->subHours(2),
            ],
            [
                'username' => 'charlie',
                'first_name' => 'Charlie',
                'last_name' => 'Brown',
                'email' => 'charlie@example.com',
                'bio' => 'Product manager and team lead',
                'is_online' => true,
                'last_seen_at' => now(),
            ],
            [
                'username' => 'diana',
                'first_name' => 'Diana',
                'last_name' => 'Prince',
                'email' => 'diana@example.com',
                'bio' => 'Marketing specialist and content creator',
                'is_online' => true,
                'last_seen_at' => now(),
            ],
            [
                'username' => 'eve',
                'first_name' => 'Eve',
                'last_name' => 'Wilson',
                'email' => 'eve@example.com',
                'bio' => 'Data scientist and AI researcher',
                'is_online' => false,
                'last_seen_at' => now()->subDays(1),
            ],
        ];

        foreach ($users as $userData) {
            User::create($userData);
        }

        // Create some follow relationships
        $alice = User::where('username', 'alice')->first();
        $bob = User::where('username', 'bob')->first();
        $charlie = User::where('username', 'charlie')->first();
        $diana = User::where('username', 'diana')->first();

        // Alice follows Bob and Charlie
        $alice->following()->attach([$bob->id, $charlie->id]);

        // Bob follows Alice and Diana
        $bob->following()->attach([$alice->id, $diana->id]);

        // Charlie follows Alice and Diana
        $charlie->following()->attach([$alice->id, $diana->id]);

        // Diana follows Alice and Bob
        $diana->following()->attach([$alice->id, $bob->id]);
    }
}
