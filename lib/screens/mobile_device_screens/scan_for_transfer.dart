import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/state_management/logic_class.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/screens/mobile_device_screens/camera_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/stock_transfer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:images_picker/images_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:scan/scan.dart';

class ScanForTransfer extends StatefulWidget {
  const ScanForTransfer(
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
  State<ScanForTransfer> createState() => _ScanForTransferState();
}

class _ScanForTransferState extends State<ScanForTransfer> {
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
        elevation: 5,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            size: size.width * .09,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        title: Text(
          'Scan',
          style: TextStyle(
            fontSize: size.width * .06,
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
                _searchBarBuilder(context, size),
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
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                size.width * .05,
                                size.width * .05,
                                size.width * .05,
                                0,
                              ),
                              child: const Divider(
                                thickness: 2,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                size.width * .05,
                                size.width * .05,
                                size.width * .05,
                                0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: size.width * .47,
                                        child: Text(
                                          'Product Name : ',
                                          style: TextStyle(
                                            fontSize: size.width * .045,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Flexible(
                                    child: Text(
                                      name.isEmpty ? '' : name,
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                          fontSize: size.width * .045,),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .03, size.width * .05, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: size.width * .47,
                                    child: Text(
                                      'Product SKU : ',
                                      style: TextStyle(
                                        fontSize: size.width * .045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      sku.isEmpty ? '' : sku,
                                      style: TextStyle(
                                        fontSize: size.width * .045,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .05, size.width * .05, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: size.width * .47,
                                    child: Text(
                                      'ShopifyStorePrice : ',
                                      style: TextStyle(
                                        fontSize: size.width * .045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  isShopifyStorePriceVisible == false
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
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25),
                                                      ),
                                                      elevation: 5,
                                                      titleTextStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontSize:
                                                            size.width * .042,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      title: Text(
                                                        'Enter New Price',
                                                        style: TextStyle(
                                                            fontSize:
                                                                size.width *
                                                                    .05),
                                                      ),
                                                      content: TextField(
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        controller:
                                                            sSPriceController,
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    "enter here"),
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      left: size
                                                                              .width *
                                                                          .05),
                                                              child:
                                                                  RoundedLoadingButton(
                                                                color:
                                                                    appColor,
                                                                borderRadius:
                                                                    10,
                                                                height:
                                                                    size.width *
                                                                        .1,
                                                                width:
                                                                    size.width *
                                                                        .25,
                                                                successIcon: Icons
                                                                    .check_rounded,
                                                                failedIcon: Icons
                                                                    .close_rounded,
                                                                successColor:
                                                                    Colors
                                                                        .green,
                                                                controller:
                                                                    cancelPriceController,
                                                                onPressed: () {
                                                                  cancelPriceController
                                                                      .error();
                                                                  Future.delayed(
                                                                      const Duration(
                                                                          seconds:
                                                                              1),
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    cancelPriceController
                                                                        .reset();
                                                                  });
                                                                },
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsets.only(
                                                                        right: size.width *
                                                                            .05),
                                                                    child:
                                                                        RoundedLoadingButton(
                                                                      color: Colors
                                                                          .green,
                                                                      borderRadius:
                                                                          10,
                                                                      height:
                                                                          size.width *
                                                                              .1,
                                                                      width: size
                                                                              .width *
                                                                          .25,
                                                                      successIcon:
                                                                          Icons
                                                                              .check_rounded,
                                                                      failedIcon:
                                                                          Icons
                                                                              .close_rounded,
                                                                      successColor:
                                                                          Colors
                                                                              .green,
                                                                      controller:
                                                                          addPriceController,
                                                                      onPressed:
                                                                          () async {
                                                                        if (sSPriceController.text.toString().isNotEmpty ||
                                                                            sSPriceController.text.toString() !=
                                                                                '') {
                                                                          if (double.parse(sSPriceController.text.toString()) >=
                                                                              0) {
                                                                            setState(() {
                                                                              sSPrice = 0;
                                                                            });
                                                                            setState(() {
                                                                              sSPrice = double.parse(sSPriceController.text.toString());
                                                                            });
                                                                            addPriceController.success();
                                                                            Future.delayed(const Duration(seconds: 1),
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            });
                                                                          } else {
                                                                            addPriceController.error();
                                                                            Future.delayed(const Duration(seconds: 1),
                                                                                () {
                                                                              addPriceController.reset();
                                                                              Fluttertoast.showToast(msg: 'Store Price cannot be less than zero', toastLength: Toast.LENGTH_LONG);
                                                                            });
                                                                          }
                                                                        } else {
                                                                          addPriceController
                                                                              .error();
                                                                          Future.delayed(
                                                                              const Duration(seconds: 1),
                                                                              () {
                                                                            addPriceController.reset();
                                                                          });
                                                                        }
                                                                      },
                                                                      child: const Text(
                                                                          'Add'),
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
                                                  padding:
                                                      const EdgeInsets.all(4.0),
                                                  child: SizedBox(
                                                    height: size.width * .07,
                                                    width: size.width * .38,
                                                    child: Center(
                                                      child: Text(
                                                        isShopifyStorePriceVisible ==
                                                                false
                                                            ? ''
                                                            : '$sSPrice',
                                                        style: TextStyle(
                                                          fontSize:
                                                              size.width * .05,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
                                    height: size.width * .12,
                                    width: size.width * .4,
                                    successIcon: Icons.check_rounded,
                                    failedIcon: Icons.close_rounded,
                                    successColor: Colors.green,
                                    controller: updatePriceController,
                                    onPressed: () async {
                                      if (sSPrice == sSPriceApi) {
                                        /// means no changes done - thus do not update
                                        updatePriceController.error();
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          updatePriceController.reset();
                                        });
                                      } else {
                                        /// changes are done - hit update store price api and fetch api again
                                        await ApiCalls.tokenAPI(
                                                refreshToken:
                                                    widget.refreshToken,
                                                authorization:
                                                    widget.authorization)
                                            .then((tokenXX) async {
                                          await updateStorePrice(
                                                  tokenXX, prodId, '$sSPrice')
                                              .then((value) async {
                                            if (value
                                                .contains('successfully')) {
                                              updatePriceController.success();
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
                                  size.width * .1, size.width * .05, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: size.height * .06,
                                    width: size.width * .6,
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
                                                StockTransfer(
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
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Stock Transfer',
                                            style: TextStyle(
                                                fontSize: size.width * .05),
                                          ),
                                          const Icon(
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
                            _productImage(context, size),
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
                  child: CachedNetworkImage(
                    imageUrl: _logicProvider.imagesResponse.value[0].url,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                      child: CircularProgressIndicator(
                          color: appColor, value: downloadProgress.progress),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/no_image/no_image.png',
                      width: size.width,
                      height: size.width,
                      fit: BoxFit.contain,
                    ),
                    width: size.width,
                    height: size.width,
                    fit: BoxFit.contain,
                  ),

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
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
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
    log('Update Store Price uri - $uri');

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
          await ApiCalls.tokenAPI(
                  refreshToken: widget.refreshToken,
                  authorization: widget.authorization)
              .then((tokenXX) async {
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
