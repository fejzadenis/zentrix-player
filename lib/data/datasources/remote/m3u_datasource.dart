import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/m3u_parser.dart';
import '../../models/channel_model.dart';

class M3uDatasource {
  final Dio _dio;

  M3uDatasource(this._dio);

  Future<List<ChannelModel>> fetchFromUrl(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      ),
    );

    final content = response.data;
    if (content == null || content.isEmpty) {
      throw Exception('Empty playlist received');
    }

    return M3uParser.parseInIsolate(content);
  }

  Future<List<ChannelModel>> parseFromContent(String content) async {
    if (content.isEmpty) {
      throw Exception('Empty playlist content');
    }
    return M3uParser.parseInIsolate(content);
  }
}
