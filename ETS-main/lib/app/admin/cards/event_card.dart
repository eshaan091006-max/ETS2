import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/form_link_card.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/app/admin/modals/form_link_modal.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/form_link.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateStr = "${event.dateString} • ${event.timeString}";
    final deptCont = DepartmentController();
    final deptName = deptCont.getDepartmentById(event.departmentId)?.name ?? '';
    List<FormLink> formLinks = FormLinkController().getFormLinksByEventId(
      event.eventId,
    );

    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Event Type Tag
            if (event.eventType == 0 || event.eventType == 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (event.eventType == 0
                          ? AppColors.primary
                          : AppColors.accent)
                      .withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.eventType == 0 ? "Classic Event" : "Flagship Event",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                        event.eventType == 0
                            ? AppColors.primary
                            : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            /// Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.eventName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.accent,
                  tooltip: 'Edit',
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: AppColors.error,
                  tooltip: 'Delete',
                  onPressed:
                      () => confirmDeletionModal(
                        context,
                        'Event',
                        onSubmit: widget.onDelete,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, thickness: 0.7),
            const SizedBox(height: 10),

            _buildDetailRow("Department", deptName),
            _buildDetailRow(
              "Highest Marks",
              event.highestMarks == -1
                  ? "Not Set"
                  : event.highestMarks.toString(),
            ),
            _buildDetailRow(
              "Format / Elims",
              event.elimsType == 0
                  ? "Direct Finals"
                  : event.elimsType == 1
                      ? "Online Elims + Offline Finals"
                      : "Offline Elims + Offline Finals",
            ),

            const SizedBox(height: 12),

            /// Form Links Section
            const Divider(height: 20),
            Row(
              children: [
                const Text(
                  "Form Links",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Add Form Link',
                  color: AppColors.primary,
                  onPressed: () {
                    dynamic addFormLink(FormLink fl) {
                      FormLinkController().createFormLink(context, fl);
                    }

                    showFormLinkModal(
                      context,
                      eventId: widget.event.eventId,
                      onSubmit: addFormLink,
                    );
                  },
                  icon: Icon(Icons.add, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (formLinks.isEmpty)
              Align(
                alignment: Alignment.center,
                child: Text(
                  "No Form Links Found .. Add to View them",
                  style: GoogleFonts.biryani(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

            for (var formLink in formLinks) FormLinkCard(formLink: formLink),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
