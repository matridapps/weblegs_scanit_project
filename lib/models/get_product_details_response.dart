import 'dart:convert';

GetProductDetailsResponse getProductDetailsResponseFromJson(String str) =>
    GetProductDetailsResponse.fromJson(json.decode(str));

String getProductDetailsResponseToJson(GetProductDetailsResponse data) =>
    json.encode(data.toJson());

class GetProductDetailsResponse {
  GetProductDetailsResponse({
    required this.result,
  });

  final List<Result> result;

  GetProductDetailsResponse copyWith({
    required List<Result> result,
  }) =>
      GetProductDetailsResponse(
        result: result ?? this.result,
      );

  factory GetProductDetailsResponse.fromJson(Map<String, dynamic> json) =>
      GetProductDetailsResponse(
        result:
            List<Result>.from(json["Result"].map((x) => Result.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Result": List<dynamic>.from(result.map((x) => x.toJson())),
      };
}

class Result {
  Result({
    required this.id,
    required this.ean,
    required this.sku,
    required this.title,
    required this.warehouseLocation,
    required this.url,
  });

  final String id;
  final String ean;
  final String sku;
  final String title;
  final String warehouseLocation;
  final String url;

  Result copyWith({
    required String id,
    required String ean,
    required String sku,
    required String title,
    required String warehouseLocation,
    required String url,
  }) =>
      Result(
        id: id ?? this.id,
        ean: ean ?? this.ean,
        sku: sku ?? this.sku,
        title: title ?? this.title,
        warehouseLocation: warehouseLocation ?? this.warehouseLocation,
        url: url ?? this.url,
      );

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["Id"] ?? '',
        ean: json["EAN"] ?? '',
        sku: json["SKU"] ?? '',
        title: json["Title"] ?? '',
        warehouseLocation: json["WarehouseLocation"] ?? '',
        url: json["Url"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "Id": id,
        "EAN": ean,
        "SKU": sku,
        "Title": title,
        "WarehouseLocation": warehouseLocation,
        "Url": url,
      };
}
