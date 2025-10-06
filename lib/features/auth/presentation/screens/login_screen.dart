import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../../../services/internet_p2p_connection_manager.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 48),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.connect_without_contact,
        size: 80,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'P2P Connect',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          'Decentralized Messaging & Newsfeed',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Connect directly, stay private',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Your Username',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Choose a username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    if (username.length < 3) {
      _showError('Username must be at least 3 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final existingUser = userProvider.findUserByUsername(username);

      if (existingUser != null) {
        await _loginExistingUser(existingUser, userProvider, feedProvider, chatProvider);
      } else {
        await _createNewUser(username, userProvider, feedProvider, chatProvider);
      }
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginExistingUser(
    existingUser,
    UserProvider userProvider,
    FeedProvider feedProvider,
    ChatProvider chatProvider,
  ) async {
    userProvider.setUser(existingUser);
    await feedProvider.initializeSampleData();
    await chatProvider.initializeSampleData();
    await _startP2P(existingUser);

    if (mounted) {
      _showSuccess('Welcome back, ${existingUser.name}! 👋');
    }
  }

  Future<void> _createNewUser(
    String username,
    UserProvider userProvider,
    FeedProvider feedProvider,
    ChatProvider chatProvider,
  ) async {
    userProvider.createUser(username);
    final newUser = userProvider.allUsers.last;
    userProvider.setUser(newUser);
    await feedProvider.initializeSampleData();
    await chatProvider.initializeSampleData();
    await _startP2P(newUser);

    if (mounted) {
      _showSuccess('Welcome to P2P Connect, $username! 🚀');
    }
  }

  Future<void> _startP2P(user) async {
    await InternetP2PConnectionManager.instance.start(
      user.id,
      signalingServerUrl: 'ws://localhost:3000',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}