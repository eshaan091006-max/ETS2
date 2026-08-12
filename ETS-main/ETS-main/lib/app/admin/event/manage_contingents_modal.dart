import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

final titleTextStyle = GoogleFonts.readexPro(fontSize: 18);
final textStyle = GoogleFonts.poppins(color: AppColors.primary);

void showUpdateContingentBottomSheet(
  BuildContext context,
  List<Participation> participations,
  Event event,
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
          return UpdateContingentSheet(
            participation: participations,
            event: event,
          );
        },
      );
    },
  );
}

void showAddContingentBottomSheet(
  BuildContext context,
  List<Contingent> contingents,
  Event event,
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
          return AddContingentSheet(contingents: contingents, event: event);
        },
      );
    },
  );
}

class AddContingentSheet extends StatefulWidget {
  final List<Contingent> contingents;
  final Event event;

  const AddContingentSheet({
    super.key,
    required this.contingents,
    required this.event,
  });

  @override
  State<AddContingentSheet> createState() => AddContingentSheetState();
}

class AddContingentSheetState extends State<AddContingentSheet> {
  final Set<int> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    List<Participation> participations =
        _selectedIds
            .map(
              (id) => Participation(
                participationId: -1,
                contingentId: id,
                eventId: widget.event.eventId,
              ),
            )
            .toList();
            
    if (participations.isEmpty) {
      AppFeedback.showError(context, "Please select at least one contingent.");
      return;
    }

    print("Selected Contingent IDs: $_selectedIds");
    AppFeedback.showLoading(context, message: "Adding contingents...");
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
    final query = _searchController.text.trim().toLowerCase();
    final filteredContingents = widget.contingents.where((c) {
      return c.contingentCode.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Text("Select Contingents", style: titleTextStyle),
          const SizedBox(height: 10),

          /// Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: InputDecoration(
              hintText: 'Search Contingents...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.primary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (text) {
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          Expanded(
            child: filteredContingents.isEmpty
                ? const Center(
                    child: Text(
                      'No contingents found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: ScrollController(),
                    itemCount: filteredContingents.length,
                    itemBuilder: (context, index) {
                      Contingent c = filteredContingents[index];
                      final isChecked = _selectedIds.contains(c.contingentId);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListTile(
                                shape: const OutlineInputBorder(),
                                tileColor: AppColors.tertiary,
                                titleTextStyle: textStyle,
                                title: Text("${c.contingentCode} "),
                                trailing: Checkbox(
                                  value: isChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(c.contingentId);
                                      } else {
                                        _selectedIds.remove(c.contingentId);
                                      }
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
                  child: Text("Add", style: titleTextStyle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close", style: titleTextStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpdateContingentSheet extends StatefulWidget {
  final List<Participation> participation;
  final Event event;

  const UpdateContingentSheet({
    required this.participation,
    required this.event,
    super.key,
  });

  @override
  State<UpdateContingentSheet> createState() => _UpdateContingentSheetState();
}

class _UpdateContingentSheetState extends State<UpdateContingentSheet> {
  // final ParticipationController _pController = ParticipationController();
  final ContingentController _cController = ContingentController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late List<TextEditingController> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.generate(widget.participation.length, (index) {
      final int originalMarks = widget.participation[index].marksScored;
      final controller = TextEditingController(
        text: '${originalMarks == -1 ? 0 : originalMarks}',
      );
      return controller;
    });
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
      // Access the text values using _fields[index].text
      List<Participation> participations = [];
      for (int i = 0; i < _fields.length; i++) {
        int marks = int.parse(_fields[i].text);
        Participation p = widget.participation[i];
        p.marksScored = marks;
        participations.add(p);
        // print("Contingent ${p.contingentId} - Marks: $marks");
      }
      await ParticipationController().updateMultipleParticipationSameEvent(
        context,
        participations,
        widget.event,
      );

      Navigator.pop(context); // Close sheet after updating
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
          Text("Update Marks", style: titleTextStyle),
          const SizedBox(height: 10),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                itemCount: widget.participation.length,
                itemBuilder: (context, index) {
                  Participation p = widget.participation[index];
                  Contingent c =
                      _cController.getContingentById(p.contingentId) ??
                      Contingent();
                  // _fields[index].text = '${p.marksScored}';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        style: textStyle,
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
                          labelText: c.contingentCode,
                          labelStyle: textStyle,

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
                  child: Text("Update", style: titleTextStyle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close", style: textStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
