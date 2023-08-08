import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/shop_replinsh_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:absolute_app/core/utils/app_export.dart';

class ApiCalls {
  static int expiryTime = 0;

  ApiCalls._();

  static Future<String> tokenAPI(
      {required String refreshToken, required String authorization}) async {
    String uri = 'https://api.channeladvisor.com/oauth2/token';
    log('Token Uri - $uri');

    final body = {
      "grant_type": "refresh_token",
      "refresh_token": refreshToken,
    };

    try {
      var response = await http.post(
        Uri.parse(uri),
        body: body,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Cache-Control": "no-cache",
          "Authorization": authorization
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('token response - ${jsonDecode(response.body)}');

        expiryTime =
            int.parse(jsonDecode(response.body)['expires_in'].toString());
        log('expiryTime - $expiryTime');
        return jsonDecode(response.body)['access_token'].toString();
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      return kerrorString;
    }
  }

  static Future<String> tokenAPIWeb() async {
    String uri = 'https://weblegs.info/JadlamApp/api/Token';
    log('Token Uri Web- $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('token response web- ${jsonDecode(response.body)}');
        return jsonDecode(response.body)['data']['access_token'].toString();
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      return kerrorString;
    }
  }

  static Future<String> getProductDetails(
      {required String ean,
      required String accountType,
      required String location}) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/Search2?EAN=$ean&Location=$location&AccountType=$accountType';
    log('Product details uri - $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");

          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product details response - ${jsonDecode(response.body)}');
        return response.body;
      } else if (response.statusCode == 500) {
        log('error response product details - ${response.body}');

        ToastUtils.showCenteredLongToast(
            message: jsonDecode(response.body)['message'].toString());

        return jsonDecode(response.body)['message'].toString();
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      return kerrorString;
    }
  }

  static Future<String> getUserCreds() async {
    String uri =
        'https://script.google.com/macros/s/AKfycbwW9hM30xPc1YAWn8h3yDmf9tym7wcG68qO4ngeHxz0liXVsU1fvmvA1o5p7_zly_EL/exec';
    log('get creds uri - $uri');

    try {
      var request = http.Request('GET', Uri.parse(uri));

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        log('result - $result');
        return result;
      } else {
        log("${response.reasonPhrase}");
        return kerrorString;
      }
    } catch (e) {
      log(e.toString());
      return kerrorString;
    }
  }

  static Future<String> getProductImages(
      {required String accessToken,
      required String productId,
      required int profileId}) async {
    String uri =
        'https://api.channeladvisor.com/v1/Images?$kAccessToken$accessToken&${kFilter}ProfileId eq $profileId and $kAbbreviation and ProductID eq $productId';
    log('get Product Images uri - $uri');

    var header = {
      "origin": "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");

          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product details response - ${jsonDecode(response.body)}');
        return response.body;
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      return kerrorString;
    }
  }

  static Future<List<ParseObject>> getWeblegsData() async {
    QueryBuilder<ParseObject> queryWeblegsData =
        QueryBuilder<ParseObject>(ParseObject('Weblegs_Data'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getWeblegsShippingRules() async {
    QueryBuilder<ParseObject> queryWeblegsData =
        QueryBuilder<ParseObject>(ParseObject('Weblegs_Shipping_Rules'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getShippingRulesList() async {
    QueryBuilder<ParseObject> queryWeblegsData =
    QueryBuilder<ParseObject>(ParseObject('Shipping_Rules_List'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getLabelPrintingData() async {
    QueryBuilder<ParseObject> queryWeblegsData =
    QueryBuilder<ParseObject>(ParseObject('label_printing_data'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getPicklistsData() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('picklists_data'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getLabelsDataPackAndScan() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('labels_data_pack_and_scan'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getDefaultValuesForSKU() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('default_values_for_sku'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getSiteNameList() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('site_name_list'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getPrintNodeData() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('PrintNodeData'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<List<ParseObject>> getChangelogData() async {
    QueryBuilder<ParseObject> queryWeblegsData = QueryBuilder<ParseObject>(ParseObject('Changelog'));
    final ParseResponse apiResponse = await queryWeblegsData.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      log('No data');
      return [];
    }
  }

  static Future<String> getAllLocations(String accType) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/Location?AccountType=$accType';
    log('getAllLocations uri - $uri');
    try {
      var response = await http.get(Uri.parse(uri));
      log('getAllLocations response - ${jsonDecode(response.body)}');
      return response.body;
    } on Exception catch (e) {
      log(e.toString());
      Fluttertoast.showToast(
          msg: 'Location data is not loaded.', toastLength: Toast.LENGTH_SHORT);
      return '';
    }
  }

  /// Api Methods by Vishal
  static Future<List<ShopReplenishSku>> returnShopReplenishList() async {
    Uri uri = Uri.parse('https://weblegs.info/JadlamApp/api/GetShopReplenishSKU');
    final response = await http.get(uri);
    return shopReplenishModelFromJson(response.body).sku;
  }
}
