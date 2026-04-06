class ApiConstants {
  ApiConstants._();

  static String xtreamBaseUrl(String server) {
    final url =
        server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    return url.startsWith('http') ? url : 'http://$url';
  }

  static String xtreamPlayerApi(String server) =>
      '${xtreamBaseUrl(server)}/player_api.php';

  static String xtreamStreamUrl(
    String server,
    String username,
    String password,
    String streamId,
  ) =>
      '${xtreamBaseUrl(server)}/live/$username/$password/$streamId.m3u8';

  static String xtreamEpgUrl(
    String server,
    String username,
    String password,
  ) =>
      '${xtreamBaseUrl(server)}/xmltv.php?username=$username&password=$password';

  static const String actionGetLiveStreams = 'get_live_streams';
  static const String actionGetLiveCategories = 'get_live_categories';
  static const String actionGetShortEpg = 'get_short_epg';
  static const String actionGetSimpleDataTable = 'get_simple_datatable';
}
