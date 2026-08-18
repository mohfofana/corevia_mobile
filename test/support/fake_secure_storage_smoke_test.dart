import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_secure_storage.dart';

void main() {
  test('installFakeSecureStorage backs FlutterSecureStorage in-memory', () async {
    final data = installFakeSecureStorage();
    const storage = FlutterSecureStorage();

    await storage.write(key: 'auth_token', value: 'abc123');

    expect(data['auth_token'], 'abc123');
    expect(await storage.read(key: 'auth_token'), 'abc123');

    await storage.delete(key: 'auth_token');
    expect(await storage.read(key: 'auth_token'), isNull);
  });
}
