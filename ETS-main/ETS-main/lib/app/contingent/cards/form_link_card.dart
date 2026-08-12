import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:url_launcher/url_launcher.dart';

class FormLinksCard extends StatelessWidget {
  final List<FormLink> formLinks;
  final int eventId;
  final int contingentId;

  const FormLinksCard({
    required this.formLinks,
    required this.eventId,
    required this.contingentId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visibleLinks =
        formLinks
            .where(
              (link) =>
                  link.eventId == eventId &&
                  link.visibleTo.contains(contingentId),
            )
            .toList();

    if (visibleLinks.isEmpty) return const SizedBox();

    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Form Links',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                visibleLinks.map((link) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(link.link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid URL')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      splashColor: AppColors.accent.withAlpha(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(70),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.open_in_new,
                              size: 20,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                link.label ?? 'Unnamed Link',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
