class Todo {
  final String id;
  final String text;
  final bool done;
  final String date;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  Todo copyWith({
    String? id,
    String? text,
    bool? done,
    String? date,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      text: map['text'] as String,
      done: (map['done'] as int) == 1,
      date: map['date'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'done': done ? 1 : 0,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
