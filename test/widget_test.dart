// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:p2p_connect/core/providers/app_providers.dart';
import 'package:p2p_connect/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('P2P Connect app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: AppProviders.providers,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that our app loads with the login screen
    expect(find.text('P2P Connect'), findsOneWidget);
    expect(find.text('Enter Your Username'), findsOneWidget);
    expect(find.text('Decentralized Messaging & Newsfeed'), findsOneWidget);
  });
}
