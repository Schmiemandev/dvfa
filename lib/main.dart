import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'login_screen.dart';
import 'transfer_screen.dart';

void main() {
  runApp(const DVFAApp());
}

class DVFAApp extends StatefulWidget {
  const DVFAApp({super.key});

  @override
  State<DVFAApp> createState() => _DVFAAppState();
}

class _DVFAAppState extends State<DVFAApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path.contains('transfer')) {
      final String? to = uri.queryParameters['to'];
      final String? amount = uri.queryParameters['amount'];

      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TransferScreen(
            recipient: to,
            amount: amount,
            autoExecute: true,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'DVFA FinTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D1B2A),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B263B),
          brightness: Brightness.dark,
          secondary: const Color(0xFF415A77),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
