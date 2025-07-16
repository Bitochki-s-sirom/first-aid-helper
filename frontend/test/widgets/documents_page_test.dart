import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/records.dart';

void main() {
  testWidgets('DocumentsPage shows something', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DocumentsPage()));

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
