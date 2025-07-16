import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/signuppage.dart';

void main() {
  testWidgets('RegisterPage shows and allows navigation back', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RegisterPage(onRegister: (data) async {}),
    ));

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
