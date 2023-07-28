import 'dart:convert';

GetPackAndScanResponse getPackAndScanResponseFromJson(String str) => GetPackAndScanResponse.fromJson(json.decode(str));

String getPackAndScanResponseToJson(GetPackAndScanResponse data) => json.encode(data.toJson());

class GetPackAndScanResponse {
  List<Sku> sku;

  GetPackAndScanResponse({
    required this.sku,
  });

  factory GetPackAndScanResponse.fromJson(Map<String, dynamic> json) => GetPackAndScanResponse(
    sku: List<Sku>.from(json["Sku"].map((x) => Sku.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Sku": List<dynamic>.from(sku.map((x) => x.toJson())),
  };
}

class Sku {
  int id;
  String orderNumber;
  String siteOrderId;
  String sku;
  String title;
  String warehouseLocation;
  String ean;
  String url;
  String siteName;
  String qtyToPick;
  String shippingCarrier;
  String shippingClass;
  dynamic totalSkUs;
  dynamic pickedSkUs;
  dynamic isPicked;
  String packagingType;

  Sku({
    required this.id,
    required this.orderNumber,
    required this.siteOrderId,
    required this.sku,
    required this.title,
    required this.warehouseLocation,
    required this.ean,
    required this.url,
    required this.siteName,
    required this.qtyToPick,
    required this.shippingCarrier,
    required this.shippingClass,
    this.totalSkUs,
    this.pickedSkUs,
    this.isPicked,
    required this.packagingType
  });

  factory Sku.fromJson(Map<String, dynamic> json) => Sku(
    id: json["Id"],
    orderNumber: json["OrderNumber"],
    siteOrderId: json["SiteOrderId"],
    sku: json["sku"],
    title: json["title"],
    warehouseLocation: json["WarehouseLocation"],
    ean: json["ean"],
    url: json["url"],
    siteName: json["SiteName"],
    qtyToPick: json["QtyToPick"],
    shippingCarrier: json["ShippingCarrier"],
    shippingClass: json["ShippingClass"],
    totalSkUs: json["TotalSKUs"],
    pickedSkUs: json["PickedSKUs"],
    isPicked: json["IsPicked"],
    packagingType: json["PackageType"] ?? ''
  );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "OrderNumber": orderNumber,
    "SiteOrderId": siteOrderId,
    "sku": sku,
    "title": title,
    "WarehouseLocation": warehouseLocation,
    "ean": ean,
    "url": url,
    "SiteName": siteName,
    "QtyToPick": qtyToPick,
    "ShippingCarrier": shippingCarrier,
    "ShippingClass": shippingClass,
    "TotalSKUs": totalSkUs,
    "PickedSKUs": pickedSkUs,
    "IsPicked": isPicked,
    "PackageType": packagingType,
  };
}
