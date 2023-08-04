import 'dart:convert';

ShopReplenishModel shopReplenishModelFromJson(String str) =>
    ShopReplenishModel.fromJson(json.decode(str));

String shopReplenishModelToJson(ShopReplenishModel data) =>
    json.encode(data.toJson());

class ShopReplenishModel {
  final List<ShopReplenishSku> sku;

  ShopReplenishModel({
    required this.sku,
  });

  factory ShopReplenishModel.fromJson(Map<String, dynamic> json) =>
      ShopReplenishModel(
        sku: List<ShopReplenishSku>.from(json["Sku"].map((x) => ShopReplenishSku.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Sku": List<dynamic>.from(sku.map((x) => x.toJson())),
      };
}

class ShopReplenishSku {
  final String ean;
  final String packageType;
  final String parentSku;
  final String productType;
  final String sku;
  final String title;
  final String warehouseLocation;
  final String url;
  final String quantity;

  ShopReplenishSku({
    required this.ean,
    required this.packageType,
    required this.parentSku,
    required this.productType,
    required this.sku,
    required this.title,
    required this.warehouseLocation,
    required this.url,
    required this.quantity,
  });

  factory ShopReplenishSku.fromJson(Map<String, dynamic> json) => ShopReplenishSku(
        ean: json["EAN"],
        packageType: json["PackageType"]!,
        parentSku: json["ParentSku"],
        productType: json["ProductType"]!,
        sku: json["sku"],
        title: json["Title"],
        warehouseLocation: json["WarehouseLocation"],
        url: json["Url"],
        quantity: json["Quantity"],
      );

  Map<String, dynamic> toJson() => {
        "EAN": ean,
        "PackageType": packageType,
        "ParentSku": parentSku,
        "ProductType": productType,
        "sku": sku,
        "Title": title,
        "WarehouseLocation": warehouseLocation,
        "Url": url,
        "Quantity": quantity,
      };
}

