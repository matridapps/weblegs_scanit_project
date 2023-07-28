import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/state_management/logic_class.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/models/get_product_quantity_response.dart';
import 'package:absolute_app/models/get_updated_location_response.dart';
import 'package:absolute_app/screens/mobile_device_screens/camera_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';
import 'package:image_network/image_network.dart';

class ProductDetailsWeb extends StatefulWidget {
  const ProductDetailsWeb(
      {Key? key,
      required this.ean,
      required this.location,
      required this.accType,
      required this.authorization,
      required this.refreshToken,
      required this.profileId,
      required this.distCenterId,
      required this.distCenterName})
      : super(key: key);

  final String ean;
  final String location;
  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final int distCenterId;
  final String distCenterName;

  @override
  State<ProductDetailsWeb> createState() => _ProductDetailsWebState();
}

class _ProductDetailsWebState extends State<ProductDetailsWeb> {
  bool isQuantityVisible = false;
  bool isPriceVisible = false;
  bool isLocationTextLoading = false;

  List<QuantityValue> quantityValues = [];
  List<LocationResult> locationValue = [];

  List<int> distIds = [];

  List<CameraDescription> cameras = [];
  XFile? _pickedFile;

  // String prodId = '';
  String prodLocation = '';

  double prodStorePrice = 0;

  int prodQuantity = 0;

  /// quantity and warehouse location from the api - not to change this variable outside api method. (only inside api method - either in first hit or update method)
  int pQApi = 0;
  String wLApi = '';

  late TextEditingController locationController;
  late TextEditingController quantityController;

  final RoundedLoadingButtonController updateController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController addQuantityController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController addLocController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelQuantityController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelLocController =
      RoundedLoadingButtonController();

  BusinessLogic _logicProvider = BusinessLogic();

  @override
  void initState() {
    locationController = TextEditingController();
    quantityController = TextEditingController();

    _logicProvider = Provider.of<BusinessLogic>(context, listen: false);

    _logicProvider
        .getProductData(
            eanValue: widget.ean,
            accType: widget.accType,
            location: widget.location)
        .whenComplete(() async {
      setState(() {
        wLApi = _logicProvider.productResponse.result[0].warehouseLocation;
        prodLocation =
            _logicProvider.productResponse.result[0].warehouseLocation;
      });
      await ApiCalls.tokenAPIWeb().then((tokenXX) async {
        await _logicProvider.getProductImage(
            accessToken: tokenXX,
            productId: _logicProvider.productResponse.result.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].id,
            profileId: widget.profileId);
        await getProductQuantity(
            tokenXX,
            _logicProvider.productResponse.result.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].id);
        await getProductStorePrice(
            tokenXX,
            _logicProvider.productResponse.result.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].id);
      });
    });

    updateController.stateStream.listen((value) {
      log('$value');
    });
    addQuantityController.stateStream.listen((value) {
      log('$value');
    });
    addLocController.stateStream.listen((value) {
      log('$value');
    });
    cancelQuantityController.stateStream.listen((value) {
      log('$value');
    });
    cancelLocController.stateStream.listen((value) {
      log('$value');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: size.height * .08,
        elevation: 5,
        title: Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: ResponsiveCheck.isLargeScreen(context)
                ? size.width * .02
                : ResponsiveCheck.isMediumScreen(context)
                    ? size.width * .025
                    : size.width * .03,
          ),
        ),
      ),
      body: SizedBox(
        height: size.height,
        child: Consumer<BusinessLogic>(
          builder: (context, value, child) => _logicProvider.isLoading == true
              ? SizedBox(
                  height: size.height,
                  width: size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: appColor,
                        strokeWidth: 3,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: size.width * .05),
                        child: Text(
                          'Loading.....Please Wait',
                          style: TextStyle(fontSize: size.width * .015),
                        ),
                      ),
                    ],
                  ),
                )
              : _logicProvider.isError == true
                  ? Center(
                      child: Text(
                        _logicProvider.errorMessage,
                        style: TextStyle(fontSize: size.width * .015),
                      ),
                    )
                  : _logicProvider.productResponse.result.isEmpty
                      ? Center(
                          child: Text(
                            'No Product found.',
                            style: TextStyle(fontSize: size.width * .04),
                          ),
                        )
                      : SizedBox(
                          height: size.height,
                          width: size.width,
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                            },
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _productTitle(context, size),
                                  Visibility(
                                    visible: !(ResponsiveCheck.isSmallScreen(
                                        context)),
                                    child: SizedBox(
                                      height: ResponsiveCheck.isLargeScreen(context) ? size.height * .45 : size.height * .5,
                                      width: size.width,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: ResponsiveCheck.isLargeScreen(context) ? size.height * .45 : size.height * .5,
                                            width: size.width * .55,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      size.width * .05,
                                                      0,
                                                      size.width * .05,
                                                      0),
                                                  child: const Divider(
                                                    thickness: 1.5,
                                                  ),
                                                ),
                                                _productSKU(context, size),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      size.width * .05,
                                                      0,
                                                      0,
                                                      0),
                                                  child: const Divider(
                                                    thickness: 1.5,
                                                  ),
                                                ),
                                                _productStorePrice(
                                                    context, size),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      size.width * .05,
                                                      0,
                                                      0,
                                                      0),
                                                  child: const Divider(
                                                    thickness: 1.5,
                                                  ),
                                                ),
                                                _productBarcode(context, size),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      size.width * .05,
                                                      0,
                                                      size.width * .05,
                                                      0),
                                                  child: const Divider(
                                                    thickness: 1.5,
                                                  ),
                                                ),
                                                _productDistCenter(
                                                    context, size),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      size.width * .05,
                                                      0,
                                                      size.width * .05,
                                                      0),
                                                  child: const Divider(
                                                    thickness: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: ResponsiveCheck.isLargeScreen(context) ? size.height * .45 : size.height * .5,
                                            width: size.width * .45,
                                            child: Center(
                                              child: _logicProvider.imagesResponse.value.isEmpty
                                                  ? const CircularProgressIndicator(
                                                color: appColor,
                                                strokeWidth: 3,
                                              )
                                                  : Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  elevation: 10,
                                                  child: SizedBox(
                                                    height: ResponsiveCheck.isLargeScreen(context) ? size.height * .45 : size.height * .5,
                                                    width: ResponsiveCheck.isLargeScreen(context) ? size.height * .45 : size.height * .5,
                                                    child: Center(
                                                      child: ImageNetwork(
                                                        image: _logicProvider.imagesResponse.value[0].url,
                                                        imageCache: CachedNetworkImageProvider(
                                                            _logicProvider.imagesResponse.value[0].url),
                                                        height: ResponsiveCheck.isLargeScreen(context) ? size.height * .43 : size.height * .48,
                                                        width: ResponsiveCheck.isLargeScreen(context) ? size.height * .43 : size.height * .48,
                                                        duration: 1000,
                                                        fitAndroidIos: BoxFit.contain,
                                                        fitWeb: BoxFitWeb.contain,
                                                        onLoading: const CircularProgressIndicator(
                                                          color: Colors.indigoAccent,
                                                        ),
                                                        onError: const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  )

                                                // GetImageCacheNetwork(
                                                //   imageFromNetworkUrl:
                                                //       _logicProvider.imagesResponse.value[0].url,
                                                //   imageFromAssetsUrl: 'assets/no_image/no_image.png',
                                                //   width: size.width,
                                                //   height: size.width,
                                                //   fit: BoxFit.contain,
                                                //   errorFit: BoxFit.contain,
                                                //   errorWidth: size.width,
                                                //   errorHeight: size.width,
                                                //   showLogs: true,
                                                //   cacheDuration: 10,
                                                // ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible:
                                        ResponsiveCheck.isSmallScreen(context),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              size.width * .05,
                                              0,
                                              size.width * .05,
                                              0),
                                          child: const Divider(
                                            thickness: 1.5,
                                          ),
                                        ),
                                        _productSKU(context, size),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              size.width * .05, 0, 0, 0),
                                          child: Divider(
                                            thickness: 1.5,
                                            endIndent: size.width * .5,
                                          ),
                                        ),
                                        _productStorePrice(context, size),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              size.width * .05, 0, 0, 0),
                                          child: Divider(
                                            thickness: 1.5,
                                            endIndent: size.width * .4,
                                          ),
                                        ),
                                        _productBarcode(context, size),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              size.width * .05,
                                              0,
                                              size.width * .05,
                                              0),
                                          child: Divider(
                                              thickness: 1.5,
                                              endIndent: size.width * .15),
                                        ),
                                        _productDistCenter(context, size),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              size.width * .05,
                                              0,
                                              size.width * .05,
                                              0),
                                          child: const Divider(
                                            thickness: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _productQuantity(context, size),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        size.width * .05,
                                        0,
                                        size.width * .05,
                                        0),
                                    child: const Divider(
                                      thickness: 1.5,
                                    ),
                                  ),
                                  _productLocation(context, size),
                                  // Padding(
                                  //   padding: EdgeInsets.fromLTRB(
                                  //       size.width * .05,
                                  //       0,
                                  //       size.width * .05,
                                  //       0),
                                  //   child: const Divider(
                                  //     thickness: 1.5,
                                  //   ),
                                  // ),
                                  // _allDistCenter(context, size),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        size.width * .05,
                                        0,
                                        size.width * .05,
                                        0),
                                    child: const Divider(
                                      thickness: 1.5,
                                    ),
                                  ),
                                  _updateButton(context, size),
                                  Visibility(
                                      visible: ResponsiveCheck.isSmallScreen(
                                          context),
                                      child: _productImage(context, size)),
                                ],
                              ),
                            ),
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _productTitle(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05, size.width * .03, size.width * .05, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              _logicProvider.productResponse.result[0].title.isEmpty
                  ? ''
                  : _logicProvider.productResponse.result[0].title,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontSize: ResponsiveCheck.isLargeScreen(context)
                      ? size.width * .015
                      : ResponsiveCheck.isMediumScreen(context)
                          ? size.width * .02
                          : size.width * .025,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05, size.width * .03, size.width * .05, 0),
      child: SizedBox(
        height: size.width,
        width: size.width,
        child: Center(
          child: _logicProvider.imagesResponse.value.isEmpty
              ? const CircularProgressIndicator(
                  color: appColor,
                  strokeWidth: 3,
                )
              : Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: SizedBox(
                    height: size.width,
                    width: size.width,
                    child: Center(
                      child: ImageNetwork(
                        image: _logicProvider.imagesResponse.value[0].url,
                        imageCache: CachedNetworkImageProvider(
                            _logicProvider.imagesResponse.value[0].url),
                        height: size.width * .6,
                        width: size.width * .6,
                        duration: 1500,
                        fitAndroidIos: BoxFit.cover,
                        fitWeb: BoxFitWeb.cover,
                        onLoading: const CircularProgressIndicator(
                          color: Colors.indigoAccent,
                        ),
                        onError: const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )

                  // GetImageCacheNetwork(
                  //   imageFromNetworkUrl:
                  //       _logicProvider.imagesResponse.value[0].url,
                  //   imageFromAssetsUrl: 'assets/no_image/no_image.png',
                  //   width: size.width,
                  //   height: size.width,
                  //   fit: BoxFit.contain,
                  //   errorFit: BoxFit.contain,
                  //   errorWidth: size.width,
                  //   errorHeight: size.width,
                  //   showLogs: true,
                  //   cacheDuration: 10,
                  // ),
                  ),
        ),
      ),
    );
  }

  Widget _productSKU(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05,
          ResponsiveCheck.isLargeScreen(context)
              ? size.width * .02
              : size.width * .05,
          size.width * .05,
          0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'SKU : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          Flexible(
            child: Text(
              _logicProvider.productResponse.result[0].sku.isEmpty
                  ? ''
                  : _logicProvider.productResponse.result[0].sku,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: ResponsiveCheck.isLargeScreen(context)
                    ? size.width * .015
                    : ResponsiveCheck.isMediumScreen(context)
                        ? size.width * .02
                        : size.width * .025,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productStorePrice(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05,
          ResponsiveCheck.isLargeScreen(context)
              ? size.width * .015
              : size.width * .03,
          size.width * .05,
          0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Store Price :  ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          isPriceVisible == false
              ? const CircularProgressIndicator(
                  color: appColor,
                )
              : Flexible(
                  child: Text(
                    '$prodStorePrice',
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: ResponsiveCheck.isLargeScreen(context)
                          ? size.width * .015
                          : ResponsiveCheck.isMediumScreen(context)
                              ? size.width * .02
                              : size.width * .025,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _productBarcode(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05,
          ResponsiveCheck.isLargeScreen(context)
              ? size.width * .015
              : size.width * .03,
          size.width * .05,
          0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                'Barcode(EAN) : ',
                style: TextStyle(
                  fontSize: ResponsiveCheck.isLargeScreen(context)
                      ? size.width * .015
                      : ResponsiveCheck.isMediumScreen(context)
                          ? size.width * .02
                          : size.width * .025,
                ),
              ),
              // Flexible(
              //   child:
              Text(
                _logicProvider.productResponse.result[0].ean.isEmpty
                    ? ''
                    : _logicProvider.productResponse.result[0].ean,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: ResponsiveCheck.isLargeScreen(context)
                      ? size.width * .015
                      : ResponsiveCheck.isMediumScreen(context)
                          ? size.width * .02
                          : size.width * .025,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productDistCenter(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05,
          ResponsiveCheck.isLargeScreen(context)
              ? size.width * .015
              : size.width * .03,
          size.width * .05,
          0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Distribution Center Name : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          Flexible(
            child: Text(
              widget.distCenterName,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: ResponsiveCheck.isLargeScreen(context)
                    ? size.width * .015
                    : ResponsiveCheck.isMediumScreen(context)
                        ? size.width * .02
                        : size.width * .025,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productQuantity(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * .05, 0, size.width * .05, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Quantity : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          isQuantityVisible == false
              ? Row(
                  children: const [
                    Center(
                      child: CircularProgressIndicator(
                        color: appColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                              titleTextStyle: TextStyle(
                                color: Colors.black,
                                fontSize: size.width * .042,
                                fontWeight: FontWeight.bold,
                              ),
                              title: Text(
                                'Enter a Quantity',
                                style: TextStyle(
                                    fontSize:
                                        ResponsiveCheck.isLargeScreen(context)
                                            ? size.width * .015
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .01
                                                : size.width * .005),
                              ),
                              content: TextField(
                                keyboardType: TextInputType.number,
                                controller: quantityController,
                                decoration: const InputDecoration(
                                    hintText: "enter here"),
                              ),
                              actions: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: size.width * .05),
                                      child: RoundedLoadingButton(
                                        color: appColor,
                                        borderRadius: 10,
                                        height: ResponsiveCheck.isLargeScreen(
                                                context)
                                            ? size.height * .07
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.height * .06
                                                : size.height * .045,
                                        width: ResponsiveCheck.isLargeScreen(
                                                context)
                                            ? size.width * .1
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .14
                                                : size.width * .18,
                                        successIcon: Icons.check_rounded,
                                        failedIcon: Icons.close_rounded,
                                        successColor: Colors.green,
                                        controller: cancelQuantityController,
                                        onPressed: () {
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            Navigator.pop(context);
                                            cancelQuantityController.reset();
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                right: size.width * .05),
                                            child: RoundedLoadingButton(
                                              color: Colors.green,
                                              borderRadius: 10,
                                              height:
                                                  ResponsiveCheck.isLargeScreen(
                                                          context)
                                                      ? size.height * .07
                                                      : ResponsiveCheck
                                                              .isMediumScreen(
                                                                  context)
                                                          ? size.height * .06
                                                          : size.height * .045,
                                              width:
                                                  ResponsiveCheck.isLargeScreen(
                                                          context)
                                                      ? size.width * .1
                                                      : ResponsiveCheck
                                                              .isMediumScreen(
                                                                  context)
                                                          ? size.width * .14
                                                          : size.width * .18,
                                              successIcon: Icons.check_rounded,
                                              failedIcon: Icons.close_rounded,
                                              successColor: Colors.green,
                                              controller: addQuantityController,
                                              onPressed: () async {
                                                if (quantityController.text
                                                        .toString()
                                                        .isNotEmpty ||
                                                    quantityController.text
                                                            .toString() !=
                                                        '') {
                                                  if (int.parse(
                                                          quantityController
                                                              .text
                                                              .toString()) >=
                                                      0) {
                                                    setState(() {
                                                      prodQuantity = 0;
                                                    });
                                                    setState(() {
                                                      prodQuantity = int.parse(
                                                          quantityController
                                                              .text
                                                              .toString());
                                                    });
                                                    Future.delayed(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      Navigator.pop(context);
                                                    });
                                                  } else {
                                                    Future.delayed(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      addQuantityController
                                                          .reset();
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              'Quantity cannot be less than zero',
                                                          toastLength: Toast
                                                              .LENGTH_LONG);
                                                    });
                                                  }
                                                } else {
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    addQuantityController
                                                        .reset();
                                                  });
                                                }
                                              },
                                              child: const Text('Add'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Card(
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            height: ResponsiveCheck.isLargeScreen(context)
                                ? size.width * .035
                                : size.width * .05,
                            width: ResponsiveCheck.isLargeScreen(context)
                                ? size.width * .2
                                : size.width * .3,
                            // child: FittedBox(
                            //   fit: BoxFit.scaleDown,
                            child: Center(
                              child: Text(
                                isQuantityVisible == false
                                    ? ''
                                    : '$prodQuantity',
                                style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .015
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .02
                                          : size.width * .025,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            //   ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: size.width * .084,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          prodQuantity = prodQuantity + 1;
                        });
                        log('prodQuantity - $prodQuantity');
                      },
                      icon: Image.asset('assets/product_details_icons/+.png'),
                      // Icon(
                      //   Icons.add,
                      //   size: size.width * .07,
                      // ),
                    ),
                    SizedBox(
                      width: size.width * .084,
                    ),
                    IconButton(
                      onPressed: () {
                        if (prodQuantity > 0) {
                          setState(() {
                            prodQuantity = prodQuantity - 1;
                          });
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Quantity cannot be less than zero');
                        }
                        log('prodQuantity - $prodQuantity');
                      },
                      icon: Image.asset('assets/product_details_icons/-.png'),
                      // Icon(
                      //   Icons.remove,
                      //   size: size.width * .07,
                      // ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _productLocation(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05,
          ResponsiveCheck.isLargeScreen(context)
              ? size.width * .015
              : size.width * .03,
          size.width * .05,
          0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Warehouse Location : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          isLocationTextLoading == true
              ? const Center(
                  child: CircularProgressIndicator(
                    color: appColor,
                  ),
                )
              : Flexible(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                            titleTextStyle: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * .042,
                              fontWeight: FontWeight.bold,
                            ),
                            title: Text(
                              'Warehouse Location',
                              style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .015
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .01
                                          : size.width * .005),
                            ),
                            content: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                hintText: "enter here",
                              ),
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: size.width * .05),
                                    child: RoundedLoadingButton(
                                      color: appColor,
                                      borderRadius: 10,
                                      height:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.height * .07
                                              : ResponsiveCheck.isMediumScreen(
                                                      context)
                                                  ? size.height * .06
                                                  : size.height * .045,
                                      width:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.width * .1
                                              : ResponsiveCheck.isMediumScreen(
                                                      context)
                                                  ? size.width * .14
                                                  : size.width * .18,
                                      successIcon: Icons.check_rounded,
                                      failedIcon: Icons.close_rounded,
                                      successColor: Colors.green,
                                      controller: cancelLocController,
                                      onPressed: () {
                                        setState(() {
                                          locationController.text = '';
                                        });
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Navigator.pop(context);
                                          cancelLocController.reset();
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              right: size.width * .05),
                                          child: RoundedLoadingButton(
                                            color: Colors.green,
                                            borderRadius: 10,
                                            height: ResponsiveCheck
                                                    .isLargeScreen(context)
                                                ? size.height * .07
                                                : ResponsiveCheck
                                                        .isMediumScreen(context)
                                                    ? size.height * .06
                                                    : size.height * .045,
                                            width: ResponsiveCheck
                                                    .isLargeScreen(context)
                                                ? size.width * .1
                                                : ResponsiveCheck
                                                        .isMediumScreen(context)
                                                    ? size.width * .14
                                                    : size.width * .18,
                                            successIcon: Icons.check_rounded,
                                            failedIcon: Icons.close_rounded,
                                            successColor: Colors.green,
                                            controller: addLocController,
                                            onPressed: () async {
                                              if (locationController.text
                                                          .toString() !=
                                                      '' ||
                                                  locationController.text
                                                      .toString()
                                                      .isNotEmpty) {
                                                setState(() {
                                                  prodLocation = '';
                                                });
                                                setState(() {
                                                  prodLocation =
                                                      locationController.text
                                                          .toString();
                                                });
                                                Future.delayed(
                                                    const Duration(seconds: 1),
                                                    () {
                                                  Navigator.pop(context);
                                                });
                                              } else {
                                                Future.delayed(
                                                    const Duration(seconds: 1),
                                                    () {
                                                  addLocController.reset();
                                                });
                                              }
                                            },
                                            child: const Text('Add'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          prodLocation == '' || prodLocation.isEmpty
                              ? 'Not Available'
                              : prodLocation,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: ResponsiveCheck.isLargeScreen(context)
                                ? size.width * .015
                                : ResponsiveCheck.isMediumScreen(context)
                                    ? size.width * .02
                                    : size.width * .025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _allDistCenter(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * .05, 0, size.width * .05, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'All Distribution Center Quantities : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 30,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _updateButton(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05, size.width * .05, size.width * .05, 0),
      child: Center(
        child: RoundedLoadingButton(
          color: appColor,
          borderRadius: 0,
          height: ResponsiveCheck.isLargeScreen(context)
              ? size.height * .07
              : ResponsiveCheck.isMediumScreen(context)
                  ? size.height * .06
                  : size.height * .045,
          width: ResponsiveCheck.isLargeScreen(context)
              ? size.width * .1
              : ResponsiveCheck.isMediumScreen(context)
                  ? size.width * .14
                  : size.width * .18,
          successIcon: Icons.check_rounded,
          failedIcon: Icons.close_rounded,
          successColor: Colors.green,
          controller: updateController,
          onPressed: () async {
            if (prodLocation == wLApi) {
              if (prodQuantity == pQApi) {
                ///both not changed - do nothing
                Future.delayed(const Duration(seconds: 1), () {
                  updateController.reset();
                });
              } else {
                /// update quantity
                await ApiCalls.tokenAPIWeb()
                    .then((value) => updateQuantity(
                                value,
                                _logicProvider.productResponse.result.isEmpty
                                    ? ''
                                    : _logicProvider
                                        .productResponse.result[0].id,
                                prodQuantity)
                            .then((value1) {
                          if (value1.contains('successfully')) {
                            getUpdatedQuantity(
                                    value,
                                    _logicProvider
                                            .productResponse.result.isEmpty
                                        ? ''
                                        : _logicProvider
                                            .productResponse.result[0].id)
                                .whenComplete(() => updateController.reset());
                          } else {
                            Future.delayed(const Duration(seconds: 1), () {
                              updateController.reset();
                            });
                          }
                        }));
              }
            } else {
              if (prodQuantity == pQApi) {
                ///update location
                if (locationController.text.toString() != '' ||
                    locationController.text.toString().isNotEmpty) {
                  await ApiCalls.tokenAPIWeb()
                      .then((value) => updateLocationForChannel(
                                  value,
                                  _logicProvider.productResponse.result.isEmpty
                                      ? ''
                                      : _logicProvider
                                          .productResponse.result[0].id,
                                  locationController.text.toString())
                              .then((value1) {
                            if (value1.contains('successfully')) {
                              updateLocation(
                                      _logicProvider
                                              .productResponse.result.isEmpty
                                          ? ''
                                          : _logicProvider
                                              .productResponse.result[0].id,
                                      locationController.text.toString())
                                  .whenComplete(() => updateController.reset());
                            } else {
                              Future.delayed(const Duration(seconds: 1), () {
                                updateController.reset();
                              });
                            }
                          }));
                } else {
                  /// location field is empty and product quantity also not changed - show toast
                  Future.delayed(const Duration(seconds: 1), () {
                    updateController.reset();
                    Fluttertoast.showToast(
                        msg: 'Empty location field cannot be updated.',
                        toastLength: Toast.LENGTH_LONG);
                  });
                }
              } else {
                ///update both
                if (locationController.text.toString() != '' ||
                    locationController.text.toString().isNotEmpty) {
                  await ApiCalls.tokenAPIWeb()
                      .then((tokenX) => updateLocationForChannel(
                                  tokenX,
                                  _logicProvider.productResponse.result.isEmpty
                                      ? ''
                                      : _logicProvider
                                          .productResponse.result[0].id,
                                  locationController.text.toString())
                              .then((value) {
                            if (value.contains('successfully')) {
                              updateLocation(
                                      _logicProvider
                                              .productResponse.result.isEmpty
                                          ? ''
                                          : _logicProvider
                                              .productResponse.result[0].id,
                                      locationController.text.toString())
                                  .whenComplete(() {
                                updateQuantity(
                                        tokenX,
                                        _logicProvider
                                                .productResponse.result.isEmpty
                                            ? ''
                                            : _logicProvider
                                                .productResponse.result[0].id,
                                        prodQuantity)
                                    .then((value) {
                                  if (value.contains('successfully')) {
                                    getUpdatedQuantity(
                                            tokenX,
                                            _logicProvider.productResponse
                                                    .result.isEmpty
                                                ? ''
                                                : _logicProvider.productResponse
                                                    .result[0].id)
                                        .whenComplete(
                                            () => updateController.reset());
                                  } else {
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      updateController.reset();
                                    });
                                  }
                                });
                              });
                            } else {
                              Future.delayed(const Duration(seconds: 1), () {
                                updateController.reset();
                              });
                            }
                          }));
                } else {
                  /// location field is empty and but product quantity is changed, so update quantity

                  await ApiCalls.tokenAPIWeb()
                      .then((tokenX) => updateQuantity(
                                  tokenX,
                                  _logicProvider.productResponse.result.isEmpty
                                      ? ''
                                      : _logicProvider
                                          .productResponse.result[0].id,
                                  prodQuantity)
                              .then((value) {
                            if (value.contains('successfully')) {
                              getUpdatedQuantity(
                                      tokenX,
                                      _logicProvider
                                              .productResponse.result.isEmpty
                                          ? ''
                                          : _logicProvider
                                              .productResponse.result[0].id)
                                  .whenComplete(() => updateController.reset());
                            } else {
                              Future.delayed(const Duration(seconds: 1), () {
                                updateController.reset();
                              });
                            }
                          }));
                }
              }
            }
          },
          child: Text(
            'Update',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getProductStorePrice(
      String accessToken, String productId) async {
    isPriceVisible = false;

    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)?$kAccessToken$accessToken&${kSelect}StorePrice';

    log('Product Price uri - $uri');

    var header = {
      "origin": "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          isPriceVisible = false;
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product price response - ${jsonDecode(response.body)}');

        prodStorePrice = 0;
        setState(() {
          prodStorePrice = jsonDecode(response.body)['StorePrice'];
        });
        log('prodStorePrice - $prodStorePrice');

        isPriceVisible = true;
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code - ${response.statusCode}');
        isPriceVisible = false;
      }
    } on Exception catch (e) {
      log(e.toString());
      isPriceVisible = false;
    }
  }

  Future<String> getProductQuantity(
      String accessToken, String productId) async {
    isQuantityVisible = false;

    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/DCQuantities?$kAccessToken$accessToken';
    log('Product Quantity uri - $uri');

    var header = {
      "origin": "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          isQuantityVisible = false;
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product quantity response - ${jsonDecode(response.body)}');

        GetProductQuantityResponse getProductQuantityResponse =
            GetProductQuantityResponse.fromJson(jsonDecode(response.body));
        log("getProductQuantityResponse - ${jsonEncode(getProductQuantityResponse)}");

        quantityValues = [];
        quantityValues.addAll(getProductQuantityResponse.value);
        log('quantityValues - ${jsonEncode(quantityValues)}');

        if (mounted) {
          setState(() {
            prodQuantity = 0;
            pQApi = 0;
            distIds = [];
          });

          setState(() {
            prodQuantity = quantityValues[quantityValues.indexWhere(
                    (e) => e.distributionCenterId == widget.distCenterId)]
                .availableQuantity;
            pQApi = quantityValues[quantityValues.indexWhere(
                    (e) => e.distributionCenterId == widget.distCenterId)]
                .availableQuantity;
            distIds.addAll(quantityValues.map((e) => e.distributionCenterId));
          });
        }
        log('prodQuantity - $prodQuantity');
        log('pQApi = $pQApi');
        log('distIds - $distIds');

        isQuantityVisible = true;
        return '${quantityValues[quantityValues.indexWhere((e) => e.distributionCenterId == widget.distCenterId)].productId}';
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code - ${response.statusCode}');
        isQuantityVisible = false;
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      isQuantityVisible = false;
      return kerrorString;
    }
  }

  Future<String> updateQuantity(
      String accessToken, String productId, int quantity) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/UpdateQuantity?$kAccessToken$accessToken';
    log('Update quantity uri - $uri');

    var header = {
      "Content-Type": "application/json",
      "origin": "*",
    };

    final body = {
      "Value": {
        "UpdateType": "InStock",
        "Updates": [
          {"DistributionCenterID": 4, "Quantity": quantity}
        ]
      }
    };

    log('body - ${jsonEncode(body)}');

    try {
      var response = await http
          .post(Uri.parse(uri), body: jsonEncode(body), headers: header)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          setState(() {});
          return http.Response('Error', 408);
        },
      );

      log('status code - ${response.statusCode}');

      if (response.statusCode == 204) {
        log('Quantity updated successfully');
        setState(() {});
        Fluttertoast.showToast(
            msg: 'Quantity updated successfully,',
            toastLength: Toast.LENGTH_LONG);
        return 'Quantity updated successfully';
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        setState(() {});
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      setState(() {});
      return kerrorString;
    }
  }

  Future<String> updateLocationForChannel(
      String accessToken, String productId, String warehouseLocation) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)?$kAccessToken$accessToken';
    log('Update Location For Channel uri - $uri');

    final body = {"WarehouseLocation": warehouseLocation};

    var header = {
      "Content-Type": "application/json",
      "origin": "*",
    };

    try {
      var response = await http
          .put(Uri.parse(uri), body: jsonEncode(body), headers: header)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 204) {
        log('Location updated successfully in channel');
        Fluttertoast.showToast(msg: 'Location updated successfully');
        return 'Location updated successfully';
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

  Future<void> updateLocation(
      String productId, String warehouseLocation) async {
    isLocationTextLoading = true;
    String uri =
        'https://weblegs.info/JadlamApp/api/Search2?Id=$productId&Location=$warehouseLocation';
    log('Update Location uri - $uri');

    try {
      var response = await http.post(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          isLocationTextLoading = false;
          setState(() {});
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('Location updated successfully ');
        log('update location response - ${jsonDecode(response.body)}');

        GetUpdatedLocationResponse getUpdatedLocationResponse =
            GetUpdatedLocationResponse.fromJson(jsonDecode(response.body));
        log('getUpdatedLocationResponse - ${jsonEncode(getUpdatedLocationResponse)}');

        wLApi = '';
        prodLocation = '';
        setState(() {
          prodLocation = getUpdatedLocationResponse.result[0].warehouseLocation;
          wLApi = getUpdatedLocationResponse.result[0].warehouseLocation;
        });
        log('prodLocation - $prodLocation');
        log('wLApi - $wLApi');
        isLocationTextLoading = false;
        setState(() {});
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        isLocationTextLoading = false;
        setState(() {});
      }
    } on Exception catch (e) {
      log(e.toString());
      isLocationTextLoading = false;
      setState(() {});
    }
  }

  Future getUpdatedQuantity(String accessToken, String productId) async {
    isQuantityVisible = false;

    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/DCQuantities?$kAccessToken$accessToken';
    log('Product Quantity uri - $uri');

    var header = {
      "origin": "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          isQuantityVisible = false;
          setState(() {});
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product quantity response - ${jsonDecode(response.body)}');

        GetProductQuantityResponse getProductQuantityResponse =
            GetProductQuantityResponse.fromJson(jsonDecode(response.body));
        log("getProductQuantityResponse - ${jsonEncode(getProductQuantityResponse)}");

        quantityValues = [];
        quantityValues.addAll(getProductQuantityResponse.value);
        log('quantityValues - ${jsonEncode(quantityValues)}');

        setState(() {
          prodQuantity = 0;
          pQApi = 0;
        });

        setState(() {
          prodQuantity = quantityValues[quantityValues.indexWhere(
                  (e) => e.distributionCenterId == widget.distCenterId)]
              .availableQuantity;
          pQApi = quantityValues[quantityValues.indexWhere(
                  (e) => e.distributionCenterId == widget.distCenterId)]
              .availableQuantity;
        });
        log('prodQuantity - $prodQuantity');
        log('pQApi - $pQApi');

        isQuantityVisible = true;
        setState(() {});
        return '${quantityValues[quantityValues.indexWhere((e) => e.distributionCenterId == widget.distCenterId)].productId}';
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        isQuantityVisible = false;
        setState(() {});
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      isQuantityVisible = false;
      setState(() {});
      return kerrorString;
    }
  }

  Future<void> setPickedFile() async {
    _pickedFile = (await ImagePicker().pickImage(source: ImageSource.gallery))!;
    setState(() {});
    log(_pickedFile!.path);
  }

  Future<void> navigateAndSetLocation(BuildContext context) async {
    // final String result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => LocationResultsScreen(
    //       imagePath: _pickedFile == null ? "" : _pickedFile!.path,
    //       isFromCamera: false,
    //       accType: widget.accType,
    //     ),
    //   ),
    // );
    // if (!mounted) return;
    // setState(() {
    //   locationController.text = result;
    // });
  }

  Future<void> initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
    } on CameraException catch (e) {
      log("Camera Exception: $e");
    }
  }

  Future<void> navigateToCameraAndSetLocation(BuildContext context) async {
    final String result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: cameras,
          accType: widget.accType,
        ),
      ),
    );
    log('results at product screen - $result');
    if (!mounted) return;
    setState(() {
      locationController.text = result;
    });
  }
}
