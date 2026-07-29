import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/chat_input_bar.dart';

void main() {
  testWidgets('tap tombol kirim memanggil onSend dengan teks yang diketik', (tester) async {
    final controller = TextEditingController();
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (t) => sent = t),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'laper');
    await tester.tap(find.bySemanticsLabel('Kirim pesan'));

    expect(sent, 'laper');
  });

  testWidgets('teks kosong tidak memanggil onSend', (tester) async {
    final controller = TextEditingController();
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) => called = true),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Kirim pesan'));
    expect(called, isFalse);
  });

  testWidgets('teks spasi-doang tidak memanggil onSend', (tester) async {
    final controller = TextEditingController();
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) => called = true),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.bySemanticsLabel('Kirim pesan'));
    expect(called, isFalse);
  });

  testWidgets('enabled false menonaktifkan field dan ganti hint', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) {}, enabled: false),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(find.text('Tunggu sebentar...'), findsOneWidget);
  });

  testWidgets('submit lewat keyboard action memanggil onSend', (tester) async {
    final controller = TextEditingController();
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (t) => sent = t),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'pengen yang pedas');
    await tester.testTextInput.receiveAction(TextInputAction.send);

    expect(sent, 'pengen yang pedas');
  });
}
