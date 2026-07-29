import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/category_badge.dart';

void main() {
  testWidgets('menampilkan label kategori', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBadge(category: 'pedas', label: 'pedas'),
        ),
      ),
    );

    expect(find.text('pedas'), findsOneWidget);
  });

  testWidgets('label dibawa lewat Semantics untuk pembaca layar', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBadge(category: 'sehat', label: 'sehat'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('sehat'), findsOneWidget);

    handle.dispose();
  });
}
