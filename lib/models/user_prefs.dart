class UserPrefs {
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
}
