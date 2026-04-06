import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/channel_model.dart';
import '../../models/category_model.dart';

class XtreamDatasource {
  final Dio _dio;

  XtreamDatasource(this._dio);

  Future<Map<String, dynamic>> authenticate({
    required String server,
    required String username,
    required String password,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.xtreamPlayerApi(server),
      queryParameters: {
        'username': username,
        'password': password,
      },
      options: Options(
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    final data = response.data;
    if (data == null) throw Exception('Authentication failed');

    final userInfo = data['user_info'] as Map<String, dynamic>?;
    if (userInfo == null) throw Exception('Invalid server response');

    final auth = userInfo['auth'] as int?;
    if (auth != 1) throw Exception('Invalid credentials');

    return data;
  }

  Future<List<ChannelModel>> getLiveStreams({
    required String server,
    required String username,
    required String password,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.xtreamPlayerApi(server),
      queryParameters: {
        'username': username,
        'password': password,
        'action': ApiConstants.actionGetLiveStreams,
      },
      options: Options(
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    final data = response.data;
    if (data == null) return [];

    return data.map((json) {
      final channel = ChannelModel.fromXtreamJson(json as Map<String, dynamic>);
      channel.streamUrl = ApiConstants.xtreamStreamUrl(
        server,
        username,
        password,
        channel.id,
      );
      return channel;
    }).toList();
  }

  Future<List<CategoryModel>> getLiveCategories({
    required String server,
    required String username,
    required String password,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.xtreamPlayerApi(server),
      queryParameters: {
        'username': username,
        'password': password,
        'action': ApiConstants.actionGetLiveCategories,
      },
      options: Options(
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    final data = response.data;
    if (data == null) return [];

    return data
        .map((json) =>
            CategoryModel.fromXtreamJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> getEpgXml({
    required String server,
    required String username,
    required String password,
  }) async {
    final response = await _dio.get<String>(
      ApiConstants.xtreamEpgUrl(server, username, password),
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 60),
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    return response.data ?? '';
  }
}
