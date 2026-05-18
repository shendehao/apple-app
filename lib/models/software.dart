class SoftwareModel {
  final int id;
  final String name;
  final String instanceId;
  final String version;
  final int accessCount;

  SoftwareModel({
    required this.id,
    required this.name,
    required this.instanceId,
    this.version = '',
    this.accessCount = 0,
  });

  factory SoftwareModel.fromJson(Map<String, dynamic> json) => SoftwareModel(
    id: json['id'],
    name: json['name'] ?? '',
    instanceId: json['instance_id'] ?? '',
    version: json['version'] ?? '',
    accessCount: json['access_count'] ?? 0,
  );
}
