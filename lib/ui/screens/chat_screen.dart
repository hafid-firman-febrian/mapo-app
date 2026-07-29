import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/chat_turn.dart';
import '../../models/mapo_response.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/grounding_badge.dart';
import '../widgets/mapo_drawer.dart';
import '../widgets/mapo_header.dart';
import '../widgets/pending_checklist.dart';
import '../widgets/quick_reply_chip.dart';
import '../widgets/recommendation_card.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final coords = await ref.read(coordsProvider.future);
    if (!mounted) return;

    await ref.read(chatProvider.notifier).ask(text, lat: coords?.lat, lng: coords?.lng);

    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _retryLast(List<ChatTurn> turns) {
    for (final turn in turns.reversed) {
      if (turn is UserTurn) {
        _send(turn.text);
        return;
      }
    }
  }

  /// "Makan ini" belum tersambung ke Firestore — itu Task 6 dari plan
  /// arsitektur, di luar scope plan ini. Tanpa handler ini sama sekali,
  /// RecommendationCard's onPick jadi null dan tombol "Makan ini" — CTA
  /// utama menurut style guide — akan tampil disabled/abu-abu. SnackBar
  /// ini kasih umpan balik nyata tanpa berpura-pura sudah tersimpan permanen.
  void _pickMeal(BuildContext context, Recommendation recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Oke, ${recommendation.name} dicatat!')),
    );
  }

  void _navigateFromDrawer(BuildContext context, MapoDrawerItem item) {
    Navigator.of(context).pop();
    switch (item) {
      case MapoDrawerItem.cariMakan:
        break;
      case MapoDrawerItem.riwayat:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiwayatScreen()));
      case MapoDrawerItem.favorit:
      case MapoDrawerItem.pengaturan:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatProvider);
    final isPending = turns.isNotEmpty && turns.last is PendingTurn;
    final entriesAsync = ref.watch(mealHistoryEntriesProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: turns.isEmpty ? 'Mangan opo hari ini?' : 'Mapo',
        subtitle: turns.isEmpty ? 'Halo! Bingung mau makan apa?' : null,
        leading: Builder(
          builder: (context) => MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedMenu01,
            label: 'Buka menu',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedUserCircle,
            label: 'Profil',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilScreen())),
          ),
        ],
      ),
      drawer: MapoDrawer(
        userName: ref.watch(currentUserDisplayProvider).displayName,
        mealCount: entriesAsync.value?.length,
        onNavigate: (item) => _navigateFromDrawer(context, item),
      ),
      body: ChatConversationBody(
        turns: turns,
        controller: _controller,
        onSend: _send,
        scrollController: _scroll,
        inputEnabled: !isPending,
        onRetryLast: turns.isEmpty ? null : () => _retryLast(turns),
        onPick: (r) => _pickMeal(context, r),
      ),
    );
  }
}

class ChatConversationBody extends StatelessWidget {
  final List<ChatTurn> turns;
  final TextEditingController controller;
  final Future<void> Function(String) onSend;
  final ScrollController scrollController;
  final bool inputEnabled;
  final void Function(Recommendation)? onPick;
  final VoidCallback? onRetryLast;

  const ChatConversationBody({
    super.key,
    required this.turns,
    required this.controller,
    required this.onSend,
    required this.scrollController,
    this.inputEnabled = true,
    this.onRetryLast,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: turns.isEmpty
              ? _HomeEmptyState(onExampleTap: onSend)
              : ListView.builder(
                  controller: scrollController,
                  padding: AppSpacing.screenPad,
                  itemCount: turns.length,
                  itemBuilder: (context, i) {
                    final isLast = i == turns.length - 1;
                    return _TurnEntrance(
                      child: _TurnView(
                        turn: turns[i],
                        onQuickReply: onSend,
                        onRetry: isLast ? onRetryLast : null,
                        onPick: onPick,
                      ),
                    );
                  },
                ),
        ),
        ChatInputBar(controller: controller, onSend: onSend, enabled: inputEnabled),
      ],
    );
  }
}

class _TurnEntrance extends StatelessWidget {
  final Widget child;
  const _TurnEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: child,
    );
  }
}

class _TurnView extends StatelessWidget {
  final ChatTurn turn;
  final ValueChanged<String> onQuickReply;
  final VoidCallback? onRetry;
  final void Function(Recommendation)? onPick;

  const _TurnView({
    required this.turn,
    required this.onQuickReply,
    this.onRetry,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return switch (turn) {
      UserTurn(:final text) => _UserBubble(text: text),
      PendingTurn() => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: PendingChecklist(),
        ),
      ErrorTurn(:final message) => _ErrorBubble(message: message, onRetry: onRetry),
      MapoTurn(:final response) => _MapoResponseView(
          response: response,
          onQuickReply: onQuickReply,
          onRetry: onRetry,
          onPick: onPick,
        ),
    };
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration:
            BoxDecoration(color: AppColors.brandFill, borderRadius: BorderRadius.circular(AppRadius.chip)),
        child: Text(text, style: AppText.bodyLarge.copyWith(color: AppColors.ink)),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.redFill, borderRadius: AppRadius.rCardSmall),
      child: Row(
        children: [
          Expanded(child: Text(message, style: AppText.bodyMedium.copyWith(color: AppColors.redDark))),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ],
      ),
    );
  }
}

class _MapoResponseView extends StatelessWidget {
  final MapoResponse response;
  final ValueChanged<String> onQuickReply;
  final VoidCallback? onRetry;
  final void Function(Recommendation)? onPick;

  const _MapoResponseView({
    required this.response,
    required this.onQuickReply,
    this.onRetry,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(response.message, style: AppText.section),
          const SizedBox(height: AppSpacing.xs),
          GroundingBadge(contextUsed: response.contextUsed),
          const SizedBox(height: AppSpacing.sm),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (response.responseType) {
      case ResponseType.single:
        if (response.recommendations.isEmpty) return const [_NoRecommendationsNotice()];
        final first = response.recommendations.first;
        return [
          RecommendationCard(
            recommendation: first,
            onRetry: onRetry,
            onPick: onPick == null ? null : () => onPick!(first),
          ),
        ];
      case ResponseType.options:
        if (response.recommendations.isEmpty) return const [_NoRecommendationsNotice()];
        return response.recommendations
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: RecommendationCard(
                  recommendation: r,
                  variant: RecommendationCardVariant.row,
                  onTap: () => onQuickReply('pilih ${r.name}'),
                ),
              ),
            )
            .toList();
      case ResponseType.clarify:
        final followUp = response.followUp;
        if (followUp == null) return const [];
        return [
          Text(followUp.question, style: AppText.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: followUp.quickReplies
                .map((r) => QuickReplyChip(label: r, onTap: () => onQuickReply(r)))
                .toList(),
          ),
        ];
    }
  }
}

class _NoRecommendationsNotice extends StatelessWidget {
  const _NoRecommendationsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.lineSoft, borderRadius: AppRadius.rCardSmall),
      child: Text('Mapo belum nemu saran yang pas. Coba ceritain lebih detail ya.', style: AppText.bodyMedium),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  final ValueChanged<String> onExampleTap;
  const _HomeEmptyState({required this.onExampleTap});

  static const _examples = ['lagi hujan, pengen anget', 'budget 15rb, yang murah', 'pengen yang pedas'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.iconBoxLarge,
            height: AppSizes.iconBoxLarge,
            decoration: const BoxDecoration(color: AppColors.brandFill, shape: BoxShape.circle),
            child: Center(
              child:
                  HugeIcon(icon: HugeIcons.strokeRoundedSmile, color: AppColors.brand, size: AppSizes.iconLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Cerita aja ke Mapo', style: AppText.section),
          const SizedBox(height: AppSpacing.xs),
          Text('Lagi pengen apa, budget berapa, mood apa — Mapo bantu pilihin', style: AppText.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text('COBA TANYA', style: AppText.caption.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppSpacing.xs),
          ..._examples.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _ExampleChip(text: e, onTap: () => onExampleTap(e)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: AppRadius.rChip,
      child: InkWell(
        borderRadius: AppRadius.rChip,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.chipPad,
          child: Text(text, style: AppText.bodyMedium.copyWith(color: AppColors.ink)),
        ),
      ),
    );
  }
}
