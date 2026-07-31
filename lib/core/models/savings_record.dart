class SavingsRecord {
  final String id;
  final double amount;
  final String date;
  final String? note;
  final String? subgoalId;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  SavingsRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.subgoalId,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  SavingsRecord copyWith({
    String? id,
    double? amount,
    String? date,
    String? note,
    String? subgoalId,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return SavingsRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      subgoalId: subgoalId ?? this.subgoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory SavingsRecord.fromMap(Map<String, dynamic> map) {
    return SavingsRecord(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      note: map['note'] as String?,
      subgoalId: map['subgoal_id'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'note': note,
      'subgoal_id': subgoalId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
