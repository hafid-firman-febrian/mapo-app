import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import '../models/chat_turn.dart';
import '../models/mapo_response.dart';
import 'widgets/recommendation_card.dart';

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

    await ref
        .read(chatProvider.notifier)
        .ask(text, lat: coords?.lat, lng: coords?.lng);

    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapo')),
      body: Column(
        children: [
          Expanded(
            child: turns.isEmpty
                ? const Center(child: Text('Bingung mau makan apa?'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: turns.length,
                    itemBuilder: (context, i) =>
                        _TurnView(turn: turns[i], onQuickReply: _send),
                  ),
          ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  final ChatTurn turn;
  final Future<void> Function(String) onQuickReply;

  const _TurnView({required this.turn, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    return switch (turn) {
      UserTurn(:final text) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text),
        ),
      ),
      PendingTurn() => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Mapo mikir dulu...'),
          ],
        ),
      ),
      ErrorTurn(:final message) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      MapoTurn(:final response) => _ResponseView(
        response: response,
        onQuickReply: onQuickReply,
      ),
    };
  }
}

class _ResponseView extends StatelessWidget {
  final MapoResponse response;
  final Future<void> Function(String) onQuickReply;

  const _ResponseView({required this.response, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response.message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Badge grounding — bukti konteks terpakai
          if (response.contextUsed?.weather != null)
            Chip(
              avatar: const Icon(Icons.cloud, size: 16),
              label: Text('berdasarkan ${response.contextUsed!.weather}'),
            ),
          const SizedBox(height: 12),

          // Layout ditentukan response_type
          ...switch (response.responseType) {
            ResponseType.clarify => [
              if (response.followUp != null) ...[
                Text(response.followUp!.question),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: response.followUp!.quickReplies
                      .map(
                        (r) => ActionChip(
                          label: Text(r),
                          onPressed: () => onQuickReply(r),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
            _ => response.recommendations
                .map((r) => RecommendationCard(recommendation: r))
                .toList(),
          },
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Lagi pengen apa? (mis. hujan, pengen anget)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
