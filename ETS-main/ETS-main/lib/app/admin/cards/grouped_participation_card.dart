import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class GroupedParticipationCard extends StatefulWidget {
  final Contingent contingent;
  final List<Participation> participations;
  final Function(Participation) onEdit;
  final Function(Participation) onDelete;

  const GroupedParticipationCard({
    super.key,
    required this.contingent,
    required this.participations,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<GroupedParticipationCard> createState() => _GroupedParticipationCardState();
}

class _GroupedParticipationCardState extends State<GroupedParticipationCard> {
  late Participation _selectedParticipation;
  bool _eventExpanded = false;
  bool _contingentExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedParticipation = widget.participations.first;
  }

  @override
  void didUpdateWidget(covariant GroupedParticipationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the list of participations changed and doesn't contain the selected one anymore,
    // reset to the first one.
    if (!widget.participations.contains(_selectedParticipation)) {
      if (widget.participations.isNotEmpty) {
        _selectedParticipation = widget.participations.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Double check if selected participation is still in the widget's participations list
    // (needed if list shrunk during rebuild/deletion)
    if (!widget.participations.contains(_selectedParticipation)) {
      _selectedParticipation = widget.participations.first;
    }

    final EventController eventController = EventController();
    final Event currentEvent = eventController.getEventById(_selectedParticipation.eventId) ??
        Event(dateTime: DateTime.now());

    final String marks =
        _selectedParticipation.marksScored == -1
            ? "-"
            : _selectedParticipation.marksScored.toString();
    final String highest =
        currentEvent.highestMarks == -1
            ? "-"
            : currentEvent.highestMarks.toString();

    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Contingent Code & Actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.contingent.contingentCode,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _iconButton(Icons.edit, AppColors.accent, () => widget.onEdit(_selectedParticipation)),
                _iconButton(Icons.delete, AppColors.error, () => widget.onDelete(_selectedParticipation)),
              ],
            ),

            const SizedBox(height: 12),

            /// Dropdown: Event Selection Label
            const Text(
              "Select Event",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            /// Dropdown: Event Selection Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withAlpha(150),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Participation>(
                  value: _selectedParticipation,
                  dropdownColor: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
                  items: widget.participations.map((Participation p) {
                    final ev = eventController.getEventById(p.eventId) ??
                        Event(dateTime: DateTime.now());
                    return DropdownMenuItem<Participation>(
                      value: p,
                      child: Text(ev.eventName),
                    );
                  }).toList(),
                  onChanged: (Participation? newPart) {
                    if (newPart != null) {
                      setState(() {
                        _selectedParticipation = newPart;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Metrics Row
            Row(
              children: [
                _buildMetric("Marks", marks, AppColors.accent),
                const SizedBox(width: 12),
                _buildMetric("Highest", highest, AppColors.warning),
              ],
            ),

            const SizedBox(height: 20),

            /// Event Section
            _buildExpandableTile(
              title: "Event Details",
              subtitle: currentEvent.eventName,
              isExpanded: _eventExpanded,
              onToggle: () => setState(() => _eventExpanded = !_eventExpanded),
              tileColor: AppColors.primary.withAlpha(25),
              child: EventCard(
                event: currentEvent,
                onEdit:
                    () => showEventModal(
                      context,
                      event: currentEvent,
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
              title: "Contingent Details",
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
