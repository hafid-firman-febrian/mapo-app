import 'package:flutter/material.dart';
import '../../models/chat_turn.dart';
import '../../models/user_prefs.dart';
import '../../themes/app_colors.dart';
import '../screens/chat_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/riwayat_screen.dart';
import '../widgets/mapo_drawer.dart';
import '../widgets/mapo_header.dart';
import 'mock_data.dart';

class ScreensGallery extends StatelessWidget {
  const ScreensGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_GalleryEntry>[
      _GalleryEntry('Home', () => _ChatPreview(turns: mockTurnsHome())),
      _GalleryEntry('Loading', () => _ChatPreview(turns: mockTurnsLoading())),
      _GalleryEntry('Single', () => _ChatPreview(turns: mockTurnsSingle())),
      _GalleryEntry('Options', () => _ChatPreview(turns: mockTurnsOptions())),
      _GalleryEntry('Clarify', () => _ChatPreview(turns: mockTurnsClarify())),
      _GalleryEntry('Error', () => _ChatPreview(turns: mockTurnsError())),
      _GalleryEntry(
        'Riwayat (terisi)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Riwayat makan', color: AppColors.green),
          body: RiwayatBody(entries: mockMealHistoryEntries()),
        ),
      ),
      _GalleryEntry(
        'Riwayat (kosong)',
        () => const Scaffold(
          appBar: MapoHeader(title: 'Riwayat makan', color: AppColors.green),
          body: RiwayatBody(entries: mockMealHistoryEmpty),
        ),
      ),
      _GalleryEntry(
        'Profil (anonim)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Profil'),
          body: ProfilBody(
            displayName: 'Ammar',
            isAnonymous: true,
            prefs: const UserPrefs(),
            onGoogleSignInTap: () {},
          ),
        ),
      ),
      _GalleryEntry(
        'Menu (drawer)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Cari makan'),
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 12, onNavigate: (_) {}),
          body: const Center(child: Text('Buka drawer lewat ikon menu di header')),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mapo — semua tampilan (debug)')),
      body: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          title: Text(entries[i].label),
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => entries[i].builder())),
        ),
      ),
    );
  }
}

class _GalleryEntry {
  final String label;
  final Widget Function() builder;
  _GalleryEntry(this.label, this.builder);
}

class _ChatPreview extends StatefulWidget {
  final List<ChatTurn> turns;
  const _ChatPreview({required this.turns});

  @override
  State<_ChatPreview> createState() => _ChatPreviewState();
}

class _ChatPreviewState extends State<_ChatPreview> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.turns.isNotEmpty && widget.turns.last is PendingTurn;
    return Scaffold(
      appBar: const MapoHeader(title: 'Mapo (preview)'),
      body: ChatConversationBody(
        turns: widget.turns,
        controller: _controller,
        onSend: (_) async {},
        scrollController: _scroll,
        inputEnabled: !isPending,
        onPick: (r) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('(preview) ${r.name} dipilih')),
        ),
      ),
    );
  }
}
