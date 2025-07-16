import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/medications.dart';

void main() {
  testWidgets('AddMedicationDialog shows fields', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AddMedicationDialog(onAdd: (_) {}),
            );
          },
          child: const Text('open'),
        );
      }),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить лекарство'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
