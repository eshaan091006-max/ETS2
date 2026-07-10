import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/form_helpers.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/link_validator.dart';

Future<void> showEventModal(
  BuildContext context, {
  Event? event,
  required Function(Event, List<FormLink>) onSubmit,
}) async {
  DepartmentController deptCont = DepartmentController();
  await deptCont.loadDepartments();

  if (deptCont.departments.isEmpty) {
    AppFeedback.showError(context, 'No departments found. Please add a department first.');
    return;
  }

  final nameController = TextEditingController(text: event?.eventName ?? '');
  final marksController = TextEditingController(
    text:
        event?.highestMarks != null && event!.highestMarks != -1
            ? event.highestMarks.toString()
            : '',
  );

  List<Map<String, TextEditingController>> linkControllers = [];

  if (event != null) {
    List<FormLink> existingLinks = FormLinkController().getFormLinksByEventId(event.eventId);
    for (var link in existingLinks) {
      linkControllers.add({
        'label': TextEditingController(text: link.label ?? ''),
        'url': TextEditingController(text: link.link),
      });
    }
    if (existingLinks.isEmpty && event.formLink.isNotEmpty) {
      linkControllers.add({
        'label': TextEditingController(text: 'Main Link'),
        'url': TextEditingController(text: event.formLink),
      });
    }
  } else {
    linkControllers.add({
        'label': TextEditingController(text: 'Main Link'),
        'url': TextEditingController(text: ''),
    });
  }

  Department selectedDepartment =
      deptCont.getDepartmentById(
        event?.departmentId ?? deptCont.departments.first.id,
      ) ??
      deptCont.departments.first;
  DateTime selectedDate = event?.dateTime ?? DateTime(2006, 2, 10, 15, 43, 0);
  int eventType = event?.eventType ?? 0;
  int elimsType = event?.elimsType ?? 0;
  List<int> collabDeptIds = List<int>.from(event?.collabDeptIds ?? []);
  final isUpdating = event != null;

  await showDialog(
    context: context,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isUpdating ? 'Update Event' : 'Add Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTextField(nameController, 'Event Name'),
                    const SizedBox(height: 12),
                    buildTextField(
                      marksController,
                      'Highest Marks (Optional)',
                      inputType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    buildDropdown<Department>(
                      label: 'Department',
                      value: selectedDepartment,
                      items: deptCont.departments,
                      getLabel: (dept) => dept.name,
                      onChanged: (val) {
                        setState(() {
                          selectedDepartment = val ?? deptCont.departments.first;
                        });
                      },
                    ),

                    if (selectedDepartment.name.toLowerCase() == 'crossovers') ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Crossover Domains',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...deptCont.departments
                          .where((d) => d.name.toLowerCase() != 'crossovers')
                          .map((d) {
                        final isSelected = collabDeptIds.contains(d.id);
                        return CheckboxListTile(
                          title: Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(d.code, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          value: isSelected,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                collabDeptIds.add(d.id);
                              } else {
                                collabDeptIds.remove(d.id);
                              }
                            });
                          },
                        );
                      }),
                    ],

                    
                    // Links Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Links', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        ...linkControllers.asMap().entries.map((entry) {
                          int index = entry.key;
                          var controllers = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: buildTextField(controllers['label']!, 'Label'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: buildTextField(controllers['url']!, 'URL'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      linkControllers.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: const Icon(Icons.add, color: AppColors.accent),
                          label: const Text('Add Link', style: TextStyle(color: AppColors.accent)),
                          onPressed: () {
                            setState(() {
                              linkControllers.add({
                                'label': TextEditingController(text: ''),
                                'url': TextEditingController(text: ''),
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    buildDropdown<int>(
                      label: 'Event Type',
                      value: eventType,
                      items: const [0, 1, 2],
                      getLabel: (val) {
                        if (val == 0) return 'Classic';
                        if (val == 1) return 'Flagship';
                        return 'None';
                      },
                      onChanged: (val) {
                        setState(() {
                          eventType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    buildDropdown<int>(
                      label: 'Event Format / Elims',
                      value: elimsType,
                      items: const [0, 1, 2],
                      getLabel: (val) {
                        switch (val) {
                          case 0:
                            return 'Direct Finals';
                          case 1:
                            return 'Online Elims + Offline Finals';
                          case 2:
                            return 'Offline Elims + Offline Finals';
                          default:
                            return 'Direct Finals';
                        }
                      },
                      onChanged: (val) {
                        setState(() {
                          elimsType = val!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      AppFeedback.showError(context, 'Event name is required');
                      return;
                    }

                    final highestMarks =
                        int.tryParse(marksController.text.trim()) ?? -1;

                    List<FormLink> finalLinks = [];
                    for (var c in linkControllers) {
                      final url = c['url']!.text.trim();
                      if (url.isNotEmpty) {
                        finalLinks.add(FormLink(
                          eventId: event?.eventId ?? 0,
                          label: c['label']!.text.trim(),
                          link: url,
                          visibleTo: [],
                        ));
                      }
                    }

                    // Validate links
                    if (finalLinks.isNotEmpty) {
                      AppFeedback.showLoading(context, message: 'Validating URLs...');
                      for (var formLink in finalLinks) {
                        final isValid = await LinkValidator.isValidWorkingLink(formLink.link);
                        if (!isValid) {
                          if (context.mounted) {
                            AppFeedback.hideLoading(context);
                            AppFeedback.showError(
                              context,
                              'The link "${formLink.link}" is not a working link or is unreachable. Please verify.',
                            );
                          }
                          return;
                        }
                      }
                      if (context.mounted) {
                        AppFeedback.hideLoading(context);
                      }
                    }

                    if (!context.mounted) return;
                    AppFeedback.showLoading(context, message: isUpdating ? 'Updating...' : 'Adding...');
                    final modalContext = context;
                    
                    await onSubmit(
                      Event(
                        eventId: event?.eventId ?? 0,
                        eventName: nameController.text.trim(),
                        highestMarks: highestMarks,
                        dateTime: DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedDate.hour,
                          selectedDate.minute,
                          selectedDate.second,
                        ),
                        formLink: finalLinks.isNotEmpty ? finalLinks.first.link : '',
                        departmentId: selectedDepartment.id,
                        eventType: eventType,
                        elimsType: elimsType,
                        collabDeptIds: selectedDepartment.name.toLowerCase() == 'crossovers' ? collabDeptIds : [],
                      ),
                      finalLinks,
                    );

                    if (modalContext.mounted) {
                      AppFeedback.hideLoading(modalContext);
                      Navigator.pop(modalContext);
                    }
                  },
                  child: Text(isUpdating ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
