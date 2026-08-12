import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/cards/participation_card.dart';
import 'package:malhar_ets/app/admin/event/manage_contingents_modal.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';

class ContingentsParticipatedPage extends StatefulWidget {
  final Event event;
  const ContingentsParticipatedPage({required this.event, super.key});

  @override
  State<ContingentsParticipatedPage> createState() =>
      _ContingentsParticipatedPageState();
}

class _ContingentsParticipatedPageState
    extends State<ContingentsParticipatedPage> {
  final ContingentController _contingentController = ContingentController();
  final ParticipationController _participationController =
      ParticipationController();
  late List<Contingent> contingents = [];
  late List<Participation> participations = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  loadData() {
    final allParticipations =
        _participationController.participations
            .where((p) => p.eventId == widget.event.eventId)
            .toList();

    final contingentMap = {
      for (var c in _contingentController.contingents) c.contingentId: c,
    };

    participations =
        allParticipations
            .where((p) => contingentMap.containsKey(p.contingentId))
            .toList();

    contingents =
        participations
            .map((p) => contingentMap[p.contingentId]!)
            .toSet()
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        IconButton(
          hoverColor: AppColors.primary,
          color: AppColors.textWhite,

          onPressed: () {
            List<Contingent> c =
                _contingentController.contingents
                    .where((c) => !contingents.contains(c))
                    .toList();
            showAddContingentBottomSheet(context, c, widget.event);
          },
          icon: Icon(Icons.add, semanticLabel: 'Add', size: 40),
        ),
        IconButton(
          hoverColor: AppColors.primary,
          color: AppColors.textWhite,
          onPressed: () {
            showUpdateContingentBottomSheet(
              context,
              participations,
              widget.event,
            );
          },
          icon: Icon(Icons.refresh, semanticLabel: 'Update', size: 40),
        ),
      ],

      appBar: AppBar(
        foregroundColor: AppColors.textWhite,
        title: Text('All Contingents'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => PageRefreshController.triggerRefresh(),
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: PageRefreshController.refreshNotifier,
        builder: (_, __, ___) {
          loadData();
          if (participations.isEmpty) {
            return Center(
              child: Text(
                'No Participations',
                style: TextStyle(color: AppColors.primary, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: participations.length,
            itemBuilder: (context, index) {
              Participation p = participations[index];
              return ParticipationCard(
                contingent: contingents.firstWhere(
                  (c) => c.contingentId == p.contingentId,
                ),

                participation: p,
                event: widget.event,

                onEdit: () => {},

                onDelete:
                    () => confirmDeletionModal(
                      context,
                      'Participation',
                      onSubmit:
                          () => ParticipationController().deleteParticipation(
                            context,
                            p,
                          ),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
