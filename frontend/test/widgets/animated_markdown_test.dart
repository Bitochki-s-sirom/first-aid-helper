import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/chathelper.dart';

void main() {
  testWidgets('AnimatedMarkdownText animates text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnimatedMarkdownText(text: 'Hello')),
    ));

    expect(find.textContaining('H'), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('H'), findsWidgets);
  });
}
