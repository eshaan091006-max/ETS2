import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/hash_util.dart';

Future<void> showContingentModal(
  BuildContext context, {
  Contingent? contingent,
  required Function(Contingent) onSubmit,
}) async {
  final TextEditingController codeController = TextEditingController(
    text: contingent?.contingentCode ?? '',
  );
  final TextEditingController passwordController = TextEditingController();

  bool isUpdating = contingent != null;
  bool obscure = true;

  await showDialog(
    context: context,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(isUpdating ? 'Update Contingent' : 'Add Contingent'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Contingent Code',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isUpdating)
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Initial Password (leave blank for contingent code)',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                   ElevatedButton(
                    onPressed: () async {
                      if (codeController.text.trim().isEmpty) {
                        AppFeedback.showError(context, 'Please fill all fields');
                        return;
                      }
  
                      // For a new contingent, hash the provided password or code as default
                      // If updating, preserve old password (unless admin resets it later)
                      final newPassword = isUpdating
                          ? contingent.password
                          : HashUtil.hashPassword(
                              passwordController.text.isNotEmpty
                                  ? passwordController.text.trim()
                                  : codeController.text.trim(),
                            );
  
                      AppFeedback.showLoading(context, message: isUpdating ? 'Updating...' : 'Adding...');
                      final modalContext = context;
                      final dynamic result = await onSubmit(
                        Contingent(
                          contingentId: contingent?.contingentId ?? 0,
                          contingentCode: codeController.text.trim(),
                          password: newPassword,
                          resetCount: contingent?.resetCount ?? 3,
                        ),
                      );
                      
                      if (modalContext.mounted) {
                        AppFeedback.hideLoading(modalContext);
                        // Only close the modal if the operation succeeded
                        final bool success = result is bool ? result : true;
                        if (success) Navigator.pop(modalContext);
                      }
                    },
                    child: Text(isUpdating ? 'Update' : 'Add'),
                  ),
                ],
              ),
        ),
      );
    },
  );
}
