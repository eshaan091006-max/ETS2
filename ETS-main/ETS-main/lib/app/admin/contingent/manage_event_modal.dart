import 'package:flutter/material.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

void showUpdateEventBottomSheet(
  BuildContext context,
  List<Participation> participations,
  Contingent contingent,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return UpdateEventSheet(participation: participations, contingent: contingent);
        },
      );
    },
  );
}

void showAddEventBottomSheet(
  BuildContext context,
  List<Event> events,
  Contingent contingent,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return AddEventSheet(events: events, contingent: contingent);
        },
      );
    },
  );
}

class AddEventSheet extends StatefulWidget {
  final List<Event> events;
  final Contingent contingent;

  const AddEventSheet({
    super.key,
    required this.events,
    required this.contingent,
  });

  @override
  State<AddEventSheet> createState() => AddEventSheetState();
}

class AddEventSheetState extends State<AddEventSheet> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.events.length, false);
  }

  void _handleSubmit() async {
    final selectedIndexes = <int>[];
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) selectedIndexes.add(i);
    }
    List<Participation> participations =
        selectedIndexes
            .map(
              (i) => Participation(
                participationId: -1,
                contingentId: widget.contingent.contingentId,
                eventId: widget.events[i].eventId,
              ),
            )
            .toList();
            
    if (participations.isEmpty) {
      AppFeedback.showError(context, "Please select at least one event.");
      return;
    }

    AppFeedback.showLoading(context, message: "Adding events...");
    final success = await ParticipationController().createMultipleParticipation(
      context,
      participations,
    );
    
    if (mounted) {
      AppFeedback.hideLoading(context);
      if (success) {
        Navigator.pop(context); // Close the modal
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Text(
            "Select Events",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: ScrollController(),
              itemCount: widget.events.length,
              itemBuilder: (context, index) {
                Event e = widget.events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: Text("${e.eventId}"),
                          title: Text("${e.eventName} "),
                          trailing: Checkbox(
                            value: _selected[index],
                            onChanged: (value) {
                              setState(() {
                                _selected[index] = value ?? false;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text("Add"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpdateEventSheet extends StatefulWidget {
  final List<Participation> participation;
  final Contingent contingent;

  const UpdateEventSheet({
    required this.participation,
    required this.contingent,
    super.key,
  });

  @override
  State<UpdateEventSheet> createState() => _UpdateEventSheetState();
}

class _UpdateEventSheetState extends State<UpdateEventSheet> {
  final EventController _eController = EventController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late List<TextEditingController> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.generate(
      widget.participation.length,
      (index) {
        final int originalMarks = widget.participation[index].marksScored;
        return TextEditingController(
          text: '${originalMarks == -1 ? 0 : originalMarks}',
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _fields) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      bool allSucceeded = true;
      for (int i = 0; i < _fields.length; i++) {
        int marks = int.parse(_fields[i].text);
        Participation p = widget.participation[i];
        if (p.marksScored != marks) {
           p.marksScored = marks;
           final bool success = await ParticipationController().updateParticipation(context, p, displayMsg: false);
           if (!success) {
             allSucceeded = false;
           }
        }
      }
      
      if (!allSucceeded) {
        if (mounted) {
          AppFeedback.showError(context, "Failed to update some participation marks. Please verify database RLS policies.");
        }
        return;
      }
      
      // Update highest marks for the affected events
      for (var p in widget.participation) {
         await EventController().updateHighestMarks(context, p.eventId);
      }
      
      if(mounted) {
         AppFeedback.showSuccess(context, "Marks updated successfully.");
         Navigator.pop(context); // Close sheet after updating
      }
    } else {
      AppFeedback.showError(context, 'Invalid Fields');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Text(
            "Update Marks",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                itemCount: widget.participation.length,
                itemBuilder: (context, index) {
                  Participation p = widget.participation[index];
                  Event e =
                      _eController.getEventById(p.eventId) ??
                      Event(dateTime: DateTime.now());

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _fields[index],
                        validator: (value) {
                          final val = int.tryParse(value ?? '');
                          if (val == null || val < -1) {
                            return "Marks must be a number!";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "${e.eventId} ${e.eventName}",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text("Update"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
