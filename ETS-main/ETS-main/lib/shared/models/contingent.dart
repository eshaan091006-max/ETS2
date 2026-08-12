import 'dart:convert';

List<Contingent> contingentFromJson(String str) =>
    List<Contingent>.from(json.decode(str).map((x) => Contingent.fromJson(x)));

String contingentToJson(List<Contingent> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Contingent {
  int contingentId;
  String contingentCode;
  String password;
  int resetCount;

  Contingent({
    this.contingentId = -1,
    this.contingentCode = "NA",
    this.password = "NA",
    this.resetCount = 3,
  });

  factory Contingent.fromJson(Map<String, dynamic> json) {
    return Contingent(
      contingentId: json['contingent_id'],
      contingentCode: json['contingent_code'],
      password: json['password'],
      resetCount: json['reset_count'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    "contingent_id": contingentId,
    "contingent_code": contingentCode,
    "password": password,
    "reset_count": resetCount,
  };

  Map<String, dynamic> toInsertJson() => {
    "contingent_id": contingentId,
    "contingent_code": contingentCode,
    "password": password,
    "reset_count": resetCount,
  };
}
