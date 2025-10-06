<?php

namespace App\Http\Controllers;

use App\Models\Chat;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChatController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        
        $chats = $user->chats()
            ->with(['participants', 'lastMessage.user'])
            ->orderBy('last_message_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $chats
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:private,group',
            'participant_ids' => 'required|array|min:1',
            'participant_ids.*' => 'exists:users,id',
            'name' => 'required_if:type,group|string|max:100',
            'description' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = auth()->user();
        $participantIds = $request->participant_ids;

        // For private chats, check if chat already exists
        if ($request->type === 'private' && count($participantIds) === 1) {
            $existingChat = Chat::where('type', 'private')
                ->whereHas('participants', function ($query) use ($user) {
                    $query->where('user_id', $user->id);
                })
                ->whereHas('participants', function ($query) use ($participantIds) {
                    $query->where('user_id', $participantIds[0]);
                })
                ->first();

            if ($existingChat) {
                return response()->json([
                    'success' => true,
                    'message' => 'Chat already exists',
                    'data' => $existingChat->load(['participants', 'lastMessage.user'])
                ]);
            }
        }

        // Add current user to participants
        $participantIds[] = $user->id;
        $participantIds = array_unique($participantIds);

        $chat = Chat::create([
            'type' => $request->type,
            'name' => $request->name,
            'description' => $request->description,
            'created_by' => $user->id,
        ]);

        // Attach participants
        $chat->participants()->attach($participantIds, [
            'role' => 'member',
            'joined_at' => now(),
        ]);

        // Make creator admin for group chats
        if ($request->type === 'group') {
            $chat->participants()->updateExistingPivot($user->id, ['role' => 'admin']);
        }

        $chat->load(['participants', 'lastMessage.user']);

        return response()->json([
            'success' => true,
            'message' => 'Chat created successfully',
            'data' => $chat
        ], 201);
    }

    public function show(Chat $chat)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $chat->load(['participants', 'messages.user']);

        return response()->json([
            'success' => true,
            'data' => $chat
        ]);
    }

    public function getMessages(Chat $chat, Request $request)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $messages = $chat->messages()
            ->with(['user', 'replyTo.user'])
            ->notDeleted()
            ->latest()
            ->paginate(50);

        return response()->json([
            'success' => true,
            'data' => $messages
        ]);
    }

    public function sendMessage(Request $request, Chat $chat)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required_without:media|string|max:2000',
            'type' => 'in:text,image,file,audio,video',
            'reply_to' => 'nullable|exists:messages,id',
            'media.*' => 'file|mimes:jpeg,png,jpg,gif,mp4,mov,avi,pdf,doc,docx|max:10240',
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
                $path = $file->store('messages', 'public');
                $media[] = [
                    'path' => $path,
                    'type' => $file->getMimeType(),
                    'size' => $file->getSize(),
                    'name' => $file->getClientOriginalName(),
                ];
            }
        }

        $message = Message::create([
            'chat_id' => $chat->id,
            'user_id' => $user->id,
            'content' => $request->content,
            'type' => $request->type ?? 'text',
            'media' => $media,
            'reply_to' => $request->reply_to,
        ]);

        // Update chat's last message timestamp
        $chat->updateLastMessage();

        $message->load(['user', 'replyTo.user']);

        // Broadcast message to other participants
        broadcast(new \App\Events\MessageSent($message))->toOthers();

        return response()->json([
            'success' => true,
            'message' => 'Message sent successfully',
            'data' => $message
        ], 201);
    }

    public function markAsRead(Chat $chat)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $chat->participants()
            ->where('user_id', $user->id)
            ->update(['last_read_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Chat marked as read'
        ]);
    }

    public function addParticipant(Request $request, Chat $chat)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id) || $chat->type !== 'group') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($chat->isParticipant($request->user_id)) {
            return response()->json([
                'success' => false,
                'message' => 'User is already a participant'
            ], 400);
        }

        $chat->participants()->attach($request->user_id, [
            'role' => 'member',
            'joined_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Participant added successfully'
        ]);
    }

    public function removeParticipant(Request $request, Chat $chat)
    {
        $user = auth()->user();

        if (!$chat->isParticipant($user->id) || $chat->type !== 'group') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $chat->participants()->detach($request->user_id);

        return response()->json([
            'success' => true,
            'message' => 'Participant removed successfully'
        ]);
    }
}
