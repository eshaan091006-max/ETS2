import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/cards/participation_card.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/helpers/empty_state_widget.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/helpers/shimmer_skeleton.dart';

class ScoresPage extends StatefulWidget {
  final Contingent c;
  const ScoresPage({required this.c, super.key});

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  final EventController _eventController = EventController();

  String selectedDepartment = 'All';
  String selectedEventType = 'All';

  late List<Participation> allParticipations;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() {
    allParticipations =
        ParticipationController().participations
            .where((p) => p.contingentId == widget.c.contingentId)
            .toList();
  }

  List<String> getDepartments() {
    final departments =
        _eventController.events
            .map(
              (e) =>
                  DepartmentController()
                      .getDepartmentById(e.departmentId)
                      ?.code,
            )
            .whereType<String>()
            .toSet()
            .toList();
    departments.sort();
    return ['All', ...departments];
  }

  List<String> getEventTypes() {
    final types =
        _eventController.events
            .map((e) {
              if (e.eventType == 1) return 'Flagship';
              if (e.eventType == 0) return 'Classic';
              return 'None';
            })
            .toSet()
            .toList();
    types.sort();
    return ['All', ...types];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (_, __, ___) {
        loadData();
        final filtered =
            allParticipations.where((p) {
              final event = _eventController.getEventById(p.eventId);
              if (event == null) return false;

              final dept = DepartmentController().getDepartmentById(event.departmentId);
              if (dept == null) return false;
              final deptCode = dept.code;
              final matchesDept =
                  selectedDepartment == 'All' || deptCode == selectedDepartment;
              final matchesType =
                  selectedEventType == 'All' ||
                  (event.eventType == 1 ? "Flagship" : (event.eventType == 0 ? "Classic" : "None")) == selectedEventType;

              return matchesDept && matchesType;
            }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 400;
                  if (isCompact) {
                    return Column(
                      children: [
                        buildDropdown(
                          label: 'Department',
                          value: selectedDepartment,
                          options: getDepartments(),
                          onChanged:
                              (val) => setState(() => selectedDepartment = val!),
                          expanded: false,
                        ),
                        const SizedBox(height: 8),
                        buildDropdown(
                          label: 'Event Type',
                          value: selectedEventType,
                          options: getEventTypes(),
                          onChanged:
                              (val) => setState(() => selectedEventType = val!),
                          expanded: false,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      buildDropdown(
                        label: 'Department',
                        value: selectedDepartment,
                        options: getDepartments(),
                        onChanged:
                            (val) => setState(() => selectedDepartment = val!),
                        expanded: true,
                      ),
                      const SizedBox(width: 12),
                      buildDropdown(
                        label: 'Event Type',
                        value: selectedEventType,
                        options: getEventTypes(),
                        onChanged:
                            (val) => setState(() => selectedEventType = val!),
                        expanded: true,
                      ),
                    ],
                  );
                },
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.secondary,
                onRefresh: () async {
                  if (PageRefreshController.onRefresh != null) {
                    PageRefreshController.onRefresh!();
                  }
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: !PageRefreshController.initialLoadCompleted
                    ? const ShimmerSkeletonList(itemCount: 3, cardHeight: 180.0)
                    : filtered.isEmpty
                        ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: EmptyStateWidget(
                              title: 'No Events Found',
                              subtitle: 'Try adjusting your type or department filters.',
                              icon: Icons.event_busy,
                              action: TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDepartment = 'All';
                                    selectedEventType = 'All';
                                  });
                                },
                                child: const Text(
                                  "Reset Filters",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final e =
                              _eventController.getEventById(p.eventId) ??
                              Event(dateTime: DateTime.now());
                          return ParticipationCard(
                            participation: p,
                            event: e,
                            entryNumber:
                                ParticipationController().entryNumberOf(p),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
