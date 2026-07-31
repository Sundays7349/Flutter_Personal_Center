class ShootingProject {
  final String id;
  final String name;
  final String? shootDate;
  final double price;
  final double cost;
  final String? participants;
  final bool done;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  ShootingProject({
    required this.id,
    required this.name,
    this.shootDate,
    required this.price,
    required this.cost,
    this.participants,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  ShootingProject copyWith({
    String? id,
    String? name,
    String? shootDate,
    double? price,
    double? cost,
    String? participants,
    bool? done,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return ShootingProject(
      id: id ?? this.id,
      name: name ?? this.name,
      shootDate: shootDate ?? this.shootDate,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      participants: participants ?? this.participants,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory ShootingProject.fromMap(Map<String, dynamic> map) {
    return ShootingProject(
      id: map['id'] as String,
      name: map['name'] as String,
      shootDate: map['shoot_date'] as String?,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      participants: map['participants'] as String?,
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
      'shoot_date': shootDate,
      'price': price,
      'cost': cost,
      'participants': participants,
      'done': done ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
