import 'package:flutter/material.dart';
import '../../models/mapo_response.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _categoryEmoji(r.category),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.reason),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                Chip(label: Text('± Rp${_fmt(r.priceEstimate)}')),
                Chip(label: Text(_spiceLabel(r.spiceLevel))),
                Chip(label: Text(r.prepTime)),
                ...r.tags.map((t) => Chip(label: Text(t))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String c) => switch (c) {
    'berkuah' => '🍜',
    'goreng' => '🍗',
    'bakar' => '🍖',
    'pedas' => '🌶️',
    'manis' => '🍰',
    'sehat' => '🥗',
    'mie' => '🍝',
    'nasi' => '🍚',
    'cemilan' => '🍢',
    _ => '🍽️',
  };

  String _spiceLabel(String s) => switch (s) {
    'pedas' => 'pedas 🌶️',
    'sedang' => 'agak pedas',
    _ => 'tidak pedas',
  };

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
}
