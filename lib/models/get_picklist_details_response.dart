import 'dart:convert';

GetPicklistDetailsResponse getPicklistDetailsResponseFromJson(String str) =>
    GetPicklistDetailsResponse.fromJson(json.decode(str));

String getPicklistDetailsResponseToJson(GetPicklistDetailsResponse data) =>
    json.encode(data.toJson());

class GetPicklistDetailsResponse {
  List<SkuXX> sku;
  dynamic shippingCarrierForSingleSku;
  dynamic shippingClassForSingleSku;
  dynamic orderForSingleSku;

  GetPicklistDetailsResponse({
    required this.sku,
    required this.shippingCarrierForSingleSku,
    required this.shippingClassForSingleSku,
    required this.orderForSingleSku,
  });

  factory GetPicklistDetailsResponse.fromJson(Map<String, dynamic> json) =>
      GetPicklistDetailsResponse(
        sku: List<SkuXX>.from(json["Sku"].map((x) => SkuXX.fromJson(x))),
        shippingCarrierForSingleSku: json["ShippingCarrierForSingleSku"],
        shippingClassForSingleSku: json["ShippingClassForSingleSku"],
        orderForSingleSku: json["OrderForSingleSku"],
      );

  Map<String, dynamic> toJson() => {
        "Sku": List<dynamic>.from(sku.map((x) => x.toJson())),
        "ShippingCarrierForSingleSku": shippingCarrierForSingleSku,
        "ShippingClassForSingleSku": shippingClassForSingleSku,
        "OrderForSingleSku": orderForSingleSku,
      };
}

class SkuXX {
  int id;
  String orderNumber;
  String siteOrderId;
  String sku;
  String title;
  String warehouseLocation;
  String ean;
  String url;
  String qtyToPick;
  String shippingCarrierForMsmqw;
  String shippingClassForMsmqw;
  List<OrderQuantity> orderQuantity;
  bool amazonLabelPrinted;
  bool easyPostLabelPrinted;
  String siteName;
  String distributionCenter;

  SkuXX({
    required this.id,
    required this.orderNumber,
    required this.siteOrderId,
    required this.sku,
    required this.title,
    required this.warehouseLocation,
    required this.ean,
    required this.url,
    required this.qtyToPick,
    required this.shippingCarrierForMsmqw,
    required this.shippingClassForMsmqw,
    required this.orderQuantity,
    required this.amazonLabelPrinted,
    required this.easyPostLabelPrinted,
    required this.siteName,
    required this.distributionCenter,
  });

  factory SkuXX.fromJson(Map<String, dynamic> json) => SkuXX(
        id: json["Id"],
        orderNumber: json["OrderNumber"],
        siteOrderId: json["SiteOrderId"],
        sku: json["sku"],
        title: json["title"],
        warehouseLocation: json["WarehouseLocation"],
        ean: json["ean"],
        url: json["url"],
        qtyToPick: json["QtyToPick"],
        shippingCarrierForMsmqw: json["ShippingCarrierForMSMQW"],
        shippingClassForMsmqw: json["ShippingClassForMSMQW"],
        orderQuantity: List<OrderQuantity>.from(
            json["OrderQuantity"].map((x) => OrderQuantity.fromJson(x))),
        amazonLabelPrinted: json["AmazonLabelPrinted"],
        easyPostLabelPrinted: json["EasyPostLabelPrinted"],
        siteName: json["SiteName"],
        distributionCenter: json["DistributionCenterCode"] ?? 'Not Available',
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
        "QtyToPick": qtyToPick,
        "ShippingCarrierForMSMQW": shippingCarrierForMsmqw,
        "ShippingClassForMSMQW": shippingClassForMsmqw,
        "OrderQuantity":
            List<dynamic>.from(orderQuantity.map((x) => x.toJson())),
        "AmazonLabelPrinted": amazonLabelPrinted,
        "EasyPostLabelPrinted": easyPostLabelPrinted,
        "SiteName": siteName,
        "DistributionCenterCode": distributionCenter,
      };
}

class OrderQuantity {
  int orderNumber;
  int quantity;
  String shippingClass;
  String shippingCarrier;
  bool amazonLabel;
  bool easyPostLabel;
  String siteName;
  String siteOrderId;
  String distributionCenter;

  OrderQuantity({
    required this.orderNumber,
    required this.quantity,
    required this.shippingClass,
    required this.shippingCarrier,
    required this.amazonLabel,
    required this.easyPostLabel,
    required this.siteName,
    required this.siteOrderId,
    required this.distributionCenter,
  });

  factory OrderQuantity.fromJson(Map<String, dynamic> json) => OrderQuantity(
        orderNumber: json["OrderNumber"],
        quantity: json["Quanity"],
        shippingClass: json["ShippingClass"],
        shippingCarrier: json["ShippingCarrier"],
        amazonLabel: json["AmazonLabel"],
        easyPostLabel: json["EasyPostLabel"],
        siteName: json["SiteName"],
        siteOrderId: json["SiteOrderId"],
        distributionCenter: json["DistributionCenterCode"],
      );

  Map<String, dynamic> toJson() => {
        "OrderNumber": orderNumber,
        "Quanity": quantity,
        "ShippingClass": shippingClass,
        "ShippingCarrier": shippingCarrier,
        "AmazonLabel": amazonLabel,
        "EasyPostLabel": easyPostLabel,
        "SiteName": siteName,
        "SiteOrderId": siteOrderId,
        "DistributionCenterCode": distributionCenter,
      };
}
