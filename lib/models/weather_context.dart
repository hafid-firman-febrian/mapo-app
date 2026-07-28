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

  factory WeatherContext.fromApi(Map<String, dynamic> json) {
    final entries = json['weather'] as List?;
    final first = (entries == null || entries.isEmpty)
        ? null
        : entries.first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>?;

    return WeatherContext(
      description: first?['description'] as String? ?? 'unknown',
      temperature: (main?['temp'] as num?)?.toDouble() ?? 0,
    );
  }

  factory WeatherContext.fromCache(Map<String, dynamic> data) {
    return WeatherContext(
      description: data['description'] as String? ?? 'unknown',
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toCache() => {
    'description': description,
    'temperature': temperature,
  };
}
