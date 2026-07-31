class FitnessWorkout {
  final String id;
  final String type;
  final int duration;
  final String date;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  FitnessWorkout({
    required this.id,
    required this.type,
    required this.duration,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  FitnessWorkout copyWith({
    String? id,
    String? type,
    int? duration,
    String? date,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return FitnessWorkout(
      id: id ?? this.id,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory FitnessWorkout.fromMap(Map<String, dynamic> map) {
    return FitnessWorkout(
      id: map['id'] as String,
      type: map['type'] as String,
      duration: map['duration'] as int,
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
      'type': type,
      'duration': duration,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
