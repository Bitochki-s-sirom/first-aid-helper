import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/validators.dart';

void main() {
  test('validateEmail detects invalid emails', () {
    expect(Validators.validateEmail('wrong'), isNotNull);
    expect(Validators.validateEmail('a@test.com'), isNull);
  });

  test('validatePassword detects too short or invalid', () {
    expect(Validators.validatePassword('12345678'), isNotNull);
  });
}
