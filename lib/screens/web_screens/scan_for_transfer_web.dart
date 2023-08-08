import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/state_management/logic_class.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/screens/mobile_device_screens/camera_screen.dart';
import 'package:absolute_app/screens/web_screens/stock_transfer_web.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_network/image_network.dart';
import 'package:image_picker/image_picker.dart';
import 'package:images_picker/images_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:scan/scan.dart';

class ScanForTransferWeb extends StatefulWidget {
  const ScanForTransferWeb(
      {Key? key,
      required this.accType,
      required this.authorization,
      required this.refreshToken,
      required this.controllerText,
      required this.crossVisible,
      required this.profileId})
      : super(key: key);

  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final String controllerText;
  final bool crossVisible;

  @override
  State<ScanForTransferWeb> createState() => _ScanForTransferWebState();
}

class _ScanForTransferWebState extends State<ScanForTransferWeb> {
  late TextEditingController _searchController;
  late TextEditingController sSPriceController;
  late FocusNode focusNode;

  final RoundedLoadingButtonController addPriceController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelPriceController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController updatePriceController =
      RoundedLoadingButtonController();

  BusinessLogic _logicProvider = BusinessLogic();

  bool crossVisible = false;
  bool isFirstTimeScanCamera = true;
  bool isFirstTimeScanStorage = true;
  bool isFirstTimeForLocation = true;
  List<CameraDescription> cameras = [];
  String scanBarcodeResult = '';
  XFile? _pickedFile;

  bool isShopifyStorePriceVisible = false;
  bool isPriceError = false;
  double sSPrice = 0;
  double sSPriceApi = 0;

  String sku = '';
  String name = '';
  String prodId = '';

  String tokenValue = '';

  bool isProductVisible = false;

  @override
  void initState() {
    _searchController = TextEditingController();
    sSPriceController = TextEditingController();
    focusNode = FocusNode();

    setState(() {
      _searchController.text = widget.controllerText;
      crossVisible = widget.crossVisible;
    });
    _logicProvider = Provider.of<BusinessLogic>(context, listen: false);

    submitItem();
    addPriceController.stateStream.listen((value) {
      log('$value');
    });

    cancelPriceController.stateStream.listen((value) {
      log('$value');
    });

    updatePriceController.stateStream.listen((value) {
      log('$value');
    });
    super.initState();
  }

  void submitItem() async {
    await Future.delayed(const Duration(milliseconds: 200), () async {
      await submitScannedItem();
    });
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
          'Scan',
          style: TextStyle(
            fontSize: ResponsiveCheck.isLargeScreen(context)
                ? size.width * .02
                : ResponsiveCheck.isMediumScreen(context)
                    ? size.width * .025
                    : size.width * .03,
            color: Colors.black,
          ),
        ),
      ),
      body: SizedBox(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: isProductVisible,
                  child: _logicProvider.isLoading
                      ? SizedBox(
                          height: size.height * .2,
                          width: size.width,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: appColor,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _productTitle(context, size),
                            Visibility(
                              visible:
                                  !(ResponsiveCheck.isSmallScreen(context)),
                              child: SizedBox(
                                height: ResponsiveCheck.isLargeScreen(context)
                                    ? size.height * .45
                                    : size.height * .5,
                                width: size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.height * .45
                                              : size.height * .5,
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
                                                size.width * .05, 0, 0, 0),
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
                                          _shopifyStorePrice(context, size),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.height * .45
                                              : size.height * .5,
                                      width: size.width * .45,
                                      child: Center(
                                        child: _logicProvider
                                                .imagesResponse.value.isEmpty
                                            ? const CircularProgressIndicator(
                                                color: appColor,
                                                strokeWidth: 3,
                                              )
                                            : Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                elevation: 10,
                                                child: SizedBox(
                                                  height: ResponsiveCheck
                                                          .isLargeScreen(
                                                              context)
                                                      ? size.height * .45
                                                      : size.height * .5,
                                                  width: ResponsiveCheck
                                                          .isLargeScreen(
                                                              context)
                                                      ? size.height * .45
                                                      : size.height * .5,
                                                  child: Center(
                                                    child: ImageNetwork(
                                                      image: _logicProvider
                                                          .imagesResponse
                                                          .value[0]
                                                          .url,
                                                      imageCache:
                                                          CachedNetworkImageProvider(
                                                              _logicProvider
                                                                  .imagesResponse
                                                                  .value[0]
                                                                  .url),
                                                      height: ResponsiveCheck
                                                              .isLargeScreen(
                                                                  context)
                                                          ? size.height * .43
                                                          : size.height * .48,
                                                      width: ResponsiveCheck
                                                              .isLargeScreen(
                                                                  context)
                                                          ? size.height * .43
                                                          : size.height * .48,
                                                      duration: 1000,
                                                      fitAndroidIos:
                                                          BoxFit.contain,
                                                      fitWeb: BoxFitWeb.contain,
                                                      onLoading:
                                                          const CircularProgressIndicator(
                                                        color:
                                                            Colors.indigoAccent,
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
                              visible: ResponsiveCheck.isSmallScreen(context),
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
                                    child: const Divider(
                                      thickness: 1.5,
                                    ),
                                  ),
                                  _shopifyStorePrice(context, size),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .03, size.width * .05, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RoundedLoadingButton(
                                    color: Colors.green,
                                    borderRadius: 10,
                                    height: ResponsiveCheck.isLargeScreen(context) ? size.height * .07 : ResponsiveCheck.isMediumScreen(context) ? size.height * .06:size.height * .045,
                                    width: ResponsiveCheck.isLargeScreen(context) ? size.width * .1 : ResponsiveCheck.isMediumScreen(context) ? size.width * .14 : size.width * .18,
                                    successIcon: Icons.check_rounded,
                                    failedIcon: Icons.close_rounded,
                                    successColor: Colors.green,
                                    controller: updatePriceController,
                                    onPressed: () async {
                                      if (sSPrice == sSPriceApi) {
                                        /// means no changes done - thus do not update
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          updatePriceController.reset();
                                        });
                                      } else {
                                        /// changes are done - hit update store price api and fetch api again
                                        await ApiCalls.tokenAPIWeb()
                                            .then((tokenXX) async {
                                          await updateStorePrice(
                                                  tokenXX, prodId, '$sSPrice')
                                              .then((value) async {
                                            if (value
                                                .contains('successfully')) {
                                              await getShopifyStorePrice(
                                                  accessToken: tokenXX,
                                                  productId: prodId,
                                                  profileId: widget.profileId);
                                              await Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () {
                                                updatePriceController.reset();
                                              });
                                            }
                                          });
                                        });
                                      }
                                    },
                                    child: const Text('Update Store Price'),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .02, size.width * .05, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: size.height * .06,
                                    width: ResponsiveCheck.isLargeScreen(context) ? size.width * .3 : ResponsiveCheck.isMediumScreen(context) ? size.width * .45 : size.width * .6,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: appColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                StockTransferWeb(
                                              authorization:
                                                  widget.authorization,
                                              refreshToken: widget.refreshToken,
                                              prodId: prodId,
                                              fromDropDownValue: 0,
                                              toDropDownValue: 4,
                                              isUpdated: false,
                                            ),
                                            transitionsBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.ease;

                                              var tween = Tween(
                                                      begin: begin, end: end)
                                                  .chain(
                                                      CurveTween(curve: curve));

                                              return SlideTransition(
                                                position:
                                                    animation.drive(tween),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Stock Transfer',
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 26,
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Visibility(
                                visible: ResponsiveCheck.isSmallScreen(context),
                                child: _productImage(context, size)),
                          ],
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shopifyStorePrice(BuildContext context, Size size) {
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
            'ShopifyStorePrice : ',
            style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .015
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .02
                      : size.width * .025,

              fontWeight: FontWeight.bold,
            ),
          ),
          isShopifyStorePriceVisible == false
              ? const CircularProgressIndicator(
                  color: appColor,
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
                                'Enter New Price',
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
                                controller: sSPriceController,
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
                                        controller: cancelPriceController,
                                        onPressed: () {
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            Navigator.pop(context);
                                            cancelPriceController.reset();
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
                                              controller: addPriceController,
                                              onPressed: () async {
                                                if (sSPriceController.text
                                                        .toString()
                                                        .isNotEmpty ||
                                                    sSPriceController.text
                                                            .toString() !=
                                                        '') {
                                                  if (double.parse(
                                                          sSPriceController.text
                                                              .toString()) >=
                                                      0) {
                                                    setState(() {
                                                      sSPrice = 0;
                                                    });
                                                    setState(() {
                                                      sSPrice = double.parse(
                                                          sSPriceController.text
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
                                                      addPriceController
                                                          .reset();
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              'Store Price cannot be less than zero',
                                                          toastLength: Toast
                                                              .LENGTH_LONG);
                                                    });
                                                  }
                                                } else {
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    addPriceController.reset();
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
                                isShopifyStorePriceVisible == false
                                    ? ''
                                    : '$sSPrice',
                                style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .015
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .02
                                          : size.width * .025,
                                ),
                              ),
                            ),
                            //   ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

          // Flexible(
          //         child: Text(
          //           isShopifyStorePriceVisible == false ? '' : '$sSPrice',
          //           overflow: TextOverflow.visible,
          //           style: TextStyle(
          //             fontSize: ResponsiveCheck.isLargeScreen(context)
          //                 ? size.width * .015
          //                 : ResponsiveCheck.isMediumScreen(context)
          //                     ? size.width * .02
          //                     : size.width * .025,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
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

                  fontWeight: FontWeight.bold,
                ),
              ),
              // Flexible(
              //   child:
              Text(
                _logicProvider.isLoading
                    ? ''
                    : _logicProvider.productResponse.result.isEmpty
                    ? ''
                    : _logicProvider.productResponse.result[0].ean,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: ResponsiveCheck.isLargeScreen(context)
                      ? size.width * .015
                      : ResponsiveCheck.isMediumScreen(context)
                          ? size.width * .02
                          : size.width * .025,
                ),
              ),
              // ),
            ],
          ),
        ],
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
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              _logicProvider.isLoading
                  ? ''
                  : _logicProvider.productResponse.result.isEmpty
                  ? ''
                  : _logicProvider.productResponse.result[0].sku,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: ResponsiveCheck.isLargeScreen(context)
                    ? size.width * .015
                    : ResponsiveCheck.isMediumScreen(context)
                        ? size.width * .02
                        : size.width * .025,
              ),
            ),
          ),
        ],
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
              _logicProvider.isLoading
              ? ''
              : _logicProvider.productResponse.result.isEmpty
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

  // ignore: unused_element
  Widget _searchBarBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          size.width * .05, size.width * .1, size.width * .05, 0),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ThemeData().colorScheme.copyWith(primary: appColor),
          ),
          child: TextFormField(
            focusNode: focusNode,
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                size: size.width * .08,
              ),
              suffixIcon: Visibility(
                visible: crossVisible,
                child: IconButton(
                    onPressed: () async {
                      _searchController.clear();
                      await Future.delayed(const Duration(milliseconds: 500),
                          () {
                        setState(() {
                          crossVisible = false;
                        });
                      });
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: size.width * .08,
                    )),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: appColor, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              focusColor: appColor,
            ),
            onChanged: (value) {
              if (value != '') {
                setState(() {
                  crossVisible = true;
                });
              } else {
                setState(() {
                  crossVisible = false;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> getShopifyStorePrice(
      {required String accessToken,
      required String productId,
      required int profileId}) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/Attributes?${kFilter}Name eq $kSStorePrice and ProfileId  eq $profileId&$kAccessToken$accessToken';
    log('getShopifyStorePrice - $uri');
    setState(() {
      isShopifyStorePriceVisible = false;
      isPriceError = false;
    });

    var header = {
      'origin': "*",
    };
    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          setState(() {
            isShopifyStorePriceVisible = true;
            isPriceError = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('getShopifyStorePrice response - ${jsonDecode(response.body)}');
        sSPrice = 0;
        sSPriceApi = 0;
        setState(() {
          sSPrice = double.parse(
              jsonDecode(response.body)['value'][0]['Value'].toString());
          sSPriceApi = double.parse(
              jsonDecode(response.body)['value'][0]['Value'].toString());
        });
        log('fetch sSPrice - $sSPrice');
        log('fetch sSPriceApi - $sSPriceApi');
        setState(() {
          isShopifyStorePriceVisible = true;
          isPriceError = false;
        });
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        setState(() {
          isShopifyStorePriceVisible = true;
          isPriceError = true;
        });
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      setState(() {
        isShopifyStorePriceVisible = true;
        isPriceError = true;
      });
    }
  }

  Future<String> updateStorePrice(
      String accessToken, String productId, String storePrice) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/Attributes($kSStorePrice)?$kAccessToken$accessToken';
    log('Update Store Price uri web - $uri');
    log('product id - $productId');

    final body = {"Value": storePrice};

    log('body - ${jsonEncode(body)}');

    try {
      var response = await http.put(Uri.parse(uri),
          body: jsonEncode(body),
          headers: {"Content-Type": "application/json"}).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          setState(() {});
          return http.Response('Error', 408);
        },
      );

      log('status code - ${response.statusCode}');

      if (response.statusCode == 204) {
        log('Shopify Store Price updated successfully');
        setState(() {});
        Fluttertoast.showToast(
            msg: 'Shopify Store Price updated successfully,',
            toastLength: Toast.LENGTH_LONG);
        return 'Shopify Store Price updated successfully';
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

  Future<void> submitScannedItem() async {
    focusNode.unfocus();
    if (_searchController.text.toString() != '') {
      if (int.tryParse(_searchController.text.toString()) != null) {
        /// means ean value
        setState(() {
          isProductVisible = true;
        });
        _logicProvider
            .getProductData(
                eanValue: _searchController.text.toString(),
                accType: widget.accType,
                location: '')
            .whenComplete(() async {
          await ApiCalls.tokenAPIWeb().then((tokenXX) async {
            setState(() {
              tokenValue = tokenXX;
            });
            await _logicProvider.getProductImage(
                accessToken: tokenXX,
                productId: _logicProvider.productResponse.result.isEmpty
                    ? ''
                    : _logicProvider.productResponse.result[0].id,
                profileId: widget.profileId);
          });
        }).whenComplete(() {
          setState(() {
            name = _logicProvider.productResponse.result[0].title.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].title;
            sku = _logicProvider.productResponse.result[0].sku.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].sku;
            prodId = _logicProvider.productResponse.result[0].id.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].id;
          });
        }).whenComplete(() async {
          await getShopifyStorePrice(
              accessToken: tokenValue,
              productId: _logicProvider.productResponse.result.isEmpty
                  ? ''
                  : _logicProvider.productResponse.result[0].id,
              profileId: widget.profileId);
        });
      } else {
        /// means location value

        setState(() {
          isProductVisible = true;
        });
        _logicProvider
            .getProductData(
                eanValue: '',
                accType: widget.accType,
                location: _searchController.text.toString())
            .whenComplete(() {
          setState(() {
            name = _logicProvider.productResponse.result[0].title.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].title;
            sku = _logicProvider.productResponse.result[0].sku.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].sku;
            prodId = _logicProvider.productResponse.result[0].id.isEmpty
                ? ''
                : _logicProvider.productResponse.result[0].id;
          });
        });
      }
    }
  }

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      log("barcodeScanRes - $barcodeScanRes");
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      scanBarcodeResult = barcodeScanRes;
    });
    log('scanBarcodeResult - $scanBarcodeResult');
  }

  Future<void> scanBarcodeFromStorage() async {
    List<Media>? res = await ImagesPicker.pick();
    if (res != null) {
      String? str = await Scan.parse(res[0].path);
      log('str - $str');
      if (str != null) {
        setState(() {
          scanBarcodeResult = str;
        });
      } else {
        setState(() {
          scanBarcodeResult = '';
        });
      }
    }
    log('scanBarcodeResult - $scanBarcodeResult');
  }

  Future<void> initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
    } on CameraException catch (e) {
      log("Camera Exception: $e");
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
    // log('result for scan location from device folder - $result');
    // if (!mounted) return;
    // if (result != '') {
    //   setState(() {
    //     _searchController.text = result;
    //     crossVisible = true;
    //   });
    // } else {
    //   setState(() {
    //     _searchController.text = '';
    //     crossVisible = false;
    //   });
    // }
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
    log('results at search screen - $result');
    if (!mounted) return;
    if (result != '') {
      setState(() {
        _searchController.text = result;
        crossVisible = true;
      });
    } else {
      setState(() {
        _searchController.text = '';
        crossVisible = false;
      });
    }
  }
}
