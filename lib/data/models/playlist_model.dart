import 'package:hive/hive.dart';
import '../../domain/entities/playlist.dart';

class PlaylistModel extends HiveObject {
  String id;
  String name;
  int typeIndex; // PlaylistType.index
  String url;
  String username;
  String password;
  String serverUrl;
  DateTime addedAt;
  DateTime? lastUpdated;
  int channelCount;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.typeIndex,
    this.url = '',
    this.username = '',
    this.password = '',
    this.serverUrl = '',
    required this.addedAt,
    this.lastUpdated,
    this.channelCount = 0,
  });

  Playlist toEntity() {
    return Playlist(
      id: id,
      name: name,
      type: PlaylistType.values[typeIndex],
      url: url,
      username: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      serverUrl: serverUrl.isEmpty ? null : serverUrl,
      addedAt: addedAt,
      lastUpdated: lastUpdated,
      channelCount: channelCount,
    );
  }

  factory PlaylistModel.fromEntity(Playlist playlist) {
    return PlaylistModel(
      id: playlist.id,
      name: playlist.name,
      typeIndex: playlist.type.index,
      url: playlist.url,
      username: playlist.username ?? '',
      password: playlist.password ?? '',
      serverUrl: playlist.serverUrl ?? '',
      addedAt: playlist.addedAt,
      lastUpdated: playlist.lastUpdated,
      channelCount: playlist.channelCount,
    );
  }
}

class PlaylistModelAdapter extends TypeAdapter<PlaylistModel> {
  @override
  final int typeId = 1;

  @override
  PlaylistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return PlaylistModel(
      id: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      typeIndex: fields[2] as int? ?? 0,
      url: fields[3] as String? ?? '',
      username: fields[4] as String? ?? '',
      password: fields[5] as String? ?? '',
      serverUrl: fields[6] as String? ?? '',
      addedAt: fields[7] as DateTime? ?? DateTime.now(),
      lastUpdated: fields[8] as DateTime?,
      channelCount: fields[9] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistModel obj) {
    writer.writeByte(10);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.typeIndex);
    writer.writeByte(3); writer.write(obj.url);
    writer.writeByte(4); writer.write(obj.username);
    writer.writeByte(5); writer.write(obj.password);
    writer.writeByte(6); writer.write(obj.serverUrl);
    writer.writeByte(7); writer.write(obj.addedAt);
    writer.writeByte(8); writer.write(obj.lastUpdated);
    writer.writeByte(9); writer.write(obj.channelCount);
  }
}
