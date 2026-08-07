import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/mapo_drawer.dart';

void main() {
  testWidgets('menampilkan nama dan jumlah makan kalau ada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 12, onNavigate: (_) {}),
        ),
      ),
    );
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Ammar'), findsOneWidget);
    expect(find.textContaining('12 kali'), findsOneWidget);
  });

  testWidgets('subjudul generik kalau mealCount null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', onNavigate: (_) {}),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.textContaining('kali'), findsNothing);
  });

  testWidgets('tap Cari makan memanggil onNavigate dengan item yang benar', (tester) async {
    MapoDrawerItem? navigated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 3, onNavigate: (i) => navigated = i),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari makan'));
    expect(navigated, MapoDrawerItem.cariMakan);
  });

  testWidgets('Favorit tidak lagi ada di drawer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', onNavigate: (_) {}),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.textContaining('Favorit'), findsNothing);
  });

  testWidgets('tap Pengaturan memanggil onNavigate dengan item yang benar', (
    tester,
  ) async {
    MapoDrawerItem? navigated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', onNavigate: (i) => navigated = i),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengaturan'));

    expect(navigated, MapoDrawerItem.pengaturan);
  });
}
