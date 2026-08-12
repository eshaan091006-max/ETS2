import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/cards/form_link_card.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Contingent? contingent;

  const EventCard({super.key, required this.event, this.contingent});

  @override
  Widget build(BuildContext context) {
    final bool isFlagship = event.eventType == 1;

    return NeonContainer(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Type badge
            Row(
              children: [
                /// Event Name with ellipsis if it overflows
                Expanded(
                  child: Text(
                    event.eventName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isFlagship ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 8), // spacing between text and chip
                /// Flagship / Classic Tag
                if (event.eventType == 0 || event.eventType == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isFlagship
                              ? Colors.amber.shade800
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFlagship ? "FLAGSHIP" : "CLASSIC",
                      style: GoogleFonts.poppins(
                        color: isFlagship ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),

            /// Collaborating domains display
            if (event.collabDeptIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: event.collabDeptIds.map((deptId) {
                  final dept = DepartmentController().getDepartmentById(deptId);
                  if (dept == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFlagship ? Colors.white24 : AppColors.primary.withAlpha(25),
                      border: Border.all(color: isFlagship ? Colors.white30 : AppColors.primary.withAlpha(80), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dept.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isFlagship ? Colors.white70 : AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 6),



            /// Format / Elims format
            Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: isFlagship ? Colors.white70 : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  event.elimsType == 0
                      ? "Direct Finals"
                      : event.elimsType == 1
                          ? "Online Elims + Offline Finals"
                          : "Offline Elims + Offline Finals",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Form link preview (if provided)
            if (contingent != null)
              FormLinksCard(
                formLinks: FormLinkController().formLinks,
                eventId: event.eventId,
                contingentId: contingent!.contingentId,
              ),

            // if (event.formLink.isNotEmpty)
            //   Row(
            //     children: [
            //       Icon(
            //         Icons.link,
            //         size: 16,
            //         color: isFlagship ? Colors.white70 : Colors.blue,
            //       ),
            //       const SizedBox(width: 6),
            //       Flexible(
            //         child: Text(
            //           event.formLink,
            //           maxLines: 1,
            //           overflow: TextOverflow.ellipsis,
            //           style: GoogleFonts.poppins(
            //             fontSize: 13,
            //             color: isFlagship ? Colors.white70 : Colors.blue,
            //             decoration: TextDecoration.underline,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
          ],
        ),
      ),
    );
  }
}
