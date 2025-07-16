import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/squareavatar.dart';

void main() {
  testWidgets('SquareAvatarWithFallback shows fallback initials',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:
          SquareAvatarWithFallback(imageUrl: '', name: 'Иван Иванов', size: 50),
    ));

    expect(find.text('И'), findsOneWidget);
  });
}
