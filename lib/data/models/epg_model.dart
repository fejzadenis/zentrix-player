import 'package:hive/hive.dart';
import '../../domain/entities/epg_program.dart';

class EpgProgramModel extends HiveObject {
  String channelId;
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  String category;
  String iconUrl;

  EpgProgramModel({
    required this.channelId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.category = '',
    this.iconUrl = '',
  });

  EpgProgram toEntity() {
    return EpgProgram(
      channelId: channelId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      category: category,
      iconUrl: iconUrl,
    );
  }

  factory EpgProgramModel.fromEntity(EpgProgram program) {
    return EpgProgramModel(
      channelId: program.channelId,
      title: program.title,
      description: program.description,
      startTime: program.startTime,
      endTime: program.endTime,
      category: program.category,
      iconUrl: program.iconUrl,
    );
  }
}

class EpgProgramModelAdapter extends TypeAdapter<EpgProgramModel> {
  @override
  final int typeId = 2;

  @override
  EpgProgramModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return EpgProgramModel(
      channelId: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      description: fields[2] as String? ?? '',
      startTime: fields[3] as DateTime? ?? DateTime.now(),
      endTime: fields[4] as DateTime? ?? DateTime.now(),
      category: fields[5] as String? ?? '',
      iconUrl: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, EpgProgramModel obj) {
    writer.writeByte(7);
    writer.writeByte(0); writer.write(obj.channelId);
    writer.writeByte(1); writer.write(obj.title);
    writer.writeByte(2); writer.write(obj.description);
    writer.writeByte(3); writer.write(obj.startTime);
    writer.writeByte(4); writer.write(obj.endTime);
    writer.writeByte(5); writer.write(obj.category);
    writer.writeByte(6); writer.write(obj.iconUrl);
  }
}
