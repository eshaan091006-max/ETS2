import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/cards/contingent_card.dart';
import 'package:malhar_ets/app/admin/cards/event_card.dart';
import 'package:malhar_ets/app/admin/contingent/events_participated_page.dart';
import 'package:malhar_ets/app/admin/modals/contingent_modal.dart';
import 'package:malhar_ets/app/admin/modals/event_modal.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/helpers/page_transitions.dart';

class ParticipationCard extends StatefulWidget {
  final Participation participation;
  final Event event;
  final Contingent contingent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ParticipationCard({
    super.key,
    required this.participation,
    required this.event,
    required this.contingent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ParticipationCard> createState() => _ParticipationCardState();
}

class _ParticipationCardState extends State<ParticipationCard> {
  bool _eventExpanded = false;
  bool _contingentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String marks =
        widget.participation.marksScored == -1
            ? "-"
            : widget.participation.marksScored.toString();
    final String highest =
        widget.event.highestMarks == -1
            ? "-"
            : widget.event.highestMarks.toString();

    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Row(
              children: [
                _buildMetric("Marks", marks, AppColors.accent),
                const SizedBox(width: 12),
                _buildMetric("Highest", highest, AppColors.warning),
                const Spacer(),
                _iconButton(Icons.edit, AppColors.accent, widget.onEdit),
                _iconButton(Icons.delete, AppColors.error, widget.onDelete),
              ],
            ),

            const SizedBox(height: 20),

            /// Event Section
            _buildExpandableTile(
              title: "Event",
              subtitle: widget.event.eventName,
              isExpanded: _eventExpanded,
              onToggle: () => setState(() => _eventExpanded = !_eventExpanded),
              tileColor: AppColors.primary.withAlpha(25),
              child: EventCard(
                event: widget.event,
                onEdit:
                    () => showEventModal(
                      context,
                      event: widget.event,
                      onSubmit: (event, links) async {
                        await EventController().updateEvent(context, event);
                        await FormLinkController().syncFormLinks(context, event.eventId, links);
                      },
                    ),
                onDelete: () {
                  // Delete logic
                },
              ),
            ),

            const SizedBox(height: 12),

            /// Contingent Section
            _buildExpandableTile(
              title: "Contingent",
              subtitle: widget.contingent.contingentCode,
              isExpanded: _contingentExpanded,
              onToggle:
                  () => setState(
                    () => _contingentExpanded = !_contingentExpanded,
                  ),
              tileColor: AppColors.accent.withAlpha(25),
              child: ContingentCard(
                contingent: widget.contingent,
                onEdit:
                    () => showContingentModal(
                      context,
                      contingent: widget.contingent,
                      onSubmit: (contingent) async {
                        await ContingentController().updateContingent(
                          context,
                          contingent,
                        );
                      },
                    ),
                onDelete: () {
                  // Delete logic
                },
                onViewEvents: () {
                  Navigator.of(context).push(
                    LiquidPageRoute(
                      page: EventsParticipatedPage(contingent: widget.contingent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        border: Border.all(color: color.withAlpha(128)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: color,
      splashRadius: 20,
      tooltip: icon == Icons.edit ? "Edit" : "Delete",
      onPressed: onTap,
    );
  }

  Widget _buildExpandableTile({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    required Color tileColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.primary,
            ),
            onTap: onToggle,
          ),
          if (isExpanded)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ],
      ),
    );
  }
}
