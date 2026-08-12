import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/utils/hash_util.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

class ContingentCard extends StatelessWidget {
  final Contingent contingent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewEvents;

  const ContingentCard({
    super.key,
    required this.contingent,
    required this.onEdit,
    required this.onDelete,
    required this.onViewEvents,
  });

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Row: Code + Edit/Delete
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            contingent.contingentCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: AppColors.warning,
                              tooltip: 'Edit',
                              onPressed: onEdit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: AppColors.error,
                              tooltip: 'Delete',
                              onPressed:
                                  () => confirmDeletionModal(
                                    context,
                                    'Contingent',
                                    onSubmit: onDelete,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text('Reset Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            final resetPasswordController = TextEditingController();
                            bool dialogObscure = true;
                            showDialog(
                              context: context,
                              builder: (ctx) => BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: StatefulBuilder(
                                  builder: (ctx, setDialogState) => AlertDialog(
                                    title: const Text('Reset Password'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Are you sure you want to reset the password for ${contingent.contingentCode}?'),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: resetPasswordController,
                                          obscureText: dialogObscure,
                                          decoration: InputDecoration(
                                            labelText: 'New Password (leave blank for code)',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                dialogObscure ? Icons.visibility_off : Icons.visibility,
                                              ),
                                              onPressed: () => setDialogState(() => dialogObscure = !dialogObscure),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final newPassPlain = resetPasswordController.text.isNotEmpty 
                                              ? resetPasswordController.text.trim() 
                                              : contingent.contingentCode;
                                          final newPasswordHash = HashUtil.hashPassword(newPassPlain);
                                          
                                          final updatedContingent = Contingent(
                                            contingentId: contingent.contingentId,
                                            contingentCode: contingent.contingentCode,
                                            password: newPasswordHash,
                                            resetCount: 3,
                                          );
                                          final success = await ContingentController().updateContingent(context, updatedContingent);
                                          if (success) {
                                            AppFeedback.showSuccess(context, 'Password reset successfully. Please send the new password to the contingent.');
                                          }
                                        },
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.event, size: 18),
                          label: const Text('Manage Events'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: onViewEvents,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
