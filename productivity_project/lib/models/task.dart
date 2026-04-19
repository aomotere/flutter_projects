import 'package:hive/hive.dart';

class Task extends HiveObject {
  String title;
  String description;
  String workflow;
  String status;

  Task({
    required this.title,
    required this.description,
    required this.workflow,
    required this.status,
  });
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Task(
      title: fields[0] as String,
      description: fields[1] as String,
      workflow: fields[2] as String,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.workflow)
      ..writeByte(3)
      ..write(obj.status);
  }
}
