import 'dart:convert';

import 'package:malhar_ets/utils/marks_format.dart';

List<Participation> participationFromJson(String str) =>
    List<Participation>.from(
      json.decode(str).map((x) => Participation.fromJson(x)),
    );

String participationToJson(List<Participation> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Participation {
  int participationId;
  int contingentId;
  int eventId;
  double marksScored;

  Participation({
    required this.participationId,
    required this.contingentId,
    required this.eventId,
    this.marksScored = -1,
  });

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
      participationId: json['participation_id'],
      contingentId: json['contingent_id'],
      eventId: json['event_id'],
      // Postgres hands back an int for whole numeric values and a double
      // otherwise, so both have to be accepted here.
      marksScored: (json['marks_scored'] as num?)?.toDouble() ?? -1,
    );
  }

  /// Marks as shown to users: a dash when unmarked, no trailing ".0".
  String get marksDisplay => formatMarks(marksScored);

  Map<String, dynamic> toJson() => {
    "participation_id": participationId,
    "contingent_id": contingentId,
    "event_id": eventId,
    "marks_scored": marksScored,
  };

  Map<String, dynamic> toInsertJson() => {
    "participation_id": participationId,
    "contingent_id": contingentId,
    "event_id": eventId,
    "marks_scored": marksScored,
  };
}
