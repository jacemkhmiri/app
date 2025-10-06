<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class PostController extends Controller
{
    public function index(Request $request)
    {
        $user = auth()->user();
        
        $posts = Post::with(['user', 'likes'])
            ->published()
            ->public()
            ->forUser($user->id)
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $posts
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:2000',
            'visibility' => 'in:public,followers,private',
            'media.*' => 'file|mimes:jpeg,png,jpg,gif,mp4,mov,avi|max:10240', // 10MB max
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $media = [];
        if ($request->hasFile('media')) {
            foreach ($request->file('media') as $file) {
                $path = $file->store('posts', 'public');
                $media[] = [
                    'path' => $path,
                    'type' => $file->getMimeType(),
                    'size' => $file->getSize(),
                    'name' => $file->getClientOriginalName(),
                ];
            }
        }

        $post = Post::create([
            'user_id' => auth()->id(),
            'content' => $request->content,
            'media' => $media,
            'tags' => $this->extractHashtags($request->content),
            'visibility' => $request->visibility ?? 'public',
            'published_at' => now(),
        ]);

        $post->load(['user', 'likes']);

        return response()->json([
            'success' => true,
            'message' => 'Post created successfully',
            'data' => $post
        ], 201);
    }

    public function show(Post $post)
    {
        $post->load(['user', 'likes', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $post
        ]);
    }

    public function update(Request $request, Post $post)
    {
        if ($post->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:2000',
            'visibility' => 'in:public,followers,private',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $post->update([
            'content' => $request->content,
            'tags' => $this->extractHashtags($request->content),
            'visibility' => $request->visibility ?? $post->visibility,
        ]);

        $post->load(['user', 'likes']);

        return response()->json([
            'success' => true,
            'message' => 'Post updated successfully',
            'data' => $post
        ]);
    }

    public function destroy(Post $post)
    {
        if ($post->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        // Delete associated media files
        if ($post->media) {
            foreach ($post->media as $media) {
                Storage::disk('public')->delete($media['path']);
            }
        }

        $post->delete();

        return response()->json([
            'success' => true,
            'message' => 'Post deleted successfully'
        ]);
    }

    public function like(Post $post)
    {
        $user = auth()->user();
        
        $like = $post->likes()->where('user_id', $user->id)->first();

        if ($like) {
            $like->delete();
            $post->decrement('likes_count');
            $isLiked = false;
        } else {
            $post->likes()->create([
                'user_id' => $user->id,
                'type' => 'like'
            ]);
            $post->increment('likes_count');
            $isLiked = true;
        }

        return response()->json([
            'success' => true,
            'message' => $isLiked ? 'Post liked' : 'Post unliked',
            'data' => [
                'is_liked' => $isLiked,
                'likes_count' => $post->fresh()->likes_count
            ]
        ]);
    }

    public function getUserPosts(Request $request, User $user)
    {
        $posts = $user->posts()
            ->with(['user', 'likes'])
            ->published()
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $posts
        ]);
    }

    private function extractHashtags($content)
    {
        preg_match_all('/#(\w+)/', $content, $matches);
        return $matches[1] ?? [];
    }
}
