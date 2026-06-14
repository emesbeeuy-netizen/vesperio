import 'package:hive/hive.dart';
import 'sleep_session.dart';

class SleepSessionAdapter extends TypeAdapter<SleepSession> {
  @override
  final int typeId = 1;

  @override
  SleepSession read(BinaryReader reader) {
    final id = reader.readString();
    final startIso = reader.readString();
    final hasEnd = reader.readBool();
    final endIso = hasEnd ? reader.readString() : null;
    final soundIds = reader.readList().cast<String>();
    final soundVolumes = reader.readList().cast<double>();
    final timerDuration = reader.readBool() ? reader.readInt() : null;
    final isActive = reader.readBool();
    final totalMinutesListened = reader.readInt();
    final hasNotes = reader.readBool();
    final notes = hasNotes ? reader.readString() : null;

    return SleepSession(
      id: id,
      startTime: DateTime.parse(startIso),
      endTime: endIso != null ? DateTime.parse(endIso) : null,
      soundIds: soundIds,
      soundVolumes: soundVolumes,
      timerDuration: timerDuration,
      isActive: isActive,
      totalMinutesListened: totalMinutesListened,
      notes: notes,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSession obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.startTime.toIso8601String());
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) writer.writeString(obj.endTime!.toIso8601String());
    writer.writeList(obj.soundIds);
    writer.writeList(obj.soundVolumes);
    writer.writeBool(obj.timerDuration != null);
    if (obj.timerDuration != null) writer.writeInt(obj.timerDuration!);
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.totalMinutesListened);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
  }
}
