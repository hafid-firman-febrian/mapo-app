import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/widgets/prefs_edit_sheet.dart';

import '../../domain/mapo_recommender_test.dart'
    show FakeMapoChat, FakeMealHistory, FakeWeatherService;

void main() {
  testWidgets('memilih chip lalu Simpan memanggil savePreferences dan menutup sheet', (
    tester,
  ) async {
    final history = FakeMealHistory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapoChatProvider.overrideWithValue(FakeMapoChat(null)),
          currentUserIdProvider.overrideWithValue('u1'),
          weatherServiceProvider.overrideWithValue(FakeWeatherService()),
          mealHistoryProvider.overrideWithValue(history),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => PrefsEditSheet.show(context, const UserPrefs()),
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.text('Selera kamu'), findsOneWidget);

    await tester.tap(find.text('> 50.000'));
    await tester.pump();
    await tester.tap(find.text('halal'));
    await tester.pump();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(history.savedPrefs.single.budgetRange, '> 50.000');
    expect(history.savedPrefs.single.restrictions, ['halal']);
    expect(find.text('Selera kamu'), findsNothing);
  });
}
