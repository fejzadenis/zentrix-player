import 'package:dio/dio.dart';

import '../../core/constants/license_constants.dart';
import '../../domain/entities/license.dart';
import '../datasources/local/license_local_datasource.dart';
import '../datasources/local/secure_device_storage.dart';
import '../datasources/remote/license_remote_datasource.dart';
import 'device_service.dart';

/// Orchestrates device registration, remote validation, and offline cache.
class LicenseService {
  LicenseService({
    required DeviceService deviceService,
    required SecureDeviceStorage secureStorage,
    required LicenseLocalDatasource local,
    LicenseRemoteDatasource? remote,
  })  : _deviceService = deviceService,
        _secure = secureStorage,
        _local = local,
        _remote = remote;

  final DeviceService _deviceService;
  final SecureDeviceStorage _secure;
  final LicenseLocalDatasource _local;
  final LicenseRemoteDatasource? _remote;

  bool get isLicensingConfigured =>
      LicenseConstants.apiBaseUrl.trim().isNotEmpty;

  LicenseRemoteDatasource _client() {
    final r = _remote;
    if (r != null) return r;
    return LicenseRemoteDatasource();
  }

  /// Splash: ensure device id, register if needed, validate with server or cache.
  Future<License> bootstrap() async {
    if (!isLicensingConfigured) {
      final id = await _deviceService.getOrCreateDeviceId();
      return License(
        deviceId: id,
        status: LicenseStatus.active,
        lastValidatedAt: DateTime.now(),
      );
    }

    final deviceId = await _deviceService.getOrCreateDeviceId();
    final remote = _client();

    try {
      var token = await _secure.readLicenseToken();

      if (token == null || token.isEmpty) {
        final reg = await remote.registerDevice(deviceId: deviceId);
        token = reg.token;
        if (token.isNotEmpty) {
          await _secure.writeLicenseToken(token);
        }
        final license =
            reg.license.copyWith(deviceId: deviceId, clearOfflineGrace: true);
        await _local.writeCached(license);
        return license;
      }

      final fresh = await remote.checkLicense(deviceId: deviceId, token: token);
      final merged =
          fresh.copyWith(deviceId: deviceId, clearOfflineGrace: true);
      await _local.writeCached(merged);
      return merged;
    } on DioException catch (_) {
      return _recoverFromOffline(deviceId);
    } catch (_) {
      return _recoverFromOffline(deviceId);
    }
  }

  /// Refresh license from network; falls back to offline grace.
  Future<License> refresh() async {
    if (!isLicensingConfigured) {
      final id = await _deviceService.getOrCreateDeviceId();
      return License(
        deviceId: id,
        status: LicenseStatus.active,
        lastValidatedAt: DateTime.now(),
      );
    }

    final deviceId = await _deviceService.getOrCreateDeviceId();
    final token = await _secure.readLicenseToken();
    final remote = _client();

    if (token == null || token.isEmpty) {
      return bootstrap();
    }

    try {
      final fresh =
          await remote.checkLicense(deviceId: deviceId, token: token);
      final merged =
          fresh.copyWith(deviceId: deviceId, clearOfflineGrace: true);
      await _local.writeCached(merged);
      return merged;
    } on DioException catch (_) {
      return _recoverFromOffline(deviceId);
    } catch (_) {
      return _recoverFromOffline(deviceId);
    }
  }

  Future<License> activate(String activationCode) async {
    if (!isLicensingConfigured) {
      throw StateError('Licensing not configured');
    }
    final deviceId = await _deviceService.getOrCreateDeviceId();
    final token = await _secure.readLicenseToken();
    if (token == null || token.isEmpty) {
      await bootstrap();
    }
    final t = await _secure.readLicenseToken();
    if (t == null || t.isEmpty) {
      throw StateError('No license token');
    }
    final remote = _client();
    final license = await remote.activateDevice(
      deviceId: deviceId,
      token: t,
      activationCode: activationCode.trim(),
    );
    final merged =
        license.copyWith(deviceId: deviceId, clearOfflineGrace: true);
    await _local.writeCached(merged);
    return merged;
  }

  License _recoverFromOffline(String deviceId) {
    final cached = _local.readCached();
    if (cached == null) {
      return License(
        deviceId: deviceId,
        status: LicenseStatus.expired,
        lastValidatedAt: _local.lastSuccessfulCheck(),
      );
    }
    final withGrace = _local.withOfflineGrace(cached.copyWith(deviceId: deviceId));
    return withGrace;
  }
}
