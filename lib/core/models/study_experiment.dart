class StudyExperiment {
  final String id;
  final String name;
  final String? date;
  final String status;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  StudyExperiment({
    required this.id,
    required this.name,
    this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  StudyExperiment copyWith({
    String? id,
    String? name,
    String? date,
    String? status,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return StudyExperiment(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory StudyExperiment.fromMap(Map<String, dynamic> map) {
    return StudyExperiment(
      id: map['id'] as String,
      name: map['name'] as String,
      date: map['date'] as String?,
      status: map['status'] as String,
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
      'date': date,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
