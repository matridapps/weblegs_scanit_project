import 'dart:convert';

GetUpdatedLocationResponse getUpdatedLocationResponseFromJson(String str) =>
    GetUpdatedLocationResponse.fromJson(json.decode(str));

String getUpdatedLocationResponseToJson(GetUpdatedLocationResponse data) =>
    json.encode(data.toJson());

class GetUpdatedLocationResponse {
  GetUpdatedLocationResponse({
    required this.result,
  });

  final List<LocationResult> result;

  GetUpdatedLocationResponse copyWith({
    required List<LocationResult> result,
  }) =>
      GetUpdatedLocationResponse(
        result: result ?? this.result,
      );

  factory GetUpdatedLocationResponse.fromJson(Map<String, dynamic> json) =>
      GetUpdatedLocationResponse(
        result:
            List<LocationResult>.from(json["Result"].map((x) => LocationResult.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Result": List<dynamic>.from(result.map((x) => x.toJson())),
      };
}

class LocationResult {
  LocationResult({
    required this.warehouseLocation,
  });

  final String warehouseLocation;

  LocationResult copyWith({
    required String warehouseLocation,
  }) =>
      LocationResult(
        warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      );

  factory LocationResult.fromJson(Map<String, dynamic> json) => LocationResult(
        warehouseLocation: json["WarehouseLocation"],
      );

  Map<String, dynamic> toJson() => {
        "WarehouseLocation": warehouseLocation,
      };
}
