import 'package:flutter/material.dart';

Future<void> confirmDialog(
  BuildContext context,
  String title,
  Widget content, {
  required VoidCallback onSubmit,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder:
            (context, setState) => AlertDialog(
              title: Text(title),
              content: content,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSubmit();
                  },
                  child: Text('Confirm'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
      );
    },
  );
}
