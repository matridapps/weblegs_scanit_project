import 'dart:convert';

GetProductQuantityResponse getProductQuantityResponseFromJson(String str) =>
    GetProductQuantityResponse.fromJson(json.decode(str));

String getProductQuantityResponseToJson(GetProductQuantityResponse data) =>
    json.encode(data.toJson());

class GetProductQuantityResponse {
  GetProductQuantityResponse({
    required this.odataContext,
    required this.value,
  });

  final String odataContext;
  final List<QuantityValue> value;

  GetProductQuantityResponse copyWith({
    required String odataContext,
    required List<QuantityValue> value,
  }) =>
      GetProductQuantityResponse(
        odataContext: odataContext ?? this.odataContext,
        value: value ?? this.value,
      );

  factory GetProductQuantityResponse.fromJson(Map<String, dynamic> json) =>
      GetProductQuantityResponse(
        odataContext: json["@odata.context"],
        value: List<QuantityValue>.from(json["value"].map((x) => QuantityValue.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "@odata.context": odataContext,
        "value": List<dynamic>.from(value.map((x) => x.toJson())),
      };
}

class QuantityValue {
  QuantityValue({
    required this.productId,
    required this.profileId,
    required this.distributionCenterId,
    required this.availableQuantity,
  });

  final int productId;
  final int profileId;
  final int distributionCenterId;
  final int availableQuantity;

  QuantityValue copyWith({
    required int productId,
    required int profileId,
    required int distributionCenterId,
    required int availableQuantity,
  }) =>
      QuantityValue(
        productId: productId ?? this.productId,
        profileId: profileId ?? this.profileId,
        distributionCenterId: distributionCenterId ?? this.distributionCenterId,
        availableQuantity: availableQuantity ?? this.availableQuantity,
      );

  factory QuantityValue.fromJson(Map<String, dynamic> json) => QuantityValue(
        productId: json["ProductID"],
        profileId: json["ProfileID"],
        distributionCenterId: json["DistributionCenterID"],
        availableQuantity: json["AvailableQuantity"],
      );

  Map<String, dynamic> toJson() => {
        "ProductID": productId,
        "ProfileID": profileId,
        "DistributionCenterID": distributionCenterId,
        "AvailableQuantity": availableQuantity,
      };
}
