import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/app/admin/modals/form_link_modal.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:url_launcher/url_launcher.dart';

class FormLinkCard extends StatefulWidget {
  final FormLink formLink;
  const FormLinkCard({required this.formLink, super.key});

  @override
  State<FormLinkCard> createState() => _FormLinkCardState();
}

class _FormLinkCardState extends State<FormLinkCard> {
  @override
  Widget build(BuildContext context) {
    final List<String> visibleToCodes = [];

    for (int id in widget.formLink.visibleTo) {
      final contingent = ContingentController().getContingentById(id);
      if (contingent != null) {
        visibleToCodes.add(contingent.contingentCode);
      }
    }
    final visibleToString =
        visibleToCodes.isEmpty ? "None" : visibleToCodes.join(', ');
    return NeonContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Label & Actions
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.formLink.label ?? 'Form Link',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: "Edit Link",
                color: AppColors.accent,
                onPressed: () {
                  dynamic editFormLink(FormLink fl) {
                    FormLinkController().updateFormLink(context, fl);
                  }

                  showFormLinkModal(
                    context,
                    eventId: widget.formLink.eventId,
                    onSubmit: editFormLink,
                    formLink: widget.formLink,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                tooltip: "Delete Link",
                color: AppColors.error,
                onPressed: () {
                  confirmDeletionModal(
                    context,
                    'Form Link',
                    onSubmit: () {
                      FormLinkController().deleteFormLink(
                        context,
                        widget.formLink.id,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          /// Link
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(widget.formLink.link)),
            child: Text(
              widget.formLink.link,
              style: const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),

          /// Visible To
          Text(
            "Visible to: $visibleToString",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
