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
    return WeatherContext(
      description: json['weather'][0]['description'] as String? ?? 'unknown',
      temperature: (json['main']['temp'] as double)?.toDouble() ?? 0,
    );
  }

  factory WeatherContext.fromCache(Map<String, dynamic> data) {
    return WeatherContext(
      description: data['description'] as String,
      temperature: (data['temperature'] as double).toDouble(),
      isKnown: true,
    );
  }

  Map<String, dynamic> toCache() => {
    'description': description,
    'temperature': temperature,
  };
}
