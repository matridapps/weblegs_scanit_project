import 'dart:convert';

GetOrderDetailsWithLabelResponse getOrderDetailsWithLabelResponseFromJson(String str) => GetOrderDetailsWithLabelResponse.fromJson(json.decode(str));

String getOrderDetailsWithLabelResponseToJson(GetOrderDetailsWithLabelResponse data) => json.encode(data.toJson());

class GetOrderDetailsWithLabelResponse {
  String orderId;
  String shipmentId;
  String trackingId;
  String labelUrl;
  String pdfLabelUrl;
  dynamic base64;
  List<PickedOrderXX> pickedOrder;

  GetOrderDetailsWithLabelResponse({
    required this.orderId,
    required this.shipmentId,
    required this.trackingId,
    required this.labelUrl,
    required this.pdfLabelUrl,
    this.base64,
    required this.pickedOrder,
  });

  factory GetOrderDetailsWithLabelResponse.fromJson(Map<String, dynamic> json) => GetOrderDetailsWithLabelResponse(
    orderId: json["OrderId"],
    shipmentId: json["ShipmentId"],
    trackingId: json["TrackingId"],
    labelUrl: json["LabelUrl"],
    pdfLabelUrl: json["PdfLabelUrl"],
    base64: json["Base64"],
    pickedOrder: List<PickedOrderXX>.from(json["pickedOrder"].map((x) => PickedOrderXX.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "OrderId": orderId,
    "ShipmentId": shipmentId,
    "TrackingId": trackingId,
    "LabelUrl": labelUrl,
    "PdfLabelUrl": pdfLabelUrl,
    "Base64": base64,
    "pickedOrder": List<dynamic>.from(pickedOrder.map((x) => x.toJson())),
  };
}

class PickedOrderXX {
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
  String packageType;

  PickedOrderXX({
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
    required this.packageType,
  });

  factory PickedOrderXX.fromJson(Map<String, dynamic> json) => PickedOrderXX(
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
    packageType: json["PackageType"],
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
    "PackageType": packageType,
  };
}
