import 'package:hive/hive.dart';
import '../../domain/entities/channel.dart';

class ChannelModel extends HiveObject {
  String id;
  String name;
  String logoUrl;
  String streamUrl;
  String category;
  String tvgId;
  bool isLive;
  int contentTypeIndex; // 0=live, 1=movie, 2=series

  ChannelModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    required this.streamUrl,
    this.category = 'Uncategorized',
    this.tvgId = '',
    this.isLive = true,
    this.contentTypeIndex = 0,
  });

  ContentType get contentType => ContentType.values[contentTypeIndex.clamp(0, 2)];

  Channel toEntity({bool isFavorite = false}) {
    return Channel(
      id: id,
      name: name,
      logoUrl: logoUrl,
      streamUrl: streamUrl,
      category: category,
      tvgId: tvgId,
      isLive: isLive,
      isFavorite: isFavorite,
      contentType: contentType,
    );
  }

  factory ChannelModel.fromEntity(Channel channel) {
    return ChannelModel(
      id: channel.id,
      name: channel.name,
      logoUrl: channel.logoUrl,
      streamUrl: channel.streamUrl,
      category: channel.category,
      tvgId: channel.tvgId,
      isLive: channel.isLive,
      contentTypeIndex: channel.contentType.index,
    );
  }

  factory ChannelModel.fromXtreamJson(
    Map<String, dynamic> json, {
    ContentType type = ContentType.live,
  }) {
    return ChannelModel(
      id: json['stream_id']?.toString() ?? json['series_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      logoUrl: json['stream_icon']?.toString() ?? json['cover']?.toString() ?? '',
      streamUrl: '',
      category: json['category_id']?.toString() ?? 'Uncategorized',
      tvgId: json['epg_channel_id']?.toString() ?? '',
      isLive: type == ContentType.live,
      contentTypeIndex: type.index,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'streamUrl': streamUrl,
    'category': category,
    'tvgId': tvgId,
    'isLive': isLive,
    'contentTypeIndex': contentTypeIndex,
  };
}

class ChannelModelAdapter extends TypeAdapter<ChannelModel> {
  @override
  final int typeId = 0;

  @override
  ChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ChannelModel(
      id: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      logoUrl: fields[2] as String? ?? '',
      streamUrl: fields[3] as String? ?? '',
      category: fields[4] as String? ?? 'Uncategorized',
      tvgId: fields[5] as String? ?? '',
      isLive: fields[6] as bool? ?? true,
      contentTypeIndex: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelModel obj) {
    writer.writeByte(8);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.logoUrl);
    writer.writeByte(3); writer.write(obj.streamUrl);
    writer.writeByte(4); writer.write(obj.category);
    writer.writeByte(5); writer.write(obj.tvgId);
    writer.writeByte(6); writer.write(obj.isLive);
    writer.writeByte(7); writer.write(obj.contentTypeIndex);
  }
}
