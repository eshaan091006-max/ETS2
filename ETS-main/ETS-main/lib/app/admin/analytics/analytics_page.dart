import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/audit_log_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/audit_log.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/ambient_glow_background.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedActionFilter = 'ALL'; // Filter for Logs

  @override
  void initState() {
    super.initState();
    AuditLogController().loadAuditLogs();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        return AmbientGlowBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('Audit Logs', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.secondary,
              onRefresh: () async {
                await AuditLogController().loadAuditLogs();
                if (mounted) {
                  setState(() {});
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildAuditLogsView(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsView() {
    final controller = AuditLogController();
    final logs = controller.auditLogs;
    final error = controller.errorMessage;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Logs',
                style: GoogleFonts.montserrat(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => controller.loadAuditLogs(),
                child: Text('Retry', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'No Changes Recorded Yet',
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final filteredLogs = _selectedActionFilter == 'ALL' 
        ? logs 
        : logs.where((log) => log.action == _selectedActionFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL'),
              const SizedBox(width: 8),
              _buildFilterChip('INSERT'),
              const SizedBox(width: 8),
              _buildFilterChip('UPDATE'),
              const SizedBox(width: 8),
              _buildFilterChip('DELETE'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredLogs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  Text(
                    'No $_selectedActionFilter Logs Found',
                    style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              final timestamp = DateFormat('dd MMM, hh:mm a').format(log.createdAt.toLocal());
              final description = _formatLogDescription(log);

              Color actionColor;
              String actionText = log.action;
              if (log.action == 'INSERT') {
                actionColor = AppColors.success;
              } else if (log.action == 'UPDATE') {
                actionColor = AppColors.accent;
              } else if (log.action == 'DELETE') {
                actionColor = AppColors.error;
              } else {
                actionColor = AppColors.primary;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(10),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: actionColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: actionColor.withAlpha(120), width: 1),
                          ),
                          child: Text(
                            actionText,
                            style: GoogleFonts.montserrat(
                              color: actionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          timestamp,
                          style: GoogleFonts.montserrat(
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          'By: ${log.changedBy}',
                          style: GoogleFonts.montserrat(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String action) {
    final isSelected = _selectedActionFilter == action;
    return ChoiceChip(
      label: Text(
        action,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isSelected ? AppColors.black : AppColors.textWhite,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedActionFilter = action;
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.black.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.white24,
        ),
      ),
    );
  }

  String _formatLogDescription(AuditLog log) {
    final Map<String, dynamic> data = log.newData ?? log.oldData ?? {};
    
    if (log.tableName == 'contingents') {
      final contingentCode = data['contingent_code'] ?? log.oldData?['contingent_code'] ?? 'Contingent #${log.recordId}';
      if (log.action == 'INSERT') {
        return 'Contingent $contingentCode was added';
      } else if (log.action == 'UPDATE') {
        return 'Contingent $contingentCode was updated';
      } else if (log.action == 'DELETE') {
        final code = log.oldData?['contingent_code'] ?? 'Contingent #${log.recordId}';
        return 'Contingent $code was deleted';
      }
      return 'Action ${log.action} on contingent $contingentCode';
    }

    final int? contingentId = data['contingent_id'];
    final int? eventId = data['event_id'];

    String? contingentCode = data['contingent_code'] ?? log.oldData?['contingent_code'];
    if (contingentCode == null) {
      contingentCode = contingentId != null
          ? (ContingentController().getContingentById(contingentId)?.contingentCode ?? 'Contingent #$contingentId')
          : 'Unknown Contingent';
    }

    String? eventName = data['event_name'] ?? log.oldData?['event_name'];
    if (eventName == null) {
      eventName = eventId != null
          ? (EventController().getEventById(eventId)?.eventName ?? 'Event #$eventId')
          : 'Unknown Event';
    }

    if (log.action == 'INSERT') {
      final rawMarks = data['marks_scored'] ?? 0;
      final marks = rawMarks == -1 ? 0 : rawMarks;
      return '$contingentCode registered for $eventName with score $marks';
    } else if (log.action == 'UPDATE') {
      final rawOldMarks = log.oldData?['marks_scored'] ?? -1;
      final rawNewMarks = log.newData?['marks_scored'] ?? -1;
      final oldMarks = rawOldMarks == -1 ? 0 : rawOldMarks;
      final newMarks = rawNewMarks == -1 ? 0 : rawNewMarks;
      if (oldMarks != newMarks) {
        return '$contingentCode score in $eventName changed from $oldMarks to $newMarks';
      }
      return '$contingentCode entry in $eventName updated';
    } else if (log.action == 'DELETE') {
      return '$contingentCode participation in $eventName was deleted';
    }
    return 'Action ${log.action} on participation #${log.recordId}';
  }
}

