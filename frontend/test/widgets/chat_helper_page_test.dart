import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/chathelper.dart';

void main() {
  testWidgets('ChatHelperPage shows send button and empty state',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatHelperPage()));

    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.text('Нет чатов'), findsOneWidget);
  });
}
