import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/quick_reply_chip.dart';

void main() {
  testWidgets('menampilkan label dan memanggil onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang pedas', onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('yang pedas'), findsOneWidget);
    await tester.tap(find.text('yang pedas'));
    expect(tapped, isTrue);
  });

  testWidgets('Semantics menandai selected saat state true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang murah', onTap: () {}, selected: true),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(QuickReplyChip));
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
  });

  testWidgets('Semantics tidak selected secara default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang cepet', onTap: () {}),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(QuickReplyChip));
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isFalse);
  });
}
