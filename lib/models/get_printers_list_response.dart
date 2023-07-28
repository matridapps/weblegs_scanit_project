import 'dart:convert';

List<GetPrintersListResponse> getPrintersListResponseFromJson(String str) =>
    List<GetPrintersListResponse>.from(
        json.decode(str).map((x) => GetPrintersListResponse.fromJson(x)));

String getPrintersListResponseToJson(List<GetPrintersListResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetPrintersListResponse {
  bool getPrintersListResponseDefault;
  String description;
  int id;
  String name;
  String state;

  GetPrintersListResponse({
    required this.getPrintersListResponseDefault,
    required this.description,
    required this.id,
    required this.name,
    required this.state,
  });

  factory GetPrintersListResponse.fromJson(Map<String, dynamic> json) =>
      GetPrintersListResponse(
        getPrintersListResponseDefault: json["default"],
        description: json["description"],
        id: json["id"],
        name: json["name"],
        state: json["state"],
      );

  Map<String, dynamic> toJson() => {
        "default": getPrintersListResponseDefault,
        "description": description,
        "id": id,
        "name": name,
        "state": state,
      };
}
