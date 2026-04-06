import '../entities/epg_program.dart';

abstract class EpgRepository {
  Future<Map<String, List<EpgProgram>>> loadEpg(String url);
  Future<List<EpgProgram>> getEpgForChannel(String channelId);
  Future<EpgProgram?> getCurrentProgram(String channelId);
  Future<List<EpgProgram>> getUpcomingPrograms(String channelId, {int limit = 10});
  Future<void> cacheEpg(Map<String, List<EpgProgram>> epgData);
}
