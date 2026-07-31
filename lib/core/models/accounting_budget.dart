class AccountingBudget {
  final int? id;
  final double monthly;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  AccountingBudget({
    this.id,
    required this.monthly,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  AccountingBudget copyWith({
    int? id,
    double? monthly,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return AccountingBudget(
      id: id ?? this.id,
      monthly: monthly ?? this.monthly,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory AccountingBudget.fromMap(Map<String, dynamic> map) {
    return AccountingBudget(
      id: map['id'] as int?,
      monthly: (map['monthly'] as num).toDouble(),
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthly': monthly,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
