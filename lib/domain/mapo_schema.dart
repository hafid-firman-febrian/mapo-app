import 'package:firebase_ai/firebase_ai.dart';

final recomendationSchema = Schema.object(
  properties: {
    'name': Schema.string(description: 'Nama menu, mis. "Soto Ayam'),
    'reason': Schema.string(
      description: 'Kenapa cocok - kaitkan ke cuaca, waktu, atau budget',
    ),
    'category': Schema.enumString(
      enumValues: [
        'berkuah',
        'goreng',
        'bakar',
        'pedas',
        'manis',
        'sehat',
        'cepat_saji',
        'nasi',
        'mie',
        'cemilan',
      ],
    ),
    'price_estimate': Schema.integer(description: 'Rupiah per porsi'),
    'spice_level': Schema.enumString(
      enumValues: ['tidak_pedas', 'sedang', 'pedas'],
    ),
    'prep_time': Schema.enumString(enumValues: ['cepat', 'sedang', 'lama']),
    'tags': Schema.array(items: Schema.string()),
  },
  optionalProperties: ['tags'],
);

final mapoResponseSchema = Schema.object(
  properties: {
    'response_type': Schema.enumString(
      enumValues: ['single', 'options', 'clarify'],
      description:
          'single = 1 saran, options = 2-3 pilihan, clarify = butuh info tambahan',
    ),
    'message': Schema.string(
      description: 'Kalimat pembuka gaya ngobrol santai bahasa indonesia',
    ),
    'recomendations': Schema.array(items: recomendationSchema),
    'follow_up': Schema.object(
      properties: {
        'question': Schema.string(),
        'quick_replies': Schema.array(items: Schema.string()),
      },
    ),
    'context-used': Schema.object(
      properties: {
        'weather': Schema.string(),
        'time_of_day': Schema.enumString(
          enumValues: ['sarapan', 'makan_siang', 'makan_malam', 'ngemil'],
        ),
        'based_on_history': Schema.boolean(),
      },
      optionalProperties: ['weather', 'time_of_day', 'based_on_history'],
    ),
  },
  optionalProperties: ['recomendations', 'follow_up', 'context_used'],
);
