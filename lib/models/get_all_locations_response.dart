import 'dart:convert';

GetAllLocationsResponse getAllLocationsResponseFromJson(String str) => GetAllLocationsResponse.fromJson(json.decode(str));

String getAllLocationsResponseToJson(GetAllLocationsResponse data) => json.encode(data.toJson());

class GetAllLocationsResponse {
  GetAllLocationsResponse({
    required this.result,
  });

  final List<AllLocationsResult> result;

  GetAllLocationsResponse copyWith({
    required List<AllLocationsResult> result,
  }) =>
      GetAllLocationsResponse(
        result: result ?? this.result,
      );

  factory GetAllLocationsResponse.fromJson(Map<String, dynamic> json) => GetAllLocationsResponse(
    result: List<AllLocationsResult>.from(json["Result"].map((x) => AllLocationsResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class AllLocationsResult {
  AllLocationsResult({
    required this.location,
  });

  final String location;

  AllLocationsResult copyWith({
    required String location,
  }) =>
      AllLocationsResult(
        location: location ?? this.location,
      );

  factory AllLocationsResult.fromJson(Map<String, dynamic> json) => AllLocationsResult(
    location: json["Location"],
  );

  Map<String, dynamic> toJson() => {
    "Location": location,
  };
}
