import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udemy_tracker/features/planner/presentation/today_dashboard_screen.dart';

void main() {
  testWidgets(
    'daily capacity dialog cancels and saves without lifecycle errors',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _DialogTestHost()));

      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Saved: none'), findsOneWidget);

      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '90');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved: 90'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('daily capacity dialog rejects zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _DialogTestHost()));

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a positive whole number.'), findsOneWidget);
    expect(find.byType(DailyCapacityDialog), findsOneWidget);
  });
}

class _DialogTestHost extends StatefulWidget {
  const _DialogTestHost();

  @override
  State<_DialogTestHost> createState() => _DialogTestHostState();
}

class _DialogTestHostState extends State<_DialogTestHost> {
  int? _savedMinutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saved: ${_savedMinutes ?? 'none'}'),
            ElevatedButton(
              onPressed: () => showDailyCapacityDialog(
                context,
                initialMinutes: 60,
                onSave: (minutes) async {
                  setState(() => _savedMinutes = minutes);
                },
              ),
              child: const Text('Open editor'),
            ),
          ],
        ),
      ),
    );
  }
}
