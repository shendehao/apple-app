class CardModel {
  final int id;
  final String key;
  final String status;
  final String? hwid;
  final DateTime? createdAt;
  final DateTime? activatedAt;
  final DateTime? lastSeen;
  final String? firstIp;
  final String? lastIp;
  final DateTime? expireDate;
  final String durationUnit;
  final int? durationValue;
  final int unbindCount;
  final int? unbindLimit;
  final String? remarks;
  final int softwareId;
  final String? softwareName;

  CardModel({
    required this.id,
    required this.key,
    required this.status,
    this.hwid,
    this.createdAt,
    this.activatedAt,
    this.lastSeen,
    this.firstIp,
    this.lastIp,
    this.expireDate,
    this.durationUnit = 'permanent',
    this.durationValue,
    this.unbindCount = 0,
    this.unbindLimit,
    this.remarks,
    required this.softwareId,
    this.softwareName,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id: json['id'],
    key: json['key'] ?? '',
    status: json['status'] ?? 'unused',
    hwid: json['hwid'],
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    activatedAt: json['first_seen_at'] != null ? DateTime.tryParse(json['first_seen_at']) : null,
    lastSeen: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at']) : null,
    firstIp: json['first_ip'],
    lastIp: json['last_ip'],
    expireDate: json['expire_date'] != null ? DateTime.tryParse(json['expire_date']) : null,
    durationUnit: json['duration_unit'] ?? 'permanent',
    durationValue: json['duration_value'],
    unbindCount: json['unbind_count'] ?? 0,
    unbindLimit: json['unbind_limit'],
    remarks: json['remarks'],
    softwareId: json['software_id'] ?? 0,
    softwareName: json['software_name'],
  );

  String get statusLabel {
    switch (status) {
      case 'unused': return '未使用';
      case 'used': return '已使用';
      case 'expired': return '已过期';
      case 'banned': return '已封禁';
      default: return status;
    }
  }

  String get typeLabel {
    switch (durationUnit) {
      case 'hour': return '${durationValue ?? 0}小时卡';
      case 'day': return '${durationValue ?? 0}天卡';
      case 'permanent': return '永久卡';
      default: return durationUnit;
    }
  }
}
