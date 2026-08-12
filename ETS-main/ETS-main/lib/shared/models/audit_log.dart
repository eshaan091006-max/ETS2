import 'dart:convert';

List<AuditLog> auditLogFromJson(String str) =>
    List<AuditLog>.from(
      json.decode(str).map((x) => AuditLog.fromJson(x)),
    );

String auditLogToJson(List<AuditLog> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AuditLog {
  int id;
  String tableName;
  String action;
  String recordId;
  Map<String, dynamic>? oldData;
  Map<String, dynamic>? newData;
  String changedBy;
  DateTime createdAt;

  AuditLog({
    required this.id,
    required this.tableName,
    required this.action,
    required this.recordId,
    this.oldData,
    this.newData,
    required this.changedBy,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      tableName: json['table_name'],
      action: json['action'],
      recordId: json['record_id'],
      oldData: json['old_data'] != null ? Map<String, dynamic>.from(json['old_data']) : null,
      newData: json['new_data'] != null ? Map<String, dynamic>.from(json['new_data']) : null,
      changedBy: json['changed_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "table_name": tableName,
    "action": action,
    "record_id": recordId,
    "old_data": oldData,
    "new_data": newData,
    "changed_by": changedBy,
    "created_at": createdAt.toIso8601String(),
  };
}
