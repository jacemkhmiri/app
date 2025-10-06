import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Core
import 'core/theme/app_theme.dart';

// Features
import 'features/auth/presentation/providers/user_provider.dart';
import 'features/auth/presentation/screens/login_screen_p2p.dart';
import 'features/auth/data/repositories/user_repository_impl.dart';
import 'features/auth/data/datasources/user_local_datasource_impl.dart';
import 'features/auth/data/datasources/user_remote_datasource_impl.dart';
import 'features/auth/domain/repositories/user_repository.dart';

import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';

import 'features/feed/presentation/providers/feed_provider.dart';
import 'features/feed/domain/repositories/feed_repository.dart';
import 'features/feed/data/repositories/feed_repository_impl.dart';

import 'features/home/presentation/screens/home_screen.dart';

// Services
import 'services/database_service.dart';
import 'services/p2p_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.init();
  
  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize HTTP client
  final httpClient = http.Client();
  
  // Initialize data sources
  final userLocalDataSource = UserLocalDataSourceImpl(
    sharedPreferences: sharedPreferences,
  );
  
  final userRemoteDataSource = UserRemoteDataSourceImpl(
    client: httpClient,
    baseUrl: 'https://p2p-signaling-server-1.onrender.com',
  );
  
  // Initialize repositories
  final userRepository = UserRepositoryImpl(
    remoteDataSource: userRemoteDataSource,
    localDataSource: userLocalDataSource,
  );
  
  // Initialize chat and feed repositories
  final chatRepository = ChatRepositoryImpl();
  final feedRepository = FeedRepositoryImpl();
  
  runApp(BeautifulP2PApp(
    userRepository: userRepository,
    chatRepository: chatRepository,
    feedRepository: feedRepository,
  ));
}

class BeautifulP2PApp extends StatelessWidget {
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final FeedRepository feedRepository;

  const BeautifulP2PApp({
    super.key,
    required this.userRepository,
    required this.chatRepository,
    required this.feedRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => P2PService(),
        ),
      ],
      child: MaterialApp(
        title: 'P2P Connect',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.currentUser == null) {
          return const LoginScreenP2P();
        }
        return const HomeScreen();
      },
    );
  }
}
