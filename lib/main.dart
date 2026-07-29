import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/firebase_options.dart';
import 'package:mapo_app/themes/app_colors.dart';
import 'package:mapo_app/themes/app_theme.dart';
import 'package:mapo_app/ui/debug/screens_gallery.dart';
import 'package:mapo_app/ui/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
  );

  // Sign-in anonim tidak boleh menghalangi runApp. Kalau first launch terjadi
  // tanpa koneksi, panggilan ini throw — tanpa guard ini future main() reject,
  // runApp tak pernah kepanggil, dan layar tinggal putih tanpa pesan apa pun.
  // Sisa app sudah aman tanpa user: currentUserIdProvider balikin null dan
  // ChatNotifier.ask merender ErrorTurn('Belum login, coba buka ulang app').
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in gagal: $e');
    }
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
      routes: kDebugMode
          ? {'/debug': (context) => const ScreensGallery()}
          : const {},
      home: kDebugMode ? const _DebugHome() : const ChatScreen(),
    );
  }
}

class _DebugHome extends StatelessWidget {
  const _DebugHome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ChatScreen(),
        Positioned(
          right: 16,
          bottom: 88,
          child: FloatingActionButton.small(
            heroTag: 'debug-gallery-fab',
            onPressed: () => Navigator.of(context).pushNamed('/debug'),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedIdea01,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
