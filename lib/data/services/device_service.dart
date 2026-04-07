import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../datasources/local/secure_device_storage.dart';

/// Stable per-install device identifier (no MAC address).
///
/// Stored in secure storage; derived display token can be used for support without
/// exposing the raw id in UI if desired.
class DeviceService {
  DeviceService(this._secure);

  final SecureDeviceStorage _secure;
  static const _uuid = Uuid();

  /// Application-specific salt (obfuscation layer; pair with server-side validation).
  static const String _salt = 'ztx|v1|device';

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secure.readDeviceId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final raw = _uuid.v4();
    await _secure.writeDeviceId(raw);
    return raw;
  }

  /// Opaque fingerprint for logs/support (not the raw device id).
  String obfuscatedFingerprint(String deviceId) {
    final bytes = utf8.encode('$_salt|$deviceId');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Strong random token for client-side nonces if needed later.
  String randomNonce() {
    final r = Random.secure();
    final list = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(list);
  }
}
