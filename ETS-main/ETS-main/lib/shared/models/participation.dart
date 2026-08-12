import 'dart:convert';

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
  int marksScored;

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
      marksScored: json['marks_scored'],
    );
  }

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
