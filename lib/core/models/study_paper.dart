class StudyPaper {
  final String id;
  final String title;
  final String? date;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  StudyPaper({
    required this.id,
    required this.title,
    this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  StudyPaper copyWith({
    String? id,
    String? title,
    String? date,
    String? note,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return StudyPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory StudyPaper.fromMap(Map<String, dynamic> map) {
    return StudyPaper(
      id: map['id'] as String,
      title: map['title'] as String,
      date: map['date'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
