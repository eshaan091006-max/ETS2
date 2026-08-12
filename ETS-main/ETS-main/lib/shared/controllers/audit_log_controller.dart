import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/audit_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogController {
  // Singleton instance
  static final AuditLogController _instance = AuditLogController._internal();

  factory AuditLogController() {
    return _instance;
  }

  AuditLogController._internal();

  final List<AuditLog> _auditLogs = [];

  List<AuditLog> get auditLogs => _auditLogs;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadAuditLogs() async {
    try {
      _errorMessage = null;
      final response = await Supabase.instance.client
          .from('audit_logs')
          .select("*")
          .order('created_at', ascending: false);

      _auditLogs.clear();
      if (response.isNotEmpty) {
        _auditLogs.addAll(
          response.map((json) => AuditLog.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      final currentSession = Supabase.instance.client.auth.currentSession;
      final role = currentSession?.user.role;
      _errorMessage = "$e\n(Session: ${currentSession != null ? 'Active' : 'Null'}, Role: $role)";
      print("Error loading audit logs: $e");
    } finally {
      PageRefreshController.triggerRefresh();
    }
  }
}
