import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/chathelper.dart';

void main() {
  testWidgets('ChatMessageWidget shows user text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ChatMessageWidget(text: 'Привет', isUser: true)),
    ));

    expect(find.text('Привет'), findsOneWidget);
  });
}
