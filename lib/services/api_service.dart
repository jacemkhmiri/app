import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String username,
      {String? password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        if (password != null) 'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (data['success'] && data['data']['token'] != null) {
      await setToken(data['data']['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    String? email,
    String? firstName,
    String? lastName,
    String? password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        if (email != null) 'email': email,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (password != null) 'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (data['success'] && data['data']['token'] != null) {
      await setToken(data['data']['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    await clearToken();
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateOnlineStatus(bool isOnline) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/online-status'),
      headers: _headers,
      body: jsonEncode({'is_online': isOnline}),
    );
    return jsonDecode(response.body);
  }

  // User endpoints
  static Future<Map<String, dynamic>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users?search=$query'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOnlineUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/online'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> followUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Post endpoints
  static Future<Map<String, dynamic>> getPosts({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts?page=$page'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPost({
    required String content,
    String visibility = 'public',
    List<File>? media,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
    );

    request.headers.addAll(_headers);
    request.fields['content'] = content;
    request.fields['visibility'] = visibility;

    if (media != null) {
      for (int i = 0; i < media.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('media[$i]', media[i].path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> likePost(int postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Chat endpoints
  static Future<Map<String, dynamic>> getChats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createChat({
    required String type,
    required List<int> participantIds,
    String? name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats'),
      headers: _headers,
      body: jsonEncode({
        'type': type,
        'participant_ids': participantIds,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMessages(int chatId,
      {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/$chatId/messages?page=$page'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String content,
    String type = 'text',
    int? replyTo,
    List<File>? media,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/chats/$chatId/messages'),
    );

    request.headers.addAll(_headers);
    request.fields['content'] = content;
    request.fields['type'] = type;
    if (replyTo != null) request.fields['reply_to'] = replyTo.toString();

    if (media != null) {
      for (int i = 0; i < media.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('media[$i]', media[i].path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markChatAsRead(int chatId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/$chatId/read'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}
