/// Server-side license status for a device.
enum LicenseStatus {
  trial,
  active,
  expired,
}

/// Cached + remote license snapshot used by the app.
class License {
  const License({
    required this.deviceId,
    required this.status,
    this.trialStart,
    this.trialEnd,
    this.expirationDate,
    this.lastValidatedAt,
    this.offlineGraceUntil,
  });

  final String deviceId;
  final LicenseStatus status;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? expirationDate;
  final DateTime? lastValidatedAt;
  final DateTime? offlineGraceUntil;

  bool get allowsPlayback {
    final now = DateTime.now();
    // Short offline window after last successful server validation (connectivity loss).
    if (offlineGraceUntil != null && now.isBefore(offlineGraceUntil!)) {
      return true;
    }
    switch (status) {
      case LicenseStatus.active:
        if (expirationDate != null && now.isAfter(expirationDate!)) {
          return false;
        }
        return true;
      case LicenseStatus.trial:
        if (trialEnd != null && now.isAfter(trialEnd!)) {
          return false;
        }
        return true;
      case LicenseStatus.expired:
        return false;
    }
  }

  Duration? get trialRemaining {
    if (status != LicenseStatus.trial || trialEnd == null) return null;
    final rem = trialEnd!.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }

  License copyWith({
    String? deviceId,
    LicenseStatus? status,
    DateTime? trialStart,
    DateTime? trialEnd,
    DateTime? expirationDate,
    DateTime? lastValidatedAt,
    DateTime? offlineGraceUntil,
    bool clearOfflineGrace = false,
  }) {
    return License(
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      expirationDate: expirationDate ?? this.expirationDate,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      offlineGraceUntil:
          clearOfflineGrace ? null : (offlineGraceUntil ?? this.offlineGraceUntil),
    );
  }
}
