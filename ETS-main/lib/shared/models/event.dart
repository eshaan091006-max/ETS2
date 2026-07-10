import 'dart:convert';

import 'package:intl/intl.dart';

List<Event> eventFromJson(String str) =>
    List<Event>.from(json.decode(str).map((x) => Event.fromJson(x)));

String eventToJson(List<Event> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Event {
  int eventId;
  String eventName;
  int highestMarks;
  DateTime dateTime;
  int departmentId;
  int eventType;
  String formLink;
  int elimsType;
  List<int> collabDeptIds;

  Event({
    this.eventId = -1,
    this.eventName = "NA",
    this.highestMarks = -1,
    required this.dateTime,
    this.departmentId = -1,
    this.eventType = 0,
    this.formLink = "https://docs.google.com/forms",
    this.elimsType = 0,
    this.collabDeptIds = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime parsedDateTime = DateTime.now();
    try {
      final dateStr = json['date_string']?.toString();
      final timeStr = json['time_string']?.toString();
      if (dateStr != null && dateStr != '-' && timeStr != null && timeStr != '-') {
        parsedDateTime = DateFormat('dd MMM yyyy hh:mm a').parse('$dateStr $timeStr');
      } else if (dateStr != null && dateStr != '-') {
        parsedDateTime = DateFormat('dd MMM yyyy').parse(dateStr);
      }
    } catch (e) {
      print("Error parsing event datetime: $e");
    }
    return Event(
      eventId: json['event_id'],
      eventName: json['event_name'].toString(),
      highestMarks: json['highest_marks'] ?? -1,
      dateTime: parsedDateTime,
      departmentId: json['department_id'] ?? -1,
      eventType: json['event_type'] ?? 0,
      formLink: json['form_link'] ?? '',
      elimsType: json['elims_type'] ?? 0,
      collabDeptIds: List<int>.from(json['collab_dept_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    "event_id": eventId,
    "event_name": eventName,
    "highest_marks": highestMarks,
    "date_string": DateFormat('dd MMM yyyy').format(dateTime),
    "time_string": DateFormat('hh:mm a').format(dateTime),
    "department_id": departmentId,
    "event_type": eventType,
    "elims_type": elimsType,
    "collab_dept_ids": collabDeptIds,
  };

  Map<String, dynamic> toInsertJson() => {
    "event_id": eventId,
    "event_name": eventName,
    "highest_marks": highestMarks,
    "date_string": DateFormat('dd MMM yyyy').format(dateTime),
    "time_string": DateFormat('hh:mm a').format(dateTime),
    "department_id": departmentId,
    "event_type": eventType,
    "elims_type": elimsType,
    "collab_dept_ids": collabDeptIds,
  };

  String get dateString =>
      (dateTime.year == 2006 && dateTime.month == 2 && dateTime.day == 10)
          ? '-'
          : DateFormat('dd MMM yyyy').format(dateTime);

  String get timeString =>
      (dateTime.hour == 15 && dateTime.minute == 43 && dateTime.second == 0)
          ? '-'
          : DateFormat('hh:mm a').format(dateTime);
}
