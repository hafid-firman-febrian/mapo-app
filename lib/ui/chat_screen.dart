import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import '../models/mapo_response.dart';
import 'widgets/recommendation_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final coords = await ref.read(coordsProvider.future);
    await ref
        .read(chatProvider.notifier)
        .ask(text, lat: coords?.lat, lng: coords?.lng);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapo')),
      body: Column(
        children: [
          Expanded(
            child: chat.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Mapo lagi bingung, coba lagi ya ${e.toString()}'),
              ),
              data: (response) => response == null
                  ? const Center(child: Text('Bingung mau makan apa?'))
                  : _ResponseView(response: response, onQuickReply: _send),
            ),
          ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _ResponseView extends StatelessWidget {
  final MapoResponse response;
  final void Function(String) onQuickReply;

  const _ResponseView({required this.response, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(response.message, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // Badge grounding — bukti konteks terpakai
        if (response.contextUsed?.weather != null)
          Chip(
            avatar: const Icon(Icons.cloud, size: 16),
            label: Text('berdasarkan ${response.contextUsed!.weather}'),
          ),
        const SizedBox(height: 16),

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
          _ =>
            response.recommendations
                .map((r) => RecommendationCard(recommendation: r))
                .toList(),
        },
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;

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
