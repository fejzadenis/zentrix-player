import 'package:dio/dio.dart';

import '../../../core/constants/license_constants.dart';
import '../../../domain/entities/license.dart';

class LicenseRemoteDatasource {
  LicenseRemoteDatasource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: LicenseConstants.apiBaseUrl.endsWith('/')
                    ? LicenseConstants.apiBaseUrl
                    : '${LicenseConstants.apiBaseUrl}/',
                connectTimeout: LicenseConstants.connectTimeout,
                receiveTimeout: LicenseConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  if (LicenseConstants.appSecret.isNotEmpty)
                    'X-App-Secret': LicenseConstants.appSecret,
                },
              ),
            );

  final Dio _dio;

  Future<RegisterDeviceResult> registerDevice({
    required String deviceId,
    String? licenseToken,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'register-device',
      data: {'device_id': deviceId},
      options: Options(
        headers: {
          if (licenseToken != null && licenseToken.isNotEmpty)
            'Authorization': 'Bearer $licenseToken',
        },
      ),
    );
    final data = res.data ?? {};
    return RegisterDeviceResult(
      token: data['token'] as String? ?? '',
      license: _parseLicense(data, deviceId),
    );
  }

  Future<License> checkLicense({
    required String deviceId,
    required String token,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'check-license',
      data: {'device_id': deviceId},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return _parseLicense(res.data ?? {}, deviceId);
  }

  Future<License> activateDevice({
    required String deviceId,
    required String token,
    required String activationCode,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'activate-device',
      data: {
        'device_id': deviceId,
        'activation_code': activationCode,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return _parseLicense(res.data ?? {}, deviceId);
  }

  License _parseLicense(Map<String, dynamic> data, String deviceId) {
    final statusStr = data['status'] as String? ?? 'expired';
    final status = LicenseStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => LicenseStatus.expired,
    );
    return License(
      deviceId: deviceId,
      status: status,
      trialStart: _parseDate(data['trial_start'] ?? data['trialStart']),
      trialEnd: _parseDate(data['trial_end'] ?? data['trialEnd']),
      expirationDate:
          _parseDate(data['expiration_date'] ?? data['expirationDate']),
      lastValidatedAt: DateTime.now(),
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class RegisterDeviceResult {
  RegisterDeviceResult({required this.token, required this.license});

  final String token;
  final License license;
}
