import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

/// Installs the package's own in-memory [TestFlutterSecureStoragePlatform] as
/// [FlutterSecureStoragePlatform.instance], so unit tests exercising
/// [FlutterSecureStorage] don't need a real platform channel.
///
/// Call in `setUp`; the returned map lets a test assert on stored values.
Map<String, String> installFakeSecureStorage() {
  final data = <String, String>{};
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
    data,
  );
  return data;
}
