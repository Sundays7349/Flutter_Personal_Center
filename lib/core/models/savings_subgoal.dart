class SavingsSubgoal {
  final String id;
  final String name;
  final double target;
  final double current;
  final bool completed;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  SavingsSubgoal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  SavingsSubgoal copyWith({
    String? id,
    String? name,
    double? target,
    double? current,
    bool? completed,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return SavingsSubgoal(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      current: current ?? this.current,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory SavingsSubgoal.fromMap(Map<String, dynamic> map) {
    return SavingsSubgoal(
      id: map['id'] as String,
      name: map['name'] as String,
      target: (map['target'] as num).toDouble(),
      current: (map['current'] as num).toDouble(),
      completed: ((map['completed'] as int?) ?? 0) == 1,
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
      'target': target,
      'current': current,
      'completed': completed ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
