class FitnessBody {
  final String id;
  final String date;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hip;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  FitnessBody({
    required this.id,
    required this.date,
    this.weight,
    this.chest,
    this.waist,
    this.hip,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  FitnessBody copyWith({
    String? id,
    String? date,
    double? weight,
    double? chest,
    double? waist,
    double? hip,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return FitnessBody(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory FitnessBody.fromMap(Map<String, dynamic> map) {
    return FitnessBody(
      id: map['id'] as String,
      date: map['date'] as String,
      weight: map['weight'] == null ? null : (map['weight'] as num).toDouble(),
      chest: map['chest'] == null ? null : (map['chest'] as num).toDouble(),
      waist: map['waist'] == null ? null : (map['waist'] as num).toDouble(),
      hip: map['hip'] == null ? null : (map['hip'] as num).toDouble(),
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
