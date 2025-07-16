import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/loginpage.dart';

void main() {
  testWidgets('LoginPage shows form and reacts to input', (tester) async {
    var loginCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(onLogin: (email, pass) async {
        loginCalled = true;
      }),
    ));

    expect(find.text('Вход в систему'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'Password123');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(loginCalled, true);
  });
}
