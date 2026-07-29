import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapo_app/firebase_options.dart';
import 'package:mapo_app/themes/app_theme.dart';
import 'package:mapo_app/ui/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
  );

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  debugPrint('UID: ${FirebaseAuth.instance.currentUser?.uid}');
  runApp(const ProviderScope(child: MapoApp()));
}

class MapoApp extends StatelessWidget {
  const MapoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapoApp',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const ChatScreen(),
    );
  }
}
