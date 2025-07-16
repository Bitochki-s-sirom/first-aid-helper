import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/profile.dart';
import '../../lib/widgets/squareavatar.dart';

void main() {
  testWidgets('ProfilePage shows avatar and editable fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.byType(SquareAvatarWithFallback), findsOneWidget);
    expect(find.text('Группа крови'), findsOneWidget);
  });
}
