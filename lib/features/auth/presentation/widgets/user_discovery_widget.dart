import 'package:flutter/material.dart';
import '../../../../services/internet_p2p_connection_manager.dart';

class UserDiscoveryWidget extends StatefulWidget {
  const UserDiscoveryWidget({super.key});

  @override
  State<UserDiscoveryWidget> createState() => _UserDiscoveryWidgetState();
}

class _UserDiscoveryWidgetState extends State<UserDiscoveryWidget> {
  List<String> _onlineUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOnlineUsers();
  }

  Future<void> _loadOnlineUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await InternetP2PConnectionManager.instance.getOnlineUsers();
      setState(() {
        _onlineUsers = users;
      });
    } catch (e) {
      print('Error loading online users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Online Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOnlineUsers,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_onlineUsers.isEmpty)
              const Text(
                'No users online',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._onlineUsers.map((userId) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    userId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(userId),
                subtitle: const Text('Online'),
                trailing: ElevatedButton(
                  onPressed: () => _connectToUser(userId),
                  child: const Text('Connect'),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToUser(String userId) async {
    try {
      await InternetP2PConnectionManager.instance.connectToUser(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting to $userId...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
