<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('username', 'like', "%{$search}%")
                  ->orWhere('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%");
            });
        }

        if ($request->has('online')) {
            $query->where('is_online', $request->boolean('online'));
        }

        $users = $query->select(['id', 'username', 'first_name', 'last_name', 'avatar', 'is_online', 'last_seen_at'])
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $users
        ]);
    }

    public function show(User $user)
    {
        $user->load(['posts' => function ($query) {
            $query->published()->public()->latest()->limit(10);
        }]);

        return response()->json([
            'success' => true,
            'data' => $user
        ]);
    }

    public function follow(User $user)
    {
        $currentUser = auth()->user();

        if ($currentUser->id === $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot follow yourself'
            ], 400);
        }

        if ($currentUser->isFollowing($user)) {
            $currentUser->following()->detach($user->id);
            $isFollowing = false;
        } else {
            $currentUser->following()->attach($user->id);
            $isFollowing = true;
        }

        return response()->json([
            'success' => true,
            'message' => $isFollowing ? 'User followed' : 'User unfollowed',
            'data' => [
                'is_following' => $isFollowing,
                'followers_count' => $user->followers()->count(),
                'following_count' => $user->following()->count()
            ]
        ]);
    }

    public function followers(User $user)
    {
        $followers = $user->followers()
            ->select(['id', 'username', 'first_name', 'last_name', 'avatar', 'is_online'])
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $followers
        ]);
    }

    public function following(User $user)
    {
        $following = $user->following()
            ->select(['id', 'username', 'first_name', 'last_name', 'avatar', 'is_online'])
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $following
        ]);
    }

    public function uploadAvatar(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'avatar' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = auth()->user();

        // Delete old avatar if exists
        if ($user->avatar) {
            Storage::disk('public')->delete($user->avatar);
        }

        $path = $request->file('avatar')->store('avatars', 'public');
        $user->update(['avatar' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Avatar uploaded successfully',
            'data' => [
                'avatar_url' => $user->avatar_url
            ]
        ]);
    }

    public function getOnlineUsers()
    {
        $users = User::where('is_online', true)
            ->select(['id', 'username', 'first_name', 'last_name', 'avatar', 'last_seen_at'])
            ->orderBy('last_seen_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $users
        ]);
    }

    public function getSuggestedUsers()
    {
        $user = auth()->user();
        
        $suggestedUsers = User::where('id', '!=', $user->id)
            ->whereNotIn('id', $user->following()->pluck('following_id'))
            ->inRandomOrder()
            ->limit(10)
            ->select(['id', 'username', 'first_name', 'last_name', 'avatar', 'is_online'])
            ->get();

        return response()->json([
            'success' => true,
            'data' => $suggestedUsers
        ]);
    }
}
