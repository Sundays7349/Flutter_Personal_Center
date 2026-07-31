class StudyEnglish {
  final String id;
  final String date;
  final int words;
  final int minutes;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  StudyEnglish({
    required this.id,
    required this.date,
    required this.words,
    required this.minutes,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  StudyEnglish copyWith({
    String? id,
    String? date,
    int? words,
    int? minutes,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return StudyEnglish(
      id: id ?? this.id,
      date: date ?? this.date,
      words: words ?? this.words,
      minutes: minutes ?? this.minutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory StudyEnglish.fromMap(Map<String, dynamic> map) {
    return StudyEnglish(
      id: map['id'] as String,
      date: map['date'] as String,
      words: map['words'] as int,
      minutes: map['minutes'] as int,
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
      'words': words,
      'minutes': minutes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
