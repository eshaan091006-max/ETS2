import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/form_helpers.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/utils/link_validator.dart';

Future<void> showFormLinkModal(
  BuildContext context, {
  required int eventId,
  FormLink? formLink,
  required Function(FormLink) onSubmit,
}) async {
  final labelController = TextEditingController(text: formLink?.label ?? '');
  final linkController = TextEditingController(text: formLink?.link ?? '');
  final searchController = TextEditingController();
  final listScrollController = ScrollController();
  final dialogScrollController = ScrollController();

  final isUpdating = formLink != null;

  final contingentController = ContingentController();
  await contingentController.loadContingents();

  if (!context.mounted) return;

  List<Contingent> allContingents = contingentController.contingents;

  // Selected contingent IDs (visibleTo)
  Set<int> selectedContingents = {if (formLink != null) ...formLink.visibleTo};

  try {
    await showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setState) {
              final query = searchController.text.trim().toLowerCase();
              final filteredContingents = allContingents.where((c) {
                return c.contingentCode.toLowerCase().contains(query);
              }).toList();

              final allFilteredSelected = filteredContingents.isNotEmpty &&
                  filteredContingents.every((c) => selectedContingents.contains(c.contingentId));

              return AlertDialog(
                title: Text(isUpdating ? 'Update Form Link' : 'Add Form Link'),
                content: SingleChildScrollView(
                  controller: dialogScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildTextField(labelController, 'Form Label'),
                      const SizedBox(height: 12),
                      buildTextField(linkController, 'Form URL'),
                      const SizedBox(height: 12),

                      /// Contingent Checkboxes Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Visible To:',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// Search field
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: AppColors.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Search Contingents...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.primary),
                                  onPressed: () {
                                    searchController.clear();
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
                          Future.microtask(() {
                            if (context.mounted) {
                              setState(() {});
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 6),

                      // Select All / Deselect All
                      CheckboxListTile(
                        dense: true,
                        title: Text(
                          allFilteredSelected
                              ? (query.isEmpty ? 'Deselect All' : 'Deselect All Filtered')
                              : (query.isEmpty ? 'Select All' : 'Select All Filtered'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: allFilteredSelected,
                        onChanged: (bool? value) {
                          Future.microtask(() {
                            if (context.mounted) {
                              setState(() {
                                if (value == true) {
                                  selectedContingents.addAll(filteredContingents.map((c) => c.contingentId));
                                } else {
                                  for (var c in filteredContingents) {
                                    selectedContingents.remove(c.contingentId);
                                  }
                                }
                              });
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Individual Contingent Checkboxes (Height constrained container)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: filteredContingents.isEmpty
                            ? const Center(
                                child: Text(
                                  'No contingents found',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                controller: listScrollController,
                                itemCount: filteredContingents.length,
                                itemBuilder: (context, index) {
                                  final contingent = filteredContingents[index];
                                  final isChecked = selectedContingents.contains(
                                    contingent.contingentId,
                                  );
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(
                                      contingent.contingentCode,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    value: isChecked,
                                    onChanged: (bool? val) {
                                      Future.microtask(() {
                                        if (context.mounted) {
                                          setState(() {
                                            if (val == true) {
                                              selectedContingents.add(contingent.contingentId);
                                            } else {
                                              selectedContingents.remove(contingent.contingentId);
                                            }
                                          });
                                        }
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  );
                                },
                              ),
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
                      final url = linkController.text.trim();
                      if (labelController.text.trim().isEmpty ||
                          url.isEmpty) {
                        AppFeedback.showError(
                          context,
                          'Label and URL are required',
                        );
                        return;
                      }

                      AppFeedback.showLoading(context, message: 'Validating URL...');
                      final isValid = await LinkValidator.isValidWorkingLink(url);
                      if (!context.mounted) return;
                      AppFeedback.hideLoading(context);

                      if (!isValid) {
                        AppFeedback.showError(
                          context,
                          'The URL is not a working link or is unreachable. Please verify.',
                        );
                        return;
                      }

                      AppFeedback.showLoading(context, message: isUpdating ? 'Updating...' : 'Adding...');
                      final modalContext = context;

                      await onSubmit(
                        FormLink(
                          id: formLink?.id ?? -1,
                          eventId: eventId,
                          label: labelController.text.trim(),
                          link: url,
                          visibleTo: selectedContingents.toList(),
                        ),
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
  } finally {
    labelController.dispose();
    linkController.dispose();
    searchController.dispose();
    listScrollController.dispose();
    dialogScrollController.dispose();
  }
}
