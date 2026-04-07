import 'package:hive_flutter/hive_flutter.dart';

/// Device id + license JWT (Hive-backed so it builds on Windows without ATL).
///
/// On Android/iOS, consider [flutter_secure_storage] or a platform channel if
/// you need hardware-backed keystore/keychain; Hive persists under app data.
class SecureDeviceStorage {
  SecureDeviceStorage();

  Box<String> get _box => Hive.box<String>('secure_storage');

  static const _kDeviceId = 'ztx_did_v1';
  static const _kLicenseToken = 'ztx_ltk_v1';

  Future<String?> readDeviceId() async => _box.get(_kDeviceId);

  Future<void> writeDeviceId(String value) async => _box.put(_kDeviceId, value);

  Future<String?> readLicenseToken() async => _box.get(_kLicenseToken);

  Future<void> writeLicenseToken(String value) async =>
      _box.put(_kLicenseToken, value);

  Future<void> clearLicenseToken() async => _box.delete(_kLicenseToken);
}
