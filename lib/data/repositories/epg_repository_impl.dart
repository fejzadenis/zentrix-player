import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/epg_parser.dart';
import '../../domain/entities/epg_program.dart';
import '../../domain/repositories/epg_repository.dart';

class EpgRepositoryImpl implements EpgRepository {
  final Dio _dio;
  Map<String, List<EpgProgram>> _cache = {};

  EpgRepositoryImpl(this._dio);

  @override
  Future<Map<String, List<EpgProgram>>> loadEpg(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 120),
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    final content = response.data;
    if (content == null || content.isEmpty) {
      return {};
    }

    final parsed = await EpgParser.parseInIsolate(content);

    _cache = parsed.map(
      (key, models) => MapEntry(
        key,
        models.map((m) => m.toEntity()).toList(),
      ),
    );

    return _cache;
  }

  @override
  Future<List<EpgProgram>> getEpgForChannel(String channelId) async {
    return _cache[channelId] ?? [];
  }

  @override
  Future<EpgProgram?> getCurrentProgram(String channelId) async {
    final programs = _cache[channelId];
    if (programs == null) return null;

    final now = DateTime.now();
    try {
      return programs.firstWhere(
        (p) => now.isAfter(p.startTime) && now.isBefore(p.endTime),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EpgProgram>> getUpcomingPrograms(
    String channelId, {
    int limit = 10,
  }) async {
    final programs = _cache[channelId];
    if (programs == null) return [];

    final now = DateTime.now();
    final upcoming =
        programs.where((p) => p.endTime.isAfter(now)).take(limit).toList();
    return upcoming;
  }

  @override
  Future<void> cacheEpg(Map<String, List<EpgProgram>> epgData) async {
    _cache = epgData;
  }
}
