import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../../../services/p2p_service.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class LoginScreenP2P extends StatefulWidget {
  const LoginScreenP2P({super.key});

  @override
  State<LoginScreenP2P> createState() => _LoginScreenP2PState();
}

class _LoginScreenP2PState extends State<LoginScreenP2P> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _serverController = TextEditingController(
    text: 'https://p2p-signaling-server-1.onrender.com'
  );
  
  bool _isLoading = false;
  bool _showAdvanced = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Predefined servers for easy selection
  final List<Map<String, String>> _servers = [
    {
      'name': 'Global Server (Recommended)',
      'url': 'https://p2p-signaling-server-1.onrender.com',
      'icon': '🌍',
    },
    {
      'name': 'US Server',
      'url': 'https://p2p-us-server.onrender.com',
      'icon': '🇺🇸',
    },
    {
      'name': 'EU Server',
      'url': 'https://p2p-eu-server.onrender.com',
      'icon': '🇪🇺',
    },
    {
      'name': 'Local Development',
      'url': 'ws://localhost:3000',
      'icon': '💻',
    },
  ];

  String _selectedServer = 'https://p2p-signaling-server-1.onrender.com';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _serverController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 48),
                    _buildLoginCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.chat_bubble_rounded,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'P2P Connect',
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Text(
          'Secure • Private • Decentralized',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect directly with anyone, anywhere',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeText(),
            const SizedBox(height: 24),
            _buildUsernameField(),
            const SizedBox(height: 20),
            _buildServerSelection(),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              _buildCustomServerField(),
            ],
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildAdvancedToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.waving_hand,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your username to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        prefixIcon: Icon(
          Icons.person_rounded,
          color: Theme.of(context).primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildServerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Server',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _servers.length,
            itemBuilder: (context, index) {
              final server = _servers[index];
              final isSelected = _selectedServer == server['url'];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Row(
                    children: [
                      Text(server['icon']!),
                      const SizedBox(width: 8),
                      Text(server['name']!),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedServer = server['url']!;
                      _serverController.text = server['url']!;
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  backgroundColor: Colors.grey[100],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomServerField() {
    return TextField(
      controller: _serverController,
      decoration: InputDecoration(
        labelText: 'Custom Server URL',
        hintText: 'wss://your-server.com',
        prefixIcon: Icon(
          Icons.dns_rounded,
          color: Theme.of(context).primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isLoading ? 0 : 4,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Connecting...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded),
                  const SizedBox(width: 12),
                  const Text(
                    'Start Chatting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return TextButton(
      onPressed: () {
        setState(() {
          _showAdvanced = !_showAdvanced;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showAdvanced ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            _showAdvanced ? 'Hide Advanced' : 'Advanced Options',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final serverUrl = _serverController.text.trim();
    
    if (username.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    if (username.length < 3) {
      _showError('Username must be at least 3 characters');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      _showError('Username can only contain letters, numbers, and underscores');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final p2pService = Provider.of<P2PService>(context, listen: false);

      // Create or find user
      final existingUser = userProvider.findUserByUsername(username);
      
      if (existingUser == null) {
        userProvider.createUser(username);
        final user = userProvider.allUsers.last;
        userProvider.setUser(user);
      } else {
        userProvider.setUser(existingUser);
      }
      
      final user = userProvider.currentUser!;

      // Initialize data
      await feedProvider.initializeSampleData();
      await chatProvider.initializeSampleData();

      // Start P2P connection with selected server
      await p2pService.initialize(
        userId: user.id,
        username: username,
        signalingServerUrl: serverUrl,
      );

      if (mounted) {
        _showSuccess('Welcome, $username! 🎉');
        // Navigation will be handled by AppNavigator automatically
      }
    } catch (e) {
      _showError('Connection failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
