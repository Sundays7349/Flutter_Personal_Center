class MemoContact {
  final String id;
  final String name;
  final String? phone;
  final String? account;
  final String? password;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  MemoContact({
    required this.id,
    required this.name,
    this.phone,
    this.account,
    this.password,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  MemoContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? account,
    String? password,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return MemoContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      account: account ?? this.account,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory MemoContact.fromMap(Map<String, dynamic> map) {
    return MemoContact(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      account: map['account'] as String?,
      password: map['password'] as String?,
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
      'phone': phone,
      'account': account,
      'password': password,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
