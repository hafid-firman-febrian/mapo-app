enum ResponseType { single, options, clarify }

class MapoResponse {
  final ResponseType responseType;
  final String message;
  final List<Recommendation> recommendations;
  final FollowUp? followUp;
  final ContextUsed? contextUsed;

  const MapoResponse({
    required this.responseType,
    required this.message,
    this.recommendations = const [],
    this.followUp,
    this.contextUsed,
  });

  factory MapoResponse.fromJson(Map<String, dynamic> json) {
    return MapoResponse(
      responseType: _parseType(json['response_type'] as String?),
      message: json['message'] as String? ?? '',
      recommendations:
          (json['recommendations'] as List?)
              ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      followUp: json['follow_up'] == null
          ? null
          : FollowUp.fromJson(json['follow_up'] as Map<String, dynamic>),
      contextUsed: json['context_used'] == null
          ? null
          : ContextUsed.fromJson(json['context_used'] as Map<String, dynamic>),
    );
  }

  static ResponseType _parseType(String? raw) {
    switch (raw) {
      case 'options':
        return ResponseType.options;
      case 'clarify':
        return ResponseType.clarify;
      default:
        return ResponseType.single;
    }
  }
}

class Recommendation {
  final String name;
  final String reason;
  final String category;
  final int priceEstimate;
  final String spiceLevel;
  final String prepTime;
  final List<String> tags;

  const Recommendation({
    required this.name,
    required this.reason,
    required this.category,
    required this.priceEstimate,
    required this.spiceLevel,
    required this.prepTime,
    this.tags = const [],
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      category: json['category'] as String? ?? 'nasi',
      priceEstimate: (json['price_estimate'] as num?)?.toInt() ?? 0,
      spiceLevel: json['spice_level'] as String? ?? 'tidak_pedas',
      prepTime: json['prep_time'] as String? ?? 'sedang',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class FollowUp {
  final String question;
  final List<String> quickReplies;

  const FollowUp({required this.question, this.quickReplies = const []});

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
    question: json['question'] as String? ?? '',
    quickReplies: (json['quick_replies'] as List?)?.cast<String>() ?? const [],
  );
}

class ContextUsed {
  final String? weather;
  final String? timeOfDay;
  final bool basedOnHistory;

  const ContextUsed({
    this.weather,
    this.timeOfDay,
    this.basedOnHistory = false,
  });

  factory ContextUsed.fromJson(Map<String, dynamic> json) => ContextUsed(
    weather: json['weather'] as String?,
    timeOfDay: json['time_of_day'] as String?,
    basedOnHistory: json['based_on_history'] as bool? ?? false,
  );
}

class MapoException implements Exception {
  final String message;
  MapoException(this.message);
  @override
  String toString() => 'MapoException: $message';
}
