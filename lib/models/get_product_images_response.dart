import 'dart:convert';

GetProductImagesResponse getProductImagesResponseFromJson(String str) =>
    GetProductImagesResponse.fromJson(json.decode(str));

String getProductImagesResponseToJson(GetProductImagesResponse data) =>
    json.encode(data.toJson());

class GetProductImagesResponse {
  GetProductImagesResponse({
    required this.value,
  });

  final List<ImageValue> value;

  GetProductImagesResponse copyWith({
    required List<ImageValue> value,
  }) =>
      GetProductImagesResponse(
        value: value ?? this.value,
      );

  factory GetProductImagesResponse.fromJson(Map<String, dynamic> json) =>
      GetProductImagesResponse(
        value: List<ImageValue>.from(
            json["value"].map((x) => ImageValue.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "value": List<dynamic>.from(value.map((x) => x.toJson())),
      };
}

class ImageValue {
  ImageValue({
    required this.productId,
    required this.profileId,
    required this.placementName,
    required this.abbreviation,
    required this.url,
  });

  final int productId;
  final int profileId;
  final String placementName;
  final String abbreviation;
  final String url;

  ImageValue copyWith({
    required int productId,
    required int profileId,
    required String placementName,
    required String abbreviation,
    required String url,
  }) =>
      ImageValue(
        productId: productId ?? this.productId,
        profileId: profileId ?? this.profileId,
        placementName: placementName ?? this.placementName,
        abbreviation: abbreviation ?? this.abbreviation,
        url: url ?? this.url,
      );

  factory ImageValue.fromJson(Map<String, dynamic> json) => ImageValue(
        productId: json["ProductID"],
        profileId: json["ProfileID"],
        placementName: json["PlacementName"],
        abbreviation: json["Abbreviation"],
        url: json["Url"],
      );

  Map<String, dynamic> toJson() => {
        "ProductID": productId,
        "ProfileID": profileId,
        "PlacementName": placementName,
        "Abbreviation": abbreviation,
        "Url": url,
      };
}
