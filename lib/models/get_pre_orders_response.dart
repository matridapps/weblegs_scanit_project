import 'dart:convert';

GetPreOrdersResponse getPreOrdersResponseFromJson(String str) =>
    GetPreOrdersResponse.fromJson(json.decode(str));

String getPreOrdersResponseToJson(GetPreOrdersResponse data) =>
    json.encode(data.toJson());

class GetPreOrdersResponse {
  List<SkuPreOrders> sku;

  GetPreOrdersResponse({
    required this.sku,
  });

  factory GetPreOrdersResponse.fromJson(Map<String, dynamic> json) =>
      GetPreOrdersResponse(
        sku: List<SkuPreOrders>.from(
            json["Sku"].map((x) => SkuPreOrders.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Sku": List<dynamic>.from(sku.map((x) => x.toJson())),
      };
}

class SkuPreOrders {
  String orderNumber;
  String siteOrderId;
  String sku;
  String title;
  String warehouseLocation;
  String ean;
  String quantity;
  String orderDate;
  String imageUrl;

  SkuPreOrders({
    required this.orderNumber,
    required this.siteOrderId,
    required this.sku,
    required this.title,
    required this.warehouseLocation,
    required this.ean,
    required this.quantity,
    required this.orderDate,
    required this.imageUrl,
  });

  factory SkuPreOrders.fromJson(Map<String, dynamic> json) => SkuPreOrders(
        orderNumber: json["OrderNumber"],
        siteOrderId: json["SiteOrderId"],
        sku: json["sku"],
        title: json["title"],
        warehouseLocation: json["WarehouseLocation"],
        ean: json["ean"],
        quantity: json["Quantity"],
        orderDate: json["OrderDate"],
        imageUrl: json["ImageUrl"],
      );

  Map<String, dynamic> toJson() => {
        "OrderNumber": orderNumber,
        "SiteOrderId": siteOrderId,
        "sku": sku,
        "title": title,
        "WarehouseLocation": warehouseLocation,
        "ean": ean,
        "Quantity": quantity,
        "OrderDate": orderDate,
        "ImageUrl": imageUrl,
      };
}
