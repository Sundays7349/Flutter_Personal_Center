class MemoShopping {
  final String id;
  final String name;
  final bool done;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  MemoShopping({
    required this.id,
    required this.name,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  MemoShopping copyWith({
    String? id,
    String? name,
    bool? done,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return MemoShopping(
      id: id ?? this.id,
      name: name ?? this.name,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory MemoShopping.fromMap(Map<String, dynamic> map) {
    return MemoShopping(
      id: map['id'] as String,
      name: map['name'] as String,
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
      'name': name,
      'done': done ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
