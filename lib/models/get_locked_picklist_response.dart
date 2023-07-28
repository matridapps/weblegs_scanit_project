import 'dart:convert';

GetLockedPicklistResponse getLockedPicklistResponseFromJson(String str) =>
    GetLockedPicklistResponse.fromJson(json.decode(str));

String getLockedPicklistResponseToJson(GetLockedPicklistResponse data) =>
    json.encode(data.toJson());

class GetLockedPicklistResponse {
  List<MessageXX> message;

  GetLockedPicklistResponse({
    required this.message,
  });

  factory GetLockedPicklistResponse.fromJson(Map<String, dynamic> json) =>
      GetLockedPicklistResponse(
        message: List<MessageXX>.from(
            json["message"].map((x) => MessageXX.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "message": List<dynamic>.from(message.map((x) => x.toJson())),
      };
}

class MessageXX {
  String id;
  String batchId;
  String userName;
  String createdDate;

  MessageXX({
    required this.id,
    required this.batchId,
    required this.userName,
    required this.createdDate,
  });

  factory MessageXX.fromJson(Map<String, dynamic> json) => MessageXX(
        id: json["id"],
        batchId: json["BatchId"],
        userName: json["UserName"],
        createdDate: json["CreatedOn"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "BatchId": batchId,
        "UserName": userName,
        "CreatedOn": createdDate,
      };
}
