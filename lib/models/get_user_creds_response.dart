import 'dart:convert';

List<GetUserCredsResponse> getUserCredsResponseFromJson(String str) =>
    List<GetUserCredsResponse>.from(
        json.decode(str).map((x) => GetUserCredsResponse.fromJson(x)));

String getUserCredsResponseToJson(List<GetUserCredsResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetUserCredsResponse {
  GetUserCredsResponse({
    required this.srNo,
    required this.userId,
    required this.password,
    required this.accountType,
    required this.authorization,
    required this.refreshToken,
    required this.profileId,
    required this.distributionCenterId,
    required this.distributionCenterName,
  });

  final int srNo;
  final String userId;
  final String password;
  final String accountType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final int distributionCenterId;
  final String distributionCenterName;

  GetUserCredsResponse copyWith({
    required int srNo,
    required String userId,
    required String password,
    required String accountType,
    required String authorization,
    required String refreshToken,
    required int profileId,
    required int distributionCenterId,
    required String distributionCenterName,
  }) =>
      GetUserCredsResponse(
        srNo: srNo ?? this.srNo,
        userId: userId ?? this.userId,
        password: password ?? this.password,
        accountType: accountType ?? this.accountType,
        authorization: authorization ?? this.authorization,
        refreshToken: refreshToken ?? this.refreshToken,
        profileId: profileId ?? this.profileId,
        distributionCenterId: distributionCenterId ?? this.distributionCenterId,
        distributionCenterName:
            distributionCenterName ?? this.distributionCenterName,
      );

  factory GetUserCredsResponse.fromJson(Map<String, dynamic> json) =>
      GetUserCredsResponse(
        srNo: json["sr_no"],
        userId: json["user_id"],
        password: json["password"],
        accountType: json["account_type"],
        authorization: json["authorization"],
        refreshToken: json["refresh_token"],
        profileId: json["profile_id"],
        distributionCenterId: json["distribution_center_id"],
        distributionCenterName: json["distribution_center_name"],
      );

  Map<String, dynamic> toJson() => {
        "sr_no": srNo,
        "user_id": userId,
        "password": password,
        "account_type": accountType,
        "authorization": authorization,
        "refresh_token": refreshToken,
        "profile_id": profileId,
        "distribution_center_id": distributionCenterId,
        "distribution_center_name": distributionCenterName,
      };
}
