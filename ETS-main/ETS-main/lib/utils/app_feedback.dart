import 'package:flutter/material.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import '../constants/app_colors.dart'; // adjust path as needed

class AppFeedback {
  /// Show a loading dialog
  static void showLoading(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: AppColors.background,
              content: Row(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    if (!context.mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, AppColors.success);
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, AppColors.error);
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, AppColors.warning);
  }

  static void notifyUpdate(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      AppColors.primary,
      action: SnackBarAction(
        textColor: AppColors.textWhite,
        label: 'Update',
        onPressed: PageRefreshController.triggerRefresh,
      ),
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message,
    Color bgColor, {
    SnackBarAction? action, // Optional action
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: action, // Add action if provided
      ),
    );
  }
}
