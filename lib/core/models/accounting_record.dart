class AccountingRecord {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String? note;
  final String date;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  AccountingRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  AccountingRecord copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    String? date,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return AccountingRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory AccountingRecord.fromMap(Map<String, dynamic> map) {
    return AccountingRecord(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
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
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
