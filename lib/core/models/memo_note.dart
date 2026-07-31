class MemoNote {
  final String id;
  final String content;
  final bool done;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  MemoNote({
    required this.id,
    required this.content,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  MemoNote copyWith({
    String? id,
    String? content,
    bool? done,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return MemoNote(
      id: id ?? this.id,
      content: content ?? this.content,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory MemoNote.fromMap(Map<String, dynamic> map) {
    return MemoNote(
      id: map['id'] as String,
      content: map['content'] as String,
      done: (map['done'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'done': done ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
