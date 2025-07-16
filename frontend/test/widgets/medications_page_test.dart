import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/medications.dart';

void main() {
  testWidgets('MedicationsRunoutPage shows empty list message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MedicationsRunoutPage()));
    expect(find.text('Лекарства не найдены'), findsOneWidget);

    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
