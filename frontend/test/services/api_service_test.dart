import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ApiService.login throws error on invalid credentials', () async {
    try {
      await ApiService.login(email: 'invalid', password: 'wrong');
      fail('Expected exception');
    } catch (e) {
      expect(e.toString(), contains('Exception'));
    }
  });
}
