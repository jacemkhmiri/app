import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/user_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/feed/presentation/providers/feed_provider.dart';

class AppProviders {
  static List<ChangeNotifierProvider> get providers => [
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
    ChangeNotifierProvider(create: (_) => FeedProvider()),
  ];
}
