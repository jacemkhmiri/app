import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Core

// Features
import 'features/auth/presentation/providers/user_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.init();
  
  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize HTTP client
  final httpClient = http.Client();
  
  // Initialize connectivity
  // final connectivity = Connectivity();
  
  // Initialize network info
  // final networkInfo = NetworkInfoImpl(connectivity: connectivity);
  
  // Initialize data sources
  final userLocalDataSource = UserLocalDataSourceImpl(
    sharedPreferences: sharedPreferences,
  );
  
  final userRemoteDataSource = UserRemoteDataSourceImpl(
    client: httpClient,
    baseUrl: 'http://localhost:8000', // Replace with your backend URL
  );
  
  // Initialize repositories
  final userRepository = UserRepositoryImpl(
    remoteDataSource: userRemoteDataSource,
    localDataSource: userLocalDataSource,
  );
  
  // Initialize chat and feed repositories
  final chatRepository = ChatRepositoryImpl();
  final feedRepository = FeedRepositoryImpl();
  
  runApp(MyApp(
    userRepository: userRepository,
    chatRepository: chatRepository,
    feedRepository: feedRepository,
  ));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final ChatRepository chatRepository;
  final FeedRepository feedRepository;

  const MyApp({
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
      ],
      child: MaterialApp(
        title: 'P2P Connect',
        theme: _buildTheme(),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return userProvider.currentUser == null
                ? const LoginScreen()
                : const HomeScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.teal,
      primaryColor: const Color(0xFF075E54),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: const Color(0xFF128C7E),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF075E54),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF128C7E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
