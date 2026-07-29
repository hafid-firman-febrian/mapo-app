class WeatherContext {
  final String description;
  final double temperature;
  final bool isKnown;

  WeatherContext({
    required this.description,
    required this.temperature,
    this.isKnown = true,
  });

  factory WeatherContext.unknown() {
    return WeatherContext(
      description: 'unknown',
      temperature: 0,
      isKnown: false,
    );
  }

  /// `isKnown` hanya true kalau kedua field memang ada di payload. Payload
  /// rusak tidak boleh jadi "unknown, 0°C" yang dianggap fakta — prompt Gemini
  /// (`_buildContextBlock`) mencetak cuaca apa adanya kalau `isKnown` true.
  factory WeatherContext.fromApi(Map<String, dynamic> json) {
    final entries = json['weather'] as List?;
    final first = (entries == null || entries.isEmpty)
        ? null
        : entries.first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>?;
    final description = first?['description'] as String?;
    final temperature = (main?['temp'] as num?)?.toDouble();

    return WeatherContext(
      description: description ?? 'unknown',
      temperature: temperature ?? 0,
      isKnown: description != null && temperature != null,
    );
  }

  factory WeatherContext.fromCache(Map<String, dynamic> data) {
    final description = data['description'] as String?;
    final temperature = (data['temperature'] as num?)?.toDouble();

    return WeatherContext(
      description: description ?? 'unknown',
      temperature: temperature ?? 0,
      isKnown: description != null && temperature != null,
    );
  }

  Map<String, dynamic> toCache() => {
    'description': description,
    'temperature': temperature,
  };
}
