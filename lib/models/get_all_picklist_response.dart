import 'dart:convert';

GetAllPicklistResponse getAllPicklistResponseFromJson(String str) =>
    GetAllPicklistResponse.fromJson(json.decode(str));

String getAllPicklistResponseToJson(GetAllPicklistResponse data) =>
    json.encode(data.toJson());

class GetAllPicklistResponse {
  List<Batch> batch;
  dynamic sku;

  GetAllPicklistResponse({
    required this.batch,
    this.sku,
  });

  factory GetAllPicklistResponse.fromJson(Map<String, dynamic> json) =>
      GetAllPicklistResponse(
        batch: List<Batch>.from(json["Batch"].map((x) => Batch.fromJson(x))),
        sku: json["Sku"],
      );

  Map<String, dynamic> toJson() => {
        "Batch": List<dynamic>.from(batch.map((x) => x.toJson())),
        "Sku": sku,
      };
}

class Batch {
  String picklist;
  String batchId;
  String createdOn;
  String requestType;
  String status;
  String pickedsku;
  String totalsku;
  String pickedorder;
  String totalorder;
  String partialSkus;
  String partialOrders;
  String isAlreadyOpened;

  Batch({
    required this.picklist,
    required this.batchId,
    required this.createdOn,
    required this.requestType,
    required this.status,
    required this.pickedsku,
    required this.totalsku,
    required this.pickedorder,
    required this.totalorder,
    required this.partialSkus,
    required this.partialOrders,
    required this.isAlreadyOpened,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
        picklist: json["Picklist"] ?? 'null',
        batchId: json["BatchId"],
        createdOn: json["CreatedOn"],
        requestType: json["Request_Type"],
        status: json["status"],
        pickedsku: json["pickedsku"],
        totalsku: json["totalsku"],
        pickedorder: json["pickedorder"],
        totalorder: json["totalorder"],
        partialSkus: json["partialSkus"],
        partialOrders: json["partialOrders"],
        isAlreadyOpened: json["IsAlreadyOpened"],
      );

  Map<String, dynamic> toJson() => {
        "Picklist": picklist,
        "BatchId": batchId,
        "CreatedOn": createdOn,
        "Request_Type": requestType,
        "status": status,
        "pickedsku": pickedsku,
        "totalsku": totalsku,
        "pickedorder": pickedorder,
        "totalorder": totalorder,
        "partialSkus": partialSkus,
        "partialOrders": partialOrders,
        "IsAlreadyOpened": isAlreadyOpened,
      };
}
