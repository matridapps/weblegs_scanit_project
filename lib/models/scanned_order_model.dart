import 'dart:convert';

class ScannedOrderModel {
  final String picklistType;
  final String title;
  final String sku;
  final String barcode;
  final String orderNumber;
  final String qtyToPick;
  final String url;
  final String siteOrderId;
  final String siteName;
  final String labelError;
  final String labelUrl;
  final String? packagingType;

  ScannedOrderModel({
    required this.picklistType,
    required this.title,
    required this.sku,
    required this.barcode,
    required this.orderNumber,
    required this.qtyToPick,
    required this.url,
    required this.siteOrderId,
    required this.siteName,
    required this.labelError,
    required this.labelUrl,
    this.packagingType,
  });

  factory ScannedOrderModel.fromJson(Map<String, dynamic> jsonData) {
    return ScannedOrderModel(
      picklistType: jsonData['PicklistType'] ?? '',
      title: jsonData['title'] ?? '',
      sku: jsonData['sku'] ?? '',
      barcode: jsonData['ean'] ?? '',
      orderNumber: jsonData['OrderNumber'] ?? '',
      qtyToPick: jsonData['QtyToPick'] ?? '',
      url: jsonData['url'] ?? '',
      siteOrderId: jsonData['SiteOrderId'] ?? '',
      siteName: jsonData['SiteName'] ?? '',
      labelError: jsonData['LabelError'] ?? '',
      labelUrl: jsonData['LabelUrl'] ?? '',
      packagingType: jsonData['PackagingType'] ?? 'NA',
    );
  }

  static Map<String, dynamic> toMap(ScannedOrderModel scannedOrderModel) {
    return {
      'PicklistType': scannedOrderModel.picklistType,
      'title': scannedOrderModel.title,
      'sku': scannedOrderModel.sku,
      'ean': scannedOrderModel.barcode,
      'OrderNumber': scannedOrderModel.orderNumber,
      'QtyToPick': scannedOrderModel.qtyToPick,
      'url': scannedOrderModel.url,
      'SiteOrderId': scannedOrderModel.siteOrderId,
      'SiteName': scannedOrderModel.siteName,
      'LabelError': scannedOrderModel.labelError,
      'LabelUrl': scannedOrderModel.labelUrl,
      'PackagingType': scannedOrderModel.packagingType,
    };
  }

  static String encode(List<ScannedOrderModel> scannedOrderModels) {
    return json.encode(
      scannedOrderModels
          .map<Map<String, dynamic>>((value) => ScannedOrderModel.toMap(value))
          .toList(),
    );
  }

  static List<ScannedOrderModel> decode(String scannedOrderModels) {
    return (json.decode(scannedOrderModels) as List<dynamic>)
        .map<ScannedOrderModel>((item) => ScannedOrderModel.fromJson(item))
        .toList();
  }
}
