import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/epg_repository_impl.dart';
import '../../domain/entities/epg_program.dart';
import '../../domain/repositories/epg_repository.dart';
import 'playlist_provider.dart';

final epgRepositoryProvider = Provider<EpgRepository>((ref) {
  return EpgRepositoryImpl(ref.watch(dioProvider));
});

class EpgState {
  final Map<String, List<EpgProgram>> programsByChannel;
  final bool isLoading;
  final String? error;

  const EpgState({
    this.programsByChannel = const {},
    this.isLoading = false,
    this.error,
  });

  EpgState copyWith({
    Map<String, List<EpgProgram>>? programsByChannel,
    bool? isLoading,
    String? error,
  }) {
    return EpgState(
      programsByChannel: programsByChannel ?? this.programsByChannel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EpgNotifier extends StateNotifier<EpgState> {
  final EpgRepository _repository;

  EpgNotifier(this._repository) : super(const EpgState());

  Future<void> loadEpg(String url) async {
    if (url.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.loadEpg(url);
      state = state.copyWith(programsByChannel: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  EpgProgram? getCurrentProgram(String channelId) {
    final programs = state.programsByChannel[channelId];
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

  List<EpgProgram> getUpcomingPrograms(String channelId, {int limit = 10}) {
    final programs = state.programsByChannel[channelId];
    if (programs == null) return [];

    final now = DateTime.now();
    return programs.where((p) => p.endTime.isAfter(now)).take(limit).toList();
  }
}

final epgProvider = StateNotifierProvider<EpgNotifier, EpgState>((ref) {
  return EpgNotifier(ref.watch(epgRepositoryProvider));
});
