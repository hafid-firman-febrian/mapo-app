class UserPrefs {
  static const budgetOptions = [
    '< 15.000',
    '15.000-25.000',
    '25.000-50.000',
    '> 50.000',
  ];

  static const restrictionOptions = [
    'tidak pedas',
    'halal',
    'vegetarian',
    'tanpa gorengan',
    'tanpa seafood',
  ];

  final String budgetRange;
  final List<String> restrictions;

  const UserPrefs({
    this.budgetRange = '15.000-25.000',
    this.restrictions = const [],
  });

  factory UserPrefs.fromDoc(Map<String, dynamic> data) => UserPrefs(
    budgetRange: data['budget_range'] as String? ?? '15.000-25.000',
    restrictions: (data['restrictions'] as List?)?.cast<String>() ?? const [],
  );

  Map<String, dynamic> toDoc() => {
    'budget_range': budgetRange,
    'restrictions': restrictions,
  };

  UserPrefs copyWith({String? budgetRange, List<String>? restrictions}) =>
      UserPrefs(
        budgetRange: budgetRange ?? this.budgetRange,
        restrictions: restrictions ?? this.restrictions,
      );
}
