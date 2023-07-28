import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/models/get_product_details_response.dart';
import 'package:absolute_app/models/get_product_images_response.dart';
import 'package:absolute_app/models/get_user_creds_response.dart';
import 'package:flutter/material.dart';

class BusinessLogic extends ChangeNotifier {
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  GetProductDetailsResponse _response = GetProductDetailsResponse(result: []);
  List<GetUserCredsResponse> _credsResponse = [];

  GetProductImagesResponse _imagesResponse =
      GetProductImagesResponse(value: []);

  GetProductImagesResponse get imagesResponse => _imagesResponse;

  List<GetUserCredsResponse> get credsResponse => _credsResponse;

  bool get isLoading => _isLoading;

  bool get isError => _isError;

  String get errorMessage => _errorMessage;

  GetProductDetailsResponse get productResponse => _response;

  Future<void> getProductData(
      {required String eanValue, required String accType, required String location}) async {
    _isLoading = true;
    _errorMessage = '';
    _isError = false;
    await ApiCalls.getProductDetails(ean: eanValue, accountType: accType, location: location)
        .then((value) {
      switch (value) {
        case kEanEmpty:
          _errorMessage = kEanEmpty;
          _isLoading = false;
          _response = GetProductDetailsResponse(result: []);
          _isError = true;
          break;
        case kEanNFound:
          log('error found - $kEanNFound');
          _errorMessage = kEanNFound;
          _isLoading = false;
          log('isLoading - $_isLoading');
          _response = GetProductDetailsResponse(result: []);
          _isError = true;
          break;
        case kerrorString:
          _errorMessage = kerrorString;
          _isLoading = false;
          _isError = true;
          _response = GetProductDetailsResponse(result: []);
          break;
        default:
          try {
            _errorMessage = '';
            _isError = false;
            _isLoading = true;
            _response = GetProductDetailsResponse.fromJson(jsonDecode(value));
          } catch (e) {
            _errorMessage = '$kerrorString\n$e';
            _isLoading = false;
            _response = GetProductDetailsResponse(result: []);
            _isError = true;
          }
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getUserCred() async {
    _isLoading = true;
    await ApiCalls.getUserCreds().then((value) {
      switch (value) {
        case kerrorString:
          _errorMessage = kerrorString;
          _isLoading = false;
          _isError = true;
          _credsResponse = [];
          break;
        default:
          try {
            _errorMessage = '';
            _isError = false;
            _isLoading = false;
            _credsResponse.addAll(getUserCredsResponseFromJson(value));
          } catch (e) {
            _errorMessage = '$kerrorString\n$e';
            _isLoading = false;
            _credsResponse = [];
            _isError = true;
          }
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getProductImage(
      {required String accessToken,
      required String productId,
      required int profileId}) async {
    _isLoading = true;
    await ApiCalls.getProductImages(
            accessToken: accessToken,
            productId: productId,
            profileId: profileId)
        .then((value) {
      switch (value) {
        case kerrorString:
          _errorMessage = kerrorString;
          _isLoading = false;
          _isError = true;
          _imagesResponse = GetProductImagesResponse(value: []);
          break;
        default:
          try {
            _errorMessage = '';
            _isError = false;
            _isLoading = false;
            _imagesResponse =
                GetProductImagesResponse.fromJson(jsonDecode(value));
          } catch (e) {
            _errorMessage = '$kerrorString\n$e';
            _isLoading = false;
            _imagesResponse = GetProductImagesResponse(value: []);
            _isError = true;
          }
      }
    });

    _isLoading = false;
    notifyListeners();
  }
}
