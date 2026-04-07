import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/license_constants.dart';
import '../../../domain/entities/license.dart';

/// Persists last known-good license for offline grace.
class LicenseLocalDatasource {
  Box get _box => Hive.box('license_cache');

  static const _kPayload = 'license_payload';
  static const _kLastSuccessMs = 'last_success_ms';

  License? readCached() {
    final map = _box.get(_kPayload);
    if (map is! Map) return null;
    return _fromMap(Map<String, dynamic>.from(map));
  }

  Future<void> writeCached(License license) async {
    await _box.put(_kPayload, _toMap(license));
    await _box.put(
      _kLastSuccessMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  DateTime? lastSuccessfulCheck() {
    final ms = _box.get(_kLastSuccessMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clear() async {
    await _box.delete(_kPayload);
    await _box.delete(_kLastSuccessMs);
  }

  Map<String, dynamic> _toMap(License l) {
    return {
      'deviceId': l.deviceId,
      'status': l.status.name,
      'trialStart': l.trialStart?.toIso8601String(),
      'trialEnd': l.trialEnd?.toIso8601String(),
      'expirationDate': l.expirationDate?.toIso8601String(),
      'lastValidatedAt': l.lastValidatedAt?.toIso8601String(),
      'offlineGraceUntil': l.offlineGraceUntil?.toIso8601String(),
    };
  }

  License _fromMap(Map<String, dynamic> m) {
    return License(
      deviceId: m['deviceId'] as String? ?? '',
      status: _parseStatus(m['status'] as String?),
      trialStart: _parse(m['trialStart']),
      trialEnd: _parse(m['trialEnd']),
      expirationDate: _parse(m['expirationDate']),
      lastValidatedAt: _parse(m['lastValidatedAt']),
      offlineGraceUntil: _parse(m['offlineGraceUntil']),
    );
  }

  DateTime? _parse(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  LicenseStatus _parseStatus(String? s) {
    switch (s) {
      case 'trial':
        return LicenseStatus.trial;
      case 'active':
        return LicenseStatus.active;
      case 'expired':
        return LicenseStatus.expired;
      default:
        return LicenseStatus.expired;
    }
  }

  /// Apply offline grace window to a license when network fails.
  License withOfflineGrace(License base) {
    final last = lastSuccessfulCheck() ?? base.lastValidatedAt ?? DateTime.now();
    final until = last.add(LicenseConstants.offlineGrace);
    return base.copyWith(offlineGraceUntil: until);
  }
}
