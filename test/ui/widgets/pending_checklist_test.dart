import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/pending_checklist.dart';

void main() {
  testWidgets('menampilkan Mapo lagi mikir dan step pertama di awal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PendingChecklist(stepDuration: Duration(milliseconds: 50)),
        ),
      ),
    );

    expect(find.text('Mapo lagi mikir...'), findsOneWidget);
    expect(find.text('Ngecek cuaca...'), findsOneWidget);

    // Bereskan timer yang masih jalan sebelum widget tree di-dispose.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('step berikutnya muncul bertahap seiring waktu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PendingChecklist(stepDuration: Duration(milliseconds: 50)),
        ),
      ),
    );

    expect(find.text('Ngecek riwayat makan...'), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Ngecek riwayat makan...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Menyusun saran...'), findsOneWidget);

    // Tidak ada step ke-4 — timer berhenti sendiri di step terakhir.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Menyusun saran...'), findsOneWidget);
  });
}
