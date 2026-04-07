import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/license_constants.dart';
import '../../data/datasources/local/license_local_datasource.dart';
import '../../data/datasources/local/secure_device_storage.dart';
import '../../data/datasources/remote/license_remote_datasource.dart';
import '../../data/services/device_service.dart';
import '../../data/services/license_service.dart';
import '../../domain/entities/license.dart';

final secureDeviceStorageProvider = Provider<SecureDeviceStorage>((ref) {
  return SecureDeviceStorage();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.watch(secureDeviceStorageProvider));
});

final licenseLocalDatasourceProvider = Provider<LicenseLocalDatasource>((ref) {
  return LicenseLocalDatasource();
});

final licenseRemoteDatasourceProvider = Provider<LicenseRemoteDatasource?>((ref) {
  if (LicenseConstants.apiBaseUrl.trim().isEmpty) return null;
  return LicenseRemoteDatasource();
});

final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService(
    deviceService: ref.watch(deviceServiceProvider),
    secureStorage: ref.watch(secureDeviceStorageProvider),
    local: ref.watch(licenseLocalDatasourceProvider),
    remote: ref.watch(licenseRemoteDatasourceProvider),
  );
});

class LicenseViewState {
  const LicenseViewState({
    this.license,
    this.isLoading = false,
    this.error,
  });

  final License? license;
  final bool isLoading;
  final String? error;

  bool get canPlay {
    if (license == null) return false;
    return license!.allowsPlayback;
  }
}

/// Holds licensing state; call [bootstrap] from splash and [refresh] before playback.
class LicenseNotifier extends StateNotifier<LicenseViewState> {
  LicenseNotifier(this._service) : super(const LicenseViewState());

  final LicenseService _service;

  bool get isLicensingConfigured => _service.isLicensingConfigured;

  Future<void> bootstrap() async {
    state = LicenseViewState(license: state.license, isLoading: true, error: null);
    try {
      final license = await _service.bootstrap();
      state = LicenseViewState(license: license, isLoading: false);
    } catch (e) {
      state = LicenseViewState(
        license: state.license,
        isLoading: false,
        error: '$e',
      );
    }
  }

  Future<void> refresh() async {
    state = LicenseViewState(license: state.license, isLoading: true, error: null);
    try {
      final license = await _service.refresh();
      state = LicenseViewState(license: license, isLoading: false);
    } catch (e) {
      state = LicenseViewState(
        license: state.license,
        isLoading: false,
        error: '$e',
      );
    }
  }

  /// Returns true if playback is allowed after a network refresh when possible.
  Future<bool> ensurePlaybackAllowed() async {
    if (!_service.isLicensingConfigured) {
      return true;
    }
    await refresh();
    return state.canPlay;
  }

  Future<void> activate(String code) async {
    state = LicenseViewState(license: state.license, isLoading: true, error: null);
    try {
      final license = await _service.activate(code);
      state = LicenseViewState(license: license, isLoading: false);
    } catch (e) {
      state = LicenseViewState(
        license: state.license,
        isLoading: false,
        error: '$e',
      );
      rethrow;
    }
  }

  String? get trialCountdownLabel {
    final l = state.license;
    if (l == null || l.status != LicenseStatus.trial) return null;
    final rem = l.trialRemaining;
    if (rem == null) return null;
    final d = rem.inDays;
    final h = rem.inHours.remainder(24);
    final m = rem.inMinutes.remainder(60);
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

final licenseProvider =
    StateNotifierProvider<LicenseNotifier, LicenseViewState>((ref) {
  return LicenseNotifier(ref.watch(licenseServiceProvider));
});
