class ShootingIdea {
  final String id;
  final String content;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  ShootingIdea({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  ShootingIdea copyWith({
    String? id,
    String? content,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return ShootingIdea(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory ShootingIdea.fromMap(Map<String, dynamic> map) {
    return ShootingIdea(
      id: map['id'] as String,
      content: map['content'] as String,
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
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
