import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/cards/participation_card.dart';
import 'package:malhar_ets/app/admin/contingent/manage_event_modal.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/helpers/animated_card_wrapper.dart';
import 'package:malhar_ets/helpers/empty_state_widget.dart';

class EventsParticipatedPage extends StatefulWidget {
  final Contingent contingent;
  const EventsParticipatedPage({required this.contingent, super.key});

  @override
  State<EventsParticipatedPage> createState() => _EventsParticipatedPageState();
}

class _EventsParticipatedPageState extends State<EventsParticipatedPage> {
  final EventController _eventController = EventController();
  final ParticipationController _participationController =
      ParticipationController();

  List<Event> events = [];
  List<Participation> participations = [];

  String selectedDept = 'All';
  String selectedType = 'All';

  List<String> departments = ['All'];
  List<String> types = ['All', 'Classic', 'Flagship', 'None'];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    participations =
        _participationController.participations
            .where((p) => p.contingentId == widget.contingent.contingentId)
            .toList();

    List<int> eventIds = participations.map((p) => p.eventId).toList();

    events =
        _eventController.events
            .where((e) => eventIds.contains(e.eventId))
            .toList();

    // Set department list from filtered events
    departments = [
      'All',
      ...{
        for (var e in events)
          DepartmentController()
              .getDepartmentById(e.departmentId.toInt())
              ?.code,
      }.whereType<String>(),
    ];
  }

  List<Participation> getFilteredParticipations() {
    return participations.where((p) {
      final event = events.firstWhere((e) => e.eventId == p.eventId);

      final deptCode =
          DepartmentController()
              .getDepartmentById(event.departmentId.toInt())
              ?.code;

      final deptMatch = selectedDept == 'All' || deptCode == selectedDept;
      final typeMatch =
          selectedType == 'All' ||
          (selectedType == 'Classic' && event.eventType == 0) ||
          (selectedType == 'Flagship' && event.eventType == 1) ||
          (selectedType == 'None' && event.eventType == 2);

      return deptMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, refresh, child) {
        _initData();
        final filteredParticipations = getFilteredParticipations();

        return Scaffold(
          backgroundColor: AppColors.secondary,
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            onPressed: () {
              // Every event stays selectable: picking one the contingent is
              // already in adds a further entry rather than being blocked.
              showAddEventBottomSheet(
                context,
                _eventController.events,
                widget.contingent,
              );
            },
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            foregroundColor: AppColors.textWhite,
            title: const Text('All Events'),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          body: Column(
            children: [
              // FILTER BAR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppColors.secondary.withAlpha(230),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 400;
                    if (isCompact) {
                      return Column(
                        children: [
                          buildDropdown(
                            label: 'Dept',
                            value: selectedDept,
                            options: departments,
                            onChanged: (val) => setState(() => selectedDept = val!),
                            expanded: false,
                          ),
                          const SizedBox(height: 8),
                          buildDropdown(
                            label: 'Type',
                            value: selectedType,
                            options: types,
                            onChanged: (val) => setState(() => selectedType = val!),
                            expanded: false,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        buildDropdown(
                          label: 'Dept',
                          value: selectedDept,
                          options: departments,
                          onChanged: (val) => setState(() => selectedDept = val!),
                          expanded: true,
                        ),
                        const SizedBox(width: 12),
                        buildDropdown(
                          label: 'Type',
                          value: selectedType,
                          options: types,
                          onChanged: (val) => setState(() => selectedType = val!),
                          expanded: true,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // PARTICIPATION LIST
              Expanded(
                child:
                    filteredParticipations.isEmpty
                        ? EmptyStateWidget(
                          title: 'No Participations Yet',
                          subtitle:
                              'This contingent has not been added to any events matching the filters.',
                          icon: Icons.event_note,
                          action: TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDept = 'All';
                                selectedType = 'All';
                              });
                            },
                            child: const Text(
                              "Clear Filters",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredParticipations.length,
                          itemBuilder: (context, index) {
                            final p = filteredParticipations[index];
                            final event = events.firstWhere(
                              (e) => e.eventId == p.eventId,
                            );

                            return AnimatedCardWrapper(
                              key: ValueKey(p.participationId),
                              child: ParticipationCard(
                                contingent: widget.contingent,
                                participation: p,
                                event: event,
                                onEdit: () {
                                  showUpdateEventBottomSheet(context, [
                                    p,
                                  ], widget.contingent);
                                },
                                onDelete: () {
                                  confirmDeletionModal(
                                    context,
                                    'Participation',
                                    onSubmit: () {
                                      _participationController
                                          .deleteParticipation(context, p);
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
