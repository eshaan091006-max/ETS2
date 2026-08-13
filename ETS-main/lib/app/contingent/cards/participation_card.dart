import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/cards/event_card.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/utils/marks_format.dart';

class ParticipationCard extends StatelessWidget {
  final Participation participation;
  final Event event;

  /// Which of the contingent's entries in this event this card shows.
  ///
  /// 0 means it is the only entry, so no label is drawn.
  final int entryNumber;

  const ParticipationCard({
    super.key,
    required this.participation,
    required this.event,
    this.entryNumber = 0,
  });

  double _getPercentage() {
    if (participation.marksScored == -1 || event.highestMarks <= 0) return -1;
    return participation.marksScored / event.highestMarks;
  }

  Color _getGradientColor(double percent) {
    if (percent < 0) return Colors.grey.shade400;

    // Red (low) to Yellow (mid) to Green (high)
    return Color.lerp(
      percent < 0.5 ? Colors.red : Colors.yellow,
      percent < 0.5 ? Colors.yellow : Colors.green,
      percent < 0.5 ? percent * 2 : (percent - 0.5) * 2,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final double percent = _getPercentage();
    final Color markColor = _getGradientColor(percent);

    return NeonContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Entry label, shown only when this event holds more than one
            /// of the contingent's entries
            if (entryNumber > 0) ...[
              buildEntryChip(entryNumber),
              const SizedBox(height: 10),
            ],

            /// Marks Scored Box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(
                  'Marks Scored',
                  participation.marksScored,
                  markColor,
                ),
                _buildMetric('Highest Marks', event.highestMarks, markColor),
              ],
            ),

            const SizedBox(height: 12),

            /// EventCard below (reused)
            EventCard(event: event),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        border: Border.all(color: color.withAlpha(128)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            formatMarks(value),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
