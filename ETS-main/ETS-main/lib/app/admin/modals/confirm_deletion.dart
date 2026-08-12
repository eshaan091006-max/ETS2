import 'dart:ui';
import 'package:flutter/material.dart';

Future<void> confirmDeletionModal(
  BuildContext context,
  String label, {
  required VoidCallback onSubmit,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text("Confirm Delete"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Make Sure You have Chosen the right $label.'),
                    const SizedBox(height: 12),
                    Text(
                      '2. Make Sure You have deleted all the Participations connected with this $label.',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onSubmit();
                    },
                    child: const Text('Delete'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
        ),
      );
    },
  );
}
